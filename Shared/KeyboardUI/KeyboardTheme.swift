import SwiftUI

/// Colours for the keyboard, close to the system keyboard so it feels at home,
/// in both light and dark mode.
enum KeyboardTheme {
    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.12) : Color(red: 0.82, green: 0.84, blue: 0.86)
    }

    static func key(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.36, green: 0.36, blue: 0.38) : .white
    }

    /// The darker keys (delete, return, globe) like on Apple's keyboard.
    static func functionKey(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.24, green: 0.24, blue: 0.26) : Color(red: 0.67, green: 0.69, blue: 0.73)
    }

    static func keyShadow(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .black.opacity(0.45) : Color(red: 0.53, green: 0.54, blue: 0.56)
    }

    static func text(_ scheme: ColorScheme) -> Color { scheme == .dark ? .white : .black }

    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.62) : Color.black.opacity(0.55)
    }

    /// Utter's blue, for the mic when it's ready.
    static let ready = Color(red: 0.18, green: 0.42, blue: 1.0)
    /// Red while listening: tap to stop.
    static let live = Color(red: 1.0, green: 0.27, blue: 0.23)
}
