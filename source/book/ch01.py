"""
Chapter 1, written by hand to docs/CONTENT_BRIEF.md.

Each section teaches one idea in nine steps, in this order: question, idea, picture, reason, name,
example, mistake, turn, sayBack. A section's `teaches` lists the concept cards whose names first
appear in its `name` step. `build(k)` returns the chapter and `cards(k)` its concept cards; both take the
exporter's answer-key helpers.
"""

from itertools import permutations

from book.arithmetic import Fraction, common_multiples, factors, gcd, is_prime, isqrt, lcm, multiples, prime_factors, prod


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
        "beyondSchoolBook": False,
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
                "figure": True,
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
                "figure": True,
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
        "debate": {
            "id": "debate-ch01-primes",
            "oupUnitNumber": 1,
            "title": "Two trains from Dadar",
            "contextPrompt": "Fast trains leave Dadar every 12 minutes. Slow trains leave every 18 minutes. "
                             "Both leave together at 8:00 AM. Kabir and Meera disagree about when they next leave together.",
            "speakerAName": "Kabir",
            "speakerAClaim": "Multiply the two gaps. 12 × 18 = 216, so it is 216 minutes later.",
            "speakerBName": "Meera",
            "speakerBClaim": "Count on in 12s and in 18s. The first number in both lists is 36, so it is 36 minutes later.",
            "choices": [
                {"id": "ch01-a", "speakerLabel": "Kabir is right (216 minutes)",
                 "reasoningStatement": "To find when two things next happen together, multiply the two gaps.",
                 "isCorrect": False,
                 "socraticRebuttal": "The trains do leave together after 216 minutes. "
                                     "But they have already left together five times before that. "
                                     "The first time is after 36 minutes."},
                {"id": "ch01-b", "speakerLabel": "Meera is right (36 minutes)",
                 "reasoningStatement": "The 12s go 12, 24, 36. The 18s go 18, 36. The first number in both lists is 36.",
                 "isCorrect": True,
                 "socraticRebuttal": "Yes. 36 = 3 × 12 and 36 = 2 × 18, so both trains leave at 8:36 AM."},
                {"id": "ch01-c", "speakerLabel": "Neither. It is 6 minutes.",
                 "reasoningStatement": "6 is the biggest number that divides into both 12 and 18.",
                 "isCorrect": False,
                 "socraticRebuttal": "6 does divide into both. But after 6 minutes neither train has left again. "
                                     "The answer must be a number that 12 and 18 both divide into."},
            ],
            "invariantTakeaway": "Multiplying two numbers always gives a number in both lists. It is often not the first one.",
        },
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


def cards(k):
    """The concept cards this chapter teaches that stand on other cards. Bedrock cards are in bedrock.py."""
    return {
        "prime-number": {
            "name": "Prime number",
            "aliases": ["prime number", "prime numbers", "prime", "primes"],
            "oneSentence": "A whole number with exactly two factors, 1 and itself.",
            "picture": "7 students can only line up as 1 row of 7 or 7 rows of 1. No other equal rows work, so 7 is prime. "
                       "6 students can make 2 rows of 3, so 6 is not.",
            "steps": [
                "Try dividing by 2, 3, 5, 7 and so on.",
                "If nothing divides exactly before the pairs repeat, the number is prime.",
                "Remember that 1 is not prime. It has only one factor.",
                "The first few primes are 2, 3, 5, 7, 11, 13, 17 and 19.",
            ],
            "workedExample": "Is 29 prime? It is odd, so 2 does not divide it. 29 ÷ 3 leaves 2 over. 29 ÷ 5 leaves 4 over. "
                             "6 × 6 is already more than 29, so there is nothing bigger to check. 29 is prime.",
            "check": {
                "prompt": "Which of these is prime: 21, 23 or 27?",
                "answer": "23",
                "answerKey": k.one(k.num("23"), accepts=["23"], rejects=["21", "27"]),
            },
            "mixUp": {
                "name": "odd numbers",
                "how": "9, 15 and 21 are odd but not prime. And 2 is prime but not odd.",
            },
            "standsOn": ["factor"],
        },
        "prime-factors": {
            "name": "Prime factors",
            "aliases": ["prime factors", "prime factor", "prime factorisation", "product of primes", "factor tree", "factor trees"],
            "oneSentence": "The prime numbers that multiply together to make a number.",
            "picture": "Think of primes as bricks that cannot be split. 12 is built from the bricks 2, 2 and 3, "
                       "because 2 × 2 × 3 = 12. No other set of prime bricks makes 12.",
            "steps": [
                "Split the number into any two factors. 60 = 6 × 10.",
                "Split each part again until every part is prime. 6 = 2 × 3 and 10 = 2 × 5.",
                "Write the primes in order. 60 = 2 × 2 × 3 × 5.",
                "Check by multiplying back. 2 × 2 × 3 × 5 = 60.",
            ],
            "workedExample": "Write 84 as a product of primes. 84 = 2 × 42. 42 = 2 × 21. 21 = 3 × 7. "
                             "So 84 = 2 × 2 × 3 × 7. Starting with 84 = 7 × 12 gives the same four primes.",
            "check": {
                "prompt": "Write 30 as a product of prime factors.",
                "answer": "2 × 3 × 5",
                "answerKey": k.one(product_forms(k, ("2", "3", "5")),
                                   accepts=["2 × 3 × 5", "5 × 3 × 2", "2*3*5"],
                                   rejects=["5 × 6", "2 × 15", "3 × 10"]),
            },
            "mixUp": {
                "with": "factor",
                "how": "The factors of 12 are 1, 2, 3, 4, 6 and 12. Its prime factors are only 2, 2 and 3.",
            },
            "standsOn": ["prime-number", "factor"],
        },
        "hcf": {
            "name": "Highest common factor",
            "short": "HCF",
            "aliases": ["highest common factor", "HCF", "common factor", "common factors"],
            "oneSentence": "The biggest number that divides exactly into both numbers.",
            "picture": "You have 12 samosas and 18 jalebis. You want identical plates with nothing left over. "
                       "The most plates you can make is 6, each with 2 samosas and 3 jalebis. So the HCF of 12 and 18 is 6.",
            "steps": [
                "List the factors of each number. 12: 1, 2, 3, 4, 6, 12. 18: 1, 2, 3, 6, 9, 18.",
                "Find the ones in both lists: 1, 2, 3 and 6.",
                "Take the biggest: 6.",
            ],
            "bigNumbers": "Break each number into prime factors. 12 = 2 × 2 × 3 and 18 = 2 × 3 × 3. "
                          "They share one 2 and one 3. Multiply what they share: 2 × 3 = 6.",
            "workedExample": "Find the HCF of 16 and 40. 16 = 2 × 2 × 2 × 2 and 40 = 2 × 2 × 2 × 5. "
                             "They share three 2s. 2 × 2 × 2 = 8, so the HCF is 8.",
            "check": {
                "prompt": "What is the HCF of 20 and 30?",
                "answer": "10",
                "answerKey": k.one(k.num("10"), accepts=["10", "= 10"], rejects=["5", "60", "2"]),
            },
            "mixUp": {
                "with": "lcm",
                "how": "The HCF is never bigger than the smaller number. The LCM is never smaller than the bigger number.",
            },
            "standsOn": ["factor", "prime-factors"],
            "footing": "factors-and-multiples",
        },
        "lcm": {
            "name": "Lowest common multiple",
            "short": "LCM",
            "aliases": ["lowest common multiple", "least common multiple", "LCM", "common multiple", "common multiples"],
            "oneSentence": "The smallest number that both numbers divide into exactly.",
            "picture": "One bus leaves every 4 minutes and another every 6 minutes. They leave together now. "
                       "They next leave together 12 minutes later. So the LCM of 4 and 6 is 12.",
            "steps": [
                "List the multiples of each number. 4: 4, 8, 12, 16. 6: 6, 12, 18.",
                "Find the first number in both lists: 12.",
            ],
            "bigNumbers": "Break each number into prime factors. 12 = 2 × 2 × 3 and 18 = 2 × 3 × 3. "
                          "Take each prime the most times it appears in either number. That is two 2s and two 3s. "
                          "2 × 2 × 3 × 3 = 36.",
            "workedExample": "Find the LCM of 6 and 15. The multiples of 15 are 15, 30, 45. Does 6 divide into 15? No. "
                             "Into 30? Yes, 6 × 5 = 30. The LCM is 30. Notice that it is not 6 × 15 = 90.",
            "check": {
                "prompt": "What is the LCM of 6 and 8?",
                "answer": "24",
                "answerKey": k.one(k.num("24"), accepts=["24", "= 24"], rejects=["48", "2", "14"]),
            },
            "mixUp": {
                "with": "hcf",
                "how": "The LCM is the bigger answer. Both numbers divide into it. The HCF is the smaller answer. "
                       "It divides into both numbers.",
            },
            "standsOn": ["multiple", "prime-factors"],
            "footing": "factors-and-multiples",
        },
        "index-laws": {
            "name": "Laws of indices",
            "aliases": ["laws of indices", "index laws", "index law"],
            "oneSentence": "Shortcuts for multiplying and dividing powers of the same number.",
            "picture": "2³ × 2² is (2 × 2 × 2) × (2 × 2). Count the 2s. There are five, so 2³ × 2² = 2⁵.",
            "steps": [
                "Check that the bases match. The laws only work for the same base.",
                "To multiply, add the indices. 2³ × 2² = 2⁵.",
                "To divide, subtract the indices. 2⁵ ÷ 2² = 2³.",
                "For a power of a power, multiply the indices. (2³)² = 2⁶.",
            ],
            "workedExample": "Simplify 3⁴ × 3² ÷ 3³. Multiplying adds the indices, giving 3⁶. "
                             "Dividing subtracts them, giving 3³. And 3³ = 27.",
            "check": {
                "prompt": "5² × 5⁴ is a single power of 5. What is its index?",
                "answer": "6",
                "answerKey": k.one(k.num("6"), accepts=["6"], rejects=["8", "2"]),
            },
            "mixUp": {
                "name": "different bases",
                "how": "2³ × 3² has two different bases, so no law joins it. Work out each part: 8 × 9 = 72.",
            },
            "standsOn": ["power"],
        },
        "square-root": {
            "name": "Square root",
            "symbol": "√",
            "aliases": ["square root", "square roots", "√"],
            "oneSentence": "The number that, multiplied by itself, gives the number you started with.",
            "picture": "A square floor has 49 tiles. Each side must be 7 tiles long, because 7 × 7 = 49. "
                       "So the square root of 49 is 7, written √49 = 7.",
            "steps": [
                "Ask what number times itself gives this one.",
                "Use the square numbers you know: 1, 4, 9, 16, 25, 36, 49, 64, 81, 100.",
                "If the number sits between two of them, so does its root. √30 is between 5 and 6.",
            ],
            "workedExample": "Find √144. 10 × 10 = 100 is too small. 12 × 12 = 144. So √144 = 12.",
            "check": {
                "prompt": "What is √81?",
                "answer": "9",
                "answerKey": k.one(k.num("9"), accepts=["9", "= 9"], rejects=["40.5", "8", "6561"]),
            },
            "mixUp": {
                "name": "halving",
                "how": "√16 is 4, not 8. Halving asks what you add to itself. A square root asks what you multiply by itself.",
            },
            "standsOn": ["power"],
            "footing": "squares-and-roots",
        },
        "irrational-number": {
            "name": "Irrational number",
            "aliases": ["irrational number", "irrational numbers", "irrational"],
            "oneSentence": "A number that cannot be written as a fraction of two whole numbers.",
            "picture": "Type √2 into a calculator. It shows 1.41421356 and then runs out of screen. "
                       "The digits never end and never settle into a repeating pattern. No fraction lands exactly on it.",
            "steps": [
                "If a number can be written as a fraction, like 0.75 = 3/4, it is rational.",
                "A decimal that stops, or repeats for ever, can always be written as a fraction.",
                "The square root of a whole number that is not a square number is irrational. √2, √3 and √5 are.",
            ],
            "workedExample": "Is √36 irrational? No. √36 = 6, a whole number. Is √40 irrational? "
                             "40 is not a square number, so yes.",
            "check": {
                "prompt": "Only one of √16, √20 and √25 is irrational. Which number is under its root sign?",
                "answer": "20",
                "answerKey": k.one(k.num("20"), accepts=["20", "= 20"], rejects=["16", "25"]),
            },
            "mixUp": {
                "name": "a long decimal",
                "how": "0.333… goes on for ever, but it repeats and equals 1/3. It is rational. An irrational number never repeats.",
            },
            "standsOn": ["square-root"],
        },
    }


def sums():
    """Every sum chapter 1 and its cards state, recomputed. test_book_maths.py checks computed == stated."""
    pattern = [(n, n * (-2)) for n in (3, 2, 1, 0, -1, -2)]
    return [
        # Skill card
        ("(−2)³ × (−3)", (-2) ** 3 * (-3), 24),
        ("HCF of 12 and 20", gcd(12, 20), 4),
        ("LCM of 12 and 20", lcm(12, 20), 60),
        # Bridge, tip, widget and Atlas lessons: (−1) × (−1) = +1, and 3 ↔ −3
        ("(−1) × (−1)", (-1) * (-1), 1),
        ("3 × (−1)", 3 * (-1), -3),
        ("(−3) × (−1)", (-3) * (-1), 3),
        ("odd turns face backward, even face forward", [(-1) ** turns for turns in (1, 2, 3, 4)], [-1, 1, -1, 1]),
        # 1.1 Minus times minus
        ("3 bills of ₹50 cancelled", (-3) * (-50), 150),
        ("3 debts of ₹50", 3 * 50, 150),
        ("the pattern 3, 2, 1, 0, −1, −2 times (−2)", [product for _, product in pattern], [-6, -4, -2, 0, 2, 4]),
        ("each answer is 2 more than the one before",
         {b - a for (_, a), (_, b) in zip(pattern, pattern[1:])}, {2}),
        ("4 × 6", 4 * 6, 24),
        ("24 ÷ 3", Fraction(24, 3), 8),
        ("(−4) × 6 ÷ (−3)", Fraction((-4) * 6, -3), 8),
        ("−3 − 4", -3 - 4, -7),
        ("(−6) × (−3) ÷ (−9)", Fraction((-6) * (-3), -9), -2),
        # 1.2 Every number has an ingredients list
        ("equal rows for 24", factors(24)[1:-1], [2, 3, 4, 6, 8, 12]),
        ("23 only works as one long row", is_prime(23), True),
        ("6 × 10", 6 * 10, 60),
        ("6 = 2 × 3 and 10 = 2 × 5", (2 * 3, 2 * 5), (6, 10)),
        ("60 as primes", prime_factors(60), (2, 2, 3, 5)),
        ("4 × 15", 4 * 15, 60),
        ("4 = 2 × 2 and 15 = 3 × 5", (2 * 2, 3 * 5), (4, 15)),
        ("6 and 10 are factors of 60", (60 % 6, 60 % 10), (0, 0)),
        ("1 has only one factor", len(factors(1)), 1),
        ("84 = 2 × 42, 42 = 2 × 21, 21 = 3 × 7", (2 * 42, 2 * 21, 3 * 7), (84, 42, 21)),
        ("84 as primes", prime_factors(84), (2, 2, 3, 7)),
        ("4 × 21", 4 * 21, 84),
        ("4 and 21 can still break", (is_prime(4), is_prime(21)), (False, False)),
        ("9, 15 and 21 are odd and not prime", [(n % 2, is_prime(n)) for n in (9, 15, 21)], [(1, False)] * 3),
        ("90 as primes", prime_factors(90), (2, 3, 3, 5)),
        # 1.3 What two numbers share
        ("bunches that divide 24 and 36", [d for d in factors(gcd(24, 36)) if d > 1], [2, 3, 4, 6, 12]),
        ("HCF of 24 and 36", gcd(24, 36), 12),
        ("roses and marigolds in each of 12 bunches", (24 // 12, 36 // 12), (2, 3)),
        ("24 as primes", prime_factors(24), (2, 2, 2, 3)),
        ("36 as primes", prime_factors(36), (2, 2, 3, 3)),
        ("shared pieces 2 × 2 × 3", 2 * 2 * 3, 12),
        ("24, 48 and 72 are multiples of 24", multiples(24, 3), [24, 48, 72]),
        ("LCM of 24 and 36", lcm(24, 36), 72),
        ("multiples of 12", multiples(12, 3), [12, 24, 36]),
        ("multiples of 18", multiples(18, 2), [18, 36]),
        ("LCM of 12 and 18", lcm(12, 18), 36),
        ("12 as primes", prime_factors(12), (2, 2, 3)),
        ("18 as primes", prime_factors(18), (2, 3, 3)),
        ("2 × 2 × 3 × 3", 2 * 2 * 3 * 3, 36),
        ("12 × 18", 12 * 18, 216),
        ("216 is a common multiple of 12 and 18", (216 % 12, 216 % 18), (0, 0)),
        ("HCF × LCM for 12 and 18", gcd(12, 18) * lcm(12, 18), 216),
        ("6 × 36", 6 * 36, 216),
        ("LCM of 8 and 12", lcm(8, 12), 24),
        # 1.4 A shorthand for repeated multiplying
        ("rounds 1 to 4", [2 ** r for r in range(1, 5)], [2, 4, 8, 16]),
        ("round 10", 2 ** 10, 1024),
        ("ten 2s multiplied", prod([2] * 10), 1024),
        ("2³ × 2²", 2 ** 3 * 2 ** 2, 2 ** 5),
        ("2⁵ ÷ 2²", Fraction(2 ** 5, 2 ** 2), 2 ** 3),
        ("4 + 2", 4 + 2, 6),
        ("6 − 3", 6 - 3, 3),
        ("3⁴ × 3² ÷ 3³", Fraction(3 ** 4 * 3 ** 2, 3 ** 3), 3 ** 3),
        ("3³", 3 ** 3, 27),
        ("5² ÷ 5²", Fraction(5 ** 2, 5 ** 2), 1),
        ("5⁰", 5 ** 0, 1),
        ("2³ is not 2 × 3", (2 ** 3, 2 * 3 != 2 ** 3), (8, True)),
        ("2³ × 3²", 2 ** 3 * 3 ** 2, 72),
        ("8 × 9", 8 * 9, 72),
        ("7³ × 7⁵", 7 ** 3 * 7 ** 5, 7 ** 8),
        # 1.5 The number no fraction can reach
        ("7 × 7", 7 * 7, 49),
        ("1.4 × 1.4", Fraction("1.4") ** 2, Fraction("1.96")),
        ("1.5 × 1.5", Fraction("1.5") ** 2, Fraction("2.25")),
        ("2 is between 1.4² and 1.5²", Fraction("1.96") < 2 < Fraction("2.25"), True),
        ("1.41 × 1.41", Fraction("1.41") ** 2, Fraction("1.9881")),
        ("1.42 × 1.42", Fraction("1.42") ** 2, Fraction("2.0164")),
        ("2 is between 1.41² and 1.42²", Fraction("1.9881") < 2 < Fraction("2.0164"), True),
        ("√49", isqrt(49), 7),
        ("8 × 8", 8 * 8, 64),
        ("√50 is between 7 and 8", (isqrt(50), 7 * 7 < 50 < 8 * 8), (7, True)),
        ("√16", isqrt(16), 4),
        ("4 × 4", 4 * 4, 16),
        ("√30 is between 5 and 6", (isqrt(30), 5 * 5 < 30 < 6 * 6), (5, True)),
        # Widgets and Atlas lessons
        ("24 and 36: HCF × LCM", gcd(24, 36) * lcm(24, 36), 864),
        ("12 × 72", 12 * 72, 864),
        ("24 × 36", 24 * 36, 864),
        ("24 and 24: HCF and LCM", (gcd(24, 24), lcm(24, 24)), (24, 24)),
        ("the doubling staircase", [2 ** n for n in range(1, 11)], [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024]),
        ("2³ and 2⁴", (2 ** 3, 2 ** 4), (8, 16)),
        ("8 × 16", 8 * 16, 128),
        ("128 is the 7th step", 2 ** 7, 128),
        ("3 steps and 4 more", 3 + 4, 7),
        ("2³ × 2⁴", 2 ** 3 * 2 ** 4, 2 ** 7),
        # Who is right? Two trains from Dadar
        ("12 × 18 minutes", 12 * 18, 216),
        ("the 12s and the 18s", (multiples(12, 3), multiples(18, 2)), ([12, 24, 36], [18, 36])),
        ("first time together", lcm(12, 18), 36),
        ("36 = 3 × 12 = 2 × 18", (3 * 12, 2 * 18), (36, 36)),
        ("8:00 AM plus 36 minutes is 8:36", 0 + 36, 36),
        ("together five times before 216 minutes", len(common_multiples(12, 18, below=216)), 5),
        ("6 divides into both 12 and 18", (12 % 6, 18 % 6, gcd(12, 18)), (0, 0, 6)),
        # Cards: prime-number
        ("7 has two factors", factors(7), [1, 7]),
        ("6 = 2 rows of 3", 2 * 3, 6),
        ("29 ÷ 2, 3 and 5 leave 1, 2 and 4 over", (29 % 2, 29 % 3, 29 % 5), (1, 2, 4)),
        ("6 × 6 is more than 29", 6 * 6 > 29, True),
        ("29 is prime", is_prime(29), True),
        ("the first primes", [n for n in range(2, 20) if is_prime(n)], [2, 3, 5, 7, 11, 13, 17, 19]),
        ("only 23 of 21, 23, 27 is prime", [n for n in (21, 23, 27) if is_prime(n)], [23]),
        ("2 is prime and even", (is_prime(2), 2 % 2), (True, 0)),
        # Cards: prime-factors
        ("2 × 2 × 3", 2 * 2 * 3, 12),
        ("2 × 2 × 3 × 5", 2 * 2 * 3 * 5, 60),
        ("84 = 7 × 12 gives the same primes", tuple(sorted((7,) + prime_factors(12))), prime_factors(84)),
        ("30 as primes", prime_factors(30), (2, 3, 5)),
        ("factors of 12", factors(12), [1, 2, 3, 4, 6, 12]),
        # Cards: hcf
        ("HCF of 12 and 18", gcd(12, 18), 6),
        ("samosas and jalebis per plate", (12 // 6, 18 // 6), (2, 3)),
        ("factors of 18", factors(18), [1, 2, 3, 6, 9, 18]),
        ("factors in both lists", sorted(set(factors(12)) & set(factors(18))), [1, 2, 3, 6]),
        ("2 × 3", 2 * 3, 6),
        ("16 as primes", prime_factors(16), (2, 2, 2, 2)),
        ("40 as primes", prime_factors(40), (2, 2, 2, 5)),
        ("2 × 2 × 2", 2 * 2 * 2, 8),
        ("HCF of 16 and 40", gcd(16, 40), 8),
        ("HCF of 20 and 30", gcd(20, 30), 10),
        # Cards: lcm
        ("LCM of 4 and 6", lcm(4, 6), 12),
        ("multiples of 4", multiples(4, 4), [4, 8, 12, 16]),
        ("multiples of 6", multiples(6, 3), [6, 12, 18]),
        ("multiples of 15", multiples(15, 3), [15, 30, 45]),
        ("6 does not divide 15", 15 % 6 != 0, True),
        ("6 × 5", 6 * 5, 30),
        ("LCM of 6 and 15", lcm(6, 15), 30),
        ("6 × 15", 6 * 15, 90),
        ("LCM of 6 and 8", lcm(6, 8), 24),
        # Cards: index-laws
        ("2⁵ ÷ 2² = 2³", Fraction(2 ** 5, 2 ** 2), 2 ** 3),
        ("(2³)²", (2 ** 3) ** 2, 2 ** 6),
        ("5² × 5⁴", 5 ** 2 * 5 ** 4, 5 ** (2 + 4)),
        # Cards: square-root
        ("the square numbers", [n * n for n in range(1, 11)], [1, 4, 9, 16, 25, 36, 49, 64, 81, 100]),
        ("10 × 10", 10 * 10, 100),
        ("12 × 12", 12 * 12, 144),
        ("√144", isqrt(144), 12),
        ("√81", isqrt(81), 9),
        # Cards: irrational-number
        ("0.75", Fraction("0.75"), Fraction(3, 4)),
        ("√2 on a calculator", f"{2 ** 0.5:.10f}"[:10], "1.41421356"),
        ("√36", isqrt(36), 6),
        ("40 is not a square number", isqrt(40) ** 2 == 40, False),
        ("only √20 of √16, √20, √25 is irrational", [n for n in (16, 20, 25) if isqrt(n) ** 2 != n], [20]),
        ("1/3 as a decimal starts 0.333", f"{1 / 3:.3f}", "0.333"),
    ]


def answers():
    """Chapter 1's turn answers and its cards' check answers, computed."""
    return {
        "ch01-s1-turn": Fraction((-6) * (-3), -9),
        "ch01-s2-turn": prime_factors(90),
        "ch01-s3-turn": lcm(8, 12),
        "ch01-s4-turn": f"7^{3 + 5}",
        "ch01-s5-turn": isqrt(30),
        "prime-number-check": next(n for n in (21, 23, 27) if is_prime(n)),
        "prime-factors-check": prime_factors(30),
        "hcf-check": gcd(20, 30),
        "lcm-check": lcm(6, 8),
        "index-laws-check": 2 + 4,
        "square-root-check": isqrt(81),
        "irrational-number-check": next(n for n in (16, 20, 25) if isqrt(n) ** 2 != n),
    }
