"""
Chapter 15, written by hand to docs/CONTENT_BRIEF.md. It maps to OUP Unit 15 (Probability).

Each section teaches one idea in nine steps, in this order: question, idea, picture, reason, name,
example, mistake, turn, sayBack. A section's `teaches` lists the concept cards whose names first
appear in its `name` step. `build(k)` returns the chapter and `cards(k)` its concept cards; both take the
exporter's answer-key helpers.
"""

import math

from book.arithmetic import Fraction


def perms(n, r):
    return math.perm(n, r)


def combs(n, k):
    return math.comb(n, k)


def build(k):
    return {
        "number": 15,
        "title": "Counting outcomes",
        "subtitle": "School book chapter 15 · Fair grids for two dice, multiplying along branches, "
                    "counting orders with n!, and why pegs build a bell curve",
        "hookSummary": "Roll two fair dice and add the spots. Why does a total of 7 show up six times as often as a total of 12?",
        "beyondSchoolBook": False,
        "skillCard": {
            "skill": "Listing equally likely outcomes in a grid or tree, working out probabilities with and without replacement, and counting arrangements and choices",
            "sheCan": {
                "prompt": "With no calculator: two fair six-sided dice are rolled. What is the chance their sum is 9, in simplest form? "
                          "A bag holds 5 red and 3 blue marbles, and two are drawn without putting the first back. What is the chance both are red? "
                          "And how many 3-person teams can be chosen from 8 students?",
                "answer": "On the 6 × 6 grid, four pairs add to 9: (3,6), (4,5), (5,4), (6,3), so the chance is 4/36 = 1/9. "
                          "For two red marbles without replacement: 5/8 × 4/7 = 20/56 = 5/14. "
                          "For 3 students chosen from 8: (8 × 7 × 6) ÷ (3 × 2 × 1) = 56 teams.",
            },
            "whyItMatters": "Games, weather forecasts, genetics and quality checks all rest on counting how many ways something can happen out of all equally likely ways.",
            "standsOn": [
                "Chapter 0: sets, intersections and complements",
                "Chapter 2: multiplying and simplifying fractions",
                "Chapter 13: fair random choices from a group",
            ],
            "unlocks": [
                "Chapter 16: updating a probability when new evidence narrows the outcomes",
                "Genetics: Punnett grids for inherited traits",
                "Statistics: binomial probabilities and the normal curve",
            ],
        },
        "intuitionToFormula": {
            "concreteAction": "In the figure, set the rows of pegs to 6, the slot to 3, and the bounce chance to 50%.",
            "ahaInvariant": "To land in slot 3 after 6 rows, a ball must bounce right 3 times and left 3 times. "
                            "There are 20 different paths to that middle slot, and only 1 path to each end.",
            "formulaDisplay": "P(A) = ways ÷ total,   ⁿPᵣ = n! ÷ (n − r)!,   ⁿCᵣ = n! ÷ (r!(n − r)!)",
            "termMappings": [
                {"symbol": "n! ÷ (n − r)!", "visualPart": "Choices for 1st place × 2nd place × …", "colorRole": "red",
                 "meaning": "Ordered arrangements when the order of picking matters"},
                {"symbol": "÷ r!", "visualPart": "Collapsing rearrangements of the same r items", "colorRole": "blue",
                 "meaning": "Dividing out the r! orders to count unordered teams"},
                {"symbol": "ⁿCₖ paths", "visualPart": "The height of bar k on the pegboard", "colorRole": "amber",
                 "meaning": "How many left-right paths land in slot k"},
            ],
            "atlasFigureRef": "statistics/galton/index.html",
        },
        "sections": [
            {
                "heading": "15.1 Why 7 beats 12 six to one",
                "teaches": ["outcome", "sample-space", "probability", "mutually-exclusive"],
                "steps": [
                    {"kind": "question",
                     "text": "You roll a red die and a blue die and add them. "
                             "There are 11 possible totals, from 2 to 12. Does each total have a 1 in 11 chance?"},
                    {"kind": "idea",
                     "text": "No. A total of 12 happens in only one way, 6 on red and 6 on blue. "
                             "A total of 7 happens in six ways: (1,6), (2,5), (3,4), (4,3), (5,2) and (6,1)."},
                    {"kind": "picture",
                     "text": "Draw a 6 × 6 grid with red 1 to 6 along the side and blue 1 to 6 along the top. "
                             "Count the 36 squares, and shade the diagonal of four squares that add to 9: (3,6), (4,5), (5,4), (6,3)."},
                    {"kind": "reason",
                     "text": "Why count the 36 pairs instead of the 11 totals? Each of the 36 pairs is equally likely, 1 in 36. "
                             "The 11 totals are not equally likely because different numbers of pairs make them."},
                    {"kind": "name",
                     "text": "One possible result of a trial is an outcome, and the complete list or grid of all possible results is the sample space. "
                             "When outcomes are equally likely, the probability of a result is wanted outcomes ÷ total outcomes, on a scale from 0 to 1. "
                             "Results that cannot happen at the same time are mutually exclusive; their probabilities add up, and P(not A) = 1 − P(A)."},
                    {"kind": "example",
                     "text": "On the 36-square grid for two fair dice, four squares add to 9. "
                             "So the probability of a sum of 9 is 4 ÷ 36 = 1/9, and the probability of not getting 9 is 1 − 1/9 = 8/9."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to treat (3, 6) and (6, 3) as one outcome. "
                             "Red 3 with blue 6 and red 6 with blue 3 are two separate squares on the 36-square grid."},
                    {"kind": "turn",
                     "text": "Two fair six-sided dice are rolled. What is the probability that their sum is 11, as a fraction in simplest form?",
                     "answer": "1/18",
                     "answerKey": k.one(k.num("1/18", simplest=True), accepts=["1/18"], rejects=["2/36", "1/36", "1/11"])},
                    {"kind": "sayBack",
                     "text": "List the sample space of equally likely outcomes first; probability is wanted outcomes ÷ total outcomes, and P(not A) = 1 − P(A)."},
                ],
            },
            {
                "heading": "15.2 Testing a coin and multiplying along a tree",
                "teaches": ["experimental-probability", "independent-events", "tree-diagram"],
                "steps": [
                    {"kind": "question",
                     "text": "A bag holds 5 red and 3 blue marbles, 8 in all. "
                             "You pick one marble, keep it out, and pick a second. Why does the fraction for the second marble change?"},
                    {"kind": "idea",
                     "text": "Because only 7 marbles are left in the bag. "
                             "If the first marble was red, only 4 of the remaining 7 are red, so the chance of two reds is 5/8 × 4/7 = 20/56 = 5/14."},
                    {"kind": "picture",
                     "text": "Draw two branches from the start labeled Red (5/8) and Blue (3/8). "
                             "From the Red tip, split into Red (4/7) and Blue (3/7), and multiply along the top path: 5/8 × 4/7."},
                    {"kind": "reason",
                     "text": "Why multiply along the branches? Five eighths of the time you take the top branch, and four sevenths of those times you take the next top branch. "
                             "Four sevenths of five eighths is 5/8 × 4/7."},
                    {"kind": "name",
                     "text": "A probability estimated from real trials, count of successes ÷ number of trials, is an experimental probability. "
                             "Two stages where the first result does not change the chances of the second are independent events, so P(A and B) = P(A) × P(B). "
                             "A branching picture that writes each step's fractions on its branches is a tree diagram."},
                    {"kind": "example",
                     "text": "If you put the first marble back before picking the second, the two picks are independent events: P(both red) = 5/8 × 5/8 = 25/64. "
                             "Without replacement they are not: P(both red) = 5/8 × 4/7 = 5/14."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to add along a path, writing 5/8 + 4/7. "
                             "Multiply along the branches to follow one path; add at the end only when combining two separate paths."},
                    {"kind": "turn",
                     "text": "A bag holds 4 green and 2 yellow counters, 6 in all. Two counters are drawn without replacement. "
                             "What is the probability that both are green, in simplest form?",
                     "answer": "2/5",
                     "answerKey": k.one(k.num("2/5", simplest=True), accepts=["2/5", "0.4"], rejects=["12/30", "4/9", "16/36"])},
                    {"kind": "sayBack",
                     "text": "On a tree diagram, multiply along branches for one path and add separate paths. "
                             "Only independent events keep the same fractions on the second step."},
                ],
            },
            {
                "heading": "15.3 When order matters and when it does not",
                "teaches": ["factorial", "permutation", "combination"],
                "steps": [
                    {"kind": "question",
                     "text": "From 8 students, how many ways can you award Gold, Silver and Bronze medals? "
                             "How does that count change for an equal 3-person team?"},
                    {"kind": "idea",
                     "text": "For medals, there are 8 choices for Gold, 7 for Silver and 6 for Bronze: 8 × 7 × 6 = 336 ways. "
                             "For a team, the same 3 students can be arranged in 3 × 2 × 1 = 6 medal orders, so divide 336 by 6 to get 56 teams."},
                    {"kind": "picture",
                     "text": "Draw three medal boxes [8][7][6]. "
                             "Underneath, group the 6 rearrangements of Asha, Rohan and Meera into one single team box."},
                    {"kind": "reason",
                     "text": "Why divide by 6? In a team there is no Gold, Silver or Bronze. "
                             "Every group of 3 people was counted 3 × 2 × 1 = 6 times in the ordered list, so dividing by 6 counts each team once."},
                    {"kind": "name",
                     "text": "This section goes beyond the school book. The product of all whole numbers from n down to 1 is n factorial, written n!. "
                             "An ordered arrangement of r items from n is a permutation, ⁿPᵣ = n! ÷ (n − r)!. "
                             "An unordered selection of r items from n is a combination, ⁿCᵣ = n! ÷ (r!(n − r)!)."},
                    {"kind": "example",
                     "text": "4! = 4 × 3 × 2 × 1 = 24. "
                             "To choose 2 captains of equal rank from 6 players, calculate ⁶C₂ = (6 × 5) ÷ (2 × 1) = 15 pairs."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to use ⁿPᵣ when order does not matter. "
                             "Ask whether swapping two picked people changes the result: if not, divide by r! to get a combination."},
                    {"kind": "turn",
                     "text": "How many different 2-topping pizzas can you choose from 7 toppings, where the order of the two toppings does not matter?",
                     "answer": "21",
                     "answerKey": k.one(k.num("21"), accepts=["21", "21 pizzas"], rejects=["42", "14", "9"])},
                    {"kind": "sayBack",
                     "text": "n! multiplies from n down to 1; a permutation counts ordered picks, and a combination divides by r! when order does not matter."},
                ],
            },
            {
                "heading": "15.4 Dropping balls through a pegboard",
                "figure": True,
                "teaches": ["bell-curve"],
                "steps": [
                    {"kind": "question",
                     "text": "A ball drops through 6 rows of pegs, bouncing left or right with a 50% chance at each peg. "
                             "Why do most balls pile up in the middle slots instead of spreading evenly across the bottom?"},
                    {"kind": "idea",
                     "text": "Because there is only 1 path that goes right all 6 times, "
                             "but there are ⁶C₃ = 20 different paths that go right 3 times and left 3 times."},
                    {"kind": "picture",
                     "text": "In the figure, set the pegboard rows to 6, the slot to 3, and the bounce chance to 50%. "
                             "Read the path counts above the bars: 1, 6, 15, 20, 15, 6, 1, adding up to 64 paths in all."},
                    {"kind": "reason",
                     "text": "Why is the count in slot k equal to ⁿCₖ? Choosing a path to slot k means choosing which k of the n rows bounce right. "
                             "That is a combination of k rows out of n."},
                    {"kind": "name",
                     "text": "As the number of rows grows, the tall middle bars and low outer tails smooth into the symmetric shape called a bell curve."},
                    {"kind": "example",
                     "text": "With 6 rows at 50%, there are 2⁶ = 64 equally likely paths. "
                             "Slot 3 has ⁶C₃ = 20 paths, so the probability of landing in slot 3 is 20 ÷ 64 = 5/16 = 31.25%."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to think a ball 'aims' for the middle. "
                             "Every single path has the same 1 in 64 chance; the middle wins only because 20 paths lead there."},
                    {"kind": "turn",
                     "text": "A ball drops through 4 rows of pegs (n = 4). How many paths ⁴C₂ land in the middle slot (k = 2)?",
                     "answer": "6",
                     "answerKey": k.one(k.num("6"), accepts=["6", "6 paths"], rejects=["4", "8", "16"])},
                    {"kind": "sayBack",
                     "text": "Slot k after n rows of pegs collects ⁿCₖ paths, piling most balls in the middle to form a bell curve."},
                ],
            },
        ],
        "callouts": [
            {"kind": "predict", "title": "Predict first",
             "body": "In the figure with 6 rows of pegs, predict how many paths land in slot 0 and how many land in slot 1."},
            {"kind": "check", "title": "Explain it",
             "body": "Explain to a friend why a sum of 7 on two dice is six times as likely as a sum of 2."},
            {"kind": "careful", "title": "With or without replacement?",
             "body": "Before multiplying along a tree diagram, check whether the first item was put back. If not, decrease both the total and the matching count by 1."},
        ],
        "debate": {
            "id": "debate-ch15-counting",
            "oupUnitNumber": 15,
            "title": "One head and one tail: two outcomes or three?",
            "contextPrompt": "Two fair coins, a ₹1 coin and a ₹2 coin, are tossed together. Asha and Rohan argue about the probability of getting one Head and one Tail.",
            "speakerAName": "Asha",
            "speakerAClaim": "There are three possible results: two Heads, two Tails, or one of each. So one Head and one Tail has probability 1/3.",
            "speakerBName": "Rohan",
            "speakerBClaim": "The 2 × 2 sample space has four equally likely outcomes: HH, HT, TH and TT. Both HT and TH give one of each, so the probability is 2/4 = 1/2.",
            "choices": [
                {"id": "ch15-a", "speakerLabel": "Asha is right (1/3)",
                 "reasoningStatement": "HT and TH are the same result, so there are only 3 outcomes.",
                 "isCorrect": False,
                 "socraticRebuttal": "Head on the ₹1 coin with Tail on the ₹2 coin is a different physical outcome from Tail on ₹1 with Head on ₹2."},
                {"id": "ch15-b", "speakerLabel": "Rohan is right (2/4 = 1/2)",
                 "reasoningStatement": "Of the 4 equally likely pairs in the sample space, 2 pairs (HT and TH) have one Head and one Tail.",
                 "isCorrect": True,
                 "socraticRebuttal": "Yes. Listing all 4 equally likely pairs in the sample space shows that HT and TH together take up 2 out of 4 squares."},
                {"id": "ch15-c", "speakerLabel": "Neither. It is 1/2 × 1/2 = 1/4.",
                 "reasoningStatement": "Multiply 1/2 for Head by 1/2 for Tail.",
                 "isCorrect": False,
                 "socraticRebuttal": "1/4 is the probability of HT alone. Adding TH (another 1/4) gives 1/4 + 1/4 = 1/2."},
            ],
            "invariantTakeaway": "Count equally likely pairs in the full sample space: HT and TH are two separate ways to get one Head and one Tail.",
        },
        "keyTerms": ["Outcome", "Sample space", "Probability", "Mutually exclusive", "Experimental probability",
                     "Independent events", "Tree diagram", "Factorial", "Permutation", "Combination", "Bell curve"],
        "widgets": ["w_atlas_galton_board", "w_combinatorics_tree_builder"],
        "widgetText": {
            "w_atlas_galton_board": {
                "title": "The pegboard and Pascal's path counts",
                "challengePrompt": "Set the rows to 6 and step the slot k from 0 across to 6. "
                                   "Predict which slot has the tallest bar when the bounce chance is 50%.",
                "cutaway": "At each peg a ball goes left or right. "
                           "Slot k collects all paths with k right bounces, and there are ⁿCₖ such paths.",
                "idealised": "The rule: slot k has ⁿCₖ = n! ÷ (k!(n − k)!) paths",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Set rows n to 6, slot k to 3, and bounce chance p to 50%."},
                    {"title": "2. Notice", "caption": "The red middle bar at k = 3 has 20 paths, the tallest on the board."},
                    {"title": "3. Match the rule", "caption": "⁶C₃ = (6 × 5 × 4) ÷ (3 × 2 × 1) = 20 paths out of 2⁶ = 64."},
                    {"title": "4. Push it further", "caption": "Slide p to 70% and watch the peak shift toward the right-hand slots."},
                    {"title": "5. Draw it", "caption": "Write out row 4 of path counts (1, 4, 6, 4, 1) and check they add to 16."},
                ],
            },
            "w_combinatorics_tree_builder": {
                "title": "Tree branches and counting choices",
                "challengePrompt": "Follow a two-step tree with and without replacement. "
                                   "Predict whether the second-step denominator stays the same or drops by 1.",
                "cutaway": "Along a single path you multiply the fractions on each branch. "
                           "When order does not matter in a group pick, divide the ordered count by r!.",
                "idealised": "The rule: multiply along branches; divide by r! when order does not matter",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Trace the top path for two red marbles drawn from 5 red and 3 blue without replacement."},
                    {"title": "2. Notice", "caption": "The first branch is 5/8 and the second is 4/7."},
                    {"title": "3. Match the rule", "caption": "Multiply along the path: 5/8 × 4/7 = 20/56 = 5/14."},
                    {"title": "4. Push it further", "caption": "Compare with replacement, where the second branch stays 5/8."},
                    {"title": "5. Draw it", "caption": "Draw the four branches for two picks from 5 red and 3 blue and check the four products add to 1."},
                ],
            },
        },
        "atlasLessons": [
            {
                "title": "Chapter 15 · Why sample-space grids keep outcomes fair",
                "question": "Why does a 6 × 6 grid give the right dice probabilities when listing totals 2 to 12 does not?",
                "explanation": "Each of the 36 squares pairs one face of the first die with one face of the second die, so all 36 squares are equally likely.",
                "limits": "The rule: P(A) = wanted squares ÷ total equally likely squares",
            },
            {
                "title": "Chapter 15 · Multiplying along tree branches",
                "question": "When do the branch fractions stay the same on the second step of a tree?",
                "explanation": "They stay the same when the two steps are independent events, such as tossing a coin twice or drawing with replacement.",
                "limits": "The rule: P(A and B) = P(A) × P(B) for independent events",
            },
            {
                "title": "Chapter 15 · Dividing out the order",
                "question": "Why does ⁿCᵣ divide the ordered count ⁿPᵣ by r!?",
                "explanation": "Every team of r people can be lined up in r! different orders. "
                               "Dividing by r! collapses those r! orders into one single team.",
                "limits": "The rule: ⁿCᵣ = ⁿPᵣ ÷ r! = n! ÷ (r!(n − r)!)",
            },
        ],
        "visualMathTips": {},
        "schoolTopics": {
            "15.1": "Probability measures how likely an outcome is on a scale from 0 (impossible) to 1 (certain). "
                    "When outcomes cannot happen together they are mutually exclusive, their probabilities add up, and P(not A) = 1 − P(A).",
            "15.2": "Experimental probability is successes ÷ trials. "
                    "As you run more trials, the experimental probability settles closer to the theoretical probability.",
            "15.3": "When all outcomes in the sample space are equally likely, P(A) = wanted outcomes ÷ total outcomes. "
                    "Factorials, permutations and combinations count large sample spaces without listing every item.",
            "15.4": "Two-way sample-space grids and tree diagrams organise combined events. "
                    "Multiply along branches to find the probability of a path, and add separate paths at the end.",
        },
        "schoolQuestions": {
            "q-oup-ch15-wb-focus": {
                "workedExample": "Step 1: Two six-sided dice have 6 × 6 = 36 equally likely pairs in the sample space.\n"
                                 "Step 2: List the pairs that add to 9: (3, 6), (4, 5), (5, 4) and (6, 3), which is 4 pairs.\n"
                                 "Step 3: Divide 4 by 36 and simplify: 4/36 = 1/9.",
                "fadedPrompt": "4 pairs out of 36 add to 9, so the probability is 4/36 = ___.",
            },
            "q-oup-ch15-wb-practice": {
                "workedExample": "Step 1: On the first draw there are 5 red marbles out of 8, so P(1st red) = 5/8.\n"
                                 "Step 2: Without replacement, 4 red marbles remain out of 7, so P(2nd red) = 4/7.\n"
                                 "Step 3: Multiply along the branch: 5/8 × 4/7 = 20/56 = 5/14.",
                "fadedPrompt": "5/8 × 4/7 = 20/56 = ___ in simplest form.",
            },
            "q-oup-ch15-wb-challenge": {
                "workedExample": "Step 1: There are 8 × 7 × 6 = 336 ordered ways to pick 3 students from 8.\n"
                                 "Step 2: A committee has no order, and 3 students can be ordered in 3! = 3 × 2 × 1 = 6 ways.\n"
                                 "Step 3: Divide 336 by 6: ⁸C₃ = 336 ÷ 6 = 56 committees.",
                "fadedPrompt": "⁸C₃ = (8 × 7 × 6) ÷ (3 × 2 × 1) = 336 ÷ 6 = ___ committees.",
            },
        },
    }


def cards(k):
    """The concept cards chapter 15 teaches."""
    return {
        "outcome": {
            "name": "Outcome",
            "aliases": ["outcome", "outcomes"],
            "oneSentence": "One single possible result of a trial, such as rolling a 4 on a die or landing Heads on a coin.",
            "picture": "The six upturned faces 1, 2, 3, 4, 5, 6 that a single die can show when it stops rolling.",
            "steps": [
                "Look at the action being carried out (rolling, spinning, picking).",
                "List each distinct result that can happen on a single try.",
                "Check whether each outcome has the same chance.",
            ],
            "workedExample": "When you spin a fair 5-sided spinner numbered 1 to 5, there are 5 equally likely outcomes.",
            "check": {
                "prompt": "A letter is picked at random from the word MATHS. How many equally likely outcomes are there?",
                "answer": "5",
                "answerKey": k.one(k.num("5"), accepts=["5", "5 outcomes"], rejects=["1", "4", "26"]),
            },
            "mixUp": {
                "with": "sample-space",
                "how": "An outcome is one single result; the sample space is the set of all possible outcomes together.",
            },
            "standsOn": [],
            "footing": "equally-likely-outcomes",
        },
        "sample-space": {
            "name": "Sample space",
            "aliases": ["the sample space", "a sample space", "sample space", "sample spaces"],
            "oneSentence": "The complete set or grid of all possible outcomes of a trial.",
            "picture": "A 6 × 6 grid showing all 36 pairs (red, blue) when two dice are rolled.",
            "steps": [
                "List every outcome for the first item down the side and the second item along the top.",
                "Fill in every square of the grid so no pair is missed.",
                "Count the total number of squares for the denominator.",
            ],
            "workedExample": "Tossing a coin (H, T) and rolling a 4-sided die (1, 2, 3, 4) has a sample space of 2 × 4 = 8 pairs.",
            "check": {
                "prompt": "You spin a 3-colour spinner and roll a 6-sided die. How many outcomes are in the sample space?",
                "answer": "18",
                "answerKey": k.one(k.num("18"), accepts=["18", "18 outcomes"], rejects=["9", "3", "6"]),
            },
            "mixUp": {
                "name": "adding the sizes instead of multiplying",
                "how": "Each of the 3 colours can pair with each of the 6 numbers, giving 3 × 6 = 18 pairs, not 3 + 6 = 9.",
            },
            "standsOn": ["outcome", "set"],
        },
        "probability": {
            "name": "Probability",
            "aliases": ["probability", "probabilities"],
            "oneSentence": "A number from 0 to 1 that measures how likely an outcome is: wanted outcomes divided by total equally likely outcomes.",
            "picture": "A bar from 0 (impossible) through 1/2 (even chance) to 1 (certain).",
            "steps": [
                "Count the total number of equally likely outcomes in the sample space.",
                "Count how many of those outcomes match what you want.",
                "Write wanted ÷ total as a fraction, decimal or percentage.",
            ],
            "workedExample": "A bag has 3 red and 7 blue counters, 10 in all. The probability of picking red is 3/10 = 0.3.",
            "check": {
                "prompt": "A fair 8-sided spinner is numbered 1 to 8. What is the probability of landing on a multiple of 3, as a fraction in simplest form?",
                "answer": "1/4",
                "answerKey": k.one(k.num("1/4", simplest=True), accepts=["1/4", "0.25"], rejects=["2/8", "3/8", "1/3"]),
            },
            "mixUp": {
                "name": "writing wanted ÷ unwanted",
                "how": "The bottom of a probability fraction is always the total number of outcomes (8), not the unwanted ones (6).",
            },
            "standsOn": ["outcome", "fraction"],
            "footing": "the-right-total",
        },
        "mutually-exclusive": {
            "name": "Mutually exclusive",
            "aliases": ["mutually exclusive"],
            "oneSentence": "Two results that cannot happen at the same time on a single trial, so their probabilities add up and all possible results add to 1.",
            "picture": "Two non-overlapping circles inside a box: landing in one means you cannot be in the other.",
            "steps": [
                "Check that the two results have no outcome in common.",
                "Add their probabilities to find P(A or B) = P(A) + P(B).",
                "Subtract from 1 to find the probability that something does not happen: P(not A) = 1 − P(A).",
            ],
            "workedExample": "On a spinner, P(red) = 0.3 and P(blue) = 0.5. They cannot happen on the same spin, so P(red or blue) = 0.3 + 0.5 = 0.8.",
            "check": {
                "prompt": "The probability that it rains tomorrow is 0.35. What is the probability that it does not rain?",
                "answer": "0.65",
                "answerKey": k.one(k.num("0.65"), accepts=["0.65", "13/20"], rejects=["0.35", "0.75", "1.35"]),
            },
            "mixUp": {
                "with": "independent-events",
                "how": "Mutually exclusive results cannot happen together (add probabilities). Independent events come from separate steps that do not affect each other (multiply probabilities).",
            },
            "standsOn": ["probability", "intersection"],
        },
        "experimental-probability": {
            "name": "Experimental probability",
            "aliases": ["experimental probability", "experimental probabilities", "relative frequency", "relative frequencies"],
            "oneSentence": "A probability estimated from real trials: the number of times a result happened divided by the total number of trials.",
            "picture": "A tally chart of 100 drawing-pin drops showing 62 point-up landings: 62/100 = 0.62.",
            "steps": [
                "Count how many times the result happened in the experiment.",
                "Divide by the total number of trials carried out.",
                "Use more trials to get a steadier estimate.",
            ],
            "workedExample": "A biased die is rolled 50 times and shows a six 15 times. The experimental probability of a six is 15 ÷ 50 = 3/10 = 0.3.",
            "check": {
                "prompt": "A spinner is spun 40 times and lands on green 10 times. What is the experimental probability of green, in simplest form?",
                "answer": "1/4",
                "answerKey": k.one(k.num("1/4", simplest=True), accepts=["1/4", "0.25"], rejects=["10/40", "1/3", "4"]),
            },
            "mixUp": {
                "with": "probability",
                "how": "Theoretical probability counts symmetrical outcomes ahead of time; experimental probability divides observed hits by trials.",
            },
            "standsOn": ["probability", "sample"],
        },
        "independent-events": {
            "name": "Independent events",
            "aliases": ["independent events", "independent event"],
            "oneSentence": "Two stages where the result of the first does not change the probabilities of the second, so P(A and B) = P(A) × P(B).",
            "picture": "Tossing a coin twice: the coin has no memory of the first toss.",
            "steps": [
                "Check that the first outcome does not change the items or chances for the second.",
                "Find P(A) for the first stage and P(B) for the second stage.",
                "Multiply P(A) × P(B).",
            ],
            "workedExample": "Rolling a 6 on a fair die (1/6) and tossing Heads on a fair coin (1/2) are independent events, so P(both) = 1/6 × 1/2 = 1/12.",
            "check": {
                "prompt": "A fair coin is tossed twice. What is the probability of getting two Heads, as a fraction in simplest form?",
                "answer": "1/4",
                "answerKey": k.one(k.num("1/4", simplest=True), accepts=["1/4", "0.25"], rejects=["1/2", "2/4", "1"]),
            },
            "mixUp": {
                "name": "drawing without replacement",
                "how": "When you keep a marble out of the bag, the total drops by 1, so the two draws are not independent events.",
            },
            "standsOn": ["probability"],
        },
        "tree-diagram": {
            "name": "Tree diagram",
            "aliases": ["tree diagram", "tree diagrams", "probability tree", "probability trees"],
            "oneSentence": "A branching diagram where you multiply along branches for one path and add separate paths at the end.",
            "picture": "Branches splitting left to right for Pick 1 and Pick 2, with each branch carrying its fraction.",
            "steps": [
                "Draw one set of branches for the first stage and check their fractions add to 1.",
                "From each tip, draw branches for the second stage (updating fractions if there is no replacement).",
                "Multiply along the branches of each wanted path, then add the wanted paths together.",
            ],
            "workedExample": "On a tree where P(Rain today) = 0.2 and P(Rain tomorrow) = 0.3 independently, the path Rain–Rain has probability 0.2 × 0.3 = 0.06.",
            "check": {
                "prompt": "Along one path of a tree diagram, the first branch has probability 0.5 and the second branch has probability 0.4. "
                          "What is the probability of following that path?",
                "answer": "0.2",
                "answerKey": k.one(k.num("0.2"), accepts=["0.2", "1/5"], rejects=["0.9", "0.1", "2"]),
            },
            "mixUp": {
                "name": "adding along the branches",
                "how": "Adding 0.5 + 0.4 = 0.9 is wrong; multiply 0.5 × 0.4 = 0.2 to require both steps of the path to happen.",
            },
            "standsOn": ["probability"],
        },
        "factorial": {
            "name": "Factorial",
            "symbol": "n!",
            "aliases": ["factorial", "factorials", "n!"],
            "oneSentence": "The product of all whole numbers from n down to 1, written n!, counting how many ways n items can be ordered.",
            "picture": "Three chairs in a row: 3 choices for the first chair, 2 for the second, 1 for the last: 3! = 6.",
            "steps": [
                "Start with the whole number n.",
                "Multiply by n − 1, then n − 2, all the way down to 1.",
                "Remember that 0! is defined as 1.",
            ],
            "workedExample": "5! = 5 × 4 × 3 × 2 × 1 = 120 ways to line up 5 books on a shelf.",
            "check": {
                "prompt": "What is the value of 4! (4 factorial)?",
                "answer": "24",
                "answerKey": k.one(k.num("24"), accepts=["24"], rejects=["4", "10", "12"]),
            },
            "mixUp": {
                "name": "adding from n down to 1",
                "how": "4! multiplies 4 × 3 × 2 × 1 = 24; adding 4 + 3 + 2 + 1 = 10 is the triangular number.",
            },
            "standsOn": [],
        },
        "permutation": {
            "name": "Permutation",
            "aliases": ["permutation", "permutations", "ⁿPᵣ", "nPr"],
            "oneSentence": "An ordered arrangement of r items chosen from n items, where the order of picking matters: ⁿPᵣ = n! ÷ (n − r)!.",
            "picture": "Picking 1st, 2nd and 3rd prize winners from 8 runners: 8 × 7 × 6 = 336.",
            "steps": [
                "Write down n choices for the first place.",
                "Multiply by n − 1 for the second, down to r factors in all.",
                "Use ⁿPᵣ whenever swapping two chosen items makes a different result.",
            ],
            "workedExample": "From 5 digits, the number of 2-digit codes with no repeated digit is ⁵P₂ = 5 × 4 = 20.",
            "check": {
                "prompt": "In a race with 6 runners, how many ways can Gold and Silver (1st and 2nd place) be awarded?",
                "answer": "30",
                "answerKey": k.one(k.num("30"), accepts=["30", "30 ways"], rejects=["15", "12", "36"]),
            },
            "mixUp": {
                "with": "combination",
                "how": "A permutation cares about order (Gold then Silver is different from Silver then Gold); a combination does not.",
            },
            "standsOn": ["factorial"],
        },
        "combination": {
            "name": "Combination",
            "aliases": ["combination", "combinations", "ⁿCᵣ", "nCr"],
            "oneSentence": "A selection of r items from n where order does not matter: ⁿCᵣ = n! ÷ (r!(n − r)!).",
            "picture": "Choosing 3 friends from 8 to share a cab: swapping their seats inside the cab is still the same group of 3.",
            "steps": [
                "Multiply the top r factors starting from n down: n × (n − 1) × …",
                "Divide by r! = r × (r − 1) × … × 1 to remove the duplicate orders.",
                "Check that ⁿCᵣ is always smaller than or equal to ⁿPᵣ.",
            ],
            "workedExample": "Choosing 2 books from 5 to pack for a trip gives ⁵C₂ = (5 × 4) ÷ (2 × 1) = 10 pairs.",
            "check": {
                "prompt": "How many pairs of 2 players can be chosen from a squad of 6 (⁶C₂)?",
                "answer": "15",
                "answerKey": k.one(k.num("15"), accepts=["15", "15 pairs"], rejects=["30", "12", "8"]),
            },
            "mixUp": {
                "with": "permutation",
                "how": "Forgetting to divide by 2! = 2 gives 30 ordered pairs instead of 15 unordered pairs.",
            },
            "standsOn": ["permutation", "factorial"],
        },
        "bell-curve": {
            "name": "Bell curve",
            "aliases": ["bell curve", "bell curves", "normal curve"],
            "oneSentence": "The symmetric, bell-shaped distribution with a tall middle peak and low outer tails that appears when many small random steps add up.",
            "picture": "Hundred of balls dropped through a pegboard piling high in the middle slots and tapering off at both edges.",
            "steps": [
                "Find the middle slot where left and right bounces balance.",
                "Notice that the combination counts ⁿCₖ are largest in the middle and symmetric on both sides.",
                "As the number of rows grows, the stepped bars approach a smooth bell curve.",
            ],
            "workedExample": "For 6 rows of pegs, the path counts 1, 6, 15, 20, 15, 6, 1 rise to 20 in the middle and match left to right.",
            "check": {
                "prompt": "In row 4 of the pegboard, the path counts are 1, 4, 6, 4, 1. What is the total number of paths across all 5 slots?",
                "answer": "16",
                "answerKey": k.one(k.num("16"), accepts=["16", "16 paths"], rejects=["6", "15", "8"]),
            },
            "mixUp": {
                "name": "a flat uniform spread",
                "how": "One die has a flat spread (1/6 each), but adding several dice or rows of pegs piles outcomes in the middle into a bell curve.",
            },
            "standsOn": ["combination", "probability"],
        },
    }


def sums():
    """Every sum chapter 15 and its cards state, recomputed."""
    return [
        # Skill card and school unit 15
        ("dice sum 9", (6 * 6, Fraction(4, 36)), (36, Fraction(1, 9))),
        ("two red marbles without replacement", (5 + 3, Fraction(5, 8) * Fraction(4, 7)), (8, Fraction(5, 14))),
        ("8C3 committees", (perms(8, 3), math.factorial(3), combs(8, 3)), (336, 6, 56)),
        # 15.1
        ("sum of 9 and not 9", (Fraction(4, 36), 1 - Fraction(1, 9)), (Fraction(1, 9), Fraction(8, 9))),
        ("turn 15.1 sum 11", Fraction(2, 36), Fraction(1, 18)),
        # 15.2
        ("with replacement 5/8 * 5/8", Fraction(5, 8) * Fraction(5, 8), Fraction(25, 64)),
        ("turn 15.2 two green from 4 green, 2 yellow",
         (4 + 2, Fraction(4, 6) * Fraction(3, 5), Fraction(4, 6) ** 2),
         (6, Fraction(2, 5), Fraction(4, 9))),
        # 15.3
        ("4! and 6C2", (math.factorial(4), combs(6, 2)), (24, 15)),
        ("turn 15.3 7C2", (combs(7, 2), perms(7, 2), 7 * 2, 7 + 2), (21, 42, 14, 9)),
        # 15.4
        ("row 6 pascal",
         ([combs(6, k) for k in range(7)], sum(combs(6, k) for k in range(7)),
          2 ** 6, Fraction(20, 64), float(Fraction(20, 64)) * 100),
         ([1, 6, 15, 20, 15, 6, 1], 64, 64, Fraction(5, 16), 31.25)),
        ("turn 15.4 4C2", (combs(4, 2), 2 ** 4), (6, 16)),
        # Debate
        ("debate two coins", (Fraction(2, 4), Fraction(1, 2) * Fraction(1, 2), Fraction(1, 4) + Fraction(1, 4)),
         (Fraction(1, 2), Fraction(1, 4), Fraction(1, 2))),
        # Cards
        ("sample-space card and check", (2 * 4, 3 * 6, 3 + 6), (8, 18, 9)),
        ("probability card and check", (Fraction(3, 10), Fraction(2, 8)), (Fraction(3, 10), Fraction(1, 4))),
        ("mutually-exclusive card and check", (round(0.3 + 0.5, 2), round(1 - 0.35, 2)), (0.8, 0.65)),
        ("experimental-probability card and check", (Fraction(15, 50), Fraction(10, 40)), (Fraction(3, 10), Fraction(1, 4))),
        ("independent-events card and check", (Fraction(1, 6) * Fraction(1, 2), Fraction(1, 2) * Fraction(1, 2)),
         (Fraction(1, 12), Fraction(1, 4))),
        ("tree-diagram card and check", (round(0.2 * 0.3, 2), round(0.5 * 0.4, 2), round(0.5 + 0.4, 2)), (0.06, 0.2, 0.9)),
        ("factorial card and check", (math.factorial(3), math.factorial(5), math.factorial(4), 4 + 3 + 2 + 1), (6, 120, 24, 10)),
        ("permutation card and check", (perms(5, 2), perms(6, 2)), (20, 30)),
        ("combination card and check", (combs(5, 2), combs(6, 2)), (10, 15)),
        ("bell-curve check", sum(combs(4, k) for k in range(5)), 16),
    ]


def answers():
    """Chapter 15's turn answers and its cards' check answers, computed."""
    return {
        "ch15-s1-turn": Fraction(2, 36),
        "ch15-s2-turn": Fraction(4, 6) * Fraction(3, 5),
        "ch15-s3-turn": combs(7, 2),
        "ch15-s4-turn": combs(4, 2),
        "outcome-check": len("MATHS"),
        "sample-space-check": 3 * 6,
        "probability-check": Fraction(2, 8),
        "mutually-exclusive-check": round(1 - 0.35, 2),
        "experimental-probability-check": Fraction(10, 40),
        "independent-events-check": Fraction(1, 2) * Fraction(1, 2),
        "tree-diagram-check": round(0.5 * 0.4, 2),
        "factorial-check": math.factorial(4),
        "permutation-check": perms(6, 2),
        "combination-check": combs(6, 2),
        "bell-curve-check": sum(combs(4, k) for k in range(5)),
    }
