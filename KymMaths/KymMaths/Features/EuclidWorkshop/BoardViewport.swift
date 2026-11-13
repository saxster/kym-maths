import SwiftUI

/// Maps board units (y up) to view points (y down), fitting an extent into a view with a margin.
struct BoardViewport {
    let scale: Double
    private let origin: CGPoint
    private let extent: BoardExtent

    init(fitting extent: BoardExtent, in size: CGSize, margin: CGFloat = 28) {
        self.extent = extent
        let usable = CGSize(width: max(1, size.width - 2 * margin), height: max(1, size.height - 2 * margin))
        scale = min(Double(usable.width) / max(extent.width, 1e-9), Double(usable.height) / max(extent.height, 1e-9))
        origin = CGPoint(
            x: (size.width - CGFloat(extent.width * scale)) / 2,
            y: (size.height - CGFloat(extent.height * scale)) / 2
        )
    }

    func toView(_ p: Vec2) -> CGPoint {
        CGPoint(x: origin.x + CGFloat((p.x - extent.min.x) * scale),
                y: origin.y + CGFloat((extent.max.y - p.y) * scale))
    }

    func toBoard(_ p: CGPoint) -> Vec2 {
        Vec2(x: extent.min.x + Double(p.x - origin.x) / scale,
             y: extent.max.y - Double(p.y - origin.y) / scale)
    }

    func length(_ boardUnits: Double) -> CGFloat { CGFloat(boardUnits * scale) }

    func boardLength(_ points: CGFloat) -> Double { Double(points) / scale }

    /// The view height that fits the extent at `width`, so the board keeps the figure's shape.
    static func height(for extent: BoardExtent, width: CGFloat, margin: CGFloat = 28, clampedTo range: ClosedRange<CGFloat>) -> CGFloat {
        let inner = max(1, width - 2 * margin)
        let ideal = inner * CGFloat(extent.height / max(extent.width, 1e-9)) + 2 * margin
        return min(max(ideal, range.lowerBound), range.upperBound)
    }
}

extension ColorRole {
    /// Byrne's colour for this role on drafting paper.
    var figureColor: Color { MathsFigureColor.roleColor(rawValue) }
}

/// Paths shared by the board, the step-order outline and the shear page.
enum BoardPaths {
    static func circle(_ centre: CGPoint, radius: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: centre.x - radius, y: centre.y - radius, width: 2 * radius, height: 2 * radius))
    }

    static func line(_ a: CGPoint, _ b: CGPoint) -> Path {
        var path = Path()
        path.move(to: a)
        path.addLine(to: b)
        return path
    }

    static func polygon(_ corners: [CGPoint]) -> Path {
        var path = Path()
        guard let first = corners.first else { return path }
        path.move(to: first)
        corners.dropFirst().forEach { path.addLine(to: $0) }
        path.closeSubpath()
        return path
    }

    /// A wedge at `vertex` between the rays to `p` and `q`, the smaller way round.
    static func wedge(_ p: CGPoint, vertex: CGPoint, _ q: CGPoint, radius: CGFloat) -> Path {
        let a = atan2(p.y - vertex.y, p.x - vertex.x)
        var b = atan2(q.y - vertex.y, q.x - vertex.x)
        var sweep = b - a
        while sweep > .pi { sweep -= 2 * .pi }
        while sweep < -.pi { sweep += 2 * .pi }
        b = a + sweep
        var path = Path()
        path.move(to: vertex)
        path.addArc(center: vertex, radius: radius, startAngle: .radians(Double(a)), endAngle: .radians(Double(b)), clockwise: sweep < 0)
        path.closeSubpath()
        return path
    }
}
