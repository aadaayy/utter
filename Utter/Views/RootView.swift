import SwiftUI

/// Home, with Settings and the listening screen on top of it.
struct RootView: View {
    @Binding var route: UtterApp.Route
    @EnvironmentObject private var engine: DictationEngine

    var body: some View {
        NavigationStack {
            HomeView(openSettings: { route = .settings }, openListening: { route = .listening })
                .navigationDestination(isPresented: Binding(get: { route == .settings },
                                                            set: { if !$0 { route = .home } })) {
                    SettingsView()
                }
        }
        .fullScreenCover(isPresented: Binding(get: { route == .listening },
                                              set: { if !$0 { route = .home } })) {
            ListeningView(close: { route = .home })
        }
    }
}
