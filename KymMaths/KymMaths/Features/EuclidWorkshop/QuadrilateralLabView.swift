import SwiftUI

/// PhET-inspired Quadrilateral Family explorer in Euclid's Workshop: drag any corner A–D
/// to discover why every square is also a rectangle, rhombus, parallelogram and kite.
struct QuadrilateralLabView: View {
    @Environment(\.standardTheme) private var theme
    @Bindable var store: AppStore

    @State private var vertices: [Vec2] = QuadrilateralClassifier.preset(.square)
    @State private var draggingIndex: Int?
    @State private var lastMovedVertex: String?
    @State private var showEqualSides = true
    @State private var showParallel = true
    @State private var showRightAngles = true
    @State private var showDiagonals = false
    @State private var smallSteps = false
    @State private var completedMissions: Set<String> = []
    @State private var width: CGFloat = 0
    @AppStorage("kymmaths.euclid.quadrilateral.paperChecked") private var paperChecked = false

    private static let extent = BoardExtent(
        min: QuadrilateralClassifier.boardMin,
        max: QuadrilateralClassifier.boardMax
    )
    private static let cornerNames = ["A", "B", "C", "D"]
    private static let presetKinds: [QuadrilateralKind] = [
        .square, .rectangle, .rhombus, .parallelogram, .isoscelesTrapezium, .trapezium, .kite
    ]
    private static let twoColumnMinWidth: CGFloat = 820

    var body: some View {
        let props = QuadrilateralClassifier.inspect(vertices)
        let voicing = QuadrilateralClassifier.voicingSummary(for: props, movedVertex: lastMovedVertex)

        EuclidPage(
            eyebrow: "Euclid's Workshop · Shape lab",
            title: "Quadrilateral family",
            subtitle: "Drag any corner A, B, C or D. Watch which properties hold and which names still apply.",
            back: { store.euclidRoute = .map }
        ) {
            Group {
                if width >= Self.twoColumnMinWidth {
                    HStack(alignment: .top, spacing: StandardSpacing.lg) {
                        boardSection(props: props, voicing: voicing)
                            .frame(maxWidth: .infinity)
                        inspectorSection(props: props)
                            .frame(width: 340)
                    }
                } else {
                    VStack(alignment: .leading, spacing: StandardSpacing.lg) {
                        boardSection(props: props, voicing: voicing)
                        inspectorSection(props: props)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .readWidth($width)

            PaperCheckCard(
                check: QuadrilateralClassifier.deviceOffCheck,
                isChecked: paperChecked
            ) {
                paperChecked.toggle()
            }
            .paperCard()
        }
        .onChange(of: vertices) { _, updated in
            let current = QuadrilateralClassifier.inspect(updated)
            for mission in QuadrilateralMission.all where mission.check(current) {
                completedMissions.insert(mission.id)
            }
        }
    }

    // MARK: - Board & Controls

    private func boardSection(
        props: QuadrilateralProperties,
        voicing: StageVoicingResponse
    ) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.md) {
            GeometryReader { geo in
                Canvas { context, size in
                    drawQuadrilateral(in: &context, size: size, props: props)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            handleDragChanged(location: value.location, startLocation: value.startLocation, in: geo.size)
                        }
                        .onEnded { _ in
                            draggingIndex = nil
                        }
                )
            }
            .frame(height: 360)
            .background(MathsFigureColor.paper)
            .clipShape(RoundedRectangle(cornerRadius: MathsFigureRadius.frame, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: MathsFigureRadius.frame, style: .continuous)
                    .strokeBorder(MathsFigureColor.ink.opacity(0.14), lineWidth: 1)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Quadrilateral board")
            .accessibilityValue(voicing.spokenLine)
            .accessibilityHint("Drag corners A, B, C or D, or pick a shape preset below.")

            Text(voicing.hint ?? voicing.context)
                .patternedType(.readingSmall)
                .foregroundStyle(voicing.hint != nil ? theme.patterned.color(.moves) : theme.mute(theme.ink))
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                Kicker("Show on board", muted: true)
                FlowLayout(spacing: StandardSpacing.xs) {
                    PatternedChip("Equal sides", isSelected: showEqualSides) { showEqualSides.toggle() }
                    PatternedChip("Parallel", isSelected: showParallel) { showParallel.toggle() }
                    PatternedChip("Right angles", isSelected: showRightAngles) { showRightAngles.toggle() }
                    PatternedChip("Diagonals", isSelected: showDiagonals) { showDiagonals.toggle() }
                    PatternedChip("Small steps", isSelected: smallSteps) { smallSteps.toggle() }
                }
            }

            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                Kicker("Jump to a family", muted: true)
                FlowLayout(spacing: StandardSpacing.xs) {
                    ForEach(Self.presetKinds) { kind in
                        PatternedChip(kind.title, isSelected: props.primaryKind == kind) {
                            vertices = QuadrilateralClassifier.preset(kind)
                            lastMovedVertex = nil
                        }
                    }
                    Button("Reset") {
                        vertices = QuadrilateralClassifier.preset(.square)
                        lastMovedVertex = nil
                    }
                    .buttonStyle(OutlineButtonStyle())
                }
            }
        }
        .paperCard()
    }

    // MARK: - Classification, Family Tree & Missions

    private func inspectorSection(props: QuadrilateralProperties) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.md) {
            VStack(alignment: .leading, spacing: StandardSpacing.sm) {
                Kicker("What you built")
                if !props.isSimple {
                    Text("Sides cross over")
                        .standardType(.headlineMd)
                        .foregroundStyle(theme.patterned.color(.moves))
                    Text("Two opposite sides cross. Drag a corner back so the loop stays open.")
                        .patternedType(.readingSmall)
                        .foregroundStyle(theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(props.primaryKind.title)
                        .standardType(.headlineMd)
                        .foregroundStyle(theme.ink)
                    Text(props.primaryKind.plainRule)
                        .patternedType(.readingSmall)
                        .foregroundStyle(theme.mute(theme.ink))
                        .fixedSize(horizontal: false, vertical: true)

                    let ancestors = Array(props.hierarchy.dropFirst())
                    if !ancestors.isEmpty {
                        VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                            Kicker("Also counts as", muted: true)
                            FlowLayout(spacing: StandardSpacing.xs) {
                                ForEach(ancestors) { ancestor in
                                    Text(ancestor.title)
                                        .standardType(.uiCaption)
                                        .foregroundStyle(theme.ink)
                                        .padding(.horizontal, StandardSpacing.xs)
                                        .padding(.vertical, 3)
                                        .background(
                                            Capsule().fill(theme.patterned.sunkColor)
                                        )
                                        .overlay(
                                            Capsule().strokeBorder(theme.hairline(), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }

                    Rectangle().fill(theme.hairline()).frame(height: 1)
                    measurementsGrid(props: props)
                }
            }
            .paperCard()

            VStack(alignment: .leading, spacing: StandardSpacing.sm) {
                Kicker("Discovery missions")
                ForEach(QuadrilateralMission.all) { mission in
                    let isDone = completedMissions.contains(mission.id) || mission.check(props)
                    VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                        HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.xs) {
                            Text(mission.title)
                                .standardType(.uiHeadline)
                                .foregroundStyle(theme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: StandardSpacing.xs)
                            StatusTag(isDone ? .proven : .notStarted, label: isDone ? "Built" : "Try it")
                        }
                        Text(mission.prompt)
                            .standardType(.uiCaption)
                            .foregroundStyle(theme.mute(theme.ink))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if mission.id != QuadrilateralMission.all.last?.id {
                        Rectangle().fill(theme.hairline()).frame(height: 1)
                    }
                }
            }
            .paperCard()
        }
    }

    private func measurementsGrid(props: QuadrilateralProperties) -> some View {
        let sideNames = ["AB", "BC", "CD", "DA"]
        let sidesSummary = (0..<4)
            .map { "\(sideNames[$0]) \(String(format: "%.1f", props.sideLengths[$0]))" }
            .joined(separator: " · ")
        let anglesSummary = (0..<4)
            .map { "∠\(Self.cornerNames[$0]) \(Int(props.angles[$0].rounded()))°" }
            .joined(separator: " · ")
        var diagFacts: [String] = []
        if props.diagonalsEqual { diagFacts.append("Equal") }
        if props.diagonalsPerpendicular { diagFacts.append("90° crossing") }
        if props.diagonalsBisectEachOther { diagFacts.append("Bisect") }
        let diagSummary = diagFacts.isEmpty ? "Unequal diagonals" : diagFacts.joined(separator: " · ")

        return VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
            Text(sidesSummary)
                .standardType(.uiCaption)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(anglesSummary)
                .standardType(.uiCaption)
                .foregroundStyle(theme.mute(theme.ink))
                .fixedSize(horizontal: false, vertical: true)
            Text(diagSummary)
                .standardType(.uiCaption)
                .foregroundStyle(theme.patterned.color(.given))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Gesture Handling

    private func handleDragChanged(location: CGPoint, startLocation: CGPoint, in size: CGSize) {
        let viewport = BoardViewport(fitting: Self.extent, in: size, margin: 28)
        if draggingIndex == nil {
            var bestIndex: Int?
            var bestDistance: CGFloat = 56
            for (idx, pt) in vertices.enumerated() {
                let viewPt = viewport.toView(pt)
                let dist = hypot(startLocation.x - viewPt.x, startLocation.y - viewPt.y)
                if dist < bestDistance {
                    bestDistance = dist
                    bestIndex = idx
                }
            }
            draggingIndex = bestIndex
        }

        guard let activeIdx = draggingIndex else { return }
        let snapped = QuadrilateralClassifier.snap(viewport.toBoard(location), smallSteps: smallSteps)
        let tooCloseToOther = vertices.indices.contains { idx in
            idx != activeIdx && snapped.distance(to: vertices[idx]) < 0.35
        }
        guard !tooCloseToOther else { return }
        vertices[activeIdx] = snapped
        lastMovedVertex = Self.cornerNames[activeIdx]
    }

    // MARK: - Canvas Drawing

    private func drawQuadrilateral(
        in context: inout GraphicsContext,
        size: CGSize,
        props: QuadrilateralProperties
    ) {
        let viewport = BoardViewport(fitting: Self.extent, in: size, margin: 28)

        // Subtle 0.5-unit coordinate dots
        var gx = QuadrilateralClassifier.boardMin.x
        while gx <= QuadrilateralClassifier.boardMax.x + 1e-6 {
            var gy = QuadrilateralClassifier.boardMin.y
            while gy <= QuadrilateralClassifier.boardMax.y + 1e-6 {
                let pt = viewport.toView(Vec2(x: gx, y: gy))
                context.fill(BoardPaths.circle(pt, radius: 1.25), with: .color(MathsFigureColor.ink.opacity(0.16)))
                gy += 0.5
            }
            gx += 0.5
        }

        let corners = vertices.map(viewport.toView)

        // Shape wash
        let poly = BoardPaths.polygon(corners)
        let wash = props.isSimple ? ColorRole.amber.figureColor.opacity(0.16) : ColorRole.red.figureColor.opacity(0.12)
        context.fill(poly, with: .color(wash))

        // Diagonals overlay
        if showDiagonals {
            var diagPath = Path()
            diagPath.move(to: corners[0]); diagPath.addLine(to: corners[2])
            diagPath.move(to: corners[1]); diagPath.addLine(to: corners[3])
            context.stroke(
                diagPath,
                with: .color(ColorRole.blue.figureColor.opacity(0.7)),
                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
            )
            if props.diagonalsBisectEachOther {
                let mid = viewport.toView(0.5 * (vertices[0] + vertices[2]))
                context.fill(BoardPaths.circle(mid, radius: 4), with: .color(ColorRole.green.figureColor))
            }
            if props.diagonalsPerpendicular && props.isConvex,
               let inter = diagonalIntersection(corners[0], corners[2], corners[1], corners[3]) {
                drawRightAngleSquare(
                    in: &context,
                    vertex: inter,
                    prev: corners[0],
                    next: corners[1]
                )
            }
        }

        // Right-angle corner squares
        if showRightAngles, props.isConvex {
            for idx in props.rightAngleIndices {
                drawRightAngleSquare(
                    in: &context,
                    vertex: corners[idx],
                    prev: corners[(idx + 3) % 4],
                    next: corners[(idx + 1) % 4]
                )
            }
        }

        // Edges
        context.stroke(
            poly,
            with: .color(props.isSimple ? MathsFigureColor.ink : ColorRole.red.figureColor),
            style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round)
        )

        // Parallel chevrons
        if showParallel {
            for (pairIndex, pair) in props.parallelPairs.enumerated() {
                drawParallelChevrons(
                    in: &context,
                    from: corners[pair.firstEdge],
                    to: corners[(pair.firstEdge + 1) % 4],
                    count: pairIndex + 1
                )
                drawParallelChevrons(
                    in: &context,
                    from: corners[pair.secondEdge],
                    to: corners[(pair.secondEdge + 1) % 4],
                    count: pairIndex + 1
                )
            }
        }

        // Equal-side tick marks and edge length measurements
        if showEqualSides {
            for (groupIndex, group) in props.equalSideGroups.enumerated() {
                let tickCount = min(3, groupIndex + 1)
                for edgeIdx in group {
                    drawEqualTicks(
                        in: &context,
                        from: corners[edgeIdx],
                        to: corners[(edgeIdx + 1) % 4],
                        count: tickCount
                    )
                }
            }
            let centroid = CGPoint(
                x: corners.map(\.x).reduce(0, +) / 4.0,
                y: corners.map(\.y).reduce(0, +) / 4.0
            )
            for edgeIdx in 0..<4 {
                let a = corners[edgeIdx]
                let b = corners[(edgeIdx + 1) % 4]
                let mid = CGPoint(x: (a.x + b.x) * 0.5, y: (a.y + b.y) * 0.5)
                let dir = unitVector(from: a, to: b)
                var outward = CGPoint(x: -dir.y, y: dir.x)
                let toMidX = mid.x - centroid.x
                let toMidY = mid.y - centroid.y
                if outward.x * toMidX + outward.y * toMidY < 0 {
                    outward = CGPoint(x: -outward.x, y: -outward.y)
                }
                let pt = CGPoint(
                    x: mid.x - dir.x * 16 + outward.x * 20,
                    y: mid.y - dir.y * 16 + outward.y * 20
                )
                context.draw(
                    Text(String(format: "%.1f", props.sideLengths[edgeIdx]))
                        .font(MathsFigureType.labelMono)
                        .foregroundStyle(MathsFigureColor.ink),
                    at: pt
                )
            }
        }

        // Draggable vertices A, B, C, D
        for (idx, pt) in corners.enumerated() {
            let isDragging = draggingIndex == idx
            let ring = BoardPaths.circle(pt, radius: isDragging ? 15 : 13)
            context.fill(ring, with: .color(MathsFigureColor.pinCapsule))
            context.stroke(
                ring,
                with: .color(isDragging ? ColorRole.red.figureColor : MathsFigureColor.ink),
                lineWidth: isDragging ? 2.5 : 1.5
            )
            context.draw(
                Text(Self.cornerNames[idx]).font(MathsFigureType.label).foregroundStyle(MathsFigureColor.ink),
                at: pt
            )
        }
    }

    private func drawRightAngleSquare(
        in context: inout GraphicsContext,
        vertex: CGPoint,
        prev: CGPoint,
        next: CGPoint
    ) {
        let u = unitVector(from: vertex, to: prev)
        let v = unitVector(from: vertex, to: next)
        let r: CGFloat = 12
        let p1 = CGPoint(x: vertex.x + u.x * r, y: vertex.y + u.y * r)
        let p2 = CGPoint(x: p1.x + v.x * r, y: p1.y + v.y * r)
        let p3 = CGPoint(x: vertex.x + v.x * r, y: vertex.y + v.y * r)
        var path = Path()
        path.move(to: p1); path.addLine(to: p2); path.addLine(to: p3)
        context.stroke(path, with: .color(ColorRole.green.figureColor), lineWidth: 1.6)
    }

    private func drawParallelChevrons(
        in context: inout GraphicsContext,
        from a: CGPoint,
        to b: CGPoint,
        count: Int
    ) {
        let dir = unitVector(from: a, to: b)
        let norm = CGPoint(x: -dir.y, y: dir.x)
        let mid = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
        for i in 0..<count {
            let offset = (CGFloat(i) - CGFloat(count - 1) / 2.0) * 7.0
            let tip = CGPoint(x: mid.x + dir.x * (offset + 4), y: mid.y + dir.y * (offset + 4))
            let left = CGPoint(x: mid.x + dir.x * (offset - 4) + norm.x * 5, y: mid.y + dir.y * (offset - 4) + norm.y * 5)
            let right = CGPoint(x: mid.x + dir.x * (offset - 4) - norm.x * 5, y: mid.y + dir.y * (offset - 4) - norm.y * 5)
            var chevron = Path()
            chevron.move(to: left); chevron.addLine(to: tip); chevron.addLine(to: right)
            context.stroke(chevron, with: .color(ColorRole.blue.figureColor), lineWidth: 1.8)
        }
    }

    private func drawEqualTicks(
        in context: inout GraphicsContext,
        from a: CGPoint,
        to b: CGPoint,
        count: Int
    ) {
        let dir = unitVector(from: a, to: b)
        let norm = CGPoint(x: -dir.y, y: dir.x)
        let mid = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
        for i in 0..<count {
            let offset = (CGFloat(i) - CGFloat(count - 1) / 2.0) * 5.0 + 14.0
            let center = CGPoint(x: mid.x + dir.x * offset, y: mid.y + dir.y * offset)
            let p1 = CGPoint(x: center.x + norm.x * 6, y: center.y + norm.y * 6)
            let p2 = CGPoint(x: center.x - norm.x * 6, y: center.y - norm.y * 6)
            context.stroke(BoardPaths.line(p1, p2), with: .color(ColorRole.red.figureColor), lineWidth: 1.8)
        }
    }

    private func diagonalIntersection(
        _ p1: CGPoint,
        _ p2: CGPoint,
        _ p3: CGPoint,
        _ p4: CGPoint
    ) -> CGPoint? {
        let a1 = p2.y - p1.y
        let b1 = p1.x - p2.x
        let c1 = a1 * p1.x + b1 * p1.y
        let a2 = p4.y - p3.y
        let b2 = p3.x - p4.x
        let c2 = a2 * p3.x + b2 * p3.y
        let det = a1 * b2 - a2 * b1
        guard abs(det) > 1e-6 else { return nil }
        return CGPoint(x: (b2 * c1 - b1 * c2) / det, y: (a1 * c2 - a2 * c1) / det)
    }

    private func unitVector(from a: CGPoint, to b: CGPoint) -> CGPoint {
        let dx = b.x - a.x
        let dy = b.y - a.y
        let len = max(1e-6, hypot(dx, dy))
        return CGPoint(x: dx / len, y: dy / len)
    }
}
