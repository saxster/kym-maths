import Foundation

struct MotifRecord: Codable, Equatable {
    /// She answered the check on the motif board without help.
    var solved = false
    /// Her last right answer came after the helper line was shown, so it did not count.
    var assisted = false
    /// A parent saw the device-off check done on paper.
    var parentChecked = false
}

/// Kym's motifs, keyed by motif id. Only the picture level exists so far.
struct MotifProgress: Codable, Equatable {
    private var records: [String: MotifRecord] = [:]

    func record(for id: MotifID) -> MotifRecord {
        records[id.raw] ?? MotifRecord()
    }

    @discardableResult
    mutating func recordPicture(for id: MotifID, assisted: Bool) -> ProgressOutcome {
        var record = record(for: id)
        guard !record.solved else { return .notNext }
        if assisted {
            record.assisted = true
            records[id.raw] = record
            return .assisted
        }
        record.solved = true
        record.assisted = false
        records[id.raw] = record
        return .advanced(to: .picture)
    }

    mutating func setParentChecked(_ checked: Bool, for id: MotifID) {
        var record = record(for: id)
        record.parentChecked = checked
        records[id.raw] = record
    }
}

/// Saves motif progress as JSON in UserDefaults, beside the Euclid progress.
struct MotifProgressStore {
    static let key = "kymmaths.motif.progress"
    let defaults: UserDefaults

    func load() -> MotifProgress {
        guard let data = defaults.data(forKey: Self.key),
              let progress = try? JSONDecoder().decode(MotifProgress.self, from: data) else { return MotifProgress() }
        return progress
    }

    func save(_ progress: MotifProgress) {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
