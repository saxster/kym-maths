import SwiftUI

// MARK: - Room 2: School Maths 8 (Deborah Barton OUP Ch 1–16 + 3-Tier Companion Workbook + Infinite Generator)

struct SchoolMathsHomeView: View {
    @Bindable var store: AppStore

    @State private var tierFilter: CompanionWorkbookTierFilter = .allTiers
    @State private var selectedTemplate: QuantitativeTemplateKind = .primeFactorHCFLCM
    @State private var problemSeed: Int = 1
    @State private var numericInput: String = ""
    @State private var quantEval: QuantitativeAttemptEvaluation?
    @State private var scannerTopic: SchoolMathsTopic?

    var body: some View {
        let currentProblem = QuantitativeMathsEngine.generate(template: selectedTemplate, seed: problemSeed)

        JournalPage {
            EditorialHeader(
                eyebrow: "School Textbook Spine & 3-Tier Companion Workbook",
                title: store.seedPack.schoolTextbook.title,
                subtitle: "By \(store.seedPack.schoolTextbook.authors) · \(store.seedPack.schoolTextbook.publisher) · pp. 5–\(store.seedPack.schoolTextbook.learnersBookTotalPages)"
            )

            // 1. Lens Switcher
            JournalCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack(alignment: .top) {
                        Spacer()
                        Button {
                            store.showSettingsSheet = true
                        } label: {
                            Label("Customise Syllabus", systemImage: "slider.horizontal.3")
                        }
                        .buttonStyle(JournalSecondaryButtonStyle())
                    }

                    AdaptiveOptionPicker(
                        options: MathsCurriculumLens.allCases,
                        selection: $store.selectedCurriculumLens,
                        label: { $0.title }
                    )

                    // Chapter Selector (Ch 1–16)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.xs) {
                            ForEach(store.visibleSchoolUnits) { unit in
                                let badgeIcon: String = {
                                    switch unit.schoolStatus {
                                    case "ticked": return "checkmark.circle.fill"
                                    case "circled": return "circle.dashed.inset.filled"
                                    default: return "book.closed"
                                    }
                                }()
                                MathsFilterChip(
                                    title: "Ch \(unit.unitNumber): \(unit.title)",
                                    systemImage: badgeIcon,
                                    isSelected: store.selectedUnitNumber == unit.unitNumber
                                ) {
                                    store.selectedUnitNumber = unit.unitNumber
                                    if let firstTopic = unit.topics.first {
                                        store.selectedTopicCode = firstTopic.code
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 2. Selected OUP Chapter Details & Topics
            let unit = store.selectedUnit
            let readiness = store.readiness(for: unit)
            JournalSection(
                title: "OUP Chapter \(unit.unitNumber) · \(unit.title)",
                eyebrow: "Student Book pp. \(unit.learnersBookStartPage)–\(unit.learnersBookEndPage) · \(unit.statusBadgeLabel)"
            ) {
                JournalCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            JournalBadge(text: unit.statusBadgeLabel, symbol: "bookmark.fill", tone: unit.schoolStatus == "ticked" ? .positive : .accent)
                            JournalBadge(text: unit.disciplineBadgeLabel, symbol: "function", tone: .info)
                            JournalBadge(text: readiness.readinessBadgeText, symbol: "checkmark.seal.fill", tone: .positive)
                            Spacer()
                            Text("BKT Mastery: \(Int(readiness.averageBKTMastery * 100))%")
                                .font(Typography.caption.weight(.semibold))
                                .foregroundStyle(Color.kymaiaMutedInk)
                        }

                        Text(unit.scienceInContext)
                            .font(Typography.callout)
                            .foregroundStyle(Color.kymaiaMutedInk)

                        // Topics inside this chapter
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 270), spacing: Spacing.sm)], spacing: Spacing.sm) {
                            ForEach(unit.topics) { topic in
                                let skill = store.bktSkillsById[topic.code]
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    HStack {
                                        Text("\(topic.code) · \(topic.title)")
                                            .font(Typography.subheadline.weight(.bold))
                                            .foregroundStyle(Color.kymaiaInk)
                                        Spacer()
                                        Text("p. \(topic.learnersBookPage)")
                                            .font(Typography.mono)
                                            .foregroundStyle(Color.kymaiaPrimary)
                                    }
                                    Text(topic.summary)
                                        .font(Typography.caption)
                                        .foregroundStyle(Color.kymaiaMutedInk)

                                    if let watchout = topic.cambridgeWatchouts.first {
                                        HStack(alignment: .top, spacing: 4) {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .font(.kymaiaCaption2)
                                                .foregroundStyle(Color.kymaiaWarning)
                                            Text(watchout)
                                                .font(Typography.caption)
                                                .foregroundStyle(Color.kymaiaInk)
                                        }
                                    }

                                    HStack {
                                        if let firstCh = topic.livingWorldChapters.first {
                                            Button {
                                                store.selectedChapterNumber = firstCh
                                                store.activeRoom = .patternedWorld
                                            } label: {
                                                Label("Patterned World Ch \(firstCh)", systemImage: "book.pages")
                                                    .font(Typography.caption.weight(.semibold))
                                            }
                                            .buttonStyle(.plain)
                                            .foregroundStyle(Color.kymaiaPrimary)
                                        }
                                        Spacer()
                                        if let s = skill {
                                            Text("\(Int(s.pLearned * 100))% mastery")
                                                .font(Typography.caption)
                                                .foregroundStyle(Color.kymaiaSuccess)
                                        }
                                        Button {
                                            scannerTopic = topic
                                        } label: {
                                            Image(systemName: "doc.viewfinder")
                                                .foregroundStyle(Color.kymaiaMutedInk)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(Spacing.sm)
                                .quietPanelBackground()
                                .overlay(
                                    RoundedRectangle(cornerRadius: Spacing.radiusMD, style: .continuous)
                                        .strokeBorder(Color.kymaiaHairline, lineWidth: 1)
                                )
                            }
                        }
                    }
                }
            }

            // 3. 3-Tier Singapore & Checkpoint Companion Workbook (Solving the Missing School Workbook)
            let filteredQuestions = store.questions(forUnit: unit.unitNumber, tierFilter: tierFilter)
            JournalSection(
                title: "3-Tier Singapore & Checkpoint Companion Workbook (Ch \(unit.unitNumber))",
                eyebrow: "Built to Replace the Missing School Workbook · Focus → Singapore CPA → Olympiad Challenge"
            ) {
                JournalCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        AdaptiveOptionPicker(
                            options: CompanionWorkbookTierFilter.allCases,
                            selection: $tierFilter,
                            label: { $0.title }
                        )

                        ForEach(filteredQuestions) { question in
                            let proof = store.proofsByQuestionId[question.id]
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                HStack {
                                    JournalBadge(text: "Topic \(question.topicCode)", symbol: "number", tone: .accent)
                                    JournalBadge(text: "Tier: \(question.tier)", symbol: "layers.fill", tone: question.tier == "Challenge" ? .warning : .info)
                                    JournalBadge(text: "\(question.marks) marks", symbol: "star.fill", tone: .neutral)
                                    Spacer()
                                    JournalBadge(
                                        text: (proof?.level ?? .unseen).displayTitle,
                                        symbol: (proof?.level.isIndependentProof == true) ? "checkmark.seal.fill" : "circle.dotted",
                                        tone: (proof?.level.isIndependentProof == true) ? .positive : .neutral
                                    )
                                }

                                Text(question.bookSection)
                                    .font(Typography.caption)
                                    .foregroundStyle(Color.kymaiaMutedInk)

                                Text(question.prompt)
                                    .font(Typography.body)
                                    .foregroundStyle(Color.kymaiaInk)

                                HStack {
                                    Button {
                                        store.activePracticeQuestion = question
                                    } label: {
                                        Label("Open Worked Example & Proof Studio", systemImage: "pencil.and.outline")
                                    }
                                    .buttonStyle(JournalSecondaryButtonStyle())

                                    Spacer()
                                }
                            }
                            .padding(Spacing.md)
                            .quietPanelBackground()
                        }
                    }
                }
            }

            // 4. Infinite Wolfram-Verified Quantitative Generator (With Intuition -> "Aha!" -> Formula)
            JournalSection(
                title: "Infinite Wolfram-Verified Problem Generator (21 Templates)",
                eyebrow: "Every Problem Connects Visual Intuition → \"Aha!\" Invariant → Symbolic Formula"
            ) {
                JournalCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.xs) {
                                ForEach(QuantitativeTemplateKind.allCases) { kind in
                                    MathsFilterChip(
                                        title: kind.title,
                                        systemImage: "function",
                                        isSelected: selectedTemplate == kind
                                    ) {
                                        selectedTemplate = kind
                                        quantEval = nil
                                        numericInput = ""
                                    }
                                }
                            }
                        }

                        HStack {
                            JournalBadge(text: currentProblem.title, symbol: "sparkles", tone: .accent)
                            JournalBadge(text: "Seed #\(problemSeed)", symbol: "die.face.5", tone: .neutral)
                            Spacer()
                            Button {
                                problemSeed += 1
                                quantEval = nil
                                numericInput = ""
                            } label: {
                                Label("New Parameterized Variant", systemImage: "arrow.clockwise")
                            }
                            .buttonStyle(JournalSecondaryButtonStyle())
                        }

                        Text(currentProblem.prompt)
                            .font(Typography.title3)
                            .foregroundStyle(Color.kymaiaInk)

                        if store.showIntuitionBeforeFormula {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("VISUAL INTUITION → \"AHA!\" INVARIANT → SYMBOLIC FORMULA")
                                    .font(Typography.eyebrow)
                                    .foregroundStyle(Color.kymaiaPrimary)
                                Text("• Visual Action: \(currentProblem.visualIntuitionStep)")
                                    .font(Typography.caption)
                                    .foregroundStyle(Color.kymaiaInk)
                                Text("• \"Aha!\" Invariant: \(currentProblem.ahaInvariantStep)")
                                    .font(Typography.caption)
                                    .foregroundStyle(Color.kymaiaSuccess)
                                Text("• Symbolic Formula: \(currentProblem.formulaStep)")
                                    .font(Typography.mono)
                                    .foregroundStyle(Color.kymaiaPrimary)
                            }
                            .padding(Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .quietPanelBackground()
                        }

                        HStack(spacing: Spacing.sm) {
                            NumericKeypadField(
                                label: "Numeric Answer",
                                unitLabel: currentProblem.unitLabel,
                                text: $numericInput
                            ) {
                                quantEval = QuantitativeMathsEngine.evaluate(problem: currentProblem, numericInput: numericInput)
                            }
                            Button("Verify Answer") {
                                quantEval = QuantitativeMathsEngine.evaluate(problem: currentProblem, numericInput: numericInput)
                            }
                            .buttonStyle(BrassButtonStyle())
                        }

                        if let eval = quantEval {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                HStack {
                                    Image(systemName: eval.isCorrect ? "checkmark.seal.fill" : "xmark.octagon.fill")
                                        .foregroundStyle(eval.isCorrect ? Color.kymaiaSuccess : Color.kymaiaWarning)
                                    Text(eval.feedback)
                                        .font(Typography.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.kymaiaInk)
                                }
                                ForEach(currentProblem.stepByStepDerivation, id: \.self) { step in
                                    Text(step)
                                        .font(Typography.caption)
                                        .foregroundStyle(Color.kymaiaMutedInk)
                                }
                            }
                            .padding(Spacing.sm)
                            .quietPanelBackground()
                        }
                    }
                }
            }
        }
        .onAppear {
            tierFilter = store.defaultWorkbookTier
        }
        .sheet(item: $store.activePracticeQuestion) { question in
            QuestionProofPracticeView(question: question, store: store)
        }
        .sheet(item: $scannerTopic) { topic in
            TextbookPageScannerSheet(topic: topic, store: store)
        }
    }
}
