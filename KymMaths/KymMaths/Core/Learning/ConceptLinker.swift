import Foundation

/// One linked phrase in a piece of learner text. `offset` and `length` count Unicode scalars.
struct ConceptLink: Equatable, Sendable {
    let concept: String
    let text: String
    let offset: Int
    let length: Int

    /// How much of the phrase is drawn as the link. "power of" and "multiple of" are aliases so that
    /// the bare words link only in their maths sense; the "of" is not part of the name and stays plain.
    var shownLength: Int {
        ConceptLinker.fold(text).suffix(3).elementsEqual(" of".unicodeScalars) ? length - 3 : length
    }
}

/// Finds the concept-card links in learner text. `source/concept_links.py` implements the same rule and
/// writes `Tests/Golden/concept-links.json`, which a test replays here, so keep the two in step.
///
/// Scan left to right; at each position try the longest phrase first among every alias and stop phrase,
/// ignoring case. A phrase edge that is a letter or digit needs a neighbour on that side that is neither,
/// so "factorise" does not match "factor". A stop phrase, an `exclude` match or a concept already linked
/// in the scope is consumed with no link. Matches never overlap.
struct ConceptLinker: Sendable {
    struct Match: Equatable, Sendable {
        let offset: Int
        let length: Int
        /// Nil for a stop phrase.
        let concept: String?
    }

    private struct Phrase: Sendable {
        let scalars: [Unicode.Scalar]
        let concept: String?
    }

    /// Phrases by their first folded scalar, longest first.
    private let phrases: [Unicode.Scalar: [Phrase]]

    init(aliases: [(concept: String, aliases: [String])], stopPhrases: [String]) {
        var byText: [String: String?] = [:]
        var order: [String] = []
        func add(_ phrase: String, _ concept: String?) {
            let folded = String(String.UnicodeScalarView(Self.fold(phrase)))
            guard !folded.isEmpty, !byText.keys.contains(folded) else { return }
            byText[folded] = concept
            order.append(folded)
        }
        stopPhrases.forEach { add($0, nil) }
        for card in aliases { card.aliases.forEach { add($0, card.concept) } }

        var index: [Unicode.Scalar: [Phrase]] = [:]
        for text in order {
            let scalars = Array(text.unicodeScalars)
            index[scalars[0], default: []].append(Phrase(scalars: scalars, concept: byText[text] ?? nil))
        }
        phrases = index.mapValues { $0.sorted { $0.scalars.count > $1.scalars.count } }
    }

    init(cards: [ConceptCard], stopPhrases: [String]) {
        self.init(aliases: cards.map { ($0.id, $0.aliases) }, stopPhrases: stopPhrases)
    }

    func matches(in text: String) -> [Match] {
        let folded = Self.fold(text)
        var found: [Match] = []
        var at = 0
        while at < folded.count {
            if let hit = phrases[folded[at]]?.first(where: { Self.fits($0.scalars, in: folded, at: at) }) {
                found.append(Match(offset: at, length: hit.scalars.count, concept: hit.concept))
                at += hit.scalars.count
            } else {
                at += 1
            }
        }
        return found
    }

    /// The links in `text`. `linked` holds the concepts this scope has already linked.
    func links(in text: String, exclude: String? = nil, linked: Set<String> = []) -> [ConceptLink] {
        let scalars = Array(text.unicodeScalars)
        var seen = linked
        var out: [ConceptLink] = []
        for match in matches(in: text) {
            guard let concept = match.concept, concept != exclude, !seen.contains(concept) else { continue }
            seen.insert(concept)
            let slice = String(String.UnicodeScalarView(scalars[match.offset..<match.offset + match.length]))
            out.append(ConceptLink(concept: concept, text: slice, offset: match.offset, length: match.length))
        }
        return out
    }

    /// For texts read in order as one scope, the concepts linked before each one.
    func linkedBefore(_ texts: [String], exclude: String? = nil) -> [Set<String>] {
        var seen: Set<String> = []
        return texts.map { text in
            defer { seen.formUnion(links(in: text, exclude: exclude, linked: seen).map(\.concept)) }
            return seen
        }
    }

    // MARK: - The rule's pieces

    static func isWordScalar(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.properties.generalCategory {
        case .uppercaseLetter, .lowercaseLetter, .titlecaseLetter, .modifierLetter, .otherLetter: true
        default: scalar.properties.numericType != nil
        }
    }

    /// Lower case one scalar at a time, so offsets in the folded text match the original.
    static func fold(_ text: String) -> [Unicode.Scalar] {
        text.unicodeScalars.map { scalar in
            let lower = scalar.properties.lowercaseMapping.unicodeScalars
            return lower.count == 1 ? lower.first! : scalar
        }
    }

    private static func fits(_ phrase: [Unicode.Scalar], in folded: [Unicode.Scalar], at: Int) -> Bool {
        let end = at + phrase.count
        guard end <= folded.count, folded[at..<end].elementsEqual(phrase) else { return false }
        if isWordScalar(phrase[0]), at > 0, isWordScalar(folded[at - 1]) { return false }
        if isWordScalar(phrase[phrase.count - 1]), end < folded.count, isWordScalar(folded[end]) { return false }
        return true
    }
}

/// The pack's concept cards and the linker built from them.
struct ConceptLibrary: Sendable {
    static let scheme = "kymconcept"
    static let shared = ConceptLibrary(pack: SeedPackLoader.shared)

    let cards: [String: ConceptCard]
    let linker: ConceptLinker

    init(cards: [ConceptCard], stopPhrases: [String]) {
        self.cards = Dictionary(cards.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        linker = ConceptLinker(cards: cards, stopPhrases: stopPhrases)
    }

    init(pack: KymMathsSeedPack) {
        self.init(cards: pack.concepts, stopPhrases: pack.conceptStopPhrases)
    }

    func card(_ id: String) -> ConceptCard? { cards[id] }

    static func url(for concept: String) -> URL {
        URL(string: "\(scheme)://\(concept)")!
    }

    /// The concept a `kymconcept://<id>` link names.
    static func concept(in url: URL) -> String? {
        guard url.scheme == scheme, let host = url.host, !host.isEmpty else { return nil }
        return host
    }
}
