import SwiftUI

// Small Patterned pieces the School book screens share. Candidates to promote into
// Design/Patterned once the rooms are merged.

/// The quiet close cross at the top corner of a sheet.
struct SheetCloseButton: View {
    @Environment(\.standardTheme) private var theme
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .standardType(.uiHeadline)
                .foregroundStyle(theme.mute(theme.ink))
                .frame(width: StandardAccessibility.touchTarget, height: StandardAccessibility.touchTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
        .keyboardShortcut(.cancelAction)
    }
}

/// A square icon button with a label for VoiceOver, for small tool rows.
struct ToolIconButton: View {
    @Environment(\.standardTheme) private var theme
    private let systemImage: String
    private let label: String
    private let isOn: Bool
    private let action: () -> Void

    init(_ label: String, systemImage: String, isOn: Bool = false, action: @escaping () -> Void) {
        self.label = label
        self.systemImage = systemImage
        self.isOn = isOn
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .standardType(.uiHeadline).fontWeight(.regular)
                .foregroundStyle(isOn ? theme.brass : theme.mute(theme.ink))
                .frame(width: StandardAccessibility.touchTarget, height: StandardAccessibility.touchTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
