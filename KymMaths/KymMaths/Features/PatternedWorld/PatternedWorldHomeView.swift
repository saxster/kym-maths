import SwiftUI

// MARK: - Room 3: The Patterned World (21 Story-First Chapters with Visual Intuition -> "Aha!" -> Symbolic Formula)

enum PatternedWorldReadingMode: String, CaseIterable, Identifiable, Sendable {
    case interactiveBeats = "Interactive Beats (Brilliant Mode)"
    case fullChapterScroll = "Full Chapter Scroll"

    var id: String { rawValue }
    var title: String { rawValue }
}

struct PatternedWorldHomeView: View {
    @Bindable var store: AppStore

    @State private var readingMode: PatternedWorldReadingMode = .interactiveBeats
    @State private var activeBeatIndex: Int = 0
    @State private var completedBeatIds: Set<String> = []
    @State private var narrator = ChapterAudioNarrator()
    @State private var selectedTermSymbol: String? = nil
    @State private var highlightedColorRole: String? = nil
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

    private func isBeatUnlocked(_ beat: ChapterInteractiveBeat, in chapter: PatternedWorldChapter) -> Bool {
        if !beat.requiresInteractionToUnlock || completedBeatIds.contains(beat.id) {
            return true
        }
        if let callout = beat.callout {
            return store.calloutResponses[callout.id]?.isUnlocked == true
        }
        if let debate = beat.debateScenario {
            return store.calloutResponses["debate-\(debate.id)"]?.isUnlocked == true
        }
        return true
    }

    private func canNavigateToBeat(
        at targetIndex: Int,
        beats: [ChapterInteractiveBeat],
        chapter: PatternedWorldChapter
    ) -> Bool {
        guard targetIndex > 0 else { return true }
        for idx in 0..<min(targetIndex, beats.count) {
            if !isBeatUnlocked(beats[idx], in: chapter) {
                return false
            }
        }
        return true
    }

    private var readingModePicker: some View {
        AdaptiveOptionPicker(
            options: PatternedWorldReadingMode.allCases,
            selection: $readingMode,
            label: { $0.title }
        )
        .fixedSize()
    }

    @ViewBuilder
    private func stageControls(currentBeat: ChapterInteractiveBeat, beatIndex: Int, chapter: PatternedWorldChapter) -> some View {
        // Read + Listen Synchronized Audio Narrator Controls
        Button {
            narrator.togglePlayPause(
                text: currentBeat.spokenScript,
                beatIndex: beatIndex,
                beatId: currentBeat.id
            )
        } label: {
            Label(
                narrator.isSpeaking ? "Stop Read-Aloud" : "Read & Listen",
                systemImage: narrator.isSpeaking ? "stop.circle.fill" : "speaker.wave.2.fill"
            )
        }
        .buttonStyle(JournalSecondaryButtonStyle())
        .fixedSize()

        Button("\(String(format: "%.2gx", narrator.playbackSpeedMultiplier))") {
            narrator.cycleSpeed()
        }
        .buttonStyle(JournalSecondaryButtonStyle())
        .fixedSize()

        Button {
            showEmbeddedWebStage.toggle()
        } label: {
            Label(showEmbeddedWebStage ? "Hide Interactive Stage" : "Show Interactive Stage", systemImage: "cube.transparent.fill")
        }
        .buttonStyle(JournalSecondaryButtonStyle())
        .fixedSize()

        if chapter.id == EuclidBuildLinks.mapChapter {
            Button {
                store.openEuclid(.map)
            } label: {
                Label("Build it yourself", systemImage: "compass.drawing")
            }
            .buttonStyle(JournalSecondaryButtonStyle())
            .fixedSize()
            .help("Open Book I in Euclid's Workshop")
        }
    }

    var body: some View {
        let chapter = store.selectedChapter
        let bridge = chapter.intuitionToFormula
        let progress = store.readingProgressByChapter[chapter.number]
        let beats = ChapterInteractiveBeatEngine.beats(for: chapter)
        let clampedBeatIndex = min(max(0, activeBeatIndex), max(0, beats.count - 1))
        let currentBeat = beats[clampedBeatIndex]

        JournalPage {
            EditorialHeader(
                eyebrow: "Interactive Story-First Textbook · 5 Volumes · 21 Chapters",
                title: "The Patterned World",
                subtitle: "Every chapter moves from Concrete Visual Intuition → The \"Aha!\" Invariant → The Actual Symbolic Formula."
            )

            // 1. Volume/Chapter Strip + Mode Switcher + Read+Listen Audio Narrator
            JournalCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // One row when it fits; otherwise the controls wrap under the picker, so no
                    // button is squeezed into a tall empty pill.
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .center, spacing: Spacing.sm) {
                            readingModePicker
                            Spacer()
                            stageControls(currentBeat: currentBeat, beatIndex: clampedBeatIndex, chapter: chapter)
                        }
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            readingModePicker
                            FlowLayout(spacing: Spacing.sm) {
                                stageControls(currentBeat: currentBeat, beatIndex: clampedBeatIndex, chapter: chapter)
                            }
                        }
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
                                    narrator.stop()
                                    store.selectedChapterNumber = ch.number
                                    activeBeatIndex = 0
                                    selectedTermSymbol = nil
                                    highlightedColorRole = nil
                                }
                            }
                        }
                    }
                }
            }

            // 1B. Interactive Beats Mode (Brilliant-style Bite-Sized Micro-Step Flow)
            if readingMode == .interactiveBeats {
                let currentUnlocked = isBeatUnlocked(currentBeat, in: chapter)
                JournalSection(
                    title: "Interactive Beat Flow · Beat \(clampedBeatIndex + 1) of \(beats.count)",
                    eyebrow: "Chapter \(chapter.number): \(chapter.title) · Bite-Sized Discovery & Check Gates"
                ) {
                    JournalCard {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            // Segmented Beat Progress Bar
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Spacing.xs) {
                                    ForEach(beats) { beat in
                                        let isCurrent = beat.index == clampedBeatIndex
                                        let isDone = isBeatUnlocked(beat, in: chapter) && (completedBeatIds.contains(beat.id) || beat.index < clampedBeatIndex)
                                        let canJump = canNavigateToBeat(at: beat.index, beats: beats, chapter: chapter)
                                        Button {
                                            if canJump {
                                                activeBeatIndex = beat.index
                                            }
                                        } label: {
                                            HStack(spacing: 4) {
                                                Image(systemName: isDone ? "checkmark.circle.fill" : (isCurrent ? "sparkles" : (canJump ? "circle" : "lock.fill")))
                                                    .foregroundStyle(isDone ? Color.kymaiaSuccess : (isCurrent ? Color.kymaiaPrimary : Color.kymaiaMutedInk))
                                                Text("Beat \(beat.index + 1)")
                                                    .font(Typography.caption.weight(isCurrent ? .bold : .regular))
                                                    .foregroundStyle(canJump ? Color.kymaiaInk : Color.kymaiaMutedInk)
                                            }
                                            .padding(.horizontal, Spacing.xs)
                                            .padding(.vertical, 6)
                                            .background(isCurrent ? Color.kymaiaSelectionFill : Color.kymaiaElevatedSurface)
                                            .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusSM))
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(!canJump)
                                    }
                                }
                            }

                            HStack {
                                JournalBadge(text: currentBeat.eyebrow, symbol: "sparkles", tone: .accent)
                                if currentBeat.requiresInteractionToUnlock {
                                    JournalBadge(
                                        text: currentUnlocked ? "Gate Unlocked ✓" : "Interactive Gate Required",
                                        symbol: currentUnlocked ? "lock.open.fill" : "lock.fill",
                                        tone: currentUnlocked ? .positive : .warning
                                    )
                                }
                                Spacer()
                                Text("Step \(clampedBeatIndex + 1) / \(beats.count)")
                                    .font(Typography.mono)
                                    .foregroundStyle(Color.kymaiaMutedInk)
                            }

                            Text(currentBeat.title)
                                .font(Typography.title2)
                                .foregroundStyle(Color.kymaiaInk)

                            ForEach(currentBeat.bodyParagraphs, id: \.self) { para in
                                Text(para)
                                    .font(Typography.body)
                                    .foregroundStyle(Color.kymaiaInk)
                            }

                            if let callout = currentBeat.callout {
                                let saved = store.calloutResponses[callout.id]
                                let draftBinding = Binding<String>(
                                    get: { calloutDrafts[callout.id] ?? saved?.responseText ?? "" },
                                    set: { calloutDrafts[callout.id] = $0 }
                                )
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    HStack {
                                        JournalBadge(text: callout.badgeText, symbol: callout.symbolName, tone: .info)
                                        Text(callout.title)
                                            .font(Typography.subheadline.weight(.semibold))
                                            .foregroundStyle(Color.kymaiaInk)
                                        Spacer()
                                        if saved?.isUnlocked == true {
                                            JournalBadge(text: "Verified ✓", symbol: "checkmark.circle.fill", tone: .positive)
                                        }
                                    }
                                    Text(callout.body)
                                        .font(Typography.caption)
                                        .foregroundStyle(Color.kymaiaInk)

                                    if callout.kind == "predict" || callout.kind == "check" {
                                        LearnerTextInput(
                                            title: "Your response for this beat:",
                                            placeholder: "Type your prediction or derivation step...",
                                            text: draftBinding,
                                            minHeight: 64
                                        )
                                        Button("Lock Beat Response") {
                                            let responseText = draftBinding.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                                ? "Verified beat reasoning"
                                                : draftBinding.wrappedValue
                                            store.saveCalloutResponse(
                                                calloutId: callout.id,
                                                chapterNumber: chapter.number,
                                                text: responseText,
                                                thinkingWhileReading: readingThoughtsByChapter[chapter.number] ?? "",
                                                confidencePercent: calloutConfidenceById[callout.id] ?? 75,
                                                isUnlockedOverride: true
                                            )
                                            completedBeatIds.insert(currentBeat.id)
                                        }
                                        .buttonStyle(currentUnlocked ? AnyButtonStyle(JournalSecondaryButtonStyle()) : AnyButtonStyle(BrassButtonStyle()))
                                    }
                                }
                                .padding(Spacing.sm)
                                .quietPanelBackground()
                            }

                            if let formulaBridge = currentBeat.formulaBridge {
                                IntuitionFormulaBridgeCard(
                                    bridge: formulaBridge,
                                    selectedTermSymbol: $selectedTermSymbol
                                ) { term in
                                    highlightedColorRole = term.colorRole
                                }
                            }

                            if let debate = currentBeat.debateScenario {
                                MathematicalDebateCardView(
                                    scenario: debate,
                                    initialSelectedChoiceId: store.calloutResponses["debate-\(debate.id)"]?.responseText,
                                    onChoiceSelected: { choice, isCorrect in
                                        store.saveCalloutResponse(
                                            calloutId: "debate-\(debate.id)",
                                            chapterNumber: chapter.number,
                                            text: choice.id,
                                            thinkingWhileReading: readingThoughtsByChapter[chapter.number] ?? "",
                                            confidencePercent: isCorrect ? 95 : 40,
                                            isUnlockedOverride: isCorrect
                                        )
                                        if isCorrect {
                                            completedBeatIds.insert(currentBeat.id)
                                        }
                                    }
                                )
                            }

                            HStack {
                                if clampedBeatIndex > 0 {
                                    Button("← Previous Beat") {
                                        activeBeatIndex = max(0, clampedBeatIndex - 1)
                                    }
                                    .buttonStyle(JournalSecondaryButtonStyle())
                                }
                                Spacer()
                                if !currentUnlocked {
                                    Text("Complete the interactive prompt above to unlock the next beat")
                                        .font(Typography.caption)
                                        .foregroundStyle(Color.kymaiaMutedInk)
                                    Button("Skip Gate →") {
                                        completedBeatIds.insert(currentBeat.id)
                                        if clampedBeatIndex + 1 < beats.count {
                                            activeBeatIndex = clampedBeatIndex + 1
                                        }
                                    }
                                    .buttonStyle(JournalSecondaryButtonStyle())
                                } else if clampedBeatIndex + 1 < beats.count {
                                    Button("Continue to Beat \(clampedBeatIndex + 2) →") {
                                        completedBeatIds.insert(currentBeat.id)
                                        let nextIdx = clampedBeatIndex + 1
                                        activeBeatIndex = nextIdx
                                        let frac = Double(nextIdx + 1) / Double(max(1, beats.count))
                                        store.markChapterRead(
                                            chapterNumber: chapter.number,
                                            fraction: frac,
                                            incrementCounters: false
                                        )
                                    }
                                    .buttonStyle(BrassButtonStyle())
                                } else {
                                    Button("Complete Chapter \(chapter.number) ✓") {
                                        completedBeatIds.insert(currentBeat.id)
                                        store.markChapterRead(
                                            chapterNumber: chapter.number,
                                            fraction: 1.0,
                                            incrementCounters: true
                                        )
                                    }
                                    .buttonStyle(BrassButtonStyle())
                                }
                            }
                        }
                    }
                }

                if showEmbeddedWebStage {
                    JournalSection(
                        title: "Interactive Intuition → Formula Sandbox & @saxster/atlas Stage",
                        eyebrow: "Drag Sliders, Manipulate Geometry & Launch 3D Teaching Figures"
                    ) {
                        JournalCard {
                            PatternedWorldWebStageView(
                                chapterNumber: chapter.number,
                                atlasRoute: bridge.atlasFigureRef,
                                highlightedColorRole: highlightedColorRole,
                                onTermHighlighted: { role, symbol in
                                    highlightedColorRole = role
                                    if !symbol.isEmpty {
                                        selectedTermSymbol = symbol
                                    }
                                },
                                store: store
                            )
                            .frame(height: 540)
                            .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMD, style: .continuous))
                        }
                    }
                }
            } else {
                // 2. Chapter Hero & Intuition -> "Aha!" -> Symbolic Formula Anatomy (Full Chapter Scroll Mode)
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
                                            let responseText = predictBinding.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                                ? "Locked prediction"
                                                : predictBinding.wrappedValue
                                            store.saveCalloutResponse(
                                                calloutId: predictCallout.id,
                                                chapterNumber: chapter.number,
                                                text: responseText,
                                                thinkingWhileReading: readingThoughtsByChapter[chapter.number] ?? "",
                                                confidencePercent: calloutConfidenceById[predictCallout.id] ?? 75,
                                                isUnlockedOverride: true
                                            )
                                        }
                                        .buttonStyle(JournalSecondaryButtonStyle())

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
                                    IntuitionFormulaBridgeCard(
                                        bridge: bridge,
                                        selectedTermSymbol: $selectedTermSymbol
                                    ) { term in
                                        highlightedColorRole = term.colorRole
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
                                highlightedColorRole: highlightedColorRole,
                                onTermHighlighted: { role, symbol in
                                    highlightedColorRole = role
                                    if !symbol.isEmpty {
                                        selectedTermSymbol = symbol
                                    }
                                },
                                store: store
                            )
                            .frame(height: 540)
                            .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMD, style: .continuous))
                        }
                    }
                }

                // 3B. Peer Mathematical Debate ("Who Is Right & Why?")
                let scrollDebate = MathematicalDebateEngine.scenario(forChapter: chapter.number)
                JournalSection(
                    title: "Peer Mathematical Debate · Ch \(chapter.number)",
                    eyebrow: "Who Is Right & Why? · Build Misconception Immunity"
                ) {
                    MathematicalDebateCardView(
                        scenario: scrollDebate,
                        initialSelectedChoiceId: store.calloutResponses["debate-\(scrollDebate.id)"]?.responseText,
                        onChoiceSelected: { choice, isCorrect in
                            store.saveCalloutResponse(
                                calloutId: "debate-\(scrollDebate.id)",
                                chapterNumber: chapter.number,
                                text: choice.id,
                                thinkingWhileReading: readingThoughtsByChapter[chapter.number] ?? "",
                                confidencePercent: isCorrect ? 95 : 40,
                                isUnlockedOverride: isCorrect
                            )
                        }
                    )
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
                                        .buttonStyle(JournalSecondaryButtonStyle())
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
                                                let responseText = binding.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                                    ? "Verified checkpoint"
                                                    : binding.wrappedValue
                                                store.saveCalloutResponse(
                                                    calloutId: callout.id,
                                                    chapterNumber: chapter.number,
                                                    text: responseText,
                                                    thinkingWhileReading: readingThoughtsByChapter[chapter.number] ?? "",
                                                    confidencePercent: confBinding.wrappedValue,
                                                    isUnlockedOverride: true
                                                )
                                            }
                                            .buttonStyle(JournalSecondaryButtonStyle())
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .onDisappear {
            narrator.stop()
        }
    }
}
