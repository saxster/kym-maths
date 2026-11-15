import Foundation

/// Marks a speed-math card. The whole answer must match: a piece of it never passes.
enum SpeedMathAnswerCheck {
    static func isCorrect(typed: String, expected: String) -> Bool {
        let given = normalize(typed)
        let wanted = normalize(expected)
        guard !given.isEmpty else { return false }
        if given == wanted { return true }
        if let a = Double(given), let b = Double(wanted) { return abs(a - b) < 1e-9 }
        return false
    }

    private static func normalize(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: "pi", with: "π")
            .replacingOccurrences(of: "%", with: "")
            .filter { !$0.isWhitespace }
    }
}
