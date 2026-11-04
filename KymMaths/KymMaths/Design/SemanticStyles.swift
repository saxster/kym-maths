import SwiftUI

enum KymaiaSemanticStyle {
    static var appBackground: Color { .kymaiaBackground }
    static var groupedBackground: Color { .kymaiaGroupedBackground }
    static var surface: Color { .kymaiaSurface }
    static var elevatedSurface: Color { .kymaiaElevatedSurface }
    static var primaryText: Color { .kymaiaInk }
    static var secondaryText: Color { .kymaiaMutedInk }
    static var tertiaryText: Color { .kymaiaTertiaryInk }
    static var hairline: Color { .kymaiaHairline }
    static var accent: Color { .kymaiaPrimary }
    static var success: Color { .kymaiaSuccess }
    static var warning: Color { .kymaiaWarning }
    static var destructive: Color { .kymaiaError }
    static var canvas: Color { .kymaiaCanvas }
    static var sidebar: Color { .kymaiaSidebar }
    static var paper: Color { .kymaiaPaper }
    static var paperRaised: Color { .kymaiaPaperRaised }
    static var controlFill: Color { .kymaiaControlFill }
    static var selectionFill: Color { .kymaiaSelectionFill }
    static var focusRing: Color { .kymaiaFocusRing }
    static var scrim: Color { .kymaiaScrim }

    static func phaseAccent(_ phase: RitualPhase) -> Color {
        Color.phaseColor(phase)
    }
}

extension ShapeStyle where Self == Color {
    static var kymaiaAppBackground: Color { KymaiaSemanticStyle.appBackground }
    static var kymaiaGroupedBackground: Color { KymaiaSemanticStyle.groupedBackground }
    static var kymaiaSurfaceStyle: Color { KymaiaSemanticStyle.surface }
    static var kymaiaElevatedSurface: Color { KymaiaSemanticStyle.elevatedSurface }
    static var kymaiaPrimaryText: Color { KymaiaSemanticStyle.primaryText }
    static var kymaiaAccent: Color { KymaiaSemanticStyle.accent }
    static var kymaiaSuccessStyle: Color { KymaiaSemanticStyle.success }
    static var kymaiaWarningStyle: Color { KymaiaSemanticStyle.warning }
    static var kymaiaDestructive: Color { KymaiaSemanticStyle.destructive }
}

/// Fixed sizes inside drawn mathematics figures (plate pins, Pólya bar models, the scratchpad's
/// unit tiles), where the type is part of the drawing's geometry and must not scale with Dynamic
/// Type. Everything outside a figure uses the `Font.kymaia*` tokens or `.standardType(_:)`.
enum MathsFigureType {
    static let label = Font.system(size: 11, weight: .bold)
    static let labelMedium = Font.system(size: 11, weight: .semibold)
    static let labelMono = Font.system(size: 11, weight: .bold, design: .monospaced)
    static let labelMonoMedium = Font.system(size: 11, weight: .semibold, design: .monospaced)
    static let note = Font.system(size: 10.5, weight: .bold)
    static let noteMono = Font.system(size: 10.5, weight: .bold, design: .monospaced)
    static let hint = Font.system(size: 10.5, weight: .medium)
    static let tally = Font.system(size: 10, weight: .bold)
    static let unitTile = Font.system(size: 10, weight: .semibold, design: .monospaced)
    static let axisTick = Font.system(size: 9, design: .monospaced)
    static let areaTerm = Font.system(size: 13, weight: .bold)
    static let setSymbol = Font.system(size: 14, weight: .bold, design: .serif)
}

/// Corner radii drawn inside figure `Canvas`es, sized to the figure's own geometry.
enum MathsFigureRadius {
    /// A bar-model or scratchpad unit tile.
    static let tile: CGFloat = 4
    /// A Pólya bar segment.
    static let bar: CGFloat = 5
    /// A grid cell in the n × (n+1) rectangle.
    static let cell: CGFloat = 2
    /// A figure's framing box or a shape drawn on the tutor board.
    static let frame: CGFloat = 10
}

/// Fixed colours of the figure plates: they are printed on drafting paper, so they don't follow
/// the theme.
enum MathsFigureColor {
    /// Drafting rag paper behind every plate.
    static let paper = Color(red: 0.965, green: 0.953, blue: 0.925)
    /// A callout pin's number, on its red or green disc.
    static let pinNumber = Color(white: 1)
    /// A callout pin's capsule, lifted off the plate.
    static let pinCapsule = Color(white: 1).opacity(0.92)
}
