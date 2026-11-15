import Foundation

/// The fade path of one skill, in the order it must be earned (docs/EUCLID_SPINE.md, "Fade path").
enum SkillLevel: Int, Codable, CaseIterable, Comparable {
    /// She solves the construction on the Byrne board.
    case picture
    /// She solves it again in the Letters layer, A, B, C in place of colour.
    case letters
    /// She orders the proof's steps and names each justification, with no hint above R2.
    case head
    /// She picks this proposition for a word problem with no figure.
    case knowsWhen

    static func < (lhs: SkillLevel, rhs: SkillLevel) -> Bool { lhs.rawValue < rhs.rawValue }

    var title: String {
        switch self {
        case .picture: "With the picture"
        case .letters: "In letters"
        case .head: "In her head"
        case .knowsWhen: "Knows when"
        }
    }

    var next: SkillLevel? { SkillLevel(rawValue: rawValue + 1) }
}

struct EuclidSkillRecord: Codable, Equatable {
    var highest: SkillLevel?
    /// Her last try at the next level used help, so it did not count.
    var assisted = false
    /// A parent saw the device-off check done on paper.
    var parentChecked = false
}

enum ProgressOutcome: Equatable {
    case advanced(to: SkillLevel)
    /// The level was earned with help, so it stays where it was.
    case assisted
    /// Levels are earned in order; this one is not next.
    case notNext
}

/// Kym's levels across the spine. Encodes as `{"records": {id: EuclidSkillRecord}}`, keyed by proposition id.
struct EuclidProgress: Codable, Equatable {
    private var records: [String: EuclidSkillRecord] = [:]

    func record(for id: PropositionID) -> EuclidSkillRecord {
        records[id.raw] ?? EuclidSkillRecord()
    }

    func highest(_ id: PropositionID) -> SkillLevel? {
        record(for: id).highest
    }

    /// The level she is working towards.
    func nextLevel(_ id: PropositionID) -> SkillLevel? {
        guard let highest = highest(id) else { return .picture }
        return highest.next
    }

    /// Proven at least with the picture: these become tools.
    var proven: Set<PropositionID> {
        Set(records.compactMap { $0.value.highest == nil ? nil : PropositionID($0.key) })
    }

    @discardableResult
    mutating func record(_ level: SkillLevel, for id: PropositionID, assisted: Bool) -> ProgressOutcome {
        var record = record(for: id)
        if let highest = record.highest, level <= highest { return .notNext }
        guard level == nextLevel(id) else { return .notNext }
        if assisted {
            record.assisted = true
            records[id.raw] = record
            return .assisted
        }
        record.highest = level
        record.assisted = false
        records[id.raw] = record
        return .advanced(to: level)
    }

    mutating func setParentChecked(_ checked: Bool, for id: PropositionID) {
        var record = record(for: id)
        record.parentChecked = checked
        records[id.raw] = record
    }
}

extension EuclidSpine {
    /// The built propositions `id` stands on that she has not yet proven with the picture.
    /// Accepted facts never hold anything back.
    static func needs(_ id: PropositionID, progress: EuclidProgress) -> [PropositionID] {
        let proven = progress.proven
        return (proposition(id)?.uses ?? []).filter { used in
            guard case .built? = proposition(used)?.kind else { return false }
            return !proven.contains(used)
        }
    }

    /// A proposition opens once everything built that it stands on is proven.
    static func isOpen(_ id: PropositionID, progress: EuclidProgress) -> Bool {
        proposition(id) != nil && needs(id, progress: progress).isEmpty
    }
}

/// Saves progress as JSON in UserDefaults, the way `AppStore` keeps its preferences.
struct EuclidProgressStore {
    static let key = "kymmaths.euclid.progress"
    let defaults: UserDefaults

    func load() -> EuclidProgress {
        guard let data = defaults.data(forKey: Self.key),
              let progress = try? JSONDecoder().decode(EuclidProgress.self, from: data) else { return EuclidProgress() }
        return progress
    }

    func save(_ progress: EuclidProgress) {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
