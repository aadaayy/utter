import SwiftUI

/// Utter's look in the app: warm paper, ink type, New York serif headings, and
/// the ember colour only where the mic is (see Brand).
enum Theme {
    static let accent = Brand.ember
    static let done = Brand.done
}

/// A soft card on the paper background.
struct Card<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) { content }
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Brand.surface(scheme), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Brand.hairline(scheme), lineWidth: 0.5))
            .shadow(color: .black.opacity(scheme == .dark ? 0 : 0.04), radius: 12, y: 4)
    }
}

/// Small caps over a card's content: "SET UP", "TRY IT".
struct Eyebrow: View {
    let text: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .tracking(1.2)
            .foregroundStyle(Brand.muted(scheme))
    }
}

/// The ember orb with a mic, used on the home screen and while listening.
struct EmberOrb: View {
    var size: CGFloat
    var symbol: String = "mic.fill"
    var dimmed = false

    var body: some View {
        ZStack {
            Circle()
                .fill(dimmed ? AnyShapeStyle(Color.gray.opacity(0.5)) : AnyShapeStyle(Brand.emberGradient))
            Circle()
                .fill(LinearGradient(colors: [.white.opacity(0.35), .clear], startPoint: .top, endPoint: .center))
                .padding(size * 0.04)
            Image(systemName: symbol)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .shadow(color: dimmed ? .clear : Brand.ember.opacity(0.35), radius: size * 0.18, y: size * 0.08)
    }
}

/// A full-width ink pill: the one main action on a screen.
struct InkButtonStyle: ButtonStyle {
    var fill: AnyShapeStyle? = nil
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(fill == nil ? Brand.onInk(scheme) : .white)
            .padding(.horizontal, 22)
            .frame(minHeight: 52)
            .background(fill ?? AnyShapeStyle(Brand.ink(scheme)), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// A quiet pill on a hairline fill, for second actions.
struct QuietButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Brand.ink(scheme))
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .background(Brand.hairline(scheme), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
