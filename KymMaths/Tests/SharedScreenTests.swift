import Foundation
import KymDesign
import Testing
@testable import KymMaths

/// Faults the chapter 2 and 3 walks found in the screens every chapter shares.
@Suite("Shared screens")
struct SharedScreenTests {
    static let pack = SeedPackLoader.load()

    // Who is right?

    @Test("Try again clears a wrong pick, even one saved on an earlier visit")
    func tryAgainClearsASavedPick() {
        let ids = ["a", "b", "c"]
        var pick = DebatePick()
        #expect(pick.active(saved: nil, among: ids) == nil)

        // The card saves each pick, so the saved pick is the wrong one by the time she taps Try again.
        pick.choose("a")
        #expect(pick.active(saved: "a", among: ids) == "a")
        pick.tryAgain()
        #expect(pick.active(saved: "a", among: ids) == nil)

        pick.choose("b")
        #expect(pick.active(saved: "b", among: ids) == "b")
    }

    @Test("A pick saved on an earlier visit shows when the card opens, and ids from another card do not")
    func savedPickShowsOnOpening() {
        let pick = DebatePick()
        #expect(pick.active(saved: "b", among: ["a", "b"]) == "b")
        #expect(pick.active(saved: "z", among: ["a", "b"]) == nil)
    }

    @Test("A wrong pick marks only itself, so the right answer is still hers to find")
    func wrongPickDoesNotShowTheAnswer() {
        #expect(DebatePick.tone(isChosen: false, pickedIsCorrect: nil) == .idle)
        #expect(DebatePick.tone(isChosen: true, pickedIsCorrect: false) == .wrong)
        #expect(DebatePick.tone(isChosen: false, pickedIsCorrect: false) == .dimmed)
        #expect(DebatePick.tone(isChosen: true, pickedIsCorrect: true) == .correct)
        #expect(DebatePick.tone(isChosen: false, pickedIsCorrect: true) == .dimmed)
    }

    // The whole chapter in one scroll

    @Test("The whole-chapter contents list names only parts the page has a heading for, in page order")
    func wholeChapterContentsMatchThePage() throws {
        let chapter = try #require(Self.pack.chapters.first { $0.number == 3 })
        let rows = WholeChapterContents.rows(for: chapter)
        #expect(rows.map(\.label) == [
            "From picture to formula", "Who is right?",
            "Sharing in parts", "Find one first", "When more means less",
            "One multiplication for a change", "Working backwards", "Growth on growth",
        ])
        #expect(Set(rows.map(\.id)).count == rows.count)
        #expect(Array(rows.dropFirst(2).map(\.id)) == chapter.sections.map(\.id))
    }

    // The school question screen

    @Test("A long list of answer parts is a sentence of its own, not the answer box's placeholder")
    func answerPartsLine() throws {
        func question(_ id: String) throws -> SchoolMathsQuestion {
            try #require(Self.pack.schoolQuestions.first { $0.id == id })
        }
        #expect(try question("q-oup-ch06-sb").answerPartsLine
            == "The answer has two parts: the subtraction step and the fraction in simplest form.")
        #expect(try question("q-oup-ch15-sb").answerPartsLine
            == "The answer has three parts: true positives, false positives and P(D | +).")
        let onePart = try #require(Self.pack.schoolQuestions.first { $0.answerKey.parts.count <= 1 })
        #expect(onePart.answerPartsLine == nil)
    }
}
