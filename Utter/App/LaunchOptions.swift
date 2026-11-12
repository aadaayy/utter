import CoreGraphics
import Foundation
import SwiftUI

/// Settings the automatic checks pass when they launch the app, so the
/// screenshots show the same thing every time. Normal launches use none.
struct LaunchOptions {
    /// Never touch the mic or the real shared folder; show sample states.
    var testing = false
    /// Turn off animations (for steady screenshots).
    var still = false
    /// Which screen to open: home, listening, settings or keyboard.
    var screen = "home"
    /// For the keyboard screen: idle, starting, listening, countdown, typed,
    /// fullaccess, spanish or clipboard.
    var keyboardState = "idle"
    /// For the home screen: fresh (nothing set up yet) or ready (all done).
    var setup = "fresh"
    /// Draw in dark mode.
    var dark = false
    /// Draw the screen at another phone's size (in points), shrunk to fit,
    /// e.g. "-previewSize 951x669" for the open iPhone Duo.
    var previewSize: CGSize?
    /// A bigger text size, as if set in Settings.
    var textSize: DynamicTypeSize?

    static let current = LaunchOptions(arguments: ProcessInfo.processInfo.arguments)

    init(arguments: [String] = []) {
        func value(after flag: String) -> String? {
            guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else { return nil }
            return arguments[index + 1]
        }
        testing = arguments.contains("-uiTesting")
        still = arguments.contains("-still")
        dark = arguments.contains("-dark")
        screen = value(after: "-screen") ?? "home"
        keyboardState = value(after: "-keyboard") ?? "idle"
        setup = value(after: "-setup") ?? "fresh"
        switch value(after: "-textSize") {
        case "xxxLarge": textSize = .xxxLarge
        case "accessibility2": textSize = .accessibility2
        case "accessibility3": textSize = .accessibility3
        default: textSize = nil
        }
        if arguments.contains("-openDuoPreview") {
            previewSize = CGSize(width: 951, height: 669)
        } else if let text = value(after: "-previewSize") {
            let parts = text.split(separator: "x").compactMap { Double($0) }
            if parts.count == 2 { previewSize = CGSize(width: parts[0], height: parts[1]) }
        }
    }
}
