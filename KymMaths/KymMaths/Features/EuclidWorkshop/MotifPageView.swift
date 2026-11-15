import SwiftUI

/// One motif's page: the figure with its givens to light, the check with an answer box, and the
/// paper check. Once she has answered, she can drag the free point and flip the switch to see the
/// rule hold and then fail.
struct MotifPageView: View {
    @Environment(\.standardTheme) private var theme
    @Bindable var store: AppStore
    let id: MotifID

    @State private var state = MotifState()
    @State private var lit: Int?
    @State private var showsHelper = false
    /// The helper line was shown before a right answer, so the answer counts as help.
    @State private var helperBeforeAnswer = false
    @State private var answers: [String] = []
    @State private var solved = false
    @State private var outcome: ProgressOutcome?
    @State private var nudge: String?
    @State private var width: CGFloat = 0

    private static let sideBySide: CGFloat = 900

    var body: some View {
        let motif = MotifSpine.motif(id)
        EuclidPage(
            eyebrow: "Euclid's Workshop · Motif \(id)",
            title: motif?.title ?? "No such motif",
            subtitle: motif == nil ? "\(id) is not on the motif list." : "Spot the figure, answer the check, then test the rule it runs on.",
            back: { store.euclidRoute = .map }
        ) {
            if let motif { content(motif) }
        }
        .onAppear {
            reset()
            #if DEBUG
            applyDebugLaunch()
            #endif
        }
    }

    @ViewBuilder
    private func content(_ motif: Motif) -> some View {
        Group {
            if width >= Self.sideBySide {
                VStack(alignment: .leading, spacing: StandardSpacing.lg) {
                    HStack(alignment: .top, spacing: StandardSpacing.lg) {
                        figureCard(motif).frame(maxWidth: .infinity)
                        checkCard(motif).frame(width: 360)
                    }
                    paperCheck(motif)
                }
            } else {
                VStack(alignment: .leading, spacing: StandardSpacing.lg) {
                    figureCard(motif)
                    checkCard(motif)
                    paperCheck(motif)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .readWidth($width)
    }

    // MARK: - The figure

    private var status: LearningStatus {
        guard solved else { return .working }
        return outcome == .assisted ? .withHelp : .proven
    }

    private func figureCard(_ motif: Motif) -> some View {
        let scene = motif.scene
        let figure = scene.build(state)
        let extent = scene.extent
        return VStack(alignment: .leading, spacing: StandardSpacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Kicker("The figure", muted: true)
                Spacer(minLength: StandardSpacing.xs)
                StatusTag(status)
            }
            MotifBoard(
                title: motif.title,
                scene: scene,
                figure: figure,
                extent: extent,
                lights: lit.map { scene.question[$0].lights },
                showsHelper: showsHelper,
                showsAnswer: solved,
                canDrag: solved && scene.canDrag(state),
                onDrag: { state.free = $0 },
                onDragEnd: {
                    if let free = scene.freePoint { state.free = scene.build(state).points[free] }
                }
            )
            .frame(height: BoardViewport.height(for: extent, width: 620, clampedTo: 300...460))
            if solved, let rule = scene.rule?(figure) {
                readout(rule)
            }
            Rectangle().fill(theme.hairline()).frame(height: 1)
            givens(scene)
            if !figure.helpers.isEmpty {
                Button {
                    showsHelper.toggle()
                    if showsHelper, !solved { helperBeforeAnswer = true }
                } label: {
                    Label(showsHelper ? "Hide the helper line" : "Show the helper line", systemImage: "line.diagonal")
                }
                .buttonStyle(OutlineButtonStyle())
                .help(solved ? "Draws the helper line" : "Draws the helper line. Answering with it showing counts as help.")
            }
            if scene.freePoint != nil || scene.condition != nil {
                ruleCard(scene)
            }
        }
        .paperCard()
    }

    /// The givens and the goal, as chips that light what they name on the figure.
    private func givens(_ scene: MotifScene) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            Text("Tap a given to light it on the figure. Tap it again to clear.")
                .standardType(.uiCaption)
                .foregroundStyle(theme.mute(theme.ink))
                .fixedSize(horizontal: false, vertical: true)
            FlowLayout(spacing: StandardSpacing.xs) {
                ForEach(Array(scene.question.enumerated()), id: \.offset) { index, phrase in
                    if phrase.role != .plain {
                        Button(phrase.text) {
                            lit = lit == index ? nil : index
                        }
                        .buttonStyle(EuclidChipStyle(isLit: lit == index))
                        .accessibilityHint(lit == index ? "Clears the figure" : "Lights what this names on the figure")
                        .accessibilityAddTraits(lit == index ? .isSelected : [])
                    }
                }
            }
        }
    }

    /// The switch that keeps or breaks the rule, with what dragging does.
    private func ruleCard(_ scene: MotifScene) -> some View {
        let caption = scene.freePoint.map { dragCaption(scene, free: $0) }
        return VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            if solved, let condition = scene.condition {
                Toggle(isOn: Binding(get: { !state.broken }, set: { state.broken = !$0 })) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(state.broken ? "\(condition): off. The rule breaks" : "\(condition): on. The rule holds")
                            .standardType(.uiHeadline)
                            .foregroundStyle(theme.ink)
                        if let caption {
                            Text(caption)
                                .standardType(.uiCaption)
                                .foregroundStyle(theme.mute(theme.ink))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .toggleStyle(.switch)
                .tint(theme.ink)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Test the rule")
                        .standardType(.uiHeadline)
                        .foregroundStyle(theme.ink)
                    if let caption {
                        Text(caption)
                            .standardType(.uiCaption)
                            .foregroundStyle(theme.mute(theme.ink))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            if solved, state != scene.state {
                Button("Back to the check") { state = scene.state }
                    .buttonStyle(TextLinkButtonStyle(arrow: false))
            }
        }
        .padding(StandardSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                .strokeBorder(theme.hairline(), lineWidth: 1)
        )
    }

    private func dragCaption(_ scene: MotifScene, free: String) -> String {
        guard solved else { return "Answer first. Then you can drag \(free) and flip the switch." }
        if scene.canDrag(state) { return "Drag \(free). The figure is measured again as it moves." }
        return "Switch \(scene.condition ?? "the condition") back on to drag \(free) again."
    }

    private func readout(_ rule: MotifRule) -> some View {
        let unit = rule.unit
        return VStack(spacing: StandardSpacing.xxs) {
            HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.sm) {
                Text("\(rule.lhsLabel) = \(unit.reading(rule.lhs))")
                Text(rule.holds ? "=" : "≠")
                    .foregroundStyle(rule.holds ? theme.ink : theme.patterned.assistedColor)
                Text("\(rule.rhsLabel) = \(unit.reading(rule.rhs))")
            }
            .patternedType(.mathDisplay)
            .monospacedDigit()
            .foregroundStyle(theme.ink)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            if let note = rule.note {
                Text(note)
                    .standardType(.uiCaption)
                    .foregroundStyle(rule.holds ? theme.mute(theme.ink) : theme.patterned.assistedColor)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(StandardSpacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                .fill(theme.patterned.sunkColor)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rule.holds
            ? "The rule holds: \(rule.lhsLabel) is \(unit.spoken(rule.lhs)), \(rule.rhsLabel) is \(unit.spoken(rule.rhs))"
            : "The rule fails: \(rule.lhsLabel) is \(unit.spoken(rule.lhs)) but \(rule.rhsLabel) is \(unit.spoken(rule.rhs))")
    }

    // MARK: - The check

    private func checkCard(_ motif: Motif) -> some View {
        let scene = motif.scene
        let record = store.motifProgress.record(for: id)
        return VStack(alignment: .leading, spacing: StandardSpacing.md) {
            Kicker("The check")
            Text(scene.question.map(\.text).joined(separator: " "))
                .patternedType(.question)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Rectangle().fill(theme.hairline()).frame(height: 1)
            Kicker("Your answer")
            ForEach(Array(scene.goal.enumerated()), id: \.offset) { index, quantity in
                answerBox(motif, index: index, quantity: quantity)
            }
            Text(Self.unitHint(scene.goal.first?.unit ?? .degrees))
                .standardType(.uiCaption)
                .foregroundStyle(theme.mute(theme.ink))
            if let nudge, !solved {
                Text(nudge)
                    .standardType(.uiBody)
                    .foregroundStyle(theme.patterned.assistedColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Rectangle().fill(theme.hairline()).frame(height: 1)
            Kicker("The move")
            if solved {
                solvedPanel(motif)
            } else {
                LockedNote("The move opens once your answer is right.")
            }
            Spacer(minLength: 0)
            HStack(spacing: StandardSpacing.sm) {
                SkillLamps(lit: record.solved ? 1 : 0)
                Text(record.solved ? "\(SkillLevel.picture.lampName) · lit" : SkillLevel.picture.lampName)
                    .standardType(.uiCaption)
                    .foregroundStyle(theme.mute(theme.ink))
            }
            if !solved {
                Button {
                    check(motif)
                } label: {
                    Label("Check", systemImage: "arrow.right").labelStyle(TrailingIconLabelStyle())
                }
                .buttonStyle(InkButtonStyle(fullWidth: true))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .paperCard()
    }

    private func answerBox(_ motif: Motif, index: Int, quantity: Quantity) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.xs) {
            Text(quantity.item.name + " =")
                .patternedType(.mathInline)
                .italic()
                .foregroundStyle(theme.mute(theme.ink))
            TextField("?", text: answerBinding(index))
                .learnerTextInput(.retrieval)
                .textFieldStyle(.plain)
                .patternedType(.numeral).fontWeight(.regular).monospaced()
                .foregroundStyle(theme.ink)
                .fixedSize()
                .frame(minWidth: 72, alignment: .leading)
                .disabled(solved)
                .onSubmit { check(motif) }
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
                .accessibilityLabel("\(quantity.item.name), in \(quantity.unit.placeholder)")
            if let symbol = quantity.unit.symbol {
                Text(symbol)
                    .patternedType(.mathInline)
                    .foregroundStyle(theme.ink)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, StandardSpacing.md)
        .frame(minHeight: 60)
        .background(
            RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                .fill(theme.bg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                .strokeBorder(solved ? theme.patterned.provenColor : theme.ink, lineWidth: 1.5)
        )
    }

    private static func unitHint(_ unit: QuantityUnit) -> String {
        switch unit {
        case .degrees: "Degrees. Numbers only."
        case .centimetres: "Centimetres. Numbers only."
        case .length: "A length. Numbers only."
        case .ratio: "A decimal, to two places."
        }
    }

    private func solvedPanel(_ motif: Motif) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            StatusTag(outcome == .assisted ? .withHelp : .proven,
                      label: outcome == .assisted ? "Right, with help" : "Right")
            Text(motif.move)
                .patternedType(.readingDefault)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(outcomeMessage)
                .standardType(.uiCaption)
                .foregroundStyle(outcome == .assisted ? theme.patterned.assistedColor : theme.mute(theme.ink))
                .fixedSize(horizontal: false, vertical: true)
            Button("Start again") { reset() }
                .buttonStyle(OutlineButtonStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var outcomeMessage: String {
        switch outcome {
        case .advanced?: "With the picture: lamp lit."
        case .assisted?: "The helper line was showing before you answered, so the lamp stays off. Start again without it to light it."
        case .notNext?, nil: "Right again. That lamp is already lit."
        }
    }

    private func paperCheck(_ motif: Motif) -> some View {
        let record = store.motifProgress.record(for: id)
        return PaperCheckCard(check: DeviceOffCheck(task: motif.check, answer: motif.answer), isChecked: record.parentChecked) {
            store.motifProgress.setParentChecked(!record.parentChecked, for: id)
        }
        .paperCard()
    }

    // MARK: - Actions

    private func answerBinding(_ index: Int) -> Binding<String> {
        Binding(get: { answers.indices.contains(index) ? answers[index] : "" },
                set: { if answers.indices.contains(index) { answers[index] = $0 } })
    }

    private func check(_ motif: Motif) {
        let goal = motif.scene.goal
        let typed = answers.map {
            Double($0.replacingOccurrences(of: "°", with: "").replacingOccurrences(of: "cm", with: "").trimmingCharacters(in: .whitespaces))
        }
        guard typed.allSatisfy({ $0 != nil }) else {
            nudge = "Type a number in each box."
            return
        }
        let right = zip(goal, typed).allSatisfy { quantity, value in abs(quantity.value - value!) < quantity.unit.tolerance }
        guard right else {
            nudge = showsHelper
                ? "Not quite. Look at the angles the helper line makes, then try again."
                : "Not quite, and no harm done. Look at the angles you know and try again."
            return
        }
        nudge = nil
        solved = true
        outcome = store.motifProgress.recordPicture(for: id, assisted: helperBeforeAnswer)
    }

    private func reset() {
        let scene = MotifSpine.motif(id)?.scene
        state = scene?.state ?? MotifState()
        answers = Array(repeating: "", count: scene?.goal.count ?? 0)
        lit = nil
        showsHelper = false
        helperBeforeAnswer = false
        solved = false
        outcome = nil
        nudge = nil
    }

    #if DEBUG
    private func applyDebugLaunch() {
        let defaults = UserDefaults.standard
        guard let motif = MotifSpine.motif(id) else { return }
        if defaults.bool(forKey: "MotifHelper") {
            showsHelper = true
            helperBeforeAnswer = true
        }
        if let answer = defaults.string(forKey: "MotifAnswer") {
            answers = answers.map { _ in answer }
            check(motif)
        }
        if let light = defaults.string(forKey: "MotifLight").flatMap(Int.init), motif.scene.question.indices.contains(light) {
            lit = light
        }
        state.broken = defaults.bool(forKey: "MotifBroken")
        if let drag = defaults.string(forKey: "MotifDrag") {
            let parts = drag.split(separator: ",").compactMap { Double($0) }
            if parts.count == 2 { state.free = Vec2(x: parts[0], y: parts[1]) }
        }
    }
    #endif
}

/// The motif's figure on drafting paper: lines, parallel arrows, angle arcs with their sizes,
/// and the free point she can drag once she has answered.
struct MotifBoard: View {
    let title: String
    let scene: MotifScene
    let figure: MotifFigure
    let extent: BoardExtent
    /// What the lit phrase names. Everything else fades.
    let lights: [FigureItem]?
    let showsHelper: Bool
    let showsAnswer: Bool
    let canDrag: Bool
    let onDrag: (Vec2) -> Void
    let onDragEnd: () -> Void

    /// Board offset from the pointer to the free point, while a drag that started on it runs.
    @State private var grab: Vec2?

    #if os(iOS)
    private static let reach: CGFloat = 30
    #else
    private static let reach: CGFloat = 20
    #endif

    private static let givenRoles: [ColorRole] = [.red, .blue, .amber]

    var body: some View {
        GeometryReader { geo in
            let viewport = BoardViewport(fitting: extent, in: geo.size, margin: 16)
            Canvas { context, _ in draw(in: &context, viewport) }
                .contentShape(Rectangle())
                .gesture(drag(viewport), including: canDrag ? .all : .subviews)
        }
        .background(MathsFigureColor.paper)
        .clipShape(RoundedRectangle(cornerRadius: MathsFigureRadius.frame, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: MathsFigureRadius.frame, style: .continuous)
                .strokeBorder(MathsFigureColor.ink.opacity(0.12), lineWidth: 1)
        )
        .accessibilityElement()
        .accessibilityLabel("\(title) figure")
        .accessibilityValue(accessibilityValue)
    }

    private var accessibilityValue: String {
        func spoken(_ quantity: Quantity) -> String { figure.measure(quantity.item).map(quantity.unit.spoken) ?? "" }
        let givens = scene.givens.map { "\($0.item.name) \(spoken($0))" }
        let goals = scene.goal.map { "\($0.item.name) \(showsAnswer ? spoken($0) : "unknown")" }
        return (givens + goals).joined(separator: ", ")
    }

    private func drag(_ viewport: BoardViewport) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard let free = scene.freePoint, let at = figure.points[free] else { return }
                if grab == nil {
                    let start = viewport.toView(at)
                    guard hypot(value.startLocation.x - start.x, value.startLocation.y - start.y) < Self.reach else { return }
                    grab = at - viewport.toBoard(value.startLocation)
                }
                if let grab { onDrag(viewport.toBoard(value.location) + grab) }
            }
            .onEnded { _ in
                if grab != nil { onDragEnd() }
                grab = nil
            }
    }

    // MARK: - Lighting

    private func isLit(_ item: FigureItem) -> Bool {
        guard let lights else { return true }
        if lights.contains(where: { $0.names(item) }) { return true }
        switch item {
        case let .point(p):
            return lights.contains { $0.pointNames.contains(p) }
        case let .segment(a, b):
            return lights.contains { light in
                guard case let .angle(p, v, q) = light else { return false }
                return (v == a && (b == p || b == q)) || (v == b && (a == p || a == q))
            }
        case .angle:
            return false
        }
    }

    private func ink(_ item: FigureItem, _ color: Color = MathsFigureColor.ink) -> Color {
        isLit(item) ? color : color.opacity(0.18)
    }

    // MARK: - Drawing

    private func draw(in context: inout GraphicsContext, _ viewport: BoardViewport) {
        func at(_ name: String) -> CGPoint { viewport.toView(figure.points[name]!) }

        for light in lights ?? [] {
            drawLight(light, in: &context, viewport)
        }

        if showsHelper {
            for helper in figure.helpers {
                context.stroke(BoardPaths.line(at(helper[0]), at(helper[1])), with: .color(MathsFigureColor.ink.opacity(0.6)),
                               style: StrokeStyle(lineWidth: 1.6, lineCap: .round, dash: [6, 5]))
            }
            for twin in figure.twins {
                guard case let .angle(p, v, q) = twin.helper else { continue }
                let color = roleColor(of: twin.twin)
                context.fill(BoardPaths.wedge(at(p), vertex: at(v), at(q), radius: 20), with: .color(color.opacity(0.28)))
                context.stroke(Self.arc(at(p), vertex: at(v), at(q), radius: 20), with: .color(color), lineWidth: 2)
            }
        }

        for segment in figure.segments {
            let item = FigureItem.segment(segment[0], segment[1])
            context.stroke(BoardPaths.line(at(segment[0]), at(segment[1])), with: .color(ink(item)),
                           style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
        }

        for parallel in figure.parallels {
            let item = FigureItem.segment(parallel[0], parallel[1])
            drawArrow(from: at(parallel[0]), to: at(parallel[1]), color: ink(item), in: &context)
        }

        // Longest first, so a given that lies along a longer one (AD on AB) is drawn on top of it.
        let longestFirst = scene.givens.enumerated().sorted { (figure.measure($0.element.item) ?? 0) > (figure.measure($1.element.item) ?? 0) }
        for (index, quantity) in longestFirst where Self.isSegment(quantity.item) {
            drawQuantity(quantity, color: Self.givenRoles[index % Self.givenRoles.count].figureColor,
                         label: format(figure.measure(quantity.item), unit: quantity.unit), in: &context, viewport)
        }
        for (index, quantity) in scene.givens.enumerated() where !Self.isSegment(quantity.item) {
            drawQuantity(quantity, color: Self.givenRoles[index % Self.givenRoles.count].figureColor,
                         label: format(figure.measure(quantity.item), unit: quantity.unit), in: &context, viewport)
        }
        for quantity in scene.goal {
            let asked = lights?.contains { $0.names(quantity.item) } ?? false
            let label = showsAnswer && !asked ? format(figure.measure(quantity.item), unit: quantity.unit) : "?"
            drawQuantity(quantity, color: ColorRole.green.figureColor, label: label, in: &context, viewport, radius: 34)
        }

        let lines = figure.segments + (showsHelper ? figure.helpers : [])
        for (name, position) in figure.points {
            let isHelperPoint = figure.helpers.joined().contains(name) && !figure.segments.joined().contains(name)
            if isHelperPoint && !showsHelper { continue }
            let p = viewport.toView(position)
            let color = ink(.point(name))
            context.fill(BoardPaths.circle(p, radius: 3.6), with: .color(color))
            let away = labelDirection(of: name, lines: lines, viewport)
            context.draw(Text(name).font(MathsFigureType.setSymbol).foregroundStyle(color),
                         at: CGPoint(x: p.x + 18 * away.x, y: p.y + 18 * away.y))
        }

        if canDrag, let free = scene.freePoint {
            context.stroke(BoardPaths.circle(at(free), radius: 11), with: .color(MathsFigureColor.amber),
                           lineWidth: grab == nil ? 2 : 3)
        }
    }

    /// The colour of a given angle, so the helper line's copy of it reads as the same angle.
    private func roleColor(of item: FigureItem) -> Color {
        guard let index = scene.givens.firstIndex(where: { $0.item.names(item) }) else { return MathsFigureColor.ink }
        return Self.givenRoles[index % Self.givenRoles.count].figureColor
    }

    private func drawQuantity(_ quantity: Quantity, color: Color, label: String, in context: inout GraphicsContext,
                              _ viewport: BoardViewport, radius: CGFloat = 26) {
        func at(_ name: String) -> CGPoint { viewport.toView(figure.points[name]!) }
        let shade = isLit(quantity.item) ? color : color.opacity(0.18)
        switch quantity.item {
        case let .angle(p, v, q):
            let (pp, vv, qq) = (at(p), at(v), at(q))
            let text = context.resolve(Text(label).font(MathsFigureType.areaTerm).foregroundStyle(shade))
            let size = text.measure(in: CGSize(width: 200, height: 60))
            let (u, w) = (Self.unit(pp - vv), Self.unit(qq - vv))
            let half = acos(min(1, max(-1, u.x * w.x + u.y * w.y))) / 2
            // A narrow angle moves its label out until the label fits between the arms, and takes its arc along.
            let reach = min(max(radius + 15, hypot(size.width, size.height) / 2 / max(sin(half), 0.05) + 2), 120)
            let arc = reach - 15
            context.fill(BoardPaths.wedge(pp, vertex: vv, qq, radius: arc), with: .color(shade.opacity(0.22)))
            context.stroke(Self.arc(pp, vertex: vv, qq, radius: arc), with: .color(shade), lineWidth: 2)
            let bisector = Self.unit(u + w)
            context.draw(text, at: CGPoint(x: vv.x + reach * bisector.x, y: vv.y + reach * bisector.y))
        case let .segment(a, b):
            let (pa, pb) = (at(a), at(b))
            let side: CGFloat = holdsShorterSegment(quantity.item) ? -14 : 14
            let normal = Self.unit(CGPoint(x: pa.y - pb.y, y: pb.x - pa.x))
            let middle = CGPoint(x: (pa.x + pb.x) / 2 + side * normal.x, y: (pa.y + pb.y) / 2 + side * normal.y)
            context.stroke(BoardPaths.line(pa, pb), with: .color(shade), style: StrokeStyle(lineWidth: 3.4, lineCap: .round))
            context.draw(Text(label).font(MathsFigureType.areaTerm).foregroundStyle(shade), at: middle)
        case .point:
            break
        }
    }

    private static func isSegment(_ item: FigureItem) -> Bool {
        if case .segment = item { true } else { false }
    }

    /// A segment with a shorter given or goal lying along it puts its label on the other side, so the two never stack.
    private func holdsShorterSegment(_ item: FigureItem) -> Bool {
        guard case let .segment(a, b) = item, let pa = figure.points[a], let pb = figure.points[b] else { return false }
        let along = (pb - pa).unit
        return (scene.givens + scene.goal).contains { other in
            guard case let .segment(c, d) = other.item, !other.item.names(item),
                  let pc = figure.points[c], let pd = figure.points[d] else { return false }
            let onLine = abs(along.cross(pc - pa)) < 1e-6 && abs(along.cross(pd - pa)) < 1e-6
            return onLine && pc.distance(to: pd) < pa.distance(to: pb)
        }
    }

    /// A soft band under whatever the lit phrase names.
    private func drawLight(_ item: FigureItem, in context: inout GraphicsContext, _ viewport: BoardViewport) {
        func at(_ name: String) -> CGPoint? { figure.points[name].map(viewport.toView) }
        let glow = MathsFigureColor.amber.opacity(0.35)
        switch item {
        case let .point(p):
            guard let p = at(p) else { return }
            context.fill(BoardPaths.circle(p, radius: 12), with: .color(glow))
        case let .segment(a, b):
            guard let a = at(a), let b = at(b) else { return }
            context.stroke(BoardPaths.line(a, b), with: .color(glow), style: StrokeStyle(lineWidth: 12, lineCap: .round))
        case let .angle(p, v, q):
            guard let p = at(p), let v = at(v), let q = at(q) else { return }
            context.fill(BoardPaths.wedge(p, vertex: v, q, radius: 44), with: .color(glow))
        }
    }

    /// One arrowhead at the middle of a line, pointing from `a` to `b`.
    private func drawArrow(from a: CGPoint, to b: CGPoint, color: Color, in context: inout GraphicsContext) {
        let along = Self.unit(b - a)
        let tip = CGPoint(x: (a.x + b.x) / 2 + 5 * along.x, y: (a.y + b.y) / 2 + 5 * along.y)
        let back = CGPoint(x: tip.x - 9 * along.x, y: tip.y - 9 * along.y)
        var path = Path()
        path.move(to: CGPoint(x: back.x - 6 * along.y, y: back.y + 6 * along.x))
        path.addLine(to: tip)
        path.addLine(to: CGPoint(x: back.x + 6 * along.y, y: back.y - 6 * along.x))
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
    }

    /// A letter sits in the widest gap between the lines leaving its point, including a line that runs through it.
    private func labelDirection(of name: String, lines: [[String]], _ viewport: BoardViewport) -> CGPoint {
        let here = viewport.toView(figure.points[name]!)
        var rays: [CGFloat] = []
        for line in lines {
            let (a, b) = (viewport.toView(figure.points[line[0]]!), viewport.toView(figure.points[line[1]]!))
            if line[0] == name { rays.append(atan2(b.y - here.y, b.x - here.x)) }
            if line[1] == name { rays.append(atan2(a.y - here.y, a.x - here.x)) }
            let (ab, ah) = (b - a, here - a)
            let along = (ab.x * ah.x + ab.y * ah.y) / max(ab.x * ab.x + ab.y * ab.y, 1e-9)
            if !line.contains(name), along > 0, along < 1, abs(ab.x * ah.y - ab.y * ah.x) / hypot(ab.x, ab.y) < 1 {
                rays += [atan2(ab.y, ab.x), atan2(-ab.y, -ab.x)]
            }
        }
        guard !rays.isEmpty else { return CGPoint(x: 0, y: -1) }
        let sorted = rays.sorted()
        let gaps = sorted.indices.map { i in
            let next = i + 1 < sorted.count ? sorted[i + 1] : sorted[0] + 2 * .pi
            return (from: sorted[i], width: next - sorted[i])
        }
        let widest = gaps.max { $0.width < $1.width }!
        let angle = widest.from + widest.width / 2
        return CGPoint(x: cos(angle), y: sin(angle))
    }

    private static func arc(_ p: CGPoint, vertex: CGPoint, _ q: CGPoint, radius: CGFloat) -> Path {
        let start = atan2(p.y - vertex.y, p.x - vertex.x)
        var sweep = atan2(q.y - vertex.y, q.x - vertex.x) - start
        while sweep > .pi { sweep -= 2 * .pi }
        while sweep < -.pi { sweep += 2 * .pi }
        var path = Path()
        path.addArc(center: vertex, radius: radius, startAngle: .radians(Double(start)),
                    endAngle: .radians(Double(start + sweep)), clockwise: sweep < 0)
        return path
    }

    private static func unit(_ v: CGPoint) -> CGPoint {
        let length = max(hypot(v.x, v.y), 1e-9)
        return CGPoint(x: v.x / length, y: v.y / length)
    }

    private func format(_ value: Double?, unit: QuantityUnit) -> String {
        value.map(unit.label) ?? ""
    }
}

private extension CGPoint {
    static func - (a: CGPoint, b: CGPoint) -> CGPoint { CGPoint(x: a.x - b.x, y: a.y - b.y) }
    static func + (a: CGPoint, b: CGPoint) -> CGPoint { CGPoint(x: a.x + b.x, y: a.y + b.y) }
}
