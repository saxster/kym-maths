import AVFoundation
import Observation
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

/// Every room's secondary action. It draws as the Patterned outline button, so rooms not yet
/// redrawn already lose their tinted capsules.
struct JournalSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        OutlineButtonStyle().makeBody(configuration: configuration)
    }
}

// MARK: - JournalPage, JournalSection & JournalBadge Overloads

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

// MARK: - MathSymbolRibbon, LearnerTextInput & NumericKeypadField Views

struct MathSymbolToken: Identifiable, Hashable, Sendable {
    let id: String
    let label: String
    let insertion: String
    let accessibilityName: String

    static let standardTokens: [MathSymbolToken] = [
        MathSymbolToken(id: "sq", label: "x²", insertion: "²", accessibilityName: "squared"),
        MathSymbolToken(id: "cube", label: "x³", insertion: "³", accessibilityName: "cubed"),
        MathSymbolToken(id: "sqrt", label: "√(", insertion: "√(", accessibilityName: "square root"),
        MathSymbolToken(id: "frac", label: "a/b", insertion: "/", accessibilityName: "fraction slash"),
        MathSymbolToken(id: "mul", label: "×", insertion: " × ", accessibilityName: "multiply"),
        MathSymbolToken(id: "div", label: "÷", insertion: " ÷ ", accessibilityName: "divide"),
        MathSymbolToken(id: "pm", label: "±", insertion: "±", accessibilityName: "plus or minus"),
        MathSymbolToken(id: "eq", label: "=", insertion: " = ", accessibilityName: "equals"),
        MathSymbolToken(id: "implies", label: "⇒", insertion: " ⇒ ", accessibilityName: "implies"),
        MathSymbolToken(id: "le", label: "≤", insertion: " ≤ ", accessibilityName: "less than or equal"),
        MathSymbolToken(id: "ge", label: "≥", insertion: " ≥ ", accessibilityName: "greater than or equal"),
        MathSymbolToken(id: "pi", label: "π", insertion: "π", accessibilityName: "pi"),
        MathSymbolToken(id: "deg", label: "°", insertion: "°", accessibilityName: "degrees"),
        MathSymbolToken(id: "cap", label: "∩", insertion: " ∩ ", accessibilityName: "intersection"),
        MathSymbolToken(id: "cup", label: "∪", insertion: " ∪ ", accessibilityName: "union"),
        MathSymbolToken(id: "delta", label: "Δ", insertion: "Δ", accessibilityName: "delta"),
        MathSymbolToken(id: "int", label: "∫", insertion: "∫", accessibilityName: "integral"),
        MathSymbolToken(id: "pct", label: "%", insertion: "%", accessibilityName: "percent")
    ]
}

/// A row of maths keys above a text field: tap one and its symbol goes into the text.
struct MathSymbolRibbon: View {
    @Environment(\.standardTheme) private var theme
    @Binding var text: String
    var tokens: [MathSymbolToken] = MathSymbolToken.standardTokens

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: StandardSpacing.xxs) {
                ForEach(tokens) { token in
                    Button {
                        text.append(token.insertion)
                    } label: {
                        Text(token.label)
                            .patternedType(.mathInline)
                            .foregroundStyle(theme.ink)
                            .padding(.horizontal, StandardSpacing.xs)
                            .frame(minWidth: StandardAccessibility.touchTarget, minHeight: StandardAccessibility.touchTarget)
                            .background(
                                RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                                    .fill(theme.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                                    .strokeBorder(theme.hairline(), lineWidth: 1)
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Insert \(token.accessibilityName)")
                }
            }
            .padding(.vertical, 2)
        }
    }
}

/// Where the reader writes in her own words. What she types shows in her handwriting, in Byrne
/// blue, on the sunk margin paper, as in the Figma "Your turn" and "Your working" boxes.
struct LearnerTextInput: View {
    @Environment(\.standardTheme) private var theme
    let title: String
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 96
    var showMathRibbon: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            if !title.isEmpty {
                Text(title)
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if showMathRibbon {
                MathSymbolRibbon(text: $text)
            }
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .learnerTextInput(.retrieval)
                    .patternedType(.hand)
                    .foregroundStyle(theme.patterned.color(.given))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: minHeight)
                    .padding(StandardSpacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                            .fill(theme.patterned.marginColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                            .strokeBorder(theme.hairline(), lineWidth: 1)
                    )
                    .accessibilityLabel(title.isEmpty ? placeholder : title)
                if text.isEmpty && !placeholder.isEmpty {
                    Text(placeholder)
                        .patternedType(.readingSmall)
                        .foregroundStyle(theme.mute(theme.ink))
                        .padding(.horizontal, StandardSpacing.md)
                        .padding(.vertical, StandardSpacing.md)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
        }
    }
}

// MARK: - Term colours

/// The colour a seed-pack term takes, by its role. Red, amber and blue are Byrne's: red moves,
/// amber (his yellow) stays the same, blue is given. Green is not one of Byrne's; the figures use
/// it for a settled result, so it takes the proven tone. Yellow type is too pale to read, so a
/// yellow term keeps the ink colour and sits on its wash, as `ByrneText` does.
private struct TermTone {
    let swatch: Color
    let text: Color
    let wash: Color
    let marksWithWash: Bool

    init(role: String, theme: StandardTheme) {
        let palette = theme.patterned
        switch role.lowercased() {
        case "red":
            swatch = palette.color(.moves); text = swatch; wash = palette.wash(.moves); marksWithWash = false
        case "blue":
            swatch = palette.color(.given); text = swatch; wash = palette.wash(.given); marksWithWash = false
        case "amber", "yellow":
            swatch = palette.color(.stays); text = theme.ink; wash = palette.wash(.stays); marksWithWash = true
        case "green":
            swatch = palette.provenColor; text = swatch; wash = palette.provenWashColor; marksWithWash = false
        default:
            swatch = theme.ink; text = theme.ink; wash = palette.sunkColor; marksWithWash = false
        }
    }
}

private extension TermTone {
    static func byrne(_ role: ByrneRole, theme: StandardTheme) -> TermTone {
        TermTone(role: role == .moves ? "red" : role == .stays ? "amber" : "blue", theme: theme)
    }
}

/// "What stays the same" in Byrne yellow: the one idea that holds whatever moves.
private struct StaysTheSameNote: View {
    @Environment(\.standardTheme) private var theme
    let label: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
            Text(label)
                .patternedType(.kicker)
                .foregroundStyle(theme.mute(theme.ink))
            Text(text)
                .patternedType(.readingDefault)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, StandardSpacing.md)
        .padding(.vertical, StandardSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                .fill(theme.patterned.wash(.stays))
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Shared Intuition -> Formula Bridge Card

/// The picture-to-formula card: the formula in display maths with each term in its figure colour,
/// the action to try, what stays the same, and a "What if…?" check on one term (a perturbation
/// probe, after Brilliant's micro-checks).
struct IntuitionFormulaBridgeCard: View {
    @Environment(\.standardTheme) private var theme
    let bridge: IntuitionToFormulaBridge
    @Binding var selectedTermSymbol: String?
    /// Off where the page already shows what you do and what stays the same just above the card.
    var showsSteps = true
    var onSelectTerm: ((FormulaTermMapping) -> Void)? = nil
    @State private var revealedPerturbationSymbols: Set<String> = []

    private var activeTerm: FormulaTermMapping? {
        if let sym = selectedTermSymbol,
           let match = bridge.termMappings.first(where: { $0.symbol == sym }) {
            return match
        }
        return bridge.termMappings.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.md) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    Kicker("See why it's true")
                    Spacer(minLength: StandardSpacing.sm)
                    hint
                }
                VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                    Kicker("See why it's true")
                    hint
                }
            }

            VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                ForEach(Array(Self.formulaLines(bridge.formulaDisplay).enumerated()), id: \.offset) { _, line in
                    Text(formulaText(line))
                        .patternedType(.mathDisplay)
                        .foregroundStyle(theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .combine)

            if showsSteps {
                Text(bridge.concreteAction)
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                StaysTheSameNote(label: "What stays the same", text: bridge.ahaInvariant)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: StandardSpacing.xs) {
                    ForEach(bridge.termMappings) { term in
                        termChip(term)
                    }
                }
                .padding(.vertical, 2)
            }

            if let term = activeTerm {
                termDetail(term)
            }
        }
        .paperCard()
        .onChange(of: bridge.formulaDisplay) { _, _ in
            revealedPerturbationSymbols.removeAll()
        }
    }

    private var hint: some View {
        Text("Tap a part below to find it in the picture")
            .standardType(.uiCaption)
            .foregroundStyle(theme.mute(theme.ink))
    }

    private func termChip(_ term: FormulaTermMapping) -> some View {
        let tone = TermTone(role: term.colorRole, theme: theme)
        let isSelected = (activeTerm?.symbol == term.symbol)
        return Button {
            selectedTermSymbol = term.symbol
            onSelectTerm?(term)
        } label: {
            HStack(spacing: StandardSpacing.xs) {
                Circle()
                    .fill(tone.swatch)
                    .frame(width: 9, height: 9)
                Text(term.symbol)
                    .patternedType(.mathInline)
                    .foregroundStyle(tone.text)
                    .lineLimit(1)
            }
            .padding(.horizontal, StandardSpacing.sm)
            .frame(minHeight: StandardAccessibility.touchTarget)
            .background(
                Capsule().fill(isSelected ? tone.wash : theme.surface)
            )
            .overlay(
                Capsule().strokeBorder(isSelected ? tone.swatch : theme.hairline(), lineWidth: isSelected ? 1.5 : 1)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(term.symbol): \(term.visualPart)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func termDetail(_ term: FormulaTermMapping) -> some View {
        let tone = TermTone(role: term.colorRole, theme: theme)
        let isRevealed = revealedPerturbationSymbols.contains(term.symbol)
        return VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.xs) {
                    Text(term.symbol)
                        .patternedType(.mathInline)
                        .foregroundStyle(tone.text)
                    Text("is " + term.visualPart.prefix(1).lowercased() + term.visualPart.dropFirst())
                        .patternedType(.readingDefault)
                        .foregroundStyle(theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(term.meaning)
                    .patternedType(.readingSmall)
                    .foregroundStyle(theme.mute(theme.ink))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)

            Rectangle().fill(theme.hairline()).frame(height: 1)

            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                Kicker("What if…?")
                Text("What if you changed \(term.symbol) and kept everything else the same?")
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if isRevealed {
                    Text("In the picture, the \(term.visualPart) changes with it. Everything else holds still, and what stays the same is still true.")
                        .patternedType(.readingSmall)
                        .foregroundStyle(theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button(isRevealed ? "Hide what happens" : "Show me what happens") {
                    if isRevealed {
                        revealedPerturbationSymbols.remove(term.symbol)
                    } else {
                        revealedPerturbationSymbols.insert(term.symbol)
                    }
                }
                .buttonStyle(OutlineButtonStyle())
            }
        }
        .padding(StandardSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                .fill(theme.patterned.marginColor)
        )
        .overlay(alignment: .leading) {
            UnevenRoundedRectangle(topLeadingRadius: StandardRadius.lg, bottomLeadingRadius: StandardRadius.lg)
                .fill(tone.swatch)
                .frame(width: 3)
        }
    }

    /// The seed pack strings several formulas into one line with wide gaps between them; one per
    /// line reads better at display size.
    static func formulaLines(_ formula: String) -> [String] {
        let separator = #/,\s{2,}|;\s{2,}|\s{3,}and\s{3,}/#
        let lines = formula.split(separator: separator)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return lines.isEmpty ? [formula] : lines
    }

    /// One formula line with each term in its colour. A term is coloured only where it appears
    /// exactly once in the whole formula, so a single letter that recurs never lights the wrong
    /// place. The chosen term also sits on its wash.
    private func formulaText(_ line: String) -> AttributedString {
        var text = AttributedString(line)
        for term in bridge.termMappings {
            guard !term.symbol.isEmpty,
                  bridge.formulaDisplay.ranges(of: term.symbol).count == 1,
                  let range = text.range(of: term.symbol)
            else { continue }
            let tone = TermTone(role: term.colorRole, theme: theme)
            text[range].foregroundColor = tone.text
            if tone.marksWithWash || term.symbol == activeTerm?.symbol {
                text[range].backgroundColor = tone.wash
            }
        }
        return text
    }
}

/// A short numeric answer. Digits are serif with tabular figures so a column of answers lines up.
struct NumericKeypadField: View {
    @Environment(\.standardTheme) private var theme
    @ScaledMetric(relativeTo: .title2) private var answerSize: CGFloat = 24
    let label: String
    let unitLabel: String
    @Binding var text: String
    var onSubmit: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.xs) {
            TextField(label, text: $text)
                .learnerTextInput(.retrieval)
                .textFieldStyle(.plain)
                .font(PatternedType.readingDefault.font(size: answerSize).monospacedDigit())
                .foregroundStyle(theme.ink)
                .onSubmit(onSubmit)
                .padding(.horizontal, StandardSpacing.md)
                .frame(minHeight: StandardAccessibility.touchTarget + 8)
                .background(
                    RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                        .fill(theme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                        .strokeBorder(theme.ink, lineWidth: 1.5)
                )
            if !unitLabel.isEmpty {
                Text(unitLabel)
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.mute(theme.ink))
            }
        }
    }
}

// MARK: - Shared CPA Interactive Manipulative Sandbox Card

/// The concrete-pictorial-abstract sandbox: two sliders move a drawn model, and the sum it shows
/// can be copied into the reader's working. The first slider is the thing that moves (red), the
/// second the given (blue), as in Byrne.
struct CPAManipulativeSandboxCard: View {
    @Environment(\.standardTheme) private var theme
    let spec: CPAManipulativeSpec
    @Binding var state: CPAManipulativeState
    var onStampToWorking: ((String) -> Void)? = nil

    private var moves: TermTone { .byrne(.moves, theme: theme) }
    private var given: TermTone { .byrne(.given, theme: theme) }
    private var stays: TermTone { .byrne(.stays, theme: theme) }

    /// A name a twelve-year-old would use for each model.
    private var modelName: String {
        switch spec.kind {
        case .singaporeBarPartition: "Bar model"
        case .alKhwarizmiAreaBox: "Area square"
        case .geometricAngleVectorBalance: "Angles and turns"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                    Kicker("Move it and see")
                    Text(modelName)
                        .standardType(.headlineSm)
                        .foregroundStyle(theme.ink)
                }
                Spacer(minLength: StandardSpacing.sm)
                if let onStampToWorking {
                    Button("Copy into my working") {
                        onStampToWorking(state.liveReadout(for: spec))
                    }
                    .buttonStyle(OutlineButtonStyle())
                }
            }

            Text(spec.instruction)
                .patternedType(.readingDefault)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            cpaVisualCanvas
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .background(theme.patterned.marginColor)
                .clipShape(RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                        .strokeBorder(theme.hairline(), lineWidth: 1)
                )

            ViewThatFits(in: .horizontal) {
                HStack(spacing: StandardSpacing.lg) { sliders }
                VStack(spacing: StandardSpacing.sm) { sliders }
            }

            Text(state.liveReadout(for: spec))
                .patternedType(.mathInline)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            StaysTheSameNote(label: "What stays the same", text: spec.invariantSummary)
        }
        .paperCard()
    }

    @ViewBuilder private var sliders: some View {
        slider(spec.primaryLabel, value: $state.primaryValue, range: spec.primaryRange, step: spec.primaryStep, tone: moves)
        slider(spec.secondaryLabel, value: $state.secondaryValue, range: spec.secondaryRange, step: spec.secondaryStep, tone: given)
    }

    private func slider(
        _ label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        tone: TermTone
    ) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .standardType(.uiBody)
                    .foregroundStyle(theme.ink)
                Spacer()
                Text("\(Int(value.wrappedValue.rounded()))")
                    .patternedType(.mathInline)
                    .monospacedDigit()
                    .foregroundStyle(tone.text)
            }
            Slider(value: value, in: range, step: step)
                .tint(tone.swatch)
                .accessibilityLabel(label)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var cpaVisualCanvas: some View {
        switch spec.kind {
        case .singaporeBarPartition:
            let count = max(1, Int(state.primaryValue.rounded()))
            let unitVal = Int(state.secondaryValue.rounded())
            VStack(spacing: StandardSpacing.xs) {
                HStack(spacing: 3) {
                    ForEach(0..<count, id: \.self) { idx in
                        VStack(spacing: 2) {
                            Text("\(unitVal)")
                                .patternedType(.mathInline)
                                .foregroundStyle(given.text)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                            Text("\(idx + 1)")
                                .patternedType(.sidenote)
                                .foregroundStyle(theme.mute(theme.ink))
                        }
                        .frame(maxWidth: .infinity, minHeight: 64)
                        .background(
                            RoundedRectangle(cornerRadius: StandardRadius.sm)
                                .fill(given.wash)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: StandardRadius.sm)
                                .strokeBorder(given.swatch, lineWidth: 1.5)
                        )
                    }
                }
                Text("\(count) parts × \(unitVal) = \(count * unitVal)")
                    .patternedType(.mathInline)
                    .foregroundStyle(moves.text)
            }
            .padding(StandardSpacing.md)

        case .alKhwarizmiAreaBox:
            let a = max(1, state.primaryValue)
            let b = max(1, state.secondaryValue)
            let fracA = CGFloat(a / (a + b))
            GeometryReader { geo in
                let w = max(80, geo.size.width - 24)
                let h = max(60, geo.size.height - 20)
                let wA = max(36, w * fracA)
                let wB = max(28, w - wA)
                let hA = max(32, h * fracA)
                let hB = max(24, h - hA)
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        areaTile("a² = \(Int((a * a).rounded()))", tone: moves, width: wA, height: hA)
                        areaTile("ab = \(Int((a * b).rounded()))", tone: stays, width: wB, height: hA)
                    }
                    HStack(spacing: 2) {
                        areaTile("ab = \(Int((a * b).rounded()))", tone: stays, width: wA, height: hB)
                        areaTile("b² = \(Int((b * b).rounded()))", tone: given, width: wB, height: hB)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

        case .geometricAngleVectorBalance:
            let deg = state.primaryValue
            let supp = 180.0 - deg
            let turns = max(3, Int(state.secondaryValue.rounded()))
            HStack(alignment: .top, spacing: StandardSpacing.lg) {
                VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                    Text("Angles on a straight line")
                        .standardType(.uiCaption)
                        .foregroundStyle(theme.mute(theme.ink))
                    HStack(spacing: StandardSpacing.xxs) {
                        mathChip("θ = \(Int(deg.rounded()))°", tone: moves)
                        Text("+")
                            .patternedType(.mathInline)
                            .foregroundStyle(theme.ink)
                        mathChip("\(Int(supp.rounded()))°", tone: given)
                        Text("= 180°")
                            .patternedType(.mathInline)
                            .foregroundStyle(theme.ink)
                    }
                }
                Rectangle().fill(theme.hairline()).frame(width: 1)
                VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                    Text("Walking round a \(turns)-sided shape")
                        .standardType(.uiCaption)
                        .foregroundStyle(theme.mute(theme.ink))
                    mathChip("turn at each corner = 360° ÷ \(turns) = \(Int((360.0 / Double(turns)).rounded()))°", tone: stays)
                    Text("angle inside = \(Int((180.0 - 360.0 / Double(turns)).rounded()))°")
                        .patternedType(.mathInline)
                        .foregroundStyle(theme.ink)
                }
            }
            .padding(StandardSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func areaTile(_ label: String, tone: TermTone, width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: StandardRadius.sm)
                .fill(tone.wash)
            RoundedRectangle(cornerRadius: StandardRadius.sm)
                .strokeBorder(tone.swatch, lineWidth: 1.5)
            Text(label)
                .patternedType(.mathInline)
                .foregroundStyle(tone.text)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .padding(.horizontal, 4)
        }
        .frame(width: width, height: height)
    }

    private func mathChip(_ text: String, tone: TermTone) -> some View {
        Text(text)
            .patternedType(.mathInline)
            .foregroundStyle(tone.text)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.horizontal, StandardSpacing.xs)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: StandardRadius.sm)
                    .fill(tone.wash)
            )
    }
}

// MARK: - Read + Listen Synchronized Audio Narrator (SmartyMe Pattern)

@MainActor
@Observable
public final class ChapterAudioNarrator: NSObject, AVSpeechSynthesizerDelegate {
    public private(set) var isSpeaking: Bool = false
    public private(set) var activeBeatIndex: Int = 0
    public private(set) var currentBeatId: String? = nil
    public private(set) var activeWatchStepIndex: Int = 0
    public private(set) var lastSpokenText: String = ""
    public var playbackSpeedMultiplier: Float = 1.0

    private let synthesizer = AVSpeechSynthesizer()
    private let allowsHardwareSpeech: Bool

    public init(allowsHardwareSpeech: Bool = true) {
        self.allowsHardwareSpeech = allowsHardwareSpeech
        super.init()
        self.synthesizer.delegate = self
    }

    public static let availableSpeeds: [Float] = [1.0, 1.25, 1.5]

    public func cycleSpeed() {
        if let idx = Self.availableSpeeds.firstIndex(of: playbackSpeedMultiplier) {
            playbackSpeedMultiplier = Self.availableSpeeds[(idx + 1) % Self.availableSpeeds.count]
        } else {
            playbackSpeedMultiplier = 1.0
        }
    }

    public func speak(
        text: String,
        beatIndex: Int = 0,
        beatId: String? = nil,
        watchStepIndex: Int = 0
    ) {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        stop()
        activeBeatIndex = beatIndex
        currentBeatId = beatId
        activeWatchStepIndex = watchStepIndex
        lastSpokenText = cleaned
        isSpeaking = true

        guard allowsHardwareSpeech else { return }
        if KymLiveStaticTextNarrator.shared.hasElevenLabsKeyConfigured {
            KymLiveStaticTextNarrator.shared.readAloud(
                text: cleaned,
                itemID: beatId ?? "maths-beat-\(beatIndex)",
                rate: playbackSpeedMultiplier,
                allowsHardwareSpeech: allowsHardwareSpeech
            ) { [weak self] in
                self?.handleUtteranceDidFinish()
            }
            return
        }
        let utterance = AVSpeechUtterance(string: cleaned)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB") ?? AVSpeechSynthesisVoice(language: "en-IN")
        let baseRate = AVSpeechUtteranceDefaultSpeechRate
        utterance.rate = min(
            AVSpeechUtteranceMaximumSpeechRate,
            max(AVSpeechUtteranceMinimumSpeechRate, baseRate * playbackSpeedMultiplier)
        )
        synthesizer.speak(utterance)
    }

    public func togglePlayPause(
        text: String,
        beatIndex: Int = 0,
        beatId: String? = nil,
        watchStepIndex: Int = 0
    ) {
        if isSpeaking {
            stop()
        } else {
            speak(
                text: text,
                beatIndex: beatIndex,
                beatId: beatId,
                watchStepIndex: watchStepIndex
            )
        }
    }

    public func advanceWatchStep(totalSteps: Int) {
        guard totalSteps > 0 else {
            activeWatchStepIndex = 0
            return
        }
        activeWatchStepIndex = (activeWatchStepIndex + 1) % totalSteps
    }

    public func handleUtteranceDidFinish() {
        isSpeaking = false
    }

    public func stop() {
        KymLiveStaticTextNarrator.shared.stop()
        if allowsHardwareSpeech && synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }

    nonisolated public func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Task { @MainActor [weak self] in
            self?.handleUtteranceDidFinish()
        }
    }

    nonisolated public func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        Task { @MainActor [weak self] in
            self?.handleUtteranceDidFinish()
        }
    }
}

// MARK: - Shared Buggy-Rule Trap Banner

/// Shown when an answer matches a known wrong rule (a buggy-rule diagnosis): what the trap is,
/// why it tempts, and a picture that fixes it. Said kindly, in the "with help" tone, never red.
struct BuggyRuleTrapBanner: View {
    @Environment(\.standardTheme) private var theme
    let trap: BuggyRuleTrap

    var body: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            Text("A tempting trap · \(trap.trapName)")
                .patternedType(.kicker)
                .foregroundStyle(theme.patterned.assistedColor)
                .accessibilityAddTraits(.isHeader)
            Text(trap.diagnosticWhy)
                .patternedType(.readingDefault)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            if !trap.visualFixNudge.isEmpty && trap.visualFixNudge != trap.diagnosticWhy {
                HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.xs) {
                    Image(systemName: "eye")
                        .foregroundStyle(theme.brass)
                        .accessibilityHidden(true)
                    Text("Picture it: \(trap.visualFixNudge)")
                        .patternedType(.readingSmall)
                        .foregroundStyle(theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.leading, StandardSpacing.md)
        .padding(.trailing, StandardSpacing.md)
        .padding(.vertical, StandardSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                .fill(theme.patterned.marginColor)
        )
        .overlay(alignment: .leading) {
            UnevenRoundedRectangle(topLeadingRadius: StandardRadius.lg, bottomLeadingRadius: StandardRadius.lg)
                .fill(theme.patterned.assistedColor)
                .frame(width: 3)
        }
    }
}

// MARK: - Shared Mathematical Debate Card ("Who Is Right & Why?")

/// Two friends disagree; the reader picks whose reasoning holds. A wrong pick gets a
/// counter-example (Socratic rebuttal) and a second go. People are drawn in ink, not Byrne colours,
/// which stay for the maths.
struct MathematicalDebateCardView: View {
    @Environment(\.standardTheme) private var theme
    let scenario: MathematicalDebateScenario
    var initialSelectedChoiceId: String? = nil
    var onChoiceSelected: ((MathematicalDebateChoice, Bool) -> Void)? = nil
    var onResolved: ((Bool) -> Void)? = nil
    @State private var pick = DebatePick()

    private var activeChoiceId: String? {
        pick.active(saved: initialSelectedChoiceId, among: scenario.choices.map(\.id))
    }

    private var selectedChoice: MathematicalDebateChoice? {
        guard let id = activeChoiceId else { return nil }
        return MathematicalDebateEngine.evaluateChoice(scenario: scenario, choiceId: id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Kicker("Who's right?")
                Spacer(minLength: StandardSpacing.sm)
                Text("Chapter \(scenario.chapterNumber) · School book chapter \(scenario.oupUnitNumber)")
                    .standardType(.uiCaption)
                    .foregroundStyle(theme.mute(theme.ink))
            }

            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                Text(scenario.title)
                    .standardType(.headlineSm)
                    .foregroundStyle(theme.ink)
                Text(scenario.contextPrompt)
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: StandardSpacing.sm) { claims }
                VStack(alignment: .leading, spacing: StandardSpacing.sm) { claims }
            }

            VStack(spacing: StandardSpacing.xs) {
                let picked = selectedChoice
                ForEach(scenario.choices) { choice in
                    let isChosen = (activeChoiceId == choice.id)
                    let tone = DebatePick.tone(isChosen: isChosen, pickedIsCorrect: picked?.isCorrect)
                    choiceRow(choice, tone: tone, isChosen: isChosen) {
                        pick.choose(choice.id)
                        onChoiceSelected?(choice, choice.isCorrect)
                        onResolved?(choice.isCorrect)
                    }
                }
            }

            if let chosen = selectedChoice {
                resolution(chosen)
            }
        }
        .paperCard()
        .onChange(of: scenario.id) { _, _ in
            pick = DebatePick()
        }
    }

    @ViewBuilder private var claims: some View {
        claim(name: scenario.speakerAName, text: scenario.speakerAClaim)
        claim(name: scenario.speakerBName, text: scenario.speakerBClaim)
    }

    private func claim(name: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
            Text("\(name) says")
                .patternedType(.kicker)
                .foregroundStyle(theme.mute(theme.ink))
            Text("“\(text)”")
                .italic()
                .patternedType(.readingDefault)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(StandardSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                .fill(theme.patterned.marginColor)
        )
        .accessibilityElement(children: .combine)
    }

    private func choiceRow(
        _ choice: MathematicalDebateChoice,
        tone: QuizOptionTone,
        isChosen: Bool,
        action: @escaping () -> Void
    ) -> some View {
        let palette = theme.patterned
        let edge: Color = switch tone {
        case .correct: palette.provenColor
        case .wrong: palette.assistedColor
        case .idle: theme.hairline()
        case .dimmed: theme.hairline().opacity(0.6)
        }
        let fill: Color = switch tone {
        case .correct: palette.provenWashColor
        case .wrong: palette.marginColor
        case .idle, .dimmed: theme.surface
        }
        let mark: Color = switch tone {
        case .correct: palette.provenColor
        case .wrong: palette.assistedColor
        case .idle, .dimmed: theme.mute(theme.ink)
        }
        return Button(action: action) {
            HStack(alignment: .top, spacing: StandardSpacing.sm) {
                Image(systemName: tone.icon)
                    .foregroundStyle(mark)
                    .frame(width: 22)
                    .accessibilityHidden(true)
                Text(Self.choiceText(choice))
                    .patternedType(.readingDefault)
                    .foregroundStyle(tone == .dimmed ? theme.mute(theme.ink) : theme.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            // Padding plus one line of reading text is taller than a touch target, so no
            // minimum-height frame: one would let a squeezed stack crush a two-line row.
            .padding(StandardSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous).fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                    .strokeBorder(edge, lineWidth: isChosen || tone == .correct ? 1.5 : 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .allowsHitTesting(tone == .idle)
        .accessibilityValue(tone.accessibilityValue)
    }

    /// The speaker in bold on the first line, then their reasoning under it, as one run of text.
    private static func choiceText(_ choice: MathematicalDebateChoice) -> AttributedString {
        var speaker = AttributedString(choice.speakerLabel)
        speaker.inlinePresentationIntent = .stronglyEmphasized
        return speaker + AttributedString("\n\(choice.reasoningStatement)")
    }

    private func resolution(_ chosen: MathematicalDebateChoice) -> some View {
        let palette = theme.patterned
        let tint = chosen.isCorrect ? palette.provenColor : palette.assistedColor
        return VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: chosen.isCorrect ? "checkmark.circle.fill" : "lightbulb")
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)
                Text(chosen.isCorrect ? "That's the reasoning that holds" : "Here's a case that breaks it")
                    .standardType(.uiHeadline)
                    .foregroundStyle(tint)
                Spacer()
                if !chosen.isCorrect {
                    Button("Try again") {
                        pick.tryAgain()
                    }
                    .buttonStyle(OutlineButtonStyle())
                }
            }
            Text(chosen.socraticRebuttal)
                .patternedType(.readingDefault)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            StaysTheSameNote(label: "The big idea", text: scenario.invariantTakeaway)
        }
    }
}

/// Which choice of a "Who is right?" shows as picked. A pick saved on an earlier visit shows until
/// Kym picks again or asks to try again; without `isRetrying`, "Try again" fell back to the saved pick.
struct DebatePick: Equatable {
    private(set) var picked: String?
    private(set) var isRetrying = false

    mutating func choose(_ id: String) {
        picked = id
        isRetrying = false
    }

    mutating func tryAgain() {
        picked = nil
        isRetrying = true
    }

    func active(saved: String?, among ids: [String]) -> String? {
        if let picked, ids.contains(picked) { return picked }
        if !isRetrying, let saved, ids.contains(saved) { return saved }
        return nil
    }

    /// How a row looks. A wrong pick marks only itself, so the right answer is still hers to find on
    /// the second go; `pickedIsCorrect` is nil before any pick.
    static func tone(isChosen: Bool, pickedIsCorrect: Bool?) -> QuizOptionTone {
        guard let pickedIsCorrect else { return .idle }
        guard isChosen else { return .dimmed }
        return pickedIsCorrect ? .correct : .wrong
    }
}
