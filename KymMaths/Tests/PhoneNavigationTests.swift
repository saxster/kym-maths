import Foundation
import SwiftUI
import Testing
@testable import KymMaths

/// On iPhone the split view collapses to one column. Choosing a room has to move that column to the room,
/// or the tap only moves the sidebar highlight and the room never opens.
@Suite("Phone navigation")
@MainActor
struct PhoneNavigationTests {
    private func store() -> AppStore { AppStore(db: DatabaseManager(inMemory: true)) }

    @Test("The phone starts on the list of rooms")
    func startsOnSidebar() {
        #expect(store().compactColumn == .sidebar)
    }

    @Test("Choosing a room shows it, even the room that is already active")
    func choosingARoomShowsIt() {
        for room in AppRoom.allCases {
            let store = store()
            store.activeRoom = room
            #expect(store.compactColumn == .detail, "\(room)")
        }
    }

    @Test("Up next and deep links show the room they open")
    func upNextAndDeepLinksShowTheRoom() throws {
        let euclid = store()
        euclid.openEuclid(.map)
        #expect(euclid.compactColumn == .detail)

        let linked = store()
        linked.openDeepLink(try #require(URL(string: "kymmaths://school/3")))
        #expect(linked.compactColumn == .detail)
        #expect(linked.activeRoom == .schoolMaths)
    }

    @Test("Deadlines and Settings open over the list without leaving it")
    func sheetsKeepTheList() throws {
        let store = store()
        store.openDeepLink(try #require(URL(string: "kymmaths://settings")))
        #expect(store.showSettingsSheet)
        #expect(store.compactColumn == .sidebar)
    }
}
