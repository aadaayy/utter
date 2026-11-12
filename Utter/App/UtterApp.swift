import SwiftUI
import UIKit

@main
struct UtterApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var engine: DictationEngine
    @StateObject private var setup: SetupChecker
    @State private var route: Route

    enum Route: Equatable { case home, listening, settings, keyboard }

    init() {
        let options = LaunchOptions.current
        let store = options.testing ? SharedStore.testing() : SharedStore.shared
        let engine = DictationEngine(store: store, demo: options.testing)
        let setup = SetupChecker(store: store, engine: engine, sample: options.testing ? options.setup : nil)
        if options.testing { Samples.apply(options, to: engine) }
        _engine = StateObject(wrappedValue: engine)
        _setup = StateObject(wrappedValue: setup)
        switch options.screen {
        case "listening": _route = State(initialValue: .listening)
        case "settings": _route = State(initialValue: .settings)
        case "keyboard": _route = State(initialValue: .keyboard)
        default: _route = State(initialValue: .home)
        }
        if options.still { UIView.setAnimationsEnabled(false) }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let size = LaunchOptions.current.previewSize {
                    ScreenPreview(screen: size) { content }
                } else {
                    content
                }
            }
            .modifier(TextSizeOverride(size: LaunchOptions.current.textSize))
            .preferredColorScheme(LaunchOptions.current.testing ? (LaunchOptions.current.dark ? .dark : .light) : nil)
            .environmentObject(engine)
            .environmentObject(setup)
            .onOpenURL { url in handle(url) }
        }
    }

    @ViewBuilder private var content: some View {
        switch route {
        case .keyboard:
            KeyboardPreviewScreen(state: LaunchOptions.current.keyboardState)
        default:
            RootView(route: $route)
        }
    }

    /// utter://listen?lang=es, from the keyboard's mic.
    private func handle(_ url: URL) {
        guard url.scheme == "utter", url.host == "listen" else { return }
        let code = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "lang" })?.value
        let language = code.flatMap(DictationLanguage.init(rawValue:))
        route = .listening
        Task { await engine.start(language: language) }
    }
}

/// The checks' bigger text size, when they pass one; otherwise the phone's own.
struct TextSizeOverride: ViewModifier {
    let size: DynamicTypeSize?

    func body(content: Content) -> some View {
        if let size { content.dynamicTypeSize(size) } else { content }
    }
}

/// The app drawn at another phone's screen size, shrunk to fit whatever
/// simulator runs it. The automatic checks can't unfold the Duo simulator,
/// so they use this to show the open Duo (about 951 by 669 points).
struct ScreenPreview<Content: View>: View {
    let screen: CGSize
    @ViewBuilder var content: Content

    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width / screen.width, geometry.size.height / screen.height)
            content
                .frame(width: screen.width, height: screen.height)
                .clipped()
                .scaleEffect(scale)
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .background(Color.black)
        .ignoresSafeArea()
    }
}

/// Regular iPhones stay upright. The iPhone Duo turns freely (folded it's
/// nearly square, and open it's already wide).
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        Self.isRegularPhone ? .portrait : .allButUpsideDown
    }

    /// A long, narrow screen (about 2 to 1): every iPhone but the Duo.
    static let isRegularPhone: Bool = {
        let bounds = UIScreen.main.bounds
        let long = max(bounds.width, bounds.height), short = min(bounds.width, bounds.height)
        return long / max(short, 1) > 1.7
    }()
}
