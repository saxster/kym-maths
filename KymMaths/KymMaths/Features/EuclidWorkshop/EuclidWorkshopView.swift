import SwiftUI

/// Where Euclid's Workshop is showing.
enum EuclidRoute: Hashable {
    case map
    case board(PropositionID)
    case stepOrder(PropositionID)
    case motif(MotifID)
}

/// Room: Euclid's Workshop. Kym builds Book I with a compass and a straightedge.
struct EuclidWorkshopView: View {
    @Bindable var store: AppStore

    var body: some View {
        switch store.euclidRoute {
        case .map:
            EuclidSpineMapView(store: store)
        case let .board(id):
            EuclidPropositionPage(store: store, id: id)
                .id(id)
        case let .stepOrder(id):
            StepOrderRoundView(store: store, id: id)
                .id("order-\(id)")
        case let .motif(id):
            MotifPageView(store: store, id: id)
                .id("motif-\(id)")
        }
    }
}

/// One proposition's page: the tool rail, the board with its step and hint, and the proof beside it.
struct EuclidPropositionPage: View {
    @Environment(\.standardTheme) private var theme
    @Bindable var store: AppStore
    let id: PropositionID

    @State private var session: EuclidWorkshopSession?
    @State private var recorded: ProgressOutcome?
    @State private var width: CGFloat = 0

    var body: some View {
        let proposition = EuclidSpine.proposition(id)
        EuclidPage(
            eyebrow: "Euclid's Workshop · \(id.raw)",
            title: proposition?.title ?? id.raw,
            subtitle: proposition?.statement ?? "",
            back: { store.euclidRoute = .map }
        ) {
            if session != nil {
                content
                if let proposition { chain(proposition) }
            } else {
                Text("\(id) is a fact the book leans on, and school teaches it. There is nothing to build here.")
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.mute(theme.ink))
                    .paperCard()
            }
        }
        .onAppear { start() }
    }

    private var sessionBinding: Binding<EuclidWorkshopSession> {
        Binding(get: { session! }, set: { session = $0 })
    }

    /// Rail, board and proof side by side need this much width; narrower, the proof goes under
    /// the board, and narrower still the rail becomes a row above it.
    private static let threeColumns: CGFloat = 84 + 480 + 300 + 2 * StandardSpacing.md
    private static let railAndBoard: CGFloat = 84 + 420 + StandardSpacing.md

    @ViewBuilder
    private var content: some View {
        Group {
            if width >= Self.threeColumns {
                HStack(alignment: .top, spacing: StandardSpacing.md) {
                    EuclidBoardToolbar(session: sessionBinding, axis: .rail)
                    boardCard.frame(maxHeight: .infinity, alignment: .top)
                    proofCard.frame(width: 300).frame(maxHeight: .infinity, alignment: .top)
                }
                .fixedSize(horizontal: false, vertical: true)
            } else if width >= Self.railAndBoard {
                VStack(alignment: .leading, spacing: StandardSpacing.md) {
                    HStack(alignment: .top, spacing: StandardSpacing.md) {
                        EuclidBoardToolbar(session: sessionBinding, axis: .rail)
                        boardCard.frame(maxHeight: .infinity, alignment: .top)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    proofCard
                }
            } else {
                VStack(alignment: .leading, spacing: StandardSpacing.md) {
                    EuclidBoardToolbar(session: sessionBinding, axis: .row)
                    boardCard
                    proofCard
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        shearCard
    }

    /// I.47's proof is easiest to see moving, once the proof itself is open.
    @ViewBuilder
    private var shearCard: some View {
        if id == "I.47", session?.hasAttempted == true {
            PythagorasShearView()
                .paperCard()
        }
    }

    // MARK: - The board

    private var boardCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepHeader
                .padding(.horizontal, StandardSpacing.lg)
                .padding(.vertical, StandardSpacing.md)
            Rectangle().fill(theme.hairline()).frame(height: 1)
            if let hint = session?.hint {
                hintLine(hint)
                    .padding(.horizontal, StandardSpacing.lg)
                    .padding(.top, StandardSpacing.md)
            }
            GeometryReader { geo in
                EuclidBoardCanvas(session: session!, framed: false) { location, tolerance in
                    session?.tap(at: location, tolerance: tolerance)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(height: boardHeight)
            Rectangle().fill(theme.hairline()).frame(height: 1)
            VStack(alignment: .leading, spacing: StandardSpacing.md) {
                if session?.isSolved == true {
                    solvedPanel
                } else if let status = session?.status, status.text != session?.prompt {
                    EuclidFeedbackLine(tone: tone(status.kind), text: status.text)
                } else {
                    EuclidFeedbackLine(tone: .info, text: "Each move stays on the board. Undo takes back the last one.")
                }
            }
            .padding(.horizontal, StandardSpacing.lg)
            .padding(.vertical, StandardSpacing.md)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: StandardRadius.xl, style: .continuous).fill(theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: StandardRadius.xl, style: .continuous)
                .strokeBorder(theme.hairline(), lineWidth: 1)
        )
        .onChange(of: session?.isSolved) { _, _ in recordIfSolved() }
    }

    /// "STEP 2 OF 4", what the tool in hand waits for, and a dot per step.
    private var stepHeader: some View {
        let step = session?.scriptStep
        return HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.sm) {
            if session?.isSolved == true {
                Kicker("Built")
                Text("Every step is on the board.")
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.ink)
            } else {
                if let step { Kicker("Step \(step.current) of \(step.total)") }
                Text(session?.prompt ?? "")
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: StandardSpacing.xs)
            if let total = step?.total ?? session.map({ $0.script.steps.count }), total > 1, total <= 12 {
                let done = session?.isSolved == true ? total : (step?.current ?? 1) - 1
                HStack(spacing: 5) {
                    ForEach(0..<total, id: \.self) { index in
                        Circle()
                            .fill(index < done ? theme.brass : theme.faint(theme.ink).opacity(0.5))
                            .frame(width: 7, height: 7)
                    }
                }
                .accessibilityElement()
                .accessibilityLabel("\(done) of \(total) steps on the board")
            }
        }
    }

    private func hintLine(_ hint: WorkshopHint) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
            Kicker(hint.rung.plainTitle, muted: !hint.rung.surrendersRetrieval)
            HandNote(hint.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var boardHeight: CGFloat {
        guard let extent = session?.extent else { return 420 }
        return BoardViewport.height(for: extent, width: 600, clampedTo: 400...600)
    }

    private func tone(_ kind: BoardStatus.Kind) -> EuclidFeedbackLine.Tone {
        switch kind {
        case .info: .info
        case .refusal: .refusal
        case .success: .success
        }
    }

    private var solvedPanel: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            if recorded == .assisted {
                StatusTag(.withHelp, label: "Built with help")
            } else {
                StatusTag(.proven, label: "Built")
            }
            Text(solvedMessage)
                .patternedType(.readingDefault)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            FlowLayout(spacing: StandardSpacing.xs) {
                if let highest = store.euclidProgress.highest(id), highest >= .letters {
                    Button("Put the steps in order") { store.euclidRoute = .stepOrder(id) }
                        .buttonStyle(OutlineButtonStyle())
                }
                if session?.layer == .byrne {
                    Button("Try it in letters") { start(layer: .letters) }
                        .buttonStyle(OutlineButtonStyle())
                }
                Button("Build it again") { start() }
                    .buttonStyle(OutlineButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var solvedMessage: String {
        let level = session?.earnedLevel
        switch recorded {
        case let .advanced(to)?:
            return "\(to.lampName): lamp lit. \(nextStep(after: to))"
        case .assisted?:
            return "Built with help (a big hint, or the proof opened early), so the lamp stays off. Build it again from a fresh board to light it."
        case .notNext?, nil:
            if let level, let highest = store.euclidProgress.highest(id), level <= highest {
                return "Built again. That lamp is already lit."
            }
            return "Built. Light the lamps in order: with the picture first, then in letters."
        }
    }

    private func nextStep(after level: SkillLevel) -> String {
        switch level {
        case .picture: "Next, build it again with letters."
        case .letters: "Next, put the proof's steps in order from memory."
        case .head, .knowsWhen: ""
        }
    }

    // MARK: - The proof and the chain

    private var proofCard: some View {
        ProofStepsView(session: sessionBinding, record: store.euclidProgress.record(for: id)) { open($0) }
            .paperCard()
    }

    private func chain(_ proposition: EuclidProposition) -> some View {
        ChainCard(
            standsOn: proposition.uses.map(link),
            unlocks: proposition.unlocks.map(link)
        ) { link in
            open(PropositionID(link.code))
        }
    }

    private func link(_ id: PropositionID) -> ChainLink {
        ChainLink(code: id.raw, title: EuclidSpine.proposition(id)?.title ?? "")
    }

    // MARK: - Actions

    private func start(layer: BoardLayer? = nil) {
        guard let proposition = EuclidSpine.proposition(id) else { return }
        let next = store.euclidProgress.nextLevel(id)
        let layer = layer ?? (next == .picture || next == nil ? .byrne : .letters)
        session = EuclidWorkshopSession(proposition: proposition,
                                        tools: EuclidWorkshopSession.tools(for: id, progress: store.euclidProgress),
                                        layer: layer)
        recorded = nil
        #if DEBUG
        EuclidDebugLaunch.prepare(&session)
        recordIfSolved()
        #endif
    }

    private func recordIfSolved() {
        guard recorded == nil, let session, let level = session.earnedLevel else { return }
        recorded = store.recordEuclid(level, for: id, assisted: session.isAssisted)
    }

    /// A built proposition opens its board; a school fact, or one still locked, shows on the map.
    private func open(_ target: PropositionID) {
        if EuclidSpine.proposition(target)?.isAccepted == true {
            store.euclidMapSelection = target
            store.euclidRoute = .map
        } else {
            store.openEuclid(.board(target))
        }
    }
}

#if DEBUG
/// Launch arguments for driving the workshop from a script, e.g.
/// `-KymMathsSection euclidWorkshop -EuclidOpen I.10 -EuclidReplay solved -EuclidLayer letters`.
/// Also `-EuclidProgress picture|letters|head`, `-EuclidHints n`, `-EuclidShearT 0.4`,
/// `-EuclidSelect I.10` (map), and `-EuclidSeed n -EuclidPlaced n` (step-order round).
/// A motif page opens with `-EuclidOpen motif:M1`, and takes `-MotifLight n` (light question phrase n),
/// `-MotifAnswer 75`, `-MotifHelper YES`, `-MotifBroken YES` and `-MotifDrag x,y` (the free point pulled to a board point).
enum EuclidDebugLaunch {
    private static var defaults: UserDefaults { .standard }

    @MainActor
    static func apply(to store: AppStore) {
        let driven = ["EuclidOpen", "EuclidReplay", "EuclidProgress"].contains { defaults.string(forKey: $0) != nil }
        if driven {
            store.useEphemeralEuclidProgress(demo(defaults.string(forKey: "EuclidProgress")))
        }
        if let room = defaults.string(forKey: "KymMathsSection").flatMap(AppRoom.init(rawValue:)) {
            store.activeRoom = room
        }
        // "map", "I.10", "order:I.10" or "motif:M1".
        if let open = defaults.string(forKey: "EuclidOpen") {
            store.euclidRoute = switch open {
            case "map": .map
            case let order where order.hasPrefix("order:"): .stepOrder(PropositionID(String(order.dropFirst(6))))
            case let motif where motif.hasPrefix("motif:"): .motif(MotifID(String(motif.dropFirst(6))))
            default: .board(PropositionID(open))
            }
        }
    }

    /// Every built proposition lit up to `level`, so its tools and later rounds show. "start" lights
    /// only I.1, up to "In your head", the way the map looks a week in.
    private static func demo(_ level: String?) -> EuclidProgress {
        var progress = EuclidProgress()
        if level == "start" {
            for level in SkillLevel.allCases where level <= .head {
                progress.record(level, for: "I.1", assisted: false)
            }
            return progress
        }
        let top: SkillLevel? = switch level {
        case "picture": .picture
        case "letters": .letters
        case "head": .head
        default: nil
        }
        guard let top else { return progress }
        for proposition in EuclidSpine.catalog {
            guard case .built = proposition.kind else { continue }
            for level in SkillLevel.allCases where level <= top {
                progress.record(level, for: proposition.id, assisted: false)
            }
        }
        return progress
    }

    static func prepare(_ session: inout EuclidWorkshopSession?) {
        guard var s = session else { return }
        if let layer = defaults.string(forKey: "EuclidLayer").flatMap(BoardLayer.init(rawValue:)) {
            s.layer = layer
        }
        switch defaults.string(forKey: "EuclidReplay") {
        case "solved": s.playScript(moves: .max)
        case "partial": s.playScript(moves: s.script.steps.flatMap(\.moves).count / 2)
        default: break
        }
        for _ in 0..<defaults.integer(forKey: "EuclidHints") { s.requestHint() }
        session = s
    }
}
#endif
