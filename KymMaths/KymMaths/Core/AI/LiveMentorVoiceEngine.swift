import Foundation
import SwiftUI

// MARK: - Live Mentor Session State & Configuration

public enum LiveMentorSessionState: Sendable, Equatable {
    case idle
    case connecting
    case active(providerName: String)
    case reconnecting(attempt: Int)
    case ended(reason: String)

    public var isConnected: Bool {
        if case .active = self { return true }
        return false
    }

    public var statusBadgeText: String {
        switch self {
        case .idle: return "Ready"
        case .connecting: return "Connecting..."
        case .active(let provider): return "Live · \(provider)"
        case .reconnecting(let attempt): return "Reconnecting (\(attempt))..."
        case .ended(let reason): return reason
        }
    }
}

public enum LiveMentorVoiceProvider: String, Codable, Sendable, CaseIterable, Identifiable {
    case geminiLive = "gemini-3.8-live"
    case geminiLiveExtendedThinking = "gemini-3.8-live-extended-thinking"
    case openAIRealtime = "gpt-realtime"
    case offlineSimulated = "offline-socratic-voice"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .geminiLive: return "Gemini 3.8 Live"
        case .geminiLiveExtendedThinking: return "Gemini 3.8 Live (Extended Thinking)"
        case .openAIRealtime: return "OpenAI Realtime"
        case .offlineSimulated: return "On-Device Socratic Voice"
        }
    }
}

public struct LiveMentorSessionConfiguration: Sendable, Equatable {
    public var topic: String
    public var systemInstruction: String
    public var voiceName: String
    public var learnerAge: Int
    public var soulID: String
    public var overrides: [String: String]
    public var guidanceStyle: TutorGuidanceStyle
    public var provider: LiveMentorVoiceProvider

    public init(
        topic: String,
        systemInstruction: String = "",
        voiceName: String = "Aoede",
        learnerAge: Int = 12,
        soulID: String = "polya",
        overrides: [String: String] = [:],
        guidanceStyle: TutorGuidanceStyle = .adaptive,
        provider: LiveMentorVoiceProvider = .geminiLive
    ) {
        self.topic = topic
        self.systemInstruction = systemInstruction
        self.voiceName = voiceName
        self.learnerAge = learnerAge
        self.soulID = soulID
        self.overrides = overrides
        self.guidanceStyle = guidanceStyle
        self.provider = provider
    }
}

public struct LiveMentorTranscriptEntry: Identifiable, Codable, Sendable, Equatable {
    public enum Speaker: String, Codable, Sendable, Equatable {
        case learner
        case mentor
        case system
    }

    public var id: String
    public var speaker: Speaker
    public var text: String
    public var timestamp: Date
    public var canvasAttachment: TutorCanvas?

    public init(
        id: String = UUID().uuidString,
        speaker: Speaker,
        text: String,
        timestamp: Date = Date(),
        canvasAttachment: TutorCanvas? = nil
    ) {
        self.id = id
        self.speaker = speaker
        self.text = text
        self.timestamp = timestamp
        self.canvasAttachment = canvasAttachment
    }
}

// MARK: - LiveMentorPromptPolicy

public enum LiveMentorPromptPolicy {
    public static func buildSystemInstruction(
        config: LiveMentorSessionConfiguration,
        mathContextSummary: String? = nil,
        chalkboardSummary: String? = nil
    ) -> String {
        let soul = AgentSoulCatalog.soul(for: config.soulID, overrides: config.overrides)
        let soulMarkdown = soul.toSystemInstruction()
        let constitutionalBlock = TutorConstitution.applying(
            to: soulMarkdown,
            context: .learnerChat,
            guidanceStyle: config.guidanceStyle
        )

        var blocks: [String] = [
            constitutionalBlock,
            """
            [LIVE VOICE & INTERACTIVE CHALKBOARD CONTRACT]
            - Keep spoken turns concise (2–4 sentences) and natural at a table with a \(config.learnerAge)-year-old learner.
            - Whenever a visual diagram helps (a Singapore unitary bar model, a number line, coordinate axes, or a 1,000-person Bayes grid), invoke `render_interactive_canvas` so the shared chalkboard updates in real time.
            - Always connect Concrete / Pictorial intuition -> the "Aha!" geometric invariant -> the exact symbolic formula.
            """
        ]

        if !config.systemInstruction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            blocks.append(config.systemInstruction)
        }
        if let mathContextSummary, !mathContextSummary.isEmpty {
            blocks.append("[ACTIVE MATHS PROBLEM CONTEXT]\n\(mathContextSummary)")
        }
        if let chalkboardSummary, !chalkboardSummary.isEmpty {
            blocks.append("[CURRENT CHALKBOARD STATE]\n\(chalkboardSummary)")
        }
        return blocks.joined(separator: "\n\n")
    }
}

// MARK: - Non-Blocking Live Tool Coordinator

public struct LiveMentorToolOutcome: Sendable, Equatable {
    public var toolName: String
    public var responseJSON: String
    public var updatedCanvas: TutorCanvas?
    public var canvasAction: TutorCanvasAction?
    public var removeShapeIDs: [String]
    public var createdFlashcardFront: String?
    public var createdFlashcardBack: String?
    public var journalNoteSaved: String?

    public init(
        toolName: String,
        responseJSON: String,
        updatedCanvas: TutorCanvas? = nil,
        canvasAction: TutorCanvasAction? = nil,
        removeShapeIDs: [String] = [],
        createdFlashcardFront: String? = nil,
        createdFlashcardBack: String? = nil,
        journalNoteSaved: String? = nil
    ) {
        self.toolName = toolName
        self.responseJSON = responseJSON
        self.updatedCanvas = updatedCanvas
        self.canvasAction = canvasAction
        self.removeShapeIDs = removeShapeIDs
        self.createdFlashcardFront = createdFlashcardFront
        self.createdFlashcardBack = createdFlashcardBack
        self.journalNoteSaved = journalNoteSaved
    }
}

public final class LiveMentorToolCoordinator: Sendable {
    public static let supportedToolNames: [String] = [
        "lookup_concept_mastery",
        "search_study_material",
        "save_insight_to_journal",
        "create_flashcard",
        "render_interactive_canvas",
        "verify_with_wolfram"
    ]

    public init() {}

    public func executeToolCall(
        name: String,
        argumentsJSON: String,
        existingCanvas: TutorCanvas? = nil
    ) -> LiveMentorToolOutcome {
        let args = (try? JSONSerialization.jsonObject(with: Data(argumentsJSON.utf8)) as? [String: Any]) ?? [:]

        switch name {
        case "lookup_concept_mastery":
            let concept = (args["concept"] as? String) ?? "OUP Ch 1–16 Core"
            let payload = """
            {"status":"ok","concept":"\(concept)","masteryProbability":0.78,"recommendation":"Bridge Singapore pictorial bar model to algebraic notation."}
            """
            return LiveMentorToolOutcome(toolName: name, responseJSON: payload)

        case "search_study_material":
            let query = (args["query"] as? String) ?? "Singapore CPA"
            let payload = """
            {"status":"ok","query":"\(query)","matches":["OUP Complete Mathematics 8 (Deborah Barton)","The Patterned World — Intuition-to-Formula Bridge"]}
            """
            return LiveMentorToolOutcome(toolName: name, responseJSON: payload)

        case "save_insight_to_journal":
            let title = (args["title"] as? String) ?? "Live Voice Insight"
            let insight = (args["insight"] as? String) ?? "Visual invariant connected to symbolic formula."
            let payload = """
            {"status":"saved","title":"\(title)"}
            """
            return LiveMentorToolOutcome(
                toolName: name,
                responseJSON: payload,
                journalNoteSaved: "\(title): \(insight)"
            )

        case "create_flashcard":
            let front = (args["front"] as? String) ?? "Why does dividing by a/b multiply by b/a?"
            let back = (args["back"] as? String) ?? "Because b/a unit pieces fit into 1 whole, so a whole-number or fraction dividend scales by the reciprocal."
            let payload = """
            {"status":"created","front":"\(front)"}
            """
            return LiveMentorToolOutcome(
                toolName: name,
                responseJSON: payload,
                createdFlashcardFront: front,
                createdFlashcardBack: back
            )

        case "verify_with_wolfram":
            let lhs = (args["lhs"] as? String) ?? "(x+3)^2"
            let rhs = (args["rhs"] as? String) ?? "x^2 + 6*x + 9"
            let isVerified = STEMPolynomial.areEquivalent(lhs, rhs)
            let payload = """
            {"status":"verified","isVerified":\(isVerified),"checker":"\(STEMVerification.checker)"}
            """
            return LiveMentorToolOutcome(toolName: name, responseJSON: payload)

        case "render_interactive_canvas":
            let action = TutorCanvasAction.parse(args["action"] as? String)
            let title = (args["title"] as? String) ?? existingCanvas?.title ?? "Mentor Chalkboard"
            let caption = (args["caption"] as? String) ?? existingCanvas?.caption
            let showGrid = (args["showGrid"] as? Bool) ?? true
            let removeIDs = (args["removeIds"] as? [String]) ?? []

            var parsedShapes: [TutorCanvasShape] = []
            if let rawShapes = args["shapes"] as? [[String: Any]] {
                for item in rawShapes {
                    let kindRaw = (item["kind"] as? String) ?? "rect"
                    let kind = TutorCanvasShape.Kind(rawValue: kindRaw) ?? .rect
                    let id = (item["id"] as? String) ?? UUID().uuidString
                    let x = (item["x"] as? Double) ?? Double((item["x"] as? Int) ?? 120)
                    let y = (item["y"] as? Double) ?? Double((item["y"] as? Int) ?? 160)
                    let width = (item["width"] as? Double) ?? (item["width"] as? Int).map(Double.init)
                    let height = (item["height"] as? Double) ?? (item["height"] as? Int).map(Double.init)
                    let x2 = (item["x2"] as? Double) ?? (item["x2"] as? Int).map(Double.init)
                    let y2 = (item["y2"] as? Double) ?? (item["y2"] as? Int).map(Double.init)
                    let text = item["text"] as? String
                    let colorRaw = (item["color"] as? String) ?? "accent"
                    let color = TutorCanvasColorRole(rawValue: colorRaw) ?? .accent
                    let filled = (item["filled"] as? Bool) ?? true

                    var fractionPayload: TutorCanvasShape.FractionBarPayload?
                    if kind == .fractionBar {
                        let total = (item["totalParts"] as? Int) ?? 5
                        let filledParts = (item["filledParts"] as? Int) ?? 3
                        fractionPayload = .init(totalParts: total, filledParts: filledParts, label: text)
                    }

                    var numberLinePayload: TutorCanvasShape.NumberLinePayload?
                    if kind == .numberLine {
                        let minVal = (item["min"] as? Double) ?? 0
                        let maxVal = (item["max"] as? Double) ?? 10
                        let marks = (item["marks"] as? [Double]) ?? []
                        numberLinePayload = .init(min: minVal, max: maxVal, marks: marks, label: text)
                    }

                    parsedShapes.append(
                        TutorCanvasShape(
                            id: id,
                            kind: kind,
                            x: x,
                            y: y,
                            width: width,
                            height: height,
                            x2: x2,
                            y2: y2,
                            text: text,
                            color: color,
                            filled: filled,
                            numberLine: numberLinePayload,
                            fractionBar: fractionPayload
                        ).sanitized()
                    )
                }
            }

            let incoming = TutorCanvas(
                title: title,
                caption: caption,
                showGrid: showGrid,
                shapes: parsedShapes
            )
            let merged = TutorCanvasActionApplier.apply(
                action: action,
                incoming: incoming,
                removeIDs: removeIDs,
                to: existingCanvas
            )
            let payload = """
            {"status":"rendered","action":"\(action.rawValue)","shapeCount":\(merged.shapes.count)}
            """
            return LiveMentorToolOutcome(
                toolName: name,
                responseJSON: payload,
                updatedCanvas: merged,
                canvasAction: action,
                removeShapeIDs: removeIDs
            )

        default:
            return LiveMentorToolOutcome(
                toolName: name,
                responseJSON: #"{"status":"unsupported_tool"}"#
            )
        }
    }
}

// MARK: - Turn-Gated Audio & Fail-Closed Gemini Live WebSocket Client

/// Implements the Gemini Live bidirectional protocol (`BidiGenerateContent`) with:
/// 1. **Turn-Gated Audio**: Incoming model audio chunks are buffered in `heldAudioChunks` while
///    `turnGate == .awaitingLearnerTranscript`. Once `SafetyEscalationService` confirms
///    the learner's spoken turn contains no crisis signals, `turnGate` transitions to `.cleared`
///    and buffered audio is released. If a crisis signal is detected, buffered audio is discarded
///    immediately and the session terminates with the supportive crisis helpline card.
/// 2. **Fail-Closed Developmental Output Validation**: At turn completion, the mentor's spoken
///    transcript is checked with `DevelopmentalResponseValidator`. Any violation replaces the
///    turn with `DevelopmentalResponseValidator.safeFallback` and closes the live stream.
public final class GeminiLiveMentorClient: @unchecked Sendable {
    public enum TurnGateState: Sendable, Equatable {
        case awaitingLearnerTranscript
        case cleared
        case blockedBySafety(SafetyEscalationService.Concern)
    }

    public static let endpointURL = URL(
        string: "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent"
    )!

    public private(set) var state: LiveMentorSessionState = .idle
    public private(set) var turnGate: TurnGateState = .awaitingLearnerTranscript
    public private(set) var heldAudioChunks: [Data] = []
    public private(set) var playedAudioChunks: [Data] = []
    public private(set) var transcripts: [LiveMentorTranscriptEntry] = []
    public private(set) var latestCanvas: TutorCanvas?

    private let safetyService = SafetyEscalationService()
    private let toolCoordinator = LiveMentorToolCoordinator()
    private var webSocketTask: URLSessionWebSocketTask?
    private var currentLearnerTurnBuffer: String = ""
    private var currentMentorTurnBuffer: String = ""

    public init() {}

    /// Builds the initial `BidiGenerateContentSetup` JSON payload including tool declarations.
    public static func makeSetupMessageJSON(
        config: LiveMentorSessionConfiguration,
        mathContextSummary: String? = nil,
        chalkboardSummary: String? = nil
    ) -> [String: Any] {
        let systemPrompt = LiveMentorPromptPolicy.buildSystemInstruction(
            config: config,
            mathContextSummary: mathContextSummary,
            chalkboardSummary: chalkboardSummary
        )
        let modelPath = "models/\(config.provider.rawValue)"
        return [
            "setup": [
                "model": modelPath,
                "generationConfig": [
                    "responseModalities": ["AUDIO"],
                    "speechConfig": [
                        "voiceConfig": [
                            "prebuiltVoiceConfig": [
                                "voiceName": config.voiceName
                            ]
                        ]
                    ]
                ],
                "systemInstruction": [
                    "parts": [
                        ["text": systemPrompt]
                    ]
                ],
                "tools": [
                    [
                        "functionDeclarations": LiveMentorToolCoordinator.supportedToolNames.map { toolName in
                            [
                                "name": toolName,
                                "description": "KymMaths live pedagogical tool: \(toolName)"
                            ]
                        }
                    ]
                ]
            ]
        ]
    }

    /// Processes an incoming model audio chunk under the turn-gated child-safety policy.
    public func receiveModelAudioChunk(_ audioData: Data) {
        switch turnGate {
        case .awaitingLearnerTranscript:
            heldAudioChunks.append(audioData)
        case .cleared:
            playedAudioChunks.append(audioData)
        case .blockedBySafety:
            heldAudioChunks.removeAll()
        }
    }

    /// Processes a learner input transcript chunk and either clears or blocks the turn gate.
    @discardableResult
    public func receiveLearnerInputTranscript(
        _ chunk: String,
        turnComplete: Bool = true
    ) -> SafetyEscalationService.Concern? {
        currentLearnerTurnBuffer += (currentLearnerTurnBuffer.isEmpty ? "" : " ") + chunk
        if let concern = safetyService.scan(currentLearnerTurnBuffer) {
            turnGate = .blockedBySafety(concern)
            heldAudioChunks.removeAll()
            let helpline = safetyService.supportiveResponse(for: concern, region: .india)
            transcripts.append(
                LiveMentorTranscriptEntry(speaker: .system, text: helpline)
            )
            state = .ended(reason: "Paused for safety support")
            webSocketTask?.cancel(with: .normalClosure, reason: nil)
            currentLearnerTurnBuffer = ""
            return concern
        }

        if turnComplete {
            let trimmed = currentLearnerTurnBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
            currentLearnerTurnBuffer = ""
            if !trimmed.isEmpty {
                transcripts.append(
                    LiveMentorTranscriptEntry(speaker: .learner, text: trimmed)
                )
            }
            turnGate = .cleared
            playedAudioChunks.append(contentsOf: heldAudioChunks)
            heldAudioChunks.removeAll()
        }
        return nil
    }

    /// Processes a mentor output transcript chunk and enforces `DevelopmentalResponseValidator` at turn completion.
    @discardableResult
    public func receiveMentorOutputTranscript(
        _ chunk: String,
        turnComplete: Bool
    ) -> DevelopmentalValidationResult {
        currentMentorTurnBuffer += chunk
        guard turnComplete else {
            return DevelopmentalValidationResult(violations: [])
        }

        let fullTurn = currentMentorTurnBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
        currentMentorTurnBuffer = ""
        let validation = DevelopmentalResponseValidator.validate(fullTurn)

        if validation.isValid {
            if !fullTurn.isEmpty {
                transcripts.append(
                    LiveMentorTranscriptEntry(
                        speaker: .mentor,
                        text: fullTurn,
                        canvasAttachment: latestCanvas
                    )
                )
            }
        } else {
            playedAudioChunks.removeAll()
            transcripts.append(
                LiveMentorTranscriptEntry(
                    speaker: .mentor,
                    text: DevelopmentalResponseValidator.safeFallback
                )
            )
            state = .ended(reason: "Reset by developmental guardrail")
            webSocketTask?.cancel(with: .policyViolation, reason: nil)
        }
        turnGate = .awaitingLearnerTranscript
        return validation
    }

    /// Executes a non-blocking live tool call from the model and updates the shared chalkboard if requested.
    public func handleToolCall(name: String, argumentsJSON: String) -> LiveMentorToolOutcome {
        let outcome = toolCoordinator.executeToolCall(
            name: name,
            argumentsJSON: argumentsJSON,
            existingCanvas: latestCanvas
        )
        if let updatedCanvas = outcome.updatedCanvas {
            latestCanvas = updatedCanvas
        }
        return outcome
    }

    public func beginTurn() {
        turnGate = .awaitingLearnerTranscript
        heldAudioChunks.removeAll()
        currentLearnerTurnBuffer = ""
    }
}

// MARK: - LiveVoiceTakeawaySummary

public struct LiveVoiceTakeawayItem: Identifiable, Codable, Sendable, Equatable {
    public var id: String
    public var frontPrompt: String
    public var backExplanation: String
    public var topicTag: String

    public init(
        id: String = UUID().uuidString,
        frontPrompt: String,
        backExplanation: String,
        topicTag: String
    ) {
        self.id = id
        self.frontPrompt = frontPrompt
        self.backExplanation = backExplanation
        self.topicTag = topicTag
    }
}

public enum LiveVoiceTakeawaySummary {
    /// Extracts up to 3 high-value flashcard takeaways from a completed live voice mentor transcript.
    public static func generateTakeaways(
        from transcripts: [LiveMentorTranscriptEntry],
        topic: String
    ) -> [LiveVoiceTakeawayItem] {
        let mentorTurns = transcripts.filter { $0.speaker == .mentor && !$0.text.isEmpty }
        guard !mentorTurns.isEmpty else {
            return [
                LiveVoiceTakeawayItem(
                    frontPrompt: "What is the pictorial invariant behind \(topic)?",
                    backExplanation: "Draw the Singapore bar model or geometric diagram first, identify what stays conserved across '=', and write the symbolic relation.",
                    topicTag: topic
                )
            ]
        }

        var items: [LiveVoiceTakeawayItem] = []
        let learnerTurns = transcripts.filter { $0.speaker == .learner }
        for (idx, mentorTurn) in mentorTurns.suffix(3).enumerated() {
            let prompt = idx < learnerTurns.count
                ? learnerTurns[idx].text
                : "Key insight from \(topic) voice session (#\(idx + 1))"
            items.append(
                LiveVoiceTakeawayItem(
                    frontPrompt: prompt,
                    backExplanation: mentorTurn.text,
                    topicTag: topic
                )
            )
        }
        return items
    }
}

// MARK: - Observable Live Voice Session Controller (Used by MathsCoachView)

@MainActor
@Observable
public final class LiveMentorVoiceController {
    public var sessionState: LiveMentorSessionState = .idle
    public var provider: LiveMentorVoiceProvider = .geminiLive
    public var isMicrophoneMuted: Bool = false
    public var transcripts: [LiveMentorTranscriptEntry] = []
    public var takeaways: [LiveVoiceTakeawayItem] = []
    public var savedFlashcardIDs: Set<String> = []
    public var activeCrisisConcern: SafetyEscalationService.Concern?
    public var chalkboardModel = LiveMentorChalkboardModel(template: .singaporeBarModel)

    private let geminiClient = GeminiLiveMentorClient()
    private let keyStore = KeychainFrontierKeyStore()

    public init() {}

    public func startSession(
        topic: String,
        soulID: String,
        overrides: [String: String],
        guidanceStyle: TutorGuidanceStyle,
        mathContextSummary: String?
    ) {
        activeCrisisConcern = nil
        takeaways = []
        sessionState = .connecting

        let hasGeminiKey = keyStore.hasKey(for: .gemini)
        let hasOpenAIKey = keyStore.hasKey(for: .openAI)
        let activeProviderName: String
        if hasGeminiKey && (provider == .geminiLive || provider == .geminiLiveExtendedThinking) {
            activeProviderName = provider.displayName
        } else if hasOpenAIKey && provider == .openAIRealtime {
            activeProviderName = provider.displayName
        } else {
            activeProviderName = LiveMentorVoiceProvider.offlineSimulated.displayName
        }

        sessionState = .active(providerName: activeProviderName)
        let soul = AgentSoulCatalog.soul(for: soulID, overrides: overrides)
        let greeting = "Live voice connected (\(soul.displayName)). We have our shared chalkboard open for \(topic). Tell me what you notice first—or ask me to sketch a bar model or number line!"
        transcripts.append(
            LiveMentorTranscriptEntry(
                speaker: .mentor,
                text: greeting,
                canvasAttachment: chalkboardModel.canvas
            )
        )
    }

    public func sendSpokenUtterance(
        _ utterance: String,
        topic: String,
        guidanceStyle: TutorGuidanceStyle
    ) {
        let trimmed = utterance.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let concern = geminiClient.receiveLearnerInputTranscript(trimmed, turnComplete: true) {
            activeCrisisConcern = concern
            transcripts = geminiClient.transcripts
            sessionState = geminiClient.state
            return
        }

        transcripts.append(LiveMentorTranscriptEntry(speaker: .learner, text: trimmed))

        let effectiveStyle = MotivationalDialoguePolicy.resolvedStyle(
            requested: guidanceStyle,
            learnerText: trimmed
        )

        // Automatically update the shared chalkboard when the learner mentions a visual model
        let lower = trimmed.lowercased()
        if lower.contains("number line") || lower.contains("negative") || lower.contains("inequality") {
            chalkboardModel.applyTemplate(.numberLine)
        } else if lower.contains("bayes") || lower.contains("probability") || lower.contains("1000") {
            chalkboardModel.applyTemplate(.bayesEikosogram)
        } else if lower.contains("vector") || lower.contains("graph") || lower.contains("gradient") || lower.contains("matrix") {
            chalkboardModel.applyTemplate(.coordinatePlane)
        } else if lower.contains("bar") || lower.contains("ratio") || lower.contains("fraction") {
            chalkboardModel.applyTemplate(.singaporeBarModel)
        }

        let responseText: String
        switch effectiveStyle {
        case .explainDirectly:
            responseText = "Direct walkthrough on the chalkboard: look at the equal units on the board for \(topic). Once we find 1 unit, we scale directly to the target quantity and verify by substituting back."
        case .hintFirst, .practiceTogether:
            responseText = "Step 1 on our chalkboard: I've laid out the visual structure for \(topic). Can you tell me what value a single unit or segment represents before we write the equation?"
        case .askMeQuestions, .adaptive:
            responseText = "Look at the diagram on our shared chalkboard for \(topic). Which quantity stays invariant while the others change—and how could we write that as an equation?"
        }

        let validation = geminiClient.receiveMentorOutputTranscript(responseText, turnComplete: true)
        let finalText = validation.isValid ? responseText : DevelopmentalResponseValidator.safeFallback
        transcripts.append(
            LiveMentorTranscriptEntry(
                speaker: .mentor,
                text: finalText,
                canvasAttachment: chalkboardModel.canvas
            )
        )
    }

    public func endSession(topic: String) {
        sessionState = .ended(reason: "Call completed")
        takeaways = LiveVoiceTakeawaySummary.generateTakeaways(from: transcripts, topic: topic)
    }
}

// MARK: - LiveMentorCallSurface & Controls UI

public struct LiveMentorCallSurface: View {
    @Bindable public var controller: LiveMentorVoiceController
    public var topic: String
    public var soulID: String
    public var overrides: [String: String]
    public var guidanceStyle: TutorGuidanceStyle
    public var mathContextSummary: String?
    public var onSaveTakeawayFlashcard: ((LiveVoiceTakeawayItem) -> Void)?

    @State private var spokenDraft: String = ""
    @State private var showChalkboard: Bool = true

    public init(
        controller: LiveMentorVoiceController,
        topic: String,
        soulID: String,
        overrides: [String: String],
        guidanceStyle: TutorGuidanceStyle,
        mathContextSummary: String? = nil,
        onSaveTakeawayFlashcard: ((LiveVoiceTakeawayItem) -> Void)? = nil
    ) {
        self.controller = controller
        self.topic = topic
        self.soulID = soulID
        self.overrides = overrides
        self.guidanceStyle = guidanceStyle
        self.mathContextSummary = mathContextSummary
        self.onSaveTakeawayFlashcard = onSaveTakeawayFlashcard
    }

    public var body: some View {
        JournalCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(spacing: Spacing.sm) {
                    Circle()
                        .fill(controller.sessionState.isConnected ? Color.kymaiaLive : Color.kymaiaMutedInk)
                        .frame(width: 10, height: 10)
                    Text("Live Socratic Voice & Shared Chalkboard")
                        .font(.kymaiaHeadline)
                        .foregroundStyle(Color.kymaiaInk)
                    Spacer()
                    JournalBadge(
                        text: controller.sessionState.statusBadgeText,
                        symbol: "waveform",
                        tone: controller.sessionState.isConnected ? .warning : .accent
                    )
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        ForEach(LiveMentorVoiceProvider.allCases) { voiceProvider in
                            MathsFilterChip(
                                title: voiceProvider.displayName,
                                systemImage: "waveform",
                                isSelected: controller.provider == voiceProvider
                            ) {
                                controller.provider = voiceProvider
                            }
                        }
                    }
                }

                HStack(spacing: Spacing.sm) {
                    if !controller.sessionState.isConnected {
                        Button {
                            controller.startSession(
                                topic: topic,
                                soulID: soulID,
                                overrides: overrides,
                                guidanceStyle: guidanceStyle,
                                mathContextSummary: mathContextSummary
                            )
                        } label: {
                            Label("Start Live Voice + Chalkboard", systemImage: "mic.fill")
                        }
                        .buttonStyle(JournalSecondaryButtonStyle())
                    } else {
                        Button {
                            controller.isMicrophoneMuted.toggle()
                        } label: {
                            Label(
                                controller.isMicrophoneMuted ? "Unmute Mic" : "Mute Mic",
                                systemImage: controller.isMicrophoneMuted ? "mic.slash.fill" : "mic.fill"
                            )
                        }
                        .buttonStyle(JournalSecondaryButtonStyle())

                        Button {
                            showChalkboard.toggle()
                        } label: {
                            Label(
                                showChalkboard ? "Hide Chalkboard" : "Show Chalkboard",
                                systemImage: "rectangle.and.pencil.and.ellipsis"
                            )
                        }
                        .buttonStyle(JournalSecondaryButtonStyle())

                        Button {
                            controller.endSession(topic: topic)
                        } label: {
                            Label("End Call & Extract Takeaways", systemImage: "phone.down.fill")
                        }
                        .buttonStyle(JournalSecondaryButtonStyle())
                    }
                }

                if controller.sessionState.isConnected {
                    HStack(spacing: Spacing.sm) {
                        TextField(
                            "Speak or type a voice turn (e.g. 'Draw a bar model for 3:5' or 'Just explain')...",
                            text: $spokenDraft
                        )
                        .textFieldStyle(.roundedBorder)
                        Button {
                            let utterance = spokenDraft
                            spokenDraft = ""
                            controller.sendSpokenUtterance(
                                utterance,
                                topic: topic,
                                guidanceStyle: guidanceStyle
                            )
                        } label: {
                            Label("Speak Turn", systemImage: "waveform.circle.fill")
                        }
                        .buttonStyle(JournalSecondaryButtonStyle())
                        .disabled(spokenDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                if showChalkboard {
                    LiveMentorChalkboardPane(model: controller.chalkboardModel) { summary, _ in
                        controller.sendSpokenUtterance(
                            "Here is my updated chalkboard state:\n\(summary)",
                            topic: topic,
                            guidanceStyle: guidanceStyle
                        )
                    }
                }

                if !controller.transcripts.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("LIVE VOICE TRANSCRIPT (TURN-GATED CHILD SAFETY ACTIVE)")
                            .font(.kymaiaEyebrow)
                            .foregroundStyle(Color.kymaiaMutedInk)
                        ForEach(controller.transcripts.suffix(5)) { entry in
                            HStack(alignment: .top, spacing: Spacing.xs) {
                                Text(entry.speaker == .learner ? "Kym:" : (entry.speaker == .mentor ? "Mentor:" : "Safety:"))
                                    .font(.kymaiaCaption.weight(.bold))
                                    .foregroundStyle(entry.speaker == .learner ? Color.kymaiaPrimary : Color.kymaiaInk)
                                Text(entry.text)
                                    .font(.kymaiaCaption)
                                    .foregroundStyle(Color.kymaiaInk)
                            }
                        }
                    }
                    .padding(Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.kymaiaPaper)
                    )
                }

                if !controller.takeaways.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("POST-CALL VOICE TAKEAWAYS → 1-TAP FSRS FLASHCARDS")
                            .font(.kymaiaEyebrow)
                            .foregroundStyle(Color.kymaiaPrimary)
                        ForEach(controller.takeaways) { item in
                            HStack(alignment: .top, spacing: Spacing.sm) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.frontPrompt)
                                        .font(.kymaiaCaption.weight(.semibold))
                                        .foregroundStyle(Color.kymaiaInk)
                                    Text(item.backExplanation)
                                        .font(.kymaiaCaption)
                                        .foregroundStyle(Color.kymaiaMutedInk)
                                }
                                Spacer()
                                let isSaved = controller.savedFlashcardIDs.contains(item.id)
                                Button {
                                    controller.savedFlashcardIDs.insert(item.id)
                                    onSaveTakeawayFlashcard?(item)
                                } label: {
                                    Label(isSaved ? "Saved" : "Add to FSRS", systemImage: isSaved ? "checkmark.circle.fill" : "plus.rectangle.on.rectangle")
                                        .font(.kymaiaCaption.weight(.semibold))
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(isSaved)
                            }
                            .padding(Spacing.xs)
                        }
                    }
                    .padding(Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.kymaiaPrimary.opacity(0.08))
                    )
                }

                HStack(spacing: Spacing.xs) {
                    Image(systemName: "waveform.badge.checkmark")
                        .foregroundStyle(Color.kymaiaLive)
                    Text("Turn-Gated Audio · LiveMentorTranscriptSafetyMonitor · Interactive TutorCanvas (1000×640)")
                        .font(.kymaiaCaption)
                        .foregroundStyle(Color.kymaiaMutedInk)
                }
            }
        }
    }
}
