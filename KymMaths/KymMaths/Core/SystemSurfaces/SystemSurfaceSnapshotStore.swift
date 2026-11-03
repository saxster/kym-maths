import Foundation

// MARK: - Widget & AppIntents Shared Snapshot Store

struct KymMathsSystemSnapshot: Codable, Equatable, Sendable {
    let generatedAt: Date
    let learnerName: String
    let dueCardsCount: Int
    let dueCardHeadline: String
    let activeUnitTitle: String
    let independentProofsCount: Int
    let secureProofsCount: Int
    let totalQuestionsCount: Int
    let nextDeadlineTitle: String
    let nextDeadlineDate: Date?
    let deepLinkURLString: String
}

enum SystemSurfaceSnapshotStore {
    static let fileName = "kymmaths-widget-snapshot.json"

    static func snapshotURL() -> URL {
        // The widgets that read this are iPad-only, and only the iPad build may use the app group.
        #if os(iOS)
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.kymaia.science") {
            return groupURL.appendingPathComponent(fileName)
        }
        #endif
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        return appSupport.appendingPathComponent(fileName)
    }

    @MainActor
    static func writeSnapshot(from store: AppStore) {
        let due = store.dueFSRSCards
        let headline = due.first?.frontPrompt ?? "All spaced-retrieval cards reviewed for today!"
        let deadline = store.nextSchoolDeadline

        let snapshot = KymMathsSystemSnapshot(
            generatedAt: Date(),
            learnerName: store.learnerDisplayName,
            dueCardsCount: due.count,
            dueCardHeadline: headline,
            activeUnitTitle: "Ch \(store.selectedUnit.unitNumber) · \(store.selectedUnit.title)",
            independentProofsCount: store.overallIndependentProofCount,
            secureProofsCount: store.overallSecureCount,
            totalQuestionsCount: store.seedPack.schoolQuestions.count,
            nextDeadlineTitle: deadline?.title ?? "Cambridge Stage 8 Checkpoint Prep",
            nextDeadlineDate: deadline?.dueAt,
            deepLinkURLString: "kymmaths://today"
        )

        if let data = try? JSONEncoder().encode(snapshot) {
            try? data.write(to: snapshotURL(), options: .atomic)
        }
    }

    static func readSnapshot() -> KymMathsSystemSnapshot? {
        guard let data = try? Data(contentsOf: snapshotURL()) else { return nil }
        return try? JSONDecoder().decode(KymMathsSystemSnapshot.self, from: data)
    }
}
