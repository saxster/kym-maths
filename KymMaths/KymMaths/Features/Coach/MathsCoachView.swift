import SwiftUI

// MARK: - Room 7: Constitutional AI Mathematics Mentor & Offline FTS5 Socratic Coach (Ported from ../kym_tutor)

struct MathsCoachView: View {
    @Bindable var store: AppStore

    @State private var queryText: String = ""
    @State private var workingDraftText: String = ""
    @State private var liveVoiceController = LiveMentorVoiceController()
    @State private var safetyEvalReport: SafetyEvalSuiteReport = ChildSafetyEvalHarness.runFullSuite()
    @State private var latestCouncilVerdict: AdversarialCouncil.CouncilVerdict?

    private let starterPrompts = [
        "Why does HCF × LCM = a × b?",
        "How do I convert 0.27 recurring to a fraction?",
        "Explain Bayes' Theorem with the 1,000-person square",
        "How does a secant line become the derivative dy/dx?",
        "What does det(A) = ad − bc mean geometrically?",
        "Just explain how to expand 5(2x + 3) − 3(x − 4)"
    ]

    var body: some View {
        let activeSoul = store.activeSoul

        JournalPage {
            // 1. Constitutional Guardrail & 4-Phase Understanding Banner
            JournalCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack(spacing: Spacing.xs) {
                        JournalBadge(
                            text: "Constitution \(TutorConstitution.version)",
                            symbol: "checkmark.shield.fill",
                            tone: .positive
                        )
                        JournalBadge(
                            text: "Phase: \(store.currentUnderstandingPhase.title)",
                            symbol: "chart.line.uptrend.xyaxis",
                            tone: .accent
                        )
                        JournalBadge(
                            text: store.aiFeaturePolicy.displayName,
                            symbol: "cpu",
                            tone: .info
                        )
                        Spacer()
                        Text("Policy SHA-256: \(String(TutorConstitution.policyHash.prefix(10)))…")
                            .font(Typography.caption)
                            .foregroundStyle(Color.kymaiaMutedInk)
                    }

                    Text("Constitutional Mathematics Mentor · \(activeSoul.displayName)")
                        .font(Typography.title2)
                        .foregroundStyle(Color.kymaiaInk)

                    Text(activeSoul.subtitle + " · " + store.currentUnderstandingPhase.badgeSubtitle)
                        .font(Typography.callout)
                        .foregroundStyle(Color.kymaiaMutedInk)

                    // Soul Persona Selector
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("CHOOSE YOUR MENTOR SOUL PERSONA")
                            .font(Typography.eyebrow)
                            .foregroundStyle(Color.kymaiaPrimary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.xs) {
                                ForEach(AgentSoulCatalog.all) { soul in
                                    JournalChip(
                                        title: soul.displayName,
                                        systemImage: soul.icon,
                                        isSelected: store.selectedSoulId == soul.personaId
                                    ) {
                                        store.selectedSoulId = soul.personaId
                                    }
                                }
                            }
                        }
                    }

                    // Guidance Style Selector (TutorGuidanceStyle)
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("COACHING & GUIDANCE STYLE (SAY \"JUST EXPLAIN\" ANYTIME TO OPT OUT)")
                            .font(Typography.eyebrow)
                            .foregroundStyle(Color.kymaiaPrimary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.xs) {
                                ForEach(TutorGuidanceStyle.allCases) { style in
                                    JournalChip(
                                        title: style.title,
                                        systemImage: style.icon,
                                        isSelected: store.requestedGuidanceStyle == style
                                    ) {
                                        store.requestedGuidanceStyle = style
                                    }
                                }
                            }
                        }
                    }

                    // Starter Prompts
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.xs) {
                            ForEach(starterPrompts, id: \.self) { prompt in
                                JournalChip(
                                    title: prompt,
                                    systemImage: "sparkles",
                                    isSelected: false
                                ) {
                                    Task {
                                        await store.sendMentorMessage(
                                            prompt,
                                            activeQuestion: store.activePracticeQuestion,
                                            learnerDraft: workingDraftText
                                        )
                                    }
                                }
                            }
                        }
                    }

                    // Input & Share Scratchpad Working
                    HStack(spacing: Spacing.sm) {
                        TextField(
                            "Ask \(activeSoul.displayName) (or say 'just explain' for a direct breakdown)...",
                            text: $queryText
                        )
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            sendCurrentQuery()
                        }

                        Button("Ask Mentor") {
                            sendCurrentQuery()
                        }
                        .buttonStyle(JournalPrimaryButtonStyle())

                        if let activeQ = store.activePracticeQuestion,
                           let savedPad = store.loadScratchpad(questionId: activeQ.id) {
                            Button("Share Saved Working") {
                                Task {
                                    await store.shareScratchpadWithCoach(
                                        pngData: savedPad.previewPNGData,
                                        activeQuestion: activeQ
                                    )
                                }
                            }
                            .buttonStyle(JournalSecondaryButtonStyle())
                        }
                    }

                    Text("Epistemic Honesty Rule: Coach conversations help you build intuition, but only the deterministic Question Proof & Exact Polynomial Checker (\(STEMVerification.checker)) certifies mastery.")
                        .font(Typography.caption)
                        .foregroundStyle(Color.kymaiaMutedInk)
                }
            }

            // 1B. Live Bidirectional Voice & Interactive Shared Chalkboard (Ported from ../kym_tutor)
            JournalSection(
                title: "Live Socratic Voice & Shared Chalkboard",
                eyebrow: "Gemini 3.8 Live / OpenAI Realtime · Turn-Gated Safety · 1000×640 TutorCanvas"
            ) {
                LiveMentorCallSurface(
                    controller: liveVoiceController,
                    topic: store.selectedUnit.title,
                    soulID: store.selectedSoulId,
                    overrides: store.soulParentOverrides,
                    guidanceStyle: store.requestedGuidanceStyle,
                    mathContextSummary: store.activePracticeQuestion?.prompt
                ) { takeaway in
                    store.saveVoiceTakeawayFlashcard(takeaway)
                }
            }

            // 2. Active Soul Document & 4-Agent Adversarial Council Status
            JournalSection(
                title: "Active Mentor Soul, Adversarial Council & KORA Safety Gate",
                eyebrow: "Safety & Learner Agency Always Outrank Persona Preferences"
            ) {
                JournalCard {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            JournalBadge(text: activeSoul.displayName, symbol: activeSoul.icon, tone: .accent)
                            JournalBadge(text: "Tone: \(store.soulParentOverrides["tone"] ?? "warm")", symbol: "slider.horizontal.3", tone: .info)
                            JournalBadge(text: "Pacing: \(store.soulParentOverrides["pacing"] ?? "steady")", symbol: "metronome", tone: .neutral)
                            JournalBadge(
                                text: "KORA Safety Eval: \(safetyEvalReport.passedScenarios)/\(safetyEvalReport.totalScenarios) Passed",
                                symbol: "checkmark.shield.fill",
                                tone: .positive
                            )
                        }
                        Text("Primary Method: \(activeSoul.teachingStyle.primaryMethod)")
                            .font(Typography.subheadline.weight(.semibold))
                            .foregroundStyle(Color.kymaiaInk)
                        Text("Scaffolding: \(activeSoul.teachingStyle.scaffoldingApproach)")
                            .font(Typography.caption)
                            .foregroundStyle(Color.kymaiaMutedInk)

                        if let verdict = latestCouncilVerdict {
                            Divider()
                            HStack(spacing: Spacing.xs) {
                                JournalBadge(
                                    text: verdict.consensusApproved ? "4-Expert Council Approved" : "Council Revised",
                                    symbol: "person.3.sequence.fill",
                                    tone: verdict.consensusApproved ? .positive : .warning
                                )
                                JournalBadge(
                                    text: String(format: "Score %.0f%%", verdict.averageScore * 100),
                                    symbol: "gauge.with.dots.needle.67percent",
                                    tone: .info
                                )
                                let budget = AIBudgetLedger.shared.status()
                                JournalBadge(
                                    text: "Daily Quota: \(budget.remainingDaily)/\(budget.dailyLimit)",
                                    symbol: "chart.bar.fill",
                                    tone: .neutral
                                )
                            }
                        }
                    }
                }
            }

            // 3. Dialogue History
            JournalSection(
                title: "Mentor Dialogue & Grounded Citations",
                eyebrow: "Protected by DevelopmentalResponseValidator & SafetyEscalationService"
            ) {
                if store.mentorTurns.isEmpty {
                    JournalCard {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack {
                                JournalBadge(text: activeSoul.displayName, symbol: activeSoul.icon, tone: .accent)
                                JournalBadge(text: "OUP Ch 1–16 + The Patterned World Ch 0–20", symbol: "book.closed", tone: .info)
                            }
                            Text("Hello \(store.learnerDisplayName)! I am \(activeSoul.displayName). Choose how you'd like us to work above—whether through Socratic questions, a light hint, collaborative practice, or a direct explanation—and ask me about any chapter in Deborah Barton's Oxford Complete Mathematics 8 or The Patterned World.")
                                .font(Typography.body)
                                .foregroundStyle(Color.kymaiaInk)
                        }
                    }
                } else {
                    ForEach(store.mentorTurns) { turn in
                        JournalCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                HStack {
                                    JournalBadge(
                                        text: turn.role == "learner"
                                            ? store.learnerDisplayName
                                            : (turn.role == "safety" ? "Child Safety Gate" : activeSoul.displayName),
                                        symbol: turn.role == "learner"
                                            ? "person.fill"
                                            : (turn.role == "safety" ? "heart.text.square.fill" : activeSoul.icon),
                                        tone: turn.role == "learner"
                                            ? .neutral
                                            : (turn.role == "safety" ? .warning : .accent)
                                    )
                                    JournalBadge(
                                        text: turn.guidanceStyle.title,
                                        symbol: turn.guidanceStyle.icon,
                                        tone: .info
                                    )
                                    JournalBadge(
                                        text: turn.understandingPhase.title,
                                        symbol: "sparkle",
                                        tone: .neutral
                                    )
                                }

                                Text(turn.text)
                                    .font(Typography.body)
                                    .foregroundStyle(Color.kymaiaInk)
                            }
                        }
                    }
                }
            }
        }
    }

    private func sendCurrentQuery() {
        let trimmed = queryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        queryText = ""
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
