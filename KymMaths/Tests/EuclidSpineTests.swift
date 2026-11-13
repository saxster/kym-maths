import Foundation
import Testing
@testable import KymMaths

@Suite("Euclid spine")
struct EuclidSpineTests {
    private static let built: [(EuclidProposition, Construction)] = EuclidSpine.catalog.compactMap { proposition in
        if case let .built(construction) = proposition.kind { (proposition, construction) } else { nil }
    }

    private static func construction(_ id: PropositionID) throws -> Construction {
        let proposition = try #require(EuclidSpine.proposition(id))
        guard case let .built(construction) = proposition.kind else {
            throw BoardError.notBuildable(id)
        }
        return construction
    }

    // MARK: - The graph

    @Test("The spine builds I.1, I.9, I.10, I.11, I.46 and I.47, and every id is listed once")
    func builtSet() {
        #expect(Self.built.map(\.0.id) == ["I.1", "I.9", "I.10", "I.11", "I.46", "I.47"])
        let ids = EuclidSpine.catalog.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("Every proposition a proof cites is in the catalog")
    func usesExist() {
        for proposition in EuclidSpine.catalog {
            for used in proposition.uses {
                #expect(EuclidSpine.proposition(used) != nil, "\(proposition.id) uses \(used), which is missing")
            }
            for step in proposition.proofSteps {
                if case let .proposition(cited) = step.because {
                    #expect(proposition.uses.contains(cited), "\(proposition.id) cites \(cited) without listing it in uses")
                }
            }
        }
    }

    @Test("The dependency graph has no loops, and each proposition stands only on lower-numbered ones")
    func noLoops() {
        var visiting: Set<PropositionID> = [], done: Set<PropositionID> = []
        func visit(_ id: PropositionID) -> Bool {
            if done.contains(id) { return true }
            guard visiting.insert(id).inserted, let proposition = EuclidSpine.proposition(id) else { return false }
            let ok = proposition.uses.allSatisfy(visit)
            done.insert(id)
            return ok
        }
        for proposition in EuclidSpine.catalog {
            #expect(visit(proposition.id), "a loop runs through \(proposition.id)")
            for used in proposition.uses {
                #expect(Self.number(used) < Self.number(proposition.id), "\(proposition.id) uses the later \(used)")
            }
        }
    }

    @Test("Every built proposition unlocks another or leads to a chapter")
    func noDeadEnds() {
        for (proposition, _) in Self.built {
            #expect(!proposition.unlocks.isEmpty || proposition.leadsToChapter != nil, "\(proposition.id) leads nowhere")
        }
        #expect(EuclidSpine.proposition("I.1")?.unlocks == ["I.9", "I.10", "I.11"])
        #expect(EuclidSpine.proposition("I.47")?.leadsToChapter == "ch12")
    }

    @Test("Built propositions carry a proof and a word problem that names them; accepted ones name their chapter")
    func cards() {
        for proposition in EuclidSpine.catalog {
            switch proposition.kind {
            case .built:
                #expect(!proposition.proofSteps.isEmpty, "\(proposition.id) has no proof")
                #expect(proposition.knowsWhen?.answer == proposition.id)
            case let .accepted(taughtIn):
                #expect(taughtIn.contains("OUP"), "\(proposition.id) does not say where school teaches it")
                #expect(proposition.uses.isEmpty && proposition.proofSteps.isEmpty)
            }
            #expect(!proposition.deviceOffCheck.task.isEmpty && !proposition.deviceOffCheck.answer.isEmpty)
        }
    }

    // MARK: - Constructions

    @Test("Each scripted construction satisfies its goal", arguments: built.map(\.0.id))
    func scriptedSolution(_ id: PropositionID) throws {
        let construction = try Self.construction(id)
        let (board, names) = try construction.build()
        #expect(construction.goal.isSatisfied(by: board, names: names))
    }

    @Test("Replaying each construction's history rebuilds it exactly", arguments: built.map(\.0.id))
    func replay(_ id: PropositionID) throws {
        let construction = try Self.construction(id)
        let (board, _) = try construction.build()
        #expect(try ConstructionBoard.replay(givens: construction.givens, history: board.history) == board)
    }

    @Test("Every glyph in a proof names a point of the construction, and segments and circles match the board's colour",
          arguments: built.map(\.0.id))
    func proofGlyphsMatchBoard(_ id: PropositionID) throws {
        let proposition = try #require(EuclidSpine.proposition(id))
        let (board, names) = try Self.construction(id).build()
        func at(_ name: String) throws -> Vec2 { try board.position(of: try #require(names[name], "\(id) has no point \(name)")) }

        for token in proposition.proofSteps.flatMap(\.claim) {
            switch token {
            case .text:
                break
            case let .segment(p, q, role):
                let (pp, pq) = (try at(p), try at(q))
                let drawn = board.curves.contains { curve in
                    guard curve.role == role, case let .segment(a, b) = curve.curve else { return false }
                    return Self.contains(board, a, b, pp) && Self.contains(board, a, b, pq)
                }
                #expect(drawn, "\(id): \(p)\(q) is not drawn in \(role)")
            case let .circle(center, role):
                let c = try #require(names[center])
                let drawn = board.curves.contains { curve in
                    guard curve.role == role, case let .circle(centre, _) = curve.curve else { return false }
                    return centre == c
                }
                #expect(drawn, "\(id): no \(role) circle centred at \(center)")
            case let .angle(p, v, q, _):
                for name in [p, v, q] { _ = try at(name) }
            case let .region(corners, _):
                for name in corners { _ = try at(name) }
            }
        }
    }

    // MARK: - Near misses

    private static func given(_ construction: Construction, plus extra: [Given]) -> (ConstructionBoard, [String: PointID]) {
        let board = ConstructionBoard(givens: construction.givens + extra)
        let names = Dictionary(uniqueKeysWithValues: board.points.indices.compactMap { index -> (String, PointID)? in
            if case let .given(name) = board.points[index].origin { (name, PointID(raw: index)) } else { nil }
        })
        return (board, names)
    }

    @Test("A given point in exactly the right place does not count: the apex must be constructed")
    func givenApexFails() throws {
        let construction = try Self.construction("I.1")
        var (board, names) = Self.given(construction, plus: [.point("C", Vec2(x: 2, y: 2 * 3.0.squareRoot()))])
        _ = try board.segment(names.point("C"), names.point("A"), .blue)
        _ = try board.segment(names.point("C"), names.point("B"), .red)
        #expect(!construction.goal.isSatisfied(by: board, names: names))
    }

    @Test("A goal needs its sides drawn, not just its corners found")
    func undrawnSidesFail() throws {
        let i1 = try Self.construction("I.1")
        var (triangle, n) = Self.given(i1, plus: [])
        let (a, b) = (try n.point("A"), try n.point("B"))
        let c = try triangle.intersect(try triangle.circle(a, through: b, .blue), try triangle.circle(b, through: a, .red), .left)
        _ = try triangle.segment(c, a, .blue)
        #expect(!i1.goal.isSatisfied(by: triangle, names: n), "CB is missing")
        _ = try triangle.segment(c, b, .red)
        #expect(i1.goal.isSatisfied(by: triangle, names: n))

        let i46 = try Self.construction("I.46")
        var (square, m) = Self.given(i46, plus: [])
        let (p, sa, sb, q) = (try m.point("P"), try m.point("A"), try m.point("B"), try m.point("Q"))
        let fromA = try square.use("I.11", [p, q, sa]).point("F")
        let fromB = try square.use("I.11", [p, q, sb]).point("F")
        let d = try square.intersect(try square.circle(sa, through: sb, .blue), try square.segment(sa, fromA, .amber), .nearer)
        let e = try square.intersect(try square.circle(sb, through: sa, .red), try square.segment(sb, fromB, .amber), .nearer)
        #expect(!i46.goal.isSatisfied(by: square, names: m), "DE is missing")
        _ = try square.segment(d, e, .green)
        #expect(i46.goal.isSatisfied(by: square, names: m))
    }

    @Test("I.1 fails when the second circle runs through a point 2% too far out")
    func nearMissI1() throws {
        let construction = try Self.construction("I.1")
        var (board, n) = Self.given(construction, plus: [.point("X", Vec2(x: 4 - 4.08, y: 0))])
        let (a, b) = (try n.point("A"), try n.point("B"))
        let c = try board.intersect(try board.circle(a, through: b, .blue), try board.circle(b, through: n.point("X"), .red), .left)
        _ = try board.segment(c, a, .blue)
        _ = try board.segment(c, b, .red)
        #expect(!construction.goal.isSatisfied(by: board, names: n))

        var honest = Self.given(construction, plus: []).0
        _ = try honest.use("I.1", [a, b])
        #expect(construction.goal.isSatisfied(by: honest, names: n), "the same givens pass when built honestly")
    }

    @Test("I.9 fails when E is cut off 2% further along AC than D")
    func nearMissI9() throws {
        let construction = try Self.construction("I.9")
        var (board, n) = Self.given(construction, plus: [.point("X", Vec2(x: 4.08, y: 0))])
        let (a, b, c) = (try n.point("A"), try n.point("B"), try n.point("C"))
        let e = try board.intersect(try board.circle(a, through: n.point("X"), .green), try board.segment(a, c, .ink), .nearer)
        let f = try board.use("I.1", [e, b]).point("C")
        _ = try board.segment(a, f, .amber)
        #expect(!construction.goal.isSatisfied(by: board, names: n))
    }

    @Test("I.10 fails when the two circles have unequal radii")
    func nearMissI10() throws {
        let construction = try Self.construction("I.10")
        var (board, n) = Self.given(construction, plus: [.point("X", Vec2(x: 7 - 7 * 0.98, y: 0))])
        let (a, b) = (try n.point("A"), try n.point("B"))
        let aroundA = try board.circle(a, through: b, .blue)
        let aroundB = try board.circle(b, through: n.point("X"), .red)
        let up = try board.intersect(aroundA, aroundB, .left)
        let down = try board.intersect(aroundA, aroundB, .right)
        _ = try board.intersect(try board.segment(up, down, .amber), try board.segment(a, b, .ink), .only)
        #expect(!construction.goal.isSatisfied(by: board, names: n))
    }

    @Test("I.11 fails when E is 2% further from C than D is")
    func nearMissI11() throws {
        let construction = try Self.construction("I.11")
        var (board, n) = Self.given(construction, plus: [.point("X", Vec2(x: 3 + 3 * 1.02, y: 0))])
        let (a, b, c) = (try n.point("A"), try n.point("B"), try n.point("C"))
        let e = try board.intersect(try board.circle(c, through: n.point("X"), .green), try board.segment(a, b, .ink), .nearer)
        let f = try board.use("I.1", [a, e]).point("C")
        _ = try board.segment(c, f, .amber)
        #expect(!construction.goal.isSatisfied(by: board, names: n))
    }

    @Test("I.46 fails when one side is cut off 2% too long")
    func nearMissI46() throws {
        let construction = try Self.construction("I.46")
        var (board, n) = Self.given(construction, plus: [.point("X", Vec2(x: 5 - 5 * 1.02, y: 0))])
        let (p, a, b, q) = (try n.point("P"), try n.point("A"), try n.point("B"), try n.point("Q"))
        let upFromA = try board.segment(a, board.use("I.11", [p, q, a]).point("F"), .amber)
        let fromB = try board.use("I.11", [p, q, b]).point("F")
        let upFromB = try board.segment(b, fromB, .amber)
        let d = try board.intersect(try board.circle(a, through: b, .blue), upFromA, .nearer)
        let e = try board.intersect(try board.circle(b, through: n.point("X"), .red), upFromB, .nearer)
        _ = try board.segment(d, e, .green)
        #expect(!construction.goal.isSatisfied(by: board, names: n))
    }

    @Test("I.47 fails when one square is built inward, over the triangle")
    func nearMissI47() throws {
        let construction = try Self.construction("I.47")
        var (board, n) = Self.given(construction, plus: [])
        func run(_ inputs: [String]) throws { _ = try board.use("I.46", inputs.map { try n.point($0) }) }
        try run(["bc2", "C", "B", "bc1"])
        try run(["ab2", "B", "A", "ab1"])
        try run(["ac2", "C", "A", "ac1"])
        #expect(!construction.goal.isSatisfied(by: board, names: n))

        var outward = Self.given(construction, plus: []).0
        for inputs in [["bc2", "C", "B", "bc1"], ["ab2", "B", "A", "ab1"], ["ac1", "A", "C", "ac2"]] {
            _ = try outward.use("I.46", inputs.map { try n.point($0) })
        }
        #expect(construction.goal.isSatisfied(by: outward, names: n), "turning that square outward passes")
    }

    // MARK: - Macros

    @Test("Building I.10 with the I.1 and I.9 tools gives the same figure as doing every step by hand")
    func macroMatchesPrimitives() throws {
        let construction = try Self.construction("I.10")
        let (viaTools, _) = try construction.build()

        var byHand = ConstructionBoard(givens: construction.givens)
        let (a, b) = (try #require(byHand.pointID(named: "A")), try #require(byHand.pointID(named: "B")))
        // I.1 on AB.
        let aroundA = try byHand.circle(a, through: b, .blue)
        let aroundB = try byHand.circle(b, through: a, .red)
        let c = try byHand.intersect(aroundA, aroundB, .left)
        _ = try byHand.segment(c, a, .blue)
        _ = try byHand.segment(c, b, .red)
        // I.9 on the angle at C: its circle through A cuts CB at B, and I.1 on BA reuses both circles.
        _ = try byHand.circle(c, through: a, .green)
        let f = try byHand.intersect(aroundB, aroundA, .left)
        _ = try byHand.segment(f, b, .blue)
        _ = try byHand.segment(f, a, .red)
        let cf = try byHand.segment(c, f, .amber)
        _ = try byHand.intersect(cf, CurveID(raw: 0), .only)

        #expect(viaTools.points == byHand.points)
        #expect(viaTools.curves.map(\.curve) == byHand.curves.map(\.curve))
        #expect(Array(viaTools.history.prefix(2)) == [.macro("I.1", inputs: [a, b]), .macro("I.9", inputs: [c, a, b])],
                "each tool use is one step in the history")
    }

    @Test("A macro on an accepted proposition, or with the wrong number of points, throws and changes nothing")
    func macroErrors() throws {
        var board = ConstructionBoard(givens: [.point("A", Vec2(x: 0, y: 0)), .point("B", Vec2(x: 1, y: 0))])
        let before = board
        #expect(throws: BoardError.notBuildable("I.4")) { try board.apply(.macro("I.4", inputs: [])) }
        #expect(throws: BoardError.wrongInputCount("I.9", expected: 3, got: 2)) {
            try board.apply(.macro("I.9", inputs: [PointID(raw: 0), PointID(raw: 1)]))
        }
        #expect(board == before)
    }

    // MARK: - Helpers

    private static func number(_ id: PropositionID) -> Int {
        Int(id.raw.split(separator: ".").last ?? "") ?? 0
    }

    private static func contains(_ board: ConstructionBoard, _ a: PointID, _ b: PointID, _ x: Vec2) -> Bool {
        guard let s0 = try? board.position(of: a), let s1 = try? board.position(of: b) else { return false }
        let d = s1 - s0
        let t = (x - s0).dot(d) / d.dot(d)
        return t > -1e-9 && t < 1 + 1e-9 && abs(d.cross(x - s0)) < 1e-9 * d.dot(d)
    }
}
