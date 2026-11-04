import Foundation

/// KymMaths draws in The Standard, the design system it shares with the other subject apps and
/// apple_poem (teaching_kit `docs/STANDARD.md`).
enum AppTheme {
    /// Where an old theme of KymMaths's catalogue went when The Standard replaced it: Euclid's
    /// drafting paper becomes Paper, the warm paper themes become Warm, Dusk becomes Dusk, and
    /// every other old id becomes Vivid, the new default.
    static let legacy: [String: String] = [
        "euclid": "parchment",
        "hearth": "sepia",
        "scholar": "sepia",
        "dusk": "dark-graphite"
    ]

    /// Moves an old stored choice to its Standard theme and makes the choice the design system's
    /// theme. Call it first thing in every process that draws UI.
    static func register(defaults: UserDefaults = .standard) {
        StandardThemeStore.register(defaults: defaults, legacy: legacy)
    }
}
