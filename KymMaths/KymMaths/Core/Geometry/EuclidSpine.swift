import Foundation

/// A proposition of Euclid's Elements by book and number, as Heath writes it: "I.47".
struct PropositionID: Hashable, Codable, ExpressibleByStringLiteral, CustomStringConvertible {
    let raw: String

    init(_ raw: String) { self.raw = raw }
    init(stringLiteral value: String) { self.raw = value }

    var description: String { raw }
}

/// Book I's postulates, common notions and definitions keep Heath's numbering.
enum Justification: Hashable {
    case postulate(Int)
    case commonNotion(Int)
    case definition(Int)
    case proposition(PropositionID)

    var label: String {
        switch self {
        case let .postulate(n): "Post. \(n)"
        case let .commonNotion(n): "C.N. \(n)"
        case let .definition(n): "Def. \(n)"
        case let .proposition(id): id.raw
        }
    }

    /// Heath's wording, shortened. Only the ones a proof in the catalog cites.
    var meaning: String {
        switch self {
        case .postulate(1): "Postulate 1: any two points can be joined by a straight line."
        case .postulate(3): "Postulate 3: a circle can be drawn with any centre, through any point."
        case .postulate(4): "Postulate 4: all right angles are equal."
        case .commonNotion(1): "Common Notion 1: things equal to the same thing are equal to each other."
        case .commonNotion(2): "Common Notion 2: equals added to equals give equals."
        case .definition(10): "Definition 10: when a line stands on another and makes equal angles side by side, each is a right angle."
        case .definition(15): "Definition 15: every radius of a circle is the same length."
        case .definition(20): "Definition 20: an equilateral triangle has three equal sides."
        case .definition(22): "Definition 22: a square has four equal sides and four right angles."
        case let .proposition(id): EuclidSpine.proposition(id).map { "\(id): \($0.title)" } ?? id.raw
        default: label
        }
    }
}

/// A piece of a Byrne-style claim. Parts name the construction's points; the Byrne view draws
/// them as coloured glyphs and hides the letters, which the Letters layer shows again.
enum ClaimToken: Hashable {
    case text(String)
    case segment(String, String, ColorRole)
    case angle(String, String, String, ColorRole)
    case circle(center: String, ColorRole)
    /// A triangle, square or parallelogram, named by its corners in order.
    case region([String], ColorRole)
}

struct ProofStep: Hashable {
    let claim: [ClaimToken]
    let because: Justification
}

/// A proposition Kym builds, or one the spine leans on and her school teaches.
enum PropositionKind {
    case built(Construction)
    case accepted(taughtIn: String)
}

struct Construction {
    let givens: [Given]
    /// The scripted solution, and the body of the proposition's macro. Takes the given points by name
    /// and returns every named point, in the proposition's own lettering.
    let construct: (inout ConstructionBoard, [String: PointID]) throws -> [String: PointID]
    let goal: Goal
    /// What to tap when the proposition is used as a tool.
    let inputPrompt: String

    var givenPointNames: [String] {
        givens.compactMap { given in
            if case let .point(name, _) = given { name } else { nil }
        }
    }

    /// The scripted solution, run on a fresh board of the givens.
    func build() throws -> (board: ConstructionBoard, names: [String: PointID]) {
        var board = ConstructionBoard(givens: givens)
        let given = try Dictionary(uniqueKeysWithValues: givenPointNames.map { name in
            guard let id = board.pointID(named: name) else { throw BoardError.unknownName(name) }
            return (name, id)
        })
        let names = try construct(&board, given)
        return (board, names)
    }
}

/// The task she does on paper with a real compass, with the answer a parent checks.
struct DeviceOffCheck: Hashable {
    let task: String
    let answer: String
}

/// A word problem with no figure. She knows the skill when she names the proposition that solves it.
struct KnowsWhenPrompt: Hashable {
    let problem: String
    let answer: PropositionID
}

struct EuclidProposition {
    let id: PropositionID
    let title: String
    /// Plain English, for a 12-year-old.
    let statement: String
    let kind: PropositionKind
    /// What the proof cites. The proof is for this app's construction, which can differ from Euclid's.
    let uses: [PropositionID]
    let proofSteps: [ProofStep]
    let deviceOffCheck: DeviceOffCheck
    let knowsWhen: KnowsWhenPrompt?
    /// The KymMaths chapter this skill pays off in.
    let leadsToChapter: String?
    /// Hint rungs R0–R2, which keep retrieval intact, so they name no letters and no proposition.
    var hints: [String] = []

    /// The propositions whose proofs cite this one. Derived from `uses`, so the two never disagree.
    var unlocks: [PropositionID] {
        EuclidSpine.catalog.filter { $0.uses.contains(id) }.map(\.id)
    }
}

/// Book I as a dependency graph, from the equilateral triangle to Pythagoras.
/// docs/EUCLID_SPINE.md is the readable version; when the two disagree, this file wins.
enum EuclidSpine {
    static let catalog: [EuclidProposition] = [
        i1, i9, i10, i11, i46, i47,
        i4, i8, i14, i28, i33, i34, i41,
    ]

    static func proposition(_ id: PropositionID) -> EuclidProposition? {
        byID[id]
    }

    private static let byID = Dictionary(catalog.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

    private static func degrees(_ d: Double) -> Double { d * .pi / 180 }

    // MARK: - Built

    static let i1 = EuclidProposition(
        id: "I.1",
        title: "Equilateral triangle",
        statement: "On a given line, build a triangle with all three sides equal.",
        kind: .built(Construction(
            givens: [.point("A", Vec2(x: 0, y: 0)), .point("B", Vec2(x: 4, y: 0)), .segment("A", "B")],
            construct: { board, n in
                let (a, b) = (try n.point("A"), try n.point("B"))
                let aroundA = try board.circle(a, through: b, .blue)
                let aroundB = try board.circle(b, through: a, .red)
                let c = try board.intersect(aroundA, aroundB, .left)
                _ = try board.segment(c, a, .blue)
                _ = try board.segment(c, b, .red)
                return ["A": a, "B": b, "C": c]
            },
            goal: .equilateralTriangle(on: "A", "B"),
            inputPrompt: "Tap the two ends of the base. The triangle goes on the left as you walk from the first to the second."
        )),
        uses: [],
        proofSteps: [
            ProofStep(claim: [.segment("C", "A", .blue), .text("="), .segment("A", "B", .ink),
                              .text(": both are radii of"), .circle(center: "A", .blue)],
                      because: .definition(15)),
            ProofStep(claim: [.segment("C", "B", .red), .text("="), .segment("B", "A", .ink),
                              .text(": both are radii of"), .circle(center: "B", .red)],
                      because: .definition(15)),
            ProofStep(claim: [.segment("C", "A", .blue), .text("="), .segment("C", "B", .red),
                              .text(": both equal"), .segment("A", "B", .ink)],
                      because: .commonNotion(1)),
            ProofStep(claim: [.text("All three sides are equal, so"), .region(["A", "B", "C"], .amber),
                              .text("is equilateral")],
                      because: .definition(20)),
        ],
        deviceOffCheck: DeviceOffCheck(
            task: "On paper, with a real compass, build an equilateral triangle on a 6 cm line. Measure all three sides.",
            answer: "All three sides are 6 cm."
        ),
        knowsWhen: KnowsWhenPrompt(
            problem: "Three friends want to stand so that each one is the same distance from the other two. Two are already standing. Where does the third go?",
            answer: "I.1"
        ),
        leadsToChapter: nil,
        hints: [
            "The third corner must be exactly one line-length from each end of the line.",
            "Every point one line-length from an end lies on a circle around that end.",
            "Two circles, one around each end, cross where both distances are right.",
        ]
    )

    static let i9 = EuclidProposition(
        id: "I.9",
        title: "Bisect an angle",
        statement: "Cut a given angle exactly in half.",
        kind: .built(Construction(
            givens: [
                .point("A", Vec2(x: 0, y: 0)),
                .point("B", Vec2(x: 4, y: 0)),
                .point("C", Vec2(x: 6 * cos(degrees(70)), y: 6 * sin(degrees(70)))),
                .segment("A", "B"),
                .segment("A", "C"),
            ],
            construct: { board, n in
                let (a, b, c) = (try n.point("A"), try n.point("B"), try n.point("C"))
                // Euclid takes D anywhere on AB and copies AD onto AC with I.3. A circle centred at
                // the vertex does both: D is B itself, and E is where the circle cuts AC.
                let d = b
                let aroundA = try board.circle(a, through: d, .green)
                let e = try board.intersect(aroundA, try board.segment(a, c, .ink), .nearer)
                let (pa, pd, pe) = (try board.position(of: a), try board.position(of: d), try board.position(of: e))
                // I.1 puts its apex left of the line it is given; order D and E so the apex lands away from A.
                let base = (pe - pd).cross(pa - pd) > 0 ? [e, d] : [d, e]
                let f = try board.use("I.1", base).point("C")
                _ = try board.segment(a, f, .amber)
                return ["A": a, "B": b, "C": c, "D": d, "E": e, "F": f]
            },
            goal: .bisectAngle(vertex: "A", arms: "B", "C"),
            inputPrompt: "Tap the corner of the angle, then one point on each arm."
        )),
        uses: ["I.1", "I.8"],
        proofSteps: [
            ProofStep(claim: [.segment("A", "D", .ink), .text("="), .segment("A", "E", .ink),
                              .text(": both are radii of"), .circle(center: "A", .green)],
                      because: .definition(15)),
            ProofStep(claim: [.segment("D", "F", .red), .text("="), .segment("E", "F", .blue),
                              .text(": two sides of an equilateral triangle")],
                      because: .proposition("I.1")),
            ProofStep(claim: [.text("The two triangles share"), .segment("A", "F", .amber),
                              .text(", so"), .angle("D", "A", "F", .red), .text("="), .angle("E", "A", "F", .blue),
                              .text(":"), .segment("A", "F", .amber), .text("cuts the angle in half")],
                      because: .proposition("I.8")),
        ],
        deviceOffCheck: DeviceOffCheck(
            task: "Draw a 70° angle. Bisect it with a compass and a ruler, then measure each half.",
            answer: "Each half is 35°."
        ),
        knowsWhen: KnowsWhenPrompt(
            problem: "A path starts at the corner of a field and must stay the same distance from both walls. Which way does it run?",
            answer: "I.9"
        ),
        leadsToChapter: nil,
        hints: [
            "Find two points, one on each arm, the same distance from the corner.",
            "A circle around the corner cuts both arms at the same distance.",
            "An equilateral triangle on those two cut points has its far corner on the halfway line.",
        ]
    )

    static let i10 = EuclidProposition(
        id: "I.10",
        title: "Bisect a segment",
        statement: "Cut a given line exactly in half.",
        kind: .built(Construction(
            givens: [.point("A", Vec2(x: 0, y: 0)), .point("B", Vec2(x: 7, y: 0)), .segment("A", "B")],
            construct: { board, n in
                let (a, b) = (try n.point("A"), try n.point("B"))
                let c = try board.use("I.1", [a, b]).point("C")
                let f = try board.use("I.9", [c, a, b]).point("F")
                let d = try board.intersect(try board.segment(c, f, .amber), try board.segment(a, b, .ink), .only)
                return ["A": a, "B": b, "C": c, "D": d]
            },
            goal: .bisectSegment("A", "B"),
            inputPrompt: "Tap the two ends of the segment."
        )),
        uses: ["I.1", "I.9", "I.4"],
        proofSteps: [
            ProofStep(claim: [.segment("A", "C", .blue), .text("="), .segment("C", "B", .red),
                              .text(": two sides of an equilateral triangle")],
                      because: .proposition("I.1")),
            ProofStep(claim: [.angle("A", "C", "D", .red), .text("="), .angle("B", "C", "D", .blue),
                              .text(":"), .segment("C", "D", .amber), .text("cuts the angle in half")],
                      because: .proposition("I.9")),
            ProofStep(claim: [.text("The two triangles share"), .segment("C", "D", .amber),
                              .text(", so"), .segment("A", "D", .ink), .text("="), .segment("D", "B", .ink)],
                      because: .proposition("I.4")),
        ],
        deviceOffCheck: DeviceOffCheck(
            task: "Draw a 7 cm line. Find its midpoint with a compass. Measure both halves and the angle where the two lines cross.",
            answer: "Each half is 3.5 cm, and the lines cross at 90°."
        ),
        knowsWhen: KnowsWhenPrompt(
            problem: "Where can a well go so that it is the same distance from two villages?",
            answer: "I.10"
        ),
        leadsToChapter: "ch09",
        hints: [
            "The midpoint is the same distance from both ends. So is every point on one special line.",
            "The top corner of an equilateral triangle on the segment is the same distance from both ends.",
            "Halve the angle at that top corner. The halving line crosses the segment at its midpoint.",
        ]
    )

    static let i11 = EuclidProposition(
        id: "I.11",
        title: "Perpendicular at a point",
        statement: "From a point on a line, draw a second line at right angles to it.",
        kind: .built(Construction(
            givens: [
                .point("A", Vec2(x: 0, y: 0)),
                .point("B", Vec2(x: 8, y: 0)),
                .point("C", Vec2(x: 3, y: 0)),
                .segment("A", "B"),
            ],
            construct: { board, n in
                let (a, b, c) = (try n.point("A"), try n.point("B"), try n.point("C"))
                let (pa, pb, pc) = (try board.position(of: a), try board.position(of: b), try board.position(of: c))
                // Euclid takes D anywhere on the line. The nearer end is a point already on the board,
                // and the circle through it cuts the line again inside the segment.
                let d = pc.distance(to: pa) <= pc.distance(to: pb) ? a : b
                let aroundC = try board.circle(c, through: d, .green)
                let e = try board.intersect(aroundC, try board.segment(a, b, .ink), awayFrom: d)
                // Ordered along A→B, so I.1's apex, and the perpendicular, land left of A→B.
                let f = try board.use("I.1", d == a ? [d, e] : [e, d]).point("C")
                _ = try board.segment(c, f, .amber)
                return ["A": a, "B": b, "C": c, "D": d, "E": e, "F": f]
            },
            goal: .perpendicularAt(point: "C", onSegment: "A", "B"),
            inputPrompt: "Tap both ends of the line, then the point on it. The right angle opens to the left of first → second."
        )),
        uses: ["I.1", "I.8"],
        proofSteps: [
            ProofStep(claim: [.segment("C", "D", .ink), .text("="), .segment("C", "E", .ink),
                              .text(": both are radii of"), .circle(center: "C", .green)],
                      because: .definition(15)),
            ProofStep(claim: [.segment("D", "F", .blue), .text("="), .segment("E", "F", .red),
                              .text(": two sides of an equilateral triangle")],
                      because: .proposition("I.1")),
            ProofStep(claim: [.text("The two triangles share"), .segment("C", "F", .amber),
                              .text(", so"), .angle("D", "C", "F", .red), .text("="), .angle("E", "C", "F", .blue)],
                      because: .proposition("I.8")),
            ProofStep(claim: [.text("Equal angles side by side on a line are right angles, so"),
                              .segment("C", "F", .amber), .text("is at right angles to"), .segment("A", "B", .ink)],
                      because: .definition(10)),
        ],
        deviceOffCheck: DeviceOffCheck(
            task: "Draw a line and mark a point on it. Without a protractor, draw a line through the point at right angles. Check it with a set square.",
            answer: "The set square fits: the angle is 90°."
        ),
        knowsWhen: KnowsWhenPrompt(
            problem: "A flagpole must stand at right angles to a straight path, at one marked spot. How do you set it out with only a rope and two pegs?",
            answer: "I.11"
        ),
        leadsToChapter: nil,
        hints: [
            "Find two points on the line, the same distance either side of the marked point.",
            "A circle around the marked point cuts the line at two such points.",
            "An equilateral triangle on those two points has its top corner straight above the marked point.",
        ]
    )

    static let i46 = EuclidProposition(
        id: "I.46",
        title: "Square on a segment",
        statement: "On a given line, build a square.",
        kind: .built(Construction(
            // The board has no Postulate 2, so the given line runs past A and B, far enough for I.11 at each end.
            givens: [
                .point("P", Vec2(x: -3.5, y: 0)),
                .point("A", Vec2(x: 0, y: 0)),
                .point("B", Vec2(x: 5, y: 0)),
                .point("Q", Vec2(x: 8.5, y: 0)),
                .segment("P", "Q"),
            ],
            construct: { board, n in
                let (p, a, b, q) = (try n.point("P"), try n.point("A"), try n.point("B"), try n.point("Q"))
                let upFromA = try board.segment(a, board.use("I.11", [p, q, a]).point("F"), .amber)
                let upFromB = try board.segment(b, board.use("I.11", [p, q, b]).point("F"), .amber)
                let d = try board.intersect(try board.circle(a, through: b, .blue), upFromA, .nearer)
                let e = try board.intersect(try board.circle(b, through: a, .red), upFromB, .nearer)
                _ = try board.segment(d, e, .green)
                return ["P": p, "A": a, "B": b, "Q": q, "D": d, "E": e]
            },
            goal: .squareOn(side: "A", "B"),
            inputPrompt: "Tap four points along one line: an end of the line, the two corners of the side, the other end. The square goes on the left."
        )),
        uses: ["I.11", "I.28", "I.33", "I.34"],
        proofSteps: [
            ProofStep(claim: [.segment("A", "D", .amber), .text("="), .segment("A", "B", .ink),
                              .text(": both are radii of"), .circle(center: "A", .blue)],
                      because: .definition(15)),
            ProofStep(claim: [.segment("B", "E", .amber), .text("="), .segment("B", "A", .ink),
                              .text(": both are radii of"), .circle(center: "B", .red)],
                      because: .definition(15)),
            ProofStep(claim: [.angle("D", "A", "B", .red), .text("and"), .angle("E", "B", "A", .blue),
                              .text("are right angles")],
                      because: .proposition("I.11")),
            ProofStep(claim: [.text("Together they make two right angles, so"), .segment("A", "D", .amber),
                              .text("is parallel to"), .segment("B", "E", .amber)],
                      because: .proposition("I.28")),
            ProofStep(claim: [.segment("A", "D", .amber), .text("and"), .segment("B", "E", .amber),
                              .text("are equal and parallel, so"), .segment("D", "E", .green),
                              .text("is equal and parallel to"), .segment("A", "B", .ink)],
                      because: .proposition("I.33")),
            ProofStep(claim: [.text("Opposite angles of a parallelogram are equal, so every angle of"),
                              .region(["A", "D", "E", "B"], .amber), .text("is a right angle")],
                      because: .proposition("I.34")),
            ProofStep(claim: [.text("Four equal sides and four right angles:"),
                              .region(["A", "D", "E", "B"], .amber), .text("is a square")],
                      because: .definition(22)),
        ],
        deviceOffCheck: DeviceOffCheck(
            task: "Build a square on a 5 cm line with a compass and a ruler. Measure a diagonal.",
            answer: "About 7.1 cm (5 × √2 ≈ 7.07)."
        ),
        knowsWhen: KnowsWhenPrompt(
            problem: "Mark out a square sandpit along one wall of the garden, with each side as long as the wall.",
            answer: "I.46"
        ),
        leadsToChapter: nil,
        hints: [
            "A square needs a right angle at each end of its side.",
            "Raise a line at right angles at each end of the side.",
            "Cut each upright to the side's length with a circle around its foot, then join the two tops.",
        ]
    )

    static let i47 = EuclidProposition(
        id: "I.47",
        title: "Pythagoras",
        statement: "In a right-angled triangle, the square on the longest side equals the squares on the other two sides added together.",
        kind: .built(Construction(
            // A 3-4-5 triangle with the right angle at A. Each side's given line runs on past its ends
            // (bc1 beyond B, bc2 beyond C, and so on) so I.46 can raise a square on it.
            givens: [
                .point("A", Vec2(x: 1.8, y: 2.4)),
                .point("B", Vec2(x: 0, y: 0)),
                .point("C", Vec2(x: 5, y: 0)),
                .point("bc1", Vec2(x: -3.5, y: 0)),
                .point("bc2", Vec2(x: 8.5, y: 0)),
                .point("ab1", Vec2(x: 3.06, y: 4.08)),
                .point("ab2", Vec2(x: -1.26, y: -1.68)),
                .point("ac1", Vec2(x: -0.44, y: 4.08)),
                .point("ac2", Vec2(x: 7.24, y: -1.68)),
                .segment("bc1", "bc2"),
                .segment("ab1", "ab2"),
                .segment("ac1", "ac2"),
            ],
            construct: { board, n in
                let (a, b, c) = (try n.point("A"), try n.point("B"), try n.point("C"))
                let (d, e) = try square(&board, on: b, c, line: (n.point("bc1"), n.point("bc2")), awayFrom: a)
                let (g, f) = try square(&board, on: a, b, line: (n.point("ab1"), n.point("ab2")), awayFrom: c)
                let (h, k) = try square(&board, on: a, c, line: (n.point("ac1"), n.point("ac2")), awayFrom: b)
                // Euclid draws AL parallel to BD with I.31. The board has no parallel tool, so AL is
                // dropped onto DE at right angles instead: a circle centred A cuts DE at D and N, and I.10 halves DN.
                let aroundA = try board.circle(a, through: d, .ink)
                let nPoint = try board.intersect(aroundA, try board.segment(d, e, .green), awayFrom: d)
                let l = try board.use("I.10", [d, nPoint]).point("D")
                let m = try board.intersect(
                    try board.segment(a, l, .amber),
                    try board.segment(n.point("bc1"), n.point("bc2"), .ink),
                    .only
                )
                _ = try board.segment(a, d, .red)
                _ = try board.segment(f, c, .red)
                _ = try board.segment(a, e, .blue)
                _ = try board.segment(b, k, .blue)
                return n.merging(["D": d, "E": e, "F": f, "G": g, "H": h, "K": k, "L": l, "M": m, "N": nPoint]) { $1 }
            },
            goal: .squaresOnRightTriangle(rightAngle: "A", "B", "C"),
            inputPrompt: "Tap the right-angled corner, the other two corners, then both far ends of each side's line."
        )),
        uses: ["I.46", "I.10", "I.8", "I.28", "I.14", "I.4", "I.41"],
        proofSteps: [
            ProofStep(claim: [.segment("D", "L", .green), .text("="), .segment("L", "N", .green),
                              .text(": the point halves"), .segment("D", "N", .green)],
                      because: .proposition("I.10")),
            ProofStep(claim: [.text("Both ends of"), .segment("D", "N", .green), .text("lie on"), .circle(center: "A", .ink),
                              .text(", so they are equally far from its centre, and the triangles share"),
                              .segment("A", "L", .amber), .text(", so"),
                              .angle("A", "L", "D", .red), .text("="), .angle("A", "L", "N", .blue)],
                      because: .proposition("I.8")),
            ProofStep(claim: [.text("Equal angles side by side are right angles, so"), .segment("A", "L", .amber),
                              .text("is at right angles to"), .segment("D", "E", .green)],
                      because: .definition(10)),
            ProofStep(claim: [.segment("B", "D", .amber), .text("is at right angles to"), .segment("D", "E", .green),
                              .text("too, so"), .segment("A", "L", .amber), .text("is parallel to"),
                              .segment("B", "D", .amber)],
                      because: .proposition("I.28")),
            ProofStep(claim: [.angle("B", "A", "C", .red), .text("and"), .angle("B", "A", "G", .blue),
                              .text("are right angles, so"), .segment("G", "A", .amber), .text("and"),
                              .segment("A", "C", .ink), .text("make one straight line")],
                      because: .proposition("I.14")),
            ProofStep(claim: [.angle("D", "B", "C", .red), .text("="), .angle("F", "B", "A", .blue),
                              .text(": both are right angles")],
                      because: .postulate(4)),
            ProofStep(claim: [.text("Add"), .angle("A", "B", "C", .green), .text("to each:"),
                              .angle("D", "B", "A", .red), .text("="), .angle("F", "B", "C", .blue)],
                      because: .commonNotion(2)),
            ProofStep(claim: [.segment("B", "D", .amber), .text("="), .segment("B", "C", .ink), .text("and"),
                              .segment("B", "A", .ink), .text("="), .segment("B", "F", .amber), .text(", so"),
                              .region(["A", "B", "D"], .red), .text("="), .region(["F", "B", "C"], .red)],
                      because: .proposition("I.4")),
            ProofStep(claim: [.region(["B", "D", "L", "M"], .blue), .text("is double"),
                              .region(["A", "B", "D"], .red), .text(": the same base"), .segment("B", "D", .amber),
                              .text(", between the parallels"), .segment("B", "D", .amber), .text("and"),
                              .segment("A", "L", .amber)],
                      because: .proposition("I.41")),
            ProofStep(claim: [.region(["A", "B", "F", "G"], .blue), .text("is double"),
                              .region(["F", "B", "C"], .red), .text(": the same base"), .segment("F", "B", .amber),
                              .text(", between the parallels"), .segment("F", "B", .amber),
                              .text("and the straight line"), .segment("G", "A", .amber), .segment("A", "C", .ink)],
                      because: .proposition("I.41")),
            ProofStep(claim: [.text("Both are double the same-sized triangle, so"),
                              .region(["B", "D", "L", "M"], .blue), .text("="), .region(["A", "B", "F", "G"], .blue)],
                      because: .commonNotion(1)),
            ProofStep(claim: [.text("In the same way, joining"), .segment("A", "E", .blue), .text("and"),
                              .segment("B", "K", .blue), .text(":"), .region(["C", "E", "L", "M"], .green),
                              .text("="), .region(["A", "C", "K", "H"], .green)],
                      because: .proposition("I.41")),
            ProofStep(claim: [.region(["B", "D", "E", "C"], .amber), .text("="),
                              .region(["B", "D", "L", "M"], .blue), .text("+"), .region(["C", "E", "L", "M"], .green),
                              .text("="), .region(["A", "B", "F", "G"], .blue), .text("+"),
                              .region(["A", "C", "K", "H"], .green)],
                      because: .commonNotion(2)),
        ],
        deviceOffCheck: DeviceOffCheck(
            task: "Sketch the three squares and say why the two small squares fill the big one. Then: a right triangle has shorter sides 5 and 12. How long is the longest side?",
            answer: "Each small square equals the rectangle below it in the big square. 25 + 144 = 169, so the longest side is 13."
        ),
        knowsWhen: KnowsWhenPrompt(
            problem: "A ladder is 13 m long and its foot is 5 m from the wall. How high up the wall does it reach?",
            answer: "I.47"
        ),
        leadsToChapter: "ch12",
        hints: [
            "Each side of the triangle needs its own square, on the side away from the triangle.",
            "The square tool builds on the left of its line, in the order you tap the four points.",
            "Walk along each side so the triangle is on your right, and tap the line's points in that order.",
        ]
    )

    /// I.46 on the side `u`–`v`, on the side away from `w`. `line` is the given line, its first end beyond `u`.
    /// Returns the square's new corners next to `u` and next to `v`.
    private static func square(
        _ board: inout ConstructionBoard,
        on u: PointID, _ v: PointID,
        line: (PointID, PointID),
        awayFrom w: PointID
    ) throws -> (PointID, PointID) {
        let (pu, pv, pw) = (try board.position(of: u), try board.position(of: v), try board.position(of: w))
        // I.46 builds on the left of its line, so when w is on the left, walk the line the other way.
        if (pv - pu).cross(pw - pu) > 0 {
            let corners = try board.use("I.46", [line.1, v, u, line.0])
            return (try corners.point("E"), try corners.point("D"))
        }
        let corners = try board.use("I.46", [line.0, u, v, line.1])
        return (try corners.point("D"), try corners.point("E"))
    }

    // MARK: - Accepted

    static let i4 = accepted(
        "I.4", "Side-angle-side",
        "If two triangles have two sides equal and the angle between those sides equal, they match exactly: the third sides, the other angles and the areas are equal too.",
        taughtIn: "OUP 3.4 Constructions (ch09)",
        check: DeviceOffCheck(
            task: "Draw a triangle with sides 5 cm and 7 cm and 40° between them. Measure the third side.",
            answer: "About 4.5 cm, and everyone who draws it gets the same."
        )
    )

    static let i8 = accepted(
        "I.8", "Side-side-side",
        "If two triangles have all three sides equal, their angles are equal too.",
        taughtIn: "OUP 3.4 Constructions (ch09)",
        check: DeviceOffCheck(
            task: "Draw a triangle with sides 3 cm, 4 cm and 5 cm. Measure the angle opposite the 5 cm side.",
            answer: "90°."
        )
    )

    static let i14 = accepted(
        "I.14", "Angles that make a straight line",
        "If two lines meet at a point on a third line, from opposite sides, and the two angles add up to two right angles, the two lines make one straight line.",
        taughtIn: "OUP 8.2 Angles in parallel and intersecting lines (ch08)",
        check: DeviceOffCheck(
            task: "Two lines meet a third at one point, from opposite sides, making angles of 130° and 50°. Do they make one straight line?",
            answer: "Yes: 130° + 50° = 180°."
        )
    )

    static let i28 = accepted(
        "I.28", "Co-interior angles make parallels",
        "If a line crosses two other lines and the two inside angles on one side add up to two right angles, the two lines are parallel.",
        taughtIn: "OUP 8.2 Angles in parallel and intersecting lines (ch08)",
        check: DeviceOffCheck(
            task: "A line crosses two others. The inside angles on one side are 115° and 65°. Are the two lines parallel?",
            answer: "Yes: 115° + 65° = 180°."
        )
    )

    static let i33 = accepted(
        "I.33", "Equal parallels make a parallelogram",
        "Join the ends of two equal, parallel lines on the same side, and the joining lines are equal and parallel too.",
        taughtIn: "OUP 3.1 Quadrilaterals (ch09)",
        check: DeviceOffCheck(
            task: "Draw two parallel 5 cm lines, one above the other, and join their ends on the same side. Measure the two joining lines.",
            answer: "They are equal, and parallel: the shape is a parallelogram."
        )
    )

    static let i34 = accepted(
        "I.34", "Parallelogram sides and angles",
        "In a parallelogram, opposite sides are equal, opposite angles are equal, and a diagonal cuts it into two equal halves.",
        taughtIn: "OUP 3.1 Quadrilaterals (ch09)",
        check: DeviceOffCheck(
            task: "A parallelogram has sides 6 cm and 4 cm and one angle of 70°. Give all its sides and angles.",
            answer: "Sides 6, 4, 6 and 4 cm; angles 70°, 110°, 70° and 110°."
        )
    )

    static let i41 = accepted(
        "I.41", "Triangle is half the parallelogram",
        "A parallelogram is double a triangle that has the same base and lies between the same parallel lines.",
        taughtIn: "OUP 5.2 Areas of parallelograms and trapeziums (ch10)",
        check: DeviceOffCheck(
            task: "A parallelogram has base 8 cm and height 5 cm. A triangle sits on the same base, between the same parallels. What is its area?",
            answer: "20 cm², half of 40 cm²."
        )
    )

    private static func accepted(
        _ id: PropositionID, _ title: String, _ statement: String,
        taughtIn: String, check: DeviceOffCheck
    ) -> EuclidProposition {
        EuclidProposition(
            id: id, title: title, statement: statement,
            kind: .accepted(taughtIn: taughtIn),
            uses: [], proofSteps: [], deviceOffCheck: check, knowsWhen: nil, leadsToChapter: nil
        )
    }
}
