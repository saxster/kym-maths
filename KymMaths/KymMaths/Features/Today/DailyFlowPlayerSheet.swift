import SwiftUI

// MARK: - Today's path, step by step

/// The four steps of today's path, one at a time: remember, discover, spot the trap, prove it
/// yourself. A bar along the top shows where she is and jumps to any step.
struct DailyFlowPlayerSheet: View {
    let plan: DailyFlowSessionPlan
    @Bindable var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.standardTheme) private var theme
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var currentStage: DailyFlowStageKind
    @State private var completedStages: Set<DailyFlowStageKind>
    @State private var currentReviewCardIndex: Int = 0
    @State private var showCardBack = false
    @State private var narrator = ChapterAudioNarrator()
    @State private var selectedTermSymbol: String? = nil
    @State private var trapInput = ""
    @State private var trapEval: QuantitativeAttemptEvaluation? = nil
    /// Pinned when the sheet opens. The plan is rebuilt whenever progress changes, and a right
    /// answer moves the selector on, so reading it live would drop the card and its feedback.
    @State private var knowsWhen: EuclidKnowsWhenAttempt? = nil

    init(
        plan: DailyFlowSessionPlan,
        store: AppStore,
        startStage: DailyFlowStageKind = .fsrsMemoryLock,
        doneBefore: Set<DailyFlowStageKind> = []
    ) {
        self.plan = plan
        self.store = store
        _currentStage = State(initialValue: startStage)
        _completedStages = State(initialValue: doneBefore)
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, gutter)
                .padding(.vertical, StandardSpacing.sm)
            ScrollView {
                VStack(alignment: .leading, spacing: StandardSpacing.lg) {
                    stageHeader
                    stageBody
                    coachLine
                }
                .frame(maxWidth: 780, alignment: .leading)
                .padding(.horizontal, gutter)
                .padding(.top, StandardSpacing.xl)
                .padding(.bottom, StandardSpacing.xl3)
                .frame(maxWidth: .infinity)
            }
        }
        .background(theme.bg.ignoresSafeArea())
        #if os(macOS)
        .frame(minWidth: 760, minHeight: 640)
        #endif
        .onAppear {
            if knowsWhen == nil { knowsWhen = plan.euclidKnowsWhen.map(EuclidKnowsWhenAttempt.init(question:)) }
        }
        .onDisappear {
            narrator.stop()
        }
    }

    private var gutter: CGFloat {
        sizeClass == .compact ? StandardSpacing.md : StandardSpacing.xl
    }

    private func go(to stage: DailyFlowStageKind, completing finished: DailyFlowStageKind? = nil) {
        narrator.stop()
        if let finished { completedStages.insert(finished) }
        currentStage = stage
    }

    // MARK: Top bar

    private var topBar: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: StandardSpacing.lg) {
                closeButton
                Spacer(minLength: 0)
                stageBar
                Spacer(minLength: 0)
                minutesLeft
            }
            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                HStack {
                    closeButton
                    Spacer(minLength: StandardSpacing.sm)
                    minutesLeft
                }
                stageBar
            }
        }
    }

    private var closeButton: some View {
        Button {
            narrator.stop()
            dismiss()
        } label: {
            HStack(spacing: StandardSpacing.sm) {
                Image(systemName: "xmark")
                    .foregroundStyle(theme.mute(theme.ink))
                Text("Today's path")
                    .standardType(.uiHeadline)
                    .foregroundStyle(theme.ink)
            }
            .frame(minHeight: StandardAccessibility.touchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close today's path")
        .keyboardShortcut(.cancelAction)
    }

    private var minutesLeft: some View {
        let left = DailyFlowStageKind.allCases
            .filter { !completedStages.contains($0) }
            .reduce(0) { $0 + $1.minutes }
        return Text(left == 0 ? "All four steps done" : "About \(left) minutes left")
            .standardType(.uiBody)
            .foregroundStyle(theme.mute(theme.ink))
    }

    private var stageBar: some View {
        HStack(spacing: StandardSpacing.sm) {
            ForEach(DailyFlowStageKind.allCases) { stage in
                let isActive = currentStage == stage
                let isDone = completedStages.contains(stage)
                Button {
                    go(to: stage)
                } label: {
                    VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                        Capsule()
                            .fill(isActive ? theme.ink : isDone ? theme.patterned.provenColor : theme.patterned.sunkColor)
                            .frame(height: 3)
                        Text(stage.plainTitle)
                            .standardType(.uiBody)
                            .fontWeight(isActive ? .semibold : .regular)
                            .foregroundStyle(isActive ? theme.ink : theme.mute(theme.ink))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(minWidth: 72, maxWidth: 116, minHeight: StandardAccessibility.touchTarget, alignment: .topLeading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Step \(stage.rawValue + 1), \(stage.plainTitle)")
                .accessibilityValue(isDone ? "Done" : isActive ? "Open now" : "")
                .accessibilityAddTraits(isActive ? .isSelected : [])
            }
        }
    }

    // MARK: Step header

    private var stageHeader: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            Kicker("Step \(currentStage.rawValue + 1) of 4 · \(currentStage.plainTitle)")
            Text(stageTitle)
                .standardType(.headlineLg)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(stageIntro)
                .patternedType(.reading)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var stageTitle: String {
        switch currentStage {
        case .fsrsMemoryLock: "Bring it back before you look."
        case .conceptDiscoveryBeat: "See why it works."
        case .misconceptionImmunity: "Spot the trap."
        case .companionWorkbookProof: "Prove it yourself."
        }
    }

    private var stageIntro: String {
        switch currentStage {
        case .fsrsMemoryLock:
            plan.reviewCards.isEmpty
                ? "Nothing needs remembering today. You can go straight on."
                : "Say the answer in your head first, then check it. Each card you remember waits longer before it comes back."
        case .conceptDiscoveryBeat:
            "Chapter \(plan.chapter.number), \(plan.chapter.title). \(plan.chapter.hookSummary)"
        case .misconceptionImmunity:
            "Two friends disagree. Decide who is right and why, then try one quick sum where a wrong rule is tempting."
        case .companionWorkbookProof:
            "Workbook \(plan.proofQuestion.topicCode), \(plan.proofQuestion.tier). Work it out on your own, start to finish."
        }
    }

    // MARK: Step body

    @ViewBuilder private var stageBody: some View {
        switch currentStage {
        case .fsrsMemoryLock: rememberStage
        case .conceptDiscoveryBeat: discoverStage
        case .misconceptionImmunity: trapStage
        case .companionWorkbookProof: proveStage
        }
    }

    @ViewBuilder private var rememberStage: some View {
        if !plan.reviewCards.isEmpty {
            let safeIndex = min(max(0, currentReviewCardIndex), plan.reviewCards.count - 1)
            let card = plan.reviewCards[safeIndex]
            VStack(alignment: .leading, spacing: StandardSpacing.md) {
                Text("Card \(safeIndex + 1) of \(plan.reviewCards.count) · Topic \(card.topicCode) · Chapter \(card.chapterNumber) · holds for about \(String(format: "%.1f", card.stability)) days")
                    .standardType(.uiCaption)
                    .foregroundStyle(theme.mute(theme.ink))
                Text(card.frontPrompt)
                    .patternedType(.reading)
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                if showCardBack {
                    Text(card.backAnswer)
                        .patternedType(.readingDefault)
                        .foregroundStyle(theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(StandardSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                                .fill(theme.patterned.sunkColor)
                        )
                    Text("How did that feel?")
                        .standardType(.uiBody)
                        .foregroundStyle(theme.mute(theme.ink))
                    FlowLayout(spacing: StandardSpacing.sm) {
                        ForEach(FSRSRating.allCases, id: \.rawValue) { rating in
                            Button(rating.title) {
                                store.reviewFSRSCard(card, rating: rating)
                                showCardBack = false
                                if safeIndex + 1 < plan.reviewCards.count {
                                    currentReviewCardIndex = safeIndex + 1
                                } else {
                                    go(to: .conceptDiscoveryBeat, completing: .fsrsMemoryLock)
                                }
                            }
                            .buttonStyle(OutlineButtonStyle())
                        }
                    }
                } else {
                    primaryRow("Show the answer", systemImage: "eye") {
                        showCardBack = true
                    }
                }
            }
            .paperCard()
        } else {
            primaryRow("On to Discover") {
                go(to: .conceptDiscoveryBeat, completing: .fsrsMemoryLock)
            }
        }
    }

    private var discoverStage: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.lg) {
            ForEach(plan.discoveryBeat.bodyParagraphs, id: \.self) { paragraph in
                Text(paragraph)
                    .patternedType(.reading)
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button {
                narrator.togglePlayPause(text: plan.discoveryBeat.spokenScript, beatIndex: plan.discoveryBeat.index)
            } label: {
                Label(
                    narrator.isSpeaking ? "Stop reading" : "Read it to me",
                    systemImage: narrator.isSpeaking ? "stop.circle" : "speaker.wave.2"
                )
            }
            .buttonStyle(OutlineButtonStyle())

            IntuitionFormulaBridgeCard(
                bridge: plan.chapter.intuitionToFormula,
                selectedTermSymbol: $selectedTermSymbol
            )

            primaryRow("On to Spot the trap") {
                go(to: .misconceptionImmunity, completing: .conceptDiscoveryBeat)
            }
        }
    }

    private var trapStage: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.lg) {
            MathematicalDebateCardView(
                scenario: plan.debateScenario,
                initialSelectedChoiceId: store.calloutResponses["debate-\(plan.debateScenario.id)"]?.responseText,
                onChoiceSelected: { choice, isCorrect in
                    store.saveCalloutResponse(
                        calloutId: "debate-\(plan.debateScenario.id)",
                        chapterNumber: plan.debateScenario.chapterNumber,
                        text: choice.id,
                        confidencePercent: isCorrect ? 95 : 40,
                        isUnlockedOverride: isCorrect
                    )
                    if isCorrect {
                        completedStages.insert(.misconceptionImmunity)
                    }
                }
            )

            VStack(alignment: .leading, spacing: StandardSpacing.md) {
                Kicker("Quick check · \(plan.trapProblem.title)")
                Text(plan.trapProblem.prompt)
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(alignment: .center, spacing: StandardSpacing.sm) {
                    NumericKeypadField(
                        label: "Answer",
                        unitLabel: plan.trapProblem.unitLabel,
                        text: $trapInput
                    ) {
                        trapEval = QuantitativeMathsEngine.evaluate(problem: plan.trapProblem, numericInput: trapInput)
                    }
                    Button("Check") {
                        trapEval = QuantitativeMathsEngine.evaluate(problem: plan.trapProblem, numericInput: trapInput)
                    }
                    .buttonStyle(OutlineButtonStyle())
                }
                if let eval = trapEval {
                    Text(eval.feedback)
                        .standardType(.uiHeadline)
                        .foregroundStyle(eval.isCorrect ? theme.patterned.provenColor : theme.patterned.assistedColor)
                        .fixedSize(horizontal: false, vertical: true)
                    if let trap = eval.matchedTrap {
                        BuggyRuleTrapBanner(trap: trap)
                    }
                }
            }
            .paperCard()

            if let attempt = knowsWhen {
                EuclidKnowsWhenCard(question: attempt.question, choice: attempt.choice, isRight: attempt.isRight) { choice in
                    knowsWhen?.choose(choice, progress: &store.euclidProgress)
                }
            }

            primaryRow("On to Prove it yourself") {
                go(to: .companionWorkbookProof, completing: .misconceptionImmunity)
            }
        }
    }

    private var proveStage: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.md) {
            Text(plan.proofQuestion.prompt)
                .patternedType(.reading)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: StandardSpacing.sm) {
                    finishButton
                    Spacer(minLength: StandardSpacing.sm)
                    proveButton
                }
                VStack(alignment: .trailing, spacing: StandardSpacing.sm) {
                    proveButton
                    finishButton
                }
            }
        }
        .paperCard()
    }

    private var proveButton: some View {
        primaryButton("Prove it in the workbook", systemImage: "pencil.and.outline") {
            narrator.stop()
            completedStages.insert(.companionWorkbookProof)
            dismiss()
            store.activePracticeQuestion = plan.proofQuestion
            store.activeRoom = .schoolMaths
        }
    }

    private var finishButton: some View {
        Button("Finish for today") {
            narrator.stop()
            completedStages.insert(.companionWorkbookProof)
            dismiss()
        }
        .buttonStyle(OutlineButtonStyle())
    }

    /// The step's one filled button, at the trailing edge.
    private func primaryRow(_ title: String, systemImage: String = "arrow.right", action: @escaping () -> Void) -> some View {
        HStack {
            Spacer(minLength: 0)
            primaryButton(title, systemImage: systemImage, action: action)
        }
    }

    /// Each step shows one filled button, and every step draws it here.
    private func primaryButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: StandardSpacing.xs) {
                Text(title)
                Image(systemName: systemImage).imageScale(.small)
            }
        }
        .buttonStyle(InkButtonStyle())
    }

    private var coachLine: some View {
        Button {
            narrator.stop()
            dismiss()
            store.activeRoom = .coach
        } label: {
            Label("Stuck? Ask Coach for a hint, not the answer.", systemImage: "bubble.left")
                .standardType(.uiBody)
                .foregroundStyle(theme.mute(theme.ink))
                .frame(minHeight: StandardAccessibility.touchTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
