import SwiftUI

/// Where Euclid's Workshop is showing.
enum EuclidRoute: Hashable {
    case map
    case board(PropositionID)
    case stepOrder(PropositionID)
}

/// Room: Euclid's Workshop. Kym builds Book I with a compass and a straightedge.
struct EuclidWorkshopView: View {
    @Bindable var store: AppStore

    var body: some View {
        switch store.euclidRoute {
        case .map, .stepOrder:
            EuclidPropositionPage(store: store, id: "I.1")
        case let .board(id):
            EuclidPropositionPage(store: store, id: id)
                .id(id)
        }
    }
}

/// One proposition's page: the board, its toolbar and hint, and the proof beside it.
struct EuclidPropositionPage: View {
    @Bindable var store: AppStore
    let id: PropositionID

    @State private var session: EuclidWorkshopSession?
    @State private var lastOutcome: TapOutcome?
    @State private var recorded: ProgressOutcome?
    @State private var width: CGFloat = 0

    var body: some View {
        JournalPage(title: "", column: .calendar) {
            if let proposition = EuclidSpine.proposition(id) {
                EditorialHeader(
                    eyebrow: "Euclid's Workshop · Book I",
                    title: "\(proposition.id) · \(proposition.title)",
                    subtitle: proposition.statement
                )
            }
            if session != nil {
                content
            } else {
                JournalEmptyState(title: "Nothing to build", systemImage: "book.closed",
                                  message: "\(id) is a fact the spine accepts. School teaches it.")
            }
        }
        .onAppear { start() }
    }

    private var sessionBinding: Binding<EuclidWorkshopSession> {
        Binding(get: { session! }, set: { session = $0 })
    }

    /// Board and proof side by side need this much width; narrower, the proof goes underneath.
    private static let sideBySide: CGFloat = 520 + Spacing.md + 340

    @ViewBuilder
    private var content: some View {
        Group {
            if width >= Self.sideBySide {
                HStack(alignment: .top, spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        boardCard
                        shearCard
                    }
                    .frame(maxWidth: .infinity)
                    proofCard.frame(width: 340)
                }
            } else {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    boardCard
                    shearCard
                    proofCard
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
    }

    /// I.47's proof is easiest to see moving, once the proof itself is open.
    @ViewBuilder
    private var shearCard: some View {
        if id == "I.47", session?.hasAttempted == true {
            JournalCard {
                PythagorasShearView()
            }
        }
    }

    private var boardCard: some View {
        JournalCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                EuclidBoardToolbar(session: sessionBinding) { lastOutcome = nil }
                GeometryReader { geo in
                    EuclidBoardCanvas(session: session!) { location, tolerance in
                        lastOutcome = session?.tap(at: location, tolerance: tolerance)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                .frame(height: boardHeight)
                statusLine
                if let hint = session?.hint {
                    hintPanel(hint)
                }
                if session?.isSolved == true {
                    solvedPanel
                }
            }
        }
        .onChange(of: session?.isSolved) { _, _ in recordIfSolved() }
    }

    private var boardHeight: CGFloat {
        guard let extent = session?.extent else { return 420 }
        return BoardViewport.height(for: extent, width: 620, clampedTo: 340...560)
    }

    private var proofCard: some View {
        JournalCard {
            ProofStepsView(session: sessionBinding) { open($0) }
        }
    }

    private var statusLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
            Image(systemName: lastOutcome?.message == nil ? "hand.point.up.left" : "exclamationmark.circle")
                .foregroundStyle(lastOutcome?.message == nil ? Color.kymaiaMutedInk : Color.kymaiaWarning)
            Text(lastOutcome?.message ?? session?.prompt ?? "")
                .font(Typography.caption)
                .foregroundStyle(Color.kymaiaInk)
        }
    }

    private func hintPanel(_ hint: WorkshopHint) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            JournalBadge(text: hint.rung.badgeText, symbol: "lightbulb.fill",
                         tone: hint.rung.surrendersRetrieval ? .warning : .info)
            Text(hint.text)
                .font(Typography.body)
                .foregroundStyle(Color.kymaiaInk)
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .quietPanelBackground()
    }

    private var solvedPanel: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            JournalBadge(text: "Solved", symbol: "checkmark.seal.fill", tone: .positive)
            Text(solvedMessage)
                .font(Typography.body)
                .foregroundStyle(Color.kymaiaInk)
            HStack(spacing: Spacing.xs) {
                Button("Build it again") { start() }
                    .buttonStyle(JournalSecondaryButtonStyle())
                if session?.layer == .byrne {
                    Button("Try it in letters") { start(layer: .letters) }
                        .buttonStyle(JournalSecondaryButtonStyle())
                }
            }
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .quietPanelBackground()
    }

    private var solvedMessage: String {
        let level = session?.earnedLevel
        switch recorded {
        case let .advanced(to)?:
            return "\(to.title): lamp lit. \(nextStep(after: to))"
        case .assisted?:
            return "Solved with help (a hint from R3 up, or the proof opened early), so the lamp stays off. Build it again from a fresh board to light it."
        case .notNext?, nil:
            if let level, let highest = store.euclidProgress.highest(id), level <= highest {
                return "Solved again. That lamp is already lit."
            }
            return "Solved. Light the lamps in order: with the picture first, then in letters."
        }
    }

    private func nextStep(after level: SkillLevel) -> String {
        switch level {
        case .picture: "Next, solve it again in the Letters layer."
        case .letters: "Next, put the proof's steps in order from memory."
        case .head, .knowsWhen: ""
        }
    }

    // MARK: - Actions

    private func start(layer: BoardLayer? = nil) {
        guard let proposition = EuclidSpine.proposition(id) else { return }
        let next = store.euclidProgress.nextLevel(id)
        let layer = layer ?? (next == .picture || next == nil ? .byrne : .letters)
        session = EuclidWorkshopSession(proposition: proposition,
                                        tools: EuclidWorkshopSession.tools(for: id, progress: store.euclidProgress),
                                        layer: layer)
        lastOutcome = nil
        recorded = nil
        #if DEBUG
        EuclidDebugLaunch.prepare(&session)
        #endif
    }

    private func recordIfSolved() {
        guard recorded == nil, let session, let level = session.earnedLevel else { return }
        recorded = store.recordEuclid(level, for: id, assisted: session.isAssisted)
    }

    private func open(_ target: PropositionID) {
        store.euclidRoute = .board(target)
    }
}

#if DEBUG
/// Launch arguments for driving the workshop from a script, e.g.
/// `-KymMathsSection euclidWorkshop -EuclidOpen I.10 -EuclidReplay solved -EuclidLayer letters`.
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
        if let open = defaults.string(forKey: "EuclidOpen") {
            store.euclidRoute = .board(PropositionID(open))
        }
    }

    /// Every built proposition lit up to `level`, so its tools and later rounds show.
    private static func demo(_ level: String?) -> EuclidProgress {
        var progress = EuclidProgress()
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
