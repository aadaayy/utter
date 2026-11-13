import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var engine: DictationEngine
    @State private var settings = UtterSettings()
    @State private var loaded = false
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Form {
            Section {
                Picker("Language", selection: $settings.language) {
                    ForEach(DictationLanguage.allCases, id: \.self) { language in
                        Text(language.name).tag(language)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("language-picker")
            } header: {
                Text("Language")
            } footer: {
                Text("The keyboard's EN/ES key switches too, even while you talk.")
            }

            Section {
                Toggle("Clean up my words", isOn: $settings.cleanup)
                    .accessibilityIdentifier("cleanup-toggle")
                Text(engine.cleaner.modelStatusLine)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Cleanup")
            } footer: {
                Text("Removes um and uh, keeps your corrections (\"Tuesday, no, Wednesday\" becomes \"Wednesday\") and adds punctuation. Off types your words exactly as spoken. Raw words on the keyboard undoes it for one sentence.")
            }

            Section("Listening") {
                LabeledContent("Stops after", value: "1 minute of quiet")
                LabeledContent("Say \"new line\"", value: "starts a new line")
                LabeledContent("Say \"new paragraph\"", value: "skips a line")
                LabeledContent("Say \"scratch that\"", value: "drops that sentence")
                LabeledContent("In Spanish", value: "nueva línea, nuevo párrafo, borra eso")
            }

            Section("Privacy") {
                Text("Your voice and your words never leave this iPhone. Utter has no account and no server, and the keyboard never goes online.")
                    .font(.subheadline)
            }

            Section {
                LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.paper(scheme).ignoresSafeArea())
        .toolbarBackground(Brand.paper(scheme), for: .navigationBar)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !loaded else { return }
            settings = engine.store.settings
            loaded = true
        }
        .onChange(of: settings) { _, newValue in
            guard loaded else { return }
            let languageChanged = newValue.language != engine.store.settings.language
            engine.store.settings = newValue
            if languageChanged { engine.setLanguage(newValue.language) }
        }
    }
}
