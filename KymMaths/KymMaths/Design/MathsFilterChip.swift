import SwiftUI

/// The kit's `StandardFilterChip` with a leading SF Symbol: transparent with a hairline when
/// inactive, solid ink with page-coloured text when active. KymMaths needs the symbol because
/// several strips use it to show state (a stamp earned, a chapter read, a 3D lab).
struct MathsFilterChip: View {
    @Environment(\.standardTheme) private var theme
    private let title: String
    private let systemImage: String
    private let isSelected: Bool
    private let action: () -> Void

    init(title: String, systemImage: String, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .standardType(.labelMd)
                .tracking(0.6)
                .padding(.horizontal, StandardSpacing.sm)
                .padding(.vertical, StandardSpacing.xs)
                .foregroundStyle(isSelected ? theme.bg : theme.ink)
                .background(Capsule().fill(isSelected ? theme.ink : Color.clear))
                .overlay(Capsule().stroke(isSelected ? Color.clear : theme.hairline(), lineWidth: 1))
                .frame(minHeight: StandardAccessibility.touchTarget)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
