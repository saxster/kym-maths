import Foundation
import Testing
@testable import KymMaths

@Suite("PhET-inspired interactive labs & pedagogy integration")
struct PhetLabsIntegrationTests {

    @Test("InteractiveStageTelemetry, StageSnapshotRecord, and StagePreset parse and round-trip cleanly")
    func stageContractsRoundTrip() throws {
        let payload: [String: Any] = [
            "chapterNumber": 5,
            "mode": "balance-explorer",
            "params": ["a": 3, "b": 4, "c": 1, "d": 10],
            "readoutPlain": "2x + 4 = 10 · level",
            "goalReached": true,
            "goalDetail": "Isolated x = 3 cleanly",
            "interactionCount": 4,
            "voicing": [
                "name": "Equality Explorer",
                "object": "Subtracted x from both pans",
                "context": "Both pans hold 2x + 4 and 10 and stay level",
                "hint": "Remove 4 ones next"
            ]
        ]

        let telemetry = try #require(InteractiveStageTelemetry.parse(from: payload))
        #expect(telemetry.chapterNumber == 5)
        #expect(telemetry.mode == "balance-explorer")
        #expect(telemetry.params["a"] == 3)
        #expect(telemetry.goalReached)
        #expect(telemetry.interactionCount == 4)
        #expect(telemetry.voicing.name == "Equality Explorer")
        #expect(telemetry.voicing.spokenLine.contains("Remove 4 ones next"))

        #expect(InteractiveStageTelemetry.parse(from: ["mode": "missing-chapter"]) == nil)

        let pngBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
        let snapDict: [String: Any] = [
            "id": "snap-test-1",
            "chapterNumber": 7,
            "title": "Perpendicular ghost check",
            "summary": "m = -0.5 against ghost m = 2",
            "contextSentence": "The two lines meet at 90° because 2 × (-0.5) = -1.",
            "params": ["a": 2, "b": -0.5],
            "pngDataUrl": "data:image/png;base64,\(pngBase64)"
        ]
        let snap = try #require(StageSnapshotRecord.parse(from: snapDict))
        #expect(snap.id == "snap-test-1")
        #expect(snap.chapterNumber == 7)
        #expect(snap.params["b"] == -0.5)
        #expect(snap.pngData != nil)
        #expect(StageSnapshotRecord.parse(from: ["chapterNumber": 7]) == nil)

        let preset = StagePreset(
            chapterNumber: 3,
            step: .challenge,
            mode: "ratio-tuner",
            params: ["a": 4, "b": 6],
            challengePrompt: "Keep the ratio fixed",
            lockedControls: ["b"]
        )
        let json = try #require(preset.jsonString())
        let decoded = try JSONDecoder().decode(StagePreset.self, from: Data(json.utf8))
        #expect(decoded == preset)
    }

    @Test("LabStampGate requires real interaction plus own words and rejects boilerplate")
    func stampGateEnforcesHonestInteractionAndOwnWords() {
        let baseTelemetry = InteractiveStageTelemetry(
            chapterNumber: 5,
            mode: "balance-explorer",
            params: [:],
            readoutPlain: "x = 3",
            voicing: StageVoicingResponse(name: "Balance", object: "Pan", context: "x = 3"),
            goalReached: false,
            goalDetail: nil,
            interactionCount: 3
        )

        let emptyEval = LabStampGate.evaluate(
            note: "   ",
            telemetry: baseTelemetry,
            chapterNumber: 5,
            goalAlreadyReached: false
        )
        #expect(!emptyEval.canStamp)
        #expect(emptyEval.guidance != nil)

        let boilerplateEval = LabStampGate.evaluate(
            note: "Verified invariant for ch 5",
            telemetry: baseTelemetry,
            chapterNumber: 5,
            goalAlreadyReached: false
        )
        #expect(!boilerplateEval.canStamp)

        let shortEval = LabStampGate.evaluate(
            note: "both sides",
            telemetry: baseTelemetry,
            chapterNumber: 5,
            goalAlreadyReached: false
        )
        #expect(!shortEval.canStamp)

        let unmovedEval = LabStampGate.evaluate(
            note: "Doing the same thing to both pans keeps the beam flat.",
            telemetry: InteractiveStageTelemetry(
                chapterNumber: 5,
                mode: "balance-explorer",
                params: [:],
                readoutPlain: "",
                voicing: StageVoicingResponse(name: "Balance", object: "", context: ""),
                goalReached: false,
                goalDetail: nil,
                interactionCount: 1
            ),
            chapterNumber: 5,
            goalAlreadyReached: false
        )
        #expect(!unmovedEval.canStamp)

        let honestEval = LabStampGate.evaluate(
            note: "Doing the same thing to both pans keeps the beam flat.",
            telemetry: baseTelemetry,
            chapterNumber: 5,
            goalAlreadyReached: false
        )
        #expect(honestEval.canStamp)
        #expect(honestEval.guidance == nil)

        let goalUnlockedEval = LabStampGate.evaluate(
            note: "I isolated x by subtracting x from both pans first.",
            telemetry: nil,
            chapterNumber: 5,
            goalAlreadyReached: true
        )
        #expect(goalUnlockedEval.canStamp)
    }

    @Test("StagePresetCatalog maps all 64 school questions and key footings cleanly")
    func stagePresetCatalogCoversSchoolQuestionsAndFootings() throws {
        let pack = SeedPackLoader.load()
        #expect(pack.schoolQuestions.count == 64)
        for q in pack.schoolQuestions {
            let preset = StagePresetCatalog.preset(for: q)
            #expect((0...20).contains(preset.chapterNumber), "Question \(q.id) mapped to invalid chapter \(preset.chapterNumber)")
            let json = try #require(preset.jsonString(), "Preset for \(q.id) failed JSON encoding")
            #expect(!json.isEmpty)
        }

        #expect(pack.footings.count >= 22)
        for footing in pack.footings {
            let preset = try #require(StagePresetCatalog.preset(forFooting: footing.id), "Missing preset for seed footing \(footing.id)")
            #expect((0...20).contains(preset.chapterNumber))
        }
        #expect(StagePresetCatalog.preset(forFooting: "nonexistent-footing") == nil)
    }

    @Test("ModelSimplificationsCatalog gives concise plain-English notes across all 21 chapters")
    func modelSimplificationsFollowPlainEnglishRules() {
        let bannedWords = [
            "invariant", "lockstep", "horizon", "symbolic", "anatomy", "duality",
            "renormalise", "heuristic", "mensuration", "kinematics", "don't worry",
            "it's easy", "simply", "just", "obviously", "clearly"
        ]

        for ch in 0...20 {
            let note = ModelSimplificationsCatalog.note(forChapter: ch)
            #expect(!note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Chapter \(ch) missing note")

            let lower = note.lowercased()
            for banned in bannedWords {
                #expect(!lower.contains(banned), "Chapter \(ch) note contains banned word '\(banned)': \(note)")
            }

            let sentences = note.split(whereSeparator: { $0 == "." || $0 == "!" || $0 == "?" })
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            #expect(!sentences.isEmpty)
            for sentence in sentences {
                let words = sentence.split(whereSeparator: \.isWhitespace).count
                #expect(words <= 25, "Chapter \(ch) sentence exceeds 25 words (\(words)): \(sentence)")
            }
        }
    }

    @Test("AttemptMismatchDiff activates only on 2nd consecutive miss and never leaks the model answer")
    func attemptMismatchDiffNonSpoilerContract() throws {
        let pack = SeedPackLoader.load()
        for q in pack.schoolQuestions {
            let failingEval = QuestionEvaluationResult(
                matchedParts: [],
                missingParts: [],
                coverageFraction: 0,
                isPass: false,
                resultingProofLevel: .shaky,
                feedbackSummary: "Not yet.",
                diagnosticCell: .shakyNearMiss
            )
            let passingEval = QuestionEvaluationResult(
                matchedParts: ["result"],
                missingParts: [],
                coverageFraction: 1,
                isPass: true,
                resultingProofLevel: .proven,
                feedbackSummary: "Right.",
                diagnosticCell: .solidKnowledge
            )

            #expect(AttemptMismatchDiff.compare(consecutiveMisses: 2, submission: "42", evaluation: passingEval, question: q) == nil)
            #expect(AttemptMismatchDiff.compare(consecutiveMisses: 1, submission: "42", evaluation: failingEval, question: q) == nil)
            #expect(AttemptMismatchDiff.compare(consecutiveMisses: 2, submission: "   ", evaluation: failingEval, question: q) == nil)

            let diff = AttemptMismatchDiff.compare(consecutiveMisses: 2, submission: "0.75", evaluation: failingEval, question: q)
            #expect(diff != nil, "Expected diff on 2nd miss for \(q.id)")
            if let diff {
                let fullText = [diff.whatMatches, diff.whereItSplits, diff.tryNext].joined(separator: " ")
                let modelTrimmed = q.modelAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
                if modelTrimmed.count >= 6 {
                    #expect(!fullText.contains(modelTrimmed), "Mismatch diff leaked model answer for \(q.id)")
                }
            }
        }

        // Positive hyphenated question prompts must not trigger a false-positive negative-sign hint
        if let basePos = pack.schoolQuestions.first(where: {
            !$0.modelAnswer.contains("-") && !$0.modelAnswer.contains("−") && !$0.prompt.lowercased().contains("negative")
        }) {
            let hyphenated = SchoolMathsQuestion(
                id: "test-hyphen-pos",
                unitNumber: basePos.unitNumber,
                topicCode: basePos.topicCode,
                sourceBook: basePos.sourceBook,
                bookSection: basePos.bookSection,
                tier: basePos.tier,
                commandWord: basePos.commandWord,
                marks: basePos.marks,
                prompt: "Find twenty-four well-known pieces in the pattern.",
                workedExample: basePos.workedExample,
                fadedPrompt: basePos.fadedPrompt,
                fadedAnswer: basePos.fadedAnswer,
                modelAnswer: "24",
                answerKey: basePos.answerKey,
                linkedChapter: basePos.linkedChapter,
                linkedWidget: basePos.linkedWidget,
                stuck: nil
            )
            let evalFail = QuestionEvaluationResult(
                matchedParts: [],
                missingParts: [],
                coverageFraction: 0,
                isPass: false,
                resultingProofLevel: .shaky,
                feedbackSummary: "Not yet.",
                diagnosticCell: .shakyNearMiss
            )
            let diff = try #require(AttemptMismatchDiff.compare(consecutiveMisses: 2, submission: "12", evaluation: evalFail, question: hyphenated))
            #expect(!diff.whereItSplits.lowercased().contains("minus sign"))
        }
    }

    @Test("QuadrilateralClassifier detects exact hierarchy, snap grid, voicing, and all 5 missions")
    func quadrilateralClassifierAndMissions() {
        let expectations: [(QuadrilateralKind, [QuadrilateralKind])] = [
            (.square, [.square, .rectangle, .rhombus, .parallelogram, .isoscelesTrapezium, .trapezium, .kite, .general]),
            (.rectangle, [.rectangle, .parallelogram, .isoscelesTrapezium, .trapezium, .general]),
            (.rhombus, [.rhombus, .parallelogram, .trapezium, .kite, .general]),
            (.parallelogram, [.parallelogram, .trapezium, .general]),
            (.isoscelesTrapezium, [.isoscelesTrapezium, .trapezium, .general]),
            (.trapezium, [.trapezium, .general]),
            (.kite, [.kite, .general]),
            (.general, [.general])
        ]

        for (kind, expectedSubset) in expectations {
            let props = QuadrilateralClassifier.inspect(QuadrilateralClassifier.preset(kind))
            #expect(props.isSimple, "\(kind.rawValue) should be simple")
            #expect(props.isConvex, "\(kind.rawValue) should be convex")
            #expect(props.primaryKind == kind, "Expected primaryKind \(kind.rawValue), got \(props.primaryKind.rawValue)")
            for ancestor in expectedSubset {
                #expect(props.hierarchy.contains(ancestor), "\(kind.rawValue) hierarchy missing \(ancestor.rawValue)")
            }
            let voicing = QuadrilateralClassifier.voicingSummary(for: props, movedVertex: "A")
            #expect(voicing.name == kind.title)
            #expect(!voicing.context.isEmpty)
        }

        // Verify snapping bounds and small-step precision
        let snappedCoarse = QuadrilateralClassifier.snap(Vec2(x: 9.0, y: -1.32), smallSteps: false)
        #expect(abs(snappedCoarse.x - QuadrilateralClassifier.boardMax.x) < 1e-9)
        #expect(abs(snappedCoarse.y - (-1.5)) < 1e-9)

        let snappedFine = QuadrilateralClassifier.snap(Vec2(x: 1.24, y: -0.86), smallSteps: true)
        #expect(abs(snappedFine.x - 1.2) < 1e-9)
        #expect(abs(snappedFine.y - (-0.9)) < 1e-9)

        // Verify each of the 5 missions passes on its matching family preset
        let missionTargets: [String: QuadrilateralKind] = [
            "kite-only": .kite,
            "rectangle-not-square": .rectangle,
            "rhombus-not-square": .rhombus,
            "parallelogram-break": .parallelogram,
            "square-all": .square
        ]
        for mission in QuadrilateralMission.all {
            let targetKind = missionTargets[mission.id]!
            let props = QuadrilateralClassifier.inspect(QuadrilateralClassifier.preset(targetKind))
            #expect(mission.check(props), "Mission \(mission.id) should succeed on \(targetKind.rawValue)")
        }

        // Slanted parallelogram and rhombus must NOT be misclassified as isosceles trapezium
        let slantedParallelogram = [Vec2(x: 0, y: 0), Vec2(x: 4, y: 0), Vec2(x: 5, y: 3), Vec2(x: 1, y: 3)]
        let paraProps = QuadrilateralClassifier.inspect(slantedParallelogram)
        #expect(paraProps.primaryKind == .parallelogram)
        #expect(!paraProps.hierarchy.contains(.isoscelesTrapezium))

        let slantedRhombus = [Vec2(x: 0, y: 0), Vec2(x: 5, y: 0), Vec2(x: 8, y: 4), Vec2(x: 3, y: 4)]
        let rhomProps = QuadrilateralClassifier.inspect(slantedRhombus)
        #expect(rhomProps.primaryKind == .rhombus)
        #expect(!rhomProps.hierarchy.contains(.isoscelesTrapezium))

        // Concave dart interior angles sum to 360° with one reflex angle (> 180°)
        let concaveDart = [Vec2(x: 0, y: 3), Vec2(x: -2, y: -2), Vec2(x: 0, y: 0), Vec2(x: 2, y: -2)]
        let dartProps = QuadrilateralClassifier.inspect(concaveDart)
        #expect(!dartProps.isConvex)
        #expect(abs(dartProps.angles.reduce(0, +) - 360.0) < 0.05)
        #expect(dartProps.angles.contains(where: { $0 > 180.0 }))
    }

    @Test("Scratchpad stamps, live tutor brief, and bridge script include PhET capabilities")
    func scratchpadTutorAndWebBridge() {
        #expect(MathsScratchpadStamp.allCases.contains(.doubleNumberLine))
        #expect(!MathsScratchpadStamp.doubleNumberLine.title.isEmpty)
        #expect(!MathsScratchpadStamp.doubleNumberLine.hint.isEmpty)

        let withStage = MathLiveTutorContext.brief(
            chapterTitle: "Equal Pull",
            questionId: "q5-1",
            questionPrompt: "Solve 3x + 4 = x + 10",
            workedSteps: ["Subtract x"],
            learnerDraft: "2x + 4 = 10",
            hasSharedHandwriting: false,
            liveStageContext: "Ch 5 (balance-explorer): Left 2x + 4, right 10, beam balanced"
        )
        #expect(withStage.contains("Live interactive figure state"))
        #expect(withStage.contains("Left 2x + 4, right 10"))

        let withoutStage = MathLiveTutorContext.brief(
            chapterTitle: "Equal Pull",
            questionId: nil,
            questionPrompt: nil,
            workedSteps: [],
            learnerDraft: "",
            hasSharedHandwriting: false
        )
        #expect(!withoutStage.contains("Live interactive figure state"))

        let preset = StagePreset(chapterNumber: 5, step: .cutAway, mode: "balance-explorer", params: ["a": 3])
        let syncJS = PatternedWorldWebStageBridge.buildSyncScript(
            chapterNumber: 5,
            atlasRoute: nil,
            highlightedColorRole: "red",
            isDark: false,
            stageStep: .cutAway,
            stagePreset: preset
        )
        #expect(syncJS.contains("window.setStageStep('cutAway')"))
        #expect(syncJS.contains("window.configureStagePreset("))

        let escapedJS = PatternedWorldWebStageBridge.buildSyncScript(
            chapterNumber: 5,
            atlasRoute: nil,
            highlightedColorRole: "red'); alert(\"xss\")//\n</script>",
            isDark: false,
            stageStep: .cutAway,
            stagePreset: nil
        )
        #expect(escapedJS.contains(#"window.highlightFormulaTerm('red\'); alert("xss")//\n\u003C/script\u003E')"#))
    }

    @MainActor
    @Test("AppStore records telemetry, persists snapshots to journal, and handles figure/quadrilateral routes")
    func appStoreStageAndDeepLinks() throws {
        let store = AppStore(db: DatabaseManager(inMemory: true))

        let telemetry = InteractiveStageTelemetry(
            chapterNumber: 3,
            mode: "ratio-tuner",
            params: ["a": 4, "b": 6],
            readoutPlain: "Ratio 2:3",
            voicing: StageVoicingResponse(name: "Ratio Tuner", object: "Right hand", context: "2:3 locked"),
            goalReached: true,
            goalDetail: "Found equivalent ratio 4:6",
            interactionCount: 3
        )
        store.recordStageTelemetry(telemetry)
        #expect(store.latestStageTelemetry == telemetry)
        #expect(store.stageGoalReachedByChapter[3] == true)

        let snapshot = StageSnapshotRecord(
            id: "snap-ch3-test",
            chapterNumber: 3,
            title: "Ratio 4 to 6",
            summary: "4 : 6 matches 2 : 3",
            contextSentence: "Doubling both hands keeps the ratio tuned.",
            params: ["a": 4, "b": 6],
            capturedAt: Date()
        )
        store.recordStageSnapshot(snapshot)
        #expect(store.stageSnapshots.contains(where: { $0.id == "snap-ch3-test" }))

        store.saveStageSnapshotToJournal(snapshot)
        #expect(store.journalEntries.contains(where: { $0.id == "journal-snap-snap-ch3-test" }))

        let preset = StagePreset(chapterNumber: 7, step: .cutAway, mode: "graph-probe", params: ["a": 2])
        store.openLab(with: preset)
        #expect(store.activeRoom == .labsAtlas)
        #expect(store.selectedChapterNumber == 7)
        #expect(store.pendingStagePreset == preset)

        let quadURL = try #require(URL(string: "kymmaths://euclid/quadrilateral"))
        store.openDeepLink(quadURL)
        #expect(store.activeRoom == .euclidWorkshop)
        #expect(store.euclidRoute == .quadrilateral)
    }

    @Test("Bundled PatternedWorldBook includes atelier_stage and Atlas 2D engine kits")
    func bundledAtelierResourcesResolve() throws {
        let atelier = try #require(
            KymResources.url(forResource: "atelier_stage", withExtension: "mjs", subdirectory: "PatternedWorldBook")
        )
        #expect(FileManager.default.fileExists(atPath: atelier.path))
        for kit in ["iso_kit", "draft_kit", "diegetic", "prose", "draft_standard"] {
            let url = try #require(
                KymResources.url(forResource: kit, withExtension: "js", subdirectory: "PatternedWorldBook/atlas/engine"),
                "Missing bundled engine kit \(kit).js"
            )
            #expect(FileManager.default.fileExists(atPath: url.path))
        }
    }
}
