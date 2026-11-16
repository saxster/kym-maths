import Foundation
import Testing
@testable import KymMaths

@Suite("Algebra marked by doing the algebra")
struct ExpressionMarkingTests {
    private static let goldenURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("Golden/expression-reading.json")

    private struct GoldenCase: Decodable {
        let input: String
        let readsAs: String?
        let preview: String??
        let equivalentTo: String?
        let equivalent: Bool?
        let expanded: String?
        let factorised: String?

        enum CodingKeys: String, CodingKey {
            case input, readsAs, preview, equivalentTo, equivalent, expanded, factorised
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            input = try c.decode(String.self, forKey: .input)
            readsAs = try c.decodeIfPresent(String.self, forKey: .readsAs)
            preview = c.contains(.preview) ? .some(try c.decodeIfPresent(String.self, forKey: .preview)) : .none
            equivalentTo = try c.decodeIfPresent(String.self, forKey: .equivalentTo)
            equivalent = try c.decodeIfPresent(Bool.self, forKey: .equivalent)
            expanded = try c.decodeIfPresent(String.self, forKey: .expanded)
            factorised = try c.decodeIfPresent(String.self, forKey: .factorised)
        }
    }

    private static func describe(_ expansion: AnswerExpression.Expansion) -> String {
        switch expansion {
        case .ok: "ok"
        case .bracketLeft: "bracketLeft"
        case .likeTermsLeft: "likeTermsLeft"
        }
    }

    private static func describe(_ factorisation: AnswerExpression.Factorisation) -> String {
        switch factorisation {
        case .ok: "ok"
        case .notAProduct: "notAProduct"
        case let .bracketWithCommonFactor(bracket): "bracketWithCommonFactor: \(bracket.display)"
        }
    }

    @Test("The Swift reader agrees with the Python one on every golden case")
    func goldenAgreement() throws {
        let cases = try JSONDecoder().decode([GoldenCase].self, from: Data(contentsOf: Self.goldenURL))
        #expect(cases.count > 20)
        for golden in cases {
            let expression = AnswerExpression.parse(golden.input)
            #expect(expression?.display == golden.readsAs, "\(golden.input) reads as \(expression?.display ?? "nothing")")
            if case let .some(preview) = golden.preview {
                #expect(AnswerExpression.readsAs(golden.input) == preview, "\(golden.input) previews as \(AnswerExpression.readsAs(golden.input) ?? "nothing")")
            }
            guard let expression else { continue }
            #expect(Self.describe(expression.expansion) == golden.expanded, "\(golden.input) expansion")
            #expect(Self.describe(expression.factorisation) == golden.factorised, "\(golden.input) factorisation")
            if let target = golden.equivalentTo {
                let parsed = try #require(AnswerExpression.parse(target), "\(target) does not parse")
                #expect(expression.isEquivalent(to: parsed) == golden.equivalent, "\(golden.input) against \(target)")
            }
        }
    }

    @Test("Equal expressions are equal however they are written", arguments: [
        ("5x + 3", "3 + 5x", true),
        ("x·5 + 3", "5x+3", true),
        ("(x + 7)/3", "x/3 + 7/3", true),
        ("n(n + 2)", "n² + 2n", true),
        ("-1/2x + 3", "3 - x/2", true),
        ("6ab(3a − 2b)", "18a²b − 12ab²", true),
        ("5x + 3", "5x - 3", false),
        ("x²", "2x", false),
        ("1/2x", "1/(2x)", false)
    ])
    func equivalence(a: String, b: String, equal: Bool) throws {
        let left = try #require(AnswerExpression.parse(a))
        let right = try #require(AnswerExpression.parse(b))
        #expect(left.isEquivalent(to: right) == equal)
    }

    private static func key(_ value: String, _ form: ExpressionForm) -> AnswerKey {
        AnswerKey(parts: [AnswerPart(label: "answer", anyOf: [.expression(value: value, form: form)])],
                  accepts: [], rejects: [], mistakes: [])
    }

    @Test("A form asks for the finished shape, not just an equal expression")
    func formsAskForTheFinishedShape() {
        let expand = Self.key("5x+3", .expanded)
        #expect(expand.mark("3 + 5x").isCorrect)
        #expect(expand.mark("= x·5 + 3").isCorrect)
        #expect(!expand.mark("4(2x − 3) − 3(x − 5)").isCorrect)
        let factorise = Self.key("6ab(3a-2b)", .factorised)
        #expect(factorise.mark("(3a − 2b)·6ab").isCorrect)
        #expect(!factorise.mark("18a²b − 12ab²").isCorrect)
        #expect(!factorise.mark("6a(3ab − 2b²)").isCorrect)
        let any = Self.key("(x+7)/3", .any)
        #expect(any.mark("f⁻¹(x) = 7/3 + 1/3x").isCorrect)
    }

    @Test("An equal but unfinished answer names its slip and points at what to recheck")
    func unfinishedAnswersNameTheirSlip() throws {
        let factorise = Self.key("6ab(3a-2b)", .factorised)
        let halfway = try #require(factorise.mark("6a(3ab − 2b²)").mistake)
        #expect(halfway.misconception == "common-factor-left")
        #expect(halfway.name == "You left a common factor in")
        #expect(halfway.nextStep == "It multiplies back to the right expression, but the bracket (3ab−2b²) still has a common factor. Take that out too.")
        let unfactorised = try #require(factorise.mark("18a²b − 12ab²").mistake)
        #expect(unfactorised.misconception == "stopped-early")
        #expect(unfactorised.nextStep == "It is equal, but it is not factorised yet. Write it as a product with a bracket.")
        #expect(factorise.mark("6ab(3a + 2b)").mistake == nil)

        let expand = Self.key("5x+3", .expanded)
        let bracket = try #require(expand.mark("2(x + 3) + 3(x − 1)").mistake)
        #expect(bracket.misconception == "stopped-early")
        #expect(bracket.nextStep == "It is equal, but a bracket is still there. Multiply it out.")
        let likeTerms = try #require(expand.mark("2x + 3x + 3").mistake)
        #expect(likeTerms.nextStep == "It is equal, but some like terms are not collected yet. Add them together.")
        for slip in [halfway, unfactorised, bracket, likeTerms] {
            #expect(slip.nextStep.hasSuffix("."))
            #expect(AnswerText(slip.nextStep).numbers.isEmpty, "\(slip.nextStep) shows a number")
        }
    }

    @Test("A listed mistake still wins over the slip the marker names itself")
    func listedMistakesComeFirst() throws {
        let question = try #require(SeedPackLoader.load().schoolQuestions.first { $0.id == "q-oup-ch02-wb-focus" })
        let listed = try #require(question.answerKey.mistakes.first { $0.misconception == "common-factor-left" })
        #expect(question.answerKey.mark("6a(3ab − 2b²)").mistake == listed)
    }

    @Test("The two slips the marker names itself match the pack's registry")
    func unfinishedNamesMatchTheRegistry() {
        let registry = Dictionary(uniqueKeysWithValues: SeedPackLoader.load().misconceptions.map { ($0.id, $0.name) })
        for (id, name) in KnownMistake.unfinishedNames {
            #expect(registry[id] == name, "\(id) is \"\(registry[id] ?? "missing")\" in the pack")
        }
    }

    @Test("School questions accept a right answer nobody listed, and reject the question typed back", arguments: [
        ("ch02-sb", "x·5 + 3", true),
        ("ch02-sb", "4(2x − 3) − 3(x − 5)", false),
        ("ch02-wb-focus", "(3a − 2b) × 6ab", true),
        ("ch02-wb-focus", "18a²b − 12ab²", false),
        ("ch02-wb-practice", "6(2x + 5) − 4(x − 2)", false),
        ("ch11-wb-practice", "n·n + 2n", true),
        ("ch14-wb-focus", "f⁻¹(x) = 7/3 + 1/3x", true),
        ("ch14-wb-practice", "y = 3 − ½x", true)
    ])
    func schoolQuestionsMarkByAlgebra(id: String, answer: String, right: Bool) throws {
        let question = try #require(SeedPackLoader.load().schoolQuestions.first { $0.id == "q-oup-\(id)" })
        #expect(question.answerKey.mark(answer).isCorrect == right, "\(id) \"\(answer)\"")
    }

    @Test("An expression matcher reads from JSON and refuses a value that is not an expression")
    func expressionMatcherDecodes() throws {
        let decoded = try JSONDecoder().decode(AnswerMatcher.self, from: Data(#"{"kind":"expression","value":"5x+3"}"#.utf8))
        #expect(decoded == .expression(value: "5x+3", form: .any))
        let shaped = try JSONDecoder().decode(AnswerMatcher.self, from: Data(#"{"kind":"expression","value":"5x+3","form":"expanded"}"#.utf8))
        #expect(shaped == .expression(value: "5x+3", form: .expanded))
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(AnswerMatcher.self, from: Data(#"{"kind":"expression","value":"x > 4"}"#.utf8))
        }
    }

    @Test("Reads as shows how the marker read the answer, and nothing for plain numbers or words", arguments: [
        ("n2 + 2n", "n × 2 + 2n"),
        ("x^2+6x+9", "x² + 6x + 9"),
        ("y = -1/2x + 3", "y = (−1/2)x + 3"),
        ("16", nil),
        ("I do not know", nil),
        ("x > -4", nil)
    ])
    func readsAs(typed: String, shown: String?) {
        #expect(AnswerExpression.readsAs(typed) == shown)
    }
}
