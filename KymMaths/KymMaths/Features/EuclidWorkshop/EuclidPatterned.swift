import SwiftUI

// The Patterned pieces Euclid's Workshop shares between its pages: the page frame, the
// proposition number, status from a skill record, the board tool button, the reason chip and the
// Byrne colours of a construction. Any of these could move to Design/Patterned if another room
// wants it.

// MARK: - Page frame

/// A workshop page: the room header on paper, with an optional way back to the Book I map.
struct EuclidPage<Content: View>: View {
    @Environment(\.standardTheme) private var theme
    @Environment(\.horizontalSizeClass) private var sizeClass
    private let eyebrow: String
    private let title: String
    private let subtitle: String
    private let back: (() -> Void)?
    private let content: Content

    init(eyebrow: String, title: String, subtitle: String, back: (() -> Void)? = nil,
         @ViewBuilder content: () -> Content) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.back = back
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StandardSpacing.lg) {
                VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                    if let back {
                        Button(action: back) {
                            Label("Book I map", systemImage: "chevron.backward")
                        }
                        .buttonStyle(TextLinkButtonStyle(arrow: false))
                        .padding(.top, -StandardSpacing.sm)
                    }
                    EditorialHeader(eyebrow: eyebrow, title: title, subtitle: subtitle)
                        .padding(.bottom, -StandardSpacing.sm)
                }
                content
            }
            .frame(maxWidth: 1120, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, sizeClass == .compact ? StandardSpacing.md : StandardSpacing.xl)
            .padding(.top, StandardSpacing.lg)
            .padding(.bottom, StandardSpacing.xl2)
        }
        .background(theme.bg)
    }
}

/// A section label above a column, with a muted count at its right: "STEPS TO PLACE · 3 left".
struct EuclidColumnLabel: View {
    @Environment(\.standardTheme) private var theme
    let title: String
    var trailing: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Kicker(title, muted: true)
            Spacer(minLength: StandardSpacing.xs)
            if let trailing {
                Text(trailing)
                    .standardType(.uiCaption)
                    .foregroundStyle(theme.mute(theme.ink))
            }
        }
    }
}

// MARK: - Propositions

/// A proposition's number the way the book sets it: italic serif in Byrne red, "I.9". A `size`
/// of 26 or more takes the display size; anything less sits at the inline size.
struct PropositionCode: View {
    @Environment(\.standardTheme) private var theme
    let id: PropositionID
    var size: CGFloat = 18
    var faded = false

    var body: some View {
        Text(id.raw)
            .patternedType(size >= 26 ? .mathDisplay : .mathInline)
            .italic()
            .foregroundStyle(theme.patterned.color(.moves).opacity(faded ? 0.55 : 1))
            .accessibilityLabel("Proposition \(id.raw)")
    }
}

extension EuclidSkillRecord {
    /// How many of the four lamps are lit.
    var litLamps: Int { highest.map { $0.rawValue + 1 } ?? 0 }
}

extension EuclidProposition {
    /// Where a proposition stands for her, for a `StatusTag`.
    func learningStatus(_ progress: EuclidProgress) -> LearningStatus {
        if isAccepted { return .secure }
        let record = progress.record(for: id)
        if !EuclidSpine.needs(id, progress: progress).isEmpty { return .locked }
        switch record.highest {
        case .knowsWhen?: return .secure
        case _?: return .proven
        case nil: return record.assisted ? .withHelp : .notStarted
        }
    }

    /// "School 3.4", from "OUP 3.4 Constructions (ch09)".
    var schoolSection: String? {
        oupSection.map { "School " + $0.dropFirst(4) }
    }
}

extension SkillLevel {
    /// The lamp's name as the reader hears it: "In your head", not "In her head".
    var lampName: String { SkillLamps.names[rawValue] }
}

extension HintLadderRung {
    /// The hint's place on the ladder in plain words, without the ladder's own names.
    var plainTitle: String {
        "Hint \(rawValue)" + (surrendersRetrieval ? " · counts as help" : "")
    }
}

// MARK: - Controls

/// A board tool: icon over a short name, lit in a yellow wash with a brass edge when in hand.
struct EuclidToolButtonStyle: ButtonStyle {
    var isSelected = false

    func makeBody(configuration: Configuration) -> some View {
        EuclidToolButtonBody(configuration: configuration, isSelected: isSelected)
    }
}

private struct EuclidToolButtonBody: View {
    @Environment(\.standardTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    let configuration: ButtonStyleConfiguration
    let isSelected: Bool

    var body: some View {
        configuration.label
            .labelStyle(EuclidToolLabelStyle())
            .foregroundStyle(isSelected ? theme.brass : theme.ink)
            .frame(minWidth: 60, minHeight: StandardAccessibility.touchTarget + 8)
            .padding(.horizontal, StandardSpacing.xxs)
            .background(
                RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                    .fill(isSelected ? theme.patterned.wash(.stays) : (configuration.isPressed ? theme.blank() : .clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                    .strokeBorder(isSelected ? theme.brass : .clear, lineWidth: 1)
            )
            .opacity(isEnabled ? 1 : 0.4)
            .contentShape(Rectangle())
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct EuclidToolLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: StandardSpacing.xxs) {
            configuration.icon
                .standardType(.uiHeadline)
                .frame(height: 20)
            configuration.title
                .standardType(.uiCaption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// A rounded chip for a choice among a few, such as a step's reason or a given in a question.
/// Lit, it fills with ink.
struct EuclidChipStyle: ButtonStyle {
    var isLit = false

    func makeBody(configuration: Configuration) -> some View {
        EuclidChipBody(configuration: configuration, isLit: isLit)
    }
}

private struct EuclidChipBody: View {
    @Environment(\.standardTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    let configuration: ButtonStyleConfiguration
    let isLit: Bool

    var body: some View {
        configuration.label
            .standardType(.uiBody)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(isLit ? theme.bg : theme.ink)
            .padding(.horizontal, StandardSpacing.sm)
            .padding(.vertical, StandardSpacing.xs)
            .frame(minHeight: StandardAccessibility.touchTarget - 8)
            .background(
                RoundedRectangle(cornerRadius: StandardRadius.xl, style: .continuous)
                    .fill(isLit ? theme.ink : (configuration.isPressed ? theme.blank() : theme.surface))
            )
            .overlay(
                RoundedRectangle(cornerRadius: StandardRadius.xl, style: .continuous)
                    .strokeBorder(isLit ? theme.ink : theme.faint(theme.ink), lineWidth: 1)
            )
            .opacity(isEnabled ? 1 : 0.45)
            .contentShape(Rectangle())
    }
}

/// A quiet aside with a brass rule down its left edge.
struct EuclidRuledNote: View {
    @Environment(\.standardTheme) private var theme
    let text: String

    var body: some View {
        Text(text)
            .patternedType(.readingSmall)
            .foregroundStyle(theme.mute(theme.ink))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.leading, StandardSpacing.sm)
            .overlay(alignment: .leading) {
                Rectangle().fill(theme.brass).frame(width: 2)
            }
    }
}

/// A line of feedback with its mark: a refusal, a success, or what the tool waits for.
struct EuclidFeedbackLine: View {
    enum Tone { case info, refusal, success }

    @Environment(\.standardTheme) private var theme
    let tone: Tone
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.xs) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
            Text(text)
                .standardType(.uiBody)
                .foregroundStyle(tone == .info ? theme.mute(theme.ink) : theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var symbol: String {
        switch tone {
        case .info: "hand.point.up.left"
        case .refusal: "exclamationmark.circle"
        case .success: "checkmark.circle"
        }
    }

    private var tint: Color {
        switch tone {
        case .info: theme.mute(theme.ink)
        case .refusal: theme.patterned.assistedColor
        case .success: theme.patterned.provenColor
        }
    }
}

// MARK: - Byrne colours on the board

extension ColorRole {
    /// The Byrne meaning of a board colour: red moves, amber (Byrne's yellow) stays, blue is given.
    var byrneRole: ByrneRole? {
        switch self {
        case .red: .moves
        case .amber: .stays
        case .blue: .given
        case .green, .ink: nil
        }
    }
}

/// The colours a construction is drawn in. A plate is drafting paper in every theme, so the board
/// takes the Paper values of `PatternedPalette`. What the proposition gives you is blue: a given
/// line, and any plain ink line lying along one, draws as given.
struct ByrneBoardColours {
    /// The given segments, end to end, in board units.
    let givenRuns: [(Vec2, Vec2)]

    init(construction: Construction) {
        var named: [String: Vec2] = [:]
        var runs: [(Vec2, Vec2)] = []
        for given in construction.givens {
            switch given {
            case let .point(name, at): named[name] = at
            case let .segment(a, b):
                if let pa = named[a], let pb = named[b] { runs.append((pa, pb)) }
            }
        }
        givenRuns = runs
    }

    static func color(_ role: ColorRole) -> Color {
        if let byrne = role.byrneRole { return PatternedPalette.paper.color(byrne) }
        return role == .green ? PatternedPalette.paper.provenColor : MathsFigureColor.ink
    }

    /// The role a line between `a` and `b` takes: given blue when it is an ink line along a given.
    func role(_ role: ColorRole, from a: Vec2, to b: Vec2) -> ColorRole {
        guard role == .ink, isGiven(from: a, to: b) else { return role }
        return .blue
    }

    func isGiven(from a: Vec2, to b: Vec2) -> Bool {
        givenRuns.contains { run in Self.lies(a, on: run) && Self.lies(b, on: run) }
    }

    private static func lies(_ p: Vec2, on run: (Vec2, Vec2)) -> Bool {
        let along = run.1 - run.0
        let length = along.length
        guard length > 1e-9 else { return false }
        let offset = p - run.0
        let cross = abs(along.x * offset.y - along.y * offset.x) / length
        let t = (along.x * offset.x + along.y * offset.y) / (length * length)
        return cross < 1e-6 && t > -1e-6 && t < 1 + 1e-6
    }
}

extension EuclidWorkshopSession {
    var byrneColours: ByrneBoardColours { ByrneBoardColours(construction: construction) }

    /// The given segments' curves, which the board lays down first.
    var givenCurveCount: Int {
        construction.givens.filter { if case .segment = $0 { true } else { false } }.count
    }

    /// The scripted step she is on and how many there are, for "Step 2 of 4". Nil once solved.
    var scriptStep: (current: Int, total: Int)? {
        let total = script.steps.count
        guard total > 0, !isSolved, let next = script.next(on: board),
              let index = script.steps.firstIndex(where: { $0.action == next.step.action }) else { return nil }
        return (index + 1, total)
    }
}
