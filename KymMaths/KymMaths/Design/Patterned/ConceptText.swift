import SwiftUI

/// Byrne-marked prose whose concept names link to their cards (`kymconcept://<id>`). A link reads as
/// ink, or as its Byrne colour on a coloured term, over a brass underline. `.conceptLinks()` above it
/// decides what a tap opens.
struct ConceptText: View {
    @Environment(\.standardTheme) private var theme
    @Environment(\.conceptLibrary) private var library
    private let source: String
    private let exclude: String?
    private let linked: Set<String>
    private let linking: Bool

    /// `exclude` is the card being read, which never links to itself; `linked` holds the concepts
    /// already linked earlier in the same scope, which link once. With `linking` off it draws as
    /// `ByrneText` does.
    init(_ source: String, exclude: String? = nil, linked: Set<String> = [], linking: Bool = true) {
        self.source = source
        self.exclude = exclude
        self.linked = linked
        self.linking = linking
    }

    var body: some View {
        if linking {
            Text(ConceptMarkup.attributed(source, palette: theme.patterned, ink: theme.ink, underline: theme.brass,
                                          links: library.linker, exclude: exclude, linked: linked))
                .tint(theme.ink)
        } else {
            ByrneText(source)
        }
    }
}

enum ConceptMarkup {
    /// Byrne markup coloured as `ByrneMarkup.attributed` does, with each link found in the plain text
    /// carried by the runs it spans.
    static func attributed(_ source: String, palette: PatternedPalette, ink: Color, underline: Color,
                           links linker: ConceptLinker, exclude: String?, linked: Set<String>) -> AttributedString {
        let runs = ByrneMarkup.parse(source)
        let links = linker.links(in: runs.map(\.text).joined(), exclude: exclude, linked: linked)
        var result = AttributedString()
        var at = 0
        for run in runs {
            let scalars = Array(run.text.unicodeScalars)
            var start = 0
            while start < scalars.count {
                let here = at + start
                let link = links.first { here >= $0.offset && here < $0.offset + $0.shownLength }
                let next = links.first { $0.offset > here }?.offset
                let end = link.map { $0.offset + $0.shownLength } ?? next ?? Int.max
                let stop = min(scalars.count, end - at)
                var piece = AttributedString(String(String.UnicodeScalarView(scalars[start..<stop])))
                switch run.role {
                case .stays?:
                    piece.backgroundColor = palette.wash(.stays)
                case let role?:
                    piece.foregroundColor = palette.color(role)
                case nil:
                    break
                }
                if let link {
                    piece.link = ConceptLibrary.url(for: link.concept)
                    if run.role == nil || run.role == .stays { piece.foregroundColor = ink }
                    piece.swiftUI.underlineStyle = Text.LineStyle(pattern: .solid, color: underline)
                }
                result += piece
                start = stop
            }
            at += scalars.count
        }
        return result
    }
}

private struct ConceptLibraryKey: EnvironmentKey {
    static let defaultValue = ConceptLibrary.shared
}

extension EnvironmentValues {
    var conceptLibrary: ConceptLibrary {
        get { self[ConceptLibraryKey.self] }
        set { self[ConceptLibraryKey.self] = newValue }
    }
}
