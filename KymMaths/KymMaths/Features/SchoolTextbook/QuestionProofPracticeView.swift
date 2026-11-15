import SwiftUI

// MARK: - 3-Stage Singapore CPA & Worked-Example -> Faded -> Independent Proof Practice View

struct QuestionProofPracticeView: View {
    let question: SchoolMathsQuestion
    @Bindable var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var showWorkedExample = false
    @State private var showFadedScaffold = false
    @State private var usedAssistanceInSession = false
    @State private var highestHintRung: HintLadderRung = .none
    @State private var currentHintRung: HintLadderRung = .none
    @State private var thinkingTrace = ""
    @State private var confidencePercent: Int = 75
    @State private var declinedToGuess = false
    @State private var fadedInput = ""
    @State private var fadedFeedback: SocraticGraduatedFeedback?
    @State private var revealFadedTarget = false
    @State private var cpaState = CPAManipulativeState(primaryValue: 5, secondaryValue: 12)
    @State private var answerText = ""
    @State private var evaluation: QuestionEvaluationResult?
    @State private var graduatedFeedback: SocraticGraduatedFeedback?
    @State private var interrogationResponse = ""
    @State private var interrogationLocked = false
    @State private var selectedFlawStepIndex: Int?
    @State private var flawScoreResult: SpotTheFlawScoreResult?

    private var effectiveAssisted: Bool {
        usedAssistanceInSession || highestHintRung.surrendersRetrieval
    }

    private var matchingSpotTheFlaw: SpotTheFlawPayload {
        let chKey = String(format: "ch%02d", question.unitNumber)
        return MathsSpotTheFlawCatalog.all.first(where: { $0.chapterId == chKey })
            ?? MathsSpotTheFlawCatalog.all[0]
    }

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
                            .foregroundStyle(Color.kymaiaPrimary)

                        Text(question.bookSection)
                            .font(Typography.caption)
                            .foregroundStyle(Color.kymaiaMutedInk)

                        Text(question.prompt)
                            .font(Typography.title3)
                            .foregroundStyle(Color.kymaiaInk)

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

                            if effectiveAssisted {
                                Button {
                                    showWorkedExample = false
                                    showFadedScaffold = false
                                    usedAssistanceInSession = false
                                    highestHintRung = .none
                                    currentHintRung = .none
                                    answerText = ""
                                    evaluation = nil
                                } label: {
                                    Label("Reset for Unassisted Proof", systemImage: "arrow.counterclockwise")
                                }
                                .buttonStyle(JournalSecondaryButtonStyle())
                            }
                        }

                        // 6-Rung Metered Hint Ladder (R0–R2 preserve retrieval; R3–R5 surrender retrieval)
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                Text("METERED 6-RUNG HINT LADDER (R0–R2 KEEP INDEPENDENT PROOF INTACT)")
                                    .font(Typography.eyebrow)
                                    .foregroundStyle(Color.kymaiaPrimary)
                                Spacer()
                                JournalBadge(
                                    text: highestHintRung.badgeText,
                                    symbol: highestHintRung.surrendersRetrieval ? "hand.raised.fill" : "shield.lefthalf.filled",
                                    tone: highestHintRung.surrendersRetrieval ? .warning : .positive
                                )
                            }
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Spacing.xs) {
                                    ForEach(HintLadderRung.allCases.filter { $0 != .none }, id: \.rawValue) { rung in
                                        Button {
                                            currentHintRung = rung
                                            if rung > highestHintRung {
                                                highestHintRung = rung
                                            }
                                            if rung.surrendersRetrieval {
                                                usedAssistanceInSession = true
                                            }
                                        } label: {
                                            Text(rung.badgeText)
                                                .font(Typography.caption.weight(.semibold))
                                        }
                                        .buttonStyle(JournalSecondaryButtonStyle())
                                    }
                                }
                            }
                            if currentHintRung != .none {
                                Text(MeteredHintLadderEngine.hint(for: question, rung: currentHintRung, thinkingTrace: thinkingTrace))
                                    .font(Typography.subheadline)
                                    .foregroundStyle(Color.kymaiaInk)
                                    .padding(Spacing.sm)
                                    .quietPanelBackground()
                            }
                        }

                        if effectiveAssisted {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundStyle(Color.kymaiaWarning)
                                Text("Guided mode active: Because you opened a R3–R5 hint or full scaffold, this attempt will record as Assisted Practice. R0–R2 hints preserve Independent Proof.")
                                    .font(Typography.caption)
                                    .foregroundStyle(Color.kymaiaMutedInk)
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
                                    .foregroundStyle(Color.kymaiaInk)
                            }
                        }
                    }
                }

                // Stage 2: Faded Completion (Non-Leaking Socratic Step Gate)
                if showFadedScaffold {
                    JournalSection(
                        title: "Stage 2 · Faded Step Completion",
                        eyebrow: "Complete & Verify the Missing Link Before Solo Proof"
                    ) {
                        JournalCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text(question.fadedPrompt)
                                    .font(Typography.subheadline)
                                    .foregroundStyle(Color.kymaiaInk)

                                MathSymbolRibbon(text: $fadedInput)

                                HStack(spacing: Spacing.sm) {
                                    TextField("Type the missing step or expression...", text: $fadedInput)
                                        .learnerTextInput(.retrieval)
                                        .textFieldStyle(.roundedBorder)
                                        .font(Typography.mono)
                                        .onSubmit {
                                            fadedFeedback = SocraticFeedbackEngine.evaluateFadedStep(
                                                studentInput: fadedInput,
                                                expectedFadedAnswer: question.fadedAnswer,
                                                workedHint: question.workedExample
                                            )
                                        }

                                    Button("Check Step") {
                                        fadedFeedback = SocraticFeedbackEngine.evaluateFadedStep(
                                            studentInput: fadedInput,
                                            expectedFadedAnswer: question.fadedAnswer,
                                            workedHint: question.workedExample
                                        )
                                    }
                                    .buttonStyle(JournalSecondaryButtonStyle())

                                    if fadedFeedback != nil || !fadedInput.isEmpty {
                                        Button("Reset Step") {
                                            fadedInput = ""
                                            fadedFeedback = nil
                                            revealFadedTarget = false
                                        }
                                        .buttonStyle(JournalSecondaryButtonStyle())
                                    }
                                }

                                if let fEval = fadedFeedback {
                                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                                        HStack {
                                            JournalBadge(
                                                text: fEval.tier.badgeTitle,
                                                symbol: fEval.tier == .correct ? "checkmark.seal.fill" : "lightbulb.fill",
                                                tone: fEval.tier == .correct ? .positive : .warning
                                            )
                                            Text(fEval.headline)
                                                .font(Typography.caption.weight(.bold))
                                                .foregroundStyle(Color.kymaiaInk)
                                            Spacer()
                                            if fEval.tier != .correct {
                                                Button(revealFadedTarget ? "Hide Step Target" : "Reveal Step Target") {
                                                    revealFadedTarget.toggle()
                                                    usedAssistanceInSession = true
                                                }
                                                .buttonStyle(JournalSecondaryButtonStyle())
                                            }
                                        }
                                        Text(fEval.socraticNudge)
                                            .font(Typography.caption)
                                            .foregroundStyle(Color.kymaiaMutedInk)
                                        if revealFadedTarget || fEval.tier == .correct {
                                            Text("Verified Step Target: \(question.fadedAnswer)")
                                                .font(Typography.mono)
                                                .foregroundStyle(Color.kymaiaSuccess)
                                        }
                                    }
                                    .padding(Spacing.xs)
                                    .quietPanelBackground()
                                }
                            }
                        }
                    }
                }

                // Interactive CPA Manipulative Sandbox (Concrete -> Pictorial -> Abstract Lockstep)
                JournalSection(
                    title: "Interactive CPA Manipulative Sandbox",
                    eyebrow: "Touch & Partition the Model · Stamp Live Equations into Your Working"
                ) {
                    CPAManipulativeSandboxCard(
                        spec: CPAManipulativeEngine.spec(for: question),
                        state: $cpaState
                    ) { stampedEquation in
                        if answerText.isEmpty {
                            answerText = stampedEquation
                        } else {
                            answerText += "\n" + stampedEquation
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
                    eyebrow: effectiveAssisted ? "Submitting as Assisted Practice" : "Submitting as Independent Proof"
                ) {
                    JournalCard {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            LearnerTextInput(
                                title: "Thinking Trace (optional — dictate or jot what invariant you're testing):",
                                placeholder: "e.g., Let 1 bar unit be the unknown, or compare the two areas...",
                                text: $thinkingTrace,
                                minHeight: 64
                            )

                            LearnerTextInput(
                                title: "Write your working and final answer (include units or algebraic steps):",
                                placeholder: "Show your step-by-step reasoning and final value...",
                                text: $answerText,
                                minHeight: 110
                            )

                            // Confidence × Verdict Selector (LearnHarness Calibration Channel)
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("CONFIDENCE CALIBRATION (HOW SURE ARE YOU?)")
                                    .font(Typography.eyebrow)
                                    .foregroundStyle(Color.kymaiaPrimary)
                                HStack(spacing: Spacing.sm) {
                                    Button {
                                        declinedToGuess = true
                                        confidencePercent = 0
                                    } label: {
                                        Label("I don't know yet", systemImage: declinedToGuess ? "checkmark.circle.fill" : "questionmark.circle")
                                    }
                                    .buttonStyle(JournalSecondaryButtonStyle())

                                    ForEach([(35, "Unsure · 35%"), (75, "Pretty Sure · 75%"), (95, "Certain · 95%")], id: \.0) { pct, label in
                                        Button {
                                            declinedToGuess = false
                                            confidencePercent = pct
                                        } label: {
                                            Label(
                                                label,
                                                systemImage: (!declinedToGuess && confidencePercent == pct) ? "checkmark.circle.fill" : "circle"
                                            )
                                        }
                                        .buttonStyle(JournalSecondaryButtonStyle())
                                    }
                                }
                            }

                            HStack {
                                Button {
                                    evaluation = store.submitQuestionAttempt(
                                        question: question,
                                        answerText: answerText,
                                        usedAssistance: usedAssistanceInSession,
                                        highestHintRung: highestHintRung,
                                        confidencePercent: confidencePercent,
                                        declinedToGuess: declinedToGuess,
                                        thinkingTrace: thinkingTrace
                                    )
                                    graduatedFeedback = evaluation.map {
                                        SocraticFeedbackEngine.evaluate(studentAnswer: answerText, question: question, marked: $0)
                                    }
                                } label: {
                                    Label(
                                        declinedToGuess
                                            ? "Record Honest Gap (No Penalty)"
                                            : (effectiveAssisted ? "Check Guided Solution" : "Submit Independent Proof"),
                                        systemImage: "checkmark.seal.fill"
                                    )
                                }
                                .buttonStyle(BrassButtonStyle())

                                Spacer()
                            }

                            if let eval = evaluation {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    HStack {
                                        Image(systemName: eval.isPass ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                                            .foregroundStyle(eval.isPass ? Color.kymaiaSuccess : Color.kymaiaWarning)
                                        Text(eval.feedbackSummary)
                                            .font(Typography.subheadline.weight(.semibold))
                                            .foregroundStyle(Color.kymaiaInk)
                                        Spacer()
                                        JournalBadge(
                                            text: eval.diagnosticCell.badgeTitle,
                                            symbol: "gauge.with.dots.needle.67percent",
                                            tone: eval.diagnosticCell == .solidKnowledge ? .positive : .warning
                                        )
                                        if let grad = graduatedFeedback {
                                            JournalBadge(
                                                text: grad.tier.badgeTitle,
                                                symbol: "sparkles",
                                                tone: grad.tier == .correct ? .positive : .warning
                                            )
                                        }
                                    }

                                    if let grad = graduatedFeedback, !declinedToGuess {
                                        Text("\(grad.headline) — \(grad.socraticNudge)")
                                            .font(Typography.caption)
                                            .foregroundStyle(Color.kymaiaMutedInk)
                                        if let trap = grad.detectedTrap {
                                            JournalBadge(text: "Detected: \(trap)", symbol: "exclamationmark.shield", tone: .warning)
                                        }
                                    }

                                    if eval.diagnosticCell == .committedMisconception {
                                        Divider()
                                        let stf = matchingSpotTheFlaw
                                        Text("COMMITTED MISCONCEPTION REPAIR · SPOT THE FLAW IN \(stf.title.uppercased())")
                                            .font(Typography.eyebrow)
                                            .foregroundStyle(Color.kymaiaWarning)
                                        Text(stf.problemStem)
                                            .font(Typography.subheadline.weight(.semibold))
                                            .foregroundStyle(Color.kymaiaInk)
                                        ForEach(Array(stf.steps.enumerated()), id: \.offset) { idx, stepLine in
                                            Button {
                                                selectedFlawStepIndex = idx
                                                flawScoreResult = stf.score(selectedStepIndex: idx)
                                            } label: {
                                                HStack {
                                                    Text("Step \(idx + 1): \(stepLine)")
                                                        .font(Typography.caption)
                                                        .foregroundStyle(Color.kymaiaInk)
                                                    Spacer()
                                                    if selectedFlawStepIndex == idx {
                                                        Image(systemName: "hand.point.left.fill")
                                                    }
                                                }
                                            }
                                            .buttonStyle(JournalSecondaryButtonStyle())
                                        }
                                        if let flawResult = flawScoreResult {
                                            Text(flawResult.feedback)
                                                .font(Typography.caption)
                                                .foregroundStyle(flawResult.isCorrect ? Color.kymaiaSuccess : Color.kymaiaWarning)
                                        }
                                    }

                                    if !eval.matchedParts.isEmpty, !eval.missingParts.isEmpty {
                                        Text("Right so far: \(eval.matchedParts.joined(separator: ", "))")
                                            .font(Typography.caption)
                                            .foregroundStyle(Color.kymaiaSuccess)
                                    }
                                    if !eval.matchedParts.isEmpty, !eval.missingParts.isEmpty {
                                        Text("Still to get: \(eval.missingParts.joined(separator: ", "))")
                                            .font(Typography.caption)
                                            .foregroundStyle(Color.kymaiaWarning)
                                    }

                                    if eval.isPass {
                                        let prompt = ElaborativeInterrogationEngine.makePrompt(
                                            for: question.bookSection,
                                            singaporeMethodFocus: store.selectedUnit.scienceInContext
                                        )
                                        Divider()
                                        Text("ELABORATIVE INTERROGATION · \(prompt.bloomLevel.uppercased())")
                                            .font(Typography.eyebrow)
                                            .foregroundStyle(Color.kymaiaPrimary)
                                        Text(prompt.question)
                                            .font(Typography.subheadline.weight(.semibold))
                                            .foregroundStyle(Color.kymaiaInk)
                                        Text("Hint: \(prompt.invariantHint)")
                                            .font(Typography.caption)
                                            .foregroundStyle(Color.kymaiaMutedInk)
                                        TextField("Explain why this works in 1 sentence...", text: $interrogationResponse)
                                            .learnerTextInput(.retrieval)
                                            .textFieldStyle(.roundedBorder)
                                        HStack {
                                            Button("Lock Why-Explanation") {
                                                let textToSave = interrogationResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                                    ? prompt.invariantHint
                                                    : interrogationResponse
                                                store.saveCalloutResponse(
                                                    calloutId: "interrogation-\(question.id)",
                                                    chapterNumber: question.linkedChapter,
                                                    text: textToSave,
                                                    isUnlockedOverride: true
                                                )
                                                interrogationLocked = true
                                            }
                                            .buttonStyle(JournalSecondaryButtonStyle())

                                            if interrogationLocked || store.calloutResponses["interrogation-\(question.id)"]?.isUnlocked == true {
                                                JournalBadge(
                                                    text: "Why-Explanation Logged ✓",
                                                    symbol: "checkmark.circle.fill",
                                                    tone: .positive
                                                )
                                            }
                                        }
                                    }

                                    Divider()
                                    Text("CAMBRIDGE & SINGAPORE CPA MODEL SOLUTION")
                                        .font(Typography.eyebrow)
                                        .foregroundStyle(Color.kymaiaPrimary)
                                    Text(question.workedExample)
                                        .font(Typography.caption)
                                        .foregroundStyle(Color.kymaiaMutedInk)
                                }
                                .padding(Spacing.md)
                                .quietPanelBackground()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Topic \(question.topicCode) Proof Studio")
            .onAppear {
                cpaState = CPAManipulativeEngine.initialState(for: question)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
