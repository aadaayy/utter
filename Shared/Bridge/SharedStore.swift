import Foundation

/// The shared folder (an App Group) the app and the keyboard both read and
/// write. Each message is a small JSON file, written whole, so a reader never
/// sees half of one.
///
/// The keyboard can only reach this folder once "Allow Full Access" is on.
/// If the App Group itself is missing (for example the free Apple ID refused
/// it), `isAvailable` is false and both sides fall back to the clipboard.
public final class SharedStore {
    public static let shared = SharedStore()

    /// The App Group name comes from the Info.plist (set in the Xcode project),
    /// so changing the bundle prefix changes it everywhere at once.
    public static var groupID: String {
        (Bundle.main.object(forInfoDictionaryKey: "UtterAppGroup") as? String) ?? "group.com.albertoaday.utter"
    }

    public let folder: URL?
    public var isAvailable: Bool { folder != nil }

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()

    public init(folder: URL? = SharedStore.groupFolder()) {
        self.folder = folder
        if let folder { try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true) }
    }

    /// For the automatic checks: a private folder, so runs never share state.
    public static func testing() -> SharedStore {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("utter-checks", isDirectory: true)
        try? FileManager.default.removeItem(at: folder)
        return SharedStore(folder: folder)
    }

    public static func groupFolder() -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)?
            .appendingPathComponent("Utter", isDirectory: true)
    }

    // MARK: Files

    enum File: String {
        case outbox, status, command, presence, settings, delivered
    }

    func read<Value: Decodable>(_ file: File, as type: Value.Type) -> Value? {
        guard let url = folder?.appendingPathComponent(file.rawValue + ".json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    func write<Value: Encodable>(_ value: Value, to file: File) {
        guard let url = folder?.appendingPathComponent(file.rawValue + ".json"),
              let data = try? encoder.encode(value) else { return }
        try? data.write(to: url, options: [.atomic])
    }

    // MARK: Typed access

    public var outbox: Outbox {
        get { read(.outbox, as: Outbox.self) ?? Outbox() }
        set { write(newValue, to: .outbox) }
    }

    public var status: ListenerStatus? {
        get { read(.status, as: ListenerStatus.self) }
        set { if let newValue { write(newValue, to: .status) } }
    }

    public var command: KeyboardCommand? {
        get { read(.command, as: KeyboardCommand.self) }
        set { if let newValue { write(newValue, to: .command) } }
    }

    public var presence: KeyboardPresence? {
        get { read(.presence, as: KeyboardPresence.self) }
        set { if let newValue { write(newValue, to: .presence) } }
    }

    public var settings: UtterSettings {
        get { read(.settings, as: UtterSettings.self) ?? UtterSettings() }
        set { write(newValue, to: .settings) }
    }

    /// The newest sentence id the keyboard has typed.
    public var delivered: Int {
        get { read(.delivered, as: Int.self) ?? 0 }
        set { write(newValue, to: .delivered) }
    }
}
