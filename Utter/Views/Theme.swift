import SwiftUI

/// Utter's look in the app: midnight, frosted glass and one aurora light
/// (see Brand). The app always uses this dark look; the keyboard follows the
/// phone's light or dark setting so it sits right with other keyboards.
enum Theme {
    static let accent = Brand.aurora
    static let done = Brand.done
}

/// A frosted glass card.
struct Card<Content: View>: View {
    var padding: CGFloat = 20
    @ViewBuilder var content: Content
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) { content }
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .background(Brand.surface(scheme), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Brand.glassEdge(scheme), lineWidth: 1))
            .shadow(color: .black.opacity(0.35), radius: 24, y: 12)
    }
}

/// Small spaced capitals over a card's content: "SET UP", "TRY IT".
struct Eyebrow: View {
    let text: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .tracking(1.6)
            .foregroundStyle(Brand.muted(scheme))
    }
}

/// A small aurora sphere with a symbol on it.
struct AuroraOrb: View {
    var size: CGFloat
    var symbol: String = "mic.fill"
    var dimmed = false

    var body: some View {
        ZStack {
            AuroraSphere(size: size, level: 0.2, active: !dimmed, animated: false)
            Image(systemName: symbol)
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
        }
        .frame(width: size, height: size)
    }
}

/// The main action on a screen: a bright pill (white on midnight), or an
/// aurora pill while listening.
struct InkButtonStyle: ButtonStyle {
    var fill: AnyShapeStyle? = nil
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(fill == nil ? Brand.onInk(scheme) : .white)
            .padding(.horizontal, 22)
            .frame(minHeight: 54)
            .background(fill ?? AnyShapeStyle(Brand.ink(scheme)), in: Capsule())
            .shadow(color: fill == nil ? .white.opacity(scheme == .dark ? 0.12 : 0) : Brand.aurora.opacity(0.5),
                    radius: 18, y: 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// A glass pill for second actions.
struct QuietButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Brand.ink(scheme))
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .background(Brand.hairline(scheme), in: Capsule())
            .overlay(Capsule().strokeBorder(Brand.glassEdge(scheme), lineWidth: 0.8))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
