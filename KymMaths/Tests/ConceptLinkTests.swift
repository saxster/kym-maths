import Foundation
import SwiftUI
import Testing
@testable import KymMaths

@Suite("Concept cards and links")
struct ConceptLinkTests {
    static let pack = SeedPackLoader.load()
    static let library = ConceptLibrary(pack: pack)

    private static let goldenURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("Golden/concept-links.json")

    private func concepts(_ text: String, exclude: String? = nil, linked: Set<String> = []) -> [String] {
        Self.library.linker.links(in: text, exclude: exclude, linked: linked).map(\.concept)
    }

    @Test("The pack carries eleven concept cards and chapter 1's nine-step sections")
    func packDecodesCardsAndSteps() throws {
        #expect(Self.pack.concepts.count == 11)
        #expect(Self.pack.conceptStopPhrases.contains("scale factor"))
        let chapter = try #require(Self.pack.chapters.first { $0.number == 1 })
        #expect(chapter.skillCard != nil)
        #expect(chapter.linksConcepts)
        #expect(chapter.sections.count == 5)
        for section in chapter.sections {
            #expect(section.teachingSteps.map(\.kind) == TeachingStepKind.allCases, "\(section.id) steps")
            #expect(section.excerpt == section.teachingSteps.first { $0.kind == .idea }?.text)
        }
        #expect(chapter.callouts.map(\.id) == ["ch01-c-predict", "ch01-c-aha", "ch01-c-trap"])
        let others = Self.pack.chapters.filter { $0.number != 1 }
        #expect(others.count == 20)
        #expect(others.allSatisfy { !$0.linksConcepts && $0.skillCard == nil })
        for card in Self.pack.concepts {
            for id in card.standsOn + [card.mixUp.with].compactMap({ $0 }) {
                #expect(Self.library.card(id) != nil, "\(card.id) names \(id)")
            }
        }
    }

    @Test("The linker finds the longest phrase, skips stop phrases and part words, and links once a scope")
    func linkerRule() {
        #expect(concepts("The highest common factor of 12 and 18 is 6.") == ["hcf"])
        #expect(concepts("Write 12 as a product of its prime factors.") == ["prime-factors"])
        #expect(concepts("The scale factor is 2.").isEmpty)
        #expect(concepts("A factor of a factor", exclude: "factor").isEmpty)
        #expect(concepts("A factor of a factor") == ["factor"])
        #expect(concepts("Find a factor of 12.", linked: ["factor"]).isEmpty)
        #expect(concepts("Factorise it. A powerful idea.").isEmpty)
        #expect(concepts("√2 is about 1.41.") == ["square-root"])
    }

    @Test("Offsets count Unicode scalars")
    func offsetsCountScalars() {
        let linker = ConceptLinker(aliases: [("square-root", ["√"])], stopPhrases: [])
        #expect(linker.links(in: "2³ √9") == [ConceptLink(concept: "square-root", text: "√", offset: 3, length: 1)])
    }

    @Test("A scope links each concept once, in reading order")
    func scopes() {
        let before = Self.library.linker.linkedBefore(["A factor of 12.", "Another factor.", "A multiple of 3."])
        #expect(before == [[], ["factor"], ["factor"]])
    }

    private struct GoldenEntry: Decodable {
        struct Link: Decodable { let concept: String; let text: String; let offset: Int }
        let text: String
        let exclude: String?
        let linked: [String]
        let links: [Link]
    }

    @Test("The Swift linker agrees with the Python one on every golden text")
    func goldenAgreement() throws {
        let entries = try JSONDecoder().decode([GoldenEntry].self, from: Data(contentsOf: Self.goldenURL))
        #expect(entries.count > 100)
        #expect(entries.contains { !$0.links.isEmpty && !$0.linked.isEmpty })
        for entry in entries {
            let found = Self.library.linker.links(in: entry.text, exclude: entry.exclude, linked: Set(entry.linked))
            let expected = entry.links.map { "\($0.concept)@\($0.offset):\($0.text)" }
            #expect(found.map { "\($0.concept)@\($0.offset):\($0.text)" } == expected, "\(entry.text)")
        }
    }

    @Test("Concept text carries a kymconcept link on the linked words only, and keeps a Byrne colour")
    func conceptMarkupLinks() throws {
        let text = ConceptMarkup.attributed(
            "The {red:highest common factor} of 12 and 18.", palette: .paper, ink: .black, underline: .orange,
            links: Self.library.linker, exclude: nil, linked: []
        )
        let linked = text.runs.filter { $0.link != nil }
        #expect(linked.count == 1)
        let run = try #require(linked.first)
        #expect(String(text[run.range].characters) == "highest common factor")
        #expect(run.link == ConceptLibrary.url(for: "hcf"))
        #expect(run.foregroundColor == PatternedPalette.paper.color(.moves))
        #expect(ConceptLibrary.concept(in: ConceptLibrary.url(for: "irrational-number")) == "irrational-number")
    }

    @Test("A rewritten section's beat reads its steps")
    func beatsCarrySteps() throws {
        let chapter = try #require(Self.pack.chapters.first { $0.number == 1 })
        let beats = ChapterInteractiveBeatEngine.beats(for: chapter)
        let stepped = beats.filter { !$0.teachingSteps.isEmpty }
        #expect(stepped.count == chapter.sections.count)
        for beat in stepped {
            #expect(beat.bodyParagraphs == beat.teachingSteps.map(\.text))
            #expect(beat.spokenScript.contains(beat.teachingSteps[0].text))
        }
        let other = try #require(Self.pack.chapters.first { $0.number == 2 })
        #expect(ChapterInteractiveBeatEngine.beats(for: other).allSatisfy { $0.teachingSteps.isEmpty })
    }

    @Test("A concept deep link opens its card")
    @MainActor
    func deepLink() throws {
        let store = AppStore(db: DatabaseManager(inMemory: true))
        store.openDeepLink(try #require(URL(string: "kymmaths://concept/hcf")))
        #expect(store.deepLinkedConcept?.id == "hcf")
    }
}
