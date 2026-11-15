"""
Chapter 1, written by hand to docs/CONTENT_BRIEF.md.

Each section teaches one idea in nine steps, in this order: question, idea, picture, reason, name,
example, mistake, turn, sayBack. A section's `teaches` lists the concept cards whose names first
appear in its `name` step. `build(k)` takes the exporter's answer-key helpers.
"""

from itertools import permutations


def product_forms(k, *orders_of):
    forms = set()
    for factors in orders_of:
        forms |= {"*".join(order) for order in permutations(factors)}
    return k.forms(*sorted(forms))


def build(k):
    return {
        "number": 1,
        "title": "Negative numbers, primes and powers",
        "subtitle": "School book chapter 1 · Why minus times minus is plus, how every number is built from primes, "
                    "and the rules for powers",
        "hookSummary": "Why does a minus times a minus make a plus?",
        "skillCard": {
            "skill": "Signs, primes and powers",
            "sheCan": {
                "prompt": "With no calculator: work out (−2)³ × (−3). Then find the HCF and the LCM of 12 and 20.",
                "answer": "(−2)³ × (−3) = 24. The HCF is 4 and the LCM is 60.",
            },
            "whyItMatters": "Simplifying a fraction is finding an HCF. Adding fractions is finding an LCM. "
                            "Powers are how growth, interest and computer memory are counted.",
            "standsOn": ["Times tables to 12 × 12", "Dividing with remainders", "The number line below zero"],
            "unlocks": [
                "Chapter 2: fractions and recurring decimals",
                "Chapter 4: taking out a common factor in algebra",
                "Chapter 12: Pythagoras, which needs square roots",
            ],
        },
        "intuitionToFormula": {
            "concreteAction": "Stand an arrow at 0 on the number line, pointing at the positive numbers. "
                              "Multiply by −1 and the arrow turns to face the other way. "
                              "Set the turns to 0, 1 and 2 and watch where it points.",
            "ahaInvariant": "The length of the arrow never changes. Only its direction does. "
                            "Two turns put it back where it started, so (−1) × (−1) = +1.",
            "formulaDisplay": "(−1) × (−1) = +1,   HCF × LCM = a × b",
            "termMappings": [
                {"symbol": "(−1) × (−1)", "visualPart": "The arrow, turned twice", "colorRole": "red",
                 "meaning": "Two about-turns leave it facing forward"},
                {"symbol": "HCF", "visualPart": "The blue bar", "colorRole": "blue",
                 "meaning": "The biggest number that divides into both a and b"},
                {"symbol": "LCM", "visualPart": "The amber bar", "colorRole": "amber",
                 "meaning": "The smallest number that both a and b divide into"},
            ],
            "atlasFigureRef": "maths/ch01-number-primes/index.html",
        },
        "sections": [
            {
                "heading": "1.1 Minus times minus",
                "teaches": [],
                "steps": [
                    {"kind": "question",
                     "text": "A shop owes its supplier ₹50 on each of 3 bills. The supplier cancels all 3 bills. "
                             "Is the shop better or worse off, and by how much?"},
                    {"kind": "idea",
                     "text": "Losing a debt is a gain. Take away 3 debts of ₹50 and the shop is ₹150 better off. "
                             "That is what (−3) × (−50) = +150 says: three lots of owing fifty, removed."},
                    {"kind": "picture",
                     "text": "Stand at 0 on a number line, facing the positive numbers. Multiplying by −1 means turn around. "
                             "Turn around once and you face the negative numbers. Turn around twice and you face forward again. "
                             "In the figure, set the turns to 0, 1 and 2 and watch the arrow."},
                    {"kind": "reason",
                     "text": "Why must the answer be positive? Follow this pattern. 3 × (−2) = −6. 2 × (−2) = −4. "
                             "1 × (−2) = −2. 0 × (−2) = 0. Each answer is 2 more than the one before. "
                             "Keep going, and the pattern forces (−1) × (−2) = +2 and (−2) × (−2) = +4. "
                             "Any other answer would break the pattern."},
                    {"kind": "name",
                     "text": "Numbers with a direction, like +5 and −5, are called directed numbers. The rule has two parts. "
                             "Same signs give a positive answer. Different signs give a negative answer. "
                             "Dividing follows the same rule, because dividing undoes multiplying."},
                    {"kind": "example",
                     "text": "Work out (−4) × 6 ÷ (−3). First the size: 4 × 6 = 24, and 24 ÷ 3 = 8. Now the signs. "
                             "There are two minus signs, which is two about-turns. You finish facing forward, so the answer is +8."},
                    {"kind": "mistake",
                     "text": "The rule is for multiplying and dividing only. −3 − 4 is not +7. "
                             "It is −7, because you start at −3 and move 4 further left. "
                             "The saying “two minuses make a plus” tempts you to use the rule where it does not belong. "
                             "When you add or subtract, walk it on the number line."},
                    {"kind": "turn",
                     "text": "Work out (−6) × (−3) ÷ (−9).",
                     "answer": "−2",
                     "answerKey": k.one(k.num("-2"), accepts=["-2", "−2", "= -2"], rejects=["2", "18", "-18"])},
                    {"kind": "sayBack",
                     "text": "Multiplying by a negative number is an about-turn, so two of them leave you facing forward."},
                ],
            },
            {
                "heading": "1.2 Every number has an ingredients list",
                "teaches": ["factor", "prime-number", "prime-factors"],
                "steps": [
                    {"kind": "question",
                     "text": "A class of 24 can line up in equal rows in many ways. A class of 23 cannot, however you try. "
                             "What makes 23 so awkward?"},
                    {"kind": "idea",
                     "text": "24 splits into equal rows of 2, 3, 4, 6, 8 or 12. 23 only works as one long row. "
                             "Some numbers break into smaller pieces. Others refuse to break at all."},
                    {"kind": "picture",
                     "text": "Break 60 into two pieces that multiply to make it: 6 × 10. Break those again. "
                             "6 is 2 × 3 and 10 is 2 × 5. Now nothing breaks any further. You are left with 2 × 2 × 3 × 5. "
                             "Drawn on paper, this looks like a tree with 60 at the top."},
                    {"kind": "reason",
                     "text": "Start a different way: 60 = 4 × 15. Then 4 is 2 × 2 and 15 is 3 × 5. "
                             "You get 2 × 2 × 3 × 5 again. Whichever way you break a number, you finish with the same unbreakable pieces. "
                             "They are the number's ingredients list, and every number has exactly one."},
                    {"kind": "name",
                     "text": "A number that divides exactly into another is called a factor. 6 and 10 are factors of 60. "
                             "A number with exactly two factors, 1 and itself, is a prime number. "
                             "The unbreakable pieces of 60 are its prime factors, and the drawing is a factor tree. "
                             "1 is not prime, because it has only one factor."},
                    {"kind": "example",
                     "text": "Write 84 as a product of prime factors. 84 = 2 × 42. 42 = 2 × 21. 21 = 3 × 7. "
                             "Every piece is now prime. So 84 = 2 × 2 × 3 × 7. Check by multiplying back: 4 × 21 = 84."},
                    {"kind": "mistake",
                     "text": "It is tempting to stop too early. 84 = 4 × 21 is true, but 4 and 21 can both still break. "
                             "Keep going until every piece is prime. A second trap is to think every odd number is prime. "
                             "9, 15 and 21 are odd, and none of them is prime."},
                    {"kind": "turn",
                     "text": "Write 90 as a product of prime factors.",
                     "answer": "2 × 3 × 3 × 5",
                     "answerKey": k.one(product_forms(k, ("2", "3", "3", "5"), ("2", "3^2", "5")),
                                        accepts=["2 × 3 × 3 × 5", "2 × 3² × 5", "5 × 3 × 3 × 2"],
                                        rejects=["9 × 10", "2 × 45", "2 × 3 × 15"])},
                    {"kind": "sayBack",
                     "text": "Every whole number bigger than 1 is either prime or built from primes in exactly one way."},
                ],
            },
            {
                "heading": "1.3 What two numbers share",
                "teaches": ["multiple", "hcf", "lcm"],
                "steps": [
                    {"kind": "question",
                     "text": "A florist has 24 roses and 36 marigolds. She wants identical bunches with no flowers left over. "
                             "What is the largest number of bunches she can make?"},
                    {"kind": "idea",
                     "text": "The number of bunches must divide exactly into 24 and into 36. 2 bunches work. So do 3, 4, 6 and 12. "
                             "The biggest that works is 12, with 2 roses and 3 marigolds in each bunch."},
                    {"kind": "picture",
                     "text": "Use the ingredients lists. 24 = 2 × 2 × 2 × 3 and 36 = 2 × 2 × 3 × 3. "
                             "Both lists contain two 2s and one 3. Those shared pieces multiply to 2 × 2 × 3 = 12. "
                             "In the figure, set the two numbers to 24 and 36 and read the blue bar."},
                    {"kind": "reason",
                     "text": "Why do the shared pieces give the biggest answer? A number divides into 24 only if all its pieces are in 24's list. "
                             "To divide into both numbers, its pieces must be in both lists. "
                             "Take every shared piece and you have the biggest such number."},
                    {"kind": "name",
                     "text": "The biggest number that divides into both is the highest common factor, or HCF. Now turn the question round. "
                             "The numbers in a times table are called multiples. 24, 48 and 72 are multiples of 24. "
                             "The smallest number in both times tables is the lowest common multiple, or LCM. "
                             "For 24 and 36 it is 72, the amber bar."},
                    {"kind": "example",
                     "text": "Two buses leave the depot together. One leaves every 12 minutes and the other every 18. "
                             "When do they next leave together? The multiples of 12 are 12, 24, 36. The multiples of 18 are 18, 36. "
                             "They meet at 36 minutes, so the LCM of 12 and 18 is 36. "
                             "With prime factors: 12 = 2 × 2 × 3 and 18 = 2 × 3 × 3. "
                             "Take each prime the most times it appears in either list. That gives 2 × 2 × 3 × 3 = 36."},
                    {"kind": "mistake",
                     "text": "The tempting shortcut for the LCM is to multiply the two numbers. "
                             "12 × 18 = 216 is a common multiple, but it is not the lowest. Multiplying counts the shared pieces twice. "
                             "In fact HCF × LCM always equals the two numbers multiplied together. Here 6 × 36 = 216 = 12 × 18."},
                    {"kind": "turn",
                     "text": "Find the LCM of 8 and 12.",
                     "answer": "24",
                     "answerKey": k.one(k.num("24"), accepts=["24", "= 24"], rejects=["96", "4", "48"])},
                    {"kind": "sayBack",
                     "text": "The HCF is built from the prime pieces two numbers share, and the LCM from every piece either one needs."},
                ],
            },
            {
                "heading": "1.4 A shorthand for repeated multiplying",
                "teaches": ["power", "index-laws"],
                "steps": [
                    {"kind": "question",
                     "text": "You forward a message to 2 friends. Each of them forwards it to 2 more, and so on. "
                             "How many people receive it in the 10th round?"},
                    {"kind": "idea",
                     "text": "Each round doubles the one before: 2, 4, 8, 16. "
                             "Round 10 is 2 × 2 × 2 × 2 × 2 × 2 × 2 × 2 × 2 × 2, which is 1,024 people. "
                             "Writing ten 2s is slow and hard to check. We need a shorthand."},
                    {"kind": "picture",
                     "text": "Write the count of 2s as a small raised number: 2¹⁰. Now look at 2³ × 2². "
                             "Written out, that is (2 × 2 × 2) × (2 × 2). Count the 2s. There are five, so 2³ × 2² = 2⁵."},
                    {"kind": "reason",
                     "text": "Multiplying joins two chains of 2s into one longer chain, so the counts add. "
                             "Dividing cancels 2s from the chain, so the counts subtract. "
                             "2⁵ ÷ 2² removes two of the five 2s and leaves 2³."},
                    {"kind": "name",
                     "text": "2¹⁰ is called a power of 2. The 2 is the base and the small 10 is the index. "
                             "The plural of index is indices. The counting shortcuts are the laws of indices. "
                             "To multiply powers of the same base, add the indices. To divide, subtract them."},
                    {"kind": "example",
                     "text": "Simplify 3⁴ × 3² ÷ 3³. Multiplying adds: 4 + 2 = 6, giving 3⁶. Dividing subtracts: 6 − 3 = 3, giving 3³. "
                             "And 3³ = 3 × 3 × 3 = 27. Now try 5² ÷ 5². Subtracting the indices gives 5⁰. "
                             "But any number divided by itself is 1. So 5⁰ = 1."},
                    {"kind": "mistake",
                     "text": "There are two traps. First, 2³ is not 2 × 3. It is 2 × 2 × 2 = 8. "
                             "Second, the laws need the same base. 2³ × 3² is two different chains, so work out each one: 8 × 9 = 72."},
                    {"kind": "turn",
                     "text": "Write 7³ × 7⁵ as a single power of 7.",
                     "answer": "7⁸",
                     "answerKey": k.one(k.forms("7^8"), accepts=["7⁸", "7^8"], rejects=["7¹⁵", "49⁸", "7^15"])},
                    {"kind": "sayBack",
                     "text": "A power counts how many times a number is multiplied by itself, so multiplying powers adds the counts."},
                ],
            },
            {
                "heading": "1.5 The number no fraction can reach",
                "teaches": ["square-root", "irrational-number"],
                "steps": [
                    {"kind": "question",
                     "text": "A square garden has an area of 49 square metres. How long is each side? "
                             "Now make the area 2 square metres. How long is each side this time?"},
                    {"kind": "idea",
                     "text": "For 49, you need a number that multiplies by itself to give 49. That is 7. "
                             "For 2, try 1.4. 1.4 × 1.4 = 1.96, which is a little too small. "
                             "Try 1.5. 1.5 × 1.5 = 2.25, which is too big. The side is somewhere between."},
                    {"kind": "picture",
                     "text": "Zoom in. 1.41 × 1.41 = 1.9881. 1.42 × 1.42 = 2.0164. So the side is between 1.41 and 1.42. "
                             "Each extra decimal place gets closer to 2. None of them ever lands on it exactly."},
                    {"kind": "reason",
                     "text": "Could some fraction land on it exactly? Suppose one did, written in its lowest terms. "
                             "Then top × top would equal 2 × bottom × bottom. That makes top × top even, so top is even. "
                             "Write top as 2 × something, and the same line shows that bottom is even too. "
                             "But a fraction in its lowest terms cannot have both parts even. So no fraction works. "
                             "This argument is more than 2,000 years old."},
                    {"kind": "name",
                     "text": "The number that multiplies by itself to give 49 is the square root of 49, written √49 = 7. "
                             "Numbers that can be written as fractions are called rational. "
                             "Numbers that cannot, like √2, are called irrational numbers. Their decimals never end and never repeat."},
                    {"kind": "example",
                     "text": "Between which two whole numbers does √50 lie? 7 × 7 = 49 and 8 × 8 = 64. "
                             "50 is between 49 and 64, so √50 is between 7 and 8. "
                             "It is only a little above 7, because 50 is only a little above 49."},
                    {"kind": "mistake",
                     "text": "√16 is 4, not 8. Halving is tempting because it also makes a number smaller. "
                             "Check by multiplying back: 4 × 4 = 16, but 8 × 8 = 64."},
                    {"kind": "turn",
                     "text": "√30 lies between two whole numbers. What is the smaller one?",
                     "answer": "5",
                     "answerKey": k.one(k.num("5"), accepts=["5", "= 5"], rejects=["6", "15", "30"])},
                    {"kind": "sayBack",
                     "text": "A square root asks what number times itself gives this one, and most of the answers cannot be written as fractions."},
                ],
            },
        ],
        "callouts": [
            {"kind": "predict", "title": "Predict first",
             "body": "Before you touch the figure: what is (−1) × (−1)? Write your answer and one reason for it."},
            {"kind": "check", "title": "Explain it",
             "body": "A friend says a minus times a minus should be an even bigger minus. "
                     "Explain in your own words why it is a plus."},
            {"kind": "careful", "title": "Watch out for 1",
             "body": "1 is not a prime number. A prime has exactly two factors, and 1 has only one."},
        ],
        "keyTerms": [
            "Negative number", "Factor", "Prime number", "Prime factors", "Multiple", "Highest common factor",
            "Lowest common multiple", "Power", "Laws of indices", "Square root", "Irrational number",
        ],
        "widgets": ["w_negative_rotation_line", "w_prime_venn_hcf_lcm", "w_index_staircase_surds"],
        "widgetText": {
            "w_negative_rotation_line": {
                "title": "Turning round on the number line",
                "challengePrompt": "Predict where the arrow points after 0, 1 and 2 turns. Then set the turns and check.",
                "cutaway": "Each × (−1) turns the arrow to face the other way. Its length stays the same. "
                           "Two turns bring it back, so (−1) × (−1) = +1.",
                "idealised": "The rule: (−1) × (−1) = +1",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Set the turns to 1. The arrow faces the negative numbers."},
                    {"title": "2. Notice", "caption": "Set the turns to 2. The arrow faces forward again, the same length as before."},
                    {"title": "3. Match the colours", "caption": "The green arrow faces the positive numbers. The red arrow faces the negative numbers."},
                    {"title": "4. Push it further", "caption": "On paper, try 3 turns and then 4. Odd counts face backward. Even counts face forward."},
                    {"title": "5. Draw it", "caption": "Sketch the number line and the two turns in your journal."},
                ],
            },
            "w_prime_venn_hcf_lcm": {
                "title": "What two numbers share",
                "challengePrompt": "Set the two numbers to 24 and 36. Predict the HCF and the LCM, then read the bars.",
                "cutaway": "24 = 2 × 2 × 2 × 3 and 36 = 2 × 2 × 3 × 3. The shared primes give the HCF, 12. "
                           "Every prime either number needs gives the LCM, 72.",
                "idealised": "The check: HCF × LCM = 12 × 72 = 864 = 24 × 36",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Set the first number to 24 and the second to 36."},
                    {"title": "2. Notice", "caption": "The blue bar shows the HCF, 12. The amber bar shows the LCM, 72."},
                    {"title": "3. Match the colours", "caption": "Blue is what the two numbers share. Amber is the smallest number both divide into."},
                    {"title": "4. Push it further", "caption": "Set both numbers to 24. The HCF and the LCM are both 24. Can you say why?"},
                    {"title": "5. Draw it", "caption": "Draw the factor trees for 24 and 36 in your journal and circle the shared primes."},
                ],
            },
            "w_index_staircase_surds": {
                "title": "The doubling staircase",
                "challengePrompt": "On paper, write 2¹ to 2¹⁰ as a staircase, each step double the one before. "
                                   "Use it to check that 2³ × 2⁴ = 2⁷ without multiplying it out.",
                "cutaway": "Going up one step multiplies by 2. Going up 3 steps and then 4 more is 7 steps. "
                           "That is why the indices add.",
                "idealised": "The rule: 2³ × 2⁴ = 2⁷",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Write the staircase: 2, 4, 8, 16, 32, 64, 128, 256, 512, 1,024."},
                    {"title": "2. Notice", "caption": "2³ is 8 and 2⁴ is 16. 8 × 16 = 128, which is the 7th step."},
                    {"title": "3. Match the rule", "caption": "3 steps and then 4 more steps make 7 steps: 2³ × 2⁴ = 2⁷."},
                    {"title": "4. Push it further", "caption": "Go down instead. 2⁷ ÷ 2⁴ is 4 steps down from the 7th step. Where do you land?"},
                    {"title": "5. Draw it", "caption": "Draw the staircase in your journal and mark the jump from 2³ to 2⁷."},
                ],
            },
        },
        "atlasLessons": [
            {
                "title": "Chapter 1 · Turning round on the number line",
                "question": "What does multiplying by −1 do to a number?",
                "explanation": "It keeps the size and turns the direction round. 3 becomes −3, and −3 becomes 3.",
                "limits": "The rule: (−1) × (−1) = +1",
            },
            {
                "title": "Chapter 1 · What two numbers share",
                "question": "How do the HCF and the LCM of 24 and 36 come from their prime factors?",
                "explanation": "24 = 2 × 2 × 2 × 3 and 36 = 2 × 2 × 3 × 3. The shared primes give the HCF, 12. "
                               "Every prime either number needs gives the LCM, 72.",
                "limits": "The check: HCF × LCM = 12 × 72 = 864 = 24 × 36",
            },
            {
                "title": "Chapter 1 · Why the check always works",
                "question": "Why does HCF × LCM equal the two numbers multiplied together?",
                "explanation": "24 × 36 uses every prime of both numbers. The LCM takes each prime the most times it appears in either number. "
                               "The HCF takes the shared ones, which are exactly the primes the LCM left out. "
                               "Between them they use every prime once.",
                "limits": "The rule: HCF × LCM = a × b",
            },
        ],
        "visualMathTips": {
            "tip-neg-mult": {
                "title": "Why minus times minus is plus",
                "visualIntuition": "Multiplying by −1 turns you round on the number line.",
                "ahaMoment": "Two about-turns leave you facing the way you started.",
                "formula": "(−1) × (−1) = +1",
            },
        },
    }
