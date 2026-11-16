import SwiftUI

// MARK: - The book's shape, read from the seed pack

/// Names, codes and states for The Patterned World, worked out from the seed pack and the reader's
/// saved progress. Nothing here invents learning data: wonder lines are chapter hooks, chains are
/// chapter order, and the hand note is the reader's own saved words.
enum PatternedBook {
    static func roman(_ number: Int) -> String {
        let table: [(Int, String)] = [(10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")]
        var rest = number
        var out = ""
        for (value, glyph) in table {
            while rest >= value {
                out += glyph
                rest -= value
            }
        }
        return out.isEmpty ? "\(number)" : out
    }

    static func spelled(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        formatter.locale = Locale(identifier: "en_GB")
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    /// "Volume I · The Grammar of Truth, Sets & Number Architecture" becomes
    /// ("The Grammar of Truth", "Sets & Number Architecture"). A title with no comma or colon keeps
    /// its whole name, and the topics line falls back to the volume's first chapter title.
    static func volumeName(_ volume: PatternedWorldVolume, chapters: [PatternedWorldChapter]) -> (name: String, topics: String) {
        var title = volume.title
        if let dot = title.range(of: " · ") {
            title = String(title[dot.upperBound...])
        }
        for separator in [": ", ", "] {
            if let cut = title.range(of: separator) {
                return (String(title[..<cut.lowerBound]), String(title[cut.upperBound...]))
            }
        }
        let first = chapters.first { $0.volumeNumber == volume.number }?.title ?? ""
        return (title, first)
    }

    static func chapterRange(_ volume: PatternedWorldVolume) -> String {
        guard let first = volume.chapters.first, let last = volume.chapters.last else { return "" }
        return first == last ? "Ch \(first)" : "Ch \(first)–\(last)"
    }

    /// A section heading without its "1.2 " code, since the page numbers steps itself.
    static func stripCode(_ heading: String) -> String {
        let parts = heading.split(separator: " ", maxSplits: 1)
        guard parts.count == 2, parts[0].contains("."), parts[0].allSatisfy({ $0.isNumber || $0 == "." }) else {
            return heading
        }
        return String(parts[1])
    }

    /// A heading for the contents list: no code, and no bracketed aside.
    static func shortHeading(_ heading: String) -> String {
        let plain = stripCode(heading)
        guard let open = plain.range(of: " ("), plain.hasSuffix(")") else { return plain }
        return String(plain[..<open.lowerBound])
    }

    /// Marks the formula's terms in a sentence with their Byrne roles, so a word takes the colour
    /// of the part of the figure it names. Terms coloured green in the data have no Byrne role and
    /// stay plain.
    static func byrneMarked(_ text: String, terms: [FormulaTermMapping]) -> String {
        var out = text
        for term in terms where term.symbol.count > 1 {
            guard let tag = byrneTag(term.colorRole),
                  let range = out.range(of: term.symbol),
                  !out[..<range.lowerBound].hasSuffix(":") else { continue }
            out.replaceSubrange(range, with: "{\(tag):\(term.symbol)}")
        }
        return out
    }

    static func byrneTag(_ colorRole: String) -> String? {
        switch colorRole {
        case "red": "red"
        case "blue": "blue"
        case "amber", "yellow": "yellow"
        default: nil
        }
    }

    /// The reader's most recent words in a chapter, for the handwritten margin note. Placeholder
    /// texts saved when a box was left empty are skipped.
    static func latestOwnWords(in chapters: Set<Int>, responses: [String: CalloutResponseRecord]) -> String? {
        let placeholders: Set<String> = ["Verified beat reasoning", "Locked prediction", "Verified checkpoint"]
        return responses.values
            .filter { chapters.contains($0.chapterNumber) && !$0.id.hasPrefix("debate-") }
            .filter { !placeholders.contains($0.responseText) && !$0.responseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .max { $0.updatedAt < $1.updatedAt }?
            .responseText
    }

    // MARK: - Canonical KymBookKit Manifest, Comic Bookends & ChapterSpec Bridge

    static func bookManifest(chaptersCount: Int = 21, learnerName: String = "Kym") -> BookManifest {
        BookManifest(
            bookID: "kym-patterned-maths",
            buildHash: "v1-patterned-\(chaptersCount)",
            slug: "kym_patterned_maths",
            title: "The Patterned World",
            subtitle: "Five volumes · Twenty-one chapters",
            archetype: .patternedPractice,
            primaryLearnerName: learnerName,
            tutorProfile: CodableTutorProfileSpec(
                appName: "KymMaths",
                subjectLabel: "Mathematics"
            )
        )
    }

    static func misconceptionSpec(for chapter: PatternedWorldChapter) -> MisconceptionSpec {
        let bridge = chapter.intuitionToFormula
        if let debate = chapter.debate {
            let wrongChoice = debate.choices.first(where: { !$0.isCorrect })
            let buggy = wrongChoice?.reasoningStatement ?? debate.speakerAClaim
            let rebuttal = wrongChoice?.socraticRebuttal ?? debate.invariantTakeaway
            return MisconceptionSpec(
                id: "misc-\(chapter.id)",
                title: debate.title,
                buggyRule: buggy,
                coherentWorldRule: bridge.ahaInvariant,
                refutationAnchor: "\(rebuttal) \(debate.invariantTakeaway)"
            )
        }
        let trapBody = chapter.callouts.first(where: { $0.kind == "careful" })?.body
            ?? "Changing surface numbers without checking what stays fixed."
        return MisconceptionSpec(
            id: "misc-\(chapter.id)",
            title: "Common slip in \(chapter.title)",
            buggyRule: trapBody,
            coherentWorldRule: bridge.ahaInvariant,
            refutationAnchor: bridge.concreteAction
        )
    }

    static func openerStrip(for chapter: PatternedWorldChapter, manifest: BookManifest) -> ComicStripSpec {
        let ordinal = max(1, chapter.number + 1)
        let setting = BookKitComicWorldBible.setting(forChapterOrdinal: ordinal)
        let terms = chapter.intuitionToFormula.termMappings
        let actionRich = byrneMarked(chapter.intuitionToFormula.concreteAction, terms: terms)
        let hookRich = byrneMarked(chapter.hookSummary, terms: terms)
        return ComicStripSpec(
            id: "\(chapter.id)-opener",
            role: .chapterOpener,
            title: "Chapter \(chapter.number) · \(setting.dateline)",
            panels: [
                ComicPanelSpec(
                    id: "\(chapter.id)-opener-p1",
                    panelNumber: 1,
                    span: .wide,
                    captionRich: "At \(setting.dateline): Master Bento sets up the workbench for {stays:\(chapter.title)} — \(actionRich)",
                    balloon: ComicBalloonSpec(
                        speaker: "Director Barnaby · Jargon Desk",
                        textRich: "To save time on \(chapter.title), let us simply scale {moves:the changing numbers} by memo without checking {stays:what stays fixed}.",
                        tailDirection: .bottomLeft,
                        sourceBasis: .thoughtExperiment
                    ),
                    scenePreset: .anomalySetup,
                    calloutLabel: "Ch \(chapter.number) setup"
                ),
                ComicPanelSpec(
                    id: "\(chapter.id)-opener-p2",
                    panelNumber: 2,
                    span: .half,
                    captionRich: "One second before Dash pulls the What-If Counterfactual Lever: a tempting shortcut splits from reality as soon as Kym tests the boundary case.",
                    balloon: ComicBalloonSpec(
                        speaker: "\(manifest.primaryLearnerName) & Dr. Zeta",
                        textRich: hookRich,
                        tailDirection: .bottomRight,
                        sourceBasis: .thoughtExperiment
                    ),
                    scenePreset: .intuitionBreak,
                    calloutLabel: "Wonder handoff"
                )
            ]
        )
    }

    static func closerStrip(
        for chapter: PatternedWorldChapter,
        manifest: BookManifest,
        nextChapterTitle: String? = nil
    ) -> ComicStripSpec {
        let terms = chapter.intuitionToFormula.termMappings
        let invariantRich = byrneMarked(chapter.intuitionToFormula.ahaInvariant, terms: terms)
        let misc = misconceptionSpec(for: chapter)
        let nextLabel = nextChapterTitle ?? chapter.skillCard?.unlocks.first ?? "Further chapters"
        return ComicStripSpec(
            id: "\(chapter.id)-closer",
            role: .chapterCloser,
            title: "Chapter \(chapter.number) Resolution · Back at the Atelier",
            panels: [
                ComicPanelSpec(
                    id: "\(chapter.id)-closer-p1",
                    panelNumber: 1,
                    span: .third,
                    captionRich: "Master Bento's X-Ray Loupe: \(invariantRich)",
                    balloon: nil,
                    scenePreset: .xrayMechanism,
                    calloutLabel: "Settled invariant"
                ),
                ComicPanelSpec(
                    id: "\(chapter.id)-closer-p2",
                    panelNumber: 2,
                    span: .third,
                    captionRich: "Dash & Director Barnaby's shortcut foiled: \(misc.refutationAnchor)",
                    balloon: ComicBalloonSpec(
                        speaker: "Dash · Wait a Minute",
                        textRich: "So the universe refuses to read Barnaby's flip-chart — only {stays:\(chapter.intuitionToFormula.formulaDisplay)} holds at both extremes.",
                        tailDirection: .bottomLeft,
                        sourceBasis: .thoughtExperiment
                    ),
                    scenePreset: .misconceptionTrap,
                    calloutLabel: "Trap defeated"
                ),
                ComicPanelSpec(
                    id: "\(chapter.id)-closer-p3",
                    panelNumber: 3,
                    span: .third,
                    captionRich: "What this unlocks next: carry {given:\(chapter.title)} forward into {moves:\(nextLabel)}.",
                    balloon: ComicBalloonSpec(
                        speaker: "Clara · Next Horizon",
                        textRich: "Next up in our field notebook: {given:\(nextLabel)}.",
                        tailDirection: .bottomRight,
                        sourceBasis: .documentedFact
                    ),
                    scenePreset: .nextHorizon,
                    calloutLabel: "Unlocks next"
                )
            ]
        )
    }

    static func chapterSpec(
        for chapter: PatternedWorldChapter,
        manifest: BookManifest,
        nextChapterTitle: String? = nil
    ) -> ChapterSpec {
        let terms = chapter.intuitionToFormula.termMappings
        let standsOn = chapter.skillCard?.standsOn ?? []
        let unlocks = chapter.skillCard?.unlocks ?? []
        let notation = [chapter.intuitionToFormula.formulaDisplay] + terms.map(\.symbol)
        let symbolExport = ChapterSymbolExport(
            chapterID: chapter.id,
            definedTerms: chapter.keyTerms,
            notation: notation,
            chainUnlocks: unlocks
        )
        let blocks: [BlockSpec] = [
            BlockSpec(
                id: "\(chapter.id)-key",
                chapterID: chapter.id,
                ordinal: 1,
                kind: .keyIdea,
                bodyRich: byrneMarked(chapter.intuitionToFormula.ahaInvariant, terms: terms)
            ),
            BlockSpec(
                id: "\(chapter.id)-eq",
                chapterID: chapter.id,
                ordinal: 2,
                kind: .equation,
                bodyRich: byrneMarked(chapter.intuitionToFormula.formulaDisplay, terms: terms)
            ),
            BlockSpec(
                id: "\(chapter.id)-action",
                chapterID: chapter.id,
                ordinal: 3,
                kind: .prose,
                bodyRich: byrneMarked(chapter.intuitionToFormula.concreteAction, terms: terms)
            )
        ]
        let placeholderQuestion = QuestionSpec(
            id: "\(chapter.id)-q1",
            lineageID: "\(chapter.id)-lineage-q1",
            chapterID: chapter.id,
            skillID: "\(chapter.id)-skill",
            role: .independent,
            stemRich: chapter.skillCard?.sheCan.prompt ?? chapter.hookSummary,
            answerSpec: .exactSTEM(
                canonical: chapter.skillCard?.sheCan.answer ?? "1",
                unit: nil,
                variable: nil,
                tolerance: 0.01
            )
        )
        let mentorRoom = MentorRoomSpec(
            id: "\(chapter.id)-mentor",
            chapterID: chapter.id,
            kind: .teachback,
            preparePromptRich: byrneMarked(chapter.intuitionToFormula.concreteAction, terms: terms),
            openingQuestion: chapter.hookSummary,
            objectives: [
                RoomObjectiveSpec(
                    id: "\(chapter.id)-obj-1",
                    description: chapter.intuitionToFormula.ahaInvariant,
                    requiredConcepts: Array(chapter.keyTerms.prefix(3))
                )
            ],
            offlineSpotTheFlawQuestion: placeholderQuestion
        )
        let stage = StageSpec.barOrAreaModel(
            BarAreaModelSpec(
                title: chapter.title,
                givenLabel: "Given",
                givenValue: 1.0,
                staysLabel: chapter.intuitionToFormula.formulaDisplay,
                movesLabel: "Changes",
                minMoves: 0.0,
                maxMoves: 10.0,
                initialMoves: 2.0,
                targetProductOrSum: 2.0
            )
        )
        return ChapterSpec(
            id: chapter.id,
            ordinal: max(1, chapter.number + 1),
            kicker: "CHAPTER \(chapter.number)",
            title: chapter.title,
            wonderQuestion: byrneMarked(chapter.hookSummary, terms: terms),
            standsOn: standsOn,
            unlocks: unlocks,
            symbolExport: symbolExport,
            blocks: blocks,
            stageID: "\(chapter.id)-stage",
            stage: stage,
            questions: [placeholderQuestion],
            mentorRoom: mentorRoom,
            openerStrip: openerStrip(for: chapter, manifest: manifest),
            closerStrip: closerStrip(for: chapter, manifest: manifest, nextChapterTitle: nextChapterTitle)
        )
    }
}

// MARK: - Where a chapter stands

enum ChapterStanding: Equatable {
    case read
    case reading(step: Int?)
    case next
    case later(standsOn: Int)

    static func of(
        _ chapter: PatternedWorldChapter,
        in visible: [PatternedWorldChapter],
        progress: [Int: ChapterReadingProgressRecord]
    ) -> ChapterStanding {
        let fraction = progress[chapter.number]?.readFraction ?? 0
        if fraction >= 0.9 { return .read }
        if fraction > 0 {
            let steps = ChapterInteractiveBeatEngine.beats(for: chapter).count
            let step = Int((fraction * Double(steps)).rounded())
            return .reading(step: step > 0 ? step : nil)
        }
        let firstOpen = visible.first { (progress[$0.number]?.readFraction ?? 0) < 0.9 }
        if firstOpen?.number == chapter.number { return .next }
        return .later(standsOn: max(0, chapter.number - 1))
    }

    @ViewBuilder func tag(chapter: Int) -> some View {
        switch self {
        case .read: StatusTag(.proven, label: "Read")
        case .reading(let step):
            StatusTag(.working, label: step.map { "Reading · \(chapter).\($0)" } ?? "Reading")
        case .next: StatusTag(.notStarted, label: "Next")
        case .later(let standsOn): StatusTag(.notStarted, label: "Stands on Ch \(standsOn)")
        }
    }
}

// MARK: - A chapter's steps: See, Notice, Write, Prove

/// The four stages a chapter moves through, shown at the top of the page. Each step of the
/// chapter belongs to one of them by its kind.
enum ChapterStage: Int, CaseIterable {
    case see, notice, write, prove

    var title: String {
        switch self {
        case .see: "See"
        case .notice: "Notice"
        case .write: "Write"
        case .prove: "Prove"
        }
    }

    init(_ kind: ChapterInteractiveBeatKind) {
        switch kind {
        case .everydayHook: self = .see
        case .proseInsight, .calloutGate: self = .notice
        case .interactiveLabAndFormula: self = .write
        case .misconceptionDebate, .chapterSynthesis: self = .prove
        }
    }
}

extension ChapterInteractiveBeat {
    /// A short, plain name for the step, used in the contents list and above its heading.
    var plainLabel: String {
        switch kind {
        case .everydayHook: "The big idea"
        case .proseInsight, .calloutGate: PatternedBook.shortHeading(title)
        case .interactiveLabAndFormula: "From picture to formula"
        case .misconceptionDebate: "Who is right?"
        case .chapterSynthesis: "Putting it together"
        }
    }

    func code(chapter: Int) -> String { "\(chapter).\(index + 1)" }
}

// MARK: - Buttons

/// The chapter's main action: filled ink when it is the one thing to do now, otherwise an outline.
/// Screens pass `filled: true` to one action at a time, so a page never shows two filled buttons.
struct ChapterActionStyle: ButtonStyle {
    var filled: Bool

    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        if filled {
            InkButtonStyle().makeBody(configuration: configuration)
        } else {
            OutlineButtonStyle().makeBody(configuration: configuration)
        }
    }
}

// MARK: - Layout

/// Reading text with its margin beside it, sized for the room's detail column. The kit's
/// `ReadingSpread` wants about 820 pt; an iPad in portrait with the sidebar open gives the room
/// about 700, so this spread lets the text column shrink to a 440 pt measure before the margin
/// drops below. Candidate to fold into `ReadingSpread` as a narrower threshold.
struct BookSpread<Main: View, Margin: View>: View {
    let width: CGFloat
    private let main: Main
    private let margin: Margin

    static var minMeasure: CGFloat { 440 }
    static var measure: CGFloat { 620 }
    static var marginWidth: CGFloat { 230 }
    static var gap: CGFloat { StandardSpacing.xl }
    static func fitsSideBySide(_ width: CGFloat) -> Bool {
        width >= minMeasure + gap + marginWidth
    }

    init(width: CGFloat, @ViewBuilder main: () -> Main, @ViewBuilder margin: () -> Margin) {
        self.width = width
        self.main = main()
        self.margin = margin()
    }

    var body: some View {
        if Self.fitsSideBySide(width) {
            HStack(alignment: .top, spacing: Self.gap) {
                main.frame(maxWidth: Self.measure, alignment: .leading)
                VStack(alignment: .leading, spacing: StandardSpacing.lg) { margin }
                    .frame(width: Self.marginWidth, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: StandardSpacing.lg) {
                main
                VStack(alignment: .leading, spacing: StandardSpacing.md) { margin }
            }
        }
    }
}

// MARK: - The stage, as a figure

/// The interactive stage hosted in the web view, framed as a figure in the reading column with
/// its caption and a link to fold it away.
struct ChapterFigure: View {
    @Environment(\.standardTheme) private var theme
    let chapter: PatternedWorldChapter
    @Binding var isShown: Bool
    var highlightedColorRole: String?
    var onTermHighlighted: (String, String) -> Void
    @Bindable var store: AppStore
    /// Grows to the figure's own height once the page reports it.
    @State private var stageHeight: CGFloat = 600

    var body: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            if isShown {
                PatternedWorldWebStageView(
                    chapterNumber: chapter.number,
                    atlasRoute: chapter.intuitionToFormula.atlasFigureRef,
                    highlightedColorRole: highlightedColorRole,
                    onTermHighlighted: onTermHighlighted,
                    onContentHeight: { stageHeight = max(320, $0) },
                    store: store
                )
                .frame(height: stageHeight)
                .clipShape(RoundedRectangle(cornerRadius: StandardRadius.xl, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: StandardRadius.xl, style: .continuous)
                        .strokeBorder(theme.hairline(), lineWidth: 1)
                )
                Text("Figure \(chapter.number) · Move the sliders and watch what changes and what stays the same.")
                    .patternedType(.readingSmall)
                    .foregroundStyle(theme.mute(theme.ink))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button(isShown ? "Fold the figure away" : "Open the figure") {
                isShown.toggle()
            }
            .buttonStyle(TextLinkButtonStyle(arrow: false))
        }
    }
}

// MARK: - The skill card

/// The chapter's first screen says what she will be able to do afterwards: the skill, one check to
/// try with the device off (its answer behind a tap), why it matters and what it stands on. A
/// chapter no school unit teaches says so first.
struct SkillCardPanel: View {
    @Environment(\.standardTheme) private var theme
    let card: ChapterSkillCard?
    let beyondSchoolLine: String?
    var linksConcepts = false

    @State private var showsAnswer = false

    var body: some View {
        if card != nil || beyondSchoolLine != nil {
            VStack(alignment: .leading, spacing: StandardSpacing.md) {
                if let beyondSchoolLine {
                    prose(beyondSchoolLine)
                }
                if let card {
                    VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                        Kicker("After this chapter you can")
                        Text(card.skill)
                            .standardType(.headlineSm)
                            .foregroundStyle(theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    part("Try it with the device off") {
                        prose(card.sheCan.prompt)
                        if showsAnswer {
                            prose(card.sheCan.answer)
                        }
                        Button(showsAnswer ? "Hide the answer" : "Show the answer") {
                            showsAnswer.toggle()
                        }
                        .buttonStyle(TextLinkButtonStyle(arrow: false))
                    }
                    part("Why it matters") { prose(card.whyItMatters) }
                    if !card.standsOn.isEmpty {
                        part("It stands on") {
                            ForEach(card.standsOn, id: \.self) { prose($0) }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .paperCard(padding: StandardSpacing.md)
        }
    }

    private func part<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            Kicker(title, muted: true)
            content()
        }
    }

    private func prose(_ text: String) -> some View {
        ConceptText(text, linking: linksConcepts)
            .patternedType(.readingDefault)
            .foregroundStyle(theme.ink)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Your turn

/// The reader's turn before the page goes on: the question, a box in their own words, and the
/// button that saves it.
struct YourTurnCard: View {
    @Environment(\.standardTheme) private var theme
    let callout: PatternedWorldCallout
    @Binding var text: String
    let isSaved: Bool
    let isPrimary: Bool
    var linksConcepts = false
    let save: () -> Void

    private var isPrediction: Bool { callout.kind == "predict" }

    /// For a check's box in either reading mode. It names no kind of answer, because the checks ask
    /// different things: what went wrong, why two numbers are the same, why a share is not a half.
    static let answerPlaceholder = "Write your answer in your own words…"

    var body: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    Kicker(isPrediction ? "Your turn, before you read on" : "Your turn, check your thinking")
                    Spacer(minLength: StandardSpacing.sm)
                    note
                }
                VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                    Kicker(isPrediction ? "Your turn, before you read on" : "Your turn, check your thinking")
                    note
                }
            }
            ConceptText(callout.body, linking: linksConcepts)
                .patternedType(.readingDefault)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            LearnerTextInput(
                title: "",
                placeholder: isPrediction ? "Write what you think will happen…" : Self.answerPlaceholder,
                text: $text,
                minHeight: 64
            )
            HStack(spacing: StandardSpacing.sm) {
                if isSaved {
                    StatusTag(.working, label: "Saved in your words")
                }
                Spacer(minLength: 0)
                Button(isPrediction ? "Lock my prediction" : "Save my answer", action: save)
                    .buttonStyle(ChapterActionStyle(filled: isPrimary))
            }
        }
        .paperCard()
    }

    private var note: some View {
        Text("Your own words count. Nobody marks this.")
            .standardType(.uiCaption)
            .foregroundStyle(theme.mute(theme.ink))
    }
}

// MARK: - Volume pictures

/// A small figure for each volume, drawn in Byrne's colours: two sets, a bar model, a triangle in a
/// circle, a histogram under its curve, and a pair of vectors.
struct VolumeFigure: View {
    @Environment(\.standardTheme) private var theme
    let volume: Int

    var body: some View {
        let p = theme.patterned
        let red = p.color(.moves), yellow = p.color(.stays), blue = p.color(.given)
        Canvas { context, size in
            let w = size.width, h = size.height
            let line = theme.ink
            let dotTint = theme.faint(theme.ink).opacity(0.28)
            var gx: CGFloat = 10
            while gx < w {
                var gy: CGFloat = 8
                while gy < h {
                    context.fill(Path(ellipseIn: CGRect(x: gx, y: gy, width: 1.4, height: 1.4)), with: .color(dotTint))
                    gy += 14
                }
                gx += 14
            }
            switch volume {
            case 1:
                let r = h * 0.36
                let a = CGRect(x: w * 0.5 - r * 1.55, y: h * 0.5 - r, width: r * 2, height: r * 2)
                let b = CGRect(x: w * 0.5 - r * 0.45, y: h * 0.5 - r, width: r * 2, height: r * 2)
                context.fill(Path(ellipseIn: a), with: .color(p.wash(.moves)))
                context.stroke(Path(ellipseIn: a), with: .color(red), lineWidth: 2)
                context.fill(Path(ellipseIn: b), with: .color(p.wash(.given).opacity(0.9)))
                context.stroke(Path(ellipseIn: b), with: .color(blue), lineWidth: 2.5)
            case 2:
                let x = w * 0.08, bw = w * 0.84, bh = h * 0.17
                context.fill(Path(CGRect(x: x, y: h * 0.12, width: bw, height: bh)), with: .color(yellow))
                context.fill(Path(CGRect(x: x, y: h * 0.4, width: bw * 0.66, height: bh)), with: .color(red))
                context.fill(Path(CGRect(x: x + bw * 0.66, y: h * 0.4, width: bw * 0.34, height: bh)), with: .color(blue))
                context.stroke(Path(CGRect(x: x, y: h * 0.7, width: bw * 0.32, height: bh)), with: .color(line), lineWidth: 1.5)
            case 3:
                let r = h * 0.42
                let c = CGPoint(x: w / 2, y: h / 2)
                var tri = Path()
                tri.move(to: CGPoint(x: c.x, y: c.y - r))
                tri.addLine(to: CGPoint(x: c.x + r * 0.866, y: c.y + r * 0.5))
                tri.addLine(to: CGPoint(x: c.x - r * 0.866, y: c.y + r * 0.5))
                tri.closeSubpath()
                context.fill(tri, with: .color(red))
                context.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)), with: .color(blue), lineWidth: 2.5)
                context.fill(Path(ellipseIn: CGRect(x: c.x - 3.5, y: c.y + r * 0.1 - 3.5, width: 7, height: 7)), with: .color(yellow))
            case 4:
                let heights: [CGFloat] = [0.3, 0.62, 0.86, 0.72, 0.42, 0.16]
                let base = h * 0.92, bw = w * 0.84 / CGFloat(heights.count), x0 = w * 0.08
                for (i, v) in heights.enumerated() {
                    let rect = CGRect(x: x0 + CGFloat(i) * bw, y: base - h * 0.8 * v, width: bw - 2, height: h * 0.8 * v)
                    context.fill(Path(rect), with: .color(blue))
                }
                var curve = Path()
                for step in 0...40 {
                    let t = CGFloat(step) / 40
                    let gx = (t - 0.47) / 0.17
                    let y = base - h * 0.88 * exp(-0.5 * gx * gx)
                    let pt = CGPoint(x: x0 - bw * 0.2 + t * (w * 0.84 + bw * 0.4), y: y)
                    if step == 0 { curve.move(to: pt) } else { curve.addLine(to: pt) }
                }
                context.stroke(curve, with: .color(red), lineWidth: 2)
            default:
                let o = CGPoint(x: w * 0.1, y: h * 0.9)
                let a = CGPoint(x: w * 0.3, y: h * 0.3)
                let b = CGPoint(x: w * 0.62, y: h * 0.72)
                var para = Path()
                para.move(to: o)
                para.addLine(to: a)
                para.addLine(to: CGPoint(x: a.x + b.x - o.x, y: a.y + b.y - o.y))
                para.addLine(to: b)
                para.closeSubpath()
                context.fill(para, with: .color(p.wash(.stays)))
                context.stroke(Path { $0.move(to: o); $0.addLine(to: a) }, with: .color(blue), lineWidth: 2.5)
                context.stroke(Path { $0.move(to: o); $0.addLine(to: b) }, with: .color(red), lineWidth: 2.5)
                context.fill(Path(ellipseIn: CGRect(x: o.x - 3.5, y: o.y - 3.5, width: 7, height: 7)), with: .color(line))
            }
        }
        .accessibilityHidden(true)
    }
}
