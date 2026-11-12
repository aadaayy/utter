import Foundation

/// The two languages Utter listens in. One tap on the keyboard switches.
public enum DictationLanguage: String, Codable, CaseIterable, Sendable {
    case english = "en"
    case spanish = "es"

    /// The locale handed to the speech engine (US English, US Spanish).
    public var localeIdentifier: String {
        switch self {
        case .english: return "en-US"
        case .spanish: return "es-US"
        }
    }

    /// What the keyboard's language chip shows.
    public var shortLabel: String {
        switch self {
        case .english: return "EN"
        case .spanish: return "ES"
        }
    }

    /// The language's own name.
    public var name: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        }
    }

    /// The other one, for the keyboard's switch.
    public var toggled: DictationLanguage { self == .english ? .spanish : .english }
}
