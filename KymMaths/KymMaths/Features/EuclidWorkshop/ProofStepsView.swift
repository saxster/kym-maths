import SwiftUI

/// Byrne's proof: each part of a claim is a small coloured picture of that part, not a pair of
/// letters. Tap a picture to pulse it on the board; tap a proposition to open it.
struct ProofStepsView: View {
    @Binding var session: EuclidWorkshopSession
    let onOpen: (PropositionID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("THE PROOF")
                .font(Typography.eyebrow)
                .foregroundStyle(Color.kymaiaPrimary)

            if session.hasAttempted {
                ForEach(Array(session.proposition.proofSteps.enumerated()), id: \.offset) { index, step in
                    ProofStepRow(number: index + 1, step: step, session: $session, onOpen: onOpen)
                }
                if session.isAssisted {
                    JournalBadge(text: "Assisted attempt", symbol: "hand.raised.fill", tone: .warning)
                }
            } else {
                Text("Try the construction first. The proof opens when you solve it.")
                    .font(Typography.body)
                    .foregroundStyle(Color.kymaiaInk)
                Text("Opening it early shows you the answer, so this attempt would count as help.")
                    .font(Typography.caption)
                    .foregroundStyle(Color.kymaiaMutedInk)
                Button("Show the proof now") {
                    session.revealProof()
                }
                .buttonStyle(JournalSecondaryButtonStyle())
                .disabled(!session.canRevealProof)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ProofStepRow: View {
    let number: Int
    let step: ProofStep
    @Binding var session: EuclidWorkshopSession
    let onOpen: (PropositionID) -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
            Text("\(number).")
                .font(Typography.subheadline.weight(.bold))
                .foregroundStyle(Color.kymaiaMutedInk)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                ClaimLine(claim: step.claim, session: $session)
                JustificationChip(justification: step.because, onOpen: onOpen)
            }
        }
        .padding(.vertical, Spacing.xxs)
    }
}

/// A claim laid out word by word, so long text wraps between the glyphs.
struct ClaimLine: View {
    let claim: [ClaimToken]
    @Binding var session: EuclidWorkshopSession

    private enum Piece: Hashable {
        case word(String)
        case glyph(ClaimToken)
    }

    private var pieces: [Piece] {
        claim.flatMap { token -> [Piece] in
            if case let .text(text) = token {
                return text.split(separator: " ").map { .word(String($0)) }
            }
            return [.glyph(token)]
        }
    }

    var body: some View {
        FlowLayout(spacing: 5) {
            ForEach(Array(pieces.enumerated()), id: \.offset) { _, piece in
                switch piece {
                case let .word(word):
                    Text(word)
                        .font(Typography.body)
                        .foregroundStyle(Color.kymaiaInk)
                case let .glyph(token):
                    Button {
                        session.highlightedToken = session.highlightedToken == token ? nil : token
                    } label: {
                        ClaimGlyph(token: token, positions: session.positions(of: token), layer: session.layer,
                                   isHighlighted: session.highlightedToken == token)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(ClaimGlyph.spoken(token))
                }
            }
        }
    }
}

/// One part of the figure in miniature, drawn the way it sits on the board, in its role colour.
/// The Letters layer shows the school's notation instead.
struct ClaimGlyph: View {
    let token: ClaimToken
    let positions: [Vec2]
    let layer: BoardLayer
    var isHighlighted = false

    var body: some View {
        Group {
            if layer == .letters {
                Text(Self.letters(token))
                    .font(Typography.body.weight(.semibold))
                    .foregroundStyle(MathsFigureColor.ink)
                    .padding(.horizontal, 3)
            } else {
                Canvas { context, size in draw(in: &context, size) }
                    .frame(width: 34, height: 22)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: MathsFigureRadius.tile)
                .fill(isHighlighted ? Color.kymaiaSelectionFill : MathsFigureColor.paper)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MathsFigureRadius.tile)
                .strokeBorder(isHighlighted ? Color.kymaiaPrimary : MathsFigureColor.ink.opacity(0.12), lineWidth: 1)
        )
    }

    private var role: ColorRole {
        switch token {
        case let .segment(_, _, r), let .angle(_, _, _, r), let .circle(_, r), let .region(_, r): r
        case .text: .ink
        }
    }

    private func draw(in context: inout GraphicsContext, _ size: CGSize) {
        let colour = role.figureColor
        let inset = CGRect(origin: .zero, size: size).insetBy(dx: 5, dy: 4)
        switch token {
        case .text:
            break
        case .circle:
            let r = min(inset.width, inset.height) / 2
            context.stroke(BoardPaths.circle(CGPoint(x: inset.midX, y: inset.midY), radius: r), with: .color(colour), lineWidth: 2)
        case .segment:
            let points = fitted(positions, in: inset)
            guard points.count == 2 else { return }
            context.stroke(BoardPaths.line(points[0], points[1]), with: .color(colour), style: StrokeStyle(lineWidth: 3.2, lineCap: .round))
        case .angle:
            guard positions.count == 3 else { return }
            let (p, v, q) = (positions[0], positions[1], positions[2])
            func unit(_ w: Vec2) -> Vec2 { let d = w - v; return (1 / max(d.length, 1e-9)) * d }
            let points = fitted([v, v + unit(p), v + unit(q)], in: inset)
            context.fill(BoardPaths.wedge(points[1], vertex: points[0], points[2], radius: min(inset.width, inset.height) * 0.75),
                         with: .color(colour))
            context.stroke(BoardPaths.line(points[0], points[1]), with: .color(MathsFigureColor.ink), lineWidth: 1)
            context.stroke(BoardPaths.line(points[0], points[2]), with: .color(MathsFigureColor.ink), lineWidth: 1)
        case .region:
            let points = fitted(positions, in: inset)
            context.fill(BoardPaths.polygon(points), with: .color(colour))
        }
    }

    /// Scales board positions into `rect`, y flipped, keeping their shape.
    private func fitted(_ points: [Vec2], in rect: CGRect) -> [CGPoint] {
        guard !points.isEmpty else { return [] }
        let xs = points.map(\.x), ys = points.map(\.y)
        let extent = BoardExtent(min: Vec2(x: xs.min()!, y: ys.min()!), max: Vec2(x: xs.max()!, y: ys.max()!))
        let viewport = BoardViewport(fitting: extent, in: rect.size, margin: 0)
        return points.map { p in
            let at = viewport.toView(p)
            return CGPoint(x: rect.minX + at.x, y: rect.minY + at.y)
        }
    }

    static func letters(_ token: ClaimToken) -> String {
        switch token {
        case let .text(text): text
        case let .segment(p, q, _): p + q
        case let .angle(p, v, q, _): "∠" + p + v + q
        case let .circle(center, _): "⊙" + center
        case let .region(corners, _): (corners.count == 3 ? "△" : "▱") + corners.joined()
        }
    }

    static func spoken(_ token: ClaimToken) -> String {
        switch token {
        case let .text(text): text
        case let .segment(p, q, role): "\(role.rawValue) line \(p)\(q)"
        case let .angle(p, v, q, role): "\(role.rawValue) angle \(p)\(v)\(q)"
        case let .circle(center, role): "\(role.rawValue) circle about \(center)"
        case let .region(corners, role): "\(role.rawValue) shape \(corners.joined())"
        }
    }
}

/// The reason a step holds. A proposition opens its own board.
struct JustificationChip: View {
    let justification: Justification
    let onOpen: (PropositionID) -> Void

    var body: some View {
        switch justification {
        case let .proposition(id):
            Button {
                onOpen(id)
            } label: {
                Label(justification.meaning, systemImage: "arrow.up.right.circle")
                    .font(Typography.caption.weight(.semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.kymaiaPrimary)
            .help("Open \(id)")
        default:
            Text(justification.meaning)
                .font(Typography.caption)
                .foregroundStyle(Color.kymaiaMutedInk)
        }
    }
}
