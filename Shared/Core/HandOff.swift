import Foundation

/// The messages the app and the keyboard leave for each other in the shared
/// folder. Plain Codable values, so the rules are tested without a phone.

/// One stretch of speech, ready to type.
public struct Segment: Codable, Equatable, Identifiable, Sendable {
    public var id: Int
    /// The words as heard.
    public var raw: String
    /// After cleanup (equal to raw when cleanup is off or changed nothing).
    public var clean: String
    public var language: DictationLanguage
    public var createdAt: Date

    public init(id: Int, raw: String, clean: String, language: DictationLanguage, createdAt: Date) {
        self.id = id
        self.raw = raw
        self.clean = clean
        self.language = language
        self.createdAt = createdAt
    }
}

/// The app's list of sentences, newest last.
public struct Outbox: Codable, Equatable, Sendable {
    public static let keep = 30
    /// Sentences older than this aren't typed when a keyboard shows up later.
    public static let maxAge: TimeInterval = 10 * 60

    public var segments: [Segment] = []
    public var nextID: Int = 1

    public init(segments: [Segment] = [], nextID: Int = 1) {
        self.segments = segments
        self.nextID = nextID
    }

    @discardableResult
    public mutating func append(raw: String, clean: String, language: DictationLanguage, at date: Date) -> Segment {
        let segment = Segment(id: nextID, raw: raw, clean: clean, language: language, createdAt: date)
        nextID += 1
        segments.append(segment)
        if segments.count > Outbox.keep { segments.removeFirst(segments.count - Outbox.keep) }
        return segment
    }

    /// What the keyboard still has to type, oldest first.
    public func pending(after delivered: Int, now: Date) -> [Segment] {
        segments.filter { $0.id > delivered && now.timeIntervalSince($0.createdAt) <= Outbox.maxAge }
    }

    /// The newest id, so a keyboard can skip anything stale.
    public var lastID: Int { segments.last?.id ?? 0 }
}

/// What the app is doing right now, rewritten a few times a second while it listens.
public struct ListenerStatus: Codable, Equatable, Sendable {
    public enum State: String, Codable, Sendable {
        case idle, starting, listening, stopping, failed
    }

    public var state: State
    public var language: DictationLanguage
    /// The words being heard right now, before the sentence is finished.
    public var partial: String
    /// Mic level from 0 to 1, for the keyboard's ring.
    public var level: Double
    /// Seconds left before the mic stops, once the quiet has gone on a while.
    public var countdown: Int?
    /// A short line for the keyboard when something went wrong.
    public var problem: String?
    public var updatedAt: Date

    public init(state: State, language: DictationLanguage, partial: String = "", level: Double = 0,
                countdown: Int? = nil, problem: String? = nil, updatedAt: Date) {
        self.state = state
        self.language = language
        self.partial = partial
        self.level = level
        self.countdown = countdown
        self.problem = problem
        self.updatedAt = updatedAt
    }

    /// The app rewrites this at least every second while it listens; anything
    /// older means it was closed or stopped without saying so.
    public static let staleAfter: TimeInterval = 4

    public func isLive(at date: Date) -> Bool {
        (state == .listening || state == .starting) && date.timeIntervalSince(updatedAt) < ListenerStatus.staleAfter
    }
}

/// A request from the keyboard to the app while it's listening.
public struct KeyboardCommand: Codable, Equatable, Sendable {
    public enum Action: String, Codable, Sendable { case stop, switchLanguage }
    public var id: UUID
    public var action: Action
    public var language: DictationLanguage?
    public var issuedAt: Date

    public init(id: UUID = UUID(), action: Action, language: DictationLanguage? = nil, issuedAt: Date) {
        self.id = id
        self.action = action
        self.language = language
        self.issuedAt = issuedAt
    }

    /// A command only counts for a few seconds, so an old one never stops a new session.
    public func isFresh(at date: Date) -> Bool { date.timeIntervalSince(issuedAt) < 10 }
}

/// The keyboard says hello each time it opens, so the app's setup list can tick
/// "Keyboard added" and "Full Access on".
public struct KeyboardPresence: Codable, Equatable, Sendable {
    public var lastSeen: Date
    public var fullAccess: Bool

    public init(lastSeen: Date, fullAccess: Bool) {
        self.lastSeen = lastSeen
        self.fullAccess = fullAccess
    }
}

/// Settings both sides read.
public struct UtterSettings: Codable, Equatable, Sendable {
    public var language: DictationLanguage = .english
    /// Remove fillers, apply corrections, punctuate. Off types the words as spoken.
    public var cleanup: Bool = true

    public init(language: DictationLanguage = .english, cleanup: Bool = true) {
        self.language = language
        self.cleanup = cleanup
    }
}
