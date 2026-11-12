import XCTest

/// Opens every Utter screen on each simulator and saves a screenshot of it.
/// The app shows the same sample text every run (it never touches the mic in
/// these checks), so the pictures can be compared from one build to the next.
final class WalkthroughUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = true
        XCUIDevice.shared.orientation = .portrait
    }

    private static var device: String { ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? "" }
    private static var isDuo: Bool { device.contains("Duo") }

    // MARK: - The app

    /// Home before anything is set up, then with everything ready, in light
    /// and dark.
    @MainActor
    func testHome() throws {
        for (name, extra) in [("01-home-new", ["-setup", "fresh"]),
                              ("02-home-ready", ["-setup", "ready"]),
                              ("03-home-new-dark", ["-setup", "fresh", "-dark"]),
                              ("04-home-ready-dark", ["-setup", "ready", "-dark"])] {
            let app = launch(["-screen", "home"] + extra)
            XCTAssertTrue(app.buttons["listen-button"].waitForExistence(timeout: 20), "\(name): the Start button didn't appear")
            assertOnScreen(app.buttons["listen-button"], in: app, name)
            assertOnScreen(app.buttons["settings-button"], in: app, name)
            sleep(1)
            capture(name)
            if name == "01-home-new" {
                let field = app.textViews["try-field"]
                scrollTo(field, in: app)
                capture("05-home-new-scrolled")
                XCTAssertTrue(app.descendants(matching: .any)["step-1"].exists, "Setup step 1 is missing")
            }
            app.terminate()
        }
    }

    /// Home and the keyboard with the biggest text sizes people pick.
    @MainActor
    func testBigText() throws {
        for (name, size) in [("06-home-bigger-text", "xxxLarge"), ("07-home-biggest-text", "accessibility3")] {
            let app = launch(["-screen", "home", "-setup", "fresh", "-textSize", size])
            XCTAssertTrue(app.buttons["listen-button"].waitForExistence(timeout: 20), "\(name) didn't open")
            assertOnScreen(app.buttons["listen-button"], in: app, name)
            sleep(1)
            capture(name)
            app.terminate()
        }
        let app = launch(["-screen", "keyboard", "-keyboard", "listening", "-textSize", "accessibility3"])
        XCTAssertTrue(app.buttons["mic-button"].waitForExistence(timeout: 20))
        assertKeysOnScreen(app, "08-keyboard-biggest-text")
        sleep(1)
        capture("08-keyboard-biggest-text")
    }

    /// The listening screen the keyboard's mic opens, in each state.
    @MainActor
    func testListening() throws {
        let runs: [(String, [String])] = [
            ("10-listening", []),
            ("11-listening-spanish", ["-keyboard", "spanish"]),
            ("12-listening-stopping-soon", ["-keyboard", "countdown"]),
            ("13-listening-starting", ["-keyboard", "starting"]),
            ("14-listening-mic-off", ["-keyboard", "failed"]),
            ("15-listening-dark", ["-dark"]),
        ]
        for (name, extra) in runs {
            let app = launch(["-screen", "listening"] + extra)
            let stop = app.buttons["stop-button"]
            XCTAssertTrue(stop.waitForExistence(timeout: 20), "\(name): the Stop button didn't appear")
            assertOnScreen(stop, in: app, name)
            sleep(1)
            capture(name)
            if name == "10-listening" {
                let golf = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'golf'")).firstMatch
                XCTAssertTrue(golf.exists, "The sample sentences should show")
            }
            if name == "12-listening-stopping-soon" {
                XCTAssertTrue(app.staticTexts["listening-title"].label.contains("12"),
                              "The countdown should show: \(app.staticTexts["listening-title"].label)")
            }
            app.terminate()
        }
    }

    /// Settings: language, cleanup, voice commands and privacy.
    @MainActor
    func testSettings() throws {
        var app = launch(["-screen", "settings"])
        let picker = app.descendants(matching: .any)["language-picker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 20), "Settings didn't open")
        sleep(1)
        capture("20-settings")
        app.swipeUp(velocity: .slow)
        sleep(1)
        capture("21-settings-scrolled")
        app.terminate()

        app = launch(["-screen", "settings", "-dark"])
        XCTAssertTrue(app.descendants(matching: .any)["language-picker"].waitForExistence(timeout: 20))
        sleep(1)
        capture("22-settings-dark")
        app.terminate()

        // From Home, the gear opens Settings.
        app = launch(["-screen", "home", "-setup", "ready"])
        XCTAssertTrue(app.buttons["settings-button"].waitForExistence(timeout: 20))
        app.buttons["settings-button"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["language-picker"].waitForExistence(timeout: 5),
                      "The gear should open Settings")
    }

    // MARK: - The keyboard

    /// The voice keyboard in every state, drawn under a sample message, in
    /// light and dark.
    @MainActor
    func testKeyboard() throws {
        let states: [(String, String)] = [
            ("30-keyboard-ready", "idle"),
            ("31-keyboard-starting", "starting"),
            ("32-keyboard-listening", "listening"),
            ("33-keyboard-typed", "typed"),
            ("34-keyboard-stopping-soon", "countdown"),
            ("35-keyboard-spanish", "spanish"),
            ("36-keyboard-needs-full-access", "fullaccess"),
            ("37-keyboard-clipboard", "clipboard"),
        ]
        for dark in [false, true] {
            for (name, state) in states {
                let shot = dark ? name.replacingOccurrences(of: "keyboard-", with: "keyboard-dark-") : name
                let app = launch(["-screen", "keyboard", "-keyboard", state] + (dark ? ["-dark"] : []))
                XCTAssertTrue(app.buttons["mic-button"].waitForExistence(timeout: 20), "\(shot): the mic didn't appear")
                assertKeysOnScreen(app, shot)
                sleep(1)
                capture(shot)
                if !dark && state == "spanish" {
                    XCTAssertTrue(app.buttons["language-chip"].label.contains("ES") || app.buttons["language-chip"].label.contains("Español"),
                                  "The language chip should say Spanish: \(app.buttons["language-chip"].label)")
                }
                if !dark && state == "typed" {
                    XCTAssertTrue(app.buttons["undo-cleanup"].exists, "Typed text should offer the raw words")
                }
                app.terminate()
            }
        }
    }

    // MARK: - The iPhone Duo

    /// The open iPhone Duo. The checks can't unfold the simulator, so the app
    /// draws itself at the open Duo's size, shrunk to fit.
    @MainActor
    func testOpenDuo() throws {
        try XCTSkipUnless(Self.isDuo, "Shown on the Duo simulator")
        let runs: [(String, [String], String)] = [
            ("40-open-duo-home", ["-screen", "home", "-setup", "fresh"], "listen-button"),
            ("41-open-duo-home-ready", ["-screen", "home", "-setup", "ready", "-dark"], "listen-button"),
            ("42-open-duo-listening", ["-screen", "listening"], "stop-button"),
            ("43-open-duo-settings", ["-screen", "settings"], ""),
            ("44-open-duo-keyboard", ["-screen", "keyboard", "-keyboard", "idle"], "mic-button"),
            ("45-open-duo-keyboard-listening", ["-screen", "keyboard", "-keyboard", "listening"], "mic-button"),
            ("46-open-duo-keyboard-dark", ["-screen", "keyboard", "-keyboard", "typed", "-dark"], "mic-button"),
        ]
        for (name, extra, button) in runs {
            let app = launch(["-openDuoPreview"] + extra)
            if button.isEmpty {
                XCTAssertTrue(app.descendants(matching: .any)["language-picker"].waitForExistence(timeout: 20), "\(name) didn't open")
            } else {
                XCTAssertTrue(app.buttons[button].waitForExistence(timeout: 20), "\(name) didn't open")
            }
            sleep(2)
            capture(name)
            app.terminate()
        }
    }

    /// The folded Duo held sideways: the app turns with it.
    @MainActor
    func testFoldedDuoSideways() throws {
        try XCTSkipUnless(Self.isDuo, "Shown on the Duo simulator")
        XCUIDevice.shared.orientation = .landscapeLeft
        var app = launch(["-screen", "home", "-setup", "ready"])
        XCTAssertTrue(app.buttons["listen-button"].waitForExistence(timeout: 20))
        sleep(2)
        capture("47-duo-sideways-home")
        app.terminate()
        app = launch(["-screen", "keyboard", "-keyboard", "listening"])
        XCTAssertTrue(app.buttons["mic-button"].waitForExistence(timeout: 20))
        assertKeysOnScreen(app, "48-duo-sideways-keyboard")
        sleep(2)
        capture("48-duo-sideways-keyboard")
        XCUIDevice.shared.orientation = .portrait
    }

    /// Regular iPhones stay upright: turned on its side, the app doesn't turn.
    @MainActor
    func testPhonesStayUpright() throws {
        try XCTSkipIf(Self.isDuo, "The Duo turns freely")
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = launch(["-screen", "home", "-setup", "ready"])
        XCTAssertTrue(app.buttons["listen-button"].waitForExistence(timeout: 20))
        sleep(2)
        let window = app.windows.firstMatch.frame
        XCTAssertGreaterThan(window.height, window.width, "The app should stay upright on a regular iPhone")
        capture("50-phone-held-sideways")
        XCUIDevice.shared.orientation = .portrait
    }

    // MARK: - Helpers

    @MainActor
    private func launch(_ arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-still"] + arguments
        if app.state != .notRunning {
            app.terminate()
            _ = app.wait(for: .notRunning, timeout: 15)
        }
        app.launch()
        return app
    }

    /// The mic and the keys along the bottom are all there and whole.
    @MainActor
    private func assertKeysOnScreen(_ app: XCUIApplication, _ name: String) {
        for id in ["mic-button", "space-key", "delete-key", "return-key", "language-chip"] {
            let element = app.buttons[id]
            XCTAssertTrue(element.exists, "\(name): \(id) is missing")
            assertOnScreen(element, in: app, name)
        }
        // The mic is the biggest target on the keyboard.
        let mic = app.buttons["mic-button"].frame, space = app.buttons["space-key"].frame
        XCTAssertGreaterThanOrEqual(mic.height, space.height, "\(name): the mic should be at least as tall as the space bar")
    }

    @MainActor
    private func assertOnScreen(_ element: XCUIElement, in app: XCUIApplication, _ name: String) {
        guard element.exists else { return }
        let screen = app.windows.firstMatch.frame.insetBy(dx: -1, dy: -1)
        XCTAssertTrue(screen.contains(element.frame), "\(name): \(element.identifier) is cut off: \(element.frame) on \(screen)")
    }

    /// Swipes up until the element is fully on screen (or gives up).
    @MainActor
    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication, tries: Int = 6) {
        let screen = app.windows.firstMatch.frame
        for _ in 0..<tries {
            if element.exists, screen.insetBy(dx: 0, dy: 90).contains(element.frame) { break }
            app.swipeUp(velocity: .slow)
        }
        sleep(1)
    }

    @MainActor
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
