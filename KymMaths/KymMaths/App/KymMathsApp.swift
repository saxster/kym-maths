import SwiftUI

// MARK: - KymMaths App Root & 7-Room Navigation Shell

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

    // iOS lists only take an optional selection; the sidebar never clears the room.
    private var roomSelection: Binding<AppRoom?> {
        Binding(
            get: { store.activeRoom },
            set: { if let room = $0 { store.activeRoom = room } }
        )
    }

    var body: some View {
        NavigationSplitView {
            List(AppRoom.allCases, selection: roomSelection) { room in
                Label(room.title, systemImage: room.systemImage)
                    .tag(room)
            }
            .navigationTitle("KymMaths")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    StandardThemeMenu()
                }
                ToolbarItem(placement: .automatic) {
                    Button {
                        store.showSettingsSheet = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .help("Settings & Customisation")
                }
            }
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
                }
            }
            .navigationTitle(store.activeRoom.title)
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    StandardThemeMenu()
                    Button {
                        store.showCalendarSheet = true
                    } label: {
                        Label("Deadlines", systemImage: "calendar")
                    }
                    Button {
                        store.showSettingsSheet = true
                    } label: {
                        Label("Settings", systemImage: "slider.horizontal.3")
                    }
                }
            }
        }
        .tint(Color.kymaiaPrimary)
        .sheet(isPresented: $store.showCalendarSheet) {
            CalendarHomeView(store: store)
        }
        .sheet(isPresented: $store.showSettingsSheet) {
            MathsSettingsSheet(store: store)
        }
    }
}
