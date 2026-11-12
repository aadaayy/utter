import SwiftUI

/// The first screen: setting up the keyboard, a place to try it, and how it works.
/// Phones and the folded Duo: one column. Open Duo: two columns.
struct HomeView: View {
    let openSettings: () -> Void
    let openListening: () -> Void
    @EnvironmentObject private var engine: DictationEngine
    @EnvironmentObject private var setup: SetupChecker
    @Environment(\.scenePhase) private var scenePhase
    @State private var tryText = ""

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                if geometry.size.width > 700 {
                    HStack(alignment: .top, spacing: 20) {
                        VStack(spacing: 16) {
                            header
                            setupCard
                        }
                        VStack(spacing: 16) {
                            listenCard
                            tryCard
                            howCard
                        }
                    }
                    .padding(20)
                } else {
                    VStack(spacing: 16) {
                        header
                        listenCard
                        setupCard
                        tryCard
                        howCard
                    }
                    .padding(16)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
        .navigationTitle("Utter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: openSettings) { Image(systemName: "gearshape") }
                    .accessibilityLabel("Settings")
                    .accessibilityIdentifier("settings-button")
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { setup.refresh() }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "mic.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Theme.blue, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text("Talk, and it types.")
                    .font(.title2.bold())
                Text("English and Spanish. Everything stays on this iPhone.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("home-header")
    }

    private var listenCard: some View {
        Card {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(engine.isListening ? "Listening in \(engine.language.name)" : "Not listening")
                        .font(.headline)
                    Text(engine.isListening ? "Stops after 1 minute of quiet." :
                            "Start from the Utter keyboard's mic, or here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Button {
                    if engine.isListening {
                        Task { await engine.stop() }
                    } else {
                        openListening()
                        Task { await engine.start() }
                    }
                } label: {
                    Text(engine.isListening ? "Stop" : "Start")
                        .font(.headline)
                        .padding(.horizontal, 18)
                        .frame(minHeight: 44)
                        .background(engine.isListening ? Theme.live : Theme.blue, in: Capsule())
                        .foregroundStyle(.white)
                }
                .accessibilityIdentifier("listen-button")
            }
            if let problem = engine.problem, !engine.isListening {
                Label(problem, systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var setupCard: some View {
        Card {
            HStack {
                Text(setup.allDone ? "All set" : "Set up the keyboard")
                    .font(.headline)
                Spacer()
                if setup.allDone {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.green)
                }
            }
            .accessibilityIdentifier("setup-title")

            StepRow(number: 1, done: setup.keyboardAdded, title: "Add the Utter keyboard",
                    detail: "Settings > General > Keyboard > Keyboards > Add New Keyboard > Utter.")
            StepRow(number: 2, done: setup.fullAccess, title: "Turn on Allow Full Access",
                    detail: "Tap Utter in that list. The keyboard needs it to pick up your words from this app. Nothing goes online.")
            StepRow(number: 3, done: setup.microphone == .allowed, title: "Allow the microphone",
                    detail: setup.microphone == .denied ? "It's off. Turn it on in Settings > Utter > Microphone." :
                        "Only the Utter app listens, and only after you tap the mic.") {
                if setup.microphone == .notAsked {
                    Button("Allow") { Task { await setup.requestMicrophone() } }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("allow-mic")
                }
            }
            StepRow(number: 4, done: setup.speech.values.allSatisfy { $0 == .ready }, title: "Get English and Spanish speech",
                    detail: speechDetail) {
                if setup.speech.values.contains(.needsDownload) {
                    Button("Get") { Task { await setup.downloadSpeech() } }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("download-speech")
                }
            }
            if setup.sharedFolderMissing {
                Label("This iPhone didn't give Utter its shared folder, so your words go to the clipboard. Tap Paste on the keyboard to type them.",
                      systemImage: "doc.on.clipboard")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
            Button {
                setup.openSettings()
            } label: {
                Label("Open Settings", systemImage: "gear")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.blue)
            .accessibilityIdentifier("open-settings")
        }
    }

    private var speechDetail: String {
        let states = setup.speech.values
        if states.contains(.downloading) { return "Downloading. It happens once, then works offline." }
        if states.allSatisfy({ $0 == .ready }) { return "Ready, and it works offline." }
        if states.contains(.unavailable) { return "One of the languages isn't available on this iPhone." }
        return "A one-time download from Apple. After that it works offline."
    }

    private var tryCard: some View {
        Card {
            Text("Try it here")
                .font(.headline)
            ZStack(alignment: .topLeading) {
                if tryText.isEmpty {
                    Text("Switch to the Utter keyboard with the globe key, then tap the mic.")
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
                TextEditor(text: $tryText)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 96)
                    .accessibilityIdentifier("try-field")
            }
            .padding(8)
            .background(Color(uiColor: .tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var howCard: some View {
        Card {
            Text("How it works")
                .font(.headline)
            VStack(alignment: .leading, spacing: 8) {
                HowLine(number: 1, text: "Tap the mic on the Utter keyboard.")
                HowLine(number: 2, text: "Utter opens for a second and starts listening.")
                HowLine(number: 3, text: "Go back with ◀ at the top left, or swipe right along the bottom edge.")
                HowLine(number: 4, text: "Talk. Each sentence types itself when you pause.")
                HowLine(number: 5, text: "It stops after 1 minute of quiet. Tap the mic to stop sooner.")
            }
        }
    }
}

private struct StepRow<Accessory: View>: View {
    let number: Int
    let done: Bool
    let title: String
    let detail: String
    @ViewBuilder var accessory: Accessory

    init(number: Int, done: Bool, title: String, detail: String, @ViewBuilder accessory: () -> Accessory = { EmptyView() }) {
        self.number = number
        self.done = done
        self.title = title
        self.detail = detail
        self.accessory = accessory()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(done ? Theme.green : Color(uiColor: .tertiarySystemFill))
                if done {
                    Image(systemName: "checkmark").font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                } else {
                    Text("\(number)").font(.system(size: 14, weight: .semibold)).foregroundStyle(.secondary)
                }
            }
            .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.footnote).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            accessory
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("step-\(number)")
    }
}

private struct HowLine: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("\(number)")
                .font(.footnote.weight(.bold))
                .foregroundStyle(Theme.blue)
                .frame(width: 18)
            Text(text).font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
