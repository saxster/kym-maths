import SwiftUI

/// A smaller sister of the question, worked one short step at a time, then back to her own.
/// Nothing here is recorded or counts as help.
struct StuckSheetView: View {
    let sheet: StuckSheet
    @Environment(\.dismiss) private var dismiss
    @Environment(\.standardTheme) private var theme

    @State private var state = StuckSheetState.start
    @State private var typed = ""
    @FocusState private var typing: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StandardSpacing.lg) {
                SheetCloseButton { dismiss() }
                    .padding(.leading, -StandardSpacing.sm)

                VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                    Kicker("A smaller one first")
                    ConceptText(sheet.sister)
                        .patternedType(.question)
                        .foregroundStyle(theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text("Work it on paper, then type each step.")
                        .patternedType(.readingDefault)
                        .foregroundStyle(theme.mute(theme.ink))
                }

                if case let .finished(afterRight) = state {
                    endCard(afterRight: afterRight)
                } else if let step = state.step, sheet.steps.indices.contains(step) {
                    stepCard(sheet.steps[step], number: step + 1)
                }
            }
            .padding(.horizontal, StandardSpacing.xl)
            .padding(.vertical, StandardSpacing.lg)
        }
        .background(theme.bg)
        .conceptLinks()
        .onAppear { typing = true }
    }

    private func stepCard(_ step: StuckStep, number: Int) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            Kicker("Step \(number) of \(sheet.steps.count)", muted: true)
            if case .asking(_, afterRight: true) = state {
                Text("Right.")
                    .standardType(.uiBody)
                    .foregroundStyle(theme.patterned.provenColor)
            }
            ConceptText(step.prompt)
                .patternedType(.question)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            switch state {
            case let .retrying(_, mistake):
                Text("\(mistake.name). \(mistake.nextStep)")
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.patterned.assistedColor)
                    .fixedSize(horizontal: false, vertical: true)
                AnswerCheckRow(typed: $typed, typing: $typing, check: check)
            case .shown:
                Rectangle().fill(theme.hairline()).frame(height: 1)
                ConceptText(step.working)
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text("The answer is \(step.answer).")
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.patterned.assistedColor)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Next", action: next)
                    .buttonStyle(OutlineButtonStyle())
            default:
                AnswerCheckRow(typed: $typed, typing: $typing, check: check)
            }
        }
        .paperCard()
    }

    private func endCard(afterRight: Bool) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            if afterRight {
                Text("Right.")
                    .standardType(.uiBody)
                    .foregroundStyle(theme.patterned.provenColor)
            }
            Text("Now try your own question.")
                .patternedType(.readingDefault)
                .foregroundStyle(theme.ink)
            Button("Back to my question") { dismiss() }
                .buttonStyle(InkButtonStyle())
        }
        .paperCard()
    }

    private func check() {
        guard !typed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        state = state.checking(typed, in: sheet)
        if case .asking = state { typed = "" }
        typing = true
    }

    private func next() {
        state = state.next(in: sheet)
        typed = ""
        typing = true
    }
}
