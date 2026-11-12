import Foundation

/// How a cleaned sentence goes in next to what's already typed.
public enum Insertion {
    /// The text to type: a space first unless the cursor is at the start of the
    /// field, after a space or line break, or after an opening bracket or quote.
    public static func text(_ segment: String, after before: String?) -> String {
        guard !segment.isEmpty else { return "" }
        if segment.first == "\n" { return segment }
        guard let before, let last = before.last else { return segment }
        if last.isWhitespace || last.isNewline || "([{\"'“‘¿¡".contains(last) { return segment }
        return " " + segment
    }

    /// Whether the text just before the cursor still ends with what Utter typed,
    /// so "undo cleanup" can swap it safely.
    public static func canReplace(_ inserted: String, before: String?) -> Bool {
        guard !inserted.isEmpty, let before else { return false }
        return before.hasSuffix(inserted)
    }
}
