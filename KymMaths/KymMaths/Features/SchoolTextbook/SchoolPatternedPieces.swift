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

/// One short answer and its Check button. Return checks too.
struct AnswerCheckRow: View {
    @Environment(\.standardTheme) private var theme
    @Binding var typed: String
    var typing: FocusState<Bool>.Binding
    let check: () -> Void

    private var isEmpty: Bool { typed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        HStack(spacing: StandardSpacing.sm) {
            TextField("Your answer", text: $typed)
                .focused(typing)
                .learnerTextInput(.retrieval)
                .textFieldStyle(.plain)
                .patternedType(.mathInline)
                .foregroundStyle(theme.ink)
                .padding(.horizontal, StandardSpacing.sm)
                .frame(minHeight: StandardAccessibility.touchTarget)
                .background(RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous).fill(theme.bg))
                .overlay(RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous).strokeBorder(theme.hairline(), lineWidth: 1))
                .accessibilityLabel("Your answer")
                .onSubmit { if !isEmpty { check() } }
            Button("Check") { check() }
                .buttonStyle(InkButtonStyle())
                .disabled(isEmpty)
        }
    }
}
