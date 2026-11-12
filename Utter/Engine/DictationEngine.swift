import AVFoundation
import Foundation
import Speech
import UIKit

/// The listening side of Utter. It runs in the app (keyboards can't use the
/// mic), keeps going in the background while you're back in your other app,
/// and leaves each finished sentence in the shared folder for the keyboard.
///
/// It stops by itself after 1 minute with no new words, when you tap the mic
/// on the keyboard, or when a call or another app takes the mic.
@MainActor
final class DictationEngine: ObservableObject {
    @Published private(set) var state: ListenerStatus.State = .idle
    @Published private(set) var language: DictationLanguage
    @Published private(set) var partial = ""
    @Published private(set) var level: Double = 0
    @Published private(set) var countdown: Int?
    @Published private(set) var problem: String?
    /// This session's sentences, newest last, for the listening screen.
    @Published private(set) var sentences: [Segment] = []

    let store: SharedStore
    let cleaner = Cleaner()
    /// The checks never touch the mic; they set sample states instead.
    private let demo: Bool

    private var audio: AVAudioEngine?
    private let tap = AudioTap()
    private var analyzer: SpeechAnalyzer?
    private var transcriber: SpeechTranscriber?
    private var continuation: AsyncStream<AnalyzerInput>.Continuation?
    private var resultsTask: Task<Void, Never>?
    private var cleanupChain: Task<Void, Never>?
    private var clock = SilenceClock(startedAt: Date())
    private var ticker: Timer?
    private let bell = DarwinBell()
    private var handledCommand: UUID?
    private var observers: [NSObjectProtocol] = []

    var isListening: Bool { state == .listening || state == .starting }

    init(store: SharedStore, demo: Bool = false) {
        self.store = store
        self.demo = demo
        self.language = store.settings.language
        bell.listen(.command) { [weak self] in self?.checkCommand() }
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  AVAudioSession.InterruptionType(rawValue: raw) == .began else { return }
            Task { @MainActor in await self?.stop(problem: "Stopped: another app or a call took the mic.") }
        })
        // A stale status from a session that never got to say goodbye.
        if !demo, let old = store.status, old.state == .listening || old.state == .starting {
            store.status = ListenerStatus(state: .idle, language: language, updatedAt: Date())
        }
    }

    // MARK: Start and stop

    func start(language requested: DictationLanguage? = nil) async {
        if let requested, requested != language {
            if isListening { await switchLanguage(to: requested); return }
            language = requested
        }
        guard !isListening, !demo else { return }
        problem = nil
        partial = ""
        sentences = []
        state = .starting
        clock = SilenceClock(startedAt: Date())
        publish(force: true)

        guard await Permissions.requestMicrophone() else {
            await fail("Microphone is off for Utter. Turn it on in Settings > Utter.")
            return
        }
        _ = await Permissions.requestSpeech()

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .default, options: [])
            try session.setActive(true)

            let engine = AVAudioEngine()
            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            guard format.sampleRate > 0 else {
                await fail("Utter couldn't reach the microphone.")
                return
            }
            let tap = self.tap
            input.installTap(onBus: 0, bufferSize: 2048, format: format) { buffer, _ in
                tap.feed(buffer)
            }
            engine.prepare()
            try engine.start()
            audio = engine
        } catch {
            await fail("Utter couldn't start the microphone.")
            return
        }

        do {
            try await startSpeech(language)
        } catch let error as StartError {
            await fail(error.message)
            return
        } catch {
            await fail("Speech recognition couldn't start. Try again.")
            return
        }

        cleaner.prepare()
        state = .listening
        clock = SilenceClock(startedAt: Date())
        startTicker()
        publish(force: true)
    }

    /// Lets go of the mic. Sentences already heard still get typed.
    func stop(problem: String? = nil) async {
        guard isListening || state == .failed else { return }
        state = .stopping
        ticker?.invalidate()
        ticker = nil
        publish(force: true)

        audio?.inputNode.removeTap(onBus: 0)
        audio?.stop()
        audio = nil
        await finishSpeech()
        await cleanupChain?.value
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])

        self.problem = problem
        state = .idle
        partial = ""
        level = 0
        countdown = nil
        publish(force: true)
    }

    private func fail(_ message: String) async {
        state = .failed
        problem = message
        publish(force: true)
        audio?.inputNode.removeTap(onBus: 0)
        audio?.stop()
        audio = nil
        await finishSpeech()
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        ticker?.invalidate()
        ticker = nil
    }

    // MARK: Speech

    struct StartError: Error { let message: String }

    private func startSpeech(_ language: DictationLanguage) async throws {
        guard let locale = await SpeechTranscriber.supportedLocale(equivalentTo: Locale(identifier: language.localeIdentifier)) else {
            throw StartError(message: "\(language.name) speech isn't available on this iPhone.")
        }
        let transcriber = SpeechTranscriber(locale: locale,
                                            transcriptionOptions: [],
                                            reportingOptions: [.volatileResults],
                                            attributeOptions: [])
        if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            problem = language == .spanish ? "Descargando el español (solo una vez)…" : "Downloading English speech (one time only)…"
            publish(force: true)
            try await request.downloadAndInstall()
            problem = nil
        }
        guard let format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]) else {
            throw StartError(message: "Speech recognition couldn't start. Try again.")
        }
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        let (stream, continuation) = AsyncStream<AnalyzerInput>.makeStream()
        self.transcriber = transcriber
        self.analyzer = analyzer
        self.continuation = continuation

        resultsTask = Task { [weak self] in
            do {
                for try await result in transcriber.results {
                    let text = String(result.text.characters)
                    self?.heard(text, isFinal: result.isFinal, language: language)
                }
            } catch {
                // The stream ends with an error only when the analyzer is cancelled.
            }
        }
        try await analyzer.start(inputSequence: stream)
        tap.route(to: continuation, format: format)
    }

    private func finishSpeech() async {
        tap.route(to: nil, format: nil)
        continuation?.finish()
        continuation = nil
        if let analyzer {
            try? await analyzer.finalizeAndFinishThroughEndOfInput()
        }
        await resultsTask?.value
        resultsTask = nil
        analyzer = nil
        transcriber = nil
    }

    private func switchLanguage(to newLanguage: DictationLanguage) async {
        await finishSpeech()
        language = newLanguage
        partial = ""
        do {
            try await startSpeech(newLanguage)
            clock.heardSpeech(at: Date())
            publish(force: true)
        } catch let error as StartError {
            await fail(error.message)
        } catch {
            await fail("Speech recognition couldn't switch languages. Try again.")
        }
    }

    private func heard(_ text: String, isFinal: Bool, language: DictationLanguage) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { clock.heardSpeech(at: Date()) }
        guard isFinal else {
            partial = trimmed
            publish()
            return
        }
        partial = ""
        guard !trimmed.isEmpty else { return }
        let enabled = store.settings.cleanup
        // One at a time, so sentences arrive in the order they were said.
        let previous = cleanupChain
        cleanupChain = Task { [weak self] in
            await previous?.value
            guard let self else { return }
            let clean = await self.cleaner.clean(trimmed, language: language, enabled: enabled)
            guard !clean.isEmpty else { return }
            self.deliver(raw: trimmed, clean: clean, language: language)
        }
        publish(force: true)
    }

    private func deliver(raw: String, clean: String, language: DictationLanguage) {
        if store.isAvailable {
            var outbox = store.outbox
            let segment = outbox.append(raw: raw, clean: clean, language: language, at: Date())
            store.outbox = outbox
            sentences.append(segment)
            DarwinBell.ring(.outbox)
        } else {
            // No shared folder: put the whole session on the clipboard for the keyboard's Paste.
            let segment = Segment(id: sentences.count + 1, raw: raw, clean: clean, language: language, createdAt: Date())
            sentences.append(segment)
            UIPasteboard.general.string = sentences.map(\.clean).joined(separator: " ")
        }
    }

    // MARK: Status for the keyboard

    private func startTicker() {
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func tick() {
        guard state == .listening else { return }
        let now = Date()
        level = tap.level
        countdown = clock.countdown(at: now)
        if clock.shouldStop(at: now) {
            Task { await stop() }
            return
        }
        checkCommand()
        publish()
    }

    private var lastPublish = Date.distantPast

    /// Writes the status file (at most 5 times a second) and rings the keyboard.
    private func publish(force: Bool = false) {
        guard !demo else { return }
        let now = Date()
        guard force || now.timeIntervalSince(lastPublish) >= 0.2 else { return }
        lastPublish = now
        store.status = ListenerStatus(state: state, language: language, partial: partial, level: level,
                                      countdown: countdown, problem: problem, updatedAt: now)
        DarwinBell.ring(.status)
    }

    private func checkCommand() {
        guard let command = store.command, command.id != handledCommand, command.isFresh(at: Date()) else { return }
        handledCommand = command.id
        switch command.action {
        case .stop:
            Task { await stop() }
        case .switchLanguage:
            if let next = command.language { Task { await start(language: next) } }
        }
    }

    // MARK: Sample states for the screenshots

    func showSample(state: ListenerStatus.State, language: DictationLanguage, partial: String = "",
                    level: Double = 0, countdown: Int? = nil, problem: String? = nil, sentences: [Segment] = []) {
        self.state = state
        self.language = language
        self.partial = partial
        self.level = level
        self.countdown = countdown
        self.problem = problem
        self.sentences = sentences
    }

    /// The language for the next session (from Settings or the keyboard).
    func setLanguage(_ newLanguage: DictationLanguage) {
        var settings = store.settings
        settings.language = newLanguage
        store.settings = settings
        if isListening {
            Task { await start(language: newLanguage) }
        } else {
            language = newLanguage
        }
    }
}
