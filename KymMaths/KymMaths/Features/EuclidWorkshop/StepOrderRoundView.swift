import SwiftUI

/// The "in your head" round. The finished figure sits dimmed for reference; the proof's steps
/// come shuffled, and she puts them back in order by tapping or dragging, then picks each
/// step's reason from three.
struct StepOrderRoundView: View {
    @Bindable var store: AppStore
    let id: PropositionID

    @State private var round: StepOrderRound?
    @State private var outline: EuclidWorkshopSession?
    @State private var recorded: ProgressOutcome?
    @State private var refused: Int?
    @State private var width: CGFloat = 0

    private static let sideBySide: CGFloat = 860

    var body: some View {
        JournalPage(title: "", column: .calendar) {
            if let proposition = EuclidSpine.proposition(id) {
                EditorialHeader(
                    eyebrow: "Euclid's Workshop · In your head",
                    title: "\(proposition.id) · Put the proof in order",
                    subtitle: "The steps are shuffled. Tap the one that comes next, or drag it into the proof, then pick its reason."
                )
            }
            if round != nil, outline != nil {
                content
            } else {
                JournalEmptyState(title: "No proof to order", systemImage: "list.number",
                                  message: "\(id) has no steps to put in order.")
            }
        }
        .onAppear { start() }
    }

    private var roundBinding: Binding<StepOrderRound> { Binding(get: { round! }, set: { round = $0 }) }
    private var outlineBinding: Binding<EuclidWorkshopSession> { Binding(get: { outline! }, set: { outline = $0 }) }

    @ViewBuilder
    private var content: some View {
        Group {
            if width >= Self.sideBySide {
                HStack(alignment: .top, spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        figureCard
                        poolCard
                    }
                    .frame(width: 380)
                    proofCard.frame(maxWidth: .infinity)
                }
            } else {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    figureCard
                    proofCard
                    poolCard
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
    }

    private var figureCard: some View {
        JournalCard {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("THE FIGURE")
                    .font(Typography.eyebrow)
                    .foregroundStyle(Color.kymaiaPrimary)
                EuclidBoardCanvas(session: outline!) { _, _ in }
                    .frame(height: 260)
                    .overlay(
                        RoundedRectangle(cornerRadius: MathsFigureRadius.frame, style: .continuous)
                            .fill(MathsFigureColor.paper.opacity(0.45))
                    )
                    .allowsHitTesting(false)
                Text("Tap a picture in a step to find it here.")
                    .font(Typography.caption)
                    .foregroundStyle(Color.kymaiaMutedInk)
            }
        }
    }

    private var poolCard: some View {
        JournalCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("STEPS TO PLACE")
                    .font(Typography.eyebrow)
                    .foregroundStyle(Color.kymaiaPrimary)
                if round!.pool.isEmpty {
                    Text("All placed.")
                        .font(Typography.caption)
                        .foregroundStyle(Color.kymaiaMutedInk)
                }
                ForEach(round!.pool, id: \.self) { index in
                    ClaimLine(claim: round!.steps[index].claim, session: outlineBinding)
                        .padding(Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .quietPanelBackground()
                        .overlay(
                            RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                                .strokeBorder(Color.kymaiaWarning, lineWidth: refused == index ? 2 : 0)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { place(index) }
                        .draggable(String(index))
                        .accessibilityAddTraits(.isButton)
                        .accessibilityHint("Places this step next in the proof")
                }
            }
        }
    }

    private var proofCard: some View {
        JournalCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("YOUR PROOF")
                        .font(Typography.eyebrow)
                        .foregroundStyle(Color.kymaiaPrimary)
                    Spacer()
                    Text(round!.mistakes == 1 ? "1 slip" : "\(round!.mistakes) slips")
                        .font(Typography.caption)
                        .foregroundStyle(round!.mistakes > StepOrderRound.allowedMistakes ? Color.kymaiaWarning : Color.kymaiaMutedInk)
                }
                ForEach(Array(round!.placed.enumerated()), id: \.element) { position, index in
                    placedRow(position: position, index: index)
                }
                if !round!.isComplete {
                    dropZone
                    Button {
                        round!.revealNext()
                    } label: {
                        Label("Show me the next one", systemImage: "eye")
                    }
                    .buttonStyle(JournalSecondaryButtonStyle())
                    .help("Shows the next step and its reason. The round then counts as practice.")
                } else {
                    finished
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onChange(of: round?.isComplete) { _, _ in recordIfDone() }
    }

    private func placedRow(position: Int, index: Int) -> some View {
        let step = round!.steps[index]
        let isJustified = round!.justified.contains(index)
        return HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
            Text("\(position + 1).")
                .font(Typography.subheadline.weight(.bold))
                .foregroundStyle(Color.kymaiaMutedInk)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                ClaimLine(claim: step.claim, session: outlineBinding)
                if isJustified {
                    JustificationChip(justification: step.because) { _ in }
                } else {
                    Text("Why is this true?")
                        .font(Typography.caption.weight(.semibold))
                        .foregroundStyle(Color.kymaiaPrimary)
                    ForEach(round!.options[index], id: \.self) { reason in
                        Button {
                            round!.justify(index, with: reason)
                        } label: {
                            Text(reason.meaning)
                                .font(Typography.caption)
                                .multilineTextAlignment(.leading)
                        }
                        .buttonStyle(JournalSecondaryButtonStyle())
                    }
                }
            }
        }
        .padding(.vertical, Spacing.xxs)
    }

    private var dropZone: some View {
        Text(round!.placed.isEmpty ? "Tap or drag the first step here" : "Tap or drag the next step here")
            .font(Typography.caption)
            .foregroundStyle(Color.kymaiaMutedInk)
            .frame(maxWidth: .infinity, minHeight: 44)
            .overlay(
                RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                    .strokeBorder(Color.kymaiaMutedInk.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            )
            .dropDestination(for: String.self) { items, _ in
                guard let index = items.first.flatMap(Int.init) else { return false }
                return place(index)
            }
    }

    @ViewBuilder
    private var finished: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            switch recorded {
            case .advanced?:
                JournalBadge(text: "In your head: lamp lit", symbol: "lightbulb.fill", tone: .positive)
                Text("Next comes knowing when to use it. A word problem for it will turn up in the Daily Flow.")
            case .assisted?:
                JournalBadge(text: "Done with help", symbol: "hand.raised.fill", tone: .warning)
                Text("A step was shown, so the lamp stays off. Try a fresh shuffle without peeking.")
            default:
                if round!.mistakes > StepOrderRound.allowedMistakes {
                    JournalBadge(text: "Practice round", symbol: "arrow.clockwise", tone: .info)
                    Text("More than \(StepOrderRound.allowedMistakes) slips, so this one was practice. A fresh shuffle will count.")
                } else {
                    JournalBadge(text: "In order", symbol: "checkmark.seal.fill", tone: .positive)
                    Text("Every step is in place with its reason.")
                }
            }
            HStack(spacing: Spacing.xs) {
                Button("New shuffle") { start(seed: UInt64(Date().timeIntervalSince1970 * 1000)) }
                    .buttonStyle(JournalSecondaryButtonStyle())
                Button("Back to the map") { store.euclidRoute = .map }
                    .buttonStyle(JournalSecondaryButtonStyle())
            }
        }
        .font(Typography.body)
        .foregroundStyle(Color.kymaiaInk)
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .quietPanelBackground()
    }

    // MARK: - Actions

    @discardableResult
    private func place(_ index: Int) -> Bool {
        guard round != nil else { return false }
        let placed = round!.place(index)
        refused = placed ? nil : index
        return placed
    }

    private func start(seed: UInt64? = nil) {
        guard let proposition = EuclidSpine.proposition(id) else { return }
        var seed = seed ?? UInt64(Date().timeIntervalSince1970)
        #if DEBUG
        if let fixed = UserDefaults.standard.string(forKey: "EuclidSeed").flatMap(UInt64.init) { seed = fixed }
        #endif
        round = StepOrderRound(proposition: proposition, seed: seed)
        var figure = EuclidWorkshopSession(proposition: proposition,
                                           tools: EuclidWorkshopSession.tools(for: id, progress: store.euclidProgress),
                                           layer: .letters)
        figure?.playScript(moves: .max)
        outline = figure
        recorded = nil
        refused = nil
        #if DEBUG
        let placedCount = UserDefaults.standard.integer(forKey: "EuclidPlaced")
        for _ in 0..<placedCount {
            guard let next = round?.acceptableNext.min() else { break }
            round?.place(next)
        }
        #endif
    }

    private func recordIfDone() {
        guard recorded == nil, let round, round.isComplete else { return }
        if round.earnsHead {
            recorded = store.recordEuclid(.head, for: id, assisted: false)
        } else if round.isAssisted {
            recorded = store.recordEuclid(.head, for: id, assisted: true)
        }
    }
}
