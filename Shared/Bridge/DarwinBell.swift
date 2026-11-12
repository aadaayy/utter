import Foundation

/// A doorbell between the app and the keyboard: a system-wide notification
/// with no data in it, rung after each write to the shared folder so the
/// other side reads it right away instead of waiting for its next check.
/// Needs no special permission.
public final class DarwinBell {
    public enum Name: String {
        case outbox = "com.albertoaday.utter.outbox"
        case status = "com.albertoaday.utter.status"
        case command = "com.albertoaday.utter.command"
    }

    public static func ring(_ name: Name) {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(center, CFNotificationName(name.rawValue as CFString), nil, nil, true)
    }

    private var handlers: [String: () -> Void] = [:]

    public init() {}

    deinit {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterRemoveEveryObserver(center, Unmanaged.passUnretained(self).toOpaque())
    }

    /// Calls `handler` on the main queue each time `name` rings.
    public func listen(_ name: Name, handler: @escaping () -> Void) {
        handlers[name.rawValue] = handler
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = Unmanaged.passUnretained(self).toOpaque()
        CFNotificationCenterAddObserver(center, observer, { _, observer, name, _, _ in
            guard let observer, let name else { return }
            let bell = Unmanaged<DarwinBell>.fromOpaque(observer).takeUnretainedValue()
            let key = name.rawValue as String
            DispatchQueue.main.async { bell.handlers[key]?() }
        }, name.rawValue as CFString, nil, .deliverImmediately)
    }
}
