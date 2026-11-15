import SwiftUI

// MARK: - Room 1: Today

/// The day's front page: a greeting, the idea to wonder about, today's four steps, and three
/// glances (cards to remember, the next test, the Euclid thread). Everything else the room offers
/// sits lower, folded under "More for today".
struct TodayHomeView: View {
    @Bindable var store: AppStore
    @Environment(\.standardTheme) private var theme
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var isShowingCardBack = false
    @State private var revealedBridgeIds: Set<String> = []
    @State private var selectedFormulaTermSymbol: String? = nil
    @State private var openDetails: Set<TodayDetail> = []
    /// The step the Daily Flow sheet opens on when a button chose one.
    @State private var flowStart: DailyFlowStageKind? = nil
    /// The width of the page's column, which decides how many cards sit side by side.
    @State private var contentWidth: CGFloat = 0
    /// The family the fact sprint sheet opens on, while it is open.
    @State private var sprintFamily: FactFamily? = nil

    var body: some View {
        let plan = DailyFlowSessionEngine.buildPlan(
            pack: store.seedPack,
            dueCards: store.dueFSRSCards,
            allCards: store.fsrsCards,
            selectedChapterNumber: store.selectedChapterNumber,
            selectedUnitNumber: store.selectedUnitNumber,
            proofsByQuestionId: store.proofsByQuestionId,
            euclidProgress: store.euclidProgress
        )
        let path = TodayPath(plan: plan, store: store)

        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: StandardSpacing.lg) {
                    EditorialHeader(
                        eyebrow: Self.dateLine(),
                        title: "\(Self.greeting()), \(store.learnerDisplayName).",
                        subtitle: "One idea to wonder about, then four short steps. About \(plan.estimatedMinutes) minutes."
                    )
                    .padding(.bottom, -StandardSpacing.sm)

                    warmUpBand

                    if contentWidth >= 880 {
                        HStack(alignment: .top, spacing: StandardSpacing.lg) {
                            questionCard(plan)
                            pathCard(plan, path).frame(width: 370)
                        }
                    } else {
                        questionCard(plan)
                        pathCard(plan, path)
                    }

                    VStack(alignment: .leading, spacing: StandardSpacing.md) {
                        if contentWidth >= 800 {
                            HStack(alignment: .top, spacing: StandardSpacing.md) {
                                rememberCard(proxy)
                                nextTestCard
                                euclidCard
                            }
                        } else if contentWidth >= 520 {
                            HStack(alignment: .top, spacing: StandardSpacing.md) {
                                rememberCard(proxy)
                                nextTestCard
                            }
                            euclidCard
                        } else {
                            rememberCard(proxy)
                            nextTestCard
                            euclidCard
                        }
                    }
                    .id("glance")

                    moreForToday(plan)
                        .padding(.top, StandardSpacing.lg)
                }
                .frame(maxWidth: 1080, alignment: .leading)
                .readWidth($contentWidth)
                .padding(.horizontal, sizeClass == .compact ? StandardSpacing.md : StandardSpacing.xl2)
                .padding(.top, StandardSpacing.xl)
                .padding(.bottom, StandardSpacing.xl3)
                .frame(maxWidth: .infinity)
            }
            .task {
                // `today/below` opens the room scrolled to the glances, for screenshots.
                guard store.deepLinkTail.first == "below" else { return }
                try? await Task.sleep(for: .milliseconds(500))
                proxy.scrollTo("glance", anchor: .top)
            }
        }
        .background(theme.bg.ignoresSafeArea())
        .sheet(item: $sprintFamily) { family in
            FactSprintSheet(store: store, family: family)
        }
        .onChange(of: store.deepLinkTail, initial: true) { _, tail in
            // `today/sprint` opens the next fact sprint, for screenshots.
            guard tail.first == "sprint" else { return }
            store.deepLinkTail = []
            sprintFamily = store.nextFactFamily() ?? .timesAndDivide
        }
        .modifier(FlowPresentation(isPresented: $store.showDailyFlowSheet, onDismiss: { flowStart = nil }) {
            DailyFlowPlayerSheet(
                plan: plan,
                store: store,
                startStage: flowStart ?? deepLinkStage ?? path.current ?? .fsrsMemoryLock,
                doneBefore: path.done
            )
        })
    }

    private func openFlow(at stage: DailyFlowStageKind?) {
        flowStart = stage
        store.showDailyFlowSheet = true
    }

    /// `today/flow/2` opens the sheet on step 2, for screenshots.
    private var deepLinkStage: DailyFlowStageKind? {
        guard store.deepLinkTail.first == "flow", store.deepLinkTail.count > 1,
              let step = Int(store.deepLinkTail[1]) else { return nil }
        return DailyFlowStageKind(rawValue: step - 1)
    }

    // MARK: Warm-up

    private var warmUpBand: some View {
        let next = store.nextFactFamily()
        let doneToday = FactFamily.allCases.filter { store.todaysFactSprint($0) != nil }.count
        let chips = ForEach(FactFamily.allCases) { family in
            sprintChip(family, score: store.todaysFactSprint(family)?.right)
        }
        let start = Button {
            sprintFamily = next ?? .timesAndDivide
        } label: {
            HStack(spacing: StandardSpacing.xs) {
                Text(next == nil ? "Again" : doneToday == 0 ? "Start" : "Next sprint")
                Image(systemName: "arrow.right").imageScale(.small)
            }
        }
        .buttonStyle(OutlineButtonStyle())

        return VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            Kicker("Warm-up · facts by heart")
            Text("Four 20-second sprints. Facts you know by heart leave room for the new idea.")
                .patternedType(.readingSmall)
                .foregroundStyle(theme.mute(theme.ink))
                .fixedSize(horizontal: false, vertical: true)
            if contentWidth >= 820 {
                HStack(spacing: StandardSpacing.sm) {
                    chips
                    Spacer(minLength: StandardSpacing.sm)
                    start
                }
                .padding(.top, StandardSpacing.xxs)
            } else {
                FlowLayout(spacing: StandardSpacing.xs) { chips }
                    .padding(.top, StandardSpacing.xxs)
                start
            }
        }
        .paperCard(padding: StandardSpacing.md)
    }

    private func sprintChip(_ family: FactFamily, score: Int?) -> some View {
        Button {
            sprintFamily = family
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Text(family.title)
                    .standardType(.uiCaption)
                    .foregroundStyle(theme.mute(theme.ink))
                Text(score.map { "\($0) right" } ?? "20 s")
                    .standardType(.uiHeadline)
                    .monospacedDigit()
                    .foregroundStyle((score ?? 0) > 0 ? theme.patterned.provenColor : theme.ink)
            }
            .padding(.horizontal, StandardSpacing.sm)
            .padding(.vertical, StandardSpacing.xxs)
            .frame(minHeight: StandardAccessibility.touchTarget, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                    .fill(theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                    .strokeBorder(theme.hairline(), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the \(family.title.lowercased()) sprint")
    }

    // MARK: Today's question

    private func questionCard(_ plan: DailyFlowSessionPlan) -> some View {
        let chapter = plan.chapter
        let idea = chapter.hookSummary
        return VStack(alignment: .leading, spacing: StandardSpacing.md) {
            Kicker(idea.hasSuffix("?") ? "Today's question" : "Today's idea")
            WonderQuestion(idea)
            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                Kicker("In symbols", muted: true)
                Text(chapter.intuitionToFormula.formulaDisplay)
                    .patternedType(.mathInline)
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Try it: \(chapter.intuitionToFormula.concreteAction)")
                    .patternedType(.readingSmall)
                    .foregroundStyle(theme.mute(theme.ink))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(StandardSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                    .fill(theme.patterned.sunkColor)
            )
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center) {
                    chapterSource(chapter)
                    Spacer(minLength: StandardSpacing.md)
                    readChapterLink
                }
                VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                    chapterSource(chapter)
                    readChapterLink
                }
            }
        }
        .paperCard(padding: StandardSpacing.xl)
    }

    private func chapterSource(_ chapter: PatternedWorldChapter) -> some View {
        Text("From Chapter \(chapter.number) · \(chapter.title)")
            .standardType(.uiBody)
            .foregroundStyle(theme.mute(theme.ink))
            .lineLimit(2)
    }

    private var readChapterLink: some View {
        Button("Read the chapter") {
            store.activeRoom = .patternedWorld
        }
        .buttonStyle(TextLinkButtonStyle())
    }

    // MARK: Today's path

    private func pathCard(_ plan: DailyFlowSessionPlan, _ path: TodayPath) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            Kicker("Today's path")
            VStack(spacing: 0) {
                ForEach(DailyFlowStageKind.allCases) { stage in
                    if stage != .fsrsMemoryLock {
                        Rectangle().fill(theme.hairline()).frame(height: 1)
                    }
                    Button {
                        openFlow(at: stage)
                    } label: {
                        PathStepRow(
                            number: stage.rawValue + 1,
                            title: stage.plainTitle,
                            detail: stepDetail(stage, plan),
                            minutes: stage.minutes,
                            state: path.state(of: stage)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens today's path at this step")
                }
            }
            Button {
                openFlow(at: path.current ?? .fsrsMemoryLock)
            } label: {
                HStack(spacing: StandardSpacing.xs) {
                    Text(path.continueTitle)
                    Image(systemName: "arrow.right").imageScale(.small)
                }
            }
            .buttonStyle(InkButtonStyle(fullWidth: true))
            .padding(.top, StandardSpacing.sm)

            VStack(spacing: 0) {
                Text(path.doneLine)
                    .standardType(.uiCaption)
                    .foregroundStyle(theme.mute(theme.ink))
                    .multilineTextAlignment(.center)
                Button("Change the plan") {
                    store.showSettingsSheet = true
                }
                .buttonStyle(TextLinkButtonStyle(arrow: false))
            }
            .frame(maxWidth: .infinity)
        }
        .paperCard(padding: StandardSpacing.lg)
    }

    private func stepDetail(_ stage: DailyFlowStageKind, _ plan: DailyFlowSessionPlan) -> String {
        switch stage {
        case .fsrsMemoryLock:
            let due = store.dueFSRSCards.count
            switch due {
            case 0: return "Nothing is due. A warm-up card or two."
            case 1: return "1 card comes back today"
            default: return "\(due) cards come back today"
            }
        case .conceptDiscoveryBeat:
            return "Why it works: \(plan.chapter.title)"
        case .misconceptionImmunity:
            return "\(plan.debateScenario.title): a tempting wrong answer to catch"
        case .companionWorkbookProof:
            return "Workbook \(plan.proofQuestion.topicCode) · your own working"
        }
    }

    // MARK: Three glances

    private func rememberCard(_ proxy: ScrollViewProxy) -> some View {
        let due = store.dueFSRSCards
        return VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            Kicker("Remember")
            HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.sm) {
                Text("\(due.count)")
                    .patternedType(.numeral)
                    .foregroundStyle(theme.ink)
                Text(due.count == 1 ? "card is ready to come back" : "cards are ready to come back")
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.ink)
            }
            .accessibilityElement(children: .combine)
            Group {
                if let next = due.first {
                    Text("A card waits longer each time you remember it. Next up: \(next.frontPrompt)")
                } else {
                    Text("A card waits longer each time you remember it. None are waiting now.")
                }
            }
            .patternedType(.readingSmall)
            .foregroundStyle(theme.mute(theme.ink))
            .lineLimit(4)
            if !due.isEmpty {
                Button("Try one now") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        _ = openDetails.insert(.remember)
                        proxy.scrollTo(TodayDetail.remember, anchor: .top)
                    }
                }
                .buttonStyle(TextLinkButtonStyle())
            }
        }
        .paperCard()
    }

    @ViewBuilder private var nextTestCard: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            Kicker("Next test")
            if let deadline = store.nextSchoolDeadline {
                Text(deadline.title)
                    .standardType(.headlineSm)
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(Self.dueLine(deadline.dueAt))
                    .standardType(.uiBody)
                    .foregroundStyle(theme.mute(theme.ink))
                VStack(spacing: StandardSpacing.xs) {
                    ForEach(Self.unitNumbers(deadline), id: \.self) { unit in
                        let practice = unitPractice(unit)
                        HStack(spacing: StandardSpacing.sm) {
                            Text("Ch \(unit)")
                                .standardType(.uiCaption)
                                .foregroundStyle(theme.ink)
                                .frame(width: 40, alignment: .leading)
                            ProgressRule(practice.total == 0 ? 0 : Double(practice.proved) / Double(practice.total))
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Chapter \(unit): \(practice.proved) of \(practice.total) questions proved on your own")
                    }
                }
                .padding(.vertical, StandardSpacing.xxs)
                Text(deadline.notes)
                    .patternedType(.readingSmall)
                    .foregroundStyle(theme.mute(theme.ink))
                    .lineLimit(3)
            } else {
                Text("No tests coming up.")
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.mute(theme.ink))
            }
            Button("All deadlines") {
                store.showCalendarSheet = true
            }
            .buttonStyle(TextLinkButtonStyle())
        }
        .paperCard()
    }

    private func unitPractice(_ unit: Int) -> (proved: Int, total: Int) {
        let total = store.questions(forUnit: unit).count
        let proved = store.proofsByQuestionId.values.filter { $0.unitNumber == unit && $0.level.isIndependentProof }.count
        return (proved, total)
    }

    private var euclidCard: some View {
        let progress = store.euclidProgress
        let built = EuclidSpine.catalog.filter { progress.highest($0.id) != nil }.suffix(2)
        return VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            Kicker("Euclid thread")
            ForEach(Array(built), id: \.id) { proposition in
                let lit = (progress.highest(proposition.id)?.rawValue ?? -1) + 1
                euclidRow(proposition, status: Self.lampsLine(lit), lit: lit)
            }
            if let next = store.euclidUpNext {
                euclidRow(next, status: "Ready to build", lit: 0)
            }
            if built.isEmpty && store.euclidUpNext == nil {
                Text("Every proposition here is built.")
                    .patternedType(.readingSmall)
                    .foregroundStyle(theme.mute(theme.ink))
            }
            Button("Open the workshop") {
                store.openEuclid(.map)
            }
            .buttonStyle(TextLinkButtonStyle())
        }
        .paperCard()
    }

    private func euclidRow(_ proposition: EuclidProposition, status: String, lit: Int) -> some View {
        Button {
            store.openEuclid(.board(proposition.id))
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.sm) {
                Text(proposition.id.raw)
                    .patternedType(.mathInline)
                    .foregroundStyle(theme.patterned.color(.moves))
                    .frame(width: 38, alignment: .leading)
                VStack(alignment: .leading, spacing: 2) {
                    Text(proposition.title)
                        .standardType(.uiHeadline)
                        .foregroundStyle(theme.ink)
                    Text(status)
                        .standardType(.uiCaption)
                        .foregroundStyle(theme.mute(theme.ink))
                }
                Spacer(minLength: StandardSpacing.xs)
                SkillLamps(lit: lit)
            }
            .frame(minHeight: StandardAccessibility.touchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens it in Euclid's Workshop")
    }

    // MARK: More for today

    private func moreForToday(_ plan: DailyFlowSessionPlan) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Kicker("More for today")
            Text("Proved on your own: \(store.overallIndependentProofCount) of \(store.seedPack.schoolQuestions.count) workbook questions · Atlas stamps: \(store.widgetStampsById.count) of \(store.seedPack.widgets.count) · Book: \(store.selectedCurriculumLens.title)")
                .standardType(.uiBody)
                .foregroundStyle(theme.mute(theme.ink))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, StandardSpacing.xxs)
                .padding(.bottom, StandardSpacing.sm)

            disclosure(.remember, title: "One card now", summary: "Say the answer in your head, then check.") {
                rememberNow
            }
            disclosure(.why, title: "Why it works: Chapter \(store.selectedChapter.number)", summary: "Tap a part of the formula to see it in the picture.") {
                whyItWorks
            }
            disclosure(.workbook, title: "Workbook: Chapter \(store.selectedUnit.unitNumber) · \(store.selectedUnit.title)", summary: "Questions to prove, from easy to stretching.") {
                workbook
            }
            disclosure(.subjects, title: "Maths in other subjects", summary: "Where this maths turns up in biology, physics, chemistry and money.") {
                otherSubjects
            }
            disclosure(.widgets, title: "On your Home Screen", summary: "How today looks in the widgets.") {
                KymMathsWidgetPreviewGallery(store: store)
            }
        }
    }

    private func disclosure<Content: View>(
        _ detail: TodayDetail,
        title: String,
        summary: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let isOpen = openDetails.contains(detail)
        return VStack(alignment: .leading, spacing: StandardSpacing.md) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isOpen { openDetails.remove(detail) } else { openDetails.insert(detail) }
                }
            } label: {
                HStack(alignment: .center, spacing: StandardSpacing.md) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .standardType(.headlineSm)
                            .foregroundStyle(theme.ink)
                            .multilineTextAlignment(.leading)
                        Text(summary)
                            .standardType(.uiBody)
                            .foregroundStyle(theme.mute(theme.ink))
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: StandardSpacing.sm)
                    Image(systemName: "chevron.down")
                        .foregroundStyle(theme.brass)
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                        .accessibilityHidden(true)
                }
                .frame(minHeight: StandardAccessibility.touchTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(isOpen ? "Open" : "Folded")
            .accessibilityHint(isOpen ? "Folds this part away" : "Opens this part")

            if isOpen {
                content()
                    .padding(.bottom, StandardSpacing.sm)
            }
        }
        .padding(.vertical, StandardSpacing.sm)
        .overlay(alignment: .top) {
            Rectangle().fill(theme.hairline()).frame(height: 1)
        }
        .id(detail)
    }

    @ViewBuilder private var rememberNow: some View {
        if let card = store.dueFSRSCards.first {
            VStack(alignment: .leading, spacing: StandardSpacing.md) {
                Text("Topic \(card.topicCode) · Chapter \(card.chapterNumber) · holds for about \(String(format: "%.1f", card.stability)) days")
                    .standardType(.uiCaption)
                    .foregroundStyle(theme.mute(theme.ink))
                Text(card.frontPrompt)
                    .patternedType(.reading)
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                if isShowingCardBack {
                    VStack(alignment: .leading, spacing: StandardSpacing.sm) {
                        Kicker("The answer")
                        Text(card.backAnswer)
                            .patternedType(.readingDefault)
                            .foregroundStyle(theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(StandardSpacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                                    .fill(theme.patterned.sunkColor)
                            )
                        Text("How did that feel?")
                            .standardType(.uiBody)
                            .foregroundStyle(theme.mute(theme.ink))
                        FlowLayout(spacing: StandardSpacing.sm) {
                            ForEach(FSRSRating.allCases, id: \.rawValue) { rating in
                                Button(rating.title) {
                                    isShowingCardBack = false
                                    store.reviewFSRSCard(card, rating: rating)
                                }
                                .buttonStyle(OutlineButtonStyle())
                            }
                        }
                    }
                } else {
                    Button {
                        isShowingCardBack = true
                    } label: {
                        Label("Show the answer", systemImage: "eye")
                    }
                    .buttonStyle(OutlineButtonStyle())
                }
            }
            .paperCard()
        } else {
            Text("Every card that was due has come back today. Nothing to remember until tomorrow.")
                .patternedType(.readingDefault)
                .foregroundStyle(theme.mute(theme.ink))
        }
    }

    private var whyItWorks: some View {
        let chapter = store.selectedChapter
        return VStack(alignment: .leading, spacing: StandardSpacing.md) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: StandardSpacing.xs) {
                    ForEach(store.visiblePatternedWorldChapters) { item in
                        PatternedChip(
                            "Ch \(item.number): \(item.title)",
                            isSelected: store.selectedChapterNumber == item.number
                        ) {
                            store.selectedChapterNumber = item.number
                            selectedFormulaTermSymbol = nil
                        }
                    }
                }
            }
            ViewThatFits(in: .horizontal) {
                HStack {
                    Text("Chapter \(chapter.number) · \(chapter.volumeTitle)")
                        .standardType(.uiBody)
                        .foregroundStyle(theme.mute(theme.ink))
                    Spacer(minLength: StandardSpacing.md)
                    openChapterButton
                }
                VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                    Text("Chapter \(chapter.number) · \(chapter.volumeTitle)")
                        .standardType(.uiBody)
                        .foregroundStyle(theme.mute(theme.ink))
                    openChapterButton
                }
            }
            IntuitionFormulaBridgeCard(
                bridge: chapter.intuitionToFormula,
                selectedTermSymbol: $selectedFormulaTermSymbol
            )
        }
    }

    private var openChapterButton: some View {
        Button {
            store.activeRoom = .patternedWorld
        } label: {
            Label("Open the chapter", systemImage: "arrow.up.right.square")
        }
        .buttonStyle(OutlineButtonStyle())
    }

    private var workbook: some View {
        let unit = store.selectedUnit
        let unitQuestions = store.questions(forUnit: unit.unitNumber, tierFilter: store.defaultWorkbookTier)
        return VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center) {
                    workbookIntro(unit)
                    Spacer(minLength: StandardSpacing.md)
                    allChaptersButton
                }
                VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                    workbookIntro(unit)
                    allChaptersButton
                }
            }
            ForEach(unitQuestions.prefix(4)) { question in
                let level = store.proofsByQuestionId[question.id]?.level ?? .unseen
                HStack(alignment: .center, spacing: StandardSpacing.md) {
                    VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                        HStack(spacing: StandardSpacing.sm) {
                            StatusTag(Self.status(for: level))
                            Text("\(question.tier) · Topic \(question.topicCode)")
                                .standardType(.uiCaption)
                                .foregroundStyle(theme.mute(theme.ink))
                        }
                        Text(question.prompt)
                            .patternedType(.readingDefault)
                            .foregroundStyle(theme.ink)
                            .lineLimit(2)
                    }
                    Spacer(minLength: StandardSpacing.sm)
                    Button("Prove") {
                        store.activePracticeQuestion = question
                        store.activeRoom = .schoolMaths
                    }
                    .buttonStyle(OutlineButtonStyle())
                    .accessibilityLabel("Prove: \(question.prompt)")
                }
                .padding(.vertical, StandardSpacing.sm)
                .overlay(alignment: .top) {
                    Rectangle().fill(theme.hairline()).frame(height: 1)
                }
            }
        }
    }

    private func workbookIntro(_ unit: SchoolMathsUnit) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("School book pages \(unit.learnersBookStartPage)–\(unit.learnersBookEndPage) · \(Self.schoolStatusLine(unit.schoolStatus))")
                .standardType(.uiHeadline)
                .foregroundStyle(theme.ink)
            Text("Extra questions at three levels, Focus, Practice and Challenge, in place of the missing workbook.")
                .standardType(.uiBody)
                .foregroundStyle(theme.mute(theme.ink))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var allChaptersButton: some View {
        Button {
            store.activeRoom = .schoolMaths
        } label: {
            Label("All chapters", systemImage: "book.closed")
        }
        .buttonStyle(OutlineButtonStyle())
    }

    private var otherSubjects: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: StandardSpacing.md, alignment: .top)], spacing: StandardSpacing.md) {
            ForEach(store.seedPack.crossDisciplinaryBridges) { bridge in
                VStack(alignment: .leading, spacing: StandardSpacing.sm) {
                    Kicker(bridge.discipline.capitalized)
                    Text(bridge.title)
                        .standardType(.uiHeadline)
                        .foregroundStyle(theme.ink)
                    Text(bridge.summary)
                        .patternedType(.readingSmall)
                        .foregroundStyle(theme.mute(theme.ink))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(bridge.keyEquation)
                        .patternedType(.mathInline)
                        .foregroundStyle(theme.ink)
                    Text(bridge.sourceBook)
                        .standardType(.uiCaption)
                        .foregroundStyle(theme.mute(theme.ink))
                    Rectangle().fill(theme.hairline()).frame(height: 1)
                    Text(bridge.microCheckQuestion)
                        .standardType(.uiHeadline)
                        .foregroundStyle(theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if revealedBridgeIds.contains(bridge.id) {
                        Text(bridge.microCheckAnswer)
                            .patternedType(.readingSmall)
                            .foregroundStyle(theme.patterned.provenColor)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Button("Check the answer") {
                            revealedBridgeIds.insert(bridge.id)
                        }
                        .buttonStyle(OutlineButtonStyle())
                    }
                }
                .paperCard(padding: StandardSpacing.md)
            }
        }
    }

    // MARK: Words

    private static func greeting(now: Date = .now) -> String {
        switch Calendar.current.component(.hour, from: now) {
        case ..<12: "Good morning"
        case ..<17: "Good afternoon"
        default: "Good evening"
        }
    }

    private static func dateLine(now: Date = .now) -> String {
        "\(now.formatted(.dateTime.weekday(.wide).day().month(.wide))) · Mumbai"
    }

    private static func dueLine(_ date: Date) -> String {
        let day = date.formatted(.dateTime.weekday(.wide).day().month(.wide))
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: .now),
            to: Calendar.current.startOfDay(for: date)
        ).day ?? 0
        switch days {
        case ..<0: return "\(day) · already past"
        case 0: return "\(day) · today"
        case 1: return "\(day) · tomorrow"
        default: return "\(day) · \(days) days away"
        }
    }

    private static func unitNumbers(_ deadline: SchoolDeadlineRecord) -> [Int] {
        deadline.unitNumbersCSV.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
    }

    private static func lampsLine(_ lit: Int) -> String {
        switch lit {
        case 1: "One lamp lit"
        case 2: "Two lamps lit"
        case 3: "Three lamps lit"
        case 4: "All four lamps lit"
        default: "No lamps lit yet"
        }
    }

    private static func schoolStatusLine(_ status: String) -> String {
        switch status {
        case "ticked": "Done in class"
        case "circled": "Circled for practice"
        default: "Coming up"
        }
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

/// Today's path takes the whole screen on iPad, as a page of its own, and a sheet on the Mac.
private struct FlowPresentation<Flow: View>: ViewModifier {
    @Binding var isPresented: Bool
    let onDismiss: () -> Void
    @ViewBuilder let flow: () -> Flow

    func body(content: Content) -> some View {
        #if os(iOS)
        content.fullScreenCover(isPresented: $isPresented, onDismiss: onDismiss, content: flow)
        #else
        content.sheet(isPresented: $isPresented, onDismiss: onDismiss, content: flow)
        #endif
    }
}

/// The folded parts under "More for today".
private enum TodayDetail: Hashable {
    case remember, why, workbook, subjects, widgets
}

// MARK: - Today's path

/// Which of today's four steps are done, read from what she did today: cards remembered, the
/// chapter read, the trap answered, a proof done on her own.
struct TodayPath {
    let done: Set<DailyFlowStageKind>
    /// When the most recent of those happened today.
    let lastDoneAt: Date?

    init(done: Set<DailyFlowStageKind>, lastDoneAt: Date?) {
        self.done = done
        self.lastDoneAt = lastDoneAt
    }

    @MainActor init(plan: DailyFlowSessionPlan, store: AppStore, calendar: Calendar = .current) {
        let today: (Date?) -> Date? = { date in
            guard let date, calendar.isDateInToday(date) else { return nil }
            return date
        }
        let reviewed = store.fsrsCards.compactMap { today($0.lastReviewAt) }.max()
        let read = today(store.readingProgressByChapter[plan.chapter.number]?.updatedAt)
        let trap = today(store.calloutResponses["debate-\(plan.debateScenario.id)"]?.updatedAt)
        let proved = store.proofsByQuestionId.values
            .filter { $0.level.isIndependentProof }
            .compactMap { today($0.lastAttemptAt) }
            .max()

        var done: Set<DailyFlowStageKind> = []
        if store.dueFSRSCards.isEmpty { done.insert(.fsrsMemoryLock) }
        if read != nil { done.insert(.conceptDiscoveryBeat) }
        if trap != nil { done.insert(.misconceptionImmunity) }
        if proved != nil { done.insert(.companionWorkbookProof) }
        self.init(done: done, lastDoneAt: [reviewed, read, trap, proved].compactMap { $0 }.max())
    }

    var current: DailyFlowStageKind? {
        DailyFlowStageKind.allCases.first { !done.contains($0) }
    }

    func state(of stage: DailyFlowStageKind) -> PathStepRow.State {
        if done.contains(stage) { return .done }
        return stage == current ? .current : .upcoming
    }

    var continueTitle: String {
        guard let current else { return "Go through today again" }
        if done.isEmpty { return "Start with step 1" }
        return "Continue with step \(current.rawValue + 1)"
    }

    var doneLine: String {
        guard let lastDoneAt else { return "Nothing done yet today." }
        let time = lastDoneAt.formatted(date: .omitted, time: .shortened)
        let hour = Calendar.current.component(.hour, from: lastDoneAt)
        let part = hour < 12 ? "this morning" : hour < 17 ? "this afternoon" : "this evening"
        return "Last step done at \(time) \(part)."
    }
}

extension DailyFlowStageKind {
    /// The step's name on the page, in plain words.
    var plainTitle: String {
        switch self {
        case .fsrsMemoryLock: "Remember"
        case .conceptDiscoveryBeat: "Discover"
        case .misconceptionImmunity: "Spot the trap"
        case .companionWorkbookProof: "Prove it yourself"
        }
    }

    var minutes: Int {
        self == .fsrsMemoryLock ? 3 : 4
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
