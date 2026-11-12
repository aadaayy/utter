import XCTest
@testable import UtterCore

final class RuleCleanerTests: XCTestCase {
    func testRemovesEnglishFillers() {
        XCTAssertEqual(RuleCleaner.clean("um so I was thinking uh we could go", language: .english),
                       "So I was thinking we could go.")
        XCTAssertEqual(RuleCleaner.clean("So, um, we went home", language: .english), "So, we went home.")
    }

    func testRemovesSpanishFillers() {
        XCTAssertEqual(RuleCleaner.clean("eh vamos a la playa mañana", language: .spanish),
                       "Vamos a la playa mañana.")
    }

    func testKeepsFillersWhenCleanupIsOff() {
        XCTAssertEqual(RuleCleaner.clean("um so we went", language: .english, full: false), "Um so we went.")
    }

    func testRemovesStuttersButKeepsRealDoubles() {
        XCTAssertEqual(RuleCleaner.clean("I think the the plan works", language: .english), "I think the plan works.")
        XCTAssertEqual(RuleCleaner.clean("I had had enough", language: .english), "I had had enough.")
        XCTAssertEqual(RuleCleaner.clean("no no no", language: .spanish), "No no no.")
    }

    func testCapitalizesSentencesAndI() {
        XCTAssertEqual(RuleCleaner.clean("i'm here. are you coming? yes", language: .english),
                       "I'm here. Are you coming? Yes.")
    }

    func testKeepsQuestionMarks() {
        XCTAssertEqual(RuleCleaner.clean("are you coming?", language: .english), "Are you coming?")
        XCTAssertEqual(RuleCleaner.clean("¿vienes mañana?", language: .spanish), "¿Vienes mañana?")
    }

    func testScratchThat() {
        XCTAssertEqual(RuleCleaner.clean("meet at noon scratch that meet at one", language: .english), "Meet at one.")
        XCTAssertEqual(RuleCleaner.clean("a las dos borra eso a las tres", language: .spanish), "A las tres.")
    }

    func testSpokenLineBreaks() {
        XCTAssertEqual(RuleCleaner.clean("hi Sam new line see you soon", language: .english), "Hi Sam\nSee you soon.")
        XCTAssertEqual(RuleCleaner.clean("hola nuevo párrafo gracias", language: .spanish), "Hola\n\nGracias.")
    }

    func testFixesSpacingAroundPunctuation() {
        XCTAssertEqual(RuleCleaner.clean("well , okay  then", language: .english), "Well, okay then.")
    }

    func testEmptyStaysEmpty() {
        XCTAssertEqual(RuleCleaner.clean("   ", language: .english), "")
        XCTAssertEqual(RuleCleaner.clean("um uh", language: .english), "")
    }
}
