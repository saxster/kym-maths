import SwiftUI

/// The Daily Flow's knows-when check: a word problem with no figure, and three propositions she
/// has built. Only the first answer counts.
struct EuclidKnowsWhenCard: View {
    let question: EuclidKnowsWhenQuestion
    let choice: PropositionID?
    let isRight: Bool
    let onChoose: (PropositionID) -> Void

    var body: some View {
        JournalCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                JournalBadge(text: "Euclid's Workshop · Knows when", symbol: "compass.drawing", tone: .info)
                Text(question.problem)
                    .font(Typography.body)
                    .foregroundStyle(Color.kymaiaInk)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Which construction solves it?")
                    .font(Typography.caption.weight(.semibold))
                    .foregroundStyle(Color.kymaiaMutedInk)
                FlowLayout(spacing: Spacing.xs) {
                    ForEach(question.options, id: \.self) { option in
                        MathsFilterChip(
                            title: "\(option) · \(EuclidSpine.proposition(option)?.title ?? "")",
                            systemImage: symbol(for: option),
                            isSelected: choice == option
                        ) {
                            onChoose(option)
                        }
                        .disabled(choice != nil && choice != option)
                    }
                }
                if choice != nil {
                    Text(isRight
                         ? "Yes. Knowing when to reach for it is the last lamp, and it is lit."
                         : "Not this time. It was \(question.proposition): \(EuclidSpine.proposition(question.proposition)?.title.lowercased() ?? ""). It will come round again.")
                        .font(Typography.caption.weight(.semibold))
                        .foregroundStyle(isRight ? Color.kymaiaSuccess : Color.kymaiaWarning)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func symbol(for option: PropositionID) -> String {
        guard let choice else { return "circle" }
        if option == question.proposition { return "checkmark.circle.fill" }
        return option == choice ? "xmark.circle.fill" : "circle"
    }
}
