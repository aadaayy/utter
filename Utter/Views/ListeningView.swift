import SwiftUI

/// What you see for the moment Utter is open after tapping the keyboard's mic:
/// it's listening, and how to get back to your app. Also shows the words as
/// they come in, in case you talk before going back.
struct ListeningView: View {
    let close: () -> Void
    @EnvironmentObject private var engine: DictationEngine

    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width > 700
            ZStack {
                Color(uiColor: .systemBackground).ignoresSafeArea()
                if wide {
                    HStack(spacing: 40) {
                        VStack(spacing: 20) {
                            if showsBackHint { backHint }
                            ring
                            statusText
                            buttons
                        }
                        .frame(maxWidth: .infinity)
                        transcript
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding(28)
                } else {
                    VStack(spacing: 18) {
                        if showsBackHint { backHint }
                        Spacer(minLength: 0)
                        ring
                        statusText
                        transcript
                            .frame(maxHeight: geometry.size.height * 0.3)
                        Spacer(minLength: 0)
                        buttons
                    }
                    .padding(20)
                }
            }
        }
    }

    private var spanish: Bool { engine.language == .spanish }
    /// "Go back to your app" only makes sense while Utter is (about to be) listening.
    private var showsBackHint: Bool { engine.isListening }

    private var backHint: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "arrow.up.left")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text(spanish ? "Vuelve a tu app" : "Go back to your app")
                    .font(.headline)
                Text(spanish ? "Toca ◀ arriba a la izquierda, o desliza a la derecha por el borde inferior. Utter sigue escuchando." :
                        "Tap ◀ at the top left, or swipe right along the bottom edge. Utter keeps listening.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Theme.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("back-hint")
    }

    private var ring: some View {
        let live = engine.state == .listening
        return ZStack {
            Circle()
                .fill((live ? Theme.live : Theme.blue).opacity(0.15))
                .frame(width: 150 + 60 * engine.level, height: 150 + 60 * engine.level)
                .animation(.easeOut(duration: 0.15), value: engine.level)
            Circle()
                .fill(live ? Theme.live : (engine.state == .failed ? Color.gray : Theme.blue))
                .frame(width: 120, height: 120)
            if engine.state == .starting {
                ProgressView().tint(.white).scaleEffect(1.4)
            } else {
                Image(systemName: engine.state == .failed ? "mic.slash.fill" : "mic.fill")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 210, height: 210)
        .accessibilityHidden(true)
    }

    private var statusText: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("listening-title")
            if let line = subtitle {
                Text(line)
                    .font(.subheadline)
                    .foregroundStyle(engine.problem != nil ? .orange : .secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var title: String {
        switch engine.state {
        case .starting: return spanish ? "Preparando el micrófono…" : "Starting the mic…"
        case .listening:
            if let countdown = engine.countdown { return spanish ? "Se detiene en \(countdown) s" : "Stopping in \(countdown) s" }
            return spanish ? "Escuchando en español" : "Listening in English"
        case .failed: return spanish ? "No pudo empezar" : "Couldn't start"
        default: return spanish ? "Listo" : "Stopped"
        }
    }

    private var subtitle: String? {
        if let problem = engine.problem { return problem }
        switch engine.state {
        case .listening:
            return engine.countdown != nil ? (spanish ? "Habla para seguir." : "Keep talking to keep going.") :
                (spanish ? "Se apaga tras 1 minuto de silencio." : "Stops after 1 minute of quiet.")
        case .idle: return spanish ? "El micrófono está apagado." : "The mic is off."
        default: return nil
        }
    }

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(engine.sentences) { sentence in
                        Text(sentence.clean)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if !engine.partial.isEmpty {
                        Text(engine.partial)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id("partial")
                    }
                }
                .font(.body)
                .padding(14)
            }
            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(engine.sentences.isEmpty && engine.partial.isEmpty ? 0 : 1)
            .onChange(of: engine.partial) { _, _ in proxy.scrollTo("partial", anchor: .bottom) }
            .accessibilityIdentifier("transcript")
        }
    }

    private var buttons: some View {
        HStack(spacing: 12) {
            if engine.state == .failed {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                } label: {
                    Text(spanish ? "Ajustes" : "Settings")
                        .font(.headline)
                        .frame(minWidth: 110, minHeight: 50)
                        .background(Color(uiColor: .tertiarySystemFill), in: Capsule())
                        .foregroundStyle(.primary)
                }
                .accessibilityIdentifier("open-settings")
            } else {
                Button {
                    engine.setLanguage(engine.language.toggled)
                } label: {
                    Text(engine.language == .english ? "EN → ES" : "ES → EN")
                        .font(.headline)
                        .frame(minWidth: 96, minHeight: 50)
                        .background(Color(uiColor: .tertiarySystemFill), in: Capsule())
                        .foregroundStyle(.primary)
                }
                .accessibilityLabel(engine.language == .english ? "Switch to Spanish" : "Cambiar a inglés")
                .accessibilityIdentifier("switch-language")
            }

            Button {
                if engine.isListening {
                    Task { await engine.stop() }
                } else {
                    close()
                }
            } label: {
                Text(engine.isListening ? (spanish ? "Parar" : "Stop") : (spanish ? "Cerrar" : "Done"))
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(engine.isListening ? Theme.live : Theme.blue, in: Capsule())
                    .foregroundStyle(.white)
            }
            .accessibilityIdentifier("stop-button")
        }
        .frame(maxWidth: 420)
    }
}
