import SwiftUI

// MARK: - Room 4: 3D Atlas & Active-Recall Diagram Plates (@saxster/atlas + 47 Widgets + 16 Plates)

struct LabsAtlasHomeView: View {
    @Bindable var store: AppStore

    @State private var challengeNote: String = ""
    @State private var diagramMode: String = "ghost_scaffold"
    @State private var revealedCalloutIds: Set<String> = []
    @State private var diagramInputs: [String: String] = [:]
    @State private var showEmbeddedWebStage: Bool = true
    @State private var plateSketchStrokes: [[CGPoint]] = []
    @State private var activePlateStroke: [CGPoint] = []

    var body: some View {
        let widget = store.selectedWidget
        let stamp = store.widgetStampsById[widget.id]
        let plate = store.selectedDiagramPlate

        JournalPage {
            EditorialHeader(
                eyebrow: "3D Mathematical Atlas & Diagram Recall Studio",
                title: "47 Interactive Labs + @saxster/atlas 3D Figures + 16 Diagram Plates",
                subtitle: "Powered by the pure-model @saxster/atlas engine (21 3D Chapter Apparatuses + Unit Circle, Secant-to-Tangent Calculus, 3D Matrix Sandbox, Galton Board, Bayes' 1,000-Person Unit Square & Compound Cascade)."
            )

            // 1. @saxster/atlas 3D Gallery
            JournalCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.xs) {
                            ForEach(store.seedPack.widgets) { w in
                                MathsFilterChip(
                                    title: "Ch \(w.chapter) · \(w.title)",
                                    systemImage: store.widgetStampsById[w.id] != nil ? "checkmark.seal.fill" : (w.is3D ? "cube.transparent.fill" : "slider.horizontal.below.rectangle"),
                                    isSelected: store.selectedWidgetId == w.id
                                ) {
                                    store.selectedWidgetId = w.id
                                }
                            }
                        }
                    }
                }
            }

            // 2. Active Widget & @saxster/atlas Inspector
            JournalSection(
                title: widget.title,
                eyebrow: "Chapter \(widget.chapter) · Atlas Route: \(widget.atlasRoute)"
            ) {
                JournalCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            JournalBadge(text: widget.is3D ? "3D WebGL / Atlas Figure" : "2D Interactive Figure", symbol: "cube.transparent", tone: .accent)
                            JournalBadge(text: widget.atlasRoute, symbol: "link", tone: .info)
                            if let s = stamp {
                                JournalBadge(text: "Stamped \(s.earnedAt.formatted(date: .abbreviated, time: .omitted))", symbol: "checkmark.seal.fill", tone: .positive)
                            }
                            Spacer()
                            Button {
                                showEmbeddedWebStage.toggle()
                            } label: {
                                Label(showEmbeddedWebStage ? "Hide Live Stage" : "Show Live Stage", systemImage: "cube.transparent")
                            }
                            .buttonStyle(JournalSecondaryButtonStyle())

                            Button {
                                store.selectedChapterNumber = widget.chapter
                                store.activeRoom = .patternedWorld
                            } label: {
                                Label("Launch in Full Stage", systemImage: "arrow.up.right.square")
                            }
                            .buttonStyle(JournalSecondaryButtonStyle())
                        }

                        if showEmbeddedWebStage {
                            PatternedWorldWebStageView(
                                chapterNumber: widget.chapter,
                                atlasRoute: widget.atlasRoute,
                                store: store
                            )
                            .frame(minHeight: 420, maxHeight: 520)
                            .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMD, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: Spacing.radiusMD, style: .continuous)
                                    .strokeBorder(Color.kymaiaHairline, lineWidth: 1)
                            )
                        }

                        // 3-Step Watch Sequence
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("3-STEP GUIDED OBSERVATION SEQUENCE")
                                .font(Typography.eyebrow)
                                .foregroundStyle(Color.kymaiaPrimary)
                            ForEach(Array(widget.watchSteps.enumerated()), id: \.offset) { idx, step in
                                HStack(alignment: .top, spacing: Spacing.sm) {
                                    Text("\(idx + 1).")
                                        .font(Typography.subheadline.weight(.bold))
                                        .foregroundStyle(Color.kymaiaPrimary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(step.title)
                                            .font(Typography.subheadline.weight(.semibold))
                                            .foregroundStyle(Color.kymaiaInk)
                                        Text(step.caption)
                                            .font(Typography.caption)
                                            .foregroundStyle(Color.kymaiaMutedInk)
                                    }
                                }
                            }
                        }
                        .padding(Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .quietPanelBackground()

                        // Cutaway & Idealised Honesty Drawers
                        HStack(alignment: .top, spacing: Spacing.md) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("STRUCTURAL CUTAWAY")
                                    .font(Typography.eyebrow)
                                    .foregroundStyle(Color.kymaiaSecondary)
                                Text(widget.cutaway)
                                    .font(Typography.caption)
                                    .foregroundStyle(Color.kymaiaMutedInk)
                            }
                            .padding(Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .quietPanelBackground()

                            VStack(alignment: .leading, spacing: 4) {
                                Text("MATHEMATICAL IDEALISATION")
                                    .font(Typography.eyebrow)
                                    .foregroundStyle(Color.kymaiaWarning)
                                Text(widget.idealised)
                                    .font(Typography.caption)
                                    .foregroundStyle(Color.kymaiaMutedInk)
                            }
                            .padding(Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .quietPanelBackground()
                        }

                        // Challenge Prompt & Stamp
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("CHALLENGE STAMP TASK")
                                .font(Typography.eyebrow)
                                .foregroundStyle(Color.kymaiaSuccess)
                            Text(widget.challengePrompt)
                                .font(Typography.subheadline.weight(.semibold))
                                .foregroundStyle(Color.kymaiaInk)

                            HStack {
                                TextField("Record your readout or invariant verification...", text: $challengeNote)
                                    .textFieldStyle(.roundedBorder)
                                Button("Earn Lab Stamp") {
                                    let note = challengeNote.isEmpty ? "Verified invariant on \(widget.title)" : challengeNote
                                    store.stampWidgetChallenge(widget: widget, note: note)
                                    challengeNote = ""
                                }
                                .buttonStyle(BrassButtonStyle())
                            }
                        }
                    }
                }
            }

            // 3. 16 Active-Recall Mathematical Diagram Plates
            JournalSection(
                title: "Active-Recall Mathematical Diagram Plates (16 Plates)",
                eyebrow: "Test Visual-to-Formula Anatomy Without Passive Re-Reading"
            ) {
                JournalCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.xs) {
                                ForEach(store.seedPack.diagramPlates) { p in
                                    MathsFilterChip(
                                        title: p.title,
                                        systemImage: "viewfinder.rectangular",
                                        isSelected: store.selectedDiagramPlateId == p.id
                                    ) {
                                        store.selectedDiagramPlateId = p.id
                                        revealedCalloutIds.removeAll()
                                        plateSketchStrokes.removeAll()
                                    }
                                }
                            }
                        }

                        HStack {
                            JournalBadge(text: "OUP Ch \(plate.unitNumber) · Topic \(plate.topicCode)", symbol: "book.closed", tone: .accent)
                            JournalBadge(text: "Patterned World Ch \(plate.livingWorldChapter)", symbol: "sparkles", tone: .info)
                            Spacer()
                            if !plateSketchStrokes.isEmpty {
                                Button("Clear Sketch") {
                                    plateSketchStrokes.removeAll()
                                }
                                .buttonStyle(JournalSecondaryButtonStyle())
                            }
                            AdaptiveOptionPicker(
                                options: ["label_only", "ghost_scaffold", "blank_recall"],
                                selection: $diagramMode,
                                label: { mode in
                                    switch mode {
                                    case "label_only": return "1. Study Labels"
                                    case "ghost_scaffold": return "2. Ghost Hints"
                                    default: return "3. Blank Recall"
                                    }
                                }
                            )
                        }

                        Text(plate.title)
                            .font(Typography.title3)
                            .foregroundStyle(Color.kymaiaInk)
                        Text(plate.subtitle)
                            .font(Typography.caption)
                            .foregroundStyle(Color.kymaiaMutedInk)

                        // Interactive Mathematical Diagram Plate Canvas + Pin Overlay
                        MathematicalDiagramPlateCanvasView(
                            plate: plate,
                            diagramMode: diagramMode,
                            revealedCalloutIds: $revealedCalloutIds,
                            strokes: $plateSketchStrokes,
                            activeStroke: $activePlateStroke
                        )
                        .frame(height: 310)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 250), spacing: Spacing.sm)], spacing: Spacing.sm) {
                            ForEach(Array(plate.callouts.enumerated()), id: \.element.id) { idx, callout in
                                let isRevealed = diagramMode == "label_only" || revealedCalloutIds.contains(callout.id)
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    HStack {
                                        Text("Pin \(idx + 1) · (\(Int(callout.xFraction * 100))%, \(Int(callout.yFraction * 100))%)")
                                            .font(Typography.mono)
                                            .foregroundStyle(Color.kymaiaPrimary)
                                        Spacer()
                                        Button(isRevealed ? "Hide" : "Reveal") {
                                            if revealedCalloutIds.contains(callout.id) {
                                                revealedCalloutIds.remove(callout.id)
                                            } else {
                                                revealedCalloutIds.insert(callout.id)
                                            }
                                        }
                                        .font(Typography.caption.weight(.semibold))
                                    }

                                    if diagramMode != "blank_recall" {
                                        Text("Hint: \(callout.hint)")
                                            .font(Typography.caption)
                                            .foregroundStyle(Color.kymaiaMutedInk)
                                    }

                                    if isRevealed {
                                        Text(callout.label)
                                            .font(Typography.subheadline.weight(.bold))
                                            .foregroundStyle(Color.kymaiaSuccess)
                                    } else {
                                        let binding = Binding<String>(
                                            get: { diagramInputs[callout.id] ?? "" },
                                            set: { diagramInputs[callout.id] = $0 }
                                        )
                                        TextField("Type formula or geometric label...", text: binding)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                                .padding(Spacing.sm)
                                .quietPanelBackground()
                            }
                        }

                        HStack {
                            Button("Reveal All & Log Recall Score") {
                                revealedCalloutIds = Set(plate.callouts.map(\.id))
                                store.recordDiagramRecallAttempt(
                                    plate: plate,
                                    mode: diagramMode,
                                    correctCount: plate.callouts.count,
                                    selfScore: 5
                                )
                            }
                            .buttonStyle(JournalSecondaryButtonStyle())
                            Spacer()
                            Text("Logged attempts: \(store.diagramAttempts.filter { $0.plateId == plate.id }.count)")
                                .font(Typography.caption)
                                .foregroundStyle(Color.kymaiaMutedInk)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Bespoke 16-Plate Mathematical Diagram Renderer & Pin Callout Stage

struct MathematicalDiagramPlateCanvasView: View {
    let plate: DiagramRecallPlate
    let diagramMode: String
    @Binding var revealedCalloutIds: Set<String>
    @Binding var strokes: [[CGPoint]]
    @Binding var activeStroke: [CGPoint]

    // Colour-locked palette matching @saxster/atlas and Intuition-to-Formula bridges
    private let cRed = Color(red: 0.784, green: 0.243, blue: 0.216)
    private let cBlue = Color(red: 0.180, green: 0.400, blue: 0.722)
    private let cAmber = Color(red: 0.784, green: 0.541, blue: 0.118)
    private let cGreen = Color(red: 0.118, green: 0.478, blue: 0.314)
    private let cInk = Color(red: 0.16, green: 0.14, blue: 0.20)

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                RoundedRectangle(cornerRadius: Spacing.radiusMD, style: .continuous)
                    .fill(MathsFigureColor.paper)
                    .overlay(
                        RoundedRectangle(cornerRadius: Spacing.radiusMD, style: .continuous)
                            .strokeBorder(Color.kymaiaHairline, lineWidth: 1)
                    )

                Canvas { context, canvasSize in
                    drawDraftingGrid(in: &context, size: canvasSize)
                    drawFigureGeometry(figureId: plate.figureId, in: &context, size: canvasSize)
                    drawUserStrokes(in: &context)
                }
                .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMD, style: .continuous))
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

                // Interactive numbered callout pins aligned to exact normalized (x, y) coordinates
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
                        HStack(spacing: 4) {
                            Text("\(idx + 1)")
                                .font(MathsFigureType.labelMono)
                                .foregroundStyle(MathsFigureColor.pinNumber)
                                .frame(width: 20, height: 20)
                                .background(Circle().fill(isRevealed ? cGreen : cRed))

                            if isRevealed {
                                Text(callout.label)
                                    .font(MathsFigureType.labelMedium)
                                    .foregroundStyle(cInk)
                                    .lineLimit(1)
                            } else if diagramMode == "ghost_scaffold" {
                                Text(callout.hint)
                                    .font(MathsFigureType.hint)
                                    .foregroundStyle(cInk.opacity(0.65))
                                    .lineLimit(1)
                            } else {
                                Text("?")
                                    .font(MathsFigureType.labelMono)
                                    .foregroundStyle(cRed)
                            }
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(MathsFigureColor.pinCapsule)
                                .shadow(color: .black.opacity(0.10), radius: 3, x: 0, y: 1)
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(isRevealed ? cGreen.opacity(0.75) : cRed.opacity(0.65), lineWidth: 1.2)
                        )
                    }
                    .buttonStyle(.plain)
                    .position(x: min(max(pt.x, 75), size.width - 75), y: min(max(pt.y, 22), size.height - 22))
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
        context.stroke(grid, with: .color(cInk.opacity(0.06)), lineWidth: 0.75)
    }

    private func drawUserStrokes(in context: inout GraphicsContext) {
        for stroke in strokes where stroke.count >= 2 {
            var p = Path()
            p.move(to: stroke[0])
            for pt in stroke.dropFirst() { p.addLine(to: pt) }
            context.stroke(p, with: .color(cRed), lineWidth: 2.4)
        }
        if activeStroke.count >= 2 {
            var p = Path()
            p.move(to: activeStroke[0])
            for pt in activeStroke.dropFirst() { p.addLine(to: pt) }
            context.stroke(p, with: .color(cBlue), lineWidth: 2.4)
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
            // Box-and-whisker on upper right
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
            // Riemann bars on right half
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
