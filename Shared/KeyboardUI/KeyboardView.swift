import SwiftUI

/// Utter's keyboard: no letter keys. One wide voice bar does the talking, with
/// globe, space, delete and return under it.
/// - Phones and the folded Duo: language and status on top, the voice bar in
///   the middle, the basics along the bottom.
/// - Open Duo (wide): status and the basics on the left half, a big voice bar
///   on the right half, nothing on the crease.
public struct KeyboardView<Globe: View>: View {
    @ObservedObject var model: KeyboardModel
    let globe: Globe
    @Environment(\.colorScheme) private var scheme

    public init(model: KeyboardModel, @ViewBuilder globe: () -> Globe) {
        self.model = model
        self.globe = globe()
    }

    public var body: some View {
        Group {
            if model.isWide { wide } else { compact }
        }
        .background(KeyboardTheme.background(scheme))
    }

    // MARK: Layouts

    private var compact: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 10)
                .padding(.top, 8)
            Spacer(minLength: 4)
            message
                .padding(.horizontal, 20)
            Spacer(minLength: 6)
            VoiceBar(model: model, height: 62)
                .padding(.horizontal, 12)
            Spacer(minLength: 10)
            bottomRow
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
        }
    }

    private var wide: some View {
        GeometryReader { geometry in
            let half = (geometry.size.width - 40) / 2
            HStack(spacing: 40) {
                // Left half: the words and the basics.
                VStack(alignment: .leading, spacing: 10) {
                    topBar
                    message
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer(minLength: 0)
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            globeKey
                            spaceKey
                        }
                        HStack(spacing: 6) {
                            deleteKey
                            returnKey
                        }
                    }
                }
                .frame(width: half)
                // Right half: a big voice bar, centred under the right thumb.
                VStack {
                    Spacer(minLength: 0)
                    VoiceBar(model: model, height: 92)
                        .frame(maxWidth: 400)
                    Spacer(minLength: 0)
                }
                .frame(width: half)
            }
            .padding(.vertical, 10)
        }
        .padding(.horizontal, 12)
    }

    // MARK: Pieces

    private var topBar: some View {
        HStack(spacing: 8) {
            LanguageSwitch(model: model)

            Spacer(minLength: 0)

            if model.canUndoCleanup {
                Button(action: model.onUndoCleanup) {
                    Label(model.showingRaw ? (model.language == .spanish ? "Limpio" : "Cleaned")
                                           : (model.language == .spanish ? "Sin limpiar" : "Raw words"),
                          systemImage: model.showingRaw ? "sparkles" : "arrow.uturn.backward")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(KeyboardTheme.text(scheme))
                        .padding(.horizontal, 12)
                        .frame(height: 30)
                        .background(KeyboardTheme.chip(scheme), in: Capsule())
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel(model.showingRaw ? "Put the cleaned words back" : "Undo cleanup: type my words exactly as spoken")
                .accessibilityIdentifier("undo-cleanup")
            }

            if model.phase == .clipboardOnly {
                Button(action: model.onPasteClipboard) {
                    Label(model.language == .spanish ? "Pegar" : "Paste", systemImage: "doc.on.clipboard")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Brand.onInk(scheme))
                        .padding(.horizontal, 14)
                        .frame(height: 30)
                        .background(Brand.ink(scheme), in: Capsule())
                }
                .buttonStyle(PressableStyle())
                .accessibilityIdentifier("paste-clipboard")
            }
        }
        .frame(height: 32)
    }

    private var message: some View {
        let live = model.phase == .listening && !model.partial.isEmpty && model.countdown == nil
        return VStack(alignment: model.isWide ? .leading : .center, spacing: 3) {
            Text(model.headline)
                .font(live ? .system(size: 18, weight: .regular) : .system(size: 16, weight: .semibold))
                .foregroundStyle(KeyboardTheme.text(scheme))
                .lineLimit(2)
                .truncationMode(.head)
                .multilineTextAlignment(model.isWide ? .leading : .center)
                .contentTransition(.opacity)
                .accessibilityIdentifier("keyboard-headline")
            if let detail = model.detail {
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(KeyboardTheme.secondaryText(scheme))
                    .lineLimit(2)
                    .multilineTextAlignment(model.isWide ? .leading : .center)
                    .accessibilityIdentifier("keyboard-detail")
            }
        }
        .minimumScaleFactor(0.8)
        .frame(minHeight: 44)
    }

    private var bottomRow: some View {
        HStack(spacing: 6) {
            if model.showsGlobe { globeKey }
            spaceKey
            deleteKey
            returnKey
        }
    }

    private var globeKey: some View {
        globe
            .frame(width: model.isWide ? nil : 46, height: 44)
            .frame(maxWidth: model.isWide ? .infinity : nil)
            .background(KeyboardTheme.functionKey(scheme), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .shadow(color: KeyboardTheme.keyShadow(scheme), radius: 0, x: 0, y: 1)
            .accessibilityIdentifier("globe-key")
    }

    private var spaceKey: some View {
        KeyButton(label: model.language == .spanish ? "espacio" : "space", systemImage: nil,
                  fill: KeyboardTheme.key(scheme), action: model.onSpace)
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("space-key")
    }

    private var deleteKey: some View {
        RepeatingKey(systemImage: "delete.left", fill: KeyboardTheme.functionKey(scheme), action: model.onDelete)
            .frame(width: model.isWide ? nil : 52)
            .frame(maxWidth: model.isWide ? .infinity : nil)
            .accessibilityLabel("Delete")
            .accessibilityIdentifier("delete-key")
    }

    private var returnKey: some View {
        KeyButton(label: nil, systemImage: "return", fill: KeyboardTheme.functionKey(scheme), action: model.onReturn)
            .frame(width: model.isWide ? nil : 72)
            .frame(maxWidth: model.isWide ? .infinity : nil)
            .accessibilityLabel("Return")
            .accessibilityIdentifier("return-key")
    }
}

/// EN | ES, with the current language filled in. One tap switches, even
/// while you're talking.
struct LanguageSwitch: View {
    @ObservedObject var model: KeyboardModel
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: model.onLanguage) {
            HStack(spacing: 2) {
                segment(.english)
                segment(.spanish)
            }
            .padding(2)
            .background(KeyboardTheme.chip(scheme), in: Capsule())
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(model.language == .english ? "Language: English. Switch to Spanish" : "Idioma: español. Cambiar a inglés")
        .accessibilityIdentifier("language-chip")
    }

    private func segment(_ language: DictationLanguage) -> some View {
        let on = model.language == language
        return Text(language.shortLabel)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .tracking(0.6)
            .foregroundStyle(on ? Brand.onInk(scheme) : KeyboardTheme.secondaryText(scheme))
            .frame(width: 34, height: 26)
            .background(on ? Brand.ink(scheme) : .clear, in: Capsule())
    }
}

/// The voice bar: the one big control.
/// - Ready: an ink pill with an ember mic and "Tap to talk".
/// - Opening Utter: a spinner while the app starts the mic.
/// - Listening: ember, with bars that follow your voice and a stop button.
struct VoiceBar: View {
    @ObservedObject var model: KeyboardModel
    let height: CGFloat
    @Environment(\.colorScheme) private var scheme

    private var live: Bool { model.phase == .listening }
    private var starting: Bool { model.phase == .starting }
    private var blocked: Bool { model.phase == .needsFullAccess }

    var body: some View {
        Button(action: model.onMic) {
            ZStack {
                Capsule()
                    .fill(fill)
                    .shadow(color: shadow, radius: live ? 16 : 8, y: live ? 6 : 3)
                content
                    .padding(.horizontal, height * 0.14)
            }
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .contentShape(Capsule())
        }
        .buttonStyle(PressableStyle())
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: model.phase)
        .accessibilityLabel(accessibilityText)
        .accessibilityIdentifier("mic-button")
    }

    private var fill: AnyShapeStyle {
        if live { return AnyShapeStyle(Brand.emberGradient) }
        if blocked { return AnyShapeStyle(KeyboardTheme.chip(scheme)) }
        return AnyShapeStyle(Brand.ink(scheme))
    }

    private var shadow: Color {
        if live { return Brand.ember.opacity(0.45) }
        if blocked { return .clear }
        return .black.opacity(scheme == .dark ? 0.0 : 0.22)
    }

    @ViewBuilder private var content: some View {
        let orb = height - height * 0.24
        if live {
            HStack(spacing: 12) {
                Waveform(levels: model.levels, color: .white.opacity(0.95),
                         barWidth: height > 80 ? 4 : 3, spacing: height > 80 ? 4 : 3)
                    .frame(height: height * 0.5)
                if let countdown = model.countdown {
                    Text("\(countdown)s")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
                ZStack {
                    Circle().fill(.white)
                    RoundedRectangle(cornerRadius: orb * 0.08, style: .continuous)
                        .fill(Brand.emberBottom)
                        .frame(width: orb * 0.3, height: orb * 0.3)
                }
                .frame(width: orb, height: orb)
            }
        } else {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(blocked ? AnyShapeStyle(KeyboardTheme.secondaryText(scheme).opacity(0.35))
                                          : AnyShapeStyle(Brand.emberGradient))
                    if starting {
                        ProgressView().progressViewStyle(.circular).tint(.white)
                    } else {
                        Image(systemName: blocked ? "mic.slash.fill" : "mic.fill")
                            .font(.system(size: orb * 0.42, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: orb, height: orb)
                Text(model.barLabel)
                    .font(.system(size: height > 80 ? 20 : 17, weight: .semibold))
                    .foregroundStyle(blocked ? KeyboardTheme.secondaryText(scheme) : Brand.onInk(scheme))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
                if !blocked {
                    Text(model.language.shortLabel)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(Brand.onInk(scheme).opacity(0.5))
                        .padding(.trailing, 6)
                }
            }
        }
    }

    private var accessibilityText: String {
        let spanish = model.language == .spanish
        if live { return spanish ? "Parar" : "Stop listening" }
        return spanish ? "Dictar" : "Start dictation"
    }
}

/// Presses shrink a touch, like the system's own controls.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// A plain key with Apple-keyboard styling.
struct KeyButton: View {
    let label: String?
    let systemImage: String?
    let fill: Color
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: action) {
            Group {
                if let systemImage {
                    Image(systemName: systemImage).font(.system(size: 18, weight: .regular))
                } else if let label {
                    Text(label).font(.system(size: 16))
                }
            }
            .foregroundStyle(KeyboardTheme.text(scheme))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(fill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: KeyboardTheme.keyShadow(scheme), radius: 0, x: 0, y: 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Delete: one tap deletes one character; holding keeps deleting, faster
/// after a moment, like Apple's keyboard.
struct RepeatingKey: View {
    let systemImage: String
    let fill: Color
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme
    @State private var timer: Timer?
    @State private var pressed = false

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 18))
            .foregroundStyle(KeyboardTheme.text(scheme))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(pressed ? KeyboardTheme.key(scheme) : fill,
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: KeyboardTheme.keyShadow(scheme), radius: 0, x: 0, y: 1)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !pressed else { return }
                        pressed = true
                        action()
                        var ticks = 0
                        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                            ticks += 1
                            // Wait half a second, then repeat; after 2 s, two at a time.
                            if ticks >= 5 { action() }
                            if ticks >= 20 { action() }
                        }
                    }
                    .onEnded { _ in
                        pressed = false
                        timer?.invalidate()
                        timer = nil
                    }
            )
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { action() }
    }
}

/// The globe key's picture, for the app's screenshots (the real keyboard uses
/// a UIKit button so iOS can show its keyboard list on a long press).
public struct GlobeIcon: View {
    @Environment(\.colorScheme) private var scheme
    public init() {}
    public var body: some View {
        Image(systemName: "globe")
            .font(.system(size: 18))
            .foregroundStyle(KeyboardTheme.text(scheme))
    }
}
