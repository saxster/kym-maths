import SwiftUI

/// The Figma text styles that The Standard's roles do not cover, on faces every Apple device has:
/// New York for Newsreader and STIX, SF for Inter, Bradley Hand for Caveat. Sizes follow Dynamic
/// Type from their text style. Room titles, headings and chrome keep using `.standardType(_:)`.
enum PatternedType: CaseIterable, Sendable {
    /// A chapter's opening title (60/64).
    case chapterDisplay
    /// Reading text in a chapter (19/30).
    case reading
    /// Reading text in a card (16/25).
    case readingDefault
    /// Figure captions and small reading text (14/21).
    case readingSmall
    /// A wonder question, italic (22/31).
    case question
    /// A numbered sidenote or history note in the margin (13/19).
    case sidenote
    /// The reader's own handwriting (21/24).
    case hand
    /// A displayed formula (30/38).
    case mathDisplay
    /// A formula inside a sentence, italic (19/30).
    case mathInline
    /// A small caps kicker above a heading (11/14, tracked).
    case kicker
    /// A big count, such as "4 cards" (28/32).
    case numeral

    var size: CGFloat {
        switch self {
        case .chapterDisplay: 60
        case .reading, .mathInline: 19
        case .readingDefault: 16
        case .readingSmall: 14
        case .question: 22
        case .sidenote: 13
        case .hand: 21
        case .mathDisplay: 30
        case .kicker: 11
        case .numeral: 28
        }
    }

    var lineHeight: CGFloat {
        switch self {
        case .chapterDisplay: 64
        case .reading, .mathInline: 30
        case .readingDefault: 25
        case .readingSmall: 21
        case .question: 31
        case .sidenote: 19
        case .hand: 24
        case .mathDisplay: 38
        case .kicker: 14
        case .numeral: 32
        }
    }

    var textStyle: Font.TextStyle {
        switch self {
        case .chapterDisplay: .largeTitle
        case .reading, .mathInline, .readingDefault, .hand: .body
        case .readingSmall, .sidenote: .footnote
        case .question, .mathDisplay, .numeral: .title2
        case .kicker: .caption2
        }
    }

    var tracking: CGFloat {
        switch self {
        case .chapterDisplay: -1.5
        case .kicker: 1.3
        case .numeral: -0.5
        default: 0
        }
    }

    func font(size: CGFloat) -> Font {
        switch self {
        case .hand:
            .custom("Bradley Hand", size: size)
        case .question, .mathInline:
            .system(size: size, weight: .regular, design: .serif).italic()
        case .kicker, .numeral:
            .system(size: size, weight: .semibold, design: .default)
        default:
            .system(size: size, weight: .regular, design: .serif)
        }
    }
}

extension View {
    /// Applies a Patterned text style: face, Dynamic Type size, line height and tracking.
    func patternedType(_ style: PatternedType) -> some View {
        modifier(PatternedTypeModifier(style: style))
    }
}

private struct PatternedTypeModifier: ViewModifier {
    let style: PatternedType
    @ScaledMetric private var size: CGFloat

    init(style: PatternedType) {
        self.style = style
        _size = ScaledMetric(wrappedValue: style.size, relativeTo: style.textStyle)
    }

    func body(content: Content) -> some View {
        let scale = size / style.size
        content
            .font(style.font(size: size))
            .tracking(style.tracking)
            .lineSpacing(max(0, (style.lineHeight - style.size * 1.2) * scale))
            .textCase(style == .kicker ? .uppercase : nil)
    }
}
