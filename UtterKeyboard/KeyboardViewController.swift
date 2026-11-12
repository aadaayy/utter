import SwiftUI
import UIKit

/// The Utter keyboard. It never touches the microphone (iOS doesn't let
/// keyboards); it asks the Utter app to listen, then types each sentence the
/// app leaves in the shared folder.
final class KeyboardViewController: UIInputViewController {
    private let model = KeyboardModel()
    private let bell = DarwinBell()
    private var store: SharedStore = .shared
    private var poll: Timer?
    private var heightConstraint: NSLayoutConstraint?
    /// The last sentence typed, for "undo cleanup".
    private var lastTyped: (segment: Segment, inserted: String, showingRaw: Bool)?
    /// Set when the mic was tapped, so the keyboard shows "Opening Utter…" until the app answers.
    private var startRequestedAt: Date?

    override func viewDidLoad() {
        super.viewDidLoad()
        wireActions()

        let host = UIHostingController(rootView: KeyboardView(model: model) { GlobeKey(controller: self) })
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(host)
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        host.didMove(toParent: self)

        let height = view.heightAnchor.constraint(equalToConstant: KeyboardMetrics.height(forWidth: UIScreen.main.bounds.width))
        height.priority = .init(999)
        height.isActive = true
        heightConstraint = height

        bell.listen(.outbox) { [weak self] in self?.deliverPending() }
        bell.listen(.status) { [weak self] in self?.refreshStatus() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if hasFullAccess && store.isAvailable {
            store.presence = KeyboardPresence(lastSeen: Date(), fullAccess: true)
            model.language = store.settings.language
            // A keyboard that shows up much later shouldn't type old sentences.
            let outbox = store.outbox
            if let newest = outbox.segments.last, Date().timeIntervalSince(newest.createdAt) > Outbox.maxAge {
                store.delivered = max(store.delivered, outbox.lastID)
            }
        }
        refreshStatus()
        deliverPending()
        poll?.invalidate()
        // The doorbell is quick, but a slow check every half second catches anything it misses.
        poll = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.refreshStatus()
            self?.deliverPending()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        poll?.invalidate()
        poll = nil
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let width = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
        model.isWide = width > KeyboardMetrics.wideWidth
        heightConstraint?.constant = KeyboardMetrics.height(forWidth: width)
        model.showsGlobe = needsInputModeSwitchKey
    }

    // MARK: Actions

    private func wireActions() {
        model.onMic = { [weak self] in self?.micTapped() }
        model.onLanguage = { [weak self] in self?.switchLanguage() }
        model.onSpace = { [weak self] in self?.type(" ") }
        model.onDelete = { [weak self] in self?.textDocumentProxy.deleteBackward() }
        model.onReturn = { [weak self] in self?.type("\n") }
        model.onUndoCleanup = { [weak self] in self?.undoCleanup() }
        model.onPasteClipboard = { [weak self] in self?.pasteClipboard() }
    }

    private func type(_ text: String) {
        textDocumentProxy.insertText(text)
        lastTyped = nil
        model.canUndoCleanup = false
    }

    private func micTapped() {
        guard hasFullAccess else {
            model.phase = .needsFullAccess
            return
        }
        let now = Date()
        if store.status?.isLive(at: now) == true {
            store.command = KeyboardCommand(action: .stop, issuedAt: now)
            DarwinBell.ring(.command)
            model.phase = .idle
            model.partial = ""
            return
        }
        // iOS won't let a keyboard use the mic, so the app listens. Open it;
        // it starts the mic and you come back with ◀ at the top left.
        startRequestedAt = now
        model.phase = .starting
        var components = URLComponents()
        components.scheme = "utter"
        components.host = "listen"
        components.queryItems = [URLQueryItem(name: "lang", value: model.language.rawValue)]
        if let url = components.url { openApp(url) }
    }

    private func switchLanguage() {
        let language = model.language.toggled
        model.language = language
        guard hasFullAccess, store.isAvailable else { return }
        var settings = store.settings
        settings.language = language
        store.settings = settings
        if store.status?.isLive(at: Date()) == true {
            store.command = KeyboardCommand(action: .switchLanguage, language: language, issuedAt: Date())
            DarwinBell.ring(.command)
        }
    }

    private func undoCleanup() {
        guard let last = lastTyped,
              Insertion.canReplace(last.inserted, before: textDocumentProxy.documentContextBeforeInput) else {
            model.canUndoCleanup = false
            return
        }
        for _ in 0..<last.inserted.count { textDocumentProxy.deleteBackward() }
        let swapTo = last.showingRaw ? last.segment.clean : last.segment.raw
        let leading = last.inserted.hasPrefix(" ") ? " " : ""
        let text = leading + swapTo
        textDocumentProxy.insertText(text)
        lastTyped = (last.segment, text, !last.showingRaw)
        model.showingRaw = !last.showingRaw
    }

    private func pasteClipboard() {
        guard let text = UIPasteboard.general.string, !text.isEmpty else { return }
        type(Insertion.text(text, after: textDocumentProxy.documentContextBeforeInput))
    }

    // MARK: Hand-off

    private func refreshStatus() {
        guard hasFullAccess else {
            model.phase = .needsFullAccess
            return
        }
        guard store.isAvailable else {
            model.phase = .clipboardOnly
            return
        }
        let now = Date()
        if let status = store.status, status.isLive(at: now) {
            startRequestedAt = nil
            model.phase = .listening
            model.partial = status.partial
            model.level = status.level
            model.countdown = status.countdown
            model.problem = status.problem
            if model.language != status.language { model.language = status.language }
        } else if let asked = startRequestedAt, now.timeIntervalSince(asked) < 20 {
            model.phase = .starting
        } else {
            startRequestedAt = nil
            model.phase = .idle
            model.partial = ""
            model.level = 0
            model.countdown = nil
            // Show why the last session stopped, if it failed.
            if let status = store.status, status.state == .failed, now.timeIntervalSince(status.updatedAt) < 60 {
                model.problem = status.problem
            } else {
                model.problem = nil
            }
        }
    }

    private func deliverPending() {
        guard hasFullAccess, store.isAvailable else { return }
        let delivered = store.delivered
        let pending = store.outbox.pending(after: delivered, now: Date())
        guard !pending.isEmpty else { return }
        // Mark them typed first, so two keyboards (or a quick reopen) never type a sentence twice.
        store.delivered = pending.last!.id
        for segment in pending {
            let text = Insertion.text(segment.clean, after: textDocumentProxy.documentContextBeforeInput)
            textDocumentProxy.insertText(text)
            lastTyped = (segment, text, false)
        }
        model.showingRaw = false
        model.canUndoCleanup = lastTyped.map { $0.segment.raw != $0.segment.clean } ?? false
    }

    /// Keyboards can't call UIApplication.shared, so this walks up to the app
    /// object and asks it to open Utter. It's how dictation keyboards start
    /// their app.
    private func openApp(_ url: URL) {
        var responder: UIResponder? = self
        let selector = NSSelectorFromString("openURL:options:completionHandler:")
        while let current = responder {
            if current.isKind(of: UIApplication.self), current.responds(to: selector),
               let method = class_getInstanceMethod(type(of: current), selector) {
                typealias Open = @convention(c) (AnyObject, Selector, NSURL, NSDictionary, AnyObject?) -> Void
                let open = unsafeBitCast(method_getImplementation(method), to: Open.self)
                open(current, selector, url as NSURL, NSDictionary(), nil)
                return
            }
            responder = current.next
        }
        model.problem = "Open the Utter app to start the mic"
    }
}

/// The globe key, a UIKit button so iOS shows its list of keyboards on a long
/// press, exactly like other keyboards.
struct GlobeKey: UIViewRepresentable {
    let controller: UIInputViewController

    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "globe", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18)), for: .normal)
        button.tintColor = .label
        button.accessibilityLabel = "Next keyboard"
        button.addTarget(controller, action: #selector(UIInputViewController.handleInputModeList(from:with:)), for: .allTouchEvents)
        return button
    }

    func updateUIView(_ uiView: UIButton, context: Context) {}
}
