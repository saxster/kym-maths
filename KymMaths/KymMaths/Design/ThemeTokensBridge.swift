import SwiftUI

// MARK: - ThemeTokens & WCAG Contrast Audit Bridge

struct ThemeTokens: Equatable, Sendable {
    let scheme: CuratedColorScheme

    static func tokens(for scheme: CuratedColorScheme) -> ThemeTokens {
        ThemeTokens(scheme: scheme)
    }

    var primary: Color { scheme.palette.neutrals.ink.light.color }
    var secondary: Color { scheme.palette.neutrals.mutedInk.light.color }
    var accent: Color { scheme.palette.primary.light.color }
    var accentSubtle: Color { scheme.palette.selectionFill.light.color }
    var surface: Color { scheme.palette.neutrals.surface.light.color }
    var surfaceElevated: Color { scheme.palette.neutrals.elevatedSurface.light.color }
    var borderSubtle: Color { scheme.palette.neutrals.hairline.light.color }
    var positive: Color { Color.kymaiaSuccess }
    var warning: Color { Color.kymaiaWarning }
    var info: Color { scheme.palette.secondary.light.color }

    var primaryContrastRatio: Double {
        scheme.palette.neutrals.ink.light.contrastRatio(with: scheme.palette.neutrals.surface.light)
    }

    var secondaryContrastRatio: Double {
        scheme.palette.neutrals.mutedInk.light.contrastRatio(with: scheme.palette.neutrals.surface.light)
    }

    func passesWCAGAudit() -> Bool {
        primaryContrastRatio >= 7.0 && secondaryContrastRatio >= 4.5
    }
}

private struct ThemeTokensEnvironmentKey: EnvironmentKey {
    static let defaultValue = ThemeTokens.tokens(for: .defaultScheme)
}

extension EnvironmentValues {
    var themeTokens: ThemeTokens {
        get { self[ThemeTokensEnvironmentKey.self] }
        set { self[ThemeTokensEnvironmentKey.self] = newValue }
    }
}

extension CuratedColorScheme {
    var moodSubtitle: String { summary }

    static func loadSaved() -> CuratedColorScheme {
        current
    }

    func persist() {
        UserDefaults.standard.set(rawValue, forKey: Self.storageKey)
    }
}

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

extension ThemePickerMenu {
    init(selection: Binding<CuratedColorScheme>) {
        self.init(onThemeChanged: { scheme in
            selection.wrappedValue = scheme
        })
    }
}

extension MathsSettingsSheet {
    @MainActor
    init() {
        self.init(store: AppStore())
    }
}
