import XCTest
@testable import UtterCore

final class SilenceClockTests: XCTestCase {
    let start = Date(timeIntervalSince1970: 1_800_000_000)

    func testStopsAfterOneMinuteOfQuiet() {
        var clock = SilenceClock(startedAt: start)
        XCTAssertFalse(clock.shouldStop(at: start.addingTimeInterval(59)))
        XCTAssertTrue(clock.shouldStop(at: start.addingTimeInterval(60)))
        clock.heardSpeech(at: start.addingTimeInterval(50))
        XCTAssertFalse(clock.shouldStop(at: start.addingTimeInterval(100)), "Talking at 50 s resets the minute")
        XCTAssertTrue(clock.shouldStop(at: start.addingTimeInterval(110)))
    }

    func testCountdownShowsInTheLast15Seconds() {
        let clock = SilenceClock(startedAt: start)
        XCTAssertNil(clock.countdown(at: start.addingTimeInterval(30)))
        XCTAssertEqual(clock.countdown(at: start.addingTimeInterval(45)), 15)
        XCTAssertEqual(clock.countdown(at: start.addingTimeInterval(58.5)), 2)
        XCTAssertNil(clock.countdown(at: start.addingTimeInterval(61)))
    }

    func testOlderSpeechNeverWindsTheClockBack() {
        var clock = SilenceClock(startedAt: start)
        clock.heardSpeech(at: start.addingTimeInterval(20))
        clock.heardSpeech(at: start.addingTimeInterval(10))
        XCTAssertEqual(clock.lastSpeech, start.addingTimeInterval(20))
    }
}

final class CleanupCheckTests: XCTestCase {
    func testAcceptsARealCleanup() {
        XCTAssertEqual(CleanupCheck.accept(model: "Let's meet Wednesday.", for: "um let's meet Tuesday no Wednesday"),
                       "Let's meet Wednesday.")
    }

    func testStripsQuotesAndLabels() {
        XCTAssertEqual(CleanupCheck.accept(model: "\"See you soon.\"", for: "see you soon"), "See you soon.")
        XCTAssertEqual(CleanupCheck.accept(model: "Cleaned text: See you soon.", for: "uh see you soon"), "See you soon.")
    }

    func testRejectsAnAnswerOrATranslation() {
        XCTAssertNil(CleanupCheck.accept(model: "I'm sorry, I can't help with that request today.", for: "what time is it"))
        XCTAssertNil(CleanupCheck.accept(model: "See you tomorrow at the beach.", for: "nos vemos mañana en la playa"))
    }

    func testRejectsEmptyOrTooShort() {
        XCTAssertNil(CleanupCheck.accept(model: "", for: "hello there"))
        XCTAssertNil(CleanupCheck.accept(model: "Ok.", for: "so I went to the store and bought some milk and eggs today"))
    }
}
