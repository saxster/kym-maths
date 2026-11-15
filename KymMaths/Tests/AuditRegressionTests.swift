import Foundation
import Testing
@testable import KymMaths

@Suite("Audit 2026-11-15 regressions")
struct AuditRegressionTests {
    @Test("Bundled content resolves from the build's own bundle, not the source tree")
    func resourcesResolveFromBundle() throws {
        let pack = try #require(KymResources.url(forResource: "kymmaths-seed-pack", withExtension: "json", subdirectory: "ContentPacks"))
        let book = try #require(KymResources.url(forResource: "index", withExtension: "html", subdirectory: "PatternedWorldBook"))
        for url in [pack, book] {
            #expect(!url.path.contains("/KymMaths/KymMaths/Resources/"), "\(url.path) is a source-tree path")
        }
        #expect(try SeedPackLoader.loadFromBundle().chapters.count == 21)
    }

    @Test("Set overlap question never asks for an impossible class")
    func setOverlapIsAlwaysPossible() throws {
        for seed in 1...240 {
            let problem = QuantitativeMathsEngine.generate(template: .setInclusionExclusion, seed: seed)
            let numbers = problem.prompt
                .split(whereSeparator: { !$0.isNumber })
                .compactMap { Int($0) }
            #expect(numbers.count == 4, "seed \(seed): \(problem.prompt)")
            guard numbers.count == 4 else { continue }
            let (total, setA, setB, neither) = (numbers[0], numbers[1], numbers[2], numbers[3])
            let both = Int(problem.expectedValue)
            #expect(both >= 1, "seed \(seed) asks for \(both) students")
            #expect(both <= min(setA, setB), "seed \(seed): overlap \(both) exceeds a set")
            #expect(setA + setB - both + neither == total, "seed \(seed): regions do not fill the class")
        }
    }

    @Test("No wrong-answer trap ever equals the right answer")
    func trapsNeverEqualTheAnswer() {
        for template in QuantitativeTemplateKind.allCases {
            for seed in 1...240 {
                let problem = QuantitativeMathsEngine.generate(template: template, seed: seed)
                #expect(problem.expectedValue.isFinite, "\(template.rawValue) seed \(seed)")
                for trap in problem.traps {
                    #expect(
                        abs(trap.buggyValue - problem.expectedValue) > problem.tolerance,
                        "\(template.rawValue) seed \(seed): trap \(trap.id) equals the answer \(problem.expectedValue)"
                    )
                }
            }
        }
    }

    @Test("Speed check wants the whole answer, not a piece of it", arguments: [
        ("1", "10", false),
        ("9", "9984", false),
        ("6", "6√2", false),
        ("", "8", false),
        ("10", "10", true),
        (" 10 ", "10", true),
        (".25", "0.25", true),
        ("0.250", "0.25", true),
        ("4/11", "4/11", true),
        ("4 / 11", "4/11", true),
        ("pi", "π", true),
        ("6√2", "6√2", true),
        ("-43", "-43", true),
        ("−43", "-43", true),
        ("43", "-43", false),
        ("60%", "60", true),
        ("6/8", "3/4", false)
    ])
    func speedCheckIsExact(typed: String, expected: String, correct: Bool) {
        #expect(SpeedMathAnswerCheck.isCorrect(typed: typed, expected: expected) == correct)
    }

    @Test("A prerequisite bracket belongs to exactly one chapter", arguments: [
        ("strand-right-triangle-pythagoras-12", 12, true),
        ("strand-right-triangle-pythagoras-12", 1, false),
        ("strand-right-triangle-pythagoras-12", 2, false),
        ("strand-basis-columns-20", 0, false),
        ("strand-basis-columns-20", 20, true)
    ])
    func bracketChapterMatch(id: String, chapter: Int, belongs: Bool) {
        #expect(LessonDependencyDAG.bracket(id: id, belongsToChapter: chapter) == belongs)
    }
}
