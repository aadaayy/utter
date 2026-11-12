import Foundation

/// Keeps listening while you talk and lets go of the mic after a stretch with
/// no speech (1 minute, Alberto's pick). "Speech" means new words from the
/// speech engine, not sound, so a noisy room doesn't keep the mic on forever.
public struct SilenceClock: Equatable, Sendable {
    public static let defaultLimit: TimeInterval = 60
    /// From this many seconds of quiet, the keyboard shows a countdown.
    public static let warnAfter: TimeInterval = 45

    public let limit: TimeInterval
    public private(set) var lastSpeech: Date

    public init(limit: TimeInterval = SilenceClock.defaultLimit, startedAt: Date) {
        self.limit = limit
        self.lastSpeech = startedAt
    }

    public mutating func heardSpeech(at date: Date) {
        if date > lastSpeech { lastSpeech = date }
    }

    public func silence(at date: Date) -> TimeInterval { max(0, date.timeIntervalSince(lastSpeech)) }

    public func remaining(at date: Date) -> TimeInterval { max(0, limit - silence(at: date)) }

    public func shouldStop(at date: Date) -> Bool { silence(at: date) >= limit }

    /// Seconds left to show, once the quiet has gone on long enough to warn.
    public func countdown(at date: Date) -> Int? {
        guard silence(at: date) >= SilenceClock.warnAfter, !shouldStop(at: date) else { return nil }
        return Int(remaining(at: date).rounded(.up))
    }
}
