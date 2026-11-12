import Foundation
import Speech
import SwiftUI
import UIKit

/// Works out how far setup has got, for the checklist on the home screen.
@MainActor
final class SetupChecker: ObservableObject {
    enum SpeechState: Equatable { case checking, ready, needsDownload, downloading, unavailable }

    @Published var keyboardAdded = false
    @Published var fullAccess = false
    @Published var microphone: Permissions.Status = .notAsked
    @Published var speech: [DictationLanguage: SpeechState] = [.english: .checking, .spanish: .checking]
    @Published var cleanupLine = ""
    @Published var sharedFolderMissing = false

    private let store: SharedStore
    private weak var engine: DictationEngine?
    private let sample: String?

    init(store: SharedStore, engine: DictationEngine, sample: String?) {
        self.store = store
        self.engine = engine
        self.sample = sample
        refresh()
    }

    var allDone: Bool {
        keyboardAdded && fullAccess && microphone == .allowed && speech.values.allSatisfy { $0 == .ready }
    }

    func refresh() {
        if let sample {
            let ready = sample == "ready"
            keyboardAdded = ready
            fullAccess = ready
            microphone = ready ? .allowed : .notAsked
            speech = [.english: ready ? .ready : .needsDownload, .spanish: ready ? .ready : .needsDownload]
            cleanupLine = "On: Apple's on-device model cleans up your words."
            return
        }
        sharedFolderMissing = !store.isAvailable
        // iOS lists the keyboards you've added here, by their app's id.
        let id = Bundle.main.bundleIdentifier ?? "com.albertoaday.utter"
        let keyboards = UserDefaults.standard.object(forKey: "AppleKeyboards") as? [String] ?? []
        let presence = store.presence
        keyboardAdded = keyboards.contains(where: { $0.hasPrefix(id + ".") }) || presence != nil
        fullAccess = presence?.fullAccess ?? false
        microphone = Permissions.microphone
        cleanupLine = engine?.cleaner.modelStatusLine ?? ""
        Task { await checkSpeech() }
    }

    private func transcriber(for language: DictationLanguage) async -> SpeechTranscriber? {
        guard let locale = await SpeechTranscriber.supportedLocale(equivalentTo: Locale(identifier: language.localeIdentifier)) else {
            return nil
        }
        return SpeechTranscriber(locale: locale, transcriptionOptions: [], reportingOptions: [.volatileResults], attributeOptions: [])
    }

    private func checkSpeech() async {
        for language in DictationLanguage.allCases where speech[language] != .downloading {
            guard let module = await transcriber(for: language) else {
                speech[language] = .unavailable
                continue
            }
            switch await AssetInventory.status(forModules: [module]) {
            case .installed: speech[language] = .ready
            case .downloading: speech[language] = .downloading
            case .supported: speech[language] = .needsDownload
            default: speech[language] = .unavailable
            }
        }
    }

    /// Downloads both languages' speech models (once; they then work offline).
    func downloadSpeech() async {
        for language in DictationLanguage.allCases where speech[language] == .needsDownload {
            guard let module = await transcriber(for: language) else { continue }
            speech[language] = .downloading
            do {
                if let request = try await AssetInventory.assetInstallationRequest(supporting: [module]) {
                    try await request.downloadAndInstall()
                }
                speech[language] = .ready
            } catch {
                speech[language] = .needsDownload
            }
        }
    }

    func requestMicrophone() async {
        _ = await Permissions.requestMicrophone()
        microphone = Permissions.microphone
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
    }
}
