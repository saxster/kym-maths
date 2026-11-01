import Foundation
import Security

// MARK: - AI Provider & Routing Policies (Ported from ../kym_tutor)

public enum AIProvider: String, Codable, CaseIterable, Identifiable, Sendable {
    case auto
    case local
    case gemini
    case anthropic
    case openAI = "openai"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .auto: return "Auto (Policy-Driven)"
        case .local: return "On-Device Local Engine"
        case .gemini: return "Google Gemini"
        case .anthropic: return "Anthropic Claude"
        case .openAI: return "OpenAI"
        }
    }
}

public enum AIFeaturePolicy: String, Codable, CaseIterable, Identifiable, Sendable {
    case localOnly
    case localPreferred
    case frontierPreferred
    case frontierOnly

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .localOnly: return "Local Only (Strict Offline)"
        case .localPreferred: return "Local Preferred (Frontier Fallback)"
        case .frontierPreferred: return "Frontier Preferred (Local Fallback)"
        case .frontierOnly: return "Frontier Only"
        }
    }
}

public enum AIProviderRoute: String, Codable, Sendable, Equatable {
    case local
    case frontier
}

public enum AIProviderCapability: String, Codable, Sendable, Equatable {
    case text
    case structuredJSON = "structured_json"
    case grounding
    case vision
}

public enum AIProviderOutcome: String, Codable, Sendable, Equatable {
    case success
    case failure
}

public struct MultimodalImage: Sendable, Equatable {
    public let data: Data
    public let mimeType: String

    public init(data: Data, mimeType: String = "image/jpeg") {
        self.data = data
        self.mimeType = mimeType
    }
}

public struct AIProviderProvenance: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID = UUID()
    public let featureKey: AIFeatureKey
    public let requestedProvider: AIProvider
    public let requestedPolicy: AIFeaturePolicy
    public let actualProvider: AIProvider?
    public let actualModel: String?
    public let route: AIProviderRoute
    public let capability: AIProviderCapability
    public let fallbackReason: String?
    public let latencyMs: Int
    public let outcome: AIProviderOutcome
    public let failureReason: String?
    public let policyVersion: String
    public let constitutionHash: String
    public let audience: AIAudience
    public let interaction: AIInteractionKind
    public let guidanceStyle: TutorGuidanceStyle?
    public let dialogueSupportMode: AIDialogueSupportMode?
    public let timestamp: Date

    public init(
        featureKey: AIFeatureKey,
        requestedProvider: AIProvider,
        requestedPolicy: AIFeaturePolicy,
        actualProvider: AIProvider?,
        actualModel: String?,
        route: AIProviderRoute,
        capability: AIProviderCapability,
        fallbackReason: String?,
        latencyMs: Int,
        outcome: AIProviderOutcome,
        failureReason: String?,
        policyVersion: String,
        constitutionHash: String,
        audience: AIAudience,
        interaction: AIInteractionKind,
        guidanceStyle: TutorGuidanceStyle?,
        dialogueSupportMode: AIDialogueSupportMode?,
        timestamp: Date = Date()
    ) {
        self.featureKey = featureKey
        self.requestedProvider = requestedProvider
        self.requestedPolicy = requestedPolicy
        self.actualProvider = actualProvider
        self.actualModel = actualModel
        self.route = route
        self.capability = capability
        self.fallbackReason = fallbackReason
        self.latencyMs = latencyMs
        self.outcome = outcome
        self.failureReason = failureReason
        self.policyVersion = policyVersion
        self.constitutionHash = constitutionHash
        self.audience = audience
        self.interaction = interaction
        self.guidanceStyle = guidanceStyle
        self.dialogueSupportMode = dialogueSupportMode
        self.timestamp = timestamp
    }
}

// MARK: - Keychain Frontier Key Store

public protocol FrontierKeyChecking: Sendable {
    func hasKey(for provider: AIProvider) -> Bool
    func apiKey(for provider: AIProvider) -> String?
}

public struct KeychainFrontierKeyStore: FrontierKeyChecking, Sendable {
    private static let serviceName = "com.kymmaths.app.apikeys"

    public init() {}

    public func hasKey(for provider: AIProvider) -> Bool {
        guard let key = apiKey(for: provider) else { return false }
        return !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public func apiKey(for provider: AIProvider) -> String? {
        let account = provider.rawValue
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data, let text = String(data: data, encoding: .utf8) {
            return text
        }
        // Fallback to environment variable for CLI/testing
        let envName: String
        switch provider {
        case .gemini: envName = "GEMINI_API_KEY"
        case .anthropic: envName = "ANTHROPIC_API_KEY"
        case .openAI: envName = "OPENAI_API_KEY"
        case .auto, .local: return nil
        }
        return ProcessInfo.processInfo.environment[envName]
    }

    @discardableResult
    public func saveKey(_ key: String, for provider: AIProvider) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        let account = provider.rawValue
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        guard !trimmed.isEmpty, let data = trimmed.data(using: .utf8) else { return true }
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
    }
}

// MARK: - Provider Selection Service

public struct AIProviderSelection: Sendable, Equatable {
    public let route: AIProviderRoute
    public let provider: AIProvider
    public let fallbackFrontierProvider: AIProvider?
    public let fallbackToFrontierAllowed: Bool
    public let fallbackToLocalAllowed: Bool
}

public struct AIProviderSelectionService: Sendable {
    public init() {}

    public func selectTextProvider(
        requestedProvider: AIProvider,
        defaultProvider: AIProvider,
        policy: AIFeaturePolicy,
        keyChecker: any FrontierKeyChecking
    ) -> AIProviderSelection {
        let candidateFrontier: [AIProvider] = [.gemini, .anthropic, .openAI]
        let keyedFrontiers = candidateFrontier.filter { keyChecker.hasKey(for: $0) }

        let preferredFrontier: AIProvider = {
            if requestedProvider != .auto && requestedProvider != .local && keyChecker.hasKey(for: requestedProvider) {
                return requestedProvider
            }
            if defaultProvider != .auto && defaultProvider != .local && keyChecker.hasKey(for: defaultProvider) {
                return defaultProvider
            }
            return keyedFrontiers.first ?? .gemini
        }()

        let standbyFrontier = keyedFrontiers.first(where: { $0 != preferredFrontier })

        switch policy {
        case .localOnly:
            return AIProviderSelection(
                route: .local,
                provider: .local,
                fallbackFrontierProvider: nil,
                fallbackToFrontierAllowed: false,
                fallbackToLocalAllowed: true
            )
        case .localPreferred:
            return AIProviderSelection(
                route: .local,
                provider: .local,
                fallbackFrontierProvider: standbyFrontier,
                fallbackToFrontierAllowed: !keyedFrontiers.isEmpty,
                fallbackToLocalAllowed: true
            )
        case .frontierPreferred:
            guard !keyedFrontiers.isEmpty else {
                return AIProviderSelection(
                    route: .local,
                    provider: .local,
                    fallbackFrontierProvider: nil,
                    fallbackToFrontierAllowed: false,
                    fallbackToLocalAllowed: true
                )
            }
            return AIProviderSelection(
                route: .frontier,
                provider: preferredFrontier,
                fallbackFrontierProvider: standbyFrontier,
                fallbackToFrontierAllowed: true,
                fallbackToLocalAllowed: true
            )
        case .frontierOnly:
            return AIProviderSelection(
                route: .frontier,
                provider: preferredFrontier,
                fallbackFrontierProvider: standbyFrontier,
                fallbackToFrontierAllowed: true,
                fallbackToLocalAllowed: false
            )
        }
    }
}

// MARK: - AI Provider Protocol & Constitutional Learner-Facing Extensions

public protocol AIProviderProtocol: Sendable {
    func generateText(
        prompt: String,
        systemInstruction: String?,
        provider: AIProvider,
        model: String?,
        jsonMode: Bool,
        useGrounding: Bool,
        requestContext: AIRequestContext
    ) async throws -> String

    func generateFromImage(
        prompt: String,
        images: [MultimodalImage],
        systemInstruction: String?,
        jsonMode: Bool,
        requestContext: AIRequestContext
    ) async throws -> String
}

extension AIProviderProtocol {
    public func generateLearnerFacingText(
        prompt: String,
        systemInstruction: String,
        provider: AIProvider = .auto,
        model: String? = nil,
        useGrounding: Bool = false,
        requestContext: AIRequestContext = .learnerChat
    ) async throws -> String {
        let draft = try await generateText(
            prompt: prompt,
            systemInstruction: systemInstruction,
            provider: provider,
            model: model,
            jsonMode: false,
            useGrounding: useGrounding,
            requestContext: requestContext
        )
        let firstReview = DevelopmentalResponseValidator.validate(draft)
        guard !firstReview.isValid else { return draft }

        let revisionPrompt = prompt + "\n\n" + DevelopmentalResponseValidator.revisionInstruction(for: firstReview)
        let revision = try await generateText(
            prompt: revisionPrompt,
            systemInstruction: systemInstruction,
            provider: provider,
            model: model,
            jsonMode: false,
            useGrounding: useGrounding,
            requestContext: requestContext
        )
        let secondReview = DevelopmentalResponseValidator.validate(revision)
        if secondReview.isValid {
            return revision
        }
        return DevelopmentalResponseValidator.safeFallback
    }

    public func generateLearnerFacingFromImage(
        prompt: String,
        images: [MultimodalImage],
        systemInstruction: String,
        requestContext: AIRequestContext = .questionTutor
    ) async throws -> String {
        let draft = try await generateFromImage(
            prompt: prompt,
            images: images,
            systemInstruction: systemInstruction,
            jsonMode: false,
            requestContext: requestContext
        )
        let firstReview = DevelopmentalResponseValidator.validate(draft)
        guard !firstReview.isValid else { return draft }

        let revisionPrompt = prompt + "\n\n" + DevelopmentalResponseValidator.revisionInstruction(for: firstReview)
        let revision = try await generateFromImage(
            prompt: revisionPrompt,
            images: images,
            systemInstruction: systemInstruction,
            jsonMode: false,
            requestContext: requestContext
        )
        let secondReview = DevelopmentalResponseValidator.validate(revision)
        if secondReview.isValid {
            return revision
        }
        return DevelopmentalResponseValidator.safeFallback
    }
}

// MARK: - Policy-Driven AI Provider (Ported from ../kym_tutor)

public actor PolicyDrivenAIProvider: AIProviderProtocol {
    private let localProvider: any AIProviderProtocol
    private let frontierProvider: any AIProviderProtocol
    private let selectionService: AIProviderSelectionService
    private let keyChecker: any FrontierKeyChecking
    private var defaultPolicy: AIFeaturePolicy
    private var defaultProvider: AIProvider
    private var allowRemoteCameraAIAnalysis: Bool
    private(set) var provenanceLog: [AIProviderProvenance] = []

    public init(
        localProvider: any AIProviderProtocol,
        frontierProvider: any AIProviderProtocol,
        selectionService: AIProviderSelectionService = AIProviderSelectionService(),
        keyChecker: any FrontierKeyChecking = KeychainFrontierKeyStore(),
        defaultPolicy: AIFeaturePolicy = .localPreferred,
        defaultProvider: AIProvider = .auto,
        allowRemoteCameraAIAnalysis: Bool = false
    ) {
        self.localProvider = localProvider
        self.frontierProvider = frontierProvider
        self.selectionService = selectionService
        self.keyChecker = keyChecker
        self.defaultPolicy = defaultPolicy
        self.defaultProvider = defaultProvider
        self.allowRemoteCameraAIAnalysis = allowRemoteCameraAIAnalysis
    }

    public func updateConfiguration(
        policy: AIFeaturePolicy,
        defaultProvider: AIProvider,
        allowRemoteCameraAIAnalysis: Bool
    ) {
        self.defaultPolicy = policy
        self.defaultProvider = defaultProvider
        self.allowRemoteCameraAIAnalysis = allowRemoteCameraAIAnalysis
    }

    public func recentProvenance() -> [AIProviderProvenance] {
        provenanceLog
    }

    public static func routingSummary(
        requestedProvider: AIProvider,
        policy: AIFeaturePolicy,
        selection: AIProviderSelection
    ) -> String {
        let requested = "requested=\(requestedProvider.rawValue)"
        let policyPart = "policy=\(policy.rawValue)"
        let routePart = "route=\(selection.route.rawValue)"
        let providerPart = "provider=\(selection.provider.rawValue)"
        return "\(requested) \(policyPart) \(routePart) \(providerPart)"
    }

    public func describeTextRouting(
        requestedProvider: AIProvider,
        requestContext: AIRequestContext = .learnerChat
    ) -> String {
        let selection = selectionService.selectTextProvider(
            requestedProvider: requestedProvider,
            defaultProvider: defaultProvider,
            policy: defaultPolicy,
            keyChecker: keyChecker
        )
        return Self.routingSummary(
            requestedProvider: requestedProvider,
            policy: defaultPolicy,
            selection: selection
        )
    }

    public func generateText(
        prompt: String,
        systemInstruction: String?,
        provider: AIProvider,
        model: String?,
        jsonMode: Bool,
        useGrounding: Bool,
        requestContext: AIRequestContext
    ) async throws -> String {
        let startedAt = Date()
        let guidanceStyle = requestContext.guidanceStyle ?? .adaptive
        let protectedInstruction = TutorConstitution.applying(
            to: systemInstruction,
            context: requestContext,
            guidanceStyle: guidanceStyle
        )
        let policy = defaultPolicy
        let selection = selectionService.selectTextProvider(
            requestedProvider: provider,
            defaultProvider: defaultProvider,
            policy: policy,
            keyChecker: keyChecker
        )
        let capability: AIProviderCapability = useGrounding ? .grounding : (jsonMode ? .structuredJSON : .text)

        do {
            let text: String
            let actualProvider: AIProvider
            let route: AIProviderRoute
            var fallbackReason: String?

            switch selection.route {
            case .local:
                do {
                    text = try await localProvider.generateText(
                        prompt: prompt,
                        systemInstruction: protectedInstruction,
                        provider: .local,
                        model: model,
                        jsonMode: jsonMode,
                        useGrounding: useGrounding,
                        requestContext: requestContext
                    )
                    actualProvider = .local
                    route = .local
                } catch {
                    guard selection.fallbackToFrontierAllowed else { throw error }
                    fallbackReason = error.localizedDescription
                    text = try await frontierProvider.generateText(
                        prompt: prompt,
                        systemInstruction: protectedInstruction,
                        provider: .gemini,
                        model: model,
                        jsonMode: jsonMode,
                        useGrounding: useGrounding,
                        requestContext: requestContext
                    )
                    actualProvider = .gemini
                    route = .frontier
                }
            case .frontier:
                do {
                    text = try await frontierProvider.generateText(
                        prompt: prompt,
                        systemInstruction: protectedInstruction,
                        provider: selection.provider,
                        model: model,
                        jsonMode: jsonMode,
                        useGrounding: useGrounding,
                        requestContext: requestContext
                    )
                    actualProvider = selection.provider
                    route = .frontier
                } catch {
                    fallbackReason = error.localizedDescription
                    if let standby = selection.fallbackFrontierProvider {
                        do {
                            text = try await frontierProvider.generateText(
                                prompt: prompt,
                                systemInstruction: protectedInstruction,
                                provider: standby,
                                model: nil,
                                jsonMode: jsonMode,
                                useGrounding: useGrounding,
                                requestContext: requestContext
                            )
                            actualProvider = standby
                            route = .frontier
                        } catch {
                            guard selection.fallbackToLocalAllowed else { throw error }
                            text = try await localProvider.generateText(
                                prompt: prompt,
                                systemInstruction: protectedInstruction,
                                provider: .local,
                                model: model,
                                jsonMode: jsonMode,
                                useGrounding: useGrounding,
                                requestContext: requestContext
                            )
                            actualProvider = .local
                            route = .local
                        }
                    } else {
                        guard selection.fallbackToLocalAllowed else { throw error }
                        text = try await localProvider.generateText(
                            prompt: prompt,
                            systemInstruction: protectedInstruction,
                            provider: .local,
                            model: model,
                            jsonMode: jsonMode,
                            useGrounding: useGrounding,
                            requestContext: requestContext
                        )
                        actualProvider = .local
                        route = .local
                    }
                }
            }

            let latency = Int(Date().timeIntervalSince(startedAt) * 1000)
            provenanceLog.append(
                AIProviderProvenance(
                    featureKey: requestContext.feature,
                    requestedProvider: provider,
                    requestedPolicy: policy,
                    actualProvider: actualProvider,
                    actualModel: route == .local ? "kymmaths-local-v1" : model,
                    route: route,
                    capability: capability,
                    fallbackReason: fallbackReason,
                    latencyMs: latency,
                    outcome: .success,
                    failureReason: nil,
                    policyVersion: requestContext.policyVersion,
                    constitutionHash: TutorConstitution.policyHash,
                    audience: requestContext.audience,
                    interaction: requestContext.interaction,
                    guidanceStyle: requestContext.guidanceStyle,
                    dialogueSupportMode: requestContext.dialogueSupportMode
                )
            )
            return text
        } catch {
            let latency = Int(Date().timeIntervalSince(startedAt) * 1000)
            provenanceLog.append(
                AIProviderProvenance(
                    featureKey: requestContext.feature,
                    requestedProvider: provider,
                    requestedPolicy: policy,
                    actualProvider: selection.provider,
                    actualModel: nil,
                    route: selection.route,
                    capability: capability,
                    fallbackReason: nil,
                    latencyMs: latency,
                    outcome: .failure,
                    failureReason: error.localizedDescription,
                    policyVersion: requestContext.policyVersion,
                    constitutionHash: TutorConstitution.policyHash,
                    audience: requestContext.audience,
                    interaction: requestContext.interaction,
                    guidanceStyle: requestContext.guidanceStyle,
                    dialogueSupportMode: requestContext.dialogueSupportMode
                )
            )
            throw error
        }
    }

    public func generateFromImage(
        prompt: String,
        images: [MultimodalImage],
        systemInstruction: String?,
        jsonMode: Bool,
        requestContext: AIRequestContext
    ) async throws -> String {
        let guidanceStyle = requestContext.guidanceStyle ?? .adaptive
        let protectedInstruction = TutorConstitution.applying(
            to: systemInstruction,
            context: requestContext,
            guidanceStyle: guidanceStyle
        )
        switch defaultPolicy {
        case .localOnly:
            return try await localProvider.generateFromImage(
                prompt: prompt,
                images: images,
                systemInstruction: protectedInstruction,
                jsonMode: jsonMode,
                requestContext: requestContext
            )
        case .localPreferred:
            do {
                return try await localProvider.generateFromImage(
                    prompt: prompt,
                    images: images,
                    systemInstruction: protectedInstruction,
                    jsonMode: jsonMode,
                    requestContext: requestContext
                )
            } catch {
                // Consent gate from ../kym_tutor: never upload learner handwriting/camera images
                // to a remote provider unless remote camera AI analysis is explicitly enabled.
                guard allowRemoteCameraAIAnalysis else { throw error }
                return try await frontierProvider.generateFromImage(
                    prompt: prompt,
                    images: images,
                    systemInstruction: protectedInstruction,
                    jsonMode: jsonMode,
                    requestContext: requestContext
                )
            }
        case .frontierPreferred, .frontierOnly:
            guard allowRemoteCameraAIAnalysis, keyChecker.hasKey(for: .gemini) else {
                return try await localProvider.generateFromImage(
                    prompt: prompt,
                    images: images,
                    systemInstruction: protectedInstruction,
                    jsonMode: jsonMode,
                    requestContext: requestContext
                )
            }
            return try await frontierProvider.generateFromImage(
                prompt: prompt,
                images: images,
                systemInstruction: protectedInstruction,
                jsonMode: jsonMode,
                requestContext: requestContext
            )
        }
    }
}
