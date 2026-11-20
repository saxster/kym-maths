import SwiftUI

/// Shared pinned-snapshot tray used in both Patterned World (`ChapterFigure`) and Atlas (`LabsAtlasHomeView`).
/// Derives Journal persistence live from `store.journalEntries` rather than keeping room-local saved IDs.
struct StageSnapshotStrip: View {
    let chapterNumber: Int
    @Bindable var store: AppStore
    var buttonStyleKind: ActionStyle = .textLink

    @Environment(\.standardTheme) private var theme

    enum ActionStyle {
        case textLink
        case outline
    }

    var body: some View {
        let snaps = store.stageSnapshots.filter { $0.chapterNumber == chapterNumber }
        if !snaps.isEmpty {
            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                Kicker("Pinned snapshots", muted: true)
                ForEach(snaps) { snap in
                    let isSaved = store.journalEntries.contains { $0.id == "journal-snap-\(snap.id)" }
                    HStack(alignment: .center, spacing: StandardSpacing.sm) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(snap.summary)
                                .standardType(.uiBody)
                                .foregroundStyle(theme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(snap.contextSentence)
                                .standardType(.uiCaption)
                                .foregroundStyle(theme.mute(theme.ink))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: StandardSpacing.xs)
                        if isSaved {
                            StatusTag(.proven, label: "In Journal")
                        } else if buttonStyleKind == .outline {
                            Button("Save to Journal") {
                                store.saveStageSnapshotToJournal(snap)
                            }
                            .buttonStyle(OutlineButtonStyle())
                        } else {
                            Button("Save to Journal") {
                                store.saveStageSnapshotToJournal(snap)
                            }
                            .buttonStyle(TextLinkButtonStyle(arrow: false))
                        }
                    }
                    .padding(StandardSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                            .fill(theme.patterned.sunkColor)
                    )
                }
            }
        }
    }
}
