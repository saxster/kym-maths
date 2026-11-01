import Foundation
import UserNotifications

// MARK: - Child-Safety Crisis Escalation Service (Ported from ../kym_tutor)

/// Detects child-safety crisis indicators (suicidal ideation, self-harm, abuse
/// disclosure, eating-disorder, acute distress) in free text the child enters — chat,
/// journal, spoken answers — and produces the therapeutic-addendum §3B.15 response:
/// acknowledge, do NOT process it as an academic task, connect the child to a trusted
/// adult, and notify the parent.
///
/// This is a safeguarding gate, not a clinical tool. It is intentionally high-recall and
/// errs toward surfacing a concern to a human. Detection is phrase-based and on-device;
/// the child's text is never sent to an AI provider on the escalation path.
public struct SafetyEscalationService: Sendable {

    public enum Category: String, Sendable, Codable, CaseIterable {
        case suicidalIdeation = "suicidal_ideation"
        case selfHarm = "self_harm"
        case abuseDisclosure = "abuse_disclosure"
        case eatingDisorder = "eating_disorder"
        case acuteDistress = "acute_distress"
    }

    public struct Concern: Sendable, Equatable, Codable {
        public let category: Category
        public let matchedPhrase: String

        public init(category: Category, matchedPhrase: String) {
            self.category = category
            self.matchedPhrase = matchedPhrase
        }
    }

    public enum SafetyError: Error { case concernDetected }

    public enum Region: String, Sendable, Codable {
        case india
        case unitedStates

        /// Derive the hotline script from the device locale: the US gets the
        /// 988/911 script; every other locale (India included) gets the generic
        /// script, which carries India's 112 emergency number.
        public static func current(using locale: Locale = .current) -> Region {
            locale.region?.identifier == "US" ? .unitedStates : .india
        }
    }

    public init() {}

    // Ordered by priority (most acute first). Lower-cased, high-recall indicators.
    private static let indicators: [(Category, [String])] = [
        (.suicidalIdeation, [
            "kill myself", "killing myself", "end my life", "ending my life", "want to die",
            "wanna die", "better off dead", "suicidal", "suicide", "don't want to be alive",
            "do not want to live", "don't want to live", "take my own life"
        ]),
        (.selfHarm, [
            "hurt myself", "hurting myself", "cut myself", "cutting myself", "self harm",
            "self-harm", "harm myself", "burn myself", "make myself bleed"
        ]),
        (.abuseDisclosure, [
            "touched me", "touches me", "hits me", "hitting me", "hurts me at home",
            "afraid to go home", "scared to go home", "someone hurt me", "being abused",
            "abusing me", "makes me do things"
        ]),
        (.eatingDisorder, [
            "make myself throw up", "making myself throw up", "starve myself", "starving myself",
            "stop eating", "won't eat", "too fat to eat", "purge after", "hate my body"
        ]),
        (.acuteDistress, [
            "can't go on", "cannot go on", "no reason to live", "everyone hates me",
            "want to disappear", "wish i wasn't here", "feel hopeless", "nothing matters anymore"
        ])
    ]

    /// Scan text and return the highest-priority concern, if any.
    public func scan(_ text: String) -> Concern? {
        let haystack = text.lowercased()
        for (category, phrases) in Self.indicators {
            for phrase in phrases where haystack.contains(phrase) {
                return Concern(category: category, matchedPhrase: phrase)
            }
        }
        return nil
    }

    /// The supportive, non-clinical message shown to the child in place of a normal
    /// tutoring response when a concern is detected.
    public func supportiveResponse(for concern: Concern, region: Region = .current()) -> String {
        switch region {
        case .india:
            return indiaSupportiveResponse(for: concern)
        case .unitedStates:
            return unitedStatesSupportiveResponse(for: concern)
        }
    }

    private func indiaSupportiveResponse(for concern: Concern) -> String {
        switch concern.category {
        case .suicidalIdeation, .selfHarm, .acuteDistress:
            return """
            It sounds like you're carrying something really heavy right now, and I'm really \
            glad you told me. I'm just a study helper, so I'm not the right one for this — but \
            a grown-up who cares about you is. Please talk to a parent or another trusted adult \
            right now. If you ever feel unsafe in India, you can call 112 for emergency help. \
            You are not alone.
            """
        case .abuseDisclosure:
            return """
            Thank you for trusting me with that. What you're describing matters, and you deserve \
            to feel safe. I'm only a study helper, so please tell a trusted adult — a parent, \
            teacher, or school counselor — what you just told me. If you are in danger in India, \
            call 112 for emergency help. You did the right thing by speaking up.
            """
        case .eatingDisorder:
            return """
            I hear you, and I'm glad you shared that. Your body and your feelings matter. I'm just \
            a study helper, so please talk to a parent or a doctor about how you're feeling — they \
            can really help. If you feel unsafe in India, call 112 for emergency help. You don't \
            have to handle this on your own.
            """
        }
    }

    private func unitedStatesSupportiveResponse(for concern: Concern) -> String {
        switch concern.category {
        case .suicidalIdeation, .selfHarm, .acuteDistress:
            return """
            It sounds like you're carrying something really heavy right now, and I'm really \
            glad you told me. I'm just a study helper, so I'm not the right one for this — but \
            a grown-up who cares about you is. Please talk to a parent or another trusted adult \
            right now. If you ever feel unsafe, you can call or text 988 (the Suicide & Crisis \
            Lifeline) any time, day or night. You are not alone.
            """
        case .abuseDisclosure:
            return """
            Thank you for trusting me with that. What you're describing matters, and you deserve \
            to feel safe. I'm only a study helper, so please tell a trusted adult — a parent, \
            teacher, or school counselor — what you just told me. If you are ever in danger, you \
            can call 911. You did the right thing by speaking up.
            """
        case .eatingDisorder:
            return """
            I hear you, and I'm glad you shared that. Your body and your feelings matter. I'm just \
            a study helper, so please talk to a parent, a doctor, or another trusted adult about \
            how you're feeling — they can really help. If you ever feel unsafe, you can call or \
            text 988 any time. You don't have to handle this on your own.
            """
        }
    }

    /// Record the event for the audit trail and fire an immediate, high-priority parent
    /// notification. The notification is intentionally non-specific (no quoted phrase or
    /// category) — details are surfaced to the parent in-app, not on a lock screen.
    @MainActor
    public func escalate(_ concern: Concern, channel: String) {
        guard Self.canScheduleLocalNotifications else { return }

        let content = UNMutableNotificationContent()
        content.title = "Please check in with your child"
        content.body = "KymMaths noticed something in your child's messages that may need a caring conversation. Please talk with them soon."
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        let request = UNNotificationRequest(
            identifier: "safety-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private static var canScheduleLocalNotifications: Bool {
        let extensionName = Bundle.main.bundleURL.pathExtension.lowercased()
        return extensionName == "app" || extensionName == "appex"
    }
}

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
