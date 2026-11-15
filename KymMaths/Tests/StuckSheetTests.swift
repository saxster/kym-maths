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

    @Test("A letter x between two numbers is read as times, and x as a letter still works")
    func letterXBetweenNumbersIsTimes() throws {
        let sheet = try #require(Self.pack.schoolQuestions.first { $0.id == "q-oup-ch01-sb" }?.stuck)
        #expect(sheet.steps[0].answerKey.mark("2^2 x 3").isCorrect)
        #expect(sheet.steps[0].answerKey.mark("2^2x3").isCorrect)
        let line = try #require(Self.pack.schoolQuestions.first { $0.id == "q-oup-ch14-sb" }?.stuck)
        #expect(line.steps[2].answerKey.mark("y = 3x + 6").isCorrect)
    }

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

    // MARK: The sheets in the pack

    static var sheets: [(question: SchoolMathsQuestion, sheet: StuckSheet)] {
        pack.schoolQuestions.compactMap { question in question.stuck.map { (question, $0) } }
    }

    static func givesAway(_ text: String, to key: AnswerKey) -> Bool {
        if key.mark(text).isCorrect { return true }
        let shown = AnswerText(text)
        return key.parts.flatMap(\.anyOf).contains { matcher in
            switch matcher {
            case .words: false
            case let .number(value, tolerance, simplest):
                matcher.matches(shown) || AnswerMatcher.number(value: value.negated(), tolerance: tolerance, simplest: simplest).matches(shown)
            default: matcher.matches(shown)
            }
        }
    }

    @Test("Every question marked by a number, sequence or form has a sheet of 3 to 5 steps")
    func everyMarkedQuestionHasASheet() {
        let worded: Set = ["q-oup-ch03-wb-practice", "q-oup-ch04-wb-practice", "q-oup-ch11-wb-focus"]
        for question in Self.pack.schoolQuestions where !worded.contains(question.id) {
            #expect(question.stuck != nil, "\(question.id) has no stuck sheet")
        }
        #expect(Self.sheets.count == 63)
        for (question, sheet) in Self.sheets {
            #expect((3...5).contains(sheet.steps.count), "\(question.id) has \(sheet.steps.count) steps")
            #expect(sheet.steps.allSatisfy { $0.working.hasSuffix(".") }, "\(question.id) has a working with no full stop")
        }
        let ids = Self.sheets.flatMap { $0.sheet.steps.map(\.id) }
        #expect(Set(ids).count == ids.count)
    }

    @Test("Each step marks its own answer right and its wrong samples wrong")
    func stepsMarkTheirOwnAnswers() {
        for step in Self.sheets.flatMap(\.sheet.steps) {
            let key = step.answerKey
            for answer in [step.answer] + key.accepts {
                let marking = key.mark(answer)
                #expect(marking.isCorrect, "\(step.id) rejects \"\(answer)\"")
                #expect(marking.mistake == nil, "\(step.id) \"\(answer)\" carries a mistake")
            }
            for answer in key.rejects + ["", step.prompt] {
                #expect(!key.mark(answer).isCorrect, "\(step.id) accepts \"\(answer)\"")
            }
            #expect(key.rejects.count >= 3, "\(step.id) needs more wrong samples")
        }
    }

    @Test("A step's mistake examples name that mistake, and its next step does not give the step away")
    func stepMistakesNameThemselves() {
        let steps = Self.sheets.flatMap(\.sheet.steps)
        #expect(steps.filter { !$0.answerKey.mistakes.isEmpty }.count >= 63, "most steps should name a slip")
        for (question, sheet) in Self.sheets where question.id != "q-oup-ch04-wb-practice" {
            #expect(sheet.steps.contains { !$0.answerKey.mistakes.isEmpty }, "\(question.id) sheet names no slip")
        }
        for step in steps {
            let matchers = step.answerKey.parts.flatMap(\.anyOf)
            let answerNumbers = matchers.reduce(into: Set<AnswerNumber>()) { $0.formUnion(MistakeTests.magnitudes(in: $1)) }
            for mistake in step.answerKey.mistakes {
                for example in mistake.examples {
                    #expect(step.answerKey.mark(example).mistake?.misconception == mistake.misconception,
                            "\(step.id) \"\(example)\" does not name \(mistake.misconception)")
                }
                let next = AnswerText(mistake.nextStep)
                let shared = answerNumbers.intersection(next.numbers.map { $0.value.numerator < 0 ? $0.value.negated() : $0.value })
                #expect(shared.isEmpty, "\(step.id) \(mistake.misconception) next step shows \(shared.map(\.text))")
                #expect(!matchers.contains { $0.matches(next) }, "\(step.id) \(mistake.misconception) next step is a right answer")
            }
        }
    }

    @Test("Nothing on a sheet shows the original question's answer")
    func sheetsKeepTheOriginalHidden() {
        for (question, sheet) in Self.sheets {
            var shown = [sheet.sister]
            for step in sheet.steps {
                shown += [step.prompt, step.answer, step.working] + step.answerKey.mistakes.map(\.nextStep)
            }
            for text in shown {
                #expect(!Self.givesAway(text, to: question.answerKey), "\(question.id) sheet shows its answer: \(text)")
            }
        }
    }
}
