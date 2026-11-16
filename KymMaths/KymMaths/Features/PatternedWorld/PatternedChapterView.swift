import SwiftUI

// MARK: - A chapter, open for reading

/// One chapter: the contents on the left, the reading column with its figure and the reader's turn,
/// and the margin with notes and what the chapter stands on and unlocks. Read one step at a time,
/// or as the whole chapter in one scroll.
struct PatternedChapterView: View {
    @Bindable var store: AppStore
    @Bindable var reading: ChapterReadingState
    let backToLibrary: () -> Void

    @Environment(\.standardTheme) private var theme
    @State private var width: CGFloat = 700
    @State private var hideChapterContents = false
    @State private var showDeskQuietField = false
    @State private var deskQuietDraft = ""
    @State private var deskTutorReply: String?
    /// The part of the whole-chapter page a contents row asked to scroll to.
    @State private var scrollTarget: String?

    private var chapter: PatternedWorldChapter { store.selectedChapter }
    private var beats: [ChapterInteractiveBeat] { ChapterInteractiveBeatEngine.beats(for: chapter) }
    private var beatIndex: Int { min(max(0, reading.activeBeatIndex), max(0, beats.count - 1)) }
    private var currentBeat: ChapterInteractiveBeat { beats[beatIndex] }

    private static let contentsWidth: CGFloat = 170

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Rectangle().fill(theme.hairline()).frame(height: 1)
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: StandardSpacing.xl) {
                        page
                        deskTutorBar
                    }
                    .padding(.horizontal, StandardSpacing.xl)
                    .padding(.top, StandardSpacing.xl)
                    .padding(.bottom, StandardSpacing.xl3)
                    .frame(maxWidth: hideChapterContents ? .infinity : 1180, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .readWidth($width)
                }
                .onChange(of: scrollTarget) { _, target in
                    guard let target else { return }
                    withAnimation { proxy.scrollTo(target, anchor: .top) }
                    scrollTarget = nil
                }
            }
        }
        .background(theme.bg)
        .onChange(of: store.selectedChapterNumber) {
            reading.activeBeatIndex = 0
            deskTutorReply = nil
        }
    }

    // MARK: Layout

    @ViewBuilder private var page: some View {
        let spreadWidth = width - Self.contentsWidth - StandardSpacing.xl
        if !hideChapterContents && BookSpread<EmptyView, EmptyView>.fitsSideBySide(spreadWidth) {
            HStack(alignment: .top, spacing: StandardSpacing.xl) {
                contents
                    .frame(width: Self.contentsWidth, alignment: .leading)
                BookSpread(width: spreadWidth) { mainColumn } margin: { margin(showContents: false) }
            }
        } else if BookSpread<EmptyView, EmptyView>.fitsSideBySide(width) {
            BookSpread(width: width) { mainColumn } margin: { margin(showContents: !hideChapterContents) }
        } else {
            VStack(alignment: .leading, spacing: StandardSpacing.lg) {
                if !hideChapterContents {
                    contents
                }
                BookSpread(width: width) { mainColumn } margin: { margin(showContents: false) }
            }
        }
    }

    @ViewBuilder private var mainColumn: some View {
        if reading.readingMode == .interactiveBeats {
            PatternedChapterStepView(store: store, reading: reading, chapter: chapter, beats: beats, beatIndex: beatIndex)
        } else {
            PatternedChapterScrollView(store: store, reading: reading, chapter: chapter)
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(spacing: StandardSpacing.md) {
            Button(action: backToLibrary) {
                HStack(spacing: StandardSpacing.xs) {
                    Image(systemName: "chevron.left").imageScale(.small)
                    Text("The Patterned World")
                }
                .standardType(.uiHeadline)
                .foregroundStyle(theme.ink)
                .frame(minHeight: StandardAccessibility.touchTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back to the library")

            ViewThatFits(in: .horizontal) {
                HStack(spacing: StandardSpacing.md) {
                    breadcrumb
                    Spacer(minLength: StandardSpacing.sm)
                    stages
                }
                HStack { Spacer(minLength: StandardSpacing.sm); stages }
                Spacer(minLength: 0)
            }

            listenButtons
        }
        .padding(.horizontal, StandardSpacing.lg)
        .padding(.vertical, StandardSpacing.xs)
    }

    private var breadcrumb: some View {
        Text("Volume \(PatternedBook.roman(chapter.volumeNumber))  ·  Chapter \(chapter.number)  ·  \(chapter.title)")
            .standardType(.uiBody)
            .foregroundStyle(theme.mute(theme.ink))
            .lineLimit(1)
            .layoutPriority(-1)
    }

    private var stages: some View {
        let current = ChapterStage(currentBeat.kind)
        return HStack(spacing: StandardSpacing.md) {
            ForEach(ChapterStage.allCases, id: \.self) { stage in
                let isDone = stage.rawValue < current.rawValue
                let isNow = stage == current
                HStack(spacing: StandardSpacing.xxs + 2) {
                    Circle()
                        .fill(isDone ? theme.patterned.provenColor : (isNow ? theme.ink : theme.faint(theme.ink)))
                        .frame(width: 6, height: 6)
                    Text(stage.title)
                        .standardType(isNow ? .uiHeadline : .uiBody)
                        .foregroundStyle(isNow || isDone ? theme.ink : theme.faint(theme.ink))
                }
            }
        }
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Stage: \(current.title)")
    }

    private var listenButtons: some View {
        HStack(spacing: StandardSpacing.xs) {
            Button(hideChapterContents ? "Show contents" : "Full width") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    hideChapterContents.toggle()
                }
            }
            .buttonStyle(OutlineButtonStyle())
            .accessibilityLabel(hideChapterContents ? "Show chapter contents" : "Hide chapter contents for full width")

            Button {
                reading.narrator.togglePlayPause(
                    text: currentBeat.spokenScript,
                    beatIndex: beatIndex,
                    beatId: currentBeat.id
                )
            } label: {
                Label(reading.narrator.isSpeaking ? "Stop" : "Listen",
                      systemImage: reading.narrator.isSpeaking ? "stop.fill" : "speaker.wave.2")
                    .labelStyle(.titleOnly)
            }
            .buttonStyle(OutlineButtonStyle())
            .accessibilityLabel(reading.narrator.isSpeaking ? "Stop reading aloud" : "Read this step aloud")

            Button(String(format: "%.2g×", reading.narrator.playbackSpeedMultiplier)) {
                reading.narrator.cycleSpeed()
            }
            .buttonStyle(OutlineButtonStyle())
            .accessibilityLabel("Reading speed")
        }
        .fixedSize()
    }

    // MARK: Contents

    private var contents: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            Kicker("In this chapter", muted: true)
                .padding(.bottom, StandardSpacing.xxs)
            if reading.readingMode == .interactiveBeats {
                ForEach(beats) { beat in
                    contentsRow(beat)
                }
            } else {
                ForEach(WholeChapterContents.rows(for: chapter)) { row in
                    wholeChapterRow(row)
                }
            }
            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                Kicker("How to read", muted: true)
                Picker("How to read", selection: $reading.readingMode) {
                    ForEach(PatternedWorldReadingMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .tint(theme.brass)
                .labelsHidden()
            }
            .padding(.top, StandardSpacing.md)
        }
    }

    private func contentsRow(_ beat: ChapterInteractiveBeat) -> some View {
        let isCurrent = reading.readingMode == .interactiveBeats && beat.index == beatIndex
        let isDone = isBeatUnlocked(beat) && (reading.completedBeatIds.contains(beat.id) || beat.index < beatIndex)
        let canJump = canNavigate(to: beat.index)
        return Button {
            guard canJump else { return }
            reading.readingMode = .interactiveBeats
            reading.activeBeatIndex = beat.index
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.xs) {
                Text(beat.code(chapter: chapter.number))
                    .foregroundStyle(isCurrent ? theme.brass : theme.mute(theme.ink))
                Text(beat.plainLabel)
                    .fontWeight(isCurrent ? .semibold : .regular)
                    .foregroundStyle(canJump ? theme.ink : theme.faint(theme.ink))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if isDone && !isCurrent {
                    Image(systemName: "checkmark")
                        .imageScale(.small)
                        .foregroundStyle(theme.patterned.provenColor)
                } else if !canJump {
                    Image(systemName: "lock")
                        .imageScale(.small)
                        .foregroundStyle(theme.faint(theme.ink))
                }
            }
            .standardType(.uiBody)
            .padding(.leading, StandardSpacing.sm)
            .padding(.vertical, StandardSpacing.xxs)
            .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
            .overlay(alignment: .leading) {
                if isCurrent {
                    Rectangle().fill(theme.brass).frame(width: 2)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!canJump)
        .accessibilityValue(isDone ? "Done" : (canJump ? "" : "Opens after the step before"))
    }

    /// A row for the whole chapter in one scroll: no step number and no lock, and a tap scrolls to
    /// the heading with the same words.
    private func wholeChapterRow(_ row: WholeChapterContents.Row) -> some View {
        Button {
            scrollTarget = row.id
        } label: {
            Text(row.label)
                .standardType(.uiBody)
                .foregroundStyle(theme.ink)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .padding(.leading, StandardSpacing.sm)
                .padding(.vertical, StandardSpacing.xxs)
                .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Scrolls to this part")
    }

    // MARK: Margin

    @ViewBuilder private func margin(showContents: Bool) -> some View {
        if showContents {
            contents
                .padding(.bottom, StandardSpacing.sm)
        }
        let notes = chapter.callouts.filter { $0.kind != "predict" && $0.kind != "check" }
        ForEach(Array(notes.enumerated()), id: \.element.id) { offset, note in
            MarginNote(.sidenote(offset + 1), "\(note.title). \(note.body)")
        }
        if let own = reading.readingThoughtsByChapter[chapter.number].flatMap({ $0.isEmpty ? nil : $0 })
            ?? PatternedBook.latestOwnWords(in: [chapter.number], responses: store.calloutResponses) {
            MarginNote(.hand, own)
        }
        ChainCard(standsOn: standsOn, unlocks: unlocks) { link in
            if let number = Int(link.code.replacingOccurrences(of: "Ch ", with: "")) {
                reading.open(chapter: number, store: store)
            }
        }
        if chapter.id == EuclidBuildLinks.mapChapter {
            Button("Build it in Euclid's Workshop") {
                store.openEuclid(.map)
            }
            .buttonStyle(TextLinkButtonStyle())
            .help("Open Book I in Euclid's Workshop")
        }
    }

    private var standsOn: [ChainLink] {
        store.visiblePatternedWorldChapters
            .filter { $0.number == chapter.number - 1 }
            .map { ChainLink(code: "Ch \($0.number)", title: $0.title) }
    }

    private var unlocks: [ChainLink] {
        store.visiblePatternedWorldChapters
            .filter { $0.number == chapter.number + 1 }
            .map { ChainLink(code: "Ch \($0.number)", title: $0.title) }
    }

    // MARK: Ambient British Coach Desk Bar

    private var deskTutorBar: some View {
        let preset = KymLiveBritishVoiceCatalog.defaultPreset
        return VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: StandardSpacing.sm) {
                    deskTutorHeader(preset: preset)
                    Spacer(minLength: StandardSpacing.sm)
                    deskTutorButtons
                }
                VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                    deskTutorHeader(preset: preset)
                    deskTutorButtons
                }
            }

            if let reply = deskTutorReply {
                VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                    Kicker("Clara · British Coach (en-GB)", muted: true)
                    ByrneText(reply)
                        .patternedType(.readingSmall)
                        .foregroundStyle(theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: StandardSpacing.xs) {
                        Button("Save takeaway to journal") {
                            let now = Date()
                            let entry = LabJournalEntryRecord(
                                id: "journal-desk-coach-ch\(chapter.number)-\(Int(now.timeIntervalSince1970))",
                                title: "British Coach Takeaway · Ch \(chapter.number) \(chapter.title)",
                                templateKind: "cornell",
                                paperStyle: "cornell",
                                linkedTopicCode: store.selectedTopicCode,
                                linkedChapterNumber: chapter.number,
                                linkedWidgetId: chapter.widgets.first ?? store.selectedWidgetId,
                                cueColumnText: chapter.hookSummary,
                                bodyNotesText: reply,
                                summaryText: chapter.intuitionToFormula.ahaInvariant,
                                hypothesisText: "",
                                independentVarText: "",
                                dependentVarText: "",
                                controlVarsText: "",
                                drawingData: nil,
                                snapshotPNGData: nil,
                                createdAt: now,
                                updatedAt: now
                            )
                            store.saveJournalEntry(entry)
                            deskTutorReply = "Saved to your Chapter \(chapter.number) Journal & Calendar."
                        }
                        .buttonStyle(OutlineButtonStyle())
                    }
                }
            }

            if showDeskQuietField {
                HStack(spacing: StandardSpacing.xs) {
                    TextField("Ask or reply quietly about this step…", text: $deskQuietDraft)
                        .textFieldStyle(.plain)
                        .paperField()
                    Button("Send") {
                        let q = deskQuietDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !q.isEmpty else { return }
                        deskTutorReply = "Let's test “\(q)” against what stays fixed in \(chapter.title): \(chapter.intuitionToFormula.ahaInvariant) Where does \(chapter.intuitionToFormula.formulaDisplay) show that on the figure?"
                        deskQuietDraft = ""
                    }
                    .buttonStyle(OutlineButtonStyle())
                    .disabled(deskQuietDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .paperCard(padding: StandardSpacing.md)
    }

    private func deskTutorHeader(preset: KymLiveBritishVoicePreset) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Kicker("British Coach (\(preset.displayName)) · Standing beside you")
            Text(chapter.hookSummary)
                .patternedType(.readingSmall)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var deskTutorButtons: some View {
        FlowLayout(spacing: StandardSpacing.xs) {
            Button("Talk with coach") {
                store.activeRoom = .coach
            }
            .buttonStyle(OutlineButtonStyle())

            Button(showDeskQuietField ? "Hide typing" : "Type quietly") {
                showDeskQuietField.toggle()
            }
            .buttonStyle(OutlineButtonStyle())

            Button("Give me a moment") {
                reading.narrator.stop()
                deskTutorReply = "Floor held — take all the time you need to work through the step on paper."
            }
            .buttonStyle(OutlineButtonStyle())

            Button("Journal & notes") {
                store.activeRoom = .mathsJournal
            }
            .buttonStyle(OutlineButtonStyle())
        }
    }

    // MARK: Gates

    private func isBeatUnlocked(_ beat: ChapterInteractiveBeat) -> Bool {
        PatternedChapterGates.isUnlocked(beat, reading: reading, store: store)
    }

    private func canNavigate(to index: Int) -> Bool {
        PatternedChapterGates.canNavigate(to: index, beats: beats, reading: reading, store: store)
    }
}

/// Whether a step is open: a gated step opens when its question is answered, its debate is won, or
/// the reader chose to skip it.
@MainActor
enum PatternedChapterGates {
    static func isUnlocked(_ beat: ChapterInteractiveBeat, reading: ChapterReadingState, store: AppStore) -> Bool {
        if !beat.requiresInteractionToUnlock || reading.completedBeatIds.contains(beat.id) {
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

    static func canNavigate(to index: Int, beats: [ChapterInteractiveBeat], reading: ChapterReadingState, store: AppStore) -> Bool {
        guard index > 0 else { return true }
        for idx in 0..<min(index, beats.count) where !isUnlocked(beats[idx], reading: reading, store: store) {
            return false
        }
        return true
    }

    static func isFormulaBridgeUnlocked(for chapter: PatternedWorldChapter, reading: ChapterReadingState, store: AppStore) -> Bool {
        if !store.showIntuitionBeforeFormula || reading.bypassedPredictionChapters.contains(chapter.number) {
            return true
        }
        let predictCallouts = chapter.callouts.filter { $0.kind == "predict" }
        guard !predictCallouts.isEmpty else { return true }
        return predictCallouts.contains { store.calloutResponses[$0.id]?.isUnlocked == true }
    }
}
