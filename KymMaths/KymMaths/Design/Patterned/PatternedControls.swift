import SwiftUI

extension View {
    /// A text field on sunk paper with a hairline, as in the Figma inputs. `dashed` is a blank
    /// waiting for an answer; `emphasis` is the field the screen is asking for.
    func paperField(dashed: Bool = false, emphasis: Bool = false) -> some View {
        modifier(PaperField(dashed: dashed, emphasis: emphasis))
    }
}

private struct PaperField: ViewModifier {
    @Environment(\.standardTheme) private var theme
    let dashed: Bool
    let emphasis: Bool

    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .patternedType(.readingDefault)
            .foregroundStyle(theme.ink)
            .padding(.horizontal, StandardSpacing.md)
            .padding(.vertical, StandardSpacing.xs)
            .frame(minHeight: StandardAccessibility.touchTarget)
            .background(
                RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                    .fill(theme.patterned.sunkColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                    .strokeBorder(
                        emphasis ? theme.ink.opacity(0.7) : theme.hairline(),
                        style: StrokeStyle(lineWidth: emphasis ? 1.2 : 1, dash: dashed ? [4, 3] : [])
                    )
            )
    }
}

/// Title first, icon after: "Add test →".
struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: StandardSpacing.xs) {
            configuration.title
            configuration.icon.imageScale(.small)
        }
    }
}
