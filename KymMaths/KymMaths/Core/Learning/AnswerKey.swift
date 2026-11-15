import Foundation

struct AnswerKey: Codable, Equatable, Sendable {
    let parts: [AnswerPart]
    let accepts: [String]
    let rejects: [String]
    let mistakes: [KnownMistake]

    func mark(_ answer: String) -> AnswerMarking {
        let text = AnswerText(answer)
        var matched: [String] = []
        var missing: [String] = []
        for part in parts {
            if part.anyOf.contains(where: { $0.matches(text) }) {
                matched.append(part.label)
            } else {
                missing.append(part.label)
            }
        }
        let isCorrect = !matched.isEmpty && missing.isEmpty
        let mistake = isCorrect ? nil : mistakes.first { $0.anyOf.contains { $0.matches(text) } }
        return AnswerMarking(matchedParts: matched, missingParts: missing, mistake: mistake)
    }
}

/// A common slip for one question, recognised by the wrong answer it produces.
struct KnownMistake: Codable, Equatable, Sendable {
    let misconception: String
    let name: String
    let anyOf: [AnswerMatcher]
    let nextStep: String
    let examples: [String]
}

struct AnswerPart: Codable, Equatable, Sendable {
    let label: String
    let anyOf: [AnswerMatcher]
}

struct AnswerMarking: Equatable, Sendable {
    let matchedParts: [String]
    let missingParts: [String]
    /// Set only for a wrong answer that matches a known slip.
    let mistake: KnownMistake?

    var isCorrect: Bool { !matchedParts.isEmpty && missingParts.isEmpty }
}

indirect enum AnswerMatcher: Equatable, Sendable {
    case number(value: AnswerNumber, tolerance: Double, simplest: Bool)
    case sequence(values: [AnswerNumber], ignoring: [AnswerNumber])
    case form(String)
    case words(groups: [[String]], forbid: [String])
    case all([AnswerMatcher])

    func matches(_ text: AnswerText) -> Bool {
        switch self {
        case let .number(value, tolerance, simplest):
            return text.numbers.contains { token in
                (!simplest || token.isSimplest) && token.value.equals(value, tolerance: tolerance)
            }
        case let .sequence(values, ignoring):
            let found = text.numbers.map(\.value).filter { !ignoring.contains($0) }
            guard !values.isEmpty, found.count >= values.count else { return false }
            return (0...(found.count - values.count)).contains { start in
                Array(found[start..<(start + values.count)]) == values
            }
        case let .form(value):
            return text.containsForm(value)
        case let .words(groups, forbid):
            guard !groups.isEmpty, !forbid.contains(where: text.containsPhrase) else { return false }
            return groups.allSatisfy { $0.contains(where: text.containsPhrase) }
        case let .all(matchers):
            return !matchers.isEmpty && matchers.allSatisfy { $0.matches(text) }
        }
    }
}

extension AnswerMatcher: Codable {
    private struct Wire: Codable {
        var kind: String
        var value: String?
        var values: [String]?
        var ignoring: [String]?
        var tolerance: Double?
        var simplest: Bool?
        var groups: [[String]]?
        var forbid: [String]?
        var of: [AnswerMatcher]?
    }

    init(from decoder: Decoder) throws {
        let wire = try Wire(from: decoder)
        func fail(_ reason: String) -> DecodingError {
            .dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "\(wire.kind) matcher: \(reason)"))
        }
        func number(_ text: String) throws -> AnswerNumber {
            guard let parsed = AnswerNumber(text) else { throw fail("\"\(text)\" is not a number") }
            return parsed
        }
        switch wire.kind {
        case "number":
            guard let value = wire.value else { throw fail("needs a value") }
            self = .number(value: try number(value), tolerance: wire.tolerance ?? 0, simplest: wire.simplest ?? false)
        case "sequence":
            guard let values = wire.values, !values.isEmpty else { throw fail("needs values") }
            self = .sequence(values: try values.map(number), ignoring: try (wire.ignoring ?? []).map(number))
        case "form":
            guard let value = wire.value, !value.isEmpty else { throw fail("needs a value") }
            self = .form(value)
        case "words":
            guard let groups = wire.groups, !groups.isEmpty, groups.allSatisfy({ !$0.isEmpty }) else {
                throw fail("needs non-empty groups")
            }
            self = .words(groups: groups, forbid: wire.forbid ?? [])
        case "all":
            guard let of = wire.of, !of.isEmpty else { throw fail("needs matchers") }
            self = .all(of)
        default:
            throw fail("unknown kind")
        }
    }

    func encode(to encoder: Encoder) throws {
        let wire: Wire
        switch self {
        case let .number(value, tolerance, simplest):
            wire = Wire(kind: "number", value: value.text, tolerance: tolerance, simplest: simplest)
        case let .sequence(values, ignoring):
            wire = Wire(kind: "sequence", values: values.map(\.text), ignoring: ignoring.map(\.text))
        case let .form(value):
            wire = Wire(kind: "form", value: value)
        case let .words(groups, forbid):
            wire = Wire(kind: "words", groups: groups, forbid: forbid)
        case let .all(matchers):
            wire = Wire(kind: "all", of: matchers)
        }
        try wire.encode(to: encoder)
    }
}

/// An exact fraction, so 0.25, 1/4 and 2/8 compare equal without rounding.
struct AnswerNumber: Hashable, Sendable {
    let numerator: Int
    let denominator: Int

    init?(numerator: Int, denominator: Int) {
        guard denominator != 0 else { return nil }
        let divisor = Self.gcd(abs(numerator), abs(denominator))
        let sign = denominator < 0 ? -1 : 1
        self.numerator = sign * numerator / max(divisor, 1)
        self.denominator = sign * denominator / max(divisor, 1)
    }

    /// Reads "24", "-2.5", "0.00409" or "5/14".
    init?(_ text: String) {
        let pieces = text.split(separator: "/", omittingEmptySubsequences: false)
        guard let top = pieces.first.flatMap({ Self.decimal(String($0)) }) else { return nil }
        switch pieces.count {
        case 1:
            self = top
        case 2:
            guard let bottom = Self.decimal(String(pieces[1])), bottom.numerator != 0 else { return nil }
            let (n, nOverflow) = top.numerator.multipliedReportingOverflow(by: bottom.denominator)
            let (d, dOverflow) = top.denominator.multipliedReportingOverflow(by: bottom.numerator)
            guard !nOverflow, !dOverflow else { return nil }
            self.init(numerator: n, denominator: d)
        default:
            return nil
        }
    }

    var doubleValue: Double { Double(numerator) / Double(denominator) }

    var text: String { denominator == 1 ? "\(numerator)" : "\(numerator)/\(denominator)" }

    func equals(_ other: AnswerNumber, tolerance: Double) -> Bool {
        tolerance > 0 ? abs(doubleValue - other.doubleValue) <= tolerance + 1e-12 : self == other
    }

    func negated() -> AnswerNumber {
        AnswerNumber(numerator: -numerator, denominator: denominator) ?? self
    }

    private static func decimal(_ text: String) -> AnswerNumber? {
        var body = text.trimmingCharacters(in: .whitespaces)
        let negative = body.hasPrefix("-")
        if negative { body.removeFirst() }
        let halves = body.split(separator: ".", omittingEmptySubsequences: false)
        guard (1...2).contains(halves.count) else { return nil }
        let whole = String(halves[0])
        let fraction = halves.count == 2 ? String(halves[1]) : ""
        let digits = whole + fraction
        guard !digits.isEmpty, digits.count <= 15, digits.allSatisfy(\.isASCIIDigit), let value = Int(digits) else {
            return nil
        }
        let scale = (0..<fraction.count).reduce(1) { result, _ in result * 10 }
        return AnswerNumber(numerator: negative ? -value : value, denominator: scale)
    }

    static func gcd(_ a: Int, _ b: Int) -> Int {
        b == 0 ? a : gcd(b, a % b)
    }
}

struct AnswerNumberToken: Equatable, Sendable {
    let value: AnswerNumber
    /// False for a fraction that still cancels, such as 27/99.
    let isSimplest: Bool
}

/// A learner's typed answer, read once into the three views the matchers need.
struct AnswerText: Sendable {
    let numbers: [AnswerNumberToken]
    private let words: [String]
    private let tight: [Character]

    init(_ raw: String) {
        let normalised = Self.normalise(raw)
        numbers = Self.readNumbers(Array(normalised))
        words = Self.readWords(normalised)
        tight = Array(Self.tighten(normalised))
    }

    func containsPhrase(_ phrase: String) -> Bool {
        let wanted = Self.readWords(Self.normalise(phrase))
        guard !wanted.isEmpty, words.count >= wanted.count else { return false }
        return (0...(words.count - wanted.count)).contains { start in
            Array(words[start..<(start + wanted.count)]) == wanted
        }
    }

    func containsForm(_ form: String) -> Bool {
        let needle = Array(Self.tighten(Self.normalise(form)))
        guard !needle.isEmpty, tight.count >= needle.count else { return false }
        for start in 0...(tight.count - needle.count) where Array(tight[start..<(start + needle.count)]) == needle {
            let before = start > 0 ? tight[start - 1] : nil
            let end = start + needle.count
            let after = end < tight.count ? tight[end] : nil
            let afterNext = end + 1 < tight.count ? tight[end + 1] : nil
            let openBefore = before.map { " =,;:".contains($0) } ?? true
            let openAfter: Bool
            switch after {
            case nil: openAfter = true
            case "."?: openAfter = !(afterNext?.isASCIIDigit ?? false)
            case let character?: openAfter = " =,;:".contains(character)
            }
            if openBefore && openAfter { return true }
        }
        return false
    }

    // MARK: Normalising

    private static let superscripts: [Character: Character] = [
        "⁰": "0", "¹": "1", "²": "2", "³": "3", "⁴": "4", "⁵": "5", "⁶": "6", "⁷": "7", "⁸": "8", "⁹": "9", "⁻": "-"
    ]
    private static let subscripts: [Character: Character] = [
        "₀": "0", "₁": "1", "₂": "2", "₃": "3", "₄": "4", "₅": "5", "₆": "6", "₇": "7", "₈": "8", "₉": "9", "ₙ": "n"
    ]
    private static let replacements: [Character: String] = [
        "−": "-", "–": "-", "—": "-", "×": "*", "·": "*", "÷": "/", "≈": "=", "’": "'", "′": "'",
        "∠": "angle ", "…": " ", "₹": "", "$": "", "£": "", "ᵀ": "", "°": " ", "%": " "
    ]
    private static let vulgarFractions: [Character: String] = ["½": "1/2", "¼": "1/4", "¾": "3/4", "⅓": "1/3", "⅔": "2/3"]

    static func normalise(_ raw: String) -> String {
        let withoutMarks = String(String.UnicodeScalarView(raw.unicodeScalars.filter { !(0x0300...0x036F).contains($0.value) }))
        var out = ""
        var run: Character?
        for character in withoutMarks.lowercased() {
            if let digit = superscripts[character] {
                if run != "^" { out.append("^") }
                out.append(digit)
                run = "^"
                continue
            }
            if let digit = subscripts[character] {
                if run != "_" { out.append("_") }
                out.append(digit)
                run = "_"
                continue
            }
            run = nil
            if let fraction = vulgarFractions[character] {
                if out.last?.isASCIIDigit == true { out.append(" ") }
                out.append(fraction)
            } else if let replacement = replacements[character] {
                out.append(replacement)
            } else if character.isWhitespace {
                out.append(" ")
            } else {
                out.append(character)
            }
        }
        return out
            .replacingOccurrences(of: "<=", with: "≤")
            .replacingOccurrences(of: ">=", with: "≥")
            .replacingOccurrences(of: " +", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }

    /// Removes the spacing that does not change meaning, so "5x + 3" and "5x+3" are one form.
    static func tighten(_ normalised: String) -> String {
        func replace(_ pattern: String, _ template: String, in text: String) -> String {
            text.replacingOccurrences(of: pattern, with: template, options: .regularExpression)
        }
        var text = normalised
        text = replace("square root of|square root|sqrt|root", "√", in: text)
        text = replace(" squared", "^2", in: text)
        text = replace(" cubed", "^3", in: text)
        text = replace("(?<=[0-9]) ?(cm|mm|km|kg|ml|litres?|liters?|seconds?|secs?|hours?|hrs?|units?)(\\^[0-9])?(?![a-z])", "", in: text)
        text = replace("(?<=[0-9]) ?x ?(?=[0-9])", "*", in: text)
        text = replace(" +- +", "-", in: text)
        text = replace("(?<=[^ ])- +", "-", in: text)
        text = replace(" *([+*/^=<>≤≥√]) *", "$1", in: text)
        text = replace("\\( +", "(", in: text)
        text = replace(" +\\)", ")", in: text)
        return text.trimmingCharacters(in: .whitespaces)
    }

    static func readWords(_ normalised: String) -> [String] {
        normalised
            .split(whereSeparator: { !($0.isLetter || $0.isNumber || $0 == "'") })
            .map(String.init)
    }

    // MARK: Reading numbers

    private static let units: Set<String> = [
        "cm", "mm", "km", "m", "kg", "g", "l", "ml", "s", "h", "litre", "litres", "liter", "liters",
        "sec", "secs", "second", "seconds", "min", "mins", "hr", "hrs", "hour", "hours", "rs",
        "st", "nd", "rd", "th"
    ]

    /// Numbers that stand on their own. A coefficient (3x, 4(…), 2√2), a base or exponent (10², x^2)
    /// and a subscript (S₂₀) are part of an expression, not an answer value, so they are skipped.
    static func readNumbers(_ chars: [Character]) -> [AnswerNumberToken] {
        var tokens: [AnswerNumberToken] = []
        var index = 0

        func char(_ at: Int) -> Character? { chars.indices.contains(at) ? chars[at] : nil }
        func isDigit(_ at: Int) -> Bool { char(at)?.isASCIIDigit ?? false }

        func scanInteger(from start: Int) -> (text: String, end: Int) {
            var end = start
            while isDigit(end) { end += 1 }
            var text = String(chars[start..<end])
            guard text.count <= 3 else { return (text, end) }
            // Thousands groups: 20,100 and 1,234,567, or Indian style 5,89,020. "20,15,15" is a list.
            var groups: [(digits: String, end: Int)] = []
            var cursor = end
            while char(cursor) == "," {
                var groupEnd = cursor + 1
                while isDigit(groupEnd) { groupEnd += 1 }
                let length = groupEnd - cursor - 1
                guard length == 2 || length == 3 else { break }
                groups.append((String(chars[(cursor + 1)..<groupEnd]), groupEnd))
                cursor = groupEnd
            }
            let lengths = groups.map(\.digits.count)
            let western = lengths.prefix(while: { $0 == 3 }).count
            let indianTwos = lengths.prefix(while: { $0 == 2 }).count
            let indian = indianTwos > 0 && lengths.dropFirst(indianTwos).first == 3 ? indianTwos + 1 : 0
            let used = max(western, indian)
            guard used > 0 else { return (text, end) }
            text += groups.prefix(used).map(\.digits).joined()
            end = groups[used - 1].end
            return (text, end)
        }

        func trailingRun(from start: Int) -> (letters: String, end: Int) {
            var end = start
            while let character = char(end), character.isLetter { end += 1 }
            return (String(chars[start..<end]), end)
        }

        /// True when what follows the number makes it a coefficient or a base.
        func bindsForward(at end: Int) -> Bool {
            guard let next = char(end) else { return false }
            if next == "^" || next == "(" || next == "√" { return true }
            guard next.isLetter else { return false }
            return !units.contains(trailingRun(from: end).letters)
        }

        while index < chars.count {
            let startsNumber = isDigit(index) || (chars[index] == "." && isDigit(index + 1))
            guard startsNumber else { index += 1; continue }

            let start = index
            var (text, end) = chars[index] == "." ? ("0", index) : scanInteger(from: index)
            var isInteger = true
            if char(end) == ".", isDigit(end + 1) {
                var fractionEnd = end + 1
                while isDigit(fractionEnd) { fractionEnd += 1 }
                text += "." + String(chars[(end + 1)..<fractionEnd])
                end = fractionEnd
                isInteger = false
            }

            var signStart = start
            var negative = false
            if char(start - 1) == "-" {
                let beforeMinus = char(start - 2)
                if beforeMinus == nil || " (=,*/:[".contains(beforeMinus!) {
                    negative = true
                    signStart = start - 1
                } else if beforeMinus == "^" {
                    index = end
                    continue
                }
            }
            if let before = char(signStart - 1), before.isLetter || before == "_" || before == "^" || before == "." {
                index = end
                continue
            }

            var value = AnswerNumber(text)
            var isSimplest = true
            var consumedEnd = end

            if isInteger {
                var slash = end
                while char(slash) == " " { slash += 1 }
                var denominatorStart = slash + 1
                while char(denominatorStart) == " " { denominatorStart += 1 }
                if char(slash) == "/", isDigit(denominatorStart) {
                    let (denominatorText, denominatorEnd) = scanInteger(from: denominatorStart)
                    let denominatorIsInteger = !(char(denominatorEnd) == "." && isDigit(denominatorEnd + 1))
                    if denominatorIsInteger, let top = Int(text), let bottom = Int(denominatorText), bottom != 0 {
                        value = AnswerNumber(numerator: top, denominator: bottom)
                        isSimplest = AnswerNumber.gcd(top, bottom) == 1
                        consumedEnd = denominatorEnd
                    }
                } else if char(end) == " ", isDigit(end + 1) {
                    let (topText, topEnd) = scanInteger(from: end + 1)
                    if char(topEnd) == "/", isDigit(topEnd + 1) {
                        let (bottomText, bottomEnd) = scanInteger(from: topEnd + 1)
                        if let whole = Int(text), let top = Int(topText), let bottom = Int(bottomText), top < bottom,
                           !(char(bottomEnd) == "." && isDigit(bottomEnd + 1)) {
                            value = AnswerNumber(numerator: whole * bottom + top, denominator: bottom)
                            isSimplest = AnswerNumber.gcd(top, bottom) == 1
                            consumedEnd = bottomEnd
                        }
                    }
                }
            }

            index = consumedEnd
            if bindsForward(at: consumedEnd) {
                if char(consumedEnd)?.isLetter == true { index = trailingRun(from: consumedEnd).end }
                continue
            }
            if let value {
                tokens.append(AnswerNumberToken(value: negative ? value.negated() : value, isSimplest: isSimplest))
            }
        }
        return tokens
    }
}

private extension Character {
    var isASCIIDigit: Bool { ("0"..."9").contains(self) }
}
