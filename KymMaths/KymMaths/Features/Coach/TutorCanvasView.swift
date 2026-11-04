import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - TutorCanvasView

/// Interactive chalkboard where the AI Mentor renders structured shapes, number lines,
/// Singapore bar models, and stickers, and where Kym can drag shapes or draw freehand ink.
public struct TutorCanvasView: View {
    public let canvas: TutorCanvas
    public var allowEditing: Bool
    public var onInteractiveStateChange: ((TutorCanvasEditState) -> Void)?

    public enum InteractionTool: String, CaseIterable, Identifiable {
        case move
        case ink

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .move: return "Move"
            case .ink: return "Sketch"
            }
        }

        public var icon: String {
            switch self {
            case .move: return "hand.point.up.left.fill"
            case .ink: return "pencil.tip"
            }
        }
    }

    @State private var history: TutorCanvasEditHistory
    @State private var selectedTool: InteractionTool = .move
    @State private var selectedShapeID: String?
    @State private var dragStartShape: TutorCanvasShape?
    @State private var activeStroke: [CGPoint] = []
    @State private var showGridOverride: Bool?

    public init(
        canvas: TutorCanvas,
        allowEditing: Bool = true,
        onInteractiveStateChange: ((TutorCanvasEditState) -> Void)? = nil
    ) {
        self.canvas = canvas
        self.allowEditing = allowEditing
        self.onInteractiveStateChange = onInteractiveStateChange
        self._history = State(
            initialValue: TutorCanvasEditHistory(
                initial: TutorCanvasEditState(shapes: canvas.shapes)
            )
        )
    }

    private var effectiveShowGrid: Bool {
        showGridOverride ?? canvas.showGrid
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            headerBar

            GeometryReader { geo in
                let size = geo.size
                ZStack {
                    RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                        .fill(Color.kymaiaPaper)
                        .overlay(
                            RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                                .strokeBorder(Color.kymaiaHairline, lineWidth: 1)
                        )

                    if effectiveShowGrid {
                        CanvasGridBackground()
                            .clipShape(RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous))
                    }

                    Canvas { context, canvasSize in
                        drawShapes(in: &context, size: canvasSize)
                        drawStrokes(in: &context, size: canvasSize)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous))
                    .gesture(allowEditing ? canvasGesture(in: size) : nil)
                }
            }
            .aspectRatio(TutorCanvasSpace.aspectRatio, contentMode: .fit)
            .frame(minHeight: 240, maxHeight: 420)

            if let caption = canvas.caption, !caption.isEmpty {
                Text(caption)
                    .font(.kymaiaCaption)
                    .foregroundStyle(Color.kymaiaMutedInk)
            }
        }
        .padding(Spacing.md)
        .background(Color.kymaiaSurface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                .strokeBorder(Color.kymaiaHairline, lineWidth: 1)
        )
        .onChange(of: canvas) { _, newValue in
            var updated = history.current
            updated.shapes = newValue.shapes
            history.record(updated)
            onInteractiveStateChange?(history.current)
        }
    }

    private var headerBar: some View {
        HStack(spacing: Spacing.sm) {
            Label(canvas.title, systemImage: "rectangle.and.pencil.and.ellipsis")
                .font(.kymaiaHeadline)
                .foregroundStyle(Color.kymaiaInk)

            Spacer()

            if allowEditing {
                HStack(spacing: 6) {
                    ForEach(InteractionTool.allCases) { tool in
                        Button {
                            selectedTool = tool
                        } label: {
                            Label(tool.title, systemImage: tool.icon)
                                .font(.kymaiaCaption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(selectedTool == tool ? Color.kymaiaInk : Color.clear)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(selectedTool == tool ? Color.clear : Color.kymaiaHairline, lineWidth: 1)
                                )
                                .foregroundStyle(selectedTool == tool ? Color.kymaiaBackground : Color.kymaiaInk)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        showGridOverride = !effectiveShowGrid
                    } label: {
                        Image(systemName: effectiveShowGrid ? "grid" : "square.dashed")
                            .font(.kymaiaCaption.weight(.semibold))
                            .padding(6)
                            .background(Circle().fill(Color.kymaiaPaper))
                    }
                    .buttonStyle(.plain)
                    .help("Toggle Math Grid")

                    Button {
                        history.undo()
                        onInteractiveStateChange?(history.current)
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.kymaiaCaption.weight(.semibold))
                            .padding(6)
                            .background(Circle().fill(Color.kymaiaPaper))
                    }
                    .buttonStyle(.plain)
                    .disabled(!history.canUndo)

                    Button {
                        history.redo()
                        onInteractiveStateChange?(history.current)
                    } label: {
                        Image(systemName: "arrow.uturn.forward")
                            .font(.kymaiaCaption.weight(.semibold))
                            .padding(6)
                            .background(Circle().fill(Color.kymaiaPaper))
                    }
                    .buttonStyle(.plain)
                    .disabled(!history.canRedo)

                    if !history.current.strokes.isEmpty {
                        Button {
                            var state = history.current
                            state.strokes.removeAll()
                            history.record(state)
                            onInteractiveStateChange?(history.current)
                        } label: {
                            Label("Clear Ink", systemImage: "eraser")
                                .font(.kymaiaCaption)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.kymaiaMutedInk)
                    }
                }
            }
        }
    }

    private func canvasGesture(in viewSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                switch selectedTool {
                case .move:
                    let startLogical = TutorCanvasSpace.toLogical(value.startLocation, in: viewSize)
                    if dragStartShape == nil {
                        if let hit = history.current.shapes.reversed().first(where: { $0.boundsRect.contains(startLogical) }) {
                            selectedShapeID = hit.id
                            dragStartShape = hit
                        }
                    }
                    if let startShape = dragStartShape,
                       let idx = history.current.shapes.firstIndex(where: { $0.id == startShape.id }) {
                        let delta = TutorCanvasSpace.toLogicalDelta(value.translation, in: viewSize)
                        var next = history.current
                        next.shapes[idx] = startShape.movedBy(dx: Double(delta.width), dy: Double(delta.height))
                        history.record(next)
                    }
                case .ink:
                    activeStroke.append(value.location)
                }
            }
            .onEnded { _ in
                switch selectedTool {
                case .move:
                    dragStartShape = nil
                    onInteractiveStateChange?(history.current)
                case .ink:
                    let converted = TutorCanvasInkConversion.strokePoints(in: activeStroke, viewSize: viewSize)
                    activeStroke.removeAll()
                    if !converted.isEmpty {
                        var next = history.current
                        next.strokes.append(converted)
                        history.record(next)
                        onInteractiveStateChange?(history.current)
                    }
                }
            }
    }

    private func drawShapes(in context: inout GraphicsContext, size: CGSize) {
        for shape in history.current.shapes {
            let color = shape.color.swiftUIColor
            let isSelected = shape.id == selectedShapeID

            switch shape.kind {
            case .rect:
                let topLeft = TutorCanvasSpace.toView(CGPoint(x: shape.x, y: shape.y), in: size)
                let w = CGFloat((shape.width ?? 160) / TutorCanvasSpace.width) * size.width
                let h = CGFloat((shape.height ?? 80) / TutorCanvasSpace.height) * size.height
                let rect = CGRect(x: topLeft.x, y: topLeft.y, width: w, height: h)
                let path = Path(roundedRect: rect, cornerRadius: MathsFigureRadius.frame)
                if shape.filled {
                    context.fill(path, with: .color(color.opacity(0.18)))
                }
                context.stroke(path, with: .color(color), lineWidth: isSelected ? 3 : 2)
                if let label = shape.text, !label.isEmpty {
                    context.draw(
                        Text(label).font(.kymaiaCaption.weight(.semibold)).foregroundStyle(Color.kymaiaInk),
                        at: CGPoint(x: rect.midX, y: rect.midY)
                    )
                }

            case .ellipse:
                let topLeft = TutorCanvasSpace.toView(CGPoint(x: shape.x, y: shape.y), in: size)
                let w = CGFloat((shape.width ?? 140) / TutorCanvasSpace.width) * size.width
                let h = CGFloat((shape.height ?? 90) / TutorCanvasSpace.height) * size.height
                let rect = CGRect(x: topLeft.x, y: topLeft.y, width: w, height: h)
                let path = Path(ellipseIn: rect)
                if shape.filled {
                    context.fill(path, with: .color(color.opacity(0.18)))
                }
                context.stroke(path, with: .color(color), lineWidth: isSelected ? 3 : 2)
                if let label = shape.text, !label.isEmpty {
                    context.draw(
                        Text(label).font(.kymaiaCaption.weight(.semibold)).foregroundStyle(Color.kymaiaInk),
                        at: CGPoint(x: rect.midX, y: rect.midY)
                    )
                }

            case .line, .arrow:
                let start = TutorCanvasSpace.toView(CGPoint(x: shape.x, y: shape.y), in: size)
                let end = TutorCanvasSpace.toView(
                    CGPoint(x: shape.x2 ?? (shape.x + 160), y: shape.y2 ?? shape.y),
                    in: size
                )
                var linePath = Path()
                linePath.move(to: start)
                linePath.addLine(to: end)
                context.stroke(linePath, with: .color(color), lineWidth: isSelected ? 3 : 2.2)

                if shape.kind == .arrow {
                    let angle = atan2(end.y - start.y, end.x - start.x)
                    let arrowLength: CGFloat = 11
                    let wing1 = CGPoint(
                        x: end.x - arrowLength * cos(angle - .pi / 6),
                        y: end.y - arrowLength * sin(angle - .pi / 6)
                    )
                    let wing2 = CGPoint(
                        x: end.x - arrowLength * cos(angle + .pi / 6),
                        y: end.y - arrowLength * sin(angle + .pi / 6)
                    )
                    var head = Path()
                    head.move(to: wing1)
                    head.addLine(to: end)
                    head.addLine(to: wing2)
                    context.stroke(head, with: .color(color), lineWidth: 2.2)
                }
                if let label = shape.text, !label.isEmpty {
                    let mid = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2 - 12)
                    context.draw(
                        Text(label).font(.kymaiaCaption.weight(.semibold)).foregroundStyle(color),
                        at: mid
                    )
                }

            case .text, .sticker:
                let pt = TutorCanvasSpace.toView(CGPoint(x: shape.x, y: shape.y), in: size)
                let content = shape.text ?? (shape.kind == .sticker ? "★" : "Note")
                context.draw(
                    Text(content)
                        .font(shape.kind == .sticker ? .title2 : .kymaiaBody.weight(.semibold))
                        .foregroundStyle(color),
                    at: pt,
                    anchor: .topLeading
                )

            case .numberLine:
                drawNumberLine(shape: shape, in: &context, size: size, color: color)

            case .fractionBar:
                drawFractionBar(shape: shape, in: &context, size: size, color: color)
            }
        }
    }

    private func drawNumberLine(
        shape: TutorCanvasShape,
        in context: inout GraphicsContext,
        size: CGSize,
        color: Color
    ) {
        let payload = shape.numberLine ?? TutorCanvasShape.NumberLinePayload(min: 0, max: 10, marks: [5])
        let start = TutorCanvasSpace.toView(CGPoint(x: shape.x, y: shape.y), in: size)
        let w = CGFloat((shape.width ?? 680) / TutorCanvasSpace.width) * size.width
        let end = CGPoint(x: start.x + w, y: start.y)

        var axis = Path()
        axis.move(to: start)
        axis.addLine(to: end)
        context.stroke(axis, with: .color(color), lineWidth: 2.5)

        let span = Swift.max(payload.max - payload.min, 0.0001)
        let tickValues = Array(Set([payload.min, payload.max] + payload.marks)).sorted()
        for value in tickValues {
            let t = CGFloat((value - payload.min) / span)
            let xPos = start.x + t * w
            var tick = Path()
            tick.move(to: CGPoint(x: xPos, y: start.y - 8))
            tick.addLine(to: CGPoint(x: xPos, y: start.y + 8))
            context.stroke(tick, with: .color(color), lineWidth: 2)

            if payload.marks.contains(value) {
                let dotRect = CGRect(x: xPos - 5, y: start.y - 5, width: 10, height: 10)
                context.fill(Path(ellipseIn: dotRect), with: .color(Color.kymaiaPrimary))
            }

            let formatted = value.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(value))
                : String(format: "%.2f", value)
            context.draw(
                Text(formatted).font(.kymaiaCaption.monospacedDigit()).foregroundStyle(Color.kymaiaInk),
                at: CGPoint(x: xPos, y: start.y + 20)
            )
        }

        if let label = payload.label ?? shape.text, !label.isEmpty {
            context.draw(
                Text(label).font(.kymaiaCaption.weight(.semibold)).foregroundStyle(color),
                at: CGPoint(x: start.x, y: start.y - 22),
                anchor: .leading
            )
        }
    }

    private func drawFractionBar(
        shape: TutorCanvasShape,
        in context: inout GraphicsContext,
        size: CGSize,
        color: Color
    ) {
        let payload = shape.fractionBar ?? TutorCanvasShape.FractionBarPayload(totalParts: 4, filledParts: 3)
        let topLeft = TutorCanvasSpace.toView(CGPoint(x: shape.x, y: shape.y), in: size)
        let w = CGFloat((shape.width ?? 520) / TutorCanvasSpace.width) * size.width
        let h = CGFloat((shape.height ?? 54) / TutorCanvasSpace.height) * size.height
        let total = Swift.max(payload.totalParts, 1)
        let cellW = w / CGFloat(total)

        for index in 0..<total {
            let cellRect = CGRect(
                x: topLeft.x + CGFloat(index) * cellW,
                y: topLeft.y,
                width: cellW,
                height: h
            )
            let cellPath = Path(cellRect)
            if index < payload.filledParts {
                context.fill(cellPath, with: .color(color.opacity(0.28)))
            }
            context.stroke(cellPath, with: .color(color), lineWidth: 2)
        }

        if let label = payload.label ?? shape.text, !label.isEmpty {
            context.draw(
                Text(label).font(.kymaiaCaption.weight(.semibold)).foregroundStyle(Color.kymaiaInk),
                at: CGPoint(x: topLeft.x, y: topLeft.y - 14),
                anchor: .leading
            )
        }
    }

    private func drawStrokes(in context: inout GraphicsContext, size: CGSize) {
        for stroke in history.current.strokes {
            guard stroke.count >= 2 else { continue }
            var path = Path()
            path.move(to: TutorCanvasSpace.toView(stroke[0], in: size))
            for pt in stroke.dropFirst() {
                path.addLine(to: TutorCanvasSpace.toView(pt, in: size))
            }
            context.stroke(path, with: .color(Color.kymaiaPrimary), lineWidth: 2.5)
        }

        if activeStroke.count >= 2 {
            var livePath = Path()
            livePath.move(to: activeStroke[0])
            for pt in activeStroke.dropFirst() {
                livePath.addLine(to: pt)
            }
            context.stroke(livePath, with: .color(Color.kymaiaLive), lineWidth: 2.5)
        }
    }
}

private struct CanvasGridBackground: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 28
            var path = Path()
            var x: CGFloat = step
            while x < size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += step
            }
            var y: CGFloat = step
            while y < size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += step
            }
            context.stroke(path, with: .color(Color.kymaiaPaperRule.opacity(0.55)), lineWidth: 0.75)
        }
    }
}

// MARK: - LiveMentorChalkboard Templates & Model

public enum LiveMentorChalkboardTemplate: String, CaseIterable, Identifiable, Sendable {
    case blank
    case singaporeBarModel
    case numberLine
    case coordinatePlane
    case unitCircleTrig
    case bayesEikosogram
    case matrixDeterminant

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .blank: return "Blank Math Grid"
        case .singaporeBarModel: return "Singapore Bar Model"
        case .numberLine: return "Number Line"
        case .coordinatePlane: return "Coordinate Axes"
        case .unitCircleTrig: return "Unit Circle Trig"
        case .bayesEikosogram: return "Bayes 1,000-Grid"
        case .matrixDeterminant: return "2×2 Matrix Area"
        }
    }

    public var icon: String {
        switch self {
        case .blank: return "square.grid.3x3"
        case .singaporeBarModel: return "rectangle.split.3x1"
        case .numberLine: return "ruler"
        case .coordinatePlane: return "plus.viewfinder"
        case .unitCircleTrig: return "circle.grid.cross"
        case .bayesEikosogram: return "square.split.2x2"
        case .matrixDeterminant: return "square.grid.2x2"
        }
    }

    public func makeCanvas() -> TutorCanvas {
        switch self {
        case .blank:
            return TutorCanvas(
                title: "Shared Chalkboard",
                caption: "Drag shapes or sketch directly; both you and the Mentor can update this board.",
                showGrid: true,
                shapes: []
            )
        case .singaporeBarModel:
            return TutorCanvas(
                title: "Singapore Unitary Bar Model",
                caption: "Equal units stay equal across the ratio change.",
                showGrid: true,
                shapes: [
                    TutorCanvasShape(
                        id: "bar_a",
                        kind: .fractionBar,
                        x: 100,
                        y: 160,
                        width: 600,
                        height: 64,
                        color: .accent,
                        fractionBar: .init(totalParts: 5, filledParts: 3, label: "Quantity A (3 of 5 equal units)")
                    ),
                    TutorCanvasShape(
                        id: "bar_b",
                        kind: .fractionBar,
                        x: 100,
                        y: 280,
                        width: 600,
                        height: 64,
                        color: .secondary,
                        fractionBar: .init(totalParts: 5, filledParts: 5, label: "Total Whole (5 units)")
                    )
                ]
            )
        case .numberLine:
            return TutorCanvas(
                title: "Directed Number & Inequality Line",
                caption: "Inspect signed steps, bounds, or midpoint symmetry.",
                showGrid: true,
                shapes: [
                    TutorCanvasShape(
                        id: "nl_main",
                        kind: .numberLine,
                        x: 100,
                        y: 300,
                        width: 780,
                        height: 70,
                        color: .accent,
                        numberLine: .init(min: -5, max: 5, marks: [-3, 0, 2, 4], label: "Real Number Line")
                    )
                ]
            )
        case .coordinatePlane:
            return TutorCanvas(
                title: "Coordinate Plane, Slope & Vectors",
                caption: "Plot gradients m = Δy/Δx, y-intercept (0, c), or column vectors.",
                showGrid: true,
                shapes: [
                    TutorCanvasShape(id: "x_axis", kind: .arrow, x: 100, y: 360, x2: 880, y2: 360, text: "x-axis", color: .ink),
                    TutorCanvasShape(id: "y_axis", kind: .arrow, x: 420, y: 560, x2: 420, y2: 70, text: "y-axis", color: .ink),
                    TutorCanvasShape(id: "run_dx", kind: .line, x: 420, y: 300, x2: 660, y2: 300, text: "Run Δx = 3", color: .secondary),
                    TutorCanvasShape(id: "rise_dy", kind: .line, x: 660, y: 300, x2: 660, y2: 140, text: "Rise Δy = 2", color: .warning),
                    TutorCanvasShape(id: "vec_v", kind: .arrow, x: 420, y: 300, x2: 660, y2: 140, text: "y = (2/3)x + c", color: .accent)
                ]
            )
        case .unitCircleTrig:
            return TutorCanvas(
                title: "Unit Circle Shadows (cos²θ + sin²θ = 1)",
                caption: "Radius r = 1 casts horizontal shadow cos θ and vertical shadow sin θ.",
                showGrid: true,
                shapes: [
                    TutorCanvasShape(id: "uc_ring", kind: .ellipse, x: 240, y: 100, width: 400, height: 400, text: "", color: .ink, filled: false),
                    TutorCanvasShape(id: "cos_leg", kind: .line, x: 440, y: 300, x2: 600, y2: 300, text: "cos θ", color: .secondary),
                    TutorCanvasShape(id: "sin_leg", kind: .line, x: 600, y: 300, x2: 600, y2: 180, text: "sin θ", color: .accent),
                    TutorCanvasShape(id: "radius_hyp", kind: .arrow, x: 440, y: 300, x2: 600, y2: 180, text: "r = 1", color: .success)
                ]
            )
        case .bayesEikosogram:
            return TutorCanvas(
                title: "Bayes 1,000-Person Natural Frequency Square",
                caption: "At 2% prevalence, 95% sensitivity, 5% false-alarm rate: P(D|+) = 19 / (19 + 49) ≈ 27.9%.",
                showGrid: true,
                shapes: [
                    TutorCanvasShape(id: "prior_box", kind: .rect, x: 110, y: 100, width: 140, height: 420, text: "Sick D (20)", color: .secondary, filled: false),
                    TutorCanvasShape(id: "true_pos", kind: .rect, x: 110, y: 120, width: 140, height: 400, text: "TP = 19", color: .accent, filled: true),
                    TutorCanvasShape(id: "comp_box", kind: .rect, x: 250, y: 100, width: 520, height: 420, text: "Healthy ¬D (980)", color: .secondary, filled: false),
                    TutorCanvasShape(id: "false_pos", kind: .rect, x: 250, y: 410, width: 520, height: 110, text: "False Positives FP = 49", color: .warning, filled: true),
                    TutorCanvasShape(id: "post_note", kind: .text, x: 790, y: 260, text: "P(D|+) = 19/68 ≈ 27.9%", color: .success)
                ]
            )
        case .matrixDeterminant:
            return TutorCanvas(
                title: "2×2 Matrix Transformation & Determinant Area",
                caption: "Columns Aî = (a, c) and Aĵ = (b, d) span a parallelogram of area det(A) = ad − bc.",
                showGrid: true,
                shapes: [
                    TutorCanvasShape(id: "unit_sq", kind: .rect, x: 140, y: 340, width: 140, height: 140, text: "Unit 1×1 Square", color: .secondary, filled: true),
                    TutorCanvasShape(id: "col_1", kind: .arrow, x: 420, y: 460, x2: 740, y2: 380, text: "Aî = (a, c)", color: .accent),
                    TutorCanvasShape(id: "col_2", kind: .arrow, x: 420, y: 460, x2: 520, y2: 180, text: "Aĵ = (b, d)", color: .secondary),
                    TutorCanvasShape(id: "top_edge", kind: .line, x: 520, y: 180, x2: 840, y2: 100, text: "Area = det(A) = ad − bc", color: .success),
                    TutorCanvasShape(id: "right_edge", kind: .line, x: 740, y: 380, x2: 840, y2: 100, text: "", color: .success)
                ]
            )
        }
    }
}

@MainActor
@Observable
public final class LiveMentorChalkboardModel {
    public var canvas: TutorCanvas
    public var latestEditState: TutorCanvasEditState
    public var revisionCount: Int = 0

    public init(template: LiveMentorChalkboardTemplate = .singaporeBarModel) {
        let initialCanvas = template.makeCanvas()
        self.canvas = initialCanvas
        self.latestEditState = TutorCanvasEditState(shapes: initialCanvas.shapes)
    }

    public func applyTemplate(_ template: LiveMentorChalkboardTemplate) {
        let next = template.makeCanvas()
        self.canvas = next
        self.latestEditState = TutorCanvasEditState(shapes: next.shapes)
        self.revisionCount += 1
    }

    public func applyMentorAction(
        _ action: TutorCanvasAction,
        incoming: TutorCanvas,
        removeIDs: [String] = []
    ) {
        let updated = TutorCanvasActionApplier.apply(
            action: action,
            incoming: incoming,
            removeIDs: removeIDs,
            to: canvas
        )
        self.canvas = updated
        self.latestEditState.shapes = updated.shapes
        self.revisionCount += 1
    }

    public func updateInteractiveState(_ state: TutorCanvasEditState) {
        self.latestEditState = state
        self.canvas.shapes = state.shapes
        self.revisionCount += 1
    }
}

// MARK: - Snapshot & Summary Renderer

public enum TutorCanvasSnapshotRenderer {
    /// Produces a deterministic textual summary of all shapes and strokes on the chalkboard
    /// so the AI Mentor knows the exact current state before applying an incremental update.
    public static func stateSummary(
        canvas: TutorCanvas,
        editState: TutorCanvasEditState? = nil
    ) -> String {
        let shapes = editState?.shapes ?? canvas.shapes
        let strokeCount = editState?.strokes.count ?? 0
        var lines: [String] = [
            "Chalkboard '\(canvas.title)' (\(shapes.count) shapes, \(strokeCount) freehand strokes):"
        ]
        for shape in shapes.prefix(16) {
            var desc = "- [\(shape.id)] \(shape.kind.rawValue) at (\(Int(shape.x)), \(Int(shape.y)))"
            if let text = shape.text, !text.isEmpty {
                desc += " label=\"\(text)\""
            }
            if let fb = shape.fractionBar {
                desc += " fraction=\(fb.filledParts)/\(fb.totalParts)"
            }
            if let nl = shape.numberLine {
                desc += " range=[\(nl.min)...\(nl.max)] marks=\(nl.marks)"
            }
            lines.append(desc)
        }
        return lines.joined(separator: "\n")
    }

    @MainActor
    public static func jpegData(
        canvas: TutorCanvas,
        size: CGSize = CGSize(width: 800, height: 512)
    ) -> Data? {
        let view = TutorCanvasView(canvas: canvas, allowEditing: false)
            .frame(width: size.width, height: size.height)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0
        #if canImport(UIKit)
        return renderer.uiImage?.jpegData(compressionQuality: 0.82)
        #elseif canImport(AppKit)
        guard let nsImage = renderer.nsImage,
              let tiff = nsImage.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else {
            return nil
        }
        return rep.representation(using: .jpeg, properties: [.compressionFactor: 0.82])
        #else
        return nil
        #endif
    }
}

// MARK: - LiveMentorChalkboardPane

public struct LiveMentorChalkboardPane: View {
    @Bindable public var model: LiveMentorChalkboardModel
    public var onSendBoardToMentor: ((String, Data?) -> Void)?

    public init(
        model: LiveMentorChalkboardModel,
        onSendBoardToMentor: ((String, Data?) -> Void)? = nil
    ) {
        self.model = model
        self.onSendBoardToMentor = onSendBoardToMentor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    ForEach(LiveMentorChalkboardTemplate.allCases) { template in
                        PillButton(template.title, action: {
                            model.applyTemplate(template)
                        }, icon: {
                            Image(systemName: template.icon)
                        })
                    }

                    if let onSendBoardToMentor {
                        Button {
                            let summary = TutorCanvasSnapshotRenderer.stateSummary(
                                canvas: model.canvas,
                                editState: model.latestEditState
                            )
                            let jpeg = TutorCanvasSnapshotRenderer.jpegData(canvas: model.canvas)
                            onSendBoardToMentor(summary, jpeg)
                        } label: {
                            Label("Share Board with Mentor", systemImage: "paperplane.fill")
                                .font(.kymaiaCaption.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Capsule().fill(Color.kymaiaPrimary))
                                .foregroundStyle(Color.kymaiaBackground)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            TutorCanvasView(canvas: model.canvas, allowEditing: true) { newState in
                model.updateInteractiveState(newState)
            }
        }
    }
}
