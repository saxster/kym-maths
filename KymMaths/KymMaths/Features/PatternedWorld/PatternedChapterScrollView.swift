import SwiftUI

// MARK: - The whole chapter in one scroll

/// The chapter read straight through: the idea, the prediction, what you do and what stays the
/// same, the formula once you have predicted, the figure, the debate, the sections, a note while
/// you read, and the checks. Finishing the chapter is the one filled button.
struct PatternedChapterScrollView: View {
    @Bindable var store: AppStore
    @Bindable var reading: ChapterReadingState
    let chapter: PatternedWorldChapter

    @Environment(\.standardTheme) private var theme

    private var bridge: IntuitionToFormulaBridge { chapter.intuitionToFormula }
    private var terms: [FormulaTermMapping] { bridge.termMappings }
    private var isRead: Bool { (store.readingProgressByChapter[chapter.number]?.readFraction ?? 0) >= 0.9 }

    private static let confidenceChoices: [(label: String, percent: Int)] = [
        ("Not sure", 35), ("Fairly sure", 75), ("Sure", 95)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xl) {
            opening
            predictions
            bridgeSteps
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
            debate
            sections
            thinkingNote
            checks
            finish
        }
    }

    // MARK: Opening

    private var opening: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            Kicker("Chapter \(chapter.number)  ·  \(chapter.title)")
            WonderQuestion(chapter.hookSummary)
            Text(chapter.subtitle)
                .patternedType(.readingSmall)
                .foregroundStyle(theme.mute(theme.ink))
                .fixedSize(horizontal: false, vertical: true)
            if isRead {
                StatusTag(.proven, label: "Read")
            }
        }
    }

    // MARK: Predict first

    private var predictions: some View {
        ForEach(chapter.callouts.filter { $0.kind == "predict" }) { callout in
            let saved = store.calloutResponses[callout.id]
            let draft = Binding<String>(
                get: { reading.calloutDrafts[callout.id] ?? saved?.responseText ?? "" },
                set: { reading.calloutDrafts[callout.id] = $0 }
            )
            YourTurnCard(callout: callout, text: draft, isSaved: saved?.isUnlocked == true, isPrimary: false,
                         linksConcepts: chapter.linksConcepts) {
                let typed = draft.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
                store.saveCalloutResponse(
                    calloutId: callout.id,
                    chapterNumber: chapter.number,
                    text: typed.isEmpty ? "Locked prediction" : draft.wrappedValue,
                    thinkingWhileReading: reading.readingThoughtsByChapter[chapter.number] ?? "",
                    confidencePercent: reading.calloutConfidenceById[callout.id] ?? 75,
                    isUnlockedOverride: true
                )
            }
        }
    }

    // MARK: What you do, what stays the same

    private var bridgeSteps: some View {
        let unlocked = PatternedChapterGates.isFormulaBridgeUnlocked(for: chapter, reading: reading, store: store)
        return VStack(alignment: .leading, spacing: StandardSpacing.md) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: StandardSpacing.md) { stepPanels }
                VStack(alignment: .leading, spacing: StandardSpacing.md) { stepPanels }
            }
            if unlocked {
                IntuitionFormulaBridgeCard(
                    bridge: bridge,
                    selectedTermSymbol: $reading.selectedTermSymbol
                ) { term in
                    reading.highlightedColorRole = term.colorRole
                }
            } else {
                LockedNote("The rule this picture gives you opens after you predict.")
                Button("Just show me the rule") {
                    reading.bypassedPredictionChapters.insert(chapter.number)
                }
                .buttonStyle(TextLinkButtonStyle())
            }
        }
    }

    @ViewBuilder private var stepPanels: some View {
        stepPanel(kicker: "What you do", text: bridge.concreteAction)
        stepPanel(kicker: "What stays the same", text: bridge.ahaInvariant)
    }

    private func stepPanel(kicker: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            Kicker(kicker)
            ConceptText(PatternedBook.byrneMarked(text, terms: terms), linking: chapter.linksConcepts)
                .patternedType(.readingDefault)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .paperCard(padding: StandardSpacing.md)
    }

    // MARK: Who is right?

    private var debate: some View {
        let scenario = MathematicalDebateEngine.scenario(forChapter: chapter.number)
        return VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            Kicker("Who is right, and why?")
            MathematicalDebateCardView(
                scenario: scenario,
                initialSelectedChoiceId: store.calloutResponses["debate-\(scenario.id)"]?.responseText,
                onChoiceSelected: { choice, isCorrect in
                    store.saveCalloutResponse(
                        calloutId: "debate-\(scenario.id)",
                        chapterNumber: chapter.number,
                        text: choice.id,
                        thinkingWhileReading: reading.readingThoughtsByChapter[chapter.number] ?? "",
                        confidencePercent: isCorrect ? 95 : 40,
                        isUnlockedOverride: isCorrect
                    )
                }
            )
        }
    }

    // MARK: Sections

    private var sections: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.lg) {
            ForEach(chapter.sections) { section in
                VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                    Text(PatternedBook.stripCode(section.heading))
                        .standardType(.headlineMd)
                        .foregroundStyle(theme.ink)
                    if section.teachingSteps.isEmpty {
                        ByrneText(PatternedBook.byrneMarked(section.excerpt, terms: terms))
                            .patternedType(.reading)
                            .foregroundStyle(theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        TeachingStepsView(steps: section.teachingSteps, terms: terms)
                            .padding(.top, StandardSpacing.xs)
                    }
                }
            }
        }
    }

    private var thinkingNote: some View {
        let thought = Binding<String>(
            get: { reading.readingThoughtsByChapter[chapter.number] ?? "" },
            set: { reading.readingThoughtsByChapter[chapter.number] = $0 }
        )
        return VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            Kicker("A note while you read")
            LearnerTextInput(
                title: "",
                placeholder: "A question, a link to something you know, or what still feels fuzzy…",
                text: thought,
                minHeight: 60
            )
        }
    }

    // MARK: Checks

    private var checks: some View {
        ForEach(chapter.callouts.filter { $0.kind != "predict" }) { callout in
            checkCard(callout)
        }
    }

    private func checkCard(_ callout: PatternedWorldCallout) -> some View {
        let saved = store.calloutResponses[callout.id]
        let isCheck = callout.kind == "check"
        let isRevealed = !isCheck || reading.revealedCheckCalloutIds.contains(callout.id) || saved?.isUnlocked == true
        return VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Kicker(callout.badgeText)
                Spacer()
                if saved?.isUnlocked == true {
                    StatusTag(.working, label: "Saved")
                }
            }
            Text(callout.title)
                .standardType(.headlineSm)
                .foregroundStyle(theme.ink)
            if !isRevealed {
                HStack(alignment: .center, spacing: StandardSpacing.sm) {
                    Text("Finish reading the step above, then try this check.")
                        .patternedType(.readingSmall)
                        .foregroundStyle(theme.mute(theme.ink))
                    Spacer(minLength: StandardSpacing.sm)
                    Button("I'm ready") {
                        reading.revealedCheckCalloutIds.insert(callout.id)
                    }
                    .buttonStyle(OutlineButtonStyle())
                }
            } else {
                ConceptText(PatternedBook.byrneMarked(callout.body, terms: terms), linking: chapter.linksConcepts)
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if isCheck {
                    checkInput(callout, saved: saved)
                }
            }
        }
        .paperCard()
    }

    @ViewBuilder private func checkInput(_ callout: PatternedWorldCallout, saved: CalloutResponseRecord?) -> some View {
        let answer = Binding<String>(
            get: { reading.calloutDrafts[callout.id] ?? saved?.responseText ?? "" },
            set: { reading.calloutDrafts[callout.id] = $0 }
        )
        let confidence = Binding<Int>(
            get: { reading.calloutConfidenceById[callout.id] ?? saved?.confidencePercent ?? 75 },
            set: { reading.calloutConfidenceById[callout.id] = $0 }
        )
        LearnerTextInput(
            title: "",
            placeholder: "Say what stays the same, and the rule it gives you…",
            text: answer,
            minHeight: 72
        )
        ViewThatFits(in: .horizontal) {
            HStack(spacing: StandardSpacing.sm) {
                confidencePicker(confidence)
                Spacer(minLength: StandardSpacing.sm)
                saveCheckButton(callout, answer: answer, confidence: confidence)
            }
            VStack(alignment: .leading, spacing: StandardSpacing.sm) {
                confidencePicker(confidence)
                saveCheckButton(callout, answer: answer, confidence: confidence)
            }
        }
    }

    private func confidencePicker(_ confidence: Binding<Int>) -> some View {
        HStack(spacing: StandardSpacing.xs) {
            Text("How sure are you?")
                .standardType(.uiCaption)
                .foregroundStyle(theme.mute(theme.ink))
            ForEach(Self.confidenceChoices, id: \.percent) { choice in
                Button(choice.label) {
                    confidence.wrappedValue = choice.percent
                }
                .buttonStyle(OutlineButtonStyle())
                .overlay(
                    RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                        .strokeBorder(confidence.wrappedValue == choice.percent ? theme.ink : Color.clear, lineWidth: 1.5)
                )
                .accessibilityAddTraits(confidence.wrappedValue == choice.percent ? .isSelected : [])
            }
        }
    }

    private func saveCheckButton(_ callout: PatternedWorldCallout, answer: Binding<String>, confidence: Binding<Int>) -> some View {
        Button("Save my answer") {
            let typed = answer.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
            store.saveCalloutResponse(
                calloutId: callout.id,
                chapterNumber: chapter.number,
                text: typed.isEmpty ? "Verified checkpoint" : answer.wrappedValue,
                thinkingWhileReading: reading.readingThoughtsByChapter[chapter.number] ?? "",
                confidencePercent: confidence.wrappedValue,
                isUnlockedOverride: true
            )
        }
        .buttonStyle(OutlineButtonStyle())
    }

    // MARK: Finish

    private var finish: some View {
        HStack {
            Spacer()
            Button(isRead ? "Mark as read again" : "I've finished this chapter") {
                store.markChapterRead(chapterNumber: chapter.number, fraction: 1.0)
            }
            .buttonStyle(ChapterActionStyle(filled: !isRead))
        }
    }
}
