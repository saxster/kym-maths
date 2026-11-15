import Foundation
import GRDB

// The review scheduler (FSRSScheduler, FSRS v5), BKTEngine and FSRSRating live in the shared
// KymLearning package. These conformances let the engines read and write the app's GRDB records.
extension FSRSCardRecord: ReviewCard {}

extension FSRSScheduler {
    /// This app's review schedule: FSRS v5, and a card rated again comes back the next day.
    static let app = FSRSScheduler(relearningStepDays: 1)
}
extension BKTSkillRecord: BKTSkill {}

// MARK: - 6-Rung Hint Ladder & Confidence × Verdict Diagnostic Matrix

enum HintLadderRung: Int, CaseIterable, Codable, Sendable, Comparable {
    case none = 0
    case r0AttentionRedirect = 1
    case r1PatternRedescription = 2
    case r2CandidateClass = 3
    case r3PropositionNamed = 4
    case r4MoveOutlined = 5
    case r5WorkedStep = 6

    static func < (lhs: HintLadderRung, rhs: HintLadderRung) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// R0–R2 preserve retrieval; R3–R5 surrender retrieval and count as assisted.
    var surrendersRetrieval: Bool {
        rawValue >= HintLadderRung.r3PropositionNamed.rawValue
    }

    var badgeText: String {
        switch self {
        case .none: return "No Hints"
        case .r0AttentionRedirect: return "R0 · Attention"
        case .r1PatternRedescription: return "R1 · Pattern"
        case .r2CandidateClass: return "R2 · Class"
        case .r3PropositionNamed: return "R3 · Proposition"
        case .r4MoveOutlined: return "R4 · Move"
        case .r5WorkedStep: return "R5 · Worked Step"
        }
    }

    var title: String {
        switch self {
        case .none: return "Unassisted"
        case .r0AttentionRedirect: return "Rung 0: Attention Redirect (Retrieval Intact)"
        case .r1PatternRedescription: return "Rung 1: Pattern Redescription (Retrieval Intact)"
        case .r2CandidateClass: return "R2: Candidate Class (Retrieval Intact)"
        case .r3PropositionNamed: return "R3: Proposition Named (Assisted)"
        case .r4MoveOutlined: return "R4: Move Outlined (Assisted)"
        case .r5WorkedStep: return "R5: Worked Step (Assisted)"
        }
    }
}

public enum ConfidenceVerdictCell: String, Codable, Equatable, Sendable {
    case solidKnowledge = "solid_knowledge"
    case fragileOrLuckyGuess = "fragile_or_lucky_guess"
    case committedMisconception = "committed_misconception"
    case shakyNearMiss = "shaky_near_miss"
    case honestGap = "honest_gap"

    public var badgeTitle: String {
        switch self {
        case .solidKnowledge: return "Solid Mastery"
        case .fragileOrLuckyGuess: return "Fragile / Lucky Guess — Probe Why"
        case .committedMisconception: return "Committed Misconception — Spot the Flaw"
        case .shakyNearMiss: return "Shaky Near-Miss — Retest Later"
        case .honestGap: return "Honest Gap — Prerequisite Scaffold"
        }
    }
}

enum DiagnosticFollowUpAction: Equatable, Sendable {
    case none
    case triggerElaborativeInterrogation
    case surfaceSpotTheFlaw(topicCode: String)
    case scheduleFreshSurfaceRetest(questionId: String)
}

// MARK: - Question Proof Service (Worked Example -> Faded -> Independent Proof)

struct QuestionEvaluationResult: Equatable, Sendable {
    let matchedParts: [String]
    let missingParts: [String]
    let coverageFraction: Double
    let isPass: Bool
    let resultingProofLevel: QuestionProofLevel
    let feedbackSummary: String
    let diagnosticCell: ConfidenceVerdictCell
    let recommendedFollowUp: DiagnosticFollowUpAction
    let effectiveUsedAssistance: Bool
    let mistake: KnownMistake?

    init(
        matchedParts: [String],
        missingParts: [String],
        coverageFraction: Double,
        isPass: Bool,
        resultingProofLevel: QuestionProofLevel,
        feedbackSummary: String,
        diagnosticCell: ConfidenceVerdictCell = .solidKnowledge,
        recommendedFollowUp: DiagnosticFollowUpAction = .none,
        effectiveUsedAssistance: Bool = false,
        mistake: KnownMistake? = nil
    ) {
        self.matchedParts = matchedParts
        self.missingParts = missingParts
        self.coverageFraction = coverageFraction
        self.isPass = isPass
        self.resultingProofLevel = resultingProofLevel
        self.feedbackSummary = feedbackSummary
        self.diagnosticCell = diagnosticCell
        self.recommendedFollowUp = recommendedFollowUp
        self.effectiveUsedAssistance = effectiveUsedAssistance
        self.mistake = mistake
    }
}

enum QuestionProofService {
    static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", comps.year ?? 2026, comps.month ?? 1, comps.day ?? 1)
    }

    static func classifyDiagnosticCell(
        isPass: Bool,
        confidencePercent: Int,
        declinedToGuess: Bool
    ) -> ConfidenceVerdictCell {
        if declinedToGuess {
            return .honestGap
        }
        let highConfidence = confidencePercent >= 70
        switch (isPass, highConfidence) {
        case (true, true):
            return .solidKnowledge
        case (true, false):
            return .fragileOrLuckyGuess
        case (false, true):
            return .committedMisconception
        case (false, false):
            return .shakyNearMiss
        }
    }

    static func evaluateAndRecord(
        question: SchoolMathsQuestion,
        answerText: String,
        usedAssistance: Bool,
        existingProof: QuestionProofRecord?,
        now: Date = Date(),
        highestHintRung: HintLadderRung = .none,
        confidencePercent: Int = 75,
        declinedToGuess: Bool = false,
        thinkingTrace: String = ""
    ) -> (result: QuestionEvaluationResult, record: QuestionProofRecord) {
        let effectiveAssisted = usedAssistance || highestHintRung.surrendersRetrieval
        let partLabels = question.answerKey.parts.map(\.label)

        if declinedToGuess {
            let nextLevel: QuestionProofLevel = existingProof?.level ?? .unseen
            let feedback = "Honest 'I don't know yet' recorded — no guess penalty applied. Start with Rung 0–2 hints or inspect the prerequisite intuition first."
            let record = QuestionProofRecord(
                id: question.id,
                unitNumber: question.unitNumber,
                topicCode: question.topicCode,
                proofLevel: nextLevel.rawValue,
                independentPassDays: existingProof?.independentPassDays ?? 0,
                lastIndependentPassDayKey: existingProof?.lastIndependentPassDayKey,
                lastAttemptAt: now,
                lastAnswerText: answerText,
                lastUsedAssistance: effectiveAssisted,
                matchedKeywordsCSV: "",
                missingKeywordsCSV: partLabels.joined(separator: ","),
                highestHintRung: highestHintRung.rawValue,
                confidencePercent: 0,
                declinedToGuess: true,
                thinkingTrace: thinkingTrace
            )
            let eval = QuestionEvaluationResult(
                matchedParts: [],
                missingParts: partLabels,
                coverageFraction: 0,
                isPass: false,
                resultingProofLevel: nextLevel,
                feedbackSummary: feedback,
                diagnosticCell: .honestGap,
                recommendedFollowUp: .scheduleFreshSurfaceRetest(questionId: question.id),
                effectiveUsedAssistance: effectiveAssisted
            )
            return (eval, record)
        }

        let marking = question.answerKey.mark(answerText)
        let matched = marking.matchedParts
        let missing = marking.missingParts
        let total = max(1, partLabels.count)
        let coverage = Double(matched.count) / Double(total)
        let isPass = marking.isCorrect
        let score = total == 1 ? "" : " (\(matched.count) of \(total) parts right)"
        let stillToGet = total == 1
            ? "Check each step of your working, then try again."
            : "Still to get: \(missing.joined(separator: ", "))."
        let advice = marking.mistake.map { "\($0.name). \($0.nextStep)" } ?? stillToGet

        let todayKey = dayKey(for: now)
        var passDays = existingProof?.independentPassDays ?? 0
        var lastPassDay = existingProof?.lastIndependentPassDayKey

        let nextLevel: QuestionProofLevel
        let feedback: String

        if effectiveAssisted {
            if let prev = existingProof?.level, prev.isIndependentProof {
                nextLevel = prev
            } else {
                nextLevel = .assisted
            }
            let rungNote = highestHintRung.surrendersRetrieval ? " (\(highestHintRung.badgeText) used)" : ""
            feedback = isPass
                ? "Good guided solution\(rungNote). Now solve with at most R0–R2 hints to earn Independent Proof."
                : "Guided attempt\(rungNote) recorded\(score). \(advice)"
        } else if isPass {
            if lastPassDay != todayKey {
                passDays += 1
                lastPassDay = todayKey
            }
            if passDays >= 2 {
                nextLevel = .secure
                feedback = "Secure across \(passDays) separate days."
            } else {
                nextLevel = .proven
                feedback = "Proven independently today. Prove it on one more day to lock it as Secure."
            }
        } else {
            nextLevel = .shaky
            feedback = "Not right yet\(score). \(advice)"
        }

        let cell = classifyDiagnosticCell(
            isPass: isPass,
            confidencePercent: confidencePercent,
            declinedToGuess: false
        )
        let followUp: DiagnosticFollowUpAction
        switch cell {
        case .solidKnowledge:
            followUp = .none
        case .fragileOrLuckyGuess:
            followUp = .triggerElaborativeInterrogation
        case .committedMisconception:
            followUp = .surfaceSpotTheFlaw(topicCode: question.topicCode)
        case .shakyNearMiss, .honestGap:
            followUp = .scheduleFreshSurfaceRetest(questionId: question.id)
        }

        let record = QuestionProofRecord(
            id: question.id,
            unitNumber: question.unitNumber,
            topicCode: question.topicCode,
            proofLevel: nextLevel.rawValue,
            independentPassDays: passDays,
            lastIndependentPassDayKey: lastPassDay,
            lastAttemptAt: now,
            lastAnswerText: answerText,
            lastUsedAssistance: effectiveAssisted,
            matchedKeywordsCSV: matched.joined(separator: ","),
            missingKeywordsCSV: missing.joined(separator: ","),
            highestHintRung: highestHintRung.rawValue,
            confidencePercent: confidencePercent,
            declinedToGuess: false,
            thinkingTrace: thinkingTrace,
            lastMistakeId: marking.mistake?.misconception ?? ""
        )

        let eval = QuestionEvaluationResult(
            matchedParts: matched,
            missingParts: missing,
            coverageFraction: coverage,
            isPass: isPass,
            resultingProofLevel: nextLevel,
            feedbackSummary: feedback,
            diagnosticCell: cell,
            recommendedFollowUp: followUp,
            effectiveUsedAssistance: effectiveAssisted,
            mistake: marking.mistake
        )
        return (eval, record)
    }
}

// MARK: - Three-Stage Readiness Service (Material In -> Checked Learning -> Independent Proof)

struct UnitReadinessSnapshot: Equatable, Sendable {
    let unitNumber: Int
    let topicsCount: Int
    let chaptersReadCount: Int
    let widgetsStampedCount: Int
    let questionsTotal: Int
    let questionsAssistedCount: Int
    let questionsProvenCount: Int
    let questionsSecureCount: Int
    let averageBKTMastery: Double

    var independentProofFraction: Double {
        guard questionsTotal > 0 else { return 0 }
        return Double(questionsProvenCount + questionsSecureCount) / Double(questionsTotal)
    }

    var readinessBadgeText: String {
        if questionsTotal > 0 && questionsSecureCount == questionsTotal {
            return "Exam-ready"
        } else if questionsProvenCount + questionsSecureCount > 0 {
            return "\(questionsProvenCount + questionsSecureCount)/\(questionsTotal) proven"
        } else if questionsAssistedCount > 0 {
            return "Guided practice"
        } else {
            return "Ready to start"
        }
    }
}

enum ReadinessService {
    static func snapshot(
        for unit: SchoolMathsUnit,
        pack: KymMathsSeedPack,
        proofs: [QuestionProofRecord],
        skills: [BKTSkillRecord],
        stamps: [WidgetChallengeStampRecord],
        readingProgress: [ChapterReadingProgressRecord]
    ) -> UnitReadinessSnapshot {
        let unitQuestions = pack.schoolQuestions.filter { $0.unitNumber == unit.unitNumber }
        let unitProofs = proofs.filter { $0.unitNumber == unit.unitNumber }
        let assisted = unitProofs.filter { $0.level == .assisted || $0.level == .shaky }.count
        let proven = unitProofs.filter { $0.level == .proven }.count
        let secure = unitProofs.filter { $0.level == .secure }.count

        let topicCodes = Set(unit.topics.map(\.code))
        let unitSkills = skills.filter { topicCodes.contains($0.id) }
        let avgMastery = unitSkills.isEmpty
            ? 0.0
            : unitSkills.map(\.pLearned).reduce(0, +) / Double(unitSkills.count)

        let linkedChSet = Set(unit.livingWorldChapters)
        let chaptersRead = readingProgress.filter { linkedChSet.contains($0.chapterNumber) && $0.readFraction >= 0.5 }.count
        let stampsCount = stamps.filter { linkedChSet.contains($0.chapterNumber) }.count

        return UnitReadinessSnapshot(
            unitNumber: unit.unitNumber,
            topicsCount: unit.topics.count,
            chaptersReadCount: chaptersRead,
            widgetsStampedCount: stampsCount,
            questionsTotal: unitQuestions.count,
            questionsAssistedCount: assisted,
            questionsProvenCount: proven,
            questionsSecureCount: secure,
            averageBKTMastery: avgMastery
        )
    }
}

// MARK: - 5. CPA Interactive Manipulative Engine (Singapore Bar / Al-Khwarizmi Box / Geometric Balance)

public enum CPAManipulativeKind: String, Codable, CaseIterable, Sendable {
    case singaporeBarPartition
    case alKhwarizmiAreaBox
    case geometricAngleVectorBalance

    public var title: String {
        switch self {
        case .singaporeBarPartition:
            return "Singapore Bar Partition Manipulative"
        case .alKhwarizmiAreaBox:
            return "Al-Khwarizmi Area Box Manipulative"
        case .geometricAngleVectorBalance:
            return "Geometric Angle & Vector Balance"
        }
    }

    public var badgeSymbol: String {
        switch self {
        case .singaporeBarPartition:
            return "rectangle.split.3x1.fill"
        case .alKhwarizmiAreaBox:
            return "square.grid.2x2.fill"
        case .geometricAngleVectorBalance:
            return "angle"
        }
    }
}

public struct CPAManipulativeSpec: Identifiable, Equatable, Sendable {
    public let id: String
    public let kind: CPAManipulativeKind
    public let title: String
    public let instruction: String
    public let invariantSummary: String
    public let defaultPrimaryValue: Double
    public let primaryRange: ClosedRange<Double>
    public let primaryStep: Double
    public let defaultSecondaryValue: Double
    public let secondaryRange: ClosedRange<Double>
    public let secondaryStep: Double
    public let primaryLabel: String
    public let secondaryLabel: String
    public let unitLabel: String
}

public struct CPAManipulativeState: Equatable, Sendable {
    public var primaryValue: Double
    public var secondaryValue: Double

    public init(primaryValue: Double, secondaryValue: Double) {
        self.primaryValue = primaryValue
        self.secondaryValue = secondaryValue
    }

    public func liveReadout(for spec: CPAManipulativeSpec) -> String {
        switch spec.kind {
        case .singaporeBarPartition:
            let parts = max(1, Int(primaryValue.rounded()))
            let unitVal = secondaryValue
            let total = Double(parts) * unitVal
            return "\(parts) equal bar units × \(Self.cleanNum(unitVal))\(spec.unitLabel) = \(Self.cleanNum(total))\(spec.unitLabel) total (1 unit = \(Self.cleanNum(total / Double(parts)))\(spec.unitLabel))"
        case .alKhwarizmiAreaBox:
            let a = primaryValue
            let b = secondaryValue
            let totalArea = (a + b) * (a + b)
            let a2 = a * a
            let ab = a * b
            let b2 = b * b
            return "(\(Self.cleanNum(a)) + \(Self.cleanNum(b)))² = \(Self.cleanNum(a2)) + 2(\(Self.cleanNum(ab))) + \(Self.cleanNum(b2)) = \(Self.cleanNum(totalArea)) sq units"
        case .geometricAngleVectorBalance:
            let deg = primaryValue
            let supp = 180.0 - deg
            let turns = max(3, Int(secondaryValue.rounded()))
            let extTurn = 360.0 / Double(turns)
            return "Angle θ = \(Int(deg.rounded()))° · Straight-line supplement = \(Int(supp.rounded()))° · Regular \(turns)-gon exterior turn = \(Int(extTurn.rounded()))°"
        }
    }

    private static func cleanNum(_ x: Double) -> String {
        if abs(x.rounded() - x) < 0.01 {
            return String(Int(x.rounded()))
        }
        return String(format: "%.1f", x)
    }
}

enum CPAManipulativeEngine {
    static func spec(for question: SchoolMathsQuestion) -> CPAManipulativeSpec {
        switch question.cpaManipulativeDomain {
        case "algebraic_area":
            return CPAManipulativeSpec(
                id: "cpa-box-\(question.id)",
                kind: .alKhwarizmiAreaBox,
                title: "Al-Khwarizmi 2×2 Area Partition",
                instruction: "Drag side partitions a and b to see how (a + b)² splits into a², two ab strips, and b².",
                invariantSummary: "Total bounding square area always equals the sum of its 4 interior sub-rectangles: a² + ab + ab + b².",
                defaultPrimaryValue: 10,
                primaryRange: 2...20,
                primaryStep: 1,
                defaultSecondaryValue: 4,
                secondaryRange: 1...12,
                secondaryStep: 1,
                primaryLabel: "Side a",
                secondaryLabel: "Strip b",
                unitLabel: ""
            )
        case "geometric_angle_vector":
            return CPAManipulativeSpec(
                id: "cpa-geo-\(question.id)",
                kind: .geometricAngleVectorBalance,
                title: "Angle Supplement & Polygon Turn Balance",
                instruction: "Sweep angle θ along the straight line and adjust polygon sides n to inspect the invariant 180° supplement and 360° exterior turn.",
                invariantSummary: "Adjacent angles on a straight line always sum to 180°, and exterior turns around any closed polygon sum to 360°.",
                defaultPrimaryValue: 120,
                primaryRange: 15...165,
                primaryStep: 5,
                defaultSecondaryValue: 6,
                secondaryRange: 3...12,
                secondaryStep: 1,
                primaryLabel: "Interior Angle θ (°)",
                secondaryLabel: "Polygon Sides n",
                unitLabel: "°"
            )
        default:
            return CPAManipulativeSpec(
                id: "cpa-bar-\(question.id)",
                kind: .singaporeBarPartition,
                title: "Singapore Unitary Bar Model",
                instruction: "Adjust the number of equal bar units and the value inside 1 unit to test how the total bar scales.",
                invariantSummary: "Equal bar segments represent equal quantities: once you lock the value of 1 unit, any ratio share or total is an exact multiple.",
                defaultPrimaryValue: 5,
                primaryRange: 2...12,
                primaryStep: 1,
                defaultSecondaryValue: 12,
                secondaryRange: 1...50,
                secondaryStep: 1,
                primaryLabel: "Equal Bar Units",
                secondaryLabel: "Value per Unit",
                unitLabel: ""
            )
        }
    }

    static func initialState(for question: SchoolMathsQuestion) -> CPAManipulativeState {
        let s = spec(for: question)
        return CPAManipulativeState(
            primaryValue: s.defaultPrimaryValue,
            secondaryValue: s.defaultSecondaryValue
        )
    }
}

// MARK: - 6. Interactive Chapter Beat Engine & Read+Listen Audio Narrator (Brilliant + SmartyMe Pattern)

public enum ChapterInteractiveBeatKind: String, Codable, Sendable {
    case everydayHook
    case proseInsight
    case calloutGate
    case interactiveLabAndFormula
    case misconceptionDebate
    case chapterSynthesis
}

struct ChapterInteractiveBeat: Identifiable, Equatable, Sendable {
    let id: String
    let index: Int
    let totalBeats: Int
    let kind: ChapterInteractiveBeatKind
    let eyebrow: String
    let title: String
    let bodyParagraphs: [String]
    let callout: PatternedWorldCallout?
    let widgetIds: [String]
    let formulaBridge: IntuitionToFormulaBridge?
    let debateScenario: MathematicalDebateScenario?
    let requiresInteractionToUnlock: Bool
    /// A rewritten section's steps, whose texts are also `bodyParagraphs`.
    var teachingSteps: [TeachingStep] = []
    /// Whether the chapter's figure sits beside this step.
    var showsFigure = true
    /// On the first step: what she can do after the chapter.
    var skillCard: ChapterSkillCard? = nil
    /// On the first step of a chapter no school unit teaches: says so, and names what it stands on.
    var beyondSchoolLine: String? = nil

    var spokenScript: String {
        var parts: [String] = [eyebrow, title]
        if let beyondSchoolLine {
            parts.append(beyondSchoolLine)
        }
        if let card = skillCard {
            parts.append("After this chapter you can: \(card.skill)")
            parts.append("Try this with the device off: \(card.sheCan.prompt)")
            parts.append("Why it matters: \(card.whyItMatters)")
        }
        parts.append(contentsOf: bodyParagraphs)
        if let callout {
            parts.append("\(callout.title). \(callout.body)")
        }
        if let bridge = formulaBridge {
            parts.append("The rule: \(bridge.formulaDisplay). \(bridge.concreteAction) What stays the same: \(bridge.ahaInvariant)")
        }
        return parts.joined(separator: ". ")
    }
}

enum ChapterInteractiveBeatEngine {
    static func beats(for chapter: PatternedWorldChapter) -> [ChapterInteractiveBeat] {
        var rawBeats: [ChapterInteractiveBeat] = []

        func add(
            _ kind: ChapterInteractiveBeatKind,
            eyebrow: String,
            title: String,
            body: [String],
            callout: PatternedWorldCallout? = nil,
            widgetIds: [String] = [],
            formulaBridge: IntuitionToFormulaBridge? = nil,
            debate: MathematicalDebateScenario? = nil,
            gated: Bool,
            steps: [TeachingStep] = [],
            showsFigure: Bool = true,
            skillCard: ChapterSkillCard? = nil,
            beyondSchoolLine: String? = nil
        ) {
            rawBeats.append(ChapterInteractiveBeat(
                id: "ch\(chapter.number)-beat-\(rawBeats.count)",
                index: rawBeats.count,
                totalBeats: 0,
                kind: kind,
                eyebrow: eyebrow,
                title: title,
                bodyParagraphs: body,
                callout: callout,
                widgetIds: widgetIds,
                formulaBridge: formulaBridge,
                debateScenario: debate,
                requiresInteractionToUnlock: gated,
                teachingSteps: steps,
                showsFigure: showsFigure,
                skillCard: skillCard,
                beyondSchoolLine: beyondSchoolLine
            ))
        }

        // The opening question, the skill card and the prediction.
        let predictCallout = chapter.callouts.first(where: { $0.kind == "predict" })
        add(
            .everydayHook,
            eyebrow: "Start here",
            title: chapter.title,
            body: [chapter.hookSummary, chapter.subtitle],
            callout: predictCallout,
            gated: predictCallout != nil,
            skillCard: chapter.skillCard,
            beyondSchoolLine: beyondSchoolLine(for: chapter)
        )

        // The sections, each paired with a non-predict callout in turn.
        let otherCallouts = chapter.callouts.filter { $0.kind != "predict" }
        for (secIdx, section) in chapter.sections.enumerated() {
            let pairedCallout = secIdx < otherCallouts.count ? otherCallouts[secIdx] : nil
            add(
                pairedCallout != nil ? .calloutGate : .proseInsight,
                eyebrow: pairedCallout != nil ? "Read, then check yourself" : "Read and think",
                title: section.heading,
                body: section.teachingSteps.isEmpty ? [section.excerpt] : section.teachingSteps.map(\.text),
                callout: pairedCallout,
                gated: pairedCallout?.kind == "check",
                steps: section.teachingSteps,
                showsFigure: section.showsFigure
            )
        }

        // The figure and the rule it gives.
        add(
            .interactiveLabAndFormula,
            eyebrow: "Try the figure",
            title: "From the picture to the rule",
            body: [chapter.intuitionToFormula.concreteAction, chapter.intuitionToFormula.ahaInvariant],
            widgetIds: chapter.widgets,
            formulaBridge: chapter.intuitionToFormula,
            gated: false
        )

        // Who is right?
        let debate = MathematicalDebateEngine.scenario(for: chapter)
        add(
            .misconceptionDebate,
            eyebrow: "Who is right?",
            title: debate.title,
            body: [debate.contextPrompt],
            debate: debate,
            gated: true
        )

        // The chapter in a nutshell.
        let keyTermsLine = chapter.keyTerms.isEmpty ? "" : "Words from this chapter: " + chapter.keyTerms.joined(separator: " · ")
        add(
            .chapterSynthesis,
            eyebrow: "In a nutshell",
            title: "Chapter \(chapter.number) in a nutshell: \(chapter.title)",
            body: [chapter.hookSummary, chapter.intuitionToFormula.ahaInvariant, keyTermsLine].filter { !$0.isEmpty },
            gated: false
        )

        let total = rawBeats.count
        return rawBeats.map { beat in
            ChapterInteractiveBeat(
                id: beat.id,
                index: beat.index,
                totalBeats: total,
                kind: beat.kind,
                eyebrow: beat.eyebrow,
                title: beat.title,
                bodyParagraphs: beat.bodyParagraphs,
                callout: beat.callout,
                widgetIds: beat.widgetIds,
                formulaBridge: beat.formulaBridge,
                debateScenario: beat.debateScenario,
                requiresInteractionToUnlock: beat.requiresInteractionToUnlock,
                teachingSteps: beat.teachingSteps,
                showsFigure: beat.showsFigure,
                skillCard: beat.skillCard,
                beyondSchoolLine: beat.beyondSchoolLine
            )
        }
    }

    /// "This chapter goes past your school book. It builds on times tables to 12 × 12, …" for a
    /// chapter no school unit teaches; nil for the others.
    static func beyondSchoolLine(for chapter: PatternedWorldChapter) -> String? {
        guard chapter.goesBeyondSchoolBook else { return nil }
        let opening = "This chapter goes past your school book."
        let standsOn = (chapter.skillCard?.standsOn ?? []).map(lowercasedStart)
        guard let last = standsOn.last else { return opening }
        let list = standsOn.count == 1 ? last : standsOn.dropLast().joined(separator: ", ") + " and " + last
        return "\(opening) It builds on \(list)."
    }

    /// "Times tables" becomes "times tables" mid-sentence; "HCF" and "Chapter 2" keep their capitals.
    private static func lowercasedStart(_ text: String) -> String {
        let letters = Array(text)
        guard letters.count > 1, letters[0].isUppercase, letters[1].isLowercase,
              !text.hasPrefix("Chapter ") else { return text }
        return letters[0].lowercased() + String(letters.dropFirst())
    }
}

// MARK: - 7. Mathematical Debate Engine ("Who Is Right & Why?" Misconception Immunity)

public struct MathematicalDebateChoice: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let speakerLabel: String
    public let reasoningStatement: String
    public let isCorrect: Bool
    public let socraticRebuttal: String
}

public struct MathematicalDebateScenario: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let chapterNumber: Int
    public let oupUnitNumber: Int
    public let title: String
    public let contextPrompt: String
    public let speakerAName: String
    public let speakerAClaim: String
    public let speakerBName: String
    public let speakerBClaim: String
    public let choices: [MathematicalDebateChoice]
    public let invariantTakeaway: String
}

public enum MathematicalDebateEngine {
    /// The chapter's own "Who is right?" from its pack record, or the catalog's while the chapter
    /// is not yet rewritten.
    static func scenario(for chapter: PatternedWorldChapter) -> MathematicalDebateScenario {
        chapter.debate
            ?? MathematicalDebateCatalog.all.first { $0.chapterNumber == chapter.number }
            ?? MathematicalDebateCatalog.all[0]
    }

    /// The first chapter's debate, in chapter order, that maps to this school unit.
    static func scenario(forOUPUnit unitNumber: Int, in chapters: [PatternedWorldChapter]) -> MathematicalDebateScenario {
        let scenarios = chapters.sorted { $0.number < $1.number }.map(scenario(for:))
        return scenarios.first { $0.oupUnitNumber == unitNumber }
            ?? scenarios.first
            ?? MathematicalDebateCatalog.all[0]
    }

    public static func evaluateChoice(
        scenario: MathematicalDebateScenario,
        choiceId: String
    ) -> MathematicalDebateChoice? {
        scenario.choices.first(where: { $0.id == choiceId })
    }
}

public enum MathematicalDebateCatalog {
    public static let all: [MathematicalDebateScenario] = [
        // Ch 6 -> OUP Ch 9 (Percentages & Compound Multipliers)
        MathematicalDebateScenario(
            id: "debate-ch06-percentages",
            chapterNumber: 6,
            oupUnitNumber: 9,
            title: "Festival Markup & Discount Illusion",
            contextPrompt: "A Bandra shop raises a ₹1,000 jacket by 20% and then offers a 20% sale discount. Neel and Priya debate the final price:",
            speakerAName: "Neel",
            speakerAClaim: "+20% and −20% cancel out to 0%, so the jacket is back to ₹1,000!",
            speakerBName: "Priya",
            speakerBClaim: "The 20% discount applies to ₹1,200, not ₹1,000! So 1.20 × 0.80 = 0.96, giving ₹960.",
            choices: [
                MathematicalDebateChoice(
                    id: "ch06-a",
                    speakerLabel: "Neel is right (₹1,000)",
                    reasoningStatement: "Equal percentage increases and decreases always cancel.",
                    isCorrect: false,
                    socraticRebuttal: "20% of ₹1,200 is ₹240, whereas 20% of ₹1,000 was only ₹200—you subtract more than you added!"
                ),
                MathematicalDebateChoice(
                    id: "ch06-b",
                    speakerLabel: "Priya is right (₹960)",
                    reasoningStatement: "Chained percentage changes multiply their scale factors: (1 + 0.20)(1 − 0.20) = 1 − 0.04 = 0.96.",
                    isCorrect: true,
                    socraticRebuttal: "Exact! By Difference of Two Squares, (1 + r)(1 − r) = 1 − r² is always less than 1."
                ),
                MathematicalDebateChoice(
                    id: "ch06-c",
                    speakerLabel: "Neither — it becomes ₹1,040",
                    reasoningStatement: "The markup dominates the discount.",
                    isCorrect: false,
                    socraticRebuttal: "Since the discount is taken on the LARGER ₹1,200 base, the downward step is larger than the upward step."
                )
            ],
            invariantTakeaway: "Successive percentages multiply scale factors: (1 + r)(1 − r) = 1 − r²."
        ),
        // Ch 7 -> OUP Ch 12 (Ratio, Rate & Unitary Bar Models)
        MathematicalDebateScenario(
            id: "debate-ch07-ratio",
            chapterNumber: 7,
            oupUnitNumber: 12,
            title: "The Marble Transfer Conservation Law",
            contextPrompt: "Kym and Aarav hold marbles in ratio 5 : 3. After Kym gives Aarav 10 marbles, they have equal shares (1 : 1). Reyansh and Ira debate how many marbles 1 bar unit represents:",
            speakerAName: "Reyansh",
            speakerAClaim: "The ratio difference is 5 − 3 = 2 units, so 2 units = 10 marbles (1 unit = 5 marbles).",
            speakerBName: "Ira",
            speakerBClaim: "Total units stay 5 + 3 = 8, so equal shares are 4 : 4! Kym went from 5 units to 4 units, meaning 1 unit = 10 marbles.",
            choices: [
                MathematicalDebateChoice(
                    id: "ch07-a",
                    speakerLabel: "Reyansh is right (1 unit = 5 marbles)",
                    reasoningStatement: "The gap between 5 units and 3 units is 2 units.",
                    isCorrect: false,
                    socraticRebuttal: "When Kym gives 1 unit to Aarav, the gap closes by 2 units (Kym −1, Aarav +1)! So transferring 1 unit equalises a 2-unit gap."
                ),
                MathematicalDebateChoice(
                    id: "ch07-b",
                    speakerLabel: "Ira is right (1 unit = 10 marbles, total = 80)",
                    reasoningStatement: "Internal transfers conserve total units (8 units), so 5 : 3 becomes 4 : 4 by moving 1 unit.",
                    isCorrect: true,
                    socraticRebuttal: "Spot on! Kym starts with 50, gives 10 to Aarav (who starts with 30), and both end at 40."
                ),
                MathematicalDebateChoice(
                    id: "ch07-c",
                    speakerLabel: "Neither — 5 units = 10 marbles",
                    reasoningStatement: "The transfer equals Kym's full share.",
                    isCorrect: false,
                    socraticRebuttal: "Kym only gave away a fraction of his share so that both ended with 4 units."
                )
            ],
            invariantTakeaway: "In an internal transfer between two people, the sum of bar units is conserved, and moving Δ units changes their gap by 2Δ."
        ),
        // Ch 8 -> OUP Ch 11 (Sequences, Patterns & Fenceposts)
        MathematicalDebateScenario(
            id: "debate-ch08-sequences",
            chapterNumber: 8,
            oupUnitNumber: 11,
            title: "The Staircase Fencepost Trap",
            contextPrompt: "A sequence starts at T₁ = 7 and adds d = 4 at each step (7, 11, 15, 19...). Kabir and Sia debate the formula for the 20th term T₂₀:",
            speakerAName: "Kabir",
            speakerAClaim: "For the 20th term, add twenty jumps of 4 to 7: T₂₀ = 7 + 20 × 4 = 87.",
            speakerBName: "Sia",
            speakerBClaim: "Term 1 is already at 7! To reach Term 20 from Term 1, you take 19 jumps of 4: T₂₀ = 7 + 19 × 4 = 83.",
            choices: [
                MathematicalDebateChoice(
                    id: "ch08-a",
                    speakerLabel: "Kabir is right (T₂₀ = 87)",
                    reasoningStatement: "Term n always adds n copies of the common difference d to a.",
                    isCorrect: false,
                    socraticRebuttal: "Check n = 1 with Kabir's rule: 7 + 1 × 4 = 11, which is already Term 2! You are off by one fencepost."
                ),
                MathematicalDebateChoice(
                    id: "ch08-b",
                    speakerLabel: "Sia is right (T₂₀ = 83)",
                    reasoningStatement: "Between 1st and nth posts there are (n − 1) gaps, so T_n = a + (n − 1)d.",
                    isCorrect: true,
                    socraticRebuttal: "Exact! Equivalently, since 4n starts at 4, adding +3 shifts it to start at 7: 4(20) + 3 = 83."
                ),
                MathematicalDebateChoice(
                    id: "ch08-c",
                    speakerLabel: "Neither — T₂₀ = 20 × 7 = 140",
                    reasoningStatement: "The 20th term is 20 times the first term.",
                    isCorrect: false,
                    socraticRebuttal: "Only sequences with common difference d = a (like 7, 14, 21...) are direct multiples of the first term."
                )
            ],
            invariantTakeaway: "Reaching the nth term from the 1st term takes (n − 1) steps of d: T_n = a + (n − 1)d."
        ),
        // Ch 9 -> OUP Ch 8 (Polygons, Parallel Lines & Exterior Turns)
        MathematicalDebateScenario(
            id: "debate-ch09-polygons",
            chapterNumber: 9,
            oupUnitNumber: 8,
            title: "Walking the Decagon Perimeter",
            contextPrompt: "What happens to the sum of exterior angles when you increase a regular polygon from 5 sides to 10 sides?",
            speakerAName: "Aarav",
            speakerAClaim: "Since there are twice as many corners, the sum of exterior angles doubles from 360° to 720°!",
            speakerBName: "Meera",
            speakerBClaim: "Walking all the way around ANY closed polygon spins you through exactly one full turn of 360°—each exterior angle just halves from 72° to 36°.",
            choices: [
                MathematicalDebateChoice(
                    id: "ch09-a",
                    speakerLabel: "Aarav is right (720°)",
                    reasoningStatement: "More vertices always mean a larger total exterior angle sum.",
                    isCorrect: false,
                    socraticRebuttal: "It is the INTERIOR angle sum (n − 2) × 180° that grows with n; the exterior turns always close a single 360° loop."
                ),
                MathematicalDebateChoice(
                    id: "ch09-b",
                    speakerLabel: "Meera is right (always 360°)",
                    reasoningStatement: "One complete circuit around a convex perimeter rotates your heading by 360° regardless of n.",
                    isCorrect: true,
                    socraticRebuttal: "Spot on! That is why 180° − 360°/n is the fastest route to any regular interior angle."
                ),
                MathematicalDebateChoice(
                    id: "ch09-c",
                    speakerLabel: "Neither — exterior angles sum to 180°",
                    reasoningStatement: "Angles on a straight line sum to 180°.",
                    isCorrect: false,
                    socraticRebuttal: "One interior + one exterior pair sums to 180°, but all n exterior turns together complete a 360° circle."
                )
            ],
            invariantTakeaway: "The exterior angles of any convex polygon sum to 360°, so each regular interior angle is 180° − 360°/n."
        ),
        // Ch 10 -> OUP Ch 5 (Circles, Sectors & Prism Extrusion)
        MathematicalDebateScenario(
            id: "debate-ch10-mensuration",
            chapterNumber: 10,
            oupUnitNumber: 5,
            title: "Cavalieri's Tilted Coin Stack",
            contextPrompt: "Two stacks of 20 identical ₹10 coins sit on a desk: Stack A is straight and vertical; Stack B is pushed into a leaning slant of the same height. Zoya and Dev compare their volumes:",
            speakerAName: "Zoya",
            speakerAClaim: "Stack B has longer slanted edges, so its volume must be greater than Stack A!",
            speakerBName: "Dev",
            speakerBClaim: "Both stacks are made of the exact same 20 coins (identical cross-sectional area at every height), so their volumes are identical!",
            choices: [
                MathematicalDebateChoice(
                    id: "ch10-a",
                    speakerLabel: "Zoya is right (slanted stack has more volume)",
                    reasoningStatement: "Longer slant length means more 3D space.",
                    isCorrect: false,
                    socraticRebuttal: "Did sliding the coins sideways create any new metal? Volume depends on cross-section area × perpendicular height, not slant length!"
                ),
                MathematicalDebateChoice(
                    id: "ch10-b",
                    speakerLabel: "Dev is right (volumes are equal)",
                    reasoningStatement: "Horizontal shearing preserves every slice's area and the perpendicular height (Cavalieri's Principle).",
                    isCorrect: true,
                    socraticRebuttal: "Exact! V = A_cross × h_perp holds whether a prism or cylinder is right or oblique."
                ),
                MathematicalDebateChoice(
                    id: "ch10-c",
                    speakerLabel: "Stack B has less volume because it leans",
                    reasoningStatement: "Tilting compresses the space.",
                    isCorrect: false,
                    socraticRebuttal: "Each coin keeps its exact thickness and circular area, so total volume is unchanged."
                )
            ],
            invariantTakeaway: "Volume equals cross-sectional area times perpendicular height: V = A_cross × h_⊥."
        ),
        // Ch 11 -> OUP Ch 3 (Pythagoras, Bearings & Constructions)
        MathematicalDebateScenario(
            id: "debate-ch11-pythagoras",
            chapterNumber: 11,
            oupUnitNumber: 3,
            title: "The Return Bearing Trap",
            contextPrompt: "A rescue boat sails from Mumbai Harbour (M) to a lighthouse (L) on a three-figure bearing of 065°. Tara and Rohan debate the back-bearing to return from L to M:",
            speakerAName: "Rohan",
            speakerAClaim: "Just subtract from 360°: 360° − 065° = 295°!",
            speakerBName: "Tara",
            speakerBClaim: "Reversing direction along the same straight line turns by a half-circle (180°), and the North lines at M and L are parallel: 065° + 180° = 245°!",
            choices: [
                MathematicalDebateChoice(
                    id: "ch11-a",
                    speakerLabel: "Rohan is right (295°)",
                    reasoningStatement: "Opposite bearings always sum to 360°.",
                    isCorrect: false,
                    socraticRebuttal: "295° points North-West! Since the boat sailed North-East (065°), to return home it must sail South-West (245°)."
                ),
                MathematicalDebateChoice(
                    id: "ch11-b",
                    speakerLabel: "Tara is right (245°)",
                    reasoningStatement: "By alternate angles on parallel North lines, the reverse direction differs by exactly 180°.",
                    isCorrect: true,
                    socraticRebuttal: "Spot on! Back-bearing = θ ± 180°, never 360° − θ."
                ),
                MathematicalDebateChoice(
                    id: "ch11-c",
                    speakerLabel: "Neither — it is 180° − 065° = 115°",
                    reasoningStatement: "Co-interior angles on parallel North lines sum to 180°.",
                    isCorrect: false,
                    socraticRebuttal: "115° is the angle measured anticlockwise from South or internal to the parallel lines, not the clockwise angle from North."
                )
            ],
            invariantTakeaway: "Because all North lines are parallel, the back-bearing of θ is always θ + 180° (if θ < 180°) or θ − 180° (if θ ≥ 180°)."
        ),
        // Ch 12 -> OUP Ch 4 (Scale Drawings, Similarity & Trigonometry)
        MathematicalDebateScenario(
            id: "debate-ch12-trig",
            chapterNumber: 12,
            oupUnitNumber: 4,
            title: "Scaling the Triangle vs Scaling the Sine",
            contextPrompt: "A right-angled triangle with legs 3 cm, 4 cm, and hypotenuse 5 cm is enlarged by scale factor 3 to become 9 cm, 12 cm, 15 cm. What happens to sin θ?",
            speakerAName: "Vivaan",
            speakerAClaim: "Since every side tripled, sin θ also triples from 3/5 to 9/5!",
            speakerBName: "Ananya",
            speakerBClaim: "Both Opposite and Hypotenuse tripled, so the ratio (3 × 3)/(3 × 5) = 9/15 simplifies right back to 3/5—the angle θ didn't change!",
            choices: [
                MathematicalDebateChoice(
                    id: "ch12-a",
                    speakerLabel: "Vivaan is right (sin θ triples)",
                    reasoningStatement: "Enlarging a triangle enlarges its trigonometric values.",
                    isCorrect: false,
                    socraticRebuttal: "Can sin θ ever exceed 1 in a right triangle? The hypotenuse is always the longest side!"
                ),
                MathematicalDebateChoice(
                    id: "ch12-b",
                    speakerLabel: "Ananya is right (sin θ stays 3/5 = 0.6)",
                    reasoningStatement: "Similar triangles share identical side ratios because the scale factor k cancels in (k·Opp)/(k·Hyp).",
                    isCorrect: true,
                    socraticRebuttal: "Exact! Trigonometric ratios depend ONLY on the angle θ, never on the zoom level of the triangle."
                ),
                MathematicalDebateChoice(
                    id: "ch12-c",
                    speakerLabel: "sin θ increases by 3² = 9 times",
                    reasoningStatement: "Ratios scale with area.",
                    isCorrect: false,
                    socraticRebuttal: "Area scales by k² = 9, but length ratios scale by k/k = 1 (invariant)."
                )
            ],
            invariantTakeaway: "Trigonometric ratios (sin, cos, tan) are scale-invariant properties of the angle θ itself."
        ),
        // Ch 13 -> OUP Ch 10 (Statistics, Histograms & Quartiles)
        MathematicalDebateScenario(
            id: "debate-ch13-statistics",
            chapterNumber: 13,
            oupUnitNumber: 10,
            title: "The Unequal-Width Histogram Illusion",
            contextPrompt: "In a commute-time histogram, Interval A (width 10 min) has bar height FD = 4, and Interval B (width 30 min) has bar height FD = 2. Which interval has more commuters?",
            speakerAName: "Neel",
            speakerAClaim: "Interval A has twice the bar height (4 vs 2), so Interval A has twice as many commuters!",
            speakerBName: "Sana",
            speakerBClaim: "In a histogram, AREA = Frequency! Interval A has area 10 × 4 = 40, while Interval B has area 30 × 2 = 60 commuters.",
            choices: [
                MathematicalDebateChoice(
                    id: "ch13-a",
                    speakerLabel: "Neel is right (Interval A has more)",
                    reasoningStatement: "The tallest bar always represents the highest frequency.",
                    isCorrect: false,
                    socraticRebuttal: "Height equals frequency ONLY when all class widths are equal. Here Interval B is 3 times wider!"
                ),
                MathematicalDebateChoice(
                    id: "ch13-b",
                    speakerLabel: "Sana is right (Interval B has 60 vs 40)",
                    reasoningStatement: "Frequency = Frequency Density × Class Width (the area of the rectangle).",
                    isCorrect: true,
                    socraticRebuttal: "Spot on! Interval A is more crowded per minute, but Interval B spans 30 minutes and holds 60 commuters in total."
                ),
                MathematicalDebateChoice(
                    id: "ch13-c",
                    speakerLabel: "They have the same frequency",
                    reasoningStatement: "Width and height cancel out.",
                    isCorrect: false,
                    socraticRebuttal: "Check the products: 10 × 4 = 40 ≠ 30 × 2 = 60."
                )
            ],
            invariantTakeaway: "In a histogram, bar AREA (Width × Frequency Density) equals Frequency."
        ),
        // Ch 14 -> OUP Ch 15 (Combinatorics & Probability Trees)
        MathematicalDebateScenario(
            id: "debate-ch14-combinatorics",
            chapterNumber: 14,
            oupUnitNumber: 15,
            title: "Podium Medals vs Project Team",
            contextPrompt: "From 6 students, how does choosing Gold, Silver, Bronze medallists differ from choosing a 3-person cleanup team?",
            speakerAName: "Kabir",
            speakerAClaim: "Both choose 3 people from 6, so both have 6 × 5 × 4 = 120 ways!",
            speakerBName: "Diya",
            speakerBClaim: "For the cleanup team, {A, B, C} in any order is the SAME team! So we divide 120 by 3! = 6 permutations to get 20 teams.",
            choices: [
                MathematicalDebateChoice(
                    id: "ch14-a",
                    speakerLabel: "Kabir is right (both are 120)",
                    reasoningStatement: "Selecting 3 people out of 6 always uses 6 × 5 × 4.",
                    isCorrect: false,
                    socraticRebuttal: "If Aarav, Zoya, and Dev are on the cleanup team, does it matter who was named first? All 6 orderings give the exact same team!"
                ),
                MathematicalDebateChoice(
                    id: "ch14-b",
                    speakerLabel: "Diya is right (120 podiums vs 20 teams)",
                    reasoningStatement: "Unordered combinations divide ordered permutations by k! to collapse duplicate orderings.",
                    isCorrect: true,
                    socraticRebuttal: "Exact! 6P3 = 120 ordered podiums; 6C3 = 120 / 6 = 20 unordered committees."
                ),
                MathematicalDebateChoice(
                    id: "ch14-c",
                    speakerLabel: "Divide by 3 instead of 3! = 6",
                    reasoningStatement: "There are 3 spots, so divide by 3.",
                    isCorrect: false,
                    socraticRebuttal: "Three people can be arranged in 3 × 2 × 1 = 6 ways, not 3 ways."
                )
            ],
            invariantTakeaway: "nCr = nPr / r! because every unordered subset of size r corresponds to r! ordered permutations."
        ),
        // Ch 15 -> OUP Ch 15 (Bayes & Conditional Probability)
        MathematicalDebateScenario(
            id: "debate-ch15-bayes",
            chapterNumber: 15,
            oupUnitNumber: 15,
            title: "The Rare Disease Screening Paradox",
            contextPrompt: "Out of 1,000 people, 10 are sick (and 9 test +) while 990 are healthy (and 9 test + as false alarms). If you test +, what is P(Sick | +)?",
            speakerAName: "Arjun",
            speakerAClaim: "Since 9 out of 10 sick people test positive, the test is 90% accurate—so you have a 90% chance of being sick!",
            speakerBName: "Priya",
            speakerBClaim: "Look at the 18 people who tested positive: 9 are truly sick and 9 are false alarms! So P(Sick | +) = 9 / 18 = 50%.",
            choices: [
                MathematicalDebateChoice(
                    id: "ch15-a",
                    speakerLabel: "Arjun is right (90%)",
                    reasoningStatement: "P(Sick | +) is the same as the test's sensitivity P(+ | Sick).",
                    isCorrect: false,
                    socraticRebuttal: "That's the Base-Rate Fallacy! Because healthy people outnumber sick people 99 to 1, even a 1% false-positive rate produces just as many positive tests as the sick group."
                ),
                MathematicalDebateChoice(
                    id: "ch15-b",
                    speakerLabel: "Priya is right (9 / 18 = 50%)",
                    reasoningStatement: "Conditioning on '+' restricts the sample space to the 18 total positive tests (9 true + 9 false).",
                    isCorrect: true,
                    socraticRebuttal: "Spot on! Zooming into the 18 positive tiles makes the 50% split unmistakable."
                ),
                MathematicalDebateChoice(
                    id: "ch15-c",
                    speakerLabel: "Neither — it is 9 / 1,000 = 0.9%",
                    reasoningStatement: "Always divide by the total population of 1,000.",
                    isCorrect: false,
                    socraticRebuttal: "0.9% is P(Sick AND +) before taking the test. Once you know the test is +, the 982 negative testers are eliminated!"
                )
            ],
            invariantTakeaway: "Conditioning on event B restricts the denominator to ONLY the outcomes where B occurred: P(A|B) = |A ∩ B| / |B|."
        ),
        // Ch 16 -> OUP Ch 14 (Coordinate Geometry & Straight-Line Graphs)
        MathematicalDebateScenario(
            id: "debate-ch16-graphs",
            chapterNumber: 16,
            oupUnitNumber: 14,
            title: "Perpendicular Gradients in the Plane",
            contextPrompt: "Line L₁ has gradient m₁ = 2/3. Ira and Reyansh debate the gradient m₂ of a line L₂ perpendicular (at 90°) to L₁:",
            speakerAName: "Reyansh",
            speakerAClaim: "Flip the fraction upside down to get the reciprocal: m₂ = 3/2!",
            speakerBName: "Ira",
            speakerBClaim: "Rotating a right-angled slope triangle by 90° swaps rise and run AND reverses one sign: m₂ = −3/2 (so m₁ × m₂ = −1).",
            choices: [
                MathematicalDebateChoice(
                    id: "ch16-a",
                    speakerLabel: "Reyansh is right (m₂ = +3/2)",
                    reasoningStatement: "Perpendicular lines have reciprocal positive slopes.",
                    isCorrect: false,
                    socraticRebuttal: "Both +2/3 and +3/2 slope uphill from left to right—two uphill lines can never meet at 90°!"
                ),
                MathematicalDebateChoice(
                    id: "ch16-b",
                    speakerLabel: "Ira is right (m₂ = −3/2)",
                    reasoningStatement: "A 90° rotation maps vector (3, 2) to (−2, 3), giving slope 3/(−2) = −3/2.",
                    isCorrect: true,
                    socraticRebuttal: "Exact! (2/3) × (−3/2) = −1."
                ),
                MathematicalDebateChoice(
                    id: "ch16-c",
                    speakerLabel: "Neither — m₂ = −2/3",
                    reasoningStatement: "Just negate the slope without flipping the fraction.",
                    isCorrect: false,
                    socraticRebuttal: "m = −2/3 is a reflection across the y-axis, not a 90° rotation!"
                )
            ],
            invariantTakeaway: "Perpendicular lines satisfy m₁ × m₂ = −1 because rotating (Δx, Δy) by 90° gives (−Δy, Δx)."
        ),
        // Ch 17 -> OUP Ch 14 (Calculus I: Secant to Tangent Derivative)
        MathematicalDebateScenario(
            id: "debate-ch17-derivative",
            chapterNumber: 17,
            oupUnitNumber: 14,
            title: "Zero Slope at the Peak of a Ball's Flight",
            contextPrompt: "A cricket ball thrown straight up has height h(t) = 20t − 5t². At t = 2 s, its velocity dh/dt = 0. What does dh/dt = 0 mean?",
            speakerAName: "Dev",
            speakerAClaim: "It means the ball's height is 0 meters and gravity has switched off!",
            speakerBName: "Sia",
            speakerBClaim: "Height is h(2) = 20 m (the peak)! dh/dt = 0 means the tangent line is momentarily horizontal as the ball transitions from rising (+) to falling (−).",
            choices: [
                MathematicalDebateChoice(
                    id: "ch17-a",
                    speakerLabel: "Dev is right (height is 0)",
                    reasoningStatement: "When the derivative is zero, the function value is also zero.",
                    isCorrect: false,
                    socraticRebuttal: "Plug t = 2 into h(t): 20(2) − 5(4) = 20 meters high! Derivative measures slope, not height."
                ),
                MathematicalDebateChoice(
                    id: "ch17-b",
                    speakerLabel: "Sia is right (horizontal tangent at maximum height)",
                    reasoningStatement: "A smooth curve reaches its local maximum or minimum where its instantaneous rate of change passes through 0.",
                    isCorrect: true,
                    socraticRebuttal: "Spot on! To change from climbing (+slope) to descending (−slope), the tangent must pass through 0 slope at the summit."
                ),
                MathematicalDebateChoice(
                    id: "ch17-c",
                    speakerLabel: "The ball hovers at rest forever after t = 2",
                    reasoningStatement: "Zero velocity means no further motion.",
                    isCorrect: false,
                    socraticRebuttal: "Velocity is zero only at the single instant t = 2 s; acceleration (−10 m/s²) keeps pulling it downward."
                )
            ],
            invariantTakeaway: "At a smooth peak or valley, the instantaneous rate of change dy/dx = 0 (horizontal tangent)."
        ),
        // Ch 18 -> OUP Ch 14 (Calculus II: Accumulation & Definite Integrals)
        MathematicalDebateScenario(
            id: "debate-ch18-integral",
            chapterNumber: 18,
            oupUnitNumber: 14,
            title: "What the Area Under a Velocity Graph Means",
            contextPrompt: "A metro train's speed v(t) (in m/s) is plotted against time t (in seconds). Zoya and Arjun debate what the area under the v(t) curve represents:",
            speakerAName: "Arjun",
            speakerAClaim: "Area is just geometry—it gives the train's acceleration!",
            speakerBName: "Zoya",
            speakerBClaim: "Each thin rectangle has height (m/s) × width (s) = meters! Summing all rectangles gives total distance travelled.",
            choices: [
                MathematicalDebateChoice(
                    id: "ch18-a",
                    speakerLabel: "Arjun is right (acceleration)",
                    reasoningStatement: "Anything derived from a velocity graph is acceleration.",
                    isCorrect: false,
                    socraticRebuttal: "Acceleration is the SLOPE (dv/dt) with units (m/s) ÷ s = m/s². Area multiplies axes!"
                ),
                MathematicalDebateChoice(
                    id: "ch18-b",
                    speakerLabel: "Zoya is right (total displacement in meters)",
                    reasoningStatement: "Multiplying vertical units (m/s) by horizontal units (s) yields meters, accumulating distance.",
                    isCorrect: true,
                    socraticRebuttal: "Exact! Slope divides units (dy/dx); integral area multiplies units (∫ y dx)."
                ),
                MathematicalDebateChoice(
                    id: "ch18-c",
                    speakerLabel: "Neither — it gives average speed",
                    reasoningStatement: "Area equals average value.",
                    isCorrect: false,
                    socraticRebuttal: "To get average speed, you must divide that total area (total distance) by the time interval Δt."
                )
            ],
            invariantTakeaway: "Derivative is slope (rate of change, y/x); definite integral is accumulated area (product of units, y × x)."
        ),
        // Ch 19 -> OUP Ch 16 (Vectors, Translations & Transformations)
        MathematicalDebateScenario(
            id: "debate-ch19-vectors",
            chapterNumber: 19,
            oupUnitNumber: 16,
            title: "Triangle Law of Vector Addition",
            contextPrompt: "A drone flies along vector a = (3, 4) (length 5 m) and then vector b = (5, −4) (length √41 m). What is the resultant displacement a + b?",
            speakerAName: "Kabir",
            speakerAClaim: "Add the two lengths together: |a + b| = |a| + |b|!",
            speakerBName: "Meera",
            speakerBClaim: "Place b nose-to-tail at the tip of a: the +4 up and −4 down cancel, leaving resultant a + b = (3 + 5, 4 − 4) = (8, 0) of length 8 m!",
            choices: [
                MathematicalDebateChoice(
                    id: "ch19-a",
                    speakerLabel: "Kabir is right (add lengths directly)",
                    reasoningStatement: "Vector magnitude distributes over addition.",
                    isCorrect: false,
                    socraticRebuttal: "|a + b| equals |a| + |b| ONLY when both vectors point in the exact same direction! Otherwise the triangle shortcut is shorter."
                ),
                MathematicalDebateChoice(
                    id: "ch19-b",
                    speakerLabel: "Meera is right (add components: (8, 0), length 8)",
                    reasoningStatement: "Horizontal and vertical displacements add independently by nose-to-tail chaining.",
                    isCorrect: true,
                    socraticRebuttal: "Spot on! By the Triangle Inequality, |a + b| ≤ |a| + |b|."
                ),
                MathematicalDebateChoice(
                    id: "ch19-c",
                    speakerLabel: "Multiply components (3×5, 4×(−4))",
                    reasoningStatement: "Combining vectors multiplies coordinates.",
                    isCorrect: false,
                    socraticRebuttal: "Walking 3 steps East then 5 steps East puts you 3 + 5 = 8 steps East, not 15."
                )
            ],
            invariantTakeaway: "Vectors add component-wise (nose-to-tail), and the straight-line resultant satisfies |a + b| ≤ |a| + |b|."
        ),
        // Ch 20 -> OUP Ch 13 (Matrices, Determinants & Quadratic Factorisation)
        MathematicalDebateScenario(
            id: "debate-ch20-matrices",
            chapterNumber: 20,
            oupUnitNumber: 13,
            title: "When a Matrix Collapses 2D Space to a Line",
            contextPrompt: "Matrix A = [[2, 4], [1, 2]] transforms the unit square. Ananya and Vivaan debate the area of the transformed shape:",
            speakerAName: "Vivaan",
            speakerAClaim: "Since every entry is positive, the unit square stretches into a bigger parallelogram of area 2 × 4 + 1 × 2 = 10!",
            speakerBName: "Ananya",
            speakerBClaim: "Look at the columns: (4, 2) is just 2 times (2, 1)! Both basis vectors land on the SAME line, so det(A) = 2(2) − 4(1) = 0 and the area collapses to 0.",
            choices: [
                MathematicalDebateChoice(
                    id: "ch20-a",
                    speakerLabel: "Vivaan is right (area = 10)",
                    reasoningStatement: "Positive matrix entries always expand area.",
                    isCorrect: false,
                    socraticRebuttal: "Plot the two transformed basis vectors (2, 1) and (4, 2): they point along the exact same slope 1/2, enclosing zero width between them!"
                ),
                MathematicalDebateChoice(
                    id: "ch20-b",
                    speakerLabel: "Ananya is right (det(A) = ad − bc = 0)",
                    reasoningStatement: "When one column is a scalar multiple of the other, the 2D plane squashes onto a 1D line of zero area.",
                    isCorrect: true,
                    socraticRebuttal: "Exact! Determinant ad − bc = 2(2) − 4(1) = 0 diagnoses collinear basis vectors."
                ),
                MathematicalDebateChoice(
                    id: "ch20-c",
                    speakerLabel: "The area becomes negative",
                    reasoningStatement: "Subtraction makes the area negative.",
                    isCorrect: false,
                    socraticRebuttal: "Here ad = 4 and bc = 4, so ad − bc = 0 (a flat line segment)."
                )
            ],
            invariantTakeaway: "det([[a, b], [c, d]]) = ad − bc measures the signed area scale factor of a 2×2 linear transformation."
        )
    ]
}

// MARK: - 8. Daily 15-Minute Flow Session Composer (Today Room Ritual)

public enum DailyFlowStageKind: Int, Codable, CaseIterable, Identifiable, Sendable {
    case fsrsMemoryLock = 0
    case conceptDiscoveryBeat = 1
    case misconceptionImmunity = 2
    case companionWorkbookProof = 3

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .fsrsMemoryLock:
            return "1. Memory Lock (FSRS)"
        case .conceptDiscoveryBeat:
            return "2. Concept Discovery Beat"
        case .misconceptionImmunity:
            return "3. Misconception Immunity"
        case .companionWorkbookProof:
            return "4. Workbook Proof (CPA)"
        }
    }

    public var durationLabel: String {
        switch self {
        case .fsrsMemoryLock: return "3 min"
        case .conceptDiscoveryBeat: return "4 min"
        case .misconceptionImmunity: return "4 min"
        case .companionWorkbookProof: return "4 min"
        }
    }

    public var systemImage: String {
        switch self {
        case .fsrsMemoryLock: return "brain.head.profile"
        case .conceptDiscoveryBeat: return "sparkles.rectangle.stack.fill"
        case .misconceptionImmunity: return "shield.lefthalf.filled"
        case .companionWorkbookProof: return "checkmark.seal.fill"
        }
    }
}

struct DailyFlowSessionPlan: Equatable, Sendable {
    let reviewCards: [FSRSCardRecord]
    var reviewCard: FSRSCardRecord? { reviewCards.first }
    let chapter: PatternedWorldChapter
    let discoveryBeat: ChapterInteractiveBeat
    let debateScenario: MathematicalDebateScenario
    let trapProblem: QuantitativeMathsProblem
    let proofQuestion: SchoolMathsQuestion
    let estimatedMinutes: Int
    /// Stage 3's knows-when question from Euclid's Workshop, when a proposition is in her head
    /// but she has not yet shown she knows when to use it.
    var euclidKnowsWhen: EuclidKnowsWhenQuestion? = nil
}

enum DailyFlowSessionEngine {
    static func buildPlan(
        pack: KymMathsSeedPack,
        dueCards: [FSRSCardRecord],
        allCards: [FSRSCardRecord],
        selectedChapterNumber: Int,
        selectedUnitNumber: Int,
        proofsByQuestionId: [String: QuestionProofRecord],
        euclidProgress: EuclidProgress = EuclidProgress()
    ) -> DailyFlowSessionPlan {
        // Stage 1: Up to 3 FSRS v5 retrieval cards (due cards first; if 0 due, selects the 2 lowest-stability warm-up cards)
        let selectedReviewCards: [FSRSCardRecord] = {
            if !dueCards.isEmpty {
                return Array(dueCards.prefix(3))
            }
            let sortedByStability = allCards.sorted { $0.stability < $1.stability }
            return Array(sortedByStability.prefix(2))
        }()

        // Stage 2: Concept Discovery Beat from selected chapter (or Ch 0)
        let chapter = pack.chapters.first(where: { $0.number == selectedChapterNumber })
            ?? pack.chapters[0]
        let beats = ChapterInteractiveBeatEngine.beats(for: chapter)
        let discoveryBeat = beats.first(where: { $0.kind == .interactiveLabAndFormula })
            ?? beats.first(where: { $0.kind == .calloutGate })
            ?? beats[0]

        // Stage 3: Misconception Immunity Debate + Quantitative Trap Problem
        let debate = MathematicalDebateEngine.scenario(for: chapter)
        let template = QuantitativeTemplateKind.allCases.first(where: { $0.patternedWorldChapter == chapter.number })
            ?? .setInclusionExclusion
        let trapProblem = QuantitativeMathsEngine.generate(template: template, seed: max(1, chapter.number + 1))

        // Stage 4: Companion Workbook Proof (prefer an unproven question in the selected unit)
        let unitQuestions = pack.schoolQuestions.filter { $0.unitNumber == selectedUnitNumber }
        let candidateQuestions = unitQuestions.isEmpty ? pack.schoolQuestions : unitQuestions
        let proofQuestion = candidateQuestions.first(where: { q in
            let level = proofsByQuestionId[q.id]?.level ?? .unseen
            return level == .unseen || level == .assisted
        }) ?? candidateQuestions[0]

        return DailyFlowSessionPlan(
            reviewCards: selectedReviewCards,
            chapter: chapter,
            discoveryBeat: discoveryBeat,
            debateScenario: debate,
            trapProblem: trapProblem,
            proofQuestion: proofQuestion,
            estimatedMinutes: 15,
            euclidKnowsWhen: EuclidKnowsWhen.select(progress: euclidProgress)
        )
    }
}
