import SwiftUI

/// One 20-second fact sprint: ready, running on an on-screen keypad, then the score and the facts to
/// learn. The keypad is on the page so the system keyboard never opens over the prompt.
struct FactSprintSheet: View {
    let store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.standardTheme) private var theme
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var family: FactFamily
    @State private var run: FactSprintRun
    @State private var lastTime: FactSprintRecord?
    @State private var typed = ""
    /// The fact just missed, shown whole until the next answer.
    @State private var lastMiss: Fact?
    @FocusState private var hasKeyboard: Bool

    init(store: AppStore, family: FactFamily) {
        self.store = store
        _family = State(initialValue: family)
        _run = State(initialValue: Self.freshRun(family, store: store))
        _lastTime = State(initialValue: store.factSprint(family, before: .now))
    }

    private static func freshRun(_ family: FactFamily, store: AppStore) -> FactSprintRun {
        var rng = SystemRandomNumberGenerator()
        return FactSprintRun(deck: FactSprintDeck.build(family: family, missedLastTime: store.missedLastTime(family), rng: &rng))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StandardSpacing.lg) {
                SheetCloseButton { dismiss() }
                    .padding(.leading, -StandardSpacing.sm)
                switch run.phase {
                case .ready: ready
                case .running(let startedAt): running(startedAt)
                case .finished: finished
                }
            }
            .frame(maxWidth: 560, alignment: .leading)
            .padding(.horizontal, sizeClass == .compact ? StandardSpacing.md : StandardSpacing.xl)
            .padding(.vertical, StandardSpacing.lg)
            .frame(maxWidth: .infinity)
        }
        .background(theme.bg.ignoresSafeArea())
        .focusable()
        .focused($hasKeyboard)
        .focusEffectDisabled()
        .onKeyPress(phases: .down, action: keyPressed)
        .onAppear { hasKeyboard = true }
        #if os(macOS)
        .frame(minWidth: 520, minHeight: 680)
        #endif
    }

    // MARK: Ready

    private var ready: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.md) {
            Kicker("Warm-up · facts by heart")
            Text(family.title)
                .standardType(.headlineLg)
                .foregroundStyle(theme.ink)
                .accessibilityAddTraits(.isHeader)
            if let lastTime {
                Text("Last time: \(lastTime.right) right")
                    .standardType(.uiBody)
                    .foregroundStyle(theme.mute(theme.ink))
            }
            Text("Answer as many as you can in 20 seconds. Missed facts come back first next time.")
                .patternedType(.readingDefault)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            primaryButton("Start") {
                run.start(at: .now)
                hasKeyboard = true
            }
        }
    }

    // MARK: Running

    private func running(_ startedAt: Date) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.md) {
            TimelineView(.periodic(from: startedAt, by: 0.1)) { context in
                let left = run.remaining(at: context.date)
                VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                    HStack {
                        Kicker(family.title, muted: true)
                        Spacer(minLength: StandardSpacing.sm)
                        Text("\(Int(left.rounded(.up))) s")
                            .standardType(.uiHeadline)
                            .monospacedDigit()
                            .foregroundStyle(theme.ink)
                            .accessibilityLabel("\(Int(left.rounded(.up))) seconds left")
                    }
                    ProgressRule(left / Double(FactSprintRun.seconds))
                        .accessibilityHidden(true)
                }
            }

            if let fact = run.current {
                Text(fact.prompt)
                    .patternedType(.mathDisplay)
                    .foregroundStyle(theme.ink)
                    .frame(maxWidth: .infinity, minHeight: 72)
                    .accessibilityAddTraits(.isHeader)
                answerSlot(fact)
            }
            Text(lastMiss?.worked ?? " ")
                .patternedType(.readingDefault)
                .foregroundStyle(theme.patterned.assistedColor)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(lastMiss == nil)
            keypad
        }
        .task(id: startedAt) {
            while !Task.isCancelled {
                let left = run.remaining(at: .now)
                if left <= 0 {
                    finishSprint()
                    return
                }
                try? await Task.sleep(for: .seconds(left))
            }
        }
    }

    private func answerSlot(_ fact: Fact) -> some View {
        HStack(spacing: StandardSpacing.sm) {
            Text(typed.isEmpty ? " " : typed)
                .patternedType(.mathDisplay)
                .foregroundStyle(theme.ink)
                .frame(minWidth: 140, minHeight: 56)
                .paperField(dashed: typed.isEmpty, emphasis: true)
                .accessibilityLabel("Your answer")
                .accessibilityValue(typed.isEmpty ? "empty" : typed)
            if !fact.answerSuffix.isEmpty {
                Text(fact.answerSuffix)
                    .patternedType(.mathDisplay)
                    .foregroundStyle(theme.ink)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private enum Key: Hashable {
        case digit(Int), point, slash, delete, go
    }

    private static let keyRows: [[Key]] = [
        [.digit(7), .digit(8), .digit(9), .delete],
        [.digit(4), .digit(5), .digit(6), .slash],
        [.digit(1), .digit(2), .digit(3), .point]
    ]

    private var keypad: some View {
        Grid(horizontalSpacing: StandardSpacing.xs, verticalSpacing: StandardSpacing.xs) {
            ForEach(Self.keyRows, id: \.self) { row in
                GridRow {
                    ForEach(row, id: \.self) { key in keyButton(key) }
                }
            }
            GridRow {
                keyButton(.digit(0)).gridCellColumns(2)
                keyButton(.go).gridCellColumns(2)
            }
        }
    }

    private func keyButton(_ key: Key) -> some View {
        Button {
            press(key)
        } label: {
            Group {
                switch key {
                case .digit(let n): Text("\(n)")
                case .point: Text(".")
                case .slash: Text("/")
                case .delete: Image(systemName: "delete.left")
                case .go: Text("Go")
                }
            }
            .frame(maxWidth: .infinity, minHeight: StandardAccessibility.touchTarget + 8)
        }
        .buttonStyle(KeypadKeyStyle(filled: key == .go))
        .accessibilityLabel(Self.spoken(key))
    }

    private static func spoken(_ key: Key) -> String {
        switch key {
        case .digit(let n): "\(n)"
        case .point: "Point"
        case .slash: "Fraction slash"
        case .delete: "Delete"
        case .go: "Check answer"
        }
    }

    private func press(_ key: Key) {
        hasKeyboard = true
        switch key {
        case .digit(let n): type("\(n)")
        case .point: type(".")
        case .slash: type("/")
        case .delete: if !typed.isEmpty { typed.removeLast() }
        case .go: submit()
        }
    }

    private func type(_ text: String) {
        guard typed.count < 8 else { return }
        typed += text
    }

    private func keyPressed(_ press: KeyPress) -> KeyPress.Result {
        guard case .running = run.phase else { return .ignored }
        switch press.key {
        case .return:
            submit()
        case .delete, .deleteForward:
            self.press(.delete)
        default:
            guard press.characters.count == 1, "0123456789./%".contains(press.characters) else { return .ignored }
            type(press.characters)
        }
        return .handled
    }

    private func submit() {
        let now = Date.now
        guard let outcome = run.submit(typed: typed, at: now) else {
            finishSprint()
            return
        }
        typed = ""
        if case .wrong(let fact) = outcome {
            lastMiss = fact
        } else {
            lastMiss = nil
        }
    }

    /// Records once: `finish()` only moves a running sprint, so a second call finds it finished.
    private func finishSprint(at now: Date = .now) {
        guard case .running = run.phase, run.remaining(at: now) <= 0 else { return }
        run.finish()
        store.recordFactSprint(run, family: family, at: now)
    }

    // MARK: Finished

    private var finished: some View {
        let score = run.right.count
        let next = store.nextFactFamily()
        return VStack(alignment: .leading, spacing: StandardSpacing.md) {
            Kicker(family.title)
            Text("\(score) right")
                .patternedType(.chapterDisplay)
                .foregroundStyle(theme.ink)
            if let lastTime {
                Text(Self.comparison(score, lastTime: lastTime.right))
                    .standardType(.uiBody)
                    .foregroundStyle(theme.mute(theme.ink))
            }
            if !run.missed.isEmpty {
                VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                    Kicker("Learn these", muted: true)
                    ForEach(run.missed.prefix(8), id: \.self) { fact in
                        Text(fact.worked)
                            .patternedType(.mathInline)
                            .foregroundStyle(theme.ink)
                    }
                    Text("They come back first next time.")
                        .patternedType(.readingSmall)
                        .foregroundStyle(theme.mute(theme.ink))
                }
                .paperCard(padding: StandardSpacing.md)
            }
            if let next {
                primaryButton("Next: \(next.title)") { begin(next) }
            } else {
                primaryButton("Done for today") { dismiss() }
            }
        }
    }

    private static func comparison(_ score: Int, lastTime: Int) -> String {
        switch score - lastTime {
        case 0: "Same as last time"
        case 1...: "\(score - lastTime) more than last time"
        default: "Last time: \(lastTime)"
        }
    }

    private func begin(_ next: FactFamily) {
        family = next
        lastTime = store.factSprint(next, before: .now)
        run = Self.freshRun(next, store: store)
        typed = ""
        lastMiss = nil
    }

    /// The one filled button; ready and finished never show together.
    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: StandardSpacing.xs) {
                Text(title)
                Image(systemName: "arrow.right").imageScale(.small)
            }
        }
        .buttonStyle(InkButtonStyle(fullWidth: true))
    }
}

/// A keypad key: paper with a hairline, or ink for Go, the one key that acts.
private struct KeypadKeyStyle: ButtonStyle {
    let filled: Bool

    func makeBody(configuration: Configuration) -> some View {
        KeypadKeyBody(configuration: configuration, filled: filled)
    }
}

private struct KeypadKeyBody: View {
    @Environment(\.standardTheme) private var theme
    let configuration: ButtonStyleConfiguration
    let filled: Bool

    var body: some View {
        configuration.label
            .patternedType(.mathInline)
            .fontWeight(filled ? .semibold : .regular)
            .foregroundStyle(filled ? theme.bg : theme.ink)
            .background(
                RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                    .fill(filled ? theme.ink : configuration.isPressed ? theme.blank() : theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                    .strokeBorder(filled ? Color.clear : theme.hairline(), lineWidth: 1)
            )
            .opacity(configuration.isPressed && filled ? 0.82 : 1)
            .contentShape(Rectangle())
    }
}
