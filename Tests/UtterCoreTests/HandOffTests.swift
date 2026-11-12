import XCTest
@testable import UtterCore

final class HandOffTests: XCTestCase {
    let start = Date(timeIntervalSince1970: 1_800_000_000)

    func testInsertionAddsASpaceOnlyWhenNeeded() {
        XCTAssertEqual(Insertion.text("Hello.", after: nil), "Hello.")
        XCTAssertEqual(Insertion.text("Hello.", after: ""), "Hello.")
        XCTAssertEqual(Insertion.text("Hello.", after: "Hi there."), " Hello.")
        XCTAssertEqual(Insertion.text("Hello.", after: "Hi there. "), "Hello.")
        XCTAssertEqual(Insertion.text("Hello.", after: "Note:\n"), "Hello.")
        XCTAssertEqual(Insertion.text("\nNext.", after: "Done."), "\nNext.")
        XCTAssertEqual(Insertion.text("hola", after: "¿"), "hola")
    }

    func testUndoOnlyWhenTheTextIsStillThere() {
        XCTAssertTrue(Insertion.canReplace(" Meet Wednesday.", before: "Hi. Meet Wednesday."))
        XCTAssertFalse(Insertion.canReplace(" Meet Wednesday.", before: "Hi. Meet Wednesday. Ok"))
        XCTAssertFalse(Insertion.canReplace("", before: "Hi"))
    }

    func testOutboxPendingSkipsDeliveredAndStale() {
        var box = Outbox()
        box.append(raw: "a", clean: "A.", language: .english, at: start)
        box.append(raw: "b", clean: "B.", language: .english, at: start.addingTimeInterval(700))
        box.append(raw: "c", clean: "C.", language: .spanish, at: start.addingTimeInterval(720))
        let now = start.addingTimeInterval(730)
        XCTAssertEqual(box.pending(after: 0, now: now).map(\.id), [2, 3], "The first one is over 10 minutes old")
        XCTAssertEqual(box.pending(after: 2, now: now).map(\.id), [3])
        XCTAssertEqual(box.lastID, 3)
    }

    func testOutboxKeepsTheNewestThirty() {
        var box = Outbox()
        for index in 0..<40 { box.append(raw: "\(index)", clean: "\(index)", language: .english, at: start) }
        XCTAssertEqual(box.segments.count, Outbox.keep)
        XCTAssertEqual(box.segments.first?.id, 11)
        XCTAssertEqual(box.nextID, 41)
    }

    func testOutboxRoundTripsAsJSON() throws {
        var box = Outbox()
        box.append(raw: "uh hola", clean: "Hola.", language: .spanish, at: start)
        let data = try JSONEncoder().encode(box)
        XCTAssertEqual(try JSONDecoder().decode(Outbox.self, from: data), box)
    }

    func testStatusGoesStale() {
        let status = ListenerStatus(state: .listening, language: .english, updatedAt: start)
        XCTAssertTrue(status.isLive(at: start.addingTimeInterval(2)))
        XCTAssertFalse(status.isLive(at: start.addingTimeInterval(5)))
        XCTAssertFalse(ListenerStatus(state: .idle, language: .english, updatedAt: start).isLive(at: start))
    }

    func testCommandsExpire() {
        let command = KeyboardCommand(action: .stop, issuedAt: start)
        XCTAssertTrue(command.isFresh(at: start.addingTimeInterval(3)))
        XCTAssertFalse(command.isFresh(at: start.addingTimeInterval(30)))
    }

    func testLanguages() {
        XCTAssertEqual(DictationLanguage.english.toggled, .spanish)
        XCTAssertEqual(DictationLanguage.spanish.localeIdentifier, "es-US")
    }
}
