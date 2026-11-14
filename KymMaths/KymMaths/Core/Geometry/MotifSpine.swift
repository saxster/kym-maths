import Foundation

/// A named exam figure or a composite problem built from them, as docs/MOTIF_SPINE.md numbers them: "M1", "C2".
struct MotifID: Hashable, Codable, ExpressibleByStringLiteral, CustomStringConvertible {
    let raw: String

    init(_ raw: String) { self.raw = raw }
    init(stringLiteral value: String) { self.raw = value }

    var description: String { raw }
}

/// A single fact from school that motifs are built from. Accepted here, not taught.
enum PrototypeID: String, Hashable, CaseIterable {
    case parallel = "P-par"
    case line = "P-line"
    case triangle = "P-tri"
    case isosceles = "P-iso"

    var fact: String {
        switch self {
        case .parallel: "Parallel lines: corresponding angles are equal (F), alternate angles are equal (Z), and co-interior angles add to 180° (C)."
        case .line: "Angles on a straight line add to 180°. Vertically opposite angles are equal."
        case .triangle: "A triangle's angles add to 180°. An exterior angle equals the two interior angles opposite it."
        case .isosceles: "A triangle with two equal sides has two equal angles, and the other way round."
        }
    }

    var taughtIn: String {
        switch self {
        case .parallel, .line: "OUP 8.2 Angles in parallel and intersecting lines (ch08)"
        case .triangle, .isosceles: "ch08"
        }
    }
}

/// What a motif or composite stands on: a school fact, a proposition from Euclid's Workshop, or another motif.
enum MotifFoundation: Hashable {
    case prototype(PrototypeID)
    case proposition(PropositionID)
    case motif(MotifID)
}

enum MotifLayer: Hashable {
    /// A named figure built from two or three prototypes.
    case motif
    /// A problem that needs two motifs, or a motif and a prototype.
    case composite
}

struct Motif {
    let id: MotifID
    let layer: MotifLayer
    let title: String
    /// The check she does on paper with the device off.
    let check: String
    let answer: String
    /// The helper line or short argument that cracks it. For a composite, its steps.
    let move: String
    let whyItMatters: String?
    let standsOn: [MotifFoundation]
    /// KymMaths chapters this motif pays off in.
    let chapterUnlocks: [String]
    /// The one condition the break switch removes, and what she sees when it goes.
    let breakSwitch: String?
    /// A word problem with no figure.
    let knowsWhen: String?
    let scene: MotifScene

    /// The motifs and composites that stand on this one. Derived from `standsOn`, so the two never disagree.
    var unlocks: [MotifID] {
        MotifSpine.catalog.filter { $0.standsOn.contains(.motif(id)) }.map(\.id)
    }
}

/// The motif spine of docs/MOTIF_SPINE.md: five motifs and the four composites that use them.
enum MotifSpine {
    static func motif(_ id: MotifID) -> Motif? {
        catalog.first { $0.id == id }
    }

    /// Motifs with a page she can work on. The rest wait until she has used M1.
    static let playable: Set<MotifID> = ["M1"]

    static let catalog: [Motif] = [
        Motif(
            id: "M1", layer: .motif, title: "M-shape",
            check: "AB is parallel to CD. E is between them, and the bend points away from A and C. ∠ABE = 40° and ∠CDE = 35°. Find ∠BED.",
            answer: "∠BED = 75°",
            move: "Draw a line through E parallel to AB. It splits ∠BED into two Z-angles.",
            whyItMatters: "The helper line is the first construction she invents rather than copies. Bent paths between parallels fill exam angle questions.",
            standsOn: [.prototype(.parallel)],
            chapterUnlocks: [],
            breakSwitch: "AB and CD stop being parallel: CD tilts, and ∠B + ∠D and ∠E drift apart.",
            knowsWhen: "Two shelves are parallel. A wire leaves the top shelf at 40°, bends at a nail between the shelves, and meets the bottom shelf at 35°. Both angles are on the side away from the bend. What angle does it make at the nail?",
            scene: .mShape
        ),
        Motif(
            id: "M2", layer: .motif, title: "X-shape",
            check: "AC and BD cross at O. In △AOB, ∠A = 70° and ∠B = 40°. In △COD, ∠C = 60°. Find ∠D.",
            answer: "∠D = 50°",
            move: "The angles at O are vertically opposite, so the other two pairs have the same sum.",
            whyItMatters: "Moving an angle sum from one triangle to another without measuring either. It is the engine of the star.",
            standsOn: [.prototype(.line), .prototype(.triangle)],
            chapterUnlocks: [],
            breakSwitch: "AC straight off: it bends at O, and the angles at O stop matching.",
            knowsWhen: "Two sticks cross like open scissors. In the top triangle, the angles at the stick ends are 70° and 40°. In the bottom triangle, one end angle is 60°. What is the other?",
            scene: .xShape
        ),
        Motif(
            id: "M3", layer: .motif, title: "Dart",
            check: "ABDC is an arrowhead: D sits inside angle A. ∠A = 50°, ∠ABD = 20° and ∠ACD = 30°. Find ∠BDC.",
            answer: "∠BDC = 100°",
            move: "The notch angle equals the other three added. Extend BD to meet AC, then use the exterior angle twice.",
            whyItMatters: "The exterior angle used twice in a row: her first two-step chain.",
            standsOn: [.prototype(.triangle)],
            chapterUnlocks: [],
            breakSwitch: "D leaves the inside of angle A: the shape turns convex, and the four angles add to 360°.",
            knowsWhen: "An arrowhead kite has a 50° tip, and its back corners are 20° and 30°. What is the angle inside the notch?",
            scene: .dart
        ),
        Motif(
            id: "M4", layer: .motif, title: "Bisector + parallel",
            check: "BD bisects ∠ABC. DE is parallel to BC, with E on AB. BE = 4 cm. Find DE.",
            answer: "DE = 4 cm",
            move: "∠EDB = ∠DBC (Z), and ∠DBC = ∠EBD (bisector). Two equal angles make △BED isosceles.",
            whyItMatters: "Turns two angle facts into a length. This is how a parallelogram question hands her a side.",
            standsOn: [.prototype(.parallel), .prototype(.isosceles), .proposition("I.9")],
            chapterUnlocks: [],
            breakSwitch: "DE and BC stop being parallel: DE tilts, and BE and DE stop being equal.",
            knowsWhen: "Fold a strip of paper with parallel edges, at any angle. The overlap is a triangle with two equal sides. Which motif says why?",
            scene: .bisectorParallel
        ),
        Motif(
            id: "M5", layer: .motif, title: "A-shape",
            check: "DE is parallel to BC, with D on AB and E on AC. AD = 3, AB = 5 and BC = 10. Find DE.",
            answer: "DE = 6",
            move: "Corresponding angles make the small and big triangles the same shape, so every side scales by AD/AB.",
            whyItMatters: "Scale drawings, shadows and maps. Sine and cosine are ratios in an A-shape.",
            standsOn: [.prototype(.parallel)],
            chapterUnlocks: ["ch11 (OUP 13, enlargement)", "ch12 (trigonometry)"],
            breakSwitch: "DE and BC stop being parallel: DE tilts, and AD/AB and DE/BC stop matching.",
            knowsWhen: "A 1.5 m stick casts a 2 m shadow. At the same moment a tree casts a 12 m shadow. How tall is the tree?",
            scene: .aShape
        ),
        Motif(
            id: "C1", layer: .composite, title: "Bent path + isosceles",
            check: "AB is parallel to CD, and E is between them (an M-shape). ∠ABE = 40° and ∠BED = 80°. G is on DC with DG = DE. Find ∠CDE and ∠DEG.",
            answer: "∠CDE = 40°, ∠DEG = 70°",
            move: "∠CDE = 80° − 40° (M1). △DEG has DG = DE, so its base angles are (180° − 40°) ÷ 2 (P-iso, P-tri).",
            whyItMatters: nil,
            standsOn: [.motif("M1"), .prototype(.isosceles)],
            chapterUnlocks: [],
            breakSwitch: nil,
            knowsWhen: nil,
            scene: .bentPathIsosceles
        ),
        Motif(
            id: "C2", layer: .composite, title: "Five-point star",
            check: "A five-point star's tips are 30°, 40°, 35° and 45°. Find the fifth tip.",
            answer: "30°",
            move: "Two tips move to the base of the triangle around a third tip (M2). That triangle holds all five, so they add to 180° (P-tri).",
            whyItMatters: nil,
            standsOn: [.motif("M2"), .prototype(.triangle)],
            chapterUnlocks: [],
            breakSwitch: nil,
            knowsWhen: nil,
            scene: .star
        ),
        Motif(
            id: "C3", layer: .composite, title: "Angle between two bisectors",
            check: "In △ABC, the bisectors of ∠B and ∠C meet at I. ∠A = 60°. Find ∠BIC.",
            answer: "∠BIC = 120°",
            move: "ABIC is a dart, so ∠BIC = ∠A + half ∠B + half ∠C (M3). ∠B + ∠C = 180° − ∠A (P-tri). So ∠BIC = 90° + ∠A ÷ 2.",
            whyItMatters: nil,
            standsOn: [.motif("M3"), .proposition("I.9")],
            chapterUnlocks: [],
            breakSwitch: nil,
            knowsWhen: nil,
            scene: .twoBisectors
        ),
        Motif(
            id: "C4", layer: .composite, title: "Bisector in a parallelogram",
            check: "In parallelogram ABCD, AB = 5 cm and AD = 8 cm. The bisector of ∠A meets BC at E. Find BE and EC.",
            answer: "BE = 5 cm, EC = 3 cm",
            move: "AD is parallel to BC, so M4 makes △ABE isosceles: BE = AB. BC = AD = 8, so EC = 8 − 5.",
            whyItMatters: nil,
            standsOn: [.motif("M4")],
            chapterUnlocks: [],
            breakSwitch: nil,
            knowsWhen: nil,
            scene: .parallelogramBisector
        ),
    ]
}
