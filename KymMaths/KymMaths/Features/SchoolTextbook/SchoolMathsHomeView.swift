import SwiftUI

// MARK: - School book: the class textbook chapter by chapter, its workbook, and endless practice

struct SchoolMathsHomeView: View {
    @Bindable var store: AppStore
    @Environment(\.standardTheme) private var theme

    @State private var tierFilter: CompanionWorkbookTierFilter = .allTiers
    @State private var selectedQuestionId: String?
    @State private var selectedTemplate: QuantitativeTemplateKind = .primeFactorHCFLCM
    @State private var problemSeed: Int = 1
    @State private var numericInput: String = ""
    @State private var quantEval: QuantitativeAttemptEvaluation?
    @State private var scannerTopic: SchoolMathsTopic?
    @State private var pageWidth: CGFloat = 0

    /// Wide enough for the chapter list beside the chapter card.
    private var isWide: Bool { pageWidth >= 860 }

    var body: some View {
        let unit = store.selectedUnit

        ScrollView {
            VStack(alignment: .leading, spacing: StandardSpacing.xl) {
                EditorialHeader(
                    eyebrow: "Cambridge Lower Secondary Maths 8 · \(store.seedPack.schoolTextbook.authors)",
                    title: "Your school book, chapter by chapter",
                    subtitle: "The book you carry to class, with a workbook built in: practise each topic three ways, from steady to stretching."
                )

                if isWide {
                    HStack(alignment: .top, spacing: StandardSpacing.lg) {
                        chapterList(columns: 1)
                            .frame(width: 296)
                        VStack(alignment: .leading, spacing: StandardSpacing.xl) {
                            chapterCard(unit)
                            workbook(unit)
                        }
                    }
                } else {
                    chapterList(columns: 2)
                    chapterCard(unit)
                    workbook(unit)
                }

                practiceGenerator
                debate(unit)
            }
            .padding(.horizontal, StandardSpacing.xl)
            .padding(.vertical, StandardSpacing.xl)
            .frame(maxWidth: 1120, alignment: .leading)
            .readWidth($pageWidth)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(theme.bg)
        .onAppear {
            tierFilter = store.defaultWorkbookTier
        }
        .onChange(of: store.deepLinkTail, initial: true) { _, tail in
            // `school/<unit>/scanner` opens the page scanner for the chosen topic.
            guard tail.first == "scanner" else { return }
            store.deepLinkTail = []
            scannerTopic = selectedTopic(in: store.selectedUnit)
        }
        .sheet(item: $scannerTopic) { topic in
            TextbookPageScannerSheet(topic: topic, store: store)
        }
    }

    // MARK: Chapters

    private func chapterList(columns: Int) -> some View {
        let units = store.visibleSchoolUnits
        return VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            HStack {
                Menu {
                    Picker("Which chapters", selection: $store.selectedCurriculumLens) {
                        ForEach(MathsCurriculumLens.allCases) { lens in
                            Text(lensTitle(lens)).tag(lens)
                        }
                    }
                } label: {
                    HStack(spacing: StandardSpacing.xxs) {
                        Kicker("\(units.count) chapters")
                        Image(systemName: "chevron.down")
                            .standardType(.uiMicro).fontWeight(.semibold)
                            .foregroundStyle(theme.brass)
                    }
                    .frame(minHeight: StandardAccessibility.touchTarget - 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Which chapters to show: \(lensTitle(store.selectedCurriculumLens))")
                Spacer()
            }
            .padding(.horizontal, StandardSpacing.sm)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: StandardSpacing.sm), count: columns),
                alignment: .leading,
                spacing: 2
            ) {
                ForEach(units) { item in
                    chapterRow(item)
                }
            }

            Button("Book settings") {
                store.showSettingsSheet = true
            }
            .buttonStyle(TextLinkButtonStyle())
            .padding(.horizontal, StandardSpacing.sm)
        }
        .paperCard(padding: StandardSpacing.sm)
    }

    private func chapterRow(_ item: SchoolMathsUnit) -> some View {
        let isSelected = store.selectedUnitNumber == item.unitNumber
        return Button {
            store.selectedUnitNumber = item.unitNumber
            if let firstTopic = item.topics.first {
                store.selectedTopicCode = firstTopic.code
            }
            selectedQuestionId = nil
        } label: {
            HStack(spacing: StandardSpacing.sm) {
                Text("\(item.unitNumber)")
                    .monospacedDigit()
                    .foregroundStyle(isSelected ? theme.brass : theme.mute(theme.ink))
                    .frame(width: 22, alignment: .leading)
                Text(item.title)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(theme.ink)
                    .lineLimit(1)
                Spacer(minLength: StandardSpacing.xs)
                schoolMark(item)
            }
            .standardType(.uiHeadline)
            .padding(.horizontal, StandardSpacing.sm)
            .frame(maxWidth: .infinity, minHeight: StandardAccessibility.touchTarget - 8, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                    .fill(isSelected ? theme.blank() : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Chapter \(item.unitNumber), \(item.title)\(schoolStatusWords(item).map { ", \($0)" } ?? "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// Ticked in class: a check. Circled (being taught now): a dot.
    @ViewBuilder
    private func schoolMark(_ item: SchoolMathsUnit) -> some View {
        switch item.schoolStatus {
        case "ticked":
            Image(systemName: "checkmark")
                .standardType(.uiCaption).fontWeight(.semibold)
                .foregroundStyle(theme.patterned.provenColor)
        case "circled":
            Circle()
                .fill(theme.patterned.color(.given))
                .frame(width: 7, height: 7)
        default:
            EmptyView()
        }
    }

    private func schoolStatusWords(_ item: SchoolMathsUnit) -> String? {
        switch item.schoolStatus {
        case "ticked": "done in class"
        case "circled": "in class now"
        default: nil
        }
    }

    private func lensTitle(_ lens: MathsCurriculumLens) -> String {
        switch lens {
        case .activeSchoolFocus: "Only ticked and circled chapters"
        case .coreStage8Complete: "All chapters"
        case .fullHorizonOlympiad: "All chapters, plus the extras"
        }
    }

    // MARK: The chosen chapter

    private func chapterCard(_ unit: SchoolMathsUnit) -> some View {
        let topic = selectedTopic(in: unit)
        let deeper = unit.livingWorldChapters.first.flatMap { number in
            store.seedPack.chapters.first { $0.number == number }
        }

        return VStack(alignment: .leading, spacing: StandardSpacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Kicker("Chapter \(unit.unitNumber) · Student book pp. \(unit.learnersBookStartPage)–\(unit.learnersBookEndPage)")
                Spacer(minLength: StandardSpacing.sm)
                switch unit.schoolStatus {
                case "ticked": StatusTag(.proven, label: "Done in class")
                case "circled": StatusTag(.working, label: "In class now")
                default: StatusTag(.notStarted, label: "Coming up")
                }
            }

            Text(unit.title)
                .standardType(.headlineLg)
                .foregroundStyle(theme.ink)
                .accessibilityAddTraits(.isHeader)

            if let deeper {
                WonderQuestion(deeper.hookSummary)
            }

            ChainCard(standsOn: standsOn(unit), unlocks: unlocks(unit)) { link in
                if let number = link.patternedChapter {
                    store.selectedChapterNumber = number
                    store.activeRoom = .patternedWorld
                } else if let number = Int(link.code.dropFirst(3)) {
                    store.selectedUnitNumber = number
                }
            }

            Rectangle().fill(theme.hairline()).frame(height: 1)

            VStack(spacing: 0) {
                ForEach(unit.topics) { item in
                    topicRow(item, isSelected: item.code == topic?.code)
                }
            }

            if let topic {
                topicDetail(topic, unitChapter: deeper?.number)
            }
        }
        .paperCard()
    }

    /// The chapter before it in the student book, which this one builds on.
    private func standsOn(_ unit: SchoolMathsUnit) -> [ChainLink] {
        store.visibleSchoolUnits
            .filter { $0.unitNumber == unit.unitNumber - 1 }
            .map { ChainLink(code: "Ch \($0.unitNumber)", title: $0.title) }
    }

    /// The Patterned World chapters this school chapter goes deeper into.
    private func unlocks(_ unit: SchoolMathsUnit) -> [ChainLink] {
        unit.livingWorldChapters.compactMap { number in
            store.seedPack.chapters.first { $0.number == number }
        }
        .map { ChainLink(code: "Ch \($0.number)", title: "\(ChainLink.patternedPrefix)\($0.title)") }
    }

    private func topicRow(_ topic: SchoolMathsTopic, isSelected: Bool) -> some View {
        let progress = topicProgress(topic)
        return Button {
            store.selectedTopicCode = topic.code
        } label: {
            HStack(spacing: StandardSpacing.md) {
                Text(topic.code)
                    .patternedType(.mathInline)
                    .foregroundStyle(theme.mute(theme.ink))
                    .frame(width: 40, alignment: .leading)
                Text(topic.title)
                    .standardType(.uiHeadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(theme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                ProgressRule(progress.fraction)
                    .frame(width: isWide ? 120 : 80)
                StatusTag(progress.status)
                    .frame(width: 120, alignment: .trailing)
            }
            .padding(.vertical, StandardSpacing.xs)
            .frame(minHeight: StandardAccessibility.touchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Topic \(topic.code), \(topic.title), \(progress.status.label)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    /// What the book says about the chosen topic, with the page scanner beside it.
    private func topicDetail(_ topic: SchoolMathsTopic, unitChapter: Int?) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            Rectangle().fill(theme.hairline()).frame(height: 1)
            HStack(alignment: .firstTextBaseline) {
                Kicker("Topic \(topic.code) · page \(topic.learnersBookPage)", muted: true)
                Spacer()
            }
            Text(topic.summary)
                .patternedType(.readingDefault)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let watchout = topic.cambridgeWatchouts.first {
                Text("Careful: \(watchout)")
                    .patternedType(.readingSmall)
                    .foregroundStyle(theme.mute(theme.ink))
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: StandardSpacing.md) {
                Button {
                    scannerTopic = topic
                } label: {
                    Label("Attach a page from your book", systemImage: "doc.viewfinder")
                }
                .buttonStyle(OutlineButtonStyle())

                if let chapter = topic.livingWorldChapters.first, chapter != unitChapter {
                    Button("Read it in The Patterned World, Ch \(chapter)") {
                        store.selectedChapterNumber = chapter
                        store.activeRoom = .patternedWorld
                    }
                    .buttonStyle(TextLinkButtonStyle())
                }
            }
        }
    }

    // MARK: Workbook

    private func workbook(_ unit: SchoolMathsUnit) -> some View {
        let questions = store.questions(forUnit: unit.unitNumber, tierFilter: tierFilter)
        let chosen = questions.first { $0.id == selectedQuestionId } ?? questions.first
        let topicCodes = Set(questions.map(\.topicCode))
        let scope = topicCodes.count == 1 ? "Topic \(topicCodes.first ?? "")" : "Chapter \(unit.unitNumber)"
        let readiness = store.readiness(for: unit)

        return VStack(alignment: .leading, spacing: StandardSpacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Kicker("Workbook · \(scope)")
                Spacer()
                if readiness.questionsTotal > 0 {
                    Text("\(readiness.questionsProvenCount + readiness.questionsSecureCount) of \(readiness.questionsTotal) proved on your own")
                        .standardType(.uiCaption)
                        .foregroundStyle(theme.mute(theme.ink))
                }
            }

            FlowLayout(spacing: StandardSpacing.xs) {
                ForEach(CompanionWorkbookTierFilter.allCases) { filter in
                    PatternedChip(tierFilterTitle(filter), isSelected: tierFilter == filter) {
                        tierFilter = filter
                        selectedQuestionId = nil
                    }
                }
            }

            if questions.isEmpty {
                Text("No workbook questions at this level for this chapter yet.")
                    .patternedType(.readingSmall)
                    .foregroundStyle(theme.mute(theme.ink))
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 200), spacing: StandardSpacing.md, alignment: .top)],
                    alignment: .leading,
                    spacing: StandardSpacing.md
                ) {
                    ForEach(questions) { question in
                        workbookCard(question, isChosen: question.id == chosen?.id)
                    }
                }
            }

            if let chosen {
                HStack(alignment: .center, spacing: StandardSpacing.lg) {
                    Text(lastTryNote(for: chosen))
                        .standardType(.uiBody)
                        .foregroundStyle(theme.mute(theme.ink))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button {
                        store.activePracticeQuestion = chosen
                    } label: {
                        HStack(spacing: StandardSpacing.xs) {
                            Text("Practise \(chosen.topicCode)")
                            Image(systemName: "arrow.right")
                        }
                    }
                    .buttonStyle(InkButtonStyle())
                    .accessibilityLabel("Practise topic \(chosen.topicCode): \(tierTitle(chosen.tier))")
                }
            }
        }
    }

    private func workbookCard(_ question: SchoolMathsQuestion, isChosen: Bool) -> some View {
        let level = store.proofsByQuestionId[question.id]?.level ?? .unseen
        return Button {
            selectedQuestionId = question.id
        } label: {
            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text(tierTitle(question.tier))
                        .standardType(.headlineSm)
                        .foregroundStyle(theme.ink)
                    Spacer(minLength: StandardSpacing.xs)
                    Text("\(question.marks) marks")
                        .standardType(.uiCaption)
                        .foregroundStyle(theme.mute(theme.ink))
                }
                Kicker(question.commandWord, muted: true)
                    .padding(.top, StandardSpacing.xxs)
                Text(question.prompt)
                    .patternedType(.readingSmall)
                    .foregroundStyle(theme.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                if level != .unseen {
                    StatusTag(Self.status(for: level))
                        .padding(.top, StandardSpacing.xxs)
                }
            }
            .padding(StandardSpacing.md)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                    .fill(theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                    .strokeBorder(isChosen ? theme.ink : theme.hairline(), lineWidth: isChosen ? 1.5 : 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isChosen ? .isSelected : [])
    }

    private func tierTitle(_ tier: String) -> String {
        switch tier.lowercased() {
        case "focus": "Focus"
        case "practice": "Model it"
        case "challenge": "Stretch"
        case "consolidation": "From the book"
        default: tier
        }
    }

    private func tierFilterTitle(_ filter: CompanionWorkbookTierFilter) -> String {
        switch filter {
        case .allTiers: "All"
        case .focus: "Focus"
        case .practice: "Model it"
        case .challenge: "Stretch"
        }
    }

    private func lastTryNote(for question: SchoolMathsQuestion) -> String {
        let code = question.topicCode
        switch store.proofsByQuestionId[question.id]?.level ?? .unseen {
        case .unseen:
            return "No tries yet. The first three hints keep the proof your own."
        case .assisted:
            return "Your last try at \(code) used help, so it counts as “with help”. One more on your own lights it up."
        case .shaky:
            return "Your last try at \(code) missed a step. Have another go on your own."
        case .proven:
            return "You proved \(code) on your own. Prove it again on another day to make it secure."
        case .secure:
            return "Secure: you proved \(code) on your own on two different days."
        }
    }

    // MARK: Endless practice

    private var practiceGenerator: some View {
        let problem = QuantitativeMathsEngine.generate(template: selectedTemplate, seed: problemSeed)
        return VStack(alignment: .leading, spacing: StandardSpacing.md) {
            Kicker("Endless practice")
            Text("A fresh question every time")
                .standardType(.headlineMd)
                .foregroundStyle(theme.ink)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: StandardSpacing.xs) {
                    ForEach(QuantitativeTemplateKind.allCases) { kind in
                        PatternedChip(kind.title, isSelected: selectedTemplate == kind) {
                            selectedTemplate = kind
                            quantEval = nil
                            numericInput = ""
                        }
                    }
                }
            }

            HStack(alignment: .firstTextBaseline) {
                Kicker("\(problem.title) · version \(problemSeed)", muted: true)
                Spacer()
                Button {
                    problemSeed += 1
                    quantEval = nil
                    numericInput = ""
                } label: {
                    Label("New numbers", systemImage: "arrow.clockwise")
                }
                .buttonStyle(OutlineButtonStyle())
            }

            Text(problem.prompt)
                .patternedType(.reading)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            if store.showIntuitionBeforeFormula {
                VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                    intuitionLine("See it", problem.visualIntuitionStep)
                    intuitionLine("What stays the same", problem.ahaInvariantStep)
                    intuitionLine("Write it", problem.formulaStep)
                }
                .padding(StandardSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                        .fill(theme.patterned.sunkColor)
                )
            }

            HStack(alignment: .bottom, spacing: StandardSpacing.sm) {
                NumericKeypadField(
                    label: "Your answer",
                    unitLabel: problem.unitLabel,
                    text: $numericInput
                ) {
                    quantEval = QuantitativeMathsEngine.evaluate(problem: problem, numericInput: numericInput)
                }
                Button("Check") {
                    quantEval = QuantitativeMathsEngine.evaluate(problem: problem, numericInput: numericInput)
                }
                .buttonStyle(OutlineButtonStyle())
            }

            if let eval = quantEval {
                VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                    StatusTag(eval.isCorrect ? .proven : .working, label: eval.isCorrect ? "Right" : "Not yet")
                    Text(eval.feedback)
                        .patternedType(.readingSmall)
                        .foregroundStyle(theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if let trap = eval.matchedTrap {
                        BuggyRuleTrapBanner(trap: trap)
                    }
                    ForEach(problem.stepByStepDerivation, id: \.self) { step in
                        Text(step)
                            .patternedType(.readingSmall)
                            .foregroundStyle(theme.mute(theme.ink))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .paperCard()
    }

    private func intuitionLine(_ label: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Kicker(label, muted: true)
            Text(text)
                .patternedType(.readingSmall)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Who is right?

    private func debate(_ unit: SchoolMathsUnit) -> some View {
        let scenario = MathematicalDebateEngine.scenario(forOUPUnit: unit.unitNumber, in: store.seedPack.chapters)
        return VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            Kicker("Who is right, and why?")
            Text("Two classmates disagree. Spot the tempting mistake before it catches you.")
                .patternedType(.readingSmall)
                .foregroundStyle(theme.mute(theme.ink))
            MathematicalDebateCardView(
                scenario: scenario,
                initialSelectedChoiceId: store.calloutResponses["debate-\(scenario.id)"]?.responseText,
                onChoiceSelected: { choice, isCorrect in
                    store.saveCalloutResponse(
                        calloutId: "debate-\(scenario.id)",
                        chapterNumber: scenario.chapterNumber,
                        text: choice.id,
                        confidencePercent: isCorrect ? 95 : 40,
                        isUnlockedOverride: isCorrect
                    )
                }
            )
        }
    }

    // MARK: Data

    private func selectedTopic(in unit: SchoolMathsUnit) -> SchoolMathsTopic? {
        unit.topics.first { $0.code == store.selectedTopicCode } ?? unit.topics.first
    }

    /// A topic's status and how much of its workbook is proved on Kym's own. Both come from the
    /// proof records of the topic's questions, never from a mastery estimate.
    private func topicProgress(_ topic: SchoolMathsTopic) -> (status: LearningStatus, fraction: Double) {
        let questions = store.questions(forTopic: topic.code)
        guard !questions.isEmpty else { return (.notStarted, 0) }
        let levels = questions.compactMap { store.proofsByQuestionId[$0.id]?.level }
        let proved = levels.filter(\.isIndependentProof).count
        let fraction = Double(proved) / Double(questions.count)
        let status: LearningStatus
        if levels.count == questions.count, levels.allSatisfy({ $0 == .secure }) {
            status = .secure
        } else if proved > 0 {
            status = .proven
        } else if levels.contains(.assisted) {
            status = .withHelp
        } else if levels.contains(.shaky) {
            status = .working
        } else {
            status = .notStarted
        }
        return (status, fraction)
    }

    static func status(for level: QuestionProofLevel) -> LearningStatus {
        switch level {
        case .unseen: .notStarted
        case .assisted: .withHelp
        case .shaky: .working
        case .proven: .proven
        case .secure: .secure
        }
    }
}

private extension ChainLink {
    static let patternedPrefix = "The Patterned World: "

    /// The Patterned World chapter a link opens, or nil for a school chapter.
    var patternedChapter: Int? {
        title.hasPrefix(Self.patternedPrefix) ? Int(code.dropFirst(3)) : nil
    }
}
