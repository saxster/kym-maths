import SwiftUI

// MARK: - Room 5: Pólya Problem-Solving Studio, SpeedMath Fluency & Visual MathTips

struct PolyaFluencyHomeView: View {
    @Bindable var store: AppStore

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
            EditorialHeader(
                eyebrow: "Problem Solving & Fluency",
                title: "Pólya & SpeedMath",
                subtitle: "Work a problem through Pólya's four stages, then build speed with mental-maths decks and spot-the-flaw proofs."
            )

            // 1. Pólya's 4-Stage How to Solve It Studio
            JournalSection(
                title: "George Pólya's \"How to Solve It\" Studio",
                eyebrow: "4-Stage Mathematical Problem-Solving Heuristics + Singapore CPA"
            ) {
                JournalCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        let dialStages = store.seedPack.polyaStages.map(\.dialStage)
                        StageDial(stages: dialStages, selection: activeStage.dialStage) { stage in
                            store.selectedPolyaStageId = stage.id
                        }

                        HStack {
                            JournalBadge(text: "Stage \(activeStage.stageNumber) of 4", symbol: activeStage.symbol, tone: .accent)
                            Text(activeStage.subtitle)
                                .font(Typography.subheadline.weight(.semibold))
                                .foregroundStyle(Color.kymaiaMutedInk)
                        }

                        Text(activeStage.title)
                            .font(Typography.title2)
                            .foregroundStyle(Color.kymaiaInk)

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("KEY HEURISTIC QUESTIONS TO ASK YOURSELF")
                                .font(Typography.eyebrow)
                                .foregroundStyle(Color.kymaiaPrimary)
                            ForEach(activeStage.prompts, id: \.self) { prompt in
                                HStack(alignment: .top, spacing: Spacing.xs) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.kymaiaSuccess)
                                        .padding(.top, 2)
                                    Text(prompt)
                                        .font(Typography.subheadline)
                                        .foregroundStyle(Color.kymaiaInk)
                                }
                            }
                        }
                        .padding(Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .quietPanelBackground()

                        // Interactive Singapore Bar-Model Visualiser for Pólya's Train & Platform Example
                        PolyaSingaporeBarIllustrationView(stageNumber: activeStage.stageNumber)
                            .frame(height: 128)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("SINGAPORE CPA & OLYMPIAD APPLICATION")
                                .font(Typography.eyebrow)
                                .foregroundStyle(Color.kymaiaSecondary)
                            Text(activeStage.singaporeConnection)
                                .font(Typography.caption)
                                .foregroundStyle(Color.kymaiaMutedInk)
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
                                    MathsFilterChip(
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
                                .foregroundStyle(Color.kymaiaMutedInk)
                        }

                        Text(activeDeck.subtitle)
                            .font(Typography.caption)
                            .foregroundStyle(Color.kymaiaMutedInk)

                        Text(currentCard.prompt)
                            .font(Typography.largeTitle)
                            .foregroundStyle(Color.kymaiaInk)
                            .padding(Spacing.md)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .quietPanelBackground()

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
                            .buttonStyle(BrassButtonStyle())

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
                                    .foregroundStyle(Color.kymaiaInk)
                                Text("Mental Shortcut: \(currentCard.mentalTip)")
                                    .font(Typography.caption)
                                    .foregroundStyle(Color.kymaiaMutedInk)
                            }
                            .padding(Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .quietPanelBackground()
                        }
                    }
                }
            }

            // 3. Visual MathTips (8 Geometric & Algebraic Shortcuts)
            JournalSection(
                title: "Visual MathTips · See the Geometry Behind Mental Shortcuts",
                eyebrow: "8 Visual Invariants That Replace Rote Memorisation"
            ) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: Spacing.md)], spacing: Spacing.md) {
                    ForEach(store.seedPack.visualMathTips) { tip in
                        JournalCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                HStack {
                                    JournalBadge(text: tip.category, symbol: "sparkles", tone: .accent)
                                    Spacer()
                                    Button {
                                        store.selectedChapterNumber = tip.chapter
                                        store.activeRoom = .patternedWorld
                                    } label: {
                                        Label("Open Ch \(tip.chapter)", systemImage: "arrow.up.right.square")
                                            .font(Typography.caption.weight(.semibold))
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(Color.kymaiaPrimary)
                                }
                                Text(tip.title)
                                    .font(Typography.headline)
                                    .foregroundStyle(Color.kymaiaInk)

                                // Bespoke Geometric "Aha!" Diagram for each VisualMathTip
                                VisualMathTipIllustrationView(tipId: tip.id)
                                    .frame(height: 148)

                                Text(tip.visualIdea)
                                    .font(Typography.caption)
                                    .foregroundStyle(Color.kymaiaMutedInk)
                                Text(tip.algebraicIdentity)
                                    .font(Typography.numericFormula)
                                    .foregroundStyle(Color.kymaiaPrimary)
                                    .padding(Spacing.xs)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(RoundedRectangle(cornerRadius: Spacing.radiusSM).fill(Color.kymaiaSelectionFill))
                                Text("Aha! Invariant: \(tip.example)")
                                    .font(Typography.caption.weight(.semibold))
                                    .foregroundStyle(Color.kymaiaInk)
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
                                    MathsFilterChip(
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
                            .foregroundStyle(Color.kymaiaInk)

                        Text("Tap the ONE step below that contains a mathematical flaw:")
                            .font(Typography.caption)
                            .foregroundStyle(Color.kymaiaMutedInk)

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
                                        .foregroundStyle(Color.kymaiaInk)
                                    Spacer()
                                }
                                .padding(Spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: Spacing.radiusMD)
                                        .fill(isChosen ? Color.kymaiaSelectionFill : Color.kymaiaElevatedSurface)
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
                                    .foregroundStyle(Color.kymaiaInk)
                            }
                            .padding(Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .quietPanelBackground()
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

// MARK: - Pólya 4-Stage Singapore Bar-Model Visualiser (Train & Platform Invariant)

struct PolyaSingaporeBarIllustrationView: View {
    let stageNumber: Int

    private let cRed = Color(red: 0.784, green: 0.243, blue: 0.216)
    private let cBlue = Color(red: 0.180, green: 0.400, blue: 0.722)
    private let cAmber = Color(red: 0.784, green: 0.541, blue: 0.118)
    private let cGreen = Color(red: 0.118, green: 0.478, blue: 0.314)
    private let cInk = Color(red: 0.16, green: 0.14, blue: 0.20)

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let bg = CGRect(origin: .zero, size: size)
            context.fill(Path(roundedRect: bg, cornerRadius: MathsFigureRadius.frame), with: .color(MathsFigureColor.paper))
            context.stroke(Path(roundedRect: bg, cornerRadius: MathsFigureRadius.frame), with: .color(cInk.opacity(0.15)), lineWidth: 1)

            let x0 = w * 0.16
            let trainW = w * 0.26
            let platW = w * 0.42

            // Row 1: Lamp-post journey (Train length L in 9 s)
            let bar1 = CGRect(x: x0, y: h * 0.20, width: trainW, height: 28)
            context.fill(Path(roundedRect: bar1, cornerRadius: MathsFigureRadius.bar), with: .color(cRed.opacity(0.24)))
            context.stroke(Path(roundedRect: bar1, cornerRadius: MathsFigureRadius.bar), with: .color(cRed), lineWidth: 2)
            context.draw(Text("Pole (9 s)").font(MathsFigureType.label).foregroundStyle(cInk), at: CGPoint(x: w * 0.08, y: bar1.midY))
            context.draw(Text(stageNumber >= 3 ? "Train L = 180 m (9 s)" : "Train Length L (9 s)").font(MathsFigureType.labelMonoMedium).foregroundStyle(cRed), at: CGPoint(x: bar1.midX, y: bar1.midY))

            // Row 2: Platform journey (Train L + 300 m in 24 s)
            let bar2A = CGRect(x: x0, y: h * 0.58, width: trainW, height: 28)
            let bar2B = CGRect(x: x0 + trainW + 3, y: h * 0.58, width: platW, height: 28)
            context.fill(Path(roundedRect: bar2A, cornerRadius: MathsFigureRadius.bar), with: .color(cRed.opacity(0.24)))
            context.stroke(Path(roundedRect: bar2A, cornerRadius: MathsFigureRadius.bar), with: .color(cRed), lineWidth: 2)
            context.fill(Path(roundedRect: bar2B, cornerRadius: MathsFigureRadius.bar), with: .color(cBlue.opacity(0.22)))
            context.stroke(Path(roundedRect: bar2B, cornerRadius: MathsFigureRadius.bar), with: .color(cBlue), lineWidth: 2)
            context.draw(Text("Platform (24 s)").font(MathsFigureType.label).foregroundStyle(cInk), at: CGPoint(x: w * 0.08, y: bar2A.midY))
            context.draw(Text("Train L").font(MathsFigureType.labelMonoMedium).foregroundStyle(cRed), at: CGPoint(x: bar2A.midX, y: bar2A.midY))
            context.draw(Text("Platform P = 300 m").font(MathsFigureType.labelMonoMedium).foregroundStyle(cBlue), at: CGPoint(x: bar2B.midX, y: bar2B.midY))

            if stageNumber >= 2 {
                // Difference bracket over the extra 300 m
                var diff = Path()
                diff.move(to: CGPoint(x: bar2B.minX, y: bar1.maxY + 4))
                diff.addLine(to: CGPoint(x: bar2B.maxX, y: bar1.maxY + 4))
                context.stroke(diff, with: .color(cGreen), style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                let label = stageNumber == 2
                    ? "Aha! Extra 300 m takes 24 − 9 = 15 s"
                    : (stageNumber == 3 ? "v = 300 m ÷ 15 s = 20 m/s ⇒ L = 20 × 9 = 180 m" : "General Invariant: L = P · t₁ / (t₂ − t₁) = 180 m ✓")
                context.draw(Text(label).font(MathsFigureType.labelMono).foregroundStyle(cGreen), at: CGPoint(x: bar2B.midX, y: bar1.midY))
            }
        }
    }
}

// MARK: - Bespoke Geometric "Aha!" Diagrams for All 8 VisualMathTip Cards

struct VisualMathTipIllustrationView: View {
    let tipId: String

    private let cRed = Color(red: 0.784, green: 0.243, blue: 0.216)
    private let cBlue = Color(red: 0.180, green: 0.400, blue: 0.722)
    private let cAmber = Color(red: 0.784, green: 0.541, blue: 0.118)
    private let cGreen = Color(red: 0.118, green: 0.478, blue: 0.314)
    private let cInk = Color(red: 0.16, green: 0.14, blue: 0.20)

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

private extension PolyaStageSpec {
    /// Pólya's four stages as the Standard's `StageDial` draws them: the stage number as the glyph
    /// and "Stage n: title" as the spoken label.
    var dialStage: StandardStage {
        StandardStage(id: id, label: "Stage \(stageNumber): \(title)", glyph: "\(stageNumber)")
    }
}
