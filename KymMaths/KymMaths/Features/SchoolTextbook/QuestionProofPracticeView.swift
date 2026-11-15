import SwiftUI

// MARK: - Proof studio: one question, Kym's own working, and a ladder of hints that says what each costs

struct QuestionProofPracticeView: View {
    let question: SchoolMathsQuestion
    @Bindable var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.standardTheme) private var theme

    @State private var showWorkedExample = false
    @State private var showFadedScaffold = false
    @State private var usedAssistanceInSession = false
    @State private var highestHintRung: HintLadderRung = .none
    @State private var currentHintRung: HintLadderRung = .none
    @State private var thinkingTrace = ""
    @State private var confidencePercent: Int = 75
    @State private var declinedToGuess = false
    @State private var fadedInput = ""
    @State private var fadedFeedback: SocraticGraduatedFeedback?
    @State private var revealFadedTarget = false
    @State private var cpaState = CPAManipulativeState(primaryValue: 5, secondaryValue: 12)
    /// The working, line by line. The answer box below is added to it when Kym hands in.
    @State private var answerText = ""
    @State private var finalAnswer = ""
    @State private var evaluation: QuestionEvaluationResult?
    @State private var graduatedFeedback: SocraticGraduatedFeedback?
    @State private var interrogationResponse = ""
    @State private var interrogationLocked = false
    @State private var selectedFlawStepIndex: Int?
    @State private var flawScoreResult: SpotTheFlawScoreResult?
    @State private var showScratchpad = false
    @State private var showModel = false
    @State private var showThinking = false
    @State private var pageWidth: CGFloat = 0
    @FocusState private var typingIn: TypingBox?
    @State private var handInGate = HandInGate()

    /// The boxes whose words are handed in.
    private enum TypingBox: Hashable { case working, answer, thinking }

    private var isWide: Bool { pageWidth >= 860 }

    private var effectiveAssisted: Bool {
        usedAssistanceInSession || highestHintRung.surrendersRetrieval
    }

    private var matchingSpotTheFlaw: SpotTheFlawPayload {
        let chKey = String(format: "ch%02d", question.unitNumber)
        return MathsSpotTheFlawCatalog.all.first(where: { $0.chapterId == chKey })
            ?? MathsSpotTheFlawCatalog.all[0]
    }

    private var recommendedCPAStage: ConcretenessRepresentationStage {
        let skill = store.bktSkillsById[question.topicCode]
        let exposure = (skill?.independentEvidenceCount ?? 0) + (skill?.assistedEvidenceCount ?? 0)
        let mastery = skill?.pLearned ?? 0.35
        return ConcretenessFadingEngine.recommendedStage(
            exposureCount: exposure,
            masteryProbability: mastery
        )
    }

    /// What is handed in: the working, then the answer on its own line.
    private var submission: String {
        [answerText, finalAnswer]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StandardSpacing.lg) {
                topBar
                if isWide {
                    HStack(alignment: .top, spacing: StandardSpacing.xl) {
                        mainColumn
                        VStack(alignment: .leading, spacing: StandardSpacing.lg) {
                            hintLadder
                            ladderNote
                        }
                        .frame(width: 340)
                    }
                } else {
                    mainColumn
                    hintLadder
                    ladderNote
                }
            }
            .padding(.horizontal, StandardSpacing.xl)
            .padding(.vertical, StandardSpacing.lg)
            .readWidth($pageWidth)
        }
        .background(theme.bg)
        .pageSizedSheet()
        .onAppear {
            cpaState = CPAManipulativeEngine.initialState(for: question)
        }
        .onChange(of: store.deepLinkTail, initial: true) { _, tail in
            // `proof/<unit>/scratch` opens the scratchpad over the studio.
            guard tail.first == "scratch" else { return }
            store.deepLinkTail = []
            showScratchpad = true
        }
        .sheet(isPresented: $showScratchpad) {
            MathsScratchpadView(question: question, store: store)
                .pageSizedSheet()
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(spacing: StandardSpacing.xs) {
            SheetCloseButton { dismiss() }
                .padding(.leading, -StandardSpacing.sm)
            Text("School book")
            Image(systemName: "chevron.right").imageScale(.small).foregroundStyle(theme.faint(theme.ink))
            Text("Chapter \(question.unitNumber)")
            Image(systemName: "chevron.right").imageScale(.small).foregroundStyle(theme.faint(theme.ink))
            Text("Topic \(question.topicCode)")
            Spacer()
            if let proof = store.proofsByQuestionId[question.id] {
                StatusTag(SchoolMathsHomeView.status(for: proof.level))
            }
        }
        .standardType(.uiHeadline)
        .fontWeight(.regular)
        .foregroundStyle(theme.mute(theme.ink))
        .accessibilityElement(children: .contain)
    }

    // MARK: Main column

    private var mainColumn: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.lg) {
            FlowLayout(spacing: StandardSpacing.xs) {
                tag(question.commandWord, filled: true)
                tag("\(question.marks) marks")
                tag(tierTitle)
                tag("Topic \(question.topicCode)")
            }

            Text(question.prompt)
                .standardType(question.prompt.count > 70 ? .headlineLg : .display)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            Text("\(stageTitle). \(recommendedCPAStage.coachDirective)")
                .patternedType(.readingDefault)
                .foregroundStyle(theme.mute(theme.ink))
                .fixedSize(horizontal: false, vertical: true)

            if showWorkedExample { workedExampleCard }
            if showFadedScaffold { fadedStepCard }

            workingCard

            if showModel {
                VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                    Kicker("Build it")
                    CPAManipulativeSandboxCard(
                        spec: CPAManipulativeEngine.spec(for: question),
                        state: $cpaState
                    ) { stampedEquation in
                        if answerText.isEmpty {
                            answerText = stampedEquation
                        } else {
                            answerText += "\n" + stampedEquation
                        }
                    }
                }
            }

            answerAndConfidence
            thinkingAloud
            handIn

            if let eval = evaluation {
                resultCard(eval)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func tag(_ text: String, filled: Bool = false) -> some View {
        Text(text)
            .standardType(.uiHeadline)
            .fontWeight(.regular)
            .foregroundStyle(filled ? theme.bg : theme.ink)
            .padding(.horizontal, StandardSpacing.sm + 2)
            .frame(minHeight: 34)
            .background(Capsule().fill(filled ? theme.ink : theme.surface))
            .overlay(Capsule().strokeBorder(filled ? Color.clear : theme.hairline(), lineWidth: 1))
    }

    private var tierTitle: String {
        switch question.tier.lowercased() {
        case "focus": "Focus"
        case "practice": "Model it"
        case "challenge": "Stretch"
        case "consolidation": "From the book"
        default: question.tier
        }
    }

    private var stageTitle: String {
        switch recommendedCPAStage {
        case .concrete: "Start with something real"
        case .semiAbstract: "Draw it first"
        case .abstract: "Write it in symbols"
        }
    }

    // MARK: Working

    private var workingCard: some View {
        let lines = answerText.split(separator: "\n", omittingEmptySubsequences: true).count
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Kicker("Your working")
                Spacer()
                ToolIconButton("Open the scratchpad", systemImage: "pencil") {
                    showScratchpad = true
                }
                ToolIconButton("Take back the last line", systemImage: "arrow.uturn.backward") {
                    var parts = answerText.components(separatedBy: "\n")
                    while let last = parts.last, last.trimmingCharacters(in: .whitespaces).isEmpty, !parts.isEmpty {
                        parts.removeLast()
                    }
                    if !parts.isEmpty { parts.removeLast() }
                    answerText = parts.joined(separator: "\n")
                }
                .disabled(answerText.isEmpty)
                ToolIconButton(showModel ? "Hide the model" : "Build it with a model", systemImage: "square.grid.2x2", isOn: showModel) {
                    showModel.toggle()
                }
            }
            .padding(.leading, StandardSpacing.lg)
            .padding(.trailing, StandardSpacing.xs)
            .padding(.top, StandardSpacing.xs)

            ZStack(alignment: .topLeading) {
                RuledLines(spacing: 52, color: theme.hairline())
                TextEditor(text: $answerText)
                    .focused($typingIn, equals: .working)
                    .learnerTextInput(.retrieval)
                    .scrollContentBackground(.hidden)
                    .lineSpacing(26)
                    .patternedType(.hand)
                    .foregroundStyle(theme.ink)
                    .padding(.horizontal, StandardSpacing.lg - 5)
                    .padding(.top, 10)
                    .accessibilityLabel("Your working")
                if answerText.isEmpty {
                    Text("One step on each line.")
                        .patternedType(.hand)
                        .foregroundStyle(theme.faint(theme.ink))
                        .padding(.horizontal, StandardSpacing.lg)
                        .padding(.top, 18)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .frame(minHeight: 312)

            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                MathSymbolRibbon(text: $answerText)
                Text(lines == 0 ? "Nothing written yet" : "Typed · \(lines) \(lines == 1 ? "line" : "lines")")
                    .standardType(.uiCaption)
                    .foregroundStyle(theme.mute(theme.ink))
            }
            .padding(.horizontal, StandardSpacing.lg)
            .padding(.vertical, StandardSpacing.sm)
            .overlay(alignment: .top) { Rectangle().fill(theme.hairline()).frame(height: 1) }
        }
        .background(RoundedRectangle(cornerRadius: StandardRadius.xl, style: .continuous).fill(theme.surface))
        .overlay(RoundedRectangle(cornerRadius: StandardRadius.xl, style: .continuous).strokeBorder(theme.hairline(), lineWidth: 1))
    }

    private var answerAndConfidence: some View {
        HStack(alignment: .bottom, spacing: StandardSpacing.lg) {
            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                Kicker("Answer", muted: true)
                TextField("", text: $finalAnswer, prompt: Text(question.answerPartsPhrase ?? "Your answer"))
                    .focused($typingIn, equals: .answer)
                    .learnerTextInput(.retrieval)
                    .textFieldStyle(.plain)
                    .patternedType(.mathDisplay)
                    .foregroundStyle(theme.ink)
                    .padding(.horizontal, StandardSpacing.md)
                    .frame(minHeight: 64)
                    .background(RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous).fill(theme.surface))
                    .overlay(RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous).strokeBorder(theme.ink, lineWidth: 1.5))
                    .accessibilityLabel("Answer")
            }
            .frame(maxWidth: 260)

            VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                Kicker("How sure are you?", muted: true)
                FlowLayout(spacing: StandardSpacing.xs) {
                    PatternedChip("I don't know yet", isSelected: declinedToGuess) {
                        declinedToGuess = true
                        confidencePercent = 0
                    }
                    ForEach([(35, "Unsure"), (75, "Pretty sure"), (95, "Certain")], id: \.0) { pct, label in
                        PatternedChip(label, isSelected: !declinedToGuess && confidencePercent == pct) {
                            declinedToGuess = false
                            confidencePercent = pct
                        }
                    }
                }
            }
        }
    }

    private var thinkingAloud: some View {
        DisclosureGroup(isExpanded: $showThinking) {
            TextField("What are you trying? “Let one bar be the unknown…”", text: $thinkingTrace, axis: .vertical)
                .focused($typingIn, equals: .thinking)
                .learnerTextInput(.retrieval)
                .textFieldStyle(.plain)
                .patternedType(.readingDefault)
                .foregroundStyle(theme.ink)
                .lineLimit(2...4)
                .padding(StandardSpacing.sm)
                .background(RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous).fill(theme.surface))
                .overlay(RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous).strokeBorder(theme.hairline(), lineWidth: 1))
                .padding(.top, StandardSpacing.xs)
        } label: {
            Text("Think out loud (optional). The hints read it.")
                .standardType(.uiBody)
                .foregroundStyle(theme.mute(theme.ink))
        }
        .tint(theme.brass)
    }

    private var handIn: some View {
        HStack(alignment: .center, spacing: StandardSpacing.md) {
            VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                HStack(spacing: StandardSpacing.xs) {
                    Circle()
                        .fill(effectiveAssisted ? theme.patterned.assistedColor : theme.patterned.provenColor)
                        .frame(width: 7, height: 7)
                    Text(effectiveAssisted
                         ? "With help: this try will be marked “with help”"
                         : (highestHintRung == .none ? "On your own so far: no hints used" : "Still your own: only the first three rungs"))
                        .standardType(.uiHeadline)
                        .foregroundStyle(effectiveAssisted ? theme.patterned.assistedColor : theme.patterned.provenColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if effectiveAssisted {
                    Button("Start again on my own") {
                        showWorkedExample = false
                        showFadedScaffold = false
                        usedAssistanceInSession = false
                        highestHintRung = .none
                        currentHintRung = .none
                        answerText = ""
                        finalAnswer = ""
                        evaluation = nil
                    }
                    .buttonStyle(TextLinkButtonStyle(arrow: false))
                }
            }
            Spacer(minLength: StandardSpacing.sm)
            Button {
                if handInGate.tap(isEditing: typingIn != nil) {
                    markAttempt()
                } else {
                    typingIn = nil
                }
            } label: {
                HStack(spacing: StandardSpacing.xs) {
                    Text(declinedToGuess ? "Record an honest “not yet”" : (effectiveAssisted ? "Hand in, with help" : "Hand in my proof"))
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(InkButtonStyle())
        }
        .onChange(of: typingIn) { _, box in
            guard box == nil, handInGate.editingEnded() else { return }
            // The field hands its last keys to the binding as it lets go; read it on the next turn.
            DispatchQueue.main.async { markAttempt() }
        }
    }

    private func markAttempt() {
        evaluation = store.submitQuestionAttempt(
            question: question,
            answerText: submission,
            usedAssistance: usedAssistanceInSession,
            highestHintRung: highestHintRung,
            confidencePercent: confidencePercent,
            declinedToGuess: declinedToGuess,
            thinkingTrace: thinkingTrace
        )
        graduatedFeedback = evaluation.map {
            SocraticFeedbackEngine.evaluate(studentAnswer: submission, question: question, marked: $0)
        }
    }

    // MARK: Help that counts

    private var workedExampleCard: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            HStack {
                Kicker("Worked example")
                Spacer()
                StatusTag(.withHelp, label: "Counts as help")
            }
            Text(question.workedExample)
                .patternedType(.readingDefault)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .paperCard(padding: StandardSpacing.md)
    }

    private var fadedStepCard: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            HStack {
                Kicker("Fill the gap")
                Spacer()
                StatusTag(.withHelp, label: "Counts as help")
            }
            Text(question.fadedPrompt)
                .patternedType(.readingDefault)
                .foregroundStyle(theme.ink)

            MathSymbolRibbon(text: $fadedInput)

            HStack(spacing: StandardSpacing.sm) {
                TextField("The missing step", text: $fadedInput)
                    .learnerTextInput(.retrieval)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(theme.ink)
                    .padding(.horizontal, StandardSpacing.sm)
                    .frame(minHeight: StandardAccessibility.touchTarget)
                    .background(RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous).fill(theme.bg))
                    .overlay(RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous).strokeBorder(theme.hairline(), lineWidth: 1))
                    .onSubmit(checkFadedStep)

                Button("Check step", action: checkFadedStep)
                    .buttonStyle(OutlineButtonStyle())

                if fadedFeedback != nil || !fadedInput.isEmpty {
                    Button("Clear") {
                        fadedInput = ""
                        fadedFeedback = nil
                        revealFadedTarget = false
                    }
                    .buttonStyle(TextLinkButtonStyle(arrow: false))
                }
            }

            if let fEval = fadedFeedback {
                VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                    HStack(alignment: .firstTextBaseline) {
                        StatusTag(fEval.tier == .correct ? .proven : .working, label: feedbackTitle(fEval.tier))
                        Spacer()
                        if fEval.tier != .correct {
                            Button(revealFadedTarget ? "Hide the step" : "Show me the step") {
                                revealFadedTarget.toggle()
                                usedAssistanceInSession = true
                            }
                            .buttonStyle(TextLinkButtonStyle(arrow: false))
                        }
                    }
                    Text(fEval.headline)
                        .standardType(.uiHeadline)
                        .foregroundStyle(theme.ink)
                    Text(fEval.socraticNudge)
                        .patternedType(.readingSmall)
                        .foregroundStyle(theme.mute(theme.ink))
                        .fixedSize(horizontal: false, vertical: true)
                    if revealFadedTarget || fEval.tier == .correct {
                        Text("The step: \(question.fadedAnswer)")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(theme.patterned.provenColor)
                    }
                }
            }
        }
        .paperCard(padding: StandardSpacing.md)
    }

    private func checkFadedStep() {
        fadedFeedback = SocraticFeedbackEngine.evaluateFadedStep(
            studentInput: fadedInput,
            expectedFadedAnswer: question.fadedAnswer,
            workedHint: question.workedExample
        )
    }

    // MARK: Hint ladder

    private struct Rung: Identifiable {
        let rung: HintLadderRung
        let title: String
        let detail: String
        var id: Int { rung.rawValue }
    }

    private static let rungs: [Rung] = [
        Rung(rung: .r0AttentionRedirect, title: "Nudge", detail: "Where to look first"),
        Rung(rung: .r1PatternRedescription, title: "Say it again", detail: "The pattern, in other words"),
        Rung(rung: .r2CandidateClass, title: "Kind of idea", detail: "Which family of ideas fits"),
        Rung(rung: .r3PropositionNamed, title: "The idea", detail: "The rule or fact to use"),
        Rung(rung: .r4MoveOutlined, title: "The move", detail: "What to do, in outline"),
        Rung(rung: .r5WorkedStep, title: "Worked step", detail: "One step done for you"),
    ]

    private var hintLadder: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            Text("Stuck? Climb one rung")
                .standardType(.headlineSm)
                .foregroundStyle(theme.ink)
                .accessibilityAddTraits(.isHeader)
            Text("Each rung tells you a little more. Take only what you need.")
                .standardType(.uiBody)
                .foregroundStyle(theme.mute(theme.ink))
                .fixedSize(horizontal: false, vertical: true)

            Kicker("Still yours", muted: true)
                .padding(.top, StandardSpacing.xs)
            ForEach(Self.rungs.filter { !$0.rung.surrendersRetrieval }) { rungRow($0) }

            Kicker("Counts as help")
                .padding(.top, StandardSpacing.xs)
            ForEach(Self.rungs.filter { $0.rung.surrendersRetrieval }) { rungRow($0) }
            helpRow(
                title: "Worked example",
                detail: "A similar question, all worked",
                systemImage: "lightbulb",
                isOpen: showWorkedExample
            ) {
                showWorkedExample.toggle()
                if showWorkedExample { usedAssistanceInSession = true }
            }
            helpRow(
                title: "Fill the gap",
                detail: "A worked answer with one step missing",
                systemImage: "square.dashed",
                isOpen: showFadedScaffold
            ) {
                showFadedScaffold.toggle()
                if showFadedScaffold { usedAssistanceInSession = true }
            }
        }
        .padding(StandardSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: StandardRadius.xl, style: .continuous)
                .fill(theme.patterned.marginColor)
        )
    }

    private func rungRow(_ item: Rung) -> some View {
        let isOpen = currentHintRung == item.rung
        let used = item.rung <= highestHintRung
        let tint = item.rung.surrendersRetrieval ? theme.patterned.assistedColor : theme.patterned.provenColor
        return VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            Button {
                if isOpen {
                    currentHintRung = .none
                } else {
                    currentHintRung = item.rung
                    if item.rung > highestHintRung { highestHintRung = item.rung }
                    if item.rung.surrendersRetrieval { usedAssistanceInSession = true }
                }
            } label: {
                HStack(spacing: StandardSpacing.sm) {
                    ZStack {
                        Circle().fill(used ? tint : Color.clear)
                        Circle().strokeBorder(tint, lineWidth: 1.5)
                        Text("\(item.rung.rawValue - 1)")
                            .standardType(.uiBody)
                            .fontWeight(.semibold)
                            .foregroundStyle(used ? theme.surface : tint)
                    }
                    .frame(width: 28, height: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .standardType(.uiHeadline)
                            .foregroundStyle(theme.ink)
                        Text(item.detail)
                            .standardType(.uiBody)
                            .foregroundStyle(theme.mute(theme.ink))
                    }
                    Spacer(minLength: StandardSpacing.xs)
                    Image(systemName: isOpen ? "chevron.down" : "chevron.right")
                        .standardType(.uiBody).fontWeight(.semibold)
                        .foregroundStyle(theme.mute(theme.ink))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Rung \(item.rung.rawValue - 1), \(item.title): \(item.detail)")
            .accessibilityHint(item.rung.surrendersRetrieval ? "Counts as help" : "Keeps the proof yours")

            if isOpen {
                Text(MeteredHintLadderEngine.hint(for: question, rung: item.rung, thinkingTrace: thinkingTrace))
                    .patternedType(.readingSmall)
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 40)
            }
        }
        .padding(StandardSpacing.sm)
        .background(RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous).fill(theme.surface))
        .overlay(RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous).strokeBorder(theme.hairline(), lineWidth: 1))
    }

    private func helpRow(title: String, detail: String, systemImage: String, isOpen: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: StandardSpacing.sm) {
                Image(systemName: systemImage)
                    .foregroundStyle(theme.patterned.assistedColor)
                    .frame(width: 28, height: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .standardType(.uiHeadline)
                        .foregroundStyle(theme.ink)
                    Text(isOpen ? "Showing. Tap to hide" : detail)
                        .standardType(.uiBody)
                        .foregroundStyle(theme.mute(theme.ink))
                }
                Spacer(minLength: StandardSpacing.xs)
                Image(systemName: isOpen ? "chevron.down" : "chevron.right")
                    .standardType(.uiBody).fontWeight(.semibold)
                    .foregroundStyle(theme.mute(theme.ink))
            }
            .padding(StandardSpacing.sm)
            .background(RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous).fill(theme.surface))
            .overlay(RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous).strokeBorder(theme.hairline(), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Counts as help")
    }

    private var ladderNote: some View {
        MarginNote(.sidenote(1), "Rungs 0 to 2 leave the proof yours. From rung 3, and with the worked example or a filled gap, your answer still counts, marked “with help”.")
            .padding(.horizontal, StandardSpacing.sm)
    }

    // MARK: Result

    private func resultCard(_ eval: QuestionEvaluationResult) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Kicker("How it went")
                Spacer()
                StatusTag(SchoolMathsHomeView.status(for: eval.resultingProofLevel))
            }
            Text(eval.feedbackSummary)
                .patternedType(.readingDefault)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(diagnosis(eval.diagnosticCell, slipNamed: eval.mistake != nil))
                .standardType(.uiHeadline)
                .foregroundStyle(theme.ink)

            if let grad = graduatedFeedback, !declinedToGuess, eval.mistake == nil {
                Text("\(feedbackTitle(grad.tier)). \(grad.headline). \(grad.socraticNudge)")
                    .patternedType(.readingSmall)
                    .foregroundStyle(theme.mute(theme.ink))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !eval.matchedParts.isEmpty, !eval.missingParts.isEmpty {
                Text("Right so far: \(eval.matchedParts.joined(separator: ", "))")
                    .standardType(.uiBody)
                    .foregroundStyle(theme.patterned.provenColor)
                Text("Still to get: \(eval.missingParts.joined(separator: ", "))")
                    .standardType(.uiBody)
                    .foregroundStyle(theme.patterned.assistedColor)
            }

            if eval.diagnosticCell == .committedMisconception, eval.mistake == nil {
                spotTheFlaw
            }

            if eval.isPass {
                whyItWorks
            }

            Rectangle().fill(theme.hairline()).frame(height: 1)
            if eval.isPass {
                Kicker("A model answer", muted: true)
                Text(question.workedExample)
                    .patternedType(.readingSmall)
                    .foregroundStyle(theme.mute(theme.ink))
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("The model answer opens once you get it right. Need it sooner? The Worked example rung shows it, counted as help.")
                    .patternedType(.readingSmall)
                    .foregroundStyle(theme.mute(theme.ink))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .paperCard()
    }

    private var spotTheFlaw: some View {
        let stf = matchingSpotTheFlaw
        return VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            Rectangle().fill(theme.hairline()).frame(height: 1)
            Kicker("Spot the slip · \(stf.title)")
            Text(stf.problemStem)
                .patternedType(.readingDefault)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(Array(stf.steps.enumerated()), id: \.offset) { idx, stepLine in
                Button {
                    selectedFlawStepIndex = idx
                    flawScoreResult = stf.score(selectedStepIndex: idx)
                } label: {
                    HStack {
                        Text("Step \(idx + 1): \(stepLine)")
                            .multilineTextAlignment(.leading)
                        Spacer()
                        if selectedFlawStepIndex == idx {
                            Image(systemName: "arrow.left")
                        }
                    }
                }
                .buttonStyle(OutlineButtonStyle())
                .accessibilityAddTraits(selectedFlawStepIndex == idx ? .isSelected : [])
            }
            if let flawResult = flawScoreResult {
                Text(flawResult.feedback)
                    .patternedType(.readingSmall)
                    .foregroundStyle(flawResult.isCorrect ? theme.patterned.provenColor : theme.patterned.assistedColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var whyItWorks: some View {
        let prompt = ElaborativeInterrogationEngine.makePrompt(
            for: question.bookSection,
            singaporeMethodFocus: store.selectedUnit.scienceInContext
        )
        return VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            Rectangle().fill(theme.hairline()).frame(height: 1)
            Kicker("Why does it work?")
            Text(prompt.question)
                .patternedType(.readingDefault)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("A clue: \(prompt.invariantHint)")
                .patternedType(.readingSmall)
                .foregroundStyle(theme.mute(theme.ink))
                .fixedSize(horizontal: false, vertical: true)
            TextField("Say why in one sentence", text: $interrogationResponse, axis: .vertical)
                .learnerTextInput(.retrieval)
                .textFieldStyle(.plain)
                .patternedType(.readingDefault)
                .foregroundStyle(theme.ink)
                .padding(StandardSpacing.sm)
                .background(RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous).fill(theme.bg))
                .overlay(RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous).strokeBorder(theme.hairline(), lineWidth: 1))
            HStack {
                Button("Keep my reason") {
                    let textToSave = interrogationResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? prompt.invariantHint
                        : interrogationResponse
                    store.saveCalloutResponse(
                        calloutId: "interrogation-\(question.id)",
                        chapterNumber: question.linkedChapter,
                        text: textToSave,
                        isUnlockedOverride: true
                    )
                    interrogationLocked = true
                }
                .buttonStyle(OutlineButtonStyle())

                if interrogationLocked || store.calloutResponses["interrogation-\(question.id)"]?.isUnlocked == true {
                    StatusTag(.proven, label: "Reason kept")
                }
            }
        }
    }

    private func feedbackTitle(_ tier: SocraticFeedbackTier) -> String {
        switch tier {
        case .correct: "Right"
        case .close: "Very close: check the sign or the rounding"
        case .partial: "On the right track: one step missing"
        case .far: "Not yet: try drawing it first"
        }
    }

    private func diagnosis(_ cell: ConfidenceVerdictCell, slipNamed: Bool) -> String {
        switch cell {
        case .solidKnowledge: "Right, and you were sure. That is solid."
        case .fragileOrLuckyGuess: "Right, but you weren't sure. Say why it works."
        case .committedMisconception where slipNamed: "You were sure, but it isn't right yet. Fix the slip named above."
        case .committedMisconception: "You were sure, but it isn't right yet. Find the slip below."
        case .shakyNearMiss: "Not yet, and you weren't sure. Come back to it soon."
        case .honestGap: "An honest “not yet”. Start from the first rung."
        }
    }
}

/// Ruled lines for the working card, one per line of handwriting.
private struct RuledLines: View {
    let spacing: CGFloat
    let color: Color

    var body: some View {
        Canvas { context, size in
            var path = Path()
            var y = spacing
            while y < size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += spacing
            }
            context.stroke(path, with: .color(color), lineWidth: 1)
        }
        .accessibilityHidden(true)
    }
}

/// One tap on Hand in marks what is in the boxes. Typed keys can still be queued for a box when the tap
/// lands, so while Kym is typing the tap ends editing first and the attempt is marked once editing has ended.
struct HandInGate {
    private(set) var isWaiting = false

    /// Whether the tap can mark the attempt now. If not, end editing and call `editingEnded()`.
    mutating func tap(isEditing: Bool) -> Bool {
        isWaiting = isEditing
        return !isEditing
    }

    /// Whether a hand-in was waiting on editing to end and should be marked now.
    mutating func editingEnded() -> Bool {
        defer { isWaiting = false }
        return isWaiting
    }
}
