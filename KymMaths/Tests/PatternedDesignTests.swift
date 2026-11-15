import Foundation
import Testing
@testable import KymMaths

@Suite("Patterned design system")
struct PatternedDesignTests {
    @Test("Byrne markup colours the marked words and keeps the rest as plain text")
    func byrneMarkupSplitsRuns() {
        let runs = ByrneMarkup.parse("Put {blue:an arrow} on the line; {red:turn it} and {stays:its length} holds.")
        #expect(runs == [
            .init(text: "Put ", role: nil),
            .init(text: "an arrow", role: .given),
            .init(text: " on the line; ", role: nil),
            .init(text: "turn it", role: .moves),
            .init(text: " and ", role: nil),
            .init(text: "its length", role: .stays),
            .init(text: " holds.", role: nil),
        ])
        #expect(ByrneMarkup.plain("Put {blue:an arrow} here") == "Put an arrow here")
    }

    @Test("Unknown tags and unclosed braces stay as written")
    func byrneMarkupLeavesOtherBracesAlone() {
        #expect(ByrneMarkup.plain("the set {1, 2, 3}") == "the set {1, 2, 3}")
        #expect(ByrneMarkup.plain("{green:not a role} and {red:open") == "{green:not a role} and {red:open")
        #expect(ByrneMarkup.parse("{1:2} {red:x}").last == .init(text: "x", role: .moves))
    }

    @Test("Paper and Night carry the Figma values, and a dark theme picks Night")
    func paletteFollowsTheTheme() {
        #expect(PatternedPalette.paper.red == 0xC3362B)
        #expect(PatternedPalette.night.blue == 0x7097DA)
        for theme in StandardTheme.all {
            #expect(theme.patterned == (theme.isDark ? .night : .paper), "\(theme.id)")
        }
    }

    @Test("The Patterned default moves an empty or Vivid choice to Follow System once, and keeps any other")
    func patternedDefaultIsAppliedOnce() throws {
        let suite = "PatternedDesignTests.theme.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let key = StandardThemeStore.subjectAppStorageKey

        AppTheme.adoptPatternedDefault(in: defaults)
        #expect(defaults.string(forKey: key) == StandardTheme.systemID, "no choice becomes Follow System")

        defaults.set("vivid", forKey: key)
        AppTheme.adoptPatternedDefault(in: defaults)
        #expect(defaults.string(forKey: key) == "vivid", "a Vivid chosen after the move sticks")

        defaults.removePersistentDomain(forName: suite)
        defaults.set("vivid", forKey: key)
        AppTheme.adoptPatternedDefault(in: defaults)
        #expect(defaults.string(forKey: key) == StandardTheme.systemID, "the old Vivid default moves")

        defaults.removePersistentDomain(forName: suite)
        defaults.set("dark-ink", forKey: key)
        AppTheme.adoptPatternedDefault(in: defaults)
        #expect(defaults.string(forKey: key) == "dark-ink", "a deliberate choice is kept")
    }

    @Test("Lamps read out how far a skill has come, and clamp to four")
    func lampsDescribeThemselves() {
        #expect(SkillLamps.accessibilityText(lit: 0) == "No lamps lit yet")
        #expect(SkillLamps.accessibilityText(lit: 2) == "2 of 4 lamps lit, up to in letters")
        #expect(SkillLamps.accessibilityText(lit: 4) == "4 of 4 lamps lit, up to knows when")
    }

    @MainActor
    @Test("Up next is the first open proposition with no lamp lit")
    func upNextFollowsProgress() {
        let store = AppStore()
        store.useEphemeralEuclidProgress(EuclidProgress())
        #expect(store.euclidUpNext?.id == "I.1")
        _ = store.recordEuclid(.picture, for: "I.1", assisted: false)
        let next = store.euclidUpNext
        #expect(next != nil && next?.id != "I.1")
        if let next {
            #expect(EuclidSpine.isOpen(next.id, progress: store.euclidProgress))
        }
    }
}
