import SwiftUI

// MARK: - KymMaths App Root & Room Navigation Shell

@main
struct KymMathsApp: App {
    @State private var store: AppStore

    init() {
        AppTheme.register()
        TutorConstitution.register(.kymMaths)
        _store = State(initialValue: AppStore())
    }

    var body: some Scene {
        WindowGroup {
            StandardIdiomReader {
                KymMathsRootView(store: store)
                    // The iPad's lower pixel density makes the same point size read larger and
                    // looser than on iPhone, so iPad type runs 10% smaller.
                    .environment(\.padScale, DeviceIdiom.isPad ? 0.9 : 1)
                    .standardThemeHost()
                    .onOpenURL { url in
                        store.openDeepLink(url)
                    }
            }
        }
        #if os(macOS)
        Settings {
            StandardAppearanceSettings(appName: "KymMaths")
                .standardThemeHost(rebuildsOnThemeChange: false)
        }
        #endif
    }
}

struct KymMathsRootView: View {
    @Bindable var store: AppStore
    @Environment(\.standardTheme) private var theme
    @State private var columns: NavigationSplitViewVisibility = .all
    @AppStorage("kymmaths.userCollapsedSidebar") private var userCollapsedSidebar = false
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    var body: some View {
        NavigationSplitView(columnVisibility: $columns, preferredCompactColumn: $store.compactColumn) {
            PatternedSidebar(
                store: store,
                onHideSidebar: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        userCollapsedSidebar = true
                        columns = .detailOnly
                    }
                }
            )
            .navigationSplitViewColumnWidth(min: 240, ideal: 264, max: 300)
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
        } detail: {
            VStack(spacing: 0) {
                if columns == .detailOnly {
                    HStack(spacing: StandardSpacing.sm) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                userCollapsedSidebar = false
                                columns = .all
                            }
                        } label: {
                            Label("Show Spine", systemImage: "sidebar.left")
                        }
                        .buttonStyle(OutlineButtonStyle())
                        .keyboardShortcut("\\", modifiers: [.command])
                        .accessibilityLabel("Show left spine")

                        Text("The Patterned World · \(store.activeRoom.title)")
                            .standardType(.uiCaption)
                            .foregroundStyle(theme.mute(theme.ink))
                        Spacer(minLength: 0)
                        Button {
                            store.activeRoom = .mathsJournal
                        } label: {
                            Label("Journal & Notes", systemImage: "book.pages")
                        }
                        .buttonStyle(OutlineButtonStyle())
                    }
                    .padding(.horizontal, StandardSpacing.lg)
                    .padding(.vertical, StandardSpacing.xs)
                    .background(theme.surface)
                    Rectangle().fill(theme.hairline()).frame(height: 1)
                }

                Group {
                    switch store.activeRoom {
                    case .today:
                        TodayHomeView(store: store)
                    case .schoolMaths:
                        SchoolMathsHomeView(store: store)
                    case .patternedWorld:
                        PatternedWorldHomeView(store: store)
                    case .labsAtlas:
                        LabsAtlasHomeView(store: store)
                    case .polyaFluency:
                        PolyaFluencyHomeView(store: store)
                    case .mathsJournal:
                        MathsJournalHomeView(store: store)
                    case .coach:
                        MathsCoachView(store: store)
                    case .euclidWorkshop:
                        EuclidWorkshopView(store: store)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(theme.bg)
            .navigationTitle(store.activeRoom.title)
            #if os(iOS)
            // On iPhone the room is pushed over the list, so it keeps the bar that holds the way back.
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(sizeClass == .compact ? .visible : .hidden, for: .navigationBar)
            #endif
        }
        .navigationSplitViewStyle(.balanced)
        .tint(theme.brass)
        .conceptLinks()
        .onAppear {
            if userCollapsedSidebar {
                columns = .detailOnly
            }
        }
        // The proof studio opens from Today, School book and Coach, so it hangs off the root.
        .sheet(item: $store.activePracticeQuestion) { question in
            QuestionProofPracticeView(question: question, store: store)
        }
        .sheet(isPresented: $store.showCalendarSheet) {
            CalendarHomeView(store: store)
                .pageSizedSheet()
        }
        .sheet(item: $store.deepLinkedConcept) { request in
            ConceptCardSheet(start: request.id)
        }
        .sheet(isPresented: $store.showSettingsSheet) {
            MathsSettingsSheet(store: store)
                .pageSizedSheet()
        }
        #if DEBUG
        .sheet(isPresented: $store.showPatternedGallery) {
            PatternedGallery()
                .pageSizedSheet()
        }
        #endif
    }
}
