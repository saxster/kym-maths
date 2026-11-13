import SwiftUI

// MARK: - Room 1: Today (Daily Cadence, FSRS Retrieval, Intuition->Formula Spotlight & Companion Workbook)

struct TodayHomeView: View {
    @Bindable var store: AppStore
    @State private var isShowingCardBack = false
    @State private var revealedBridgeIds: Set<String> = []
    @State private var selectedFormulaTermSymbol: String? = nil

    var body: some View {
        let dailyPlan = DailyFlowSessionEngine.buildPlan(
            pack: store.seedPack,
            dueCards: store.dueFSRSCards,
            allCards: store.fsrsCards,
            selectedChapterNumber: store.selectedChapterNumber,
            selectedUnitNumber: store.selectedUnitNumber,
            proofsByQuestionId: store.proofsByQuestionId,
            euclidProgress: store.euclidProgress
        )

        JournalPage {
            EditorialHeader(
                eyebrow: "Daily Mathematics Studio · Mumbai",
                title: "Good day, \(store.learnerDisplayName)",
                subtitle: "Oxford Cambridge Lower Secondary Complete Mathematics 8 (Deborah Barton) + Singapore CPA & Horizon Atlas"
            )

            // 1. Readiness Strip & 15-Minute Daily Flow Hero Launcher
            JournalCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack(alignment: .center) {
                        JournalBadge(
                            text: "15-Minute Daily Flow Ready",
                            symbol: "flame.fill",
                            tone: .accent
                        )
                        Spacer()
                        HStack(spacing: Spacing.xs) {
                            Button {
                                store.showCalendarSheet = true
                            } label: {
                                Label("Deadlines", systemImage: "calendar")
                            }
                            .buttonStyle(JournalSecondaryButtonStyle())

                            Button {
                                store.showSettingsSheet = true
                            } label: {
                                Label("Customise", systemImage: "slider.horizontal.3")
                            }
                            .buttonStyle(JournalSecondaryButtonStyle())
                        }
                    }

                    // 4-Stage Daily Flow Ribbon
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.xs) {
                            ForEach(DailyFlowStageKind.allCases) { stage in
                                HStack(spacing: 4) {
                                    Image(systemName: stage.systemImage)
                                        .foregroundStyle(Color.kymaiaPrimary)
                                    Text(stage.title)
                                        .font(Typography.caption.weight(.semibold))
                                        .foregroundStyle(Color.kymaiaInk)
                                    Text("· \(stage.durationLabel)")
                                        .font(Typography.mono)
                                        .foregroundStyle(Color.kymaiaMutedInk)
                                }
                                .padding(.horizontal, Spacing.xs)
                                .padding(.vertical, 6)
                                .background(Color.kymaiaElevatedSurface)
                                .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusSM))
                            }
                        }
                    }

                    HStack(alignment: .center, spacing: Spacing.sm) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Today's Guided Arc: Ch \(dailyPlan.chapter.number) (\(dailyPlan.chapter.title)) + OUP Topic \(dailyPlan.proofQuestion.topicCode)")
                                .font(Typography.subheadline.weight(.semibold))
                                .foregroundStyle(Color.kymaiaInk)
                            Text("1. FSRS Memory Lock → 2. Interactive Discovery Beat → 3. Misconception Immunity Debate → 4. Companion Workbook Proof")
                                .font(Typography.caption)
                                .foregroundStyle(Color.kymaiaMutedInk)
                        }
                        Spacer()
                        Button {
                            store.showDailyFlowSheet = true
                        } label: {
                            Label("Start 15-Min Daily Flow", systemImage: "play.fill")
                        }
                        .buttonStyle(BrassButtonStyle())
                    }

                    FlowLayout(spacing: Spacing.xs) {
                        JournalBadge(
                            text: "\(store.dueFSRSCards.count) FSRS cards due",
                            symbol: "clock.arrow.circlepath",
                            tone: store.dueFSRSCards.isEmpty ? .positive : .accent
                        )
                        JournalBadge(
                            text: "\(store.overallIndependentProofCount)/\(store.seedPack.schoolQuestions.count) Companion Workbook Proofs",
                            symbol: "checkmark.seal.fill",
                            tone: .positive
                        )
                        JournalBadge(
                            text: "\(store.widgetStampsById.count)/\(store.seedPack.widgets.count) 3D Atlas Stamps",
                            symbol: "cube.transparent.fill",
                            tone: .info
                        )
                        JournalBadge(
                            text: store.selectedCurriculumLens.title,
                            symbol: "line.3.horizontal.decrease.circle",
                            tone: .neutral
                        )
                    }

                    if let deadline = store.nextSchoolDeadline {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "flag.checkered")
                                .foregroundStyle(Color.kymaiaPrimary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Upcoming Target: \(deadline.title)")
                                    .font(Typography.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.kymaiaInk)
                                Text("Chapters \(deadline.unitNumbersCSV) · \(deadline.notes)")
                                    .font(Typography.caption)
                                    .foregroundStyle(Color.kymaiaMutedInk)
                            }
                            Spacer()
                            Text(deadline.dueAt, style: .date)
                                .font(Typography.caption.weight(.semibold))
                                .foregroundStyle(Color.kymaiaPrimary)
                        }
                        .padding(Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: Spacing.radiusMD, style: .continuous)
                                .fill(Color.kymaiaSelectionFill)
                        )
                    }
                }
            }

            // 2. FSRS v5 Spaced Retrieval Queue
            JournalSection(
                title: "Spaced Retrieval Queue (FSRS v5)",
                eyebrow: "Step 1 · Lock Formulas & Invariants Into Long-Term Memory"
            ) {
                if let card = store.dueFSRSCards.first {
                    JournalCard {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            HStack {
                                JournalBadge(text: "Topic \(card.topicCode)", symbol: "number", tone: .accent)
                                JournalBadge(text: "Patterned World Ch \(card.chapterNumber)", symbol: "book.pages", tone: .neutral)
                                Spacer()
                                Text("Stability: \(String(format: "%.1f", card.stability))d")
                                    .font(Typography.caption)
                                    .foregroundStyle(Color.kymaiaMutedInk)
                            }

                            Text(card.frontPrompt)
                                .font(Typography.title3)
                                .foregroundStyle(Color.kymaiaInk)

                            if isShowingCardBack {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    Text("INVARIANT & FORMULA ANSWER")
                                        .font(Typography.eyebrow)
                                        .foregroundStyle(Color.kymaiaSuccess)
                                    Text(card.backAnswer)
                                        .font(Typography.body)
                                        .foregroundStyle(Color.kymaiaInk)
                                        .padding(Spacing.md)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .quietPanelBackground()

                                    HStack(spacing: Spacing.sm) {
                                        ForEach(FSRSRating.allCases, id: \.rawValue) { rating in
                                            Button(rating.title) {
                                                isShowingCardBack = false
                                                store.reviewFSRSCard(card, rating: rating)
                                            }
                                            .buttonStyle(JournalSecondaryButtonStyle())
                                        }
                                    }
                                }
                            } else {
                                Button {
                                    isShowingCardBack = true
                                } label: {
                                    Label("Reveal Formula & Visual Invariant", systemImage: "eye.fill")
                                }
                                .buttonStyle(JournalSecondaryButtonStyle())
                            }
                        }
                    }
                } else {
                    EmptyStateCard(
                        eyebrow: "FSRS Review",
                        title: "All FSRS Retrieval Cards Complete for Today",
                        subtitle: "Every due formula and visual invariant has been reviewed. Proceed to your Intuition → Formula Spotlight or Companion Workbook below."
                    )
                }
            }

            // 3. Visual Intuition -> "Aha!" -> Symbolic Formula Spotlight
            let ch = store.selectedChapter
            let bridge = ch.intuitionToFormula
            JournalSection(
                title: "Visual Intuition → \"Aha!\" → Symbolic Formula",
                eyebrow: "Step 2 · Why the Formula Must Be True (Ch \(ch.number): \(ch.title))"
            ) {
                JournalCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            JournalBadge(text: "Ch \(ch.number) · \(ch.volumeTitle)", symbol: "sparkles", tone: .accent)
                            JournalBadge(text: "Atlas: \(bridge.atlasFigureRef)", symbol: "cube.transparent", tone: .info)
                            Spacer()
                            Button {
                                store.activeRoom = .patternedWorld
                            } label: {
                                Label("Open Interactive 3D Chapter", systemImage: "arrow.up.right.square")
                            }
                            .buttonStyle(JournalSecondaryButtonStyle())
                        }

                        // Shared Interactive Intuition -> Formula Bridge Card
                        IntuitionFormulaBridgeCard(
                            bridge: bridge,
                            selectedTermSymbol: $selectedFormulaTermSymbol
                        )

                        // Chapter switcher strip
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.xs) {
                                ForEach(store.visiblePatternedWorldChapters) { chapter in
                                    MathsFilterChip(
                                        title: "Ch \(chapter.number): \(chapter.title)",
                                        systemImage: store.selectedChapterNumber == chapter.number ? "checkmark.circle.fill" : "function",
                                        isSelected: store.selectedChapterNumber == chapter.number
                                    ) {
                                        store.selectedChapterNumber = chapter.number
                                        selectedFormulaTermSymbol = nil
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 4. 3-Tier Companion Workbook Queue (Solving the Missing School Workbook)
            let unit = store.selectedUnit
            let unitQuestions = store.questions(forUnit: unit.unitNumber, tierFilter: store.defaultWorkbookTier)
            JournalSection(
                title: "3-Tier Companion Workbook · OUP Ch \(unit.unitNumber): \(unit.title)",
                eyebrow: "Step 3 · Worked Example → Faded Scaffold → Independent Proof"
            ) {
                JournalCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Deborah Barton pp. \(unit.learnersBookStartPage)–\(unit.learnersBookEndPage) · \(unit.statusBadgeLabel)")
                                    .font(Typography.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.kymaiaInk)
                                Text("Replaces the missing school workbook with Focus, Singapore CPA Bar-Model Practice, and Olympiad Challenge questions.")
                                    .font(Typography.caption)
                                    .foregroundStyle(Color.kymaiaMutedInk)
                            }
                            Spacer()
                            Button {
                                store.activeRoom = .schoolMaths
                            } label: {
                                Label("All 16 Chapters", systemImage: "book.closed")
                            }
                            .buttonStyle(JournalSecondaryButtonStyle())
                        }

                        ForEach(unitQuestions.prefix(4)) { question in
                            let proof = store.proofsByQuestionId[question.id]
                            HStack(alignment: .top, spacing: Spacing.md) {
                                VStack(alignment: .leading, spacing: Spacing.xxs) {
                                    HStack(spacing: Spacing.xs) {
                                        JournalBadge(text: question.tier, symbol: "layers.fill", tone: question.tier == "Challenge" ? .warning : .accent)
                                        JournalBadge(text: "Topic \(question.topicCode)", symbol: "bookmark", tone: .neutral)
                                        JournalBadge(text: (proof?.level ?? .unseen).displayTitle, symbol: "checkmark.seal", tone: (proof?.level.isIndependentProof == true) ? .positive : .neutral)
                                    }
                                    Text(question.prompt)
                                        .font(Typography.subheadline)
                                        .foregroundStyle(Color.kymaiaInk)
                                        .lineLimit(2)
                                }
                                Spacer()
                                Button("Prove") {
                                    store.activePracticeQuestion = question
                                    store.activeRoom = .schoolMaths
                                }
                                .buttonStyle(JournalSecondaryButtonStyle())
                            }
                            .padding(Spacing.sm)
                            .quietPanelBackground()
                        }
                    }
                }
            }

            // 5. Cross-Disciplinary STEM Bridges (Biology, Physics, Chemistry, Economics)
            JournalSection(
                title: "Cross-Disciplinary STEM Bridges",
                eyebrow: "How Mathematics Powers Biology, Physics, Chemistry & Mumbai Finance"
            ) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: Spacing.md)], spacing: Spacing.md) {
                    ForEach(store.seedPack.crossDisciplinaryBridges) { bridge in
                        JournalCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                HStack {
                                    JournalBadge(text: bridge.discipline.capitalized, symbol: bridge.badgeSymbol, tone: .info)
                                    Text(bridge.sourceBook)
                                        .font(Typography.caption)
                                        .foregroundStyle(Color.kymaiaMutedInk)
                                }
                                Text(bridge.title)
                                    .font(Typography.headline)
                                    .foregroundStyle(Color.kymaiaInk)
                                Text(bridge.summary)
                                    .font(Typography.caption)
                                    .foregroundStyle(Color.kymaiaMutedInk)
                                Text(bridge.keyEquation)
                                    .font(Typography.numericFormula)
                                    .foregroundStyle(Color.kymaiaPrimary)
                                    .padding(Spacing.xs)
                                    .background(
                                        RoundedRectangle(cornerRadius: Spacing.radiusSM, style: .continuous)
                                            .fill(Color.kymaiaSelectionFill)
                                    )

                                Divider()

                                Text(bridge.microCheckQuestion)
                                    .font(Typography.caption.weight(.semibold))
                                    .foregroundStyle(Color.kymaiaInk)

                                if revealedBridgeIds.contains(bridge.id) {
                                    Text(bridge.microCheckAnswer)
                                        .font(Typography.caption)
                                        .foregroundStyle(Color.kymaiaSuccess)
                                } else {
                                    Button("Check Bridge Answer") {
                                        revealedBridgeIds.insert(bridge.id)
                                    }
                                    .buttonStyle(JournalSecondaryButtonStyle())
                                }
                            }
                        }
                    }
                }
            }

            // 6. iPadOS 27 & macOS System Surface Widgets (group.com.kymaia.science)
            JournalSection(
                title: "Live System Widgets (Home Screen & Lock Screen)",
                eyebrow: "Synced via Shared App Group (group.com.kymaia.science)"
            ) {
                KymMathsWidgetPreviewGallery(store: store)
            }
        }
        .sheet(isPresented: $store.showDailyFlowSheet) {
            DailyFlowPlayerSheet(plan: dailyPlan, store: store)
        }
    }
}

// MARK: - 15-Minute Daily Flow Guided Player Sheet

struct DailyFlowPlayerSheet: View {
    let plan: DailyFlowSessionPlan
    @Bindable var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var currentStage: DailyFlowStageKind = .fsrsMemoryLock
    @State private var completedStages: Set<DailyFlowStageKind> = []
    @State private var currentReviewCardIndex: Int = 0
    @State private var showCardBack = false
    @State private var narrator = ChapterAudioNarrator()
    @State private var selectedTermSymbol: String? = nil
    @State private var trapInput = ""
    @State private var trapEval: QuantitativeAttemptEvaluation? = nil
    @State private var knowsWhenChoice: PropositionID? = nil
    @State private var knowsWhenRight = false

    var body: some View {
        NavigationStack {
            JournalPage {
                // Segmented Stage Header
                JournalCard {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            JournalBadge(text: "15-Minute Daily Flow", symbol: "flame.fill", tone: .accent)
                            Spacer()
                            Text("\(completedStages.count) / 4 Stages Completed")
                                .font(Typography.mono)
                                .foregroundStyle(Color.kymaiaMutedInk)
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.xs) {
                                ForEach(DailyFlowStageKind.allCases) { stage in
                                    let isActive = currentStage == stage
                                    let isDone = completedStages.contains(stage)
                                    Button {
                                        narrator.stop()
                                        currentStage = stage
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: isDone ? "checkmark.circle.fill" : stage.systemImage)
                                                .foregroundStyle(isDone ? Color.kymaiaSuccess : (isActive ? Color.kymaiaPrimary : Color.kymaiaMutedInk))
                                            Text(stage.title)
                                                .font(Typography.caption.weight(isActive ? .bold : .regular))
                                                .foregroundStyle(Color.kymaiaInk)
                                        }
                                        .padding(.horizontal, Spacing.xs)
                                        .padding(.vertical, 6)
                                        .background(isActive ? Color.kymaiaSelectionFill : Color.kymaiaElevatedSurface)
                                        .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusSM))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                switch currentStage {
                case .fsrsMemoryLock:
                    JournalSection(
                        title: "Stage 1 · FSRS Memory Lock (3 min)",
                        eyebrow: "Retrieve the Key Invariant Before Seeing the Answer"
                    ) {
                        if !plan.reviewCards.isEmpty {
                            let safeIndex = min(max(0, currentReviewCardIndex), plan.reviewCards.count - 1)
                            let card = plan.reviewCards[safeIndex]
                            JournalCard {
                                VStack(alignment: .leading, spacing: Spacing.md) {
                                    HStack {
                                        JournalBadge(text: "Card \(safeIndex + 1) of \(plan.reviewCards.count)", symbol: "rectangle.stack.fill", tone: .info)
                                        JournalBadge(text: "Topic \(card.topicCode)", symbol: "number", tone: .accent)
                                        JournalBadge(text: "Ch \(card.chapterNumber)", symbol: "book.pages", tone: .neutral)
                                        Spacer()
                                        Text("Stability: \(String(format: "%.1f", card.stability))d")
                                            .font(Typography.caption)
                                            .foregroundStyle(Color.kymaiaMutedInk)
                                    }

                                    Text(card.frontPrompt)
                                        .font(Typography.title3)
                                        .foregroundStyle(Color.kymaiaInk)

                                    if showCardBack {
                                        Text(card.backAnswer)
                                            .font(Typography.body)
                                            .foregroundStyle(Color.kymaiaInk)
                                            .padding(Spacing.md)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .quietPanelBackground()

                                        HStack(spacing: Spacing.sm) {
                                            ForEach(FSRSRating.allCases, id: \.rawValue) { rating in
                                                Button(rating.title) {
                                                    store.reviewFSRSCard(card, rating: rating)
                                                    showCardBack = false
                                                    if safeIndex + 1 < plan.reviewCards.count {
                                                        currentReviewCardIndex = safeIndex + 1
                                                    } else {
                                                        completedStages.insert(.fsrsMemoryLock)
                                                        currentStage = .conceptDiscoveryBeat
                                                    }
                                                }
                                                .buttonStyle(rating == .good ? AnyButtonStyle(BrassButtonStyle()) : AnyButtonStyle(JournalSecondaryButtonStyle()))
                                            }
                                        }
                                    } else {
                                        Button("Reveal Formula & Invariant") {
                                            showCardBack = true
                                        }
                                        .buttonStyle(BrassButtonStyle())
                                    }
                                }
                            }
                        } else {
                            JournalCard {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    Text("All FSRS cards are up to date!")
                                        .font(Typography.headline)
                                        .foregroundStyle(Color.kymaiaInk)
                                    Button("Advance to Stage 2: Concept Discovery Beat →") {
                                        completedStages.insert(.fsrsMemoryLock)
                                        currentStage = .conceptDiscoveryBeat
                                    }
                                    .buttonStyle(BrassButtonStyle())
                                }
                            }
                        }
                    }

                case .conceptDiscoveryBeat:
                    JournalSection(
                        title: "Stage 2 · Concept Discovery Beat (4 min)",
                        eyebrow: "Ch \(plan.chapter.number): \(plan.chapter.title)"
                    ) {
                        JournalCard {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                HStack {
                                    JournalBadge(text: plan.discoveryBeat.eyebrow, symbol: "sparkles", tone: .accent)
                                    Spacer()
                                    Button {
                                        narrator.togglePlayPause(text: plan.discoveryBeat.spokenScript, beatIndex: plan.discoveryBeat.index)
                                    } label: {
                                        Label(narrator.isSpeaking ? "Stop Audio" : "Read & Listen", systemImage: narrator.isSpeaking ? "stop.circle.fill" : "speaker.wave.2.fill")
                                    }
                                    .buttonStyle(JournalSecondaryButtonStyle())
                                }

                                Text(plan.discoveryBeat.title)
                                    .font(Typography.title3)
                                    .foregroundStyle(Color.kymaiaInk)

                                ForEach(plan.discoveryBeat.bodyParagraphs, id: \.self) { para in
                                    Text(para)
                                        .font(Typography.body)
                                        .foregroundStyle(Color.kymaiaInk)
                                }

                                IntuitionFormulaBridgeCard(
                                    bridge: plan.chapter.intuitionToFormula,
                                    selectedTermSymbol: $selectedTermSymbol
                                )

                                HStack {
                                    Spacer()
                                    Button("Advance to Stage 3: Misconception Immunity →") {
                                        narrator.stop()
                                        completedStages.insert(.conceptDiscoveryBeat)
                                        currentStage = .misconceptionImmunity
                                    }
                                    .buttonStyle(BrassButtonStyle())
                                }
                            }
                        }
                    }

                case .misconceptionImmunity:
                    JournalSection(
                        title: "Stage 3 · Misconception Immunity & Trap Check (4 min)",
                        eyebrow: "Spot the Peer Debate Flaw + Solve 1 Quantitative Trap Check"
                    ) {
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

                        JournalCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                JournalBadge(text: "Quick Quantitative Check · \(plan.trapProblem.title)", symbol: "function", tone: .info)
                                Text(plan.trapProblem.prompt)
                                    .font(Typography.body)
                                    .foregroundStyle(Color.kymaiaInk)

                                HStack(spacing: Spacing.sm) {
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
                                    .buttonStyle(JournalSecondaryButtonStyle())
                                }

                                if let eval = trapEval {
                                    Text(eval.feedback)
                                        .font(Typography.caption.weight(.semibold))
                                        .foregroundStyle(eval.isCorrect ? Color.kymaiaSuccess : Color.kymaiaWarning)
                                    if let trap = eval.matchedTrap {
                                        BuggyRuleTrapBanner(trap: trap)
                                    }
                                }

                                HStack {
                                    Spacer()
                                    Button("Advance to Stage 4: Companion Workbook Proof →") {
                                        completedStages.insert(.misconceptionImmunity)
                                        currentStage = .companionWorkbookProof
                                    }
                                    .buttonStyle(BrassButtonStyle())
                                }
                            }
                        }

                        if let question = plan.euclidKnowsWhen {
                            EuclidKnowsWhenCard(question: question, choice: knowsWhenChoice, isRight: knowsWhenRight) { choice in
                                guard knowsWhenChoice == nil else { return }
                                knowsWhenChoice = choice
                                knowsWhenRight = EuclidKnowsWhen.answer(choice, to: question, progress: &store.euclidProgress)
                            }
                        }
                    }

                case .companionWorkbookProof:
                    JournalSection(
                        title: "Stage 4 · Companion Workbook Proof (4 min)",
                        eyebrow: "OUP Ch \(plan.proofQuestion.unitNumber) · Topic \(plan.proofQuestion.topicCode) (\(plan.proofQuestion.tier))"
                    ) {
                        JournalCard {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                Text(plan.proofQuestion.prompt)
                                    .font(Typography.title3)
                                    .foregroundStyle(Color.kymaiaInk)

                                HStack {
                                    Button {
                                        completedStages.insert(.companionWorkbookProof)
                                        dismiss()
                                        store.activePracticeQuestion = plan.proofQuestion
                                        store.activeRoom = .schoolMaths
                                    } label: {
                                        Label("Launch Full CPA Proof Studio for Topic \(plan.proofQuestion.topicCode)", systemImage: "pencil.and.outline")
                                    }
                                    .buttonStyle(BrassButtonStyle())

                                    Button("Finish Daily Flow") {
                                        completedStages.insert(.companionWorkbookProof)
                                        dismiss()
                                    }
                                    .buttonStyle(JournalSecondaryButtonStyle())
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("15-Minute Daily Flow")
            .onDisappear {
                narrator.stop()
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") {
                        narrator.stop()
                        dismiss()
                    }
                }
            }
        }
    }
}

// Helper type-erased ButtonStyle for conditional primary/secondary buttons
struct AnyButtonStyle: ButtonStyle {
    private let _makeBody: (Configuration) -> AnyView

    init<S: ButtonStyle>(_ style: S) {
        _makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        _makeBody(configuration)
    }
}
