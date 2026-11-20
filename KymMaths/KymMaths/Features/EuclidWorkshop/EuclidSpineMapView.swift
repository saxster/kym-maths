import SwiftUI

/// Book I as a map: each proposition below the ones it stands on, with four lamps for what she
/// can do with it. Facts her school teaches sit in dashed boxes with their school section.
/// Choosing a node shows it beside the map, with its paper check, which a parent ticks off.
struct EuclidSpineMapView: View {
    @Environment(\.standardTheme) private var theme
    @Bindable var store: AppStore
    @State private var width: CGFloat = 0
    @State private var mapWidth: CGFloat = 0
    /// Counts taps on nodes. When the detail sits under the map (iPhone), each tap scrolls to it,
    /// even a tap on the node already selected, or the tap would change nothing on screen.
    @State private var detailRequests = 0

    private var selected: PropositionID { store.euclidMapSelection }
    private var isStacked: Bool { width < Self.sideBySide }
    private static let detailAnchor = "euclid-map-detail"

    private static let detailWidth: CGFloat = 320
    private static let sideBySide: CGFloat = 560 + StandardSpacing.lg + detailWidth
    static let nodeGap: CGFloat = StandardSpacing.sm
    static let nodeMinWidth: CGFloat = 132

    var body: some View {
        ScrollViewReader { scroller in
            EuclidPage(
                eyebrow: "Euclid's Workshop · Book I",
                title: "From one triangle to Pythagoras",
                subtitle: "Every proposition stands on the ones above it. Build one and it becomes a tool for the next."
            ) {
                Group {
                    if isStacked {
                        VStack(alignment: .leading, spacing: StandardSpacing.lg) {
                            mapCard
                            detail.id(Self.detailAnchor)
                        }
                    } else {
                        HStack(alignment: .top, spacing: StandardSpacing.lg) {
                            mapCard.frame(maxWidth: .infinity)
                            detail.frame(width: Self.detailWidth)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .readWidth($width)
                MotifsStrip(store: store)
                QuadrilateralLabStrip(store: store)
            }
            .onChange(of: detailRequests) {
                guard isStacked else { return }
                withAnimation { scroller.scrollTo(Self.detailAnchor, anchor: .top) }
            }
        }
        .onAppear {
            #if DEBUG
            if let id = UserDefaults.standard.string(forKey: "EuclidSelect") { store.euclidMapSelection = PropositionID(id) }
            #endif
        }
    }

    // MARK: - Map

    private var mapCard: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.md) {
            legend
            map
                .frame(maxWidth: .infinity)
                .readWidth($mapWidth)
        }
        .paperCard()
    }

    private var nodeLayout: (perRow: Int, width: CGFloat) { Self.nodeLayout(mapWidth: mapWidth) }

    /// How many nodes fit across a map this wide, and how wide each is. The width is rounded down so a
    /// full row is never wider than the map: a row a hair too wide widened the map, which changed the
    /// width, forever.
    static func nodeLayout(mapWidth: CGFloat) -> (perRow: Int, width: CGFloat) {
        let available = max(mapWidth, nodeMinWidth * 2 + nodeGap)
        let perRow = max(2, Int((available + nodeGap) / (nodeMinWidth + nodeGap)))
        let width = min(176, ((available - nodeGap * CGFloat(perRow - 1)) / CGFloat(perRow)).rounded(.down))
        return (perRow, width)
    }

    /// How wide a full row of nodes is, gaps included.
    static func rowWidth(_ layout: (perRow: Int, width: CGFloat)) -> CGFloat {
        layout.width * CGFloat(layout.perRow) + nodeGap * CGFloat(layout.perRow - 1)
    }

    /// The layout's rows, each split evenly into lines that fit: six becomes three and three.
    private var lines: [[PropositionID]] {
        let perRow = nodeLayout.perRow
        return EuclidSpineLayout.rows().flatMap { row -> [[PropositionID]] in
            guard row.count > perRow else { return [row] }
            let count = (row.count + perRow - 1) / perRow
            let size = (row.count + count - 1) / count
            return stride(from: 0, to: row.count, by: size).map { Array(row[$0..<min($0 + size, row.count)]) }
        }
    }

    private var map: some View {
        let nodeWidth = nodeLayout.width
        return VStack(spacing: 30) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                HStack(alignment: .top, spacing: Self.nodeGap) {
                    ForEach(line, id: \.self) { id in
                        if let proposition = EuclidSpine.proposition(id) {
                            SpineNode(proposition: proposition, record: store.euclidProgress.record(for: id),
                                      needs: EuclidSpine.needs(id, progress: store.euclidProgress),
                                      isSelected: selected == id, width: nodeWidth) {
                                store.euclidMapSelection = id
                                detailRequests += 1
                            }
                                .anchorPreference(key: SpineNodeAnchors.self, value: .bounds) { [id: $0] }
                        }
                    }
                }
            }
        }
        .padding(.vertical, StandardSpacing.xs)
        .backgroundPreferenceValue(SpineNodeAnchors.self) { anchors in
            GeometryReader { proxy in
                ForEach(Array(EuclidSpineLayout.edges().enumerated()), id: \.offset) { _, edge in
                    if let from = anchors[edge.from], let to = anchors[edge.to] {
                        let (a, b) = (proxy[from], proxy[to])
                        let touchesSelected = edge.from == selected || edge.to == selected
                        SpineEdge(from: CGPoint(x: a.midX, y: a.maxY), to: CGPoint(x: b.midX, y: b.minY))
                            .stroke(touchesSelected ? theme.brass : theme.hairline(),
                                    lineWidth: touchesSelected ? 1.6 : 1)
                    }
                }
            }
        }
    }

    private var legend: some View {
        FlowLayout(spacing: StandardSpacing.md) {
            HStack(spacing: StandardSpacing.xs) {
                RoundedRectangle(cornerRadius: StandardRadius.sm).strokeBorder(theme.ink, lineWidth: 1).frame(width: 16, height: 11)
                Text("You build it")
            }
            HStack(spacing: StandardSpacing.xs) {
                RoundedRectangle(cornerRadius: StandardRadius.sm)
                    .strokeBorder(theme.mute(theme.ink), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                    .frame(width: 16, height: 11)
                Text("Known from school, never locked")
            }
            HStack(spacing: StandardSpacing.xs) {
                Image(systemName: "checkmark.seal.fill").foregroundStyle(theme.patterned.provenColor)
                Text("Checked on paper")
            }
        }
        .standardType(.uiCaption)
        .foregroundStyle(theme.mute(theme.ink))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Detail

    @ViewBuilder
    private var detail: some View {
        if let proposition = EuclidSpine.proposition(selected) {
            let record = store.euclidProgress.record(for: selected)
            let needs = EuclidSpine.needs(selected, progress: store.euclidProgress)
            VStack(alignment: .leading, spacing: StandardSpacing.md) {
                Kicker("Selected")
                HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.sm) {
                    PropositionCode(id: proposition.id, size: 28)
                    Text(proposition.title)
                        .standardType(.headlineMd)
                        .foregroundStyle(theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !proposition.isAccepted {
                    SolvedFigure(id: proposition.id, progress: store.euclidProgress)
                        .frame(height: 150)
                }
                Text(proposition.statement)
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if case let .accepted(taughtIn) = proposition.kind {
                    EuclidRuledNote(text: "Euclid proves this too. Here it is taken as known: school teaches it in \(taughtIn).")
                }
                Rectangle().fill(theme.hairline()).frame(height: 1)
                if !proposition.uses.isEmpty {
                    links("Stands on", proposition.uses)
                }
                if !proposition.unlocks.isEmpty {
                    links("Unlocks", proposition.unlocks)
                }
                if !proposition.isAccepted {
                    lamps(record)
                    if needs.isEmpty {
                        actions(for: proposition, record: record)
                    } else {
                        LockedNote(Self.needsText(needs) + ". Build it there, then come back.")
                    }
                }
                Rectangle().fill(theme.hairline()).frame(height: 1)
                PaperCheckCard(check: proposition.deviceOffCheck, isChecked: record.parentChecked) {
                    store.euclidProgress.setParentChecked(!record.parentChecked, for: selected)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .paperCard()
        }
    }

    private func links(_ title: String, _ ids: [PropositionID]) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
            Kicker(title, muted: true)
            ForEach(ids, id: \.self) { id in
                if let linked = EuclidSpine.proposition(id) {
                    Button {
                        store.euclidMapSelection = id
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.sm) {
                            PropositionCode(id: id, size: 18)
                            Text(linked.title)
                                .standardType(.uiBody)
                                .foregroundStyle(theme.ink)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: StandardSpacing.xs)
                            if linked.isAccepted {
                                Text("From school")
                                    .standardType(.uiCaption)
                                    .foregroundStyle(theme.mute(theme.ink))
                            } else {
                                StatusTag(linked.learningStatus(store.euclidProgress))
                            }
                        }
                        .frame(minHeight: StandardAccessibility.touchTarget)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Shows \(id.raw) on the map")
                }
            }
        }
    }

    private func lamps(_ record: EuclidSkillRecord) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            HStack(spacing: StandardSpacing.sm) {
                SkillLamps(lit: record.litLamps)
                Text("\(record.litLamps) of 4 lamps lit")
                    .standardType(.uiCaption)
                    .foregroundStyle(theme.mute(theme.ink))
            }
            if record.assisted {
                StatusTag(.withHelp, label: "Last try had help, so it didn't count")
            }
        }
    }

    @ViewBuilder
    private func actions(for proposition: EuclidProposition, record: EuclidSkillRecord) -> some View {
        VStack(spacing: StandardSpacing.sm) {
            Button {
                store.euclidRoute = .board(proposition.id)
            } label: {
                Label(record.highest == nil ? "Build it" : "Build it again", systemImage: "arrow.right")
                    .labelStyle(TrailingIconLabelStyle())
            }
            .buttonStyle(InkButtonStyle(fullWidth: true))
            if let highest = record.highest, highest >= .letters {
                Button {
                    store.euclidRoute = .stepOrder(proposition.id)
                } label: {
                    Label("Put the steps in order", systemImage: "list.number")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(OutlineButtonStyle())
            }
        }
    }
}

extension EuclidSpineMapView {
    /// "Needs I.9 first", or "Needs I.46 and I.10 first".
    static func needsText(_ needs: [PropositionID]) -> String {
        let names = needs.map(\.raw)
        let list = names.count > 1 ? names.dropLast().joined(separator: ", ") + " and " + names.last! : names.joined()
        return "Needs \(list) first"
    }
}

private struct SpineNodeAnchors: PreferenceKey {
    static var defaultValue: [PropositionID: Anchor<CGRect>] { [:] }
    static func reduce(value: inout [PropositionID: Anchor<CGRect>], nextValue: () -> [PropositionID: Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
}

/// A gentle S-curve from the bottom of one node to the top of the next.
private struct SpineEdge: Shape {
    let from: CGPoint
    let to: CGPoint

    func path(in _: CGRect) -> Path {
        var path = Path()
        path.move(to: from)
        let middle = (from.y + to.y) / 2
        path.addCurve(to: to, control1: CGPoint(x: from.x, y: middle), control2: CGPoint(x: to.x, y: middle))
        return path
    }
}

/// The finished construction, small and still, for the selected proposition.
private struct SolvedFigure: View {
    let id: PropositionID
    let progress: EuclidProgress
    @State private var session: EuclidWorkshopSession?

    var body: some View {
        Group {
            if let session {
                EuclidBoardCanvas(session: session, framed: false) { _, _ in }
                    .allowsHitTesting(false)
                    .accessibilityLabel("The finished figure for \(id.raw)")
            } else {
                Color.clear
            }
        }
        .onAppear(perform: build)
        .onChange(of: id) { _, _ in build() }
    }

    private func build() {
        guard let proposition = EuclidSpine.proposition(id) else { session = nil; return }
        var figure = EuclidWorkshopSession(proposition: proposition,
                                           tools: EuclidWorkshopSession.tools(for: id, progress: progress))
        figure?.playScript(moves: .max)
        session = figure
    }
}

/// One proposition on the map.
private struct SpineNode: View {
    @Environment(\.standardTheme) private var theme
    let proposition: EuclidProposition
    let record: EuclidSkillRecord
    /// What must be proven before this one opens.
    let needs: [PropositionID]
    let isSelected: Bool
    let width: CGFloat
    let onSelect: () -> Void

    private var isLocked: Bool { !needs.isEmpty }

    var body: some View {
        Button(action: onSelect) {
            Group {
                if proposition.isAccepted { accepted } else { built }
            }
            .frame(width: width, alignment: .leading)
            .frame(minHeight: 88, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                    .strokeBorder(stroke, style: StrokeStyle(lineWidth: isSelected ? 1.5 : 1,
                                                             dash: proposition.isAccepted && !isSelected ? [4, 3] : []))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibility)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var fill: Color {
        if isSelected { return theme.patterned.wash(.stays) }
        if proposition.isAccepted { return theme.patterned.sunkColor }
        return isLocked ? .clear : theme.surface
    }

    private var stroke: Color {
        if isSelected { return theme.brass }
        if proposition.isAccepted { return theme.faint(theme.ink) }
        if isLocked { return theme.hairline() }
        return record.highest != nil ? theme.patterned.provenColor : theme.ink
    }

    private var built: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
            HStack(alignment: .center, spacing: StandardSpacing.xxs) {
                PropositionCode(id: proposition.id, size: 20, faded: isLocked)
                Spacer(minLength: 0)
                if isLocked {
                    Image(systemName: "lock")
                        .imageScale(.small)
                        .foregroundStyle(theme.mute(theme.ink))
                } else {
                    SkillLamps(lit: record.litLamps, size: 8)
                }
                if record.parentChecked {
                    Image(systemName: "checkmark.seal.fill")
                        .imageScale(.small)
                        .foregroundStyle(theme.patterned.provenColor)
                }
            }
            Text(proposition.title)
                .standardType(.uiBody)
                .foregroundStyle(isLocked ? theme.mute(theme.ink) : theme.ink)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text(statusLine)
                .standardType(.uiCaption)
                .foregroundStyle(statusColor)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(StandardSpacing.sm)
    }

    private var statusLine: String {
        if isLocked { return EuclidSpineMapView.needsText(needs) }
        if record.assisted { return "Last try had help" }
        switch record.highest {
        case .knowsWhen?: return "Secure"
        case _?: return "Proven"
        case nil: return "Ready to build"
        }
    }

    private var statusColor: Color {
        if isLocked { return theme.mute(theme.ink) }
        if record.assisted { return theme.patterned.assistedColor }
        return record.highest != nil ? theme.patterned.provenColor : theme.brass
    }

    private var accepted: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
            HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.xs) {
                PropositionCode(id: proposition.id, size: 20, faded: true)
                if let section = proposition.schoolSection {
                    Kicker(section, muted: true)
                        .lineLimit(1)
                }
            }
            Text(proposition.title)
                .standardType(.uiBody)
                .foregroundStyle(theme.mute(theme.ink))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(StandardSpacing.sm)
    }

    private var accessibility: String {
        if proposition.isAccepted {
            return "\(proposition.id), \(proposition.title), taught at school in \(proposition.oupSection ?? "school")"
        }
        if isLocked {
            return "\(proposition.id), \(proposition.title), locked. \(EuclidSpineMapView.needsText(needs))"
        }
        let lit = record.highest.map { "highest lamp \($0.lampName)" } ?? "no lamps lit"
        return "\(proposition.id), \(proposition.title), \(lit)" + (record.assisted ? ", last try had help" : "")
    }
}

/// The motifs: figures exam questions reuse, each with a small drawing and where she stands.
private struct MotifsStrip: View {
    @Environment(\.standardTheme) private var theme
    @Bindable var store: AppStore

    private var motifs: [Motif] { MotifSpine.catalog.filter { $0.layer == .motif } }

    var body: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            FlowLayout(spacing: StandardSpacing.sm) {
                Kicker("Motifs")
                Text("Figures exam questions use again and again. Spot one and the helper line comes next.")
                    .standardType(.uiCaption)
                    .foregroundStyle(theme.mute(theme.ink))
                    .fixedSize(horizontal: false, vertical: true)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: StandardSpacing.sm)],
                      alignment: .leading, spacing: StandardSpacing.sm) {
                ForEach(motifs, id: \.id) { motif in
                    if MotifSpine.playable.contains(motif.id) {
                        Button {
                            store.openEuclid(.motif(motif.id))
                        } label: {
                            card(motif)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Opens \(motif.title)")
                    } else {
                        card(motif)
                    }
                }
            }
        }
        .padding(.top, StandardSpacing.sm)
    }

    private func card(_ motif: Motif) -> some View {
        let record = store.motifProgress.record(for: motif.id)
        let isPlayable = MotifSpine.playable.contains(motif.id)
        return VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            MotifThumbnail(scene: motif.scene)
                .frame(width: 76, height: 46)
                .opacity(isPlayable ? 1 : 0.5)
            HStack(spacing: StandardSpacing.xxs) {
                Text("\(motif.id.raw) · \(motif.title)")
                    .standardType(.uiHeadline)
                    .foregroundStyle(isPlayable ? theme.ink : theme.mute(theme.ink))
                    .lineLimit(2)
                if record.parentChecked {
                    Image(systemName: "checkmark.seal.fill")
                        .imageScale(.small)
                        .foregroundStyle(theme.patterned.provenColor)
                        .accessibilityLabel("Checked on paper")
                }
            }
            status(record, isPlayable: isPlayable)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .paperCard(padding: StandardSpacing.md)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func status(_ record: MotifRecord, isPlayable: Bool) -> some View {
        if record.solved {
            StatusTag(.proven)
        } else if record.assisted {
            StatusTag(.withHelp)
        } else if isPlayable {
            StatusTag(.notStarted)
        } else {
            StatusTag(.locked, label: "Coming next")
        }
    }
}

/// Interactive PhET-inspired quadrilateral hierarchy lab entry below the motifs shelf.
private struct QuadrilateralLabStrip: View {
    @Environment(\.standardTheme) private var theme
    @Bindable var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            FlowLayout(spacing: StandardSpacing.sm) {
                Kicker("Shape family")
                Text("Drag any corner to test which properties hold and which family names still fit.")
                    .standardType(.uiCaption)
                    .foregroundStyle(theme.mute(theme.ink))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button {
                store.openEuclid(.quadrilateral)
            } label: {
                HStack(alignment: .center, spacing: StandardSpacing.md) {
                    QuadrilateralThumbnail()
                        .frame(width: 76, height: 48)
                    VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                        Text("Quadrilateral family")
                            .standardType(.uiHeadline)
                            .foregroundStyle(theme.ink)
                        Text("Drag corners A–D to see why every square is also a rectangle, rhombus, parallelogram and kite.")
                            .standardType(.uiCaption)
                            .foregroundStyle(theme.mute(theme.ink))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: StandardSpacing.xs)
                    Image(systemName: "arrow.right")
                        .foregroundStyle(theme.mute(theme.ink))
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .paperCard(padding: StandardSpacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens the interactive quadrilateral family explorer")
        }
        .padding(.top, StandardSpacing.xs)
    }
}

private struct QuadrilateralThumbnail: View {
    @Environment(\.standardTheme) private var theme

    var body: some View {
        Canvas { context, size in
            let pts = [
                CGPoint(x: size.width * 0.22, y: size.height * 0.20),
                CGPoint(x: size.width * 0.82, y: size.height * 0.24),
                CGPoint(x: size.width * 0.72, y: size.height * 0.82),
                CGPoint(x: size.width * 0.14, y: size.height * 0.78),
            ]
            let poly = BoardPaths.polygon(pts)
            context.fill(poly, with: .color(theme.patterned.wash(.stays)))
            context.stroke(poly, with: .color(theme.ink), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            for pt in pts {
                context.fill(BoardPaths.circle(pt, radius: 2.5), with: .color(theme.patterned.color(.moves)))
            }
        }
        .accessibilityHidden(true)
    }
}

/// A motif's lines in small, the way the figure first appears.
private struct MotifThumbnail: View {
    @Environment(\.standardTheme) private var theme
    let scene: MotifScene

    var body: some View {
        Canvas { context, size in
            let figure = scene.build(scene.state)
            let viewport = BoardViewport(fitting: scene.extent, in: size, margin: 3)
            for segment in figure.segments {
                guard let a = figure.points[segment[0]], let b = figure.points[segment[1]] else { continue }
                context.stroke(BoardPaths.line(viewport.toView(a), viewport.toView(b)), with: .color(theme.ink),
                               style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            }
        }
        .accessibilityHidden(true)
    }
}

/// The task done with a real compass and the answer a parent checks. Only a parent's tap marks it.
struct PaperCheckCard: View {
    @Environment(\.standardTheme) private var theme
    let check: DeviceOffCheck
    let isChecked: Bool
    let onToggle: () -> Void
    @State private var showsAnswer = false

    var body: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            HStack(spacing: StandardSpacing.xs) {
                Image(systemName: "pencil.and.ruler")
                    .foregroundStyle(theme.brass)
                    .accessibilityHidden(true)
                Kicker("Device off")
                Spacer(minLength: StandardSpacing.xs)
                if isChecked {
                    StatusTag(.proven, label: "Checked on paper")
                }
            }
            Text(check.task)
                .patternedType(.readingDefault)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            if showsAnswer {
                Text("For the grown-up: " + check.answer)
                    .standardType(.uiCaption)
                    .foregroundStyle(theme.mute(theme.ink))
                    .fixedSize(horizontal: false, vertical: true)
            }
            FlowLayout(spacing: StandardSpacing.md) {
                Button(showsAnswer ? "Hide the answer" : "Show the answer") { showsAnswer.toggle() }
                    .buttonStyle(TextLinkButtonStyle(arrow: false))
                Button(action: onToggle) {
                    Label(isChecked ? "Undo the paper check" : "Mark checked on paper",
                          systemImage: isChecked ? "arrow.uturn.backward" : "checkmark.seal")
                }
                .buttonStyle(OutlineButtonStyle())
                .accessibilityHint("For a parent, once the paper version is right")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension EuclidProposition {
    var isAccepted: Bool {
        if case .accepted = kind { true } else { false }
    }

    /// "OUP 3.4" from "OUP 3.4 Constructions (ch09)".
    var oupSection: String? {
        guard case let .accepted(taughtIn) = kind else { return nil }
        let words = taughtIn.split(separator: " ")
        guard words.count >= 2, words[0] == "OUP" else { return nil }
        return "OUP \(words[1])"
    }
}
