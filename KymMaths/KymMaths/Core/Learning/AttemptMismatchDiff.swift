import Foundation

// MARK: - PhET Area Builder "You Built..." 2-Miss Structural Mismatch Diff

/// Side-by-side comparison shown after two consecutive misses, never leaking the answer key.
struct AttemptMismatchComparison: Equatable, Sendable {
    let yourAnswer: String
    let whatMatches: String
    let whereItSplits: String
    let tryNext: String
}

enum AttemptMismatchDiff {
    static func compare(
        consecutiveMisses: Int,
        submission: String,
        evaluation: QuestionEvaluationResult,
        question: SchoolMathsQuestion
    ) -> AttemptMismatchComparison? {
        let cleaned = submission.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !evaluation.isPass, consecutiveMisses >= 2, !cleaned.isEmpty else {
            return nil
        }

        let promptLower = question.prompt.lowercased()
        let answerTokens = cleaned
            .split(whereSeparator: \.isNewline)
            .last
            .map(String.init) ?? cleaned
        let shortShown = String(answerTokens.prefix(80))

        let whatMatches: String
        if !evaluation.matchedParts.isEmpty {
            whatMatches = "Already right: \(evaluation.matchedParts.joined(separator: ", "))."
        } else if evaluation.mistake != nil {
            whatMatches = "You reached a clear number or expression we can check line by line."
        } else if cleaned.rangeOfCharacter(from: .decimalDigits) != nil {
            whatMatches = "Your working gives a concrete value rather than leaving it blank."
        } else {
            whatMatches = "You started writing out what the question talks about."
        }

        let whereItSplits: String
        let tryNext: String

        if let slip = evaluation.mistake {
            whereItSplits = "Your answer matches a known slip: \(slip.name.lowercased())."
            tryNext = slip.nextStep
        } else if !evaluation.missingParts.isEmpty {
            whereItSplits = "The question still needs: \(evaluation.missingParts.joined(separator: ", "))."
            tryNext = "Check each part the question asked for, one line at a time."
        } else if let missingUnit = missingRequestedUnit(promptLower: promptLower, answerLower: cleaned.lowercased()) {
            whereItSplits = "The question asks for \(missingUnit), and your line does not show that unit or shape yet."
            tryNext = "Read the last line of the question again and check what unit or form it asks for."
        } else if hasDecimalVsFractionMismatch(promptLower: promptLower, answer: cleaned) {
            whereItSplits = "Your answer is written in a different form (fraction vs decimal or percent) from what was asked."
            tryNext = "Convert your value into the exact form requested in the question."
        } else if expectsNegativeSign(question: question),
                  !cleaned.contains("-"), !cleaned.contains("−") {
            whereItSplits = "This question leads below zero, and your final line carries no minus sign."
            tryNext = "Walk the sign separately from the size of the number."
        } else {
            whereItSplits = "Your line does not yet match the value or simplified form the question checks for."
            tryNext = "Test your working on a smaller set of numbers first, or open the figure to check each piece."
        }

        return AttemptMismatchComparison(
            yourAnswer: shortShown,
            whatMatches: whatMatches,
            whereItSplits: whereItSplits,
            tryNext: tryNext
        )
    }

    private static func missingRequestedUnit(promptLower: String, answerLower: String) -> String? {
        let unitChecks: [(promptNeeds: [String], answerHas: [String], label: String)] = [
            (["cm²", "cm^2", "area"], ["cm", "²", "^2"], "an area unit such as cm²"),
            (["%", "percent"], ["%"], "a percentage (%)"),
            (["°", "angle", "bearing"], ["°", "deg"], "degrees (°)"),
            (["₹", "rupees"], ["₹", "rs", "rupee"], "rupees (₹)")
        ]
        for rule in unitChecks {
            let promptAsks = rule.promptNeeds.contains { promptLower.contains($0) }
            let answerHas = rule.answerHas.contains { answerLower.contains($0) }
            if promptAsks && !answerHas {
                return rule.label
            }
        }
        return nil
    }

    private static func hasDecimalVsFractionMismatch(promptLower: String, answer: String) -> Bool {
        if promptLower.contains("fraction") && answer.contains(".") && !answer.contains("/") {
            return true
        }
        if promptLower.contains("decimal") && answer.contains("/") && !answer.contains(".") {
            return true
        }
        return false
    }

    private static func expectsNegativeSign(question: SchoolMathsQuestion) -> Bool {
        question.answerKey.parts.contains { part in
            part.anyOf.contains(where: matcherExpectsNegative)
        }
    }

    private static func matcherExpectsNegative(_ matcher: AnswerMatcher) -> Bool {
        switch matcher {
        case let .number(value, _, _):
            return value.numerator < 0
        case let .sequence(values, _):
            return values.contains { $0.numerator < 0 }
        case let .form(text):
            return text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("-")
        case let .expression(value, _):
            return value.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("-")
        case .words:
            return false
        case let .all(nested):
            return nested.contains(where: matcherExpectsNegative)
        }
    }
}
