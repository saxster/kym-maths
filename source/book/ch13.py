"""
Chapter 13, written by hand to docs/CONTENT_BRIEF.md. It maps to OUP Unit 4 (Sampling).

Each section teaches one idea in nine steps, in this order: question, idea, picture, reason, name,
example, mistake, turn, sayBack. A section's `teaches` lists the concept cards whose names first
appear in its `name` step. `build(k)` returns the chapter and `cards(k)` its concept cards; both take the
exporter's answer-key helpers.
"""

import math

from book.arithmetic import Fraction


def stratified_share(stratum_size, total_population, sample_size):
    """How many to pick from one group so its share in the sample matches its share in the population."""
    share = Fraction(stratum_size, total_population) * sample_size
    return int(share) if share.denominator == 1 else share


def standard_error(sigma, n):
    """The typical spread of sample means around the population mean: sigma divided by root n."""
    root = math.isqrt(n)
    if root * root == n:
        val = Fraction(sigma, root)
        return int(val) if val.denominator == 1 else float(val)
    return round(sigma / math.sqrt(n), 2)


def build(k):
    return {
        "number": 13,
        "title": "Samples you can trust",
        "subtitle": "School book chapter 4 · Picking a fair group, spotting a lopsided survey, "
                    "Abraham Wald's returning planes, and why bigger samples steady the average",
        "hookSummary": "A soup pot holds 10 litres. You do not drink all 10 litres to check the salt. "
                       "You stir the pot well and taste one spoonful.",
        "beyondSchoolBook": False,
        "skillCard": {
            "skill": "Designing a fair sample by random, systematic or stratified choice, and spotting when a survey leaves an important group out",
            "sheCan": {
                "prompt": "With no calculator: a school has 240 Year 7 students, 180 Year 8 students and 180 Year 9 students, 600 in all. "
                          "How many from each year belong in a fair sample of 50? "
                          "And if you pick 20 names at even steps from a list of 600, what step size do you use?",
                "answer": "Year 7 is 240 ÷ 600 × 50 = 20, Year 8 is 180 ÷ 600 × 50 = 15, and Year 9 is 15. "
                          "For 20 names from 600, step through every 600 ÷ 20 = 30th name.",
            },
            "whyItMatters": "Doctors testing a medicine, pollsters before an election and engineers checking factory parts can never test everyone. "
                            "A fair sample tells the truth about the whole group; a lopsided one fools you even when it is huge.",
            "standsOn": [
                "Chapter 2: fractions and simplifying a part of a whole",
                "Chapter 3: sharing a total in a given ratio",
                "Chapter 1: square roots, for how fast sample error shrinks",
            ],
            "unlocks": [
                "Chapter 14: drawing and measuring the spread of data you collect",
                "Chapter 15: counting equally likely outcomes when picking at random",
                "Chapter 16: updating a belief when a test screens a whole population",
            ],
        },
        "intuitionToFormula": {
            "concreteAction": "In the figure, keep the spread at 12 and slide the group size from 4 up to 16, then to 64.",
            "ahaInvariant": "When the group size is multiplied by 4, the width of the red error bar is cut in half. "
                            "And on the returning plane, the missing bullet holes on the engines show where a hit brings the plane down.",
            "formulaDisplay": "Group share = (group ÷ total) × sample,   Standard error = σ ÷ √n",
            "termMappings": [
                {"symbol": "group ÷ total", "visualPart": "Each year group's share of the whole school", "colorRole": "blue",
                 "meaning": "The fraction of the sample that group should get"},
                {"symbol": "σ ÷ √n", "visualPart": "The red bracket under the curve", "colorRole": "red",
                 "meaning": "How far a typical sample average sits from the true average"},
                {"symbol": "Missing hits", "visualPart": "The amber engine box on the plane", "colorRole": "amber",
                 "meaning": "Planes hit there did not come back to be counted"},
            ],
            "atlasFigureRef": "statistics/error/index.html",
        },
        "sections": [
            {
                "heading": "13.1 Tasting the soup without drinking the pot",
                "teaches": ["population", "sample", "random-sample"],
                "steps": [
                    {"kind": "question",
                     "text": "A cook makes a 10-litre pot of dal. How does she know if it needs more salt without eating the whole pot?"},
                    {"kind": "idea",
                     "text": "She stirs the pot well and tastes one spoonful. "
                             "When the pot is well mixed, a small spoonful tells the truth about the whole pot."},
                    {"kind": "picture",
                     "text": "Picture 600 folded slips of paper in a drum, one for each student in a school. "
                             "Shake the drum and pull out 30 slips with your eyes shut."},
                    {"kind": "reason",
                     "text": "Why shut your eyes and shake the drum? If you only ask your own table at lunch, you get your friends' habits, not the school's. "
                             "Giving every person the same chance keeps favourites out."},
                    {"kind": "name",
                     "text": "The whole group you want to know about is the population. "
                             "A smaller group chosen from it is a sample. "
                             "When every member of the population has the same chance of being chosen, it is a random sample."},
                    {"kind": "example",
                     "text": "A school has 600 students. Number them 1 to 600 and let a computer pick 30 numbers with equal chance. "
                             "The 600 students are the population, and the 30 chosen are a random sample."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to think 'random' means picking whoever walks past first. "
                             "That leaves out everyone in a classroom or on another floor. Use numbered slips or a random number list."},
                    {"kind": "turn",
                     "text": "A factory bakes 2,000 biscuits and picks 40 of them by lot to test their weight. "
                             "How many biscuits are in the population?",
                     "answer": "2000",
                     "answerKey": k.one(k.num("2000"), accepts=["2000", "2,000", "2000 biscuits"], rejects=["40", "1960", "50"])},
                    {"kind": "sayBack",
                     "text": "The population is the whole group, a sample is the part you test, and a random sample gives everyone the same chance."},
                ],
            },
            {
                "heading": "13.2 Stepping through a list and matching group shares",
                "teaches": ["systematic-sample", "stratified-sample"],
                "steps": [
                    {"kind": "question",
                     "text": "A school has 400 students in Year 7 and 200 in Year 8. "
                             "If you want 30 students in your sample, should you pick 15 from each year?"},
                    {"kind": "idea",
                     "text": "No. Year 7 is twice as big as Year 8, so it should get twice as many places in the sample: 20 from Year 7 and 10 from Year 8."},
                    {"kind": "picture",
                     "text": "Draw a bar of 6 equal blocks for the 600 students: 4 blocks for Year 7 and 2 blocks for Year 8. "
                             "Share the 30 sample places across the 6 blocks: 5 in each block."},
                    {"kind": "reason",
                     "text": "Why not 15 and 15? Taking 15 from each gives Year 8 half the voice in the sample when they are only a third of the school. "
                             "Matching each group's fraction keeps the sample in the same ratio as the school."},
                    {"kind": "name",
                     "text": "When you split the population into groups and pick from each group in proportion to its size, you take a stratified sample. "
                             "When you line everyone up on a numbered list and pick every kth person from a random start, you take a systematic sample."},
                    {"kind": "example",
                     "text": "To pick a systematic sample of 20 from a list of 600 names, divide 600 ÷ 20 = 30. "
                             "Pick a random start between 1 and 30, say 7, then take the 7th, 37th, 67th, and every 30th name."},
                    {"kind": "mistake",
                     "text": "The tempting slip in a stratified sample is to divide the sample equally among the groups. "
                             "Always multiply the sample size by group size ÷ total population."},
                    {"kind": "turn",
                     "text": "A club has 120 juniors and 80 seniors, 200 members in all. "
                             "In a stratified sample of 40 members, how many juniors should be chosen?",
                     "answer": "24",
                     "answerKey": k.one(k.num("24"), accepts=["24", "24 juniors"], rejects=["20", "16", "60"])},
                    {"kind": "sayBack",
                     "text": "A systematic sample takes every kth item on a list; a stratified sample gives each group its true fraction of the sample."},
                ],
            },
            {
                "heading": "13.3 The planes that did not come back",
                "teaches": ["bias", "survivorship-bias"],
                "steps": [
                    {"kind": "question",
                     "text": "Wanting to know how many hours people in Mumbai exercise, you ask 100 people leaving a gym at 6 am. "
                             "Why will your answer be too high?"},
                    {"kind": "idea",
                     "text": "Because people who never go to a gym had zero chance of being asked. "
                             "Your method favoured early-morning gym-goers before a single question was answered."},
                    {"kind": "picture",
                     "text": "Picture the outline of a Second World War plane. "
                             "Returning planes are covered in bullet holes along the wings and tail, while the engine boxes are clean."},
                    {"kind": "reason",
                     "text": "Why did the mathematician Abraham Wald put armour on the clean engines instead of the riddled wings? "
                             "Enemy bullets hit every part equally. Planes hit in the wings flew home to be counted; planes hit in the engine crashed and were missing from the shed."},
                    {"kind": "name",
                     "text": "When a sampling method favours some parts of the population over others, the sample has bias. "
                             "When you only see the ones that survived a test or a journey and forget the ones that dropped out, that is survivorship bias."},
                    {"kind": "example",
                     "text": "Reading only five-star reviews from customers who kept a phone for two years misses everyone who returned it in the first week. "
                             "That is survivorship bias."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to think a bigger sample cures bias. "
                             "Asking 10,000 people outside the gym still misses everyone asleep at home. Fix how you pick, not how many."},
                    {"kind": "turn",
                     "text": "Out of 50 planes sent out, 8 are hit in the engine and all 8 crash. "
                             "The other 42 return with wing hits. How many engine-hit planes are in the shed to be counted?",
                     "answer": "0",
                     "answerKey": k.one(k.num("0"), accepts=["0", "0 planes"], rejects=["8", "42", "50"])},
                    {"kind": "sayBack",
                     "text": "Bias happens when some members are more likely to be picked than others; survivorship bias happens when dropouts are invisible."},
                ],
            },
            {
                "heading": "13.4 Why four times the sample halves the wobble",
                "figure": True,
                "teaches": ["mean", "standard-error"],
                "steps": [
                    {"kind": "question",
                     "text": "Two students each estimate the average height in their school using a fair random sample. "
                             "Asha measures 16 students; Rohan measures 64. Whose estimate is likely to sit closer to the true school figure?"},
                    {"kind": "idea",
                     "text": "Rohan's. This step goes beyond the school book. "
                             "Because 64 is 4 times 16, and the square root of 4 is 2, Rohan's typical error is half as wide as Asha's."},
                    {"kind": "picture",
                     "text": "In the figure, keep the population spread at 12 and move the sample size from 16 to 64. "
                             "Watch the red bracket shrink from 3 down to 1.5."},
                    {"kind": "reason",
                     "text": "Why does the error divide by √n instead of n? In a random group, high values and low values partly cancel each other out. "
                             "The leftover wobble shrinks with the square root of the group size."},
                    {"kind": "name",
                     "text": "Adding the values and dividing by how many there are gives the mean. "
                             "The typical gap between a sample mean and the population mean is the standard error, σ ÷ √n."},
                    {"kind": "example",
                     "text": "If the population spread σ is 12 cm and you take a sample of n = 16 students, the standard error is 12 ÷ √16 = 12 ÷ 4 = 3 cm. "
                             "With n = 64 students, it drops to 12 ÷ √64 = 12 ÷ 8 = 1.5 cm."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to think doubling the sample size halves the standard error. "
                             "Because of the square root, you must multiply the sample size by 4 to halve the standard error."},
                    {"kind": "turn",
                     "text": "A population has spread σ = 20, and you take a random sample of n = 25 items. "
                             "Using σ ÷ √n, what is the standard error?",
                     "answer": "4",
                     "answerKey": k.one(k.num("4"), accepts=["4", "SE = 4"], rejects=["0.8", "5", "100"])},
                    {"kind": "sayBack",
                     "text": "The standard error is σ ÷ √n, so multiplying a random sample's size by 4 cuts the typical error of the mean in half."},
                ],
            },
        ],
        "callouts": [
            {"kind": "predict", "title": "Predict first",
             "body": "Keep the spread at 12 and multiply the sample size from 4 to 16. "
                     "Predict whether the standard error is divided by 4 or by 2."},
            {"kind": "check", "title": "Explain it",
             "body": "Explain to a friend why Abraham Wald told the engineers to armour the parts of the returning planes that had no bullet holes."},
            {"kind": "careful", "title": "Fairness before size",
             "body": "A sample of 50 chosen fairly across every year group beats a survey of 500 volunteers from one corridor."},
        ],
        "debate": {
            "id": "debate-ch13-sampling",
            "oupUnitNumber": 4,
            "title": "Equal numbers or equal shares?",
            "contextPrompt": "A school has 300 students in Year 7 and 100 in Year 8. Asha and Rohan want a stratified sample of 40 students.",
            "speakerAName": "Asha",
            "speakerAClaim": "There are two year groups, so a fair sample takes the same number from each: 20 from Year 7 and 20 from Year 8.",
            "speakerBName": "Rohan",
            "speakerBClaim": "Year 7 is three quarters of the school, so it gets three quarters of the sample: 30 from Year 7 and 10 from Year 8.",
            "choices": [
                {"id": "ch13-a", "speakerLabel": "Asha is right (20 and 20)",
                 "reasoningStatement": "Every group should have the same number of people in the sample.",
                 "isCorrect": False,
                 "socraticRebuttal": "If Year 8 gets 20 out of 40 places, it has half the sample even though it is only a quarter of the school."},
                {"id": "ch13-b", "speakerLabel": "Rohan is right (30 and 10)",
                 "reasoningStatement": "Each group gets the same fraction of the sample as its fraction of the whole school.",
                 "isCorrect": True,
                 "socraticRebuttal": "Yes. 300 ÷ 400 × 40 = 30 from Year 7 and 100 ÷ 400 × 40 = 10 from Year 8, so every student has the same 1 in 10 chance."},
                {"id": "ch13-c", "speakerLabel": "Neither. Take all 40 from Year 7 because it is the largest group.",
                 "reasoningStatement": "Only the biggest group matters for the school average.",
                 "isCorrect": False,
                 "socraticRebuttal": "Leaving Year 8 out completely gives a biased sample with zero voice for a quarter of the school."},
            ],
            "invariantTakeaway": "In a stratified sample, each group's share of the sample matches its share of the whole population.",
        },
        "keyTerms": ["Population", "Sample", "Random sample", "Systematic sample", "Stratified sample",
                     "Bias", "Survivorship bias", "Mean", "Standard error"],
        "widgets": ["w_atlas_sampling_error", "w_wald_survivorship_bomber"],
        "widgetText": {
            "w_atlas_sampling_error": {
                "title": "Sample size and the error bar",
                "challengePrompt": "Move the sample size from 4 to 16 and then to 64. "
                                   "Predict what happens to the width of the red error bar each time.",
                "cutaway": "High and low readings in a random sample partly cancel out. "
                           "The standard error is σ ÷ √n, so multiplying the sample size by 4 halves the error bar.",
                "idealised": "The rule: standard error = σ ÷ √n",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Keep the spread σ at 12 and set the sample size n to 4."},
                    {"title": "2. Notice", "caption": "At n = 4, the standard error is 12 ÷ 2 = 6."},
                    {"title": "3. Match the rule", "caption": "Slide n to 16: √16 = 4, and the standard error drops to 12 ÷ 4 = 3."},
                    {"title": "4. Push it further", "caption": "Slide n to 64 and check that 12 ÷ 8 = 1.5."},
                    {"title": "5. Draw it", "caption": "Write down the standard error for n = 4, 16 and 64 in your notebook."},
                ],
            },
            "w_wald_survivorship_bomber": {
                "title": "Wald's returning planes",
                "challengePrompt": "Look at where the returning planes were hit. "
                                   "Decide whether the armour belongs on the wings with many holes or the engine with none.",
                "cutaway": "You only see the planes that made it back. "
                           "Holes on the wings show where a plane can take a hit and still fly home; the clean engine marks where a hit is fatal.",
                "idealised": "The rule: ask who is missing from the sample before you trust the count",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Look at the blue plane outline on the right of the figure."},
                    {"title": "2. Notice", "caption": "The returning planes have hits on the fuselage and wings, not on the engine."},
                    {"title": "3. Match the rule", "caption": "Planes hit in the engine crashed, so survivorship bias hid them from the count."},
                    {"title": "4. Push it further", "caption": "Think of a phone survey or a product review where the unhappy people dropped out early."},
                    {"title": "5. Draw it", "caption": "Sketch the plane and label the missing engine hits as the unseen dropouts."},
                ],
            },
        },
        "atlasLessons": [
            {
                "title": "Chapter 13 · Fair shares in a stratified sample",
                "question": "Why do we multiply the sample size by each group's fraction of the population?",
                "explanation": "If a year group holds 240 out of 600 students, it is two fifths of the school. "
                               "Giving it two fifths of the sample means every student in the school has the same chance of being chosen.",
                "limits": "The rule: group sample = (group size ÷ total population) × sample size",
            },
            {
                "title": "Chapter 13 · Seeing the missing data",
                "question": "Why does a huge sample still lie when the method has bias?",
                "explanation": "If a survey leaves out one part of the population, taking more replies from the same place repeats the same blind spot.",
                "limits": "The rule: a random or stratified choice comes before sample size",
            },
            {
                "title": "Chapter 13 · The square-root law of sample size",
                "question": "Why must you quadruple the sample size to cut the standard error in half?",
                "explanation": "Random ups and downs cancel in proportion to √n. "
                               "Dividing by √(4n) is dividing by 2√n, which halves the typical error.",
                "limits": "The rule: standard error = σ ÷ √n",
            },
        ],
        "visualMathTips": {},
        "schoolTopics": {
            "4.1": "Primary data is data you collect yourself by counting, measuring or asking questions. "
                   "Secondary data comes from a table or record someone else already gathered. "
                   "A fair questionnaire uses short, neutral questions and non-overlapping answer boxes that cover every possible reply.",
            "4.2": "A random sample gives every member of the population the same chance. "
                   "A systematic sample picks every kth member from a numbered list, and a stratified sample takes from each group in proportion to its size.",
        },
        "schoolQuestions": {
            "q-oup-ch04-sb": {
                "workedExample": "Step 1: Add the three year groups to find the population: 240 + 180 + 180 = 600 students.\n"
                                 "Step 2: Year 7 gets 240 ÷ 600 × 50 = 20 students.\n"
                                 "Step 3: Year 8 gets 180 ÷ 600 × 50 = 15 students, and Year 9 gets 180 ÷ 600 × 50 = 15 students.\n"
                                 "Step 4: Check the total: 20 + 15 + 15 = 50 students.",
                "fadedPrompt": "Out of 600 students, Year 7 gets 240 ÷ 600 × 50 = ___, Year 8 gets ___, and Year 9 gets ___.",
            },
            "q-oup-ch04-wb-focus": {
                "workedExample": "Step 1: Divide the total list length by the sample size you want: 600 ÷ 20 = 30.\n"
                                 "Step 2: Pick a random starting number between 1 and 30, then take every 30th student after that.",
                "fadedPrompt": "600 students ÷ 20 places = every ___th student.",
            },
            "q-oup-ch04-wb-practice": {
                "workedExample": "Step 1: People leaving a gym at 6 am are already regular early-morning exercisers.\n"
                                 "Step 2: Everyone who exercises less or stays at home has no chance of being asked, so the sample is biased upward.",
                "fadedPrompt": "Asking only people at a 6 am gym causes selection ___ because non-exercisers are left out.",
            },
            "q-oup-ch04-wb-challenge": {
                "workedExample": "Step 1: The standard error is σ ÷ √n.\n"
                                 "Step 2: To divide the standard error by 2, √n must be multiplied by 2.\n"
                                 "Step 3: Since 2² = 4, the sample size n must be multiplied by 4.",
                "fadedPrompt": "Because standard error divides by √n, cutting the error in half multiplies n by 2² = ___.",
            },
        },
    }


def cards(k):
    """The concept cards chapter 13 teaches."""
    return {
        "population": {
            "name": "Population",
            "aliases": ["population", "populations"],
            "oneSentence": "The whole group of people or items you want to find out about.",
            "picture": "The whole 10-litre pot of soup on the stove, before you dip a spoon in.",
            "steps": [
                "Read the question to see who or what the study is about.",
                "Count or name the entire group, not only the ones tested.",
                "That complete group is the population.",
            ],
            "workedExample": "A council tests 50 street lamps out of the 4,000 lamps in a town. The population is all 4,000 street lamps.",
            "check": {
                "prompt": "A baker weighs 12 loaves out of the 300 loaves baked that morning. How many loaves are in the population?",
                "answer": "300",
                "answerKey": k.one(k.num("300"), accepts=["300", "300 loaves"], rejects=["12", "288", "312"]),
            },
            "mixUp": {
                "with": "sample",
                "how": "The population is the whole group; the sample is the smaller part you actually measure.",
            },
            "standsOn": [],
        },
        "sample": {
            "name": "Sample",
            "aliases": ["a sample", "the sample", "samples", "sample size", "sample sizes"],
            "oneSentence": "A smaller group chosen from the population so you can measure or ask them instead of testing everyone.",
            "picture": "One well-stirred spoonful lifted from the soup pot.",
            "steps": [
                "Find the whole population.",
                "Look at the smaller group that was actually picked and measured.",
                "Count how many are in that picked group to get the sample size.",
            ],
            "workedExample": "Out of 600 students in a school, 50 are picked to answer a survey. Those 50 students are the sample.",
            "check": {
                "prompt": "A vet checks 25 sheep out of a flock of 500. What is the sample size?",
                "answer": "25",
                "answerKey": k.one(k.num("25"), accepts=["25", "25 sheep"], rejects=["500", "475", "20"]),
            },
            "mixUp": {
                "with": "population",
                "how": "The sample is the small group you test. The population is the whole flock of 500.",
            },
            "standsOn": ["population"],
        },
        "random-sample": {
            "name": "Random sample",
            "aliases": ["random sample", "random samples", "simple random sample"],
            "oneSentence": "A sample chosen so that every member of the population has the same chance of being picked.",
            "picture": "600 numbered slips shaken in a drum, with 30 pulled out blindfolded.",
            "steps": [
                "Give every member of the population a number.",
                "Pick numbers by lot or with a random number generator.",
                "Measure the members whose numbers came up.",
            ],
            "workedExample": "Each of 200 students gets a number from 1 to 200, and 20 numbers are drawn from a hat. That gives a random sample.",
            "check": {
                "prompt": "Out of 100 numbered tickets in a bag, 10 are drawn at random. What is the chance, as a fraction in simplest form, that ticket 17 is drawn?",
                "answer": "1/10",
                "answerKey": k.one(k.num("1/10", simplest=True), accepts=["1/10"], rejects=["10/100", "1/100", "17/100"]),
            },
            "mixUp": {
                "name": "asking whoever is nearby",
                "how": "Picking people who happen to walk past leaves out everyone elsewhere. A random sample gives every member an equal chance.",
            },
            "standsOn": ["sample"],
        },
        "systematic-sample": {
            "name": "Systematic sample",
            "aliases": ["systematic sample", "systematic samples", "systematic sampling"],
            "oneSentence": "A sample taken at even steps along an ordered list, picking every kth member after a random start.",
            "picture": "A register of 600 names with every 30th name circled down the pages.",
            "steps": [
                "Divide the population size N by the sample size n to find the step k = N ÷ n.",
                "Pick a random starting position between 1 and k.",
                "Add k each time to pick the rest of the sample.",
            ],
            "workedExample": "To pick 25 bottles from a line of 500, divide 500 ÷ 25 = 20 and test every 20th bottle from a random start.",
            "check": {
                "prompt": "You want a systematic sample of 15 trees from a row of 300 trees. What step size k do you use?",
                "answer": "20",
                "answerKey": k.one(k.num("20"), accepts=["20", "every 20th tree", "k = 20"], rejects=["15", "285", "4500"]),
            },
            "mixUp": {
                "with": "stratified-sample",
                "how": "A systematic sample steps through one list every k places. A stratified sample splits the population into groups first.",
            },
            "standsOn": ["sample"],
        },
        "stratified-sample": {
            "name": "Stratified sample",
            "aliases": ["stratified sample", "stratified samples", "stratified sampling"],
            "oneSentence": "A sample where the population is split into groups and each group gets the same share of the sample as it holds in the population.",
            "picture": "A bar split into Year 7, Year 8 and Year 9, with sample places shared out in the same proportions.",
            "steps": [
                "Find each group's fraction of the whole population: group size ÷ total population.",
                "Multiply that fraction by the total sample size.",
                "Pick that many members at random inside each group.",
            ],
            "workedExample": "In a school of 500 with 200 in Year 7, a stratified sample of 50 takes (200 ÷ 500) × 50 = 20 from Year 7.",
            "check": {
                "prompt": "A choir has 30 altos and 70 sopranos, 100 singers in all. In a stratified sample of 20 singers, how many altos are chosen?",
                "answer": "6",
                "answerKey": k.one(k.num("6"), accepts=["6", "6 altos"], rejects=["10", "14", "30"]),
            },
            "mixUp": {
                "name": "splitting the sample equally",
                "how": "Two groups do not get half each unless the two groups are the same size in the population.",
            },
            "standsOn": ["sample", "ratio"],
            "footing": "ratio-and-proportion",
        },
        "bias": {
            "name": "Bias",
            "aliases": ["bias", "biased", "biased sample", "biased samples"],
            "oneSentence": "A tilt in how a sample is chosen or asked that makes the result lean away from the truth of the population.",
            "picture": "Asking only people outside a sports stadium whether they like football.",
            "steps": [
                "Ask who in the population had a smaller or zero chance of being chosen.",
                "Ask whether those left-out people would answer differently.",
                "If yes, the sample has bias.",
            ],
            "workedExample": "Phoning landlines at 2 pm on a Tuesday misses people at work and people with only a mobile, so the sample is biased.",
            "check": {
                "prompt": "A library asks 50 people borrowing books inside the library how many books people in the town read a month. "
                          "Will the estimate be too high or too low? Answer 'high' or 'low'.",
                "answer": "high",
                "answerKey": k.one(k.words(["high", "higher", "overestimate"], forbid=["low", "lower"]),
                                   accepts=["high", "too high", "higher"], rejects=["low", "too low", "neither"]),
            },
            "mixUp": {
                "name": "chance wobble in a small fair sample",
                "how": "A small random sample can miss by luck, which shrinks when you take more. Bias is a crooked net that stays crooked however big it is.",
            },
            "standsOn": ["population", "sample"],
        },
        "survivorship-bias": {
            "name": "Survivorship bias",
            "aliases": ["survivorship bias"],
            "oneSentence": "The mistake of judging a whole group by looking only at the survivors and forgetting the ones that failed or dropped out.",
            "picture": "Abraham Wald's returning planes: bullet holes on the wings, and none on the engine because engine hits crashed at sea.",
            "steps": [
                "Look at the group that reached the end and got counted.",
                "Ask who dropped out along the way and never made it into the table.",
                "Count the dropouts before drawing a conclusion.",
            ],
            "workedExample": "Studying only ten-year-old cafés makes the business look easy, because the ones that closed in year one are gone.",
            "check": {
                "prompt": "100 runners start a race, 30 drop out tired, and the 70 who finish average 50 minutes. "
                          "How many runners were left out of that 50-minute average?",
                "answer": "30",
                "answerKey": k.one(k.num("30"), accepts=["30", "30 runners"], rejects=["70", "50", "100"]),
            },
            "mixUp": {
                "with": "bias",
                "how": "Survivorship bias is the kind of bias caused specifically by failures or dropouts disappearing before the count.",
            },
            "standsOn": ["bias"],
        },
        "mean": {
            "name": "Mean",
            "aliases": ["the mean", "a mean", "sample mean", "sample means", "population mean"],
            "oneSentence": "The fair-share average: add all the values together and divide by how many values there are.",
            "picture": "Four stacks of coins of heights 3, 5, 6 and 10 levelled out into four equal stacks of 6.",
            "steps": [
                "Add every value in the list to get the total.",
                "Count how many values there are.",
                "Divide the total by the count.",
            ],
            "workedExample": "For 3, 5, 6 and 10, the total is 3 + 5 + 6 + 10 = 24. There are 4 numbers, so the mean is 24 ÷ 4 = 6.",
            "check": {
                "prompt": "Find the mean of the five numbers 4, 7, 8, 10 and 11.",
                "answer": "8",
                "answerKey": k.one(k.num("8"), accepts=["8", "mean = 8"], rejects=["40", "7", "9"]),
            },
            "mixUp": {
                "name": "forgetting to divide by the count",
                "how": "Adding the numbers gives the total, 40. You must divide by 5 to get the mean, 8.",
            },
            "standsOn": [],
        },
        "standard-error": {
            "name": "Standard error",
            "aliases": ["standard error", "standard errors"],
            "oneSentence": "The typical distance between a random sample's mean and the true population mean, equal to σ ÷ √n.",
            "picture": "The red bracket under the bell curve shrinking to half its width when the sample size n is multiplied by 4.",
            "steps": [
                "Take the square root of the sample size n.",
                "Divide the population spread σ by √n.",
                "To halve the standard error, multiply n by 4.",
            ],
            "workedExample": "When the population spread σ is 15 and the sample size n is 9, the standard error is 15 ÷ √9 = 15 ÷ 3 = 5.",
            "check": {
                "prompt": "A population has spread σ = 18 and you take a random sample of n = 36 items. What is the standard error?",
                "answer": "3",
                "answerKey": k.one(k.num("3"), accepts=["3", "SE = 3"], rejects=["0.5", "6", "18"]),
            },
            "mixUp": {
                "name": "dividing by n instead of √n",
                "how": "Divide σ by the square root of n, not by n itself: for σ = 18 and n = 36, divide by 6, not by 36.",
            },
            "standsOn": ["mean", "square-root"],
        },
    }


def sums():
    """Every sum chapter 13 and its cards state, recomputed."""
    return [
        # Skill card and school unit 4
        ("school total 240 + 180 + 180", 240 + 180 + 180, 600),
        ("stratified 50 from 600", (stratified_share(240, 600, 50), stratified_share(180, 600, 50), 20 + 15 + 15), (20, 15, 50)),
        ("systematic 20 from 600", 600 // 20, 30),
        # 13.1
        ("turn 13.1", 2000 - 40, 1960),
        # 13.2
        ("400 and 200 out of 600 for 30", (400 + 200, stratified_share(400, 600, 30), stratified_share(200, 600, 30), 30 // 6),
         (600, 20, 10, 5)),
        ("systematic start 7 step 30", (7 + 30, 7 + 60), (37, 67)),
        ("turn 13.2", (120 + 80, stratified_share(120, 200, 40), stratified_share(80, 200, 40)), (200, 24, 16)),
        # 13.3
        ("turn 13.3", 50 - 8, 42),
        # 13.4 and widget
        ("standard error sigma=12 at n=4, 16, 64",
         (standard_error(12, 4), standard_error(12, 16), standard_error(12, 64)), (6, 3, 1.5)),
        ("turn 13.4", (standard_error(20, 25), 20 / 25, math.isqrt(25)), (4, 0.8, 5)),
        # Debate
        ("debate 300 and 100 for 40",
         (300 + 100, stratified_share(300, 400, 40), stratified_share(100, 400, 40), 400 // 40),
         (400, 30, 10, 10)),
        # Cards
        ("population check", (300 - 12, 300 + 12), (288, 312)),
        ("sample check", 500 - 25, 475),
        ("random-sample check", Fraction(10, 100), Fraction(1, 10)),
        ("systematic-sample card and check", (500 // 25, 300 // 15, 300 - 15, 300 * 15), (20, 20, 285, 4500)),
        ("stratified-sample card and check",
         (stratified_share(200, 500, 50), 30 + 70, stratified_share(30, 100, 20), stratified_share(70, 100, 20)),
         (20, 100, 6, 14)),
        ("survivorship-bias check", 100 - 30, 70),
        ("mean card", (3 + 5 + 6 + 10, (3 + 5 + 6 + 10) // 4), (24, 6)),
        ("mean check", (4 + 7 + 8 + 10 + 11, (4 + 7 + 8 + 10 + 11) // 5), (40, 8)),
        ("standard-error card and check",
         (standard_error(15, 9), standard_error(18, 36), 18 / 36, math.isqrt(36)), (5, 3, 0.5, 6)),
        ("school q-oup-ch04-wb-challenge", 2 ** 2, 4),
    ]


def answers():
    """Chapter 13's turn answers and its cards' check answers, computed."""
    return {
        "ch13-s1-turn": 2000,
        "ch13-s2-turn": stratified_share(120, 120 + 80, 40),
        "ch13-s3-turn": 8 - 8,
        "ch13-s4-turn": standard_error(20, 25),
        "population-check": 300,
        "sample-check": 25,
        "random-sample-check": Fraction(10, 100),
        "systematic-sample-check": 300 // 15,
        "stratified-sample-check": stratified_share(30, 30 + 70, 20),
        "bias-check": "high",
        "survivorship-bias-check": 100 - 70,
        "mean-check": (4 + 7 + 8 + 10 + 11) // 5,
        "standard-error-check": standard_error(18, 36),
    }
