import SwiftUI

// Small pieces the Atlas and Pólya rooms share. Each is a candidate for `Design/Patterned/`.

/// A room's opening: the kit's `EditorialHeader`, with one quiet outline button beside it that
/// moves between a room's two modes (the Atlas labs and its recall page). Below about 560 pt the
/// button drops under the header.
struct RoomHeaderRow: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let switchTitle: String
    let switchSymbol: String
    let onSwitch: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: StandardSpacing.md) {
                header.frame(minWidth: 400, idealWidth: 400, maxWidth: .infinity, alignment: .leading)
                switchButton.fixedSize()
            }
            VStack(alignment: .leading, spacing: 0) {
                header
                switchButton
                    .padding(.top, -StandardSpacing.sm)
                    .padding(.bottom, StandardSpacing.md)
            }
        }
    }

    private var header: some View {
        EditorialHeader(eyebrow: eyebrow, title: title, subtitle: subtitle)
    }

    private var switchButton: some View {
        Button(action: onSwitch) {
            Label(switchTitle, systemImage: switchSymbol)
        }
        .buttonStyle(OutlineButtonStyle())
    }
}

/// Seed-pack wording made plain for a reader: template prefixes off.
enum RoomCopy {
    /// Drops a template prefix such as "Formula Anatomy: " when the text starts with it.
    static func dropping(_ prefix: String, from text: String) -> String {
        text.hasPrefix(prefix) ? String(text.dropFirst(prefix.count)) : text
    }

    /// "1. Concrete Touch" → "Concrete Touch".
    static func droppingNumber(_ text: String) -> String {
        guard let dot = text.firstIndex(of: "."),
              text[..<dot].allSatisfy(\.isNumber),
              !text[..<dot].isEmpty else { return text }
        return text[text.index(after: dot)...].trimmingCharacters(in: .whitespaces)
    }

    /// A chapter title's first clause, for a kicker: "Sets, Venn Regions & …" → "Sets".
    static func shortChapterTitle(_ title: String) -> String {
        let cut = title.firstIndex(where: { $0 == "," || $0 == ":" }) ?? title.endIndex
        return String(title[..<cut]).trimmingCharacters(in: .whitespaces)
    }
}
