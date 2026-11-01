import SwiftUI

// MARK: - 3-Stage Singapore CPA & Worked-Example -> Faded -> Independent Proof Practice View

struct QuestionProofPracticeView: View {
    let question: SchoolMathsQuestion
    @Bindable var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeTokens) private var tokens

    @State private var showWorkedExample = false
    @State private var showFadedScaffold = false
    @State private var usedAssistanceInSession = false
    @State private var fadedInput = ""
    @State private var answerText = ""
    @State private var evaluation: QuestionEvaluationResult?
    @State private var graduatedFeedback: SocraticGraduatedFeedback?
    @State private var interrogationResponse = ""
    @State private var showScratchpad = true

    private var recommendedCPAStage: ConcretenessRepresentationStage {
        let skill = store.bktSkillsById[question.topicCode]
        let exposure = (skill?.independentEvidenceCount ?? 0) + (skill?.assistedEvidenceCount ?? 0)
        let mastery = skill?.pLearned ?? 0.35
        return ConcretenessFadingEngine.recommendedStage(
            exposureCount: exposure,
            masteryProbability: mastery
        )
    }

    var body: some View {
        NavigationStack {
            JournalPage {
                // Header & Question Prompt
                JournalCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            JournalBadge(text: "Ch \(question.unitNumber) · Topic \(question.topicCode)", symbol: "book.closed", tone: .accent)
                            JournalBadge(text: "Tier: \(question.tier)", symbol: "layers.fill", tone: question.tier == "Challenge" ? .warning : .info)
                            JournalBadge(text: recommendedCPAStage.badgeTitle, symbol: "slider.horizontal.below.rectangle", tone: .info)
                            JournalBadge(text: "\(question.marks) marks · \(question.commandWord)", symbol: "checkmark.circle", tone: .neutral)
                            Spacer()
                            if let proof = store.proofsByQuestionId[question.id] {
                                JournalBadge(
                                    text: proof.level.displayTitle,
                                    symbol: proof.level.isIndependentProof ? "checkmark.seal.fill" : "clock",
                                    tone: proof.level.isIndependentProof ? .positive : .warning
                                )
                            }
                        }

                        Text(recommendedCPAStage.coachDirective)
                            .font(Typography.caption)
                            .foregroundStyle(tokens.accent)

                        Text(question.bookSection)
                            .font(Typography.caption)
                            .foregroundStyle(tokens.secondary)

                        Text(question.prompt)
                            .font(Typography.title3)
                            .foregroundStyle(tokens.primary)

                        // Scaffold controls (opening these marks usedAssistanceInSession = true)
                        HStack(spacing: Spacing.sm) {
                            Button {
                                showWorkedExample.toggle()
                                if showWorkedExample {
                                    usedAssistanceInSession = true
                                }
                            } label: {
                                Label(
                                    showWorkedExample ? "Hide Worked Example" : "1. View Worked Example (Assisted)",
                                    systemImage: "lightbulb.fill"
                                )
                            }
                            .buttonStyle(JournalSecondaryButtonStyle())

                            Button {
                                showFadedScaffold.toggle()
                                if showFadedScaffold {
                                    usedAssistanceInSession = true
                                }
                            } label: {
                                Label(
                                    showFadedScaffold ? "Hide Faded Step" : "2. Try Faded Scaffold (Assisted)",
                                    systemImage: "square.dashed"
                                )
                            }
                            .buttonStyle(JournalSecondaryButtonStyle())

                            if usedAssistanceInSession {
                                Button {
                                    showWorkedExample = false
                                    showFadedScaffold = false
                                    usedAssistanceInSession = false
                                    answerText = ""
                                    evaluation = nil
                                } label: {
                                    Label("Reset for Unassisted Proof", systemImage: "arrow.counterclockwise")
                                }
                                .buttonStyle(JournalSecondaryButtonStyle())
                            }
                        }

                        if usedAssistanceInSession {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundStyle(tokens.warning)
                                Text("Guided mode active: Because you opened a scaffold, this attempt will record as Assisted Practice. Click 'Reset for Unassisted Proof' when ready to prove independently.")
                                    .font(Typography.caption)
                                    .foregroundStyle(tokens.secondary)
                            }
                        }
                    }
                }

                // Stage 1: Worked Example
                if showWorkedExample {
                    JournalSection(
                        title: "Stage 1 · Worked Example & Singapore CPA Model",
                        eyebrow: "Study the Invariant Before Solving"
                    ) {
                        JournalCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text(question.workedExample)
                                    .font(Typography.body)
                                    .foregroundStyle(tokens.primary)
                            }
                        }
                    }
                }

                // Stage 2: Faded Completion
                if showFadedScaffold {
                    JournalSection(
                        title: "Stage 2 · Faded Step Completion",
                        eyebrow: "Complete the Missing Link"
                    ) {
                        JournalCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text(question.fadedPrompt)
                                    .font(Typography.subheadline)
                                    .foregroundStyle(tokens.primary)
                                HStack {
                                    TextField("Fill in the blank...", text: $fadedInput)
                                        .textFieldStyle(.roundedBorder)
                                    Text("Target: \(question.fadedAnswer)")
                                        .font(Typography.mono)
                                        .foregroundStyle(tokens.positive)
                                }
                            }
                        }
                    }
                }

                // Mathematical Scratchpad (Singapore Bar / Axes / Venn / Matrix)
                JournalSection(
                    title: "Working & Diagram Scratchpad",
                    eyebrow: "Draw Bar Models, Prime Trees, or Coordinate Sketches"
                ) {
                    JournalCard {
                        MathsScratchpadView(questionId: question.id, store: store)
                    }
                }

                // Stage 3: Final Solution & Mark-Scheme Verification
                JournalSection(
                    title: "Stage 3 · Final Solution & Mark-Scheme Proof",
                    eyebrow: usedAssistanceInSession ? "Submitting as Assisted Practice" : "Submitting as Independent Proof"
                ) {
                    JournalCard {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            LearnerTextInput(
                                title: "Write your working and final answer (include units or algebraic steps):",
                                placeholder: "Show your step-by-step reasoning and final value...",
                                text: $answerText,
                                minHeight: 110
                            )

                            HStack {
                                Button {
                                    evaluation = store.submitQuestionAttempt(
                                        question: question,
                                        answerText: answerText,
                                        usedAssistance: usedAssistanceInSession
                                    )
                                    graduatedFeedback = SocraticFeedbackEngine.evaluate(
                                        studentAnswer: answerText,
                                        expectedAnswer: question.fadedAnswer,
                                        keywords: question.markSchemeKeywords,
                                        workedHint: question.workedExample
                                    )
                                } label: {
                                    Label(
                                        usedAssistanceInSession ? "Check Guided Solution" : "Submit Independent Proof",
                                        systemImage: "checkmark.seal.fill"
                                    )
                                }
                                .buttonStyle(JournalPrimaryButtonStyle())

                                Spacer()
                            }

                            if let eval = evaluation {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    HStack {
                                        Image(systemName: eval.isPass ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                                            .foregroundStyle(eval.isPass ? tokens.positive : tokens.warning)
                                        Text(eval.feedbackSummary)
                                            .font(Typography.subheadline.weight(.semibold))
                                            .foregroundStyle(tokens.primary)
                                        if let grad = graduatedFeedback {
                                            Spacer()
                                            JournalBadge(
                                                text: grad.tier.badgeTitle,
                                                symbol: "sparkles",
                                                tone: grad.tier == .correct ? .positive : .warning
                                            )
                                        }
                                    }

                                    if let grad = graduatedFeedback {
                                        Text("\(grad.headline) — \(grad.socraticNudge)")
                                            .font(Typography.caption)
                                            .foregroundStyle(tokens.secondary)
                                        if let trap = grad.detectedTrap {
                                            JournalBadge(text: "Detected: \(trap)", symbol: "exclamationmark.shield", tone: .warning)
                                        }
                                    }

                                    if !eval.matchedKeywords.isEmpty {
                                        Text("Matched mark-scheme targets: \(eval.matchedKeywords.joined(separator: ", "))")
                                            .font(Typography.caption)
                                            .foregroundStyle(tokens.positive)
                                    }
                                    if !eval.missingKeywords.isEmpty {
                                        Text("Missing targets to include: \(eval.missingKeywords.joined(separator: ", "))")
                                            .font(Typography.caption)
                                            .foregroundStyle(tokens.warning)
                                    }

                                    if eval.isPass {
                                        let prompt = ElaborativeInterrogationEngine.makePrompt(
                                            for: question.bookSection,
                                            singaporeMethodFocus: store.selectedUnit.scienceInContext
                                        )
                                        Divider()
                                        Text("ELABORATIVE INTERROGATION · \(prompt.bloomLevel.uppercased())")
                                            .font(Typography.eyebrow)
                                            .foregroundStyle(tokens.accent)
                                        Text(prompt.question)
                                            .font(Typography.subheadline.weight(.semibold))
                                            .foregroundStyle(tokens.primary)
                                        Text("Hint: \(prompt.invariantHint)")
                                            .font(Typography.caption)
                                            .foregroundStyle(tokens.secondary)
                                        TextField("Explain why this works in 1 sentence...", text: $interrogationResponse)
                                            .textFieldStyle(.roundedBorder)
                                    }

                                    Divider()
                                    Text("CAMBRIDGE & SINGAPORE CPA MODEL SOLUTION")
                                        .font(Typography.eyebrow)
                                        .foregroundStyle(tokens.accent)
                                    Text(question.workedExample)
                                        .font(Typography.caption)
                                        .foregroundStyle(tokens.secondary)
                                }
                                .padding(Spacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: Spacing.radiusMD, style: .continuous)
                                        .fill(tokens.surfaceElevated)
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle("Topic \(question.topicCode) Proof Studio")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
