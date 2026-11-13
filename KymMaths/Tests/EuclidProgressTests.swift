import Foundation
import Testing
@testable import KymMaths

@Suite("Euclid progress")
struct EuclidProgressTests {
    @Test("Levels are earned one at a time, in order")
    func inOrder() {
        var progress = EuclidProgress()
        #expect(progress.record(.letters, for: "I.1", assisted: false) == .notNext)
        #expect(progress.highest("I.1") == nil)
        #expect(progress.record(.picture, for: "I.1", assisted: false) == .advanced(to: .picture))
        #expect(progress.record(.head, for: "I.1", assisted: false) == .notNext, "letters comes before head")
        #expect(progress.record(.picture, for: "I.1", assisted: false) == .notNext, "already held")
        #expect(progress.record(.letters, for: "I.1", assisted: false) == .advanced(to: .letters))
        #expect(progress.highest("I.1") == .letters)
        #expect(progress.nextLevel("I.1") == .head)
    }

    @Test("A level earned with help does not count: the level stays and the record is marked assisted")
    func assistedDoesNotCount() {
        var progress = EuclidProgress()
        #expect(progress.record(.picture, for: "I.9", assisted: true) == .assisted)
        #expect(progress.record(for: "I.9") == EuclidSkillRecord(highest: nil, assisted: true, parentChecked: false))
        #expect(progress.proven.isEmpty)
        #expect(progress.record(.picture, for: "I.9", assisted: false) == .advanced(to: .picture))
        #expect(progress.record(for: "I.9").assisted == false, "a clean attempt clears the marker")
        #expect(progress.proven == ["I.9"])
    }

    @Test("The last level has nothing after it")
    func lastLevel() {
        var progress = EuclidProgress()
        for level in SkillLevel.allCases {
            #expect(progress.record(level, for: "I.10", assisted: false) == .advanced(to: level))
        }
        #expect(progress.nextLevel("I.10") == nil)
        #expect(progress.record(.knowsWhen, for: "I.10", assisted: false) == .notNext)
    }

    @Test("Progress survives a save and a load through UserDefaults")
    func roundTrip() throws {
        let suite = "euclid-progress-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = EuclidProgressStore(defaults: defaults)
        #expect(store.load() == EuclidProgress(), "nothing saved yet")

        var progress = EuclidProgress()
        progress.record(.picture, for: "I.1", assisted: false)
        progress.record(.letters, for: "I.1", assisted: true)
        progress.setParentChecked(true, for: "I.1")
        progress.record(.picture, for: "I.46", assisted: false)
        store.save(progress)

        let loaded = EuclidProgressStore(defaults: defaults).load()
        #expect(loaded == progress)
        #expect(loaded.record(for: "I.1") == EuclidSkillRecord(highest: .picture, assisted: true, parentChecked: true))
        #expect(defaults.data(forKey: "kymmaths.euclid.progress") != nil)
    }
}
