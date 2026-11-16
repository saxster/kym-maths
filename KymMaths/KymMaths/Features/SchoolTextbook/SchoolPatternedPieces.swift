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

/// How the marker read a typed answer, under the answer box, so a misreading such as n2 for n² shows
/// before she checks. Nothing shows for a plain number or for words.
struct AnswerReadsAs: View {
    @Environment(\.standardTheme) private var theme
    let typed: String

    var body: some View {
        if let reading = AnswerExpression.readsAs(typed) {
            HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.xs) {
                Text("Reads as")
                    .standardType(.uiCaption)
                    .foregroundStyle(theme.mute(theme.ink))
                Text(reading)
                    .patternedType(.readingSmall, measured: false)
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Reads as \(reading)")
        }
    }
}

/// One short answer and its Check button. Return checks too.
struct AnswerCheckRow: View {
    @Environment(\.standardTheme) private var theme
    @Binding var typed: String
    var typing: FocusState<Bool>.Binding
    /// False on a page that already has its one filled button, such as a chapter's "Your turn".
    var filled = true
    let check: () -> Void

    private var isEmpty: Bool { typed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
            field
            AnswerReadsAs(typed: typed)
        }
    }

    private var field: some View {
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
            if filled {
                Button("Check") { check() }
                    .buttonStyle(InkButtonStyle())
                    .disabled(isEmpty)
            } else {
                Button("Check") { check() }
                    .buttonStyle(OutlineButtonStyle())
                    .disabled(isEmpty)
            }
        }
    }
}
