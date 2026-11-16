import SwiftUI

// MARK: - Room 6: the journal, Kym's own pages

struct MathsJournalHomeView: View {
    @Bindable var store: AppStore
    @Environment(\.standardTheme) private var theme

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
    @State private var isWriting = false
    @State private var pageWidth: CGFloat = 600
    @State private var journalBrowseMode: String = "calendar"
    @State private var voiceNoteBookmarkQuote: String = ""
    @State private var voiceNoteBookmarks: [BookKitVoiceNoteBookmark] = []
    @State private var voiceNoteSpeed: String = "1×"
    @State private var voicePlaybackBanner: String?
    @State private var distillDraft: String = ""
    @State private var distillStatusBanner: String?
    @State private var showRootGlossaryDrawer = false
    @State private var voiceNarrator = ChapterAudioNarrator()

    private let templates = [
        ("proof_log", "A proof"),
        ("cornell", "Cornell notes"),
        ("construction", "A construction or bar model"),
        ("lab_log", "An investigation")
    ]

    private let browseModes = [
        ("calendar", "Calendar"),
        ("by_chapter", "By chapter"),
        ("all_pages", "All pages")
    ]

    private let papers = ["grid", "dots", "lined", "blank", "cornell"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StandardSpacing.xl) {
                header
                browseAndRootPromptBar

                if journalBrowseMode == "calendar" {
                    calendarHeatStrip
                }

                ReadingSpread {
                    if isWriting { writingCard } else { pageCard }
                } margin: {
                    ideasCard
                    voiceNotesMarginCard
                    distillRuleMarginCard
                    topicStatus
                }

                exemplarTemplatesBand
                otherPages
                ideaCollection
                deleteRow
            }
            .padding(.horizontal, StandardSpacing.xl)
            .padding(.vertical, StandardSpacing.xl)
            .frame(maxWidth: 1100, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(theme.bg)
        .onAppear {
            if selectedEntryId == nil, let first = store.journalEntries.first {
                loadEntry(first)
            }
            if store.deepLinkTail.contains("write") { isWriting = true }
        }
    }

    // MARK: Header

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .bottom, spacing: StandardSpacing.lg) {
                headerTitle
                Spacer(minLength: StandardSpacing.md)
                headerActions
            }
            VStack(alignment: .leading, spacing: StandardSpacing.md) {
                headerTitle
                headerActions
            }
        }
    }

    private var headerTitle: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            Kicker(entryKicker)
            Text(title.isEmpty ? "A new page" : title)
                .standardType(.headlineLg)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: 560, alignment: .leading)
    }

    private var headerActions: some View {
        HStack(spacing: StandardSpacing.sm) {
            Button("Deadlines & calendar") { store.showCalendarSheet = true }
                .buttonStyle(OutlineButtonStyle())
            Button("Add a page") { startNewEntry() }
                .buttonStyle(OutlineButtonStyle())
            Button(isWriting ? "Read it" : "Write") { isWriting.toggle() }
                .buttonStyle(OutlineButtonStyle())
                .accessibilityHint(isWriting ? "Shows the page as it reads" : "Opens the page for writing")
            Button {
                saveCurrentEntry()
            } label: {
                HStack(spacing: StandardSpacing.xs) {
                    Text("Save entry")
                    Image(systemName: "arrow.right").imageScale(.small)
                }
            }
            .buttonStyle(InkButtonStyle())
        }
    }

    private var browseAndRootPromptBar: some View {
        let suggested = BookKitRootGlossaryCatalog.suggestedRoot(
            forSubject: "math",
            chapterOrdinal: max(1, store.selectedChapterNumber + 1)
        )
        let mathRoots = BookKitRootGlossaryCatalog.roots(for: "math")
        return VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            FlowLayout(spacing: StandardSpacing.xs) {
                ForEach(browseModes, id: \.0) { code, label in
                    PatternedChip(label, isSelected: journalBrowseMode == code) {
                        journalBrowseMode = code
                    }
                }
                Button(showRootGlossaryDrawer ? "Hide word roots" : "Greek & Latin word roots") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showRootGlossaryDrawer.toggle()
                    }
                }
                .buttonStyle(OutlineButtonStyle())
            }
            HStack(spacing: StandardSpacing.xs) {
                Kicker("Word root prompt", muted: true)
                Button("Try using “\(suggested.headword)” (\(suggested.originLanguage) \(suggested.rootForm): \(suggested.literalMeaning))") {
                    isWriting = true
                    let line = "\(suggested.headword.capitalized) (\(suggested.literalMeaning)): \(suggested.plainExplanation)"
                    if bodyText.isEmpty {
                        bodyText = line
                    } else {
                        bodyText += "\n\(line)"
                    }
                }
                .buttonStyle(OutlineButtonStyle())
            }
            if showRootGlossaryDrawer {
                VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                    Kicker("Greek & Latin mathematics roots · why the words mean what they do")
                    ForEach(mathRoots) { root in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(root.headword) · \(root.originLanguage) \(root.rootForm) (“\(root.literalMeaning)”)")
                                .standardType(.uiHeadline)
                                .foregroundStyle(theme.ink)
                            Text(root.plainExplanation)
                                .patternedType(.readingSmall)
                                .foregroundStyle(theme.mute(theme.ink))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .paperCard(padding: StandardSpacing.md)
            }
        }
    }

    private var calendarHeatStrip: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let days: [Date] = (0..<14).compactMap { offset in
            cal.date(byAdding: .day, value: -(13 - offset), to: today)
        }
        return VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            HStack {
                Kicker("14-day study & journal calendar · heat dots", muted: true)
                Spacer(minLength: 0)
                Button("Open test deadlines") {
                    store.showCalendarSheet = true
                }
                .buttonStyle(OutlineButtonStyle())
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: StandardSpacing.xs), count: 7), spacing: StandardSpacing.xs) {
                ForEach(days, id: \.self) { day in
                    let count = store.journalEntries.filter { cal.isDate($0.updatedAt, inSameDayAs: day) }.count
                    VStack(spacing: 4) {
                        Text(day.formatted(.dateTime.weekday(.narrow)))
                            .standardType(.uiCaption)
                            .foregroundStyle(theme.mute(theme.ink))
                        Text(day.formatted(.dateTime.day()))
                            .standardType(.uiBody)
                            .fontWeight(cal.isDateInToday(day) ? .bold : .regular)
                            .foregroundStyle(theme.ink)
                        Circle()
                            .fill(count > 0 ? theme.patterned.provenColor : theme.faint(theme.ink))
                            .frame(width: 7, height: 7)
                    }
                    .padding(.vertical, StandardSpacing.xs)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous).fill(theme.surface))
                    .overlay(RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous).strokeBorder(cal.isDateInToday(day) ? theme.ink : theme.hairline(), lineWidth: 1))
                }
            }
        }
        .paperCard(padding: StandardSpacing.md)
    }

    private var voiceNotesMarginCard: some View {
        let nextSec = (voiceNoteBookmarks.count + 1) * 14
        let nextStamp = BookKitVoiceBookmarkParser.formatVoiceTimestamp(nextSec)
        return VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            Kicker("Voice notes & bookmarks", muted: true)
            Text("Bookmark a step while speaking out loud, listen back at \(voiceNoteSpeed), or send it to your coach.")
                .patternedType(.readingSmall)
                .foregroundStyle(theme.mute(theme.ink))

            HStack(spacing: StandardSpacing.xs) {
                TextField("Step or quote…", text: $voiceNoteBookmarkQuote)
                    .textFieldStyle(.plain)
                    .paperField()
                Button("+ [\(nextStamp)]") {
                    let quote = voiceNoteBookmarkQuote.isEmpty ? "Ch \(store.selectedChapterNumber) · Topic \(linkedTopicCode)" : voiceNoteBookmarkQuote
                    let bm = BookKitVoiceNoteBookmark(
                        timeSeconds: nextSec,
                        pageOrSectionRef: "Topic \(linkedTopicCode)",
                        quote: quote
                    )
                    voiceNoteBookmarks.append(bm)
                    let tag = BookKitVoiceBookmarkParser.formatBookmarkTag(bm)
                    if bodyText.isEmpty {
                        bodyText = tag
                    } else {
                        bodyText += "\n\(tag)"
                    }
                    voiceNoteBookmarkQuote = ""
                    voicePlaybackBanner = "Added bookmark \(tag)"
                }
                .buttonStyle(OutlineButtonStyle())
            }

            if !voiceNoteBookmarks.isEmpty {
                FlowLayout(spacing: StandardSpacing.xs) {
                    ForEach(voiceNoteBookmarks) { bm in
                        let tag = BookKitVoiceBookmarkParser.formatBookmarkTag(bm)
                        Button(tag) {
                            let spoken = bm.quote ?? bodyText
                            voiceNarrator.togglePlayPause(text: spoken, beatIndex: 0, beatId: bm.id)
                            voicePlaybackBanner = "Playing \(tag) at \(voiceNoteSpeed)"
                        }
                        .buttonStyle(OutlineButtonStyle())
                    }
                }
            }

            HStack(spacing: StandardSpacing.xs) {
                ForEach(["1×", "1.5×", "2×"], id: \.self) { spd in
                    PatternedChip(spd, isSelected: voiceNoteSpeed == spd) {
                        voiceNoteSpeed = spd
                        voiceNarrator.playbackSpeedMultiplier = spd == "2×" ? 2.0 : (spd == "1.5×" ? 1.5 : 1.0)
                    }
                }
                Button("Ask coach") {
                    store.activeRoom = .coach
                }
                .buttonStyle(OutlineButtonStyle())
            }

            if let banner = voicePlaybackBanner {
                Text(banner)
                    .standardType(.uiCaption)
                    .foregroundStyle(theme.patterned.provenColor)
            }
        }
        .paperCard()
    }

    private var distillRuleMarginCard: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            Kicker("Distill into rule card · own words check", muted: true)
            Text("Turn this page's main idea into a review card. Must be in your own words, not copied straight from the chapter.")
                .patternedType(.readingSmall)
                .foregroundStyle(theme.mute(theme.ink))
            TextField("In my own words, the rule works because…", text: $distillDraft)
                .textFieldStyle(.plain)
                .paperField()
            Button("Distill into rule card") {
                let candidate = distillDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? summaryText
                    : distillDraft
                let source = store.selectedChapter.intuitionToFormula.ahaInvariant
                let check = BookKitParaphraseValidator.validate(ownWords: candidate, sourceExcerpt: source)
                guard check.isAccepted else {
                    distillStatusBanner = check.feedbackMessage
                    return
                }
                let item = LiveVoiceTakeawayItem(
                    frontPrompt: title.isEmpty ? "Rule from Ch \(store.selectedChapterNumber) · \(store.selectedChapter.title)" : title,
                    backExplanation: candidate,
                    topicTag: linkedTopicCode
                )
                store.saveVoiceTakeawayFlashcard(item)
                distillDraft = ""
                distillStatusBanner = "Saved to your review cards (own-words check passed)."
            }
            .buttonStyle(OutlineButtonStyle())
            if let status = distillStatusBanner {
                Text(status)
                    .standardType(.uiCaption)
                    .foregroundStyle(theme.patterned.provenColor)
            }
        }
        .paperCard()
    }

    private var exemplarTemplatesBand: some View {
        let manifest = PatternedBook.bookManifest(
            chaptersCount: max(1, store.seedPack.chapters.count),
            learnerName: store.learnerDisplayName
        )
        let chapterSpec = PatternedBook.chapterSpec(for: store.selectedChapter, manifest: manifest)
        let exemplars = BookKitJournalExemplarCatalog.exemplars(for: manifest, firstChapter: chapterSpec)
        return VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            Kicker("Example starter pages · 4 ways to begin", muted: true)
            FlowLayout(spacing: StandardSpacing.xs) {
                ForEach(exemplars) { ex in
                    Button(ex.title) {
                        isWriting = true
                        templateKind = ex.templateKind.rawValue
                        paperStyle = ex.paperStyle.rawValue
                        title = ex.title
                        cueText = ex.cueQuestions
                        bodyText = ex.bodyText
                        summaryText = ex.oneSentenceSummary
                    }
                    .buttonStyle(OutlineButtonStyle())
                }
            }
        }
    }

    private var currentEntry: LabJournalEntryRecord? {
        store.journalEntries.first { $0.id == selectedEntryId }
    }

    private var entryKicker: String {
        let entry = currentEntry
        let number: Int
        if let entry {
            number = store.journalEntries.filter { $0.createdAt <= entry.createdAt }.count
        } else {
            number = store.journalEntries.count + 1
        }
        let day = (entry?.updatedAt ?? Date()).formatted(.dateTime.weekday(.wide))
        return "Journal · Entry \(number) · \(day)"
    }

    // MARK: The page as it reads

    private var pageCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                if pageWidth >= 540 {
                    HStack(alignment: .top, spacing: 0) {
                        questionsColumn
                            .frame(width: 190, alignment: .leading)
                            .padding(StandardSpacing.lg)
                        Rectangle().fill(theme.hairline()).frame(width: 1)
                        notesColumn
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(StandardSpacing.lg)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        questionsColumn.padding(StandardSpacing.lg)
                        Rectangle().fill(theme.hairline()).frame(height: 1)
                        notesColumn.padding(StandardSpacing.lg)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .readWidth($pageWidth)

            lookBackBand
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: StandardRadius.xl, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: StandardRadius.xl, style: .continuous).strokeBorder(theme.hairline(), lineWidth: 1))
    }

    private var questionsColumn: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.lg) {
            Kicker("Questions", muted: true)
            let questions = Self.lines(cueText)
            if questions.isEmpty {
                Text("What are you wondering? Press Write to add a question.")
                    .patternedType(.readingSmall)
                    .foregroundStyle(theme.mute(theme.ink))
            }
            ForEach(Array(questions.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .patternedType(.readingSmall)
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !givenInvariantsText.isEmpty {
                labelled("What you know", givenInvariantsText)
            }
            if !targetProveText.isEmpty {
                labelled("What you want to show", targetProveText)
            }
        }
    }

    private func labelled(_ label: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
            Kicker(label, muted: true)
            Text(text)
                .patternedType(.readingSmall)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var notesColumn: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.md) {
            Kicker("Notes", muted: true)

            if let png = currentEntry?.snapshotPNGData {
                JournalSnapshotImage(pngData: png)
                    .frame(maxHeight: 220)
                    .accessibilityLabel("Your drawing for this page")
            }

            let notes = Self.lines(bodyText)
            if notes.isEmpty {
                Text("Nothing written yet.")
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.mute(theme.ink))
            }
            ForEach(Array(notes.enumerated()), id: \.offset) { index, line in
                HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.sm) {
                    Text("\(index + 1)")
                        .patternedType(.numeral)
                        .foregroundStyle(theme.mute(theme.ink))
                        .frame(minWidth: 22, alignment: .leading)
                    Text(line)
                        .patternedType(.readingDefault)
                        .foregroundStyle(theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !conjectureText.isEmpty || !polyaStepsText.isEmpty {
                Rectangle().fill(theme.hairline()).frame(height: 1)
                    .padding(.vertical, StandardSpacing.xs)
                if !conjectureText.isEmpty {
                    Text(conjectureText)
                        .patternedType(.reading)
                        .foregroundStyle(theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !polyaStepsText.isEmpty {
                    HandNote(polyaStepsText)
                }
            }
        }
    }

    private var lookBackBand: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            Kicker("Look back · in one sentence")
            Text(summaryText.isEmpty ? "When you have finished, say why it works in one sentence." : summaryText)
                .patternedType(.reading)
                .foregroundStyle(summaryText.isEmpty ? theme.mute(theme.ink) : theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(StandardSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.patterned.wash(.stays))
    }

    // MARK: The page while writing

    private var writingCard: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.md) {
            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                PaperFieldLabel("Title")
                TextField("Why HCF × LCM = a × b", text: $title)
                    .textFieldStyle(.plain)
                    .paperField(emphasis: true)
            }

            HStack(spacing: StandardSpacing.sm) {
                Menu {
                    ForEach(templates, id: \.0) { code, label in
                        Button(label) { templateKind = code }
                    }
                } label: {
                    Label(templateLabel, systemImage: "rectangle.3.group")
                }
                .buttonStyle(OutlineButtonStyle())
                .accessibilityLabel("Kind of page: \(templateLabel)")

                Menu {
                    ForEach(papers, id: \.self) { paper in
                        Button(paper.capitalized) { paperStyle = paper }
                    }
                } label: {
                    Label("\(paperStyle.capitalized) paper", systemImage: "square.grid.3x3")
                }
                .buttonStyle(OutlineButtonStyle())
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: StandardSpacing.sm)], spacing: StandardSpacing.sm) {
                proofField(label: "What you think is true", text: $conjectureText)
                proofField(label: "What you know", text: $givenInvariantsText)
                proofField(label: "What you want to show", text: $targetProveText)
                proofField(label: "Your plan (in your own hand)", text: $polyaStepsText)
            }

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: StandardSpacing.md) {
                    questionsEditor.frame(width: 200)
                    notesEditor
                }
                VStack(alignment: .leading, spacing: StandardSpacing.md) {
                    questionsEditor
                    notesEditor
                }
            }

            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                PaperFieldLabel("Look back · in one sentence")
                TextField("Why does it always work?", text: $summaryText)
                    .textFieldStyle(.plain)
                    .paperField()
            }
        }
        .paperCard()
    }

    private var templateLabel: String {
        templates.first { $0.0 == templateKind }?.1 ?? templateKind.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private var questionsEditor: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            PaperFieldLabel("Questions, one a line")
            TextEditor(text: $cueText)
                .scrollContentBackground(.hidden)
                .patternedType(.readingSmall, measured: false)
                .foregroundStyle(theme.ink)
                .padding(StandardSpacing.xs)
                .frame(minHeight: 200)
                .background(RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous).fill(theme.bg))
                .overlay(RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous).strokeBorder(theme.hairline(), lineWidth: 1))
                .accessibilityLabel("Questions")
        }
    }

    /// Cornell's cue column is the Questions field beside the notes, so the notes take the lined
    /// half of the page. Lined text starts past the margin rule.
    private var notesPaper: JournalPaperStyle {
        let style = JournalPaperStyle(rawValue: paperStyle) ?? .grid
        return style == .cornell ? .lined : style
    }

    private var notesEditor: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            PaperFieldLabel("Notes, one step a line")
            ZStack {
                JournalPaperBackground(style: notesPaper)
                    .clipShape(RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous))
                TextEditor(text: $bodyText)
                    .scrollContentBackground(.hidden)
                    .patternedType(.readingDefault, measured: false).monospaced()
                    .foregroundStyle(theme.ink)
                    .padding(StandardSpacing.xs)
                    .padding(.leading, notesPaper == .lined ? JournalPaperMetrics.textLeadingPadding - StandardSpacing.xs : 0)
                    .accessibilityLabel("Notes")
            }
            .frame(minHeight: 200)
            .overlay(RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous).strokeBorder(theme.hairline(), lineWidth: 1))
        }
    }

    private func proofField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            PaperFieldLabel(label)
            TextField(label, text: text, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .padding(.vertical, StandardSpacing.xs)
                .paperField()
        }
    }

    // MARK: The margin

    private var ideasOnThisPage: [PropositionNodeRecord] {
        guard let id = selectedEntryId else { return [] }
        return Array(store.propositionNodes.filter { node in
            node.decodedProvenance.contains { $0.sourceId == id }
        }.prefix(4))
    }

    /// The chapter after the one this page is linked to, as the next idea on the path.
    private var nextUnit: SchoolMathsUnit? {
        let units = store.seedPack.schoolTextbook.units
        guard let index = units.firstIndex(where: { unit in unit.topics.contains { $0.code == linkedTopicCode } }),
              index + 1 < units.count else { return nil }
        return units[index + 1]
    }

    private var ideasCard: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.md) {
            Kicker("Ideas on this page", muted: true)
            let ideas = ideasOnThisPage
            if ideas.isEmpty {
                Text("When you save a page, the ideas in it are kept here.")
                    .standardType(.uiBody)
                    .foregroundStyle(theme.mute(theme.ink))
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(Array(ideas.enumerated()), id: \.element.id) { index, node in
                ideaStep(
                    name: node.name,
                    detail: node.isUnconditionalTruth ? "Starting point · Ch \(node.chapterNumber)" : "Worked out · Ch \(node.chapterNumber)",
                    fill: node.isUnconditionalTruth ? theme.patterned.provenWashColor : theme.patterned.wash(.given),
                    stroke: node.isUnconditionalTruth ? theme.patterned.provenColor : theme.patterned.color(.given),
                    dashed: false,
                    isLast: index == ideas.count - 1 && nextUnit == nil
                )
            }
            if let next = nextUnit {
                ideaStep(
                    name: next.title,
                    detail: "Next, in Ch \(next.unitNumber)",
                    fill: .clear,
                    stroke: theme.hairline(),
                    dashed: true,
                    isLast: true
                )
            }
        }
        .paperCard()
    }

    private func ideaStep(name: String, detail: String, fill: Color, stroke: Color, dashed: Bool, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: StandardSpacing.sm) {
            VStack(spacing: 0) {
                Circle()
                    .fill(fill)
                    .overlay(Circle().strokeBorder(stroke, style: StrokeStyle(lineWidth: 1.5, dash: dashed ? [3, 3] : [])))
                    .frame(width: 26, height: 26)
                if !isLast {
                    Rectangle().fill(theme.hairline()).frame(width: 1, height: 22)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .standardType(.uiHeadline)
                    .foregroundStyle(dashed ? theme.mute(theme.ink) : theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail)
                    .standardType(.uiCaption)
                    .foregroundStyle(theme.mute(theme.ink))
            }
            .padding(.top, 3)
        }
        .accessibilityElement(children: .combine)
    }

    /// Where the page's topic stands, from her answers to its questions.
    @ViewBuilder
    private var topicStatus: some View {
        let questions = store.questions(forTopic: linkedTopicCode)
        if !questions.isEmpty {
            let levels = questions.map { QuestionProofLevel(rawValue: store.proofsByQuestionId[$0.id]?.proofLevel ?? "") ?? .unseen }
            let status: LearningStatus = {
                if levels.allSatisfy({ $0 == .secure }) { return .secure }
                if levels.allSatisfy({ $0 == .proven || $0 == .secure }) { return .proven }
                if levels.contains(where: { $0 == .proven || $0 == .secure }) { return .working }
                if levels.contains(where: { $0 == .assisted || $0 == .shaky }) { return .withHelp }
                return .notStarted
            }()
            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                StatusTag(status)
                Text("Topic \(linkedTopicCode) in your school book")
                    .standardType(.uiCaption)
                    .foregroundStyle(theme.mute(theme.ink))
            }
        }
    }

    // MARK: Lower on the page

    @ViewBuilder
    private var otherPages: some View {
        let others = journalBrowseMode == "all_pages"
            ? store.journalEntries
            : store.journalEntries.filter { $0.id != selectedEntryId }
        if !others.isEmpty {
            VStack(alignment: .leading, spacing: StandardSpacing.sm) {
                Kicker(journalBrowseMode == "by_chapter" ? "Pages grouped by chapter" : "Your other pages", muted: true)
                if journalBrowseMode == "by_chapter" {
                    let chapters = Array(Set(others.map { $0.linkedChapterNumber ?? 0 })).sorted()
                    ForEach(chapters, id: \.self) { chNum in
                        let chTitle = store.seedPack.chapters.first(where: { $0.number == chNum })?.title ?? "Chapter \(chNum)"
                        VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                            Kicker("Chapter \(chNum) · \(chTitle)")
                            entryListCard(others.filter { ($0.linkedChapterNumber ?? 0) == chNum })
                        }
                    }
                } else {
                    entryListCard(others)
                }
            }
        }
    }

    private func entryListCard(_ list: [LabJournalEntryRecord]) -> some View {
        VStack(spacing: 0) {
            ForEach(list) { entry in
                Button {
                    loadEntry(entry)
                } label: {
                    HStack(spacing: StandardSpacing.md) {
                        Image(systemName: "doc.text")
                            .foregroundStyle(theme.mute(theme.ink))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.title)
                                .standardType(.uiHeadline)
                                .foregroundStyle(theme.ink)
                                .multilineTextAlignment(.leading)
                            Text("Ch \(entry.linkedChapterNumber ?? 0) · \(entry.updatedAt.formatted(.dateTime.weekday(.wide).day().month(.wide)))")
                                .standardType(.uiCaption)
                                .foregroundStyle(theme.mute(theme.ink))
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .imageScale(.small)
                            .foregroundStyle(theme.mute(theme.ink))
                            .accessibilityHidden(true)
                    }
                    .padding(.vertical, StandardSpacing.sm)
                    .frame(minHeight: StandardAccessibility.touchTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if entry.id != list.last?.id {
                    Rectangle().fill(theme.hairline()).frame(height: 1)
                }
            }
        }
        .paperCard(padding: StandardSpacing.md)
    }

    private var ideaCollection: some View {
        DisclosureGroup {
            ideaCollectionBody
                .padding(.top, StandardSpacing.md)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text("Every idea you have collected")
                    .standardType(.uiHeadline)
                    .foregroundStyle(theme.ink)
                Text("\(store.propositionNodes.count) ideas · \(store.derivationChains.count) ways they link")
                    .standardType(.uiCaption)
                    .foregroundStyle(theme.mute(theme.ink))
            }
        }
        .tint(theme.ink)
        .paperCard()
    }

    private var ideaCollectionBody: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.md) {
            HStack(alignment: .center, spacing: StandardSpacing.sm) {
                Text("\(store.propositionNodes.filter(\.isUnconditionalTruth).count) starting points you can lean on.")
                    .standardType(.uiBody)
                    .foregroundStyle(theme.mute(theme.ink))
                Spacer(minLength: StandardSpacing.sm)
                Button {
                    let simplified = PropositionGraphEngine.simplifyChains(store.derivationChains)
                    try? store.db.replacePropositionGraph(nodes: store.propositionNodes, chains: simplified)
                    store.refreshState()
                } label: {
                    Label("Tidy the links", systemImage: "wand.and.stars")
                }
                .buttonStyle(OutlineButtonStyle())
                .accessibilityHint("Removes links that repeat a shorter one")
            }

            let nodesById = Dictionary(uniqueKeysWithValues: store.propositionNodes.map { ($0.id, $0) })

            if !store.derivationChains.isEmpty {
                Kicker("How they link", muted: true)
                ForEach(store.derivationChains.prefix(6)) { chain in
                    let premiseTitles = chain.premisesList.map { nodesById[$0]?.name ?? $0 }
                    let conclusionNode = nodesById[chain.conclusionId]
                    VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                        Text("\(premiseTitles.joined(separator: " + ")) → \(conclusionNode?.name ?? chain.conclusionId)")
                            .standardType(.uiHeadline)
                            .foregroundStyle(theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        if let statement = conclusionNode?.statement {
                            Text(statement)
                                .patternedType(.readingSmall)
                                .foregroundStyle(theme.mute(theme.ink))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(StandardSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous).fill(theme.patterned.sunkColor))
                }
            }

            Kicker("The ideas", muted: true)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: StandardSpacing.sm)], spacing: StandardSpacing.sm) {
                ForEach(store.propositionNodes.prefix(8)) { node in
                    VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                        HStack {
                            StatusTag(node.isUnconditionalTruth ? .secure : .working,
                                      label: node.isUnconditionalTruth ? "Starting point" : "Worked out")
                            Spacer()
                            Text("Ch \(node.chapterNumber)")
                                .standardType(.uiCaption)
                                .foregroundStyle(theme.mute(theme.ink))
                        }
                        Text(node.name)
                            .standardType(.uiHeadline)
                            .foregroundStyle(theme.ink)
                        Text(node.statement)
                            .patternedType(.readingSmall)
                            .foregroundStyle(theme.mute(theme.ink))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(StandardSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .background(RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous).fill(theme.patterned.sunkColor))
                }
            }
        }
    }

    @ViewBuilder
    private var deleteRow: some View {
        if let id = selectedEntryId, store.journalEntries.count > 1 {
            Button("Delete this page") {
                store.deleteJournalEntry(id: id)
                if let first = store.journalEntries.first {
                    loadEntry(first)
                }
            }
            .buttonStyle(TextLinkButtonStyle(arrow: false))
        }
    }

    // MARK: Text

    /// The non-empty lines of a field, without the "1." or "•" she may have typed in front.
    static func lines(_ text: String) -> [String] {
        text.split(whereSeparator: \.isNewline).compactMap { raw in
            var line = raw.trimmingCharacters(in: .whitespaces)
            if let first = line.first, "•-–*".contains(first) {
                line = String(line.dropFirst()).trimmingCharacters(in: .whitespaces)
            } else if let range = line.range(of: #"^\d+[.)]\s*"#, options: .regularExpression) {
                line.removeSubrange(range)
            }
            return line.isEmpty ? nil : line
        }
    }

    // MARK: Loading and saving (unchanged)

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
        title = "New page — Topic \(store.selectedTopicCode)"
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
        isWriting = true
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

/// A saved drawing on a journal page.
private struct JournalSnapshotImage: View {
    let pngData: Data

    var body: some View {
        #if canImport(UIKit)
        if let image = UIImage(data: pngData) {
            Image(uiImage: image).resizable().scaledToFit()
        }
        #elseif canImport(AppKit)
        if let image = NSImage(data: pngData) {
            Image(nsImage: image).resizable().scaledToFit()
        }
        #endif
    }
}
