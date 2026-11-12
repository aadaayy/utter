import Foundation

/// Guards against the on-device model doing more than cleanup: answering the
/// text, translating it, or adding words. If its answer fails these checks,
/// Utter uses the rules-only cleanup instead.
public enum CleanupCheck {
    public static func accept(model output: String, for input: String) -> String? {
        var text = output.trimmingCharacters(in: .whitespacesAndNewlines)
        // Models like to wrap answers in quotes or a label.
        for label in ["Cleaned text:", "Texto limpio:", "Text:", "Texto:"] where text.hasPrefix(label) {
            text = String(text.dropFirst(label.count)).trimmingCharacters(in: .whitespaces)
        }
        if text.count >= 2, let first = text.first, let last = text.last,
           (first == "\"" && last == "\"") || (first == "“" && last == "”") {
            text = String(text.dropFirst().dropLast())
        }
        guard !text.isEmpty else { return nil }
        let inWords = words(input), outWords = words(text)
        guard !inWords.isEmpty else { return nil }
        // Cleanup only takes words away (and fixes a few); it never doubles the length.
        if outWords.count > inWords.count + 3 { return nil }
        if Double(outWords.count) < Double(inWords.count) * 0.3 { return nil }
        // Most of its words must be the speaker's own (catches translations and answers).
        let inputSet = Set(inWords)
        let own = outWords.filter { inputSet.contains($0) }.count
        if Double(own) < Double(outWords.count) * 0.7 { return nil }
        return text
    }

    static func words(_ text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }
}
