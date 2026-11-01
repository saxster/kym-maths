import SwiftUI

// MARK: - Room 4: 3D Atlas & Active-Recall Diagram Plates (@saxster/atlas + 47 Widgets + 16 Plates)

struct LabsAtlasHomeView: View {
    @Bindable var store: AppStore
    @Environment(\.themeTokens) private var tokens

    @State private var challengeNote: String = ""
    @State private var diagramMode: String = "ghost_scaffold"
    @State private var revealedCalloutIds: Set<String> = []
    @State private var diagramInputs: [String: String] = [:]

    var body: some View {
        let widget = store.selectedWidget
        let stamp = store.widgetStampsById[widget.id]
        let plate = store.selectedDiagramPlate

        JournalPage {
            // 1. Header & @saxster/atlas 3D Gallery
            JournalCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("3D MATHEMATICAL ATLAS & DIAGRAM RECALL STUDIO")
                        .font(Typography.eyebrow)
                        .foregroundStyle(tokens.accent)
                    Text("47 Interactive Labs + @saxster/atlas 3D Figures + 16 Diagram Plates")
                        .font(Typography.title2)
                        .foregroundStyle(tokens.primary)
                    Text("Powered by the pure-model @saxster/atlas engine (Unit Circle, Secant-to-Tangent Calculus, 3D Matrix Sandbox, Galton Board, Bayes' 1,000-Person Unit Square, Fourier Epicycles, Gradient Climb & Compound Cascade).")
                        .font(Typography.subheadline)
                        .foregroundStyle(tokens.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.xs) {
                            ForEach(store.seedPack.widgets) { w in
                                JournalChip(
                                    title: "Ch \(w.chapter) · \(w.title)",
                                    systemImage: store.widgetStampsById[w.id] != nil ? "checkmark.seal.fill" : (w.is3D ? "cube.transparent.fill" : "slider.horizontal.below.rectangle"),
                                    isSelected: store.selectedWidgetId == w.id
                                ) {
                                    store.selectedWidgetId = w.id
                                }
                            }
                        }
                    }
                }
            }

            // 2. Active Widget & @saxster/atlas Inspector
            JournalSection(
                title: widget.title,
                eyebrow: "Chapter \(widget.chapter) · Atlas Route: \(widget.atlasRoute)"
            ) {
                JournalCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            JournalBadge(text: widget.is3D ? "3D WebGL / Atlas Figure" : "2D Interactive Figure", symbol: "cube.transparent", tone: .accent)
                            JournalBadge(text: widget.atlasRoute, symbol: "link", tone: .info)
                            if let s = stamp {
                                JournalBadge(text: "Stamped \(s.earnedAt.formatted(date: .abbreviated, time: .omitted))", symbol: "checkmark.seal.fill", tone: .positive)
                            }
                            Spacer()
                            Button {
                                store.selectedChapterNumber = widget.chapter
                                store.activeRoom = .patternedWorld
                            } label: {
                                Label("Launch in Full Stage", systemImage: "arrow.up.right.square")
                            }
                            .buttonStyle(JournalSecondaryButtonStyle())
                        }

                        // 3-Step Watch Sequence
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("3-STEP GUIDED OBSERVATION SEQUENCE")
                                .font(Typography.eyebrow)
                                .foregroundStyle(tokens.accent)
                            ForEach(Array(widget.watchSteps.enumerated()), id: \.offset) { idx, step in
                                HStack(alignment: .top, spacing: Spacing.sm) {
                                    Text("\(idx + 1).")
                                        .font(Typography.subheadline.weight(.bold))
                                        .foregroundStyle(tokens.accent)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(step.title)
                                            .font(Typography.subheadline.weight(.semibold))
                                            .foregroundStyle(tokens.primary)
                                        Text(step.caption)
                                            .font(Typography.caption)
                                            .foregroundStyle(tokens.secondary)
                                    }
                                }
                            }
                        }
                        .padding(Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: Spacing.radiusMD).fill(tokens.surfaceElevated))

                        // Cutaway & Idealised Honesty Drawers
                        HStack(alignment: .top, spacing: Spacing.md) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("STRUCTURAL CUTAWAY")
                                    .font(Typography.eyebrow)
                                    .foregroundStyle(tokens.info)
                                Text(widget.cutaway)
                                    .font(Typography.caption)
                                    .foregroundStyle(tokens.secondary)
                            }
                            .padding(Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: Spacing.radiusSM).fill(tokens.surfaceElevated))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("MATHEMATICAL IDEALISATION")
                                    .font(Typography.eyebrow)
                                    .foregroundStyle(tokens.warning)
                                Text(widget.idealised)
                                    .font(Typography.caption)
                                    .foregroundStyle(tokens.secondary)
                            }
                            .padding(Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: Spacing.radiusSM).fill(tokens.surfaceElevated))
                        }

                        // Challenge Prompt & Stamp
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("CHALLENGE STAMP TASK")
                                .font(Typography.eyebrow)
                                .foregroundStyle(tokens.positive)
                            Text(widget.challengePrompt)
                                .font(Typography.subheadline.weight(.semibold))
                                .foregroundStyle(tokens.primary)

                            HStack {
                                TextField("Record your readout or invariant verification...", text: $challengeNote)
                                    .textFieldStyle(.roundedBorder)
                                Button("Earn Lab Stamp") {
                                    let note = challengeNote.isEmpty ? "Verified invariant on \(widget.title)" : challengeNote
                                    store.stampWidgetChallenge(widget: widget, note: note)
                                    challengeNote = ""
                                }
                                .buttonStyle(JournalPrimaryButtonStyle())
                            }
                        }
                    }
                }
            }

            // 3. 16 Active-Recall Mathematical Diagram Plates
            JournalSection(
                title: "Active-Recall Mathematical Diagram Plates (16 Plates)",
                eyebrow: "Test Visual-to-Formula Anatomy Without Passive Re-Reading"
            ) {
                JournalCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.xs) {
                                ForEach(store.seedPack.diagramPlates) { p in
                                    JournalChip(
                                        title: p.title,
                                        systemImage: "viewfinder.rectangular",
                                        isSelected: store.selectedDiagramPlateId == p.id
                                    ) {
                                        store.selectedDiagramPlateId = p.id
                                        revealedCalloutIds.removeAll()
                                    }
                                }
                            }
                        }

                        HStack {
                            JournalBadge(text: "OUP Ch \(plate.unitNumber) · Topic \(plate.topicCode)", symbol: "book.closed", tone: .accent)
                            JournalBadge(text: "Patterned World Ch \(plate.livingWorldChapter)", symbol: "sparkles", tone: .info)
                            Spacer()
                            AdaptiveOptionPicker(
                                options: ["label_only", "ghost_scaffold", "blank_recall"],
                                selection: $diagramMode,
                                label: { mode in
                                    switch mode {
                                    case "label_only": return "1. Study Labels"
                                    case "ghost_scaffold": return "2. Ghost Hints"
                                    default: return "3. Blank Recall"
                                    }
                                }
                            )
                        }

                        Text(plate.title)
                            .font(Typography.title3)
                            .foregroundStyle(tokens.primary)
                        Text(plate.subtitle)
                            .font(Typography.caption)
                            .foregroundStyle(tokens.secondary)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 250), spacing: Spacing.sm)], spacing: Spacing.sm) {
                            ForEach(plate.callouts) { callout in
                                let isRevealed = diagramMode == "label_only" || revealedCalloutIds.contains(callout.id)
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    HStack {
                                        Text("Pin (\(Int(callout.xFraction * 100))%, \(Int(callout.yFraction * 100))%)")
                                            .font(Typography.mono)
                                            .foregroundStyle(tokens.accent)
                                        Spacer()
                                        Button(isRevealed ? "Hide" : "Reveal") {
                                            if revealedCalloutIds.contains(callout.id) {
                                                revealedCalloutIds.remove(callout.id)
                                            } else {
                                                revealedCalloutIds.insert(callout.id)
                                            }
                                        }
                                        .font(Typography.caption.weight(.semibold))
                                    }

                                    if diagramMode != "blank_recall" {
                                        Text("Hint: \(callout.hint)")
                                            .font(Typography.caption)
                                            .foregroundStyle(tokens.secondary)
                                    }

                                    if isRevealed {
                                        Text(callout.label)
                                            .font(Typography.subheadline.weight(.bold))
                                            .foregroundStyle(tokens.positive)
                                    } else {
                                        let binding = Binding<String>(
                                            get: { diagramInputs[callout.id] ?? "" },
                                            set: { diagramInputs[callout.id] = $0 }
                                        )
                                        TextField("Type formula or geometric label...", text: binding)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                                .padding(Spacing.sm)
                                .background(RoundedRectangle(cornerRadius: Spacing.radiusMD).fill(tokens.surfaceElevated))
                            }
                        }

                        HStack {
                            Button("Reveal All & Log Recall Score") {
                                revealedCalloutIds = Set(plate.callouts.map(\.id))
                                store.recordDiagramRecallAttempt(
                                    plate: plate,
                                    mode: diagramMode,
                                    correctCount: plate.callouts.count,
                                    selfScore: 5
                                )
                            }
                            .buttonStyle(JournalPrimaryButtonStyle())
                            Spacer()
                            Text("Logged attempts: \(store.diagramAttempts.filter { $0.plateId == plate.id }.count)")
                                .font(Typography.caption)
                                .foregroundStyle(tokens.secondary)
                        }
                    }
                }
            }
        }
    }
}
