import SwiftUI

// MARK: - Room 5: Pólya Problem-Solving Studio, SpeedMath Fluency & Visual MathTips

struct PolyaFluencyHomeView: View {
    @Bindable var store: AppStore
    @Environment(\.themeTokens) private var tokens

    @State private var currentCardIndex: Int = 0
    @State private var userSpeedAnswer: String = ""
    @State private var speedFeedback: String?
    @State private var streakCount: Int = 0
    @State private var selectedFlawCardId: String = MathsSpotTheFlawCatalog.all[0].id
    @State private var selectedFlawStepIndex: Int?
    @State private var learnerFlawExplanation: String = ""
    @State private var flawScoreResult: SpotTheFlawScoreResult?

    var body: some View {
        let activeStage = store.seedPack.polyaStages.first(where: { $0.id == store.selectedPolyaStageId })
            ?? store.seedPack.polyaStages[0]
        let activeDeck = store.seedPack.speedMathDecks.first(where: { $0.id == store.selectedSpeedDeckId })
            ?? store.seedPack.speedMathDecks[0]
        let currentCard = activeDeck.cards[currentCardIndex % max(1, activeDeck.cards.count)]

        JournalPage {
            // 1. Pólya's 4-Stage How to Solve It Studio
            JournalSection(
                title: "George Pólya's \"How to Solve It\" Studio",
                eyebrow: "4-Stage Mathematical Problem-Solving Heuristics + Singapore CPA"
            ) {
                JournalCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.xs) {
                                ForEach(store.seedPack.polyaStages) { stage in
                                    JournalChip(
                                        title: "Stage \(stage.stageNumber): \(stage.title)",
                                        systemImage: stage.symbol,
                                        isSelected: store.selectedPolyaStageId == stage.id
                                    ) {
                                        store.selectedPolyaStageId = stage.id
                                    }
                                }
                            }
                        }

                        HStack {
                            JournalBadge(text: "Stage \(activeStage.stageNumber) of 4", symbol: activeStage.symbol, tone: .accent)
                            Text(activeStage.subtitle)
                                .font(Typography.subheadline.weight(.semibold))
                                .foregroundStyle(tokens.secondary)
                        }

                        Text(activeStage.title)
                            .font(Typography.title2)
                            .foregroundStyle(tokens.primary)

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("KEY HEURISTIC QUESTIONS TO ASK YOURSELF")
                                .font(Typography.eyebrow)
                                .foregroundStyle(tokens.accent)
                            ForEach(activeStage.prompts, id: \.self) { prompt in
                                HStack(alignment: .top, spacing: Spacing.xs) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(tokens.positive)
                                        .padding(.top, 2)
                                    Text(prompt)
                                        .font(Typography.subheadline)
                                        .foregroundStyle(tokens.primary)
                                }
                            }
                        }
                        .padding(Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: Spacing.radiusMD).fill(tokens.surfaceElevated))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("SINGAPORE CPA & OLYMPIAD APPLICATION")
                                .font(Typography.eyebrow)
                                .foregroundStyle(tokens.info)
                            Text(activeStage.singaporeConnection)
                                .font(Typography.caption)
                                .foregroundStyle(tokens.secondary)
                        }
                    }
                }
            }

            // 2. SpeedMath Mental Fluency Arena
            JournalSection(
                title: "SpeedMath Mental Fluency Arena (6 Decks)",
                eyebrow: "Instant Recall of Squares, Cubes, Primes, Radians, Derivatives & Determinants"
            ) {
                JournalCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.xs) {
                                ForEach(store.seedPack.speedMathDecks) { deck in
                                    JournalChip(
                                        title: deck.title,
                                        systemImage: deck.symbol,
                                        isSelected: store.selectedSpeedDeckId == deck.id
                                    ) {
                                        store.selectedSpeedDeckId = deck.id
                                        currentCardIndex = 0
                                        userSpeedAnswer = ""
                                        speedFeedback = nil
                                    }
                                }
                            }
                        }

                        HStack {
                            JournalBadge(text: activeDeck.title, symbol: activeDeck.symbol, tone: .accent)
                            JournalBadge(text: "Target: \(activeDeck.targetSeconds)s / card", symbol: "timer", tone: .info)
                            JournalBadge(text: "Streak: \(streakCount) 🔥", symbol: "flame.fill", tone: .positive)
                            Spacer()
                            Text("Card \((currentCardIndex % activeDeck.cards.count) + 1) of \(activeDeck.cards.count)")
                                .font(Typography.caption)
                                .foregroundStyle(tokens.secondary)
                        }

                        Text(activeDeck.subtitle)
                            .font(Typography.caption)
                            .foregroundStyle(tokens.secondary)

                        Text(currentCard.prompt)
                            .font(Typography.largeTitle)
                            .foregroundStyle(tokens.primary)
                            .padding(Spacing.md)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .background(RoundedRectangle(cornerRadius: Spacing.radiusMD).fill(tokens.surfaceElevated))

                        HStack(spacing: Spacing.sm) {
                            TextField("Type mental answer...", text: $userSpeedAnswer)
                                .textFieldStyle(.roundedBorder)
                                .font(Typography.mono)
                                .onSubmit {
                                    checkSpeedCard(currentCard, deckCount: activeDeck.cards.count)
                                }

                            Button("Check") {
                                checkSpeedCard(currentCard, deckCount: activeDeck.cards.count)
                            }
                            .buttonStyle(JournalPrimaryButtonStyle())

                            Button("Next Card") {
                                currentCardIndex = (currentCardIndex + 1) % max(1, activeDeck.cards.count)
                                userSpeedAnswer = ""
                                speedFeedback = nil
                            }
                            .buttonStyle(JournalSecondaryButtonStyle())
                        }

                        if let fb = speedFeedback {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(fb)
                                    .font(Typography.subheadline.weight(.semibold))
                                    .foregroundStyle(tokens.primary)
                                Text("Mental Shortcut: \(currentCard.mentalTip)")
                                    .font(Typography.caption)
                                    .foregroundStyle(tokens.secondary)
                            }
                            .padding(Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: Spacing.radiusMD).fill(tokens.surfaceElevated))
                        }
                    }
                }
            }

            // 3. Visual MathTips (8 Geometric & Algebraic Shortcuts)
            JournalSection(
                title: "Visual MathTips · See the Geometry Behind Mental Shortcuts",
                eyebrow: "8 Visual Invariants That Replace Rote Memorisation"
            ) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: Spacing.md)], spacing: Spacing.md) {
                    ForEach(store.seedPack.visualMathTips) { tip in
                        JournalCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                HStack {
                                    JournalBadge(text: tip.category, symbol: "sparkles", tone: .accent)
                                }
                                Text(tip.title)
                                    .font(Typography.headline)
                                    .foregroundStyle(tokens.primary)
                                Text(tip.visualIdea)
                                    .font(Typography.caption)
                                    .foregroundStyle(tokens.secondary)
                                Text(tip.algebraicIdentity)
                                    .font(Typography.numericFormula)
                                    .foregroundStyle(tokens.accent)
                                    .padding(Spacing.xs)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(RoundedRectangle(cornerRadius: Spacing.radiusSM).fill(tokens.accentSubtle))
                                Text("Example: \(tip.example)")
                                    .font(Typography.caption.weight(.semibold))
                                    .foregroundStyle(tokens.primary)
                            }
                        }
                    }
                }
            }
            // 4. "Spot the Flaw" Worked-Solution Debugging Studio (Ported from ../kym_tutor)
            JournalSection(
                title: "\"Spot the Flaw\" Mathematical Debugging Studio",
                eyebrow: "Große & Renkl (2007) · Find the Single Planted Misconception Step"
            ) {
                let flawCard = MathsSpotTheFlawCatalog.all.first(where: { $0.id == selectedFlawCardId })
                    ?? MathsSpotTheFlawCatalog.all[0]

                JournalCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.xs) {
                                ForEach(MathsSpotTheFlawCatalog.all) { card in
                                    JournalChip(
                                        title: card.title,
                                        systemImage: "exclamationmark.magnifyingglass",
                                        isSelected: selectedFlawCardId == card.id
                                    ) {
                                        selectedFlawCardId = card.id
                                        selectedFlawStepIndex = nil
                                        learnerFlawExplanation = ""
                                        flawScoreResult = nil
                                    }
                                }
                            }
                        }

                        if let label = flawCard.misconceptionLabel {
                            JournalBadge(text: "Target Trap: \(label)", symbol: "shield.lefthalf.filled", tone: .warning)
                        }

                        Text(flawCard.problemStem)
                            .font(Typography.headline)
                            .foregroundStyle(tokens.primary)

                        Text("Tap the ONE step below that contains a mathematical flaw:")
                            .font(Typography.caption)
                            .foregroundStyle(tokens.secondary)

                        ForEach(Array(flawCard.steps.enumerated()), id: \.offset) { idx, stepText in
                            let isChosen = selectedFlawStepIndex == idx
                            Button {
                                selectedFlawStepIndex = idx
                                flawScoreResult = flawCard.score(
                                    selectedStepIndex: idx,
                                    learnerExplanation: learnerFlawExplanation
                                )
                            } label: {
                                HStack(alignment: .top, spacing: Spacing.sm) {
                                    JournalBadge(
                                        text: "Step \(idx + 1)",
                                        symbol: isChosen ? "checkmark.circle.fill" : "circle",
                                        tone: isChosen ? .accent : .neutral
                                    )
                                    Text(stepText)
                                        .font(Typography.subheadline)
                                        .foregroundStyle(tokens.primary)
                                    Spacer()
                                }
                                .padding(Spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: Spacing.radiusMD)
                                        .fill(isChosen ? tokens.accentSubtle : tokens.surfaceElevated)
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        TextField("Optional: In one line, explain why that step is flawed...", text: $learnerFlawExplanation)
                            .textFieldStyle(.roundedBorder)

                        if let result = flawScoreResult {
                            VStack(alignment: .leading, spacing: 4) {
                                JournalBadge(
                                    text: result.isCorrect ? "Flaw Identified!" : "Keep Looking",
                                    symbol: result.isCorrect ? "checkmark.seal.fill" : "arrow.triangle.2.circlepath",
                                    tone: result.isCorrect ? .positive : .warning
                                )
                                Text(result.feedback)
                                    .font(Typography.subheadline)
                                    .foregroundStyle(tokens.primary)
                            }
                            .padding(Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: Spacing.radiusMD).fill(tokens.surfaceElevated))
                        }
                    }
                }
            }
        }
    }

    private func checkSpeedCard(_ card: SpeedMathCard, deckCount: Int) {
        let trimmed = userSpeedAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let expected = card.answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !trimmed.isEmpty && (trimmed == expected || expected.contains(trimmed)) {
            streakCount += 1
            speedFeedback = "Correct! \(card.answer)"
        } else {
            streakCount = 0
            speedFeedback = "Expected: \(card.answer)"
        }
    }
}
