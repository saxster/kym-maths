import Foundation
import Testing
@testable import KymMaths

@Suite("Known mistakes on school questions")
struct MistakeTests {
    static let pack = SeedPackLoader.load()
    static let questions = pack.schoolQuestions

    static func question(_ id: String) throws -> SchoolMathsQuestion {
        try #require(questions.first { $0.id == "q-oup-\(id)" }, "no question \(id)")
    }

    static func magnitudes(in matcher: AnswerMatcher) -> Set<AnswerNumber> {
        func magnitude(_ value: AnswerNumber) -> AnswerNumber { value.numerator < 0 ? value.negated() : value }
        switch matcher {
        case let .number(value, _, _): return [magnitude(value)]
        case let .sequence(values, _): return Set(values.map(magnitude))
        case let .form(form): return Set(AnswerText(form).numbers.map { magnitude($0.value) })
        case let .all(matchers): return matchers.reduce(into: []) { $0.formUnion(magnitudes(in: $1)) }
        case .words: return []
        }
    }

    @Test("Every mistake's examples are marked wrong and name that mistake")
    func examplesNameTheirMistake() {
        for question in Self.questions {
            for mistake in question.answerKey.mistakes {
                #expect(!mistake.examples.isEmpty, "\(question.id) \(mistake.misconception) has no examples")
                for example in mistake.examples {
                    let marking = question.answerKey.mark(example)
                    #expect(!marking.isCorrect, "\(question.id) marks its example \"\(example)\" right")
                    #expect(
                        marking.mistake?.misconception == mistake.misconception,
                        "\(question.id) \"\(example)\" named \(marking.mistake?.misconception ?? "nothing"), not \(mistake.misconception)"
                    )
                }
            }
        }
    }

    @Test("A right answer never carries a mistake")
    func rightAnswersCarryNoMistake() {
        for question in Self.questions {
            for answer in question.answerKey.accepts + [question.modelAnswer] {
                let marking = question.answerKey.mark(answer)
                #expect(marking.isCorrect, "\(question.id) rejects \"\(answer)\"")
                #expect(marking.mistake == nil, "\(question.id) \"\(answer)\" carries \(marking.mistake?.misconception ?? "")")
            }
        }
    }

    @Test("Every question marked by a number, sequence or form names at least one mistake")
    func everyMarkedQuestionHasAMistake() {
        func isWorded(_ question: SchoolMathsQuestion) -> Bool {
            question.answerKey.parts.contains { part in
                part.anyOf.allSatisfy { if case .words = $0 { true } else { false } }
            }
        }
        let worded = Set(Self.questions.filter(isWorded).map(\.id))
        #expect(worded == ["q-oup-ch03-wb-practice", "q-oup-ch04-wb-practice", "q-oup-ch11-wb-focus"])
        for question in Self.questions where !worded.contains(question.id) {
            #expect(!question.answerKey.mistakes.isEmpty, "\(question.id) names no mistake")
        }
    }

    @Test("A next step never gives away a number or form from the right answer")
    func nextStepsDoNotGiveAwayTheAnswer() {
        for question in Self.questions {
            let matchers = question.answerKey.parts.flatMap(\.anyOf)
            let answerNumbers = matchers.reduce(into: Set<AnswerNumber>()) { $0.formUnion(Self.magnitudes(in: $1)) }
            for mistake in question.answerKey.mistakes {
                let step = AnswerText(mistake.nextStep)
                let stepNumbers = Set(step.numbers.map { $0.value.numerator < 0 ? $0.value.negated() : $0.value })
                let shared = answerNumbers.intersection(stepNumbers).map(\.text)
                #expect(shared.isEmpty, "\(question.id) \(mistake.misconception) next step shows \(shared)")
                #expect(!matchers.contains { $0.matches(step) }, "\(question.id) \(mistake.misconception) next step is itself a right answer")
            }
        }
    }

    @Test("The pack's misconception registry and the questions' mistakes agree")
    func registryMatchesTheMistakes() {
        let registry = Self.pack.misconceptions
        #expect(Set(registry.map(\.id)).count == registry.count, "the registry repeats an id")
        let names = Dictionary(uniqueKeysWithValues: registry.map { ($0.id, $0.name) })
        var used: Set<String> = []
        for question in Self.questions {
            for mistake in question.answerKey.mistakes {
                used.insert(mistake.misconception)
                #expect(names[mistake.misconception] == mistake.name, "\(question.id) \(mistake.misconception) does not match the registry")
            }
        }
        #expect(used == Set(names.keys), "unused or unknown ids: \(used.symmetricDifference(names.keys).sorted())")
    }

    @Test("Feedback names a known mistake and its next step, and the record keeps the id")
    func feedbackNamesTheMistake() throws {
        let question = try Self.question("ch01-wb-focus")
        let mistake = try #require(question.answerKey.mistakes.first { $0.misconception == "sign-of-product" })
        for assisted in [false, true] {
            let (result, record) = QuestionProofService.evaluateAndRecord(
                question: question,
                answerText: "16",
                usedAssistance: assisted,
                existingProof: nil
            )
            #expect(!result.isPass)
            #expect(result.mistake == mistake)
            #expect(result.feedbackSummary.contains("\(mistake.name). \(mistake.nextStep)"), "\(result.feedbackSummary)")
            #expect(record.lastMistakeId == "sign-of-product")
        }

        let (unknown, unknownRecord) = QuestionProofService.evaluateAndRecord(
            question: question,
            answerText: "-8",
            usedAssistance: false,
            existingProof: nil
        )
        #expect(!unknown.isPass)
        #expect(unknown.mistake == nil)
        #expect(unknown.feedbackSummary == "Not right yet. Check each step of your working, then try again.")
        #expect(unknownRecord.lastMistakeId.isEmpty)

        let (right, rightRecord) = QuestionProofService.evaluateAndRecord(
            question: question,
            answerText: "-16",
            usedAssistance: false,
            existingProof: nil
        )
        #expect(right.isPass && right.mistake == nil && rightRecord.lastMistakeId.isEmpty)
    }

    @Test("The slip a wrong answer came from is saved with the attempt")
    func savedAttemptKeepsTheMistake() throws {
        let record = QuestionProofService.evaluateAndRecord(
            question: try Self.question("ch01-wb-focus"), answerText: "16", usedAssistance: false, existingProof: nil
        ).record
        let db = DatabaseManager(inMemory: true)
        try db.saveQuestionProof(record)
        let saved = try #require(try db.fetchAllProofs().first { $0.id == record.id })
        #expect(saved.lastMistakeId == "sign-of-product")
    }

    @Test("Coaching for a school question uses the known mistake, never a guess against the faded step")
    func coachingUsesTheKnownMistake() throws {
        let focus = try Self.question("ch01-wb-focus")
        let marked = QuestionProofService.evaluateAndRecord(
            question: focus, answerText: "16", usedAssistance: false, existingProof: nil
        ).result
        let known = SocraticFeedbackEngine.evaluate(studentAnswer: "16", question: focus, marked: marked)
        let mistake = try #require(marked.mistake)
        #expect(known.headline == mistake.name)
        #expect(known.socraticNudge == mistake.nextStep)
        #expect(known.detectedTrap == nil)

        let challenge = try Self.question("ch02-wb-challenge")
        let negated = QuestionProofService.evaluateAndRecord(
            question: challenge, answerText: "-8100", usedAssistance: false, existingProof: nil
        ).result
        #expect(negated.mistake == nil)
        let unknown = SocraticFeedbackEngine.evaluate(studentAnswer: "-8100", question: challenge, marked: negated)
        #expect(unknown.headline == "Not there yet")
        #expect(unknown.detectedTrap == nil)
        #expect(!unknown.socraticNudge.contains("8100"))
    }
}
