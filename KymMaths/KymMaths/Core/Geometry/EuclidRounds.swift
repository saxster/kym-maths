import Foundation

/// A small seeded generator, so a round is the same every time it is built from the same seed.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

extension PropositionID {
    /// A stable number for seeding: the same on every launch, unlike `hashValue`.
    var stableSeed: UInt64 {
        raw.unicodeScalars.reduce(UInt64(1469598103934665603)) { ($0 ^ UInt64($1.value)) &* 1099511628211 }
    }
}

// MARK: - Spine map

/// Book I laid out in rows by what each proposition stands on.
enum EuclidSpineLayout {
    /// A built proposition sits one row below the deepest thing it uses. An accepted fact sits
    /// in the row above its first user, so it appears just before it is needed.
    static func rows(_ catalog: [EuclidProposition] = EuclidSpine.catalog) -> [[PropositionID]] {
        let byID = Dictionary(catalog.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var builtDepth: [PropositionID: Int] = [:]
        func depth(_ id: PropositionID) -> Int {
            if let known = builtDepth[id] { return known }
            guard let proposition = byID[id], case .built = proposition.kind else { return -1 }
            let value = 1 + (proposition.uses.map(depth).max() ?? -1)
            builtDepth[id] = max(0, value)
            return builtDepth[id]!
        }
        var depths: [PropositionID: Int] = [:]
        for proposition in catalog {
            if case .built = proposition.kind { depths[proposition.id] = depth(proposition.id) }
        }
        for proposition in catalog {
            guard case .accepted = proposition.kind else { continue }
            let users = proposition.unlocks.compactMap { depths[$0] }
            depths[proposition.id] = max(0, (users.min() ?? 1) - 1)
        }
        let deepest = depths.values.max() ?? 0
        return (0...deepest).map { row in
            catalog.filter { depths[$0.id] == row }.map(\.id)
        }
    }

    /// Every "stands on" link, from the proposition used to the one that uses it.
    static func edges(_ catalog: [EuclidProposition] = EuclidSpine.catalog) -> [(from: PropositionID, to: PropositionID)] {
        catalog.flatMap { proposition in proposition.uses.map { (from: $0, to: proposition.id) } }
    }
}

// MARK: - Step-order round

/// The "in your head" round: the proof's steps come shuffled, she puts them back in order, and
/// picks each step's reason from three. Only a round with no reveals and few slips earns the level.
struct StepOrderRound: Equatable {
    let proposition: PropositionID
    let steps: [ProofStep]
    /// The steps as first shown: indices into `steps`.
    let shuffled: [Int]
    /// Three reasons per step, the right one among two others, in a fixed shuffled order.
    let options: [[Justification]]
    private(set) var placed: [Int] = []
    private(set) var justified: Set<Int> = []
    private(set) var mistakes = 0
    private(set) var isAssisted = false

    /// More slips than this and the round is practice, not proof she has it in her head.
    static let allowedMistakes = 2

    init?(proposition: EuclidProposition, seed: UInt64) {
        guard proposition.proofSteps.count >= 2 else { return nil }
        var rng = SplitMix64(seed: seed ^ proposition.id.stableSeed)
        self.proposition = proposition.id
        steps = proposition.proofSteps
        var order = Array(steps.indices).shuffled(using: &rng)
        if order == Array(steps.indices) { order.append(order.removeFirst()) }
        shuffled = order
        let reasons = Self.reasonPool
        options = steps.map { step in
            let others = reasons.filter { $0 != step.because }.shuffled(using: &rng).prefix(2)
            return ([step.because] + others).shuffled(using: &rng)
        }
    }

    /// Every reason a proof in the catalog gives, so the wrong options are real reasons too.
    static var reasonPool: [Justification] {
        var seen: [Justification] = []
        for step in EuclidSpine.catalog.flatMap(\.proofSteps) where !seen.contains(step.because) {
            seen.append(step.because)
        }
        return seen
    }

    var pool: [Int] { shuffled.filter { !placed.contains($0) } }
    var isComplete: Bool { placed.count == steps.count && justified.count == steps.count }
    var earnsHead: Bool { isComplete && !isAssisted && mistakes <= Self.allowedMistakes }

    /// The steps that may go next. Steps side by side with the same reason do not depend on
    /// each other (the two I.41 halves of I.47, say), so either may come first.
    var acceptableNext: Set<Int> {
        let position = placed.count
        guard position < steps.count else { return [] }
        var run = position
        while run > 0, steps[run - 1].because == steps[position].because { run -= 1 }
        var end = position
        while end + 1 < steps.count, steps[end + 1].because == steps[position].because { end += 1 }
        return Set((run...end).filter { !placed.contains($0) })
    }

    /// Puts a step next. A step that can't come yet stays where it is and counts as a slip.
    @discardableResult
    mutating func place(_ index: Int) -> Bool {
        guard pool.contains(index) else { return false }
        guard acceptableNext.contains(index) else {
            mistakes += 1
            return false
        }
        placed.append(index)
        return true
    }

    /// Picks a reason for a placed step.
    @discardableResult
    mutating func justify(_ index: Int, with reason: Justification) -> Bool {
        guard placed.contains(index), !justified.contains(index) else { return false }
        guard steps[index].because == reason else {
            mistakes += 1
            return false
        }
        justified.insert(index)
        return true
    }

    /// Shows the next step and its reason. The round still finishes, but it no longer counts.
    mutating func revealNext() {
        isAssisted = true
        if let next = placed.first(where: { !justified.contains($0) }) {
            justified.insert(next)
            return
        }
        guard let next = acceptableNext.min() else { return }
        placed.append(next)
        justified.insert(next)
    }
}

// MARK: - Knows when

/// A word problem with no figure, for the Daily Flow: which proposition solves it?
struct EuclidKnowsWhenQuestion: Equatable, Sendable {
    let proposition: PropositionID
    let problem: String
    /// Three propositions she has built, the answer among them.
    let options: [PropositionID]
}

enum EuclidKnowsWhen {
    /// The earliest proposition she has in her head but has not yet shown she knows when to use.
    /// Every wrong option is one she has proven, so the question waits until she has proven two
    /// besides the answer: with one wrong option, a guess would light the last lamp half the time.
    static func select(progress: EuclidProgress, catalog: [EuclidProposition] = EuclidSpine.catalog) -> EuclidKnowsWhenQuestion? {
        let asked = catalog.filter { $0.knowsWhen != nil }
        guard let target = asked.first(where: { progress.highest($0.id) == .head }),
              let prompt = target.knowsWhen else { return nil }
        let proven = progress.proven
        let candidates = asked.map(\.id).filter { $0 != prompt.answer && proven.contains($0) }
        guard candidates.count >= 2 else { return nil }
        var rng = SplitMix64(seed: target.id.stableSeed)
        let others = candidates.shuffled(using: &rng).prefix(2)
        return EuclidKnowsWhenQuestion(
            proposition: target.id,
            problem: prompt.problem,
            options: ([prompt.answer] + others).shuffled(using: &rng)
        )
    }

    /// Her first answer. A right one lights the last lamp; a wrong one records nothing.
    static func answer(_ choice: PropositionID, to question: EuclidKnowsWhenQuestion, progress: inout EuclidProgress) -> Bool {
        guard let answer = EuclidSpine.proposition(question.proposition)?.knowsWhen?.answer, choice == answer else { return false }
        progress.record(.knowsWhen, for: question.proposition, assisted: false)
        return true
    }
}

/// One showing of a knows-when question. It keeps the question it was shown with, so the card
/// stays put with its feedback after a right answer lights the lamp and the selector moves on.
struct EuclidKnowsWhenAttempt: Equatable {
    let question: EuclidKnowsWhenQuestion
    private(set) var choice: PropositionID?
    private(set) var isRight = false

    init(question: EuclidKnowsWhenQuestion) {
        self.question = question
    }

    /// Only the first answer counts.
    mutating func choose(_ option: PropositionID, progress: inout EuclidProgress) {
        guard choice == nil else { return }
        choice = option
        isRight = EuclidKnowsWhen.answer(option, to: question, progress: &progress)
    }
}

// MARK: - Links from the book

/// Where the rest of the app opens the workshop. One table, so a widget gains its button by
/// gaining a row here.
enum EuclidBuildLinks {
    static let widgets: [String: PropositionID] = [
        "w_euclid_compass_locus": "I.10",
        "w_pythagoras_garfield_proof": "I.47",
    ]

    /// The chapter whose page opens the spine map: OUP 3.4 Constructions.
    static let mapChapter = "ch09"
}
