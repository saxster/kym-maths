import SwiftUI

// MARK: - Room 6: Proof & Mathematical Notebook Journal (Cornell, Proof Log, Singapore CPA & Lab Log)

struct MathsJournalHomeView: View {
    @Bindable var store: AppStore

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
            EditorialHeader(
                eyebrow: "Mathematical Proof & Cornell Journal",
                title: "Conjectures, Invariants & Step-by-Step Proofs",
                subtitle: "State a conjecture, find the invariant, then prove it one step at a time."
            )

            // 1. Saved Entries Strip
            JournalCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack {
                        Spacer()
                        Button {
                            startNewEntry()
                        } label: {
                            Label("New Proof Entry", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(JournalSecondaryButtonStyle())
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.xs) {
                            ForEach(store.journalEntries) { entry in
                                MathsFilterChip(
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
                                    .foregroundStyle(Color.kymaiaPrimary)
                                TextEditor(text: $cueText)
                                    .frame(minHeight: 200)
                                    .padding(Spacing.xs)
                                    .quietPanelBackground()
                            }
                            .frame(width: 220)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("STEP-BY-STEP DERIVATION & VISUAL SKETCH NOTES")
                                    .font(Typography.eyebrow)
                                    .foregroundStyle(Color.kymaiaPrimary)
                                ZStack {
                                    JournalPaperBackground(style: JournalPaperStyle(rawValue: paperStyle) ?? .grid)
                                        .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusSM))
                                    TextEditor(text: $bodyText)
                                        .scrollContentBackground(.hidden)
                                        .font(Typography.mono)
                                        .padding(Spacing.xs)
                                }
                                .frame(minHeight: 200)
                                .overlay(RoundedRectangle(cornerRadius: Spacing.radiusSM).strokeBorder(Color.kymaiaHairline, lineWidth: 1))
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("SUMMARY & GENERALISATION (LOOK BACK)")
                                .font(Typography.eyebrow)
                                .foregroundStyle(Color.kymaiaSuccess)
                            TextField("Summarise why this invariant holds in 1–2 sentences...", text: $summaryText)
                                .textFieldStyle(.roundedBorder)
                        }

                        HStack {
                            Button("Save Proof Journal Entry") {
                                saveCurrentEntry()
                            }
                            .buttonStyle(BrassButtonStyle())

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

            // 3. The Click · Personal Proposition & Derivation Graph (Ported from LearnHarness)
            JournalSection(
                title: "The Click · Personal Proposition & Derivation Graph",
                eyebrow: "\(store.propositionNodes.count) World-Facing Propositions · \(store.derivationChains.count) Minimal Derivation Chains"
            ) {
                JournalCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            JournalBadge(
                                text: "\(store.propositionNodes.filter(\.isUnconditionalTruth).count) Unconditional Foundations",
                                symbol: "shield.checkered",
                                tone: .positive
                            )
                            JournalBadge(
                                text: "\(store.derivationChains.count) Simplified Chains",
                                symbol: "point.3.connected.trianglepath.dotted",
                                tone: .accent
                            )
                            Spacer()
                            Button {
                                let simplified = PropositionGraphEngine.simplifyChains(store.derivationChains)
                                try? store.db.replacePropositionGraph(nodes: store.propositionNodes, chains: simplified)
                                store.refreshState()
                            } label: {
                                Label("Run simplifyChains Pass", systemImage: "wand.and.stars")
                            }
                            .buttonStyle(JournalSecondaryButtonStyle())
                        }

                        let nodesById = Dictionary(uniqueKeysWithValues: store.propositionNodes.map { ($0.id, $0) })

                        if !store.derivationChains.isEmpty {
                            Text("MINIMAL JOINT-PREMISE DERIVATION CHAINS ([P₁, P₂] ⟹ Q)")
                                .font(Typography.eyebrow)
                                .foregroundStyle(Color.kymaiaPrimary)

                            ForEach(store.derivationChains.prefix(6)) { chain in
                                let premiseTitles = chain.premisesList.map { nodesById[$0]?.name ?? $0 }
                                let conclusionNode = nodesById[chain.conclusionId]
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("\(premiseTitles.joined(separator: "  +  "))  ⟹  \(conclusionNode?.name ?? chain.conclusionId)")
                                            .font(Typography.subheadline.weight(.semibold))
                                            .foregroundStyle(Color.kymaiaInk)
                                        Spacer()
                                        JournalBadge(text: chain.id, symbol: "link", tone: .neutral)
                                    }
                                    if let statement = conclusionNode?.statement {
                                        Text(statement)
                                            .font(Typography.caption)
                                            .foregroundStyle(Color.kymaiaMutedInk)
                                    }
                                }
                                .padding(Spacing.sm)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .quietPanelBackground()
                            }
                        }

                        Text("EXTRACTED WORLD-FACING PROPOSITIONS")
                            .font(Typography.eyebrow)
                            .foregroundStyle(Color.kymaiaPrimary)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: Spacing.sm)], spacing: Spacing.sm) {
                            ForEach(store.propositionNodes.prefix(8)) { node in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        JournalBadge(
                                            text: node.isUnconditionalTruth ? "Unconditional Truth" : "Derived Invariant",
                                            symbol: node.isUnconditionalTruth ? "sparkles" : "function",
                                            tone: node.isUnconditionalTruth ? .positive : .info
                                        )
                                        Spacer()
                                        Text("Ch \(node.chapterNumber)")
                                            .font(Typography.caption)
                                            .foregroundStyle(Color.kymaiaMutedInk)
                                    }
                                    Text(node.name)
                                        .font(Typography.subheadline.weight(.bold))
                                        .foregroundStyle(Color.kymaiaInk)
                                    Text(node.statement)
                                        .font(Typography.caption)
                                        .foregroundStyle(Color.kymaiaMutedInk)
                                }
                                .padding(Spacing.sm)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .quietPanelBackground()
                            }
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
                .foregroundStyle(Color.kymaiaMutedInk)
            TextField(label, text: text)
                .textFieldStyle(.roundedBorder)
                .font(Typography.caption)
        }
        .padding(Spacing.xs)
        .quietPanelBackground()
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
