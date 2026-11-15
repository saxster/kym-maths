import Foundation

/// Where Kym is in a stuck sheet, and what each answer does next.
/// A named slip earns one retry of the same step; any other miss shows the step's working.
enum StuckSheetState: Equatable, Sendable {
    /// Waiting for an answer. `afterRight` shows that the step before was right.
    case asking(step: Int, afterRight: Bool)
    case retrying(step: Int, mistake: KnownMistake)
    /// The working and the answer are showing; Next moves on.
    case shown(step: Int)
    case finished(afterRight: Bool)

    static let start = StuckSheetState.asking(step: 0, afterRight: false)

    var step: Int? {
        switch self {
        case let .asking(step, _), let .retrying(step, _), let .shown(step): step
        case .finished: nil
        }
    }

    func checking(_ answer: String, in sheet: StuckSheet) -> StuckSheetState {
        let canRetry: Bool
        switch self {
        case .asking: canRetry = true
        case .retrying: canRetry = false
        case .shown, .finished: return self
        }
        guard let step, sheet.steps.indices.contains(step) else { return self }
        let marking = sheet.steps[step].answerKey.mark(answer)
        if marking.isCorrect { return Self.after(step, in: sheet, afterRight: true) }
        if canRetry, let mistake = marking.mistake { return .retrying(step: step, mistake: mistake) }
        return .shown(step: step)
    }

    func next(in sheet: StuckSheet) -> StuckSheetState {
        guard case let .shown(step) = self else { return self }
        return Self.after(step, in: sheet, afterRight: false)
    }

    private static func after(_ step: Int, in sheet: StuckSheet, afterRight: Bool) -> StuckSheetState {
        step + 1 < sheet.steps.count ? .asking(step: step + 1, afterRight: afterRight) : .finished(afterRight: afterRight)
    }
}
