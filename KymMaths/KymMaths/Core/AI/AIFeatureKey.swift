// Routing and provenance key for KymMaths' AI requests. AIRequestContext carries the shared
// module's string-backed AIFeature; the provider converts at the boundary. KymMaths' raw values
// are snake_case and differ from the module presets, so the conversion maps by case.

public enum AIFeatureKey: String, Codable, CaseIterable, Identifiable, Sendable {
    case chat
    case questionTutor = "question_tutor"
    case reading
    case assessment
    case contentGeneration = "content_generation"
    case knowledgeSearch = "knowledge_search"
    case parentDashboard = "parent_dashboard"
    case spotTheFlaw = "spot_the_flaw"

    public var id: String { rawValue }
}

extension AIFeature {
    static let spotTheFlaw = AIFeature("spot_the_flaw")
}

extension AIFeatureKey {
    init(_ feature: AIFeature) {
        switch feature {
        case .chat: self = .chat
        case .questionTutor: self = .questionTutor
        case .reading: self = .reading
        case .assessment: self = .assessment
        case .contentGeneration: self = .contentGeneration
        case .knowledgeSearch: self = .knowledgeSearch
        case .parentDashboard: self = .parentDashboard
        case .spotTheFlaw: self = .spotTheFlaw
        default: self = .contentGeneration
        }
    }
}
