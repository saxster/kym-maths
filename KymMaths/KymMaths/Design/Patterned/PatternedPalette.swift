import SwiftUI

/// Byrne's three colours. They mark maths objects only, and a colour means the same thing in a
/// sentence as in the figure beside it. Chrome never uses them.
enum ByrneRole: String, CaseIterable, Sendable {
    /// Red: the thing that moves or changes.
    case moves
    /// Yellow: the thing that stays the same, the key idea.
    case stays
    /// Blue: the given, the thing you start from.
    case given

    /// Markup names a writer may use: `{red:…}` and `{moves:…}` are the same role.
    init?(markup: String) {
        switch markup.lowercased() {
        case "red", "moves": self = .moves
        case "yellow", "stays": self = .stays
        case "blue", "given": self = .given
        default: return nil
        }
    }
}

/// The colours the Figma file adds to The Standard's paper, ink and brass: Byrne's three, their
/// washes, the learning states, and the margin and sunk paper tones. Paper values are for light
/// themes and Night values for dark ones, picked by the active theme.
struct PatternedPalette: Equatable, Sendable {
    let red: UInt32
    let yellow: UInt32
    let blue: UInt32
    let redWash: UInt32
    let yellowWash: UInt32
    let blueWash: UInt32
    let proven: UInt32
    let provenWash: UInt32
    let assisted: UInt32
    let locked: UInt32
    let margin: UInt32
    let sunk: UInt32

    static let paper = PatternedPalette(
        red: 0xC3362B, yellow: 0xE2A41C, blue: 0x23519C,
        redWash: 0xF6DCD5, yellowWash: 0xF8EACB, blueWash: 0xDCE4F2,
        proven: 0x4F6B45, provenWash: 0xE1E8D8, assisted: 0x9A6A1E, locked: 0xA39A88,
        margin: 0xF1EADC, sunk: 0xEEE6D6
    )

    static let night = PatternedPalette(
        red: 0xE5614F, yellow: 0xF0BC45, blue: 0x7097DA,
        redWash: 0x3A1D18, yellowWash: 0x3A2E14, blueWash: 0x17233A,
        proven: 0x9DB88C, provenWash: 0x1E2A1A, assisted: 0xD9A651, locked: 0x575045,
        // Dusk's surface (0x181A1D) is lighter than Figma's night page, so a sunk tone below it
        // read as a hole. On dark paper a track or field sits one step above the surface instead.
        margin: 0x181612, sunk: 0x3A3631
    )

    func color(_ role: ByrneRole) -> Color {
        switch role {
        case .moves: Self.color(red)
        case .stays: Self.color(yellow)
        case .given: Self.color(blue)
        }
    }

    func wash(_ role: ByrneRole) -> Color {
        switch role {
        case .moves: Self.color(redWash)
        case .stays: Self.color(yellowWash)
        case .given: Self.color(blueWash)
        }
    }

    var provenColor: Color { Self.color(proven) }
    var provenWashColor: Color { Self.color(provenWash) }
    var assistedColor: Color { Self.color(assisted) }
    var lockedColor: Color { Self.color(locked) }
    var marginColor: Color { Self.color(margin) }
    var sunkColor: Color { Self.color(sunk) }

    static func color(_ hex: UInt32) -> Color { KymaiaRGBA(hex: hex).color }
}

extension StandardTheme {
    /// The Patterned colours that sit with this theme: Night on dark themes, Paper on light ones.
    var patterned: PatternedPalette { isDark ? .night : .paper }
}
