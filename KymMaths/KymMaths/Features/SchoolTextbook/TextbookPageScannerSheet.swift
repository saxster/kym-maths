import SwiftUI

// MARK: - Textbook Page Scanner & OCR Notes Sheet (Deborah Barton OUP Complete Mathematics 8)

struct TextbookPageScannerSheet: View {
    let topic: SchoolMathsTopic
    @Bindable var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var bookType: String = "learners_book"
    @State private var pageNumber: Int = 7
    @State private var ocrText: String = ""

    var body: some View {
        NavigationStack {
            JournalPage {
                JournalSection(
                    title: "Attach Page from Deborah Barton's Student Book",
                    eyebrow: "Topic \(topic.code) · \(topic.title) (OUP p. \(topic.learnersBookPage))"
                ) {
                    JournalCard {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Capture or paste an exercise, teacher note, or worked problem from Kym's physical Oxford Cambridge Lower Secondary Complete Mathematics 8 textbook so it stays indexed beside Topic \(topic.code).")
                                .font(Typography.callout)
                                .foregroundStyle(Color.kymaiaMutedInk)

                            HStack(spacing: Spacing.md) {
                                Text("Page Number:")
                                    .font(Typography.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.kymaiaInk)
                                Stepper(value: $pageNumber, in: 1...265) {
                                    Text("p. \(pageNumber)")
                                        .font(Typography.mono)
                                }
                            }

                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Extracted Problem or Margin Note")
                                    .font(Typography.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.kymaiaInk)
                                TextEditor(text: $ocrText)
                                    .frame(minHeight: 160)
                                    .padding(Spacing.xs)
                                    .quietPanelBackground()
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Spacing.radiusMD, style: .continuous)
                                            .strokeBorder(Color.kymaiaHairline, lineWidth: 1)
                                    )
                            }

                            HStack {
                                Button("Pre-fill Topic Summary") {
                                    ocrText = "OUP Complete Mathematics 8 p. \(topic.learnersBookPage) — \(topic.code) \(topic.title):\n\(topic.summary)\nWatchouts: \(topic.cambridgeWatchouts.joined(separator: " | "))"
                                }
                                .buttonStyle(JournalSecondaryButtonStyle())

                                Spacer()

                                Button("Save Captured Page") {
                                    guard !ocrText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                                    store.saveCapturedTextbookPage(
                                        topicId: topic.code,
                                        bookType: bookType,
                                        pageNumber: pageNumber,
                                        ocrText: ocrText
                                    )
                                    dismiss()
                                }
                                .buttonStyle(BrassButtonStyle())
                            }
                        }
                    }
                }
            }
            .navigationTitle("Capture Textbook Page")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                pageNumber = topic.learnersBookPage
            }
        }
    }
}
