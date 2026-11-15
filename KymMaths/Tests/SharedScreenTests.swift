import Foundation
import KymDesign
import Testing
@testable import KymMaths

/// Faults the chapter 2 and 3 walks found in the screens every chapter shares.
@Suite("Shared screens")
struct SharedScreenTests {
    static let pack = SeedPackLoader.load()

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
