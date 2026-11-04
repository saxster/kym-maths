import SwiftUI

extension View {
    /// The chrome of the kit's `QuietPanel` (surface fill, `rounded.lg` corners, a hairline) for a
    /// panel nested in a card that already sets its own padding and layout. In The Standard the
    /// card and the elevated surface share one colour, so the hairline is what separates the panel.
    func quietPanelBackground() -> some View {
        modifier(QuietPanelBackground())
    }
}

private struct QuietPanelBackground: ViewModifier {
    @Environment(\.standardTheme) private var theme

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                    .fill(theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                    .strokeBorder(theme.hairline(), lineWidth: 1)
            )
    }
}
