import Foundation
import Testing
@testable import KymMaths

@Suite("Motif spine")
struct MotifSpineTests {
    private static let close = 1e-6

    // MARK: - The graph

    @Test("Every id is listed once, five motifs then four composites")
    func ids() {
        let ids = MotifSpine.catalog.map(\.id)
        #expect(Set(ids).count == ids.count)
        #expect(ids == ["M1", "M2", "M3", "M4", "M5", "C1", "C2", "C3", "C4"])
        #expect(MotifSpine.catalog.filter { $0.layer == .motif }.count == 5)
    }

    @Test("Everything a motif stands on exists: other motifs here, propositions in the Euclid spine")
    func foundationsExist() {
        for motif in MotifSpine.catalog {
            #expect(!motif.standsOn.isEmpty, "\(motif.id) stands on nothing")
            for foundation in motif.standsOn {
                switch foundation {
                case let .motif(id):
                    #expect(MotifSpine.motif(id) != nil, "\(motif.id) stands on the missing \(id)")
                case let .proposition(id):
                    #expect(EuclidSpine.proposition(id) != nil, "\(motif.id) stands on \(id), not in the Euclid spine")
                case .prototype:
                    break
                }
            }
        }
    }

    @Test("Standing on other motifs never loops")
    func noLoops() {
        var visiting: Set<MotifID> = [], done: Set<MotifID> = []
        func visit(_ id: MotifID) -> Bool {
            if done.contains(id) { return true }
            guard visiting.insert(id).inserted, let motif = MotifSpine.motif(id) else { return false }
            let ok = motif.standsOn.allSatisfy { foundation in
                if case let .motif(next) = foundation { visit(next) } else { true }
            }
            done.insert(id)
            return ok
        }
        for motif in MotifSpine.catalog {
            #expect(visit(motif.id), "a loop runs through \(motif.id)")
        }
    }

    @Test("Every motif unlocks a composite or leads to a chapter")
    func noDeadEnds() {
        for motif in MotifSpine.catalog where motif.layer == .motif {
            let composites = motif.unlocks.compactMap(MotifSpine.motif).filter { $0.layer == .composite }
            #expect(!composites.isEmpty || !motif.chapterUnlocks.isEmpty, "\(motif.id) leads nowhere")
        }
        #expect(MotifSpine.motif("M1")?.unlocks == ["C1"])
    }

    @Test("Composites stand on at least one motif; only motifs carry a break switch and a knows-when problem")
    func layers() {
        for motif in MotifSpine.catalog {
            switch motif.layer {
            case .composite:
                #expect(motif.standsOn.contains { if case .motif = $0 { true } else { false } }, "\(motif.id)")
                #expect(motif.breakSwitch == nil && motif.knowsWhen == nil, "\(motif.id)")
            case .motif:
                #expect(motif.breakSwitch != nil && motif.knowsWhen != nil && motif.whyItMatters != nil, "\(motif.id)")
            }
        }
    }

    // MARK: - The figures measure the checks

    @Test("Every figure measures its givens and its answer", arguments: MotifSpine.catalog.map(\.id))
    func figureMeasuresCheck(_ id: MotifID) throws {
        let scene = try #require(MotifSpine.motif(id)).scene
        let figure = scene.figure
        for quantity in scene.givens + scene.goal {
            let measured = try #require(figure.measure(quantity.item), "\(id): \(quantity.item.name) is not measurable")
            #expect(abs(measured - quantity.value) < Self.close, "\(id): \(quantity.item.name) measures \(measured), not \(quantity.value)")
            let isAngle = if case .angle = quantity.item { true } else { false }
            #expect(isAngle == (quantity.unit == .degrees), "\(id): \(quantity.item.name) has the wrong unit")
        }
        #expect(!scene.goal.isEmpty)
    }

    @Test("Every letter the question, figure, givens and goal name is a point of the figure", arguments: MotifSpine.catalog.map(\.id))
    func namesExist(_ id: MotifID) throws {
        let scene = try #require(MotifSpine.motif(id)).scene
        let figure = scene.figure
        let items = scene.question.flatMap(\.lights) + scene.givens.map(\.item) + scene.goal.map(\.item)
            + figure.twins.flatMap { [$0.helper, $0.twin] }
        let lines = figure.segments + figure.parallels + figure.helpers
        for name in items.flatMap(\.pointNames) + lines.flatMap(\.self) {
            #expect(figure.points[name] != nil, "\(id) names \(name), which the figure lacks")
        }
        #expect(lines.allSatisfy { $0.count == 2 }, "\(id): every line is a pair")
        for phrase in scene.question where phrase.role != .plain {
            #expect(!phrase.lights.isEmpty, "\(id): \"\(phrase.text)\" lights nothing")
        }
        #expect(scene.question.contains { $0.role == .goal })
    }

    @Test("Lines marked parallel are parallel", arguments: MotifSpine.catalog.map(\.id))
    func parallelsAreParallel(_ id: MotifID) throws {
        let figure = try #require(MotifSpine.motif(id)).scene.figure
        let directions = figure.parallels.map { pair in (figure.points[pair[1]]! - figure.points[pair[0]]!).unit }
        for direction in directions.dropFirst() {
            #expect(abs(direction.cross(directions[0])) < Self.close, "\(id)")
        }
    }

    // MARK: - M1, the M-shape

    private static let mShape = MotifScene.mShape

    private static func figure(_ e: Vec2?, broken: Bool = false) -> MotifFigure {
        mShape.build(MotifState(free: e, broken: broken))
    }

    private static func rule(_ figure: MotifFigure) throws -> MotifRule {
        let rule = try #require(mShape.rule)
        return rule(figure)
    }

    @Test("The rule ∠B + ∠D = ∠E holds at the check and wherever E is dragged inside the M-shape",
          arguments: [nil, Vec2(x: -2, y: 1), Vec2(x: 1.5, y: 3.2), Vec2(x: -1, y: 0.8)])
    func ruleHolds(_ e: Vec2?) throws {
        let figure = Self.figure(e)
        let rule = try Self.rule(figure)
        #expect(rule.holds, "∠B + ∠D = \(rule.lhs), ∠E = \(rule.rhs)")
        #expect(abs(rule.lhs - rule.rhs) < Self.close)
        if let e { #expect(figure.points["E"]!.distance(to: e) < 0.2, "a legal E stays near where she put it") }
        for twin in figure.twins {
            #expect(abs(figure.measure(twin.helper)! - figure.measure(twin.twin)!) < Self.close, "the helper line copies \(twin.twin.name)")
        }
    }

    @Test("Dragging E keeps B and D still and re-measures the angles as whole degrees")
    func dragReMeasures() {
        let check = Self.figure(nil), moved = Self.figure(Vec2(x: -2, y: 1))
        #expect(check.points["B"] == moved.points["B"] && check.points["D"] == moved.points["D"])
        let abe = moved.angle("A", "B", "E"), cde = moved.angle("C", "D", "E")
        #expect(abs(abe - 40) > 1 && abs(cde - 35) > 1, "the givens change: \(abe), \(cde)")
        #expect(abs(abe - abe.rounded()) < Self.close && abs(cde - cde.rounded()) < Self.close)
    }

    @Test("With CD tilted the rule fails, and the parallel arrows go")
    func breakSwitch() throws {
        for e in [nil, Vec2(x: -2, y: 1), Vec2(x: 1.5, y: 3.2)] {
            let figure = Self.figure(e, broken: true)
            let rule = try Self.rule(figure)
            #expect(!rule.holds && abs(rule.lhs - rule.rhs) > 1, "∠B + ∠D = \(rule.lhs), ∠E = \(rule.rhs)")
            #expect(figure.parallels.isEmpty)
        }
        #expect(!Self.figure(nil).parallels.isEmpty)
    }

    @Test("Dragging E out of the M-shape clamps it, so the figure stays an M-shape",
          arguments: [Vec2(x: 10, y: 10), Vec2(x: -10, y: -10), Vec2(x: 5, y: 2), Vec2(x: 0, y: 4), Vec2(x: 0, y: 0), Vec2(x: 2.4, y: 3.9)])
    func clamps(_ pulled: Vec2) throws {
        let figure = Self.figure(pulled)
        let (a, b, d, e) = (figure.points["A"]!, figure.points["B"]!, figure.points["D"]!, figure.points["E"]!)
        #expect(e.y > d.y + 0.4 && e.y < b.y - 0.4, "E stays strictly between the lines: \(e)")
        #expect(e.x < min(b.x, d.x) - 0.4 && e.x > a.x, "the bend still opens away from A and C: \(e)")
        #expect(try Self.rule(figure).holds)
    }
}
