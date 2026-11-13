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

    @Test("A built proposition opens only once every built proposition it stands on is proven")
    func opensInOrder() {
        var progress = EuclidProgress()
        #expect(EuclidSpine.isOpen("I.1", progress: progress), "I.1 stands on nothing")
        #expect(!EuclidSpine.isOpen("I.9", progress: progress))
        #expect(EuclidSpine.needs("I.10", progress: progress) == ["I.1", "I.9"], "I.4 is accepted, so it never gates")

        progress.record(.picture, for: "I.1", assisted: false)
        #expect(EuclidSpine.isOpen("I.9", progress: progress) && EuclidSpine.isOpen("I.11", progress: progress))
        #expect(!EuclidSpine.isOpen("I.10", progress: progress))
        #expect(EuclidSpine.needs("I.10", progress: progress) == ["I.9"])

        progress.record(.picture, for: "I.9", assisted: true)
        #expect(!EuclidSpine.isOpen("I.10", progress: progress), "a try with help does not prove I.9")
        progress.record(.picture, for: "I.9", assisted: false)
        #expect(EuclidSpine.isOpen("I.10", progress: progress))

        #expect(EuclidSpine.needs("I.47", progress: progress) == ["I.46", "I.10"])
        #expect(EuclidSpine.isOpen("I.8", progress: EuclidProgress()), "an accepted fact is never locked")
        #expect(!EuclidSpine.isOpen("I.99", progress: progress))
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
