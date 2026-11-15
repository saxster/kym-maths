import CoreGraphics
import Testing
@testable import KymMaths

/// The map sizes its nodes from its own measured width. If a row came out wider than the map, the map
/// grew, the width changed, and layout never finished: on iPhone at Extra Extra Large text the app froze.
@Suite("Euclid map layout")
struct EuclidMapLayoutTests {
    /// Every width from 0 to 1200 points in thirds of a point (an iPhone's pixel), plus the width that froze.
    private static let widths: [CGFloat] = (0...3600).map { CGFloat($0) / 3 } + [360.6666666666668]

    @Test("A full row of nodes never comes out wider than the map")
    func rowFitsTheMap() {
        let narrowest = EuclidSpineMapView.nodeMinWidth * 2 + EuclidSpineMapView.nodeGap
        for width in Self.widths {
            let layout = EuclidSpineMapView.nodeLayout(mapWidth: width)
            #expect(EuclidSpineMapView.rowWidth(layout) <= max(width, narrowest), "map \(width)")
        }
    }

    @Test("Measuring the map again after laying it out gives the same layout")
    func layoutSettles() {
        for width in Self.widths {
            // The map reads its width in whole points (`readWidth`), and grows if a row is wider.
            let layout = EuclidSpineMapView.nodeLayout(mapWidth: width.rounded(.down))
            let remeasured = max(width, EuclidSpineMapView.rowWidth(layout))
            let again = EuclidSpineMapView.nodeLayout(mapWidth: remeasured.rounded(.down))
            #expect(again.perRow == layout.perRow && again.width == layout.width, "map \(width)")
        }
    }
}
