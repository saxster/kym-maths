import SwiftUI

// MARK: - Headings and cards

/// A small brass caps label above a heading or a card: "TODAY'S QUESTION", "STANDS ON".
struct Kicker: View {
    @Environment(\.standardTheme) private var theme
    private let text: String
    private let muted: Bool

    init(_ text: String, muted: Bool = false) {
        self.text = text
        self.muted = muted
    }

    var body: some View {
        Text(text)
            .patternedType(.kicker)
            .foregroundStyle(muted ? theme.mute(theme.ink) : theme.brass)
            .accessibilityAddTraits(.isHeader)
    }
}

extension View {
    /// A raised paper card: surface fill, a hairline and soft corners. The page around it stays
    /// quiet, so the card is what the eye finds.
    func paperCard(padding: CGFloat = StandardSpacing.lg) -> some View {
        modifier(PaperCard(padding: padding))
    }
}

private struct PaperCard: ViewModifier {
    @Environment(\.standardTheme) private var theme
    let padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: StandardRadius.xl, style: .continuous)
                    .fill(theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: StandardRadius.xl, style: .continuous)
                    .strokeBorder(theme.hairline(), lineWidth: 1)
            )
    }
}

// MARK: - Wonder and the margin

/// The question a page opens with, before any definition. Accepts Byrne markup.
struct WonderQuestion: View {
    @Environment(\.standardTheme) private var theme
    private let text: String
    private let framed: Bool

    init(_ text: String, framed: Bool = true) {
        self.text = text
        self.framed = framed
    }

    var body: some View {
        if framed {
            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                HStack(spacing: StandardSpacing.xs) {
                    Circle()
                        .fill(theme.patterned.color(.moves))
                        .frame(width: 7, height: 7)
                    Text("WONDER FIRST · THOUGHT EXPERIMENT")
                        .patternedType(.kicker)
                        .foregroundStyle(theme.brass)
                }
                ByrneText(text)
                    .patternedType(.question)
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(StandardSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                    .fill(theme.patterned.wash(.stays).opacity(0.65))
            )
            .overlay(
                RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                    .strokeBorder(theme.brass.opacity(0.32), lineWidth: 1)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel(ByrneMarkup.plain(text))
        } else {
            ByrneText(text)
                .patternedType(.question)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(ByrneMarkup.plain(text))
        }
    }
}

/// The reader's own handwriting, in Byrne blue: a prediction, a note to self.
struct HandNote: View {
    @Environment(\.standardTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
            Text("YOUR OWN WORDS · SKETCH NOTE")
                .patternedType(.kicker)
                .foregroundStyle(theme.patterned.color(.given))
            Text(text)
                .patternedType(.hand)
                .foregroundStyle(theme.patterned.color(.given))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(StandardSpacing.sm + 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                .fill(theme.patterned.wash(.given).opacity(0.45))
        )
        .overlay(
            RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                .strokeBorder(theme.patterned.color(.given).opacity(0.28), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        )
        .overlay(alignment: .top) {
            Capsule()
                .fill(theme.brass.opacity(0.38))
                .frame(width: 44, height: 6)
                .offset(y: -3)
        }
        .rotationEffect(.degrees(reduceMotion ? 0 : -0.55))
    }
}

/// A note in the margin beside reading text.
struct MarginNote: View {
    enum Kind: Equatable {
        /// A numbered aside, like a footnote that sits beside its line.
        case sidenote(Int)
        /// Where the idea came from: "AD 628 · BRAHMAGUPTA".
        case history(String)
        /// The reader's handwriting.
        case hand
    }

    @Environment(\.standardTheme) private var theme
    @State private var isExpanded = false
    private let kind: Kind
    private let text: String

    init(_ kind: Kind, _ text: String) {
        self.kind = kind
        self.text = text
    }

    private var canFold: Bool { text.count > 135 }

    var body: some View {
        switch kind {
        case .sidenote(let number):
            VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.xs) {
                    Text("\(number)")
                        .patternedType(.sidenote)
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.brass)
                    ByrneText(text)
                        .patternedType(.sidenote)
                        .foregroundStyle(theme.mute(theme.ink))
                        .lineLimit(canFold && !isExpanded ? 3 : nil)
                }
                if canFold {
                    Button(isExpanded ? "Fold note ▴" : "In a nutshell ▾") {
                        isExpanded.toggle()
                    }
                    .patternedType(.kicker)
                    .foregroundStyle(theme.brass)
                    .buttonStyle(.plain)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        case .history(let kicker):
            VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                Kicker(kicker)
                ByrneText(text)
                    .patternedType(.sidenote)
                    .foregroundStyle(theme.mute(theme.ink))
                    .lineLimit(canFold && !isExpanded ? 3 : nil)
                    .fixedSize(horizontal: false, vertical: true)
                if canFold {
                    Button(isExpanded ? "Fold note ▴" : "In a nutshell ▾") {
                        isExpanded.toggle()
                    }
                    .patternedType(.kicker)
                    .foregroundStyle(theme.brass)
                    .buttonStyle(.plain)
                }
            }
            .padding(.leading, StandardSpacing.sm)
            .overlay(alignment: .leading) {
                Rectangle().fill(theme.brass).frame(width: 2)
            }
        case .hand:
            HandNote(text)
        }
    }
}

/// Reading text with a margin beside it. With room, the text column keeps a reading measure and
/// the margin sits to its right; without room, the margin notes follow the text.
struct ReadingSpread<Main: View, Margin: View>: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    private let main: Main
    private let margin: Margin

    init(@ViewBuilder main: () -> Main, @ViewBuilder margin: () -> Margin) {
        self.main = main()
        self.margin = margin()
    }

    static var textMeasure: CGFloat { 620 }
    static var marginWidth: CGFloat { 250 }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: StandardSpacing.xl2) {
                main.frame(maxWidth: Self.textMeasure, alignment: .leading)
                VStack(alignment: .leading, spacing: StandardSpacing.lg) { margin }
                    .frame(width: Self.marginWidth, alignment: .leading)
                    .padding(.top, StandardSpacing.xl3)
            }
            .frame(minWidth: Self.textMeasure * 0.85 + Self.marginWidth + StandardSpacing.xl2, alignment: .leading)
            VStack(alignment: .leading, spacing: StandardSpacing.lg) {
                main
                VStack(alignment: .leading, spacing: StandardSpacing.md) { margin }
            }
        }
    }
}

// MARK: - The chain

/// One link in a chain: a chapter, topic or proposition, with a short code ("1.1", "Ch 12", "I.9").
struct ChainLink: Identifiable, Hashable, Sendable {
    let code: String
    let title: String
    var id: String { code + title }
}

/// What this page stands on and what it unlocks.
struct ChainCard: View {
    @Environment(\.standardTheme) private var theme
    private let standsOn: [ChainLink]
    private let unlocks: [ChainLink]
    private let open: ((ChainLink) -> Void)?

    init(standsOn: [ChainLink], unlocks: [ChainLink], open: ((ChainLink) -> Void)? = nil) {
        self.standsOn = standsOn
        self.unlocks = unlocks
        self.open = open
    }

    var body: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.md) {
            HStack(spacing: 6) {
                Circle().fill(theme.patterned.color(.given)).frame(width: 6, height: 6)
                Rectangle().fill(theme.hairline()).frame(height: 1)
                Circle().fill(theme.brass).frame(width: 7, height: 7)
                Rectangle().fill(theme.hairline()).frame(height: 1)
                Circle().fill(theme.patterned.color(.moves)).frame(width: 6, height: 6)
            }
            .accessibilityHidden(true)
            group("Stands on", standsOn, empty: "Nothing yet. This is a first step.")
            group("Unlocks", unlocks, empty: "The end of this road, for now.")
        }
        .paperCard(padding: StandardSpacing.md)
    }

    private func group(_ title: String, _ links: [ChainLink], empty: String) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            Kicker(title, muted: true)
            if links.isEmpty {
                Text(empty)
                    .standardType(.uiBody)
                    .foregroundStyle(theme.mute(theme.ink))
            }
            ForEach(links) { link in
                Button {
                    open?(link)
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.xs) {
                        Text(link.code).foregroundStyle(theme.mute(theme.ink))
                        Text(link.title).foregroundStyle(theme.ink)
                    }
                    .standardType(.uiBody)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(open == nil)
            }
        }
    }
}

// MARK: - Honest progress

/// The four lamps of a skill: with the picture, in letters, in your head, knows when. A lamp is
/// lit only by an unaided answer.
struct SkillLamps: View {
    static let names = ["With the picture", "In letters", "In your head", "Knows when"]

    @Environment(\.standardTheme) private var theme
    private let lit: Int
    private let size: CGFloat

    init(lit: Int, size: CGFloat = 10) {
        self.lit = min(max(lit, 0), Self.names.count)
        self.size = size
    }

    var body: some View {
        HStack(spacing: size * 0.5) {
            ForEach(0..<Self.names.count, id: \.self) { index in
                Circle()
                    .fill(index < lit ? theme.patterned.color(.stays) : Color.clear)
                    .overlay(
                        Circle().strokeBorder(
                            index < lit ? theme.patterned.color(.stays) : theme.faint(theme.ink),
                            lineWidth: 1
                        )
                    )
                    .frame(width: size, height: size)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.accessibilityText(lit: lit))
    }

    static func accessibilityText(lit: Int) -> String {
        guard lit > 0 else { return "No lamps lit yet" }
        return "\(lit) of 4 lamps lit, up to \(names[lit - 1].lowercased())"
    }
}

/// Where a learner stands on one piece of work. With help is never shown as proven.
enum LearningStatus: String, CaseIterable, Sendable {
    case locked, notStarted, working, withHelp, proven, secure

    var label: String {
        switch self {
        case .locked: "Locked"
        case .notStarted: "Not started"
        case .working: "Working on it"
        case .withHelp: "With help"
        case .proven: "Proven"
        case .secure: "Secure"
        }
    }
}

struct StatusTag: View {
    @Environment(\.standardTheme) private var theme
    private let status: LearningStatus
    private let label: String?

    init(_ status: LearningStatus, label: String? = nil) {
        self.status = status
        self.label = label
    }

    var body: some View {
        HStack(spacing: StandardSpacing.xxs + 2) {
            mark
            Text(label ?? status.label)
                .patternedType(.kicker)
                .foregroundStyle(tint)
        }
        .accessibilityElement(children: .combine)
    }

    private var tint: Color {
        let palette = theme.patterned
        return switch status {
        case .locked, .notStarted: theme.mute(theme.ink)
        case .working: palette.color(.given)
        case .withHelp: palette.assistedColor
        case .proven, .secure: palette.provenColor
        }
    }

    @ViewBuilder private var mark: some View {
        switch status {
        case .locked:
            Image(systemName: "lock")
                .imageScale(.small)
                .foregroundStyle(tint)
        case .notStarted:
            Circle().strokeBorder(tint, lineWidth: 1).frame(width: 7, height: 7)
        case .secure:
            Circle().fill(tint).frame(width: 11, height: 11)
        default:
            Circle().fill(tint).frame(width: 7, height: 7)
        }
    }
}

/// A thin bar for how far through something is, such as a test's chapters. It shows practice
/// done, not a mastery score.
struct ProgressRule: View {
    @Environment(\.standardTheme) private var theme
    private let value: Double

    init(_ value: Double) {
        self.value = min(max(value, 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(theme.patterned.sunkColor)
                Capsule().fill(theme.patterned.provenColor)
                    .frame(width: proxy.size.width * value)
            }
        }
        .frame(height: 5)
        .accessibilityElement()
        .accessibilityValue("\(Int((value * 100).rounded())) percent")
    }
}

/// A gate the reader has not reached yet, said kindly: "What stays the same opens after you predict."
struct LockedNote: View {
    @Environment(\.standardTheme) private var theme
    private let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.sm) {
            Image(systemName: "lock")
                .foregroundStyle(theme.brass)
            Text(text)
                .patternedType(.readingSmall)
                .foregroundStyle(theme.mute(theme.ink))
        }
        .padding(.horizontal, StandardSpacing.md)
        .padding(.vertical, StandardSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                .fill(theme.patterned.wash(.stays))
        )
    }
}

// MARK: - A path of steps

/// One step on a short path, such as today's four steps.
struct PathStepRow: View {
    enum State: Equatable { case done, current, upcoming }

    @Environment(\.standardTheme) private var theme
    private let number: Int
    private let title: String
    private let detail: String
    private let minutes: Int?
    private let state: State

    init(number: Int, title: String, detail: String, minutes: Int? = nil, state: State) {
        self.number = number
        self.title = title
        self.detail = detail
        self.minutes = minutes
        self.state = state
    }

    var body: some View {
        HStack(alignment: .center, spacing: StandardSpacing.sm) {
            badge
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .standardType(.uiHeadline)
                    .foregroundStyle(state == .done ? theme.mute(theme.ink) : theme.ink)
                Text(detail)
                    .standardType(.uiBody)
                    .foregroundStyle(theme.mute(theme.ink))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: StandardSpacing.sm)
            if let minutes {
                Text("\(minutes) min")
                    .standardType(.uiCaption)
                    .foregroundStyle(theme.mute(theme.ink))
            }
        }
        .padding(.vertical, StandardSpacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityValue(state == .done ? "Done" : state == .current ? "Next" : "")
    }

    @ViewBuilder private var badge: some View {
        let size: CGFloat = 28
        switch state {
        case .done:
            Circle().fill(theme.patterned.provenColor)
                .overlay(Image(systemName: "checkmark").standardType(.uiCaption).fontWeight(.bold).foregroundStyle(theme.surface))
                .frame(width: size, height: size)
        case .current:
            Circle().fill(theme.ink)
                .overlay(Text("\(number)").standardType(.uiCaption).foregroundStyle(theme.surface))
                .frame(width: size, height: size)
        case .upcoming:
            Circle().strokeBorder(theme.faint(theme.ink), lineWidth: 1)
                .overlay(Text("\(number)").standardType(.uiCaption).foregroundStyle(theme.ink))
                .frame(width: size, height: size)
        }
    }
}

// MARK: - Buttons

/// The one filled action on a screen: ink with page-coloured text. Use it once per screen.
struct InkButtonStyle: ButtonStyle {
    var fullWidth = false

    func makeBody(configuration: Configuration) -> some View {
        InkButtonBody(configuration: configuration, fullWidth: fullWidth)
    }
}

private struct InkButtonBody: View {
    @Environment(\.standardTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    let configuration: ButtonStyleConfiguration
    let fullWidth: Bool

    var body: some View {
        configuration.label
            .standardType(.uiHeadline)
            .foregroundStyle(theme.bg)
            .padding(.horizontal, StandardSpacing.lg)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: StandardAccessibility.touchTarget)
            .background(
                RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                    .fill(theme.ink)
            )
            .opacity(isEnabled ? (configuration.isPressed ? 0.82 : 1) : 0.4)
            .contentShape(Rectangle())
    }
}

/// A secondary action: paper with a hairline. Any number per screen.
struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        OutlineButtonBody(configuration: configuration)
    }
}

private struct OutlineButtonBody: View {
    @Environment(\.standardTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    let configuration: ButtonStyleConfiguration

    var body: some View {
        configuration.label
            .standardType(.uiBody)
            .fontWeight(.semibold)
            .foregroundStyle(theme.ink)
            .padding(.horizontal, StandardSpacing.md)
            // Keeps a label that wraps to two lines off the borders; one line still fits the min height.
            .padding(.vertical, StandardSpacing.xxs)
            .frame(minHeight: StandardAccessibility.touchTarget - 8)
            .background(
                RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                    .fill(configuration.isPressed ? theme.blank() : theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                    .strokeBorder(theme.hairline(), lineWidth: 1)
            )
            .opacity(isEnabled ? 1 : 0.4)
            .contentShape(Rectangle())
    }
}

/// A brass text link that moves the reader on: "Read the chapter →".
struct TextLinkButtonStyle: ButtonStyle {
    var arrow = true

    func makeBody(configuration: Configuration) -> some View {
        TextLinkBody(configuration: configuration, arrow: arrow)
    }
}

private struct TextLinkBody: View {
    @Environment(\.standardTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    let configuration: ButtonStyleConfiguration
    let arrow: Bool

    var body: some View {
        HStack(spacing: StandardSpacing.xs) {
            configuration.label
            if arrow { Image(systemName: "arrow.right").imageScale(.small) }
        }
        .standardType(.uiHeadline)
        .foregroundStyle(theme.brass)
        .opacity(isEnabled ? (configuration.isPressed ? 0.6 : 1) : 0.4)
        .frame(minHeight: StandardAccessibility.touchTarget)
        .contentShape(Rectangle())
    }
}
