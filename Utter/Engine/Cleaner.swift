import Foundation
import FoundationModels

/// Turns what was heard into what you meant to type.
/// 1. Apple's on-device model (when Apple Intelligence is on) removes fillers,
///    keeps your corrections ("Tuesday, no, Wednesday" -> "Wednesday") and
///    punctuates. It gets about 2.5 seconds; if it's slow, refuses, or does
///    more than clean up, Utter skips it.
/// 2. Utter's own rules always run last (fillers, stutters, "new line",
///    "scratch that", capitals, full stop).
/// Nothing leaves the phone.
final class Cleaner {
    static let timeout: Double = 2.5

    static let instructions = """
    You clean up dictated speech so it can be typed as a message. \
    Remove filler words (um, uh, eh, like when used as filler) and repeated words. \
    When the speaker corrects themselves (for example "Tuesday, no, Wednesday" or "at two, I mean three"), keep only the correction. \
    Add punctuation and capital letters. \
    Keep the speaker's own words, meaning and language. Never translate, answer, explain, summarize or add anything. \
    Reply with the cleaned text only.
    """

    /// One session is made ready ahead of time so the first sentence is quick.
    private var readySession: LanguageModelSession?

    /// True when Apple Intelligence is on and its model is ready on this phone.
    var modelAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    /// A short reason when the model can't help, for Settings.
    var modelStatusLine: String {
        switch SystemLanguageModel.default.availability {
        case .available:
            return "On: Apple's on-device model cleans up your words."
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Off: turn on Apple Intelligence in Settings for smarter cleanup. Utter's own rules still remove fillers and add punctuation."
        case .unavailable(.modelNotReady):
            return "Getting ready: Apple's model is still downloading. Utter's own rules clean up until then."
        case .unavailable(.deviceNotEligible):
            return "This iPhone doesn't have Apple Intelligence, so Utter's own rules clean up your words."
        default:
            return "Utter's own rules clean up your words."
        }
    }

    func supports(_ language: DictationLanguage) -> Bool {
        SystemLanguageModel.default.supportsLocale(Locale(identifier: language.localeIdentifier))
    }

    /// Gets the model loaded before the first sentence comes in.
    func prepare() {
        guard modelAvailable, readySession == nil else { return }
        let session = LanguageModelSession(instructions: Self.instructions)
        session.prewarm()
        readySession = session
    }

    func clean(_ raw: String, language: DictationLanguage, enabled: Bool) async -> String {
        let rules = RuleCleaner.clean(raw, language: language, full: enabled)
        let wordCount = raw.split(separator: " ").count
        guard enabled, modelAvailable, supports(language), wordCount >= 3 else { return rules }

        // A fresh session each sentence keeps every request small.
        let session = readySession ?? LanguageModelSession(instructions: Self.instructions)
        readySession = nil
        defer { prepare() }

        let prompt = "Text:\n\(raw)"
        let answer: String? = await withTaskGroup(of: String?.self) { group in
            group.addTask {
                do {
                    let response = try await session.respond(to: prompt, options: GenerationOptions(sampling: .greedy))
                    return response.content
                } catch {
                    return nil
                }
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(Cleaner.timeout * 1_000_000_000))
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
        guard let answer, let accepted = CleanupCheck.accept(model: answer, for: raw) else { return rules }
        return RuleCleaner.clean(accepted, language: language, full: true)
    }
}
