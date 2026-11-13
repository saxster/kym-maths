import Foundation

/// How the board names its parts: Byrne's colours, or the school's letters drawn in ink.
enum BoardLayer: String, Hashable, CaseIterable {
    case byrne
    case letters
}

enum WorkshopTool: Hashable {
    case compass
    case straightedge
    case proposition(PropositionID)
}

/// The tool in hand and what it is waiting for.
enum ToolState: Hashable {
    enum Compass: Hashable {
        case awaitingCentre
        case awaitingRadius(PointID)
    }

    enum Straightedge: Hashable {
        case awaitingStart
        case awaitingEnd(PointID)
    }

    case compass(Compass)
    case straightedge(Straightedge)
    /// A proven proposition, collecting its given points in order.
    case proposition(PropositionID, collected: [PointID])

    init(_ tool: WorkshopTool) {
        switch tool {
        case .compass: self = .compass(.awaitingCentre)
        case .straightedge: self = .straightedge(.awaitingStart)
        case let .proposition(id): self = .proposition(id, collected: [])
        }
    }

    var tool: WorkshopTool {
        switch self {
        case .compass: .compass
        case .straightedge: .straightedge
        case let .proposition(id, _): .proposition(id)
        }
    }

    /// Points the tool holds, in the order she picked them.
    var held: [PointID] {
        switch self {
        case let .compass(.awaitingRadius(p)), let .straightedge(.awaitingEnd(p)): [p]
        case let .proposition(_, collected): collected
        default: []
        }
    }
}

enum TapRefusal: Error, Equatable {
    /// Euclid's rule: no point, no crossing within reach.
    case emptyPaper
    case alreadyOnBoard
    case alreadyPicked
    case failed(BoardError)
}

enum TapOutcome: Equatable {
    /// The tool holds this point and waits for the next.
    case picked(PointID)
    /// She tapped the held point again, so the tool let go of it.
    case released(PointID)
    case drew(CurveID)
    case built(PropositionID)
    case refused(TapRefusal)
}

/// A part of the figure to pulse on the board, from a proof glyph or a hint.
enum BoardHighlight: Equatable {
    case points([Vec2])
    case segment(Vec2, Vec2, ColorRole)
    case circle(center: Vec2, radius: Double, ColorRole)
    case angle(Vec2, vertex: Vec2, Vec2, ColorRole)
    case region([Vec2], ColorRole)
    /// The next move, drawn dashed, for an R4 hint.
    case ghostCircle(center: Vec2, radius: Double)
    case ghostSegment(Vec2, Vec2)
}

struct WorkshopHint: Equatable {
    let rung: HintLadderRung
    let text: String
    let highlight: BoardHighlight?
}

/// The region of the plane a proposition's figure covers, circles included.
struct BoardExtent: Equatable {
    var min: Vec2
    var max: Vec2

    var width: Double { max.x - min.x }
    var height: Double { max.y - min.y }
}

/// One proposition being built on the board. Every tap, tool change, hint and undo goes
/// through here, so the views only draw what this holds.
struct EuclidWorkshopSession {
    let proposition: EuclidProposition
    let construction: Construction
    /// Proven propositions she may use as one-tap tools, in catalog order.
    let tools: [PropositionID]
    let givenNames: [String: PointID]
    private(set) var board: ConstructionBoard
    private(set) var tool: ToolState = .compass(.awaitingCentre)
    var layer: BoardLayer
    /// The rung on show for the current move. It drops back to none once she makes a move.
    private(set) var hintRung: HintLadderRung = .none
    private(set) var hint: WorkshopHint?
    /// Set by any rung from R3, or by opening the proof before solving. Undo does not clear it.
    private(set) var isAssisted = false
    /// Lockhart's rule: the proof stays hidden until she has tried the problem.
    private(set) var hasAttempted = false
    /// The layer she finished in, which decides the level she earned.
    private(set) var solvedLayer: BoardLayer?
    var highlightedToken: ClaimToken?
    let script: ScriptedSolution

    static let palette: [ColorRole] = [.red, .blue, .amber, .green]

    init?(proposition: EuclidProposition, tools: [PropositionID] = [], layer: BoardLayer = .byrne) {
        guard case let .built(construction) = proposition.kind,
              let script = try? ScriptedSolution(construction) else { return nil }
        self.proposition = proposition
        self.construction = construction
        self.tools = tools
        self.layer = layer
        self.script = script
        board = ConstructionBoard(givens: construction.givens)
        givenNames = script.givenNames
    }

    /// The tools a board for `id` offers: every built proposition before it in Book I that she
    /// has proven at least with the picture. A fact the spine only accepts never becomes a tool.
    static func tools(for id: PropositionID, progress: EuclidProgress) -> [PropositionID] {
        let built = EuclidSpine.catalog.filter { if case .built = $0.kind { true } else { false } }.map(\.id)
        guard let index = built.firstIndex(of: id) else { return [] }
        let proven = progress.proven
        return built[..<index].filter(proven.contains)
    }

    // MARK: - State

    var isSolved: Bool {
        construction.goal.isSatisfied(by: board, names: givenNames)
    }

    /// The level a finished attempt earns, before progress decides whether it counts.
    var earnedLevel: SkillLevel? {
        guard isSolved, let solvedLayer else { return nil }
        return solvedLayer == .byrne ? .picture : .letters
    }

    var canRevealProof: Bool { !board.history.isEmpty || hasAttempted }

    /// The colour her next off-script curve takes.
    var nextRole: ColorRole {
        let strokes = board.history.filter {
            switch $0 {
            case .circle, .segment: true
            default: false
            }
        }.count
        return Self.palette[strokes % Self.palette.count]
    }

    var prompt: String {
        switch tool {
        case .compass(.awaitingCentre): "Compass: tap the point for the centre."
        case .compass(.awaitingRadius): "Now tap a point the circle runs through."
        case .straightedge(.awaitingStart): "Straightedge: tap the first point."
        case .straightedge(.awaitingEnd): "Now tap the point to join it to."
        case let .proposition(id, collected):
            "\(id): \(Self.construction(id)?.inputPrompt ?? "") (\(collected.count) of \(Self.inputCount(id)))"
        }
    }

    // MARK: - Moves

    mutating func choose(_ next: WorkshopTool) {
        if case let .proposition(id) = next, !tools.contains(id) { return }
        tool = ToolState(next)
    }

    /// A tap at `location` in board units. It snaps to a point or a crossing, never to empty paper;
    /// a crossing becomes a point first, then the tool takes it.
    @discardableResult
    mutating func tap(at location: Vec2, tolerance: Double) -> TapOutcome {
        guard let target = board.snap(location, tolerance: tolerance) else { return .refused(.emptyPaper) }
        let point: PointID
        switch target {
        case let .point(id):
            point = id
        case let .candidate(candidate):
            guard case let .point(id)? = try? board.apply(candidate.action) else {
                return .refused(.failed(.noIntersection(candidate.a, candidate.b, candidate.branch)))
            }
            point = id
            moved()
        }
        return use(point)
    }

    private mutating func use(_ point: PointID) -> TapOutcome {
        switch tool {
        case .compass(.awaitingCentre):
            tool = .compass(.awaitingRadius(point))
            return .picked(point)
        case let .compass(.awaitingRadius(centre)):
            if centre == point {
                tool = .compass(.awaitingCentre)
                return .released(point)
            }
            tool = .compass(.awaitingCentre)
            return draw(.circle(center: centre, through: point, role: role(circle: centre, through: point)))
        case .straightedge(.awaitingStart):
            tool = .straightedge(.awaitingEnd(point))
            return .picked(point)
        case let .straightedge(.awaitingEnd(start)):
            if start == point {
                tool = .straightedge(.awaitingStart)
                return .released(point)
            }
            tool = .straightedge(.awaitingStart)
            return draw(.segment(start, point, role: role(segment: start, point)))
        case let .proposition(id, collected):
            if collected.contains(point) { return .refused(.alreadyPicked) }
            let inputs = collected + [point]
            guard inputs.count == Self.inputCount(id) else {
                tool = .proposition(id, collected: inputs)
                return .picked(point)
            }
            tool = .proposition(id, collected: [])
            switch perform(.macro(id, inputs: inputs)) {
            case .success: return .built(id)
            case let .failure(refusal): return .refused(refusal)
            }
        }
    }

    private mutating func draw(_ action: BoardAction) -> TapOutcome {
        switch perform(action) {
        case let .success(.curve(id)): .drew(id)
        case .success: .refused(.alreadyOnBoard)
        case let .failure(refusal): .refused(refusal)
        }
    }

    /// Applies `action`, or leaves the board alone when it adds nothing or fails.
    private mutating func perform(_ action: BoardAction) -> Result<AppliedResult, TapRefusal> {
        let before = board
        do {
            let result = try board.apply(action)
            if board.points == before.points && board.curves == before.curves {
                board = before
                return .failure(.alreadyOnBoard)
            }
            moved()
            return .success(result)
        } catch let error as BoardError {
            return .failure(.failed(error))
        } catch {
            return .failure(.failed(.notBuildable(proposition.id)))
        }
    }

    private mutating func moved() {
        hint = nil
        hintRung = .none
        if isSolved, solvedLayer == nil {
            solvedLayer = layer
            hasAttempted = true
        }
    }

    mutating func undo() {
        guard !board.history.isEmpty,
              let previous = try? ConstructionBoard.replay(givens: construction.givens, history: Array(board.history.dropLast()))
        else { return }
        board = previous
        tool = ToolState(tool.tool)
        hint = nil
        hintRung = .none
        if !isSolved { solvedLayer = nil }
    }

    /// Opens the proof. Before she has solved it, that shows her the answer, so it counts as help.
    mutating func revealProof() {
        guard canRevealProof else { return }
        if !isSolved { isAssisted = true }
        hasAttempted = true
    }

    #if DEBUG
    /// Makes the next `count` scripted moves without marking help, for launch arguments that set up a screen.
    mutating func playScript(moves count: Int) {
        var made = 0
        while made < count, let next = script.next(on: board), let action = ScriptedSolution.action(for: next.move, on: board) {
            let before = board
            _ = perform(action)
            if board == before { break }
            made += 1
        }
    }
    #endif

    // MARK: - Hints

    /// Climbs one rung for the current move. R5 makes the next scripted move for her.
    mutating func requestHint() {
        guard !isSolved else { return }
        let rung = HintLadderRung(rawValue: min(hintRung.rawValue + 1, HintLadderRung.r5WorkedStep.rawValue)) ?? .r5WorkedStep
        if rung.surrendersRetrieval { isAssisted = true }
        guard let next = script.next(on: board) else {
            hintRung = rung
            hint = WorkshopHint(rung: rung, text: "Every scripted move is on the board. Check which sides still need drawing.", highlight: nil)
            return
        }
        let shown: WorkshopHint
        switch rung {
        case .none:
            return
        case .r0AttentionRedirect, .r1PatternRedescription, .r2CandidateClass:
            let index = rung.rawValue - HintLadderRung.r0AttentionRedirect.rawValue
            let text = proposition.hints.indices.contains(index) ? proposition.hints[index] : proposition.statement
            shown = WorkshopHint(rung: rung, text: text, highlight: nil)
        case .r3PropositionNamed:
            shown = WorkshopHint(rung: rung, text: Self.named(next.step.action), highlight: nil)
        case .r4MoveOutlined:
            shown = outline(next)
        case .r5WorkedStep:
            let outlined = outline(next)
            if let action = workedAction(next) {
                _ = perform(action)
                tool = ToolState(tool.tool)
            }
            shown = WorkshopHint(rung: rung, text: "Done for you: \(outlined.text)", highlight: outlined.highlight)
        }
        hintRung = rung
        hint = shown
    }

    private func usesTool(_ step: ScriptedStep) -> PropositionID? {
        if case let .macro(id, _) = step.action, tools.contains(id) { id } else { nil }
    }

    private func outline(_ next: ScriptedSolution.Next) -> WorkshopHint {
        let rung = HintLadderRung.r4MoveOutlined
        if let id = usesTool(next.step), case let .macro(_, inputs) = next.step.action {
            let at = inputs.compactMap { try? script.board.position(of: $0) }
            let names = layer == .letters ? at.compactMap(name(at:)) : []
            let order = names.count == at.count ? names.joined(separator: ", ") : "the ringed points, in the order of their numbers"
            return WorkshopHint(rung: rung, text: "Use the \(id) tool on \(order).", highlight: .points(at))
        }
        switch next.move {
        case let .circle(centre, through, _):
            let text = layer == .letters
                ? "Draw the circle centred at \(name(at: centre) ?? "the ringed point") through \(name(at: through) ?? "the second ringed point")."
                : "Draw the dashed circle with the compass: centre on the first ringed point, through the second."
            return WorkshopHint(rung: rung, text: text, highlight: .ghostCircle(center: centre, radius: centre.distance(to: through)))
        case let .segment(a, b, _):
            let text = layer == .letters
                ? "Join \(name(at: a) ?? "the first point") to \(name(at: b) ?? "the second") with the straightedge."
                : "Join the two ends of the dashed line with the straightedge."
            return WorkshopHint(rung: rung, text: text, highlight: .ghostSegment(a, b))
        case let .crossing(p):
            return WorkshopHint(rung: rung, text: "Tap the ringed crossing to make it a point.", highlight: .points([p]))
        }
    }

    private func workedAction(_ next: ScriptedSolution.Next) -> BoardAction? {
        if usesTool(next.step) != nil, case let .macro(id, inputs) = next.step.action {
            let mapped = inputs.compactMap { input in
                (try? script.board.position(of: input)).flatMap(board.point(at:))
            }
            return mapped.count == inputs.count ? .macro(id, inputs: mapped) : nil
        }
        return ScriptedSolution.action(for: next.move, on: board)
    }

    private static func named(_ action: BoardAction) -> String {
        switch action {
        case let .macro(id, _):
            "This step uses \(id): \(EuclidSpine.proposition(id)?.title.lowercased() ?? "an earlier proposition")."
        case .circle:
            Justification.postulate(3).meaning
        case .segment:
            Justification.postulate(1).meaning
        case .intersect:
            "Where two drawn curves cross is a point you may use. That is the only way to get a new point."
        }
    }

    // MARK: - Reading the figure

    /// The proposition's own letter for a point, in the Letters layer.
    func label(of id: PointID) -> String? {
        guard let position = try? board.position(of: id) else { return nil }
        return name(at: position)
    }

    func name(at position: Vec2) -> String? {
        script.letters.first { $0.position.distance(to: position) <= ScriptedSolution.sameness }?.name
    }

    /// Where a proof glyph's points sit on the scripted figure, in the glyph's own order.
    func positions(of token: ClaimToken) -> [Vec2] {
        let names: [String]
        switch token {
        case .text: return []
        case let .segment(p, q, _): names = [p, q]
        case let .angle(p, v, q, _): names = [p, v, q]
        case let .circle(center, _): names = [center]
        case let .region(corners, _): names = corners
        }
        return names.compactMap { script.position(named: $0) }
    }

    func highlight(for token: ClaimToken) -> BoardHighlight? {
        let at = positions(of: token)
        switch token {
        case .text:
            return nil
        case let .segment(_, _, role):
            return at.count == 2 ? .segment(at[0], at[1], role) : nil
        case let .angle(_, _, _, role):
            return at.count == 3 ? .angle(at[0], vertex: at[1], at[2], role) : nil
        case let .circle(center, role):
            guard let c = at.first, let radius = script.radius(ofCircleAt: center, role: role) else { return nil }
            return .circle(center: c, radius: radius, role)
        case let .region(_, role):
            return .region(at, role)
        }
    }

    /// The figure's extent, the solved board's, so the view does not rescale as she draws.
    var extent: BoardExtent { script.extent }

    // MARK: - Colour

    /// A curve on the scripted route keeps its Byrne colour, so the proof's glyphs match her board.
    private func role(circle centre: PointID, through: PointID) -> ColorRole {
        guard let c = try? board.position(of: centre), let t = try? board.position(of: through) else { return nextRole }
        return script.role(ofCircle: c, radius: c.distance(to: t)) ?? nextRole
    }

    private func role(segment a: PointID, _ b: PointID) -> ColorRole {
        guard let p = try? board.position(of: a), let q = try? board.position(of: b) else { return nextRole }
        return script.role(ofSegment: p, q) ?? nextRole
    }

    // MARK: - Catalog

    static func construction(_ id: PropositionID) -> Construction? {
        if case let .built(construction)? = EuclidSpine.proposition(id)?.kind { construction } else { nil }
    }

    static func inputCount(_ id: PropositionID) -> Int {
        construction(id)?.givenPointNames.count ?? 0
    }
}

// MARK: - The scripted solution, as moves to look for

/// One primitive move, by position, so it can be looked for on any board.
enum ScriptedMove: Hashable {
    case circle(center: Vec2, through: Vec2, role: ColorRole)
    case segment(Vec2, Vec2, role: ColorRole)
    case crossing(Vec2)
}

/// One entry of the scripted history and the primitive moves it expands into.
struct ScriptedStep {
    let action: BoardAction
    let moves: [ScriptedMove]
}

/// A proposition's scripted solution, split into the primitive moves her board can be diffed against.
struct ScriptedSolution {
    let steps: [ScriptedStep]
    /// The solved board and every named point on it, in the proposition's lettering.
    let board: ConstructionBoard
    let names: [String: PointID]
    let givenNames: [String: PointID]
    /// Single-letter names and where they sit, for the Letters layer.
    let letters: [(name: String, position: Vec2)]
    let extent: BoardExtent

    /// Positions this close are the same point, in board units.
    static let sameness = 1e-6

    struct Next {
        let step: ScriptedStep
        let move: ScriptedMove
    }

    init(_ construction: Construction) throws {
        let (solved, names) = try construction.build()
        board = solved
        self.names = names
        var replay = ConstructionBoard(givens: construction.givens)
        givenNames = Dictionary(uniqueKeysWithValues: construction.givenPointNames.compactMap { name in
            replay.pointID(named: name).map { (name, $0) }
        })
        var steps: [ScriptedStep] = []
        for action in solved.history {
            let (points, curves) = (replay.points.count, replay.curves.count)
            try replay.apply(action)
            steps.append(ScriptedStep(action: action, moves: Self.moves(replay, points: points, curves: curves)))
        }
        self.steps = steps
        letters = names.compactMap { name, id in
            guard name.count == 1, let p = try? solved.position(of: id) else { return nil }
            return (name, p)
        }.sorted { $0.name < $1.name }
        extent = Self.extent(of: solved)
    }

    /// The first scripted move missing from `board`. Every move before it is on the board, so
    /// the points and curves it needs are there too.
    func next(on board: ConstructionBoard) -> Next? {
        for step in steps {
            for move in step.moves where !Self.isPresent(move, on: board) {
                return Next(step: step, move: move)
            }
        }
        return nil
    }

    func position(named name: String) -> Vec2? {
        names[name].flatMap { try? board.position(of: $0) }
    }

    func radius(ofCircleAt name: String, role: ColorRole) -> Double? {
        guard let centre = names[name] else { return nil }
        let circles = board.curves.compactMap { curve -> (ColorRole, Double)? in
            guard case let .circle(c, t) = curve.curve, c == centre,
                  let pc = try? board.position(of: c), let pt = try? board.position(of: t) else { return nil }
            return (curve.role, pc.distance(to: pt))
        }
        return (circles.first { $0.0 == role } ?? circles.first)?.1
    }

    func role(ofCircle centre: Vec2, radius: Double) -> ColorRole? {
        for step in steps {
            for case let .circle(c, t, role) in step.moves
            where c.distance(to: centre) <= Self.sameness && abs(c.distance(to: t) - radius) <= Self.sameness {
                return role
            }
        }
        return nil
    }

    func role(ofSegment p: Vec2, _ q: Vec2) -> ColorRole? {
        for step in steps {
            for case let .segment(a, b, role) in step.moves {
                let same = (a.distance(to: p) <= Self.sameness && b.distance(to: q) <= Self.sameness)
                    || (a.distance(to: q) <= Self.sameness && b.distance(to: p) <= Self.sameness)
                if same { return role }
            }
        }
        return nil
    }

    static func isPresent(_ move: ScriptedMove, on board: ConstructionBoard) -> Bool {
        switch move {
        case let .circle(centre, through, _):
            let radius = centre.distance(to: through)
            return board.curves.contains { curve in
                guard case let .circle(c, t) = curve.curve,
                      let pc = try? board.position(of: c), let pt = try? board.position(of: t) else { return false }
                return pc.distance(to: centre) <= sameness && abs(pc.distance(to: pt) - radius) <= sameness
            }
        case let .segment(a, b, _):
            return board.isDrawn(from: a, to: b)
        case let .crossing(p):
            return board.point(at: p) != nil
        }
    }

    /// The action that makes `move` on `board`, when the points or curves it needs are there.
    static func action(for move: ScriptedMove, on board: ConstructionBoard) -> BoardAction? {
        switch move {
        case let .circle(centre, through, role):
            guard let c = board.point(at: centre), let t = board.point(at: through) else { return nil }
            return .circle(center: c, through: t, role: role)
        case let .segment(a, b, role):
            guard let p = board.point(at: a), let q = board.point(at: b) else { return nil }
            return .segment(p, q, role: role)
        case let .crossing(p):
            return board.intersectionCandidates().first { $0.position.distance(to: p) <= sameness }?.action
        }
    }

    /// The points and curves added since `points` and `curves`, in an order where each one's
    /// parts come before it: a crossing after both its curves, a curve after its points.
    private static func moves(_ board: ConstructionBoard, points: Int, curves: Int) -> [ScriptedMove] {
        var (i, j) = (points, curves)
        var moves: [ScriptedMove] = []
        func ready(point index: Int) -> Bool {
            guard case let .intersection(a, b, _) = board.points[index].origin else { return true }
            return max(a.raw, b.raw) < j
        }
        while i < board.points.count || j < board.curves.count {
            if i < board.points.count, ready(point: i) {
                moves.append(.crossing(board.points[i].position))
                i += 1
            } else if j < board.curves.count {
                let curve = board.curves[j]
                func at(_ id: PointID) -> Vec2 { board.points[id.raw].position }
                switch curve.curve {
                case let .circle(c, t): moves.append(.circle(center: at(c), through: at(t), role: curve.role))
                case let .segment(a, b): moves.append(.segment(at(a), at(b), role: curve.role))
                }
                j += 1
            } else {
                break
            }
        }
        return moves
    }

    private static func extent(of board: ConstructionBoard) -> BoardExtent {
        var low = Vec2(x: .infinity, y: .infinity), high = Vec2(x: -.infinity, y: -.infinity)
        func include(_ p: Vec2, _ r: Double = 0) {
            low = Vec2(x: Swift.min(low.x, p.x - r), y: Swift.min(low.y, p.y - r))
            high = Vec2(x: Swift.max(high.x, p.x + r), y: Swift.max(high.y, p.y + r))
        }
        board.points.forEach { include($0.position) }
        for curve in board.curves {
            if case let .circle(c, t) = curve.curve {
                let pc = board.points[c.raw].position
                include(pc, pc.distance(to: board.points[t.raw].position))
            }
        }
        return BoardExtent(min: low, max: high)
    }
}

extension ConstructionBoard {
    /// The point at `position`, if there is one.
    func point(at position: Vec2) -> PointID? {
        points.indices.first { points[$0].position.distance(to: position) <= ScriptedSolution.sameness }
            .map(PointID.init(raw:))
    }
}
