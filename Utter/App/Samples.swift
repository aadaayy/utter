import Foundation

/// The sample states the automatic checks show, so every screenshot run
/// looks the same. Never used on a real launch.
enum Samples {
    static let date = Date(timeIntervalSince1970: 1_794_000_000)

    static let englishSentences: [Segment] = [
        Segment(id: 1, raw: "um hey are we still on for golf tomorrow", clean: "Hey, are we still on for golf tomorrow?",
                language: .english, createdAt: date),
        Segment(id: 2, raw: "let's do the 8 no the 9 30 tee time", clean: "Let's do the 8, no, the 9:30 tee time.",
                language: .english, createdAt: date.addingTimeInterval(6)),
    ]

    static let spanishSentences: [Segment] = [
        Segment(id: 3, raw: "eh mañana llego a las dos no a las tres", clean: "Mañana llego a las dos, no, a las tres.",
                language: .spanish, createdAt: date),
    ]

    @MainActor
    static func apply(_ options: LaunchOptions, to engine: DictationEngine) {
        guard options.screen == "listening" else { return }
        switch options.keyboardState {
        case "spanish":
            engine.showSample(state: .listening, language: .spanish, partial: "y después vamos a cenar",
                              level: 0.55, sentences: spanishSentences)
        case "countdown":
            engine.showSample(state: .listening, language: .english, level: 0.05, countdown: 12,
                              sentences: englishSentences)
        case "failed":
            engine.showSample(state: .failed, language: .english,
                              problem: "Microphone is off for Utter. Turn it on in Settings > Utter.")
        case "starting":
            engine.showSample(state: .starting, language: .english)
        default:
            engine.showSample(state: .listening, language: .english, partial: "and bring the new driver",
                              level: 0.6, sentences: englishSentences)
        }
    }
}
