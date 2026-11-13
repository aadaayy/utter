import SwiftUI

/// Utter's look, shared by the app and the keyboard: "midnight glow".
/// Deep midnight backgrounds, frosted glass cards, clean type, and one
/// aurora light (indigo through magenta to amber) that glows brighter while
/// Utter is listening.
public enum Brand {
    // MARK: Aurora, the light of the app

    public static let auroraStart = Color(red: 0.43, green: 0.38, blue: 1.0)   // indigo
    public static let auroraMid = Color(red: 0.86, green: 0.36, blue: 0.86)    // orchid
    public static let auroraEnd = Color(red: 1.0, green: 0.62, blue: 0.40)     // amber
    /// The one colour to use where a gradient can't go.
    public static let aurora = Color(red: 0.70, green: 0.42, blue: 1.0)
    public static var auroraGradient: LinearGradient {
        LinearGradient(colors: [auroraStart, auroraMid, auroraEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    public static var auroraSweep: AngularGradient {
        AngularGradient(colors: [auroraStart, auroraMid, auroraEnd, auroraMid, auroraStart], center: .center)
    }

    // MARK: Surfaces

    /// The night sky behind the app.
    public static let midnight = Color(red: 0.035, green: 0.035, blue: 0.06)
    /// The voice bar's own dark glass, on any keyboard.
    public static let night = Color(red: 0.08, green: 0.08, blue: 0.11)

    /// Main text and the bright buttons: soft white on midnight, near-black on light.
    public static func ink(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.97, green: 0.97, blue: 1.0) : Color(red: 0.06, green: 0.06, blue: 0.09)
    }

    /// What sits on ink (the label on a bright button).
    public static func onInk(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.05, green: 0.05, blue: 0.08) : .white
    }

    /// The page behind everything.
    public static func paper(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? midnight : Color(red: 0.96, green: 0.96, blue: 0.98)
    }

    /// Frosted glass for cards.
    public static func surface(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.8)
    }

    /// Quieter text.
    public static func muted(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.56) : Color.black.opacity(0.5)
    }

    /// Hairlines and quiet fills.
    public static func hairline(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.07)
    }

    /// The light edge on glass: brighter at the top, fading down.
    public static func glassEdge(_ scheme: ColorScheme) -> LinearGradient {
        LinearGradient(colors: scheme == .dark ? [.white.opacity(0.22), .white.opacity(0.04)]
                                               : [.white.opacity(0.9), .black.opacity(0.06)],
                       startPoint: .top, endPoint: .bottom)
    }

    /// Done ticks.
    public static let done = Color(red: 0.36, green: 0.86, blue: 0.62)

    /// Headings: SF Pro, big and confident.
    public static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight)
    }
}

/// The glowing aurora sphere: the heart of Utter. It turns slowly, and swells
/// and brightens with your voice.
public struct AuroraSphere: View {
    var size: CGFloat
    var level: Double
    var active: Bool
    var animated: Bool

    public init(size: CGFloat, level: Double = 0, active: Bool = true, animated: Bool = true) {
        self.size = size
        self.level = level
        self.active = active
        self.animated = animated
    }

    public var body: some View {
        if animated {
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !active)) { context in
                sphere(angle: context.date.timeIntervalSinceReferenceDate * 18)
            }
        } else {
            sphere(angle: 35)
        }
    }

    private func sphere(angle: Double) -> some View {
        let glow = active ? 0.45 + 0.4 * level : 0.0
        return ZStack {
            // Outer bloom.
            Circle()
                .fill(Brand.auroraSweep)
                .blur(radius: size * 0.28)
                .opacity(glow)
                .scaleEffect(1.05 + 0.25 * level)
            // The sphere: swirling colour, softened.
            Circle()
                .fill(active ? AnyShapeStyle(Brand.auroraSweep) : AnyShapeStyle(Color.white.opacity(0.18)))
                .rotationEffect(.degrees(angle))
                .blur(radius: size * 0.06)
                .clipShape(Circle())
            // Depth: dark underside.
            Circle()
                .fill(RadialGradient(colors: [.clear, .black.opacity(0.45)], center: UnitPoint(x: 0.35, y: 0.3),
                                     startRadius: size * 0.15, endRadius: size * 0.62))
            // Glass highlight.
            Ellipse()
                .fill(LinearGradient(colors: [.white.opacity(0.65), .white.opacity(0)], startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.55, height: size * 0.32)
                .offset(x: -size * 0.08, y: -size * 0.24)
                .blur(radius: size * 0.02)
            Circle()
                .strokeBorder(LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0.05)],
                                             startPoint: .top, endPoint: .bottom), lineWidth: max(1, size * 0.012))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Midnight with soft aurora light pooling at the top and a warm glow low down.
public struct Backdrop: View {
    var intensity: Double

    public init(intensity: Double = 1) { self.intensity = intensity }

    public var body: some View {
        ZStack {
            Brand.midnight
            RadialGradient(colors: [Brand.auroraStart.opacity(0.38 * intensity), .clear],
                           center: UnitPoint(x: 0.15, y: -0.05), startRadius: 0, endRadius: 520)
            RadialGradient(colors: [Brand.auroraMid.opacity(0.22 * intensity), .clear],
                           center: UnitPoint(x: 1.0, y: 0.1), startRadius: 0, endRadius: 420)
            RadialGradient(colors: [Brand.auroraEnd.opacity(0.14 * intensity), .clear],
                           center: UnitPoint(x: 0.5, y: 1.1), startRadius: 0, endRadius: 480)
        }
        .ignoresSafeArea()
    }
}

/// A row of bars that follow the mic: low when you're quiet, tall when you talk.
public struct Waveform: View {
    let levels: [Double]
    let color: AnyShapeStyle
    let barWidth: CGFloat
    let spacing: CGFloat

    public init(levels: [Double], color: Color, barWidth: CGFloat = 3, spacing: CGFloat = 3) {
        self.init(levels: levels, style: AnyShapeStyle(color), barWidth: barWidth, spacing: spacing)
    }

    public init(levels: [Double], style: AnyShapeStyle, barWidth: CGFloat = 3, spacing: CGFloat = 3) {
        self.levels = levels
        self.color = style
        self.barWidth = barWidth
        self.spacing = spacing
    }

    public var body: some View {
        GeometryReader { geometry in
            let count = max(1, Int((geometry.size.width + spacing) / (barWidth + spacing)))
            let shown = Self.resample(levels, to: count)
            // One fill across the whole row, cut into bars, so a gradient runs
            // from the first bar to the last.
            Rectangle()
                .fill(color)
                .mask(
                    HStack(alignment: .center, spacing: spacing) {
                        ForEach(0..<count, id: \.self) { index in
                            Capsule()
                                .frame(width: barWidth,
                                       height: max(barWidth, geometry.size.height * (0.12 + 0.88 * shown[index])))
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                )
            .animation(.easeOut(duration: 0.12), value: levels)
        }
        .accessibilityHidden(true)
    }

    /// A steady, speech-like pattern for the screenshots: quiet on the left,
    /// louder toward now. `loudness` near 0 draws a near-flat line.
    public static func sampleLevels(count: Int, loudness: Double) -> [Double] {
        (0..<count).map { index in
            let t = Double(index)
            let syllables = abs(sin(t * 0.9)) * 0.6 + abs(sin(t * 0.37 + 1.3)) * 0.4
            let ramp = 0.35 + 0.65 * Double(index) / Double(max(count - 1, 1))
            return min(1, max(0, loudness * syllables * ramp * 1.5))
        }
    }

    /// Stretches or squeezes the level history to the number of bars that fit,
    /// newest on the right.
    static func resample(_ levels: [Double], to count: Int) -> [Double] {
        guard !levels.isEmpty else { return Array(repeating: 0, count: count) }
        return (0..<count).map { index in
            let position = Double(index) / Double(max(count - 1, 1)) * Double(levels.count - 1)
            return min(1, max(0, levels[Int(position.rounded())]))
        }
    }
}
