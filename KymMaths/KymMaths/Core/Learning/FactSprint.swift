import Foundation

/// One of the four families of facts the daily warm-up sprints through.
enum FactFamily: String, CaseIterable, Codable, Identifiable, Sendable {
    case timesAndDivide
    case squaresAndRoots
    case powers
    case fractionsDecimalsPercents

    var id: String { rawValue }

    var title: String {
        switch self {
        case .timesAndDivide: "Times and divide"
        case .squaresAndRoots: "Squares and roots"
        case .powers: "Powers"
        case .fractionsDecimalsPercents: "Fractions, decimals, percents"
        }
    }
}

struct Fact: Hashable, Sendable {
    let family: FactFamily
    let prompt: String
    let answer: String
    /// Shown after the answer slot, so "3/5 as a percent" is answered "60" beside a printed "%".
    var answerSuffix: String = ""

    var id: String { prompt }

    /// The fact said whole, "7 × 8 = 56", for after a miss.
    var worked: String {
        let left = prompt.components(separatedBy: " as a ").first ?? prompt
        return "\(left) = \(answer)\(answerSuffix)"
    }
}

/// Every fact in a family, worked out rather than typed in.
enum FactCatalog {
    static func facts(_ family: FactFamily) -> [Fact] {
        switch family {
        case .timesAndDivide:
            let pairs = (2...12).flatMap { a in (2...12).map { b in (a, b) } }
            return pairs.map { a, b in Fact(family: family, prompt: "\(a) × \(b)", answer: "\(a * b)") }
                + pairs.map { a, b in Fact(family: family, prompt: "\(a * b) ÷ \(a)", answer: "\(b)") }
        case .squaresAndRoots:
            return (1...15).map { n in Fact(family: family, prompt: "\(n)²", answer: "\(n * n)") }
                + (1...15).map { n in Fact(family: family, prompt: "√\(n * n)", answer: "\(n)") }
                + (1...5).map { n in Fact(family: family, prompt: "\(n)³", answer: "\(n * n * n)") }
        case .powers:
            let bases = [(2, 10), (3, 5), (5, 4)]
            return bases.flatMap { base, top in
                (1...top).map { power in
                    Fact(family: family, prompt: "\(base)\(superscript(power))", answer: "\(Int(pow(Double(base), Double(power))))")
                }
            }
        case .fractionsDecimalsPercents:
            let fractions = [2, 4, 5, 8, 10].flatMap { d in
                (1..<d).filter { gcd($0, d) == 1 }.map { n in (n, d) }
            }
            return fractions.flatMap { n, d -> [Fact] in
                let fraction = "\(n)/\(d)"
                let asDecimal = decimal(n * 1000 / d, over: 1000)
                return [
                    Fact(family: family, prompt: "\(fraction) as a decimal", answer: asDecimal),
                    Fact(family: family, prompt: "\(fraction) as a percent", answer: decimal(n * 1000 / d, over: 10), answerSuffix: "%"),
                    Fact(family: family, prompt: "\(asDecimal) as a fraction", answer: fraction)
                ]
            }
        }
    }

    private static func superscript(_ n: Int) -> String {
        let digits: [Character] = ["⁰", "¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "⁹"]
        return String(String(n).compactMap { $0.wholeNumberValue.map { digits[$0] } })
    }

    /// `value / scale` written as a terminating decimal: (375, 1000) is "0.375", (125, 10) is "12.5".
    private static func decimal(_ value: Int, over scale: Int) -> String {
        let whole = value / scale
        var fraction = String(value % scale)
        let places = String(scale).count - 1
        fraction = String(repeating: "0", count: places - fraction.count) + fraction
        while fraction.hasSuffix("0") { fraction.removeLast() }
        return fraction.isEmpty ? "\(whole)" : "\(whole).\(fraction)"
    }

    private static func gcd(_ a: Int, _ b: Int) -> Int {
        b == 0 ? a : gcd(b, a % b)
    }
}

enum FactSprintDeck {
    /// Last time's misses first, in the order she met them, then the rest of the family shuffled.
    static func build(family: FactFamily, missedLastTime: [String], rng: inout some RandomNumberGenerator) -> [Fact] {
        let catalog = FactCatalog.facts(family)
        let byId = Dictionary(uniqueKeysWithValues: catalog.map { ($0.id, $0) })
        var placed = Set<String>()
        let first = missedLastTime.compactMap { id -> Fact? in
            guard let fact = byId[id], placed.insert(id).inserted else { return nil }
            return fact
        }
        return first + catalog.filter { !placed.contains($0.id) }.shuffled(using: &rng)
    }
}

/// One 20-second sprint through a deck. Each answer is marked once and the next fact follows: there is
/// no second try inside a sprint.
struct FactSprintRun: Sendable {
    static let seconds = 20

    enum Phase: Equatable, Sendable {
        case ready
        case running(startedAt: Date)
        case finished
    }

    enum Outcome: Equatable, Sendable {
        case right
        case wrong(Fact)
    }

    let deck: [Fact]
    private(set) var phase: Phase = .ready
    private(set) var right: [Fact] = []
    private(set) var missed: [Fact] = []

    init(deck: [Fact]) {
        self.deck = deck
    }

    var current: Fact? {
        let next = right.count + missed.count
        guard phase != .finished, next < deck.count else { return nil }
        return deck[next]
    }

    mutating func start(at date: Date) {
        guard phase == .ready else { return }
        phase = .running(startedAt: date)
    }

    mutating func submit(typed: String, at date: Date) -> Outcome? {
        guard remaining(at: date) > 0, case .running = phase, let fact = current,
              !typed.trimmingCharacters(in: .whitespaces).isEmpty
        else { return nil }
        if SpeedMathAnswerCheck.isCorrect(typed: typed, expected: fact.answer) {
            right.append(fact)
            return .right
        }
        missed.append(fact)
        return .wrong(fact)
    }

    mutating func finish() {
        guard case .running = phase else { return }
        phase = .finished
    }

    func remaining(at date: Date) -> TimeInterval {
        switch phase {
        case .ready: TimeInterval(Self.seconds)
        case .running(let startedAt): max(0, startedAt.addingTimeInterval(TimeInterval(Self.seconds)).timeIntervalSince(date))
        case .finished: 0
        }
    }
}
