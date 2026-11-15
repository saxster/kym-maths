import SwiftUI

// MARK: - Atlas: one lab per idea, and a picture to recall from memory

/// The Atlas room. Its lab page lists every lab by chapter beside the open lab; its recall page
/// (`AtlasRecallView`) asks the reader to name a picture's parts. `widget/<id>/recall` opens the
/// recall page, and `widget/<id>/recall/<plate-id>` opens it on that picture.
struct LabsAtlasHomeView: View {
    @Bindable var store: AppStore
    @Environment(\.standardTheme) private var theme

    @State private var mode: AtlasRoomMode = .lab
    @State private var labStep: AtlasLabStep = .look
    @State private var challengeNote: String = ""
    @State private var showEmbeddedWebStage: Bool = true

    var body: some View {
        JournalPage {
            switch mode {
            case .lab:
                labPage
            case .recall:
                AtlasRecallView(store: store) { mode = .lab }
            }
        }
        .onAppear(perform: readDeepLinkTail)
        .onChange(of: store.deepLinkTail) { _, _ in readDeepLinkTail() }
        .onChange(of: store.selectedWidgetId) { _, _ in
            labStep = .look
            challengeNote = ""
        }
    }

    private func readDeepLinkTail() {
        guard store.activeRoom == .labsAtlas, store.deepLinkTail.first == "recall" else { return }
        if store.deepLinkTail.count > 1 {
            store.selectedDiagramPlateId = store.deepLinkTail[1]
        }
        mode = .recall
        store.deepLinkTail = []
    }

    // MARK: Lab page

    private var labPage: some View {
        let widget = store.selectedWidget
        return VStack(alignment: .leading, spacing: StandardSpacing.lg) {
            RoomHeaderRow(
                eyebrow: "Atlas · Chapter \(widget.chapter) lab",
                title: AtlasCopy.title(widget),
                subtitle: chapter(widget.chapter)?.hookSummary ?? "",
                switchTitle: "Recall a picture",
                switchSymbol: "eye.slash"
            ) { mode = .recall }

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: StandardSpacing.lg) {
                    labIndex
                        .frame(width: 200)
                    labCard(widget)
                        .frame(minWidth: 460, idealWidth: 460, maxWidth: .infinity, alignment: .leading)
                }
                VStack(alignment: .leading, spacing: StandardSpacing.md) {
                    labMenu(widget)
                    labCard(widget)
                }
            }
        }
    }

    private var chapterGroups: [AtlasChapterGroup] {
        var groups: [AtlasChapterGroup] = []
        for w in store.seedPack.widgets {
            if let last = groups.indices.last, groups[last].number == w.chapter {
                groups[last].widgets.append(w)
            } else {
                let title = chapter(w.chapter).map { RoomCopy.shortChapterTitle($0.title) } ?? ""
                groups.append(AtlasChapterGroup(number: w.chapter, title: title, widgets: [w]))
            }
        }
        return groups
    }

    private func chapter(_ number: Int) -> PatternedWorldChapter? {
        store.seedPack.chapters.first(where: { $0.number == number })
    }

    /// Every lab, grouped by chapter, beside the open one. It scrolls on its own so the open lab
    /// stays in view.
    private var labIndex: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                    ForEach(chapterGroups) { group in
                        Kicker("Ch \(group.number) · \(group.title)", muted: true)
                            .lineLimit(1)
                            .padding(.horizontal, StandardSpacing.sm)
                            .padding(.top, StandardSpacing.md)
                            .padding(.bottom, StandardSpacing.xxs)
                        ForEach(group.widgets) { w in
                            labRow(w).id(w.id)
                        }
                    }
                }
                .padding(.bottom, StandardSpacing.md)
            }
            .onAppear { proxy.scrollTo(store.selectedWidgetId, anchor: .center) }
        }
        .frame(height: 780)
    }

    private func labRow(_ w: InteractiveWidgetSpec) -> some View {
        let isOpen = w.id == store.selectedWidgetId
        let (status, label) = labStatus(w)
        return Button {
            store.selectedWidgetId = w.id
        } label: {
            VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                Text(AtlasCopy.title(w))
                    .standardType(isOpen ? .uiHeadline : .uiBody)
                    .foregroundStyle(theme.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                StatusTag(status, label: label)
            }
            .padding(.horizontal, StandardSpacing.sm)
            .padding(.vertical, StandardSpacing.xs + 2)
            .frame(maxWidth: .infinity, minHeight: StandardAccessibility.touchTarget, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                    .fill(isOpen ? theme.surface : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                    .strokeBorder(isOpen ? theme.hairline() : Color.clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOpen ? .isSelected : [])
    }

    private func labStatus(_ w: InteractiveWidgetSpec) -> (LearningStatus, String?) {
        if store.widgetStampsById[w.id] != nil { return (.proven, "Stamp earned") }
        if w.id == store.selectedWidgetId { return (.working, "Open now") }
        return (.notStarted, nil)
    }

    /// The lab list as a menu, for widths too narrow for a column beside the lab.
    private func labMenu(_ widget: InteractiveWidgetSpec) -> some View {
        Menu {
            ForEach(chapterGroups) { group in
                Section("Ch \(group.number) · \(group.title)") {
                    ForEach(group.widgets) { w in
                        Button(AtlasCopy.title(w)) { store.selectedWidgetId = w.id }
                    }
                }
            }
        } label: {
            HStack(spacing: StandardSpacing.xs) {
                Kicker("Lab", muted: true)
                Text(AtlasCopy.title(widget))
                    .standardType(.uiHeadline)
                    .foregroundStyle(theme.ink)
                    .lineLimit(1)
                Image(systemName: "chevron.up.chevron.down")
                    .imageScale(.small)
                    .foregroundStyle(theme.mute(theme.ink))
            }
            .padding(.horizontal, StandardSpacing.md)
            .frame(minHeight: StandardAccessibility.touchTarget)
            .background(
                RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                    .fill(theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                    .strokeBorder(theme.hairline(), lineWidth: 1)
            )
        }
        .accessibilityLabel("Choose a lab")
    }

    // MARK: The open lab

    private func labCard(_ widget: InteractiveWidgetSpec) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.lg) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: StandardSpacing.xs) {
                    ForEach(AtlasLabStep.allCases) { step in
                        PatternedChip("\(step.rawValue) · \(step.title)", isSelected: labStep == step) {
                            labStep = step
                        }
                    }
                }
            }

            stepBody(widget)

            liveFigure(widget)

            Rectangle().fill(theme.hairline()).frame(height: 1)

            stampRow(widget)

            chainLine(widget)
        }
        .paperCard()
    }

    @ViewBuilder
    private func stepBody(_ widget: InteractiveWidgetSpec) -> some View {
        switch labStep {
        case .look:
            VStack(alignment: .leading, spacing: StandardSpacing.md) {
                if let first = widget.watchSteps.first {
                    stepSentence(first.caption)
                }
                ForEach(Array(widget.watchSteps.enumerated().dropFirst()), id: \.offset) { idx, step in
                    HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.sm) {
                        Text("\(idx + 1)")
                            .patternedType(.sidenote)
                            .foregroundStyle(theme.brass)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(RoomCopy.droppingNumber(step.title))
                                .standardType(.uiHeadline)
                                .foregroundStyle(theme.ink)
                            Text(step.caption)
                                .patternedType(.readingSmall)
                                .foregroundStyle(theme.mute(theme.ink))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        case .cutAway:
            stepSentence(RoomCopy.dropping("Intuition → Formula Lockstep: ", from: widget.cutaway))
        case .ideal:
            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                Text("With the mess taken away, the picture says:")
                    .patternedType(.readingSmall)
                    .foregroundStyle(theme.mute(theme.ink))
                stepSentence(RoomCopy.dropping("Formula Anatomy: ", from: widget.idealised))
            }
        case .task:
            stepSentence(AtlasCopy.task(widget))
        }
    }

    private func stepSentence(_ text: String) -> some View {
        Text(text)
            .patternedType(.question)
            .foregroundStyle(theme.ink)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func liveFigure(_ widget: InteractiveWidgetSpec) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            if showEmbeddedWebStage {
                PatternedWorldWebStageView(
                    chapterNumber: widget.chapter,
                    atlasRoute: widget.atlasRoute,
                    store: store
                )
                .frame(minHeight: 380, maxHeight: 480)
                .clipShape(RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                        .strokeBorder(theme.hairline(), lineWidth: 1)
                )
                Text("Live figure · Chapter \(widget.chapter)\(widget.is3D ? " · turn it in 3D" : "")")
                    .standardType(.uiCaption)
                    .foregroundStyle(theme.mute(theme.ink))
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: StandardSpacing.md) { figureActions(widget) }
                VStack(alignment: .leading, spacing: StandardSpacing.xxs) { figureActions(widget) }
            }
        }
    }

    @ViewBuilder
    private func figureActions(_ widget: InteractiveWidgetSpec) -> some View {
        Button {
            showEmbeddedWebStage.toggle()
        } label: {
            Label(showEmbeddedWebStage ? "Hide the figure" : "Show the figure", systemImage: showEmbeddedWebStage ? "eye.slash" : "eye")
        }
        .buttonStyle(OutlineButtonStyle())

        Button("Open the chapter") {
            store.selectedChapterNumber = widget.chapter
            store.activeRoom = .patternedWorld
        }
        .buttonStyle(TextLinkButtonStyle())

        if let proposition = EuclidBuildLinks.widgets[widget.id] {
            Button("Build it yourself") {
                store.openEuclid(.board(proposition))
            }
            .buttonStyle(TextLinkButtonStyle())
            .help("Open \(proposition.raw) in Euclid's Workshop")
        }
    }

    private func stampRow(_ widget: InteractiveWidgetSpec) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: StandardSpacing.sm) {
                    stampField
                        .frame(minWidth: 220, idealWidth: 220, maxWidth: .infinity)
                    stampButton(widget).fixedSize()
                }
                VStack(alignment: .leading, spacing: StandardSpacing.sm) {
                    stampField
                    stampButton(widget)
                }
            }
            if let stamp = store.widgetStampsById[widget.id] {
                StatusTag(.proven, label: "Stamp earned \(stamp.earnedAt.formatted(date: .abbreviated, time: .omitted))")
            }
        }
    }

    private var stampField: some View {
        TextField("In your own words: what stayed the same?", text: $challengeNote)
            .learnerTextInput(.retrieval)
            .paperField()
    }

    private func stampButton(_ widget: InteractiveWidgetSpec) -> some View {
        Button {
            let note = challengeNote.isEmpty ? "Verified invariant on \(widget.title)" : challengeNote
            store.stampWidgetChallenge(widget: widget, note: note)
            challengeNote = ""
        } label: {
            HStack(spacing: StandardSpacing.xs) {
                Text("Earn the stamp")
                Image(systemName: "arrow.right").imageScale(.small)
            }
        }
        .buttonStyle(InkButtonStyle())
    }

    /// What this lab stands on and what it unlocks, from the chapter order: the chapter before
    /// and the chapter after. Tapping one opens that chapter's first lab.
    private func chainLine(_ widget: InteractiveWidgetSpec) -> some View {
        let before = chapter(widget.chapter - 1)
        let after = chapter(widget.chapter + 1)
        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.sm) {
                chainPart("Stands on", before)
                Image(systemName: "arrow.right")
                    .imageScale(.small)
                    .foregroundStyle(theme.mute(theme.ink))
                chainPart("Unlocks", after)
            }
            VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                chainPart("Stands on", before)
                chainPart("Unlocks", after)
            }
        }
    }

    private func chainPart(_ title: String, _ target: PatternedWorldChapter?) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.xs) {
            Kicker(title, muted: true)
            if let target {
                Button {
                    if let first = store.seedPack.widgets.first(where: { $0.chapter == target.number }) {
                        store.selectedWidgetId = first.id
                    }
                } label: {
                    Text("\(RoomCopy.shortChapterTitle(target.title)) · Ch \(target.number)")
                        .standardType(.uiBody)
                        .foregroundStyle(theme.ink)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
                .frame(minHeight: StandardAccessibility.touchTarget)
                .accessibilityHint("Opens the first lab in chapter \(target.number)")
            } else {
                Text(title == "Stands on" ? "Nothing yet: a first step" : "The end of this road, for now")
                    .standardType(.uiBody)
                    .foregroundStyle(theme.mute(theme.ink))
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Room state and copy

enum AtlasRoomMode {
    case lab, recall
}

/// The four ways into a lab, in the order a reader takes them.
enum AtlasLabStep: Int, CaseIterable, Identifiable {
    case look = 1, cutAway, ideal, task

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .look: "Look"
        case .cutAway: "Cut away"
        case .ideal: "Make it ideal"
        case .task: "Your task"
        }
    }
}

private struct AtlasChapterGroup: Identifiable {
    let number: Int
    let title: String
    var widgets: [InteractiveWidgetSpec]
    var id: Int { number }
}

enum AtlasCopy {
    private static let capitals = ["Hcf": "HCF", "Lcm": "LCM", "Ftc": "FTC"]

    /// "3D Atlas: Unit Circle" → "Unit Circle"; "Prime Venn Hcf Lcm" → "Prime Venn HCF LCM".
    static func title(_ widget: InteractiveWidgetSpec) -> String {
        RoomCopy.dropping("3D Atlas: ", from: widget.title)
            .split(separator: " ")
            .map { capitals[String($0)] ?? String($0) }
            .joined(separator: " ")
    }

    /// The seed's task template, "Manipulate X until the visual invariant locks in, then verify Y",
    /// said plainly.
    static func task(_ widget: InteractiveWidgetSpec) -> String {
        let prompt = widget.challengePrompt
        let marker = " until the visual invariant locks in, then verify "
        guard prompt.hasPrefix("Manipulate "), let range = prompt.range(of: marker) else { return prompt }
        return "Play with the figure until the pattern holds still. Then check that " + prompt[range.upperBound...]
    }
}
