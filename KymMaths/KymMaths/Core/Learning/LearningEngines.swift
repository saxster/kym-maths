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
    let matchedKeywords: [String]
    let missingKeywords: [String]
    let coverageFraction: Double
    let isPass: Bool
    let resultingProofLevel: QuestionProofLevel
    let feedbackSummary: String
    let diagnosticCell: ConfidenceVerdictCell
    let recommendedFollowUp: DiagnosticFollowUpAction
    let effectiveUsedAssistance: Bool

    init(
        matchedKeywords: [String],
        missingKeywords: [String],
        coverageFraction: Double,
        isPass: Bool,
        resultingProofLevel: QuestionProofLevel,
        feedbackSummary: String,
        diagnosticCell: ConfidenceVerdictCell = .solidKnowledge,
        recommendedFollowUp: DiagnosticFollowUpAction = .none,
        effectiveUsedAssistance: Bool = false
    ) {
        self.matchedKeywords = matchedKeywords
        self.missingKeywords = missingKeywords
        self.coverageFraction = coverageFraction
        self.isPass = isPass
        self.resultingProofLevel = resultingProofLevel
        self.feedbackSummary = feedbackSummary
        self.diagnosticCell = diagnosticCell
        self.recommendedFollowUp = recommendedFollowUp
        self.effectiveUsedAssistance = effectiveUsedAssistance
    }
}

enum QuestionProofService {
    static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", comps.year ?? 2026, comps.month ?? 1, comps.day ?? 1)
    }

    private static func normalizeMathText(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: ",", with: "")
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
                missingKeywordsCSV: question.markSchemeKeywords.joined(separator: ","),
                highestHintRung: highestHintRung.rawValue,
                confidencePercent: 0,
                declinedToGuess: true,
                thinkingTrace: thinkingTrace
            )
            let eval = QuestionEvaluationResult(
                matchedKeywords: [],
                missingKeywords: question.markSchemeKeywords,
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

        let normalizedAnswer = normalizeMathText(answerText)
        var matched: [String] = []
        var missing: [String] = []

        for kw in question.markSchemeKeywords {
            let normKw = normalizeMathText(kw)
            if !normKw.isEmpty && (normalizedAnswer.contains(normKw) || STEMPolynomial.areEquivalent(answerText, kw)) {
                matched.append(kw)
            } else {
                missing.append(kw)
            }
        }

        let total = max(1, question.markSchemeKeywords.count)
        let coverage = Double(matched.count) / Double(total)
        let trimmed = normalizedAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        let polynomialEquiv = STEMPolynomial.areEquivalent(answerText, question.fadedAnswer)
        let isPass = !trimmed.isEmpty && (
            coverage >= 0.50
            || trimmed == normalizeMathText(question.fadedAnswer)
            || polynomialEquiv
        )

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
                ? "Good guided solution\(rungNote) (\(matched.count)/\(total) mark-scheme targets). Now solve with at most R0–R2 hints to earn Independent Proof."
                : "Guided attempt\(rungNote) recorded. Check: \(missing.prefix(3).joined(separator: ", "))."
        } else if isPass {
            if lastPassDay != todayKey {
                passDays += 1
                lastPassDay = todayKey
            }
            if passDays >= 2 {
                nextLevel = .secure
                feedback = "Secure across \(passDays) separate days (\(matched.count)/\(total) mark-scheme targets)."
            } else {
                nextLevel = .proven
                feedback = "Proven independently today (\(matched.count)/\(total) mark-scheme targets). Prove it on one more day to lock it as Secure."
            }
        } else {
            nextLevel = .shaky
            feedback = "Almost there (\(matched.count)/\(total) mark-scheme targets). Check key steps: \(missing.prefix(3).joined(separator: ", "))."
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
            thinkingTrace: thinkingTrace
        )

        let eval = QuestionEvaluationResult(
            matchedKeywords: matched,
            missingKeywords: missing,
            coverageFraction: coverage,
            isPass: isPass,
            resultingProofLevel: nextLevel,
            feedbackSummary: feedback,
            diagnosticCell: cell,
            recommendedFollowUp: followUp,
            effectiveUsedAssistance: effectiveAssisted
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
