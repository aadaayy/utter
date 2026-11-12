import SwiftUI

/// Home, with Settings and the listening screen on top of it. The listening
/// screen is drawn over Home (not presented as a separate window), so it also
/// fits the open-Duo preview the checks draw.
struct RootView: View {
    @Binding var route: UtterApp.Route
    @EnvironmentObject private var engine: DictationEngine

    var body: some View {
        ZStack {
            NavigationStack {
                HomeView(openSettings: { route = .settings }, openListening: { route = .listening })
                    .navigationDestination(isPresented: Binding(get: { route == .settings },
                                                                set: { if !$0 { route = .home } })) {
                        SettingsView()
                    }
            }
            .accessibilityHidden(route == .listening)

            if route == .listening {
                ListeningView(close: { route = .home })
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }
        }
        .animation(LaunchOptions.current.still ? nil : .easeInOut(duration: 0.25), value: route)
    }
}
