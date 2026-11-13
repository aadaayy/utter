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
    @Environment(\.dynamicTypeSize) private var typeSize

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                if geometry.size.width > 700 {
                    HStack(alignment: .top, spacing: 24) {
                        VStack(spacing: 18) {
                            header
                            setupCard
                        }
                        .frame(maxWidth: .infinity, alignment: .top)
                        VStack(spacing: 18) {
                            listenCard
                            tryCard
                            howCard
                        }
                        .frame(maxWidth: .infinity, alignment: .top)
                    }
                    .padding(24)
                } else {
                    VStack(spacing: 18) {
                        header
                        listenCard
                        setupCard
                        tryCard
                        howCard
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Brand.paper(scheme).ignoresSafeArea())
        }
        .navigationTitle("Utter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Brand.paper(scheme), for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Circle().fill(engine.isListening ? AnyShapeStyle(Brand.emberGradient) : AnyShapeStyle(Brand.ink(scheme)))
                        .frame(width: 8, height: 8)
                    Text("Utter")
                        .font(.system(.title3, design: .serif).weight(.semibold))
                        .foregroundStyle(Brand.ink(scheme))
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: openSettings) { Image(systemName: "gearshape") }
                    .tint(Brand.ink(scheme))
                    .accessibilityLabel("Settings")
                    .accessibilityIdentifier("settings-button")
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { setup.refresh() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Talk, and it types.")
                .font(.system(.largeTitle, design: .serif).weight(.semibold))
                .foregroundStyle(Brand.ink(scheme))
                .fixedSize(horizontal: false, vertical: true)
            Text("English and Spanish, cleaned up as you go. Everything stays on this iPhone.")
                .font(.body)
                .foregroundStyle(Brand.muted(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("home-header")
    }

    private var listenCard: some View {
        Card {
            let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
                                                      : AnyLayout(HStackLayout(spacing: 14))
            layout {
                EmberOrb(size: 54, symbol: engine.isListening ? "waveform" : "mic.fill")
                VStack(alignment: .leading, spacing: 3) {
                    Text(engine.isListening ? "Listening in \(engine.language.name)" : "Ready when you are")
                        .font(.system(.title3, design: .serif).weight(.semibold))
                        .foregroundStyle(Brand.ink(scheme))
                    Text(engine.isListening ? "Stops after 1 minute of quiet." :
                            "Start from the Utter keyboard, or right here.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.muted(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }
            }
            if engine.isListening {
                Waveform(levels: engine.levels, color: Brand.ember, barWidth: 3, spacing: 3)
                    .frame(height: 28)
            }
            Button {
                if engine.isListening {
                    Task { await engine.stop() }
                } else {
                    openListening()
                    Task { await engine.start() }
                }
            } label: {
                Label(engine.isListening ? "Stop" : "Start dictating",
                      systemImage: engine.isListening ? "stop.fill" : "mic.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(InkButtonStyle(fill: engine.isListening ? AnyShapeStyle(Brand.emberGradient) : nil))
            .accessibilityIdentifier("listen-button")
            if let problem = engine.problem, !engine.isListening {
                Label(problem, systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var stepsDone: Int {
        [setup.keyboardAdded, setup.fullAccess, setup.microphone == .allowed,
         setup.speech.values.allSatisfy { $0 == .ready }].filter { $0 }.count
    }

    private var setupCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Eyebrow(text: "Set up")
                    Spacer()
                    Text("\(stepsDone) of 4")
                        .font(.system(size: 13, weight: .semibold).monospacedDigit())
                        .foregroundStyle(Brand.muted(scheme))
                }
                HStack(spacing: 8) {
                    Text(setup.allDone ? "All set" : "Set up the keyboard")
                        .font(.system(.title3, design: .serif).weight(.semibold))
                        .foregroundStyle(Brand.ink(scheme))
                    if setup.allDone {
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.done)
                    }
                }
                ProgressBar(value: Double(stepsDone) / 4)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("setup-title")

            VStack(alignment: .leading, spacing: 16) {
                StepRow(number: 1, done: setup.keyboardAdded, title: "Add the Utter keyboard",
                        detail: "Settings > General > Keyboard > Keyboards > Add New Keyboard > Utter.")
                StepRow(number: 2, done: setup.fullAccess, title: "Turn on Allow Full Access",
                        detail: "Tap Utter in that list. The keyboard needs it to pick up your words from this app. Nothing goes online.")
                StepRow(number: 3, done: setup.microphone == .allowed, title: "Allow the microphone",
                        detail: setup.microphone == .denied ? "It's off. Turn it on in Settings > Utter > Microphone." :
                            "Only the Utter app listens, and only after you tap the mic.") {
                    if setup.microphone == .notAsked {
                        Button("Allow") { Task { await setup.requestMicrophone() } }
                            .buttonStyle(QuietButtonStyle())
                            .accessibilityIdentifier("allow-mic")
                    }
                }
                StepRow(number: 4, done: setup.speech.values.allSatisfy { $0 == .ready }, title: "Get English and Spanish speech",
                        detail: speechDetail) {
                    if setup.speech.values.contains(.needsDownload) {
                        Button("Get") { Task { await setup.downloadSpeech() } }
                            .buttonStyle(QuietButtonStyle())
                            .accessibilityIdentifier("download-speech")
                    }
                }
            }
            if setup.sharedFolderMissing {
                Label("This iPhone didn't give Utter its shared folder, so your words go to the clipboard. Tap Paste on the keyboard to type them.",
                      systemImage: "doc.on.clipboard")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
            if setup.allDone {
                Button { setup.openSettings() } label: {
                    Label("Open Settings", systemImage: "gear").frame(maxWidth: .infinity)
                }
                .buttonStyle(QuietButtonStyle())
                .accessibilityIdentifier("open-settings")
            } else {
                Button { setup.openSettings() } label: {
                    Label("Open Settings", systemImage: "gear").frame(maxWidth: .infinity)
                }
                .buttonStyle(InkButtonStyle())
                .accessibilityIdentifier("open-settings")
            }
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
            Eyebrow(text: "Try it")
            ZStack(alignment: .topLeading) {
                if tryText.isEmpty {
                    Text("Switch to the Utter keyboard with the globe key, then tap the voice bar.")
                        .foregroundStyle(Brand.muted(scheme).opacity(0.8))
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
                TextEditor(text: $tryText)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 96)
                    .tint(Brand.ember)
                    .accessibilityIdentifier("try-field")
            }
            .padding(10)
            .background(Brand.paper(scheme), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var howCard: some View {
        Card {
            Eyebrow(text: "How it works")
            VStack(alignment: .leading, spacing: 12) {
                HowLine(number: 1, text: "Tap the voice bar on the Utter keyboard.")
                HowLine(number: 2, text: "Utter opens for a second and starts listening.")
                HowLine(number: 3, text: "Go back with ◀ at the top left, or swipe right along the bottom edge.")
                HowLine(number: 4, text: "Talk. Each sentence types itself when you pause.")
                HowLine(number: 5, text: "It stops after 1 minute of quiet. Tap Stop to end sooner.")
            }
        }
    }
}

/// A thin bar that fills as setup gets done.
private struct ProgressBar: View {
    let value: Double
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Brand.hairline(scheme))
                Capsule().fill(value >= 1 ? AnyShapeStyle(Theme.done) : AnyShapeStyle(Brand.ink(scheme)))
                    .frame(width: max(6, geometry.size.width * value))
            }
        }
        .frame(height: 6)
        .accessibilityHidden(true)
    }
}

private struct StepRow<Accessory: View>: View {
    let number: Int
    let done: Bool
    let title: String
    let detail: String
    @ViewBuilder var accessory: Accessory
    @Environment(\.colorScheme) private var scheme

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
                Circle().fill(done ? AnyShapeStyle(Theme.done) : AnyShapeStyle(Brand.hairline(scheme)))
                if done {
                    Image(systemName: "checkmark").font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                } else {
                    Text("\(number)").font(.system(size: 14, weight: .semibold, design: .serif)).foregroundStyle(Brand.ink(scheme))
                }
            }
            .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.ink(scheme))
                Text(detail).font(.footnote).foregroundStyle(Brand.muted(scheme))
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
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("\(number)")
                .font(.system(.callout, design: .serif).weight(.semibold))
                .foregroundStyle(Brand.muted(scheme))
                .frame(width: 18)
            Text(text).font(.subheadline)
                .foregroundStyle(Brand.ink(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
