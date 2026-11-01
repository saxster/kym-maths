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
    let intuitionToFormula: IntuitionToFormulaBridge
    let sections: [PatternedWorldSection]
    let callouts: [PatternedWorldCallout]
    let keyTerms: [String]
    let widgets: [String]
}

struct PatternedWorldSection: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let heading: String
    let excerpt: String
}

struct PatternedWorldCallout: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let kind: String      // predict, check, recall, careful, school, home, case
    let title: String
    let body: String

    var badgeText: String {
        switch kind {
        case "predict": return "Predict first"
        case "check": return "Intuition → Formula"
        case "recall": return "Recall"
        case "careful": return "Algebraic trap"
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
    let markSchemeKeywords: [String]
    let linkedChapter: Int
    let linkedWidget: String

    var sourceBadgeTitle: String {
        sourceBook == "workbook" ? "Companion Workbook · \(tier)" : "OUP Student Book · \(tier)"
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
            return fallbackPack()
        }
    }()

    static func loadFromBundle() throws -> KymMathsSeedPack {
        let candidateURLs: [URL?] = [
            Bundle.main.url(forResource: "kymmaths-seed-pack", withExtension: "json", subdirectory: "ContentPacks"),
            Bundle.main.url(forResource: "kymmaths-seed-pack", withExtension: "json"),
            URL(fileURLWithPath: "/Users/amarsukhi/src/MyCode/kym_maths/KymMaths/KymMaths/Resources/ContentPacks/kymmaths-seed-pack.json")
        ]
        for case let url? in candidateURLs where FileManager.default.fileExists(atPath: url.path) {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(KymMathsSeedPack.self, from: data)
        }
        throw CocoaError(.fileNoSuchFile)
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
            visualMathTips: []
        )
    }
}
