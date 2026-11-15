import Foundation
import Testing
@testable import KymMaths

@Suite("Stuck? Try a smaller one first")
struct StuckSheetTests {
    static let pack = SeedPackLoader.load()

    // MARK: The reaction rule

    static func number(_ text: String) -> AnswerMatcher {
        .number(value: AnswerNumber(text)!, tolerance: 0, simplest: false)
    }

    static let slip = KnownMistake(
        misconception: "sign-of-product",
        name: "You got a sign wrong multiplying or dividing",
        anyOf: [number("6")],
        nextStep: "A negative times a positive is negative.",
        examples: ["6"]
    )

    static let sheet = StuckSheet(
        sister: "Work out (−2) × 3 + 1.",
        steps: [
            StuckStep(
                id: "s-1", prompt: "Work out (−2) × 3.", answer: "−6", working: "(−2) × 3 = −6.",
                answerKey: AnswerKey(parts: [AnswerPart(label: "answer", anyOf: [number("-6")])], accepts: [], rejects: [], mistakes: [slip])
            ),
            StuckStep(
                id: "s-2", prompt: "Add 1.", answer: "−5", working: "−6 + 1 = −5.",
                answerKey: AnswerKey(parts: [AnswerPart(label: "answer", anyOf: [number("-5")])], accepts: [], rejects: [], mistakes: [])
            ),
        ]
    )

    @Test("A right answer moves to the next step and says so, and the last one ends the sheet")
    func rightAdvances() {
        let second = StuckSheetState.start.checking("-6", in: Self.sheet)
        #expect(second == .asking(step: 1, afterRight: true))
        #expect(second.checking("-5", in: Self.sheet) == .finished(afterRight: true))
    }

    @Test("A named slip gives one retry of the same step, and a second miss shows the working")
    func namedSlipRetriesOnce() {
        let retrying = StuckSheetState.start.checking("6", in: Self.sheet)
        #expect(retrying == .retrying(step: 0, mistake: Self.slip))
        #expect(retrying.checking("-6", in: Self.sheet) == .asking(step: 1, afterRight: true))
        #expect(retrying.checking("6", in: Self.sheet) == .shown(step: 0))
        #expect(retrying.checking("12", in: Self.sheet) == .shown(step: 0))
    }

    @Test("A wrong answer with no named slip shows the working, and Next moves on")
    func unnamedMissShowsWorking() {
        let shown = StuckSheetState.start.checking("12", in: Self.sheet)
        #expect(shown == .shown(step: 0))
        #expect(shown.checking("-6", in: Self.sheet) == shown, "the answer is showing, so checking again does nothing")
        #expect(shown.next(in: Self.sheet) == .asking(step: 1, afterRight: false))

        let lastShown = StuckSheetState.asking(step: 1, afterRight: false).checking("5", in: Self.sheet)
        #expect(lastShown == .shown(step: 1))
        #expect(lastShown.next(in: Self.sheet) == .finished(afterRight: false))
        #expect(StuckSheetState.finished(afterRight: false).step == nil)
    }
}
