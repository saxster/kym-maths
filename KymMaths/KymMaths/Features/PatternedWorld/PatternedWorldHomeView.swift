import SwiftUI

// MARK: - Room 3: The Patterned World

enum PatternedWorldReadingMode: String, CaseIterable, Identifiable, Sendable {
    case interactiveBeats = "One step at a time"
    case fullChapterScroll = "The whole chapter"

    var id: String { rawValue }
    var title: String { rawValue }
}

/// What the reader has done in this visit: which step they are on, what they typed but have not
/// saved, which gates they skipped. It outlives a trip back to the library, so returning to a
/// chapter finds the page as it was left.
@MainActor
@Observable
final class ChapterReadingState {
    var readingMode: PatternedWorldReadingMode = .interactiveBeats
    var activeBeatIndex = 0
    var completedBeatIds: Set<String> = []
    var narrator = ChapterAudioNarrator()
    var selectedTermSymbol: String?
    var highlightedColorRole: String?
    var showEmbeddedWebStage = true
    var calloutDrafts: [String: String] = [:]
    var readingThoughtsByChapter: [Int: String] = [:]
    var bypassedPredictionChapters: Set<Int> = []
    var revealedCheckCalloutIds: Set<String> = []
    var calloutConfidenceById: [String: Int] = [:]

    func open(chapter number: Int, store: AppStore) {
        narrator.stop()
        store.selectedChapterNumber = number
        activeBeatIndex = 0
        selectedTermSymbol = nil
        highlightedColorRole = nil
    }
}

/// The room: the library of volumes and chapters, and a chapter open for reading.
struct PatternedWorldHomeView: View {
    @Bindable var store: AppStore
    @State private var reading = ChapterReadingState()
    @State private var isReadingChapter = false

    var body: some View {
        Group {
            if isReadingChapter {
                PatternedChapterView(store: store, reading: reading) {
                    reading.narrator.stop()
                    isReadingChapter = false
                }
            } else {
                PatternedLibraryView(store: store) { number in
                    reading.open(chapter: number, store: store)
                    isReadingChapter = true
                }
            }
        }
        .onAppear {
            // Another room (or a `chapter/<n>` link) that picked a chapter lands in it; the room's
            // own sidebar entry, with nothing picked yet, lands in the library.
            if store.selectedChapterNumber != 0 || store.deepLinkTail.contains("read") {
                isReadingChapter = true
            }
        }
        .onDisappear {
            reading.narrator.stop()
        }
    }
}

// MARK: - The library

struct PatternedLibraryView: View {
    @Bindable var store: AppStore
    let openChapter: (Int) -> Void

    @Environment(\.standardTheme) private var theme
    @State private var chosenVolume: Int?
    @State private var width: CGFloat = 700

    private var visibleNumbers: Set<Int> { Set(store.visiblePatternedWorldChapters.map(\.number)) }

    private var volume: PatternedWorldVolume {
        let number = chosenVolume ?? store.selectedChapter.volumeNumber
        return store.seedPack.volumes.first { $0.number == number } ?? store.seedPack.volumes[0]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StandardSpacing.xl) {
                EditorialHeader(
                    eyebrow: "\(PatternedBook.spelled(store.seedPack.volumes.count)) volumes · \(store.seedPack.chapters.count) chapters",
                    title: "The Patterned World",
                    subtitle: "Every chapter opens with one idea worth wondering about. Read it first; the maths is how you find out why it is true."
                )

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 124), spacing: StandardSpacing.sm, alignment: .top)],
                    alignment: .leading,
                    spacing: StandardSpacing.sm
                ) {
                    ForEach(store.seedPack.volumes) { vol in
                        volumeCard(vol)
                    }
                }

                let parts = PatternedBook.volumeName(volume, chapters: store.seedPack.chapters)
                VStack(alignment: .leading, spacing: StandardSpacing.sm) {
                    Kicker("Volume \(PatternedBook.roman(volume.number)) · \(parts.name), \(parts.topics)", muted: true)
                    BookSpread(width: width) {
                        chapterList
                    } margin: {
                        libraryMargin
                    }
                }
            }
            .padding(.horizontal, StandardSpacing.xl)
            .padding(.top, StandardSpacing.xl)
            .padding(.bottom, StandardSpacing.xl3)
            .frame(maxWidth: 1180, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .readWidth($width)
        }
        .background(theme.bg)
    }

    // MARK: Volume cards

    private func volumeCard(_ vol: PatternedWorldVolume) -> some View {
        let parts = PatternedBook.volumeName(vol, chapters: store.seedPack.chapters)
        let isOpen = vol.chapters.contains { visibleNumbers.contains($0) }
        let isChosen = vol.number == volume.number
        let readCount = vol.chapters.filter { (store.readingProgressByChapter[$0]?.readFraction ?? 0) >= 0.9 }.count
        let started = vol.chapters.contains { (store.readingProgressByChapter[$0]?.readFraction ?? 0) > 0 }
        let status = started ? "\(readCount) of \(vol.chapters.count) read" : "Not started"

        return Button {
            chosenVolume = vol.number
        } label: {
            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                VolumeFigure(volume: vol.number)
                    .frame(height: 76)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, StandardSpacing.xs)
                    .opacity(isOpen ? 1 : 0.45)
                Kicker("Volume \(PatternedBook.roman(vol.number))")
                Text(parts.name)
                    .standardType(.headlineSm)
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(parts.topics)
                    .standardType(.uiCaption)
                    .foregroundStyle(theme.mute(theme.ink))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: StandardSpacing.xxs)
                if isOpen {
                    ViewThatFits(in: .horizontal) {
                        Text("\(PatternedBook.chapterRange(vol)) · \(status)")
                        VStack(alignment: .leading, spacing: 0) {
                            Text(PatternedBook.chapterRange(vol))
                            Text(status)
                        }
                    }
                    .standardType(.uiCaption)
                    .foregroundStyle(started ? theme.ink : theme.mute(theme.ink))
                } else {
                    StatusTag(.locked, label: "Ask a grown-up")
                }
            }
            .frame(maxWidth: .infinity, minHeight: 236, alignment: .topLeading)
            .padding(StandardSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: StandardRadius.xl, style: .continuous)
                    .fill(theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: StandardRadius.xl, style: .continuous)
                    .strokeBorder(isChosen ? theme.ink : theme.hairline(), lineWidth: isChosen ? 1.5 : 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isOpen)
        .accessibilityLabel("Volume \(vol.number), \(parts.name). \(isOpen ? status : "Switched off in Settings")")
        .accessibilityAddTraits(isChosen ? .isSelected : [])
    }

    // MARK: Chapter list

    private var chapterList: some View {
        let chapters = store.seedPack.chapters.filter { $0.volumeNumber == volume.number }
        let visible = store.visiblePatternedWorldChapters
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(chapters) { chapter in
                let standing = ChapterStanding.of(chapter, in: visible, progress: store.readingProgressByChapter)
                chapterRow(chapter, standing: standing)
                if chapter.id != chapters.last?.id {
                    Rectangle().fill(theme.hairline()).frame(height: 1)
                }
            }
            Rectangle().fill(theme.hairline()).frame(height: 1)
        }
    }

    private func chapterRow(_ chapter: PatternedWorldChapter, standing: ChapterStanding) -> some View {
        let isCurrent: Bool = if case .reading = standing { true } else { false }
        return Button {
            openChapter(chapter.number)
        } label: {
            HStack(alignment: .top, spacing: StandardSpacing.md) {
                Text("\(chapter.number)")
                    .standardType(.headlineLg)
                    .foregroundStyle(theme.brass)
                    .frame(minWidth: 30, alignment: .leading)
                VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                    // The chapter's opening idea, in the wonder face at a row's size.
                    ByrneText(chapter.hookSummary)
                        .patternedType(.mathInline)
                        .foregroundStyle(theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(chapter.title)
                        .standardType(.uiBody)
                        .foregroundStyle(theme.mute(theme.ink))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: StandardSpacing.sm)
                HStack(spacing: StandardSpacing.sm) {
                    standing.tag(chapter: chapter.number)
                    Image(systemName: "chevron.right")
                        .imageScale(.small)
                        .foregroundStyle(theme.mute(theme.ink))
                }
                .padding(.top, 6)
            }
            .padding(.vertical, StandardSpacing.md)
            .padding(.horizontal, StandardSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                    .fill(isCurrent ? theme.surface : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens chapter \(chapter.number)")
    }

    // MARK: Margin

    @ViewBuilder private var libraryMargin: some View {
        let previous = store.seedPack.volumes.first { $0.number == volume.number - 1 }
        if let previous {
            let prevName = PatternedBook.volumeName(previous, chapters: store.seedPack.chapters).name
            MarginNote(.sidenote(1), "Each volume stands on the one before. This one leans on Volume \(PatternedBook.roman(previous.number)), \(prevName).")
        } else {
            MarginNote(.sidenote(1), "This is where the book begins. Each volume after it stands on the one before.")
        }
        if let explorer = store.seedPack.explorers.first(where: { !Set($0.linkedChapters).isDisjoint(with: volume.chapters) }) {
            MarginNote(.sidenote(2), explorer.summary)
        }
        if let own = PatternedBook.latestOwnWords(in: Set(volume.chapters), responses: store.calloutResponses) {
            MarginNote(.hand, own)
        }
    }
}
