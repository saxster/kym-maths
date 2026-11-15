import SwiftUI

// MARK: - Atlas: recall the picture

/// The Atlas recall page: a picture with numbered parts, and the reader names each part with as
/// much help as they choose. "Check my labels" counts the parts named unaided, shows the rest and
/// logs the attempt.
struct AtlasRecallView: View {
    @Bindable var store: AppStore
    let backToLabs: () -> Void
    @Environment(\.standardTheme) private var theme

    @State private var help: RecallHelp = .faint
    @State private var revealedCalloutIds: Set<String> = []
    @State private var typedLabels: [String: String] = [:]
    @State private var sketchStrokes: [[CGPoint]] = []
    @State private var activeStroke: [CGPoint] = []
    @State private var resultLine: String?

    var body: some View {
        let plate = store.selectedDiagramPlate
        VStack(alignment: .leading, spacing: StandardSpacing.lg) {
            RoomHeaderRow(
                eyebrow: "Atlas · Recall the picture",
                title: "Can you name every part from memory?",
                subtitle: "\(plate.title). \(plate.sourceRef).",
                switchTitle: "Back to the labs",
                switchSymbol: "arrow.left"
            ) { backToLabs() }

            controls(plate)

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: StandardSpacing.lg) {
                    figureCard(plate)
                        .frame(minWidth: 340, idealWidth: 340, maxWidth: .infinity, alignment: .leading)
                    answers(plate)
                        .frame(width: 330)
                }
                VStack(alignment: .leading, spacing: StandardSpacing.lg) {
                    figureCard(plate)
                    answers(plate)
                }
            }
        }
        .onChange(of: store.selectedDiagramPlateId) { _, _ in startAgain(clearSketch: true) }
    }

    // MARK: Choosing a picture and the help level

    private func controls(_ plate: DiagramRecallPlate) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: StandardSpacing.lg) {
                platePicker(plate)
                helpPicker
            }
            VStack(alignment: .leading, spacing: StandardSpacing.sm) {
                platePicker(plate)
                helpPicker
            }
        }
    }

    private func platePicker(_ plate: DiagramRecallPlate) -> some View {
        HStack(spacing: StandardSpacing.sm) {
            Kicker("Picture", muted: true)
            Menu {
                ForEach(Array(store.seedPack.diagramPlates.enumerated()), id: \.element.id) { idx, p in
                    Button("\(idx + 1). \(p.title)") { store.selectedDiagramPlateId = p.id }
                }
            } label: {
                HStack(spacing: StandardSpacing.xs) {
                    Text("Plate \(plateNumber(plate))")
                        .standardType(.uiBody)
                        .foregroundStyle(theme.ink)
                    Image(systemName: "chevron.up.chevron.down")
                        .imageScale(.small)
                        .foregroundStyle(theme.mute(theme.ink))
                }
                .padding(.horizontal, StandardSpacing.md)
                .frame(minHeight: 34)
                .background(Capsule().fill(theme.surface))
                .overlay(Capsule().strokeBorder(theme.hairline(), lineWidth: 1))
                .frame(minHeight: StandardAccessibility.touchTarget)
            }
            .fixedSize()
            .accessibilityLabel("Choose a picture")
        }
    }

    private var helpPicker: some View {
        HStack(spacing: StandardSpacing.xs) {
            Kicker("How much help", muted: true)
                .fixedSize()
            ForEach(RecallHelp.allCases) { level in
                PatternedChip(level.title, isSelected: help == level) {
                    help = level
                    resultLine = nil
                }
            }
        }
    }

    private func plateNumber(_ plate: DiagramRecallPlate) -> Int {
        (store.seedPack.diagramPlates.firstIndex(where: { $0.id == plate.id }) ?? 0) + 1
    }

    // MARK: The picture

    private func figureCard(_ plate: DiagramRecallPlate) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            MathematicalDiagramPlateCanvasView(
                plate: plate,
                diagramMode: help.rawValue,
                revealedCalloutIds: $revealedCalloutIds,
                strokes: $sketchStrokes,
                activeStroke: $activeStroke
            )
            .frame(height: 380)

            HStack(alignment: .firstTextBaseline) {
                Text("Plate \(plateNumber(plate)) · \(plate.sourceRef). Sketch on it to think.")
                    .standardType(.uiCaption)
                    .foregroundStyle(theme.mute(theme.ink))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: StandardSpacing.sm)
                if !sketchStrokes.isEmpty {
                    Button("Clear my sketch") { sketchStrokes.removeAll() }
                        .buttonStyle(TextLinkButtonStyle(arrow: false))
                }
            }
        }
        .paperCard(padding: StandardSpacing.md)
    }

    // MARK: Naming the parts

    private func answers(_ plate: DiagramRecallPlate) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.md) {
            VStack(spacing: 0) {
                ForEach(Array(plate.callouts.enumerated()), id: \.element.id) { idx, callout in
                    calloutRow(number: idx + 1, callout: callout)
                    if idx < plate.callouts.count - 1 {
                        Rectangle().fill(theme.hairline()).frame(height: 1)
                    }
                }
            }
            .paperCard(padding: 0)

            VStack(alignment: .leading, spacing: StandardSpacing.sm) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: StandardSpacing.md) {
                        checkButton(plate)
                        triedLine(plate)
                    }
                    VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                        checkButton(plate)
                        triedLine(plate)
                    }
                }
                if let resultLine {
                    Text(resultLine)
                        .patternedType(.readingSmall)
                        .foregroundStyle(theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Try again") { startAgain(clearSketch: false) }
                        .buttonStyle(TextLinkButtonStyle())
                }
            }
            .paperCard(padding: StandardSpacing.md)
        }
    }

    private func calloutRow(number: Int, callout: DiagramCalloutPin) -> some View {
        let isRevealed = help == .study || revealedCalloutIds.contains(callout.id)
        return HStack(alignment: .top, spacing: StandardSpacing.sm) {
            Text("\(number)")
                .standardType(.uiCaption)
                .foregroundStyle(isRevealed ? theme.bg : theme.ink)
                .frame(width: 26, height: 26)
                .background(Circle().fill(isRevealed ? theme.ink : Color.clear))
                .overlay(Circle().strokeBorder(theme.ink, lineWidth: 1))
                .padding(.top, 9)
                .accessibilityLabel("Part \(number)")

            VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                if isRevealed {
                    Text(callout.label)
                        .patternedType(.mathInline)
                        .foregroundStyle(theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(minHeight: StandardAccessibility.touchTarget, alignment: .leading)
                } else {
                    TextField("type what this is", text: binding(for: callout.id))
                        .learnerTextInput(.retrieval)
                        .paperField(dashed: true)
                        .accessibilityLabel("Name part \(number)")
                }
                if help != .memory {
                    Text("\(help == .faint ? "Faint hint" : "Hint"): \(callout.hint)")
                        .standardType(.uiCaption)
                        .foregroundStyle(theme.mute(theme.ink))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if help != .study {
                Button {
                    toggleReveal(callout.id)
                } label: {
                    Image(systemName: isRevealed ? "checkmark" : "eye")
                        .foregroundStyle(isRevealed ? theme.patterned.provenColor : theme.mute(theme.ink))
                        .frame(width: StandardAccessibility.touchTarget, height: StandardAccessibility.touchTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isRevealed ? "Hide the name of part \(number)" : "Show the name of part \(number)")
            }
        }
        .padding(.horizontal, StandardSpacing.md)
        .padding(.vertical, StandardSpacing.sm)
    }

    private func checkButton(_ plate: DiagramRecallPlate) -> some View {
        Button {
            check(plate)
        } label: {
            HStack(spacing: StandardSpacing.xs) {
                Text("Check my labels")
                Image(systemName: "arrow.right").imageScale(.small)
            }
        }
        .buttonStyle(InkButtonStyle())
    }

    private func triedLine(_ plate: DiagramRecallPlate) -> some View {
        let tries = store.diagramAttempts.filter { $0.plateId == plate.id }.count
        let text = switch tries {
        case 0: "Not tried yet"
        case 1: "Tried once"
        default: "Tried \(tries) times"
        }
        return Label(text, systemImage: "clock")
            .standardType(.uiCaption)
            .foregroundStyle(theme.mute(theme.ink))
    }

    // MARK: Actions

    private func binding(for id: String) -> Binding<String> {
        Binding(
            get: { typedLabels[id] ?? "" },
            set: { typedLabels[id] = $0 }
        )
    }

    private func toggleReveal(_ id: String) {
        if revealedCalloutIds.contains(id) {
            revealedCalloutIds.remove(id)
        } else {
            revealedCalloutIds.insert(id)
        }
    }

    private func check(_ plate: DiagramRecallPlate) {
        let total = plate.callouts.count
        let named: Int
        let score: Int
        if help == .study {
            named = total
            score = 5
            resultLine = "You studied all \(total) parts. Try Faint hints when you're ready."
        } else {
            named = plate.callouts.filter { callout in
                !revealedCalloutIds.contains(callout.id)
                    && RecallLabelMatch.matches(typedLabels[callout.id] ?? "", label: callout.label)
            }.count
            score = total == 0 ? 1 : max(1, Int((Double(named) / Double(total) * 5).rounded()))
            resultLine = named == total
                ? "You named all \(total) parts yourself."
                : "You named \(named) of \(total) yourself. The rest are showing now: look at them, then try again."
        }
        revealedCalloutIds = Set(plate.callouts.map(\.id))
        store.recordDiagramRecallAttempt(plate: plate, mode: help.rawValue, correctCount: named, selfScore: score)
    }

    private func startAgain(clearSketch: Bool) {
        revealedCalloutIds.removeAll()
        typedLabels.removeAll()
        resultLine = nil
        if clearSketch { sketchStrokes.removeAll() }
    }
}

/// How much help the recall page gives. The raw values are the modes the attempt log stores.
enum RecallHelp: String, CaseIterable, Identifiable {
    case study = "label_only"
    case faint = "ghost_scaffold"
    case memory = "blank_recall"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .study: "Study the labels"
        case .faint: "Faint hints"
        case .memory: "From memory"
        }
    }
}

/// Whether a typed name matches a part's label. A label like "HCF (Shared Prime Overlap)" accepts
/// the whole label, the part before the brackets or the part inside them, ignoring case, spaces
/// and punctuation, or most of one of those.
enum RecallLabelMatch {
    static func matches(_ typed: String, label: String) -> Bool {
        let answer = normalized(typed)
        guard !answer.isEmpty else { return false }
        var candidates = [normalized(label)]
        if let open = label.firstIndex(of: "(") {
            candidates.append(normalized(String(label[..<open])))
            if let close = label.lastIndex(of: ")"), open < close {
                candidates.append(normalized(String(label[label.index(after: open)..<close])))
            }
        }
        return candidates.contains { candidate in
            !candidate.isEmpty && (candidate == answer || (candidate.contains(answer) && answer.count * 3 >= candidate.count * 2))
        }
    }

    static func normalized(_ text: String) -> String {
        text.lowercased().filter { !$0.isWhitespace && !",.;:'\"!?".contains($0) }
    }
}

// MARK: - The picture and its numbered pins

/// A recall plate: the figure on drafting paper, numbered pins at each part, and the reader's
/// own sketch on top. Tapping a pin shows or hides that part's name.
struct MathematicalDiagramPlateCanvasView: View {
    let plate: DiagramRecallPlate
    let diagramMode: String
    @Binding var revealedCalloutIds: Set<String>
    @Binding var strokes: [[CGPoint]]
    @Binding var activeStroke: [CGPoint]

    // The plate's own palette: Byrne's colours on drafting paper, which does not follow the theme.
    private let cRed = MathsFigureColor.roleColor("red")
    private let cBlue = MathsFigureColor.roleColor("blue")
    private let cAmber = MathsFigureColor.roleColor("amber")
    private let cGreen = MathsFigureColor.roleColor("green")
    private let cInk = MathsFigureColor.ink

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                    .fill(MathsFigureColor.paper)

                Canvas { context, canvasSize in
                    drawDraftingGrid(in: &context, size: canvasSize)
                    drawFigureGeometry(figureId: plate.figureId, in: &context, size: canvasSize)
                    drawUserStrokes(in: &context)
                }
                .clipShape(RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous))
                .gesture(
                    DragGesture(minimumDistance: 2)
                        .onChanged { value in
                            activeStroke.append(value.location)
                        }
                        .onEnded { _ in
                            if activeStroke.count >= 2 {
                                strokes.append(activeStroke)
                            }
                            activeStroke.removeAll()
                        }
                )

                ForEach(Array(plate.callouts.enumerated()), id: \.element.id) { idx, callout in
                    let isRevealed = diagramMode == "label_only" || revealedCalloutIds.contains(callout.id)
                    let pt = CGPoint(
                        x: CGFloat(callout.xFraction) * size.width,
                        y: CGFloat(callout.yFraction) * size.height
                    )
                    Button {
                        if revealedCalloutIds.contains(callout.id) {
                            revealedCalloutIds.remove(callout.id)
                        } else {
                            revealedCalloutIds.insert(callout.id)
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Text("\(idx + 1)")
                                .font(MathsFigureType.labelMono)
                                .foregroundStyle(isRevealed ? MathsFigureColor.paper : cInk)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(isRevealed ? cInk : MathsFigureColor.paper))
                                .overlay(Circle().strokeBorder(cInk, lineWidth: 1.2))
                            if isRevealed {
                                Text(callout.label)
                                    .font(MathsFigureType.labelMedium)
                                    .foregroundStyle(cInk)
                                    .lineLimit(1)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(MathsFigureColor.paper.opacity(0.92)))
                            }
                        }
                        .frame(minWidth: StandardAccessibility.touchTarget, minHeight: StandardAccessibility.touchTarget)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isRevealed ? "Part \(idx + 1): \(callout.label)" : "Part \(idx + 1)")
                    .position(
                        x: min(max(pt.x, isRevealed ? 80 : 24), size.width - (isRevealed ? 80 : 24)),
                        y: min(max(pt.y, 22), size.height - 22)
                    )
                }
            }
        }
    }

    private func drawDraftingGrid(in context: inout GraphicsContext, size: CGSize) {
        let step: CGFloat = 24
        var grid = Path()
        var x: CGFloat = step
        while x < size.width {
            grid.move(to: CGPoint(x: x, y: 0))
            grid.addLine(to: CGPoint(x: x, y: size.height))
            x += step
        }
        var y: CGFloat = step
        while y < size.height {
            grid.move(to: CGPoint(x: 0, y: y))
            grid.addLine(to: CGPoint(x: size.width, y: y))
            y += step
        }
        context.stroke(grid, with: .color(cInk.opacity(0.04)), lineWidth: 0.75)
    }

    /// The reader's sketch, in Byrne blue like all their handwriting.
    private func drawUserStrokes(in context: inout GraphicsContext) {
        for stroke in strokes where stroke.count >= 2 {
            var p = Path()
            p.move(to: stroke[0])
            for pt in stroke.dropFirst() { p.addLine(to: pt) }
            context.stroke(p, with: .color(cBlue), lineWidth: 2.2)
        }
        if activeStroke.count >= 2 {
            var p = Path()
            p.move(to: activeStroke[0])
            for pt in activeStroke.dropFirst() { p.addLine(to: pt) }
            context.stroke(p, with: .color(cBlue.opacity(0.6)), lineWidth: 2.2)
        }
    }

    private func drawFigureGeometry(figureId: String, in context: inout GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height

        switch figureId {
        case "fig-venn":
            let box = CGRect(x: 0.08 * w, y: 0.10 * h, width: 0.84 * w, height: 0.80 * h)
            context.fill(Path(roundedRect: box, cornerRadius: MathsFigureRadius.frame), with: .color(cAmber.opacity(0.08)))
            context.stroke(Path(roundedRect: box, cornerRadius: MathsFigureRadius.frame), with: .color(cInk.opacity(0.45)), lineWidth: 1.5)
            let r = min(w, h) * 0.27
            let cA = CGRect(x: 0.40 * w - r, y: 0.48 * h - r, width: 2 * r, height: 2 * r)
            let cB = CGRect(x: 0.60 * w - r, y: 0.48 * h - r, width: 2 * r, height: 2 * r)
            context.fill(Path(ellipseIn: cA), with: .color(cRed.opacity(0.20)))
            context.fill(Path(ellipseIn: cB), with: .color(cBlue.opacity(0.20)))
            let lens = CGRect(x: 0.45 * w, y: 0.28 * h, width: 0.10 * w, height: 0.40 * h)
            context.fill(Path(ellipseIn: lens), with: .color(cGreen.opacity(0.26)))
            context.stroke(Path(ellipseIn: cA), with: .color(cRed), lineWidth: 2.4)
            context.stroke(Path(ellipseIn: cB), with: .color(cBlue), lineWidth: 2.4)
            context.draw(Text("ℰ").font(MathsFigureType.setSymbol).foregroundStyle(cInk), at: CGPoint(x: 0.11 * w, y: 0.15 * h))

        case "fig-prime-venn":
            let r = min(w, h) * 0.27
            let cA = CGRect(x: 0.39 * w - r, y: 0.48 * h - r, width: 2 * r, height: 2 * r)
            let cB = CGRect(x: 0.61 * w - r, y: 0.48 * h - r, width: 2 * r, height: 2 * r)
            context.fill(Path(ellipseIn: cA), with: .color(cRed.opacity(0.18)))
            context.fill(Path(ellipseIn: cB), with: .color(cBlue.opacity(0.18)))
            context.stroke(Path(ellipseIn: cA), with: .color(cRed), lineWidth: 2.4)
            context.stroke(Path(ellipseIn: cB), with: .color(cBlue), lineWidth: 2.4)
            var brace = Path()
            brace.move(to: CGPoint(x: 0.20 * w, y: 0.78 * h))
            brace.addLine(to: CGPoint(x: 0.20 * w, y: 0.84 * h))
            brace.addLine(to: CGPoint(x: 0.80 * w, y: 0.84 * h))
            brace.addLine(to: CGPoint(x: 0.80 * w, y: 0.78 * h))
            context.stroke(brace, with: .color(cGreen), lineWidth: 2.2)

        case "fig-area-tiles":
            let x0 = 0.16 * w, xSplit = 0.54 * w, x1 = 0.86 * w
            let y0 = 0.16 * h, ySplit = 0.56 * h, y1 = 0.88 * h
            let rXX = CGRect(x: x0, y: y0, width: xSplit - x0, height: ySplit - y0)
            let rAX = CGRect(x: xSplit, y: y0, width: x1 - xSplit, height: ySplit - y0)
            let rBX = CGRect(x: x0, y: ySplit, width: xSplit - x0, height: y1 - ySplit)
            let rAB = CGRect(x: xSplit, y: ySplit, width: x1 - xSplit, height: y1 - ySplit)
            context.fill(Path(rXX), with: .color(cRed.opacity(0.22)))
            context.fill(Path(rAX), with: .color(cBlue.opacity(0.20)))
            context.fill(Path(rBX), with: .color(cBlue.opacity(0.20)))
            context.fill(Path(rAB), with: .color(cAmber.opacity(0.28)))
            for rect in [rXX, rAX, rBX, rAB] {
                context.stroke(Path(rect), with: .color(cInk.opacity(0.75)), lineWidth: 2)
            }

        case "fig-bisector":
            let pA = CGPoint(x: 0.24 * w, y: 0.50 * h)
            let pB = CGPoint(x: 0.76 * w, y: 0.50 * h)
            let pP = CGPoint(x: 0.50 * w, y: 0.20 * h)
            let pQ = CGPoint(x: 0.50 * w, y: 0.80 * h)
            let pM = CGPoint(x: 0.50 * w, y: 0.50 * h)
            var segAB = Path()
            segAB.move(to: pA); segAB.addLine(to: pB)
            context.stroke(segAB, with: .color(cInk), lineWidth: 2.5)
            var rhombus = Path()
            rhombus.move(to: pA); rhombus.addLine(to: pP); rhombus.addLine(to: pB); rhombus.addLine(to: pQ); rhombus.closeSubpath()
            context.stroke(rhombus, with: .color(cAmber), style: StrokeStyle(lineWidth: 1.8, dash: [6, 4]))
            var bisector = Path()
            bisector.move(to: CGPoint(x: 0.50 * w, y: 0.10 * h))
            bisector.addLine(to: CGPoint(x: 0.50 * w, y: 0.90 * h))
            context.stroke(bisector, with: .color(cGreen), lineWidth: 2.5)
            let sq = CGRect(x: pM.x, y: pM.y - 12, width: 12, height: 12)
            context.stroke(Path(sq), with: .color(cGreen), lineWidth: 1.8)

        case "fig-bearings":
            let pA = CGPoint(x: 0.28 * w, y: 0.62 * h)
            let pB = CGPoint(x: 0.68 * w, y: 0.44 * h)
            var northA = Path()
            northA.move(to: pA); northA.addLine(to: CGPoint(x: pA.x, y: 0.14 * h))
            var northB = Path()
            northB.move(to: pB); northB.addLine(to: CGPoint(x: pB.x, y: 0.12 * h))
            context.stroke(northA, with: .color(cBlue), lineWidth: 2.4)
            context.stroke(northB, with: .color(cBlue), lineWidth: 2.4)
            var rayAB = Path()
            rayAB.move(to: pA); rayAB.addLine(to: pB)
            context.stroke(rayAB, with: .color(cRed), lineWidth: 2.6)
            var arc1 = Path()
            arc1.addArc(center: pA, radius: 34, startAngle: .degrees(-90), endAngle: .degrees(-24), clockwise: false)
            context.stroke(arc1, with: .color(cRed), lineWidth: 2.2)
            var arc2 = Path()
            arc2.addArc(center: pB, radius: 38, startAngle: .degrees(-90), endAngle: .degrees(156), clockwise: false)
            context.stroke(arc2, with: .color(cAmber), lineWidth: 2.2)

        case "fig-circle-pi":
            let x0 = 0.20 * w, x1 = 0.82 * w, y0 = 0.28 * h, y1 = 0.76 * h
            let n = 10
            let dx = (x1 - x0) / CGFloat(n)
            for i in 0..<n {
                var tri = Path()
                let xi = x0 + CGFloat(i) * dx
                if i % 2 == 0 {
                    tri.move(to: CGPoint(x: xi, y: y1))
                    tri.addLine(to: CGPoint(x: xi + dx, y: y1))
                    tri.addLine(to: CGPoint(x: xi + dx * 0.5, y: y0))
                } else {
                    tri.move(to: CGPoint(x: xi, y: y0))
                    tri.addLine(to: CGPoint(x: xi + dx, y: y0))
                    tri.addLine(to: CGPoint(x: xi + dx * 0.5, y: y1))
                }
                tri.closeSubpath()
                context.fill(tri, with: .color((i % 2 == 0 ? cRed : cBlue).opacity(0.24)))
                context.stroke(tri, with: .color(i % 2 == 0 ? cRed : cBlue), lineWidth: 1.6)
            }
            var hLine = Path()
            hLine.move(to: CGPoint(x: x0, y: y0)); hLine.addLine(to: CGPoint(x: x0, y: y1))
            context.stroke(hLine, with: .color(cGreen), lineWidth: 3)

        case "fig-trapezium":
            var trap1 = Path()
            trap1.move(to: CGPoint(x: 0.24 * w, y: 0.76 * h))
            trap1.addLine(to: CGPoint(x: 0.62 * w, y: 0.76 * h))
            trap1.addLine(to: CGPoint(x: 0.54 * w, y: 0.24 * h))
            trap1.addLine(to: CGPoint(x: 0.30 * w, y: 0.24 * h))
            trap1.closeSubpath()
            context.fill(trap1, with: .color(cRed.opacity(0.22)))
            context.stroke(trap1, with: .color(cRed), lineWidth: 2.3)

            var trap2 = Path()
            trap2.move(to: CGPoint(x: 0.62 * w, y: 0.76 * h))
            trap2.addLine(to: CGPoint(x: 0.86 * w, y: 0.76 * h))
            trap2.addLine(to: CGPoint(x: 0.92 * w, y: 0.24 * h))
            trap2.addLine(to: CGPoint(x: 0.54 * w, y: 0.24 * h))
            trap2.closeSubpath()
            context.fill(trap2, with: .color(cBlue.opacity(0.18)))
            context.stroke(trap2, with: .color(cBlue), style: StrokeStyle(lineWidth: 2.0, dash: [6, 4]))

            var alt = Path()
            alt.move(to: CGPoint(x: 0.30 * w, y: 0.24 * h))
            alt.addLine(to: CGPoint(x: 0.30 * w, y: 0.76 * h))
            context.stroke(alt, with: .color(cGreen), style: StrokeStyle(lineWidth: 2.2, dash: [4, 3]))

        case "fig-parallel":
            var p1 = Path()
            p1.move(to: CGPoint(x: 0.12 * w, y: 0.28 * h)); p1.addLine(to: CGPoint(x: 0.88 * w, y: 0.28 * h))
            var p2 = Path()
            p2.move(to: CGPoint(x: 0.12 * w, y: 0.72 * h)); p2.addLine(to: CGPoint(x: 0.88 * w, y: 0.72 * h))
            context.stroke(p1, with: .color(cBlue), lineWidth: 2.4)
            context.stroke(p2, with: .color(cBlue), lineWidth: 2.4)
            var trans1 = Path()
            trans1.move(to: CGPoint(x: 0.28 * w, y: 0.84 * h)); trans1.addLine(to: CGPoint(x: 0.68 * w, y: 0.14 * h))
            var trans2 = Path()
            trans2.move(to: CGPoint(x: 0.56 * w, y: 0.28 * h)); trans2.addLine(to: CGPoint(x: 0.76 * w, y: 0.72 * h))
            context.stroke(trans1, with: .color(cRed), lineWidth: 2.3)
            context.stroke(trans2, with: .color(cAmber), lineWidth: 2.3)

        case "fig-histogram":
            let baseY = 0.78 * h
            let bars: [(CGFloat, CGFloat, CGFloat, Color)] = [
                (0.20, 0.08, 0.36, cBlue),
                (0.28, 0.12, 0.52, cRed),
                (0.40, 0.20, 0.28, cAmber)
            ]
            for (bx, bw, bh, col) in bars {
                let r = CGRect(x: bx * w, y: baseY - bh * h, width: bw * w, height: bh * h)
                context.fill(Path(r), with: .color(col.opacity(0.25)))
                context.stroke(Path(r), with: .color(col), lineWidth: 2)
            }
            let boxRect = CGRect(x: 0.68 * w, y: 0.26 * h, width: 0.16 * w, height: 0.16 * h)
            context.fill(Path(boxRect), with: .color(cGreen.opacity(0.22)))
            context.stroke(Path(boxRect), with: .color(cGreen), lineWidth: 2.2)
            var whisker = Path()
            whisker.move(to: CGPoint(x: 0.62 * w, y: 0.34 * h)); whisker.addLine(to: CGPoint(x: 0.90 * w, y: 0.34 * h))
            context.stroke(whisker, with: .color(cGreen), lineWidth: 2)

        case "fig-bar-model":
            let unitW = 0.11 * w
            let startX = 0.20 * w
            for i in 0..<5 {
                let r = CGRect(x: startX + CGFloat(i) * unitW, y: 0.28 * h, width: unitW - 2, height: 0.16 * h)
                let col = i < 3 ? cRed : cAmber
                context.fill(Path(roundedRect: r, cornerRadius: MathsFigureRadius.tile), with: .color(col.opacity(0.25)))
                context.stroke(Path(roundedRect: r, cornerRadius: MathsFigureRadius.tile), with: .color(col), lineWidth: 2)
            }
            for i in 0..<3 {
                let r = CGRect(x: startX + CGFloat(i) * unitW, y: 0.68 * h, width: unitW - 2, height: 0.16 * h)
                context.fill(Path(roundedRect: r, cornerRadius: MathsFigureRadius.tile), with: .color(cBlue.opacity(0.25)))
                context.stroke(Path(roundedRect: r, cornerRadius: MathsFigureRadius.tile), with: .color(cBlue), lineWidth: 2)
            }

        case "fig-enlargement":
            let pC = CGPoint(x: 0.16 * w, y: 0.76 * h)
            let objPts = [CGPoint(x: 0.36 * w, y: 0.70 * h), CGPoint(x: 0.46 * w, y: 0.70 * h), CGPoint(x: 0.40 * w, y: 0.54 * h)]
            let imgPts = [CGPoint(x: 0.56 * w, y: 0.64 * h), CGPoint(x: 0.76 * w, y: 0.64 * h), CGPoint(x: 0.64 * w, y: 0.32 * h)]
            for pt in imgPts {
                var ray = Path()
                ray.move(to: pC); ray.addLine(to: pt)
                context.stroke(ray, with: .color(cAmber), style: StrokeStyle(lineWidth: 1.6, dash: [5, 4]))
            }
            var obj = Path(); obj.addLines(objPts); obj.closeSubpath()
            context.fill(obj, with: .color(cBlue.opacity(0.25)))
            context.stroke(obj, with: .color(cBlue), lineWidth: 2.2)
            var img = Path(); img.addLines(imgPts); img.closeSubpath()
            context.fill(img, with: .color(cRed.opacity(0.22)))
            context.stroke(img, with: .color(cRed), lineWidth: 2.4)

        case "fig-linear":
            var axes = Path()
            axes.move(to: CGPoint(x: 0.28 * w, y: 0.12 * h)); axes.addLine(to: CGPoint(x: 0.28 * w, y: 0.88 * h))
            axes.move(to: CGPoint(x: 0.12 * w, y: 0.76 * h)); axes.addLine(to: CGPoint(x: 0.88 * w, y: 0.76 * h))
            context.stroke(axes, with: .color(cInk.opacity(0.6)), lineWidth: 2)
            var line1 = Path()
            line1.move(to: CGPoint(x: 0.18 * w, y: 0.74 * h)); line1.addLine(to: CGPoint(x: 0.82 * w, y: 0.22 * h))
            context.stroke(line1, with: .color(cRed), lineWidth: 2.6)
            var step = Path()
            step.move(to: CGPoint(x: 0.28 * w, y: 0.66 * h))
            step.addLine(to: CGPoint(x: 0.68 * w, y: 0.66 * h))
            step.addLine(to: CGPoint(x: 0.68 * w, y: 0.33 * h))
            context.stroke(step, with: .color(cBlue), style: StrokeStyle(lineWidth: 2.0, dash: [5, 3]))
            var perp = Path()
            perp.move(to: CGPoint(x: 0.26 * w, y: 0.18 * h)); perp.addLine(to: CGPoint(x: 0.68 * w, y: 0.66 * h))
            context.stroke(perp, with: .color(cGreen), style: StrokeStyle(lineWidth: 2.0, dash: [4, 4]))

        case "fig-unit-circle":
            let cx = 0.48 * w, cy = 0.68 * h, r = min(w, h) * 0.36
            let circleRect = CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r)
            context.stroke(Path(ellipseIn: circleRect), with: .color(cInk.opacity(0.65)), lineWidth: 2)
            let px = cx + r * cos(.pi / 4), py = cy - r * sin(.pi / 4)
            var cosLeg = Path(); cosLeg.move(to: CGPoint(x: cx, y: cy)); cosLeg.addLine(to: CGPoint(x: px, y: cy))
            var sinLeg = Path(); sinLeg.move(to: CGPoint(x: px, y: cy)); sinLeg.addLine(to: CGPoint(x: px, y: py))
            var hyp = Path(); hyp.move(to: CGPoint(x: cx, y: cy)); hyp.addLine(to: CGPoint(x: px, y: py))
            context.stroke(cosLeg, with: .color(cBlue), lineWidth: 3)
            context.stroke(sinLeg, with: .color(cRed), lineWidth: 3)
            context.stroke(hyp, with: .color(cInk), lineWidth: 2.4)
            var tanSeg = Path()
            tanSeg.move(to: CGPoint(x: cx + r, y: cy)); tanSeg.addLine(to: CGPoint(x: cx + r, y: cy - r))
            context.stroke(tanSeg, with: .color(cAmber), lineWidth: 3)

        case "fig-bayes":
            let sq = CGRect(x: 0.16 * w, y: 0.18 * h, width: 0.56 * w, height: 0.62 * h)
            let splitX = sq.minX + sq.width * 0.18
            let tpRect = CGRect(x: sq.minX, y: sq.minY + sq.height * 0.08, width: splitX - sq.minX, height: sq.height * 0.92)
            let fpRect = CGRect(x: splitX, y: sq.minY + sq.height * 0.72, width: sq.maxX - splitX, height: sq.height * 0.28)
            context.stroke(Path(sq), with: .color(cInk.opacity(0.6)), lineWidth: 2)
            context.fill(Path(tpRect), with: .color(cRed.opacity(0.32)))
            context.stroke(Path(tpRect), with: .color(cRed), lineWidth: 2)
            context.fill(Path(fpRect), with: .color(cAmber.opacity(0.32)))
            context.stroke(Path(fpRect), with: .color(cAmber), lineWidth: 2)
            let postTP = CGRect(x: 0.82 * w, y: 0.24 * h, width: 0.08 * w, height: 0.22 * h)
            let postFP = CGRect(x: 0.82 * w, y: 0.46 * h, width: 0.08 * w, height: 0.34 * h)
            context.fill(Path(postTP), with: .color(cRed.opacity(0.38)))
            context.fill(Path(postFP), with: .color(cAmber.opacity(0.38)))
            context.stroke(Path(postTP.union(postFP)), with: .color(cGreen), lineWidth: 2)

        case "fig-calculus":
            var curve = Path()
            for i in 0...40 {
                let t = CGFloat(i) / 40.0
                let x = (0.14 + 0.74 * t) * w
                let y = (0.80 - 0.56 * t * t) * h
                if i == 0 { curve.move(to: CGPoint(x: x, y: y)) } else { curve.addLine(to: CGPoint(x: x, y: y)) }
            }
            for i in 4..<8 {
                let t = CGFloat(i) / 8.0
                let bx = (0.14 + 0.74 * t) * w
                let bw = (0.74 / 8.0) * w
                let by = (0.80 - 0.56 * t * t) * h
                let r = CGRect(x: bx, y: by, width: bw - 2, height: 0.80 * h - by)
                context.fill(Path(r), with: .color(cBlue.opacity(0.22)))
                context.stroke(Path(r), with: .color(cBlue), lineWidth: 1.5)
            }
            context.stroke(curve, with: .color(cInk), lineWidth: 2.6)
            var secant = Path()
            secant.move(to: CGPoint(x: 0.32 * w, y: 0.72 * h))
            secant.addLine(to: CGPoint(x: 0.58 * w, y: 0.72 * h))
            secant.addLine(to: CGPoint(x: 0.58 * w, y: 0.46 * h))
            context.stroke(secant, with: .color(cRed), style: StrokeStyle(lineWidth: 2.0, dash: [5, 3]))

        default: // "fig-matrices"
            let o = CGPoint(x: 0.22 * w, y: 0.76 * h)
            let v1 = CGPoint(x: 0.56 * w, y: 0.64 * h)
            let v2 = CGPoint(x: 0.34 * w, y: 0.32 * h)
            let v12 = CGPoint(x: v1.x + v2.x - o.x, y: v1.y + v2.y - o.y)
            var para = Path()
            para.move(to: o); para.addLine(to: v1); para.addLine(to: v12); para.addLine(to: v2); para.closeSubpath()
            context.fill(para, with: .color(cGreen.opacity(0.22)))
            context.stroke(para, with: .color(cGreen), lineWidth: 2)
            var a1 = Path(); a1.move(to: o); a1.addLine(to: v1)
            var a2 = Path(); a2.move(to: o); a2.addLine(to: v2)
            var eig = Path(); eig.move(to: o); eig.addLine(to: CGPoint(x: 0.84 * w, y: 0.20 * h))
            context.stroke(a1, with: .color(cRed), lineWidth: 3)
            context.stroke(a2, with: .color(cBlue), lineWidth: 3)
            context.stroke(eig, with: .color(cAmber), style: StrokeStyle(lineWidth: 2.2, dash: [6, 4]))
        }
    }
}
