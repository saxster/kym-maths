import Foundation

// MARK: - Live Mentor Transcript Safety Monitor (Ported from ../kym_tutor)

public struct LiveMentorSafetyDecision: Equatable, Sendable {
    public var shouldSuppressModelContinuation: Bool
    public var supportiveResponse: String
    public var concern: SafetyEscalationService.Concern?

    public init(
        shouldSuppressModelContinuation: Bool,
        supportiveResponse: String,
        concern: SafetyEscalationService.Concern?
    ) {
        self.shouldSuppressModelContinuation = shouldSuppressModelContinuation
        self.supportiveResponse = supportiveResponse
        self.concern = concern
    }

    public static let clear = LiveMentorSafetyDecision(
        shouldSuppressModelContinuation: false,
        supportiveResponse: "",
        concern: nil
    )
}

public struct LiveMentorTranscriptSafetyMonitor: Sendable {
    private let safetyService: SafetyEscalationService

    public init(safetyService: SafetyEscalationService = SafetyEscalationService()) {
        self.safetyService = safetyService
    }

    public func evaluateTranscript(
        _ transcript: String,
        region: SafetyEscalationService.Region = .current()
    ) async -> LiveMentorSafetyDecision {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .clear }
        guard let concern = safetyService.scan(trimmed) else { return .clear }
        let response = safetyService.supportiveResponse(for: concern, region: region)
        await MainActor.run {
            safetyService.escalate(concern, channel: "live_mentor")
        }
        return LiveMentorSafetyDecision(
            shouldSuppressModelContinuation: true,
            supportiveResponse: response,
            concern: concern
        )
    }
}
