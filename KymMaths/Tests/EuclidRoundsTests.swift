import Foundation
import Testing
@testable import KymMaths

@Suite("Euclid rounds")
struct EuclidRoundsTests {
    // MARK: - Spine map

    @Test("The map puts I.1 first, I.47 last, and every proposition below what it stands on")
    func spineRows() throws {
        let rows = EuclidSpineLayout.rows()
        #expect(rows.first?.contains("I.1") == true)
        #expect(rows.last == ["I.47"])
        #expect(Set(rows.flatMap { $0 }) == Set(EuclidSpine.catalog.map(\.id)), "every node once")
        #expect(rows.flatMap { $0 }.count == EuclidSpine.catalog.count)
        let row = Dictionary(uniqueKeysWithValues: rows.enumerated().flatMap { index, ids in ids.map { ($0, index) } })
        for edge in EuclidSpineLayout.edges() {
            let (from, to) = (try #require(row[edge.from]), try #require(row[edge.to]))
            #expect(from < to, "\(edge.from) above \(edge.to)")
        }
        // The chain branches as the engine has it: I.10 and I.11 side by side, not one after the other.
        #expect(row["I.9"] == row["I.11"])
        #expect(row["I.10"] == row["I.46"])
    }

    @Test("An accepted fact sits just above the first proposition that uses it")
    func acceptedRows() throws {
        let rows = EuclidSpineLayout.rows()
        let row = Dictionary(uniqueKeysWithValues: rows.enumerated().flatMap { index, ids in ids.map { ($0, index) } })
        for proposition in EuclidSpine.catalog {
            guard case .accepted = proposition.kind else { continue }
            let firstUser = try #require(proposition.unlocks.compactMap { row[$0] }.min())
            #expect(row[proposition.id] == firstUser - 1, "\(proposition.id)")
        }
    }

    // MARK: - Step order

    private static func round(_ id: PropositionID, seed: UInt64 = 7) throws -> StepOrderRound {
        let proposition = try #require(EuclidSpine.proposition(id))
        return try #require(StepOrderRound(proposition: proposition, seed: seed))
    }

    @Test("The same seed gives the same round, the steps are shuffled, and each step offers three reasons, one right")
    func seededRound() throws {
        let a = try Self.round("I.47"), b = try Self.round("I.47")
        #expect(a == b)
        #expect(a.shuffled != Array(a.steps.indices))
        #expect(Set(a.shuffled) == Set(a.steps.indices))
        for (index, options) in a.options.enumerated() {
            #expect(options.count == 3 && Set(options).count == 3)
            #expect(options.filter { $0 == a.steps[index].because }.count == 1)
        }
        #expect(try Self.round("I.47", seed: 8) != a, "another seed, another round")
        #expect(try Self.round("I.1", seed: 1).shuffled != [0, 1, 2], "never already in order")
    }

    @Test("Steps go in proof order, a wrong step is a slip, and side-by-side steps with one reason may swap")
    func ordering() throws {
        var round = try Self.round("I.47")
        // Steps 9 and 10 (indices 8, 9) both rest on I.41.
        #expect(round.steps[8].because == .proposition("I.41") && round.steps[9].because == .proposition("I.41"))
        let early = round.place(1)
        #expect(!early, "step 2 before step 1")
        #expect(round.mistakes == 1)
        for index in 0..<8 { let ok = round.place(index); #expect(ok) }
        #expect(round.acceptableNext == [8, 9])
        let swapped = round.place(9), then = round.place(8)
        #expect(swapped && then)
        for index in 10..<round.steps.count { let ok = round.place(index); #expect(ok) }
        #expect(round.pool.isEmpty && !round.isComplete, "placed but not yet justified")
        for index in round.steps.indices { let ok = round.justify(index, with: round.steps[index].because); #expect(ok) }
        #expect(round.isComplete && round.earnsHead)
    }

    @Test("A wrong reason is a slip; too many slips, or any reveal, and the round does not earn the level")
    func slipsAndReveals() throws {
        var round = try Self.round("I.1")
        for index in round.steps.indices { round.place(index) }
        let wrong = try #require(round.options[0].first { $0 != round.steps[0].because })
        let slipped = round.justify(0, with: wrong)
        #expect(!slipped)
        for index in round.steps.indices { round.justify(index, with: round.steps[index].because) }
        #expect(round.isComplete && round.earnsHead && round.mistakes == 1)

        var sloppy = try Self.round("I.1")
        for _ in 0...StepOrderRound.allowedMistakes { sloppy.place(sloppy.steps.count - 1) }
        for index in sloppy.steps.indices { sloppy.place(index); sloppy.justify(index, with: sloppy.steps[index].because) }
        #expect(sloppy.isComplete && !sloppy.earnsHead)

        var helped = try Self.round("I.1")
        while !helped.isComplete { helped.revealNext() }
        #expect(helped.isAssisted && !helped.earnsHead && helped.placed == Array(helped.steps.indices))
    }

    // MARK: - Knows when

    @Test("The selector picks the earliest proposition held in her head, and nothing before that")
    func knowsWhenSelection() throws {
        var progress = EuclidProgress()
        #expect(EuclidKnowsWhen.select(progress: progress) == nil)
        for level in [SkillLevel.picture, .letters] { progress.record(level, for: "I.1", assisted: false) }
        #expect(EuclidKnowsWhen.select(progress: progress) == nil, "letters is not yet in her head")
        for level in [SkillLevel.picture, .letters, .head] { progress.record(level, for: "I.10", assisted: false) }
        let question = try #require(EuclidKnowsWhen.select(progress: progress))
        #expect(question.proposition == "I.10")
        #expect(question.options.count == 3 && question.options.contains("I.10") && Set(question.options).count == 3)
        #expect(EuclidKnowsWhen.select(progress: progress) == question, "stable")
        progress.record(.head, for: "I.1", assisted: false)
        #expect(EuclidKnowsWhen.select(progress: progress)?.proposition == "I.1", "earliest first")
    }

    @Test("A right first answer records knows-when; a wrong one records nothing")
    func knowsWhenRecording() throws {
        var progress = EuclidProgress()
        for level in [SkillLevel.picture, .letters, .head] { progress.record(level, for: "I.47", assisted: false) }
        let question = try #require(EuclidKnowsWhen.select(progress: progress))
        let wrong = try #require(question.options.first { $0 != "I.47" })
        let wrongAnswer = EuclidKnowsWhen.answer(wrong, to: question, progress: &progress)
        #expect(!wrongAnswer)
        #expect(progress.highest("I.47") == .head)
        let rightAnswer = EuclidKnowsWhen.answer("I.47", to: question, progress: &progress)
        #expect(rightAnswer)
        #expect(progress.highest("I.47") == .knowsWhen)
        #expect(EuclidKnowsWhen.select(progress: progress) == nil)
    }

    @Test("The Daily Flow carries a knows-when question only when one is due, and is otherwise unchanged")
    func dailyFlowCarriesQuestion() throws {
        let pack = SeedPackLoader.load()
        func plan(_ progress: EuclidProgress) -> DailyFlowSessionPlan {
            DailyFlowSessionEngine.buildPlan(pack: pack, dueCards: [], allCards: [], selectedChapterNumber: 9,
                                             selectedUnitNumber: 3, proofsByQuestionId: [:], euclidProgress: progress)
        }
        let without = plan(EuclidProgress())
        #expect(without.euclidKnowsWhen == nil)
        var progress = EuclidProgress()
        for level in [SkillLevel.picture, .letters, .head] { progress.record(level, for: "I.11", assisted: false) }
        let with = plan(progress)
        #expect(with.euclidKnowsWhen?.proposition == "I.11")
        #expect(with.debateScenario == without.debateScenario && with.trapProblem == without.trapProblem)
    }

    // MARK: - Links

    @Test("Every build-it-yourself widget exists in the pack and opens a built proposition")
    func buildLinks() throws {
        let pack = SeedPackLoader.load()
        let widgetIDs = Set(pack.widgets.map(\.id))
        for (widget, id) in EuclidBuildLinks.widgets {
            #expect(widgetIDs.contains(widget), "\(widget)")
            let proposition = try #require(EuclidSpine.proposition(id))
            guard case .built = proposition.kind else { Issue.record("\(id) is not built"); continue }
        }
        #expect(pack.chapters.contains { $0.id == EuclidBuildLinks.mapChapter })
    }
}
