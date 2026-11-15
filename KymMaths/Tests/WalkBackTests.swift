import Foundation
import Testing
@testable import KymMaths

@Suite("Walking back to the step a repeated slip rests on")
struct WalkBackTests {
    static let pack = SeedPackLoader.load()

    static func question(_ id: String) throws -> SchoolMathsQuestion {
        try #require(pack.schoolQuestions.first { $0.id == "q-oup-\(id)" }, "no question \(id)")
    }

    // MARK: The footings in the pack

    @Test("Every misconception stands on a footing in the pack, and every footing is stood on")
    func everyMisconceptionHasAFooting() {
        let footingIds = Set(Self.pack.footings.map(\.id))
        #expect(footingIds.count == Self.pack.footings.count, "a footing id repeats")
        #expect((15...22).contains(footingIds.count), "\(footingIds.count) footings")
        #expect(!Self.pack.misconceptions.isEmpty)
        for misconception in Self.pack.misconceptions {
            #expect(footingIds.contains(misconception.standsOn), "\(misconception.id) stands on unknown \(misconception.standsOn)")
        }
        #expect(Set(Self.pack.misconceptions.map(\.standsOn)) == footingIds, "a footing nothing stands on")
    }

    @Test("Every footing has three probes, and each probe's own answer is marked right")
    func probesMarkTheirOwnAnswers() {
        let probeIds = Self.pack.footings.flatMap(\.probes).map(\.id)
        #expect(Set(probeIds).count == probeIds.count, "a probe id repeats")
        for footing in Self.pack.footings {
            #expect(footing.probes.count == 3, "\(footing.id) has \(footing.probes.count) probes")
            #expect(footing.teach.hasSuffix("."), "\(footing.id) teach does not end in a full stop")
            for probe in footing.probes {
                let key = probe.answerKey
                for answer in [probe.answer] + key.accepts {
                    #expect(key.mark(answer).isCorrect, "\(probe.id) rejects \"\(answer)\"")
                }
                for answer in key.rejects + ["", probe.prompt] {
                    #expect(!key.mark(answer).isCorrect, "\(probe.id) accepts \"\(answer)\"")
                }
                #expect(key.rejects.count >= 3, "\(probe.id) needs more wrong samples")
            }
        }
    }

    @Test("A footing's teach line never gives away one of its probes' answers")
    func teachDoesNotGiveAwayAnAnswer() {
        for footing in Self.pack.footings {
            for probe in footing.probes {
                #expect(!probe.answerKey.mark(footing.teach).isCorrect, "\(footing.id) teach answers \(probe.id)")
            }
        }
    }

    // MARK: The rule

    @Test("The first slip is not due, the second is, a pass resets the count and a fail keeps it")
    func ruleCountsRepeats() {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let first = WalkBackRule.recordingSlip("sign-of-product", on: "q1", at: start, onto: nil)
        #expect(first.sinceCheck == 1 && first.total == 1)
        #expect(!WalkBackRule.isDue(first))

        let second = WalkBackRule.recordingSlip("sign-of-product", on: "q2", at: start + 60, onto: first)
        #expect(second.sinceCheck == 2 && second.total == 2 && second.lastQuestionId == "q2")
        #expect(WalkBackRule.isDue(second))

        let passed = WalkBackRule.recordingCheck(second, passed: true, at: start + 120)
        #expect(passed.sinceCheck == 0 && passed.total == 2)
        #expect(passed.lastCheckPassed == true && passed.lastCheckedAt == start + 120)
        #expect(!WalkBackRule.isDue(WalkBackRule.recordingSlip("sign-of-product", on: "q3", at: start + 180, onto: passed)))

        let failed = WalkBackRule.recordingCheck(second, passed: false, at: start + 120)
        #expect(failed.sinceCheck == 2 && failed.lastCheckPassed == false)
        let again = WalkBackRule.recordingSlip("sign-of-product", on: "q3", at: start + 180, onto: failed)
        #expect(WalkBackRule.isDue(again))
    }

    @Test("The check passes on two right in a row and ends after three probes either way",
          arguments: [
            ([true], nil as Bool?),
            ([true, true], true),
            ([false, true], nil),
            ([false, true, true], true),
            ([true, false, true], false),
            ([false, false, true], false),
            ([false, false, false], false)
          ])
    func checkOutcome(results: [Bool], expected: Bool?) {
        #expect(WalkBackRule.checkOutcome(results, probeCount: 3) == expected)
    }

    // MARK: The store

    @Test("The same slip on two questions sets a walk-back on the second, and passing clears it")
    @MainActor
    func sameSlipTwiceSetsAWalkBack() throws {
        let store = AppStore(db: DatabaseManager(inMemory: true))
        let focus = try Self.question("ch01-wb-focus")
        let expand = try Self.question("ch02-sb")

        store.submitQuestionAttempt(question: focus, answerText: "16", usedAssistance: false)
        #expect(store.pendingWalkBack == nil)
        #expect(store.slipTalliesById["sign-of-product"]?.sinceCheck == 1)

        store.submitQuestionAttempt(question: expand, answerText: "5x − 7", usedAssistance: false)
        #expect(store.pendingWalkBack == nil, "a different slip set a walk-back")

        store.submitQuestionAttempt(question: expand, answerText: "5x − 27", usedAssistance: false)
        let walkBack = try #require(store.pendingWalkBack)
        #expect(walkBack.questionId == expand.id)
        #expect(walkBack.misconception.id == "sign-of-product")
        #expect(walkBack.footing.id == "negative-numbers")

        store.finishWalkBack(passed: true)
        #expect(store.pendingWalkBack == nil)
        let tally = try #require(store.slipTalliesById["sign-of-product"])
        #expect(tally.sinceCheck == 0 && tally.total == 2 && tally.lastCheckPassed == true)
        #expect(store.slipTalliesById["expand-first-term-only"]?.sinceCheck == 1)
    }

    @Test("A failed check lets her go on, and the next same slip walks back again")
    @MainActor
    func failedCheckWalksBackAgain() throws {
        let store = AppStore(db: DatabaseManager(inMemory: true))
        let focus = try Self.question("ch01-wb-focus")
        store.submitQuestionAttempt(question: focus, answerText: "16", usedAssistance: false)
        store.submitQuestionAttempt(question: focus, answerText: "16", usedAssistance: false)
        #expect(store.pendingWalkBack?.questionId == focus.id, "the repair failed on the same question")

        store.finishWalkBack(passed: false)
        #expect(store.pendingWalkBack == nil)
        #expect(store.slipTalliesById["sign-of-product"]?.lastCheckPassed == false)

        store.submitQuestionAttempt(question: focus, answerText: "16", usedAssistance: false)
        #expect(store.pendingWalkBack?.misconception.id == "sign-of-product")
    }

    @Test("A slip tally is saved and read back through the state migrations")
    func tallyPersists() throws {
        let db = DatabaseManager(inMemory: true)
        let tally = SlipTally(
            misconceptionId: "forgot-half",
            sinceCheck: 2,
            total: 5,
            lastQuestionId: "q-oup-ch05-sb",
            lastSeenAt: Date(timeIntervalSince1970: 1_800_000_000),
            lastCheckedAt: Date(timeIntervalSince1970: 1_799_000_000),
            lastCheckPassed: false
        )
        try db.saveSlipTally(tally)
        #expect(try db.fetchSlipTallies() == [tally])
    }
}
