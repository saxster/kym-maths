import SwiftUI

// MARK: - Room 7: the coach, a patient tutor in the margin of her work

struct MathsCoachView: View {
    @Bindable var store: AppStore
    @Environment(\.standardTheme) private var theme

    @State private var queryText: String = ""
    @State private var workingDraftText: String = ""
    @State private var bracketDrafts: [String: String] = [:]
    @State private var liveVoiceController = LiveMentorVoiceController()
    @State private var safetyEvalReport: SafetyEvalSuiteReport = ChildSafetyEvalHarness.runFullSuite()
    @State private var latestCouncilVerdict: AdversarialCouncil.CouncilVerdict?
    @State private var showWorkings = false
    @State private var roomWidth: CGFloat = 700

    private let starterPrompts = [
        "Why does HCF × LCM = a × b?",
        "How do I convert 0.27 recurring to a fraction?",
        "Explain Bayes' Theorem with the 1,000-person square",
        "How does a secant line become the derivative dy/dx?",
        "What does det(A) = ad − bc mean geometrically?",
        "Just explain how to expand 5(2x + 3) − 3(x − 4)"
    ]

    private var topic: String { store.selectedUnit.title }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StandardSpacing.xl) {
                EditorialHeader(
                    eyebrow: "Coach",
                    title: "Think it through out loud",
                    subtitle: "The coach asks before it tells. You can always ask it to just explain."
                )

                Group {
                    if roomWidth >= 760 {
                        HStack(alignment: .top, spacing: StandardSpacing.lg) {
                            conversationCard.frame(maxWidth: .infinity)
                            boardColumn.frame(width: min(440, roomWidth * 0.42))
                        }
                    } else {
                        VStack(alignment: .leading, spacing: StandardSpacing.lg) {
                            conversationCard
                            boardColumn
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .readWidth($roomWidth)
            }
            .padding(StandardSpacing.xl)
            .frame(maxWidth: 1100, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(theme.bg)
        .sheet(isPresented: $showWorkings) {
            CoachWorkingsSheet(
                store: store,
                voice: liveVoiceController,
                bracketDrafts: $bracketDrafts,
                safetyEvalReport: safetyEvalReport,
                latestCouncilVerdict: latestCouncilVerdict
            )
            .pageSizedSheet()
        }
        .onAppear {
            if store.deepLinkTail.contains("how") { showWorkings = true }
        }
    }

    // MARK: The conversation

    private var conversationCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: StandardSpacing.md) {
                if store.mentorTurns.isEmpty {
                    CoachBubble(speaker: "Coach", isLearner: false) {
                        Text("Hello \(store.learnerDisplayName). What are you wondering about? Ask about any chapter in your school book or in The Patterned World.")
                            .patternedType(.readingDefault)
                            .foregroundStyle(theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    starters
                } else {
                    ForEach(store.mentorTurns) { turn in
                        turnBubble(turn)
                    }
                }

                if liveVoiceController.sessionState.isConnected {
                    voiceStrip
                }
                callTranscript
                callTakeaways

                HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.xs) {
                    Image(systemName: "lightbulb")
                        .imageScale(.small)
                        .foregroundStyle(theme.mute(theme.ink))
                        .accessibilityHidden(true)
                    Text("Say “just explain” any time and the coach will tell you straight.")
                        .standardType(.uiCaption)
                        .foregroundStyle(theme.mute(theme.ink))
                }
            }
            .padding(StandardSpacing.lg)

            Rectangle().fill(theme.hairline()).frame(height: 1)

            inputBar
                .padding(StandardSpacing.md)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: StandardRadius.xl, style: .continuous).fill(theme.surface))
        .overlay(RoundedRectangle(cornerRadius: StandardRadius.xl, style: .continuous).strokeBorder(theme.hairline(), lineWidth: 1))
    }

    private var starters: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            Kicker("Or start with one of these", muted: true)
            FlowLayout(spacing: StandardSpacing.xs) {
                ForEach(starterPrompts, id: \.self) { prompt in
                    Button(prompt) {
                        Task {
                            await store.sendMentorMessage(
                                prompt,
                                activeQuestion: store.activePracticeQuestion,
                                learnerDraft: workingDraftText
                            )
                        }
                    }
                    .buttonStyle(OutlineButtonStyle())
                }
            }
        }
    }

    @ViewBuilder
    private func turnBubble(_ turn: MathsMentorTurn) -> some View {
        switch turn.role {
        case "learner":
            CoachBubble(speaker: store.learnerDisplayName, isLearner: true) {
                Text(turn.text)
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        case "safety":
            CoachBubble(speaker: "Looking after you", isLearner: false) {
                Text(turn.text)
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        default:
            CoachBubble(speaker: "Coach", isLearner: false, note: turn.guidanceStyle == .adaptive ? nil : turn.guidanceStyle.title) {
                ConceptText(turn.text)
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var inputBar: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            HStack(spacing: StandardSpacing.sm) {
                HStack(spacing: StandardSpacing.xs) {
                    TextField(
                        liveVoiceController.sessionState.isConnected ? "Say it to the coach…" : "Ask the coach…",
                        text: $queryText
                    )
                    .textFieldStyle(.plain)
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.ink)
                    .onSubmit { sendCurrentQuery() }

                    micButton
                }
                .padding(.leading, StandardSpacing.md)
                .frame(minHeight: StandardAccessibility.touchTarget + 4)
                .background(Capsule().fill(theme.bg))
                .overlay(Capsule().strokeBorder(theme.hairline(), lineWidth: 1))

                Button {
                    sendCurrentQuery()
                } label: {
                    HStack(spacing: StandardSpacing.xs) {
                        Text("Send")
                        Image(systemName: "arrow.right").imageScale(.small)
                    }
                }
                .buttonStyle(InkButtonStyle())
                .disabled(queryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if let activeQ = store.activePracticeQuestion,
               let savedPad = store.loadScratchpad(questionId: activeQ.id) {
                Button {
                    Task {
                        await store.shareScratchpadWithCoach(
                            pngData: savedPad.previewPNGData,
                            activeQuestion: activeQ
                        )
                    }
                } label: {
                    Label("Show the coach my working", systemImage: "square.and.pencil")
                }
                .buttonStyle(OutlineButtonStyle())
            }
        }
    }

    /// Starts a spoken conversation, or mutes and unmutes one that is running.
    private var micButton: some View {
        let connected = liveVoiceController.sessionState.isConnected
        let muted = liveVoiceController.isMicrophoneMuted
        return Button {
            if connected {
                liveVoiceController.isMicrophoneMuted.toggle()
            } else {
                liveVoiceController.startSession(
                    topic: topic,
                    soulID: store.selectedSoulId,
                    overrides: store.soulParentOverrides,
                    guidanceStyle: store.requestedGuidanceStyle,
                    mathContextSummary: store.activePracticeQuestion?.prompt
                )
            }
        } label: {
            Image(systemName: connected ? (muted ? "mic.slash" : "mic.fill") : "mic")
                .foregroundStyle(connected && !muted ? theme.brass : theme.mute(theme.ink))
                .frame(width: StandardAccessibility.touchTarget, height: StandardAccessibility.touchTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(connected ? (muted ? "Turn the microphone on" : "Turn the microphone off") : "Talk to the coach")
    }

    // MARK: Talking out loud

    private var voiceStrip: some View {
        HStack(spacing: StandardSpacing.sm) {
            Circle().fill(theme.brass).frame(width: 8, height: 8)
                .accessibilityHidden(true)
            Text(liveVoiceController.isMicrophoneMuted ? "Talking with the coach · microphone off" : "Talking with the coach")
                .standardType(.uiBody)
                .foregroundStyle(theme.ink)
            Spacer(minLength: StandardSpacing.sm)
            Button {
                liveVoiceController.endSession(topic: topic)
            } label: {
                Label("End", systemImage: "phone.down")
            }
            .buttonStyle(OutlineButtonStyle())
            .accessibilityLabel("End the spoken conversation")
        }
        .padding(.horizontal, StandardSpacing.md)
        .padding(.vertical, StandardSpacing.xs)
        .background(RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous).fill(theme.patterned.sunkColor))
    }

    @ViewBuilder
    private var callTranscript: some View {
        if !liveVoiceController.transcripts.isEmpty {
            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                Kicker("What you said out loud", muted: true)
                ForEach(liveVoiceController.transcripts.suffix(5)) { entry in
                    HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.xs) {
                        Text(speakerName(entry.speaker))
                            .standardType(.uiCaption)
                            .fontWeight(.semibold)
                            .foregroundStyle(entry.speaker == .learner ? theme.ink : theme.brass)
                        Text(entry.text)
                            .standardType(.uiBody)
                            .foregroundStyle(theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(StandardSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous).fill(theme.patterned.sunkColor))
        }
    }

    private func speakerName(_ speaker: LiveMentorTranscriptEntry.Speaker) -> String {
        switch speaker {
        case .learner: return store.learnerDisplayName
        case .mentor: return "Coach"
        case .system: return "Note"
        }
    }

    @ViewBuilder
    private var callTakeaways: some View {
        if !liveVoiceController.takeaways.isEmpty {
            VStack(alignment: .leading, spacing: StandardSpacing.sm) {
                Kicker("Worth remembering")
                ForEach(liveVoiceController.takeaways) { item in
                    HStack(alignment: .top, spacing: StandardSpacing.sm) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.frontPrompt)
                                .standardType(.uiHeadline)
                                .foregroundStyle(theme.ink)
                            Text(item.backExplanation)
                                .standardType(.uiBody)
                                .foregroundStyle(theme.mute(theme.ink))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: StandardSpacing.sm)
                        let isSaved = liveVoiceController.savedFlashcardIDs.contains(item.id)
                        Button {
                            liveVoiceController.savedFlashcardIDs.insert(item.id)
                            store.saveVoiceTakeawayFlashcard(item)
                        } label: {
                            Label(isSaved ? "Kept" : "Keep for review", systemImage: isSaved ? "checkmark" : "plus")
                        }
                        .buttonStyle(OutlineButtonStyle())
                        .disabled(isSaved)
                    }
                }
            }
            .padding(StandardSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous).fill(theme.patterned.wash(.stays)))
        }
    }

    // MARK: The shared board

    private var boardColumn: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.md) {
            LiveMentorChalkboardPane(model: liveVoiceController.chalkboardModel) { summary, _ in
                liveVoiceController.sendSpokenUtterance(
                    "Here is my updated chalkboard state:\n\(summary)",
                    topic: topic,
                    guidanceStyle: store.requestedGuidanceStyle
                )
            }

            if let annotatedCanvas = store.latestAnnotatedScratchpadCanvas {
                TutorCanvasView(canvas: annotatedCanvas, allowEditing: true, kicker: "Your working, with the coach's notes")
            }

            Button("How the coach works") { showWorkings = true }
                .buttonStyle(TextLinkButtonStyle(arrow: false))
        }
    }

    // MARK: Sending

    private func sendCurrentQuery() {
        let trimmed = queryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        queryText = ""
        if liveVoiceController.sessionState.isConnected {
            liveVoiceController.sendSpokenUtterance(trimmed, topic: topic, guidanceStyle: store.requestedGuidanceStyle)
            return
        }
        Task {
            await store.sendMentorMessage(
                trimmed,
                activeQuestion: store.activePracticeQuestion,
                learnerDraft: workingDraftText
            )
            if let lastTurn = store.mentorTurns.last {
                latestCouncilVerdict = await AdversarialCouncil().deliberate(
                    candidateResponse: lastTurn.text,
                    topic: store.selectedUnit.title
                )
            }
        }
    }
}

// MARK: - A line of the conversation

/// Kym's lines sit to the right on sunk paper; the coach's sit to the left on the page, under a
/// brass label.
private struct CoachBubble<Content: View>: View {
    @Environment(\.standardTheme) private var theme
    let speaker: String
    let isLearner: Bool
    var note: String?
    @ViewBuilder let content: Content

    var body: some View {
        HStack {
            if isLearner { Spacer(minLength: StandardSpacing.xl2) }
            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                HStack(spacing: StandardSpacing.xs) {
                    Kicker(speaker, muted: isLearner)
                    if let note {
                        Text("· \(note)")
                            .standardType(.uiCaption)
                            .foregroundStyle(theme.mute(theme.ink))
                    }
                }
                content
            }
            .padding(StandardSpacing.md)
            .frame(maxWidth: 460, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                    .fill(isLearner ? theme.patterned.sunkColor : theme.bg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                    .strokeBorder(isLearner ? Color.clear : theme.hairline(), lineWidth: 1)
            )
            .accessibilityElement(children: .combine)
            if !isLearner { Spacer(minLength: StandardSpacing.xl2) }
        }
    }
}
