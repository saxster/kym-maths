import SwiftUI

/// Checks the smaller skill a repeated slip rests on, one probe at a time, then sends Kym back to the question.
/// Closing the sheet early leaves the walk-back pending, so Hand in stays shut until the check is finished.
struct WalkBackSheet: View {
    let walkBack: WalkBack
    let store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.standardTheme) private var theme

    @State private var results: [Bool] = []
    @State private var typed = ""
    @State private var missed = false
    @FocusState private var typing: Bool

    private var footing: Footing { walkBack.footing }

    private var outcome: Bool? {
        missed ? nil : WalkBackRule.checkOutcome(results, probeCount: footing.probes.count)
    }

    private var probeIndex: Int { missed ? results.count - 1 : results.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StandardSpacing.lg) {
                SheetCloseButton { dismiss() }
                    .padding(.leading, -StandardSpacing.sm)

                VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                    Kicker("Check the step underneath")
                    Text(footing.skill)
                        .standardType(.headlineLg)
                        .foregroundStyle(theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text("Work it on paper, then type the answer.")
                        .patternedType(.readingDefault)
                        .foregroundStyle(theme.mute(theme.ink))
                }

                if let passed = outcome {
                    endCard(passed: passed)
                } else {
                    probeCard(footing.probes[probeIndex])
                }
            }
            .padding(.horizontal, StandardSpacing.xl)
            .padding(.vertical, StandardSpacing.lg)
        }
        .background(theme.bg)
        .onAppear { typing = true }
    }

    private func probeCard(_ probe: FootingProbe) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            Kicker("Question \(probeIndex + 1) of \(footing.probes.count)", muted: true)
            if !missed, results.last == true {
                Text("Right. Here is the next one.")
                    .standardType(.uiBody)
                    .foregroundStyle(theme.patterned.provenColor)
            }
            Text(probe.prompt)
                .patternedType(.question)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            if missed {
                Rectangle().fill(theme.hairline()).frame(height: 1)
                Text(footing.teach)
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text("The answer is \(probe.answer).")
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.patterned.assistedColor)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Next", action: next)
                    .buttonStyle(InkButtonStyle())
            } else {
                HStack(spacing: StandardSpacing.sm) {
                    TextField("Your answer", text: $typed)
                        .focused($typing)
                        .learnerTextInput(.retrieval)
                        .textFieldStyle(.plain)
                        .patternedType(.mathInline)
                        .foregroundStyle(theme.ink)
                        .padding(.horizontal, StandardSpacing.sm)
                        .frame(minHeight: StandardAccessibility.touchTarget)
                        .background(RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous).fill(theme.bg))
                        .overlay(RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous).strokeBorder(theme.hairline(), lineWidth: 1))
                        .accessibilityLabel("Your answer")
                        .onSubmit { check(probe) }
                    Button("Check") { check(probe) }
                        .buttonStyle(InkButtonStyle())
                        .disabled(typed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .paperCard()
    }

    private func endCard(passed: Bool) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            if passed {
                Text("That step is solid. Back to the question.")
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.ink)
            } else {
                Text(footing.teach)
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Back to the question. If the slip comes back, we'll check this step again.")
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.mute(theme.ink))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button("Back to the question") {
                store.finishWalkBack(passed: passed)
                dismiss()
            }
            .buttonStyle(InkButtonStyle())
        }
        .paperCard()
    }

    private func check(_ probe: FootingProbe) {
        guard !typed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let right = probe.answerKey.mark(typed).isCorrect
        results.append(right)
        missed = !right
        if right {
            typed = ""
            typing = true
        }
    }

    private func next() {
        missed = false
        typed = ""
        typing = true
    }
}
