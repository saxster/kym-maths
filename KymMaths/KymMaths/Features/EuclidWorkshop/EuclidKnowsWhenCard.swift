import SwiftUI

/// The Daily Flow's knows-when check: a word problem with no figure, and three propositions she
/// has built. Only the first answer counts.
struct EuclidKnowsWhenCard: View {
    @Environment(\.standardTheme) private var theme
    let question: EuclidKnowsWhenQuestion
    let choice: PropositionID?
    let isRight: Bool
    let onChoose: (PropositionID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            Kicker("Euclid's Workshop · Knows when")
            Text(question.problem)
                .patternedType(.readingDefault)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("Which construction solves it?")
                .standardType(.uiCaption)
                .foregroundStyle(theme.mute(theme.ink))
            FlowLayout(spacing: StandardSpacing.xs) {
                ForEach(question.options, id: \.self) { option in
                    Button {
                        onChoose(option)
                    } label: {
                        Label("\(option) · \(EuclidSpine.proposition(option)?.title ?? "")", systemImage: symbol(for: option))
                    }
                    .buttonStyle(EuclidChipStyle(isLit: choice == option))
                    .disabled(choice != nil && choice != option)
                    .accessibilityAddTraits(choice == option ? .isSelected : [])
                }
            }
            if choice != nil {
                HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.xs) {
                    StatusTag(isRight ? .secure : .working, label: isRight ? "Knows when" : "Not this time")
                    Text(isRight
                         ? "Yes. Knowing when to reach for it is the last lamp, and it is lit."
                         : "It was \(question.proposition.raw): \(EuclidSpine.proposition(question.proposition)?.title.lowercased() ?? ""). It will come round again.")
                        .standardType(.uiBody)
                        .foregroundStyle(isRight ? theme.patterned.provenColor : theme.patterned.assistedColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .paperCard()
    }

    private func symbol(for option: PropositionID) -> String {
        guard let choice else { return "circle" }
        if option == question.proposition { return "checkmark.circle.fill" }
        return option == choice ? "xmark.circle.fill" : "circle"
    }
}
