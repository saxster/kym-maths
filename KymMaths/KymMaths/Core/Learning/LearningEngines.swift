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
    private static let fallback = MathematicalDebateScenario(
        id: "debate-fallback",
        chapterNumber: 0,
        oupUnitNumber: 1,
        title: "Who is right?",
        contextPrompt: "",
        speakerAName: "A",
        speakerAClaim: "",
        speakerBName: "B",
        speakerBClaim: "",
        choices: [],
        invariantTakeaway: ""
    )

    /// The chapter's own "Who is right?" from its pack record, or the catalog's while the chapter
    /// is not yet rewritten.
    static func scenario(for chapter: PatternedWorldChapter) -> MathematicalDebateScenario {
        chapter.debate
            ?? MathematicalDebateCatalog.all.first { $0.chapterNumber == chapter.number }
            ?? MathematicalDebateCatalog.all.first
            ?? fallback
    }

    /// The first chapter's debate, in chapter order, that maps to this school unit.
    static func scenario(forOUPUnit unitNumber: Int, in chapters: [PatternedWorldChapter]) -> MathematicalDebateScenario {
        let scenarios = chapters.sorted { $0.number < $1.number }.map(scenario(for:))
        return scenarios.first { $0.oupUnitNumber == unitNumber }
            ?? scenarios.first
            ?? MathematicalDebateCatalog.all.first
            ?? fallback
    }

    public static func evaluateChoice(
        scenario: MathematicalDebateScenario,
        choiceId: String
    ) -> MathematicalDebateChoice? {
        scenario.choices.first(where: { $0.id == choiceId })
    }
}

public enum MathematicalDebateCatalog {
    public static let all: [MathematicalDebateScenario] = []
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
