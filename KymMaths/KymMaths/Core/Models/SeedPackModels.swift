import Foundation

// MARK: - Seed Pack Root

struct KymMathsSeedPack: Codable, Sendable {
    let schemaVersion: Int
    let packId: String
    let generatedBy: String
    let volumes: [PatternedWorldVolume]
    let chapters: [PatternedWorldChapter]
    let explorers: [PatternedWorldExplorer]
    let atlasLessons: [AtlasLesson]
    let widgets: [InteractiveWidgetSpec]
    let crossDisciplinaryBridges: [CrossDisciplinaryBridge]
    let schoolTextbook: SchoolMathsTextbook
    let schoolQuestions: [SchoolMathsQuestion]
    let diagramPlates: [DiagramRecallPlate]
    let polyaStages: [PolyaStageSpec]
    let speedMathDecks: [SpeedMathDeck]
    let visualMathTips: [VisualMathTip]
    let misconceptions: [Misconception]
    let footings: [Footing]
    let concepts: [ConceptCard]
    /// Phrases that contain a card's alias but mean something else ("scale factor"); they never link.
    let conceptStopPhrases: [String]
}

// MARK: - Concept cards

/// A short page that reminds Kym of one idea. Any learner text that uses one of its aliases links to it.
struct ConceptCard: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let short: String?
    let symbol: String?
    let aliases: [String]
    let oneSentence: String
    let picture: String
    let steps: [String]
    let bigNumbers: String?
    let workedExample: String
    let check: ConceptCheck
    let mixUp: ConceptMixUp
    let standsOn: [String]
    let footing: String?
    let usedIn: [ConceptUse]
}

struct ConceptCheck: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let prompt: String
    let answer: String
    let answerKey: AnswerKey
}

/// The idea she is most likely to confuse a card with: another card (`with`) or a plain name.
struct ConceptMixUp: Codable, Equatable, Sendable {
    let with: String?
    let name: String?
    let how: String
}

/// Where a card is needed: a chapter that teaches it, or a card that stands on it.
enum ConceptUse: Codable, Equatable, Sendable {
    case chapter(Int, label: String)
    case concept(String, label: String)

    private enum CodingKeys: String, CodingKey { case chapter, concept, label }

    var label: String {
        switch self {
        case let .chapter(_, label), let .concept(_, label): label
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let label = try container.decode(String.self, forKey: .label)
        if let number = try container.decodeIfPresent(Int.self, forKey: .chapter) {
            self = .chapter(number, label: label)
        } else {
            self = .concept(try container.decode(String.self, forKey: .concept), label: label)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .chapter(number, label):
            try container.encode(number, forKey: .chapter)
            try container.encode(label, forKey: .label)
        case let .concept(id, label):
            try container.encode(id, forKey: .concept)
            try container.encode(label, forKey: .label)
        }
    }
}

struct Misconception: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    /// The footing this slip rests on, checked when the slip comes back.
    let standsOn: String
}

/// The smaller skill a slip rests on, with three quick probes that check it.
struct Footing: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let skill: String
    let teach: String
    let probes: [FootingProbe]
}

struct FootingProbe: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let prompt: String
    let answer: String
    let answerKey: AnswerKey
}

/// A smaller question solved by the same method, broken into steps. It never shows the original's answer.
struct StuckSheet: Codable, Equatable, Sendable {
    let sister: String
    let steps: [StuckStep]
}

struct StuckStep: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let prompt: String
    let answer: String
    /// The step done in one sentence, shown when Kym misses it.
    let working: String
    let answerKey: AnswerKey
}

// MARK: - The Patterned World (21 Chapters, 5 Volumes, Intuition-to-Formula Bridges)

struct PatternedWorldVolume: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let number: Int
    let title: String
    let chapters: [Int]
}

struct IntuitionToFormulaBridge: Codable, Equatable, Sendable {
    let concreteAction: String
    let ahaInvariant: String
    let formulaDisplay: String
    let termMappings: [FormulaTermMapping]
    let atlasFigureRef: String

    func perturbationPrompt(for term: FormulaTermMapping) -> String {
        "Perturbation Probe for \(term.symbol): What happens to \(formulaDisplay) if you double or vary \(term.symbol) (\(term.visualPart)) while holding all other terms fixed?"
    }

    func perturbationExplanation(for term: FormulaTermMapping) -> String {
        "Because \(term.symbol) represents \(term.visualPart) (\(term.meaning)), scaling or shifting \(term.symbol) directly transforms \(term.visualPart) while preserving the structural invariant: \(ahaInvariant)"
    }
}

struct FormulaTermMapping: Codable, Identifiable, Equatable, Sendable {
    var id: String { "\(symbol)-\(visualPart)" }
    let symbol: String
    let visualPart: String
    let colorRole: String   // "red" | "blue" | "amber" | "green"
    let meaning: String
}

struct PatternedWorldChapter: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let number: Int
    let volumeNumber: Int
    let volumeTitle: String
    let title: String
    let subtitle: String
    let hookSummary: String
    /// What she can do afterwards with the device off. Present on chapters rewritten to the content brief.
    let skillCard: ChapterSkillCard?
    let intuitionToFormula: IntuitionToFormulaBridge
    let sections: [PatternedWorldSection]
    let callouts: [PatternedWorldCallout]
    let keyTerms: [String]
    let widgets: [String]
    /// The chapter's "Who is right?", on chapters rewritten to the content brief. The others still
    /// read theirs from `MathematicalDebateCatalog`.
    let debate: MathematicalDebateScenario?
    /// True when no school unit teaches this chapter, so its first screen says it goes past her book.
    let beyondSchoolBook: Bool?

    var goesBeyondSchoolBook: Bool { beyondSchoolBook ?? false }

    /// A chapter rewritten to the content brief links its concept names to their cards; the others
    /// read as they always have.
    var linksConcepts: Bool { sections.contains { $0.steps != nil } }
}

struct ChapterSkillCard: Codable, Equatable, Sendable {
    struct DeviceOffCheck: Codable, Equatable, Sendable {
        let prompt: String
        let answer: String
    }

    let skill: String
    let sheCan: DeviceOffCheck
    let whyItMatters: String
    let standsOn: [String]
    let unlocks: [String]
}

struct PatternedWorldSection: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let heading: String
    /// The section's one paragraph; on a rewritten section, the text of its `idea` step.
    let excerpt: String
    /// The concept cards whose names this section's `name` step introduces.
    let teaches: [String]?
    /// The nine teaching steps of a rewritten section; absent on the others.
    let steps: [TeachingStep]?
    /// True on a rewritten section whose text uses the chapter's interactive figure.
    let figure: Bool?

    var teachingSteps: [TeachingStep] { steps ?? [] }

    /// Whether the figure sits beside this section. A rewritten section shows it only when its text
    /// uses it; a section not yet rewritten keeps it, as it always had.
    var showsFigure: Bool { steps == nil ? true : figure == true }
}

/// The nine moves a rewritten section makes, in this order.
enum TeachingStepKind: String, Codable, CaseIterable, Sendable {
    case question, idea, picture, reason, name, example, mistake, turn, sayBack

    /// The small label over the step. The question has none; it is the section's lead.
    var label: String? {
        switch self {
        case .question: nil
        case .idea: "The idea"
        case .picture: "Picture it"
        case .reason: "Why it works"
        case .name: "What it's called"
        case .example: "Worked example"
        case .mistake: "The tempting mistake"
        case .turn: "Your turn"
        case .sayBack: "Say it back"
        }
    }
}

struct TeachingStep: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let kind: TeachingStepKind
    let text: String
    /// Present on the `turn` step.
    let answer: String?
    let answerKey: AnswerKey?
}

struct PatternedWorldCallout: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let kind: String      // predict, check, recall, careful, school, home, case
    let title: String
    let body: String

    var badgeText: String {
        switch kind {
        case "predict": return "Predict first"
        case "check": return "Check your understanding"
        case "recall": return "Recall"
        case "careful": return "Watch out"
        case "school": return "Cambridge syllabus"
        case "home": return "Try on paper"
        case "case": return "Historical proof"
        default: return kind.capitalized
        }
    }

    var symbolName: String {
        switch kind {
        case "predict": return "sparkles"
        case "check": return "function"
        case "recall": return "arrow.counterclockwise"
        case "careful": return "exclamationmark.triangle"
        case "school": return "graduationcap"
        case "home": return "pencil.and.ruler"
        case "case": return "scroll"
        default: return "bookmark"
        }
    }
}

struct PatternedWorldExplorer: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let linkedChapters: [Int]
    let summary: String
}

struct AtlasLesson: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let widget: String
    let title: String
    let chapter: Int
    let figure: String
    let question: String
    let explanation: String
    let limits: String
    let sources: [String]
    let stories: [String]
}

struct InteractiveWidgetSpec: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let chapter: Int
    let is3D: Bool
    let atlasRoute: String
    let challengePrompt: String
    let cutaway: String
    let idealised: String
    let watchSteps: [WidgetWatchStep]
}

struct WidgetWatchStep: Codable, Equatable, Sendable {
    let title: String
    let caption: String
}

// MARK: - Cross-Disciplinary STEM Bridges

struct CrossDisciplinaryBridge: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let discipline: String // "biology" | "physics" | "chemistry" | "economics"
    let sourceBook: String
    let sourceRef: String
    let deepLink: String
    let title: String
    let schoolTopics: [String]
    let patternedWorldChapters: [Int]
    let summary: String
    let keyEquation: String
    let microCheckQuestion: String
    let microCheckAnswer: String

    var badgeSymbol: String {
        switch discipline {
        case "biology": return "leaf.fill"
        case "physics": return "gyroscope"
        case "chemistry": return "atom"
        case "economics": return "indianrupeesign.circle.fill"
        default: return "function"
        }
    }
}

// MARK: - School Textbook: OUP Cambridge Lower Secondary Complete Mathematics 8 (2nd Ed.) by Deborah Barton

enum MathsCurriculumLens: String, CaseIterable, Identifiable, Codable, Sendable {
    case activeSchoolFocus = "active_school_focus"
    case coreStage8Complete = "core_stage8_complete"
    case fullHorizonOlympiad = "full_horizon_olympiad"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .activeSchoolFocus:
            return "Active School Focus (✓ & ○)"
        case .coreStage8Complete:
            return "All 16 OUP Chapters"
        case .fullHorizonOlympiad:
            return "Full Horizon (+ Set Theory, Bayes, Calc & Matrices)"
        }
    }

    var subtitle: String {
        switch self {
        case .activeSchoolFocus:
            return "Focused on Kym's ticked (Ch 3, 5, 12) and circled (Ch 1, 2, 6, 7, 9) school chapters"
        case .coreStage8Complete:
            return "Complete Deborah Barton OUP Complete Mathematics 8 (Ch 1–16 + Reviews A, B, C)"
        case .fullHorizonOlympiad:
            return "Full Stage 8 + Singapore Bar-Model + Set Theory, Trigonometry, Bayes, Calculus & Linear Algebra"
        }
    }
}

enum CompanionWorkbookTierFilter: String, CaseIterable, Identifiable, Codable, Sendable {
    case allTiers = "all"
    case focus = "Focus"
    case practice = "Practice"
    case challenge = "Challenge"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .allTiers: return "All 3 Workbook Tiers"
        case .focus: return "Tier 1 · Focus (Fluency)"
        case .practice: return "Tier 2 · Singapore CPA & Checkpoint"
        case .challenge: return "Tier 3 · Olympiad & Horizon"
        }
    }
}

struct SchoolMathsTextbook: Codable, Equatable, Sendable {
    let id: String
    let title: String
    let authors: String
    let publisher: String
    let curriculumCode: String
    let learnersBookTotalPages: Int
    let workbookTotalPages: Int
    let units: [SchoolMathsUnit]

    /// The topic with this code ("1.4"), from whichever unit holds it.
    func topic(code: String) -> SchoolMathsTopic? {
        units.lazy.flatMap(\.topics).first { $0.code == code }
    }

    func units(for lens: MathsCurriculumLens) -> [SchoolMathsUnit] {
        switch lens {
        case .activeSchoolFocus:
            return units.filter { $0.schoolStatus == "ticked" || $0.schoolStatus == "circled" }
        case .coreStage8Complete, .fullHorizonOlympiad:
            return units
        }
    }
}

struct SchoolMathsUnit: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let unitNumber: Int
    let title: String
    let discipline: String // "number_algebra" | "geometry_measures" | "statistics_probability" | "horizon_advanced"
    let schoolStatus: String // "ticked" | "circled" | "upcoming"
    let scienceStrands: [String]
    let twsStrands: [String]
    let scienceInContext: String
    let learnersBookStartPage: Int
    let learnersBookEndPage: Int
    let workbookStartPage: Int
    let workbookEndPage: Int
    let isCompletedInSchool: Bool
    let livingWorldChapters: [Int]
    let bridgeIds: [String]
    let topics: [SchoolMathsTopic]

    var statusBadgeLabel: String {
        switch schoolStatus {
        case "ticked": return "Ticked in Book ✓"
        case "circled": return "Circled Focus ○"
        default: return "Upcoming Chapter"
        }
    }

    var disciplineBadgeLabel: String {
        switch discipline {
        case "number_algebra": return "Number & Algebra"
        case "geometry_measures": return "Geometry & Measures"
        case "statistics_probability": return "Statistics & Probability"
        default: return "Vectors & Horizon"
        }
    }
}

struct SchoolMathsTopic: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let code: String
    let title: String
    let learnersBookPage: Int
    let workbookPage: Int
    let discipline: String
    let livingWorldChapters: [Int]
    let linkedWidgets: [String]
    let bridgeIds: [String]
    let summary: String
    let cambridgeWatchouts: [String]
}

struct SchoolMathsQuestion: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let unitNumber: Int
    let topicCode: String
    let sourceBook: String      // "learners_book" | "workbook"
    let bookSection: String
    let tier: String            // "Consolidation" | "Focus" | "Practice" | "Challenge"
    let commandWord: String
    let marks: Int
    let prompt: String
    let workedExample: String
    let fadedPrompt: String
    let fadedAnswer: String
    let modelAnswer: String
    let answerKey: AnswerKey
    let linkedChapter: Int
    let linkedWidget: String
    /// Absent where no smaller twin can be solved without giving the answer away.
    let stuck: StuckSheet?

    /// The named parts of a multi-part answer ("HCF and LCM", "a, b and c"); nil when the answer is one thing.
    var answerPartsPhrase: String? {
        let labels = answerKey.parts.map(\.label)
        guard labels.count > 1, let last = labels.last else { return nil }
        return labels.dropLast().joined(separator: ", ") + " and " + last
    }

    /// "The answer has two parts: HCF and LCM." Nil when the answer is one thing.
    var answerPartsLine: String? {
        answerPartsPhrase.map { "The answer has \(Self.spelled(answerKey.parts.count)) parts: \($0)." }
    }

    private static func spelled(_ count: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        formatter.locale = Locale(identifier: "en_GB")
        return formatter.string(from: NSNumber(value: count)) ?? "\(count)"
    }

    var sourceBadgeTitle: String {
        sourceBook == "workbook" ? "Companion Workbook · \(tier)" : "OUP Student Book · \(tier)"
    }

    /// Domain-semantic manipulative classification derived from topic, widget, and prompt metadata.
    var cpaManipulativeDomain: String {
        let corpus = "\(topicCode) \(linkedWidget) \(bookSection) \(prompt)".lowercased()
        if corpus.contains("expand") || corpus.contains("factoris") || corpus.contains("quadratic")
            || corpus.contains("al-khwarizmi") || unitNumber == 2 || unitNumber == 13 {
            return "algebraic_area"
        }
        if corpus.contains("angle") || corpus.contains("polygon") || corpus.contains("pythagoras")
            || corpus.contains("bearing") || corpus.contains("vector") || corpus.contains("prism")
            || corpus.contains("circle") || [3, 5, 8, 16].contains(unitNumber) {
            return "geometric_angle_vector"
        }
        return "unitary_bar_partition"
    }
}

// MARK: - Visual Proof & Construction Recall Plates

struct DiagramRecallPlate: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let sourceRef: String
    let unitNumber: Int
    let chapter: Int
    let figureId: String
    let aspectRatio: Double
    let callouts: [DiagramCalloutPin]

    var topicCode: String { sourceRef }
    var livingWorldChapter: Int { chapter }
    var subtitle: String { "\(sourceRef) · Figure: \(figureId)" }
}

struct DiagramCalloutPin: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let label: String
    let x: Double
    let y: Double
    let hint: String

    var xFraction: Double { x }
    var yFraction: Double { y }
}

// MARK: - Pólya Studio, SpeedMath & Visual MathTips

struct PolyaStageSpec: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let phaseNumber: Int
    let title: String
    let subtitle: String
    let symbol: String
    let prompts: [String]
    let exampleProblem: String
    let phaseBreakdown: String

    var stageNumber: Int { phaseNumber }
    var singaporeConnection: String { "\(exampleProblem)\n\n\(phaseBreakdown)" }
}

struct SpeedMathDeck: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let heuristic: String
    let cards: [SpeedMathCard]

    var symbol: String { "bolt.fill" }
    var targetSeconds: Int { 8 }
}

struct SpeedMathCard: Codable, Identifiable, Equatable, Sendable {
    var id: String { prompt }
    let prompt: String
    let hint: String
    let answer: String

    var mentalTip: String { hint }
}

struct VisualMathTip: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let chapter: Int
    let visualIntuition: String
    let ahaMoment: String
    let formula: String

    var category: String { "Patterned World Ch \(chapter)" }
    var visualIdea: String { visualIntuition }
    var algebraicIdentity: String { formula }
    var example: String { ahaMoment }
}

// MARK: - Seed Pack Loader

enum SeedPackLoader {
    static func load() -> KymMathsSeedPack {
        shared
    }

    static let shared: KymMathsSeedPack = {
        do {
            return try loadFromBundle()
        } catch {
            assertionFailure("Seed pack failed to load: \(error)")
            NSLog("KymMaths: seed pack failed to load, starting empty: %@", String(describing: error))
            return fallbackPack()
        }
    }()

    static func loadFromBundle() throws -> KymMathsSeedPack {
        guard let url = KymResources.url(forResource: "kymmaths-seed-pack", withExtension: "json", subdirectory: "ContentPacks") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode(KymMathsSeedPack.self, from: Data(contentsOf: url))
    }

    static func fallbackPack() -> KymMathsSeedPack {
        KymMathsSeedPack(
            schemaVersion: 1,
            packId: "fallback",
            generatedBy: "fallback",
            volumes: [],
            chapters: [],
            explorers: [],
            atlasLessons: [],
            widgets: [],
            crossDisciplinaryBridges: [],
            schoolTextbook: SchoolMathsTextbook(
                id: "oup-complete-maths-8-2ed",
                title: "Cambridge Lower Secondary Complete Mathematics 8 (Second Edition)",
                authors: "Deborah Barton",
                publisher: "Oxford University Press",
                curriculumCode: "0862",
                learnersBookTotalPages: 260,
                workbookTotalPages: 192,
                units: []
            ),
            schoolQuestions: [],
            diagramPlates: [],
            polyaStages: [],
            speedMathDecks: [],
            visualMathTips: [],
            misconceptions: [],
            footings: [],
            concepts: [],
            conceptStopPhrases: []
        )
    }
}
