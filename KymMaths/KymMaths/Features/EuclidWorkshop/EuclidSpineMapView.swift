import SwiftUI

/// Book I as a map: each proposition below the ones it stands on, with four lamps for what she
/// can do with it. Facts her school teaches sit in grey with their OUP section. Choosing a node
/// shows its paper check, which a parent ticks off.
struct EuclidSpineMapView: View {
    @Bindable var store: AppStore
    @State private var selected: PropositionID = "I.1"
    @State private var width: CGFloat = 0

    private static let detailWidth: CGFloat = 340
    private static let mapWidth: CGFloat = 700

    var body: some View {
        JournalPage(title: "", column: .calendar) {
            EditorialHeader(
                eyebrow: "Euclid's Workshop · Book I",
                title: "From one triangle to Pythagoras",
                subtitle: "Every proposition stands on the ones above it. Build one and it becomes a tool for the next."
            )
            Group {
                if width >= Self.mapWidth + Spacing.md + Self.detailWidth {
                    HStack(alignment: .top, spacing: Spacing.md) {
                        mapCard.frame(maxWidth: .infinity)
                        detail.frame(width: Self.detailWidth)
                    }
                } else {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        mapCard
                        detail
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        }
        .onAppear {
            #if DEBUG
            if let id = UserDefaults.standard.string(forKey: "EuclidSelect") { selected = PropositionID(id) }
            #endif
        }
    }

    private var mapCard: some View {
        JournalCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                legend
                map.padding(.vertical, Spacing.xs)
            }
        }
    }

    private var map: some View {
        VStack(spacing: 34) {
            ForEach(Array(EuclidSpineLayout.rows().enumerated()), id: \.offset) { _, row in
                HStack(alignment: .top, spacing: Spacing.xs) {
                    ForEach(row, id: \.self) { id in
                        if let proposition = EuclidSpine.proposition(id) {
                            SpineNode(proposition: proposition, record: store.euclidProgress.record(for: id),
                                      isSelected: selected == id) { selected = id }
                                .anchorPreference(key: SpineNodeAnchors.self, value: .bounds) { [id: $0] }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .backgroundPreferenceValue(SpineNodeAnchors.self) { anchors in
            GeometryReader { proxy in
                ForEach(Array(EuclidSpineLayout.edges().enumerated()), id: \.offset) { _, edge in
                    if let from = anchors[edge.from], let to = anchors[edge.to] {
                        let (a, b) = (proxy[from], proxy[to])
                        let accepted = EuclidSpine.proposition(edge.from).map { if case .accepted = $0.kind { true } else { false } } ?? false
                        SpineEdge(from: CGPoint(x: a.midX, y: a.maxY), to: CGPoint(x: b.midX, y: b.minY))
                            .stroke(Color.kymaiaMutedInk.opacity(accepted ? 0.35 : 0.7),
                                    style: StrokeStyle(lineWidth: accepted ? 1 : 1.6, dash: accepted ? [3, 4] : []))
                    }
                }
            }
        }
    }

    private var legend: some View {
        FlowLayout(spacing: Spacing.sm) {
            ForEach(SkillLevel.allCases, id: \.self) { level in
                HStack(spacing: Spacing.xxs) {
                    LampDot(isLit: true)
                    Text(level.title).font(Typography.caption).foregroundStyle(Color.kymaiaMutedInk)
                }
            }
            HStack(spacing: Spacing.xxs) {
                Image(systemName: "hand.raised.fill").foregroundStyle(Color.kymaiaWarning)
                Text("last try had help").font(Typography.caption).foregroundStyle(Color.kymaiaMutedInk)
            }
            HStack(spacing: Spacing.xxs) {
                Image(systemName: "checkmark.seal.fill").foregroundStyle(Color.kymaiaSuccess)
                Text("checked on paper").font(Typography.caption).foregroundStyle(Color.kymaiaMutedInk)
            }
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detail: some View {
        if let proposition = EuclidSpine.proposition(selected) {
            let record = store.euclidProgress.record(for: selected)
            JournalCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(proposition.id.raw.uppercased() + (proposition.isAccepted ? " · FROM SCHOOL" : ""))
                        .font(Typography.eyebrow)
                        .foregroundStyle(Color.kymaiaPrimary)
                    Text(proposition.title)
                        .font(Typography.title3)
                        .foregroundStyle(Color.kymaiaInk)
                    Text(proposition.statement)
                        .font(Typography.body)
                        .foregroundStyle(Color.kymaiaInk)
                        .fixedSize(horizontal: false, vertical: true)
                    if case let .accepted(taughtIn) = proposition.kind {
                        Text("Euclid proves this too. Here it is taken as known: school teaches it in \(taughtIn).")
                            .font(Typography.caption)
                            .foregroundStyle(Color.kymaiaMutedInk)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        lamps(record)
                        actions(for: proposition, record: record)
                    }
                    if !proposition.uses.isEmpty {
                        Text("Stands on " + proposition.uses.map(\.raw).joined(separator: ", "))
                            .font(Typography.caption)
                            .foregroundStyle(Color.kymaiaMutedInk)
                    }
                    PaperCheckCard(check: proposition.deviceOffCheck, isChecked: record.parentChecked) {
                        store.euclidProgress.setParentChecked(!record.parentChecked, for: selected)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func lamps(_ record: EuclidSkillRecord) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            ForEach(SkillLevel.allCases, id: \.self) { level in
                HStack(spacing: Spacing.xs) {
                    let lit = record.highest.map { $0 >= level } ?? false
                    LampDot(isLit: lit)
                    Text(level.title)
                        .font(Typography.caption.weight(lit ? .semibold : .regular))
                        .foregroundStyle(lit ? Color.kymaiaInk : Color.kymaiaMutedInk)
                }
            }
            if record.assisted {
                JournalBadge(text: "Last try had help, so it didn't count", symbol: "hand.raised.fill", tone: .warning)
            }
        }
    }

    @ViewBuilder
    private func actions(for proposition: EuclidProposition, record: EuclidSkillRecord) -> some View {
        FlowLayout(spacing: Spacing.xs) {
            Button {
                store.euclidRoute = .board(proposition.id)
            } label: {
                Label(record.highest == nil ? "Build it" : "Build it again", systemImage: "compass.drawing")
            }
            .buttonStyle(JournalSecondaryButtonStyle())
            if let highest = record.highest, highest >= .letters {
                Button {
                    store.euclidRoute = .stepOrder(proposition.id)
                } label: {
                    Label("Steps in order", systemImage: "list.number")
                }
                .buttonStyle(JournalSecondaryButtonStyle())
            }
        }
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

private struct LampDot: View {
    let isLit: Bool

    var body: some View {
        Circle()
            .fill(isLit ? Color.kymaiaPrimary : Color.clear)
            .overlay(Circle().strokeBorder(isLit ? Color.kymaiaPrimary : Color.kymaiaMutedInk.opacity(0.6), lineWidth: 1.2))
            .frame(width: 9, height: 9)
    }
}

/// One proposition on the map.
private struct SpineNode: View {
    let proposition: EuclidProposition
    let record: EuclidSkillRecord
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            if proposition.isAccepted { accepted } else { built }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibility)
    }

    private var built: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(spacing: Spacing.xxs) {
                Text(proposition.id.raw)
                    .font(Typography.headline)
                    .foregroundStyle(Color.kymaiaInk)
                Spacer(minLength: 0)
                if record.assisted {
                    Image(systemName: "hand.raised.fill").foregroundStyle(Color.kymaiaWarning).font(Typography.caption)
                }
                if record.parentChecked {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(Color.kymaiaSuccess).font(Typography.caption)
                }
            }
            Text(proposition.title)
                .font(Typography.caption)
                .foregroundStyle(Color.kymaiaMutedInk)
                .lineLimit(2, reservesSpace: true)
            HStack(spacing: 4) {
                ForEach(SkillLevel.allCases, id: \.self) { level in
                    LampDot(isLit: record.highest.map { $0 >= level } ?? false)
                }
            }
        }
        .padding(Spacing.xs)
        .frame(width: 124, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                .fill(isSelected ? Color.kymaiaSelectionFill : Color.kymaiaElevatedSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                .strokeBorder(isSelected ? Color.kymaiaPrimary : Color.kymaiaHairline, lineWidth: isSelected ? 2 : 1)
        )
    }

    private var accepted: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(proposition.id.raw)
                .font(Typography.subheadline.weight(.semibold))
                .foregroundStyle(Color.kymaiaMutedInk)
            Text(proposition.oupSection ?? "School")
                .font(Typography.caption)
                .foregroundStyle(Color.kymaiaMutedInk)
        }
        .padding(Spacing.xs)
        .frame(width: 84, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                .fill(isSelected ? Color.kymaiaSelectionFill : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                .strokeBorder(isSelected ? Color.kymaiaPrimary : Color.kymaiaMutedInk.opacity(0.4),
                              style: StrokeStyle(lineWidth: isSelected ? 2 : 1, dash: isSelected ? [] : [4, 3]))
        )
    }

    private var accessibility: String {
        if proposition.isAccepted {
            return "\(proposition.id), \(proposition.title), taught at school in \(proposition.oupSection ?? "school")"
        }
        let lit = record.highest.map { "highest lamp \($0.title)" } ?? "no lamps lit"
        return "\(proposition.id), \(proposition.title), \(lit)" + (record.assisted ? ", last try had help" : "")
    }
}

/// The task done with a real compass and the answer a parent checks. Only a parent's tap marks it.
struct PaperCheckCard: View {
    let check: DeviceOffCheck
    let isChecked: Bool
    let onToggle: () -> Void
    @State private var showsAnswer = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Label("Device off", systemImage: "pencil.and.ruler")
                .font(Typography.caption.weight(.semibold))
                .foregroundStyle(Color.kymaiaPrimary)
            Text(check.task)
                .font(Typography.body)
                .foregroundStyle(Color.kymaiaInk)
                .fixedSize(horizontal: false, vertical: true)
            if showsAnswer {
                Text("For the grown-up: " + check.answer)
                    .font(Typography.caption)
                    .foregroundStyle(Color.kymaiaMutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
            FlowLayout(spacing: Spacing.xs) {
                Button(showsAnswer ? "Hide the answer" : "Show the answer") { showsAnswer.toggle() }
                    .buttonStyle(JournalSecondaryButtonStyle())
                Button(action: onToggle) {
                    Label(isChecked ? "Checked on paper" : "Mark checked on paper",
                          systemImage: isChecked ? "checkmark.seal.fill" : "seal")
                }
                .buttonStyle(JournalSecondaryButtonStyle())
                .accessibilityHint("For a parent, once the paper version is right")
            }
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .quietPanelBackground()
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
