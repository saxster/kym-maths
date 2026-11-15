import SwiftUI

/// Colour-linked prose. A writer marks the words that name a maths object with its Byrne role, and
/// the words take the same colour as the object in the figure:
/// `"Put {blue:an arrow} on the line. Multiplying by −1 {red:turns the arrow around}."`
/// Tags are `red`/`moves`, `yellow`/`stays` and `blue`/`given`. Unknown tags and unclosed braces
/// stay as plain text.
enum ByrneMarkup {
    struct Run: Equatable, Sendable {
        let text: String
        let role: ByrneRole?
    }

    static func parse(_ source: String) -> [Run] {
        var runs: [Run] = []
        var plain = ""
        var rest = Substring(source)
        while let open = rest.firstIndex(of: "{") {
            plain += rest[..<open]
            let tail = rest[rest.index(after: open)...]
            guard let colon = tail.firstIndex(of: ":"),
                  let close = tail.firstIndex(of: "}"),
                  colon < close,
                  let role = ByrneRole(markup: String(tail[..<colon]))
            else {
                plain.append("{")
                rest = tail
                continue
            }
            if !plain.isEmpty { runs.append(Run(text: plain, role: nil)) }
            plain = ""
            runs.append(Run(text: String(tail[tail.index(after: colon)..<close]), role: role))
            rest = tail[tail.index(after: close)...]
        }
        plain += rest
        if !plain.isEmpty { runs.append(Run(text: plain, role: nil)) }
        return runs
    }

    /// The text with its marked runs coloured. Red and blue words take their colour; yellow words,
    /// too pale to read as type, keep the ink colour on a yellow wash.
    static func attributed(_ source: String, palette: PatternedPalette) -> AttributedString {
        var result = AttributedString()
        for run in parse(source) {
            var piece = AttributedString(run.text)
            switch run.role {
            case .stays?:
                piece.backgroundColor = palette.wash(.stays)
            case let role?:
                piece.foregroundColor = palette.color(role)
            case nil:
                break
            }
            result += piece
        }
        return result
    }

    /// The text with the markup removed, for accessibility labels and search.
    static func plain(_ source: String) -> String {
        parse(source).map(\.text).joined()
    }
}

/// A `Text` from Byrne markup, coloured for the active theme.
struct ByrneText: View {
    @Environment(\.standardTheme) private var theme
    private let source: String

    init(_ source: String) {
        self.source = source
    }

    var body: some View {
        Text(ByrneMarkup.attributed(source, palette: theme.patterned))
    }
}
