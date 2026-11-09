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

struct JournalSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        JournalCapsuleButtonStyle(prominence: .tinted, size: .small)
            .makeBody(configuration: configuration)
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

struct MathSymbolRibbon: View {
    @Binding var text: String
    var tokens: [MathSymbolToken] = MathSymbolToken.standardTokens

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xxs) {
                ForEach(tokens) { token in
                    Button {
                        text.append(token.insertion)
                    } label: {
                        Text(token.label)
                            .font(Typography.mono.weight(.semibold))
                            .foregroundStyle(Color.kymaiaInk)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: Spacing.radiusSM, style: .continuous)
                                    .fill(Color.kymaiaElevatedSurface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Spacing.radiusSM, style: .continuous)
                                    .strokeBorder(Color.kymaiaHairline, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Insert \(token.accessibilityName)")
                }
            }
            .padding(.vertical, 2)
        }
    }
}

struct LearnerTextInput: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 96
    var showMathRibbon: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if !title.isEmpty {
                Text(title)
                    .font(Typography.caption.weight(.semibold))
                    .foregroundStyle(Color.kymaiaInk)
            }
            if showMathRibbon {
                MathSymbolRibbon(text: $text)
            }
            ZStack(alignment: .topLeading) {
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
                if text.isEmpty && !placeholder.isEmpty {
                    Text(placeholder)
                        .font(Typography.caption)
                        .foregroundStyle(Color.kymaiaTertiaryInk)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.sm)
                        .allowsHitTesting(false)
                }
            }
        }
    }
}

// MARK: - Shared Intuition -> Formula Bridge Card

struct IntuitionFormulaBridgeCard: View {
    let bridge: IntuitionToFormulaBridge
    @Binding var selectedTermSymbol: String?
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
        JournalCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    JournalBadge(text: "Intuition → Formula Bridge", symbol: "function", tone: .info)
                    Spacer()
                    Text("Tap any term to highlight its visual geometry")
                        .font(Typography.caption)
                        .foregroundStyle(Color.kymaiaMutedInk)
                }

                Text(bridge.formulaDisplay)
                    .font(Typography.numericFormula)
                    .foregroundStyle(Color.kymaiaInk)
                    .padding(Spacing.xs)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.kymaiaElevatedSurface)
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusSM))

                Text("1. Concrete Visual Action: \(bridge.concreteAction)")
                    .font(Typography.body)
                    .foregroundStyle(Color.kymaiaInk)

                Text("2. The \"Aha!\" Invariant: \(bridge.ahaInvariant)")
                    .font(Typography.caption.weight(.semibold))
                    .foregroundStyle(Color.kymaiaSuccess)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        ForEach(bridge.termMappings) { term in
                            let roleAccent = KymaiaSemanticStyle.roleAccent(term.colorRole)
                            let figureSwatch = MathsFigureColor.roleColor(term.colorRole)
                            let isSelected = (activeTerm?.symbol == term.symbol)
                            Button {
                                selectedTermSymbol = term.symbol
                                onSelectTerm?(term)
                            } label: {
                                HStack(spacing: Spacing.xxs) {
                                    Circle()
                                        .fill(figureSwatch)
                                        .frame(width: 8, height: 8)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(MathsFigureColor.paper, lineWidth: 1)
                                        )
                                    Text(term.symbol)
                                        .font(Typography.mono.weight(.bold))
                                        .foregroundStyle(roleAccent)
                                    Text("↔ \(term.visualPart)")
                                        .font(Typography.caption)
                                        .foregroundStyle(Color.kymaiaInk)
                                }
                                .padding(.horizontal, Spacing.xs)
                                .padding(.vertical, 6)
                                .background(roleAccent.opacity(isSelected ? 0.18 : 0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Spacing.radiusSM)
                                        .strokeBorder(isSelected ? roleAccent : roleAccent.opacity(0.35), lineWidth: isSelected ? 1.5 : 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusSM))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if let term = activeTerm {
                    let roleAccent = KymaiaSemanticStyle.roleAccent(term.colorRole)
                    let isPerturbationRevealed = revealedPerturbationSymbols.contains(term.symbol)
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack(alignment: .top, spacing: Spacing.xs) {
                            Image(systemName: "viewfinder.circle.fill")
                                .foregroundStyle(roleAccent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Selected Term: \(term.symbol) ↔ \(term.visualPart) (\(term.colorRole.uppercased()))")
                                    .font(Typography.caption.weight(.bold))
                                    .foregroundStyle(roleAccent)
                                Text(term.meaning)
                                    .font(Typography.caption)
                                    .foregroundStyle(Color.kymaiaInk)
                            }
                        }

                        Divider()

                        // Brilliant-Style Perturbation Micro-Check
                        HStack(alignment: .top, spacing: Spacing.xs) {
                            Image(systemName: "sparkles.rectangle.stack")
                                .foregroundStyle(Color.kymaiaPrimary)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(bridge.perturbationPrompt(for: term))
                                    .font(Typography.caption.weight(.semibold))
                                    .foregroundStyle(Color.kymaiaInk)

                                Button(isPerturbationRevealed ? "Hide Perturbation Effect" : "Reveal Perturbation Effect") {
                                    if isPerturbationRevealed {
                                        revealedPerturbationSymbols.remove(term.symbol)
                                    } else {
                                        revealedPerturbationSymbols.insert(term.symbol)
                                    }
                                }
                                .buttonStyle(JournalSecondaryButtonStyle())

                                if isPerturbationRevealed {
                                    Text(bridge.perturbationExplanation(for: term))
                                        .font(Typography.caption)
                                        .foregroundStyle(Color.kymaiaSuccess)
                                }
                            }
                        }
                    }
                    .padding(Spacing.xs)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(roleAccent.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusSM))
                }
            }
        }
        .onChange(of: bridge.formulaDisplay) { _, _ in
            revealedPerturbationSymbols.removeAll()
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

// MARK: - Shared CPA Interactive Manipulative Sandbox Card

struct CPAManipulativeSandboxCard: View {
    let spec: CPAManipulativeSpec
    @Binding var state: CPAManipulativeState
    var onStampToWorking: ((String) -> Void)? = nil

    var body: some View {
        JournalCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    JournalBadge(text: spec.kind.title, symbol: spec.kind.badgeSymbol, tone: .accent)
                    Spacer()
                    if let onStampToWorking {
                        Button("Stamp Equation to Working") {
                            onStampToWorking(state.liveReadout(for: spec))
                        }
                        .buttonStyle(JournalSecondaryButtonStyle())
                    }
                }

                Text(spec.instruction)
                    .font(Typography.caption)
                    .foregroundStyle(Color.kymaiaInk)

                cpaVisualCanvas
                    .frame(height: 118)
                    .background(MathsFigureColor.paper)
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusSM))
                    .overlay(
                        RoundedRectangle(cornerRadius: Spacing.radiusSM)
                            .strokeBorder(Color.kymaiaHairline, lineWidth: 1)
                    )

                HStack(spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(spec.primaryLabel)
                                .font(Typography.caption.weight(.semibold))
                                .foregroundStyle(Color.kymaiaInk)
                            Spacer()
                            Text("\(Int(state.primaryValue.rounded()))")
                                .font(Typography.mono.weight(.bold))
                                .foregroundStyle(MathsFigureColor.red)
                        }
                        Slider(
                            value: $state.primaryValue,
                            in: spec.primaryRange,
                            step: spec.primaryStep
                        )
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(spec.secondaryLabel)
                                .font(Typography.caption.weight(.semibold))
                                .foregroundStyle(Color.kymaiaInk)
                            Spacer()
                            Text("\(Int(state.secondaryValue.rounded()))")
                                .font(Typography.mono.weight(.bold))
                                .foregroundStyle(MathsFigureColor.blue)
                        }
                        Slider(
                            value: $state.secondaryValue,
                            in: spec.secondaryRange,
                            step: spec.secondaryStep
                        )
                    }
                }

                Text(state.liveReadout(for: spec))
                    .font(Typography.mono.weight(.semibold))
                    .foregroundStyle(Color.kymaiaPrimary)
                    .padding(Spacing.xs)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.kymaiaElevatedSurface)
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusSM))

                Text("Invariant: \(spec.invariantSummary)")
                    .font(Typography.caption)
                    .foregroundStyle(Color.kymaiaMutedInk)
            }
        }
    }

    @ViewBuilder
    private var cpaVisualCanvas: some View {
        switch spec.kind {
        case .singaporeBarPartition:
            let count = max(1, Int(state.primaryValue.rounded()))
            let unitVal = Int(state.secondaryValue.rounded())
            VStack(spacing: Spacing.xs) {
                HStack(spacing: 4) {
                    ForEach(0..<count, id: \.self) { idx in
                        VStack(spacing: 2) {
                            Text("\(unitVal)")
                                .font(MathsFigureType.unitTile)
                                .foregroundStyle(MathsFigureColor.ink)
                            Text("u\(idx + 1)")
                                .font(MathsFigureType.axisTick)
                                .foregroundStyle(Color.kymaiaMutedInk)
                        }
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(
                            RoundedRectangle(cornerRadius: MathsFigureRadius.bar)
                                .fill((idx % 2 == 0 ? MathsFigureColor.blue : MathsFigureColor.amber).opacity(0.22))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: MathsFigureRadius.bar)
                                .strokeBorder(idx % 2 == 0 ? MathsFigureColor.blue : MathsFigureColor.amber, lineWidth: 1.5)
                        )
                    }
                }
                Text("Total Brace = \(count) units × \(unitVal) = \(count * unitVal)")
                    .font(MathsFigureType.labelMono)
                    .foregroundStyle(MathsFigureColor.red)
            }
            .padding(Spacing.sm)

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
                        ZStack {
                            RoundedRectangle(cornerRadius: MathsFigureRadius.tile)
                                .fill(MathsFigureColor.red.opacity(0.22))
                            Text("a² = \(Int((a * a).rounded()))")
                                .font(MathsFigureType.labelMono)
                                .foregroundStyle(MathsFigureColor.red)
                        }
                        .frame(width: wA, height: hA)

                        ZStack {
                            RoundedRectangle(cornerRadius: MathsFigureRadius.tile)
                                .fill(MathsFigureColor.amber.opacity(0.22))
                            Text("ab = \(Int((a * b).rounded()))")
                                .font(MathsFigureType.noteMono)
                                .foregroundStyle(MathsFigureColor.amber)
                        }
                        .frame(width: wB, height: hA)
                    }
                    HStack(spacing: 2) {
                        ZStack {
                            RoundedRectangle(cornerRadius: MathsFigureRadius.tile)
                                .fill(MathsFigureColor.amber.opacity(0.22))
                            Text("ab = \(Int((a * b).rounded()))")
                                .font(MathsFigureType.noteMono)
                                .foregroundStyle(MathsFigureColor.amber)
                        }
                        .frame(width: wA, height: hB)

                        ZStack {
                            RoundedRectangle(cornerRadius: MathsFigureRadius.tile)
                                .fill(MathsFigureColor.blue.opacity(0.22))
                            Text("b² = \(Int((b * b).rounded()))")
                                .font(MathsFigureType.noteMono)
                                .foregroundStyle(MathsFigureColor.blue)
                        }
                        .frame(width: wB, height: hB)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

        case .geometricAngleVectorBalance:
            let deg = state.primaryValue
            let supp = 180.0 - deg
            let turns = max(3, Int(state.secondaryValue.rounded()))
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Straight-Line Supplement")
                        .font(MathsFigureType.label)
                        .foregroundStyle(MathsFigureColor.ink)
                    HStack(spacing: 4) {
                        Text("θ = \(Int(deg.rounded()))°")
                            .font(MathsFigureType.labelMono)
                            .foregroundStyle(MathsFigureColor.red)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, 4)
                            .background(MathsFigureColor.red.opacity(0.16))
                            .clipShape(RoundedRectangle(cornerRadius: MathsFigureRadius.tile))
                        Text("+")
                            .font(MathsFigureType.labelMono)
                        Text("\(Int(supp.rounded()))° = 180°")
                            .font(MathsFigureType.labelMono)
                            .foregroundStyle(MathsFigureColor.blue)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, 4)
                            .background(MathsFigureColor.blue.opacity(0.16))
                            .clipShape(RoundedRectangle(cornerRadius: MathsFigureRadius.tile))
                    }
                }
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Regular \(turns)-gon Turns")
                        .font(MathsFigureType.label)
                        .foregroundStyle(MathsFigureColor.ink)
                    Text("Exterior = 360°/\(turns) = \(Int((360.0 / Double(turns)).rounded()))°")
                        .font(MathsFigureType.noteMono)
                        .foregroundStyle(MathsFigureColor.amber)
                    Text("Interior = \(Int((180.0 - 360.0 / Double(turns)).rounded()))°")
                        .font(MathsFigureType.noteMono)
                        .foregroundStyle(MathsFigureColor.green)
                }
            }
            .padding(Spacing.sm)
        }
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
        let utterance = AVSpeechUtterance(string: cleaned)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-IN") ?? AVSpeechSynthesisVoice(language: "en-GB")
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

struct BuggyRuleTrapBanner: View {
    let trap: BuggyRuleTrap

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            JournalBadge(
                text: "Buggy-Rule Trap Caught: \(trap.trapName)",
                symbol: "exclamationmark.shield.fill",
                tone: .warning
            )
            Text(trap.diagnosticWhy)
                .font(Typography.caption.weight(.semibold))
                .foregroundStyle(Color.kymaiaInk)
            if !trap.visualFixNudge.isEmpty && trap.visualFixNudge != trap.diagnosticWhy {
                HStack(alignment: .top, spacing: Spacing.xxs) {
                    Image(systemName: "eye.trianglebadge.exclamationmark")
                        .foregroundStyle(Color.kymaiaPrimary)
                    Text("Visual Fix: \(trap.visualFixNudge)")
                        .font(Typography.caption)
                        .foregroundStyle(Color.kymaiaPrimary)
                }
            }
        }
        .padding(Spacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.kymaiaWarning.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusSM))
    }
}

// MARK: - Shared Mathematical Debate Card ("Who Is Right & Why?")

struct MathematicalDebateCardView: View {
    let scenario: MathematicalDebateScenario
    var initialSelectedChoiceId: String? = nil
    var onChoiceSelected: ((MathematicalDebateChoice, Bool) -> Void)? = nil
    var onResolved: ((Bool) -> Void)? = nil
    @State private var selectedChoiceId: String? = nil

    private var activeChoiceId: String? {
        if let id = selectedChoiceId,
           scenario.choices.contains(where: { $0.id == id }) {
            return id
        }
        if let initId = initialSelectedChoiceId,
           scenario.choices.contains(where: { $0.id == initId }) {
            return initId
        }
        return nil
    }

    private var selectedChoice: MathematicalDebateChoice? {
        guard let id = activeChoiceId else { return nil }
        return MathematicalDebateEngine.evaluateChoice(scenario: scenario, choiceId: id)
    }

    var body: some View {
        JournalCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    JournalBadge(text: "Mathematical Debate · Who Is Right?", symbol: "person.2.wave.2.fill", tone: .warning)
                    Spacer()
                    Text("Ch \(scenario.chapterNumber) · OUP Unit \(scenario.oupUnitNumber)")
                        .font(Typography.caption)
                        .foregroundStyle(Color.kymaiaMutedInk)
                }

                Text(scenario.title)
                    .font(Typography.headline)
                    .foregroundStyle(Color.kymaiaInk)

                Text(scenario.contextPrompt)
                    .font(Typography.body)
                    .foregroundStyle(Color.kymaiaInk)

                HStack(alignment: .top, spacing: Spacing.sm) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(scenario.speakerAName)'s Claim")
                            .font(Typography.caption.weight(.bold))
                            .foregroundStyle(Color.kymaiaError)
                        Text("\"\(scenario.speakerAClaim)\"")
                            .font(Typography.caption)
                            .foregroundStyle(Color.kymaiaInk)
                    }
                    .padding(Spacing.xs)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.kymaiaError.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusSM))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(scenario.speakerBName)'s Claim")
                            .font(Typography.caption.weight(.bold))
                            .foregroundStyle(Color.kymaiaSecondary)
                        Text("\"\(scenario.speakerBClaim)\"")
                            .font(Typography.caption)
                            .foregroundStyle(Color.kymaiaInk)
                    }
                    .padding(Spacing.xs)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.kymaiaSecondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusSM))
                }

                VStack(spacing: Spacing.xs) {
                    let isAnswered = (selectedChoice != nil)
                    ForEach(scenario.choices) { choice in
                        let isChosen = (activeChoiceId == choice.id)
                        let tone = QuizOptionTone.resolve(
                            isAnswered: isAnswered,
                            isCorrectOption: choice.isCorrect,
                            isChosen: isChosen
                        )
                        QuizAnswerOption(
                            text: "\(choice.speakerLabel) — \(choice.reasoningStatement)",
                            tone: tone,
                            isChosen: isChosen
                        ) {
                            selectedChoiceId = choice.id
                            onChoiceSelected?(choice, choice.isCorrect)
                            onResolved?(choice.isCorrect)
                        }
                    }
                }

                if let chosen = selectedChoice {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: chosen.isCorrect ? "checkmark.seal.fill" : "lightbulb.fill")
                                .foregroundStyle(chosen.isCorrect ? Color.kymaiaSuccess : Color.kymaiaWarning)
                            Text(chosen.isCorrect ? "Debate Resolved — Invariant Verified!" : "Socratic Counter-Example:")
                                .font(Typography.caption.weight(.bold))
                                .foregroundStyle(chosen.isCorrect ? Color.kymaiaSuccess : Color.kymaiaWarning)
                            Spacer()
                            if !chosen.isCorrect {
                                Button("Try Again") {
                                    selectedChoiceId = nil
                                }
                                .buttonStyle(JournalSecondaryButtonStyle())
                            }
                        }
                        Text(chosen.socraticRebuttal)
                            .font(Typography.caption)
                            .foregroundStyle(Color.kymaiaInk)
                        Text("Key Takeaway: \(scenario.invariantTakeaway)")
                            .font(Typography.caption.weight(.semibold))
                            .foregroundStyle(Color.kymaiaPrimary)
                    }
                    .padding(Spacing.xs)
                    .background((chosen.isCorrect ? Color.kymaiaSuccess : Color.kymaiaWarning).opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusSM))
                }
            }
        }
        .onChange(of: scenario.id) { _, _ in
            selectedChoiceId = nil
        }
    }
}

extension MathsSettingsSheet {
    @MainActor
    init() {
        self.init(store: AppStore())
    }
}
