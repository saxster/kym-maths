import SwiftUI

// MARK: - Pólya & Speed: a map for being stuck, and small shapes behind fast sums

struct PolyaFluencyHomeView: View {
    @Bindable var store: AppStore
    @Environment(\.standardTheme) private var theme

    @State private var currentCardIndex: Int = 0
    @State private var userSpeedAnswer: String = ""
    @State private var speedFeedback: SpeedFeedback?
    @State private var tipIndex: Int = 0
    @State private var askedPrompts: Set<String> = []
    @State private var stageNotes: [String: String] = [:]
    @State private var selectedFlawCardId: String = MathsSpotTheFlawCatalog.all[0].id
    @State private var selectedFlawStepIndex: Int?
    @State private var learnerFlawExplanation: String = ""
    @State private var flawScoreResult: SpotTheFlawScoreResult?
    @State private var selectedPracticeMode: PracticeDemandMode = .discrimination
    @State private var selectedPracticeItemIndex: Int = 0
    @State private var practiceUserAnswer: String = ""
    @State private var practiceRevealedInsight: String?

    var body: some View {
        let stages = store.seedPack.polyaStages
        let activeStage = stages.first(where: { $0.id == store.selectedPolyaStageId }) ?? stages[0]
        let activeDeck = store.seedPack.speedMathDecks.first(where: { $0.id == store.selectedSpeedDeckId })
            ?? store.seedPack.speedMathDecks[0]
        let currentCard = activeDeck.cards[currentCardIndex % max(1, activeDeck.cards.count)]

        JournalPage {
            EditorialHeader(
                eyebrow: "Pólya & Speed",
                title: "What do you do when you're stuck?",
                subtitle: "Pólya's four stages are a map for being stuck. Speed tricks are the same idea, small: see a shape, not a sum."
            )

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: StandardSpacing.lg) {
                    polyaCard(stages: stages, active: activeStage)
                        .frame(minWidth: 400, idealWidth: 400, maxWidth: .infinity, alignment: .leading)
                    VStack(alignment: .leading, spacing: StandardSpacing.lg) {
                        speedCard(deck: activeDeck, card: currentCard)
                        tipCard
                    }
                    .frame(width: 280)
                }
                VStack(alignment: .leading, spacing: StandardSpacing.lg) {
                    polyaCard(stages: stages, active: activeStage)
                    speedCard(deck: activeDeck, card: currentCard)
                    tipCard
                }
            }

            flawSection

            practiceSection
        }
    }

    // MARK: Pólya's four stages

    private func polyaCard(stages: [PolyaStageSpec], active: PolyaStageSpec) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.lg) {
            VStack(alignment: .leading, spacing: StandardSpacing.sm) {
                Kicker("Today's problem")
                WonderQuestion(stages[0].exampleProblem)
            }

            stageTabs(stages: stages, active: active)

            VStack(alignment: .leading, spacing: StandardSpacing.sm) {
                Kicker("Questions to ask yourself in stage \(active.stageNumber)", muted: true)
                ForEach(active.prompts, id: \.self) { prompt in
                    promptRow(prompt)
                }
            }

            PolyaSingaporeBarIllustrationView(stageNumber: active.stageNumber)
                .frame(height: active.stageNumber >= 2 ? 132 : 100)
                .accessibilityLabel("Two bars: the train alone, and the train plus the platform")

            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                Kicker("In this problem", muted: true)
                if active.stageNumber > 1 {
                    Text(active.exampleProblem)
                        .patternedType(.readingSmall)
                        .italic()
                        .foregroundStyle(theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(active.phaseBreakdown)
                    .patternedType(.readingSmall)
                    .foregroundStyle(theme.mute(theme.ink))
                    .fixedSize(horizontal: false, vertical: true)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: StandardSpacing.sm) {
                    stageNoteField(active)
                        .frame(minWidth: 180, idealWidth: 180, maxWidth: .infinity)
                    advanceButton(stages: stages, active: active).fixedSize()
                }
                VStack(alignment: .leading, spacing: StandardSpacing.sm) {
                    stageNoteField(active)
                    advanceButton(stages: stages, active: active)
                }
            }
        }
        .paperCard()
    }

    /// The four stages as a ruled row: the open stage carries the heavy rule and "You are here".
    private func stageTabs(stages: [PolyaStageSpec], active: PolyaStageSpec) -> some View {
        HStack(alignment: .top, spacing: StandardSpacing.xs) {
            ForEach(stages) { stage in
                let isActive = stage.id == active.id
                Button {
                    store.selectedPolyaStageId = stage.id
                } label: {
                    VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                        Rectangle()
                            .fill(isActive ? theme.ink : theme.hairline())
                            .frame(height: isActive ? 2 : 1)
                        Text("\(stage.stageNumber) · \(PolyaCopy.shortStage(stage.stageNumber))")
                            .standardType(.uiBody)
                            .fontWeight(isActive ? .semibold : .regular)
                            .foregroundStyle(isActive ? theme.ink : theme.mute(theme.ink))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        if isActive {
                            Text("You are here")
                                .standardType(.uiCaption)
                                .foregroundStyle(theme.mute(theme.ink))
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: StandardAccessibility.touchTarget, alignment: .topLeading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Stage \(stage.stageNumber): \(RoomCopy.droppingNumber(stage.title))")
                .accessibilityAddTraits(isActive ? .isSelected : [])
            }
        }
    }

    private func promptRow(_ prompt: String) -> some View {
        let asked = askedPrompts.contains(prompt)
        return Button {
            if asked { askedPrompts.remove(prompt) } else { askedPrompts.insert(prompt) }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.sm) {
                Image(systemName: asked ? "checkmark" : "lightbulb")
                    .foregroundStyle(asked ? theme.brass : theme.mute(theme.ink))
                Text(prompt)
                    .patternedType(.readingSmall)
                    .foregroundStyle(theme.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, StandardSpacing.md)
            .padding(.vertical, StandardSpacing.sm)
            .frame(minHeight: StandardAccessibility.touchTarget)
            .background(
                RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                    .fill(asked ? theme.blank() : theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                    .strokeBorder(asked ? Color.clear : theme.hairline(), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(asked ? "Asked" : "")
        .accessibilityHint("Marks this question as one you asked yourself")
    }

    private func stageNoteField(_ stage: PolyaStageSpec) -> some View {
        TextField(
            PolyaCopy.notePlaceholder(stage.stageNumber),
            text: Binding(
                get: { stageNotes[stage.id] ?? "" },
                set: { stageNotes[stage.id] = $0 }
            )
        )
        .learnerTextInput(.retrieval)
        .paperField()
    }

    private func advanceButton(stages: [PolyaStageSpec], active: PolyaStageSpec) -> some View {
        Button {
            let index = stages.firstIndex(where: { $0.id == active.id }) ?? 0
            store.selectedPolyaStageId = stages[(index + 1) % stages.count].id
        } label: {
            HStack(spacing: StandardSpacing.xs) {
                Text(PolyaCopy.advanceTitle(active.stageNumber))
                Image(systemName: "arrow.right").imageScale(.small)
            }
        }
        .buttonStyle(InkButtonStyle())
    }

    // MARK: Speed

    private func speedCard(deck: SpeedMathDeck, card: SpeedMathCard) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.md) {
            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                Kicker("Speed · See the shape")
                Menu {
                    ForEach(store.seedPack.speedMathDecks) { d in
                        Button(d.title) {
                            store.selectedSpeedDeckId = d.id
                            currentCardIndex = 0
                            userSpeedAnswer = ""
                            speedFeedback = nil
                        }
                    }
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.xxs) {
                        Text(deck.title)
                            .standardType(.uiBody)
                            .foregroundStyle(theme.mute(theme.ink))
                            .multilineTextAlignment(.leading)
                        Image(systemName: "chevron.down")
                            .imageScale(.small)
                            .foregroundStyle(theme.mute(theme.ink))
                    }
                    .frame(minHeight: StandardAccessibility.touchTarget, alignment: .leading)
                }
                .accessibilityLabel("Choose a deck. Now: \(deck.title)")
            }

            Text(card.prompt)
                .patternedType(.mathDisplay)
                .foregroundStyle(theme.ink)
                .minimumScaleFactor(0.6)
                .fixedSize(horizontal: false, vertical: true)
            Text("Card \((currentCardIndex % max(1, deck.cards.count)) + 1) of \(deck.cards.count)")
                .standardType(.uiCaption)
                .foregroundStyle(theme.mute(theme.ink))

            TextField("Your answer", text: $userSpeedAnswer)
                .learnerTextInput(.retrieval)
                .font(.system(.title3, design: .monospaced))
                .paperField()
                .onSubmit { checkSpeedCard(card) }

            HStack(spacing: StandardSpacing.sm) {
                Button("Check") { checkSpeedCard(card) }
                    .buttonStyle(OutlineButtonStyle())
                Button {
                    currentCardIndex = (currentCardIndex + 1) % max(1, deck.cards.count)
                    userSpeedAnswer = ""
                    speedFeedback = nil
                } label: {
                    HStack(spacing: StandardSpacing.xs) {
                        Text("Another one")
                        Image(systemName: "arrow.right").imageScale(.small)
                    }
                }
                .buttonStyle(OutlineButtonStyle())
            }

            if let feedback = speedFeedback {
                VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                    Text(feedback.isCorrect ? "Yes: \(card.answer)." : "Not this time. It's \(card.answer).")
                        .standardType(.uiHeadline)
                        .foregroundStyle(feedback.isCorrect ? theme.patterned.provenColor : theme.ink)
                    Text("= \(card.mentalTip)")
                        .patternedType(.mathInline)
                        .foregroundStyle(theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(deck.heuristic)
                        .standardType(.uiBody)
                        .foregroundStyle(theme.mute(theme.ink))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .paperCard()
    }

    private func checkSpeedCard(_ card: SpeedMathCard) {
        speedFeedback = SpeedFeedback(
            isCorrect: SpeedMathAnswerCheck.isCorrect(typed: userSpeedAnswer, expected: card.answer)
        )
    }

    // MARK: The picture behind a shortcut

    private var tipCard: some View {
        let tips = store.seedPack.visualMathTips
        let tip = tips[tipIndex % max(1, tips.count)]
        return VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            Text(tip.title)
                .standardType(.uiHeadline)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            VisualMathTipIllustrationView(tipId: tip.id)
                .frame(height: 160)

            Text(tip.visualIdea)
                .standardType(.uiBody)
                .foregroundStyle(theme.mute(theme.ink))
                .fixedSize(horizontal: false, vertical: true)
            Text(tip.algebraicIdentity)
                .patternedType(.mathInline)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(tip.example)
                .standardType(.uiBody)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: StandardSpacing.md) {
                Button("Chapter \(tip.chapter)") {
                    store.selectedChapterNumber = tip.chapter
                    store.activeRoom = .patternedWorld
                }
                .buttonStyle(TextLinkButtonStyle())
                .accessibilityLabel("Open chapter \(tip.chapter)")
                Spacer(minLength: 0)
                Button {
                    tipIndex = (tipIndex + 1) % max(1, tips.count)
                } label: {
                    Label("\(tipIndex % max(1, tips.count) + 1) of \(tips.count)", systemImage: "arrow.trianglehead.clockwise")
                        .standardType(.uiCaption)
                        .foregroundStyle(theme.mute(theme.ink))
                        .frame(minHeight: StandardAccessibility.touchTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Next picture")
            }
        }
        .paperCard()
    }

    // MARK: Spot the flaw

    private var flawSection: some View {
        let flawCard = MathsSpotTheFlawCatalog.all.first(where: { $0.id == selectedFlawCardId })
            ?? MathsSpotTheFlawCatalog.all[0]
        return VStack(alignment: .leading, spacing: StandardSpacing.md) {
            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                Kicker("Spot the flaw")
                Text("One step in each worked answer is wrong. Find it.")
                    .standardType(.headlineSm)
                    .foregroundStyle(theme.ink)
            }

            VStack(alignment: .leading, spacing: StandardSpacing.md) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: StandardSpacing.xs) {
                        ForEach(MathsSpotTheFlawCatalog.all) { card in
                            PatternedChip(card.title, isSelected: selectedFlawCardId == card.id) {
                                selectedFlawCardId = card.id
                                selectedFlawStepIndex = nil
                                learnerFlawExplanation = ""
                                flawScoreResult = nil
                            }
                        }
                    }
                }

                if let label = flawCard.misconceptionLabel {
                    HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.xs) {
                        Kicker("The trap", muted: true)
                        Text(label)
                            .standardType(.uiBody)
                            .foregroundStyle(theme.mute(theme.ink))
                    }
                }

                Text(flawCard.problemStem)
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Tap the one step that goes wrong.")
                    .standardType(.uiBody)
                    .foregroundStyle(theme.mute(theme.ink))

                ForEach(Array(flawCard.steps.enumerated()), id: \.offset) { idx, stepText in
                    let isChosen = selectedFlawStepIndex == idx
                    Button {
                        selectedFlawStepIndex = idx
                        flawScoreResult = flawCard.score(
                            selectedStepIndex: idx,
                            learnerExplanation: learnerFlawExplanation
                        )
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.sm) {
                            Text("Step \(idx + 1)")
                                .patternedType(.kicker)
                                .foregroundStyle(isChosen ? theme.ink : theme.mute(theme.ink))
                                .frame(width: 56, alignment: .leading)
                            Text(stepText)
                                .patternedType(.readingDefault)
                                .foregroundStyle(theme.ink)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                        .padding(StandardSpacing.sm)
                        .frame(minHeight: StandardAccessibility.touchTarget)
                        .background(
                            RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                                .fill(isChosen ? theme.blank() : theme.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                                .strokeBorder(isChosen ? theme.brass : theme.hairline(), lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isChosen ? .isSelected : [])
                }

                TextField("If you like: say why that step is wrong", text: $learnerFlawExplanation)
                    .learnerTextInput(.retrieval)
                    .paperField()

                if let result = flawScoreResult {
                    VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                        StatusTag(result.isCorrect ? .proven : .working, label: result.isCorrect ? "You found it" : "Keep looking")
                        Text(result.feedback)
                            .patternedType(.readingSmall)
                            .foregroundStyle(theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .paperCard()
        }
    }

    // MARK: Mixed practice

    private var practiceSection: some View {
        let allStreamItems = InterleavedPracticeStreamEngine.buildStream(
            activeTeachingChapter: store.selectedChapterNumber,
            isTeachingChapterActive: false,
            propositions: store.propositionNodes,
            chains: store.derivationChains,
            proofs: Array(store.proofsByQuestionId.values)
        )
        let modeItems = allStreamItems.filter { $0.mode == selectedPracticeMode }
        let activeItem = modeItems.isEmpty
            ? allStreamItems.first
            : modeItems[selectedPracticeItemIndex % modeItems.count]

        return VStack(alignment: .leading, spacing: StandardSpacing.md) {
            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                Kicker("Mixed practice")
                Text("Tell lookalikes apart, and chain small steps.")
                    .standardType(.headlineSm)
                    .foregroundStyle(theme.ink)
            }

            VStack(alignment: .leading, spacing: StandardSpacing.md) {
                HStack(spacing: StandardSpacing.xs) {
                    ForEach(PracticeDemandMode.allCases, id: \.rawValue) { mode in
                        PatternedChip(PolyaCopy.modeTitle(mode), isSelected: selectedPracticeMode == mode) {
                            selectedPracticeMode = mode
                            selectedPracticeItemIndex = 0
                            practiceUserAnswer = ""
                            practiceRevealedInsight = nil
                        }
                    }
                }

                Text(PolyaCopy.modeSubtitle(selectedPracticeMode))
                    .standardType(.uiBody)
                    .foregroundStyle(theme.mute(theme.ink))

                if let item = activeItem {
                    HStack(alignment: .firstTextBaseline) {
                        Text(PolyaCopy.modifierTitle(item.modifier))
                            .patternedType(.kicker)
                            .foregroundStyle(theme.mute(theme.ink))
                        Spacer(minLength: StandardSpacing.sm)
                        Button("Next prompt") {
                            selectedPracticeItemIndex += 1
                            practiceUserAnswer = ""
                            practiceRevealedInsight = nil
                        }
                        .buttonStyle(OutlineButtonStyle())
                    }

                    Text(item.title)
                        .standardType(.uiHeadline)
                        .foregroundStyle(theme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    if let twin = item.twinPair {
                        ViewThatFits(in: .horizontal) {
                            HStack(alignment: .top, spacing: StandardSpacing.md) {
                                twinBox("Twin A", twin.twinACase)
                                twinBox("Twin B", twin.twinBCase)
                            }
                            VStack(alignment: .leading, spacing: StandardSpacing.sm) {
                                twinBox("Twin A", twin.twinACase)
                                twinBox("Twin B", twin.twinBCase)
                            }
                        }

                        Text("The trap: \(twin.sharedSurfaceTrap)")
                            .patternedType(.readingSmall)
                            .foregroundStyle(theme.mute(theme.ink))
                            .fixedSize(horizontal: false, vertical: true)

                        Text("What decides it? \(twin.decidingPremiseQuestion)")
                            .patternedType(.readingDefault)
                            .foregroundStyle(theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        sunkBox(Text(item.prompt).patternedType(.readingDefault).foregroundStyle(theme.ink))
                    }

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: StandardSpacing.sm) {
                            practiceField.frame(minWidth: 220, idealWidth: 220, maxWidth: .infinity)
                            showAnswerButton(item.expectedInsight).fixedSize()
                        }
                        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
                            practiceField
                            showAnswerButton(item.expectedInsight)
                        }
                    }

                    if let insight = practiceRevealedInsight {
                        MarginNote(.history("The difference"), insight)
                    }
                }
            }
            .paperCard()
        }
    }

    private var practiceField: some View {
        TextField("Name what decides it, or chain the steps", text: $practiceUserAnswer)
            .learnerTextInput(.retrieval)
            .paperField()
    }

    private func showAnswerButton(_ insight: String) -> some View {
        Button("Show the answer") { practiceRevealedInsight = insight }
            .buttonStyle(OutlineButtonStyle())
    }

    private func twinBox(_ title: String, _ text: String) -> some View {
        sunkBox(
            VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                Kicker(title, muted: true)
                Text(text)
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        )
    }

    private func sunkBox(_ content: some View) -> some View {
        content
            .padding(StandardSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                    .fill(theme.patterned.sunkColor)
            )
    }
}

private struct SpeedFeedback: Equatable {
    let isCorrect: Bool
}

/// The room's own words for the stages, the practice modes and their modifiers.
enum PolyaCopy {
    static func shortStage(_ number: Int) -> String {
        switch number {
        case 1: "Understand"
        case 2: "Plan"
        case 3: "Carry out"
        default: "Look back"
        }
    }

    static func notePlaceholder(_ number: Int) -> String {
        switch number {
        case 1: "What I know: …"
        case 2: "My plan: …"
        case 3: "My working: …"
        default: "What I'd use again: …"
        }
    }

    static func advanceTitle(_ number: Int) -> String {
        switch number {
        case 1: "Make a plan"
        case 2: "Carry out my plan"
        case 3: "Look back"
        default: "Start again"
        }
    }

    static func modeTitle(_ mode: PracticeDemandMode) -> String {
        switch mode {
        case .recall: "Say it cold"
        case .discrimination: "Twins"
        case .composition: "Chains"
        }
    }

    static func modeSubtitle(_ mode: PracticeDemandMode) -> String {
        switch mode {
        case .recall: "Say a true fact or a move from a short cue, with nothing to look at."
        case .discrimination: "Two problems look alike, but one small fact changes which rule works."
        case .composition: "Join two or more facts where no single rule gets you there."
        }
    }

    static func modifierTitle(_ modifier: PracticeDemandModifier) -> String {
        switch modifier {
        case .forwardStandard: "From the facts to the answer"
        case .reverseConclusionToGrounds: "From the answer back to what it needs"
        case .probeWeakenedPremise: "What breaks if a fact is weakened?"
        }
    }
}

// MARK: - Pólya's four stages, drawn as two bars (the train and the platform)

struct PolyaSingaporeBarIllustrationView: View {
    let stageNumber: Int

    private let cRed = MathsFigureColor.roleColor("red")
    private let cBlue = MathsFigureColor.roleColor("blue")
    private let cGreen = MathsFigureColor.roleColor("green")
    private let cInk = MathsFigureColor.ink

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let bg = CGRect(origin: .zero, size: size)
            context.fill(Path(roundedRect: bg, cornerRadius: MathsFigureRadius.frame), with: .color(MathsFigureColor.paper))
            context.stroke(Path(roundedRect: bg, cornerRadius: MathsFigureRadius.frame), with: .color(cInk.opacity(0.15)), lineWidth: 1)

            // A fixed label column on the left, so row names never run into the bars.
            let labelX: CGFloat = 12
            let x0: CGFloat = min(112, w * 0.32)
            let room = max(80, w - x0 - 12)
            let trainW = room * 0.36
            let platW = room * 0.64 - 3
            let barH: CGFloat = 26

            func rowLabel(_ text: String, y: CGFloat) {
                context.draw(
                    Text(text).font(MathsFigureType.label).foregroundStyle(cInk),
                    at: CGPoint(x: labelX, y: y),
                    anchor: .leading
                )
            }

            // Row 1: passing a pole (the train's own length, 9 s)
            let bar1 = CGRect(x: x0, y: 14, width: trainW, height: barH)
            context.fill(Path(roundedRect: bar1, cornerRadius: MathsFigureRadius.bar), with: .color(cRed.opacity(0.24)))
            context.stroke(Path(roundedRect: bar1, cornerRadius: MathsFigureRadius.bar), with: .color(cRed), lineWidth: 2)
            rowLabel("Pole · 9 s", y: bar1.midY)
            context.draw(Text(stageNumber >= 3 ? "L = 180 m" : "Train L").font(MathsFigureType.labelMonoMedium).foregroundStyle(cRed), at: CGPoint(x: bar1.midX, y: bar1.midY))

            // Row 2: passing the platform (train plus 300 m, 24 s)
            let bar2A = CGRect(x: x0, y: 58, width: trainW, height: barH)
            let bar2B = CGRect(x: x0 + trainW + 3, y: 58, width: platW, height: barH)
            context.fill(Path(roundedRect: bar2A, cornerRadius: MathsFigureRadius.bar), with: .color(cRed.opacity(0.24)))
            context.stroke(Path(roundedRect: bar2A, cornerRadius: MathsFigureRadius.bar), with: .color(cRed), lineWidth: 2)
            context.fill(Path(roundedRect: bar2B, cornerRadius: MathsFigureRadius.bar), with: .color(cBlue.opacity(0.22)))
            context.stroke(Path(roundedRect: bar2B, cornerRadius: MathsFigureRadius.bar), with: .color(cBlue), lineWidth: 2)
            rowLabel("Platform · 24 s", y: bar2A.midY)
            context.draw(Text("Train L").font(MathsFigureType.labelMonoMedium).foregroundStyle(cRed), at: CGPoint(x: bar2A.midX, y: bar2A.midY))
            context.draw(Text("P = 300 m").font(MathsFigureType.labelMonoMedium).foregroundStyle(cBlue), at: CGPoint(x: bar2B.midX, y: bar2B.midY))

            if stageNumber >= 2 {
                // The extra 300 m, bracketed between the rows; the "aha" sits under the bars.
                var diff = Path()
                diff.move(to: CGPoint(x: bar2B.minX, y: bar1.maxY + 6))
                diff.addLine(to: CGPoint(x: bar2B.maxX, y: bar1.maxY + 6))
                context.stroke(diff, with: .color(cGreen), style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                let label = switch stageNumber {
                case 2: "The extra 300 m takes 24 − 9 = 15 s"
                case 3: "v = 300 ÷ 15 = 20 m/s, so L = 20 × 9 = 180 m"
                default: "In general: L = P · t₁ ÷ (t₂ − t₁) = 180 m ✓"
                }
                context.draw(
                    Text(label).font(MathsFigureType.labelMono).foregroundStyle(cGreen),
                    at: CGPoint(x: labelX, y: bar2A.maxY + 22),
                    anchor: .leading
                )
            }
        }
    }
}

// MARK: - Bespoke Geometric "Aha!" Diagrams for All 8 VisualMathTip Cards

struct VisualMathTipIllustrationView: View {
    let tipId: String

    private let cRed = MathsFigureColor.roleColor("red")
    private let cBlue = MathsFigureColor.roleColor("blue")
    private let cAmber = MathsFigureColor.roleColor("amber")
    private let cGreen = MathsFigureColor.roleColor("green")
    private let cInk = MathsFigureColor.ink

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let bg = CGRect(origin: .zero, size: size)
            context.fill(Path(roundedRect: bg, cornerRadius: MathsFigureRadius.frame), with: .color(MathsFigureColor.paper))
            context.stroke(Path(roundedRect: bg, cornerRadius: MathsFigureRadius.frame), with: .color(cInk.opacity(0.14)), lineWidth: 1)

            switch tipId {
            case "tip-neg-mult":
                let cy = h * 0.62, cx = w * 0.50, r = min(w * 0.32, h * 0.38)
                var axis = Path(); axis.move(to: CGPoint(x: w * 0.10, y: cy)); axis.addLine(to: CGPoint(x: w * 0.90, y: cy))
                context.stroke(axis, with: .color(cInk.opacity(0.6)), lineWidth: 2)
                var arc1 = Path()
                arc1.addArc(center: CGPoint(x: cx, y: cy), radius: r, startAngle: .degrees(0), endAngle: .degrees(-180), clockwise: true)
                context.stroke(arc1, with: .color(cRed), lineWidth: 2.5)
                var arc2 = Path()
                arc2.addArc(center: CGPoint(x: cx, y: cy), radius: r * 0.75, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
                context.stroke(arc2, with: .color(cGreen), style: StrokeStyle(lineWidth: 2.5, dash: [5, 3]))
                context.draw(Text("0").font(MathsFigureType.labelMono).foregroundStyle(cInk), at: CGPoint(x: cx, y: cy + 14))
                context.draw(Text("−1 (180° flip)").font(MathsFigureType.note).foregroundStyle(cRed), at: CGPoint(x: cx - r, y: cy + 14))
                context.draw(Text("+1 (360° = +ab)").font(MathsFigureType.note).foregroundStyle(cGreen), at: CGPoint(x: cx + r, y: cy + 14))

            case "tip-binomial-square":
                let s = min(w, h) * 0.76
                let x0 = (w - s) * 0.5, y0 = (h - s) * 0.5
                let a = s * 0.62, b = s - a
                let rAA = CGRect(x: x0, y: y0, width: a, height: a)
                let rAB1 = CGRect(x: x0 + a, y: y0, width: b, height: a)
                let rAB2 = CGRect(x: x0, y: y0 + a, width: a, height: b)
                let rBB = CGRect(x: x0 + a, y: y0 + a, width: b, height: b)
                context.fill(Path(rAA), with: .color(cRed.opacity(0.25)))
                context.fill(Path(rAB1), with: .color(cBlue.opacity(0.24)))
                context.fill(Path(rAB2), with: .color(cBlue.opacity(0.24)))
                context.fill(Path(rBB), with: .color(cAmber.opacity(0.28)))
                for r in [rAA, rAB1, rAB2, rBB] { context.stroke(Path(r), with: .color(cInk.opacity(0.75)), lineWidth: 1.6) }
                context.draw(Text("a²").font(MathsFigureType.areaTerm).foregroundStyle(cRed), at: CGPoint(x: rAA.midX, y: rAA.midY))
                context.draw(Text("ab").font(MathsFigureType.label).foregroundStyle(cBlue), at: CGPoint(x: rAB1.midX, y: rAB1.midY))
                context.draw(Text("ab").font(MathsFigureType.label).foregroundStyle(cBlue), at: CGPoint(x: rAB2.midX, y: rAB2.midY))
                context.draw(Text("b²").font(MathsFigureType.label).foregroundStyle(cAmber), at: CGPoint(x: rBB.midX, y: rBB.midY))

            case "tip-gauss-sum":
                let n = 5
                let cellW = min(w * 0.11, 26.0)
                let cellH = min(h * 0.12, 18.0)
                let x0 = (w - CGFloat(n) * cellW) * 0.5
                let yBase = h * 0.84
                for col in 0..<n {
                    let redCount = col + 1
                    let blueCount = n - col
                    for row in 0..<(n + 1) {
                        let rect = CGRect(
                            x: x0 + CGFloat(col) * cellW,
                            y: yBase - CGFloat(row + 1) * cellH,
                            width: cellW - 1.5,
                            height: cellH - 1.5
                        )
                        let isOrig = row < redCount
                        let c = isOrig ? cRed : cBlue
                        context.fill(Path(roundedRect: rect, cornerRadius: MathsFigureRadius.cell), with: .color(c.opacity(0.28)))
                        context.stroke(Path(roundedRect: rect, cornerRadius: MathsFigureRadius.cell), with: .color(c), lineWidth: 1.2)
                        let _ = blueCount
                    }
                }
                context.draw(Text("n × (n+1) rectangle").font(MathsFigureType.noteMono).foregroundStyle(cGreen), at: CGPoint(x: w * 0.5, y: h * 0.12))

            case "tip-circle-area":
                let x0 = w * 0.16, x1 = w * 0.84, y0 = h * 0.24, y1 = h * 0.76
                let n = 10
                let dx = (x1 - x0) / CGFloat(n)
                for i in 0..<n {
                    var tri = Path()
                    let xi = x0 + CGFloat(i) * dx
                    if i % 2 == 0 {
                        tri.move(to: CGPoint(x: xi, y: y1)); tri.addLine(to: CGPoint(x: xi + dx, y: y1)); tri.addLine(to: CGPoint(x: xi + dx * 0.5, y: y0))
                    } else {
                        tri.move(to: CGPoint(x: xi, y: y0)); tri.addLine(to: CGPoint(x: xi + dx, y: y0)); tri.addLine(to: CGPoint(x: xi + dx * 0.5, y: y1))
                    }
                    tri.closeSubpath()
                    context.fill(tri, with: .color((i % 2 == 0 ? cRed : cBlue).opacity(0.25)))
                    context.stroke(tri, with: .color(i % 2 == 0 ? cRed : cBlue), lineWidth: 1.4)
                }
                context.draw(Text("Base ≈ πr").font(MathsFigureType.labelMono).foregroundStyle(cBlue), at: CGPoint(x: w * 0.50, y: h * 0.88))
                context.draw(Text("r").font(MathsFigureType.labelMono).foregroundStyle(cRed), at: CGPoint(x: x0 - 12, y: (y0 + y1) * 0.5))

            case "tip-pythag-trig":
                let cx = w * 0.50, cy = h * 0.56, r = min(w, h) * 0.36
                let circleRect = CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r)
                context.stroke(Path(ellipseIn: circleRect), with: .color(cInk.opacity(0.55)), lineWidth: 1.8)
                let px = cx + r * cos(.pi / 5), py = cy - r * sin(.pi / 5)
                var cosP = Path(); cosP.move(to: CGPoint(x: cx, y: cy)); cosP.addLine(to: CGPoint(x: px, y: cy))
                var sinP = Path(); sinP.move(to: CGPoint(x: px, y: cy)); sinP.addLine(to: CGPoint(x: px, y: py))
                var hypP = Path(); hypP.move(to: CGPoint(x: cx, y: cy)); hypP.addLine(to: CGPoint(x: px, y: py))
                context.stroke(cosP, with: .color(cBlue), lineWidth: 3)
                context.stroke(sinP, with: .color(cRed), lineWidth: 3)
                context.stroke(hypP, with: .color(cGreen), lineWidth: 2.4)
                context.draw(Text("cos θ").font(MathsFigureType.note).foregroundStyle(cBlue), at: CGPoint(x: (cx + px) * 0.5, y: cy + 12))
                context.draw(Text("sin θ").font(MathsFigureType.note).foregroundStyle(cRed), at: CGPoint(x: px + 22, y: (cy + py) * 0.5))
                context.draw(Text("r = 1").font(MathsFigureType.note).foregroundStyle(cGreen), at: CGPoint(x: (cx + px) * 0.5 - 12, y: (cy + py) * 0.5 - 10))

            case "tip-bayes-square":
                let sq = CGRect(x: w * 0.16, y: h * 0.14, width: w * 0.48, height: h * 0.72)
                let splitX = sq.minX + sq.width * 0.18
                let tpR = CGRect(x: sq.minX, y: sq.minY + sq.height * 0.08, width: splitX - sq.minX, height: sq.height * 0.92)
                let fpR = CGRect(x: splitX, y: sq.minY + sq.height * 0.70, width: sq.maxX - splitX, height: sq.height * 0.30)
                context.stroke(Path(sq), with: .color(cInk.opacity(0.55)), lineWidth: 1.6)
                context.fill(Path(tpR), with: .color(cRed.opacity(0.32)))
                context.stroke(Path(tpR), with: .color(cRed), lineWidth: 1.8)
                context.fill(Path(fpR), with: .color(cAmber.opacity(0.32)))
                context.stroke(Path(fpR), with: .color(cAmber), lineWidth: 1.8)
                context.draw(Text("TP=19").font(MathsFigureType.tally).foregroundStyle(cRed), at: CGPoint(x: w * 0.78, y: h * 0.34))
                context.draw(Text("FP=49").font(MathsFigureType.tally).foregroundStyle(cAmber), at: CGPoint(x: w * 0.78, y: h * 0.62))

            case "tip-calculus-ftc":
                let x0 = w * 0.16, x1 = w * 0.72, yBase = h * 0.80, yTop = h * 0.22
                var tri = Path()
                tri.move(to: CGPoint(x: x0, y: yBase)); tri.addLine(to: CGPoint(x: x1, y: yBase)); tri.addLine(to: CGPoint(x: x1, y: yTop)); tri.closeSubpath()
                context.fill(tri, with: .color(cBlue.opacity(0.22)))
                context.stroke(tri, with: .color(cBlue), lineWidth: 2)
                let strip = CGRect(x: x0 + (x1 - x0) * 0.6, y: yBase - (yBase - yTop) * 0.6, width: 12, height: (yBase - yTop) * 0.6)
                context.fill(Path(strip), with: .color(cAmber.opacity(0.45)))
                let bar = CGRect(x: w * 0.80, y: yTop, width: 16, height: yBase - yTop)
                context.fill(Path(bar), with: .color(cRed.opacity(0.32)))
                context.stroke(Path(bar), with: .color(cRed), lineWidth: 2)
                context.draw(Text("∫ f′ dt = Δf").font(MathsFigureType.noteMono).foregroundStyle(cGreen), at: CGPoint(x: w * 0.44, y: h * 0.24))

            default: // "tip-matrix-det"
                let o = CGPoint(x: w * 0.20, y: h * 0.78)
                let v1 = CGPoint(x: w * 0.58, y: h * 0.64)
                let v2 = CGPoint(x: w * 0.34, y: h * 0.28)
                let v12 = CGPoint(x: v1.x + v2.x - o.x, y: v1.y + v2.y - o.y)
                var para = Path()
                para.move(to: o); para.addLine(to: v1); para.addLine(to: v12); para.addLine(to: v2); para.closeSubpath()
                context.fill(para, with: .color(cGreen.opacity(0.24)))
                context.stroke(para, with: .color(cGreen), lineWidth: 2)
                var a1 = Path(); a1.move(to: o); a1.addLine(to: v1)
                var a2 = Path(); a2.move(to: o); a2.addLine(to: v2)
                context.stroke(a1, with: .color(cRed), lineWidth: 2.8)
                context.stroke(a2, with: .color(cBlue), lineWidth: 2.8)
                context.draw(Text("det(A) = ad − bc").font(MathsFigureType.labelMono).foregroundStyle(cGreen), at: CGPoint(x: (o.x + v12.x) * 0.5, y: (o.y + v12.y) * 0.5))
            }
        }
    }
}
