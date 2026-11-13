import SwiftUI

/// Utter's look, shared by the app and the keyboard.
/// Mostly ink and warm paper, with one warm "ember" colour that only shows
/// while Utter is listening, so a glance tells you whether the mic is on.
public enum Brand {
    /// Ember, the listening colour: coral into rose.
    public static let emberTop = Color(red: 1.0, green: 0.45, blue: 0.24)
    public static let emberBottom = Color(red: 0.95, green: 0.19, blue: 0.39)
    public static let ember = Color(red: 0.98, green: 0.31, blue: 0.31)
    public static var emberGradient: LinearGradient {
        LinearGradient(colors: [emberTop, emberBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// Text and the "ready" controls: near-black in light mode, warm white in dark.
    public static func ink(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.96, green: 0.95, blue: 0.93) : Color(red: 0.07, green: 0.07, blue: 0.08)
    }

    /// What sits on ink (the label on a ready button).
    public static func onInk(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.07, green: 0.07, blue: 0.08) : .white
    }

    /// The page behind everything: warm paper, or a soft black.
    public static func paper(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.045, green: 0.045, blue: 0.05) : Color(red: 0.965, green: 0.957, blue: 0.94)
    }

    /// Cards on the paper.
    public static func surface(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.12) : .white
    }

    /// Quieter text.
    public static func muted(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.58) : Color.black.opacity(0.52)
    }

    /// Hairlines and quiet fills.
    public static func hairline(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }

    /// Done ticks.
    public static let done = Color(red: 0.16, green: 0.68, blue: 0.42)

    /// The serif used for headings (Apple's New York), for an editorial feel.
    public static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

/// A row of bars that follow the mic: low when you're quiet, tall when you talk.
public struct Waveform: View {
    let levels: [Double]
    let color: Color
    let barWidth: CGFloat
    let spacing: CGFloat

    public init(levels: [Double], color: Color, barWidth: CGFloat = 3, spacing: CGFloat = 3) {
        self.levels = levels
        self.color = color
        self.barWidth = barWidth
        self.spacing = spacing
    }

    public var body: some View {
        GeometryReader { geometry in
            let count = max(1, Int((geometry.size.width + spacing) / (barWidth + spacing)))
            let shown = Self.resample(levels, to: count)
            HStack(alignment: .center, spacing: spacing) {
                ForEach(0..<count, id: \.self) { index in
                    Capsule()
                        .fill(color)
                        .frame(width: barWidth,
                               height: max(barWidth, geometry.size.height * (0.12 + 0.88 * shown[index])))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
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
