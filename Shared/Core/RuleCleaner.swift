import Foundation

/// Cleanup that needs no model: filler words, stutters, spoken commands
/// ("new line", "scratch that"), spacing, capitals and the final full stop.
/// It runs on every sentence, after Apple's on-device model when that's
/// available, and on its own when it isn't (or when cleanup is off it does
/// only the light touches: spacing, capitals, full stop).
public enum RuleCleaner {
    /// Sounds that are never words, per language.
    static let fillers: [DictationLanguage: Set<String>] = [
        .english: ["um", "umm", "ummm", "uh", "uhh", "uhm", "uhmm", "er", "erm", "hmm", "hm", "mm", "mmm", "ah"],
        .spanish: ["eh", "ehh", "ehm", "em", "emm", "mm", "mmm", "hmm", "ah"],
    ]

    /// Doubled words people really say twice on purpose.
    static let allowedDoubles: Set<String> = ["had", "that", "no", "bye", "ha", "very", "so", "muy", "sí", "si", "ya", "que"]

    /// Phrases that throw away what came before them in the same stretch of speech.
    static let scratchPhrases = ["scratch that", "borra eso", "bórralo"]

    /// Spoken layout commands.
    static let breaks: [(phrase: String, text: String)] = [
        ("new paragraph", "\n\n"), ("nuevo párrafo", "\n\n"),
        ("new line", "\n"), ("nueva línea", "\n"), ("nueva linea", "\n"),
    ]

    /// Cleans one sentence or stretch of speech.
    /// - Parameter full: false keeps every word as spoken (cleanup off).
    public static func clean(_ text: String, language: DictationLanguage, full: Bool = true) -> String {
        var result = collapseSpaces(text)
        if full {
            result = applyScratch(result)
            result = removeFillers(result, language: language)
            result = removeStutters(result)
        }
        result = applyBreaks(result)
        result = fixPunctuationSpacing(result)
        result = capitalize(result, language: language)
        result = finish(result)
        return result
    }

    // MARK: Steps

    static func collapseSpaces(_ text: String) -> String {
        let lines = text.components(separatedBy: "\n").map { line in
            line.split(whereSeparator: { $0 == " " || $0 == "\t" }).joined(separator: " ")
        }
        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespaces)
    }

    static func applyScratch(_ text: String) -> String {
        var result = text
        for phrase in scratchPhrases {
            if let range = result.range(of: phrase, options: [.caseInsensitive, .backwards]) {
                result = String(result[range.upperBound...])
                    .trimmingCharacters(in: CharacterSet(charactersIn: " ,.;:"))
            }
        }
        return result
    }

    /// Splits into words with any punctuation glued to them ("um," -> core "um", tail ",").
    static func removeFillers(_ text: String, language: DictationLanguage) -> String {
        let fillerSet = fillers[language] ?? []
        var words: [String] = []
        for token in text.split(separator: " ", omittingEmptySubsequences: true).map(String.init) {
            let core = token.lowercased().trimmingCharacters(in: .punctuationCharacters)
            if fillerSet.contains(core) {
                // Keep sentence-ending punctuation the filler carried ("um." ends the sentence).
                if let last = token.last, ".?!".contains(last), let previous = words.popLast() {
                    words.append(previous.trimmingCharacters(in: CharacterSet(charactersIn: ",;:")) + String(last))
                }
                continue
            }
            words.append(token)
        }
        var joined = words.joined(separator: " ")
        // A filler at the very start can leave a dangling comma: ", so we went" -> "so we went".
        joined = joined.trimmingCharacters(in: CharacterSet(charactersIn: ", "))
        return joined
    }

    static func removeStutters(_ text: String) -> String {
        var words: [String] = []
        for token in text.split(separator: " ", omittingEmptySubsequences: true).map(String.init) {
            if let previous = words.last {
                let a = previous.lowercased().trimmingCharacters(in: .punctuationCharacters)
                let b = token.lowercased().trimmingCharacters(in: .punctuationCharacters)
                // Only when the first copy has no punctuation ("the the", not "go. Go").
                let firstIsBare = previous.trimmingCharacters(in: .punctuationCharacters) == previous
                if !a.isEmpty, a == b, firstIsBare, !allowedDoubles.contains(a) {
                    words[words.count - 1] = matchCase(of: previous, to: token)
                    continue
                }
            }
            words.append(token)
        }
        return words.joined(separator: " ")
    }

    /// "The the" -> "The": keeps the first copy's capital with the second copy's punctuation.
    static func matchCase(of first: String, to second: String) -> String {
        guard let f = first.first, f.isUppercase else { return second }
        return second.prefix(1).uppercased() + second.dropFirst()
    }

    static func applyBreaks(_ text: String) -> String {
        var result = text
        for (phrase, replacement) in breaks {
            while let range = result.range(of: phrase, options: .caseInsensitive) {
                // Eat the spaces and commas around the command.
                var lower = range.lowerBound, upper = range.upperBound
                while lower > result.startIndex, " ,".contains(result[result.index(before: lower)]) {
                    lower = result.index(before: lower)
                }
                while upper < result.endIndex, " ,.".contains(result[upper]) {
                    upper = result.index(after: upper)
                }
                result.replaceSubrange(lower..<upper, with: replacement)
            }
        }
        return result
    }

    static func fixPunctuationSpacing(_ text: String) -> String {
        var result = text
        for mark in [",", ".", "?", "!", ";", ":"] {
            result = result.replacingOccurrences(of: " " + mark, with: mark)
        }
        while result.contains(",,") { result = result.replacingOccurrences(of: ",,", with: ",") }
        result = result.replacingOccurrences(of: ",.", with: ".")
        return result
    }

    /// Capital at the start, after . ? ! and after a line break; "i" -> "I" in English.
    static func capitalize(_ text: String, language: DictationLanguage) -> String {
        var output = ""
        var capitalizeNext = true
        for character in text {
            if capitalizeNext, character.isLetter {
                output.append(contentsOf: String(character).uppercased())
                capitalizeNext = false
                continue
            }
            output.append(character)
            if ".?!\n".contains(character) { capitalizeNext = true }
            else if !character.isWhitespace, !"¿¡\"'(".contains(character) { capitalizeNext = false }
        }
        if language == .english {
            var words = output.components(separatedBy: " ")
            for index in words.indices {
                let word = words[index]
                let core = word.trimmingCharacters(in: .punctuationCharacters)
                if core == "i" || core.hasPrefix("i'") || core.hasPrefix("i’") {
                    words[index] = word.replacingOccurrences(of: core, with: "I" + core.dropFirst())
                }
            }
            output = words.joined(separator: " ")
        }
        return output
    }

    /// A full stop when the speech ended on a word.
    static func finish(_ text: String) -> String {
        var result = text
        while result.hasSuffix(" ") || result.hasSuffix(",") { result.removeLast() }
        guard let last = result.last else { return result }
        if last.isLetter || last.isNumber || last == "\"" || last == ")" { result.append(".") }
        return result
    }
}
