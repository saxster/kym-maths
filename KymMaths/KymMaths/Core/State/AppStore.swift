import Foundation
import Observation
import SwiftUI

// MARK: - Primary Rooms (Maximum 7 Top-Level Rooms)

enum AppRoom: String, CaseIterable, Identifiable, Sendable {
    case today
    case schoolMaths
    case patternedWorld
    case labsAtlas
    case polyaFluency
    case mathsJournal
    case coach

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return "Today"
        case .schoolMaths: return "School Maths 8"
        case .patternedWorld: return "Patterned World"
        case .labsAtlas: return "3D Atlas & Diagrams"
        case .polyaFluency: return "Pólya & SpeedMath"
        case .mathsJournal: return "Proof Journal"
        case .coach: return "Maths Coach"
        }
    }

    var shortTitle: String {
        switch self {
        case .today: return "Today"
        case .schoolMaths: return "OUP Ch 1–16"
        case .patternedWorld: return "Patterned World"
        case .labsAtlas: return "3D Atlas"
        case .polyaFluency: return "Pólya & Speed"
        case .mathsJournal: return "Journal"
        case .coach: return "Coach"
        }
    }

    var systemImage: String {
        switch self {
        case .today: return "sun.max.fill"
        case .schoolMaths: return "book.closed.fill"
        case .patternedWorld: return "sparkles.rectangle.stack.fill"
        case .labsAtlas: return "cube.transparent.fill"
        case .polyaFluency: return "bolt.badge.clock.fill"
        case .mathsJournal: return "square.and.pencil"
        case .coach: return "bubble.left.and.text.bubble.right.fill"
        }
    }
}

// MARK: - Observable AppStore

@MainActor
@Observable
final class AppStore {
    let db: DatabaseManager
    let seedPack: KymMathsSeedPack

    // Navigation
    var activeRoom: AppRoom = .today
    var colorScheme: CuratedColorScheme
    var selectedUnitNumber: Int = 1
    var selectedTopicCode: String = "1.1"
    var selectedChapterNumber: Int = 0
    var selectedWidgetId: String = "prime-factor-lattice"
    var selectedDiagramPlateId: String = "plate-prime-sieve-venn"
    var selectedPolyaStageId: String = "polya-1-understand"
    var selectedSpeedDeckId: String = "deck-squares-cubes"
    var activePracticeQuestion: SchoolMathsQuestion?
    var showCalendarSheet: Bool = false
    var showSettingsSheet: Bool = false

    // Customisation & Preferences (persisted in UserDefaults)
    var learnerDisplayName: String {
        didSet { UserDefaults.standard.set(learnerDisplayName, forKey: "kymmaths.pref.learnerName") }
    }
    var selectedCurriculumLens: MathsCurriculumLens {
        didSet { UserDefaults.standard.set(selectedCurriculumLens.rawValue, forKey: "kymmaths.pref.curriculumLens") }
    }
    var defaultWorkbookTier: CompanionWorkbookTierFilter {
        didSet { UserDefaults.standard.set(defaultWorkbookTier.rawValue, forKey: "kymmaths.pref.workbookTier") }
    }
    var showSingaporeBarModelsByDefault: Bool {
        didSet { UserDefaults.standard.set(showSingaporeBarModelsByDefault, forKey: "kymmaths.pref.showBarModels") }
    }
    var showIntuitionBeforeFormula: Bool {
        didSet { UserDefaults.standard.set(showIntuitionBeforeFormula, forKey: "kymmaths.pref.intuitionFirst") }
    }
    var enableAdvancedHorizonModules: Bool {
        didSet { UserDefaults.standard.set(enableAdvancedHorizonModules, forKey: "kymmaths.pref.enableHorizon") }
    }
    var dailyPracticeGoalMinutes: Int {
        didSet { UserDefaults.standard.set(dailyPracticeGoalMinutes, forKey: "kymmaths.pref.dailyGoalMinutes") }
    }
    var defaultScratchpadPaperStyle: String {
        didSet { UserDefaults.standard.set(defaultScratchpadPaperStyle, forKey: "kymmaths.pref.scratchpadPaper") }
    }

    // AI Mentor, Constitution & Guardrail Preferences (Ported from ../kym_tutor)
    var selectedSoulId: String {
        didSet { UserDefaults.standard.set(selectedSoulId, forKey: "kymmaths.pref.soulId") }
    }
    var requestedGuidanceStyle: TutorGuidanceStyle {
        didSet { UserDefaults.standard.set(requestedGuidanceStyle.rawValue, forKey: "kymmaths.pref.guidanceStyle") }
    }
    var aiFeaturePolicy: AIFeaturePolicy {
        didSet {
            UserDefaults.standard.set(aiFeaturePolicy.rawValue, forKey: "kymmaths.pref.aiPolicy")
            syncAIProviderConfig()
        }
    }
    var defaultAIProvider: AIProvider {
        didSet {
            UserDefaults.standard.set(defaultAIProvider.rawValue, forKey: "kymmaths.pref.aiProvider")
            syncAIProviderConfig()
        }
    }
    var allowRemoteCameraAIAnalysis: Bool {
        didSet {
            UserDefaults.standard.set(allowRemoteCameraAIAnalysis, forKey: "kymmaths.pref.allowRemoteCamera")
            syncAIProviderConfig()
        }
    }
    var soulParentOverrides: [String: String] {
        didSet {
            let safe = AgentSoulOverridePolicy.safeOverrides(from: soulParentOverrides)
            UserDefaults.standard.set(safe, forKey: "kymmaths.pref.soulOverrides")
        }
    }

    // AI Mentor Runtime State
    let safetyService = SafetyEscalationService()
    let aiRouter: PolicyDrivenAIProvider
    var currentUnderstandingPhase: UnderstandingPhase = .exploring
    var learnerTurnCount: Int = 0
    var mentorTurns: [MathsMentorTurn] = []
    var lastSafetyConcern: SafetyEscalationService.Concern?
    var didShareScratchpadWithCoach: Bool = false

    // Reactive Database State
    var proofsByQuestionId: [String: QuestionProofRecord] = [:]
    var fsrsCards: [FSRSCardRecord] = []
    var bktSkillsById: [String: BKTSkillRecord] = [:]
    var journalEntries: [LabJournalEntryRecord] = []
    var diagramAttempts: [DiagramRecallAttemptRecord] = []
    var widgetStampsById: [String: WidgetChallengeStampRecord] = [:]
    var readingProgressByChapter: [Int: ChapterReadingProgressRecord] = [:]
    var deadlines: [SchoolDeadlineRecord] = []
    var capturedPages: [CapturedTextbookPageRecord] = []
    var calloutResponses: [String: CalloutResponseRecord] = [:]

    init(db: DatabaseManager = .shared) {
        self.db = db
        self.seedPack = SeedPackLoader.load()
        self.colorScheme = CuratedColorScheme.loadSaved()

        let defaults = UserDefaults.standard
        self.learnerDisplayName = defaults.string(forKey: "kymmaths.pref.learnerName") ?? "Kym"
        self.selectedCurriculumLens = MathsCurriculumLens(
            rawValue: defaults.string(forKey: "kymmaths.pref.curriculumLens") ?? ""
        ) ?? .coreStage8Complete
        self.defaultWorkbookTier = CompanionWorkbookTierFilter(
            rawValue: defaults.string(forKey: "kymmaths.pref.workbookTier") ?? ""
        ) ?? .allTiers
        self.showSingaporeBarModelsByDefault = defaults.object(forKey: "kymmaths.pref.showBarModels") as? Bool ?? true
        self.showIntuitionBeforeFormula = defaults.object(forKey: "kymmaths.pref.intuitionFirst") as? Bool ?? true
        self.enableAdvancedHorizonModules = defaults.object(forKey: "kymmaths.pref.enableHorizon") as? Bool ?? true
        self.dailyPracticeGoalMinutes = defaults.object(forKey: "kymmaths.pref.dailyGoalMinutes") as? Int ?? 25
        self.defaultScratchpadPaperStyle = defaults.string(forKey: "kymmaths.pref.scratchpadPaper") ?? "grid"

        let savedSoul = defaults.string(forKey: "kymmaths.pref.soulId") ?? "polya"
        self.selectedSoulId = savedSoul
        self.requestedGuidanceStyle = TutorGuidanceStyle(
            rawValue: defaults.string(forKey: "kymmaths.pref.guidanceStyle") ?? ""
        ) ?? .adaptive
        let initialPolicy = AIFeaturePolicy(
            rawValue: defaults.string(forKey: "kymmaths.pref.aiPolicy") ?? ""
        ) ?? .localPreferred
        self.aiFeaturePolicy = initialPolicy
        let initialProvider = AIProvider(
            rawValue: defaults.string(forKey: "kymmaths.pref.aiProvider") ?? ""
        ) ?? .auto
        self.defaultAIProvider = initialProvider
        let initialRemoteConsent = defaults.object(forKey: "kymmaths.pref.allowRemoteCamera") as? Bool ?? false
        self.allowRemoteCameraAIAnalysis = initialRemoteConsent
        let rawOverrides = (defaults.dictionary(forKey: "kymmaths.pref.soulOverrides") as? [String: String]) ?? [
            "tone": "warm",
            "pacing": "steady",
            "response_length": "balanced",
            "analogy_preference": "use-when-helpful"
        ]
        self.soulParentOverrides = AgentSoulOverridePolicy.safeOverrides(from: rawOverrides)

        self.aiRouter = PolicyDrivenAIProvider(
            localProvider: LocalMathsConstitutionalProvider(),
            frontierProvider: FrontierMathsHTTPProvider(),
            defaultPolicy: initialPolicy,
            defaultProvider: initialProvider,
            allowRemoteCameraAIAnalysis: initialRemoteConsent
        )

        refreshState()
    }

    private func syncAIProviderConfig() {
        let policy = aiFeaturePolicy
        let provider = defaultAIProvider
        let remoteConsent = allowRemoteCameraAIAnalysis
        Task {
            await aiRouter.updateConfiguration(
                policy: policy,
                defaultProvider: provider,
                allowRemoteCameraAIAnalysis: remoteConsent
            )
        }
    }

    var activeSoul: AgentSoulDocument {
        AgentSoulCatalog.soul(for: selectedSoulId, overrides: soulParentOverrides)
    }

    func setTheme(_ scheme: CuratedColorScheme) {
        colorScheme = scheme
        scheme.persist()
    }

    func setSoulOverride(key: AgentSoulOverrideKey, value: String) {
        guard AgentSoulOverridePolicy.isAllowed(key: key.rawValue, value: value) else { return }
        var updated = soulParentOverrides
        updated[key.rawValue] = value
        soulParentOverrides = updated
    }

    func resetCustomisationDefaults() {
        setTheme(.journal)
        learnerDisplayName = "Kym"
        selectedCurriculumLens = .coreStage8Complete
        defaultWorkbookTier = .allTiers
        showSingaporeBarModelsByDefault = true
        showIntuitionBeforeFormula = true
        enableAdvancedHorizonModules = true
        dailyPracticeGoalMinutes = 25
        defaultScratchpadPaperStyle = "grid"
        selectedSoulId = "polya"
        requestedGuidanceStyle = .adaptive
        aiFeaturePolicy = .localPreferred
        defaultAIProvider = .auto
        allowRemoteCameraAIAnalysis = false
        soulParentOverrides = [
            "tone": "warm",
            "pacing": "steady",
            "response_length": "balanced",
            "analogy_preference": "use-when-helpful"
        ]
    }

    func refreshState() {
        let proofs = (try? db.fetchAllProofs()) ?? []
        proofsByQuestionId = Dictionary(uniqueKeysWithValues: proofs.map { ($0.id, $0) })
        fsrsCards = (try? db.fetchAllFSRSCards()) ?? []
        let skills = (try? db.fetchAllBKTSkills()) ?? []
        bktSkillsById = Dictionary(uniqueKeysWithValues: skills.map { ($0.id, $0) })
        journalEntries = (try? db.fetchJournalEntries()) ?? []
        diagramAttempts = (try? db.fetchDiagramAttempts()) ?? []
        let stamps = (try? db.fetchWidgetStamps()) ?? []
        widgetStampsById = Dictionary(uniqueKeysWithValues: stamps.map { ($0.id, $0) })
        let progress = (try? db.fetchChapterReadingProgress()) ?? []
        readingProgressByChapter = Dictionary(uniqueKeysWithValues: progress.map { ($0.chapterNumber, $0) })
        deadlines = (try? db.fetchDeadlines()) ?? []
        capturedPages = (try? db.fetchCapturedPages()) ?? []
        let callouts = (try? db.fetchCalloutResponses()) ?? []
        calloutResponses = Dictionary(uniqueKeysWithValues: callouts.map { ($0.id, $0) })

        SystemSurfaceSnapshotStore.writeSnapshot(from: self)
    }

    // MARK: - Computed Helpers

    var dueFSRSCards: [FSRSCardRecord] {
        let now = Date()
        return fsrsCards.filter { $0.dueAt <= now }
    }

    var visibleSchoolUnits: [SchoolMathsUnit] {
        seedPack.schoolTextbook.units(for: selectedCurriculumLens)
    }

    var visiblePatternedWorldChapters: [PatternedWorldChapter] {
        if enableAdvancedHorizonModules {
            return seedPack.chapters
        }
        return seedPack.chapters.filter { $0.volumeNumber <= 3 }
    }

    var selectedUnit: SchoolMathsUnit {
        seedPack.schoolTextbook.units.first(where: { $0.unitNumber == selectedUnitNumber })
            ?? seedPack.schoolTextbook.units[0]
    }

    var selectedTopic: SchoolMathsTopic {
        for unit in seedPack.schoolTextbook.units {
            if let topic = unit.topics.first(where: { $0.code == selectedTopicCode }) {
                return topic
            }
        }
        return selectedUnit.topics[0]
    }

    var selectedChapter: PatternedWorldChapter {
        seedPack.chapters.first(where: { $0.number == selectedChapterNumber })
            ?? seedPack.chapters[0]
    }

    var selectedWidget: InteractiveWidgetSpec {
        seedPack.widgets.first(where: { $0.id == selectedWidgetId })
            ?? seedPack.widgets[0]
    }

    var selectedDiagramPlate: DiagramRecallPlate {
        seedPack.diagramPlates.first(where: { $0.id == selectedDiagramPlateId })
            ?? seedPack.diagramPlates[0]
    }

    func questions(forUnit unitNumber: Int, tierFilter: CompanionWorkbookTierFilter = .allTiers) -> [SchoolMathsQuestion] {
        let all = seedPack.schoolQuestions.filter { $0.unitNumber == unitNumber }
        switch tierFilter {
        case .allTiers:
            return all
        case .focus, .practice, .challenge:
            return all.filter { $0.tier.caseInsensitiveCompare(tierFilter.rawValue) == .orderedSame }
        }
    }

    func questions(forTopic code: String) -> [SchoolMathsQuestion] {
        seedPack.schoolQuestions.filter { $0.topicCode == code }
    }

    func readiness(for unit: SchoolMathsUnit) -> UnitReadinessSnapshot {
        ReadinessService.snapshot(
            for: unit,
            pack: seedPack,
            proofs: Array(proofsByQuestionId.values),
            skills: Array(bktSkillsById.values),
            stamps: Array(widgetStampsById.values),
            readingProgress: Array(readingProgressByChapter.values)
        )
    }

    var overallIndependentProofCount: Int {
        proofsByQuestionId.values.filter { $0.level.isIndependentProof }.count
    }

    var overallSecureCount: Int {
        proofsByQuestionId.values.filter { $0.level == .secure }.count
    }

    var nextSchoolDeadline: SchoolDeadlineRecord? {
        let now = Date()
        return deadlines.filter { $0.dueAt >= now }.sorted(by: { $0.dueAt < $1.dueAt }).first
            ?? deadlines.first
    }

    // MARK: - Actions

    @discardableResult
    func submitQuestionAttempt(
        question: SchoolMathsQuestion,
        answerText: String,
        usedAssistance: Bool
    ) -> QuestionEvaluationResult {
        let existing = proofsByQuestionId[question.id]
        let (eval, record) = QuestionProofService.evaluateAndRecord(
            question: question,
            answerText: answerText,
            usedAssistance: usedAssistance,
            existingProof: existing
        )
        try? db.saveQuestionProof(record)

        if let skill = bktSkillsById[question.topicCode] {
            let updatedSkill = BKTEngine.update(
                skill: skill,
                isCorrect: eval.isPass,
                usedAssistance: usedAssistance
            )
            try? db.saveBKTSkill(updatedSkill)
        }

        refreshState()
        return eval
    }

    func reviewFSRSCard(_ card: FSRSCardRecord, rating: FSRSRating) {
        let updated = IntervalReviewScheduler.schedule(card: card, rating: rating)
        try? db.saveFSRSCard(updated)
        refreshState()
    }

    func saveVoiceTakeawayFlashcard(_ item: LiveVoiceTakeawayItem) {
        let now = Date()
        let card = FSRSCardRecord(
            id: "voice-card-\(item.id)",
            topicCode: selectedTopicCode,
            chapterNumber: selectedChapterNumber,
            frontPrompt: item.frontPrompt,
            backAnswer: item.backExplanation,
            stability: 1.5,
            difficulty: 5.0,
            elapsedDays: 0,
            scheduledDays: 1,
            reps: 0,
            lapses: 0,
            state: 0,
            dueAt: now,
            lastReviewAt: nil
        )
        try? db.saveFSRSCard(card)

        let journalEntry = LabJournalEntryRecord(
            id: "voice-journal-\(item.id)",
            title: "Live Voice Takeaway · \(item.topicTag)",
            templateKind: "cornell",
            paperStyle: "grid",
            linkedTopicCode: selectedTopicCode,
            linkedChapterNumber: selectedChapterNumber,
            linkedWidgetId: nil,
            cueColumnText: item.frontPrompt,
            bodyNotesText: item.backExplanation,
            summaryText: "Captured from Live Voice & Shared Chalkboard session.",
            hypothesisText: "",
            independentVarText: "",
            dependentVarText: "",
            controlVarsText: "",
            drawingData: nil,
            snapshotPNGData: nil,
            createdAt: now,
            updatedAt: now
        )
        try? db.saveJournalEntry(journalEntry)
        refreshState()
    }

    func stampWidgetChallenge(widget: InteractiveWidgetSpec, note: String) {
        let stamp = WidgetChallengeStampRecord(
            id: widget.id,
            chapterNumber: widget.chapter,
            earnedAt: Date(),
            readoutSnapshot: note
        )
        try? db.saveWidgetStamp(stamp)
        refreshState()
    }

    func markChapterRead(chapterNumber: Int, fraction: Double) {
        let id = String(format: "ch%02d", chapterNumber)
        let current = readingProgressByChapter[chapterNumber]
        let record = ChapterReadingProgressRecord(
            id: id,
            chapterNumber: chapterNumber,
            readFraction: max(current?.readFraction ?? 0.0, min(1.0, fraction)),
            predictionsCompleted: (current?.predictionsCompleted ?? 0) + 1,
            checksCompleted: (current?.checksCompleted ?? 0) + 1,
            updatedAt: Date()
        )
        try? db.saveChapterReadingProgress(record)
        refreshState()
    }

    func saveJournalEntry(_ entry: LabJournalEntryRecord) {
        try? db.saveJournalEntry(entry)
        refreshState()
    }

    func deleteJournalEntry(id: String) {
        try? db.deleteJournalEntry(id: id)
        refreshState()
    }

    func recordDiagramRecallAttempt(
        plate: DiagramRecallPlate,
        mode: String,
        correctCount: Int,
        selfScore: Int,
        drawingData: Data? = nil
    ) {
        let attempt = DiagramRecallAttemptRecord(
            id: UUID().uuidString,
            plateId: plate.id,
            mode: mode,
            correctCalloutsCount: correctCount,
            totalCalloutsCount: plate.callouts.count,
            drawingData: drawingData,
            selfScore: selfScore,
            completedAt: Date()
        )
        try? db.saveDiagramAttempt(attempt)
        refreshState()
    }

    func saveScratchpad(
        questionId: String,
        attemptNumber: Int = 1,
        paperStyle: String,
        stampKind: String?,
        drawingData: Data,
        previewPNGData: Data,
        strokeCount: Int
    ) {
        let record = ScratchpadRecord(
            id: "\(questionId)::attempt::\(attemptNumber)",
            questionId: questionId,
            attemptNumber: attemptNumber,
            paperStyle: paperStyle,
            stampKind: stampKind,
            drawingData: drawingData,
            previewPNGData: previewPNGData,
            strokeCount: strokeCount,
            updatedAt: Date()
        )
        try? db.saveScratchpad(record)
    }

    func loadScratchpad(questionId: String) -> ScratchpadRecord? {
        try? db.fetchLatestScratchpad(forQuestionId: questionId)
    }

    func saveCalloutResponse(calloutId: String, chapterNumber: Int, text: String) {
        let record = CalloutResponseRecord(
            id: calloutId,
            chapterNumber: chapterNumber,
            responseText: text,
            isUnlocked: !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            updatedAt: Date()
        )
        try? db.saveCalloutResponse(record)
        refreshState()
    }

    func addDeadline(title: String, unitNumbersCSV: String, dueAt: Date, kind: String, notes: String) {
        let record = SchoolDeadlineRecord(
            id: "deadline-\(UUID().uuidString.prefix(8))",
            title: title,
            unitNumbersCSV: unitNumbersCSV,
            dueAt: dueAt,
            kind: kind,
            notes: notes
        )
        try? db.saveDeadline(record)
        refreshState()
    }

    func deleteDeadline(id: String) {
        try? db.deleteDeadline(id: id)
        refreshState()
    }

    func saveCapturedTextbookPage(topicId: String, bookType: String, pageNumber: Int, ocrText: String) {
        let record = CapturedTextbookPageRecord(
            id: "page-\(topicId)-\(bookType)-\(pageNumber)",
            topicId: topicId,
            bookType: bookType,
            pageNumber: pageNumber,
            ocrText: ocrText,
            capturedAt: Date()
        )
        try? db.saveCapturedPage(record)
        refreshState()
    }

    // MARK: - Constitutional AI Mentor & Safety Guardrails (Ported from ../kym_tutor)

    func sendMentorMessage(
        _ rawText: String,
        activeQuestion: SchoolMathsQuestion? = nil,
        learnerDraft: String = ""
    ) async {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let resolvedStyle = MotivationalDialoguePolicy.resolvedStyle(
            requested: requestedGuidanceStyle,
            learnerText: trimmed
        )
        let supportMode = MotivationalDialoguePolicy.supportMode(
            for: resolvedStyle,
            learnerText: trimmed
        )

        // 1. On-device Child-Safety Crisis Gate (never sends crisis text to an AI provider)
        if let concern = safetyService.scan(trimmed) {
            lastSafetyConcern = concern
            mentorTurns.append(
                MathsMentorTurn(
                    role: "learner",
                    text: trimmed,
                    personaId: selectedSoulId,
                    guidanceStyle: resolvedStyle,
                    supportMode: supportMode,
                    understandingPhase: currentUnderstandingPhase,
                    blockedBySafetyCategory: concern.category.rawValue
                )
            )
            let safeMessage = safetyService.supportiveResponse(for: concern)
            safetyService.escalate(concern, channel: "maths_coach")
            mentorTurns.append(
                MathsMentorTurn(
                    role: "safety",
                    text: safeMessage,
                    personaId: selectedSoulId,
                    guidanceStyle: resolvedStyle,
                    supportMode: supportMode,
                    understandingPhase: currentUnderstandingPhase,
                    blockedBySafetyCategory: concern.category.rawValue
                )
            )
            return
        }

        // 2. Append learner turn and advance 4-phase understanding conservatively
        learnerTurnCount += 1
        currentUnderstandingPhase = QuestionTutoringPhasePolicy.phase(
            afterTurn: trimmed,
            learnerTurnCount: learnerTurnCount,
            current: currentUnderstandingPhase
        )
        mentorTurns.append(
            MathsMentorTurn(
                role: "learner",
                text: trimmed,
                personaId: selectedSoulId,
                guidanceStyle: resolvedStyle,
                supportMode: supportMode,
                understandingPhase: currentUnderstandingPhase
            )
        )

        // 3. Ground with offline FTS5 knowledge + contextual Maths brief + Soul Document + Constitution
        let kbResults = (try? db.searchKnowledgeBase(query: trimmed)) ?? (chapters: [], topics: [])
        let knowledgeContext: String
        if let topTopic = kbResults.topics.first {
            knowledgeContext = "Grounded in OUP Topic \(topTopic.code) \(topTopic.title) (p. \(topTopic.learnersBookPage)): \(topTopic.summary)"
        } else if let topCh = kbResults.chapters.first {
            knowledgeContext = "Grounded in Patterned World Ch \(topCh.chapterNumber) \(topCh.title): \(topCh.hookSummary) · Formula: \(topCh.formulaDisplay)"
        } else {
            knowledgeContext = "Grounded in \(selectedChapter.title) (\(selectedUnit.title)): \(selectedChapter.intuitionToFormula.concreteAction) → \(selectedChapter.intuitionToFormula.formulaDisplay)"
        }

        let liveBrief = MathLiveTutorContext.brief(
            chapterTitle: selectedChapter.title,
            questionId: activeQuestion?.id,
            questionPrompt: activeQuestion?.prompt,
            workedSteps: activeQuestion.map { [$0.workedExample] } ?? [],
            learnerDraft: learnerDraft,
            hasSharedHandwriting: didShareScratchpadWithCoach
        )

        let requestContext = AIRequestContext.learnerDialogue(
            feature: activeQuestion != nil ? .questionTutor : .chat,
            interaction: .tutoringDialogue,
            requestedStyle: requestedGuidanceStyle,
            learnerText: trimmed
        )

        let systemInstruction = activeSoul.toSystemInstruction() + "\n\n" + liveBrief
        let compositePrompt = "Learner question: \"\(trimmed)\"\n\nCurriculum grounding:\n\(knowledgeContext)"

        let replyText = (try? await aiRouter.generateLearnerFacingText(
            prompt: compositePrompt,
            systemInstruction: systemInstruction,
            provider: defaultAIProvider,
            model: nil,
            useGrounding: true,
            requestContext: requestContext
        )) ?? DevelopmentalResponseValidator.safeFallback

        mentorTurns.append(
            MathsMentorTurn(
                role: "mentor",
                text: replyText,
                personaId: selectedSoulId,
                guidanceStyle: resolvedStyle,
                supportMode: supportMode,
                understandingPhase: currentUnderstandingPhase
            )
        )
    }

    func shareScratchpadWithCoach(pngData: Data, activeQuestion: SchoolMathsQuestion? = nil) async {
        didShareScratchpadWithCoach = true
        let image = MultimodalImage(data: pngData, mimeType: "image/png")
        let systemInstruction = activeSoul.toSystemInstruction()
        let reply = (try? await aiRouter.generateLearnerFacingFromImage(
            prompt: "The learner explicitly shared her saved working for the current Maths question (\(activeQuestion?.id ?? "scratchpad")). Ask her to confirm any ambiguous handwriting; this is not a submitted final answer.",
            images: [image],
            systemInstruction: systemInstruction,
            requestContext: .questionTutor
        )) ?? "Your saved working was shared with Coach (processed locally on-device)."

        mentorTurns.append(
            MathsMentorTurn(
                role: "mentor",
                text: reply,
                personaId: selectedSoulId,
                guidanceStyle: requestedGuidanceStyle,
                supportMode: .standard,
                understandingPhase: currentUnderstandingPhase
            )
        )
    }

    // MARK: - Deep Link Routing (kymmaths://)

    func openDeepLink(_ url: URL) {
        guard url.scheme == "kymmaths" else { return }
        let host = url.host() ?? ""
        let pathParts = url.pathComponents.filter { $0 != "/" }

        switch host {
        case "today":
            activeRoom = .today
        case "school":
            activeRoom = .schoolMaths
            if let first = pathParts.first, let unitNum = Int(first) {
                selectedUnitNumber = unitNum
            }
        case "chapter":
            activeRoom = .patternedWorld
            if let first = pathParts.first, let chNum = Int(first) {
                selectedChapterNumber = chNum
            }
        case "widget":
            activeRoom = .labsAtlas
            if let first = pathParts.first {
                selectedWidgetId = first
            }
        case "polya":
            activeRoom = .polyaFluency
        case "journal":
            activeRoom = .mathsJournal
        case "coach":
            activeRoom = .coach
        default:
            break
        }
    }
}
