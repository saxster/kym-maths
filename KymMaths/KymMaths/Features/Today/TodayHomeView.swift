import SwiftUI

// MARK: - Room 1: Today (Daily Cadence, FSRS Retrieval, Intuition->Formula Spotlight & Companion Workbook)

struct TodayHomeView: View {
    @Bindable var store: AppStore
    @Environment(\.themeTokens) private var tokens
    @State private var isShowingCardBack = false
    @State private var revealedBridgeIds: Set<String> = []

    var body: some View {
        JournalPage {
            // 1. Hero Greeting & Readiness Strip
            JournalCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text("DAILY MATHEMATICS STUDIO · MUMBAI")
                                .font(Typography.eyebrow)
                                .tracking(0.6)
                                .foregroundStyle(tokens.accent)
                            Text("Good day, \(store.learnerDisplayName)")
                                .font(Typography.largeTitle)
                                .foregroundStyle(tokens.primary)
                            Text("Oxford Cambridge Lower Secondary Complete Mathematics 8 (Deborah Barton) + Singapore CPA & Horizon Atlas")
                                .font(Typography.subheadline)
                                .foregroundStyle(tokens.secondary)
                        }
                        Spacer()
                        HStack(spacing: Spacing.xs) {
                            Button {
                                store.showCalendarSheet = true
                            } label: {
                                Label("Deadlines", systemImage: "calendar")
                            }
                            .buttonStyle(JournalSecondaryButtonStyle())

                            Button {
                                store.showSettingsSheet = true
                            } label: {
                                Label("Customise", systemImage: "slider.horizontal.3")
                            }
                            .buttonStyle(JournalSecondaryButtonStyle())
                        }
                    }

                    FlowLayout(spacing: Spacing.xs) {
                        JournalBadge(
                            text: "\(store.dueFSRSCards.count) FSRS cards due",
                            symbol: "clock.arrow.circlepath",
                            tone: store.dueFSRSCards.isEmpty ? .positive : .accent
                        )
                        JournalBadge(
                            text: "\(store.overallIndependentProofCount)/\(store.seedPack.schoolQuestions.count) Companion Workbook Proofs",
                            symbol: "checkmark.seal.fill",
                            tone: .positive
                        )
                        JournalBadge(
                            text: "\(store.widgetStampsById.count)/\(store.seedPack.widgets.count) 3D Atlas Stamps",
                            symbol: "cube.transparent.fill",
                            tone: .info
                        )
                        JournalBadge(
                            text: store.selectedCurriculumLens.title,
                            symbol: "line.3.horizontal.decrease.circle",
                            tone: .neutral
                        )
                    }

                    if let deadline = store.nextSchoolDeadline {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "flag.checkered")
                                .foregroundStyle(tokens.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Upcoming Target: \(deadline.title)")
                                    .font(Typography.subheadline.weight(.semibold))
                                    .foregroundStyle(tokens.primary)
                                Text("Chapters \(deadline.unitNumbersCSV) · \(deadline.notes)")
                                    .font(Typography.caption)
                                    .foregroundStyle(tokens.secondary)
                            }
                            Spacer()
                            Text(deadline.dueAt, style: .date)
                                .font(Typography.caption.weight(.semibold))
                                .foregroundStyle(tokens.accent)
                        }
                        .padding(Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: Spacing.radiusMD, style: .continuous)
                                .fill(tokens.accentSubtle)
                        )
                    }
                }
            }

            // 2. FSRS v5 Spaced Retrieval Queue
            JournalSection(
                title: "Spaced Retrieval Queue (FSRS v5)",
                eyebrow: "Step 1 · Lock Formulas & Invariants Into Long-Term Memory"
            ) {
                if let card = store.dueFSRSCards.first {
                    JournalCard {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            HStack {
                                JournalBadge(text: "Topic \(card.topicCode)", symbol: "number", tone: .accent)
                                JournalBadge(text: "Patterned World Ch \(card.chapterNumber)", symbol: "book.pages", tone: .neutral)
                                Spacer()
                                Text("Stability: \(String(format: "%.1f", card.stability))d")
                                    .font(Typography.caption)
                                    .foregroundStyle(tokens.secondary)
                            }

                            Text(card.frontPrompt)
                                .font(Typography.title3)
                                .foregroundStyle(tokens.primary)

                            if isShowingCardBack {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    Text("INVARIANT & FORMULA ANSWER")
                                        .font(Typography.eyebrow)
                                        .foregroundStyle(tokens.positive)
                                    Text(card.backAnswer)
                                        .font(Typography.body)
                                        .foregroundStyle(tokens.primary)
                                        .padding(Spacing.md)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(
                                            RoundedRectangle(cornerRadius: Spacing.radiusMD, style: .continuous)
                                                .fill(tokens.surfaceElevated)
                                        )

                                    HStack(spacing: Spacing.sm) {
                                        ForEach(FSRSRating.allCases, id: \.rawValue) { rating in
                                            Button(rating.title) {
                                                isShowingCardBack = false
                                                store.reviewFSRSCard(card, rating: rating)
                                            }
                                            .buttonStyle(rating == .good || rating == .easy ? AnyButtonStyle(JournalPrimaryButtonStyle()) : AnyButtonStyle(JournalSecondaryButtonStyle()))
                                        }
                                    }
                                }
                            } else {
                                Button {
                                    isShowingCardBack = true
                                } label: {
                                    Label("Reveal Formula & Visual Invariant", systemImage: "eye.fill")
                                }
                                .buttonStyle(JournalPrimaryButtonStyle())
                            }
                        }
                    }
                } else {
                    JournalCard {
                        HStack(spacing: Spacing.md) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(tokens.positive)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("All FSRS Retrieval Cards Complete for Today")
                                    .font(Typography.headline)
                                    .foregroundStyle(tokens.primary)
                                Text("Every due formula and visual invariant has been reviewed. Proceed to your Intuition → Formula Spotlight or Companion Workbook below.")
                                    .font(Typography.caption)
                                    .foregroundStyle(tokens.secondary)
                            }
                        }
                    }
                }
            }

            // 3. Visual Intuition -> "Aha!" -> Symbolic Formula Spotlight
            let ch = store.selectedChapter
            let bridge = ch.intuitionToFormula
            JournalSection(
                title: "Visual Intuition → \"Aha!\" → Symbolic Formula",
                eyebrow: "Step 2 · Why the Formula Must Be True (Ch \(ch.number): \(ch.title))"
            ) {
                JournalCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            JournalBadge(text: "Ch \(ch.number) · \(ch.volumeTitle)", symbol: "sparkles", tone: .accent)
                            JournalBadge(text: "Atlas: \(bridge.atlasFigureRef)", symbol: "cube.transparent", tone: .info)
                            Spacer()
                            Button {
                                store.activeRoom = .patternedWorld
                            } label: {
                                Label("Open Interactive 3D Chapter", systemImage: "arrow.up.right.square")
                            }
                            .buttonStyle(JournalSecondaryButtonStyle())
                        }

                        // 3-Stage Pedagogical Pipeline
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            intuitionStepBox(
                                stepLabel: "1. CONCRETE ACTION (WHAT YOU MANIPULATE)",
                                text: bridge.concreteAction,
                                accentColor: tokens.accent
                            )
                            intuitionStepBox(
                                stepLabel: "2. THE \"AHA!\" INVARIANT (WHAT NEVER CHANGES)",
                                text: bridge.ahaInvariant,
                                accentColor: tokens.positive
                            )
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("3. SYMBOLIC FORMULA & COLOUR-LOCKED ANATOMY")
                                    .font(Typography.eyebrow)
                                    .foregroundStyle(tokens.warning)
                                Text(bridge.formulaDisplay)
                                    .font(Typography.numericFormula)
                                    .foregroundStyle(tokens.primary)
                                    .padding(Spacing.sm)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: Spacing.radiusSM, style: .continuous)
                                            .fill(tokens.surfaceElevated)
                                    )

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: Spacing.xs)], spacing: Spacing.xs) {
                                    ForEach(bridge.termMappings) { mapping in
                                        HStack(alignment: .top, spacing: Spacing.xs) {
                                            Circle()
                                                .fill(colorForRole(mapping.colorRole))
                                                .frame(width: 10, height: 10)
                                                .padding(.top, 5)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("\(mapping.symbol)  ←  \(mapping.visualPart)")
                                                    .font(Typography.caption.weight(.bold))
                                                    .foregroundStyle(tokens.primary)
                                                Text(mapping.meaning)
                                                    .font(Typography.caption)
                                                    .foregroundStyle(tokens.secondary)
                                            }
                                        }
                                        .padding(Spacing.xs)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(
                                            RoundedRectangle(cornerRadius: Spacing.radiusSM, style: .continuous)
                                                .fill(tokens.surfaceElevated)
                                        )
                                    }
                                }
                            }
                        }

                        // Chapter switcher strip
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.xs) {
                                ForEach(store.visiblePatternedWorldChapters) { chapter in
                                    JournalChip(
                                        title: "Ch \(chapter.number): \(chapter.title)",
                                        systemImage: store.selectedChapterNumber == chapter.number ? "checkmark.circle.fill" : "function",
                                        isSelected: store.selectedChapterNumber == chapter.number
                                    ) {
                                        store.selectedChapterNumber = chapter.number
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 4. 3-Tier Companion Workbook Queue (Solving the Missing School Workbook)
            let unit = store.selectedUnit
            let unitQuestions = store.questions(forUnit: unit.unitNumber, tierFilter: store.defaultWorkbookTier)
            JournalSection(
                title: "3-Tier Companion Workbook · OUP Ch \(unit.unitNumber): \(unit.title)",
                eyebrow: "Step 3 · Worked Example → Faded Scaffold → Independent Proof"
            ) {
                JournalCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Deborah Barton pp. \(unit.learnersBookStartPage)–\(unit.learnersBookEndPage) · \(unit.statusBadgeLabel)")
                                    .font(Typography.subheadline.weight(.semibold))
                                    .foregroundStyle(tokens.primary)
                                Text("Replaces the missing school workbook with Focus, Singapore CPA Bar-Model Practice, and Olympiad Challenge questions.")
                                    .font(Typography.caption)
                                    .foregroundStyle(tokens.secondary)
                            }
                            Spacer()
                            Button {
                                store.activeRoom = .schoolMaths
                            } label: {
                                Label("All 16 Chapters", systemImage: "book.closed")
                            }
                            .buttonStyle(JournalSecondaryButtonStyle())
                        }

                        ForEach(unitQuestions.prefix(4)) { question in
                            let proof = store.proofsByQuestionId[question.id]
                            HStack(alignment: .top, spacing: Spacing.md) {
                                VStack(alignment: .leading, spacing: Spacing.xxs) {
                                    HStack(spacing: Spacing.xs) {
                                        JournalBadge(text: question.tier, symbol: "layers.fill", tone: question.tier == "Challenge" ? .warning : .accent)
                                        JournalBadge(text: "Topic \(question.topicCode)", symbol: "bookmark", tone: .neutral)
                                        JournalBadge(text: (proof?.level ?? .unseen).displayTitle, symbol: "checkmark.seal", tone: (proof?.level.isIndependentProof == true) ? .positive : .neutral)
                                    }
                                    Text(question.prompt)
                                        .font(Typography.subheadline)
                                        .foregroundStyle(tokens.primary)
                                        .lineLimit(2)
                                }
                                Spacer()
                                Button("Prove") {
                                    store.activePracticeQuestion = question
                                    store.activeRoom = .schoolMaths
                                }
                                .buttonStyle(JournalPrimaryButtonStyle())
                            }
                            .padding(Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: Spacing.radiusMD, style: .continuous)
                                    .fill(tokens.surfaceElevated)
                            )
                        }
                    }
                }
            }

            // 5. Cross-Disciplinary STEM Bridges (Biology, Physics, Chemistry, Economics)
            JournalSection(
                title: "Cross-Disciplinary STEM Bridges",
                eyebrow: "How Mathematics Powers Biology, Physics, Chemistry & Mumbai Finance"
            ) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: Spacing.md)], spacing: Spacing.md) {
                    ForEach(store.seedPack.crossDisciplinaryBridges) { bridge in
                        JournalCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                HStack {
                                    JournalBadge(text: bridge.discipline.capitalized, symbol: bridge.badgeSymbol, tone: .info)
                                    Text(bridge.sourceBook)
                                        .font(Typography.caption)
                                        .foregroundStyle(tokens.secondary)
                                }
                                Text(bridge.title)
                                    .font(Typography.headline)
                                    .foregroundStyle(tokens.primary)
                                Text(bridge.summary)
                                    .font(Typography.caption)
                                    .foregroundStyle(tokens.secondary)
                                Text(bridge.keyEquation)
                                    .font(Typography.numericFormula)
                                    .foregroundStyle(tokens.accent)
                                    .padding(Spacing.xs)
                                    .background(
                                        RoundedRectangle(cornerRadius: Spacing.radiusSM, style: .continuous)
                                            .fill(tokens.accentSubtle)
                                    )

                                Divider()

                                Text(bridge.microCheckQuestion)
                                    .font(Typography.caption.weight(.semibold))
                                    .foregroundStyle(tokens.primary)

                                if revealedBridgeIds.contains(bridge.id) {
                                    Text(bridge.microCheckAnswer)
                                        .font(Typography.caption)
                                        .foregroundStyle(tokens.positive)
                                } else {
                                    Button("Check Bridge Answer") {
                                        revealedBridgeIds.insert(bridge.id)
                                    }
                                    .buttonStyle(JournalSecondaryButtonStyle())
                                }
                            }
                        }
                    }
                }
            }

            // 6. iPadOS 27 & macOS System Surface Widgets (group.com.kymaia.science)
            JournalSection(
                title: "Live System Widgets (Home Screen & Lock Screen)",
                eyebrow: "Synced via Shared App Group (group.com.kymaia.science)"
            ) {
                KymMathsWidgetPreviewGallery(store: store)
            }
        }
    }

    @ViewBuilder
    private func intuitionStepBox(stepLabel: String, text: String, accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(stepLabel)
                .font(Typography.eyebrow)
                .foregroundStyle(accentColor)
            Text(text)
                .font(Typography.subheadline)
                .foregroundStyle(tokens.primary)
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Spacing.radiusSM, style: .continuous)
                .fill(tokens.surfaceElevated)
        )
    }

    private func colorForRole(_ role: String) -> Color {
        switch role {
        case "red": return Color(red: 0.78, green: 0.22, blue: 0.18)
        case "blue": return Color(red: 0.14, green: 0.36, blue: 0.72)
        case "amber": return Color(red: 0.76, green: 0.48, blue: 0.08)
        case "green": return Color(red: 0.15, green: 0.52, blue: 0.32)
        default: return tokens.accent
        }
    }
}

// Helper type-erased ButtonStyle for conditional primary/secondary buttons
struct AnyButtonStyle: ButtonStyle {
    private let _makeBody: (Configuration) -> AnyView

    init<S: ButtonStyle>(_ style: S) {
        _makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        _makeBody(configuration)
    }
}
