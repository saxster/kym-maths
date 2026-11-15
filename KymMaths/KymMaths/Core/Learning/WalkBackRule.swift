import Foundation

/// A named slip that has come back, and the smaller skill to check before Kym tries the question again.
struct WalkBack: Identifiable, Equatable, Sendable {
    let questionId: String
    let misconception: Misconception
    let footing: Footing

    var id: String { "\(questionId)/\(misconception.id)" }
}

/// When a repeated slip sends Kym back to its footing, and when the check of that footing is passed.
enum WalkBackRule {
    static let repeatThreshold = 2
    /// Right answers in a row that show the footing is solid.
    static let rightInARowToPass = 2

    static func recordingSlip(
        _ misconceptionId: String,
        on questionId: String,
        at now: Date,
        onto tally: SlipTally?
    ) -> SlipTally {
        var next = tally ?? SlipTally(
            misconceptionId: misconceptionId,
            sinceCheck: 0,
            total: 0,
            lastQuestionId: questionId,
            lastSeenAt: now
        )
        next.sinceCheck += 1
        next.total += 1
        next.lastQuestionId = questionId
        next.lastSeenAt = now
        return next
    }

    static func isDue(_ tally: SlipTally) -> Bool {
        tally.sinceCheck >= repeatThreshold
    }

    /// A failed check keeps the count, so the next time the slip comes back the walk-back is due again.
    static func recordingCheck(_ tally: SlipTally, passed: Bool, at now: Date) -> SlipTally {
        var next = tally
        next.lastCheckedAt = now
        next.lastCheckPassed = passed
        if passed { next.sinceCheck = 0 }
        return next
    }

    /// Whether the check has ended, and if so whether it passed, given each probe's result so far.
    static func checkOutcome(_ results: [Bool], probeCount: Int) -> Bool? {
        let passed = results.count >= rightInARowToPass && results.suffix(rightInARowToPass).allSatisfy { $0 }
        if passed { return true }
        return results.count >= probeCount ? false : nil
    }
}
