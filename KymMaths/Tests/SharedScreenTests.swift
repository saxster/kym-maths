import Foundation
import KymDesign
import Testing
@testable import KymMaths

/// Faults the chapter 2 and 3 walks found in the screens every chapter shares.
@Suite("Shared screens")
struct SharedScreenTests {
    static let pack = SeedPackLoader.load()

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
