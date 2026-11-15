import SwiftUI

// MARK: - Scratchpad: paper, drawing stamps and the reader's own working for one question

enum MathsScratchpadStamp: String, CaseIterable, Identifiable, Sendable {
    case singaporeBar = "singapore_bar"
    case numberLine = "number_line"
    case cartesianAxes = "cartesian_axes"
    case unitCircle = "unit_circle"
    case venn2Set = "venn_2set"
    case primeTree = "prime_tree"
    case truthTable = "truth_table"
    case matrixGrid = "matrix_grid"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .singaporeBar: return "Bar model"
        case .cartesianAxes: return "Axes"
        case .unitCircle: return "Unit circle"
        case .venn2Set: return "Venn"
        case .primeTree: return "Factor tree"
        case .truthTable: return "Truth table"
        case .matrixGrid: return "2×2 matrix"
        case .numberLine: return "Number line"
        }
    }

    /// One line under the paper that says how to use the stamp.
    var hint: String {
        switch self {
        case .singaporeBar: return "Bar model: equal boxes are equal units. Find one unit first."
        case .cartesianAxes: return "Axes: the origin is (0, 0). Gradient m = Δy ÷ Δx, and y = mx + c."
        case .unitCircle: return "Unit circle: P = (cos θ, sin θ), cos²θ + sin²θ = 1, and π rad = 180°."
        case .venn2Set: return "Venn: |A ∪ B| = |A| + |B| − |A ∩ B|. The HCF sits in the overlap."
        case .primeTree: return "Factor tree: split until every branch ends in a prime: 2, 3, 5, 7, 11…"
        case .truthTable: return "Truth table: P | Q | P ∧ Q | P ∨ Q, one row for each case."
        case .matrixGrid: return "2×2 matrix: det = ad − bc, and the trace is a + d."
        case .numberLine: return "Number line: an open ○ for < and >, a filled ● for ≤ and ≥."
        }
    }
}

/// The colours a reader can write in: ink, or one of Byrne's three for the maths.
enum ScratchInk: String, CaseIterable, Identifiable, Sendable {
    case ink, red, yellow, blue

    var id: String { rawValue }

    var name: String {
        switch self {
        case .ink: "Ink"
        case .red: "Red, for what moves"
        case .yellow: "Yellow, for what stays"
        case .blue: "Blue, for what is given"
        }
    }

    func color(_ theme: StandardTheme) -> Color {
        switch self {
        case .ink: theme.ink
        case .red: theme.patterned.color(.moves)
        case .yellow: theme.patterned.color(.stays)
        case .blue: theme.patterned.color(.given)
        }
    }
}

struct ScratchStroke: Equatable, Sendable {
    var points: [CGPoint]
    var ink: ScratchInk
}

struct MathsScratchpadView: View {
    let question: SchoolMathsQuestion
    @Bindable var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.standardTheme) private var theme

    @State private var paperStyle: String = "grid"
    @State private var selectedStamp: MathsScratchpadStamp? = .singaporeBar
    @State private var textScratchNotes: String = ""
    @State private var savedStrokeCount: Int = 0
    @State private var isSketchMode: Bool = false
    @State private var inkStrokes: [ScratchStroke] = []
    @State private var activeInkStroke: [CGPoint] = []
    @State private var currentInk: ScratchInk = .ink
    @State private var sheetHeight: CGFloat = 0

    private static let paperStyles: [(id: String, title: String)] = [
        ("grid", "Grid"), ("dots", "Dots"), ("lined", "Lined"), ("blank", "Blank"), ("cornell", "Cornell"),
    ]
    /// The paper takes the height the header, stamps and footer leave, and never less than 420.
    private var paperHeight: CGFloat { max(420, sheetHeight - 340) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StandardSpacing.lg) {
                header
                paper
                stamps
                footer
            }
            .padding(StandardSpacing.xl)
        }
        .readHeight($sheetHeight)
        .background(theme.bg)
        .onAppear(perform: load)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .bottom, spacing: StandardSpacing.lg) {
            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                Kicker("Scratchpad · Topic \(question.topicCode)")
                Text("Think on paper")
                    .standardType(.display)
                    .foregroundStyle(theme.ink)
                    .accessibilityAddTraits(.isHeader)
                Text(question.prompt)
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.mute(theme.ink))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: StandardSpacing.xxs) {
                Kicker("Paper", muted: true)
                FlowLayout(spacing: StandardSpacing.xs) {
                    ForEach(Self.paperStyles, id: \.id) { style in
                        PatternedChip(style.title, isSelected: paperStyle == style.id) {
                            paperStyle = style.id
                        }
                    }
                }
                .frame(maxWidth: 420)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .overlay(alignment: .topTrailing) {
            SheetCloseButton { dismiss() }
                .offset(x: StandardSpacing.sm, y: -StandardSpacing.lg)
        }
    }

    // MARK: Paper

    private var paper: some View {
        ZStack(alignment: .topLeading) {
            ScratchPaper(style: paperStyle, line: theme.hairline(), accent: theme.brass.opacity(0.45))

            MathsStampBlueprintCanvas(
                stamp: selectedStamp,
                inkStrokes: inkStrokes,
                activeInkStroke: activeInkStroke,
                activeInk: currentInk
            )
            .allowsHitTesting(false)

            if isSketchMode {
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 2)
                            .onChanged { value in
                                activeInkStroke.append(value.location)
                            }
                            .onEnded { _ in
                                if activeInkStroke.count >= 2 {
                                    inkStrokes.append(ScratchStroke(points: activeInkStroke, ink: currentInk))
                                }
                                activeInkStroke.removeAll()
                            }
                    )
                    .accessibilityLabel("Drawing area")
            } else {
                TextEditor(text: $textScratchNotes)
                    .scrollContentBackground(.hidden)
                    .patternedType(.hand)
                    .foregroundStyle(theme.ink)
                    .padding(.top, 64)
                    .padding(.horizontal, StandardSpacing.lg)
                    .accessibilityLabel("Your working")
            }
        }
        .frame(height: paperHeight)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: StandardRadius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: StandardRadius.xl, style: .continuous)
                .strokeBorder(theme.hairline(), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) { toolbar.padding(StandardSpacing.md) }
        .overlay(alignment: .bottomLeading) {
            if let stamp = selectedStamp {
                Text(stamp.hint)
                    .standardType(.uiCaption)
                    .foregroundStyle(theme.mute(theme.ink))
                    .padding(StandardSpacing.md)
            }
        }
    }

    private var toolbar: some View {
        HStack(spacing: 0) {
            ToolIconButton(
                isSketchMode ? "Drawing. Switch to typing" : "Typing. Switch to drawing",
                systemImage: isSketchMode ? "pencil.tip" : "keyboard",
                isOn: isSketchMode
            ) {
                isSketchMode.toggle()
            }
            ForEach(ScratchInk.allCases) { ink in
                Button {
                    currentInk = ink
                    isSketchMode = true
                } label: {
                    Circle()
                        .fill(ink.color(theme))
                        .frame(width: 18, height: 18)
                        .overlay(
                            Circle()
                                .strokeBorder(theme.ink, lineWidth: currentInk == ink && isSketchMode ? 2 : 0)
                                .padding(-4)
                        )
                        .frame(width: 36, height: StandardAccessibility.touchTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(ink.name)
                .accessibilityAddTraits(currentInk == ink ? .isSelected : [])
            }
            ToolIconButton("Undo the last line", systemImage: "arrow.uturn.backward") {
                if !inkStrokes.isEmpty { inkStrokes.removeLast() }
            }
            .disabled(inkStrokes.isEmpty)
        }
        .padding(.horizontal, StandardSpacing.xs)
        .background(Capsule().fill(theme.surface))
        .overlay(Capsule().strokeBorder(theme.hairline(), lineWidth: 1))
    }

    // MARK: Stamps and saving

    private var stamps: some View {
        HStack(alignment: .center, spacing: StandardSpacing.sm) {
            Kicker("Stamps", muted: true)
            FlowLayout(spacing: StandardSpacing.xs) {
                ForEach(MathsScratchpadStamp.allCases) { stamp in
                    PatternedChip(stamp.title, isSelected: selectedStamp == stamp) {
                        selectedStamp = (selectedStamp == stamp) ? nil : stamp
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack(alignment: .center, spacing: StandardSpacing.sm) {
            Text(savedStrokeCount > 0
                 ? "Saved. Your typed working stays with this question for next time."
                 : "Your typed working saves with this question. Drawings are for thinking and are not kept.")
                .standardType(.uiBody)
                .foregroundStyle(theme.mute(theme.ink))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Clear ink") {
                inkStrokes.removeAll()
            }
            .buttonStyle(OutlineButtonStyle())
            .disabled(inkStrokes.isEmpty)
            Button {
                save()
            } label: {
                HStack(spacing: StandardSpacing.xs) {
                    Text("Save working")
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(InkButtonStyle())
        }
    }

    private func save() {
        let data = Data(textScratchNotes.utf8)
        let totalCount = max(1, textScratchNotes.count + inkStrokes.count)
        store.saveScratchpad(
            questionId: question.id,
            paperStyle: paperStyle,
            stampKind: selectedStamp?.rawValue,
            drawingData: data,
            previewPNGData: Data(),
            strokeCount: totalCount
        )
        savedStrokeCount = totalCount
    }

    private func load() {
        paperStyle = store.defaultScratchpadPaperStyle
        if let existing = store.loadScratchpad(questionId: question.id),
           let savedText = String(data: existing.drawingData, encoding: .utf8) {
            textScratchNotes = savedText
            paperStyle = existing.paperStyle
            if let kind = existing.stampKind {
                selectedStamp = MathsScratchpadStamp(rawValue: kind)
            }
        }
    }
}

// MARK: - Paper

/// Ruled paper in the theme's hairline: grid, dots, lined, blank or Cornell.
private struct ScratchPaper: View {
    let style: String
    let line: Color
    let accent: Color

    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 24
            switch style {
            case "grid":
                var path = Path()
                var x = step
                while x < size.width { path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: size.height)); x += step }
                var y = step
                while y < size.height { path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: size.width, y: y)); y += step }
                context.stroke(path, with: .color(line), lineWidth: 1)
            case "dots":
                var y = step
                while y < size.height {
                    var x = step
                    while x < size.width {
                        context.fill(Path(ellipseIn: CGRect(x: x - 1.25, y: y - 1.25, width: 2.5, height: 2.5)), with: .color(line.opacity(2.5)))
                        x += step
                    }
                    y += step
                }
            case "lined", "cornell":
                var path = Path()
                var y: CGFloat = 32
                while y < size.height { path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: size.width, y: y)); y += 32 }
                context.stroke(path, with: .color(line), lineWidth: 1)
                let marginX = style == "cornell" ? size.width * 0.28 : 44
                var margin = Path()
                margin.move(to: CGPoint(x: marginX, y: 0)); margin.addLine(to: CGPoint(x: marginX, y: size.height))
                context.stroke(margin, with: .color(accent), lineWidth: 1)
            default:
                break
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Stamp figures, drawn in Byrne's colours, with the reader's ink on top

struct MathsStampBlueprintCanvas: View {
    let stamp: MathsScratchpadStamp?
    let inkStrokes: [ScratchStroke]
    let activeInkStroke: [CGPoint]
    let activeInk: ScratchInk

    @Environment(\.standardTheme) private var theme

    var body: some View {
        let palette = theme.patterned
        let cRed = palette.color(.moves)
        let cBlue = palette.color(.given)
        let cAmber = palette.color(.stays)
        let cGreen = palette.provenColor
        let inkColors = Dictionary(uniqueKeysWithValues: ScratchInk.allCases.map { ($0, $0.color(theme)) })

        Canvas { context, size in
            let w = size.width
            let h = size.height

            switch stamp {
            case nil:
                break

            case .singaporeBar?:
                let x0 = w * 0.46
                let uW = w * 0.085
                for i in 0..<5 {
                    let r = CGRect(x: x0 + CGFloat(i) * uW, y: h * 0.28, width: uW - 2, height: 34)
                    let col = i < 3 ? cRed : cAmber
                    context.fill(Path(roundedRect: r, cornerRadius: MathsFigureRadius.tile), with: .color(col.opacity(0.14)))
                    context.stroke(Path(roundedRect: r, cornerRadius: MathsFigureRadius.tile), with: .color(col.opacity(0.7)), lineWidth: 1.5)
                    context.draw(Text("1u").font(MathsFigureType.unitTile).foregroundStyle(col), at: CGPoint(x: r.midX, y: r.midY))
                }
                for i in 0..<3 {
                    let r = CGRect(x: x0 + CGFloat(i) * uW, y: h * 0.56, width: uW - 2, height: 34)
                    context.fill(Path(roundedRect: r, cornerRadius: MathsFigureRadius.tile), with: .color(cBlue.opacity(0.14)))
                    context.stroke(Path(roundedRect: r, cornerRadius: MathsFigureRadius.tile), with: .color(cBlue.opacity(0.7)), lineWidth: 1.5)
                    context.draw(Text("1u").font(MathsFigureType.unitTile).foregroundStyle(cBlue), at: CGPoint(x: r.midX, y: r.midY))
                }

            case .cartesianAxes?:
                let ox = w * 0.68, oy = h * 0.56
                var axes = Path()
                axes.move(to: CGPoint(x: w * 0.44, y: oy)); axes.addLine(to: CGPoint(x: w * 0.94, y: oy))
                axes.move(to: CGPoint(x: ox, y: h * 0.16)); axes.addLine(to: CGPoint(x: ox, y: h * 0.90))
                context.stroke(axes, with: .color(cBlue.opacity(0.6)), lineWidth: 1.8)
                var line = Path()
                line.move(to: CGPoint(x: w * 0.50, y: h * 0.80)); line.addLine(to: CGPoint(x: w * 0.88, y: h * 0.24))
                context.stroke(line, with: .color(cRed.opacity(0.6)), style: StrokeStyle(lineWidth: 1.8, dash: [5, 3]))

            case .unitCircle?:
                let cx = w * 0.70, cy = h * 0.56, r = min(w, h) * 0.30
                let cRect = CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r)
                context.stroke(Path(ellipseIn: cRect), with: .color(cBlue.opacity(0.6)), lineWidth: 1.8)
                let px = cx + r * cos(.pi / 5), py = cy - r * sin(.pi / 5)
                var tri = Path()
                tri.move(to: CGPoint(x: cx, y: cy)); tri.addLine(to: CGPoint(x: px, y: cy)); tri.addLine(to: CGPoint(x: px, y: py)); tri.closeSubpath()
                context.fill(tri, with: .color(cRed.opacity(0.12)))
                context.stroke(tri, with: .color(cRed.opacity(0.7)), lineWidth: 1.8)

            case .venn2Set?:
                let r = min(w, h) * 0.25
                let cA = CGRect(x: w * 0.62 - r, y: h * 0.55 - r, width: 2 * r, height: 2 * r)
                let cB = CGRect(x: w * 0.76 - r, y: h * 0.55 - r, width: 2 * r, height: 2 * r)
                context.fill(Path(ellipseIn: cA), with: .color(cRed.opacity(0.10)))
                context.fill(Path(ellipseIn: cB), with: .color(cBlue.opacity(0.10)))
                context.stroke(Path(ellipseIn: cA), with: .color(cRed.opacity(0.7)), lineWidth: 1.8)
                context.stroke(Path(ellipseIn: cB), with: .color(cBlue.opacity(0.7)), lineWidth: 1.8)

            case .primeTree?:
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
                context.stroke(branches, with: .color(theme.mute(theme.ink)), lineWidth: 1.5)
                for (pt, col) in [(top, cBlue), (l1, cGreen), (r1, cBlue), (r2L, cGreen), (r2R, cGreen)] {
                    let nr = CGRect(x: pt.x - 16, y: pt.y - 12, width: 32, height: 24)
                    context.fill(Path(ellipseIn: nr), with: .color(col.opacity(0.14)))
                    context.stroke(Path(ellipseIn: nr), with: .color(col.opacity(0.7)), lineWidth: 1.5)
                }

            case .truthTable?:
                let x0 = w * 0.48, y0 = h * 0.24, tw = w * 0.46, th = h * 0.64
                let rect = CGRect(x: x0, y: y0, width: tw, height: th)
                context.stroke(Path(rect), with: .color(cBlue.opacity(0.6)), lineWidth: 1.6)
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

            case .matrixGrid?:
                let x0 = w * 0.56, y0 = h * 0.28, mw = w * 0.30, mh = h * 0.52
                var brackets = Path()
                brackets.move(to: CGPoint(x: x0 + 10, y: y0)); brackets.addLine(to: CGPoint(x: x0, y: y0))
                brackets.addLine(to: CGPoint(x: x0, y: y0 + mh)); brackets.addLine(to: CGPoint(x: x0 + 10, y: y0 + mh))
                brackets.move(to: CGPoint(x: x0 + mw - 10, y: y0)); brackets.addLine(to: CGPoint(x: x0 + mw, y: y0))
                brackets.addLine(to: CGPoint(x: x0 + mw, y: y0 + mh)); brackets.addLine(to: CGPoint(x: x0 + mw - 10, y: y0 + mh))
                context.stroke(brackets, with: .color(cRed.opacity(0.7)), lineWidth: 2.2)
                var diag1 = Path(); diag1.move(to: CGPoint(x: x0 + 24, y: y0 + 24)); diag1.addLine(to: CGPoint(x: x0 + mw - 24, y: y0 + mh - 24))
                var diag2 = Path(); diag2.move(to: CGPoint(x: x0 + mw - 24, y: y0 + 24)); diag2.addLine(to: CGPoint(x: x0 + 24, y: y0 + mh - 24))
                context.stroke(diag1, with: .color(cGreen.opacity(0.6)), style: StrokeStyle(lineWidth: 1.6, dash: [4, 3]))
                context.stroke(diag2, with: .color(cAmber), style: StrokeStyle(lineWidth: 1.6, dash: [4, 3]))

            case .numberLine?:
                let y = h * 0.56, x0 = w * 0.42, x1 = w * 0.94
                var axis = Path(); axis.move(to: CGPoint(x: x0, y: y)); axis.addLine(to: CGPoint(x: x1, y: y))
                context.stroke(axis, with: .color(cBlue.opacity(0.7)), lineWidth: 2.0)
                for i in -5...5 {
                    let tx = x0 + CGFloat(i + 5) / 10.0 * (x1 - x0)
                    var tick = Path(); tick.move(to: CGPoint(x: tx, y: y - 6)); tick.addLine(to: CGPoint(x: tx, y: y + 6))
                    context.stroke(tick, with: .color(cBlue.opacity(0.7)), lineWidth: 1.5)
                    context.draw(Text("\(i)").font(MathsFigureType.axisTick).foregroundStyle(cBlue), at: CGPoint(x: tx, y: y + 16))
                }
            }

            // The reader's own lines, in the colour each was drawn with.
            for stroke in inkStrokes where stroke.points.count >= 2 {
                var p = Path()
                p.move(to: stroke.points[0])
                for pt in stroke.points.dropFirst() { p.addLine(to: pt) }
                context.stroke(p, with: .color(inkColors[stroke.ink] ?? cBlue), style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
            }
            if activeInkStroke.count >= 2 {
                var p = Path()
                p.move(to: activeInkStroke[0])
                for pt in activeInkStroke.dropFirst() { p.addLine(to: pt) }
                context.stroke(p, with: .color(inkColors[activeInk] ?? cBlue), style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
            }
        }
    }
}
