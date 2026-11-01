import AppIntents
import Foundation

// MARK: - AppIntents & Spotlight Shortcuts for KymMaths

struct OpenTodayMathsQueueIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Today's Maths Queue"
    static let description = IntentDescription("Opens KymMaths to Today's Spaced Retrieval, Singapore Bar-Model Practice, and 3D Atlas queue.")
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let snapshot = SystemSurfaceSnapshotStore.readSnapshot()
        let dueCount = snapshot?.dueCardsCount ?? 0
        return .result(dialog: "Opening KymMaths. You have \(dueCount) spaced-retrieval cards due today.")
    }
}

struct OpenMatrixSandboxIntent: AppIntent {
    static let title: LocalizedStringResource = "Open 3D Matrix & Calculus Atlas"
    static let description = IntentDescription("Opens KymMaths directly to the interactive 3D Matrix Sandbox, Unit Circle, and Calculus Lab.")
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        return .result(dialog: "Opening the 3D Matrix Sandbox and Calculus Atlas in KymMaths.")
    }
}

struct KymMathsShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenTodayMathsQueueIntent(),
            phrases: [
                "Start my maths practice in \(.applicationName)",
                "Open today's queue in \(.applicationName)"
            ],
            shortTitle: "Today's Maths Queue",
            systemImageName: "function"
        )
        AppShortcut(
            intent: OpenMatrixSandboxIntent(),
            phrases: [
                "Open 3D Matrix Sandbox in \(.applicationName)",
                "Launch 3D Atlas in \(.applicationName)"
            ],
            shortTitle: "3D Matrix & Calculus Atlas",
            systemImageName: "cube.transparent.fill"
        )
    }
}
