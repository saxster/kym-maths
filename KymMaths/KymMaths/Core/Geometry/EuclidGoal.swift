import Foundation

/// What a built proposition asks for, named by its given points. A goal looks for constructed points
/// (never given ones) and for the segments that must be drawn, so it also accepts a learner's own route.
enum Goal: Hashable {
    case equilateralTriangle(on: String, String)
    case bisectAngle(vertex: String, arms: String, String)
    case bisectSegment(String, String)
    case perpendicularAt(point: String, onSegment: String, String)
    /// A square on either side of the segment.
    case squareOn(side: String, String)
    /// A square on each side, on the side away from the triangle.
    case squaresOnRightTriangle(rightAngle: String, String, String)

    /// Lengths match to this fraction of the given figure's size; angles to this many radians.
    static let tolerance = 1e-6

    func isSatisfied(by board: ConstructionBoard, names: [String: PointID]) -> Bool {
        (try? check(GoalBoard(board: board, names: names))) ?? false
    }

    private func check(_ g: GoalBoard) throws -> Bool {
        switch self {
        case let .equilateralTriangle(a, b):
            let (pa, pb) = (try g.at(a), try g.at(b))
            let side = pa.distance(to: pb)
            return g.drawn(pa, pb) && g.constructed.contains { p in
                g.same(p.distance(to: pa), side, scale: side) && g.same(p.distance(to: pb), side, scale: side)
                    && g.drawn(p, pa) && g.drawn(p, pb)
            }

        case let .bisectAngle(vertex, b, c):
            let (pv, pb, pc) = (try g.at(vertex), try g.at(b), try g.at(c))
            let half = Self.angle(at: pv, pb, pc) / 2
            return g.drawn(pv, pb) && g.drawn(pv, pc) && g.constructed.contains { p in
                p.distance(to: pv) > ConstructionBoard.coincidence && g.drawn(pv, p)
                    && g.same(Self.angle(at: pv, pb, p), half, scale: 1)
                    && g.same(Self.angle(at: pv, p, pc), half, scale: 1)
            }

        case let .bisectSegment(a, b):
            let (pa, pb) = (try g.at(a), try g.at(b))
            return g.drawn(pa, pb) && g.hasConstructedPoint(at: 0.5 * (pa + pb), scale: pa.distance(to: pb))

        case let .perpendicularAt(point, a, b):
            let (pc, pa, pb) = (try g.at(point), try g.at(a), try g.at(b))
            let line = pb - pa
            return g.drawn(pa, pb) && g.constructed.contains { p in
                let arm = p - pc
                return arm.length > ConstructionBoard.coincidence && g.drawn(pc, p)
                    && abs(arm.dot(line)) <= Self.tolerance * arm.length * line.length
            }

        case let .squareOn(a, b):
            let (pa, pb) = (try g.at(a), try g.at(b))
            return g.hasSquare(on: pa, pb, turning: 1) || g.hasSquare(on: pa, pb, turning: -1)

        case let .squaresOnRightTriangle(a, b, c):
            let (pa, pb, pc) = (try g.at(a), try g.at(b), try g.at(c))
            return [(pb, pc, pa), (pa, pb, pc), (pa, pc, pb)].allSatisfy { u, v, w in
                g.hasSquare(on: u, v, turning: (v - u).cross(w - u) > 0 ? -1 : 1)
            }
        }
    }

    /// The angle at `vertex` between the rays to `p` and `q`, in radians, from 0 to π.
    static func angle(at vertex: Vec2, _ p: Vec2, _ q: Vec2) -> Double {
        let (a, b) = (p - vertex, q - vertex)
        return atan2(abs(a.cross(b)), a.dot(b))
    }
}

private struct GoalBoard {
    let board: ConstructionBoard
    let names: [String: PointID]

    var constructed: [Vec2] {
        board.points.compactMap { point in
            if case .intersection = point.origin { point.position } else { nil }
        }
    }

    func at(_ name: String) throws -> Vec2 {
        try board.position(of: names.point(name))
    }

    func drawn(_ p: Vec2, _ q: Vec2) -> Bool {
        board.isDrawn(from: p, to: q)
    }

    func same(_ a: Double, _ b: Double, scale: Double) -> Bool {
        abs(a - b) <= Goal.tolerance * scale
    }

    func hasConstructedPoint(at target: Vec2, scale: Double) -> Bool {
        constructed.contains { $0.distance(to: target) <= Goal.tolerance * scale }
    }

    /// The square on `a`–`b` whose other corners lie a quarter turn counterclockwise (`turning` 1) or clockwise (-1).
    func hasSquare(on a: Vec2, _ b: Vec2, turning: Double) -> Bool {
        let side = a.distance(to: b)
        let offset = turning * (b - a).perpendicular
        let (d, e) = (a + offset, b + offset)
        return hasConstructedPoint(at: d, scale: side) && hasConstructedPoint(at: e, scale: side)
            && drawn(a, b) && drawn(a, d) && drawn(b, e) && drawn(d, e)
    }
}
