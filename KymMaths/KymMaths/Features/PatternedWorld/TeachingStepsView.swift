import SwiftUI

/// A rewritten section's nine steps under their labels. The section is one link scope: a concept
/// links the first time a step names it, not again further down.
struct TeachingStepsView: View {
    let steps: [TeachingStep]
    let terms: [FormulaTermMapping]

    @Environment(\.conceptLibrary) private var library

    var body: some View {
        let linkedBefore = library.linker.linkedBefore(steps.map { ByrneMarkup.plain($0.text) })
        VStack(alignment: .leading, spacing: StandardSpacing.lg) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                TeachingStepRow(step: step, text: PatternedBook.byrneMarked(step.text, terms: terms),
                                linked: linkedBefore[index])
            }
        }
    }
}

private struct TeachingStepRow: View {
    let step: TeachingStep
    let text: String
    let linked: Set<String>

    @Environment(\.standardTheme) private var theme
    @State private var typed = ""
    @State private var marking: AnswerMarking?
    @FocusState private var typing: Bool

    var body: some View {
        switch step.kind {
        case .question:
            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                HStack(spacing: StandardSpacing.xs) {
                    Circle()
                        .fill(theme.patterned.color(.moves))
                        .frame(width: 7, height: 7)
                    Text("WONDER FIRST · QUESTION")
                        .patternedType(.kicker)
                        .foregroundStyle(theme.brass)
                }
                ConceptText(text, linked: linked)
                    .patternedType(.question)
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(StandardSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                    .fill(theme.patterned.wash(.stays).opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                    .strokeBorder(theme.brass.opacity(0.3), lineWidth: 1)
            )
        case .turn:
            VStack(alignment: .leading, spacing: StandardSpacing.sm) {
                labelled
                if let key = step.answerKey {
                    if typing {
                        BookKitSymbolicAccessoryBar { token in
                            typed += token
                        }
                    }
                    AnswerCheckRow(typed: $typed, typing: $typing, filled: false) {
                        marking = key.mark(typed)
                    }
                    .onChange(of: typed) { marking = nil }
                    if let marking {
                        Text(marking.isCorrect ? "Right." : "The answer is \(step.answer ?? "").")
                            .patternedType(.readingDefault)
                            .foregroundStyle(marking.isCorrect ? theme.patterned.provenColor : theme.patterned.assistedColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .paperCard()
        case .name:
            HStack(alignment: .top, spacing: StandardSpacing.sm) {
                BookKitSignpostMedallion(.remember)
                labelled
            }
            .padding(StandardSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                    .fill(theme.patterned.wash(.stays).opacity(0.5))
            )
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(theme.patterned.color(.stays))
                    .frame(width: 3)
            }
        case .mistake:
            HStack(alignment: .top, spacing: StandardSpacing.sm) {
                BookKitSignpostMedallion(.warning)
                labelled
            }
            .padding(.leading, StandardSpacing.md)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(theme.patterned.color(.moves))
                    .frame(width: 3)
            }
        case .example:
            HStack(alignment: .top, spacing: StandardSpacing.sm) {
                BookKitSignpostMedallion(.tip)
                labelled
            }
        case .sayBack:
            HStack(alignment: .top, spacing: StandardSpacing.sm) {
                BookKitSignpostMedallion(.remember)
                labelled
            }
            .padding(StandardSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                    .fill(theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                    .strokeBorder(theme.brass.opacity(0.35), lineWidth: 1)
            )
        default:
            labelled
        }
    }

    private var labelled: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            if let label = step.kind.label {
                Kicker(label, muted: step.kind != .turn)
            }
            ConceptText(text, linked: linked)
                .patternedType(.reading)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
