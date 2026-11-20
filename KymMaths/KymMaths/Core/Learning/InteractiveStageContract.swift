import Foundation

// MARK: - PhET-Style Progressive Disclosure, Voicing, Presets, Snapshots & Stamp Gate

/// The four progressive-disclosure stages a lab figure moves through in step-by-step discovery.
enum StageRevealStep: String, CaseIterable, Identifiable, Codable, Sendable {
    case openPlay
    case cutAway
    case symbolic
    case challenge

    var id: String { rawValue }

    var stepIndex: Int {
        switch self {
        case .openPlay: 1
        case .cutAway: 2
        case .symbolic: 3
        case .challenge: 4
        }
    }

    var title: String {
        switch self {
        case .openPlay: "Look"
        case .cutAway: "Cut away"
        case .symbolic: "Make it ideal"
        case .challenge: "Your task"
        }
    }
}

/// PhET's four-part accessible voicing response for a figure control or state transition.
struct StageVoicingResponse: Codable, Equatable, Sendable {
    let name: String
    let object: String
    let context: String
    let hint: String?

    init(name: String, object: String, context: String, hint: String? = nil) {
        self.name = name
        self.object = object
        self.context = context
        self.hint = hint
    }

    var spokenLine: String {
        [name, object, context, hint]
            .compactMap { part in
                guard let trimmed = part?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
                    return nil
                }
                return trimmed
            }
            .joined(separator: ". ")
    }
}

/// One pinned state of a figure, for side-by-side comparison or saving into the Journal.
struct StageSnapshotRecord: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let chapterNumber: Int
    let title: String
    let summary: String
    let contextSentence: String
    let params: [String: Double]
    let pngData: Data?
    let capturedAt: Date

    init(
        id: String,
        chapterNumber: Int,
        title: String,
        summary: String,
        contextSentence: String,
        params: [String: Double],
        pngData: Data? = nil,
        capturedAt: Date = Date()
    ) {
        self.id = id
        self.chapterNumber = chapterNumber
        self.title = title
        self.summary = summary
        self.contextSentence = contextSentence
        self.params = params
        self.pngData = pngData
        self.capturedAt = capturedAt
    }

    static func parse(from dict: [String: Any], now: Date = Date()) -> StageSnapshotRecord? {
        guard let chapterNumber = parseInt(dict["chapterNumber"] ?? dict["chapter"]) else { return nil }
        let rawId = (dict["id"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = ((dict["title"] as? String) ?? "Chapter \(chapterNumber) snapshot")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let summary = ((dict["summary"] as? String) ?? (dict["readoutPlain"] as? String) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let context = ((dict["contextSentence"] as? String) ?? summary)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !summary.isEmpty || !context.isEmpty else { return nil }
        let params = parseDoubleMap(dict["params"])
        let pngData = decodePNGData(dict["pngDataUrl"] ?? dict["dataUrl"])
        let id = (rawId?.isEmpty == false)
            ? rawId!
            : "snap-ch\(chapterNumber)-\(Int(now.timeIntervalSince1970 * 1000))"
        return StageSnapshotRecord(
            id: id,
            chapterNumber: chapterNumber,
            title: title,
            summary: summary.isEmpty ? context : summary,
            contextSentence: context.isEmpty ? summary : context,
            params: params,
            pngData: pngData,
            capturedAt: now
        )
    }
}

/// Live telemetry sent from `PatternedWorldBook` over `kymmathsBridge`.
struct InteractiveStageTelemetry: Codable, Equatable, Sendable {
    let chapterNumber: Int
    let mode: String
    let params: [String: Double]
    let readoutPlain: String
    let voicing: StageVoicingResponse
    let goalReached: Bool
    let goalDetail: String?
    let interactionCount: Int

    static func parse(from dict: [String: Any]) -> InteractiveStageTelemetry? {
        guard let chapterNumber = parseInt(dict["chapterNumber"] ?? dict["chapter"]) else { return nil }
        let mode = ((dict["mode"] as? String) ?? "default").trimmingCharacters(in: .whitespacesAndNewlines)
        let params = parseDoubleMap(dict["params"])
        let readoutPlain = ((dict["readoutPlain"] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let goalReached = (dict["goalReached"] as? Bool) ?? false
        let goalDetail = (dict["goalDetail"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let interactionCount = max(0, parseInt(dict["interactionCount"]) ?? 0)

        let voicingDict = dict["voicing"] as? [String: Any]
        let name = ((voicingDict?["name"] as? String) ?? "Chapter \(chapterNumber) figure")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let object = ((voicingDict?["object"] as? String) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let context = ((voicingDict?["context"] as? String) ?? readoutPlain)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let hint = (voicingDict?["hint"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

        return InteractiveStageTelemetry(
            chapterNumber: chapterNumber,
            mode: mode.isEmpty ? "default" : mode,
            params: params,
            readoutPlain: readoutPlain,
            voicing: StageVoicingResponse(
                name: name.isEmpty ? "Chapter \(chapterNumber) figure" : name,
                object: object,
                context: context,
                hint: (hint?.isEmpty == true) ? nil : hint
            ),
            goalReached: goalReached,
            goalDetail: (goalDetail?.isEmpty == true) ? nil : goalDetail,
            interactionCount: interactionCount
        )
    }
}

/// Host-injected initial configuration for a stage figure (mirroring PhET-iO presets).
struct StagePreset: Codable, Equatable, Sendable {
    let chapterNumber: Int
    let step: StageRevealStep
    let mode: String?
    let params: [String: Double]
    let challengePrompt: String?
    let lockedControls: [String]

    init(
        chapterNumber: Int,
        step: StageRevealStep,
        mode: String? = nil,
        params: [String: Double] = [:],
        challengePrompt: String? = nil,
        lockedControls: [String] = []
    ) {
        self.chapterNumber = chapterNumber
        self.step = step
        self.mode = mode
        self.params = params
        self.challengePrompt = challengePrompt
        self.lockedControls = lockedControls
    }

    func jsonString() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

/// Maps school questions and footings to pre-configured interactive labs.
enum StagePresetCatalog {
    static func preset(for question: SchoolMathsQuestion) -> StagePreset {
        let chapter = max(0, min(20, question.linkedChapter))
        switch chapter {
        case 1:
            return StagePreset(
                chapterNumber: 1,
                step: .cutAway,
                mode: "distance",
                params: ["a": -3, "b": 4],
                challengePrompt: "Drag A and B to test signs and distance across zero."
            )
        case 2:
            return StagePreset(
                chapterNumber: 2,
                step: .cutAway,
                mode: "double-line",
                params: ["a": 3, "b": 12],
                challengePrompt: "Slide the marker to 1 unit first, then scale back up."
            )
        case 3:
            return StagePreset(
                chapterNumber: 3,
                step: .cutAway,
                mode: "ratio-tuner",
                params: ["a": 4, "b": 6, "c": 8],
                challengePrompt: "Keep the two hands in proportion, then test locking the ratio."
            )
        case 4:
            let wantsFactor = question.prompt.lowercased().contains("factor")
            let hasMinus = question.prompt.contains("-") || question.prompt.contains("−")
            return StagePreset(
                chapterNumber: 4,
                step: .cutAway,
                mode: wantsFactor ? "area-factor" : (hasMinus ? "area-generic" : "area-scale"),
                params: ["a": 4, "b": hasMinus ? -3 : 2, "c": 3],
                challengePrompt: wantsFactor
                    ? "Match the four inner areas by stepping the outside edges."
                    : "Split the box along each edge and add the four areas."
            )
        case 5:
            return StagePreset(
                chapterNumber: 5,
                step: .cutAway,
                mode: "balance-explorer",
                params: ["a": 3, "b": 4, "c": 1, "d": 10],
                challengePrompt: "Keep the beam level while isolating one red x on a pan."
            )
        case 7:
            let isMachine = question.prompt.lowercased().contains("function")
                || question.prompt.lowercased().contains("inverse")
                || question.prompt.lowercased().contains("input")
            return StagePreset(
                chapterNumber: 7,
                step: .cutAway,
                mode: isMachine ? "function-machine" : "graph-probe",
                params: ["a": 2, "b": 1, "c": 2],
                challengePrompt: isMachine
                    ? "Test inputs, then swap or reverse the rule blocks."
                    : "Drag the line points and pin a ghost to compare gradients."
            )
        case 13:
            return StagePreset(
                chapterNumber: 13,
                step: .cutAway,
                mode: "live-sampler",
                params: ["a": 12, "b": 9],
                challengePrompt: "Draw samples at small n and big n to watch the spread shrink."
            )
        case 14:
            let isHist = question.prompt.lowercased().contains("density")
                || question.prompt.lowercased().contains("histogram")
            return StagePreset(
                chapterNumber: 14,
                step: .cutAway,
                mode: isHist ? "histogram" : "mean-balance",
                params: ["a": 25, "b": 30, "c": 18],
                challengePrompt: isHist
                    ? "Widen the bar and watch height fall so area stays equal to frequency."
                    : "Predict the balance point and median, then drag one dot far right."
            )
        case 17, 18:
            return StagePreset(
                chapterNumber: chapter,
                step: .cutAway,
                mode: "calculus-grapher",
                params: ["a": 1.5, "b": 0.5, "c": 1],
                challengePrompt: "Slide the vertical line across all three graphs at once."
            )
        default:
            return StagePreset(
                chapterNumber: chapter,
                step: .cutAway,
                mode: nil,
                params: [:],
                challengePrompt: "Test the numbers from your question on the figure and watch what stays fixed."
            )
        }
    }

    static func preset(forFooting footingId: String) -> StagePreset? {
        footingPresets[footingId]
    }

    private static let footingPresets: [String: StagePreset] = [
        "negative-numbers": StagePreset(chapterNumber: 1, step: .cutAway, mode: "distance", params: ["a": -4, "b": 3], challengePrompt: "Check turns and distance below zero."),
        "inverse-operations": StagePreset(chapterNumber: 5, step: .cutAway, mode: "balance-explorer", params: ["a": 2, "b": 3, "c": 0, "d": 11], challengePrompt: "Undo the outer step first while keeping both pans balanced."),
        "distributive-law": StagePreset(chapterNumber: 4, step: .cutAway, mode: "area-generic", params: ["a": 5, "b": 2, "c": -3], challengePrompt: "Check every single box in the grid before adding."),
        "factors-and-multiples": StagePreset(chapterNumber: 1, step: .cutAway, mode: "classic-turns", params: ["a": 24, "b": 36, "c": 2], challengePrompt: "Spot the common factors that divide both numbers cleanly."),
        "squares-and-roots": StagePreset(chapterNumber: 1, step: .cutAway, mode: "classic-turns", params: ["a": 36, "b": 48, "c": 2], challengePrompt: "Track prime pairs inside square numbers."),
        "fractions": StagePreset(chapterNumber: 2, step: .cutAway, mode: "double-line", params: ["a": 2, "b": 8], challengePrompt: "Line up 0 on both rails to check equivalent fractions."),
        "rounding": StagePreset(chapterNumber: 13, step: .cutAway, mode: "live-sampler", params: ["a": 10, "b": 16, "c": 1], challengePrompt: "Watch how narrow error bars behave at larger sample sizes."),
        "place-value": StagePreset(chapterNumber: 2, step: .cutAway, mode: "recurring", params: ["a": 36, "b": 3, "c": 4], challengePrompt: "Shift digits left by multiplying by 100, then subtract the repeating tail."),
        "multiply-or-divide": StagePreset(chapterNumber: 2, step: .cutAway, mode: "double-line", params: ["a": 3, "b": 4], challengePrompt: "Find 1 unit on the bottom rail first, then scale smoothly."),
        "ratio-and-proportion": StagePreset(chapterNumber: 3, step: .cutAway, mode: "ratio-tuner", params: ["a": 2, "b": 3, "c": 8], challengePrompt: "Lock the ratio so both quantities scale by the same multiplier."),
        "percentages": StagePreset(chapterNumber: 3, step: .cutAway, mode: "compound-growth", params: ["a": 3, "b": 5, "c": 8], challengePrompt: "Compare flat steps against repeated multiplier steps."),
        "units-and-scale": StagePreset(chapterNumber: 11, step: .cutAway, mode: nil, params: ["a": 2, "b": 0, "c": 0], challengePrompt: "Check what happens to length versus area when you double the scale factor."),
        "area-and-perimeter": StagePreset(chapterNumber: 10, step: .cutAway, mode: nil, params: ["a": 4, "b": 12, "c": 90], challengePrompt: "Separate outer boundary length from tiled interior area."),
        "angle-facts": StagePreset(chapterNumber: 8, step: .cutAway, mode: nil, params: ["a": 50, "b": 60, "c": 6], challengePrompt: "Spot which lines are parallel before adding angles."),
        "coordinates-and-gradient": StagePreset(chapterNumber: 7, step: .cutAway, mode: "graph-probe", params: ["a": 2, "b": -1, "c": 1], challengePrompt: "Check rise over run with the point probe."),
        "transformations": StagePreset(chapterNumber: 11, step: .cutAway, mode: nil, params: ["a": 2, "b": 1, "c": 1], challengePrompt: "Check centre, direction and scale factor separately."),
        "equally-likely-outcomes": StagePreset(chapterNumber: 15, step: .cutAway, mode: nil, params: ["a": 6, "b": 3, "c": 50], challengePrompt: "Count equal paths feeding each middle bin."),
        "the-right-total": StagePreset(chapterNumber: 16, step: .cutAway, mode: nil, params: ["a": 2, "b": 95, "c": 5], challengePrompt: "Pick out the exact subgroup total before writing the denominator."),
        "spread-and-density": StagePreset(chapterNumber: 14, step: .cutAway, mode: "histogram", params: ["a": 20, "b": 30, "c": 18], challengePrompt: "Divide frequency by class width to keep area honest."),
        "vectors": StagePreset(chapterNumber: 19, step: .cutAway, mode: nil, params: ["a": 3.5, "b": 2.0, "c": 60], challengePrompt: "Walk the horizontal step then the vertical step nose to tail."),
        "nth-term": StagePreset(chapterNumber: 6, step: .cutAway, mode: nil, params: ["a": 5, "b": 1, "c": 2], challengePrompt: "Pair first and last terms, and spot the constant step between terms."),
        "answer-the-question": StagePreset(chapterNumber: 0, step: .cutAway, mode: nil, params: ["a": 18, "b": 15, "c": 7], challengePrompt: "Check which exact group or outside complement the question asks for.")
    ]
}

/// Ensures lab stamps require real figure work plus Kym's own summary sentence.
enum LabStampGate {
    struct Evaluation: Equatable, Sendable {
        let canStamp: Bool
        let cleanedNote: String
        let guidance: String?
    }

    private static let minimumNoteLength = 12
    private static let boilerplatePrefixes = [
        "verified invariant",
        "stamped from",
        "checked",
        "ok",
        "done",
        "test",
    ]

    static func evaluate(
        note: String,
        telemetry: InteractiveStageTelemetry?,
        chapterNumber: Int,
        goalAlreadyReached: Bool
    ) -> Evaluation {
        let cleaned = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = cleaned.lowercased()
        let isBoilerplate = boilerplatePrefixes.contains { prefix in
            lower == prefix || lower.hasPrefix(prefix + " ") || lower.hasPrefix(prefix + ":")
        }
        let hasValidNote = cleaned.count >= minimumNoteLength && !isBoilerplate

        let interactedOnChapter = goalAlreadyReached
            || (telemetry?.chapterNumber == chapterNumber && (telemetry?.goalReached == true || (telemetry?.interactionCount ?? 0) >= 2))

        if !interactedOnChapter && !hasValidNote {
            return Evaluation(
                canStamp: false,
                cleanedNote: cleaned,
                guidance: "Move the figure first to test the pattern, then write in your own words what stayed the same."
            )
        }
        if !interactedOnChapter {
            return Evaluation(
                canStamp: false,
                cleanedNote: cleaned,
                guidance: "Try the figure at least twice (or finish the task in step 4) before earning the stamp."
            )
        }
        if !hasValidNote {
            return Evaluation(
                canStamp: false,
                cleanedNote: cleaned,
                guidance: "Write at least one full sentence in your own words about what stayed fixed."
            )
        }
        return Evaluation(canStamp: true, cleanedNote: cleaned, guidance: nil)
    }
}

private func parseInt(_ raw: Any?) -> Int? {
    if let i = raw as? Int { return i }
    if let d = raw as? Double { return Int(d.rounded()) }
    if let n = raw as? NSNumber { return n.intValue }
    if let s = raw as? String { return Int(s) }
    return nil
}

private func parseDoubleMap(_ raw: Any?) -> [String: Double] {
    guard let dict = raw as? [String: Any] else { return [:] }
    var out: [String: Double] = [:]
    for (k, v) in dict {
        if let d = v as? Double {
            out[k] = d
        } else if let i = v as? Int {
            out[k] = Double(i)
        } else if let n = v as? NSNumber {
            out[k] = n.doubleValue
        }
    }
    return out
}

private func decodePNGData(_ raw: Any?) -> Data? {
    guard let s = (raw as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else {
        return nil
    }
    let prefix = "data:image/png;base64,"
    guard s.hasPrefix(prefix) else { return nil }
    return Data(base64Encoded: String(s.dropFirst(prefix.count)))
}
