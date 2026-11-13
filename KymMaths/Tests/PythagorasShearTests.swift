import Foundation
import Testing
@testable import KymMaths

@Suite("Pythagoras shear")
struct PythagorasShearTests {
    private static let shapes: [PythagorasShear] = [.book, PythagorasShear(legAB: 2, legAC: 5), PythagorasShear(legAB: 1, legAC: 1)]
    private static let close = 1e-9

    private static func area(_ pieces: some Sequence<ShearPiece>) -> Double {
        pieces.reduce(0) { $0 + abs(PythagorasShear.signedArea($1.corners)) }
    }

    private static func same(_ p: Vec2, _ q: Vec2) -> Bool { p.distance(to: q) < 1e-9 }

    @Test("The book's triangle has the I.47 board's letters where the board puts them")
    func matchesBoard() throws {
        let proposition = try #require(EuclidSpine.proposition("I.47"))
        let session = try #require(EuclidWorkshopSession(proposition: proposition))
        let shear = PythagorasShear.book
        let named: [(String, Vec2)] = [("A", shear.a), ("B", shear.b), ("C", shear.c), ("D", shear.d), ("E", shear.e),
                                       ("F", shear.f), ("G", shear.g), ("H", shear.h), ("K", shear.k), ("L", shear.l), ("M", shear.m)]
        for (name, point) in named {
            let board = try #require(session.script.position(named: name), "\(name) on the board")
            #expect(board.distance(to: point) < 1e-6, "\(name): board \(board), shear \(point)")
        }
    }

    @Test("At every moment each square's pieces keep its area, and the total is the square on the longest side")
    func areaConserved() {
        for shear in Self.shapes {
            let (ab, ac, bc) = (shear.a.distance(to: shear.b), shear.a.distance(to: shear.c), shear.b.distance(to: shear.c))
            for step in 0...240 {
                let t = Double(step) / 240
                let pieces = shear.interpolate(t: t)
                #expect(abs(Self.area(pieces.prefix(2)) - ab * ab) < Self.close, "blue at t=\(t)")
                #expect(abs(Self.area(pieces.suffix(2)) - ac * ac) < Self.close, "green at t=\(t)")
                #expect(abs(Self.area(pieces) - bc * bc) < Self.close, "total at t=\(t)")
            }
        }
    }

    @Test("Each move ends exactly on the next still")
    func movesReachTheirStills() {
        for shear in Self.shapes {
            for move in shear.motions.indices {
                let justBefore = shear.interpolate(t: (Double(move + 1) - 1e-9) / Double(shear.motions.count))
                for (moving, still) in zip(justBefore, shear.frames[move + 1].pieces) {
                    for (p, q) in zip(moving.corners, still.corners) {
                        #expect(p.distance(to: q) < 1e-6, "move \(move)")
                    }
                }
            }
            #expect(shear.interpolate(t: 0) == shear.frames[0].pieces)
            #expect(shear.interpolate(t: 1) == shear.frames.last?.pieces)
        }
    }

    @Test("At the end the two rectangles tile the square on the longest side")
    func rectanglesTileTheSquare() throws {
        for shear in Self.shapes {
            let pieces = try #require(shear.frames.last).pieces
            let bc = shear.b.distance(to: shear.c)
            let blueCorners = Set(pieces.prefix(2).flatMap(\.corners))
            let greenCorners = Set(pieces.suffix(2).flatMap(\.corners))
            #expect(blueCorners == [shear.b, shear.d, shear.l, shear.m])
            #expect(greenCorners == [shear.c, shear.e, shear.l, shear.m])
            // M on BC and L on DE, with ML upright, so the two rectangles share a side and fill BDEC.
            #expect(shear.m.y == 0 && shear.m.x > 0 && shear.m.x < bc)
            #expect(shear.l.x == shear.m.x && abs(shear.l.y - shear.d.y) < Self.close)
            #expect(abs(Self.area(pieces) - bc * bc) < Self.close)
            #expect(abs(Self.area(pieces.prefix(2)) - shear.m.x * bc) < Self.close)
        }
    }

    @Test("The picture shows Euclid's equal red pair, then the red one as half of the rectangle")
    func trianglePairThenRectangleHalf() {
        let shear = PythagorasShear.book
        let reds = shear.frames.flatMap(\.pieces).filter { $0.role == .red }
        let shapes = Set(reds.map { Set($0.corners) })
        let fbc: Set<Vec2> = [shear.f, shear.b, shear.c]
        let abd: Set<Vec2> = [shear.a, shear.b, shear.d]
        let mbd: Set<Vec2> = [shear.m, shear.b, shear.d]
        #expect(shapes.contains(fbc) && shapes.contains(abd) && shapes.contains(mbd), "three red triangles")
        // FBC and ABD are the pair I.4 proves equal: the turn about B carries one onto the other.
        let turned = [shear.f, shear.b, shear.c].map { PythagorasShear.rotate($0, about: shear.b, by: -.pi / 2) }
        #expect(zip(turned, [shear.a, shear.b, shear.d]).allSatisfy { Self.same($0, $1) })
        // MBD is half of BDLM.
        let half = abs(PythagorasShear.signedArea([shear.m, shear.b, shear.d]))
        #expect(abs(2 * half - shear.m.x * shear.b.distance(to: shear.c)) < Self.close)
        #expect(shear.frames.allSatisfy { $0.pieces.allSatisfy { $0.corners.count == 3 } })
    }

    @Test("Captions follow the moves and the last one describes the end")
    func captions() {
        let shear = PythagorasShear.book
        #expect(shear.captions.count == shear.motions.count + 1)
        #expect(shear.caption(at: 0) == shear.captions[0])
        #expect(shear.caption(at: 0.5) == shear.captions[3])
        #expect(shear.caption(at: 1) == shear.captions.last)
        let words = shear.captions.flatMap { $0.split(whereSeparator: { !$0.isLetter }) }
        #expect(!words.contains { $0.count <= 2 && $0.allSatisfy(\.isUppercase) }, "letter-free, like the Byrne board")
    }
}
