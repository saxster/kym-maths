import Foundation
import Testing
@testable import KymMaths

@Suite("Fact sprint")
struct FactSprintTests {
    private struct Seeded: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state
        }
    }

    private static func fact(_ prompt: String) throws -> Fact {
        try #require(FactFamily.allCases.lazy.flatMap(FactCatalog.facts).first { $0.prompt == prompt }, "no fact \(prompt)")
    }

    private static let start = Date(timeIntervalSince1970: 1_800_000_000)

    // MARK: The catalog

    @Test("Every family has facts, each prompt once, and the marker accepts every answer", arguments: FactFamily.allCases)
    func catalogIsSound(family: FactFamily) {
        let facts = FactCatalog.facts(family)
        #expect(!facts.isEmpty)
        #expect(Set(facts.map(\.id)).count == facts.count)
        for fact in facts {
            #expect(fact.family == family)
            #expect(SpeedMathAnswerCheck.isCorrect(typed: fact.answer, expected: fact.answer), "\(fact.prompt) = \(fact.answer)")
        }
    }

    @Test("Spot facts are marked as a teacher would", arguments: [
        ("7 × 8", "56", true),
        ("56 ÷ 7", "8", true),
        ("13²", "169", true),
        ("√144", "12", true),
        ("2⁶", "64", true),
        ("1/8 as a decimal", ".125", true),
        ("1/8 as a decimal", "0.125", true),
        ("3/8 as a decimal", "0.375", true),
        ("3/8 as a decimal", "0.125", false),
        ("0.75 as a fraction", "3/4", true),
        ("0.75 as a fraction", "6/8", false),
        ("3/5 as a percent", "60", true),
        ("3/5 as a percent", "60%", true),
        ("7 × 8", "54", false)
    ])
    func spotFacts(prompt: String, typed: String, correct: Bool) throws {
        let fact = try Self.fact(prompt)
        #expect(SpeedMathAnswerCheck.isCorrect(typed: typed, expected: fact.answer) == correct)
    }

    @Test("A missed fact is said whole")
    func workedLine() throws {
        #expect(try Self.fact("7 × 8").worked == "7 × 8 = 56")
        #expect(try Self.fact("3/5 as a percent").worked == "3/5 = 60%")
        #expect(try Self.fact("0.75 as a fraction").worked == "0.75 = 3/4")
    }

    // MARK: The deck

    @Test("Last time's misses come first, in order and once; unknown ids are dropped; every fact is in the deck once")
    func missesComeFirst() {
        var rng = Seeded(state: 7)
        let missed = ["9 × 7", "56 ÷ 8", "9 × 7", "not a fact", "12 × 12"]
        let deck = FactSprintDeck.build(family: .timesAndDivide, missedLastTime: missed, rng: &rng)
        #expect(deck.prefix(3).map(\.id) == ["9 × 7", "56 ÷ 8", "12 × 12"])
        #expect(deck.count == FactCatalog.facts(.timesAndDivide).count)
        #expect(Set(deck) == Set(FactCatalog.facts(.timesAndDivide)))
    }

    // MARK: The run

    private static func run(_ prompts: [String]) throws -> FactSprintRun {
        FactSprintRun(deck: try prompts.map(fact))
    }

    @Test("Right and wrong answers are counted, and a wrong one moves on")
    func countsRightAndWrong() throws {
        var run = try Self.run(["7 × 8", "13²", "2⁶"])
        run.start(at: Self.start)
        #expect(run.submit(typed: "56", at: Self.start + 1) == .right)
        #expect(run.submit(typed: "196", at: Self.start + 2) == .wrong(try Self.fact("13²")))
        #expect(run.current?.prompt == "2⁶")
        #expect(run.submit(typed: "64", at: Self.start + 3) == .right)
        #expect(run.right.map(\.prompt) == ["7 × 8", "2⁶"])
        #expect(run.missed.map(\.prompt) == ["13²"])
    }

    @Test("An empty answer does nothing")
    func emptyIgnored() throws {
        var run = try Self.run(["7 × 8"])
        run.start(at: Self.start)
        #expect(run.submit(typed: "  ", at: Self.start + 1) == nil)
        #expect(run.current?.prompt == "7 × 8")
        #expect(run.right.isEmpty && run.missed.isEmpty)
    }

    @Test("An answer at or after 20 seconds is not counted")
    func lateIgnored() throws {
        var run = try Self.run(["7 × 8", "13²"])
        run.start(at: Self.start)
        #expect(run.submit(typed: "56", at: Self.start + 19.9) == .right)
        #expect(run.submit(typed: "169", at: Self.start + 20) == nil)
        #expect(run.submit(typed: "169", at: Self.start + 25) == nil)
        #expect(run.right.count == 1 && run.missed.isEmpty)
        #expect(run.remaining(at: Self.start + 25) == 0)
    }

    @Test("Nothing is counted before the start or after the finish")
    func outsideTheSprintIgnored() throws {
        var run = try Self.run(["7 × 8", "13²"])
        #expect(run.submit(typed: "56", at: Self.start) == nil)
        #expect(run.remaining(at: Self.start) == 20)
        run.start(at: Self.start)
        run.finish()
        #expect(run.phase == .finished)
        #expect(run.submit(typed: "56", at: Self.start + 1) == nil)
        #expect(run.current == nil)
        #expect(run.right.isEmpty && run.missed.isEmpty)
    }

    // MARK: Saving

    @Test("A sprint record is saved and read back through the state migrations")
    func recordPersists() throws {
        let db = DatabaseManager(inMemory: true)
        let record = FactSprintRecord(
            id: UUID().uuidString,
            family: .powers,
            day: "2026-11-15",
            right: 12,
            wrong: 2,
            missed: ["2⁹", "3⁵"],
            finishedAt: Self.start
        )
        try db.saveFactSprint(record)
        #expect(try db.fetchFactSprints() == [record])
    }

    @Test("The store keeps today's score, last time's score and last time's misses per family")
    @MainActor
    func storeQueries() throws {
        let store = AppStore(db: DatabaseManager(inMemory: true))
        let yesterday = Self.start
        let today = Self.start + 86_400

        var first = try Self.run(["7 × 8", "56 ÷ 7", "9 × 7"])
        first.start(at: yesterday)
        _ = first.submit(typed: "56", at: yesterday + 1)
        _ = first.submit(typed: "9", at: yesterday + 2)
        first.finish()
        store.recordFactSprint(first, family: .timesAndDivide, at: yesterday + 20)

        #expect(store.todaysFactSprint(.timesAndDivide, now: today) == nil)
        #expect(store.missedLastTime(.timesAndDivide) == ["56 ÷ 7"])
        #expect(store.nextFactFamily(now: today) == .timesAndDivide)

        var second = try Self.run(["56 ÷ 7", "9 × 7"])
        second.start(at: today)
        _ = second.submit(typed: "8", at: today + 1)
        _ = second.submit(typed: "63", at: today + 2)
        second.finish()
        let saved = store.recordFactSprint(second, family: .timesAndDivide, at: today + 20)

        #expect(store.todaysFactSprint(.timesAndDivide, now: today)?.right == 2)
        #expect(store.factSprint(.timesAndDivide, before: saved.finishedAt)?.right == 1)
        #expect(store.missedLastTime(.timesAndDivide) == [])
        #expect(store.missedLastTime(.powers) == [])
        #expect(store.nextFactFamily(now: today) == .squaresAndRoots)
    }
}
