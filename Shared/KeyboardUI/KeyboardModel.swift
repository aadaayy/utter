import Combine
import Foundation

/// Everything the keyboard shows. The real keyboard fills it from the shared
/// folder; the app fills it with fixed sample states for the screenshots.
public final class KeyboardModel: ObservableObject {
    public enum Phase: Equatable {
        /// Ready: tap the mic to start.
        case idle
        /// The app is opening and starting the mic.
        case starting
        /// Listening; sentences type themselves.
        case listening
        /// Full Access is off, so the keyboard can't reach the shared folder.
        case needsFullAccess
        /// The shared folder is missing; text comes over the clipboard instead.
        case clipboardOnly
    }

    @Published public var phase: Phase = .idle
    @Published public var language: DictationLanguage = .english
    /// The words being heard right now.
    @Published public var partial: String = ""
    /// Mic level, 0 to 1. Each new level also goes on the end of `levels`.
    @Published public var level: Double = 0 {
        didSet { levels = Array((levels + [level]).suffix(Self.levelHistory)) }
    }
    /// The last few mic levels, oldest first, for the waveform.
    @Published public var levels: [Double] = Array(repeating: 0, count: KeyboardModel.levelHistory)
    public static let levelHistory = 32
    /// Seconds left before the mic lets go, near the end of a quiet minute.
    @Published public var countdown: Int?
    /// A short problem line from the app ("Microphone is off for Utter").
    @Published public var problem: String?
    /// True right after Utter typed a cleaned sentence that differs from the raw words.
    @Published public var canUndoCleanup = false
    /// True while the cleaned sentence has been swapped for the raw words.
    @Published public var showingRaw = false
    /// The open iPhone Duo (or any keyboard wider than 700 points).
    @Published public var isWide = false
    /// iOS decides whether the globe key shows (it hides on phones with a
    /// separate globe button under the keyboard).
    @Published public var showsGlobe = true
    /// What the fake text field shows in the app's screenshots (unused by the real keyboard).
    @Published public var sampleText: String = ""

    public var onMic: () -> Void = {}
    public var onLanguage: () -> Void = {}
    public var onSpace: () -> Void = {}
    public var onDelete: () -> Void = {}
    public var onReturn: () -> Void = {}
    public var onUndoCleanup: () -> Void = {}
    public var onPasteClipboard: () -> Void = {}

    public init() {}

    /// The line above the mic.
    public var headline: String {
        let spanish = language == .spanish
        switch phase {
        case .idle:
            return spanish ? "Habla y se escribe." : "Talk, and it types."
        case .starting:
            return spanish ? "Un momento" : "One moment"
        case .listening:
            if let countdown { return spanish ? "Se detiene en \(countdown) s" : "Stopping in \(countdown) s" }
            if !partial.isEmpty { return partial }
            return spanish ? "Escuchando…" : "Listening…"
        case .needsFullAccess:
            return "Turn on Allow Full Access for Utter"
        case .clipboardOnly:
            return "Utter copied your words"
        }
    }

    /// The smaller line under it.
    public var detail: String? {
        if let problem { return problem }
        let spanish = language == .spanish
        switch phase {
        case .idle:
            return spanish ? "Escribe mientras hablas. Se apaga tras 1 minuto de silencio." :
                "Types as you talk. Stops after 1 minute of quiet."
        case .starting:
            return spanish ? "Luego vuelve aquí con ◀ arriba a la izquierda" : "Then come back with ◀ at the top left"
        case .listening:
            if countdown != nil { return spanish ? "Habla para seguir" : "Keep talking to keep going" }
            return partial.isEmpty ? (spanish ? "Toca para parar" : "Tap to stop") : nil
        case .needsFullAccess:
            return "Settings > General > Keyboard > Keyboards > Utter"
        case .clipboardOnly:
            return "Tap Paste to type them here"
        }
    }

    public var isListening: Bool { phase == .listening || phase == .starting }

    /// The words on the voice bar itself.
    public var barLabel: String {
        let spanish = language == .spanish
        switch phase {
        case .idle, .clipboardOnly: return spanish ? "Toca para hablar" : "Tap to talk"
        case .starting: return spanish ? "Abriendo Utter…" : "Opening Utter…"
        case .listening: return spanish ? "Parar" : "Stop"
        case .needsFullAccess: return spanish ? "Falta acceso total" : "Full Access needed"
        }
    }
}
