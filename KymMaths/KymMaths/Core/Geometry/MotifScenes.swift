import Foundation

/// Each motif's figure, built from the check's numbers. The answers are only ever measured.
extension MotifScene {
    static let mShape: MotifScene = {
        let abe = 40.0, cde = 35.0
        return MotifScene(
            question: [
                .given("AB is parallel to CD.", .segment("A", "B"), .segment("C", "D")),
                .given("E is between them, and the bend points toward A and C.",
                       .point("E"), .segment("B", "E"), .segment("E", "D")),
                .given("∠ABE = \(degrees(abe))", .angle("A", "B", "E")),
                QuestionPhrase(text: "and"),
                .given("∠CDE = \(degrees(cde)).", .angle("C", "D", "E")),
                .goal("Find ∠BED.", .angle("B", "E", "D")),
            ],
            givens: [.degrees(.angle("A", "B", "E"), abe), .degrees(.angle("C", "D", "E"), cde)],
            goal: [.degrees(.angle("B", "E", "D"), 75)],
            freePoint: "E",
            condition: "AB parallel to CD",
            build: { MShape.figure(abe: abe, cde: cde, state: $0) },
            rule: { figure in
                MotifRule(lhsLabel: "∠B + ∠D", lhs: figure.angle("A", "B", "E") + figure.angle("C", "D", "E"),
                          rhsLabel: "∠E", rhs: figure.angle("B", "E", "D"))
            }
        )
    }()

    static let xShape: MotifScene = {
        let oab = 70.0, oba = 40.0, ocd = 60.0
        return MotifScene(
            question: [
                .given("AC and BD cross at O.", .segment("A", "C"), .segment("B", "D"), .point("O")),
                .given("In △AOB, ∠A = \(degrees(oab))", .angle("O", "A", "B")),
                .given("and ∠B = \(degrees(oba)).", .angle("O", "B", "A")),
                .given("In △COD, ∠C = \(degrees(ocd)).", .angle("O", "C", "D")),
                .goal("Find ∠D.", .angle("O", "D", "C")),
            ],
            givens: [.degrees(.angle("O", "A", "B"), oab), .degrees(.angle("O", "B", "A"), oba), .degrees(.angle("O", "C", "D"), ocd)],
            goal: [.degrees(.angle("O", "D", "C"), 50)],
            freePoint: "D",
            condition: "AC straight",
            build: { XShape.figure(oab: oab, oba: oba, ocd: ocd, state: $0) },
            rule: { figure in
                let top = figure.angle("A", "O", "B"), bottom = figure.angle("C", "O", "D")
                return MotifRule(
                    lhsLabel: "∠A + ∠B", lhs: figure.angle("O", "A", "B") + figure.angle("O", "B", "A"),
                    rhsLabel: "∠C + ∠D", rhs: figure.angle("O", "C", "D") + figure.angle("O", "D", "C"),
                    note: abs(top - bottom) < 0.5
                        ? "The angles at O are vertically opposite: ∠AOB = ∠COD = \(degrees(top.rounded()))."
                        : "AC bends at O, so the angles there differ: ∠AOB = \(degrees(top.rounded())), ∠COD = \(degrees(bottom.rounded()))."
                )
            }
        )
    }()

    static let dart: MotifScene = {
        let bac = 50.0, abd = 20.0, acd = 30.0
        return MotifScene(
            question: [
                .given("ABDC is an arrowhead: D sits inside angle A.", .point("D"), .segment("B", "D"), .segment("D", "C")),
                .given("∠A = \(degrees(bac)),", .angle("B", "A", "C")),
                .given("∠ABD = \(degrees(abd))", .angle("A", "B", "D")),
                QuestionPhrase(text: "and"),
                .given("∠ACD = \(degrees(acd)).", .angle("A", "C", "D")),
                .goal("Find ∠BDC.", .angle("B", "D", "C")),
            ],
            givens: [.degrees(.angle("B", "A", "C"), bac), .degrees(.angle("A", "B", "D"), abd), .degrees(.angle("A", "C", "D"), acd)],
            goal: [.degrees(.angle("B", "D", "C"), 100)],
            freePoint: "D",
            condition: "D inside angle A",
            build: { Dart.figure(bac: bac, abd: abd, acd: acd, state: $0) },
            rule: { figure in
                let notch = figure.angle("B", "D", "C")
                let others = figure.angle("B", "A", "C") + figure.angle("A", "B", "D") + figure.angle("A", "C", "D")
                return MotifRule(
                    lhsLabel: "∠BDC", lhs: notch, rhsLabel: "∠A + ∠ABD + ∠ACD", rhs: others,
                    note: abs(notch - others) < 0.5
                        ? nil
                        : "ABDC is not a dart now. It is convex, so its four angles add to \(degrees((notch + others).rounded())) instead."
                )
            }
        )
    }()

    static let bisectorParallel: MotifScene = {
        let be = 4.0
        return MotifScene(
            question: [
                .given("BD bisects ∠ABC.", .angle("A", "B", "D"), .angle("D", "B", "C")),
                .given("DE is parallel to BC, with E on AB.", .segment("D", "E"), .segment("B", "C"), .point("E")),
                .given("BE = \(be.formatted()) cm.", .segment("B", "E")),
                .goal("Find DE.", .segment("D", "E")),
            ],
            givens: [.centimetres(.segment("B", "E"), be)],
            goal: [.centimetres(.segment("D", "E"), 4)],
            freePoint: "A",
            condition: "DE parallel to BC",
            build: { BisectorParallel.figure(be: be, state: $0) },
            rule: { figure in
                MotifRule(lhsLabel: "BE", lhs: figure.length("B", "E"), rhsLabel: "DE", rhs: figure.length("D", "E"), unit: .centimetres)
            }
        )
    }()

    static let aShape: MotifScene = {
        let ad = 3.0, ab = 5.0, bc = 10.0
        return MotifScene(
            question: [
                .given("DE is parallel to BC,", .segment("D", "E"), .segment("B", "C")),
                .given("with D on AB and E on AC.", .point("D"), .point("E")),
                .given("AD = \(ad.formatted()),", .segment("A", "D")),
                .given("AB = \(ab.formatted())", .segment("A", "B")),
                QuestionPhrase(text: "and"),
                .given("BC = \(bc.formatted()).", .segment("B", "C")),
                .goal("Find DE.", .segment("D", "E")),
            ],
            givens: [.length(.segment("A", "D"), ad), .length(.segment("A", "B"), ab), .length(.segment("B", "C"), bc)],
            goal: [.length(.segment("D", "E"), 6)],
            freePoint: "D",
            condition: "DE parallel to BC",
            build: { AShape.figure(ad: ad, ab: ab, bc: bc, state: $0) },
            rule: { figure in
                MotifRule(lhsLabel: "AD/AB", lhs: figure.length("A", "D") / figure.length("A", "B"),
                          rhsLabel: "DE/BC", rhs: figure.length("D", "E") / figure.length("B", "C"), unit: .ratio)
            }
        )
    }()

    static let bentPathIsosceles: MotifScene = {
        let abe = 40.0, bed = 80.0
        return MotifScene(
            question: [
                .given("AB is parallel to CD, and E is between them.", .segment("A", "B"), .segment("C", "D"), .point("E")),
                .given("∠ABE = \(degrees(abe))", .angle("A", "B", "E")),
                QuestionPhrase(text: "and"),
                .given("∠BED = \(degrees(bed)).", .angle("B", "E", "D")),
                .given("G is on DC with DG = DE.", .point("G"), .segment("D", "G"), .segment("D", "E")),
                .goal("Find ∠CDE", .angle("C", "D", "E")),
                .goal("and ∠DEG.", .angle("D", "E", "G")),
            ],
            givens: [.degrees(.angle("A", "B", "E"), abe), .degrees(.angle("B", "E", "D"), bed)],
            goal: [.degrees(.angle("C", "D", "E"), 40), .degrees(.angle("D", "E", "G"), 70)],
            build: { _ in
                let e = Vec2(x: 0, y: 2)
                let a = Vec2(x: -3, y: 4), c = Vec2(x: -3, y: 0)
                let b = Vec2.meet(e, .heading(abe), a, .heading(0))
                let d = Vec2.meet(e, .heading(abe - bed), c, .heading(0))
                let g = d + d.distance(to: e) * (c - d).unit
                return MotifFigure(points: ["A": a, "B": b, "C": c, "D": d, "E": e, "G": g],
                                   segments: [["A", "B"], ["C", "D"], ["B", "E"], ["E", "D"], ["E", "G"]],
                                   parallels: [["A", "B"], ["C", "D"]])
            }
        )
    }()

    static let star: MotifScene = {
        let tips: [String: Double] = ["A": 30, "B": 40, "C": 35, "D": 45]
        return MotifScene(
            question: [
                .given("A five-point star's tips are \(degrees(tips["A"]!)),", .angle("D", "A", "C")),
                .given("\(degrees(tips["B"]!)),", .angle("E", "B", "D")),
                .given("\(degrees(tips["C"]!))", .angle("A", "C", "E")),
                QuestionPhrase(text: "and"),
                .given("\(degrees(tips["D"]!)).", .angle("B", "D", "A")),
                .goal("Find the fifth tip.", .angle("C", "E", "B")),
            ],
            givens: [.degrees(.angle("D", "A", "C"), tips["A"]!), .degrees(.angle("E", "B", "D"), tips["B"]!),
                     .degrees(.angle("A", "C", "E"), tips["C"]!), .degrees(.angle("B", "D", "A"), tips["D"]!)],
            goal: [.degrees(.angle("C", "E", "B"), 30)],
            build: { _ in
                // The star is the walk E → B → D → A → C → E with every edge touching one circle.
                // Each tip turns the walk by 180° minus the tip; the turn at E is whatever closes it.
                var headings = [90.0]
                for tip in ["B", "D", "A", "C"] { headings.append(headings.last! + 180 - tips[tip]!) }
                let edges = headings.map { (through: Vec2.heading($0 - 90), along: Vec2.heading($0)) }
                func corner(_ i: Int, _ j: Int) -> Vec2 { .meet(edges[i].through, edges[i].along, edges[j].through, edges[j].along) }
                return MotifFigure(points: ["B": corner(0, 1), "D": corner(1, 2), "A": corner(2, 3), "C": corner(3, 4), "E": corner(4, 0)],
                                   segments: [["E", "B"], ["B", "D"], ["D", "A"], ["A", "C"], ["C", "E"]])
            }
        )
    }()

    static let twoBisectors: MotifScene = {
        let bac = 60.0
        return MotifScene(
            question: [
                .given("In △ABC, the bisectors of ∠B and ∠C meet at I.", .segment("B", "I"), .segment("C", "I"), .point("I")),
                .given("∠A = \(degrees(bac)).", .angle("B", "A", "C")),
                .goal("Find ∠BIC.", .angle("B", "I", "C")),
            ],
            givens: [.degrees(.angle("B", "A", "C"), bac)],
            goal: [.degrees(.angle("B", "I", "C"), 120)],
            build: { _ in
                let a = Vec2(x: 0, y: 4)
                let b = a + 5 * .heading(-90 - bac / 2), c = a + 7 * .heading(-90 + bac / 2)
                let i = Vec2.meet(b, (a - b).unit + (c - b).unit, c, (a - c).unit + (b - c).unit)
                return MotifFigure(points: ["A": a, "B": b, "C": c, "I": i],
                                   segments: [["A", "B"], ["B", "C"], ["C", "A"], ["B", "I"], ["C", "I"]])
            }
        )
    }()

    static let parallelogramBisector: MotifScene = {
        let ab = 5.0, ad = 8.0
        return MotifScene(
            question: [
                .given("In parallelogram ABCD,", .segment("A", "B"), .segment("B", "C"), .segment("C", "D"), .segment("D", "A")),
                .given("AB = \(ab.formatted()) cm", .segment("A", "B")),
                QuestionPhrase(text: "and"),
                .given("AD = \(ad.formatted()) cm.", .segment("A", "D")),
                .given("The bisector of ∠A meets BC at E.", .segment("A", "E"), .point("E")),
                .goal("Find BE", .segment("B", "E")),
                .goal("and EC.", .segment("E", "C")),
            ],
            givens: [.centimetres(.segment("A", "B"), ab), .centimetres(.segment("A", "D"), ad)],
            goal: [.centimetres(.segment("B", "E"), 5), .centimetres(.segment("E", "C"), 3)],
            build: { _ in
                let dab = 60.0
                let a = Vec2(x: 0, y: 0), d = Vec2(x: ad, y: 0), b = ab * Vec2.heading(dab)
                let c = b + d
                let e = Vec2.meet(a, .heading(dab / 2), b, d - a)
                return MotifFigure(points: ["A": a, "B": b, "C": c, "D": d, "E": e],
                                   segments: [["A", "B"], ["B", "C"], ["C", "D"], ["D", "A"], ["A", "E"]],
                                   parallels: [["A", "D"], ["B", "C"]])
            }
        )
    }()

    private static func degrees(_ value: Double) -> String { "\(value.formatted())°" }
}

/// How far a line turns when a break switch knocks it off: enough to see, and enough to move the rule well off.
private let breakTurn = 12.0

/// A whole number of degrees, kept to a range.
private func wholeDegrees(_ value: Double, _ range: ClosedRange<Double>) -> Double {
    min(max(value.rounded(), range.lowerBound), range.upperBound)
}

/// The M-shape: AB along the top line, CD along the bottom, and E between them with B and D to its right.
/// B and D stay put while she drags E; E snaps so ∠ABE and ∠CDE are whole degrees, which keeps the
/// readout's sum honest when she adds the labels in her head.
private enum MShape {
    static let top = 4.0
    static let left = -3.0
    static let start = Vec2(x: 0, y: 2)
    static let margin = 0.5
    static func figure(abe: Double, cde: Double, state: MotifState) -> MotifFigure {
        let b = Vec2.meet(start, .heading(abe), Vec2(x: 0, y: top), .heading(0))
        let d = Vec2.meet(start, .heading(-cde), Vec2(x: 0, y: 0), .heading(0))
        let a = Vec2(x: left, y: top), straightC = Vec2(x: left, y: 0)
        let e = state.free.map { snapped(clamped($0, b: b, d: d), b: b, d: d) } ?? start
        let c = state.broken ? straightC.rotated(by: breakTurn, about: d) : straightC
        let reach = max(b.x, d.x) + 0.8
        return MotifFigure(
            points: ["A": a, "B": b, "C": c, "D": d, "E": e, "F": Vec2(x: left, y: e.y), "G": Vec2(x: reach, y: e.y)],
            segments: [["A", "B"], ["C", "D"], ["B", "E"], ["E", "D"]],
            parallels: state.broken ? [] : [["A", "B"], ["C", "D"]],
            helpers: [["F", "G"]],
            twins: [AngleTwin(helper: .angle("B", "E", "G"), twin: .angle("A", "B", "E")),
                    AngleTwin(helper: .angle("G", "E", "D"), twin: .angle("C", "D", "E"))]
        )
    }

    /// Strictly between the lines, and left of B and D, so the bend still points toward A and C.
    static func clamped(_ p: Vec2, b: Vec2, d: Vec2) -> Vec2 {
        Vec2(x: min(max(p.x, left + margin), min(b.x, d.x) - margin),
             y: min(max(p.y, margin), top - margin))
    }

    /// The whole-degree point nearest `p` that is still inside the clamp, so dropping E where it landed leaves it there.
    static func snapped(_ p: Vec2, b: Vec2, d: Vec2) -> Vec2 {
        let west = Vec2(x: -1, y: 0)
        let atB = (acos((p - b).unit.dot(west)) * 180 / .pi).rounded()
        let atD = (acos((p - d).unit.dot(west)) * 180 / .pi).rounded()
        let grid = [-1.0, 0, 1].flatMap { i in [-1.0, 0, 1].map { j in
            Vec2.meet(b, .heading(180 + atB + i), d, .heading(180 - atD - j))
        } }
        let inside = grid.filter { clamped($0, b: b, d: d).distance(to: $0) < 1e-9 }
        return inside.min { $0.distance(to: p) < $1.distance(to: p) } ?? grid[4]
    }
}

/// The X-shape: AB along the top, AC and BD crossing at O, and CD closing the bottom triangle.
/// A, B and C stay put while she drags D. D snaps so ∠B and ∠C are whole degrees; with ∠A fixed,
/// every angle in both triangles is then whole and the two sums in the readout match the labels.
private enum XShape {
    static let a = Vec2(x: -2, y: 2), b = Vec2(x: 2, y: 2)

    static func figure(oab: Double, oba: Double, ocd: Double, state: MotifState) -> MotifFigure {
        let towardC = Vec2.heading(-oab)
        let c = Vec2.meet(a, towardC, b, .heading(180 + oba)) + 2.4 * towardC
        let (atB, atC) = state.free.map { clamped(atB: (a - b).turn(to: $0 - b), atC: (a - c).turn(to: $0 - c)) } ?? (oba, ocd)
        let d = Vec2.meet(b, (a - b).turned(atB), c, (a - c).turned(atC))
        let o = Vec2.meet(a, towardC, b, d - b)
        let bent = state.broken ? c.rotated(by: breakTurn, about: o) : c
        return MotifFigure(
            points: ["A": a, "B": b, "C": bent, "D": d, "O": o],
            segments: (state.broken ? [["A", "O"], ["O", "C"]] : [["A", "C"]]) + [["B", "D"], ["A", "B"], ["C", "D"]]
        )
    }

    /// ∠B keeps O between A and C; ∠C keeps ∠D between 45° and 80°, so the bottom triangle never
    /// flattens or runs off the board.
    static func clamped(atB: Double, atC: Double) -> (Double, Double) {
        let b = wholeDegrees(atB, 30...50)
        return (b, wholeDegrees(atC, max(35, b - 10)...(b + 25)))
    }
}

/// The dart: A at the tip, B and C at the back corners, and D in the notch. A, B and C stay put while
/// she drags D. D snaps so ∠ABD and ∠ACD are whole degrees, and stays strictly inside the triangle.
/// The break switch mirrors D across BC, which makes ABDC convex.
private enum Dart {
    static let abc = 55.0
    static let margin = 15.0
    /// The widest the notch opens, so D never lies flat on BC.
    static let widest = 150.0

    static func figure(bac: Double, abd: Double, acd: Double, state: MotifState) -> MotifFigure {
        let a = Vec2(x: 0, y: 0), b = a + 6 * .heading(bac / 2)
        let c = Vec2.meet(a, .heading(-bac / 2), b, (a - b).turned(abc))
        let acb = 180 - bac - abc
        let (atB, atC) = state.free.map { p in
            let atB = wholeDegrees((a - b).turn(to: p - b), margin...(abc - margin))
            return (atB, wholeDegrees(-(a - c).turn(to: p - c), margin...min(acb - margin, widest - bac - atB)))
        } ?? (abd, acd)
        let towardD = (a - b).turned(atB)
        let inside = Vec2.meet(b, towardD, c, (a - c).turned(-atC))
        guard !state.broken else {
            return MotifFigure(points: ["A": a, "B": b, "C": c, "D": inside.reflected(across: b, c)],
                               segments: [["A", "B"], ["B", "D"], ["D", "C"], ["C", "A"]])
        }
        return MotifFigure(points: ["A": a, "B": b, "C": c, "D": inside, "E": Vec2.meet(b, towardD, a, c - a)],
                           segments: [["A", "B"], ["B", "D"], ["D", "C"], ["C", "A"]],
                           helpers: [["D", "E"]])
    }
}

/// The bisector and the parallel: B at the corner, BC along the bottom, and A she can drag to open or
/// close ∠ABC. D is where the bisector meets AC, and E is where the line through D parallel to BC
/// meets AB. The board is scaled so BE is the check's length at the check.
private enum BisectorParallel {
    static let b = Vec2(x: 0, y: 0)
    static let abc = 70.0

    static func figure(be: Double, state: MotifState) -> MotifFigure {
        let k = be / corners(a: 7 * .heading(abc), c: Vec2(x: 8, y: 0), tilt: 0).e.length
        let c = Vec2(x: 8 * k, y: 0)
        let a = state.free.map { p in
            min(max(p.length, 5 * k), 8.5 * k) * .heading(min(max(p.heading, 40), 110))
        } ?? 7 * k * .heading(abc)
        let (d, e) = corners(a: a, c: c, tilt: state.broken ? breakTurn : 0)
        return MotifFigure(points: ["A": a, "B": b, "C": c, "D": d, "E": e],
                           segments: [["A", "B"], ["B", "C"], ["C", "A"], ["B", "D"], ["D", "E"]],
                           parallels: state.broken ? [] : [["E", "D"], ["B", "C"]])
    }

    static func corners(a: Vec2, c: Vec2, tilt: Double) -> (d: Vec2, e: Vec2) {
        let d = Vec2.meet(b, .heading(a.heading / 2), a, c - a)
        return (d, Vec2.meet(d, .heading(tilt), b, a - b))
    }
}

/// The A-shape: A at the top, BC along the bottom, and D she slides along AB. E is where the line
/// through D parallel to BC meets AC. AD snaps to tenths, so AD/AB is exact to two places.
private enum AShape {
    static let side = Vec2.heading(-105)

    static func figure(ad: Double, ab: Double, bc: Double, state: MotifState) -> MotifFigure {
        let a = Vec2(x: 0, y: 0), b = a + ab * side
        let c = b + bc * .heading(0)
        let along = state.free.map { min(max((($0 - a).dot(side) * 10).rounded() / 10, 1), ab - 0.5) } ?? ad
        let d = a + along * side
        let e = Vec2.meet(d, .heading(state.broken ? breakTurn : 0), a, c - a)
        return MotifFigure(points: ["A": a, "B": b, "C": c, "D": d, "E": e],
                           segments: [["A", "B"], ["A", "C"], ["B", "C"], ["D", "E"]],
                           parallels: state.broken ? [] : [["D", "E"], ["B", "C"]])
    }
}
