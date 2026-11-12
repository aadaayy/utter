import SwiftUI

/// For the automatic checks only: the simulator can't add a keyboard, so the
/// app draws the Utter keyboard's real layout under a plain note, in each of
/// its states, at the size the keyboard would have on that phone.
struct KeyboardPreviewScreen: View {
    let state: String
    @StateObject private var model = KeyboardModel()
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = KeyboardMetrics.height(forWidth: width)
            VStack(spacing: 0) {
                note
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.top, geometry.safeAreaInsets.top)
                KeyboardView(model: model) { GlobeIcon() }
                    .frame(height: height)
                // iOS's own strip under the keyboard on phones without a home button.
                systemStrip
                    .frame(height: max(geometry.safeAreaInsets.bottom, 8))
            }
            .ignoresSafeArea()
            .onAppear { configure(width: width) }
        }
        .background(Color(uiColor: .systemBackground))
    }

    private var note: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(model.language == .spanish ? "Para: Carlos" : "To: Mike")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Divider()
            Text("\(model.sampleText)\(Text("|").foregroundStyle(Theme.blue))")
                .font(.body)
                .accessibilityIdentifier("note-text")
        }
        .padding(16)
    }

    private var systemStrip: some View {
        HStack {
            Image(systemName: "globe")
                .font(.system(size: 22))
                .foregroundStyle(KeyboardTheme.text(scheme).opacity(0.8))
                .padding(.leading, 28)
                .opacity(model.showsGlobe ? 0 : 1)
            Spacer()
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(KeyboardTheme.background(scheme))
    }

    private func configure(width: CGFloat) {
        model.isWide = width > KeyboardMetrics.wideWidth
        // Phones with Face ID put the globe under the keyboard, not on it.
        model.showsGlobe = model.isWide
        switch state {
        case "starting":
            model.phase = .starting
        case "listening":
            model.phase = .listening
            model.partial = "and bring the new driver"
            model.level = 0.6
            model.sampleText = "Hey, are we still on for golf tomorrow?"
        case "countdown":
            model.phase = .listening
            model.countdown = 12
            model.level = 0.05
            model.sampleText = "Hey, are we still on for golf tomorrow? Let's do the 9:30 tee time."
        case "typed":
            model.phase = .listening
            model.level = 0.3
            model.canUndoCleanup = true
            model.sampleText = "Hey, are we still on for golf tomorrow? Let's do the 9:30 tee time."
        case "fullaccess":
            model.phase = .needsFullAccess
        case "spanish":
            model.language = .spanish
            model.phase = .listening
            model.partial = "y después vamos a cenar"
            model.level = 0.5
            model.canUndoCleanup = true
            model.sampleText = "Mañana llego a las tres."
        case "clipboard":
            model.phase = .clipboardOnly
        default:
            model.phase = .idle
        }
    }
}
