"""
Chapter 2, written by hand to docs/CONTENT_BRIEF.md. It carries school unit 6.

Each section teaches one idea in nine steps, in this order: question, idea, picture, reason, name,
example, mistake, turn, sayBack. A section's `teaches` lists the concept cards whose names first
appear in its `name` step. `build(k)` returns the chapter and `cards(k)` its concept cards; both take the
exporter's answer-key helpers. The letter x arrives in the last section, after 0.333… has been worked in words.

`schoolTopics` and `schoolQuestions` rewrite the topic summaries, worked examples and faded prompts of
school unit 6. The answer keys and stuck sheets stay in the exporter.
"""

from book.arithmetic import (Fraction, decimal_digits, gcd, lcm, mixed, prime_factors, recurring, round_dp, round_sf,
                             terminates)


def build(k):
    return {
        "number": 2,
        "title": "Fractions and recurring decimals",
        "subtitle": "School book chapter 6 · Fractions that share a name, why you flip to divide, "
                    "and decimals that never end",
        "hookSummary": "How can 0.333… go on for ever and still be exactly one third?",
        "beyondSchoolBook": False,
        "skillCard": {
            "skill": "Fractions and decimals, both ways",
            "sheCan": {
                "prompt": "With no calculator: work out 5 1/2 − 2 2/3 and 9 ÷ 3/5. Then write 0.454545… as a fraction.",
                "answer": "5 1/2 − 2 2/3 = 2 5/6. 9 ÷ 3/5 = 15. 0.454545… = 5/11.",
            },
            "whyItMatters": "Recipes, prices and measurements are rarely whole numbers. "
                            "Almost every chapter after this one divides something, and dividing makes fractions.",
            "standsOn": [
                "Chapter 1: factors, multiples, the HCF and the LCM",
                "Place value down to thousandths",
                "Dividing by a one-digit number, with remainders",
            ],
            "unlocks": [
                "Chapter 3: sharing in parts, percentages and growth",
                "Chapter 4: algebra, where the same fraction rules work on letters",
                "Chapter 15: counting chances, which are written as fractions",
            ],
        },
        "intuitionToFormula": {
            "concreteAction": "Set the repeating digits to 36. The red row is 100 lots of the number 0.3636… "
                              "The blue row is 1 lot of it. Take the blue row away from the red row.",
            "ahaInvariant": "The digits after the decimal point are the same in both rows, so they cancel. "
                            "What is left is a whole number: 99 lots make 36. So the number is 36/99, which is 4/11.",
            "formulaDisplay": "100x − x = 99x,   a ÷ b/c = a × c/b",
            "termMappings": [
                {"symbol": "100x", "visualPart": "The red row", "colorRole": "red",
                 "meaning": "100 lots of the number, which moves every digit two places to the left"},
                {"symbol": "x", "visualPart": "The blue row", "colorRole": "blue",
                 "meaning": "1 lot of the number, the recurring decimal itself"},
                {"symbol": "99x", "visualPart": "The green box", "colorRole": "green",
                 "meaning": "What is left after taking away, which is a whole number"},
                {"symbol": "a ÷ b/c", "visualPart": "The amber line", "colorRole": "amber",
                 "meaning": "How many pieces of size b/c fit into a"},
            ],
            "atlasFigureRef": "maths/ch02-fractions-decimals/index.html",
        },
        "sections": [
            {
                "heading": "2.1 One amount, many names",
                "teaches": ["numerator-denominator", "equivalent-fractions", "simplest-form"],
                "steps": [
                    {"kind": "question",
                     "text": "Kym eats 2 slices of a pizza cut into 4 equal slices. "
                             "Aarav has a pizza of the same size, cut into 8 equal slices, and eats 4. Who ate more?"},
                    {"kind": "idea",
                     "text": "They ate the same amount: half a pizza each. "
                             "Cutting every slice in two doubles the number of slices and doubles how many you eat. "
                             "The amount of pizza does not change. So 2/4 and 4/8 are two names for one amount."},
                    {"kind": "picture",
                     "text": "Draw a bar and split it into 4 equal parts. Shade 2 of them. "
                             "Now draw a line through the middle of every part. The bar has 8 parts and 4 are shaded. "
                             "The shaded length has not moved."},
                    {"kind": "reason",
                     "text": "Why does this work? Multiplying the top and the bottom by 2 is multiplying by 2/2. "
                             "And 2/2 is 1 whole. Multiplying by 1 never changes an amount. "
                             "Dividing the top and the bottom by the same number undoes it, so that is safe too."},
                    {"kind": "name",
                     "text": "The top number of a fraction is the numerator and the bottom number is the denominator. "
                             "Fractions that name the same amount, like 2/4 and 4/8, are equivalent fractions. "
                             "Divide the top and the bottom by their highest common factor and you reach the simplest form. "
                             "For 2/4 and 4/8 that is 1/2."},
                    {"kind": "example",
                     "text": "Write 18/24 in its simplest form. The HCF of 18 and 24 is 6. 18 ÷ 6 = 3 and 24 ÷ 6 = 4. "
                             "So 18/24 = 3/4. Check: 3 and 4 share no factor except 1, so you cannot go further."},
                    {"kind": "mistake",
                     "text": "It is tempting to add the same number to the top and the bottom. Try it: 1/2 would become 2/3. "
                             "But half a pizza is not two thirds of a pizza. Adding changes the amount. "
                             "Only multiplying or dividing both parts keeps it the same."},
                    {"kind": "turn",
                     "text": "Write 24/36 in its simplest form.",
                     "answer": "2/3",
                     "answerKey": k.one(k.num("2/3", simplest=True), accepts=["2/3", "= 2/3"],
                                        rejects=["4/6", "12/18", "3/2"])},
                    {"kind": "sayBack",
                     "text": "Multiplying or dividing the top and the bottom by the same number gives a new name for the same amount."},
                ],
            },
            {
                "heading": "2.2 Taking away pieces of different sizes",
                "teaches": ["common-denominator", "improper-fraction", "mixed-number"],
                "steps": [
                    {"kind": "question",
                     "text": "Kym has 3 1/4 metres of ribbon. She cuts off 1 2/3 metres to wrap a gift. "
                             "How much ribbon is left?"},
                    {"kind": "idea",
                     "text": "Quarters and thirds are pieces of different sizes, so you cannot take one from the other yet. "
                             "Cut both into twelfths. A quarter is 3 twelfths and a third is 4 twelfths. "
                             "Now every piece is the same size, and you can count them."},
                    {"kind": "picture",
                     "text": "Think of 3 1/4 as 3 whole metres and 1 quarter. Each whole metre is 4 quarters, so that is 13 quarters. "
                             "In the same way, 1 2/3 is 5 thirds. "
                             "In twelfths, 13 quarters is 39 twelfths and 5 thirds is 20 twelfths."},
                    {"kind": "reason",
                     "text": "Why twelfths? The new denominator must be in the 4 times table and in the 3 times table. "
                             "The lowest common multiple of 4 and 3 is 12. "
                             "Any common multiple would work, but the lowest keeps the numbers small."},
                    {"kind": "name",
                     "text": "A denominator that both fractions can share is a common denominator. Here it is 12. "
                             "A fraction whose top is bigger than its bottom, like 13/4, is an improper fraction. "
                             "A whole number with a fraction beside it, like 3 1/4, is a mixed number."},
                    {"kind": "example",
                     "text": "Work out 3 1/4 − 1 2/3. Write both as improper fractions: 13/4 and 5/3. "
                             "Give both the common denominator 12: 39/12 and 20/12. "
                             "Take away the numerators: 39 − 20 = 19, so the answer is 19/12. "
                             "12 twelfths make 1 whole, which leaves 7 twelfths. The ribbon left is 1 7/12 metres."},
                    {"kind": "mistake",
                     "text": "The tempting way is to take away the tops and the bottoms separately. "
                             "For 3/4 − 1/3 that gives 2/1, which is 2. But you started with less than 1 whole, so 2 cannot be right. "
                             "The denominator names the size of the piece. It is not something you take away."},
                    {"kind": "turn",
                     "text": "Work out 2 1/2 − 1 2/3. Give your answer as a fraction in its simplest form.",
                     "answer": "5/6",
                     "answerKey": k.one(k.num("5/6", simplest=True), accepts=["5/6", "= 5/6"],
                                        rejects=["1 1/6", "1/6", "10/12"])},
                    {"kind": "sayBack",
                     "text": "To add or take away fractions, first cut them into pieces of the same size, then count the pieces."},
                ],
            },
            {
                "heading": "2.3 Why you flip to divide",
                "figure": True,
                "teaches": ["reciprocal"],
                "steps": [
                    {"kind": "question",
                     "text": "A jug holds 4 litres of lassi. Each glass takes 2/3 of a litre. How many glasses can you fill?"},
                    {"kind": "idea",
                     "text": "Dividing asks how many times one amount fits into another. Start by counting thirds. "
                             "Each litre holds 3 thirds, so 4 litres hold 12 thirds. Each glass uses 2 of them. "
                             "12 ÷ 2 = 6, so you can fill 6 glasses."},
                    {"kind": "picture",
                     "text": "Draw 4 bars for the 4 litres and cut each into 3 equal parts. That makes 12 parts. "
                             "Circle them in groups of 2, and you get 6 groups. "
                             "In the figure, set the whole number to 4 and the bottom of the fraction to 3. Read the amber line."},
                    {"kind": "reason",
                     "text": "Look at what you did. You multiplied 4 by 3 to count the thirds. Then you divided by 2 to make the groups. "
                             "Multiplying by 3 and dividing by 2 is the same as multiplying by 3/2. "
                             "So 4 ÷ 2/3 = 4 × 3/2."},
                    {"kind": "name",
                     "text": "Turn a fraction upside down and you get its reciprocal. The reciprocal of 2/3 is 3/2. "
                             "Dividing by a fraction is the same as multiplying by its reciprocal. "
                             "Multiplying fractions is the short part: multiply the numerators, then multiply the denominators. "
                             "So 1/2 × 3/4 = 3/8, which is half of three quarters."},
                    {"kind": "example",
                     "text": "Work out 1 1/2 ÷ 3/8. Write 1 1/2 as the improper fraction 3/2. "
                             "The reciprocal of 3/8 is 8/3, so work out 3/2 × 8/3. "
                             "Multiply the numerators and the denominators: 24/6, which is 4. "
                             "Check with the meaning. Four pieces of 3/8 make 12/8, and 12/8 is 1 1/2."},
                    {"kind": "mistake",
                     "text": "Dividing does not always make a number smaller. 4 ÷ 2/3 = 6, which is bigger than 4. "
                             "That feels wrong until you remember the question: how many small pieces fit? "
                             "A second trap is flipping the wrong fraction. Only the one you divide by gets flipped."},
                    {"kind": "turn",
                     "text": "A tailor has 6 metres of cloth. Each scarf needs 3/4 of a metre. Work out 6 ÷ 3/4.",
                     "answer": "8",
                     "answerKey": k.one(k.num("8"), accepts=["8", "= 8", "8 scarves"], rejects=["4.5", "9/2", "2", "1/8"])},
                    {"kind": "sayBack",
                     "text": "Dividing by a fraction asks how many of that piece fit, so you multiply by the fraction turned upside down."},
                ],
            },
            {
                "heading": "2.4 Where the decimal point goes",
                "teaches": ["decimal-place"],
                "steps": [
                    {"kind": "question",
                     "text": "A floor tile is 0.3 m long and 0.2 m wide. Is its area 0.6 square metres, or 0.06?"},
                    {"kind": "idea",
                     "text": "0.3 is 3 tenths and 0.2 is 2 tenths. 3 × 2 = 6. "
                             "But tenths times tenths are hundredths, so the area is 6 hundredths. "
                             "That is 0.06 square metres, ten times smaller than 0.6."},
                    {"kind": "picture",
                     "text": "Draw a square 1 m by 1 m and cut it into a 10 by 10 grid. That makes 100 small squares. "
                             "The tile reaches 3 squares one way and 2 the other. It covers 6 small squares out of 100."},
                    {"kind": "reason",
                     "text": "As fractions, 0.3 × 0.2 is 3/10 × 2/10. Multiply the numerators to get 6. "
                             "Multiply the denominators to get 100. The answer is 6/100. "
                             "Each digit after a decimal point brings one more division by 10 into the answer."},
                    {"kind": "name",
                     "text": "The positions after the decimal point are called decimal places. 0.3 has one decimal place and 0.06 has two. "
                             "To multiply decimals, multiply them as whole numbers first. "
                             "Then give the answer as many decimal places as the two numbers had between them."},
                    {"kind": "example",
                     "text": "Work out 4.5 ÷ 0.15. Dividing by a decimal is awkward, so change the question. "
                             "Multiply both numbers by 100 to get 450 ÷ 15. "
                             "The answer does not change, for the same reason that equivalent fractions are equal. "
                             "45 ÷ 15 = 3, so 450 ÷ 15 = 30. Check: 30 × 0.15 = 4.5."},
                    {"kind": "mistake",
                     "text": "Multiplying does not always make a number bigger. 8 × 0.5 = 4, because 0.5 of something is half of it. "
                             "And dividing by a number less than 1 makes it bigger: 8 ÷ 0.5 = 16. "
                             "Ask how many halves fit into 8."},
                    {"kind": "turn",
                     "text": "Work out 0.4 × 0.06.",
                     "answer": "0.024",
                     "answerKey": k.one(k.num("0.024"), accepts=["0.024", ".024", "= 0.024"],
                                        rejects=["0.24", "0.0024", "2.4"])},
                    {"kind": "sayBack",
                     "text": "Multiply decimals as whole numbers and then place the point. "
                             "To divide by a decimal, scale both numbers until you divide by a whole number."},
                ],
            },
            {
                "heading": "2.5 How many digits to keep",
                "teaches": ["significant-figures"],
                "steps": [
                    {"kind": "question",
                     "text": "A cricket ground counts a crowd of 32,846. The newspaper prints 33,000. "
                             "Has the newspaper made a mistake?"},
                    {"kind": "idea",
                     "text": "No. The first two digits carry almost all the information. "
                             "33,000 is the nearest thousand to 32,846, and it is easier to remember. "
                             "The newspaper kept the digits that matter most and rounded the rest."},
                    {"kind": "picture",
                     "text": "Mark 32,000 and 33,000 on a number line. 32,846 sits between them, much closer to 33,000. "
                             "The halfway mark is 32,500. Anything at or past halfway rounds up."},
                    {"kind": "reason",
                     "text": "Now take a tiny number: 0.004718 kg of saffron. The zeros at the front only hold the digits in place. "
                             "They vanish if you write the mass as 4.718 g. The digits that measure anything start at the 4."},
                    {"kind": "name",
                     "text": "The digits that carry the size of a number are its significant figures. "
                             "Count them from the first digit that is not zero. "
                             "32,846 to 2 significant figures is 33,000, and 0.004718 is 0.0047. "
                             "Decimal places are different: they are counted from the decimal point."},
                    {"kind": "example",
                     "text": "Round 0.03064 to 3 significant figures. The first significant figure is the 3. "
                             "The zero after the 3 counts, because it sits between measured digits. "
                             "So the three figures are 3, 0 and 6. The next digit is 4, which is less than 5, so the 6 stays. "
                             "The answer is 0.0306."},
                    {"kind": "mistake",
                     "text": "There are two traps. First, 0.0306 to 2 decimal places is 0.03, which throws most of the number away. "
                             "Decimal places and significant figures are different counts. Second, keep the size. "
                             "32,846 to 2 significant figures is 33,000, not 33. The zeros hold the place of each digit."},
                    {"kind": "turn",
                     "text": "Round 0.05093 to 2 significant figures.",
                     "answer": "0.051",
                     "answerKey": k.one(k.num("0.051"), accepts=["0.051", ".051", "= 0.051"],
                                        rejects=["0.05", "0.0509", "0.06", "51"])},
                    {"kind": "sayBack",
                     "text": "Significant figures are counted from the first digit that is not zero, so they work for huge and tiny numbers alike."},
                ],
            },
            {
                "heading": "2.6 Decimals that never end",
                "figure": True,
                "teaches": ["terminating-decimal", "recurring-decimal"],
                "steps": [
                    {"kind": "question",
                     "text": "Share ₹1 equally among 4 friends and each gets ₹0.25. "
                             "Share ₹1 among 3 friends and the calculator shows 0.3333333. What went wrong with 3?"},
                    {"kind": "idea",
                     "text": "Nothing went wrong. Divide 1 by 3 by hand. 10 tenths shared among 3 is 3 each, with 1 tenth left over. "
                             "That 1 tenth becomes 10 hundredths, and the same step happens again. "
                             "The remainder is always 1, so the 3s never stop."},
                    {"kind": "picture",
                     "text": "Now divide 1 by 7 by hand. The remainder at each step can only be 1, 2, 3, 4, 5 or 6. "
                             "After at most six steps, one of them must come back. "
                             "From then on the digits repeat: 1 ÷ 7 = 0.142857142857…"},
                    {"kind": "reason",
                     "text": "Why does 1/4 stop when 1/3 does not? A decimal that stops is a fraction over 10, 100 or 1,000. "
                             "Those denominators are built only from the primes 2 and 5. 1/4 fits, because it is 25/100. "
                             "But no power of 10 is a multiple of 3, so 1/3 can never stop."},
                    {"kind": "name",
                     "text": "A decimal that stops, like 0.25, is a terminating decimal. "
                             "A decimal whose digits repeat for ever, like 0.333…, is a recurring decimal. "
                             "The three dots mean the pattern goes on. Some books put a dot over the repeating digits instead."},
                    {"kind": "example",
                     "text": "Write 0.333… as a fraction. Ten lots of it are 3.333…, and one lot is 0.333…, with the same tail of digits. "
                             "Take one lot from ten lots and the tails cancel, so nine lots are exactly 3. "
                             "The number is 3/9, which is 1/3. Now try 0.3636…, where two digits repeat. "
                             "Write x for the number, so that 100x = 36.3636… and the tails match again. "
                             "Subtract x and 99x = 36, so x = 36/99 = 4/11. "
                             "In the figure, set the repeating digits to 36 and follow the three rows."},
                    {"kind": "mistake",
                     "text": "0.3 and 0.333… are different numbers. 0.3 is 3/10, and 0.333… is 1/3, which is a little more. "
                             "If you cut a recurring decimal short, you have rounded it. "
                             "A second trap: when two digits repeat, multiplying by 10 does not line the tails up. Multiply by 100."},
                    {"kind": "turn",
                     "text": "Write 0.151515… as a fraction in its simplest form.",
                     "answer": "5/33",
                     "answerKey": k.one(k.num("5/33", simplest=True), accepts=["5/33", "x = 5/33", "= 5/33"],
                                        rejects=["15/99", "15/100", "3/20", "1/6"])},
                    {"kind": "sayBack",
                     "text": "Multiply a recurring decimal so the repeating tails line up, subtract, and a fraction is left."},
                ],
            },
        ],
        "callouts": [
            {"kind": "predict", "title": "Predict first",
             "body": "Before you touch the figure: is 3 ÷ 2/4 bigger or smaller than 3? Decide, and write down why you think so."},
            {"kind": "check", "title": "Explain it",
             "body": "A friend says 1/3 cannot equal 0.333… because the 3s never finish. "
                     "Explain in your own words why the two are the same number."},
            {"kind": "careful", "title": "Watch out for the flip",
             "body": "When you divide by a fraction, flip only the fraction you divide by. The first number stays as it is."},
        ],
        "debate": {
            "id": "debate-ch02-fractions",
            "oupUnitNumber": 6,
            "title": "Half-litre bottles",
            "contextPrompt": "A juice stall has 6 litres of nimbu pani. It sells it in bottles of 1/2 a litre. "
                             "Riya and Arjun disagree about how many bottles it can fill.",
            "speakerAName": "Riya",
            "speakerAClaim": "6 ÷ 1/2 means half of 6. That is 3 bottles.",
            "speakerBName": "Arjun",
            "speakerBClaim": "Each litre fills 2 bottles, so 6 litres fill 12 bottles.",
            "choices": [
                {"id": "ch02-a", "speakerLabel": "Riya is right (3 bottles)",
                 "reasoningStatement": "Dividing makes a number smaller, so the answer must be less than 6.",
                 "isCorrect": False,
                 "socraticRebuttal": "Half of 6 is 6 × 1/2, which is 3. But 3 bottles of half a litre hold only 1 1/2 litres. "
                                     "Where did the other 4 1/2 litres go?"},
                {"id": "ch02-b", "speakerLabel": "Arjun is right (12 bottles)",
                 "reasoningStatement": "Two half-litre bottles fill from each litre, and there are 6 litres.",
                 "isCorrect": True,
                 "socraticRebuttal": "Yes. 6 ÷ 1/2 = 6 × 2 = 12. Check it: 12 bottles of half a litre hold 6 litres."},
                {"id": "ch02-c", "speakerLabel": "Neither. It is 1/12 of a bottle.",
                 "reasoningStatement": "Flip the 6 to get 1/6, then multiply by 1/2.",
                 "isCorrect": False,
                 "socraticRebuttal": "That flips the wrong number. One litre alone fills 2 bottles, so 1/12 of a bottle cannot be right. "
                                     "Flip only the 1/2."},
            ],
            "invariantTakeaway": "Dividing by a number less than 1 gives an answer bigger than the number you started with.",
        },
        "keyTerms": [
            "Fraction", "Numerator and denominator", "Equivalent fractions", "Simplest form", "Common denominator",
            "Improper fraction", "Mixed number", "Reciprocal", "Decimal place", "Significant figures",
            "Terminating decimal", "Recurring decimal",
        ],
        "widgets": ["w_recurring_decimal_tail_canceller", "w_fraction_area_division"],
        "widgetText": {
            "w_recurring_decimal_tail_canceller": {
                "title": "Lining up the repeating digits",
                "challengePrompt": "Set the repeating digits to 36. Predict what is left when the blue row is taken from the red row. "
                                   "Then read the green box.",
                "cutaway": "The red row is 100 lots of 0.3636… and the blue row is 1 lot. "
                           "Their digits after the point match, so they cancel. 99 lots are left, and they make 36.",
                "idealised": "The result: 0.3636… = 36/99 = 4/11",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Set the repeating digits to 36. The red row shows 36.3636… and the blue row shows 0.3636…"},
                    {"title": "2. Notice", "caption": "After the decimal point the two rows are identical. Taking one from the other leaves exactly 36."},
                    {"title": "3. Match the colours", "caption": "Red is 100 lots of the number. Blue is 1 lot. Green is the 99 lots left over."},
                    {"title": "4. Push it further", "caption": "Set the repeating digits to 18. The green box gives 18/99, which is 2/11. Divide 2 by 11 on paper to check."},
                    {"title": "5. Draw it", "caption": "Write the three rows for 0.3636… in your journal, with the matching digits lined up."},
                ],
            },
            "w_fraction_area_division": {
                "title": "How many pieces fit?",
                "challengePrompt": "Set the whole number to 4 and the bottom of the fraction to 3. "
                                   "Predict how many pieces of 2/3 fit into 4. Then read the amber line.",
                "cutaway": "4 wholes cut into thirds make 12 thirds. Each piece uses 2 of them, so 6 pieces fit. "
                           "That is 4 × 3 ÷ 2, which is 4 × 3/2.",
                "idealised": "The rule: 4 ÷ 2/3 = 4 × 3/2 = 6",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Set the whole number to 4 and the bottom of the fraction to 3."},
                    {"title": "2. Notice", "caption": "The amber line counts the pieces. 6 pieces of 2/3 fit into 4."},
                    {"title": "3. Match the rule", "caption": "Multiplying by 3 counts the thirds. Dividing by 2 groups them. Together that is × 3/2."},
                    {"title": "4. Push it further", "caption": "Keep the whole number at 4 and set the bottom to 6. The pieces are smaller, so more fit. How many?"},
                    {"title": "5. Draw it", "caption": "Draw 4 bars cut into thirds in your journal and circle the groups of 2."},
                ],
            },
        },
        "atlasLessons": [
            {
                "title": "Chapter 2 · Lining up the repeating digits",
                "question": "Why does multiplying 0.3636… by 100 help to turn it into a fraction?",
                "explanation": "Multiplying by 100 moves every digit two places to the left. "
                               "The digits after the point still read 3636…, as they did before. "
                               "Subtracting the original number removes them all and leaves the whole number 36.",
                "limits": "The result: 99 × the number = 36, so the number is 4/11",
            },
            {
                "title": "Chapter 2 · How many pieces fit?",
                "question": "Why is dividing by 2/3 the same as multiplying by 3/2?",
                "explanation": "Cutting each whole into thirds multiplies the count by 3. "
                               "Grouping the thirds in twos divides it by 2. Doing both is multiplying by 3/2.",
                "limits": "The rule: 4 ÷ 2/3 = 4 × 3/2 = 6",
            },
            {
                "title": "Chapter 2 · The decimal that is secretly 1",
                "question": "What fraction is 0.999…?",
                "explanation": "Ten lots of it are 9.999…, and one lot is 0.999…, with the same tail. "
                               "Take one lot from ten lots and nine lots are exactly 9. So the number is 9/9, which is 1. "
                               "0.999… and 1 are two names for one number.",
                "limits": "The result: 0.999… = 1",
            },
        ],
        "visualMathTips": {},
        "schoolTopics": {
            "6.1": "Multiply decimals as whole numbers, then count the decimal places back in. "
                   "To divide by a decimal, first multiply both numbers by 10 or 100 so you divide by a whole number.",
            "6.2": "Significant figures are counted from the first digit that is not zero. "
                   "Round once, at the end of a calculation.",
            "6.3": "A fraction in simplest form gives a decimal that stops only when its denominator is built from 2s and 5s. "
                   "Otherwise the digits repeat. "
                   "To turn a recurring decimal into a fraction, multiply so the repeating tails line up, then subtract.",
            "6.4": "Write both mixed numbers as improper fractions. Give them a common denominator, then subtract the numerators.",
            "6.5": "To multiply fractions, multiply the numerators and multiply the denominators. "
                   "To divide by a fraction, multiply by its reciprocal.",
        },
        "schoolQuestions": {
            "q-oup-ch06-sb": {
                "workedExample": "Step 1: Two digits repeat, so multiply x by 100. This gives 100x = 27.2727… with the same tail as x.\n"
                                 "Step 2: Subtract x = 0.2727… and the tails cancel. So 99x = 27.\n"
                                 "Step 3: Divide both sides by 99. So x = 27/99.\n"
                                 "Step 4: Divide the top and the bottom by 9, their highest common factor. So x = 3/11.",
                "fadedPrompt": "100x = 27.2727… and x = 0.2727…, so 99x = 27. Then x = 27/99, which in simplest form is ___.",
            },
            "q-oup-ch06-wb-focus": {
                "workedExample": "Step 1: Find the first digit that is not zero. It is the 4, so start counting there.\n"
                                 "Step 2: Count three significant figures: 4, 0 and 8. The zero between them counts.\n"
                                 "Step 3: Look at the next digit, which is 6. It is 5 or more, so the 8 rounds up to 9.\n"
                                 "Step 4: Keep the zeros at the front, because they hold the digits in place. The answer is 0.00409.",
                "fadedPrompt": "The three significant figures are 4, 0 and 8, and the next digit is 6. Rounded, the number is ___.",
            },
            "q-oup-ch06-wb-practice": {
                "workedExample": "Step 1: Write both as improper fractions. 4 1/6 = 25/6 and 1 3/4 = 7/4.\n"
                                 "Step 2: The lowest common multiple of 6 and 4 is 12, so use twelfths. 25/6 = 50/12 and 7/4 = 21/12.\n"
                                 "Step 3: Subtract the numerators. 50 − 21 = 29, so the answer is 29/12.\n"
                                 "Step 4: 24 twelfths make 2 wholes, which leaves 5 twelfths. The answer is 2 5/12.",
                "fadedPrompt": "50/12 − 21/12 = 29/12. As a mixed number, 29/12 = ___.",
            },
            "q-oup-ch06-wb-challenge": {
                "workedExample": "Step 1: Write the mixed numbers as improper fractions. 2 2/5 = 12/5 and 1 1/15 = 16/15.\n"
                                 "Step 2: To divide by 16/15, multiply by its reciprocal, 15/16. 12/5 × 15/16 = 180/80 = 9/4.\n"
                                 "Step 3: Multiply by 5/9. 9/4 × 5/9 = 45/36.\n"
                                 "Step 4: Divide the top and the bottom by 9. The answer is 5/4, which is 1 1/4.",
                "fadedPrompt": "12/5 × 15/16 = 9/4, and 9/4 × 5/9 = 45/36. In simplest form, 45/36 = ___.",
            },
        },
    }


def cards(k):
    """The concept cards this chapter teaches that stand on other cards. Fraction and Decimal place are in bedrock.py."""
    return {
        "numerator-denominator": {
            "name": "Numerator and denominator",
            "aliases": ["numerator", "numerators", "denominator", "denominators"],
            "oneSentence": "The top and bottom numbers of a fraction: how many parts you have, and how many make a whole.",
            "picture": "In 3/8 of a pizza, the 8 is the denominator. It tells you the pizza was cut into 8 equal slices. "
                       "The 3 is the numerator. It tells you that you have 3 of them.",
            "steps": [
                "Read the bottom number first. It names the size of the piece: halves, thirds, quarters, eighths.",
                "Then read the top number. It counts the pieces.",
                "A bigger denominator means smaller pieces. 1/8 is less than 1/4.",
            ],
            "workedExample": "Which is bigger, 3/8 or 5/8? The denominators match, so the pieces are the same size. "
                             "5 pieces is more than 3 pieces, so 5/8 is bigger.",
            "check": {
                "prompt": "What is the denominator of 7/12?",
                "answer": "12",
                "answerKey": k.one(k.num("12"), accepts=["12", "= 12"], rejects=["7", "19", "7/12"]),
            },
            "mixUp": {
                "name": "which one is which",
                "how": "Denominator starts with d, like down. It is the number down below, and it names the pieces.",
            },
            "standsOn": ["fraction"],
        },
        "equivalent-fractions": {
            "name": "Equivalent fractions",
            "aliases": ["equivalent fractions", "equivalent fraction"],
            "oneSentence": "Fractions that look different but name the same amount.",
            "picture": "Half a pizza is 1 slice out of 2, or 2 out of 4, or 4 out of 8. "
                       "The slices get smaller and you get more of them. The amount of pizza is the same.",
            "steps": [
                "Multiply the numerator and the denominator by the same number. 1/2 = 2/4 = 3/6.",
                "Or divide both by the same number. 6/8 = 3/4.",
                "To test two fractions, multiply across. 2/3 and 8/12 match because 2 × 12 = 3 × 8.",
            ],
            "workedExample": "Fill the gap: 3/5 = ?/20. The denominator went from 5 to 20, which is × 4. "
                             "Do the same to the numerator. 3 × 4 = 12, so 3/5 = 12/20.",
            "check": {
                "prompt": "2/3 is the same amount as how many twelfths?",
                "answer": "8",
                "answerKey": k.one(k.num("8"), accepts=["8", "= 8", "8 twelfths"], rejects=["4", "11", "6"]),
            },
            "mixUp": {
                "name": "adding the same number to both parts",
                "how": "1/2 and 2/3 are not equivalent. Adding 1 to the top and the bottom changes the amount. "
                       "Only multiplying or dividing keeps it.",
            },
            "standsOn": ["fraction", "numerator-denominator"],
        },
        "simplest-form": {
            "name": "Simplest form",
            "aliases": ["simplest form", "simplest terms"],
            "oneSentence": "The version of a fraction with the smallest numbers, where top and bottom share no factor except 1.",
            "picture": "12 of the 16 panels of a wall are painted. Group the panels in fours and it is 3 groups out of 4. "
                       "3/4 says the same thing with smaller numbers.",
            "steps": [
                "Find the highest common factor of the numerator and the denominator. For 12/16 it is 4.",
                "Divide both by it. 12 ÷ 4 = 3 and 16 ÷ 4 = 4.",
                "Check that the new numbers share no factor except 1. 3/4 is in simplest form.",
            ],
            "bigNumbers": "If you cannot see the HCF, divide by any common factor and repeat. 84/126 = 42/63 = 6/9 = 2/3.",
            "workedExample": "Write 20/30 in simplest form. The HCF of 20 and 30 is 10. 20 ÷ 10 = 2 and 30 ÷ 10 = 3. "
                             "So 20/30 = 2/3.",
            "check": {
                "prompt": "Write 15/25 in simplest form.",
                "answer": "3/5",
                "answerKey": k.one(k.num("3/5", simplest=True), accepts=["3/5", "= 3/5"], rejects=["15/25", "5/3", "1/5"]),
            },
            "mixUp": {
                "name": "a smaller amount",
                "how": "3/4 has smaller numbers than 12/16, but it is the same amount. Simplifying changes the name, not the size.",
            },
            "standsOn": ["equivalent-fractions", "hcf"],
        },
        "common-denominator": {
            "name": "Common denominator",
            "aliases": ["common denominator", "common denominators", "lowest common denominator"],
            "oneSentence": "A denominator that two or more fractions can share, so their pieces are the same size.",
            "picture": "You cannot add half a paratha to a third of a paratha by counting pieces. Cut both into sixths. "
                       "Now it is 3 sixths and 2 sixths, which is 5 sixths.",
            "steps": [
                "Find the lowest common multiple of the denominators. For 1/2 and 1/3 it is 6.",
                "Change each fraction into an equivalent fraction with that denominator. 1/2 = 3/6 and 1/3 = 2/6.",
                "Add or subtract the numerators and keep the denominator. 3/6 + 2/6 = 5/6.",
            ],
            "workedExample": "Work out 3/4 − 1/6. The LCM of 4 and 6 is 12. 3/4 = 9/12 and 1/6 = 2/12. "
                             "9 − 2 = 7, so the answer is 7/12.",
            "check": {
                "prompt": "Work out 1/4 + 1/6 as a fraction in simplest form.",
                "answer": "5/12",
                "answerKey": k.one(k.num("5/12", simplest=True), accepts=["5/12", "= 5/12"], rejects=["2/10", "1/5", "10/24"]),
            },
            "mixUp": {
                "name": "adding the denominators",
                "how": "1/2 + 1/3 is not 2/5. 2/5 is less than 1/2, and adding a third cannot make a half smaller.",
            },
            "standsOn": ["equivalent-fractions", "lcm"],
        },
        "improper-fraction": {
            "name": "Improper fraction",
            "aliases": ["improper fraction", "improper fractions", "top-heavy fraction", "top-heavy fractions"],
            "oneSentence": "A fraction whose numerator is at least as big as its denominator, so it is worth 1 whole or more.",
            "picture": "Seven friends each eat half a dosa. That is 7 halves, written 7/2. "
                       "Seven halves make 3 whole dosas and 1 half more.",
            "steps": [
                "To turn a mixed number into an improper fraction, multiply the whole number by the denominator.",
                "Add the numerator. For 3 1/2: 3 × 2 = 6, and 6 + 1 = 7.",
                "Write the total over the same denominator: 7/2.",
            ],
            "workedExample": "Write 2 3/5 as an improper fraction. 2 wholes are 2 × 5 = 10 fifths. "
                             "Add the 3 fifths to get 13 fifths. So 2 3/5 = 13/5.",
            "check": {
                "prompt": "Write 4 2/3 as an improper fraction.",
                "answer": "14/3",
                "answerKey": k.one(k.forms("14/3"), accepts=["14/3", "= 14/3"], rejects=["4 2/3", "12/3", "8/3", "42/3"]),
            },
            "mixUp": {
                "with": "mixed-number",
                "how": "7/2 and 3 1/2 are the same amount. The improper fraction is easier to calculate with. "
                       "The mixed number is easier to picture.",
            },
            "standsOn": ["fraction", "numerator-denominator"],
        },
        "mixed-number": {
            "name": "Mixed number",
            "aliases": ["mixed number", "mixed numbers"],
            "oneSentence": "A whole number and a fraction written side by side, like 2 1/2.",
            "picture": "A recipe asks for 2 1/2 cups of rice. That is 2 full cups and half a cup more. "
                       "The whole number and the fraction are added together.",
            "steps": [
                "To turn an improper fraction into a mixed number, divide the numerator by the denominator.",
                "The whole-number answer is the whole part. For 17/5: 17 ÷ 5 = 3, with 2 left over.",
                "The remainder goes over the same denominator: 3 2/5.",
            ],
            "workedExample": "Write 23/4 as a mixed number. 23 ÷ 4 = 5, with 3 left over. So 23/4 = 5 3/4. "
                             "Check: 5 × 4 + 3 = 23.",
            "check": {
                "prompt": "Write 11/3 as a mixed number.",
                "answer": "3 2/3",
                "answerKey": k.one(k.forms("3 2/3", "3 and 2/3"), accepts=["3 2/3", "3 and 2/3", "= 3 2/3"],
                                   rejects=["11/3", "3 1/3", "2 2/3"]),
            },
            "mixUp": {
                "name": "multiplying",
                "how": "2 1/2 means 2 + 1/2, not 2 × 1/2. A mixed number is the one place where side by side means add.",
            },
            "standsOn": ["improper-fraction"],
        },
        "reciprocal": {
            "name": "Reciprocal",
            "aliases": ["reciprocal", "reciprocals"],
            "oneSentence": "What you get when you turn a fraction upside down.",
            "picture": "A glass holds 1/4 of a litre, so 4 glasses fill 1 litre. 1/4 and 4 are reciprocals. "
                       "Multiply any number by its reciprocal and you get exactly 1.",
            "steps": [
                "Write the number as a fraction. A whole number like 5 is 5/1.",
                "Swap the numerator and the denominator. The reciprocal of 5/1 is 1/5.",
                "Check by multiplying. 5 × 1/5 = 1.",
                "To divide by a fraction, multiply by its reciprocal. 6 ÷ 3/4 = 6 × 4/3 = 8.",
            ],
            "workedExample": "Work out 2/3 ÷ 4/5. The reciprocal of 4/5 is 5/4. 2/3 × 5/4 = 10/12. "
                             "In simplest form that is 5/6.",
            "check": {
                "prompt": "What is the reciprocal of 2/7?",
                "answer": "7/2",
                "answerKey": k.one(k.num("7/2"), accepts=["7/2", "3 1/2", "3.5"], rejects=["2/7", "-2/7", "5/7"]),
            },
            "mixUp": {
                "with": "negative-number",
                "how": "The reciprocal of 2 is 1/2, not −2. A reciprocal turns a number upside down. "
                       "A minus sign turns it to face the other way.",
            },
            "standsOn": ["fraction"],
        },
        "significant-figures": {
            "name": "Significant figures",
            "short": "s.f.",
            "aliases": ["significant figures", "significant figure", "s.f."],
            "oneSentence": "The digits that carry the size of a number, counted from the first digit that is not zero.",
            "picture": "A stadium holds 32,846 people. A reporter writes 33,000. "
                       "She kept 2 significant figures, the digits that matter most, and rounded the rest.",
            "steps": [
                "Find the first digit that is not zero. That is the first significant figure.",
                "Count along as many figures as you need. Zeros between them or after them count.",
                "Look at the next digit. If it is 5 or more, round the last kept digit up.",
                "Fill with zeros to keep the size. 32,846 becomes 33,000, not 33.",
            ],
            "workedExample": "Round 0.006194 to 2 significant figures. The first significant figure is the 6. "
                             "The two figures are 6 and 1. The next digit is 9, so the 1 rounds up. The answer is 0.0062.",
            "check": {
                "prompt": "Round 47,360 to 2 significant figures.",
                "answer": "47,000",
                "answerKey": k.one(k.num("47000"), accepts=["47,000", "47000"], rejects=["47", "48,000", "47,400"]),
            },
            "mixUp": {
                "with": "decimal-place",
                "how": "0.004718 to 2 decimal places is 0.00. To 2 significant figures it is 0.0047. "
                       "Significant figures keep a small number alive.",
            },
            "standsOn": ["decimal-place"],
            "footing": "rounding",
        },
        "terminating-decimal": {
            "name": "Terminating decimal",
            "aliases": ["terminating decimal", "terminating decimals"],
            "oneSentence": "A decimal that stops after a certain number of digits.",
            "picture": "₹1 shared among 4 friends is 25 paise each, or ₹0.25. "
                       "The division finishes with nothing left over, so the decimal stops.",
            "steps": [
                "Write the fraction in simplest form.",
                "Break the denominator into prime factors.",
                "If the only primes are 2s and 5s, the decimal stops. 3/40 stops because 40 = 2 × 2 × 2 × 5.",
                "If any other prime appears, the digits repeat for ever. 1/6 does, because 6 = 2 × 3.",
            ],
            "workedExample": "Does 7/20 give a terminating decimal? 20 = 2 × 2 × 5, so yes. "
                             "Make the denominator 100: 7/20 = 35/100 = 0.35.",
            "check": {
                "prompt": "Which of these gives a terminating decimal: 1/3, 1/8 or 1/9?",
                "answer": "1/8",
                "answerKey": k.one(k.num("1/8"), accepts=["1/8", "0.125"], rejects=["1/3", "1/9"]),
            },
            "mixUp": {
                "with": "recurring-decimal",
                "how": "0.25 stops. 0.2525… goes on for ever. The dots, or a dot over the digits, tell you which one you have.",
            },
            "standsOn": ["decimal-place", "fraction"],
        },
        "recurring-decimal": {
            "name": "Recurring decimal",
            "aliases": ["recurring decimal", "recurring decimals", "recurring", "repeating decimal", "repeating decimals"],
            "oneSentence": "A decimal whose digits repeat in the same pattern for ever.",
            "picture": "Share ₹1 among 3 friends. Each gets 33 paise and 1 paisa is left. "
                       "Share that paisa and the same thing happens again. "
                       "On a calculator, 1 ÷ 3 = 0.3333333, and the 3s never stop.",
            "steps": [
                "Count how many digits repeat. In 0.2424… two digits repeat.",
                "Multiply by 10 for one repeating digit, by 100 for two, by 1,000 for three.",
                "Subtract the original number, so the repeating parts cancel. 24.2424… − 0.2424… = 24.",
                "You took 1 lot from 100 lots, so 99 lots are 24. The number is 24/99 = 8/33.",
            ],
            "workedExample": "Write 0.777… as a fraction. One digit repeats, so multiply by 10 to get 7.777… "
                             "Subtract 0.777… and 9 lots are exactly 7. The number is 7/9.",
            "check": {
                "prompt": "Write 0.111… as a fraction.",
                "answer": "1/9",
                "answerKey": k.one(k.num("1/9", simplest=True), accepts=["1/9", "= 1/9"], rejects=["1/10", "11/100", "1/11"]),
            },
            "mixUp": {
                "with": "irrational-number",
                "how": "A recurring decimal goes on for ever but repeats, so it is a fraction. "
                       "An irrational number goes on for ever and never repeats.",
            },
            "standsOn": ["decimal-place", "fraction"],
        },
    }


def sums():
    """Every sum chapter 2, its cards and its school unit text state, recomputed. test_book_maths.py checks computed == stated."""
    third, quarter = Fraction(1, 3), Fraction(1, 4)
    ribbon, cut = 3 + quarter, 1 + 2 * third
    return [
        # Skill card
        ("5 1/2 − 2 2/3", mixed(5 + Fraction(1, 2) - (2 + 2 * third)), "2 5/6"),
        ("9 ÷ 3/5", 9 / Fraction(3, 5), 15),
        ("0.4545…", recurring("45"), Fraction(5, 11)),
        # Bridge, widgets and Atlas lessons
        ("0.3636…", recurring("36"), Fraction(4, 11)),
        ("36/99", Fraction(36, 99), Fraction(4, 11)),
        ("100 lots take away 1 lot", 100 - 1, 99),
        ("100 × 0.3636… − 0.3636…", 100 * recurring("36") - recurring("36"), 36),
        ("0.1818…", (recurring("18"), Fraction(18, 99)), (Fraction(2, 11), Fraction(2, 11))),
        ("2 ÷ 11 starts 0.1818", decimal_digits(2, 11, 4), "1818"),
        ("4 ÷ 2/3", 4 / Fraction(2, 3), 6),
        ("4 × 3/2", 4 * Fraction(3, 2), 6),
        ("4 × 3 ÷ 2", Fraction(4 * 3, 2), 6),
        ("4 wholes in thirds", 4 * 3, 12),
        ("4 ÷ 2/6: more pieces fit", 4 / Fraction(2, 6) > 6, True),
        ("0.999…", recurring("9"), 1),
        ("9/9", Fraction(9, 9), 1),
        # 2.1 One amount, many names
        ("2/4 and 4/8", (Fraction(2, 4), Fraction(4, 8)), (Fraction(1, 2), Fraction(1, 2))),
        ("2/2", Fraction(2, 2), 1),
        ("HCF of 18 and 24", gcd(18, 24), 6),
        ("18 ÷ 6 and 24 ÷ 6", (18 // 6, 24 // 6), (3, 4)),
        ("18/24", Fraction(18, 24), Fraction(3, 4)),
        ("3 and 4 share no factor except 1", gcd(3, 4), 1),
        ("adding 1 to the top and bottom of 1/2", Fraction(1 + 1, 2 + 1), Fraction(2, 3)),
        ("a half is not two thirds", Fraction(1, 2) != Fraction(2, 3), True),
        ("24/36", Fraction(24, 36), Fraction(2, 3)),
        # 2.2 Taking away pieces of different sizes
        ("a quarter and a third in twelfths", (quarter * 12, third * 12), (3, 4)),
        ("3 1/4 in quarters", ribbon / quarter, 13),
        ("1 2/3 in thirds", cut / third, 5),
        ("13 quarters and 5 thirds in twelfths", (ribbon * 12, cut * 12), (39, 20)),
        ("LCM of 4 and 3", lcm(4, 3), 12),
        ("39 − 20", 39 - 20, 19),
        ("19/12 as a mixed number", mixed(Fraction(19, 12)), "1 7/12"),
        ("tops and bottoms taken away separately", Fraction(3 - 1, 4 - 3), 2),
        ("3/4 − 1/3 is less than 1 whole", Fraction(3, 4) - third < 1, True),
        ("2 1/2 − 1 2/3", Fraction(5, 2) - Fraction(5, 3), Fraction(5, 6)),
        # 2.3 Why you flip to divide
        ("12 thirds in groups of 2", 12 // 2, 6),
        ("reciprocal of 2/3", 1 / Fraction(2, 3), Fraction(3, 2)),
        ("1/2 × 3/4", Fraction(1, 2) * Fraction(3, 4), Fraction(3, 8)),
        ("1 1/2 as an improper fraction", 1 + Fraction(1, 2), Fraction(3, 2)),
        ("reciprocal of 3/8", 1 / Fraction(3, 8), Fraction(8, 3)),
        ("3 × 8 over 2 × 3", (3 * 8, 2 * 3), (24, 6)),
        ("24/6", Fraction(24, 6), 4),
        ("1 1/2 ÷ 3/8", Fraction(3, 2) / Fraction(3, 8), 4),
        ("four pieces of 3/8", 4 * Fraction(3, 8), Fraction(12, 8)),
        ("12/8 is 1 1/2", Fraction(12, 8), Fraction(3, 2)),
        ("4 ÷ 2/3 is bigger than 4", 4 / Fraction(2, 3) > 4, True),
        # 2.4 Where the decimal point goes
        ("3 × 2", 3 * 2, 6),
        ("0.3 × 0.2", Fraction("0.3") * Fraction("0.2"), Fraction("0.06")),
        ("0.06 is ten times smaller than 0.6", Fraction("0.6") / Fraction("0.06"), 10),
        ("a 10 by 10 grid", 10 * 10, 100),
        ("3/10 × 2/10", Fraction(3, 10) * Fraction(2, 10), Fraction(6, 100)),
        ("4.5 × 100 and 0.15 × 100", (Fraction("4.5") * 100, Fraction("0.15") * 100), (450, 15)),
        ("45 ÷ 15", 45 // 15, 3),
        ("450 ÷ 15", 450 // 15, 30),
        ("4.5 ÷ 0.15", Fraction("4.5") / Fraction("0.15"), 30),
        ("30 × 0.15", 30 * Fraction("0.15"), Fraction("4.5")),
        ("8 × 0.5", 8 * Fraction("0.5"), 4),
        ("8 ÷ 0.5", 8 / Fraction("0.5"), 16),
        ("0.4 × 0.06", Fraction("0.4") * Fraction("0.06"), Fraction("0.024")),
        # 2.5 How many digits to keep
        ("32,846 to the nearest thousand", round(32846, -3), 33000),
        ("halfway between 32,000 and 33,000", (32000 + 33000) // 2, 32500),
        ("32,846 is past halfway", 32846 >= 32500, True),
        ("0.004718 kg in grams", Fraction("0.004718") * 1000, Fraction("4.718")),
        ("32,846 to 2 significant figures", round_sf("32846", 2), 33000),
        ("0.004718 to 2 significant figures", round_sf("0.004718", 2), Fraction("0.0047")),
        ("0.03064 to 3 significant figures", round_sf("0.03064", 3), Fraction("0.0306")),
        ("the digit after 3, 0 and 6 is 4", "0.03064"[6], "4"),
        ("0.0306 to 2 decimal places", round_dp("0.0306", 2), Fraction("0.03")),
        ("0.05093 to 2 significant figures", round_sf("0.05093", 2), Fraction("0.051")),
        # 2.6 Decimals that never end
        ("₹1 among 4 friends", Fraction(1, 4), Fraction("0.25")),
        ("1 ÷ 3 on a calculator", "0." + decimal_digits(1, 3, 7), "0.3333333"),
        ("10 tenths among 3", divmod(10, 3), (3, 1)),
        ("1 ÷ 7", "0." + decimal_digits(1, 7, 12), "0.142857142857"),
        ("remainders when dividing by 7", sorted({n % 7 for n in range(1, 100) if n % 7}), [1, 2, 3, 4, 5, 6]),
        ("10, 100 and 1,000 are built from 2 and 5", {p for n in (10, 100, 1000) for p in prime_factors(n)}, {2, 5}),
        ("1/4", Fraction(1, 4), Fraction(25, 100)),
        ("1/4 stops and 1/3 does not", (terminates(Fraction(1, 4)), terminates(Fraction(1, 3))), (True, False)),
        ("no power of 10 is a multiple of 3", [10 ** n % 3 for n in range(1, 7)], [1] * 6),
        ("0.333…", recurring("3"), Fraction(1, 3)),
        ("ten lots take away one lot of 0.333…", 10 * recurring("3") - recurring("3"), 3),
        ("3/9", Fraction(3, 9), Fraction(1, 3)),
        ("0.3 is 3/10", Fraction("0.3"), Fraction(3, 10)),
        ("1/3 is a little more than 0.3", Fraction(1, 3) > Fraction("0.3"), True),
        ("0.1515…", recurring("15"), Fraction(5, 33)),
        # Who is right? Half-litre bottles
        ("half of 6", 6 * Fraction(1, 2), 3),
        ("3 bottles of half a litre", 3 * Fraction(1, 2), Fraction(3, 2)),
        ("litres not bottled", 6 - Fraction(3, 2), Fraction(9, 2)),
        ("6 ÷ 1/2", 6 / Fraction(1, 2), 12),
        ("6 × 2", 6 * 2, 12),
        ("12 bottles of half a litre", 12 * Fraction(1, 2), 6),
        ("one litre fills 2 bottles", 1 / Fraction(1, 2), 2),
        ("1/6 × 1/2", Fraction(1, 6) * Fraction(1, 2), Fraction(1, 12)),
        ("the callout: 3 ÷ 2/4", 3 / Fraction(2, 4), 6),
        # Cards: numerator-denominator, equivalent-fractions
        ("1/8 is less than 1/4", Fraction(1, 8) < Fraction(1, 4), True),
        ("5/8 is bigger than 3/8", Fraction(5, 8) > Fraction(3, 8), True),
        ("1/2 = 2/4 = 3/6", {Fraction(1, 2), Fraction(2, 4), Fraction(3, 6)}, {Fraction(1, 2)}),
        ("6/8", Fraction(6, 8), Fraction(3, 4)),
        ("2 × 12 and 3 × 8", (2 * 12, 3 * 8), (24, 24)),
        ("5 to 20 is × 4", 20 // 5, 4),
        ("3/5 = 12/20", (3 * 4, Fraction(3, 5)), (12, Fraction(12, 20))),
        ("2/3 in twelfths", Fraction(2, 3) * 12, 8),
        # Cards: simplest-form
        ("HCF of 12 and 16", gcd(12, 16), 4),
        ("12/16", (12 // 4, 16 // 4, Fraction(12, 16)), (3, 4, Fraction(3, 4))),
        ("84/126 = 42/63 = 6/9 = 2/3", {Fraction(84, 126), Fraction(42, 63), Fraction(6, 9)}, {Fraction(2, 3)}),
        ("HCF of 20 and 30", gcd(20, 30), 10),
        ("20/30", (20 // 10, 30 // 10, Fraction(20, 30)), (2, 3, Fraction(2, 3))),
        ("15/25", Fraction(15, 25), Fraction(3, 5)),
        # Cards: common-denominator
        ("LCM of 2 and 3", lcm(2, 3), 6),
        ("1/2 and 1/3 in sixths", (Fraction(1, 2) * 6, Fraction(1, 3) * 6), (3, 2)),
        ("1/2 + 1/3", Fraction(1, 2) + Fraction(1, 3), Fraction(5, 6)),
        ("LCM of 4 and 6", lcm(4, 6), 12),
        ("3/4 and 1/6 in twelfths", (Fraction(3, 4) * 12, Fraction(1, 6) * 12), (9, 2)),
        ("3/4 − 1/6", Fraction(3, 4) - Fraction(1, 6), Fraction(7, 12)),
        ("1/4 + 1/6", Fraction(1, 4) + Fraction(1, 6), Fraction(5, 12)),
        ("2/5 is less than 1/2", Fraction(2, 5) < Fraction(1, 2), True),
        # Cards: improper-fraction, mixed-number
        ("7 halves", mixed(Fraction(7, 2)), "3 1/2"),
        ("3 × 2 + 1", 3 * 2 + 1, 7),
        ("2 3/5", (2 * 5, 2 * 5 + 3, 2 + Fraction(3, 5)), (10, 13, Fraction(13, 5))),
        ("4 2/3", 4 + Fraction(2, 3), Fraction(14, 3)),
        ("17 ÷ 5", (divmod(17, 5), mixed(Fraction(17, 5))), ((3, 2), "3 2/5")),
        ("23 ÷ 4", (divmod(23, 4), mixed(Fraction(23, 4))), ((5, 3), "5 3/4")),
        ("5 × 4 + 3", 5 * 4 + 3, 23),
        ("11/3 as a mixed number", mixed(Fraction(11, 3)), "3 2/3"),
        # Cards: reciprocal
        ("4 glasses of 1/4 litre", 4 * Fraction(1, 4), 1),
        ("5 × 1/5", 5 * Fraction(1, 5), 1),
        ("6 × 4/3", 6 * Fraction(4, 3), 8),
        ("2/3 × 5/4", (2 * 5, 3 * 4, Fraction(2, 3) / Fraction(4, 5)), (10, 12, Fraction(5, 6))),
        ("reciprocal of 2/7", 1 / Fraction(2, 7), Fraction(7, 2)),
        # Cards: significant-figures
        ("0.006194 to 2 significant figures", round_sf("0.006194", 2), Fraction("0.0062")),
        ("47,360 to 2 significant figures", round_sf("47360", 2), 47000),
        ("0.004718 to 2 decimal places", round_dp("0.004718", 2), 0),
        # Cards: terminating-decimal, recurring-decimal
        ("40 as primes", prime_factors(40), (2, 2, 2, 5)),
        ("3/40 stops and 1/6 does not", (terminates(Fraction(3, 40)), terminates(Fraction(1, 6))), (True, False)),
        ("20 as primes", prime_factors(20), (2, 2, 5)),
        ("7/20", (Fraction(7, 20), Fraction(35, 100)), (Fraction("0.35"), Fraction("0.35"))),
        ("only 1/8 of 1/3, 1/8, 1/9 stops", [d for d in (3, 8, 9) if terminates(Fraction(1, d))], [8]),
        ("1 rupee among 3 friends, in paise", divmod(100, 3), (33, 1)),
        ("0.2424…", (100 * recurring("24") - recurring("24"), recurring("24")), (24, Fraction(8, 33))),
        ("24/99", Fraction(24, 99), Fraction(8, 33)),
        ("0.777…", (10 * recurring("7") - recurring("7"), recurring("7")), (7, Fraction(7, 9))),
        ("0.111…", recurring("1"), Fraction(1, 9)),
        # School unit 6: worked examples
        ("0.2727…", (100 * recurring("27") - recurring("27"), recurring("27")), (27, Fraction(3, 11))),
        ("27/99 and its HCF", (gcd(27, 99), Fraction(27, 99)), (9, Fraction(3, 11))),
        ("0.0040862 to 3 significant figures", round_sf("0.0040862", 3), Fraction("0.00409")),
        ("the digit after 4, 0 and 8 is 6", "0.0040862"[7], "6"),
        ("4 1/6 and 1 3/4", (4 + Fraction(1, 6), 1 + Fraction(3, 4)), (Fraction(25, 6), Fraction(7, 4))),
        ("LCM of 6 and 4", lcm(6, 4), 12),
        ("25/6 and 7/4 in twelfths", (Fraction(25, 6) * 12, Fraction(7, 4) * 12), (50, 21)),
        ("50 − 21", 50 - 21, 29),
        ("29/12 as a mixed number", mixed(Fraction(29, 12)), "2 5/12"),
        ("2 2/5 and 1 1/15", (2 + Fraction(2, 5), 1 + Fraction(1, 15)), (Fraction(12, 5), Fraction(16, 15))),
        ("12/5 × 15/16", (12 * 15, 5 * 16, Fraction(12, 5) * Fraction(15, 16)), (180, 80, Fraction(9, 4))),
        ("9/4 × 5/9", (9 * 5, 4 * 9, Fraction(9, 4) * Fraction(5, 9)), (45, 36, Fraction(5, 4))),
        ("45/36 and its HCF", (gcd(45, 36), mixed(Fraction(45, 36))), (9, "1 1/4")),
    ]


def answers():
    """Chapter 2's turn answers and its cards' check answers, computed."""
    return {
        "ch02-s1-turn": Fraction(24, 36),
        "ch02-s2-turn": Fraction(5, 2) - Fraction(5, 3),
        "ch02-s3-turn": 6 / Fraction(3, 4),
        "ch02-s4-turn": Fraction("0.4") * Fraction("0.06"),
        "ch02-s5-turn": round_sf("0.05093", 2),
        "ch02-s6-turn": recurring("15"),
        "numerator-denominator-check": Fraction(7, 12).denominator,
        "equivalent-fractions-check": Fraction(2, 3) * 12,
        "simplest-form-check": Fraction(15, 25),
        "common-denominator-check": Fraction(1, 4) + Fraction(1, 6),
        "improper-fraction-check": 4 + Fraction(2, 3),
        "mixed-number-check": mixed(Fraction(11, 3)),
        "reciprocal-check": 1 / Fraction(2, 7),
        "significant-figures-check": round_sf("47360", 2),
        "terminating-decimal-check": next(Fraction(1, d) for d in (3, 8, 9) if terminates(Fraction(1, d))),
        "recurring-decimal-check": recurring("1"),
    }
