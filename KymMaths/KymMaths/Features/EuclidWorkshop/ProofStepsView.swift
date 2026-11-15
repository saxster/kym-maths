import SwiftUI

/// Byrne's proof: each part of a claim is a small coloured picture of that part, not a pair of
/// letters. Tap a picture to pulse it on the board; tap a proposition to open it. Until she has
/// tried the construction the proof stays closed, with a way to open it early that counts as help.
struct ProofStepsView: View {
    @Environment(\.standardTheme) private var theme
    @Binding var session: EuclidWorkshopSession
    /// Her lamps for this proposition, shown under a closed proof.
    var record = EuclidSkillRecord()
    let onOpen: (PropositionID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Text("The proof")
                    .standardType(.headlineSm)
                    .foregroundStyle(theme.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: StandardSpacing.xs)
                if !session.hasAttempted {
                    StatusTag(.locked)
                } else if session.isAssisted {
                    StatusTag(.withHelp)
                }
            }
            Rectangle().fill(theme.hairline()).frame(height: 1)

            if session.hasAttempted {
                ForEach(Array(session.proposition.proofSteps.enumerated()), id: \.offset) { index, step in
                    ProofStepRow(number: index + 1, step: step, session: $session, onOpen: onOpen)
                }
                if session.isAssisted {
                    Text("The proof opened before the board was built, so this try counts as help.")
                        .standardType(.uiCaption)
                        .foregroundStyle(theme.patterned.assistedColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                closed
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var closed: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.md) {
            VStack(spacing: StandardSpacing.sm) {
                Image(systemName: "lock")
                    .standardType(.headlineMd)
                    .foregroundStyle(theme.mute(theme.ink))
                    .accessibilityHidden(true)
                Text("Try the construction first. The proof opens when you build it.")
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, StandardSpacing.xs)
            // The proof's lines, face down: one bar per step, in the colours it will use.
            VStack(alignment: .leading, spacing: StandardSpacing.sm) {
                ForEach(Array(session.proposition.proofSteps.prefix(6).enumerated()), id: \.offset) { index, _ in
                    Capsule()
                        .fill(index.isMultiple(of: 2) ? theme.patterned.wash(Self.washes[(index / 2) % 3]) : theme.patterned.sunkColor)
                        .frame(height: 7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.trailing, CGFloat(index % 3) * 22)
                }
            }
            .accessibilityHidden(true)
            HStack(alignment: .center, spacing: StandardSpacing.sm) {
                SkillLamps(lit: record.litLamps)
                Text(lampLine)
                    .standardType(.uiCaption)
                    .foregroundStyle(theme.mute(theme.ink))
                    .fixedSize(horizontal: false, vertical: true)
            }
            EuclidRuledNote(text: "Opening it early shows you the answer, so this try would count as help.")
            Button("Show the proof now") {
                session.revealProof()
            }
            .buttonStyle(OutlineButtonStyle())
            .frame(maxWidth: .infinity)
            .disabled(!session.canRevealProof)
        }
    }

    private static let washes: [ByrneRole] = [.given, .stays, .moves]

    private var lampLine: String {
        let next: SkillLevel? = record.highest == nil ? .picture : record.highest?.next
        guard let next else { return "Every lamp is lit" }
        return "Build it on your own to light “\(next.lampName)”"
    }
}

private struct ProofStepRow: View {
    @Environment(\.standardTheme) private var theme
    let number: Int
    let step: ProofStep
    @Binding var session: EuclidWorkshopSession
    let onOpen: (PropositionID) -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.sm) {
            Text("\(number)")
                .patternedType(.mathInline)
                .foregroundStyle(theme.mute(theme.ink))
                .frame(minWidth: 14, alignment: .leading)
            VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                ClaimLine(claim: step.claim, session: $session)
                JustificationChip(justification: step.because, onOpen: onOpen)
            }
        }
        .padding(.vertical, StandardSpacing.xxs)
    }
}

/// A claim laid out word by word, so long text wraps between the glyphs.
struct ClaimLine: View {
    @Environment(\.standardTheme) private var theme
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
                        .patternedType(.readingDefault)
                        .foregroundStyle(theme.ink)
                case let .glyph(token):
                    Button {
                        session.highlightedToken = session.highlightedToken == token ? nil : token
                    } label: {
                        ClaimGlyph(token: token, positions: session.positions(of: token), skeleton: session.skeleton,
                                   layer: session.layer, colours: session.byrneColours,
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
/// A segment sits within a faint copy of the whole figure, so two lines of one colour and length
/// tell apart by where they are. The Letters layer shows the school's notation instead.
struct ClaimGlyph: View {
    let token: ClaimToken
    let positions: [Vec2]
    /// The solved figure's lines, for placing a segment.
    var skeleton: [FigureStroke] = []
    let layer: BoardLayer
    /// The construction's givens, so a given line keeps its blue in the glyph.
    var colours: ByrneBoardColours?
    var isHighlighted = false

    var body: some View {
        Group {
            if layer == .letters {
                Text(Self.letters(token))
                    .patternedType(.readingDefault)
                    .fontWeight(.semibold)
                    .foregroundStyle(MathsFigureColor.ink)
                    .padding(.horizontal, 3)
            } else {
                Canvas { context, size in draw(in: &context, size) }
                    .frame(width: 36, height: 26)
            }
        }
        // A picked glyph is lit in light amber on the paper, so its ink stays readable in every theme.
        .background(
            RoundedRectangle(cornerRadius: MathsFigureRadius.tile)
                .fill(MathsFigureColor.paper)
                .overlay(RoundedRectangle(cornerRadius: MathsFigureRadius.tile)
                    .fill(MathsFigureColor.amber.opacity(isHighlighted ? 0.3 : 0)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: MathsFigureRadius.tile)
                .strokeBorder(isHighlighted ? MathsFigureColor.amber : MathsFigureColor.ink.opacity(0.12),
                              lineWidth: isHighlighted ? 2 : 1)
        )
    }

    private var role: ColorRole {
        switch token {
        case let .segment(_, _, r):
            if let colours, positions.count == 2 { colours.role(r, from: positions[0], to: positions[1]) } else { r }
        case let .angle(_, _, _, r), let .circle(_, r), let .region(_, r): r
        case .text: .ink
        }
    }

    private func draw(in context: inout GraphicsContext, _ size: CGSize) {
        let colour = role.figureColor
        let inset = CGRect(origin: .zero, size: size).insetBy(dx: 4, dy: 3)
        switch token {
        case .text:
            break
        case .circle:
            let r = min(inset.width, inset.height) / 2
            context.stroke(BoardPaths.circle(CGPoint(x: inset.midX, y: inset.midY), radius: r), with: .color(colour), lineWidth: 2)
        case .segment:
            guard positions.count == 2 else { return }
            let figure = skeleton.flatMap { [$0.from, $0.to] }
            let points = fitted(positions + figure, in: inset)
            for index in stride(from: 2, to: points.count, by: 2) {
                context.stroke(BoardPaths.line(points[index], points[index + 1]), with: .color(MathsFigureColor.ink.opacity(0.2)), lineWidth: 0.8)
            }
            context.stroke(BoardPaths.line(points[0], points[1]), with: .color(colour), style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
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
    @Environment(\.standardTheme) private var theme
    let justification: Justification
    let onOpen: (PropositionID) -> Void

    var body: some View {
        switch justification {
        case let .proposition(id):
            Button {
                onOpen(id)
            } label: {
                HStack(spacing: StandardSpacing.xxs) {
                    Text(justification.meaning)
                    Image(systemName: "arrow.up.right").imageScale(.small)
                }
                .standardType(.uiCaption)
                .fontWeight(.semibold)
                .frame(minHeight: 28, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(theme.brass)
            .help("Open \(id.raw)")
        default:
            Text(justification.meaning)
                .standardType(.uiCaption)
                .foregroundStyle(theme.mute(theme.ink))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
