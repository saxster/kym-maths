import SwiftUI

// MARK: - School Deadlines & Checkpoint Readiness Planner Sheet

struct CalendarHomeView: View {
    @Bindable var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var newTitle: String = ""
    @State private var newUnitsCSV: String = "1,2,6,7"
    @State private var newDueAt: Date = Date().addingTimeInterval(7 * 86_400)
    @State private var newKind: String = "unit_test"
    @State private var newNotes: String = ""

    var body: some View {
        NavigationStack {
            JournalPage {
                JournalSection(
                    title: "School Maths Tests & Checkpoint Deadlines",
                    eyebrow: "Reverse-Engineered Spaced Proof Schedule"
                ) {
                    ForEach(store.deadlines) { deadline in
                        JournalCard {
                            HStack(alignment: .top, spacing: Spacing.md) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        JournalBadge(text: "Chapters \(deadline.unitNumbersCSV)", symbol: "book.closed", tone: .accent)
                                        JournalBadge(text: deadline.kind.replacingOccurrences(of: "_", with: " ").capitalized, symbol: "calendar", tone: .info)
                                    }
                                    Text(deadline.title)
                                        .font(Typography.headline)
                                        .foregroundStyle(Color.kymaiaInk)
                                    Text(deadline.notes)
                                        .font(Typography.caption)
                                        .foregroundStyle(Color.kymaiaMutedInk)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 6) {
                                    Text(deadline.dueAt, style: .date)
                                        .font(Typography.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.kymaiaPrimary)
                                    Button("Remove") {
                                        store.deleteDeadline(id: deadline.id)
                                    }
                                    .font(Typography.caption)
                                    .foregroundStyle(Color.kymaiaMutedInk)
                                }
                            }
                        }
                    }
                }

                JournalSection(
                    title: "Add New School Test or Review Target",
                    eyebrow: "Keep Kym Ahead of Classroom Pacing"
                ) {
                    JournalCard {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            TextField("Target Title (e.g., Review A & Algebra Checkpoint)", text: $newTitle)
                                .textFieldStyle(.roundedBorder)
                            TextField("OUP Chapter Numbers (e.g., 1,2,6,7,9)", text: $newUnitsCSV)
                                .textFieldStyle(.roundedBorder)
                            DatePicker("Target Date", selection: $newDueAt, displayedComponents: .date)
                            TextField("Notes / Focus Topics", text: $newNotes)
                                .textFieldStyle(.roundedBorder)

                            Button("Add School Target") {
                                guard !newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                                store.addDeadline(
                                    title: newTitle,
                                    unitNumbersCSV: newUnitsCSV,
                                    dueAt: newDueAt,
                                    kind: newKind,
                                    notes: newNotes
                                )
                                newTitle = ""
                                newNotes = ""
                            }
                            .buttonStyle(JournalPrimaryButtonStyle())
                        }
                    }
                }
            }
            .navigationTitle("Maths Deadlines & Planner")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
