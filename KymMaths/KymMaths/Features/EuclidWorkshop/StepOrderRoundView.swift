import SwiftUI

/// The "in your head" round. The finished figure sits beside the proof for reference; the proof's
/// steps come shuffled, and she puts them back in order by tapping or dragging, then picks each
/// step's reason from three.
struct StepOrderRoundView: View {
    @Environment(\.standardTheme) private var theme
    @Bindable var store: AppStore
    let id: PropositionID

    @State private var round: StepOrderRound?
    @State private var outline: EuclidWorkshopSession?
    @State private var recorded: ProgressOutcome?
    @State private var refused: Int?
    @State private var width: CGFloat = 0

    private static let threeColumns: CGFloat = 960
    private static let twoColumns: CGFloat = 600

    var body: some View {
        EuclidPage(
            eyebrow: "Euclid's Workshop · \(id.raw) · In your head",
            title: "Put the proof in order",
            subtitle: "The steps are shuffled. Tap the one that comes next, or drag it into the proof, then pick its reason.",
            back: { store.euclidRoute = .map }
        ) {
            if round != nil, outline != nil {
                content
                footer
            } else {
                Text("\(id) has no proof steps to put in order.")
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.mute(theme.ink))
                    .paperCard()
            }
        }
        .onAppear { start() }
    }

    private var outlineBinding: Binding<EuclidWorkshopSession> { Binding(get: { outline! }, set: { outline = $0 }) }

    @ViewBuilder
    private var content: some View {
        Group {
            if width >= Self.threeColumns {
                HStack(alignment: .top, spacing: StandardSpacing.lg) {
                    figureColumn.frame(width: 250)
                    poolColumn.frame(maxWidth: .infinity)
                    proofColumn.frame(maxWidth: .infinity)
                }
            } else if width >= Self.twoColumns {
                VStack(alignment: .leading, spacing: StandardSpacing.lg) {
                    HStack(alignment: .top, spacing: StandardSpacing.lg) {
                        figureColumn.frame(width: 240)
                        poolColumn.frame(maxWidth: .infinity)
                    }
                    proofColumn
                }
            } else {
                VStack(alignment: .leading, spacing: StandardSpacing.lg) {
                    figureColumn
                    proofColumn
                    poolColumn
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .readWidth($width)
        .onChange(of: round?.isComplete) { _, _ in recordIfDone() }
    }

    // MARK: - The figure and the slips

    private var figureColumn: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            EuclidColumnLabel(title: "The figure")
            VStack(alignment: .leading, spacing: StandardSpacing.sm) {
                EuclidBoardCanvas(session: outline!, framed: false) { _, _ in }
                    .frame(height: 200)
                    .allowsHitTesting(false)
                Rectangle().fill(theme.hairline()).frame(height: 1)
                Text("Tap a pair of letters in a step to find it here.")
                    .standardType(.uiCaption)
                    .foregroundStyle(theme.mute(theme.ink))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .paperCard(padding: StandardSpacing.md)
            slipsCard
        }
    }

    private var slipsCard: some View {
        let slips = round!.mistakes
        let over = slips > StepOrderRound.allowedMistakes
        return HStack(alignment: .center, spacing: StandardSpacing.md) {
            Text("\(slips)")
                .patternedType(.numeral)
                .foregroundStyle(over ? theme.patterned.assistedColor : theme.ink)
            VStack(alignment: .leading, spacing: 2) {
                Text(slips == 1 ? "slip" : "slips")
                    .standardType(.uiHeadline)
                    .foregroundStyle(theme.ink)
                Text(over
                     ? "More than \(StepOrderRound.allowedMistakes), so this round is practice. A fresh shuffle will count."
                     : "A step that goes in too early bounces back. Slips are how you find the order.")
                    .standardType(.uiCaption)
                    .foregroundStyle(theme.mute(theme.ink))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .paperCard(padding: StandardSpacing.md)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Steps to place

    private var poolColumn: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            EuclidColumnLabel(title: "Steps to place", trailing: "\(round!.pool.count) left")
            ForEach(round!.pool, id: \.self) { index in
                HStack(alignment: .top, spacing: StandardSpacing.sm) {
                    Image(systemName: "square.grid.2x2")
                        .foregroundStyle(theme.mute(theme.ink))
                        .padding(.top, 4)
                        .accessibilityHidden(true)
                    ClaimLine(claim: round!.steps[index].claim, session: outlineBinding)
                }
                .paperCard(padding: StandardSpacing.md)
                .overlay(
                    RoundedRectangle(cornerRadius: StandardRadius.xl, style: .continuous)
                        .strokeBorder(theme.patterned.assistedColor, lineWidth: refused == index ? 1.5 : 0)
                )
                .contentShape(Rectangle())
                .onTapGesture { place(index) }
                .draggable(String(index))
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Places this step next in the proof")
            }
            if round!.pool.isEmpty {
                Text("Every step is in the proof.")
                    .patternedType(.readingSmall)
                    .foregroundStyle(theme.mute(theme.ink))
            } else {
                EuclidRuledNote(text: "A step can only use what the steps above it have already shown.")
                    .padding(.top, StandardSpacing.xs)
            }
        }
    }

    // MARK: - Your proof

    private var proofColumn: some View {
        let total = round!.steps.count
        return VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            EuclidColumnLabel(title: "Your proof", trailing: "\(round!.placed.count) of \(total) placed")
            ForEach(Array(round!.placed.enumerated()), id: \.element) { position, index in
                placedRow(position: position, index: index)
            }
            if round!.isComplete {
                finished
            } else {
                ForEach(round!.placed.count..<total, id: \.self) { position in
                    slot(position: position, isNext: position == round!.placed.count)
                }
            }
        }
    }

    private func placedRow(position: Int, index: Int) -> some View {
        let step = round!.steps[index]
        let isJustified = round!.justified.contains(index)
        return HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.sm) {
            Text("\(position + 1)")
                .patternedType(.mathInline)
                .foregroundStyle(theme.mute(theme.ink))
                .frame(minWidth: 14, alignment: .leading)
            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                ClaimLine(claim: step.claim, session: outlineBinding)
                if isJustified {
                    HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.xxs) {
                        Image(systemName: "checkmark").imageScale(.small)
                        Text(step.because.meaning)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .standardType(.uiCaption)
                    .foregroundStyle(theme.patterned.provenColor)
                } else {
                    Kicker("Why is this true?")
                        .padding(.top, StandardSpacing.xxs)
                    FlowLayout(spacing: StandardSpacing.xs) {
                        ForEach(round!.options[index], id: \.self) { reason in
                            Button(reason.meaning) {
                                round!.justify(index, with: reason)
                            }
                            .buttonStyle(EuclidChipStyle())
                        }
                    }
                }
            }
        }
        .paperCard(padding: StandardSpacing.md)
        .overlay(
            RoundedRectangle(cornerRadius: StandardRadius.xl, style: .continuous)
                .strokeBorder(theme.brass, lineWidth: isJustified ? 0 : 1)
        )
    }

    /// A place still empty. The next one takes a dropped step.
    private func slot(position: Int, isNext: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.sm) {
            Text("\(position + 1)")
                .patternedType(.mathInline)
            Text(isNext ? "Tap or drag step \(position + 1) here" : "Step \(position + 1) goes here")
                .standardType(.uiBody)
        }
        .foregroundStyle(theme.mute(theme.ink).opacity(isNext ? 1 : 0.6))
        .padding(.horizontal, StandardSpacing.md)
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: StandardRadius.xl, style: .continuous)
                .strokeBorder(isNext ? theme.faint(theme.ink) : theme.hairline(), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
        )
        .dropDestination(for: String.self) { items, _ in
            guard isNext, let index = items.first.flatMap(Int.init) else { return false }
            return place(index)
        }
    }

    @ViewBuilder
    private var finished: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            switch recorded {
            case .advanced?:
                StatusTag(.proven, label: "In your head: lamp lit")
                Text("Next comes knowing when to use it. A word problem for it will turn up in the Daily Flow.")
            case .assisted?:
                StatusTag(.withHelp, label: "Done with help")
                Text("A step was shown, so the lamp stays off. Try a fresh shuffle without peeking.")
            default:
                if round!.mistakes > StepOrderRound.allowedMistakes {
                    StatusTag(.working, label: "Practice round")
                    Text("More than \(StepOrderRound.allowedMistakes) slips, so this one was practice. A fresh shuffle will count.")
                } else {
                    StatusTag(.proven, label: "In order")
                    Text("Every step is in place with its reason.")
                }
            }
            Button("Back to the map") { store.euclidRoute = .map }
                .buttonStyle(TextLinkButtonStyle())
        }
        .patternedType(.readingDefault)
        .foregroundStyle(theme.ink)
        .fixedSize(horizontal: false, vertical: true)
        .paperCard(padding: StandardSpacing.md)
    }

    // MARK: - Footer

    private var footer: some View {
        let record = store.euclidProgress.record(for: id)
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: StandardSpacing.md) {
                lamps(record)
                Spacer(minLength: StandardSpacing.md)
                footerActions
            }
            VStack(alignment: .leading, spacing: StandardSpacing.sm) {
                lamps(record)
                HStack(spacing: StandardSpacing.md) { footerActions }
            }
        }
        .padding(.top, StandardSpacing.sm)
    }

    private func lamps(_ record: EuclidSkillRecord) -> some View {
        HStack(spacing: StandardSpacing.sm) {
            SkillLamps(lit: record.litLamps)
            Text(record.highest.map { $0 >= .head } == true
                 ? "“\(SkillLevel.head.lampName)” is lit"
                 : "Order it right to light “\(SkillLevel.head.lampName)”")
                .standardType(.uiCaption)
                .foregroundStyle(theme.mute(theme.ink))
        }
    }

    @ViewBuilder
    private var footerActions: some View {
        if !round!.isComplete, !round!.pool.isEmpty || round!.placed.contains(where: { !round!.justified.contains($0) }) {
            Button("Show me the next one") { round!.revealNext() }
                .buttonStyle(TextLinkButtonStyle(arrow: false))
                .help("Shows the next step and its reason. The round then counts as practice.")
        }
        Button("New shuffle") { start(seed: UInt64(Date().timeIntervalSince1970 * 1000)) }
            .buttonStyle(OutlineButtonStyle())
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
        // `-EuclidPlaced n` places the first n steps, and `-EuclidJustified n` gives the first n their reasons.
        let defaults = UserDefaults.standard
        for _ in 0..<defaults.integer(forKey: "EuclidPlaced") {
            guard let next = round?.acceptableNext.min() else { break }
            round?.place(next)
        }
        for index in (round?.placed ?? []).prefix(defaults.integer(forKey: "EuclidJustified")) {
            round?.justify(index, with: round!.steps[index].because)
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
