import Foundation

/// Something a motif figure names by its letters.
enum FigureItem: Hashable {
    case point(String)
    case segment(String, String)
    /// Arm, vertex, arm. The angle under 180° unless stated.
    case angle(String, String, String)

    var pointNames: [String] {
        switch self {
        case let .point(p): [p]
        case let .segment(a, b): [a, b]
        case let .angle(a, v, b): [a, v, b]
        }
    }

    /// "∠BED", "BE" or "E".
    var name: String {
        switch self {
        case let .point(p): p
        case let .segment(a, b): a + b
        case let .angle(a, v, b): "∠" + a + v + b
        }
    }

    /// The same item, whichever way round its letters are written.
    func names(_ other: FigureItem) -> Bool {
        switch (self, other) {
        case let (.point(p), .point(q)): p == q
        case let (.segment(a, b), .segment(c, d)): (a, b) == (c, d) || (a, b) == (d, c)
        case let (.angle(a, v, b), .angle(c, w, d)): v == w && ((a, b) == (c, d) || (a, b) == (d, c))
        default: false
        }
    }
}

/// A motif's figure: named points, the lines between them, and which lines carry parallel arrows.
struct MotifFigure {
    var points: [String: Vec2]
    /// Each a pair of point names.
    var segments: [[String]]
    /// The segments marked with parallel arrows, all in one group.
    var parallels: [[String]] = []
    /// Helper-line segments, hidden until she asks for them.
    var helpers: [[String]] = []
    /// Angles the helper line makes, each with the angle it copies. The board draws a pair in one colour.
    var twins: [AngleTwin] = []

    /// The angle at `v` between the rays to `a` and `b`, in degrees, under 180°.
    func angle(_ a: String, _ v: String, _ b: String) -> Double {
        guard let pa = points[a], let pv = points[v], let pb = points[b] else { return .nan }
        let u = pa - pv, w = pb - pv
        let cosine = u.dot(w) / (u.length * w.length)
        return acos(min(1, max(-1, cosine))) * 180 / .pi
    }

    func length(_ a: String, _ b: String) -> Double {
        guard let pa = points[a], let pb = points[b] else { return .nan }
        return pa.distance(to: pb)
    }

    /// The size of an angle or a segment; a point has none.
    func measure(_ item: FigureItem) -> Double? {
        switch item {
        case .point: nil
        case let .segment(a, b): length(a, b)
        case let .angle(a, v, b): angle(a, v, b)
        }
    }
}

/// An angle at the helper line and the given angle it equals.
struct AngleTwin {
    let helper: FigureItem
    let twin: FigureItem
}

enum QuantityUnit: Hashable {
    case degrees
    case length
}

/// A number the question states or asks for, and the item it measures.
struct Quantity: Hashable {
    let item: FigureItem
    let value: Double
    let unit: QuantityUnit

    static func degrees(_ item: FigureItem, _ value: Double) -> Quantity { Quantity(item: item, value: value, unit: .degrees) }
    static func length(_ item: FigureItem, _ value: Double) -> Quantity { Quantity(item: item, value: value, unit: .length) }
}

/// One phrase of the question. Tapping a given or the goal lights what it names on the figure.
struct QuestionPhrase: Hashable {
    enum Role: Hashable { case plain, given, goal }

    let text: String
    var lights: [FigureItem] = []
    var role: Role = .plain

    static func given(_ text: String, _ lights: FigureItem...) -> QuestionPhrase { QuestionPhrase(text: text, lights: lights, role: .given) }
    static func goal(_ text: String, _ lights: FigureItem...) -> QuestionPhrase { QuestionPhrase(text: text, lights: lights, role: .goal) }
}

/// What she has done to a figure: where she has pulled its free point, and whether the break switch is on.
struct MotifState: Equatable {
    /// Where she is pulling the free point; the figure clamps it to where the motif still holds. Nil is the check's position.
    var free: Vec2?
    var broken = false
}

/// The motif's rule as two sides that should match, measured on the live figure.
struct MotifRule {
    let lhsLabel: String
    let lhs: Double
    let rhsLabel: String
    let rhs: Double

    var holds: Bool { abs(lhs - rhs) < 0.5 }
}

struct MotifScene {
    let question: [QuestionPhrase]
    let givens: [Quantity]
    let goal: [Quantity]
    /// The point she can drag, when the motif has one.
    var freePoint: String? = nil
    let build: (MotifState) -> MotifFigure
    /// The state that reproduces the check's numbers.
    var state = MotifState()
    var rule: ((MotifFigure) -> MotifRule)? = nil

    var figure: MotifFigure { build(state) }
    var hasBreakSwitch: Bool { rule != nil }
}

// MARK: - Plane geometry for building figures from their numbers

extension Vec2 {
    /// The unit vector `degrees` counterclockwise from the x-axis.
    static func heading(_ degrees: Double) -> Vec2 {
        let radians = degrees * .pi / 180
        return Vec2(x: cos(radians), y: sin(radians))
    }

    var unit: Vec2 { (1 / length) * self }

    /// This point turned `degrees` counterclockwise about `pivot`.
    func rotated(by degrees: Double, about pivot: Vec2) -> Vec2 {
        PythagorasShear.rotate(self, about: pivot, by: degrees * .pi / 180)
    }

    /// This direction turned `degrees` counterclockwise.
    func turned(_ degrees: Double) -> Vec2 {
        rotated(by: degrees, about: Vec2(x: 0, y: 0))
    }

    /// Where the line through `p` along `u` meets the line through `q` along `v`.
    static func meet(_ p: Vec2, _ u: Vec2, _ q: Vec2, _ v: Vec2) -> Vec2 {
        let s = (q - p).cross(v) / u.cross(v)
        return p + s * u
    }
}
