import Foundation

/// A typed algebra answer read into one tree. Parsing, working out its value, showing it back and
/// checking its finished shape all walk this tree, never the text.
indirect enum AnswerExpression: Equatable, Sendable {
    case number(AnswerNumber)
    /// A single letter, or π.
    case symbol(Character)
    case negate(AnswerExpression)
    /// A subtracted term is stored as `.negate`.
    case sum([AnswerExpression])
    case product(AnswerExpression, AnswerExpression)
    case quotient(AnswerExpression, AnswerExpression)
    case power(AnswerExpression, AnswerExpression)
    case root(AnswerExpression)
    /// Brackets the learner typed, kept so the shape checks and the preview see them.
    case group(AnswerExpression)

    static let pi: Character = "π"

    /// Reads one expression. Nil for words, inequalities, equations and unbalanced brackets.
    static func parse(_ raw: String) -> AnswerExpression? {
        parse(normalised: AnswerText.normalise(raw))
    }

    static func parse(normalised: String) -> AnswerExpression? {
        guard let lexemes = lex(Array(AnswerText.tighten(normalised))), !lexemes.isEmpty else { return nil }
        var parser = Parser(lexemes: lexemes)
        guard let expression = parser.sum(), parser.atEnd else { return nil }
        return expression
    }

    // MARK: Segments

    struct Segment: Equatable, Sendable {
        /// The separator typed before this piece: "=", ",", ";" or "and". Empty for the first piece.
        let separator: String
        let typed: String
        let expression: AnswerExpression?
    }

    /// The pieces of an answer on either side of "=", ",", ";" and "and", each read on its own.
    /// The marker and the "Reads as" line both use these.
    static func segments(normalised: String) -> [Segment] {
        let pattern = try! NSRegularExpression(pattern: "[=,;]|\\band\\b")
        let whole = NSRange(normalised.startIndex..., in: normalised)
        var segments: [Segment] = []
        var separator = ""
        var cursor = normalised.startIndex
        func add(upTo end: String.Index) {
            var typed = normalised[cursor..<end].trimmingCharacters(in: .whitespaces)
            while typed.hasSuffix(".") { typed.removeLast() }
            typed = typed.trimmingCharacters(in: .whitespaces)
            if !typed.isEmpty {
                segments.append(Segment(separator: segments.isEmpty ? "" : separator, typed: typed,
                                        expression: parse(normalised: typed)))
            }
        }
        for match in pattern.matches(in: normalised, range: whole) {
            guard let range = Range(match.range, in: normalised) else { continue }
            add(upTo: range.lowerBound)
            separator = String(normalised[range])
            cursor = range.upperBound
        }
        add(upTo: normalised.endIndex)
        return segments
    }

    /// How the marker read a typed answer, or nil when there is no algebra in it or nothing in it reads.
    static func readsAs(_ raw: String) -> String? {
        let normalised = AnswerText.normalise(raw)
        guard normalised.contains(where: { ("a"..."z").contains($0) || $0 == pi || "^/*".contains($0) }) else { return nil }
        let segments = segments(normalised: normalised)
        guard segments.contains(where: { $0.expression != nil }) else { return nil }
        return segments.map { segment in
            let shown = segment.expression?.display ?? segment.typed
            switch segment.separator {
            case "": return shown
            case "=": return " = " + shown
            case "and": return " and " + shown
            default: return segment.separator + " " + shown
            }
        }.joined()
    }

    // MARK: Value

    func value(at values: [Character: Double]) -> Double {
        switch self {
        case let .number(n): n.doubleValue
        case let .symbol(c): c == Self.pi ? .pi : values[c] ?? .nan
        case let .negate(e): -e.value(at: values)
        case let .sum(terms): terms.reduce(0) { $0 + $1.value(at: values) }
        case let .product(a, b): a.value(at: values) * b.value(at: values)
        case let .quotient(a, b): a.value(at: values) / b.value(at: values)
        case let .power(base, exponent): pow(base.value(at: values), exponent.value(at: values))
        case let .root(e): e.value(at: values).squareRoot()
        case let .group(e): e.value(at: values)
        }
    }

    var letters: Set<Character> {
        switch self {
        case .number: []
        case let .symbol(c): c == Self.pi ? [] : [c]
        case let .negate(e), let .root(e), let .group(e): e.letters
        case let .sum(terms): terms.reduce(into: []) { $0.formUnion($1.letters) }
        case let .product(a, b), let .quotient(a, b), let .power(a, b): a.letters.union(b.letters)
        }
    }

    static let samplePoints = 6
    static let sampleValues: [Double] = [1.37, 2.91, 0.53, 3.7, -1.21, 1.83, 0.71, 2.29]

    /// Equal as algebra: the two agree at six awkward points, each letter getting a different value.
    func isEquivalent(to other: AnswerExpression) -> Bool {
        let letters = self.letters.union(other.letters).sorted()
        var usable = 0
        for point in 0..<Self.samplePoints {
            var values: [Character: Double] = [:]
            for (index, letter) in letters.enumerated() {
                values[letter] = Self.sampleValues[(point + 3 * index) % Self.sampleValues.count]
            }
            let a = value(at: values)
            let b = other.value(at: values)
            guard a.isFinite, b.isFinite else { continue }
            guard abs(a - b) <= 1e-9 * max(1, abs(a), abs(b)) else { return false }
            usable += 1
        }
        return usable >= 3
    }

    // MARK: Display

    /// The expression as the preview shows it: x², −, the learner's brackets, × only where a digit follows.
    var display: String { render(top: true) }

    private func render(top: Bool) -> String {
        switch self {
        case let .number(n):
            return Self.decimalText(n)
        case let .symbol(c):
            return String(c)
        case let .negate(e):
            return "−" + e.render(top: false)
        case let .sum(terms):
            let (plus, minus) = top ? (" + ", " − ") : ("+", "−")
            return terms.enumerated().map { index, term in
                if index == 0 { return term.render(top: false) }
                if case let .negate(inner) = term { return minus + inner.render(top: false) }
                return plus + term.render(top: false)
            }.joined()
        case let .product(a, b):
            var left = a.render(top: false)
            if case .quotient = a { left = "(" + left + ")" }
            var right = b.render(top: false)
            if case .negate = b { right = "(" + right + ")" }
            let digitNext = right.first.map { $0.isNumber || $0 == "." } ?? false
            var bareRoot = false
            if case let .root(radicand) = a, !radicand.isGroup { bareRoot = right.first != "(" }
            return left + (digitNext || bareRoot ? " × " : "") + right
        case let .quotient(a, b):
            var right = b.render(top: false)
            if case .negate = b { right = "(" + right + ")" }
            return a.render(top: false) + "/" + right
        case let .power(base, exponent):
            var baseText = base.render(top: false)
            switch base {
            case .number, .symbol, .group: break
            default: baseText = "(" + baseText + ")"
            }
            if let k = exponent.integerLiteral {
                return baseText + String(String(k).map { Self.superscripts[$0] ?? $0 })
            }
            switch exponent {
            case .number, .symbol, .group: return baseText + "^" + exponent.render(top: false)
            default: return baseText + "^(" + exponent.render(top: false) + ")"
            }
        case let .root(e):
            return "√" + e.render(top: false)
        case let .group(e):
            return "(" + e.render(top: false) + ")"
        }
    }

    private static let superscripts: [Character: Character] = [
        "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴", "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹", "-": "⁻"
    ]

    /// A typed number is always a whole number or a decimal, so its denominator only has factors 2 and 5.
    static func decimalText(_ n: AnswerNumber) -> String {
        guard n.denominator != 1 else { return "\(n.numerator)" }
        var places = 0
        var scale = 1
        while scale % n.denominator != 0, places < 15 {
            scale *= 10
            places += 1
        }
        let digits = String(abs(n.numerator) * (scale / n.denominator))
        let padded = String(repeating: "0", count: max(0, places + 1 - digits.count)) + digits
        let cut = padded.index(padded.endIndex, offsetBy: -places)
        return (n.numerator < 0 ? "-" : "") + padded[..<cut] + "." + padded[cut...]
    }

    // MARK: Shape

    enum Expansion: Equatable, Sendable {
        case ok
        case bracketLeft
        case likeTermsLeft
    }

    enum Factorisation: Equatable, Sendable {
        case ok
        case notAProduct
        case bracketWithCommonFactor(bracket: AnswerExpression)
    }

    /// Expanded: no bracket holding a sum is multiplied, divided or raised to a power, and like terms are collected.
    var expansion: Expansion {
        if hasWorkedBracket { return .bracketLeft }
        let signatures = stripped.terms.map { Monomial.of($0).signature }
        return Set(signatures).count == signatures.count ? .ok : .likeTermsLeft
    }

    var isExpanded: Bool { expansion == .ok }

    /// Factorised: a product with at least one bracket, and no bracket whose terms still share a factor.
    var factorisation: Factorisation {
        let whole = stripped
        if case .sum = whole { return .notAProduct }
        let brackets = whole.factors.compactMap(\.bracket)
        guard !brackets.isEmpty else { return .notAProduct }
        for bracket in brackets where Self.termsShareAFactor(bracket.stripped.terms) {
            return .bracketWithCommonFactor(bracket: bracket)
        }
        return .ok
    }

    private static func termsShareAFactor(_ terms: [AnswerExpression]) -> Bool {
        let monomials = terms.map(Monomial.of)
        let coefficients = monomials.compactMap(\.coefficient)
        if coefficients.count == monomials.count, coefficients.allSatisfy({ $0.denominator == 1 }) {
            let divisor = coefficients.reduce(0) { AnswerNumber.gcd($0, abs($1.numerator)) }
            if divisor > 1 { return true }
        }
        guard let first = monomials.first else { return false }
        return first.powers.contains { name, power in
            name.count == 1 && power > 0 && monomials.allSatisfy { ($0.powers[name] ?? 0) > 0 }
        }
    }

    private var isGroup: Bool {
        if case .group = self { true } else { false }
    }

    private var stripped: AnswerExpression {
        if case let .group(inner) = self { inner.stripped } else { self }
    }

    /// A bracket with a sum inside it.
    private var isBracketedSum: Bool {
        if case .group = self, case .sum = stripped { true } else { false }
    }

    private var hasWorkedBracket: Bool {
        switch self {
        case .number, .symbol: false
        case let .negate(e): e.isBracketedSum || e.hasWorkedBracket
        case let .product(a, b), let .quotient(a, b):
            a.isBracketedSum || b.isBracketedSum || a.hasWorkedBracket || b.hasWorkedBracket
        case let .power(base, exponent): base.isBracketedSum || base.hasWorkedBracket || exponent.hasWorkedBracket
        case let .sum(terms): terms.contains(where: \.hasWorkedBracket)
        case let .root(e), let .group(e): e.hasWorkedBracket
        }
    }

    /// The terms of a sum, with a bracketed sum standing as a term opened out.
    private var terms: [AnswerExpression] {
        guard case let .sum(terms) = self else { return [self] }
        return terms.flatMap { $0.isBracketedSum ? $0.stripped.terms : [$0] }
    }

    private var factors: [AnswerExpression] {
        switch self {
        case let .product(a, b), let .quotient(a, b): a.factors + b.factors
        case let .negate(e): e.factors
        case let .group(inner): isBracketedSum ? [self] : inner.factors
        default: [self]
        }
    }

    /// The bracket this factor puts round a sum, itself or as the base of a power.
    private var bracket: AnswerExpression? {
        if isBracketedSum { return self }
        if case let .power(base, _) = self, base.isBracketedSum { return base }
        return nil
    }

    fileprivate var integerLiteral: Int? {
        switch self {
        case let .number(n) where n.denominator == 1: n.numerator
        case let .negate(.number(n)) where n.denominator == 1: -n.numerator
        default: nil
        }
    }

    // MARK: Lexing and parsing

    fileprivate enum Token: Equatable {
        case number(AnswerNumber)
        case symbol(Character)
        case op(Character)
    }

    fileprivate struct Lexeme {
        let token: Token
        let spacedBefore: Bool
    }

    private static func lex(_ chars: [Character]) -> [Lexeme]? {
        var lexemes: [Lexeme] = []
        var index = 0
        var spaced = false
        func isDigit(_ at: Int) -> Bool { at < chars.count && ("0"..."9").contains(chars[at]) }
        while index < chars.count {
            let c = chars[index]
            if c == " " {
                spaced = true
                index += 1
                continue
            }
            if isDigit(index) || (c == "." && isDigit(index + 1)) {
                var end = index
                while isDigit(end) { end += 1 }
                if end < chars.count, chars[end] == ".", isDigit(end + 1) {
                    end += 1
                    while isDigit(end) { end += 1 }
                }
                guard let number = AnswerNumber(String(chars[index..<end])) else { return nil }
                lexemes.append(Lexeme(token: .number(number), spacedBefore: spaced))
                index = end
            } else if ("a"..."z").contains(c) {
                var end = index
                while end < chars.count, ("a"..."z").contains(chars[end]) { end += 1 }
                let run = Array(chars[index..<end])
                var symbols: [Character] = []
                var at = 0
                while at < run.count {
                    if at + 1 < run.count, run[at] == "p", run[at + 1] == "i" {
                        symbols.append(pi)
                        at += 2
                    } else {
                        symbols.append(run[at])
                        at += 1
                    }
                }
                // Letters side by side are a product (6ab), but a run of four or more is a word.
                guard symbols.count < 4 else { return nil }
                for (offset, symbol) in symbols.enumerated() {
                    lexemes.append(Lexeme(token: .symbol(symbol), spacedBefore: offset == 0 && spaced))
                }
                index = end
            } else if c == pi || "+-*/^()√".contains(c) {
                lexemes.append(Lexeme(token: c == pi ? .symbol(pi) : .op(c), spacedBefore: spaced))
                index += 1
            } else {
                return nil
            }
            spaced = false
        }
        return lexemes
    }

    /// ^ binds tightest and to the right, then unary minus, then ×, ÷ and side-by-side products at one
    /// level from the left, so 1/2x is (1/2)x and -x^2 is -(x²).
    fileprivate struct Parser {
        let lexemes: [Lexeme]
        var index = 0

        var atEnd: Bool { index == lexemes.count }

        private var next: Token? { index < lexemes.count ? lexemes[index].token : nil }

        private mutating func take(_ op: Character) -> Bool {
            guard next == .op(op) else { return false }
            index += 1
            return true
        }

        mutating func sum() -> AnswerExpression? {
            guard let first = term() else { return nil }
            var terms = [first]
            while true {
                if take("+") {
                    guard let t = term() else { return nil }
                    terms.append(t)
                } else if take("-") {
                    guard let t = term() else { return nil }
                    terms.append(.negate(t))
                } else {
                    break
                }
            }
            return terms.count == 1 ? first : .sum(terms)
        }

        private mutating func term() -> AnswerExpression? {
            guard var left = unary() else { return nil }
            while true {
                if take("*") {
                    guard let right = unary() else { return nil }
                    left = .product(left, right)
                } else if take("/") {
                    guard let right = unary() else { return nil }
                    left = .quotient(left, right)
                } else if startsImplicitFactor() {
                    guard let right = unary() else { return nil }
                    left = .product(left, right)
                } else {
                    return left
                }
            }
        }

        /// A space between two letters or two numbers ends the expression: "nth term" and "2 5/12" are not products.
        private func startsImplicitFactor() -> Bool {
            guard index < lexemes.count else { return false }
            let lexeme = lexemes[index]
            switch lexeme.token {
            case .op("("), .op("√"):
                return true
            case .number, .symbol:
                guard lexeme.spacedBefore else { return true }
                if case .symbol = lexeme.token, case .number = lexemes[index - 1].token { return true }
                return false
            default:
                return false
            }
        }

        private mutating func unary() -> AnswerExpression? {
            if take("-") { return unary().map { .negate($0) } }
            if take("+") { return unary() }
            return power()
        }

        private mutating func power() -> AnswerExpression? {
            guard let base = primary() else { return nil }
            guard take("^") else { return base }
            return unary().map { .power(base, $0) }
        }

        private mutating func primary() -> AnswerExpression? {
            guard let token = next else { return nil }
            index += 1
            switch token {
            case let .number(n): return .number(n)
            case let .symbol(c): return .symbol(c)
            case .op("("):
                guard let inner = sum(), take(")") else { return nil }
                return .group(inner)
            case .op("√"):
                return primary().map { .root($0) }
            default:
                return nil
            }
        }
    }
}

/// A term read as a coefficient times letters to powers. A part it cannot split (a root, a bracketed sum)
/// counts as one opaque factor named by its display.
private struct Monomial {
    var coefficient: AnswerNumber?
    var powers: [String: Int]

    static func of(_ term: AnswerExpression) -> Monomial {
        switch term {
        case let .number(n):
            return Monomial(coefficient: n, powers: [:])
        case let .symbol(c):
            return Monomial(coefficient: .one, powers: [String(c): 1])
        case let .negate(e):
            var inner = of(e)
            inner.coefficient = inner.coefficient?.negated()
            return inner
        case let .group(inner):
            if case .sum = inner { return opaque(term) }
            return of(inner)
        case let .product(a, b):
            return of(a).combined(with: of(b), sign: 1)
        case let .quotient(a, b):
            return of(a).combined(with: of(b), sign: -1)
        case let .power(base, exponent):
            guard let k = exponent.integerLiteral else { return opaque(term) }
            let inner = of(base)
            return Monomial(coefficient: inner.coefficient.flatMap { $0.raised(to: k) }, powers: inner.powers.mapValues { $0 * k })
        case .sum, .root:
            return opaque(term)
        }
    }

    static func opaque(_ term: AnswerExpression) -> Monomial {
        Monomial(coefficient: .one, powers: ["[" + term.display + "]": 1])
    }

    func combined(with other: Monomial, sign: Int) -> Monomial {
        let coefficient: AnswerNumber? = if let a = self.coefficient, let b = other.coefficient {
            sign > 0 ? a.multiplied(by: b) : b.reciprocal.flatMap { a.multiplied(by: $0) }
        } else {
            nil
        }
        return Monomial(coefficient: coefficient, powers: powers.merging(other.powers.mapValues { $0 * sign }, uniquingKeysWith: +))
    }

    var signature: String {
        powers.filter { $0.value != 0 }.sorted { $0.key < $1.key }.map { "\($0.key)^\($0.value)" }.joined(separator: ",")
    }
}

private extension AnswerNumber {
    static let one = AnswerNumber(numerator: 1, denominator: 1)!

    func multiplied(by other: AnswerNumber) -> AnswerNumber? {
        let (n, nOverflow) = numerator.multipliedReportingOverflow(by: other.numerator)
        let (d, dOverflow) = denominator.multipliedReportingOverflow(by: other.denominator)
        guard !nOverflow, !dOverflow else { return nil }
        return AnswerNumber(numerator: n, denominator: d)
    }

    var reciprocal: AnswerNumber? { AnswerNumber(numerator: denominator, denominator: numerator) }

    func raised(to k: Int) -> AnswerNumber? {
        guard let base = k >= 0 ? self : reciprocal else { return nil }
        var result: AnswerNumber? = .one
        for _ in 0..<min(abs(k), 64) { result = result.flatMap { $0.multiplied(by: base) } }
        return abs(k) > 64 ? nil : result
    }
}

enum ExpressionForm: String, Codable, Sendable {
    case any
    case expanded
    case factorised

    func accepts(_ expression: AnswerExpression) -> Bool {
        switch self {
        case .any: true
        case .expanded: expression.isExpanded
        case .factorised: expression.factorisation == .ok
        }
    }

    /// The slip in an answer that is equal to the target but not in this shape yet.
    func unfinished(_ expression: AnswerExpression) -> KnownMistake? {
        switch self {
        case .any:
            return nil
        case .expanded:
            switch expression.expansion {
            case .ok: return nil
            case .bracketLeft: return .unfinished("stopped-early", "It is equal, but a bracket is still there. Multiply it out.")
            case .likeTermsLeft: return .unfinished("stopped-early", "It is equal, but some like terms are not collected yet. Add them together.")
            }
        case .factorised:
            switch expression.factorisation {
            case .ok: return nil
            case .notAProduct: return .unfinished("stopped-early", "It is equal, but it is not factorised yet. Write it as a product with a bracket.")
            case let .bracketWithCommonFactor(bracket):
                return .unfinished("common-factor-left",
                                   "It multiplies back to the right expression, but the bracket \(bracket.display) still has a common factor. Take that out too.")
            }
        }
    }
}

extension KnownMistake {
    /// The registry names of the two slips the marker names on its own, for an answer that is equal but unfinished.
    static let unfinishedNames = [
        "stopped-early": "You stopped one step too soon",
        "common-factor-left": "You left a common factor in"
    ]

    fileprivate static func unfinished(_ id: String, _ nextStep: String) -> KnownMistake {
        KnownMistake(misconception: id, name: unfinishedNames[id] ?? id, anyOf: [], nextStep: nextStep, examples: [])
    }
}
