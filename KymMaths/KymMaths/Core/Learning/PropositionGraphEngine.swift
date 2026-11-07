import CryptoKit
import Foundation
import GRDB

// MARK: - Provenance & Graph Contracts (Ported from LearnHarness src/core/graph.ts & extraction.ts)

public struct ProvenancePoint: Codable, Sendable, Equatable, Hashable {
    public var sourceKind: String   // "chapter" | "journal" | "mentor_session" | "seed"
    public var sourceId: String     // e.g. "ch12", "journal-starter-intuition-to-formula"
    public var anchorId: String     // messageId or sectionId ("" when source-level)

    public init(sourceKind: String, sourceId: String, anchorId: String = "") {
        self.sourceKind = sourceKind
        self.sourceId = sourceId
        self.anchorId = anchorId
    }
}

public struct ExtractedProposition: Codable, Sendable, Equatable, Identifiable {
    public var id: String           // Job-local id: "p1", "p2", ...
    public var name: String         // Short mathematical headword ("Unit Circle Pythagorean Identity")
    public var statement: String    // Self-contained, world-facing proposition at full precision
    public var aliases: [String]
    public var isUnconditionalTruth: Bool
    public var chapterNumber: Int
    public var topicCode: String
    public var anchorId: String

    public init(
        id: String,
        name: String,
        statement: String,
        aliases: [String] = [],
        isUnconditionalTruth: Bool = false,
        chapterNumber: Int = 0,
        topicCode: String = "1.1",
        anchorId: String = ""
    ) {
        self.id = id
        self.name = name
        self.statement = statement
        self.aliases = aliases
        self.isUnconditionalTruth = isUnconditionalTruth
        self.chapterNumber = chapterNumber
        self.topicCode = topicCode
        self.anchorId = anchorId
    }
}

public struct ExtractedChain: Codable, Sendable, Equatable {
    public var premises: [String]   // Job-local ids ("p1") or existing graph node ids ("n_...")
    public var conclusion: String   // Job-local id or existing graph node id

    public init(premises: [String], conclusion: String) {
        self.premises = premises
        self.conclusion = conclusion
    }
}

public struct ExtractionFindings: Codable, Sendable, Equatable {
    public var propositions: [ExtractedProposition]
    public var chains: [ExtractedChain]

    public init(propositions: [ExtractedProposition], chains: [ExtractedChain]) {
        self.propositions = propositions
        self.chains = chains
    }
}

public struct AuditIdentityLink: Codable, Sendable, Equatable {
    public var id: String           // Job-local proposition id ("p1")
    public var linkTo: String?      // Existing graph node id ("n_...") or nil to mint a new node

    public init(id: String, linkTo: String?) {
        self.id = id
        self.linkTo = linkTo
    }
}

public struct AuditVerdicts: Codable, Sendable, Equatable {
    public var links: [AuditIdentityLink]

    public init(links: [AuditIdentityLink]) {
        self.links = links
    }
}

public struct GraphMergeStats: Codable, Sendable, Equatable {
    public var addedNodes: Int
    public var linkedNodes: Int
    public var addedChains: Int
    public var droppedRedundantChains: Int

    public init(
        addedNodes: Int = 0,
        linkedNodes: Int = 0,
        addedChains: Int = 0,
        droppedRedundantChains: Int = 0
    ) {
        self.addedNodes = addedNodes
        self.linkedNodes = linkedNodes
        self.addedChains = addedChains
        self.droppedRedundantChains = droppedRedundantChains
    }
}

// MARK: - PropositionGraphEngine (3-Stage Extractor -> Identity Auditor -> Deterministic Merger + simplifyChains)

public enum PropositionGraphEngine {

    /// Canonical merge key for a joint-premise derivation chain: sorted premises + ">" + conclusion.
    public static func chainKey(premises: [String], conclusion: String) -> String {
        let sortedUnique = Array(Set(premises)).sorted()
        return "\(sortedUnique.joined(separator: "+"))>\(conclusion)"
    }

    public static func deterministicNodeId(for seed: String) -> String {
        let digest = SHA256.hash(data: Data(seed.utf8))
        let hex = digest.prefix(6).map { String(format: "%02x", $0) }.joined()
        return "n_\(hex)"
    }

    public static func deterministicChainId(for key: String) -> String {
        let digest = SHA256.hash(data: Data(key.utf8))
        let hex = digest.prefix(6).map { String(format: "%02x", $0) }.joined()
        return "arg_\(hex)"
    }

    // MARK: - Stage 1: Extractor (Digest-Aware Extraction from Journal Entries, Chapters & Mentor Turns)

    static func extractFindings(fromJournalEntry entry: LabJournalEntryRecord) -> ExtractionFindings {
        let ch = entry.linkedChapterNumber ?? 0
        let topic = entry.linkedTopicCode ?? "1.1"
        let givenText = entry.independentVarText.trimmingCharacters(in: .whitespacesAndNewlines)
        let conjectureText = entry.hypothesisText.trimmingCharacters(in: .whitespacesAndNewlines)
        let targetText = entry.dependentVarText.trimmingCharacters(in: .whitespacesAndNewlines)
        let summaryText = entry.summaryText.trimmingCharacters(in: .whitespacesAndNewlines)

        let foundationStatement = !givenText.isEmpty
            ? givenText
            : (!entry.cueColumnText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? entry.cueColumnText.trimmingCharacters(in: .whitespacesAndNewlines)
                : "Equal units and geometric area stay conserved across valid transformations.")

        let intermediateStatement = !conjectureText.isEmpty
            ? conjectureText
            : (!entry.bodyNotesText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? String(entry.bodyNotesText.trimmingCharacters(in: .whitespacesAndNewlines).prefix(220))
                : "Partitioning the quantity into equal Singapore bar units exposes the conserved invariant.")

        let conclusionStatement = !summaryText.isEmpty
            ? summaryText
            : (!targetText.isEmpty ? targetText : entry.title)

        let p1 = ExtractedProposition(
            id: "p1",
            name: "\(entry.title) · Foundation",
            statement: sanitizeWorldFacingStatement(foundationStatement),
            aliases: [entry.title],
            isUnconditionalTruth: true,
            chapterNumber: ch,
            topicCode: topic,
            anchorId: "\(entry.id)#given"
        )
        let p2 = ExtractedProposition(
            id: "p2",
            name: "\(entry.title) · Structural Invariant",
            statement: sanitizeWorldFacingStatement(intermediateStatement),
            aliases: [],
            isUnconditionalTruth: false,
            chapterNumber: ch,
            topicCode: topic,
            anchorId: "\(entry.id)#invariant"
        )
        let p3 = ExtractedProposition(
            id: "p3",
            name: entry.title,
            statement: sanitizeWorldFacingStatement(conclusionStatement),
            aliases: targetText.isEmpty ? [] : [targetText],
            isUnconditionalTruth: false,
            chapterNumber: ch,
            topicCode: topic,
            anchorId: "\(entry.id)#conclusion"
        )

        return ExtractionFindings(
            propositions: [p1, p2, p3],
            chains: [
                ExtractedChain(premises: ["p1"], conclusion: "p2"),
                ExtractedChain(premises: ["p1", "p2"], conclusion: "p3")
            ]
        )
    }

    static func extractFindings(fromChapter chapter: PatternedWorldChapter, topicCode: String = "1.1") -> ExtractionFindings {
        let bridge = chapter.intuitionToFormula
        let p1 = ExtractedProposition(
            id: "p1",
            name: "Ch \(chapter.number) Concrete Action",
            statement: sanitizeWorldFacingStatement(bridge.concreteAction),
            aliases: ["Ch \(chapter.number) Physical Setup"],
            isUnconditionalTruth: true,
            chapterNumber: chapter.number,
            topicCode: topicCode,
            anchorId: "\(chapter.id)#concrete"
        )
        let p2 = ExtractedProposition(
            id: "p2",
            name: "Ch \(chapter.number) Aha! Invariant",
            statement: sanitizeWorldFacingStatement(bridge.ahaInvariant),
            aliases: chapter.keyTerms,
            isUnconditionalTruth: false,
            chapterNumber: chapter.number,
            topicCode: topicCode,
            anchorId: "\(chapter.id)#invariant"
        )
        let p3 = ExtractedProposition(
            id: "p3",
            name: "\(chapter.title): \(bridge.formulaDisplay)",
            statement: sanitizeWorldFacingStatement("\(bridge.formulaDisplay) — \(chapter.hookSummary)"),
            aliases: [bridge.formulaDisplay, chapter.title],
            isUnconditionalTruth: false,
            chapterNumber: chapter.number,
            topicCode: topicCode,
            anchorId: "\(chapter.id)#formula"
        )

        return ExtractionFindings(
            propositions: [p1, p2, p3],
            chains: [
                ExtractedChain(premises: ["p1"], conclusion: "p2"),
                ExtractedChain(premises: ["p2"], conclusion: "p3")
            ]
        )
    }

    /// Converts learner-centric or misconception phrasings into world-facing true statements
    /// per LearnHarness extraction doctrine ("Never 'the learner understands X', always 'X';
    /// a misconception enters as its true correction").
    public static func sanitizeWorldFacingStatement(_ raw: String) -> String {
        var cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefixesToStrip = [
            "the learner understands that ",
            "kym understands that ",
            "the student learned that ",
            "i learned that ",
            "misconception: "
        ]
        for prefix in prefixesToStrip {
            if cleaned.lowercased().hasPrefix(prefix) {
                cleaned = String(cleaned.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        guard let first = cleaned.first else { return cleaned }
        return String(first).uppercased() + cleaned.dropFirst()
    }

    // MARK: - Stage 2: Identity Auditor (Equivalence Linking Across Sessions)

    public static func auditIdentities(
        extracted: [ExtractedProposition],
        existingNodes: [PropositionNodeRecord]
    ) -> AuditVerdicts {
        var links: [AuditIdentityLink] = []

        for prop in extracted {
            let normStatement = normalizeForIdentity(prop.statement)
            let normName = normalizeForIdentity(prop.name)

            let matchedNode = existingNodes.first { existing in
                if normalizeForIdentity(existing.statement) == normStatement {
                    return true
                }
                if normalizeForIdentity(existing.name) == normName && existing.chapterNumber == prop.chapterNumber {
                    return true
                }
                let existingAliases = existing.decodedAliases.map(normalizeForIdentity)
                if existingAliases.contains(normStatement) || existingAliases.contains(normName) {
                    return true
                }
                for alias in prop.aliases {
                    let normAlias = normalizeForIdentity(alias)
                    if !normAlias.isEmpty && (existingAliases.contains(normAlias) || normalizeForIdentity(existing.name) == normAlias) {
                        return true
                    }
                }
                return false
            }

            links.append(AuditIdentityLink(id: prop.id, linkTo: matchedNode?.id))
        }

        return AuditVerdicts(links: links)
    }

    private static func normalizeForIdentity(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ".", with: "")
    }

    // MARK: - Stage 3: Deterministic Merger & simplifyChains Maintenance Pass

    public static func mergeFindings(
        sourceKind: String,
        sourceId: String,
        findings: ExtractionFindings,
        verdicts: AuditVerdicts,
        existingNodes: [PropositionNodeRecord],
        existingChains: [DerivationChainRecord],
        now: Date = Date()
    ) -> (nodes: [PropositionNodeRecord], chains: [DerivationChainRecord], stats: GraphMergeStats) {
        var nodesById: [String: PropositionNodeRecord] = Dictionary(
            uniqueKeysWithValues: existingNodes.map { ($0.id, $0) }
        )
        var orderedNodeIds: [String] = existingNodes.map(\.id)
        var mapping: [String: String] = [:]
        let linkOf: [String: String] = Dictionary(
            uniqueKeysWithValues: verdicts.links.compactMap { link in
                guard let target = link.linkTo else { return nil }
                return (link.id, target)
            }
        )

        var stats = GraphMergeStats()

        // 1. Resolve propositions -> link to existing node or mint new node
        for prop in findings.propositions {
            if mapping[prop.id] != nil { continue }
            let point = ProvenancePoint(sourceKind: sourceKind, sourceId: sourceId, anchorId: prop.anchorId)

            if let targetId = linkOf[prop.id], var existing = nodesById[targetId] {
                var mergedAliases = existing.decodedAliases
                for candidateAlias in ([prop.name, prop.statement] + prop.aliases) {
                    let trimmed = candidateAlias.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty && trimmed != existing.name && trimmed != existing.statement && !mergedAliases.contains(trimmed) {
                        mergedAliases.append(trimmed)
                    }
                }
                var mergedProvenance = existing.decodedProvenance
                if !mergedProvenance.contains(point) {
                    mergedProvenance.append(point)
                }
                existing.aliasesJSON = PropositionNodeRecord.encodeStringArray(mergedAliases)
                existing.provenanceJSON = PropositionNodeRecord.encodeProvenance(mergedProvenance)
                if prop.isUnconditionalTruth {
                    existing.isUnconditionalTruth = true
                }
                nodesById[targetId] = existing
                mapping[prop.id] = targetId
                stats.linkedNodes += 1
            } else {
                let newId = deterministicNodeId(for: "\(sourceId)::\(prop.id)::\(prop.name)")
                if var already = nodesById[newId] {
                    var mergedProvenance = already.decodedProvenance
                    if !mergedProvenance.contains(point) {
                        mergedProvenance.append(point)
                    }
                    already.provenanceJSON = PropositionNodeRecord.encodeProvenance(mergedProvenance)
                    nodesById[newId] = already
                    mapping[prop.id] = newId
                } else {
                    let node = PropositionNodeRecord(
                        id: newId,
                        name: prop.name,
                        statement: prop.statement,
                        aliasesJSON: PropositionNodeRecord.encodeStringArray(prop.aliases),
                        isUnconditionalTruth: prop.isUnconditionalTruth,
                        chapterNumber: prop.chapterNumber,
                        topicCode: prop.topicCode,
                        provenanceJSON: PropositionNodeRecord.encodeProvenance([point]),
                        createdAt: now
                    )
                    nodesById[newId] = node
                    orderedNodeIds.append(newId)
                    mapping[prop.id] = newId
                    stats.addedNodes += 1
                }
            }
        }

        // 2. Resolve and append chains
        var allChains = existingChains
        var chainsByKey: [String: Int] = [:]
        for (idx, ch) in allChains.enumerated() {
            chainsByKey[ch.chainKey] = idx
        }

        let resolveEndpoint = { (endpoint: String) -> String? in
            if let mapped = mapping[endpoint] { return mapped }
            if nodesById[endpoint] != nil { return endpoint }
            return nil
        }

        for chain in findings.chains {
            guard let conclusion = resolveEndpoint(chain.conclusion) else { continue }
            let premises = Array(Set(chain.premises.compactMap(resolveEndpoint)))
                .filter { $0 != conclusion }
                .sorted()
            guard !premises.isEmpty else { continue }

            let key = chainKey(premises: premises, conclusion: conclusion)
            let point = ProvenancePoint(sourceKind: sourceKind, sourceId: sourceId)

            if let existingIdx = chainsByKey[key] {
                var existingChain = allChains[existingIdx]
                var prov = existingChain.decodedProvenance
                if !prov.contains(point) {
                    prov.append(point)
                    existingChain.provenanceJSON = PropositionNodeRecord.encodeProvenance(prov)
                    allChains[existingIdx] = existingChain
                }
            } else {
                let newChain = DerivationChainRecord(
                    id: deterministicChainId(for: key),
                    premisesCSV: premises.joined(separator: ","),
                    conclusionId: conclusion,
                    chainKey: key,
                    provenanceJSON: PropositionNodeRecord.encodeProvenance([point]),
                    createdAt: now
                )
                chainsByKey[key] = allChains.count
                allChains.append(newChain)
                stats.addedChains += 1
            }
        }

        // 2b. Deterministic Chain Simplification (Prefer-Fewest-Premises + Ancestry-Cover)
        let simplifiedChains = simplifyChains(allChains)
        stats.droppedRedundantChains = max(0, allChains.count - simplifiedChains.count)

        let finalNodes = orderedNodeIds.compactMap { nodesById[$0] }
        return (finalNodes, simplifiedChains, stats)
    }

    /// Ported directly from LearnHarness `src/core/graph.ts` (`simplifyChains`):
    /// Strips redundant derivations per conclusion group in greedy `(premiseCount, createdAt, chainKey)` order:
    /// 1. **Prefer-fewest-premises:** A chain whose premise set strictly contains a kept chain's premise set is redundant.
    /// 2. **Ancestry-cover:** A chain `[A, B, C] ⟹ Y` whose every premise is either in a kept chain's premises
    ///    or is a transitive ancestor of one (e.g. `[A, B] ⟹ X` + `[X, C] ⟹ Y`) is redundant.
    public static func simplifyChains(_ chains: [DerivationChainRecord]) -> [DerivationChainRecord] {
        guard chains.count >= 2 else { return chains }

        // Build full pre-simplification premise lookup by conclusion
        var premisesOfConclusion: [String: [[String]]] = [:]
        for chain in chains {
            premisesOfConclusion[chain.conclusionId, default: []].append(chain.premisesList)
        }

        // Memoized cycle-guarded ancestry walk
        var ancestryMemo: [String: Set<String>] = [:]
        func ancestry(of nodeId: String, visiting: inout Set<String>) -> Set<String> {
            if let cached = ancestryMemo[nodeId] { return cached }
            if visiting.contains(nodeId) { return [] }
            visiting.insert(nodeId)
            var out: Set<String> = []
            for premiseGroup in premisesOfConclusion[nodeId] ?? [] {
                for premise in premiseGroup {
                    out.insert(premise)
                    let transitive = ancestry(of: premise, visiting: &visiting)
                    out.formUnion(transitive)
                }
            }
            visiting.remove(nodeId)
            ancestryMemo[nodeId] = out
            return out
        }

        // Group chains by conclusion
        var byConclusion: [String: [DerivationChainRecord]] = [:]
        for chain in chains {
            byConclusion[chain.conclusionId, default: []].append(chain)
        }

        var keptKeys: Set<String> = []
        for (_, group) in byConclusion {
            if group.count == 1 {
                keptKeys.insert(group[0].chainKey)
                continue
            }

            let sortedCandidates = group.sorted { a, b in
                let aCount = a.premisesList.count
                let bCount = b.premisesList.count
                if aCount != bCount { return aCount < bCount }
                if a.createdAt != b.createdAt { return a.createdAt < b.createdAt }
                return a.chainKey < b.chainKey
            }

            var keptCovers: [(premises: Set<String>, cover: Set<String>)] = []
            for candidate in sortedCandidates {
                let candidatePremises = Set(candidate.premisesList)
                let isCoveredByExisting = keptCovers.contains { kept in
                    // Rule 1: Prefer-fewest-premises (kept.premises is a strict subset of candidatePremises)
                    // Rule 2: Ancestry-cover (candidatePremises is a distinct subset of kept.cover)
                    kept.premises.isStrictSubset(of: candidatePremises)
                        || (candidatePremises != kept.premises && candidatePremises.isSubset(of: kept.cover))
                }
                if isCoveredByExisting {
                    continue
                }

                var cover = candidatePremises
                for p in candidatePremises {
                    var visiting: Set<String> = []
                    cover.formUnion(ancestry(of: p, visiting: &visiting))
                }
                keptCovers.append((premises: candidatePremises, cover: cover))
                keptKeys.insert(candidate.chainKey)
            }
        }

        return chains.filter { keptKeys.contains($0.chainKey) }
    }
}
