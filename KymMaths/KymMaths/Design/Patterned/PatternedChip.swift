import SwiftUI

/// A choice among a few (a paper style, a stage, how sure, a chapter): ink when chosen, paper with
/// a hairline otherwise. It picks, it does not act, so it is never the screen's filled button.
struct PatternedChip: View {
    @Environment(\.standardTheme) private var theme
    private let title: String
    private let systemImage: String?
    private let isSelected: Bool
    private let round: Bool
    private let action: () -> Void

    /// `round` draws a circle sized for one or two digits, such as a chapter number.
    init(_ title: String, systemImage: String? = nil, isSelected: Bool, round: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.isSelected = isSelected
        self.round = round
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: StandardSpacing.xxs + 2) {
                if let systemImage {
                    Image(systemName: systemImage).imageScale(.small)
                }
                Text(title)
                    .lineLimit(1)
                    .monospacedDigit()
            }
            .standardType(.uiBody)
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundStyle(isSelected ? theme.bg : theme.ink)
            .padding(.horizontal, round ? StandardSpacing.xxs : StandardSpacing.md)
            .frame(minWidth: 36, minHeight: 34)
            .background(Capsule().fill(isSelected ? theme.ink : theme.surface))
            .overlay(Capsule().strokeBorder(isSelected ? Color.clear : theme.hairline(), lineWidth: 1))
            .frame(minHeight: StandardAccessibility.touchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
