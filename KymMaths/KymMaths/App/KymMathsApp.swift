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

    var body: some View {
        NavigationSplitView(columnVisibility: $columns) {
            PatternedSidebar(store: store)
                .navigationSplitViewColumnWidth(min: 240, ideal: 264, max: 300)
                #if os(iOS)
                .toolbar(.hidden, for: .navigationBar)
                #endif
        } detail: {
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
            .background(theme.bg)
            .navigationTitle(store.activeRoom.title)
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
        }
        .navigationSplitViewStyle(.balanced)
        .tint(theme.brass)
        // The proof studio opens from Today, School book and Coach, so it hangs off the root.
        .sheet(item: $store.activePracticeQuestion) { question in
            QuestionProofPracticeView(question: question, store: store)
        }
        .sheet(isPresented: $store.showCalendarSheet) {
            CalendarHomeView(store: store)
                .pageSizedSheet()
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
