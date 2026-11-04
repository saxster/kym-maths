import PencilKit
import SwiftUI

// MARK: - Mathematical Scratchpad with Singapore Bar-Model, Unit Circle, Venn & Matrix Blueprint Stamps

enum MathsScratchpadStamp: String, CaseIterable, Identifiable, Sendable {
    case singaporeBar = "singapore_bar"
    case cartesianAxes = "cartesian_axes"
    case unitCircle = "unit_circle"
    case venn2Set = "venn_2set"
    case primeTree = "prime_tree"
    case truthTable = "truth_table"
    case matrixGrid = "matrix_grid"
    case numberLine = "number_line"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .singaporeBar: return "Singapore Bar"
        case .cartesianAxes: return "x-y Axes"
        case .unitCircle: return "Unit Circle"
        case .venn2Set: return "2-Set Venn"
        case .primeTree: return "Factor Tree"
        case .truthTable: return "Truth Table"
        case .matrixGrid: return "2×2 Matrix"
        case .numberLine: return "Number Line"
        }
    }

    var symbol: String {
        switch self {
        case .singaporeBar: return "rectangle.split.3x1"
        case .cartesianAxes: return "chart.xyaxis.line"
        case .unitCircle: return "circle.grid.cross"
        case .venn2Set: return "circle.grid.2x1"
        case .primeTree: return "point.3.connected.trianglepath.dotted"
        case .truthTable: return "tablecells"
        case .matrixGrid: return "square.grid.2x2"
        case .numberLine: return "ruler"
        }
    }
}

struct MathsScratchpadView: View {
    let questionId: String
    @Bindable var store: AppStore

    @State private var paperStyle: String = "grid"
    @State private var selectedStamp: MathsScratchpadStamp? = .singaporeBar
    @State private var textScratchNotes: String = ""
    @State private var savedStrokeCount: Int = 0
    @State private var isSketchMode: Bool = false
    @State private var inkStrokes: [[CGPoint]] = []
    @State private var activeInkStroke: [CGPoint] = []

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Label("Mathematical Working & Geometric Blueprint Scratchpad", systemImage: "pencil.and.ruler")
                    .font(Typography.subheadline.weight(.semibold))
                    .foregroundStyle(Color.kymaiaInk)
                Spacer()
                Button {
                    isSketchMode.toggle()
                } label: {
                    Label(isSketchMode ? "Mode: Sketch Ink" : "Mode: Type Notes", systemImage: isSketchMode ? "pencil.tip.crop.circle.fill" : "keyboard")
                        .font(Typography.caption.weight(.semibold))
                }
                .buttonStyle(JournalSecondaryButtonStyle())

                if !inkStrokes.isEmpty {
                    Button("Clear Ink") {
                        inkStrokes.removeAll()
                    }
                    .font(Typography.caption)
                }

                Menu {
                    ForEach(["grid", "dots", "lined", "blank", "cornell"], id: \.self) { style in
                        Button(style.capitalized) {
                            paperStyle = style
                        }
                    }
                } label: {
                    Label("Paper: \(paperStyle.capitalized)", systemImage: "doc.plaintext")
                        .font(Typography.caption.weight(.semibold))
                }
            }

            // Stamp selector bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    ForEach(MathsScratchpadStamp.allCases) { stamp in
                        JournalChip(
                            title: stamp.title,
                            systemImage: stamp.symbol,
                            isSelected: selectedStamp == stamp
                        ) {
                            selectedStamp = (selectedStamp == stamp) ? nil : stamp
                        }
                    }
                }
            }

            // Canvas with paper background, geometric blueprint stamp, and working layer
            ZStack(alignment: .topLeading) {
                JournalPaperBackground(style: JournalPaperStyle(rawValue: paperStyle) ?? .grid)
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMD, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Spacing.radiusMD, style: .continuous)
                            .strokeBorder(Color.kymaiaHairline, lineWidth: 1)
                    )

                if let stamp = selectedStamp {
                    MathsStampBlueprintCanvas(
                        stamp: stamp,
                        inkStrokes: inkStrokes,
                        activeInkStroke: activeInkStroke
                    )
                    .frame(height: 240)
                    .allowsHitTesting(false)

                    stampOverlayView(for: stamp)
                        .padding(Spacing.xs)
                        .allowsHitTesting(false)
                }

                if isSketchMode {
                    Color.clear
                        .frame(height: 240)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 2)
                                .onChanged { value in
                                    activeInkStroke.append(value.location)
                                }
                                .onEnded { _ in
                                    if activeInkStroke.count >= 2 {
                                        inkStrokes.append(activeInkStroke)
                                    }
                                    activeInkStroke.removeAll()
                                }
                        )
                } else {
                    TextEditor(text: $textScratchNotes)
                        .scrollContentBackground(.hidden)
                        .font(Typography.mono)
                        .foregroundStyle(Color.kymaiaInk)
                        .padding(.top, 28)
                        .padding(.horizontal, Spacing.sm)
                        .frame(height: 240)
                }
            }

            HStack {
                Text("Select a geometric blueprint stamp above and type algebraic steps or sketch directly onto the diagram.")
                    .font(Typography.caption)
                    .foregroundStyle(Color.kymaiaMutedInk)
                Spacer()
                Button("Save Working") {
                    let data = Data(textScratchNotes.utf8)
                    let totalCount = max(1, textScratchNotes.count + inkStrokes.count)
                    store.saveScratchpad(
                        questionId: questionId,
                        paperStyle: paperStyle,
                        stampKind: selectedStamp?.rawValue,
                        drawingData: data,
                        previewPNGData: Data(),
                        strokeCount: totalCount
                    )
                    savedStrokeCount = totalCount
                }
                .buttonStyle(JournalSecondaryButtonStyle())
            }
        }
        .onAppear {
            paperStyle = store.defaultScratchpadPaperStyle
            if let existing = store.loadScratchpad(questionId: questionId),
               let savedText = String(data: existing.drawingData, encoding: .utf8) {
                textScratchNotes = savedText
                paperStyle = existing.paperStyle
                if let kind = existing.stampKind {
                    selectedStamp = MathsScratchpadStamp(rawValue: kind)
                }
            }
        }
    }

    @ViewBuilder
    private func stampOverlayView(for stamp: MathsScratchpadStamp) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: stamp.symbol)
                .foregroundStyle(Color.kymaiaPrimary.opacity(0.85))
            Text(stampHintText(for: stamp))
                .font(Typography.caption)
                .foregroundStyle(Color.kymaiaMutedInk.opacity(0.9))
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.kymaiaElevatedSurface.opacity(0.90))
        )
    }

    private func stampHintText(for stamp: MathsScratchpadStamp) -> String {
        switch stamp {
        case .singaporeBar:
            return "Singapore CPA Bar Guide: [ Unit 1 ][ Unit 2 ][ Unit 3 ] = Total · Find 1 unit first"
        case .cartesianAxes:
            return "Coordinate Axes Guide: Origin (0,0) · Gradient m = Δy / Δx · y = mx + c"
        case .unitCircle:
            return "Unit Circle Guide: P = (cos θ, sin θ) · cos²θ + sin²θ = 1 · π rad = 180°"
        case .venn2Set:
            return "2-Set Venn Guide: |A ∪ B| = |A| + |B| − |A ∩ B| · HCF in lens, LCM in union"
        case .primeTree:
            return "Prime Factor Tree Guide: Split composite into primes 2, 3, 5, 7, 11..."
        case .truthTable:
            return "Truth Table Guide: P | Q | P ∧ Q | P ∨ Q | ¬(P ∧ Q) ⇔ ¬P ∨ ¬Q"
        case .matrixGrid:
            return "2×2 Matrix Guide: [[a, b], [c, d]] · det(A) = ad − bc · tr(A) = a + d"
        case .numberLine:
            return "Inequality Number Line Guide: ○ open (<, >) · ● closed (≤, ≥)"
        }
    }
}

// MARK: - Authentic Geometric Blueprint Canvas for All 8 Mathematical Stamps

struct MathsStampBlueprintCanvas: View {
    let stamp: MathsScratchpadStamp
    let inkStrokes: [[CGPoint]]
    let activeInkStroke: [CGPoint]

    private let cRed = Color(red: 0.784, green: 0.243, blue: 0.216)
    private let cBlue = Color(red: 0.180, green: 0.400, blue: 0.722)
    private let cAmber = Color(red: 0.784, green: 0.541, blue: 0.118)
    private let cGreen = Color(red: 0.118, green: 0.478, blue: 0.314)

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            switch stamp {
            case .singaporeBar:
                let x0 = w * 0.46
                let uW = w * 0.085
                for i in 0..<5 {
                    let r = CGRect(x: x0 + CGFloat(i) * uW, y: h * 0.28, width: uW - 2, height: 34)
                    let col = i < 3 ? cRed : cAmber
                    context.fill(Path(roundedRect: r, cornerRadius: 4), with: .color(col.opacity(0.14)))
                    context.stroke(Path(roundedRect: r, cornerRadius: 4), with: .color(col.opacity(0.55)), lineWidth: 1.5)
                    context.draw(Text("1u").font(.system(size: 10, weight: .semibold, design: .monospaced)).foregroundStyle(col.opacity(0.75)), at: CGPoint(x: r.midX, y: r.midY))
                }
                for i in 0..<3 {
                    let r = CGRect(x: x0 + CGFloat(i) * uW, y: h * 0.56, width: uW - 2, height: 34)
                    context.fill(Path(roundedRect: r, cornerRadius: 4), with: .color(cBlue.opacity(0.14)))
                    context.stroke(Path(roundedRect: r, cornerRadius: 4), with: .color(cBlue.opacity(0.55)), lineWidth: 1.5)
                    context.draw(Text("1u").font(.system(size: 10, weight: .semibold, design: .monospaced)).foregroundStyle(cBlue.opacity(0.75)), at: CGPoint(x: r.midX, y: r.midY))
                }

            case .cartesianAxes:
                let ox = w * 0.68, oy = h * 0.56
                var axes = Path()
                axes.move(to: CGPoint(x: w * 0.44, y: oy)); axes.addLine(to: CGPoint(x: w * 0.94, y: oy))
                axes.move(to: CGPoint(x: ox, y: h * 0.16)); axes.addLine(to: CGPoint(x: ox, y: h * 0.90))
                context.stroke(axes, with: .color(cBlue.opacity(0.50)), lineWidth: 1.8)
                var line = Path()
                line.move(to: CGPoint(x: w * 0.50, y: h * 0.80)); line.addLine(to: CGPoint(x: w * 0.88, y: h * 0.24))
                context.stroke(line, with: .color(cRed.opacity(0.45)), style: StrokeStyle(lineWidth: 1.8, dash: [5, 3]))

            case .unitCircle:
                let cx = w * 0.70, cy = h * 0.56, r = min(w, h) * 0.30
                let cRect = CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r)
                context.stroke(Path(ellipseIn: cRect), with: .color(cBlue.opacity(0.45)), lineWidth: 1.8)
                let px = cx + r * cos(.pi / 5), py = cy - r * sin(.pi / 5)
                var tri = Path()
                tri.move(to: CGPoint(x: cx, y: cy)); tri.addLine(to: CGPoint(x: px, y: cy)); tri.addLine(to: CGPoint(x: px, y: py)); tri.closeSubpath()
                context.fill(tri, with: .color(cRed.opacity(0.12)))
                context.stroke(tri, with: .color(cRed.opacity(0.55)), lineWidth: 1.8)

            case .venn2Set:
                let r = min(w, h) * 0.25
                let cA = CGRect(x: w * 0.62 - r, y: h * 0.55 - r, width: 2 * r, height: 2 * r)
                let cB = CGRect(x: w * 0.76 - r, y: h * 0.55 - r, width: 2 * r, height: 2 * r)
                context.fill(Path(ellipseIn: cA), with: .color(cRed.opacity(0.10)))
                context.fill(Path(ellipseIn: cB), with: .color(cBlue.opacity(0.10)))
                context.stroke(Path(ellipseIn: cA), with: .color(cRed.opacity(0.55)), lineWidth: 1.8)
                context.stroke(Path(ellipseIn: cB), with: .color(cBlue.opacity(0.55)), lineWidth: 1.8)

            case .primeTree:
                let top = CGPoint(x: w * 0.70, y: h * 0.24)
                let l1 = CGPoint(x: w * 0.58, y: h * 0.50)
                let r1 = CGPoint(x: w * 0.82, y: h * 0.50)
                let r2L = CGPoint(x: w * 0.74, y: h * 0.76)
                let r2R = CGPoint(x: w * 0.88, y: h * 0.76)
                var branches = Path()
                branches.move(to: top); branches.addLine(to: l1)
                branches.move(to: top); branches.addLine(to: r1)
                branches.move(to: r1); branches.addLine(to: r2L)
                branches.move(to: r1); branches.addLine(to: r2R)
                context.stroke(branches, with: .color(cAmber.opacity(0.60)), lineWidth: 1.8)
                for (pt, col) in [(top, cBlue), (l1, cGreen), (r1, cBlue), (r2L, cGreen), (r2R, cGreen)] {
                    let nr = CGRect(x: pt.x - 16, y: pt.y - 12, width: 32, height: 24)
                    context.fill(Path(ellipseIn: nr), with: .color(col.opacity(0.14)))
                    context.stroke(Path(ellipseIn: nr), with: .color(col.opacity(0.60)), lineWidth: 1.5)
                }

            case .truthTable:
                let x0 = w * 0.48, y0 = h * 0.24, tw = w * 0.46, th = h * 0.64
                let rect = CGRect(x: x0, y: y0, width: tw, height: th)
                context.stroke(Path(rect), with: .color(cBlue.opacity(0.50)), lineWidth: 1.6)
                for rIdx in 1...4 {
                    let ry = y0 + CGFloat(rIdx) * (th / 5.0)
                    var row = Path(); row.move(to: CGPoint(x: x0, y: ry)); row.addLine(to: CGPoint(x: x0 + tw, y: ry))
                    context.stroke(row, with: .color(cBlue.opacity(0.35)), lineWidth: 1.0)
                }
                for cIdx in 1...3 {
                    let cx = x0 + CGFloat(cIdx) * (tw / 4.0)
                    var col = Path(); col.move(to: CGPoint(x: cx, y: y0)); col.addLine(to: CGPoint(x: cx, y: y0 + th))
                    context.stroke(col, with: .color(cBlue.opacity(0.35)), lineWidth: 1.0)
                }

            case .matrixGrid:
                let x0 = w * 0.56, y0 = h * 0.28, mw = w * 0.30, mh = h * 0.52
                var brackets = Path()
                brackets.move(to: CGPoint(x: x0 + 10, y: y0)); brackets.addLine(to: CGPoint(x: x0, y: y0))
                brackets.addLine(to: CGPoint(x: x0, y: y0 + mh)); brackets.addLine(to: CGPoint(x: x0 + 10, y: y0 + mh))
                brackets.move(to: CGPoint(x: x0 + mw - 10, y: y0)); brackets.addLine(to: CGPoint(x: x0 + mw, y: y0))
                brackets.addLine(to: CGPoint(x: x0 + mw, y: y0 + mh)); brackets.addLine(to: CGPoint(x: x0 + mw - 10, y: y0 + mh))
                context.stroke(brackets, with: .color(cRed.opacity(0.60)), lineWidth: 2.2)
                var diag1 = Path(); diag1.move(to: CGPoint(x: x0 + 24, y: y0 + 24)); diag1.addLine(to: CGPoint(x: x0 + mw - 24, y: y0 + mh - 24))
                var diag2 = Path(); diag2.move(to: CGPoint(x: x0 + mw - 24, y: y0 + 24)); diag2.addLine(to: CGPoint(x: x0 + 24, y: y0 + mh - 24))
                context.stroke(diag1, with: .color(cGreen.opacity(0.45)), style: StrokeStyle(lineWidth: 1.6, dash: [4, 3]))
                context.stroke(diag2, with: .color(cAmber.opacity(0.45)), style: StrokeStyle(lineWidth: 1.6, dash: [4, 3]))

            case .numberLine:
                let y = h * 0.56, x0 = w * 0.42, x1 = w * 0.94
                var axis = Path(); axis.move(to: CGPoint(x: x0, y: y)); axis.addLine(to: CGPoint(x: x1, y: y))
                context.stroke(axis, with: .color(cBlue.opacity(0.55)), lineWidth: 2.0)
                for i in -5...5 {
                    let tx = x0 + CGFloat(i + 5) / 10.0 * (x1 - x0)
                    var tick = Path(); tick.move(to: CGPoint(x: tx, y: y - 6)); tick.addLine(to: CGPoint(x: tx, y: y + 6))
                    context.stroke(tick, with: .color(cBlue.opacity(0.55)), lineWidth: 1.5)
                    context.draw(Text("\(i)").font(.system(size: 9, design: .monospaced)).foregroundStyle(cBlue.opacity(0.75)), at: CGPoint(x: tx, y: y + 16))
                }
            }

            // Draw user freehand ink strokes
            for stroke in inkStrokes where stroke.count >= 2 {
                var p = Path()
                p.move(to: stroke[0])
                for pt in stroke.dropFirst() { p.addLine(to: pt) }
                context.stroke(p, with: .color(cRed), lineWidth: 2.4)
            }
            if activeInkStroke.count >= 2 {
                var p = Path()
                p.move(to: activeInkStroke[0])
                for pt in activeInkStroke.dropFirst() { p.addLine(to: pt) }
                context.stroke(p, with: .color(cBlue), lineWidth: 2.4)
            }
        }
    }
}
