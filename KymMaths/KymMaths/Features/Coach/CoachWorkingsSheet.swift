import SwiftUI

// MARK: - How the coach works

/// Everything about the coach that is not the conversation: how it helps, who it is, how it
/// sounds, what it checks first, and how it keeps itself honest. Opened from the Coach room.
struct CoachWorkingsSheet: View {
    @Bindable var store: AppStore
    @Bindable var voice: LiveMentorVoiceController
    @Binding var bracketDrafts: [String: String]
    let safetyEvalReport: SafetyEvalSuiteReport
    let latestCouncilVerdict: AdversarialCouncil.CouncilVerdict?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.standardTheme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StandardSpacing.xl) {
                PaperSheetHeader(
                    kicker: "Coach",
                    title: "How the coach works",
                    subtitle: "Choose how it helps you. It asks before it tells, unless you ask it to just explain."
                ) { dismiss() }

                section("How it helps") { guidance }
                section("Who coaches you") { persona }
                section("Talking out loud") { voiceChoice }
                section("Checking what you already know") { prerequisites }
                section("Keeping it honest") { honesty }

                HStack {
                    Spacer()
                    Button("Done") { dismiss() }
                        .buttonStyle(InkButtonStyle())
                        .keyboardShortcut(.defaultAction)
                }
            }
            .padding(StandardSpacing.xl)
            .frame(maxWidth: 820, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(theme.surface)
        #if os(macOS)
        .frame(minWidth: 600, idealWidth: 760, minHeight: 600, idealHeight: 820)
        #endif
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            Kicker(title)
            content()
        }
    }

    // MARK: How it helps

    private var guidance: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            FlowLayout(spacing: StandardSpacing.xs) {
                ForEach(TutorGuidanceStyle.allCases) { style in
                    PatternedChip(style.title, systemImage: style.icon, isSelected: store.requestedGuidanceStyle == style) {
                        store.requestedGuidanceStyle = style
                    }
                }
            }
            Text("Right now: \(Self.phaseWords(store.currentUnderstandingPhase)).")
                .standardType(.uiBody)
                .foregroundStyle(theme.mute(theme.ink))
        }
    }

    static func phaseWords(_ phase: UnderstandingPhase) -> String {
        switch phase {
        case .exploring: return "trying things out with objects and pictures"
        case .deepening: return "linking the picture to the symbols"
        case .confirming: return "ready to try it on your own"
        case .mastered: return "you have shown you can do it"
        }
    }

    // MARK: Who coaches you

    private var persona: some View {
        let soul = store.activeSoul
        return VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            FlowLayout(spacing: StandardSpacing.xs) {
                ForEach(AgentSoulCatalog.all) { candidate in
                    PatternedChip(candidate.displayName, systemImage: candidate.icon, isSelected: store.selectedSoulId == candidate.personaId) {
                        store.selectedSoulId = candidate.personaId
                    }
                }
            }
            VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                Text(soul.subtitle)
                    .standardType(.uiHeadline)
                    .foregroundStyle(theme.ink)
                Text("How they build it up: \(soul.teachingStyle.scaffoldingApproach)")
                    .standardType(.uiBody)
                    .foregroundStyle(theme.mute(theme.ink))
                    .fixedSize(horizontal: false, vertical: true)
                Text("Tone: \(store.soulParentOverrides["tone"] ?? "warm") · Pace: \(store.soulParentOverrides["pacing"] ?? "steady")")
                    .standardType(.uiBody)
                    .foregroundStyle(theme.mute(theme.ink))
            }
            .paperCard(padding: StandardSpacing.md)
        }
    }

    // MARK: Talking out loud

    private var voiceChoice: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            FlowLayout(spacing: StandardSpacing.xs) {
                ForEach(LiveMentorVoiceProvider.allCases) { provider in
                    PatternedChip(Self.voiceLabel(provider), systemImage: "waveform", isSelected: voice.provider == provider) {
                        voice.provider = provider
                    }
                }
            }
            Text(voiceStatus)
                .standardType(.uiBody)
                .foregroundStyle(theme.mute(theme.ink))
        }
    }

    static func voiceLabel(_ provider: LiveMentorVoiceProvider) -> String {
        switch provider {
        case .geminiLive: return "Cloud voice"
        case .geminiLiveExtendedThinking: return "Cloud voice, slower and more careful"
        case .openAIRealtime: return "Second cloud voice"
        case .offlineSimulated: return "On this iPad"
        }
    }

    private var voiceStatus: String {
        switch voice.sessionState {
        case .idle: return "Ready. Tap the microphone in the room to talk."
        case .connecting: return "Connecting…"
        case .active: return "Talking now."
        case .reconnecting: return "Reconnecting…"
        case .ended: return "The last conversation has ended."
        }
    }

    // MARK: Checking what you already know

    private var prerequisites: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.md) {
            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                PaperFieldLabel("What the coach is doing")
                FlowLayout(spacing: StandardSpacing.xs) {
                    ForEach(AgentPromptRole.allCases) { role in
                        PatternedChip(Self.roleLabel(role), isSelected: store.activeMentorRole == role) {
                            store.activeMentorRole = role
                        }
                    }
                }
            }

            ForEach(store.prerequisiteBrackets) { bracket in
                let binding = Binding<String>(
                    get: { bracketDrafts[bracket.id] ?? bracket.learnerResponse },
                    set: { bracketDrafts[bracket.id] = $0 }
                )
                VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(bracket.strandTitle)
                            .standardType(.uiHeadline)
                            .foregroundStyle(theme.ink)
                        Spacer(minLength: StandardSpacing.sm)
                        StatusTag(Self.depthStatus(bracket.depthLevel), label: Self.depthLabel(bracket.depthLevel))
                    }
                    Text(bracket.diagnosticProbeQuestion)
                        .patternedType(.readingSmall)
                        .foregroundStyle(theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: StandardSpacing.sm) {
                        TextField("Your answer", text: binding)
                            .textFieldStyle(.plain)
                            .paperField()
                        Button("Check") {
                            store.recordPrerequisiteBracketAnswer(
                                bracketId: bracket.id,
                                answer: binding.wrappedValue
                            )
                        }
                        .buttonStyle(OutlineButtonStyle())
                    }
                }
                .paperCard(padding: StandardSpacing.md)
            }

            if let dag = store.activeLessonDAG {
                VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                    PaperFieldLabel("The steps to \(dag.targetConceptTitle)")
                    ForEach(dag.nodes) { node in
                        let isActive = dag.activeNodeId == node.id
                        HStack(alignment: .top, spacing: StandardSpacing.sm) {
                            Image(systemName: node.isCompleted ? "checkmark.circle.fill" : (isActive ? "arrow.right.circle" : "circle"))
                                .foregroundStyle(node.isCompleted ? theme.patterned.provenColor : (isActive ? theme.brass : theme.mute(theme.ink)))
                                .accessibilityLabel(node.isCompleted ? "Held" : (isActive ? "Now" : "Not yet"))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(node.title)
                                    .standardType(.uiHeadline)
                                    .foregroundStyle(theme.ink)
                                Text(node.unconditionalProposition)
                                    .standardType(.uiBody)
                                    .foregroundStyle(theme.mute(theme.ink))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: StandardSpacing.sm)
                            if !node.isCompleted {
                                Button("I've got this") {
                                    store.activeLessonDAG?.markNodeCompleted(node.id)
                                }
                                .buttonStyle(OutlineButtonStyle())
                            }
                        }
                        .padding(.vertical, StandardSpacing.xxs)
                    }
                }
                .paperCard(padding: StandardSpacing.md)
            }
        }
    }

    static func roleLabel(_ role: AgentPromptRole) -> String {
        switch role {
        case .prober: return "Finding what to start from"
        case .teacher: return "Teaching the next step"
        case .practice: return "Practising with hints"
        }
    }

    static func depthLabel(_ level: PrerequisiteDepthLevel) -> String {
        switch level {
        case .unprobed: return "Not checked yet"
        case .needsConcreteGroundFloor: return "Start with objects"
        case .pictorialReady: return "Ready for pictures"
        case .symbolicFluent: return "Fluent with symbols"
        }
    }

    static func depthStatus(_ level: PrerequisiteDepthLevel) -> LearningStatus {
        switch level {
        case .unprobed: return .notStarted
        case .needsConcreteGroundFloor: return .withHelp
        case .pictorialReady: return .working
        case .symbolicFluent: return .proven
        }
    }

    // MARK: Keeping it honest

    private var honesty: some View {
        let budget = AIBudgetLedger.shared.status()
        return VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            honestyLine("checkmark.shield", "Safety checks: \(safetyEvalReport.passedScenarios) of \(safetyEvalReport.totalScenarios) passed.")
            if let verdict = latestCouncilVerdict {
                honestyLine(
                    "person.3",
                    verdict.consensusApproved
                        ? "Four reviewers read the last answer and agreed with it (\(Int((verdict.averageScore * 100).rounded())) out of 100)."
                        : "Four reviewers read the last answer and asked for changes (\(Int((verdict.averageScore * 100).rounded())) out of 100)."
                )
                honestyLine("tray", "Cloud answers left today: \(budget.remainingDaily) of \(budget.dailyLimit).")
            }
            honestyLine("seal", "Talking with the coach helps you understand. Only a question you answer yourself, checked by the book's exact answer checker, counts as proven.")
        }
        .paperCard(padding: StandardSpacing.md)
    }

    private func honestyLine(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(theme.mute(theme.ink))
                .accessibilityHidden(true)
            Text(text)
                .standardType(.uiBody)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
