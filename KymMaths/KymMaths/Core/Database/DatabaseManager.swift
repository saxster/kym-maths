import Foundation
import GRDB

// MARK: - Question Proof Level

enum QuestionProofLevel: String, Codable, CaseIterable, Sendable {
    case unseen
    case assisted       // Used hint, worked example, or faded completion
    case shaky          // Attempted independently but missed mark-scheme targets
    case proven         // Answered independently on the current day
    case secure         // Proven across 2+ spaced calendar days

    var displayTitle: String {
        switch self {
        case .unseen: return "Not tried yet"
        case .assisted: return "Assisted practice"
        case .shaky: return "Needs another try"
        case .proven: return "Proven today"
        case .secure: return "Secure across days"
        }
    }

    var isIndependentProof: Bool {
        self == .proven || self == .secure
    }
}

// MARK: - GRDB Records

struct QuestionProofRecord: Codable, FetchableRecord, PersistableRecord, Identifiable, Equatable, Sendable {
    static let databaseTableName = "question_proofs"

    var id: String                  // questionId
    var unitNumber: Int
    var topicCode: String
    var proofLevel: String          // QuestionProofLevel.rawValue
    var independentPassDays: Int
    var lastIndependentPassDayKey: String?
    var lastAttemptAt: Date
    var lastAnswerText: String
    var lastUsedAssistance: Bool
    var matchedKeywordsCSV: String
    var missingKeywordsCSV: String

    var level: QuestionProofLevel {
        QuestionProofLevel(rawValue: proofLevel) ?? .unseen
    }
}

struct FSRSCardRecord: Codable, FetchableRecord, PersistableRecord, Identifiable, Equatable, Sendable {
    static let databaseTableName = "fsrs_cards"

    var id: String
    var topicCode: String
    var chapterNumber: Int
    var frontPrompt: String
    var backAnswer: String
    var stability: Double
    var difficulty: Double
    var elapsedDays: Double
    var scheduledDays: Double
    var reps: Int
    var lapses: Int
    var state: Int                  // 0=new, 1=learning, 2=review, 3=relearning
    var dueAt: Date
    var lastReviewAt: Date?
}

struct BKTSkillRecord: Codable, FetchableRecord, PersistableRecord, Identifiable, Equatable, Sendable {
    static let databaseTableName = "bkt_skills"

    var id: String                  // topicCode or chapterId
    var title: String
    var pLearned: Double
    var pTransit: Double
    var pSlip: Double
    var pGuess: Double
    var independentEvidenceCount: Int
    var assistedEvidenceCount: Int
    var updatedAt: Date
}

struct LabJournalEntryRecord: Codable, FetchableRecord, PersistableRecord, Identifiable, Equatable, Sendable {
    static let databaseTableName = "lab_journal_entries"

    var id: String
    var title: String
    var templateKind: String        // free, cornell, proof_log, construction, lab_log
    var paperStyle: String          // blank, lined, grid, dots, cornell
    var linkedTopicCode: String?
    var linkedChapterNumber: Int?
    var linkedWidgetId: String?
    var cueColumnText: String
    var bodyNotesText: String
    var summaryText: String
    var hypothesisText: String      // Conjecture / Theorem Statement
    var independentVarText: String  // Given Data & Invariants
    var dependentVarText: String    // Target Unknown / To Prove
    var controlVarsText: String     // Pólya Heuristic & Construction Steps
    var drawingData: Data?
    var snapshotPNGData: Data?
    var createdAt: Date
    var updatedAt: Date
}

struct ScratchpadRecord: Codable, FetchableRecord, PersistableRecord, Identifiable, Equatable, Sendable {
    static let databaseTableName = "question_scratchpads"

    var id: String                  // questionId + "::attempt::" + attemptNumber
    var questionId: String
    var attemptNumber: Int
    var paperStyle: String
    var stampKind: String?          // singapore_bar, cartesian_axes, unit_circle, venn_2set, prime_tree, truth_table, matrix_grid, number_line
    var drawingData: Data
    var previewPNGData: Data
    var strokeCount: Int
    var updatedAt: Date
}

struct DiagramRecallAttemptRecord: Codable, FetchableRecord, PersistableRecord, Identifiable, Equatable, Sendable {
    static let databaseTableName = "diagram_recall_attempts"

    var id: String
    var plateId: String
    var mode: String                // label_only, ghost_scaffold, blank_recall
    var correctCalloutsCount: Int
    var totalCalloutsCount: Int
    var drawingData: Data?
    var selfScore: Int              // 1..5
    var completedAt: Date
}

struct WidgetChallengeStampRecord: Codable, FetchableRecord, PersistableRecord, Identifiable, Equatable, Sendable {
    static let databaseTableName = "widget_challenge_stamps"

    var id: String                  // widgetId
    var chapterNumber: Int
    var earnedAt: Date
    var readoutSnapshot: String
}

struct ChapterReadingProgressRecord: Codable, FetchableRecord, PersistableRecord, Identifiable, Equatable, Sendable {
    static let databaseTableName = "chapter_reading_progress"

    var id: String                  // ch00..ch20
    var chapterNumber: Int
    var readFraction: Double
    var predictionsCompleted: Int
    var checksCompleted: Int
    var updatedAt: Date
}

struct SchoolDeadlineRecord: Codable, FetchableRecord, PersistableRecord, Identifiable, Equatable, Sendable {
    static let databaseTableName = "school_deadlines"

    var id: String
    var title: String
    var unitNumbersCSV: String      // e.g. "1,2,6,7,9"
    var dueAt: Date
    var kind: String                // unit_test, checkpoint_review, companion_workbook
    var notes: String
}

public struct CapturedTextbookPageRecord: Codable, FetchableRecord, PersistableRecord, Identifiable, Equatable, Sendable {
    public static let databaseTableName = "captured_textbook_pages"

    public var id: String
    public var topicId: String
    public var bookType: String     // learners_book or workbook
    public var pageNumber: Int
    public var ocrText: String
    public var capturedAt: Date
}

struct CalloutResponseRecord: Codable, FetchableRecord, PersistableRecord, Identifiable, Equatable, Sendable {
    static let databaseTableName = "callout_responses"

    var id: String                  // calloutId
    var chapterNumber: Int
    var responseText: String
    var isUnlocked: Bool
    var updatedAt: Date
}

struct KBChapterRecord: Codable, FetchableRecord, PersistableRecord, Identifiable, Equatable, Sendable {
    static let databaseTableName = "kb_chapters"

    var id: String
    var chapterNumber: Int
    var volumeNumber: Int
    var title: String
    var hookSummary: String
    var formulaDisplay: String
    var keyTermsCSV: String
}

struct KBSchoolTopicRecord: Codable, FetchableRecord, PersistableRecord, Identifiable, Equatable, Sendable {
    static let databaseTableName = "kb_school_topics"

    var id: String
    var unitNumber: Int
    var code: String
    var title: String
    var learnersBookPage: Int
    var workbookPage: Int
    var summary: String
    var watchoutsText: String
}

// MARK: - 3-Database GRDB Manager (KB + State + Mnemosyne + Shared Science Spine)

final class DatabaseManager: Sendable {
    static let shared = DatabaseManager()

    let kbPool: DatabaseWriter
    let statePool: DatabaseWriter
    let mnemosynePool: DatabaseWriter

    init(inMemory: Bool = false) {
        if inMemory {
            let kb = try! DatabaseQueue()
            let state = try! DatabaseQueue()
            let mnem = try! DatabaseQueue()
            self.kbPool = kb
            self.statePool = state
            self.mnemosynePool = mnem
        } else {
            let baseDir = Self.resolveDatabaseDirectory()
            try? FileManager.default.createDirectory(at: baseDir, withIntermediateDirectories: true)
            let kbURL = baseDir.appendingPathComponent("kb.sqlite")
            let stateURL = baseDir.appendingPathComponent("state.sqlite")
            let mnemURL = baseDir.appendingPathComponent("mnemosyne.sqlite")
            self.kbPool = try! DatabasePool(path: kbURL.path)
            self.statePool = try! DatabasePool(path: stateURL.path)
            self.mnemosynePool = try! DatabasePool(path: mnemURL.path)
        }

        try! Self.migrateKB(kbPool)
        try! Self.migrateState(statePool)
        try! Self.migrateMnemosyne(mnemosynePool)
        try! seedInitialDataIfNeeded()
    }

    private static func resolveDatabaseDirectory() -> URL {
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.kymaia.science") {
            return groupURL.appendingPathComponent("KymMathsDB", isDirectory: true)
        }
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("KymMaths", isDirectory: true)
    }

    private static func migrateKB(_ writer: DatabaseWriter) throws {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1_kb") { db in
            try db.create(table: "kb_metadata", ifNotExists: true) { t in
                t.primaryKey("key", .text)
                t.column("value", .text).notNull()
            }
            try db.create(table: KBChapterRecord.databaseTableName, ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("chapterNumber", .integer).notNull()
                t.column("volumeNumber", .integer).notNull()
                t.column("title", .text).notNull()
                t.column("hookSummary", .text).notNull()
                t.column("formulaDisplay", .text).notNull()
                t.column("keyTermsCSV", .text).notNull()
            }
            try db.create(table: KBSchoolTopicRecord.databaseTableName, ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("unitNumber", .integer).notNull()
                t.column("code", .text).notNull()
                t.column("title", .text).notNull()
                t.column("learnersBookPage", .integer).notNull()
                t.column("workbookPage", .integer).notNull()
                t.column("summary", .text).notNull()
                t.column("watchoutsText", .text).notNull()
            }
        }
        try migrator.migrate(writer)
    }

    private static func migrateState(_ writer: DatabaseWriter) throws {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1_state") { db in
            try db.create(table: QuestionProofRecord.databaseTableName, ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("unitNumber", .integer).notNull()
                t.column("topicCode", .text).notNull()
                t.column("proofLevel", .text).notNull()
                t.column("independentPassDays", .integer).notNull().defaults(to: 0)
                t.column("lastIndependentPassDayKey", .text)
                t.column("lastAttemptAt", .datetime).notNull()
                t.column("lastAnswerText", .text).notNull()
                t.column("lastUsedAssistance", .boolean).notNull()
                t.column("matchedKeywordsCSV", .text).notNull()
                t.column("missingKeywordsCSV", .text).notNull()
            }

            try db.create(table: FSRSCardRecord.databaseTableName, ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("topicCode", .text).notNull()
                t.column("chapterNumber", .integer).notNull()
                t.column("frontPrompt", .text).notNull()
                t.column("backAnswer", .text).notNull()
                t.column("stability", .double).notNull()
                t.column("difficulty", .double).notNull()
                t.column("elapsedDays", .double).notNull()
                t.column("scheduledDays", .double).notNull()
                t.column("reps", .integer).notNull()
                t.column("lapses", .integer).notNull()
                t.column("state", .integer).notNull()
                t.column("dueAt", .datetime).notNull()
                t.column("lastReviewAt", .datetime)
            }

            try db.create(table: BKTSkillRecord.databaseTableName, ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("title", .text).notNull()
                t.column("pLearned", .double).notNull()
                t.column("pTransit", .double).notNull()
                t.column("pSlip", .double).notNull()
                t.column("pGuess", .double).notNull()
                t.column("independentEvidenceCount", .integer).notNull()
                t.column("assistedEvidenceCount", .integer).notNull()
                t.column("updatedAt", .datetime).notNull()
            }

            try db.create(table: WidgetChallengeStampRecord.databaseTableName, ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("chapterNumber", .integer).notNull()
                t.column("earnedAt", .datetime).notNull()
                t.column("readoutSnapshot", .text).notNull()
            }

            try db.create(table: ChapterReadingProgressRecord.databaseTableName, ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("chapterNumber", .integer).notNull()
                t.column("readFraction", .double).notNull()
                t.column("predictionsCompleted", .integer).notNull()
                t.column("checksCompleted", .integer).notNull()
                t.column("updatedAt", .datetime).notNull()
            }

            try db.create(table: SchoolDeadlineRecord.databaseTableName, ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("title", .text).notNull()
                t.column("unitNumbersCSV", .text).notNull()
                t.column("dueAt", .datetime).notNull()
                t.column("kind", .text).notNull()
                t.column("notes", .text).notNull()
            }

            try db.create(table: CapturedTextbookPageRecord.databaseTableName, ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("topicId", .text).notNull()
                t.column("bookType", .text).notNull()
                t.column("pageNumber", .integer).notNull()
                t.column("ocrText", .text).notNull()
                t.column("capturedAt", .datetime).notNull()
            }

            try db.create(table: CalloutResponseRecord.databaseTableName, ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("chapterNumber", .integer).notNull()
                t.column("responseText", .text).notNull()
                t.column("isUnlocked", .boolean).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
        }
        try migrator.migrate(writer)
    }

    private static func migrateMnemosyne(_ writer: DatabaseWriter) throws {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1_mnemosyne") { db in
            try db.create(table: LabJournalEntryRecord.databaseTableName, ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("title", .text).notNull()
                t.column("templateKind", .text).notNull()
                t.column("paperStyle", .text).notNull()
                t.column("linkedTopicCode", .text)
                t.column("linkedChapterNumber", .integer)
                t.column("linkedWidgetId", .text)
                t.column("cueColumnText", .text).notNull()
                t.column("bodyNotesText", .text).notNull()
                t.column("summaryText", .text).notNull()
                t.column("hypothesisText", .text).notNull()
                t.column("independentVarText", .text).notNull()
                t.column("dependentVarText", .text).notNull()
                t.column("controlVarsText", .text).notNull()
                t.column("drawingData", .blob)
                t.column("snapshotPNGData", .blob)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }

            try db.create(table: ScratchpadRecord.databaseTableName, ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("questionId", .text).notNull()
                t.column("attemptNumber", .integer).notNull()
                t.column("paperStyle", .text).notNull()
                t.column("stampKind", .text)
                t.column("drawingData", .blob).notNull()
                t.column("previewPNGData", .blob).notNull()
                t.column("strokeCount", .integer).notNull()
                t.column("updatedAt", .datetime).notNull()
            }

            try db.create(table: DiagramRecallAttemptRecord.databaseTableName, ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("plateId", .text).notNull()
                t.column("mode", .text).notNull()
                t.column("correctCalloutsCount", .integer).notNull()
                t.column("totalCalloutsCount", .integer).notNull()
                t.column("drawingData", .blob)
                t.column("selfScore", .integer).notNull()
                t.column("completedAt", .datetime).notNull()
            }
        }
        try migrator.migrate(writer)
    }

    func seedInitialDataIfNeeded() throws {
        let pack = SeedPackLoader.shared
        let now = Date()

        try kbPool.write { db in
            let existingKBChapters = try KBChapterRecord.fetchCount(db)
            if existingKBChapters == 0 {
                for ch in pack.chapters {
                    let rec = KBChapterRecord(
                        id: ch.id,
                        chapterNumber: ch.number,
                        volumeNumber: ch.volumeNumber,
                        title: ch.title,
                        hookSummary: ch.hookSummary,
                        formulaDisplay: ch.intuitionToFormula.formulaDisplay,
                        keyTermsCSV: ch.keyTerms.joined(separator: ", ")
                    )
                    try rec.save(db)
                }
                for unit in pack.schoolTextbook.units {
                    for topic in unit.topics {
                        let rec = KBSchoolTopicRecord(
                            id: topic.id,
                            unitNumber: unit.unitNumber,
                            code: topic.code,
                            title: topic.title,
                            learnersBookPage: topic.learnersBookPage,
                            workbookPage: topic.workbookPage,
                            summary: topic.summary,
                            watchoutsText: topic.cambridgeWatchouts.joined(separator: " | ")
                        )
                        try rec.save(db)
                    }
                }
            }
        }

        try statePool.write { db in
            let existingCards = try FSRSCardRecord.fetchCount(db)
            if existingCards == 0 {
                for q in pack.schoolQuestions {
                    let card = FSRSCardRecord(
                        id: "card-\(q.id)",
                        topicCode: q.topicCode,
                        chapterNumber: q.linkedChapter,
                        frontPrompt: q.prompt,
                        backAnswer: q.modelAnswer,
                        stability: 1.8,
                        difficulty: 4.5,
                        elapsedDays: 0,
                        scheduledDays: 1,
                        reps: 0,
                        lapses: 0,
                        state: 0,
                        dueAt: now,
                        lastReviewAt: nil
                    )
                    try card.save(db)
                }
            }

            let existingSkills = try BKTSkillRecord.fetchCount(db)
            if existingSkills == 0 {
                for unit in pack.schoolTextbook.units {
                    for topic in unit.topics {
                        let initialPLearned: Double
                        switch unit.schoolStatus {
                        case "ticked": initialPLearned = 0.62
                        case "circled": initialPLearned = 0.42
                        default: initialPLearned = 0.25
                        }
                        let skill = BKTSkillRecord(
                            id: topic.code,
                            title: "\(topic.code) \(topic.title)",
                            pLearned: initialPLearned,
                            pTransit: 0.18,
                            pSlip: 0.10,
                            pGuess: 0.15,
                            independentEvidenceCount: 0,
                            assistedEvidenceCount: 0,
                            updatedAt: now
                        )
                        try skill.save(db)
                    }
                }
            }

            let existingDeadlines = try SchoolDeadlineRecord.fetchCount(db)
            if existingDeadlines == 0 {
                let cal = Calendar.current
                let circledReview = SchoolDeadlineRecord(
                    id: "deadline-circled-algebra-number",
                    title: "Circled Chapters Proof (Ch 1, 2, 6, 7 & 9)",
                    unitNumbersCSV: "1,2,6,7,9",
                    dueAt: cal.date(byAdding: .day, value: 6, to: now) ?? now,
                    kind: "unit_test",
                    notes: "Integers & HCF/LCM (Ch 1), Expressions (Ch 2), Fractions & Recurring Decimals (Ch 6), Equations & Formulae (Ch 7), and Percentages (Ch 9)."
                )
                let horizonStretch = SchoolDeadlineRecord(
                    id: "deadline-horizon-trig-bayes-calc",
                    title: "Horizon Milestone: Set Theory, Unit Circle, Bayes & Calculus",
                    unitNumbersCSV: "3,5,12,15,16",
                    dueAt: cal.date(byAdding: .day, value: 14, to: now) ?? now,
                    kind: "checkpoint_review",
                    notes: "Visual Intuition → Formula proofs across Unit Circle (Ch 12), Bayes' 1,000-Person Square (Ch 15–16), Derivatives/Integrals (Ch 17–18), and 2×2 Matrices (Ch 20)."
                )
                try circledReview.save(db)
                try horizonStretch.save(db)
            }
        }

        try mnemosynePool.write { db in
            let existingEntries = try LabJournalEntryRecord.fetchCount(db)
            if existingEntries == 0 {
                let starter = LabJournalEntryRecord(
                    id: "journal-starter-intuition-to-formula",
                    title: "Ch 12 & Ch 20 — How shadows become sin²θ + cos²θ = 1 and parallelograms become det(A) = ad − bc",
                    templateKind: "proof_log",
                    paperStyle: "cornell",
                    linkedTopicCode: "16.2",
                    linkedChapterNumber: 12,
                    linkedWidgetId: "w_atlas_unit_circle",
                    cueColumnText: "1. Why is sin θ the vertical shadow?\n2. Why does sin²θ + cos²θ = 1 for every angle?\n3. Why is det(A) = ad − bc the universal area scale factor?",
                    bodyNotesText: "• On the @saxster/atlas unit circle of radius 1, level light casts vertical shadow sin θ (red) and top light casts horizontal shadow cos θ (blue).\n• Those two shadows form a right triangle with hypotenuse OP = 1, so Pythagoras gives sin²θ + cos²θ = 1².\n• In the 2×2 Matrix Sandbox, column 1 (a, c) is where î lands and column 2 (b, d) is where ĵ lands; subtracting the four corner triangles from the (a+b)×(c+d) box leaves exact area ad − bc.",
                    summaryText: "A formula is a compressed picture: every symbol in sin²θ + cos²θ = 1 and det(A) = ad − bc records a geometric invariant you can see and drag.",
                    hypothesisText: "For any angle θ on the unit circle, the areas of the red (sin²θ) and blue (cos²θ) leg-squares sum to the 1×1 radius square.",
                    independentVarText: "Angle θ ∈ [0°, 360°] and basis vectors Aî = (a, c), Aĵ = (b, d)",
                    dependentVarText: "Shadow lengths (cos θ, sin θ) and parallelogram area det(A) = ad − bc",
                    controlVarsText: "Pólya Strategy: Draw the auxiliary bounding box and use area conservation.",
                    drawingData: nil,
                    snapshotPNGData: nil,
                    createdAt: now,
                    updatedAt: now
                )
                try starter.save(db)
            }
        }
    }

    // MARK: - Repository CRUD & Knowledge Base Search Methods

    func fetchAllProofs() throws -> [QuestionProofRecord] {
        try statePool.read { db in
            try QuestionProofRecord.fetchAll(db)
        }
    }

    func saveQuestionProof(_ record: QuestionProofRecord) throws {
        try statePool.write { db in
            try record.save(db)
        }
    }

    func fetchAllFSRSCards() throws -> [FSRSCardRecord] {
        try statePool.read { db in
            try FSRSCardRecord.order(Column("dueAt").asc).fetchAll(db)
        }
    }

    func saveFSRSCard(_ card: FSRSCardRecord) throws {
        try statePool.write { db in
            try card.save(db)
        }
    }

    func fetchAllBKTSkills() throws -> [BKTSkillRecord] {
        try statePool.read { db in
            try BKTSkillRecord.fetchAll(db)
        }
    }

    func saveBKTSkill(_ skill: BKTSkillRecord) throws {
        try statePool.write { db in
            try skill.save(db)
        }
    }

    func fetchJournalEntries() throws -> [LabJournalEntryRecord] {
        try mnemosynePool.read { db in
            try LabJournalEntryRecord.order(Column("updatedAt").desc).fetchAll(db)
        }
    }

    func saveJournalEntry(_ entry: LabJournalEntryRecord) throws {
        try mnemosynePool.write { db in
            try entry.save(db)
        }
    }

    func deleteJournalEntry(id: String) throws {
        try mnemosynePool.write { db in
            _ = try LabJournalEntryRecord.deleteOne(db, key: id)
        }
    }

    func fetchDiagramAttempts() throws -> [DiagramRecallAttemptRecord] {
        try mnemosynePool.read { db in
            try DiagramRecallAttemptRecord.order(Column("completedAt").desc).fetchAll(db)
        }
    }

    func saveDiagramAttempt(_ attempt: DiagramRecallAttemptRecord) throws {
        try mnemosynePool.write { db in
            try attempt.save(db)
        }
    }

    func fetchWidgetStamps() throws -> [WidgetChallengeStampRecord] {
        try statePool.read { db in
            try WidgetChallengeStampRecord.fetchAll(db)
        }
    }

    func saveWidgetStamp(_ stamp: WidgetChallengeStampRecord) throws {
        try statePool.write { db in
            try stamp.save(db)
        }
    }

    func fetchChapterReadingProgress() throws -> [ChapterReadingProgressRecord] {
        try statePool.read { db in
            try ChapterReadingProgressRecord.fetchAll(db)
        }
    }

    func saveChapterReadingProgress(_ progress: ChapterReadingProgressRecord) throws {
        try statePool.write { db in
            try progress.save(db)
        }
    }

    func fetchDeadlines() throws -> [SchoolDeadlineRecord] {
        try statePool.read { db in
            try SchoolDeadlineRecord.order(Column("dueAt").asc).fetchAll(db)
        }
    }

    func saveDeadline(_ deadline: SchoolDeadlineRecord) throws {
        try statePool.write { db in
            try deadline.save(db)
        }
    }

    func deleteDeadline(id: String) throws {
        try statePool.write { db in
            _ = try SchoolDeadlineRecord.deleteOne(db, key: id)
        }
    }

    func fetchCapturedPages() throws -> [CapturedTextbookPageRecord] {
        try statePool.read { db in
            try CapturedTextbookPageRecord.order(Column("capturedAt").desc).fetchAll(db)
        }
    }

    func saveCapturedPage(_ page: CapturedTextbookPageRecord) throws {
        try statePool.write { db in
            try page.save(db)
        }
    }

    func fetchCalloutResponses() throws -> [CalloutResponseRecord] {
        try statePool.read { db in
            try CalloutResponseRecord.fetchAll(db)
        }
    }

    func saveCalloutResponse(_ record: CalloutResponseRecord) throws {
        try statePool.write { db in
            try record.save(db)
        }
    }

    func saveScratchpad(_ record: ScratchpadRecord) throws {
        try mnemosynePool.write { db in
            try record.save(db)
        }
    }

    func fetchLatestScratchpad(forQuestionId questionId: String) throws -> ScratchpadRecord? {
        try mnemosynePool.read { db in
            try ScratchpadRecord
                .filter(Column("questionId") == questionId)
                .order(Column("updatedAt").desc)
                .fetchOne(db)
        }
    }

    func searchKnowledgeBase(query: String) throws -> (chapters: [KBChapterRecord], topics: [KBSchoolTopicRecord]) {
        let pattern = "%\(query.trimmingCharacters(in: .whitespacesAndNewlines))%"
        return try kbPool.read { db in
            let chapters = try KBChapterRecord
                .filter(
                    Column("title").like(pattern)
                    || Column("hookSummary").like(pattern)
                    || Column("formulaDisplay").like(pattern)
                    || Column("keyTermsCSV").like(pattern)
                )
                .fetchAll(db)
            let topics = try KBSchoolTopicRecord
                .filter(
                    Column("title").like(pattern)
                    || Column("summary").like(pattern)
                    || Column("watchoutsText").like(pattern)
                    || Column("code").like(pattern)
                )
                .fetchAll(db)
            return (chapters, topics)
        }
    }
}
