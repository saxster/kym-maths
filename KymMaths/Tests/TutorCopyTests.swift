import Testing
@testable import KymMaths

/// The hint ladder and the "Why does it work?" prompt are read by the learner. They must talk about
/// the question's maths, never about another app's subject or our own internal labels.
@Suite("Tutor copy on the practice screen")
struct TutorCopyTests {
    static let pack = SeedPackLoader.load()

    /// Words that belong to the science app, the book's front matter, or the engine's own vocabulary.
    static let leakedPhrases = [
        "Living World", "conservation law", "conserved", "invariant family",
        "Candidate Class", "Retrieval Intact", "Retrieval Surrendered", "Attention Redirect",
        "Pattern Redescription", "Proposition Named", "Move Outlined", "Worked Step (",
        "R0 ·", "R1 ·", "R2 ·", "R3 ·", "R4 ·", "R5 ·",
        "OUP Complete Mathematics", "Companion Workbook", "pp.",
    ]

    static let hcfQuestion = pack.schoolQuestions.first { $0.id == "q-oup-ch01-sb" }!

    static let ladderRungs: [HintLadderRung] = [
        .r0AttentionRedirect, .r1PatternRedescription, .r2CandidateClass,
        .r3PropositionNamed, .r4MoveOutlined, .r5WorkedStep,
    ]

    @Test("Rung 2 names the question's own topic and what it asks for")
    func rungTwoNamesTheTopic() {
        let question = Self.hcfQuestion
        let topic = Self.pack.schoolTextbook.topic(code: question.topicCode)
        let hint = MeteredHintLadderEngine.hint(for: question, rung: .r2CandidateClass, topic: topic)
        #expect(hint == "This question is from topic 1.4, Prime factorization to find the HCF and LCM. Which idea from that topic gets you the HCF and LCM?")
    }

    @Test("Why does it work? asks about the HCF and LCM and gives the topic's own clue")
    func whyPromptIsAboutTheMaths() {
        let question = Self.hcfQuestion
        let topic = Self.pack.schoolTextbook.topic(code: question.topicCode)
        let prompt = ElaborativeInterrogationEngine.makePrompt(for: question, topic: topic)
        #expect(prompt.question == "Why does this method always give the right HCF and LCM?")
        #expect(prompt.invariantHint == "Break each number into prime factors with a factor tree. The highest common factor (HCF) multiplies the shared primes; the lowest common multiple (LCM) takes each prime the most times it appears.")
    }

    @Test("No hint rung or Why prompt leaks another subject or an internal label, on any question")
    func noLeaksOnAnyQuestion() {
        for question in Self.pack.schoolQuestions {
            let topic = Self.pack.schoolTextbook.topic(code: question.topicCode)
            var texts = Self.ladderRungs.map { MeteredHintLadderEngine.hint(for: question, rung: $0, topic: topic) }
            let why = ElaborativeInterrogationEngine.makePrompt(for: question, topic: topic)
            texts += [why.question, why.invariantHint]
            for text in texts {
                for phrase in Self.leakedPhrases {
                    #expect(!text.contains(phrase), "\(question.id): \"\(text)\" contains \"\(phrase)\"")
                }
                #expect(!text.contains(question.bookSection), "\(question.id): \"\(text)\" quotes the book section")
            }
        }
    }

    @Test("Without a topic, rung 2 and the Why prompt still read as plain maths")
    func fallbackWithoutTopic() {
        let question = Self.hcfQuestion
        let hint = MeteredHintLadderEngine.hint(for: question, rung: .r2CandidateClass, topic: nil)
        #expect(hint == "Which topic in this chapter is this question from? Name it before you start on the HCF and LCM.")
        let prompt = ElaborativeInterrogationEngine.makePrompt(for: question, topic: nil)
        #expect(prompt.question == "Why does this method always give the right HCF and LCM?")
        #expect(prompt.invariantHint == "Look back at your steps. Which one makes the answer certain?")
    }
}
