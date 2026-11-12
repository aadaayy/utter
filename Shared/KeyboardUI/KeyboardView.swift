import SwiftUI

/// Utter's keyboard: no letter keys, one big mic, and the basics around it.
/// - Phones and the folded Duo: the line of words on top, the mic in the
///   middle, and globe, space, delete and return along the bottom.
/// - Open Duo (wide): the basics on the left half and the mic on the right
///   half, with nothing on the crease.
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
        VStack(spacing: 6) {
            topBar
                .padding(.horizontal, 8)
                .padding(.top, 8)
            Spacer(minLength: 0)
            message
                .padding(.horizontal, 16)
            MicButton(model: model, size: 84)
                .padding(.vertical, 4)
            Spacer(minLength: 0)
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
                // Right half: the mic, centred.
                VStack(spacing: 10) {
                    Spacer(minLength: 0)
                    MicButton(model: model, size: 112)
                    Spacer(minLength: 0)
                }
                .frame(width: half)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 0)
        }
        .padding(.horizontal, 12)
    }

    // MARK: Pieces

    private var topBar: some View {
        HStack(spacing: 8) {
            Button(action: model.onLanguage) {
                Text(model.language.shortLabel)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(KeyboardTheme.text(scheme))
                    .frame(width: 44, height: 30)
                    .background(KeyboardTheme.functionKey(scheme), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(model.language == .english ? "Language: English. Switch to Spanish" : "Idioma: español. Cambiar a inglés")
            .accessibilityIdentifier("language-chip")

            Spacer(minLength: 0)

            if model.canUndoCleanup {
                Button(action: model.onUndoCleanup) {
                    Label(model.showingRaw ? (model.language == .spanish ? "Limpio" : "Cleaned")
                                           : (model.language == .spanish ? "Sin limpiar" : "Raw words"),
                          systemImage: model.showingRaw ? "sparkles" : "arrow.uturn.backward")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(KeyboardTheme.text(scheme))
                        .padding(.horizontal, 10)
                        .frame(height: 30)
                        .background(KeyboardTheme.functionKey(scheme), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(model.showingRaw ? "Put the cleaned words back" : "Undo cleanup: type my words exactly as spoken")
                .accessibilityIdentifier("undo-cleanup")
            }

            if model.phase == .clipboardOnly {
                Button(action: model.onPasteClipboard) {
                    Label("Paste", systemImage: "doc.on.clipboard")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .frame(height: 30)
                        .background(KeyboardTheme.ready, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("paste-clipboard")
            }
        }
    }

    private var message: some View {
        VStack(alignment: model.isWide ? .leading : .center, spacing: 2) {
            Text(model.headline)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(KeyboardTheme.text(scheme))
                .lineLimit(2)
                .truncationMode(.head)
                .multilineTextAlignment(model.isWide ? .leading : .center)
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
            .background(KeyboardTheme.functionKey(scheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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

/// The big round mic. Blue when ready, red with a ring that follows your
/// voice while listening.
struct MicButton: View {
    @ObservedObject var model: KeyboardModel
    let size: CGFloat

    private var live: Bool { model.phase == .listening }
    private var starting: Bool { model.phase == .starting }
    private var blocked: Bool { model.phase == .needsFullAccess }

    var body: some View {
        Button(action: model.onMic) {
            ZStack {
                if live {
                    Circle()
                        .fill(KeyboardTheme.live.opacity(0.22))
                        .frame(width: size * (1.12 + 0.26 * model.level), height: size * (1.12 + 0.26 * model.level))
                        .animation(.easeOut(duration: 0.12), value: model.level)
                }
                Circle()
                    .fill(live ? KeyboardTheme.live : (blocked ? Color.gray : KeyboardTheme.ready))
                    .frame(width: size, height: size)
                    .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
                if starting {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(size / 50)
                } else {
                    Image(systemName: live ? "stop.fill" : (blocked ? "mic.slash.fill" : "mic.fill"))
                        .font(.system(size: size * 0.36, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: size * 1.4, height: size * 1.4)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(live ? (model.language == .spanish ? "Parar" : "Stop listening")
                            : (model.language == .spanish ? "Dictar" : "Start dictation"))
        .accessibilityIdentifier("mic-button")
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
