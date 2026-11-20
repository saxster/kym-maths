import Foundation

// MARK: - PhET Quadrilateral Hierarchy Explorer Model & Classifier

enum QuadrilateralKind: String, CaseIterable, Identifiable, Codable, Sendable {
    case square
    case rectangle
    case rhombus
    case parallelogram
    case isoscelesTrapezium
    case trapezium
    case kite
    case general

    var id: String { rawValue }

    var title: String {
        switch self {
        case .square: "Square"
        case .rectangle: "Rectangle"
        case .rhombus: "Rhombus"
        case .parallelogram: "Parallelogram"
        case .isoscelesTrapezium: "Isosceles trapezium"
        case .trapezium: "Trapezium"
        case .kite: "Kite"
        case .general: "General quadrilateral"
        }
    }

    var plainRule: String {
        switch self {
        case .square: "Four equal sides and four 90° corners."
        case .rectangle: "Four 90° corners; opposite sides are equal and parallel."
        case .rhombus: "Four equal sides; opposite sides are parallel and diagonals cross at 90°."
        case .parallelogram: "Both pairs of opposite sides are parallel and equal."
        case .isoscelesTrapezium: "One pair of parallel sides, with the other two sides equal."
        case .trapezium: "At least one pair of opposite sides is parallel."
        case .kite: "Two pairs of next-door sides match in length."
        case .general: "Four straight sides meeting at four corners."
        }
    }
}

struct ParallelPair: Equatable, Sendable {
    let firstEdge: Int
    let secondEdge: Int
}

struct QuadrilateralProperties: Equatable, Sendable {
    let vertices: [Vec2]
    let sideLengths: [Double]
    let angles: [Double]
    let equalSideGroups: [[Int]]
    let parallelPairs: [ParallelPair]
    let rightAngleIndices: [Int]
    let diagonalsEqual: Bool
    let diagonalsPerpendicular: Bool
    let diagonalsBisectEachOther: Bool
    let isConvex: Bool
    let isSimple: Bool
    let primaryKind: QuadrilateralKind
    let hierarchy: [QuadrilateralKind]
}

struct QuadrilateralMission: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let prompt: String
    let check: @Sendable (QuadrilateralProperties) -> Bool

    static func == (lhs: QuadrilateralMission, rhs: QuadrilateralMission) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title && lhs.prompt == rhs.prompt
    }

    static let all: [QuadrilateralMission] = [
        QuadrilateralMission(
            id: "kite-only",
            title: "Kite without parallel sides",
            prompt: "Make a kite with no parallel sides: two pairs of next-door sides equal.",
            check: { props in
                props.isSimple && props.isConvex && props.primaryKind == .kite
            }
        ),
        QuadrilateralMission(
            id: "rectangle-not-square",
            title: "Equal diagonals, unequal sides",
            prompt: "Make a rectangle (four 90° corners and equal diagonals) without all four sides being equal.",
            check: { props in
                props.isSimple && props.isConvex && props.primaryKind == .rectangle
            }
        ),
        QuadrilateralMission(
            id: "rhombus-not-square",
            title: "90° diagonals, slanted corners",
            prompt: "Make a rhombus whose diagonals cross at 90°, with all four sides equal and no right-angle corners.",
            check: { props in
                props.isSimple && props.isConvex && props.primaryKind == .rhombus
            }
        ),
        QuadrilateralMission(
            id: "parallelogram-break",
            title: "Tilt a square into a parallelogram",
            prompt: "Keep opposite sides parallel, but break both equal-adjacent sides and right angles.",
            check: { props in
                props.isSimple && props.isConvex && props.primaryKind == .parallelogram
            }
        ),
        QuadrilateralMission(
            id: "square-all",
            title: "Every property at once",
            prompt: "Lock all four symmetries together: four equal sides and four 90° corners.",
            check: { props in
                props.isSimple && props.isConvex && props.primaryKind == .square
            }
        )
    ]
}

enum QuadrilateralClassifier {
    static let boardMin = Vec2(x: -3.5, y: -2.5)
    static let boardMax = Vec2(x: 3.5, y: 2.5)

    static let deviceOffCheck = DeviceOffCheck(
        task: "Sketch a rhombus that is not a square and draw its two diagonals. Name two facts that stay true for every square too.",
        answer: "All four sides are equal, and the diagonals bisect each other at 90°. A square adds four 90° corners and equal diagonals."
    )

    static func snap(_ point: Vec2, smallSteps: Bool) -> Vec2 {
        let step = smallSteps ? 0.1 : 0.5
        let sx = (point.x / step).rounded() * step
        let sy = (point.y / step).rounded() * step
        return Vec2(
            x: min(max(sx, boardMin.x), boardMax.x),
            y: min(max(sy, boardMin.y), boardMax.y)
        )
    }

    static func preset(_ kind: QuadrilateralKind) -> [Vec2] {
        switch kind {
        case .square:
            return [Vec2(x: -1.5, y: 1.5), Vec2(x: 1.5, y: 1.5), Vec2(x: 1.5, y: -1.5), Vec2(x: -1.5, y: -1.5)]
        case .rectangle:
            return [Vec2(x: -2.0, y: 1.2), Vec2(x: 2.0, y: 1.2), Vec2(x: 2.0, y: -1.2), Vec2(x: -2.0, y: -1.2)]
        case .rhombus:
            return [Vec2(x: 0.0, y: 2.0), Vec2(x: 1.5, y: 0.0), Vec2(x: 0.0, y: -2.0), Vec2(x: -1.5, y: 0.0)]
        case .parallelogram:
            return [Vec2(x: -1.5, y: 1.5), Vec2(x: 2.5, y: 1.5), Vec2(x: 1.5, y: -1.5), Vec2(x: -2.5, y: -1.5)]
        case .isoscelesTrapezium:
            return [Vec2(x: -1.0, y: 1.5), Vec2(x: 1.0, y: 1.5), Vec2(x: 2.5, y: -1.5), Vec2(x: -2.5, y: -1.5)]
        case .trapezium:
            return [Vec2(x: -1.5, y: 1.5), Vec2(x: 1.0, y: 1.5), Vec2(x: 2.5, y: -1.5), Vec2(x: -2.0, y: -1.5)]
        case .kite:
            return [Vec2(x: 0.0, y: 2.0), Vec2(x: 1.5, y: 0.5), Vec2(x: 0.0, y: -2.0), Vec2(x: -1.5, y: 0.5)]
        case .general:
            return [Vec2(x: -2.0, y: 1.5), Vec2(x: 1.0, y: 2.0), Vec2(x: 2.5, y: -0.5), Vec2(x: -1.5, y: -2.0)]
        }
    }

    static func inspect(
        _ vertices: [Vec2],
        lengthTolerance: Double = 0.12,
        angleToleranceDeg: Double = 2.5
    ) -> QuadrilateralProperties {
        precondition(vertices.count == 4, "Quadrilateral requires 4 vertices")
        let sides = (0..<4).map { i in vertices[i].distance(to: vertices[(i + 1) % 4]) }
        let edgeVecs = (0..<4).map { i in vertices[(i + 1) % 4] - vertices[i] }

        // Signed polygon winding so reflex interior angles become 360° - theta and always sum to 360° for simple quads.
        var signedArea2 = 0.0
        for i in 0..<4 {
            let a = vertices[i]
            let b = vertices[(i + 1) % 4]
            signedArea2 += (a.x * b.y - b.x * a.y)
        }
        let windingSign = signedArea2 >= 0 ? 1.0 : -1.0

        // Compute interior angles and cross signs to check convexity and self-intersection.
        var crosses: [Double] = []
        var angles: [Double] = []
        for i in 0..<4 {
            let prev = vertices[(i + 3) % 4]
            let curr = vertices[i]
            let next = vertices[(i + 1) % 4]
            let u = prev - curr
            let v = next - curr
            // Cross product from outgoing edge (next - curr) to incoming edge (prev - curr): matches windingSign on convex corners.
            let cornerTurn = (next - curr).cross(prev - curr)
            crosses.append(u.cross(v))
            let denom = u.length * v.length
            if denom < 1e-9 {
                angles.append(0)
            } else {
                let c = min(1.0, max(-1.0, u.dot(v) / denom))
                let rawDeg = acos(c) * 180.0 / .pi
                let isReflex = (cornerTurn * windingSign) < -1e-6
                angles.append(isReflex ? (360.0 - rawDeg) : rawDeg)
            }
        }

        let isSimple = !segmentsProperlyIntersect(vertices[0], vertices[1], vertices[2], vertices[3])
            && !segmentsProperlyIntersect(vertices[1], vertices[2], vertices[3], vertices[0])
            && sides.allSatisfy { $0 > 1e-4 }
        let allPos = crosses.allSatisfy { $0 > 1e-6 }
        let allNeg = crosses.allSatisfy { $0 < -1e-6 }
        let isConvex = isSimple && (allPos || allNeg)

        let rightAngles = (0..<4).filter { abs(angles[$0] - 90.0) <= angleToleranceDeg }

        // Group equal side lengths cleanly without re-adding already grouped edges
        var equalGroups: [[Int]] = []
        var visited = Set<Int>()
        for i in 0..<4 where !visited.contains(i) {
            var group = [i]
            for j in (i + 1)..<4 where !visited.contains(j) && abs(sides[i] - sides[j]) <= lengthTolerance {
                group.append(j)
            }
            if group.count >= 2 {
                equalGroups.append(group)
                group.forEach { visited.insert($0) }
            }
        }

        // Parallel pairs: opposite edges (0, 2) and (1, 3)
        var parallelPairs: [ParallelPair] = []
        if isParallel(edgeVecs[0], edgeVecs[2], angleToleranceDeg: angleToleranceDeg) {
            parallelPairs.append(ParallelPair(firstEdge: 0, secondEdge: 2))
        }
        if isParallel(edgeVecs[1], edgeVecs[3], angleToleranceDeg: angleToleranceDeg) {
            parallelPairs.append(ParallelPair(firstEdge: 1, secondEdge: 3))
        }

        // Diagonals AC (0-2) and BD (1-3)
        let dAC = vertices[2] - vertices[0]
        let dBD = vertices[3] - vertices[1]
        let diagonalsEqual = abs(dAC.length - dBD.length) <= lengthTolerance
        let diagDenom = dAC.length * dBD.length
        let diagonalsPerp = diagDenom > 1e-9
            && abs(asin(min(1.0, max(-1.0, dAC.dot(dBD) / diagDenom))) * 180.0 / .pi) <= angleToleranceDeg
        let midAC = 0.5 * (vertices[0] + vertices[2])
        let midBD = 0.5 * (vertices[1] + vertices[3])
        let diagonalsBisect = midAC.distance(to: midBD) <= lengthTolerance

        let minSide = sides.min() ?? 0
        let maxSide = sides.max() ?? 0
        let allFourSidesEqual = (maxSide - minSide) <= lengthTolerance
        let fourRightAngles = rightAngles.count == 4 && isConvex
        let twoParallelPairs = parallelPairs.count == 2 && isConvex
        let oneOrMoreParallelPairs = !parallelPairs.isEmpty && isConvex
        let oppositeSidesEqual = abs(sides[0] - sides[2]) <= lengthTolerance
            && abs(sides[1] - sides[3]) <= lengthTolerance
            && isConvex

        // Adjacent disjoint equal-side pairs: (0==1 && 2==3) or (1==2 && 3==0)
        let kiteByPairs = (abs(sides[0] - sides[1]) <= lengthTolerance && abs(sides[2] - sides[3]) <= lengthTolerance)
            || (abs(sides[1] - sides[2]) <= lengthTolerance && abs(sides[3] - sides[0]) <= lengthTolerance)
        let isKite = isConvex && kiteByPairs
        let isParallelogram = twoParallelPairs || (oppositeSidesEqual && diagonalsBisect)
        let isRhombus = isConvex && allFourSidesEqual
        let isRectangle = isConvex && fourRightAngles
        let isSquare = isRhombus && isRectangle

        // An isosceles trapezium has a pair of parallel bases AND equal-length non-parallel legs
        // with congruent base angles (equivalently equal diagonals), excluding non-rectangular parallelograms/rhombuses.
        var isIsoscelesTrap = false
        if isConvex, !parallelPairs.isEmpty, diagonalsEqual {
            for pair in parallelPairs {
                let otherA = (pair.firstEdge + 1) % 4
                let otherB = (pair.firstEdge + 3) % 4
                if abs(sides[otherA] - sides[otherB]) <= lengthTolerance {
                    isIsoscelesTrap = true
                }
            }
        }

        // Build inclusive subset hierarchy (most specific -> most general).
        var hierarchy: [QuadrilateralKind] = []
        if isSquare { hierarchy.append(.square) }
        if isRectangle { hierarchy.append(.rectangle) }
        if isRhombus { hierarchy.append(.rhombus) }
        if isParallelogram { hierarchy.append(.parallelogram) }
        if isIsoscelesTrap || isRectangle || isSquare { hierarchy.append(.isoscelesTrapezium) }
        if oneOrMoreParallelPairs || isParallelogram { hierarchy.append(.trapezium) }
        if isKite || isRhombus || isSquare { hierarchy.append(.kite) }
        hierarchy.append(.general)

        // Deduplicate preserving order
        var seen = Set<QuadrilateralKind>()
        hierarchy = hierarchy.filter { seen.insert($0).inserted }

        let primary = hierarchy.first ?? .general
        return QuadrilateralProperties(
            vertices: vertices,
            sideLengths: sides,
            angles: angles,
            equalSideGroups: equalGroups,
            parallelPairs: parallelPairs,
            rightAngleIndices: rightAngles,
            diagonalsEqual: diagonalsEqual,
            diagonalsPerpendicular: diagonalsPerp,
            diagonalsBisectEachOther: diagonalsBisect,
            isConvex: isConvex,
            isSimple: isSimple,
            primaryKind: primary,
            hierarchy: hierarchy
        )
    }

    static func voicingSummary(
        for props: QuadrilateralProperties,
        movedVertex: String? = nil
    ) -> StageVoicingResponse {
        let name = props.primaryKind.title
        let object = movedVertex.map { "Corner \($0) moved" } ?? "Four-sided shape"
        var facts: [String] = []
        if !props.parallelPairs.isEmpty {
            facts.append("\(props.parallelPairs.count) parallel \(props.parallelPairs.count == 1 ? "pair" : "pairs")")
        } else {
            facts.append("no parallel sides")
        }
        if !props.rightAngleIndices.isEmpty {
            facts.append("\(props.rightAngleIndices.count) right \(props.rightAngleIndices.count == 1 ? "angle" : "angles")")
        }
        if props.diagonalsPerpendicular {
            facts.append("diagonals cross at 90°")
        } else if props.diagonalsEqual {
            facts.append("diagonals have equal length")
        }
        let subsetNames = props.hierarchy.dropFirst().dropLast().map(\.title)
        let subsetText = subsetNames.isEmpty ? "" : " Also a \(subsetNames.joined(separator: ", "))."
        let context = "\(name): \(facts.joined(separator: ", ")).\(subsetText)"
        return StageVoicingResponse(
            name: name,
            object: object,
            context: context,
            hint: props.isSimple ? nil : "Two edges cross over. Drag a corner back so sides do not cross."
        )
    }

    private static func isParallel(_ a: Vec2, _ b: Vec2, angleToleranceDeg: Double) -> Bool {
        let denom = a.length * b.length
        guard denom > 1e-9 else { return false }
        let sinTheta = abs(a.cross(b)) / denom
        let angleDeg = asin(min(1.0, max(0.0, sinTheta))) * 180.0 / .pi
        return angleDeg <= angleToleranceDeg
    }

    private static func segmentsProperlyIntersect(_ a: Vec2, _ b: Vec2, _ c: Vec2, _ d: Vec2) -> Bool {
        let d1 = (b - a).cross(c - a)
        let d2 = (b - a).cross(d - a)
        let d3 = (d - c).cross(a - c)
        let d4 = (d - c).cross(b - c)
        return (d1 * d2 < -1e-7) && (d3 * d4 < -1e-7)
    }
}
