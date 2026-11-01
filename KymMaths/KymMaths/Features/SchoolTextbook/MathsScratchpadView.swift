import PencilKit
import SwiftUI

// MARK: - Mathematical Scratchpad with Singapore Bar-Model, Unit Circle, Venn & Matrix Stamps

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
    @Environment(\.themeTokens) private var tokens

    @State private var paperStyle: String = "grid"
    @State private var selectedStamp: MathsScratchpadStamp? = .singaporeBar
    @State private var textScratchNotes: String = ""
    @State private var savedStrokeCount: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Label("Mathematical Working & Singapore Bar Scratchpad", systemImage: "pencil.and.ruler")
                    .font(Typography.subheadline.weight(.semibold))
                    .foregroundStyle(tokens.primary)
                Spacer()
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

            // Canvas with paper background and stamp guide overlay
            ZStack(alignment: .topLeading) {
                JournalPaperBackground(style: JournalPaperStyle(rawValue: paperStyle) ?? .grid)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMD, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Spacing.radiusMD, style: .continuous)
                            .strokeBorder(tokens.borderSubtle, lineWidth: 1)
                    )

                if let stamp = selectedStamp {
                    stampOverlayView(for: stamp)
                        .padding(Spacing.md)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $textScratchNotes)
                    .scrollContentBackground(.hidden)
                    .font(Typography.mono)
                    .foregroundStyle(tokens.primary)
                    .padding(Spacing.sm)
                    .frame(height: 220)
            }

            HStack {
                Text("Write your algebraic steps, bar-model unit values, or geometric angle reasons above.")
                    .font(Typography.caption)
                    .foregroundStyle(tokens.secondary)
                Spacer()
                Button("Save Working") {
                    let data = Data(textScratchNotes.utf8)
                    store.saveScratchpad(
                        questionId: questionId,
                        paperStyle: paperStyle,
                        stampKind: selectedStamp?.rawValue,
                        drawingData: data,
                        previewPNGData: Data(),
                        strokeCount: max(1, textScratchNotes.count)
                    )
                    savedStrokeCount = textScratchNotes.count
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
        HStack(spacing: Spacing.sm) {
            Image(systemName: stamp.symbol)
                .foregroundStyle(tokens.accent.opacity(0.65))
            Text(stampHintText(for: stamp))
                .font(Typography.caption)
                .foregroundStyle(tokens.secondary.opacity(0.75))
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(tokens.surfaceElevated.opacity(0.85))
        )
    }

    private func stampHintText(for stamp: MathsScratchpadStamp) -> String {
        switch stamp {
        case .singaporeBar:
            return "Singapore CPA Bar Guide: [ Unit 1 ][ Unit 2 ][ Unit 3 ] = Total · Find 1 unit first"
        case .cartesianAxes:
            return "Coordinate Axes Guide: Origin (0,0) · Gradient m = Δy / Δx · y = mx + c"
        case .unitCircle:
            return "Unit Circle Guide: (cos θ, sin θ) · cos²θ + sin²θ = 1 · π rad = 180°"
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
