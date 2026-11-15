import Foundation

/// KymMaths draws in The Standard, the design system it shares with the other subject apps and
/// apple_poem (teaching_kit `docs/STANDARD.md`).
enum AppTheme {
    /// Where an old theme of KymMaths's catalogue went when The Standard replaced it: Euclid's
    /// drafting paper becomes Paper, the warm paper themes become Warm, Dusk becomes Dusk, and
    /// every other old id becomes Vivid, which `adoptPatternedDefault` then moves to Follow System.
    static let legacy: [String: String] = [
        "euclid": "parchment",
        "hearth": "sepia",
        "scholar": "sepia",
        "dusk": "dark-graphite"
    ]

    /// Set once the Patterned redesign has chosen this learner's default.
    static let patternedDefaultKey = "kymmaths.theme.patternedDefaultApplied"

    /// The Patterned World reads on paper by day and Dusk at night, so its default is Follow
    /// System. A learner with no choice, or still on Vivid (the old default), moves there once.
    /// Any other choice is kept, and a later choice of Vivid sticks.
    static func adoptPatternedDefault(in defaults: UserDefaults, key: String = StandardThemeStore.subjectAppStorageKey) {
        guard !defaults.bool(forKey: patternedDefaultKey) else { return }
        defaults.set(true, forKey: patternedDefaultKey)
        let stored = defaults.string(forKey: key)
        if stored == nil || stored == StandardTheme.defaultID {
            defaults.set(StandardTheme.systemID, forKey: key)
        }
    }

    /// Moves an old stored choice to its Standard theme, applies the Patterned default once, and
    /// makes the choice the design system's theme. Call it first thing in every process that draws UI.
    static func register(defaults: UserDefaults = .standard) {
        StandardThemeStore.migrateLegacyChoice(in: defaults, legacy: legacy)
        adoptPatternedDefault(in: defaults)
        StandardThemeStore.register(defaults: defaults, legacy: legacy)
    }
}
