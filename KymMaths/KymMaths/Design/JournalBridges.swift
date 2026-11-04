import SwiftUI

// MARK: - Spacing & Typography Bridges

extension Spacing {
    public static let xxs: CGFloat = 2
    public static let radiusSM: CGFloat = CornerRadius.small
    public static let radiusMD: CGFloat = CornerRadius.medium
    public static let radiusLG: CGFloat = CornerRadius.large
}

enum Typography {
    static var largeTitle: Font { .kymaiaAppTitle }
    static var title2: Font { .kymaiaTitle2 }
    static var title3: Font { .kymaiaTitle3 }
    static var headline: Font { .kymaiaHeadline }
    static var subheadline: Font { .kymaiaSubheadline }
    static var body: Font { .kymaiaBody }
    static var callout: Font { .callout }
    static var caption: Font { .kymaiaCaption }
    static var eyebrow: Font { .kymaiaEyebrow }
    static var mono: Font { .kymaiaMonospaced }
    static var numericFormula: Font { .system(.title3, design: .monospaced).weight(.semibold) }
}

// MARK: - Button Styles

struct JournalPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        JournalCapsuleButtonStyle(prominence: .filled, size: .regular)
            .makeBody(configuration: configuration)
    }
}

struct JournalSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        JournalCapsuleButtonStyle(prominence: .tinted, size: .small)
            .makeBody(configuration: configuration)
    }
}

// MARK: - JournalPage, JournalSection, JournalBadge & JournalChip Overloads

extension JournalPage {
    init(@ViewBuilder content: () -> Content) {
        self.init(title: "", content: content)
    }
}

extension JournalSection {
    init(title: String, eyebrow: String, @ViewBuilder content: () -> Content) {
        self.init(title: "\(eyebrow) · \(title)", seeAllIdentifier: nil, seeAll: nil, content: content)
    }
}

enum JournalBadgeTone: Equatable, Sendable {
    case accent
    case positive
    case warning
    case info
    case neutral
}

extension JournalBadge {
    init(text: String, symbol: String, tone: JournalBadgeTone = .accent) {
        let color: Color = {
            switch tone {
            case .accent: return .kymaiaPrimary
            case .positive: return .kymaiaSuccess
            case .warning: return .kymaiaWarning
            case .info: return .kymaiaSecondary
            case .neutral: return .kymaiaMutedInk
            }
        }()
        self.init(symbol: symbol, tint: color, size: .small, labelText: text)
    }
}

extension JournalChip {
    init(title: String, systemImage: String, isSelected: Bool, action: @escaping () -> Void) {
        self.init(text: title, tone: isSelected ? .accent : .muted, systemImage: systemImage, action: action)
    }
}

// MARK: - AdaptiveOptionPicker Convenience Init

extension AdaptiveOptionPicker {
    init(
        options: [Option],
        selection: Binding<Option>,
        label: @escaping (Option) -> String
    ) {
        self.init("Select Option", selection: selection, options: options, titleForOption: label)
    }
}

// MARK: - LearnerTextInput & NumericKeypadField Views

struct LearnerTextInput: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 96

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(Typography.caption.weight(.semibold))
                .foregroundStyle(Color.kymaiaInk)
            TextEditor(text: $text)
                .learnerTextInput(.retrieval)
                .font(Typography.body)
                .frame(minHeight: minHeight)
                .padding(Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                        .fill(Color.kymaiaSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                        .strokeBorder(Color.kymaiaControlBorder, lineWidth: 1)
                )
        }
    }
}

struct NumericKeypadField: View {
    let label: String
    let unitLabel: String
    @Binding var text: String
    var onSubmit: () -> Void

    var body: some View {
        HStack(spacing: Spacing.xs) {
            TextField(label, text: $text)
                .learnerTextInput(.retrieval)
                .textFieldStyle(.roundedBorder)
                .font(Typography.mono)
                .onSubmit(onSubmit)
            if !unitLabel.isEmpty {
                Text(unitLabel)
                    .font(Typography.mono)
                    .foregroundStyle(Color.kymaiaMutedInk)
            }
        }
    }
}

extension MathsSettingsSheet {
    @MainActor
    init() {
        self.init(store: AppStore())
    }
}
