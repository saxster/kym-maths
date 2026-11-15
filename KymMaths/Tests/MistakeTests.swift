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
}
