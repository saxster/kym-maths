import Foundation
import Testing
@testable import KymMaths

@Suite("Euclid workshop session")
struct EuclidWorkshopSessionTests {
    private static let root3 = 3.0.squareRoot()
    private static let reach = 0.2

    private static func session(_ id: PropositionID, tools: [PropositionID] = [], layer: BoardLayer = .byrne) throws -> EuclidWorkshopSession {
        let proposition = try #require(EuclidSpine.proposition(id))
        return try #require(EuclidWorkshopSession(proposition: proposition, tools: tools, layer: layer))
    }

    private static func tap(_ s: inout EuclidWorkshopSession, _ x: Double, _ y: Double) -> TapOutcome {
        s.tap(at: Vec2(x: x, y: y), tolerance: reach)
    }

    private static func circles(_ board: ConstructionBoard) -> [(Vec2, Double, ColorRole)] {
        board.curves.compactMap { curve in
            guard case let .circle(c, t) = curve.curve,
                  let pc = try? board.position(of: c), let pt = try? board.position(of: t) else { return nil }
            return (pc, pc.distance(to: pt), curve.role)
        }
    }

    // MARK: - Taps

    @Test("Two compass taps, centre then a point on the circle, draw that circle")
    func compassDrawsCircle() throws {
        var s = try Self.session("I.1")
        let a = try #require(s.givenNames["A"])
        #expect(Self.tap(&s, 0.05, -0.05) == .picked(a))
        #expect(s.tool == .compass(.awaitingRadius(a)))
        guard case .drew = Self.tap(&s, 3.9, 0.1) else { Issue.record("expected a circle"); return }

        let drawn = Self.circles(s.board)
        #expect(drawn.count == 1)
        #expect(drawn.first.map { $0.0 == Vec2(x: 0, y: 0) && abs($0.1 - 4) < 1e-12 } == true)
        #expect(drawn.first?.2 == .blue, "a curve on the scripted route keeps its Byrne colour")
        #expect(s.tool == .compass(.awaitingCentre))
    }

    @Test("Two straightedge taps join the points; a segment off the scripted route takes the next palette colour")
    func straightedgeDrawsSegment() throws {
        var s = try Self.session("I.11")
        s.choose(.straightedge)
        _ = Self.tap(&s, 3, 0)
        guard case let .drew(id) = Self.tap(&s, 8, 0) else { Issue.record("expected a segment"); return }
        let curve = s.board.curves[id.raw]
        let (c, b) = (try #require(s.givenNames["C"]), try #require(s.givenNames["B"]))
        #expect(curve.curve == .segment(c, b))
        #expect(curve.role == .red, "the first off-script stroke is red")
    }

    @Test("A tap on empty paper changes nothing and says why")
    func emptyPaper() throws {
        var s = try Self.session("I.1")
        let before = s.board
        #expect(Self.tap(&s, 2, 1) == .refused(.emptyPaper))
        #expect(s.board == before)
        #expect(s.tool == .compass(.awaitingCentre))
    }

    @Test("Tapping the held point again lets it go")
    func release() throws {
        var s = try Self.session("I.1")
        let a = try #require(s.givenNames["A"])
        _ = Self.tap(&s, 0, 0)
        #expect(Self.tap(&s, 0, 0) == .released(a))
        #expect(s.tool == .compass(.awaitingCentre) && s.board.history.isEmpty)
    }

    @Test("Tapping where two circles cross makes that crossing a point, and the tool takes it")
    func candidateMaterialises() throws {
        var s = try Self.session("I.1")
        _ = Self.tap(&s, 0, 0); _ = Self.tap(&s, 4, 0)
        _ = Self.tap(&s, 4, 0); _ = Self.tap(&s, 0, 0)
        let count = s.board.points.count

        guard case let .picked(apex) = Self.tap(&s, 2.05, 2 * Self.root3 - 0.05) else {
            Issue.record("the crossing should be picked"); return
        }
        #expect(s.board.points.count == count + 1)
        let point = s.board.points[apex.raw]
        #expect(point.position.distance(to: Vec2(x: 2, y: 2 * Self.root3)) < 1e-12)
        guard case .intersection = point.origin else { Issue.record("a crossing, not a free point"); return }
    }

    @Test("Solving I.1 by taps alone, on the given points and the circles' crossing, meets the goal")
    func solveI1ByTaps() throws {
        var s = try Self.session("I.1")
        let apex = (2.0, 2 * Self.root3)
        _ = Self.tap(&s, 0, 0); _ = Self.tap(&s, 4, 0)
        _ = Self.tap(&s, 4, 0); _ = Self.tap(&s, 0, 0)
        s.choose(.straightedge)
        _ = Self.tap(&s, apex.0, apex.1); _ = Self.tap(&s, 0, 0)
        #expect(!s.isSolved, "one side is still missing")
        #expect(!s.hasAttempted, "the proof stays hidden until she solves it or asks")
        _ = Self.tap(&s, apex.0, apex.1); _ = Self.tap(&s, 4, 0)

        #expect(s.isSolved)
        #expect(s.hasAttempted)
        #expect(s.earnedLevel == .picture)
        #expect(!s.isAssisted)
        #expect(s.board.curves.map(\.role) == [.ink, .blue, .red, .blue, .red], "her board has the proof's colours")
    }

    @Test("Solving in the Letters layer earns the letters level")
    func lettersLayer() throws {
        var s = try Self.session("I.1", layer: .letters)
        while !s.isSolved, s.board.history.count < 20 { s.requestHint() }
        #expect(s.earnedLevel == .letters)
        #expect(s.label(of: try #require(s.givenNames["A"])) == "A")
        let apex = try #require(s.board.point(at: Vec2(x: 2, y: 2 * Self.root3)))
        #expect(s.label(of: apex) == "C", "a constructed point takes the proposition's letter")
    }

    @Test("Undo removes the last move and puts the tool back to its first step")
    func undo() throws {
        var s = try Self.session("I.1")
        _ = Self.tap(&s, 0, 0); _ = Self.tap(&s, 4, 0)
        let oneCircle = s.board
        _ = Self.tap(&s, 4, 0); _ = Self.tap(&s, 0, 0)
        _ = Self.tap(&s, 2, 2 * Self.root3)
        #expect(s.board.history.count == 3)

        s.undo()
        #expect(s.board.history.count == 2, "the crossing is gone")
        #expect(s.tool == .compass(.awaitingCentre))
        s.undo()
        #expect(s.board == oneCircle)
        s.undo(); s.undo()
        #expect(s.board.history.isEmpty && s.board.curves.count == 1, "the given line stays")
    }

    @Test("Undo after a solve unsolves it")
    func undoUnsolves() throws {
        var s = try Self.session("I.1")
        while !s.isSolved, s.board.history.count < 20 { s.requestHint() }
        s.undo()
        #expect(!s.isSolved && s.earnedLevel == nil)
    }

    // MARK: - Hints

    @Test("R0 to R2 keep retrieval; R3 names the next step's postulate and marks the attempt assisted")
    func hintRungs() throws {
        var s = try Self.session("I.1")
        let i1 = try #require(EuclidSpine.proposition("I.1"))
        for (rung, text) in zip([HintLadderRung.r0AttentionRedirect, .r1PatternRedescription, .r2CandidateClass], i1.hints) {
            s.requestHint()
            #expect(s.hintRung == rung && s.hint?.text == text)
            #expect(!s.isAssisted)
        }
        s.requestHint()
        #expect(s.hintRung == .r3PropositionNamed)
        #expect(s.hint?.text == Justification.postulate(3).meaning, "the first move is a circle")
        #expect(s.isAssisted)
        s.requestHint()
        #expect(s.hint?.highlight == .ghostCircle(center: Vec2(x: 0, y: 0), radius: 4))
        #expect(s.board.history.isEmpty, "R4 only outlines")
    }

    @Test("R5 makes the next scripted move, in its Byrne colour, and the attempt stays assisted after undo")
    func workedStep() throws {
        var s = try Self.session("I.1")
        for _ in 0..<6 { s.requestHint() }
        #expect(s.hintRung == .r5WorkedStep)
        let drawn = Self.circles(s.board)
        #expect(drawn.count == 1 && drawn[0].0 == Vec2(x: 0, y: 0) && abs(drawn[0].1 - 4) < 1e-12 && drawn[0].2 == .blue)
        s.undo()
        #expect(s.isAssisted)
    }

    @Test("A move of her own drops the hint back to none, but not the assisted flag")
    func hintResetsOnMove() throws {
        var s = try Self.session("I.1")
        for _ in 0..<4 { s.requestHint() }
        _ = Self.tap(&s, 0, 0); _ = Self.tap(&s, 4, 0)
        #expect(s.hintRung == .none && s.hint == nil && s.isAssisted)
    }

    @Test("Pressing R5 over and over solves every proposition, with no tools and with every earlier one as a tool",
          arguments: ["I.1", "I.9", "I.10", "I.11", "I.46", "I.47"] as [PropositionID])
    func workedStepsSolve(_ id: PropositionID) throws {
        let earlier = EuclidSpine.catalog.filter {
            if case .built = $0.kind { true } else { false }
        }.map(\.id).prefix { $0 != id }
        for tools in [[], Array(earlier)] {
            var s = try Self.session(id, tools: tools)
            var presses = 0
            while !s.isSolved, presses < 600 {
                let before = s.board
                s.requestHint()
                presses += 1
                if s.hintRung == .r5WorkedStep {
                    #expect(s.board != before, "\(id) R5 made no move (tools \(tools))")
                    if s.board == before { return }
                }
            }
            #expect(s.isSolved, "\(id) with tools \(tools)")
            #expect(s.isAssisted)
        }
    }

    @Test("With I.1 and I.9 as tools, R5 on I.10 uses the I.1 tool as one step")
    func workedStepUsesTool() throws {
        var s = try Self.session("I.10", tools: ["I.1", "I.9"])
        for _ in 0..<6 { s.requestHint() }
        let (a, b) = (try #require(s.givenNames["A"]), try #require(s.givenNames["B"]))
        #expect(s.board.history == [.macro("I.1", inputs: [a, b])])
    }

    // MARK: - Tools

    @Test("Tools are the earlier built propositions she has proven; accepted facts and unproven ones are not")
    func toolsFromProgress() throws {
        var progress = EuclidProgress()
        #expect(EuclidWorkshopSession.tools(for: "I.10", progress: progress).isEmpty, "nothing proven yet")

        progress.record(.picture, for: "I.1", assisted: false)
        progress.record(.picture, for: "I.9", assisted: true)
        #expect(EuclidWorkshopSession.tools(for: "I.10", progress: progress) == ["I.1"], "an assisted attempt proves nothing")

        progress.record(.picture, for: "I.9", assisted: false)
        progress.record(.picture, for: "I.47", assisted: false)
        progress.record(.picture, for: "I.4", assisted: false)
        #expect(EuclidWorkshopSession.tools(for: "I.10", progress: progress) == ["I.1", "I.9"], "later and accepted ones stay off")
        #expect(EuclidWorkshopSession.tools(for: "I.1", progress: progress).isEmpty, "a proposition is never its own tool")
        #expect(EuclidWorkshopSession.tools(for: "I.4", progress: progress).isEmpty, "an accepted fact has no board")
    }

    @Test("Choosing a tool she has not proven does nothing")
    func unprovenToolIgnored() throws {
        var s = try Self.session("I.10", tools: ["I.1"])
        s.choose(.proposition("I.9"))
        #expect(s.tool.tool == .compass)
        s.choose(.proposition("I.1"))
        #expect(s.tool.tool == .proposition("I.1"))
    }

    @Test("A tool's circles and helper points are scaffolding; its result's sides are not, and undo forgets them")
    func toolScaffolding() throws {
        var s = try Self.session("I.10", tools: ["I.1"])
        for _ in 0..<6 { s.requestHint() }
        #expect(s.board.history.count == 1, "one I.1 step")
        let circles = s.board.curves.indices.filter { if case .circle = s.board.curves[$0].curve { true } else { false } }
        let segments = s.board.curves.indices.filter { if case .segment = s.board.curves[$0].curve { true } else { false } }
        #expect(circles.count == 2)
        #expect(Set(circles.map(CurveID.init(raw:))).isSubset(of: s.scaffolding.curves))
        let sides = segments.filter { !s.scaffolding.curves.contains(CurveID(raw: $0)) }
        #expect(sides.count == 3, "AB was given, and I.1 drew CA and CB")
        let apex = try #require(s.script.position(named: "C"))
        let apexID = try #require(s.board.point(at: apex))
        #expect(!s.scaffolding.points.contains(apexID), "the apex is the result")

        s.undo()
        #expect(s.scaffolding == .init())
    }

    @Test("I.46 as a tool keeps the square's sides, even where they lie along its longer helper lines")
    func squareSidesKept() throws {
        var s = try Self.session("I.47", tools: ["I.1", "I.9", "I.10", "I.11", "I.46"])
        s.playScript(moves: .max)
        #expect(s.isSolved)
        #expect(!s.scaffolding.spans.isEmpty, "the squares' upright sides lie along I.11's perpendiculars")
        // Every side of the three squares is drawn strongly: as a kept segment or as a span.
        let strong: [(Vec2, Vec2)] = s.board.curves.indices.compactMap { index in
            let id = CurveID(raw: index)
            if let ends = s.scaffolding.spans[id] {
                return (try? s.board.position(of: ends[0])).flatMap { a in (try? s.board.position(of: ends[1])).map { (a, $0) } }
            }
            guard !s.scaffolding.curves.contains(id), case let .segment(a, b) = s.board.curves[index].curve else { return nil }
            return (try? s.board.position(of: a)).flatMap { pa in (try? s.board.position(of: b)).map { (pa, $0) } }
        }
        func covered(_ p: String, _ q: String) throws -> Bool {
            let (a, b) = (try #require(s.script.position(named: p)), try #require(s.script.position(named: q)))
            return strong.contains { u, v in
                let along = v - u
                func on(_ w: Vec2) -> Bool {
                    let t = (w - u).dot(along) / along.dot(along)
                    return abs(along.cross(w - u)) < 1e-6 * along.length && t > -1e-9 && t < 1 + 1e-9
                }
                return on(a) && on(b)
            }
        }
        for (p, q) in [("B", "D"), ("D", "E"), ("E", "C"), ("A", "G"), ("G", "F"), ("F", "B"), ("A", "H"), ("H", "K"), ("K", "C")] {
            #expect(try covered(p, q), "\(p)\(q) drawn")
        }
    }

    @Test("A curve she draws herself is never scaffolding")
    func ownCurvesNotScaffolding() throws {
        var s = try Self.session("I.1")
        _ = Self.tap(&s, 0, 0); _ = Self.tap(&s, 4, 0)
        #expect(s.scaffolding.curves.isEmpty && s.scaffolding.points.isEmpty)
    }

    // MARK: - Proof

    @Test("Opening the proof needs a first try, and before a solve it counts as help")
    func revealProof() throws {
        var s = try Self.session("I.1")
        s.revealProof()
        #expect(!s.hasAttempted, "nothing tried yet")
        _ = Self.tap(&s, 0, 0); _ = Self.tap(&s, 4, 0)
        s.revealProof()
        #expect(s.hasAttempted && s.isAssisted)
    }

    @Test("A proof glyph highlights its part where the scripted figure has it")
    func glyphHighlight() throws {
        let s = try Self.session("I.1")
        guard case let .segment(p, q, role)? = s.highlight(for: .segment("C", "A", .blue)) else {
            Issue.record("expected a segment highlight"); return
        }
        #expect(p.distance(to: Vec2(x: 2, y: 2 * Self.root3)) < 1e-12 && q == Vec2(x: 0, y: 0) && role == .blue)
        #expect(s.highlight(for: .circle(center: "B", .red)) == .circle(center: Vec2(x: 4, y: 0), radius: 4, .red))
        #expect(s.highlight(for: .text("so")) == nil)
    }

    // MARK: - Status line

    @Test("The status line prompts for the tool until the board is solved, then says nothing")
    func promptStopsWhenSolved() throws {
        var s = try Self.session("I.1")
        #expect(s.status == BoardStatus(kind: .info, text: "Compass: tap the point for the centre."))
        while !s.isSolved, s.board.history.count < 20 { s.requestHint() }
        #expect(s.isSolved)
        #expect(s.prompt == nil && s.status == nil)
    }

    @Test("A refused tap reads as a refusal until a hint, a tool or an undo makes it stale")
    func refusalClears() throws {
        var s = try Self.session("I.1")
        _ = Self.tap(&s, 2, 1)
        #expect(s.status?.kind == .refusal)
        s.requestHint()
        #expect(s.status?.kind == .info, "the hint replaces the stale refusal")

        _ = Self.tap(&s, 2, 1)
        s.choose(.straightedge)
        #expect(s.status == BoardStatus(kind: .info, text: "Straightedge: tap the first point."))
    }

    @Test("A proposition tool that builds reads as a success, not a warning")
    func builtIsSuccess() throws {
        var s = try Self.session("I.10", tools: ["I.1"])
        s.choose(.proposition("I.1"))
        _ = Self.tap(&s, 0, 0)
        #expect(s.status?.kind == .info)
        #expect(Self.tap(&s, 7, 0) == .built("I.1"))
        #expect(s.status == BoardStatus(kind: .success, text: "I.1 built in one step."))
    }

    // MARK: - Reading the figure

    @Test("A given line that runs past the figure is split at the figure's own points")
    func givenSpans() throws {
        func spans(_ id: PropositionID) throws -> Set<Set<Vec2>> {
            Set(try Self.session(id).givenSpans.values.map { [$0.from, $0.to] })
        }
        let (a, b, c) = (Vec2(x: 1.8, y: 2.4), Vec2(x: 0, y: 0), Vec2(x: 5, y: 0))
        #expect(try spans("I.47") == [[b, c], [a, b], [a, c]], "the triangle itself, inside three longer lines")
        #expect(try spans("I.46") == [[Vec2(x: 0, y: 0), Vec2(x: 5, y: 0)]])
        for id: PropositionID in ["I.1", "I.9", "I.10", "I.11"] {
            #expect(try spans(id).isEmpty, "\(id)'s given lines end at its own points")
        }
    }

    @Test("Solved I.47 shows a plain figure: the triangle, three shaded squares, AL and the four joins, no circles")
    func cleanI47() throws {
        var s = try Self.session("I.47", tools: ["I.1", "I.9", "I.10", "I.11", "I.46"])
        #expect(s.cleanFigure == nil, "not before it is solved")
        s.playScript(moves: .max)
        let figure = try #require(s.cleanFigure)
        func at(_ name: String) throws -> Vec2 { try #require(s.script.position(named: name)) }
        let lettered = try Set(["A", "B", "C", "D", "E", "F", "G", "H", "K", "L", "M", "N"].map(at))
        for stroke in figure.strokes {
            #expect(lettered.contains(stroke.from) && lettered.contains(stroke.to), "no line runs past a lettered point")
        }
        func drawn(_ p: String, _ q: String) throws -> Bool {
            let ends: Set<Vec2> = [try at(p), try at(q)]
            return figure.strokes.contains { [$0.from, $0.to] == ends }
        }
        for (p, q) in [("B", "C"), ("A", "B"), ("A", "C"), ("A", "L"), ("A", "D"), ("F", "C"), ("A", "E"), ("B", "K"),
                       ("B", "D"), ("D", "E"), ("C", "E"), ("G", "F"), ("H", "K")] {
            #expect(try drawn(p, q), "\(p)\(q)")
        }
        #expect(figure.fills.map(\.role) == [.amber, .blue, .green])
        #expect(try figure.fills.first?.corners == ["B", "D", "E", "C"].map(at))

        s.showsConstructionLines = true
        #expect(s.cleanFigure == nil, "the toggle brings the construction back")
    }

    @Test("A proposition without a plain version keeps its arcs when solved")
    func noCleanFigureForI1() throws {
        var s = try Self.session("I.1")
        s.playScript(moves: .max)
        #expect(s.isSolved && !s.offersCleanFigure && s.cleanFigure == nil)
    }

    @Test("Each letter on solved I.10 sits away from every line that meets its point")
    func labelsClearLines() throws {
        var s = try Self.session("I.10", layer: .letters)
        s.playScript(moves: .max)
        for (index, point) in s.board.points.enumerated() {
            guard s.label(of: PointID(raw: index)) != nil else { continue }
            let direction = s.labelDirection(of: PointID(raw: index))
            for curve in s.board.curves {
                guard case let .segment(a, b) = curve.curve else { continue }
                let (pa, pb) = (try s.board.position(of: a), try s.board.position(of: b))
                for (from, to) in [(pa, pb), (pb, pa)] where from.distance(to: point.position) > 1e-6 {
                    let along = to - from
                    let t = (point.position - from).dot(along) / along.dot(along)
                    guard abs(along.cross(point.position - from)) < 1e-6 * along.length, t > -1e-6, t < 1 + 1e-6 else { continue }
                    let ray = from - point.position
                    let cosine = ray.dot(direction) / ray.length
                    #expect(cosine < cos(.pi / 6), "\(s.label(of: PointID(raw: index)) ?? "") clears its lines")
                }
            }
        }
        let d = try #require(s.board.point(at: Vec2(x: 3.5, y: 0)))
        #expect(s.label(of: d) == "D")
    }

    @Test("A point no line meets takes its letter straight out from the middle")
    func labelFallsBackToRadial() {
        let direction = EuclidWorkshopSession.labelDirection(at: Vec2(x: 3, y: 4), lines: [], outFrom: Vec2(x: 0, y: 0))
        #expect(abs(direction.x - 0.6) < 1e-12 && abs(direction.y - 0.8) < 1e-12)
    }
}
