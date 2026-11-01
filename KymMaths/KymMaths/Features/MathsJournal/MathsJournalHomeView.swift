import SwiftUI

// MARK: - Room 6: Proof & Mathematical Notebook Journal (Cornell, Proof Log, Singapore CPA & Lab Log)

struct MathsJournalHomeView: View {
    @Bindable var store: AppStore
    @Environment(\.themeTokens) private var tokens

    @State private var selectedEntryId: String?
    @State private var title: String = ""
    @State private var templateKind: String = "proof_log"
    @State private var paperStyle: String = "grid"
    @State private var linkedTopicCode: String = "1.4"
    @State private var cueText: String = ""
    @State private var bodyText: String = ""
    @State private var summaryText: String = ""
    @State private var conjectureText: String = ""
    @State private var givenInvariantsText: String = ""
    @State private var targetProveText: String = ""
    @State private var polyaStepsText: String = ""

    private let templates = [
        ("proof_log", "Mathematical Proof Log"),
        ("cornell", "Cornell Theorem Notes"),
        ("construction", "Geometric Construction & Bar Model"),
        ("lab_log", "3D Atlas Investigation")
    ]

    var body: some View {
        JournalPage {
            // 1. Header & Saved Entries Strip
            JournalCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("MATHEMATICAL PROOF & CORNELL JOURNAL")
                                .font(Typography.eyebrow)
                                .foregroundStyle(tokens.accent)
                            Text("Conjectures, Invariants & Step-by-Step Proofs")
                                .font(Typography.title2)
                                .foregroundStyle(tokens.primary)
                        }
                        Spacer()
                        Button {
                            startNewEntry()
                        } label: {
                            Label("New Proof Entry", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(JournalPrimaryButtonStyle())
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.xs) {
                            ForEach(store.journalEntries) { entry in
                                JournalChip(
                                    title: entry.title,
                                    systemImage: "doc.text.fill",
                                    isSelected: selectedEntryId == entry.id
                                ) {
                                    loadEntry(entry)
                                }
                            }
                        }
                    }
                }
            }

            // 2. Active Proof Editor
            JournalSection(
                title: title.isEmpty ? "Untitled Proof Entry" : title,
                eyebrow: "Template: \(templateKind.replacingOccurrences(of: "_", with: " ").capitalized) · Paper: \(paperStyle.capitalized)"
            ) {
                JournalCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack(spacing: Spacing.md) {
                            TextField("Entry Title (e.g., HCF × LCM = a × b Proof)", text: $title)
                                .textFieldStyle(.roundedBorder)
                                .font(Typography.headline)

                            Menu {
                                ForEach(templates, id: \.0) { code, label in
                                    Button(label) { templateKind = code }
                                }
                            } label: {
                                Label("Template", systemImage: "rectangle.3.group")
                            }

                            Menu {
                                ForEach(["grid", "dots", "lined", "blank", "cornell"], id: \.self) { p in
                                    Button(p.capitalized) { paperStyle = p }
                                }
                            } label: {
                                Label("Paper: \(paperStyle.capitalized)", systemImage: "square.grid.3x3")
                            }
                        }

                        // Structured Proof Scaffolding
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: Spacing.sm)], spacing: Spacing.sm) {
                            proofFieldCard(label: "Conjecture / Formula Statement", text: $conjectureText)
                            proofFieldCard(label: "Given Data & Visual Invariant", text: $givenInvariantsText)
                            proofFieldCard(label: "Target Unknown / To Prove (Q.E.D.)", text: $targetProveText)
                            proofFieldCard(label: "Pólya Heuristic & Construction", text: $polyaStepsText)
                        }

                        // Cornell Cue + Main Derivation Body on Paper Background
                        HStack(alignment: .top, spacing: Spacing.md) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("KEY DEFINITIONS & AXIOMS")
                                    .font(Typography.eyebrow)
                                    .foregroundStyle(tokens.accent)
                                TextEditor(text: $cueText)
                                    .frame(minHeight: 200)
                                    .padding(Spacing.xs)
                                    .background(RoundedRectangle(cornerRadius: Spacing.radiusSM).fill(tokens.surfaceElevated))
                            }
                            .frame(width: 220)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("STEP-BY-STEP DERIVATION & VISUAL SKETCH NOTES")
                                    .font(Typography.eyebrow)
                                    .foregroundStyle(tokens.accent)
                                ZStack {
                                    JournalPaperBackground(style: JournalPaperStyle(rawValue: paperStyle) ?? .grid)
                                        .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusSM))
                                    TextEditor(text: $bodyText)
                                        .scrollContentBackground(.hidden)
                                        .font(Typography.mono)
                                        .padding(Spacing.xs)
                                }
                                .frame(minHeight: 200)
                                .overlay(RoundedRectangle(cornerRadius: Spacing.radiusSM).strokeBorder(tokens.borderSubtle, lineWidth: 1))
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("SUMMARY & GENERALISATION (LOOK BACK)")
                                .font(Typography.eyebrow)
                                .foregroundStyle(tokens.positive)
                            TextField("Summarise why this invariant holds in 1–2 sentences...", text: $summaryText)
                                .textFieldStyle(.roundedBorder)
                        }

                        HStack {
                            Button("Save Proof Journal Entry") {
                                saveCurrentEntry()
                            }
                            .buttonStyle(JournalPrimaryButtonStyle())

                            if let id = selectedEntryId, store.journalEntries.count > 1 {
                                Button("Delete Entry") {
                                    store.deleteJournalEntry(id: id)
                                    if let first = store.journalEntries.first {
                                        loadEntry(first)
                                    }
                                }
                                .buttonStyle(JournalSecondaryButtonStyle())
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
        .onAppear {
            if selectedEntryId == nil, let first = store.journalEntries.first {
                loadEntry(first)
            }
        }
    }

    @ViewBuilder
    private func proofFieldCard(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Typography.caption.weight(.bold))
                .foregroundStyle(tokens.secondary)
            TextField(label, text: text)
                .textFieldStyle(.roundedBorder)
                .font(Typography.caption)
        }
        .padding(Spacing.xs)
        .background(RoundedRectangle(cornerRadius: Spacing.radiusSM).fill(tokens.surfaceElevated))
    }

    private func loadEntry(_ entry: LabJournalEntryRecord) {
        selectedEntryId = entry.id
        title = entry.title
        templateKind = entry.templateKind
        paperStyle = entry.paperStyle
        linkedTopicCode = entry.linkedTopicCode ?? "1.4"
        cueText = entry.cueColumnText
        bodyText = entry.bodyNotesText
        summaryText = entry.summaryText
        conjectureText = entry.hypothesisText
        givenInvariantsText = entry.independentVarText
        targetProveText = entry.dependentVarText
        polyaStepsText = entry.controlVarsText
    }

    private func startNewEntry() {
        selectedEntryId = "journal-\(UUID().uuidString.prefix(8))"
        title = "New Mathematical Proof — Topic \(store.selectedTopicCode)"
        templateKind = "proof_log"
        paperStyle = store.defaultScratchpadPaperStyle
        linkedTopicCode = store.selectedTopicCode
        cueText = ""
        bodyText = ""
        summaryText = ""
        conjectureText = ""
        givenInvariantsText = ""
        targetProveText = ""
        polyaStepsText = ""
    }

    private func saveCurrentEntry() {
        let id = selectedEntryId ?? "journal-\(UUID().uuidString.prefix(8))"
        let now = Date()
        let entry = LabJournalEntryRecord(
            id: id,
            title: title.isEmpty ? "Mathematical Proof Note" : title,
            templateKind: templateKind,
            paperStyle: paperStyle,
            linkedTopicCode: linkedTopicCode,
            linkedChapterNumber: store.selectedChapterNumber,
            linkedWidgetId: store.selectedWidgetId,
            cueColumnText: cueText,
            bodyNotesText: bodyText,
            summaryText: summaryText,
            hypothesisText: conjectureText,
            independentVarText: givenInvariantsText,
            dependentVarText: targetProveText,
            controlVarsText: polyaStepsText,
            drawingData: nil,
            snapshotPNGData: nil,
            createdAt: now,
            updatedAt: now
        )
        store.saveJournalEntry(entry)
        selectedEntryId = id
    }
}
