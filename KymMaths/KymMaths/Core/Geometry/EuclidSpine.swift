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

    /// The propositions whose proofs cite this one. Derived from `uses`, so the two never disagree.
    var unlocks: [PropositionID] {
        EuclidSpine.catalog.filter { $0.uses.contains(id) }.map(\.id)
    }
}

/// Book I as a dependency graph, from the equilateral triangle to Pythagoras.
/// docs/EUCLID_SPINE.md is the readable version; when the two disagree, this file wins.
enum EuclidSpine {
    static let catalog: [EuclidProposition] = [
        i4, i8, i14, i28, i33, i34, i41,
    ]

    static func proposition(_ id: PropositionID) -> EuclidProposition? {
        byID[id]
    }

    private static let byID = Dictionary(catalog.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

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
