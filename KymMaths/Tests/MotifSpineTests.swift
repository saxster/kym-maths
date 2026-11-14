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

@Suite("Playable motifs")
struct PlayableMotifTests {
    private static let close = 1e-6

    static let draggable: [MotifID] = MotifSpine.catalog.filter { $0.scene.freePoint != nil }.map(\.id)

    /// Where she might put the free point inside each motif's legal region, as offsets from where it starts.
    /// The A-shape's D slides along AB, so its offsets run along AB.
    static let legalNudges: [MotifID: [Vec2]] = [
        "M1": [Vec2(x: -2, y: -1), Vec2(x: 1.5, y: 1.2), Vec2(x: -1, y: -1.2)],
        "M2": [Vec2(x: 0.15, y: 0.1), Vec2(x: -0.15, y: 0.15), Vec2(x: 0.1, y: -0.1)],
        "M3": [Vec2(x: 0.4, y: 0.2), Vec2(x: -0.5, y: 0), Vec2(x: 0.3, y: -0.4)],
        "M4": [Vec2(x: 0.5, y: 0.3), Vec2(x: -0.6, y: -1.2), Vec2(x: 1.2, y: 0.6)],
        "M5": [-1.6 * Vec2.heading(-105), -0.8 * Vec2.heading(-105), 1.2 * Vec2.heading(-105)],
    ]

    /// Pulls from far off the board down to close around the figure.
    static let pulls: [Vec2] = stride(from: -30.0, through: 30, by: 2.5).flatMap { x in
        stride(from: -30.0, through: 30, by: 2.5).map { Vec2(x: x, y: $0) }
    } + stride(from: -6.0, through: 6, by: 0.4).flatMap { x in
        stride(from: -6.0, through: 6, by: 0.4).map { Vec2(x: x, y: $0) }
    }

    private static func scene(_ id: MotifID) throws -> MotifScene {
        try #require(MotifSpine.motif(id)).scene
    }

    private static func rule(_ scene: MotifScene, _ state: MotifState) throws -> MotifRule {
        let rule = try #require(scene.rule)
        return rule(scene.build(state))
    }

    private static func legalStates(_ id: MotifID) throws -> [MotifState] {
        let scene = try scene(id)
        let home = try #require(scene.figure.points[scene.freePoint ?? ""])
        return try #require(legalNudges[id]).map { MotifState(free: home + $0) }
    }

    @Test("Every playable motif has a free point, a rule and a break switch, and every motif is playable")
    func playable() throws {
        for motif in MotifSpine.catalog {
            #expect(MotifSpine.playable.contains(motif.id) == (motif.layer == .motif), "\(motif.id)")
        }
        for id in MotifSpine.playable {
            let scene = try Self.scene(id)
            #expect(scene.freePoint != nil && scene.rule != nil && scene.condition != nil, "\(id)")
        }
    }

    @Test("The rule holds at the check and wherever the free point goes inside the motif", arguments: draggable)
    func ruleHolds(_ id: MotifID) throws {
        let scene = try Self.scene(id)
        let free = try #require(scene.freePoint)
        #expect(try Self.rule(scene, scene.state).holds, "\(id) at the check")
        for state in try Self.legalStates(id) {
            let figure = scene.build(state)
            let rule = try Self.rule(scene, state)
            #expect(rule.holds && abs(rule.lhs - rule.rhs) < Self.close, "\(id) at \(state.free!): \(rule.lhs) vs \(rule.rhs)")
            #expect(figure.points[free]!.distance(to: state.free!) < 0.2, "\(id): a legal \(free) stays near where she put it")
            let moved = (scene.givens + scene.goal).contains { abs(figure.measure($0.item)! - scene.figure.measure($0.item)!) > $0.unit.tolerance }
            #expect(moved, "\(id): dragging \(free) changes what the board measures")
        }
    }

    @Test("Pulling the free point anywhere keeps the rule, keeps the figure whole, and stays on the board", arguments: draggable)
    func clamps(_ id: MotifID) throws {
        let scene = try Self.scene(id)
        let extent = scene.extent
        let inset = 0.3
        for pull in Self.pulls {
            let figure = scene.build(MotifState(free: pull))
            let rule = try Self.rule(scene, MotifState(free: pull))
            #expect(rule.holds, "\(id) pulled to \(pull): \(rule.lhs) vs \(rule.rhs)")
            for (name, p) in figure.points {
                #expect(p.x > extent.min.x + inset && p.x < extent.max.x - inset && p.y > extent.min.y + inset && p.y < extent.max.y - inset,
                        "\(id) pulled to \(pull): \(name) at \(p) leaves the board")
            }
            let points = Array(figure.points.values)
            for i in points.indices { for j in points.indices where j > i {
                #expect(points[i].distance(to: points[j]) > 0.3, "\(id) pulled to \(pull): two points nearly meet at \(points[i])")
            } }
            for quantity in scene.givens + scene.goal {
                guard case .angle = quantity.item else { continue }
                let angle = figure.measure(quantity.item)!
                #expect(angle > 5 && angle < 175, "\(id) pulled to \(pull): \(quantity.item.name) = \(angle)")
            }
        }
    }

    @Test("The readout adds up from the board's labels: angles are whole degrees, and equal sides read the same", arguments: draggable)
    func honestReadout(_ id: MotifID) throws {
        let scene = try Self.scene(id)
        for pull in Self.pulls {
            let figure = scene.build(MotifState(free: pull))
            let rule = try Self.rule(scene, MotifState(free: pull))
            #expect(rule.unit.label(rule.lhs) == rule.unit.label(rule.rhs), "\(id) pulled to \(pull)")
            guard rule.unit == .degrees else { continue }
            for quantity in scene.givens + scene.goal {
                let angle = figure.measure(quantity.item)!
                #expect(abs(angle - angle.rounded()) < Self.close, "\(id) pulled to \(pull): \(quantity.item.name) = \(angle)")
            }
        }
    }

    @Test("Dropping the free point where it landed leaves the figure as it is", arguments: draggable)
    func dropIsStable(_ id: MotifID) throws {
        let scene = try Self.scene(id)
        let free = try #require(scene.freePoint)
        for broken in [false, true] {
            for pull in Self.pulls {
                let state = MotifState(free: pull, broken: broken)
                guard scene.canDrag(state) else { continue }
                let landed = scene.build(state)
                let dropped = scene.build(MotifState(free: landed.points[free], broken: broken))
                for (name, p) in landed.points {
                    #expect(p.distance(to: dropped.points[name]!) < Self.close, "\(id) broken \(broken), pulled to \(pull): \(name) moves")
                }
            }
        }
    }

    @Test("With the break switch on, the rule fails by a clear margin and the parallel arrows go", arguments: draggable)
    func breakSwitch(_ id: MotifID) throws {
        let scene = try Self.scene(id)
        let states = [scene.state] + (try Self.legalStates(id)) + Self.pulls.map { MotifState(free: $0) }
        for state in states {
            let broken = MotifState(free: state.free, broken: true)
            let rule = try Self.rule(scene, broken)
            #expect(!rule.holds && abs(rule.lhs - rule.rhs) > 5 * rule.unit.tolerance,
                    "\(id) broken at \(String(describing: state.free)): \(rule.lhs) vs \(rule.rhs)")
            #expect(scene.build(broken).parallels.isEmpty, "\(id)")
        }
    }

    @Test("Bending AC at O splits the angles there, and the note says so")
    func xShapeBends() throws {
        let scene = try Self.scene("M2")
        let straight = scene.figure, bent = scene.build(MotifState(broken: true))
        #expect(abs(straight.angle("A", "O", "B") - straight.angle("C", "O", "D")) < Self.close)
        #expect(abs(bent.angle("A", "O", "B") - bent.angle("C", "O", "D")) > 10)
        #expect(try Self.rule(scene, MotifState(broken: true)).note?.contains("∠COD") == true)
    }

    @Test("Breaking the dart moves D outside the triangle and stops the drag; the four angles then add to 360°")
    func dartTurnsConvex() throws {
        let scene = try Self.scene("M3")
        for state in [scene.state] + (try Self.legalStates("M3")) {
            let broken = MotifState(free: state.free, broken: true)
            let figure = scene.build(broken)
            let (a, b, c, d) = (figure.points["A"]!, figure.points["B"]!, figure.points["C"]!, figure.points["D"]!)
            #expect((c - b).cross(d - b) * (c - b).cross(a - b) < 0, "D is across BC from A")
            let sum = figure.angle("B", "A", "C") + figure.angle("A", "B", "D") + figure.angle("B", "D", "C") + figure.angle("A", "C", "D")
            #expect(abs(sum - 360) < Self.close)
            #expect(try Self.rule(scene, broken).note?.contains("360°") == true)
            #expect(!scene.canDrag(broken))
            #expect(scene.canDrag(state))
        }
    }

    @Test("Length answers carry their unit: the bisector check in cm, the A-shape without one")
    func lengthUnits() throws {
        #expect(try Self.scene("M4").goal.map(\.unit) == [.centimetres])
        #expect(try Self.scene("M5").goal.map(\.unit) == [.length])
        #expect(try Self.rule(Self.scene("M4"), MotifState()).unit == .centimetres)
        #expect(try Self.rule(Self.scene("M5"), MotifState()).unit == .ratio)
        #expect(QuantityUnit.centimetres.reading(4) == "4 cm")
        #expect(QuantityUnit.ratio.reading(0.6) == "0.60")
    }
}

@Suite("Motif progress")
struct MotifProgressTests {
    @Test("A right answer with the helper line shown first is marked as help and does not solve the motif")
    func assisted() {
        var progress = MotifProgress()
        #expect(progress.recordPicture(for: "M1", assisted: true) == .assisted)
        #expect(progress.record(for: "M1") == MotifRecord(solved: false, assisted: true, parentChecked: false))
        #expect(progress.recordPicture(for: "M1", assisted: false) == .advanced(to: .picture))
        #expect(progress.record(for: "M1") == MotifRecord(solved: true, assisted: false, parentChecked: false))
        #expect(progress.recordPicture(for: "M1", assisted: false) == .notNext, "already solved")
    }

    @Test("Progress survives a save and a load through UserDefaults")
    func roundTrip() throws {
        let suite = "motif-progress-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = MotifProgressStore(defaults: defaults)
        #expect(store.load() == MotifProgress(), "nothing saved yet")

        var progress = MotifProgress()
        progress.recordPicture(for: "M1", assisted: false)
        progress.setParentChecked(true, for: "M1")
        progress.recordPicture(for: "M2", assisted: true)
        store.save(progress)

        let loaded = MotifProgressStore(defaults: defaults).load()
        #expect(loaded == progress)
        #expect(loaded.record(for: "M1") == MotifRecord(solved: true, assisted: false, parentChecked: true))
        #expect(loaded.record(for: "M2").assisted)
        #expect(defaults.data(forKey: "kymmaths.motif.progress") != nil)
    }
}
