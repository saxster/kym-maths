import SwiftUI

/// The header of a planner or settings sheet: an optional kicker, a serif title, a line under it
/// and a close button. Shared by Settings and Deadlines.
struct PaperSheetHeader: View {
    @Environment(\.standardTheme) private var theme
    private let kicker: String?
    private let title: String
    private let subtitle: String?
    private let close: () -> Void

    init(kicker: String? = nil, title: String, subtitle: String? = nil, close: @escaping () -> Void) {
        self.kicker = kicker
        self.title = title
        self.subtitle = subtitle
        self.close = close
    }

    var body: some View {
        HStack(alignment: .top, spacing: StandardSpacing.md) {
            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                if let kicker { Kicker(kicker) }
                Text(title)
                    .standardType(.headlineLg)
                    .foregroundStyle(theme.ink)
                    .accessibilityAddTraits(.isHeader)
                if let subtitle {
                    Text(subtitle)
                        .standardType(.uiBody)
                        .foregroundStyle(theme.mute(theme.ink))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            Button(action: close) {
                Image(systemName: "xmark")
                    .standardType(.uiHeadline).fontWeight(.regular)
                    .foregroundStyle(theme.ink)
                    .frame(width: StandardAccessibility.touchTarget, height: StandardAccessibility.touchTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
    }
}

/// A labelled field on paper: a small label over a bordered box.
struct PaperFieldLabel: View {
    @Environment(\.standardTheme) private var theme
    private let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .standardType(.uiBody)
            .foregroundStyle(theme.mute(theme.ink))
    }
}
