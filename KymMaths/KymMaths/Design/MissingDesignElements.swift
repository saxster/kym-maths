import SwiftUI

// MARK: - Corner radii (the one scale)
public enum CornerRadius {
    public static let micro: CGFloat = 4
    public static let small: CGFloat = 8
    public static let medium: CGFloat = 14
    public static let large: CGFloat = 18
    public static let extraLarge: CGFloat = 26
    /// Every card's corner: set by the chosen theme.
    public static var card: CGFloat { CuratedColorScheme.current.style.cardRadius }
}

// MARK: - Missing Colors
extension Color {
    public static var masteryLearning: Color { Color.kymaiaPrimary }
    public static let masteryNew = Color.kymaiaMutedInk
    public static var kymaiaReward: Color { Color.kymaiaSecondary }
    public static var kymaiaRewardBackground: Color { Color.kymaiaSecondary.opacity(0.14) }
    public static var statStreak: Color { Color.kymaiaPrimary }
    public static let kymaiaIdentityBackground = Color.kymaiaLive.opacity(0.12)
    public static let statMastered = Color.kymaiaSuccess
    public static var therapeuticBackground: Color { Color.kymaiaBackground }
    public static let therapeuticText = Color.kymaiaInk
    public static var kymaiaCuriosityBackground: Color { Color.kymaiaPrimary.opacity(0.12) }
    public static let statDue = Color.kymaiaError
    
    static func phaseColor(_ phase: RitualPhase) -> Color {
        switch phase {
        case .identityPrime:
            return Color.kymaiaLive
        case .warmRetrieval, .breakthrough:
            return Color.kymaiaPrimary
        case .struggleZone:
            return Color.kymaiaError
        case .curiosityHook:
            return Color.kymaiaSecondary
        case .reflection:
            return Color.kymaiaSuccess
        case .complete:
            return Color.kymaiaSuccess
        }
    }
}

extension Font {
    public static let kymaiaSerifBody = Font.body
    public static let kymaiaSubheadline = Font.subheadline
    public static var kymaiaCardTitle: Font { .kymaiaHeadline }
    public static var kymaiaTitle2: Font {
        .system(.title2, design: CuratedColorScheme.current.style.headingFace.design).weight(.bold)
    }
    public static var kymaiaTitle3: Font {
        .system(.title3, design: CuratedColorScheme.current.style.headingFace.design).weight(.semibold)
    }
    public static var kymaiaCaption2: Font { .caption2 }
    public static var kymaiaMonospaced: Font { .system(.callout, design: .monospaced) }
}

extension Animation {
    public static let kymaiaStandard = Animation.spring(response: 0.4, dampingFraction: 0.6)
    public static let kymaiaFast = Animation.easeOut(duration: 0.2)
    public static let kymaiaQuick = Animation.easeOut(duration: 0.2)
}

extension StrokeWidth {
    public static let thin: CGFloat = 0.5
    public static let hairline: CGFloat = 0.25
}

// MARK: - Missing Styles
public struct KymaiaSecondaryButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(minHeight: 44)
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
            .background(Color.kymaiaPrimary.opacity(configuration.isPressed ? 0.18 : 0.12))
            .foregroundColor(.kymaiaPrimaryStrong)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .strokeBorder(Color.kymaiaControlBorder, lineWidth: StrokeWidth.light)
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
            .kymaiaPointerHighlight(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

public struct KymaiaOptionButtonStyle: ButtonStyle {
    var isSelected: Bool
    var isCorrect: Bool?

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(minHeight: 44)
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
            .background(isSelected ? (isCorrect == true ? Color.kymaiaSuccess : Color.kymaiaPrimary) : Color.kymaiaSurface)
            .foregroundColor(isSelected ? Color.kymaiaBackground : Color.kymaiaInk)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .strokeBorder(Color.kymaiaControlBorder, lineWidth: StrokeWidth.light)
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
            .kymaiaPointerHighlight(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

public struct KymaiaCardStyleModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.kymaiaSurface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
            .kymaiaCardChrome(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
    }
}

extension View {
    public func kymaiaCardStyle() -> some View {
        self.modifier(KymaiaCardStyleModifier())
    }
}

public struct KymaiaPrimaryButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(minHeight: 44)
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
            .background(Color.kymaiaPrimary.opacity(configuration.isPressed ? 0.76 : 1))
            .foregroundColor(Color.kymaiaBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
            .kymaiaPointerHighlight(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}
