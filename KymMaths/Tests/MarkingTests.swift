import Foundation
import Testing
@testable import KymMaths

@Suite("School question marking")
struct MarkingTests {
    static let questions = SeedPackLoader.load().schoolQuestions

    static func isMarkedRight(_ id: String, _ answer: String) throws -> Bool {
        let question = try #require(questions.first { $0.id == "q-oup-\(id)" }, "no question \(id)")
        return QuestionProofService.evaluateAndRecord(
            question: question,
            answerText: answer,
            usedAssistance: false,
            existingProof: nil
        ).result.isPass
    }

    @Test("Wrong answers the keyword marker used to accept", arguments: [
        ("ch07-wb-focus", "x = 7"),
        ("ch01-wb-challenge", "b = 15"),
        ("ch06-wb-practice", "2"),
        ("ch07-wb-practice", "x ≥ 4"),
        ("ch05-wb-focus", "C = 10 cm"),
        ("ch11-wb-focus", "I do not know"),
        ("ch12-wb-practice", "40 hours"),
        ("ch01-wb-focus", "−160"),
        ("ch13-wb-focus", "P′ = (3, −5)")
    ])
    func wrongAnswerIsRejected(id: String, answer: String) throws {
        #expect(try !Self.isMarkedRight(id, answer), "\(id) accepted \"\(answer)\"")
    }

    @Test("Right answers the keyword marker used to reject", arguments: [
        ("ch07-wb-focus", "3"),
        ("ch01-wb-challenge", "60"),
        ("ch02-sb", "5x+3"),
        ("ch09-wb-challenge", "16550"),
        ("ch15-wb-focus", "1/9"),
        ("ch11-sb", "4n+3 900"),
        ("ch14-sb", "y=2x+5 -2.5")
    ])
    func rightAnswerIsAccepted(id: String, answer: String) throws {
        #expect(try Self.isMarkedRight(id, answer), "\(id) rejected \"\(answer)\"")
    }

    @Test("Every question marks its own sample answers the way its key says")
    func answerKeysMarkTheirOwnSamples() {
        #expect(Self.questions.count == 64)
        for question in Self.questions {
            let key = question.answerKey
            #expect(!key.parts.isEmpty, "\(question.id) has no parts")
            #expect(Set(key.parts.map(\.label)).count == key.parts.count, "\(question.id) repeats a part label")
            #expect(key.accepts.count >= 2 && key.rejects.count >= 3, "\(question.id) needs more sample answers")
            for answer in key.accepts + [question.modelAnswer] {
                #expect(key.mark(answer).isCorrect, "\(question.id) rejects \"\(answer)\"")
            }
            let neverRight = ["", "   ", "I have no idea about this, can you check", question.prompt]
            for answer in key.rejects + neverRight {
                #expect(!key.mark(answer).isCorrect, "\(question.id) accepts \"\(answer)\"")
            }
        }
    }

    @Test("Every concept card check and every turn step marks its own sample answers the way its key says")
    func cardChecksAndTurnStepsMarkTheirOwnSamples() {
        let pack = SeedPackLoader.load()
        let checks = pack.concepts.map { ($0.check.id, $0.check.answer, $0.check.answerKey) }
        let turns = pack.chapters.flatMap(\.sections).flatMap(\.teachingSteps).filter { $0.kind == .turn }
            .compactMap { step in step.answerKey.map { (step.id, step.answer ?? "", $0) } }
        #expect(checks.count == 47)
        #expect(turns.count == 24)
        // Not the prompt itself, as above: a check that asks her to pick from a list ("21, 23 or 27")
        // has the answer among its numbers, and the marker looks for the number anywhere.
        for (id, answer, key) in checks + turns {
            #expect(!key.accepts.isEmpty && key.rejects.count >= 2, "\(id) needs more sample answers")
            for sample in key.accepts + [answer] {
                #expect(key.mark(sample).isCorrect, "\(id) rejects \"\(sample)\"")
            }
            for sample in key.rejects + ["", "   ", "I have no idea about this, can you check"] {
                #expect(!key.mark(sample).isCorrect, "\(id) accepts \"\(sample)\"")
            }
        }
    }

    @Test("Feedback names the missing part, never the answer")
    func feedbackNamesThePartNotTheAnswer() throws {
        let question = try #require(Self.questions.first { $0.id == "q-oup-ch01-sb" })
        let result = QuestionProofService.evaluateAndRecord(
            question: question,
            answerText: "HCF = 24",
            usedAssistance: false,
            existingProof: nil
        ).result
        #expect(!result.isPass)
        #expect(result.matchedParts == ["HCF"])
        #expect(result.missingParts == ["LCM"])
        #expect(result.feedbackSummary.contains("LCM"))
        #expect(!result.feedbackSummary.contains("360"))
        let coaching = SocraticFeedbackEngine.evaluate(studentAnswer: "HCF = 24", question: question, marked: result)
        #expect(coaching.tier == .partial)
        #expect(!coaching.socraticNudge.contains("360"))
    }

    @Test("Numbers are read the way a marker reads them", arguments: [
        ("x = 3", ["3"]),
        ("3x + 4(2) = 2³", ["2"]),
        ("₹16,550", ["16550"]),
        ("5,89,020", ["589020"]),
        ("20,15,15", ["20", "15", "15"]),
        ("(5,−3)", ["5", "-3"]),
        ("8 − 3", ["8", "3"]),
        ("2 5/12", ["29/12"]),
        ("4/36 = 1/9", ["1/9", "1/9"]),
        ("30.5cm and 72s", ["61/2", "72"]),
        ("S₂₀ = 900", ["900"]),
        ("every 30th", ["30"]),
        (".25", ["1/4"]),
        ("−½x + 3", ["3"])
    ])
    func numbersAreReadInContext(text: String, expected: [String]) {
        #expect(AnswerText(text).numbers.map(\.value.text) == expected)
    }

    @Test("An answer number that already sits in the question is a known, listed case")
    func answerNumbersRarelyEchoTheQuestion() {
        func numbers(in matcher: AnswerMatcher) -> [AnswerNumber] {
            switch matcher {
            case let .number(value, _, _): [value]
            case let .all(matchers): matchers.flatMap(numbers)
            case .sequence, .form, .words: []
            }
        }
        var echoed: Set<String> = []
        for question in Self.questions {
            let given = Set(AnswerText(question.prompt).numbers.map(\.value))
            for part in question.answerKey.parts where part.anyOf.flatMap(numbers).contains(where: given.contains) {
                echoed.insert("\(question.id.dropFirst(6)) \(part.label)")
            }
        }
        #expect(echoed == ["ch10-wb-focus median", "ch06-sb the fraction in simplest form"])
    }
}
