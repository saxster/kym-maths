import Foundation
import Testing
@testable import KymMaths

@Suite("Construction board")
struct ConstructionBoardTests {
    private static let root3 = 3.0.squareRoot()

    private func board(_ points: [(String, Double, Double)], segments: [(String, String)] = []) -> ConstructionBoard {
        ConstructionBoard(
            givens: points.map { .point($0.0, Vec2(x: $0.1, y: $0.2)) } + segments.map { .segment($0.0, $0.1) }
        )
    }

    private func id(_ board: ConstructionBoard, _ name: String) throws -> PointID {
        try #require(board.pointID(named: name))
    }

    private func expectClose(_ p: Vec2, _ x: Double, _ y: Double, sourceLocation: SourceLocation = #_sourceLocation) {
        #expect(abs(p.x - x) < 1e-12 && abs(p.y - y) < 1e-12, "got (\(p.x), \(p.y)), want (\(x), \(y))",
                sourceLocation: sourceLocation)
    }

    @Test("Two unit circles with centres 1 apart meet at (0.5, ±√3/2); left is the counterclockwise side of first centre → second")
    func circleCircle() throws {
        var b = board([("A", 0, 0), ("B", 1, 0)])
        let (a, bb) = (try id(b, "A"), try id(b, "B"))
        let aroundA = try b.circle(a, through: bb, .blue)
        let aroundB = try b.circle(bb, through: a, .red)

        expectClose(try #require(try b.intersection(aroundA, aroundB, .left)), 0.5, Self.root3 / 2)
        expectClose(try #require(try b.intersection(aroundA, aroundB, .right)), 0.5, -Self.root3 / 2)
        expectClose(try #require(try b.intersection(aroundB, aroundA, .left)), 0.5, -Self.root3 / 2)

        let top = try b.intersect(aroundA, aroundB, .left)
        expectClose(try b.position(of: top), 0.5, Self.root3 / 2)
        #expect(b.points[top.raw].origin == .intersection(aroundA, aroundB, .left))
    }

    @Test("A segment crosses a circle twice; nearer is the first crossing walking from the segment's first end")
    func segmentCircle() throws {
        var b = board([("O", 0, 0), ("R", 1, 0), ("P", -2, 0.5), ("Q", 2, 0.5)], segments: [("P", "Q")])
        let unit = try b.circle(id(b, "O"), through: id(b, "R"), .blue)
        let pq = CurveID(raw: 0)
        let half = Self.root3 / 2

        expectClose(try #require(try b.intersection(pq, unit, .nearer)), -half, 0.5)
        expectClose(try #require(try b.intersection(unit, pq, .farther)), half, 0.5)

        let qp = try b.segment(id(b, "Q"), id(b, "P"), .ink)
        #expect(qp == pq, "the same segment drawn backwards is the segment already on the board")
    }

    @Test("Two crossing segments meet once")
    func segmentSegment() throws {
        var b = board([("A", 0, 0), ("B", 4, 4), ("C", 0, 4), ("D", 4, 0)], segments: [("A", "B")])
        let cd = try b.segment(id(b, "C"), id(b, "D"), .red)
        expectClose(try #require(try b.intersection(CurveID(raw: 0), cd, .only)), 2, 2)
        #expect(try b.intersection(CurveID(raw: 0), cd, .left) == nil)
    }

    @Test("A crossing beyond the end of a segment does not exist")
    func crossingOutsideSegment() throws {
        var b = board([("A", 0, 0), ("B", 1, 0), ("C", 3, -1), ("D", 3, 1), ("O", 5, 0), ("R", 5, 1)],
                      segments: [("A", "B")])
        let ab = CurveID(raw: 0)
        let cd = try b.segment(id(b, "C"), id(b, "D"), .red)
        let circle = try b.circle(id(b, "O"), through: id(b, "R"), .blue)

        #expect(try b.intersection(ab, cd, .only) == nil, "the lines would meet at (3, 0), past B")
        #expect(try b.intersection(ab, circle, .nearer) == nil, "the circle's crossings at x = 4 and 6 are past B")
        #expect(throws: BoardError.noIntersection(ab, cd, .only)) { try b.intersect(ab, cd, .only) }
    }

    @Test("Circles that do not meet cannot be intersected, and a failed action changes nothing")
    func noIntersection() throws {
        var b = board([("A", 0, 0), ("B", 1, 0), ("C", 5, 0), ("D", 6, 0)])
        let left = try b.circle(id(b, "A"), through: id(b, "B"), .blue)
        let right = try b.circle(id(b, "C"), through: id(b, "D"), .red)
        let before = b

        #expect(throws: BoardError.noIntersection(left, right, .left)) { try b.intersect(left, right, .left) }
        #expect(b == before)
    }

    @Test("Actions on ids that are not on the board throw")
    func unknownIDs() throws {
        var b = board([("A", 0, 0), ("B", 1, 0)])
        let ghost = PointID(raw: 7)
        #expect(throws: BoardError.unknownPoint(ghost)) { try b.apply(.circle(center: ghost, through: PointID(raw: 0), role: .red)) }
        #expect(throws: BoardError.unknownCurve(CurveID(raw: 3))) {
            try b.apply(.intersect(CurveID(raw: 3), CurveID(raw: 4), .left))
        }
        #expect(throws: BoardError.zeroLength) { try b.apply(.circle(center: PointID(raw: 0), through: PointID(raw: 0), role: .red)) }
        #expect(b.history.isEmpty)
    }

    @Test("Snapping lands on an existing point first, then on a crossing, and never on empty paper")
    func snapping() throws {
        var b = board([("A", 0, 0), ("B", 1, 0)])
        let (a, bb) = (try id(b, "A"), try id(b, "B"))
        _ = try b.circle(a, through: bb, .blue)
        _ = try b.circle(bb, through: a, .red)

        #expect(b.snap(Vec2(x: 3, y: 3), tolerance: 0.2) == nil, "nothing near: no free point")
        #expect(b.snap(Vec2(x: 0.5, y: 0), tolerance: 0.2) == nil, "on no crossing")

        guard case let .candidate(top) = b.snap(Vec2(x: 0.52, y: 0.84), tolerance: 0.2) else {
            Issue.record("expected the upper crossing as a candidate")
            return
        }
        expectClose(top.position, 0.5, Self.root3 / 2)

        let c = try b.apply(top.action)
        #expect(b.snap(Vec2(x: 0.52, y: 0.84), tolerance: 0.2) == .point(try #require(c.pointID)))

        // A far, wide snap still prefers the existing point B to the nearer lower crossing.
        #expect(b.snap(Vec2(x: 0.7, y: -0.5), tolerance: 0.7) == .point(bb))
        #expect(b.intersectionCandidates().count == 1, "only the lower crossing is left to make")
    }

    @Test("Replaying the givens and the history rebuilds the same board")
    func replay() throws {
        let givens: [Given] = [.point("A", Vec2(x: 0, y: 0)), .point("B", Vec2(x: 3, y: 1)), .segment("A", "B")]
        var b = ConstructionBoard(givens: givens)
        let (a, bb) = (try id(b, "A"), try id(b, "B"))
        let aroundA = try b.circle(a, through: bb, .blue)
        let aroundB = try b.circle(bb, through: a, .red)
        let up = try b.intersect(aroundA, aroundB, .left)
        let down = try b.intersect(aroundA, aroundB, .right)
        let cross = try b.segment(up, down, .amber)
        _ = try b.intersect(cross, CurveID(raw: 0), .only)

        #expect(try ConstructionBoard.replay(givens: givens, history: b.history) == b)
    }
}

private extension AppliedResult {
    var pointID: PointID? {
        if case let .point(id) = self { id } else { nil }
    }
}
