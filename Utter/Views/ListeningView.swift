import SwiftUI

/// What you see for the moment Utter is open after tapping the keyboard's mic:
/// it's listening, and how to get back to your app. Also shows the words as
/// they come in, in case you talk before going back.
struct ListeningView: View {
    let close: () -> Void
    @EnvironmentObject private var engine: DictationEngine
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width > 700
            ZStack {
                Brand.paper(scheme).ignoresSafeArea()
                // A warm glow behind the orb while the mic is on.
                RadialGradient(colors: [Brand.ember.opacity(live ? (scheme == .dark ? 0.28 : 0.18) : 0), .clear],
                               center: wide ? UnitPoint(x: 0.25, y: 0.45) : UnitPoint(x: 0.5, y: 0.38),
                               startRadius: 0, endRadius: wide ? 420 : 340)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.4), value: live)
                if wide {
                    HStack(spacing: 40) {
                        VStack(spacing: 22) {
                            if showsBackHint { backHint }
                            Spacer(minLength: 0)
                            ring
                            wave
                            statusText
                            Spacer(minLength: 0)
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
                        wave
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
    private var live: Bool { engine.state == .listening }
    /// "Go back to your app" only makes sense while Utter is (about to be) listening.
    private var showsBackHint: Bool { engine.isListening }

    private var backHint: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "arrow.up.left")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Brand.onInk(scheme))
                .frame(width: 30, height: 30)
                .background(Brand.ink(scheme), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(spanish ? "Vuelve a tu app" : "Go back to your app")
                    .font(.headline)
                    .foregroundStyle(Brand.ink(scheme))
                Text(spanish ? "Toca ◀ arriba a la izquierda, o desliza a la derecha por el borde inferior. Utter sigue escuchando." :
                        "Tap ◀ at the top left, or swipe right along the bottom edge. Utter keeps listening.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.muted(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Brand.surface(scheme), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Brand.hairline(scheme), lineWidth: 0.5))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("back-hint")
    }

    private var ring: some View {
        ZStack {
            // Two soft halos that breathe with your voice.
            Circle()
                .fill(Brand.ember.opacity(live ? 0.12 : 0))
                .frame(width: 150 + 70 * engine.level, height: 150 + 70 * engine.level)
            Circle()
                .fill(Brand.ember.opacity(live ? 0.18 : 0))
                .frame(width: 128 + 34 * engine.level, height: 128 + 34 * engine.level)
            if engine.state == .starting {
                ProgressView().tint(.white).scaleEffect(1.4)
                    .frame(width: 112, height: 112)
                    .background(Brand.emberGradient, in: Circle())
            } else {
                EmberOrb(size: 112,
                         symbol: engine.state == .failed ? "mic.slash.fill" : (live ? "waveform" : "mic.fill"),
                         dimmed: !live && engine.state != .starting)
            }
        }
        .animation(.easeOut(duration: 0.15), value: engine.level)
        .frame(width: 220, height: 220)
        .accessibilityHidden(true)
    }

    private var wave: some View {
        Waveform(levels: engine.levels, color: Brand.ember, barWidth: 3, spacing: 4)
            .frame(width: 220, height: 36)
            .opacity(live ? 1 : 0)
    }

    private var statusText: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(.title, design: .serif).weight(.semibold))
                .foregroundStyle(Brand.ink(scheme))
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("listening-title")
            if let line = subtitle {
                Text(line)
                    .font(.subheadline)
                    .foregroundStyle(engine.problem != nil ? AnyShapeStyle(Color.orange) : AnyShapeStyle(Brand.muted(scheme)))
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
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(engine.sentences) { sentence in
                        Text(sentence.clean)
                            .foregroundStyle(Brand.ink(scheme))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if !engine.partial.isEmpty {
                        Text(engine.partial)
                            .foregroundStyle(Brand.muted(scheme))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id("partial")
                    }
                }
                .font(.system(.title3, design: .serif))
                .lineSpacing(3)
                .padding(18)
            }
            .background(Brand.surface(scheme), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Brand.hairline(scheme), lineWidth: 0.5))
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
                    Text(spanish ? "Ajustes" : "Settings").frame(minWidth: 96)
                }
                .buttonStyle(QuietButtonStyle())
                .accessibilityIdentifier("open-settings")
            } else {
                Button {
                    engine.setLanguage(engine.language.toggled)
                } label: {
                    HStack(spacing: 2) {
                        segment(.english)
                        segment(.spanish)
                    }
                    .padding(3)
                    .background(Brand.hairline(scheme), in: Capsule())
                }
                .buttonStyle(.plain)
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
                Label(engine.isListening ? (spanish ? "Parar" : "Stop") : (spanish ? "Cerrar" : "Done"),
                      systemImage: engine.isListening ? "stop.fill" : "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(InkButtonStyle())
            .accessibilityIdentifier("stop-button")
        }
        .frame(maxWidth: 420)
    }

    private func segment(_ language: DictationLanguage) -> some View {
        let on = engine.language == language
        return Text(language.shortLabel)
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .tracking(0.6)
            .foregroundStyle(on ? Brand.onInk(scheme) : Brand.muted(scheme))
            .frame(width: 46, height: 40)
            .background(on ? Brand.ink(scheme) : .clear, in: Capsule())
    }
}
