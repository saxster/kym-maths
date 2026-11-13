import Foundation

/// One coloured triangle of the shear picture.
struct ShearPiece: Equatable {
    var corners: [Vec2]
    var role: ColorRole
}

/// A still of the shear: four triangles, two from each short side's square.
struct ShearFrame: Equatable {
    var pieces: [ShearPiece]
}

/// How the pieces get from one still to the next. Both keep every triangle's area.
enum ShearMotion: Equatable {
    /// Each corner slides in a straight line. Every corner that moves slides along a line
    /// parallel to its triangle's fixed base, so base and height stay the same.
    case slide
    /// The listed pieces turn rigidly about `pivot` by `angle` radians; the rest stay put.
    case turn(about: Vec2, by: Double, pieces: [Int])
}

/// Euclid's proof of I.47 as a moving picture. Each square on a short side slides over into a
/// parallelogram, turns a quarter about a corner of the triangle, then slides down into its
/// rectangle of the square on the longest side. Slides and turns never change an area, which is
/// the whole proof.
///
/// Letters follow `EuclidSpine.i47`: right angle at A, BC the longest side, squares ABFG, ACKH
/// and BDEC, and AL meeting BC at M and DE at L.
struct PythagorasShear {
    let a, b, c, d, e, f, g, h, k, l, m: Vec2
    /// Seven stills: the squares, three moves for the blue square, three for the green one.
    let frames: [ShearFrame]
    /// `motions[i]` takes `frames[i]` to `frames[i + 1]`.
    let motions: [ShearMotion]
    /// What each move shows, letter-free. `captions[i]` belongs to `motions[i]`; the last one
    /// describes the finished picture.
    let captions: [String]

    /// The book's 3-4-5 triangle, matching the I.47 board.
    static let book = PythagorasShear(legAB: 3, legAC: 4)

    /// A right triangle with BC along the x-axis from the origin, A above it.
    init(legAB: Double, legAC: Double) {
        let hyp = (legAB * legAB + legAC * legAC).squareRoot()
        b = Vec2(x: 0, y: 0)
        c = Vec2(x: hyp, y: 0)
        a = Vec2(x: legAB * legAB / hyp, y: legAB * legAC / hyp)
        // Each square sits on the side away from the triangle.
        d = Vec2(x: 0, y: -hyp)
        e = Vec2(x: hyp, y: -hyp)
        let outAB = (a - b).perpendicular          // counterclockwise from BA points away from C
        f = b + outAB
        g = a + outAB
        let outAC = (c - a).perpendicular          // counterclockwise from AC points away from B
        k = c + outAC
        h = a + outAC
        m = Vec2(x: a.x, y: 0)
        l = Vec2(x: a.x, y: -hyp)

        // Blue square: slide its top along GC to the parallelogram FBCG′, turn it about B
        // (F lands on A, C on D), then slide its top down AL into the rectangle BDLM.
        let gSlid = g + (c - a)
        let quarterAboutB = -Double.pi / 2
        let gTurned = Self.rotate(gSlid, about: b, by: quarterAboutB)
        // Green square: the same about C, ending as the rectangle CELM.
        let hSlid = h + (b - a)
        let quarterAboutC = Double.pi / 2
        let hTurned = Self.rotate(hSlid, about: c, by: quarterAboutC)

        func blue(_ p: Vec2, _ q: Vec2, _ r: Vec2, _ role: ColorRole = .blue) -> ShearPiece { ShearPiece(corners: [p, q, r], role: role) }
        func green(_ p: Vec2, _ q: Vec2, _ r: Vec2, _ role: ColorRole = .green) -> ShearPiece { ShearPiece(corners: [p, q, r], role: role) }

        let squaresAB = [blue(f, b, a), blue(f, a, g)]
        let slidAB = [blue(f, b, c, .red), blue(f, c, gSlid)]
        let turnedAB = [blue(a, b, d, .red), blue(a, d, gTurned)]
        let rectangleBM = [blue(m, b, d, .red), blue(m, d, l)]
        let squaresAC = [green(k, c, a), green(k, a, h)]
        let slidAC = [green(k, c, b, .amber), green(k, b, hSlid)]
        let turnedAC = [green(a, c, e, .amber), green(a, e, hTurned)]
        let rectangleCM = [green(m, c, e, .amber), green(m, e, l)]

        frames = [
            ShearFrame(pieces: squaresAB + squaresAC),
            ShearFrame(pieces: slidAB + squaresAC),
            ShearFrame(pieces: turnedAB + squaresAC),
            ShearFrame(pieces: rectangleBM + squaresAC),
            ShearFrame(pieces: rectangleBM + slidAC),
            ShearFrame(pieces: rectangleBM + turnedAC),
            ShearFrame(pieces: rectangleBM + rectangleCM),
        ]
        motions = [
            .slide,
            .turn(about: b, by: quarterAboutB, pieces: [0, 1]),
            .slide,
            .slide,
            .turn(about: c, by: quarterAboutC, pieces: [2, 3]),
            .slide,
        ]
        captions = [
            "Slide the blue square's far edge along its line. Same base, same height, so the same area. Half of it is now the red triangle.",
            "Turn it a quarter turn about the triangle's corner. The red triangle lands exactly where the other red triangle was: they are equal.",
            "Slide its tip down the line to the longest side. The area still has not changed, and the blue square is now a rectangle.",
            "Now the green square. Slide its far edge along its line: same base, same height, same area.",
            "Turn it a quarter turn about the other corner. Its amber half lands on the matching amber triangle.",
            "Slide it down to the longest side. The green square is now the other rectangle.",
            "The two rectangles fill the square on the longest side, so the two small squares together equal it.",
        ]
    }

    // MARK: - Playing

    /// Where `t` (0 at the squares, 1 at the rectangles) falls: the move under way and how far into it.
    func position(at t: Double) -> (move: Int, progress: Double) {
        let clamped = min(max(t, 0), 1)
        let scaled = clamped * Double(motions.count)
        let move = min(Int(scaled), motions.count - 1)
        return (move, scaled - Double(move))
    }

    /// The pieces at `t`. Keyframe `i` sits at `t = i / 6`. A piece takes its new colour as soon as it moves.
    func interpolate(t: Double) -> [ShearPiece] {
        let (move, s) = position(at: t)
        let from = frames[move].pieces, to = frames[move + 1].pieces
        if s == 0 { return from }
        if s >= 1 { return to }
        return from.indices.map { index in
            let corners: [Vec2]
            switch motions[move] {
            case .slide:
                corners = zip(from[index].corners, to[index].corners).map { p, q in p + s * (q - p) }
            case let .turn(pivot, angle, pieces):
                corners = pieces.contains(index)
                    ? from[index].corners.map { Self.rotate($0, about: pivot, by: s * angle) }
                    : from[index].corners
            }
            return ShearPiece(corners: corners, role: to[index].role)
        }
    }

    /// The sentence for the move under way at `t`, or the closing one at the end.
    func caption(at t: Double) -> String {
        t >= 1 ? captions[motions.count] : captions[position(at: t).move]
    }

    /// Every point of the figure, for fitting it to a view.
    var allPoints: [Vec2] { [a, b, c, d, e, f, g, h, k, l, m] }

    // MARK: - Geometry

    static func rotate(_ p: Vec2, about pivot: Vec2, by angle: Double) -> Vec2 {
        let v = p - pivot
        let (cosA, sinA) = (cos(angle), sin(angle))
        return pivot + Vec2(x: v.x * cosA - v.y * sinA, y: v.x * sinA + v.y * cosA)
    }

    /// The shoelace formula: positive for a counterclockwise polygon.
    static func signedArea(_ corners: [Vec2]) -> Double {
        guard corners.count >= 3 else { return 0 }
        var sum = 0.0
        for index in corners.indices {
            sum += corners[index].cross(corners[(index + 1) % corners.count])
        }
        return sum / 2
    }
}
