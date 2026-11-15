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

    @Test("The pack carries the cards of chapters 0 to 3, and their nine-step sections")
    func packDecodesCardsAndSteps() throws {
        #expect(Self.pack.concepts.count == 47)
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
        let zero = try #require(Self.pack.chapters.first { $0.number == 0 })
        #expect(zero.skillCard != nil && zero.linksConcepts && zero.goesBeyondSchoolBook)
        #expect(zero.sections.count == 7)
        for section in zero.sections {
            #expect(section.teachingSteps.map(\.kind) == TeachingStepKind.allCases, "\(section.id) steps")
        }
        #expect(zero.callouts.map(\.id) == ["ch00-c-predict", "ch00-c-aha", "ch00-c-trap"])
        let two = try #require(Self.pack.chapters.first { $0.number == 2 })
        #expect(two.skillCard != nil && two.linksConcepts && !two.goesBeyondSchoolBook)
        #expect(two.sections.count == 6)
        for section in two.sections {
            #expect(section.teachingSteps.map(\.kind) == TeachingStepKind.allCases, "\(section.id) steps")
        }
        #expect(two.callouts.map(\.id) == ["ch02-c-predict", "ch02-c-aha", "ch02-c-trap"])
        let three = try #require(Self.pack.chapters.first { $0.number == 3 })
        #expect(three.skillCard != nil && three.linksConcepts && !three.goesBeyondSchoolBook)
        #expect(three.sections.count == 6)
        for section in three.sections {
            #expect(section.teachingSteps.map(\.kind) == TeachingStepKind.allCases, "\(section.id) steps")
        }
        #expect(three.callouts.map(\.id) == ["ch03-c-predict", "ch03-c-aha", "ch03-c-trap"])
        let others = Self.pack.chapters.filter { $0.number > 3 }
        #expect(others.count == 17)
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

    @Test("A link through \"power of\" or \"multiple of\" underlines the name and leaves \"of\" plain")
    func trailingOfIsNotUnderlined() throws {
        let links = Self.library.linker.links(in: "No power of 10 is a multiple of 3, and 7³ is a power.")
        let power = try #require(links.first { $0.concept == "power" })
        #expect(power.text == "power of")
        #expect(power.shownLength == 5)
        let multiple = try #require(links.first { $0.concept == "multiple" })
        #expect(multiple.text == "multiple of")
        #expect(multiple.shownLength == 8)
        let hcf = try #require(Self.library.linker.links(in: "Find the HCF.").first)
        #expect(hcf.shownLength == hcf.length)

        let text = ConceptMarkup.attributed(
            "But no power of 10 is a multiple of 3.", palette: .paper, ink: .black, underline: .orange,
            links: Self.library.linker, exclude: nil, linked: []
        )
        let underlined = text.runs.filter { $0.link != nil }.map { String(text[$0.range].characters) }
        #expect(underlined == ["power", "multiple"])
        #expect(String(text.characters) == "But no power of 10 is a multiple of 3.")
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
        let other = try #require(Self.pack.chapters.first { $0.number == 4 })
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

/// Stage 0 of docs/CONTENT_PLAN.md: the wrappers Swift puts round every chapter read from the
/// chapter's own record, and use words a 12-year-old reads without stumbling.
@Suite("Chapter wrappers")
struct ChapterWrapperTests {
    static let pack = SeedPackLoader.load()

    private static func chapter(_ number: Int) throws -> PatternedWorldChapter {
        try #require(pack.chapters.first { $0.number == number })
    }

    private static func beat(for section: PatternedWorldSection, in beats: [ChapterInteractiveBeat]) throws -> ChapterInteractiveBeat {
        try #require(beats.first { $0.title == section.heading }, "\(section.id) has a beat")
    }

    // G5

    @Test("Chapter 1's Who is right? comes from its pack record, not the Swift catalog")
    func debateFromPack() throws {
        let chapter = try Self.chapter(1)
        let packDebate = try #require(chapter.debate, "chapter 1 carries its debate")
        #expect(packDebate.id == "debate-ch01-primes")
        let beat = try #require(ChapterInteractiveBeatEngine.beats(for: chapter).first { $0.kind == .misconceptionDebate })
        #expect(beat.debateScenario == packDebate)
        #expect(beat.title == packDebate.title)
        #expect(MathematicalDebateEngine.scenario(for: chapter) == packDebate)
        #expect(!MathematicalDebateCatalog.all.contains { $0.chapterNumber == 1 })
    }

    // G6

    @Test("Chapter 1's first step carries its skill card, with the answer kept back")
    func firstBeatSkillCard() throws {
        let chapter = try Self.chapter(1)
        let card = try #require(chapter.skillCard)
        let first = try #require(ChapterInteractiveBeatEngine.beats(for: chapter).first)
        #expect(first.kind == .everydayHook)
        #expect(first.skillCard == card)
        #expect(first.spokenScript.contains(card.skill))
        #expect(first.spokenScript.contains(card.sheCan.prompt))
        #expect(first.spokenScript.contains(card.whyItMatters))
        #expect(!first.spokenScript.contains(card.sheCan.answer))
        #expect(!chapter.goesBeyondSchoolBook)
        #expect(first.beyondSchoolLine == nil)
    }

    @Test("A chapter marked beyond the school book decodes and says so on its first step")
    func beyondSchoolBook() throws {
        let original = try Self.chapter(1)
        var record = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any])
        record["beyondSchoolBook"] = true
        let chapter = try JSONDecoder().decode(PatternedWorldChapter.self, from: JSONSerialization.data(withJSONObject: record))
        #expect(chapter.goesBeyondSchoolBook)
        let line = try #require(ChapterInteractiveBeatEngine.beats(for: chapter).first?.beyondSchoolLine)
        #expect(line.contains("school book"))
        for item in try #require(chapter.skillCard).standsOn {
            #expect(line.localizedCaseInsensitiveContains(item), "names \(item)")
        }
        #expect(Self.pack.chapters.filter { $0.number != 1 }.allSatisfy { !$0.goesBeyondSchoolBook || $0.skillCard != nil })
    }

    // G7

    @Test("The figure sits beside the sections that use it, and not beside 1.5")
    func figureOnlyWhereNamed() throws {
        let chapter = try Self.chapter(1)
        let beats = ChapterInteractiveBeatEngine.beats(for: chapter)
        let s1 = try #require(chapter.sections.first { $0.id == "ch01-s1" })
        let s5 = try #require(chapter.sections.first { $0.id == "ch01-s5" })
        #expect(s1.figure == true)
        #expect(s5.figure == nil || s5.figure == false)
        #expect(try Self.beat(for: s1, in: beats).showsFigure)
        #expect(try !Self.beat(for: s5, in: beats).showsFigure)
        #expect(beats.first { $0.kind == .interactiveLabAndFormula }?.showsFigure == true)
        // A chapter not yet rewritten keeps the figure beside every section.
        let other = try Self.chapter(4)
        let otherBeats = ChapterInteractiveBeatEngine.beats(for: other)
        for section in other.sections {
            #expect(try Self.beat(for: section, in: otherBeats).showsFigure, "\(section.id)")
        }
    }

    // G9

    @Test("A card keeps its typed answer and scroll place when she follows a link and comes back")
    func cardTrail() {
        var trail = ConceptCardTrail(start: "hcf")
        #expect(trail.previous == nil)
        trail.current.typed = "10"
        trail.current.scrolledTo = "Check yourself"
        let marking = AnswerMarking(matchedParts: ["answer"], missingParts: [], mistake: nil)
        trail.current.marking = marking

        trail.follow("factor")
        #expect(trail.current.card == "factor")
        #expect(trail.current.typed.isEmpty && trail.current.scrolledTo == nil && trail.current.marking == nil)
        #expect(trail.previous?.card == "hcf")
        trail.current.typed = "3"

        trail.follow("factor")
        #expect(trail.stops.count == 2, "following the card already open does nothing")

        trail.back()
        #expect(trail.current.card == "hcf")
        #expect(trail.current.typed == "10")
        #expect(trail.current.scrolledTo == "Check yourself")
        #expect(trail.current.marking == marking)

        trail.back()
        #expect(trail.stops.count == 1, "the first card has nothing to go back to")
    }

    // G12

    private static let banned = ["invariant", "lockstep", "horizon", "symbolic", "anatomy", "duality", "renormalise",
                                 "heuristic", "mensuration", "kinematics", "simply", "just", "obviously", "clearly"]

    private static func bannedWords(in text: String) -> [String] {
        let words = Set(text.lowercased().split { !$0.isLetter }.map(String.init))
        return banned.filter(words.contains)
    }

    @Test("Chapter 1's step titles and eyebrows use plain words and no exclamation marks")
    func plainWrapperLabels() throws {
        let chapter = try Self.chapter(1)
        let beats = ChapterInteractiveBeatEngine.beats(for: chapter)
        for beat in beats {
            for label in [beat.eyebrow, beat.title, beat.plainLabel] {
                #expect(Self.bannedWords(in: label).isEmpty, "\(beat.id): \(label)")
                #expect(!label.contains("!"), "\(beat.id): \(label)")
            }
            #expect(Self.bannedWords(in: beat.spokenScript).isEmpty, "\(beat.id) reads aloud: \(beat.spokenScript)")
        }
        let synthesis = try #require(beats.last)
        #expect(synthesis.bodyParagraphs.contains { $0.hasPrefix("Words from this chapter: ") })
    }
}
