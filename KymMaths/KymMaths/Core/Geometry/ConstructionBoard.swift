import Foundation

/// A point or a direction in the board's plane. y points up, so "left" and "counterclockwise" agree.
struct Vec2: Hashable, Codable {
    var x: Double
    var y: Double

    static func + (a: Vec2, b: Vec2) -> Vec2 { Vec2(x: a.x + b.x, y: a.y + b.y) }
    static func - (a: Vec2, b: Vec2) -> Vec2 { Vec2(x: a.x - b.x, y: a.y - b.y) }
    static func * (k: Double, v: Vec2) -> Vec2 { Vec2(x: k * v.x, y: k * v.y) }

    func dot(_ o: Vec2) -> Double { x * o.x + y * o.y }
    /// Positive when `o` turns counterclockwise from `self`.
    func cross(_ o: Vec2) -> Double { x * o.y - y * o.x }
    var length: Double { (x * x + y * y).squareRoot() }
    func distance(to o: Vec2) -> Double { (self - o).length }
    /// A quarter turn counterclockwise.
    var perpendicular: Vec2 { Vec2(x: -y, y: x) }
}

/// Ids are creation-order indices, so replaying a history hands out the same ids.
struct PointID: Hashable, Codable { let raw: Int }
struct CurveID: Hashable, Codable { let raw: Int }

/// The board's colours. The Byrne view draws each role in its `MathsFigureColor`.
enum ColorRole: String, Hashable, Codable, CaseIterable {
    case red, blue, amber, green, ink
}

enum Curve: Hashable, Codable {
    /// Postulate 3.
    case circle(center: PointID, through: PointID)
    /// Postulate 1. Finite only: the board has no Postulate 2, so givens are drawn long enough instead.
    case segment(PointID, PointID)
}

/// Which crossing an intersection takes, when two curves cross twice.
enum Branch: String, Hashable, Codable {
    /// Circle and circle: the crossing left of the directed line from the first centre to the second.
    case left
    case right
    /// Segment and circle: walking the segment from its first endpoint, the first crossing on it.
    case nearer
    /// Segment and circle: the second crossing on the segment.
    case farther
    /// Segment and segment.
    case only
}

/// Euclid's rule: a point is given, or it is where two drawn curves cross. There are no free points.
enum PointOrigin: Hashable, Codable {
    case given(name: String)
    case intersection(CurveID, CurveID, Branch)
}

struct BoardPoint: Hashable, Codable {
    let position: Vec2
    let origin: PointOrigin
}

struct BoardCurve: Hashable, Codable {
    let curve: Curve
    let role: ColorRole
}

/// What a proposition starts from. Given segments join given points and are drawn in ink.
enum Given: Hashable {
    case point(String, Vec2)
    case segment(String, String)
}

enum BoardAction: Hashable, Codable {
    case circle(center: PointID, through: PointID, role: ColorRole)
    case segment(PointID, PointID, role: ColorRole)
    case intersect(CurveID, CurveID, Branch)
    /// Runs a proven proposition's construction on `inputs`, its given points in order.
    case macro(PropositionID, inputs: [PointID])
}

enum AppliedResult: Hashable {
    case curve(CurveID)
    case point(PointID)
    /// The proposition's named points, in its own lettering.
    case macro([String: PointID])
}

/// A crossing that exists on the board but has not been made into a point yet.
struct Candidate: Hashable {
    let a: CurveID
    let b: CurveID
    let branch: Branch
    let position: Vec2

    var action: BoardAction { .intersect(a, b, branch) }
}

enum SnapTarget: Hashable {
    case point(PointID)
    case candidate(Candidate)
}

enum BoardError: Error, Equatable {
    case unknownPoint(PointID)
    case unknownCurve(CurveID)
    case unknownName(String)
    case unknownProposition(PropositionID)
    /// A circle through its own centre, or a segment from a point to itself.
    case zeroLength
    case noIntersection(CurveID, CurveID, Branch)
    case notBuildable(PropositionID)
    case wrongInputCount(PropositionID, expected: Int, got: Int)
}

/// A compass-and-straightedge figure, rebuilt from its givens and the learner's actions.
///
/// Drawing a curve that is already on the board, or crossing at a point that already exists,
/// hands back the existing id. A macro is one history entry; replay expands it again.
struct ConstructionBoard: Equatable {
    private(set) var points: [BoardPoint] = []
    private(set) var curves: [BoardCurve] = []
    private(set) var history: [BoardAction] = []

    /// Two positions closer than this are the same point.
    static let coincidence = 1e-9

    init(givens: [Given]) {
        var named: [String: PointID] = [:]
        for given in givens {
            switch given {
            case let .point(name, position):
                named[name] = PointID(raw: points.count)
                points.append(BoardPoint(position: position, origin: .given(name: name)))
            case let .segment(a, b):
                guard let a = named[a], let b = named[b] else {
                    preconditionFailure("A given segment must join given points declared before it")
                }
                curves.append(BoardCurve(curve: .segment(a, b), role: .ink))
            }
        }
    }

    static func replay(givens: [Given], history: [BoardAction]) throws -> ConstructionBoard {
        var board = ConstructionBoard(givens: givens)
        for action in history {
            try board.apply(action)
        }
        return board
    }

    func pointID(named name: String) -> PointID? {
        points.indices.first { points[$0].origin == .given(name: name) }.map(PointID.init(raw:))
    }

    func position(of id: PointID) throws -> Vec2 {
        guard points.indices.contains(id.raw) else { throw BoardError.unknownPoint(id) }
        return points[id.raw].position
    }

    // MARK: - Actions

    @discardableResult
    mutating func apply(_ action: BoardAction) throws -> AppliedResult {
        switch action {
        case let .circle(center, through, role): .curve(try circle(center, through: through, role))
        case let .segment(a, b, role): .curve(try segment(a, b, role))
        case let .intersect(a, b, branch): .point(try intersect(a, b, branch))
        case let .macro(id, inputs): .macro(try use(id, inputs))
        }
    }

    mutating func circle(_ center: PointID, through: PointID, _ role: ColorRole) throws -> CurveID {
        try recording(.circle(center: center, through: through, role: role)) { board in
            let radius = try board.position(of: through).distance(to: board.position(of: center))
            guard radius > Self.coincidence else { throw BoardError.zeroLength }
            if let same = try board.curves.indices.first(where: { index in
                guard case let .circle(c, t) = board.curves[index].curve, c == center else { return false }
                return abs(try board.position(of: t).distance(to: board.position(of: c)) - radius) <= Self.coincidence
            }) {
                return CurveID(raw: same)
            }
            return board.add(.circle(center: center, through: through), role)
        }
    }

    mutating func segment(_ a: PointID, _ b: PointID, _ role: ColorRole) throws -> CurveID {
        try recording(.segment(a, b, role: role)) { board in
            guard try board.position(of: a).distance(to: board.position(of: b)) > Self.coincidence else {
                throw BoardError.zeroLength
            }
            if let same = board.curves.indices.first(where: {
                board.curves[$0].curve == .segment(a, b) || board.curves[$0].curve == .segment(b, a)
            }) {
                return CurveID(raw: same)
            }
            return board.add(.segment(a, b), role)
        }
    }

    mutating func intersect(_ a: CurveID, _ b: CurveID, _ branch: Branch) throws -> PointID {
        try recording(.intersect(a, b, branch)) { board in
            guard let position = try board.intersection(a, b, branch) else {
                throw BoardError.noIntersection(a, b, branch)
            }
            if let existing = board.existingPoint(at: position) {
                return existing
            }
            board.points.append(BoardPoint(position: position, origin: .intersection(a, b, branch)))
            return PointID(raw: board.points.count - 1)
        }
    }

    /// Where `a` and `b` cross other than at `known`: where a circle through D cuts a line through D again.
    mutating func intersect(_ a: CurveID, _ b: CurveID, awayFrom known: PointID) throws -> PointID {
        let knownPosition = try position(of: known)
        let options = try branches(a, b)
        for branch in options {
            if let p = try intersection(a, b, branch), p.distance(to: knownPosition) > Self.coincidence {
                return try intersect(a, b, branch)
            }
        }
        throw BoardError.noIntersection(a, b, options[options.count - 1])
    }

    /// Runs a proven proposition on `inputs`. Its given segments are drawn first, as Postulate 1 allows.
    mutating func use(_ id: PropositionID, _ inputs: [PointID]) throws -> [String: PointID] {
        try recording(.macro(id, inputs: inputs)) { board in
            guard let proposition = EuclidSpine.proposition(id) else { throw BoardError.unknownProposition(id) }
            guard case let .built(construction) = proposition.kind else { throw BoardError.notBuildable(id) }
            let names = construction.givenPointNames
            guard inputs.count == names.count else {
                throw BoardError.wrongInputCount(id, expected: names.count, got: inputs.count)
            }
            for input in inputs {
                _ = try board.position(of: input)
            }
            let bound = Dictionary(uniqueKeysWithValues: zip(names, inputs))
            let outer = board.history
            for case let .segment(a, b) in construction.givens {
                _ = try board.segment(bound.point(a), bound.point(b), .ink)
            }
            let named = try construction.construct(&board, bound)
            board.history = outer
            return named
        }
    }

    /// Applies `body` to a copy, so a failed action leaves the board unchanged.
    private mutating func recording<T>(_ action: BoardAction, _ body: (inout ConstructionBoard) throws -> T) throws -> T {
        var next = self
        let value = try body(&next)
        next.history.append(action)
        self = next
        return value
    }

    private mutating func add(_ curve: Curve, _ role: ColorRole) -> CurveID {
        curves.append(BoardCurve(curve: curve, role: role))
        return CurveID(raw: curves.count - 1)
    }

    private func existingPoint(at position: Vec2) -> PointID? {
        points.indices.first { points[$0].position.distance(to: position) <= Self.coincidence }
            .map(PointID.init(raw:))
    }

    // MARK: - Queries

    /// Where `a` and `b` cross on `branch`, or nil when that crossing does not exist.
    func intersection(_ a: CurveID, _ b: CurveID, _ branch: Branch) throws -> Vec2? {
        guard a != b else { return nil }
        switch (try shape(a), try shape(b)) {
        case let (.circle(c1, r1), .circle(c2, r2)):
            return Self.circleCircle(c1, r1, c2, r2, branch)
        case let (.segment(p0, p1), .circle(c, r)), let (.circle(c, r), .segment(p0, p1)):
            return Self.segmentCircle(p0, p1, c, r, branch)
        case let (.segment(p0, p1), .segment(q0, q1)):
            return branch == .only ? Self.segmentSegment(p0, p1, q0, q1) : nil
        }
    }

    /// Every crossing of two drawn curves that is not yet a point.
    func intersectionCandidates() -> [Candidate] {
        var found: [Candidate] = []
        for i in curves.indices {
            for j in curves.indices where j > i {
                let a = CurveID(raw: i), b = CurveID(raw: j)
                for branch in (try? branches(a, b)) ?? [] {
                    guard let p = try? intersection(a, b, branch),
                          existingPoint(at: p) == nil,
                          !found.contains(where: { $0.position.distance(to: p) <= Self.coincidence })
                    else { continue }
                    found.append(Candidate(a: a, b: b, branch: branch, position: p))
                }
            }
        }
        return found
    }

    /// The nearest existing point within `tolerance`, else the nearest candidate crossing. Never a free point.
    func snap(_ p: Vec2, tolerance: Double) -> SnapTarget? {
        let point = points.indices
            .map { (id: PointID(raw: $0), distance: points[$0].position.distance(to: p)) }
            .filter { $0.distance <= tolerance }
            .min { $0.distance < $1.distance }
        if let point { return .point(point.id) }
        let candidate = intersectionCandidates()
            .filter { $0.position.distance(to: p) <= tolerance }
            .min { $0.position.distance(to: p) < $1.position.distance(to: p) }
        return candidate.map(SnapTarget.candidate)
    }

    /// Whether some drawn segment runs through both `p` and `q`.
    func isDrawn(from p: Vec2, to q: Vec2) -> Bool {
        curves.contains { curve in
            guard case let .segment(a, b) = curve.curve,
                  let s0 = try? position(of: a), let s1 = try? position(of: b) else { return false }
            return Self.lies(p, on: s0, s1) && Self.lies(q, on: s0, s1)
        }
    }

    // MARK: - Geometry

    private enum Shape {
        case circle(Vec2, Double)
        case segment(Vec2, Vec2)
    }

    private func shape(_ id: CurveID) throws -> Shape {
        guard curves.indices.contains(id.raw) else { throw BoardError.unknownCurve(id) }
        switch curves[id.raw].curve {
        case let .circle(center, through):
            let c = try position(of: center)
            return .circle(c, try position(of: through).distance(to: c))
        case let .segment(a, b):
            return .segment(try position(of: a), try position(of: b))
        }
    }

    private func branches(_ a: CurveID, _ b: CurveID) throws -> [Branch] {
        switch (try shape(a), try shape(b)) {
        case (.circle, .circle): [.left, .right]
        case (.segment, .segment): [.only]
        default: [.nearer, .farther]
        }
    }

    /// Slack, as a fraction of a segment's length, for a crossing at the segment's very end.
    private static let endSlack = 1e-9

    private static func circleCircle(_ c1: Vec2, _ r1: Double, _ c2: Vec2, _ r2: Double, _ branch: Branch) -> Vec2? {
        let d = c1.distance(to: c2)
        guard d > coincidence else { return nil }
        let along = (d * d + r1 * r1 - r2 * r2) / (2 * d)
        let h2 = r1 * r1 - along * along
        guard h2 >= -endSlack * r1 * r1 else { return nil }
        let u = (1 / d) * (c2 - c1)
        let base = c1 + along * u
        let offset = h2 > 0 ? h2.squareRoot() : 0
        switch branch {
        case .left: return base + offset * u.perpendicular
        case .right: return base - offset * u.perpendicular
        default: return nil
        }
    }

    private static func segmentCircle(_ p0: Vec2, _ p1: Vec2, _ c: Vec2, _ r: Double, _ branch: Branch) -> Vec2? {
        let d = p1 - p0, f = p0 - c
        let a = d.dot(d), b = 2 * f.dot(d), k = f.dot(f) - r * r
        let disc = b * b - 4 * a * k
        guard disc >= -endSlack * a * a else { return nil }
        let root = disc > 0 ? disc.squareRoot() : 0
        var onSegment = [(-b - root) / (2 * a), (-b + root) / (2 * a)]
            .filter { $0 >= -endSlack && $0 <= 1 + endSlack }
        if onSegment.count == 2, onSegment[1] - onSegment[0] <= endSlack {
            onSegment.removeLast()
        }
        let t: Double?
        switch branch {
        case .nearer: t = onSegment.first
        case .farther: t = onSegment.count == 2 ? onSegment[1] : nil
        default: t = nil
        }
        return t.map { p0 + $0 * d }
    }

    private static func segmentSegment(_ p0: Vec2, _ p1: Vec2, _ q0: Vec2, _ q1: Vec2) -> Vec2? {
        let r = p1 - p0, s = q1 - q0
        let denom = r.cross(s)
        guard abs(denom) > endSlack * r.length * s.length else { return nil }
        let t = (q0 - p0).cross(s) / denom
        let u = (q0 - p0).cross(r) / denom
        let range = -endSlack...(1 + endSlack)
        guard range.contains(t), range.contains(u) else { return nil }
        return p0 + t * r
    }

    private static func lies(_ x: Vec2, on s0: Vec2, _ s1: Vec2) -> Bool {
        let d = s1 - s0
        let length2 = d.dot(d)
        let t = (x - s0).dot(d) / length2
        return t >= -endSlack && t <= 1 + endSlack && abs(d.cross(x - s0)) <= endSlack * length2
    }
}

extension Dictionary where Key == String, Value == PointID {
    /// The point a construction calls `name`.
    func point(_ name: String) throws -> PointID {
        guard let id = self[name] else { throw BoardError.unknownName(name) }
        return id
    }
}

// MARK: - Reading segments

/// A drawn piece of the figure: a whole segment or part of one, in its colour.
struct FigureStroke: Equatable {
    let from: Vec2
    let to: Vec2
    let role: ColorRole
}

extension ConstructionBoard {
    /// The two of `marks` on segment `id` that lie farthest apart along it, first-end first. Nil for
    /// a circle, or when fewer than two marks at different places lie on the segment.
    func outermost<Mark>(on id: CurveID, of marks: [(mark: Mark, at: Vec2)],
                         tolerance: Double = coincidence) -> (first: Mark, last: Mark)? {
        guard curves.indices.contains(id.raw), case let .segment(a, b) = curves[id.raw].curve,
              let pa = try? position(of: a), let pb = try? position(of: b) else { return nil }
        let along = pb - pa
        let length = along.length
        let onIt = marks.compactMap { mark -> (Mark, Double)? in
            let w = mark.at - pa
            let t = w.dot(along) / (length * length)
            guard abs(along.cross(w)) <= tolerance * length, t > -tolerance, t < 1 + tolerance else { return nil }
            return (mark.mark, t)
        }.sorted { $0.1 < $1.1 }
        guard let first = onIt.first, let last = onIt.last, (last.1 - first.1) * length > tolerance else { return nil }
        return (first.0, last.0)
    }

    /// Every segment's part between the outermost of `marks` on it: the lines those points name.
    func strokes(between marks: [Vec2], tolerance: Double = coincidence) -> [FigureStroke] {
        curves.indices.compactMap { index in
            outermost(on: CurveID(raw: index), of: marks.map { ($0, $0) }, tolerance: tolerance)
                .map { FigureStroke(from: $0.first, to: $0.last, role: curves[index].role) }
        }
    }
}
