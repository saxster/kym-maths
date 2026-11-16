"""
Chapter 16, written by hand to docs/CONTENT_BRIEF.md. It goes beyond the school book and rewrites q-oup-ch15-sb.

Each section teaches one idea in nine steps, in this order: question, idea, picture, reason, name,
example, mistake, turn, sayBack. A section's `teaches` lists the concept cards whose names first
appear in its `name` step. `build(k)` returns the chapter and `cards(k)` its concept cards; both take the
exporter's answer-key helpers.
"""

from book.arithmetic import Fraction


def bayes_counts(total, prevalence, sensitivity, false_positive_rate):
    sick = round(total * prevalence)
    healthy = total - sick
    tp = round(sick * sensitivity)
    fp = round(healthy * false_positive_rate)
    return sick, healthy, tp, fp, Fraction(tp, tp + fp)


def build(k):
    return {
        "number": 16,
        "title": "Bayes: updating a belief",
        "subtitle": "Beyond the school book · Why a 95% accurate test on a rare condition is right only 28% of the time, "
                    "worked out in 1,000 people before any formula",
        "hookSummary": "A medical test is 95% accurate, and you test positive for a condition that affects 2 in 100 people. "
                       "Why is the chance you actually have it only about 28%, not 95%?",
        "beyondSchoolBook": True,
        "skillCard": {
            "skill": "Turning percentages into counts out of 1,000 people to update a probability when new evidence arrives",
            "sheCan": {
                "prompt": "With no calculator: out of 1,000 people, 2% (20 people) have a trait and 980 do not. "
                          "A test flags 95% of the 20 who have it, and also falsely flags 5% of the 980 who do not. "
                          "How many people test positive in all, and what fraction of them actually have the trait?",
                "answer": "95% of 20 is 19 true positives, and 5% of 980 is 49 false positives. "
                          "In all, 19 + 49 = 68 people test positive, and 19/68 (about 27.9%) actually have the trait.",
            },
            "whyItMatters": "Doctors reading a scan, spam filters checking an email and detectives weighing a clue all update a starting chance when new evidence arrives.",
            "standsOn": [
                "Chapter 2: simplifying fractions",
                "Chapter 3: percentages and sharing a total in a ratio",
                "Chapter 15: sample spaces and tree diagrams",
            ],
            "unlocks": [
                "Medicine: reading screening tests without panicking over false alarms",
                "Computer science: spam filters and machine learning classifiers",
                "Science: weighing how strongly new evidence supports a hypothesis",
            ],
        },
        "intuitionToFormula": {
            "concreteAction": "In the figure, set the condition rate to 2%, the true-hit rate to 95%, and the false-alarm rate to 5%.",
            "ahaInvariant": "Out of 1,000 people, everyone who tested negative disappears. "
                            "Only two bars remain: 19 sick people flagged red and 49 healthy people flagged amber, so 19 out of 68 are sick.",
            "formulaDisplay": "P(sick | +) = true positives ÷ (true positives + false positives)",
            "termMappings": [
                {"symbol": "True positives", "visualPart": "The red rectangle on the left (19 of 1,000)", "colorRole": "red",
                 "meaning": "Sick people the test rightly flags"},
                {"symbol": "False positives", "visualPart": "The amber rectangle on the right (49 of 1,000)", "colorRole": "amber",
                 "meaning": "Healthy people the test wrongly flags"},
                {"symbol": "Red ÷ (Red + Amber)", "visualPart": "The red share of the stacked bar on the far right", "colorRole": "green",
                 "meaning": "The updated chance of being sick once the test is positive"},
            ],
            "atlasFigureRef": "maths/ch17-bayes-probability/index.html",
        },
        "sections": [
            {
                "heading": "16.1 Narrowing the world when you learn a clue",
                "teaches": ["conditional-probability", "base-rate", "prior"],
                "steps": [
                    {"kind": "question",
                     "text": "In a school of 1,000 students, 20 cycle to school and 980 walk or take the bus. "
                             "What is the chance a student cycles before you look, and how does it change if they hold a cycle helmet?"},
                    {"kind": "idea",
                     "text": "Before you see the helmet, the chance is 20 out of 1,000, or 2%. "
                             "Once you see the helmet, you stop dividing by all 1,000 students and divide only by the students carrying a helmet."},
                    {"kind": "picture",
                     "text": "Draw a box of 1,000 dots, with a narrow strip of 20 cyclists on the left and 980 non-cyclists on the right. "
                             "Draw a circle around only the dots holding a helmet; that circle is your new denominator."},
                    {"kind": "reason",
                     "text": "Why does the denominator shrink? Everyone without a helmet is ruled out by what you saw. "
                             "Probabilities must be counted inside the group that matches the clue."},
                    {"kind": "name",
                     "text": "The starting share of a group in the whole population, such as 20 in 1,000 (2%), is the base rate. "
                             "Your starting probability before seeing the clue is the prior. "
                             "The probability of A given that B has happened is the conditional probability, written P(A | B), read 'the probability of A given B'."},
                    {"kind": "example",
                     "text": "In a two-way table, 30 students play chess, and 12 of those 30 also play tabla. "
                             "Given that a student plays chess, the conditional probability they play tabla is 12 ÷ 30 = 2/5."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to keep dividing by the whole 1,000 after you know the clue happened. "
                             "The vertical bar in P(A | B) means 'restrict the denominator to B'."},
                    {"kind": "turn",
                     "text": "In a club of 100 members, 25 wear glasses, and 10 of those 25 are left-handed. "
                             "Given that a member wears glasses, what is the conditional probability they are left-handed, in simplest form?",
                     "answer": "2/5",
                     "answerKey": k.one(k.num("2/5", simplest=True), accepts=["2/5", "0.4"], rejects=["10/25", "1/10", "1/4"])},
                    {"kind": "sayBack",
                     "text": "The base rate gives your prior before the clue; conditional probability P(A | B) shrinks the denominator to only the cases where B happened."},
                ],
            },
            {
                "heading": "16.2 Two ways a test can be right, and how false alarms pile up",
                "teaches": ["sensitivity", "specificity", "false-positive"],
                "steps": [
                    {"kind": "question",
                     "text": "Out of 1,000 people, 20 are sick and 980 are healthy. "
                             "A test catches 95% of the 20 sick people, and it is 95% accurate on the 980 healthy people too. "
                             "How many healthy people still get a wrong positive result?"},
                    {"kind": "idea",
                     "text": "5% of 980, which is 49 healthy people. "
                             "Even a small 5% slip rate makes a big pile of 49 wrong alarms when it acts on a crowd of 980 healthy people."},
                    {"kind": "picture",
                     "text": "Split a bar of 1,000 people into 20 sick on the left and 980 healthy on the right. "
                             "Colour 19 of the 20 red (0.95 × 20 = 19), and colour 49 of the 980 amber (0.05 × 980 = 49)."},
                    {"kind": "reason",
                     "text": "Why are there more amber boxes (49) than red boxes (19)? "
                             "Because healthy people outnumber sick people 980 to 20. Five per cent of a huge crowd beats ninety-five per cent of a tiny group."},
                    {"kind": "name",
                     "text": "The share of sick people the test rightly flags positive is its sensitivity (here 19 out of 20, or 95%). "
                             "The share of healthy people the test rightly clears negative is its specificity (here 931 out of 980, or 95%). "
                             "A healthy person wrongly flagged positive is a false positive (here the remaining 5% of 980, which is 49 people)."},
                    {"kind": "example",
                     "text": "If 500 people are healthy and a test has 98% specificity, then 98% of 500 = 490 test negative, "
                             "and the remaining 2% of 500 = 10 are false positives."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to take 5% of all 1,000 people instead of 5% of the 980 healthy people. "
                             "Sensitivity acts on the sick group; the false-positive rate acts on the healthy group."},
                    {"kind": "turn",
                     "text": "Out of 400 healthy people, a test has a 5% false-positive rate (95% specificity). "
                             "How many false positives does it produce?",
                     "answer": "20",
                     "answerKey": k.one(k.num("20"), accepts=["20", "20 people"], rejects=["380", "5", "80"])},
                    {"kind": "sayBack",
                     "text": "Sensitivity measures true hits among the sick; specificity measures true clears among the healthy, and the rest of the healthy group are false positives."},
                ],
            },
            {
                "heading": "16.3 Counting inside the positive room",
                "figure": True,
                "teaches": ["posterior", "likelihood-ratio", "bayes-theorem"],
                "steps": [
                    {"kind": "question",
                     "text": "Put all 19 truly sick positive testers and all 49 false-positive testers into one room. "
                             "If you are in that room of 68 people, what is the chance you are actually sick?"},
                    {"kind": "idea",
                     "text": "19 out of 68, which is about 27.9%. "
                             "The 932 people who tested negative are not in the room, so the chance is red divided by red plus amber."},
                    {"kind": "picture",
                     "text": "In the figure, look at the stacked bar on the far right for 2%, 95% and 5%. "
                             "The red top piece is 19 and the amber bottom piece is 49, making 68 positive tests in all."},
                    {"kind": "reason",
                     "text": "Why did the chance jump from 2% to 27.9%, yet stop far short of 95%? "
                             "A positive test is 95% ÷ 5% = 19 times as likely when you are sick as when you are healthy, "
                             "which boosts the odds from 20 : 980 to (20 × 19) : 980 = 380 : 980 = 19 : 49."},
                    {"kind": "name",
                     "text": "The updated probability after seeing the evidence is the posterior. "
                             "The multiplier sensitivity ÷ false-positive rate (here 95% ÷ 5% = 19) is the likelihood ratio. "
                             "The rule posterior = true positives ÷ (true positives + false positives) is Bayes' theorem."},
                    {"kind": "example",
                     "text": "In a group of 1,000 people, 10 are sick and 990 are healthy. "
                             "A test flags 9 of the 10 sick people and 9 of the 990 healthy people. "
                             "By Bayes' theorem, the posterior is 9 ÷ (9 + 9) = 9/18 = 1/2 = 50%."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to confuse the test's 95% sensitivity with the posterior. "
                             "Forgetting the base rate and assuming P(sick | +) equals P(+ | sick) is the base-rate trap."},
                    {"kind": "turn",
                     "text": "In a screening of 1,000 people, there are 20 true positives and 60 false positives. "
                             "What is the posterior probability of being sick given a positive test, as a decimal?",
                     "answer": "0.25",
                     "answerKey": k.one(k.num("0.25"), accepts=["0.25", "1/4"], rejects=["0.33", "0.02", "0.75"])},
                    {"kind": "sayBack",
                     "text": "Bayes' theorem finds the posterior by dividing true positives by all positives (true positives + false positives), multiplying the prior odds by the likelihood ratio."},
                ],
            },
        ],
        "callouts": [
            {"kind": "predict", "title": "Predict first",
             "body": "In the figure, raise the base rate from 2% to 10% while keeping sensitivity at 95% and false positives at 5%. "
                     "Predict whether the posterior rises above 50%."},
            {"kind": "check", "title": "Explain it",
             "body": "Explain to a friend using 1,000 people why a 95% accurate test on a rare 2% condition gives more false alarms (49) than true hits (19)."},
            {"kind": "careful", "title": "Turn percentages into 1,000 people",
             "body": "Whenever a conditional probability question gives you percentages, turn them into whole numbers out of 1,000 people before dividing."},
        ],
        "debate": {
            "id": "debate-ch16-bayes",
            "oupUnitNumber": 12,
            "title": "90% accurate test: 90% chance or 50% chance?",
            "contextPrompt": "Out of 1,000 people, 10 are sick (and 9 test positive) while 990 are healthy (and 9 test positive as false alarms). Asha and Rohan debate the chance a positive tester is sick.",
            "speakerAName": "Asha",
            "speakerAClaim": "9 out of 10 sick people test positive, so the test is 90% accurate. If you test positive, you have a 90% chance of being sick.",
            "speakerBName": "Rohan",
            "speakerBClaim": "18 people tested positive in all: 9 sick and 9 healthy, in a 1 : 1 ratio. So your chance of being sick is 9 ÷ 18 = 50%.",
            "choices": [
                {"id": "ch16-a", "speakerLabel": "Asha is right (90%)",
                 "reasoningStatement": "The chance of being sick given a positive test is the same as the test's 90% hit rate.",
                 "isCorrect": False,
                 "socraticRebuttal": "90% is the share of sick people who test positive. You also have to count the 9 healthy people who tested positive."},
                {"id": "ch16-b", "speakerLabel": "Rohan is right (9 ÷ 18 = 50%)",
                 "reasoningStatement": "Among the 18 people who tested positive, true positives and false positives are in the ratio 9 : 9, so half are sick.",
                 "isCorrect": True,
                 "socraticRebuttal": "Yes. Only 18 people tested positive, 9 sick and 9 healthy, so 9 ÷ 18 = 50%."},
                {"id": "ch16-c", "speakerLabel": "Neither. It is 9 ÷ 1,000 = 0.9%.",
                 "reasoningStatement": "Divide the 9 sick positive testers by all 1,000 people.",
                 "isCorrect": False,
                 "socraticRebuttal": "Once you know the test is positive, the 982 people who tested negative are ruled out."},
            ],
            "invariantTakeaway": "Among all positive tests, compare true positives with false positives: P(sick | +) = true positives ÷ (true positives + false positives).",
        },
        "keyTerms": ["Conditional probability", "Base rate", "Prior", "Sensitivity", "Specificity",
                     "False positive", "Posterior", "Likelihood ratio", "Bayes' theorem"],
        "widgets": ["w_atlas_bayes_square", "w_bayes_natural_frequency_tree"],
        "widgetText": {
            "w_atlas_bayes_square": {
                "title": "The 1,000-person Bayes square",
                "challengePrompt": "Set the condition rate to 2%, sensitivity to 95%, and false-positive rate to 5%. "
                                   "Predict whether the red true-positive box or the amber false-positive box is bigger.",
                "cutaway": "Out of 1,000 people, 20 are sick (19 red true positives) and 980 are healthy (49 amber false positives). "
                           "The posterior is 19 ÷ (19 + 49) ≈ 27.9%.",
                "idealised": "The rule: P(sick | +) = true positives ÷ (true positives + false positives)",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Set the three sliders to 2%, 95% and 5%."},
                    {"title": "2. Notice", "caption": "The red count is 19 and the amber count is 49."},
                    {"title": "3. Match the rule", "caption": "Look at the bar on the far right: 19 ÷ (19 + 49) = 19/68 ≈ 27.9%."},
                    {"title": "4. Push it further", "caption": "Slide the condition rate up to 10% and watch the red share overtake the amber share."},
                    {"title": "5. Draw it", "caption": "Draw the 1,000-person tree split into 20 and 980 in your notebook."},
                ],
            },
            "w_bayes_natural_frequency_tree": {
                "title": "Counting 1,000 people through a tree",
                "challengePrompt": "Follow 1,000 people down the branches: first split by the base rate, then by the test result. "
                                   "Add the two positive tips to find the new denominator.",
                "cutaway": "Replacing decimals with 1,000 whole people turns Bayes' theorem into simple addition: "
                           "19 true positives plus 49 false positives make 68 positives in all.",
                "idealised": "The rule: posterior = red tip ÷ (red tip + amber tip)",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Start with 1,000 people at the root of the tree."},
                    {"title": "2. Notice", "caption": "2% sends 20 people down the sick branch and 980 down the healthy branch."},
                    {"title": "3. Match the rule", "caption": "95% of 20 gives 19 red; 5% of 980 gives 49 amber; 19 ÷ 68 ≈ 27.9%."},
                    {"title": "4. Push it further", "caption": "What if a second independent test is run on those 68 people?"},
                    {"title": "5. Draw it", "caption": "Write the four leaf counts (19, 1, 49, 931) and check they add to 1,000."},
                ],
            },
        },
        "atlasLessons": [
            {
                "title": "Chapter 16 · Why the base rate matters",
                "question": "Why does a 95% accurate test give so many false alarms when a condition is rare?",
                "explanation": "When only 20 in 1,000 people have the condition, 980 are healthy. "
                               "Even a 5% false-alarm rate on 980 healthy people creates 49 false positives, more than twice the 19 true positives.",
                "limits": "The rule: count true positives and false positives out of 1,000 people first",
            },
            {
                "title": "Chapter 16 · Throwing away the negative tests",
                "question": "Why is the denominator 68 instead of 1,000 once the test comes back positive?",
                "explanation": "The 932 people who tested negative are no longer possible cases. "
                               "Conditioning on a positive test restricts the world to the 19 + 49 = 68 positive testers.",
                "limits": "The rule: P(D | +) = TP ÷ (TP + FP)",
            },
            {
                "title": "Chapter 16 · Multiplying the odds by the likelihood ratio",
                "question": "How does a positive test change the ratio of sick to healthy?",
                "explanation": "Each sick person is 95% ÷ 5% = 19 times as likely to test positive as each healthy person. "
                               "So the prior ratio 20 : 980 is multiplied by 19 to become 380 : 980 = 19 : 49.",
                "limits": "The rule: posterior odds = prior odds × likelihood ratio",
            },
        ],
        "visualMathTips": {
            "tip-bayes-square": {
                "title": "Why a positive result from a 95% accurate test is right only 28% of the time",
                "visualIntuition": "In a square of 1,000 people at a 2% base rate, only 20 people are sick while 980 are healthy.",
                "ahaMoment": "A 5% false-alarm rate on 980 healthy people creates 49 false positives, which outnumber the 19 true positives.",
                "formula": "P(D | +) = 19 ÷ (19 + 49) = 19/68 ≈ 27.9%",
            },
        },
        "schoolQuestions": {
            "q-oup-ch15-sb": {
                "workedExample": "Step 1: Out of 1,000 people, 2% have the trait: 0.02 × 1,000 = 20 people, and 980 do not.\n"
                                 "Step 2: True positives = 95% of 20 = 0.95 × 20 = 19 people.\n"
                                 "Step 3: False positives = 5% of 980 = 0.05 × 980 = 49 people.\n"
                                 "Step 4: Out of 19 + 49 = 68 positive tests, P(D | +) = 19/68 ≈ 27.9%.",
                "fadedPrompt": "True positives = 19 and false positives = 49, so P(D | +) = 19 ÷ (19 + 49) = ___.",
            },
        },
    }


def cards(k):
    """The concept cards chapter 16 teaches."""
    return {
        "conditional-probability": {
            "name": "Conditional probability",
            "aliases": ["conditional probability", "conditional probabilities", "P(A | B)", "P(D | +)"],
            "oneSentence": "The probability that A happens given that B has already happened, written P(A | B): count of (A and B) divided by count of B.",
            "picture": "A Venn diagram where everything outside circle B is shaded out, leaving only circle B as the new denominator.",
            "steps": [
                "Restrict your attention to the group where the given condition B happened.",
                "Count how many in that group also have A.",
                "Divide count(A and B) by count(B).",
            ],
            "workedExample": "Out of 50 students who study French, 15 also study German. Given a student studies French, P(German | French) = 15 ÷ 50 = 3/10.",
            "check": {
                "prompt": "In a group, 40 people drink tea, and 12 of those 40 also take sugar. "
                          "Given that a person drinks tea, what is the conditional probability they take sugar, in simplest form?",
                "answer": "3/10",
                "answerKey": k.one(k.num("3/10", simplest=True), accepts=["3/10", "0.3"], rejects=["12/40", "12/52", "10/3"]),
            },
            "mixUp": {
                "name": "dividing by the whole population instead of B",
                "how": "Once B is known to be true, divide by the count of B (40), not by the whole room.",
            },
            "standsOn": ["probability", "sample-space"],
        },
        "base-rate": {
            "name": "Base rate",
            "aliases": ["base rate", "base rates", "base-rate", "prevalence"],
            "oneSentence": "The starting share of the population that has a trait or condition before any test is run.",
            "picture": "A narrow 20-person strip on the left edge of a 1,000-person square (2%).",
            "steps": [
                "Start with a round crowd of 1,000 people.",
                "Multiply 1,000 by the base rate percentage to see how many have the condition.",
                "Subtract from 1,000 to see how many do not.",
            ],
            "workedExample": "A base rate of 3% means 30 people out of every 1,000 have the condition, and 970 do not.",
            "check": {
                "prompt": "A condition has a base rate of 4%. Out of 1,000 people, how many have the condition?",
                "answer": "40",
                "answerKey": k.one(k.num("40"), accepts=["40", "40 people"], rejects=["4", "960", "400"]),
            },
            "mixUp": {
                "with": "posterior",
                "how": "The base rate is the starting share in the whole population before the test; the posterior is the share after a test result.",
            },
            "standsOn": ["probability", "percentage"],
        },
        "prior": {
            "name": "Prior",
            "aliases": ["prior", "priors", "prior probability"],
            "oneSentence": "Your starting probability for a belief before you see the new piece of evidence.",
            "picture": "The 2% starting mark on the probability bar before the test result arrives.",
            "steps": [
                "Check what is known before the new clue or test result.",
                "With no other personal clue, set the prior equal to the population base rate.",
                "Update it to the posterior once the evidence comes in.",
            ],
            "workedExample": "If 5% of emails are spam, the prior probability that a new email is spam before reading a word is 0.05.",
            "check": {
                "prompt": "1 in 20 boxes in a warehouse contains a prize. Before opening a box, what is the prior probability it has a prize, as a decimal?",
                "answer": "0.05",
                "answerKey": k.one(k.num("0.05"), accepts=["0.05", "1/20"], rejects=["0.5", "0.95", "20"]),
            },
            "mixUp": {
                "with": "posterior",
                "how": "Prior means 'before the clue'; posterior means 'after the clue'.",
            },
            "standsOn": ["base-rate", "probability"],
        },
        "sensitivity": {
            "name": "Sensitivity",
            "aliases": ["sensitivity", "true-positive rate"],
            "oneSentence": "The share of truly sick people that a test rightly flags as positive: P(+ | sick).",
            "picture": "19 red positive boxes out of the 20 sick people in the left column (19 ÷ 20 = 95%).",
            "steps": [
                "Look only at the group who truly have the condition.",
                "Multiply that count by the sensitivity to find the number of true positives.",
                "The remaining sick people are missed (false negatives).",
            ],
            "workedExample": "If 40 people have a virus and a test has 90% sensitivity, it rightly flags 0.90 × 40 = 36 of them.",
            "check": {
                "prompt": "Out of 50 people who have a condition, a test flags 45 as positive. What is the test's sensitivity, as a percentage?",
                "answer": "90%",
                "answerKey": k.one(k.num("90"), accepts=["90%", "90"], rejects=["45%", "10%", "95%"]),
            },
            "mixUp": {
                "with": "posterior",
                "how": "Sensitivity is P(+ | sick), the hit rate among sick people. It is not P(sick | +), the chance a positive tester is sick.",
            },
            "standsOn": ["conditional-probability", "percentage"],
        },
        "specificity": {
            "name": "Specificity",
            "aliases": ["specificity", "true-negative rate"],
            "oneSentence": "The share of healthy people that a test rightly clears as negative: P(− | healthy).",
            "picture": "931 cleared people out of 980 healthy people when specificity is 95%.",
            "steps": [
                "Look only at the healthy group who do not have the condition.",
                "Multiply that count by the specificity to find the true negatives.",
                "Subtract specificity from 100% to get the false-positive rate.",
            ],
            "workedExample": "A test with 96% specificity rightly clears 96% of healthy people and gives false positives to the other 4%.",
            "check": {
                "prompt": "A test has 92% specificity on healthy people. What percentage of healthy people get a false positive?",
                "answer": "8%",
                "answerKey": k.one(k.num("8"), accepts=["8%", "8"], rejects=["92%", "18%", "2%"]),
            },
            "mixUp": {
                "with": "sensitivity",
                "how": "Sensitivity tests the sick group; specificity tests the healthy group.",
            },
            "standsOn": ["conditional-probability", "percentage"],
        },
        "false-positive": {
            "name": "False positive",
            "aliases": ["false positive", "false positives", "false-positive", "false alarm", "false alarms"],
            "oneSentence": "A healthy person (or clean item) that a test wrongly flags as positive.",
            "picture": "The 49 amber boxes inside the healthy column: 5% of 980 healthy people.",
            "steps": [
                "Find the number of healthy people who do not have the condition.",
                "Multiply by the false-positive rate (1 − specificity).",
                "Add this count to the true positives to get the total number of positive tests.",
            ],
            "workedExample": "With 900 healthy people and a 5% false-positive rate, there are 0.05 × 900 = 45 false positives.",
            "check": {
                "prompt": "Out of 800 healthy people, a test has a 3% false-positive rate. How many false positives occur?",
                "answer": "24",
                "answerKey": k.one(k.num("24"), accepts=["24", "24 people"], rejects=["3", "776", "240"]),
            },
            "mixUp": {
                "name": "applying the false-positive rate to the sick group",
                "how": "Only a healthy person can be a false positive, so multiply the false-positive rate by the healthy count.",
            },
            "standsOn": ["specificity", "percentage"],
        },
        "posterior": {
            "name": "Posterior",
            "aliases": ["posterior", "posteriors", "posterior probability"],
            "oneSentence": "The updated probability after taking the new evidence into account: true positives divided by all positive tests.",
            "picture": "The red share at the top of the isolated positive bar: 19 out of 68.",
            "steps": [
                "Count the true positives (red) and the false positives (amber).",
                "Add them to find everyone who tested positive.",
                "Divide true positives by total positives.",
            ],
            "workedExample": "When 15 sick people and 30 healthy people test positive, the posterior is 15 ÷ (15 + 30) = 15/45 = 1/3.",
            "check": {
                "prompt": "In a trial, 12 sick people and 28 healthy people test positive. What is the posterior probability of being sick, as a decimal?",
                "answer": "0.3",
                "answerKey": k.one(k.num("0.3"), accepts=["0.3", "3/10"], rejects=["0.43", "12/28", "0.7"]),
            },
            "mixUp": {
                "with": "prior",
                "how": "The prior is the chance before the test; the posterior is the updated chance among those who tested positive.",
            },
            "standsOn": ["prior", "false-positive"],
        },
        "likelihood-ratio": {
            "name": "Likelihood ratio",
            "aliases": ["likelihood ratio", "likelihood ratios"],
            "oneSentence": "How many times more likely a positive result is for a sick person than for a healthy person: sensitivity ÷ false-positive rate.",
            "picture": "A 95% hit bar compared with a 5% false-alarm bar: 95% ÷ 5% = 19 times as tall.",
            "steps": [
                "Write the sensitivity and the false-positive rate in the same form (both percentages or both decimals).",
                "Divide sensitivity by the false-positive rate.",
                "Multiply the prior odds by this ratio to get the posterior odds.",
            ],
            "workedExample": "A test with 90% sensitivity and a 10% false-positive rate has a likelihood ratio of 90 ÷ 10 = 9.",
            "check": {
                "prompt": "A test has 80% sensitivity and a 4% false-positive rate. What is its likelihood ratio?",
                "answer": "20",
                "answerKey": k.one(k.num("20"), accepts=["20", "20:1"], rejects=["76", "3.2", "0.05"]),
            },
            "mixUp": {
                "name": "subtracting instead of dividing",
                "how": "Divide 80% by 4% to get 20; do not subtract 80 − 4 = 76.",
            },
            "standsOn": ["sensitivity", "false-positive", "ratio"],
        },
        "bayes-theorem": {
            "name": "Bayes' theorem",
            "aliases": ["Bayes' theorem", "Bayes’ theorem", "Bayes' rule", "Bayes’ rule"],
            "oneSentence": "The rule that updates a prior probability with new evidence: P(D | +) = true positives ÷ (true positives + false positives).",
            "picture": "The 1,000-person square narrowed down to its red true-positive block over red plus amber.",
            "steps": [
                "Turn the base rate into sick and healthy counts out of 1,000.",
                "Work out true positives from the sick count and false positives from the healthy count.",
                "Divide true positives by (true positives + false positives).",
            ],
            "workedExample": "Out of 1,000 people, 20 are sick (19 test +) and 980 are healthy (49 test +). Bayes' theorem gives P(D | +) = 19 ÷ (19 + 49) = 19/68.",
            "check": {
                "prompt": "Out of 1,000 people, 50 are sick and 40 of them test positive. Of the 950 healthy people, 40 also test positive. "
                          "By Bayes' theorem, what is P(sick | +) as a decimal?",
                "answer": "0.5",
                "answerKey": k.one(k.num("0.5"), accepts=["0.5", "1/2"], rejects=["0.8", "0.04", "0.05"]),
            },
            "mixUp": {
                "name": "ignoring the healthy crowd",
                "how": "40 out of 50 is 80% sensitivity, but because 40 healthy people also tested positive, the true share among positive tests is 40 ÷ 80 = 0.5.",
            },
            "standsOn": ["posterior", "sensitivity", "false-positive"],
        },
    }


def sums():
    """Every sum chapter 16 and its cards state, recomputed."""
    sick, healthy, tp, fp, post = bayes_counts(1000, Fraction(2, 100), Fraction(95, 100), Fraction(5, 100))
    return [
        # Main 1,000-person example (2%, 95%, 5%)
        ("1000-person 2% 95% 5%",
         (sick, healthy, tp, fp, tp + fp, post, round(float(post) * 100, 1), 1000 - (tp + fp), healthy - fp),
         (20, 980, 19, 49, 68, Fraction(19, 68), 27.9, 932, 931)),
        # 16.1
        ("16.1 example and turn", (Fraction(12, 30), Fraction(10, 25)), (Fraction(2, 5), Fraction(2, 5))),
        # 16.2
        ("16.2 example 500 at 98%", (round(500 * 0.98), round(500 * 0.02)), (490, 10)),
        ("turn 16.2 400 at 5%", (round(400 * 0.05), round(400 * 0.95)), (20, 380)),
        # 16.3
        ("likelihood ratio 95 / 5", (95 // 5, 20 * 19, Fraction(380, 980)), (19, 380, Fraction(19, 49))),
        ("16.3 example and debate 10 sick 990 healthy",
         (10 + 990, 9 + 9, Fraction(9, 18), 1000 - 18), (1000, 18, Fraction(1, 2), 982)),
        ("turn 16.3 20 TP 60 FP", (float(Fraction(20, 20 + 60)), round(20 / 60, 2)), (0.25, 0.33)),
        # Cards
        ("conditional-probability card and check", (Fraction(15, 50), Fraction(12, 40)), (Fraction(3, 10), Fraction(3, 10))),
        ("base-rate card and check", (round(1000 * 0.03), 1000 - 30, round(1000 * 0.04), 1000 - 40), (30, 970, 40, 960)),
        ("prior check", float(Fraction(1, 20)), 0.05),
        ("sensitivity card and check", (round(40 * 0.90), round(45 / 50 * 100)), (36, 90)),
        ("specificity card and check", (100 - 96, 100 - 92), (4, 8)),
        ("false-positive card and check", (round(900 * 0.05), round(800 * 0.03), 800 - 24), (45, 24, 776)),
        ("posterior card and check",
         (Fraction(15, 15 + 30), float(Fraction(12, 12 + 28)), round(12 / 28, 2)),
         (Fraction(1, 3), 0.3, 0.43)),
        ("likelihood-ratio card and check", (90 // 10, 80 // 4, 80 - 4), (9, 20, 76)),
        ("bayes-theorem check", (50 + 950, float(Fraction(40, 40 + 40)), float(Fraction(40, 50))), (1000, 0.5, 0.8)),
    ]


def answers():
    """Chapter 16's turn answers and its cards' check answers, computed."""
    return {
        "ch16-s1-turn": Fraction(10, 25),
        "ch16-s2-turn": round(400 * Fraction(5, 100)),
        "ch16-s3-turn": float(Fraction(20, 20 + 60)),
        "conditional-probability-check": Fraction(12, 40),
        "base-rate-check": round(1000 * Fraction(4, 100)),
        "prior-check": float(Fraction(1, 20)),
        "sensitivity-check": round(Fraction(45, 50) * 100),
        "specificity-check": 100 - 92,
        "false-positive-check": round(800 * Fraction(3, 100)),
        "posterior-check": float(Fraction(12, 12 + 28)),
        "likelihood-ratio-check": 80 // 4,
        "bayes-theorem-check": float(Fraction(40, 40 + 40)),
    }
