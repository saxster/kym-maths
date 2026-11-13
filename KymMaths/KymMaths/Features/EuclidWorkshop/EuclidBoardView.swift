import SwiftUI

/// The compass-and-straightedge board: Byrne colours on drafting paper, arcs kept, and the
/// crossing nearest the pointer ringed. Taps go to the session, which snaps them.
struct EuclidBoardCanvas: View {
    let session: EuclidWorkshopSession
    let onTap: (_ location: Vec2, _ tolerance: Double) -> Void

    @State private var pointer: CGPoint?

    #if os(iOS)
    private static let reach: CGFloat = 24
    #else
    private static let reach: CGFloat = 16
    #endif

    private var highlights: [BoardHighlight] {
        [session.highlightedToken.flatMap(session.highlight(for:)), session.hint?.highlight].compactMap { $0 }
    }

    var body: some View {
        GeometryReader { geo in
            let viewport = BoardViewport(fitting: session.extent, in: geo.size)
            TimelineView(.animation(minimumInterval: 1 / 30, paused: highlights.isEmpty)) { timeline in
                Canvas { context, _ in
                    let pulse = 0.55 + 0.45 * sin(timeline.date.timeIntervalSinceReferenceDate * 4)
                    draw(in: &context, viewport, pulse: highlights.isEmpty ? 1 : pulse)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { pointer = $0.location }
                    .onEnded { value in
                        onTap(viewport.toBoard(value.location), viewport.boardLength(Self.reach))
                        #if os(iOS)
                        pointer = nil
                        #endif
                    }
            )
            .onContinuousHover { phase in
                switch phase {
                case let .active(location): pointer = location
                case .ended: pointer = nil
                }
            }
        }
        .background(MathsFigureColor.paper)
        .clipShape(RoundedRectangle(cornerRadius: MathsFigureRadius.frame, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: MathsFigureRadius.frame, style: .continuous)
                .strokeBorder(MathsFigureColor.ink.opacity(0.12), lineWidth: 1)
        )
        .accessibilityElement()
        .accessibilityLabel("Construction board for \(session.proposition.id), \(session.proposition.title)")
        .accessibilityValue(session.isSolved ? "Solved" : session.prompt)
    }

    // MARK: - Drawing

    private func colour(_ role: ColorRole) -> Color {
        session.layer == .letters ? MathsFigureColor.ink : role.figureColor
    }

    private func draw(in context: inout GraphicsContext, _ viewport: BoardViewport, pulse: Double) {
        let board = session.board
        for highlight in highlights {
            drawHighlight(highlight, in: &context, viewport, pulse: pulse)
        }

        let scaffolding = session.scaffolding
        // A tool's scaffolding goes down first and faint, so her own curves sit on top of it.
        for pass in [true, false] {
            for (index, curve) in board.curves.enumerated() where scaffolding.curves.contains(CurveID(raw: index)) == pass {
                drawCurve(curve, on: board, viewport, in: &context, faint: pass)
            }
        }
        for (id, ends) in scaffolding.spans {
            guard ends.count == 2, let pa = try? board.position(of: ends[0]), let pb = try? board.position(of: ends[1]) else { continue }
            context.stroke(BoardPaths.line(viewport.toView(pa), viewport.toView(pb)),
                           with: .color(colour(board.curves[id.raw].role)), style: StrokeStyle(lineWidth: 3.2, lineCap: .round))
        }

        drawPreview(in: &context, viewport)

        for candidate in board.intersectionCandidates()
        where !scaffolding.curves.contains(candidate.a) && !scaffolding.curves.contains(candidate.b) {
            let at = viewport.toView(candidate.position)
            context.stroke(BoardPaths.circle(at, radius: 3), with: .color(MathsFigureColor.ink.opacity(0.35)), lineWidth: 1)
        }

        for (index, point) in board.points.enumerated() {
            let at = viewport.toView(point.position)
            if scaffolding.points.contains(PointID(raw: index)) {
                context.fill(BoardPaths.circle(at, radius: 2), with: .color(MathsFigureColor.ink.opacity(0.3)))
                continue
            }
            let isGiven = if case .given = point.origin { true } else { false }
            context.fill(BoardPaths.circle(at, radius: isGiven ? 4.5 : 3.6), with: .color(MathsFigureColor.ink))
            if session.layer == .letters, let name = session.label(of: PointID(raw: index)) {
                drawLabel(name, at: at, viewport, in: &context)
            }
        }

        for (order, held) in session.tool.held.enumerated() {
            guard let p = try? board.position(of: held) else { continue }
            let at = viewport.toView(p)
            context.stroke(BoardPaths.circle(at, radius: 9), with: .color(MathsFigureColor.ink), lineWidth: 2)
            if case .proposition = session.tool {
                context.draw(Text("\(order + 1)").font(MathsFigureType.tally).foregroundStyle(MathsFigureColor.ink),
                             at: CGPoint(x: at.x + 13, y: at.y - 13))
            }
        }

        if let target = snapPosition(viewport) {
            context.stroke(BoardPaths.circle(viewport.toView(target), radius: 12),
                           with: .color(MathsFigureColor.amber), lineWidth: 2.2)
        }
    }

    private func drawCurve(_ curve: BoardCurve, on board: ConstructionBoard, _ viewport: BoardViewport,
                           in context: inout GraphicsContext, faint: Bool) {
        let scaffoldInk = MathsFigureColor.ink.opacity(0.16)
        switch curve.curve {
        case let .circle(c, t):
            guard let pc = try? board.position(of: c), let pt = try? board.position(of: t) else { return }
            let path = BoardPaths.circle(viewport.toView(pc), radius: viewport.length(pc.distance(to: pt)))
            context.stroke(path, with: .color(faint ? scaffoldInk : colour(curve.role).opacity(0.85)), lineWidth: faint ? 0.8 : 1.4)
        case let .segment(a, b):
            guard let pa = try? board.position(of: a), let pb = try? board.position(of: b) else { return }
            let path = BoardPaths.line(viewport.toView(pa), viewport.toView(pb))
            context.stroke(path, with: .color(faint ? scaffoldInk : colour(curve.role)),
                           style: StrokeStyle(lineWidth: faint ? 1 : 3.2, lineCap: .round))
        }
    }

    private func snapPosition(_ viewport: BoardViewport) -> Vec2? {
        guard let pointer else { return nil }
        switch session.board.snap(viewport.toBoard(pointer), tolerance: viewport.boardLength(Self.reach)) {
        case let .point(id)?: return try? session.board.position(of: id)
        case let .candidate(candidate)?: return candidate.position
        case nil: return nil
        }
    }

    /// The curve the held point and the ringed target would make.
    private func drawPreview(in context: inout GraphicsContext, _ viewport: BoardViewport) {
        guard let target = snapPosition(viewport), let held = session.tool.held.first,
              let from = try? session.board.position(of: held), from.distance(to: target) > ConstructionBoard.coincidence
        else { return }
        let dashed = StrokeStyle(lineWidth: 1.4, dash: [5, 5])
        switch session.tool {
        case .compass:
            context.stroke(BoardPaths.circle(viewport.toView(from), radius: viewport.length(from.distance(to: target))),
                           with: .color(session.nextRole.figureColor.opacity(0.6)), style: dashed)
        case .straightedge:
            context.stroke(BoardPaths.line(viewport.toView(from), viewport.toView(target)),
                           with: .color(session.nextRole.figureColor.opacity(0.6)), style: dashed)
        case .proposition:
            break
        }
    }

    private func drawHighlight(_ highlight: BoardHighlight, in context: inout GraphicsContext, _ viewport: BoardViewport, pulse: Double) {
        let dashed = StrokeStyle(lineWidth: 1.8, lineCap: .round, dash: [6, 5])
        switch highlight {
        case let .points(points):
            for (order, p) in points.enumerated() {
                let at = viewport.toView(p)
                context.stroke(BoardPaths.circle(at, radius: 12), with: .color(MathsFigureColor.ink.opacity(pulse)), lineWidth: 2.4)
                if points.count > 1 {
                    context.draw(Text("\(order + 1)").font(MathsFigureType.tally).foregroundStyle(MathsFigureColor.ink),
                                 at: CGPoint(x: at.x + 16, y: at.y - 16))
                }
            }
        case let .segment(a, b, role):
            context.stroke(BoardPaths.line(viewport.toView(a), viewport.toView(b)),
                           with: .color(colour(role).opacity(0.35 * pulse)), style: StrokeStyle(lineWidth: 12, lineCap: .round))
        case let .circle(c, r, role):
            context.stroke(BoardPaths.circle(viewport.toView(c), radius: viewport.length(r)),
                           with: .color(colour(role).opacity(0.35 * pulse)), lineWidth: 8)
        case let .angle(p, v, q, role):
            context.fill(BoardPaths.wedge(viewport.toView(p), vertex: viewport.toView(v), viewport.toView(q), radius: 30),
                         with: .color(colour(role).opacity(0.55 * pulse)))
        case let .region(corners, role):
            context.fill(BoardPaths.polygon(corners.map(viewport.toView)), with: .color(colour(role).opacity(0.3 * pulse)))
        case let .ghostCircle(c, r):
            let at = viewport.toView(c)
            context.stroke(BoardPaths.circle(at, radius: viewport.length(r)), with: .color(MathsFigureColor.ink.opacity(0.7)), style: dashed)
            context.stroke(BoardPaths.circle(at, radius: 12), with: .color(MathsFigureColor.ink.opacity(pulse)), lineWidth: 2.4)
        case let .ghostSegment(a, b):
            context.stroke(BoardPaths.line(viewport.toView(a), viewport.toView(b)), with: .color(MathsFigureColor.ink.opacity(0.7)), style: dashed)
        }
    }

    /// A letter set off from the point, away from the figure's middle.
    private func drawLabel(_ name: String, at point: CGPoint, _ viewport: BoardViewport, in context: inout GraphicsContext) {
        let extent = session.extent
        let middle = viewport.toView(Vec2(x: (extent.min.x + extent.max.x) / 2, y: (extent.min.y + extent.max.y) / 2))
        var dx = point.x - middle.x, dy = point.y - middle.y
        let length = max(1, (dx * dx + dy * dy).squareRoot())
        (dx, dy) = (dx / length, dy / length)
        if length < 2 { (dx, dy) = (0.7, -0.7) }
        context.draw(Text(name).font(MathsFigureType.setSymbol).foregroundStyle(MathsFigureColor.ink),
                     at: CGPoint(x: point.x + 15 * dx, y: point.y + 15 * dy))
    }
}

/// Compass, straightedge, one tool per proven proposition, then undo, hint and the layer switch.
struct EuclidBoardToolbar: View {
    @Binding var session: EuclidWorkshopSession
    var onUndo: () -> Void = {}

    var body: some View {
        FlowLayout(spacing: Spacing.xs) {
            MathsFilterChip(title: "Compass", systemImage: "circle.dashed", isSelected: session.tool.tool == .compass) {
                session.choose(.compass)
            }
            MathsFilterChip(title: "Straightedge", systemImage: "line.diagonal", isSelected: session.tool.tool == .straightedge) {
                session.choose(.straightedge)
            }
            ForEach(session.tools, id: \.self) { id in
                MathsFilterChip(
                    title: "\(id) · \(EuclidSpine.proposition(id)?.title ?? "")",
                    systemImage: "wand.and.rays",
                    isSelected: session.tool.tool == .proposition(id)
                ) {
                    session.choose(.proposition(id))
                }
            }
            Button {
                session.undo()
                onUndo()
            } label: {
                Label("Undo", systemImage: "arrow.uturn.backward")
            }
            .buttonStyle(JournalSecondaryButtonStyle())
            .disabled(session.board.history.isEmpty)

            Button {
                session.requestHint()
            } label: {
                Label("Hint", systemImage: "lightbulb")
            }
            .buttonStyle(JournalSecondaryButtonStyle())
            .disabled(session.isSolved)

            MathsFilterChip(title: "Letters", systemImage: "textformat", isSelected: session.layer == .letters) {
                session.layer = session.layer == .letters ? .byrne : .letters
            }
        }
    }
}

extension TapOutcome {
    /// What the status line says after a tap, when the tap needs explaining.
    var message: String? {
        switch self {
        case .refused(.emptyPaper):
            "Euclid allows no free points. Tap a point, or a place where two lines cross."
        case .refused(.alreadyOnBoard):
            "That is already on the board."
        case .refused(.alreadyPicked):
            "That point is already chosen."
        case let .refused(.failed(error)):
            switch error {
            case .noIntersection: "Those lines don't cross there."
            case let .wrongInputCount(id, expected, _): "\(id) needs \(expected) points."
            default: "That tool can't be used on those points. Try them in another order."
            }
        case let .built(id):
            "\(id) built in one step."
        case .picked, .released, .drew:
            nil
        }
    }
}
