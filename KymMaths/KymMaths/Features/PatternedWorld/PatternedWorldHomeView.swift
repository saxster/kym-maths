import SwiftUI

// MARK: - Room 3: The Patterned World (21 Story-First Chapters with Visual Intuition -> "Aha!" -> Symbolic Formula)

struct PatternedWorldHomeView: View {
    @Bindable var store: AppStore

    @State private var showEmbeddedWebStage = true
    @State private var calloutDrafts: [String: String] = [:]
    @State private var readingThoughtsByChapter: [Int: String] = [:]
    @State private var bypassedPredictionChapters: Set<Int> = []
    @State private var revealedCheckCalloutIds: Set<String> = []
    @State private var calloutConfidenceById: [String: Int] = [:]

    private func isFormulaBridgeUnlocked(for chapter: PatternedWorldChapter) -> Bool {
        if !store.showIntuitionBeforeFormula || bypassedPredictionChapters.contains(chapter.number) {
            return true
        }
        let predictCallouts = chapter.callouts.filter { $0.kind == "predict" }
        guard !predictCallouts.isEmpty else { return true }
        return predictCallouts.contains { store.calloutResponses[$0.id]?.isUnlocked == true }
    }

    var body: some View {
        let chapter = store.selectedChapter
        let bridge = chapter.intuitionToFormula
        let progress = store.readingProgressByChapter[chapter.number]

        JournalPage {
            EditorialHeader(
                eyebrow: "Interactive Story-First Textbook · 5 Volumes · 21 Chapters",
                title: "The Patterned World",
                subtitle: "Every chapter moves from Concrete Visual Intuition → The \"Aha!\" Invariant → The Actual Symbolic Formula."
            )

            // 1. Volume/Chapter Strip
            JournalCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack(alignment: .top) {
                        Spacer()
                        Button {
                            showEmbeddedWebStage.toggle()
                        } label: {
                            Label(showEmbeddedWebStage ? "Hide Interactive Stage" : "Show Interactive Stage", systemImage: "cube.transparent.fill")
                        }
                        .buttonStyle(JournalSecondaryButtonStyle())
                    }

                    // Volumes bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.xs) {
                            ForEach(store.seedPack.volumes) { vol in
                                JournalBadge(
                                    text: "Vol \(vol.number): \(vol.title)",
                                    symbol: "books.vertical.fill",
                                    tone: chapter.volumeNumber == vol.number ? .accent : .neutral
                                )
                            }
                        }
                    }

                    // Chapters strip
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.xs) {
                            ForEach(store.visiblePatternedWorldChapters) { ch in
                                MathsFilterChip(
                                    title: "Ch \(ch.number): \(ch.title)",
                                    systemImage: (store.readingProgressByChapter[ch.number]?.readFraction ?? 0) >= 0.9 ? "checkmark.circle.fill" : "book.pages",
                                    isSelected: store.selectedChapterNumber == ch.number
                                ) {
                                    store.selectedChapterNumber = ch.number
                                }
                            }
                        }
                    }
                }
            }

            // 2. Chapter Hero & Intuition -> "Aha!" -> Symbolic Formula Anatomy
            JournalSection(
                title: "Chapter \(chapter.number) · \(chapter.title)",
                eyebrow: "Volume \(chapter.volumeNumber): \(chapter.volumeTitle) · \(chapter.subtitle)"
            ) {
                JournalCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            JournalBadge(text: "Ch \(chapter.number)", symbol: "sparkles", tone: .accent)
                            JournalBadge(text: "3D Atlas: \(bridge.atlasFigureRef)", symbol: "cube.transparent", tone: .info)
                            if let p = progress, p.readFraction >= 0.9 {
                                JournalBadge(text: "Completed ✓", symbol: "checkmark.seal.fill", tone: .positive)
                            }
                            Spacer()
                            Button("Mark Chapter Complete") {
                                store.markChapterRead(chapterNumber: chapter.number, fraction: 1.0)
                            }
                            .buttonStyle(BrassButtonStyle())
                        }

                        Text(chapter.hookSummary)
                            .font(Typography.body)
                            .foregroundStyle(Color.kymaiaInk)

                        // Step 0: Open Prediction Gate (LearnHarness Arrival Law: Predict arrives open before teaching)
                        let predictCallouts = chapter.callouts.filter { $0.kind == "predict" }
                        ForEach(predictCallouts) { predictCallout in
                            let savedPredict = store.calloutResponses[predictCallout.id]
                            let predictBinding = Binding<String>(
                                get: { calloutDrafts[predictCallout.id] ?? savedPredict?.responseText ?? "" },
                                set: { calloutDrafts[predictCallout.id] = $0 }
                            )
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                HStack {
                                    JournalBadge(text: "Step 0 · Predict Before Formula", symbol: "sparkles", tone: .accent)
                                    Text(predictCallout.title)
                                        .font(Typography.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.kymaiaInk)
                                    Spacer()
                                    if savedPredict?.isUnlocked == true {
                                        JournalBadge(text: "Prediction Locked ✓", symbol: "checkmark.circle.fill", tone: .positive)
                                    }
                                }
                                Text(predictCallout.body)
                                    .font(Typography.caption)
                                    .foregroundStyle(Color.kymaiaInk)
                                LearnerTextInput(
                                    title: "Your intuition prediction before seeing the symbolic formula:",
                                    placeholder: "What do you predict stays equal or happens next?",
                                    text: predictBinding,
                                    minHeight: 60
                                )
                                HStack {
                                    Button("Lock Prediction & Unlock Formula Bridge") {
                                        store.saveCalloutResponse(
                                            calloutId: predictCallout.id,
                                            chapterNumber: chapter.number,
                                            text: predictBinding.wrappedValue,
                                            thinkingWhileReading: readingThoughtsByChapter[chapter.number] ?? "",
                                            confidencePercent: calloutConfidenceById[predictCallout.id] ?? 75
                                        )
                                    }
                                    .buttonStyle(BrassButtonStyle())

                                    if !isFormulaBridgeUnlocked(for: chapter) {
                                        Button("Just reveal the formula bridge") {
                                            bypassedPredictionChapters.insert(chapter.number)
                                        }
                                        .buttonStyle(JournalSecondaryButtonStyle())
                                    }
                                }
                            }
                            .padding(Spacing.sm)
                            .quietPanelBackground()
                        }

                        // The 3-Step Intuition -> "Aha!" -> Formula Bridge
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("THE INTUITION → \"AHA!\" → FORMULA BRIDGE")
                                .font(Typography.eyebrow)
                                .foregroundStyle(Color.kymaiaPrimary)

                            HStack(alignment: .top, spacing: Spacing.md) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("1. Concrete Visual Action")
                                        .font(Typography.caption.weight(.bold))
                                        .foregroundStyle(Color.kymaiaPrimary)
                                    Text(bridge.concreteAction)
                                        .font(Typography.caption)
                                        .foregroundStyle(Color.kymaiaInk)
                                }
                                .padding(Spacing.sm)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .quietPanelBackground()

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("2. The \"Aha!\" Invariant")
                                        .font(Typography.caption.weight(.bold))
                                        .foregroundStyle(Color.kymaiaSuccess)
                                    Text(bridge.ahaInvariant)
                                        .font(Typography.caption)
                                        .foregroundStyle(Color.kymaiaInk)
                                }
                                .padding(Spacing.sm)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .quietPanelBackground()
                            }

                            if isFormulaBridgeUnlocked(for: chapter) {
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text("3. Actual Symbolic Formula & Colour-Locked Anatomy")
                                        .font(Typography.caption.weight(.bold))
                                        .foregroundStyle(Color.kymaiaWarning)
                                    Text(bridge.formulaDisplay)
                                        .font(Typography.numericFormula)
                                        .foregroundStyle(Color.kymaiaInk)
                                        .padding(Spacing.sm)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .quietPanelBackground()

                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: Spacing.xs)], spacing: Spacing.xs) {
                                        ForEach(bridge.termMappings) { term in
                                            HStack(alignment: .top, spacing: 6) {
                                                Circle()
                                                    .fill(colorForRole(term.colorRole))
                                                    .frame(width: 10, height: 10)
                                                    .padding(.top, 4)
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("\(term.symbol)  ↔  \(term.visualPart)")
                                                        .font(Typography.caption.weight(.bold))
                                                        .foregroundStyle(Color.kymaiaInk)
                                                    Text(term.meaning)
                                                        .font(Typography.caption)
                                                        .foregroundStyle(Color.kymaiaMutedInk)
                                                }
                                            }
                                            .padding(Spacing.xs)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .quietPanelBackground()
                                        }
                                    }
                                }
                            } else {
                                HStack(spacing: Spacing.sm) {
                                    Image(systemName: "lock.shield.fill")
                                        .foregroundStyle(Color.kymaiaPrimary)
                                    Text("Enter a quick prediction above (or click 'Just reveal the formula bridge') to unveil the symbolic compression.")
                                        .font(Typography.caption)
                                        .foregroundStyle(Color.kymaiaMutedInk)
                                }
                                .padding(Spacing.sm)
                                .quietPanelBackground()
                            }
                        }
                    }
                }
            }

            // 3. Embedded Interactive WebGL/SVG Stage (@saxster/atlas + Intuition-to-Formula Sandbox)
            if showEmbeddedWebStage {
                JournalSection(
                    title: "Interactive Intuition → Formula Sandbox & @saxster/atlas Stage",
                    eyebrow: "Drag Sliders, Manipulate Geometry & Launch 3D Teaching Figures"
                ) {
                    JournalCard {
                        PatternedWorldWebStageView(
                            chapterNumber: chapter.number,
                            atlasRoute: bridge.atlasFigureRef,
                            store: store
                        )
                        .frame(height: 540)
                        .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMD, style: .continuous))
                    }
                }
            }

            // 4. Narrative Sections & Callouts (Predict -> Teach -> Check Rhythm)
            JournalSection(
                title: "Deep Narrative & Mathematical Proofs",
                eyebrow: "Sections, Thinking-While-Reading Note & Collapsed Checkpoints"
            ) {
                ForEach(chapter.sections) { section in
                    JournalCard {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text(section.heading)
                                .font(Typography.title3)
                                .foregroundStyle(Color.kymaiaInk)
                            Text(section.excerpt)
                                .font(Typography.body)
                                .foregroundStyle(Color.kymaiaMutedInk)
                        }
                    }
                }

                // Thinking-While-Reading Note (LearnHarness Reading-Time Channel)
                JournalCard {
                    let thoughtBinding = Binding<String>(
                        get: { readingThoughtsByChapter[chapter.number] ?? "" },
                        set: { readingThoughtsByChapter[chapter.number] = $0 }
                    )
                    LearnerTextInput(
                        title: "Thinking While Reading (jot a question, connection, or invariant before opening the Check):",
                        placeholder: "What clicked while reading these sections, or what still feels fuzzy?",
                        text: thoughtBinding,
                        minHeight: 60
                    )
                }

                ForEach(chapter.callouts.filter { $0.kind != "predict" }) { callout in
                    let saved = store.calloutResponses[callout.id]
                    let isCheck = callout.kind == "check"
                    let isRevealed = !isCheck || revealedCheckCalloutIds.contains(callout.id) || (saved?.isUnlocked == true)

                    JournalCard {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack {
                                JournalBadge(text: callout.badgeText, symbol: callout.symbolName, tone: .accent)
                                Text(callout.title)
                                    .font(Typography.headline)
                                    .foregroundStyle(Color.kymaiaInk)
                                Spacer()
                                if saved?.isUnlocked == true {
                                    JournalBadge(text: "Recorded ✓", symbol: "checkmark.circle.fill", tone: .positive)
                                }
                            }

                            if !isRevealed {
                                HStack {
                                    Text("Finish reading the teaching step above, then open this verification check.")
                                        .font(Typography.caption)
                                        .foregroundStyle(Color.kymaiaMutedInk)
                                    Spacer()
                                    Button("Ready for the Check") {
                                        revealedCheckCalloutIds.insert(callout.id)
                                    }
                                    .buttonStyle(BrassButtonStyle())
                                }
                            } else {
                                Text(callout.body)
                                    .font(Typography.body)
                                    .foregroundStyle(Color.kymaiaInk)

                                if isCheck {
                                    let binding = Binding<String>(
                                        get: { calloutDrafts[callout.id] ?? saved?.responseText ?? "" },
                                        set: { calloutDrafts[callout.id] = $0 }
                                    )
                                    let confBinding = Binding<Int>(
                                        get: { calloutConfidenceById[callout.id] ?? saved?.confidencePercent ?? 75 },
                                        set: { calloutConfidenceById[callout.id] = $0 }
                                    )
                                    LearnerTextInput(
                                        title: "Write your derivation to verify this reasoning step:",
                                        placeholder: "State the invariant and resulting formula...",
                                        text: binding,
                                        minHeight: 72
                                    )
                                    HStack(spacing: Spacing.sm) {
                                        Text("Confidence:")
                                            .font(Typography.caption.weight(.semibold))
                                        ForEach([35, 75, 95], id: \.self) { pct in
                                            Button("\(pct)%") {
                                                confBinding.wrappedValue = pct
                                            }
                                            .buttonStyle(JournalSecondaryButtonStyle())
                                        }
                                        Spacer()
                                        Button("Save Checkpoint Response") {
                                            store.saveCalloutResponse(
                                                calloutId: callout.id,
                                                chapterNumber: chapter.number,
                                                text: binding.wrappedValue,
                                                thinkingWhileReading: readingThoughtsByChapter[chapter.number] ?? "",
                                                confidencePercent: confBinding.wrappedValue
                                            )
                                        }
                                        .buttonStyle(BrassButtonStyle())
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func colorForRole(_ role: String) -> Color {
        switch role {
        case "red": return Color(red: 0.78, green: 0.22, blue: 0.18)
        case "blue": return Color(red: 0.14, green: 0.36, blue: 0.72)
        case "amber": return Color(red: 0.76, green: 0.48, blue: 0.08)
        case "green": return Color(red: 0.15, green: 0.52, blue: 0.32)
        default: return Color.kymaiaPrimary
        }
    }
}
