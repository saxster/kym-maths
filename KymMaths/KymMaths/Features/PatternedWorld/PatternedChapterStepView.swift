import SwiftUI

// MARK: - One step at a time

/// The reading column for one step of a chapter: its heading as a question, the text with Byrne
/// colours, the figure, the reader's turn, and the way on. The one filled button is whichever
/// action is next: locking the prediction while the gate is shut, moving on once it is open.
struct PatternedChapterStepView: View {
    @Bindable var store: AppStore
    @Bindable var reading: ChapterReadingState
    let chapter: PatternedWorldChapter
    let beats: [ChapterInteractiveBeat]
    let beatIndex: Int

    @Environment(\.standardTheme) private var theme

    private var beat: ChapterInteractiveBeat { beats[beatIndex] }
    private var isUnlocked: Bool { PatternedChapterGates.isUnlocked(beat, reading: reading, store: store) }
    private var terms: [FormulaTermMapping] { chapter.intuitionToFormula.termMappings }

    var body: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.lg) {
            VStack(alignment: .leading, spacing: StandardSpacing.sm) {
                Kicker("\(beat.code(chapter: chapter.number))  ·  \(beat.plainLabel)")
                WonderQuestion(heading)
                if beat.kind == .everydayHook {
                    Text(chapter.subtitle)
                        .patternedType(.readingSmall)
                        .foregroundStyle(theme.mute(theme.ink))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if beat.teachingSteps.isEmpty {
                ForEach(paragraphs, id: \.self) { paragraph in
                    ConceptText(PatternedBook.byrneMarked(paragraph, terms: terms), linking: chapter.linksConcepts)
                        .patternedType(.reading)
                        .foregroundStyle(theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                TeachingStepsView(steps: beat.teachingSteps, terms: terms)
            }

            if let bridge = beat.formulaBridge {
                IntuitionFormulaBridgeCard(
                    bridge: bridge,
                    selectedTermSymbol: $reading.selectedTermSymbol
                ) { term in
                    reading.highlightedColorRole = term.colorRole
                }
            }

            ChapterFigure(
                chapter: chapter,
                isShown: $reading.showEmbeddedWebStage,
                highlightedColorRole: reading.highlightedColorRole,
                onTermHighlighted: { role, symbol in
                    reading.highlightedColorRole = role
                    if !symbol.isEmpty { reading.selectedTermSymbol = symbol }
                },
                store: store
            )

            if let callout = beat.callout {
                calloutBlock(callout)
            }

            if let debate = beat.debateScenario {
                MathematicalDebateCardView(
                    scenario: debate,
                    initialSelectedChoiceId: store.calloutResponses["debate-\(debate.id)"]?.responseText,
                    onChoiceSelected: { choice, isCorrect in
                        store.saveCalloutResponse(
                            calloutId: "debate-\(debate.id)",
                            chapterNumber: chapter.number,
                            text: choice.id,
                            thinkingWhileReading: reading.readingThoughtsByChapter[chapter.number] ?? "",
                            confidencePercent: isCorrect ? 95 : 40,
                            isUnlockedOverride: isCorrect
                        )
                        if isCorrect {
                            reading.completedBeatIds.insert(beat.id)
                        }
                    }
                )
            }

            if !isUnlocked {
                LockedNote(lockedText)
            }

            wayOn
        }
    }

    // MARK: Words

    /// The step's heading. The first step opens with the chapter's own idea; later steps with
    /// their section heading.
    private var heading: String {
        switch beat.kind {
        case .everydayHook: chapter.hookSummary
        case .misconceptionDebate: beat.title
        case .chapterSynthesis: "What stays true in “\(chapter.title)”"
        default: beat.plainLabel
        }
    }

    private var paragraphs: [String] {
        switch beat.kind {
        // The hook is already the heading, and the subtitle sits under it; the reading text is
        // what you do with the figure.
        case .everydayHook: [chapter.intuitionToFormula.concreteAction]
        default: beat.bodyParagraphs.filter { $0 != heading }
        }
    }

    private var lockedText: String {
        if beat.debateScenario != nil {
            return "The next step opens when you pick who is right, and say why."
        }
        if beat.callout?.kind == "predict" {
            return "What stays the same, and the rule it gives you, opens after you predict."
        }
        return "The next step opens after you write your answer."
    }

    // MARK: The reader's turn

    @ViewBuilder private func calloutBlock(_ callout: PatternedWorldCallout) -> some View {
        if callout.kind == "predict" || callout.kind == "check" {
            let saved = store.calloutResponses[callout.id]
            let draft = Binding<String>(
                get: { reading.calloutDrafts[callout.id] ?? saved?.responseText ?? "" },
                set: { reading.calloutDrafts[callout.id] = $0 }
            )
            YourTurnCard(
                callout: callout,
                text: draft,
                isSaved: saved?.isUnlocked == true,
                isPrimary: !isUnlocked,
                linksConcepts: chapter.linksConcepts
            ) {
                let typed = draft.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
                store.saveCalloutResponse(
                    calloutId: callout.id,
                    chapterNumber: chapter.number,
                    text: typed.isEmpty ? "Verified beat reasoning" : draft.wrappedValue,
                    thinkingWhileReading: reading.readingThoughtsByChapter[chapter.number] ?? "",
                    confidencePercent: reading.calloutConfidenceById[callout.id] ?? 75,
                    isUnlockedOverride: true
                )
                reading.completedBeatIds.insert(beat.id)
            }
        } else {
            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                Kicker(callout.badgeText)
                Text(callout.title)
                    .standardType(.headlineSm)
                    .foregroundStyle(theme.ink)
                ConceptText(PatternedBook.byrneMarked(callout.body, terms: terms), linking: chapter.linksConcepts)
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .paperCard()
        }
    }

    // MARK: The way on

    private var wayOn: some View {
        HStack(spacing: StandardSpacing.sm) {
            if beatIndex > 0 {
                Button {
                    reading.activeBeatIndex = max(0, beatIndex - 1)
                } label: {
                    Label("Back", systemImage: "arrow.left")
                }
                .buttonStyle(OutlineButtonStyle())
            }
            Spacer(minLength: StandardSpacing.sm)
            if !isUnlocked {
                Button("Skip for now") {
                    reading.completedBeatIds.insert(beat.id)
                    if beatIndex + 1 < beats.count {
                        reading.activeBeatIndex = beatIndex + 1
                    }
                }
                .buttonStyle(TextLinkButtonStyle())
            } else if beatIndex + 1 < beats.count {
                Button("Read on: \(beats[beatIndex + 1].plainLabel)") {
                    reading.completedBeatIds.insert(beat.id)
                    let next = beatIndex + 1
                    reading.activeBeatIndex = next
                    store.markChapterRead(
                        chapterNumber: chapter.number,
                        fraction: Double(next + 1) / Double(max(1, beats.count)),
                        incrementCounters: false
                    )
                }
                .buttonStyle(ChapterActionStyle(filled: true))
                .lineLimit(1)
            } else {
                Button("Finish chapter \(chapter.number)") {
                    reading.completedBeatIds.insert(beat.id)
                    store.markChapterRead(chapterNumber: chapter.number, fraction: 1.0, incrementCounters: true)
                }
                .buttonStyle(ChapterActionStyle(filled: true))
            }
        }
    }
}
