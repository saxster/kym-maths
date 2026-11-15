"""
Chapter 4, written by hand to docs/CONTENT_BRIEF.md. It carries school unit 2.

Each section teaches one idea in nine steps, in this order: question, idea, picture, reason, name,
example, mistake, turn, sayBack. A section's `teaches` lists the concept cards whose names first
appear in its `name` step. `build(k)` returns the chapter and `cards(k)` its concept cards; both take the
exporter's answer-key helpers. Every section starts from rupees, tiles or a photo before any letter appears.

The word "term" means a part of an expression here. Chapter 6 uses it for a number in a list only after
its own card. `schoolTopics` and `schoolQuestions` rewrite the topic summaries, worked examples and faded
prompts of school unit 2. The answer keys and stuck sheets stay in the exporter.
"""

from itertools import product

from book.arithmetic import gcd

VALUES = range(-6, 7)


def same(lhs, rhs, letters=1):
    """True when two expressions, written as functions, agree for every whole number from −6 to 6."""
    return all(lhs(*point) == rhs(*point) for point in product(VALUES, repeat=letters))


def written(*terms):
    """An expression as the marker reads it, from (coefficient, letters) pairs: (4, "x"), (−3, "") → "4x-3"."""
    out = ""
    for coefficient, letters in terms:
        if coefficient == 0:
            continue
        sign = "-" if coefficient < 0 else ("+" if out else "")
        size = abs(coefficient)
        out += sign + (str(size) if size != 1 or not letters else "") + letters
    return out


def build(k):
    return {
        "number": 4,
        "title": "Brackets and factorising",
        "subtitle": "School book chapter 2 · Letters for numbers, multiplying out brackets, and putting them back",
        "hookSummary": "A square tile of side x grows by 3 cm along each edge. Why is its new area not x² + 9?",
        "beyondSchoolBook": False,
        "skillCard": {
            "skill": "Writing, multiplying out and factorising expressions",
            "sheCan": {
                "prompt": "With no calculator: multiply out 3(2x − 5). Factorise 12y + 18. Work out 41² − 39².",
                "answer": "6x − 15. 6(2y + 3). 160.",
            },
            "whyItMatters": "A letter lets one line of working stand for every case at once. "
                            "Moving between brackets and separate terms is the main tool in all the algebra that follows.",
            "standsOn": [
                "Chapter 1: the HCF, and powers such as 3² and x²",
                "Multiplying and adding negative numbers",
                "The area of a rectangle is its length × its width",
            ],
            "unlocks": [
                "Chapter 5: finding the number a letter stands for",
                "Chapter 6: one rule that gives any number in a list",
                "Chapter 7: drawing the straight line for a rule such as y = 2x + 1",
            ],
        },
        "intuitionToFormula": {
            "concreteAction": "Set the side to 4, the first number to 3 and the second number to 2. "
                              "The rectangle is 7 wide and 6 tall, and it is cut into four pieces.",
            "ahaInvariant": "The pieces hold 16, 12, 8 and 6, which add up to 42, and 7 × 6 = 42. "
                            "Write x for the side and the pieces are x², 3x, 2x and 6, whatever x is.",
            "formulaDisplay": "a(b + c) = ab + ac,   (x + a)(x + b) = x² + (a + b)x + ab,   a² − b² = (a − b)(a + b)",
            "termMappings": [
                {"symbol": "x²", "visualPart": "The red square", "colorRole": "red",
                 "meaning": "The square of side x"},
                {"symbol": "ax and bx", "visualPart": "The two blue strips", "colorRole": "blue",
                 "meaning": "The strips of width a and height b along the square's sides"},
                {"symbol": "ab", "visualPart": "The amber corner", "colorRole": "amber",
                 "meaning": "The small corner, a wide and b tall"},
                {"symbol": "(a + b)x", "visualPart": "The green line", "colorRole": "green",
                 "meaning": "The two strips added together"},
            ],
            "atlasFigureRef": "maths/ch04-algebra-tiles/index.html",
        },
        "sections": [
            {
                "heading": "4.1 Letters for numbers",
                "teaches": ["variable", "expression"],
                "steps": [
                    {"kind": "question",
                     "text": "At the school canteen a samosa costs ₹15 and a cup of chai costs ₹10. "
                             "Kym buys 3 samosas and 2 chais, and Aarav buys 5 samosas and 1 chai. "
                             "Is there one rule that prices every order?"},
                    {"kind": "idea",
                     "text": "Every bill is worked out the same way. Kym pays 3 × ₹15 + 2 × ₹10 = ₹65. "
                             "Aarav pays 5 × ₹15 + 1 × ₹10 = ₹85. Only the two counts change from one order to the next."},
                    {"kind": "picture",
                     "text": "Make a table with a column for samosas, a column for chais and a column for the bill. "
                             "Each row is one order. The ₹15 and the ₹10 sit in every row. "
                             "The counts are the only boxes that change."},
                    {"kind": "reason",
                     "text": "Why use a letter? Write s for the number of samosas and c for the number of chais. "
                             "Then every bill is 15 × s + 10 × c rupees. "
                             "One line of maths now stands for every row of the table, even orders nobody has placed yet."},
                    {"kind": "name",
                     "text": "A letter that stands for a number that can change is called a variable. Here s and c are variables. "
                             "Numbers, variables and signs joined into a rule, such as 15s + 10c, make an expression. "
                             "We write 15s for 15 × s and leave out the × sign. An expression has no = sign."},
                    {"kind": "example",
                     "text": "Pens cost ₹12 each and notebooks cost ₹30 each. "
                             "An order of p pens and n notebooks costs 12p + 30n rupees. "
                             "For 4 pens and 2 notebooks, that is 12 × 4 + 30 × 2 = 48 + 60 = ₹108."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to read 15s as two digits side by side, the way 15 and 2 make 152. "
                             "In algebra, a number written next to a letter is multiplied by it. If s = 2, then 15s is 30. "
                             "A second trap is to think s means samosa. It means the number of samosas."},
                    {"kind": "turn",
                     "text": "A bus ticket costs ₹20 for an adult and ₹10 for a child. "
                             "Write an expression for the cost, in rupees, of a adults and k children.",
                     "answer": "20a + 10k",
                     "answerKey": k.one(k.forms("20a+10k", "10k+20a"), accepts=["20a + 10k", "10k + 20a", "20a+10k"],
                                        rejects=["30ak", "20k + 10a", "20 + 10", "30"])},
                    {"kind": "sayBack",
                     "text": "A variable stands for a number that can change, and an expression is a rule built from it."},
                ],
            },
            {
                "heading": "4.2 Putting numbers in",
                "teaches": ["substitution"],
                "steps": [
                    {"kind": "question",
                     "text": "The canteen bill for s samosas and c chais is 15s + 10c rupees. "
                             "What does Meera pay for 4 samosas and 3 chais?"},
                    {"kind": "idea",
                     "text": "Put 4 where the s is and 3 where the c is. Then 15s + 10c becomes 15 × 4 + 10 × 3. "
                             "That is 60 + 30, so Meera pays ₹90."},
                    {"kind": "picture",
                     "text": "Think of each letter as an empty box. Write the bill as 15 × ( ) + 10 × ( ). "
                             "Then drop each number into its own box and work out the sum."},
                    {"kind": "reason",
                     "text": "Why keep the boxes as brackets? A letter stands for its whole number, sign and all. "
                             "So when t = −3, t² means (−3) × (−3), which is 9. "
                             "Without the bracket, −3² reads as −(3 × 3), which is −9."},
                    {"kind": "name",
                     "text": "Putting numbers in place of the letters is called substitution. "
                             "Write each number in a bracket as you substitute it. "
                             "Then work in the usual order: brackets, powers, × and ÷, and last of all + and −."},
                    {"kind": "example",
                     "text": "Find 3x² − 2y when x = −2 and y = 5. Write it with brackets: 3 × (−2)² − 2 × (5). "
                             "The power comes first: (−2)² = 4. So the value is 3 × 4 − 10 = 12 − 10 = 2."},
                    {"kind": "mistake",
                     "text": "One slip is to square only the 2 and keep the minus outside, which gives 3 × (−4) − 10 = −22. "
                             "Another is to work out 3 × (−2) first and then square it, which gives 36 − 10 = 26. "
                             "Powers come before multiplying."},
                    {"kind": "turn",
                     "text": "Find the value of a² + 4a when a = −3.",
                     "answer": "−3",
                     "answerKey": k.one(k.num("-3"), accepts=["-3", "−3", "= -3"], rejects=["21", "-21", "3", "-9"])},
                    {"kind": "sayBack",
                     "text": "Substitute each number in a bracket, then work out powers before you multiply."},
                ],
            },
            {
                "heading": "4.3 Tidying up",
                "teaches": ["term", "coefficient", "like-terms"],
                "steps": [
                    {"kind": "question",
                     "text": "A pack of pencils costs p rupees and an eraser costs e rupees. "
                             "On Monday Kym buys 3 packs and 2 erasers. On Friday she buys 4 packs and 1 eraser. "
                             "Her spending is 3p + 2e + 4p + e. Can it be written in fewer pieces?"},
                    {"kind": "idea",
                     "text": "The packs can be counted together, and so can the erasers. "
                             "3 packs and 4 packs make 7 packs, and 2 erasers and 1 eraser make 3. "
                             "So her spending is 7p + 3e."},
                    {"kind": "picture",
                     "text": "Sort the shopping into two piles. The pencil pile holds 3 packs and then 4, which is 7. "
                             "The eraser pile holds 2 and then 1, which is 3. A pack and an eraser never share a pile."},
                    {"kind": "reason",
                     "text": "Why not join 7p and 3e into 10 of something? They count different things. "
                             "Test it with prices. If p = 20 and e = 5, then 7p + 3e = 140 + 15 = 155. "
                             "But 10p would be 200 and 10e would be 50."},
                    {"kind": "name",
                     "text": "The parts of an expression joined by + or − are the terms of the expression. "
                             "In 7p + 3e − 4, the terms are 7p, 3e and −4. "
                             "The number in front of a letter is its coefficient, so the coefficient of p is 7. "
                             "Terms with exactly the same letters are like terms. Only like terms can be added together."},
                    {"kind": "example",
                     "text": "Simplify 5a + 3b − 2a + b. The a terms are 5a and −2a, which make 3a. "
                             "The b terms are 3b and b, and b on its own has coefficient 1. They make 4b. "
                             "So 5a + 3b − 2a + b = 3a + 4b."},
                    {"kind": "mistake",
                     "text": "The tempting step is to add every number and write 7ab. But a and b count different things. "
                             "Watch the signs too: the minus in −2a belongs to that term, so 2a is taken away. "
                             "And x and x² are not alike. When x = 3, x is 3 but x² is 9."},
                    {"kind": "turn",
                     "text": "Simplify 6x + 2y − x + 5y.",
                     "answer": "5x + 7y",
                     "answerKey": k.one(k.forms("5x+7y", "7y+5x"), accepts=["5x + 7y", "7y + 5x", "5x+7y"],
                                        rejects=["12xy", "7x + 7y", "5x + 3y"])},
                    {"kind": "sayBack",
                     "text": "Only like terms can be added, so collect each letter's terms on their own."},
                ],
            },
            {
                "heading": "4.4 Multiplying out a bracket",
                "teaches": ["expanding-brackets"],
                "steps": [
                    {"kind": "question",
                     "text": "A school orders 4 kits. Each kit holds a geometry box at ₹65 and a ruler at ₹15. "
                             "Kym works out 4 × 80. Aarav works out 4 × 65 + 4 × 15. Who is right?"},
                    {"kind": "idea",
                     "text": "Both are. Kym gets 4 × ₹80 = ₹320, and Aarav gets ₹260 + ₹60 = ₹320. "
                             "Four kits hold four boxes and four rulers, so you can count whole kits or count the pieces."},
                    {"kind": "picture",
                     "text": "Draw a rectangle 4 squares tall and 80 squares long. Its area is 4 × 80. "
                             "Draw a line down it 65 squares from the left. "
                             "The two pieces have areas 4 × 65 and 4 × 15, and together they fill the rectangle."},
                    {"kind": "reason",
                     "text": "The same cut works when one length is a letter. 4(x + 3) means 4 × (x + 3). "
                             "A rectangle 4 tall and x + 3 long splits into a piece 4 by x and a piece 4 by 3. "
                             "So 4(x + 3) = 4x + 12, whatever number x stands for."},
                    {"kind": "name",
                     "text": "Writing 4(x + 3) as 4x + 12 is called expanding brackets, or multiplying out. "
                             "The number outside multiplies every term inside the bracket. "
                             "It works for a minus sign too: 5(2y − 1) = 10y − 5."},
                    {"kind": "example",
                     "text": "Expand and simplify 3(2x + 5) − 2(x − 4). The first bracket gives 6x + 15. "
                             "The second has −2 outside, so it gives −2x + 8, because −2 × −4 = +8. "
                             "Collect like terms: 6x − 2x = 4x and 15 + 8 = 23. The answer is 4x + 23."},
                    {"kind": "mistake",
                     "text": "The common slip is to multiply only the first term, so 3(2x + 5) becomes 6x + 5. "
                             "The rectangle shows why that is wrong: the strip for the 5 is 3 rows tall as well. "
                             "The other slip is a sign. −2(x − 4) is −2x + 8, not −2x − 8."},
                    {"kind": "turn",
                     "text": "Expand and simplify 4(2x + 3) + 3(x − 2).",
                     "answer": "11x + 6",
                     "answerKey": k.one(k.forms("11x+6", "6+11x"), accepts=["11x + 6", "6 + 11x", "11x+6"],
                                        rejects=["11x + 1", "11x + 18", "5x + 6"])},
                    {"kind": "sayBack",
                     "text": "The number outside a bracket multiplies every term inside it, sign and all."},
                ],
            },
            {
                "heading": "4.5 Putting the bracket back",
                "teaches": ["factorising"],
                "steps": [
                    {"kind": "question",
                     "text": "A tiled floor is 6 tiles wide and holds 42 tiles, so it is 7 tiles long. "
                             "Another floor is also 6 tiles wide, and it holds 12x + 18 tiles. How long is that floor?"},
                    {"kind": "idea",
                     "text": "Run the last section backwards. 12x is 6 × 2x, and 18 is 6 × 3. "
                             "So 12x + 18 = 6(2x + 3), and the floor is 2x + 3 tiles long."},
                    {"kind": "picture",
                     "text": "Draw the rectangle with its side of 6 marked. Cut it into two pieces with areas 12x and 18. "
                             "Each piece is 6 tall, so their lengths are 2x and 3. The whole length is 2x + 3."},
                    {"kind": "reason",
                     "text": "Why take out 6 and not 2? Both 2 and 3 divide each term too. "
                             "But 12x + 18 = 2(6x + 9), and 6x and 9 still share a 3. "
                             "Taking out the highest common factor leaves nothing more to take out."},
                    {"kind": "name",
                     "text": "Writing an expression as a number or letter times a bracket is called factorising. "
                             "Find the HCF of the terms, write it outside a bracket, and divide each term by it. "
                             "A letter can be part of the HCF too: 5x² + 15x = 5x(x + 3)."},
                    {"kind": "example",
                     "text": "Factorise 20p²q + 8pq. The HCF of 20 and 8 is 4. Both terms have at least one p and one q. "
                             "So the HCF of the terms is 4pq. 20p²q ÷ 4pq = 5p and 8pq ÷ 4pq = 2. "
                             "The answer is 4pq(5p + 2). Check by expanding: 4pq × 5p = 20p²q."},
                    {"kind": "mistake",
                     "text": "The usual slip is to stop too soon. 20p²q + 8pq = 2p(10pq + 4q) is true, "
                             "but 2 and q are still common to both terms in the bracket. "
                             "Another slip is to lose a term. When a whole term is the HCF, it leaves 1 behind: 3x + 3 = 3(x + 1)."},
                    {"kind": "turn",
                     "text": "Factorise 14y − 21.",
                     "answer": "7(2y − 3)",
                     "answerKey": k.one(k.forms("7(2y-3)", "7(-3+2y)", "-7(3-2y)"),
                                        accepts=["7(2y − 3)", "7(2y-3)", "-7(3 - 2y)"],
                                        rejects=["7(2y − 21)", "2y − 3", "7(14y − 21)", "-7y"])},
                    {"kind": "sayBack",
                     "text": "To factorise, take the HCF outside a bracket, then check by expanding."},
                ],
            },
            {
                "heading": "4.6 Two brackets",
                "figure": True,
                "teaches": ["quadratic-expression"],
                "steps": [
                    {"kind": "question",
                     "text": "A square photo is 6 cm by 6 cm. A border makes it 3 cm longer and 2 cm taller, so it is 9 cm by 8 cm. "
                             "Kym says the new area is 6 × 6 + 3 × 2 = 42 cm². Is she right?"},
                    {"kind": "idea",
                     "text": "No. The new photo is 9 cm by 8 cm, so its area is 72 cm². "
                             "Kym counted the old photo and the small corner, but she left out two strips. "
                             "One strip is 3 by 6 and the other is 6 by 2."},
                    {"kind": "picture",
                     "text": "Draw the 9 by 8 rectangle and cut it into four pieces. "
                             "They hold 6 × 6 = 36, 3 × 6 = 18, 6 × 2 = 12 and 3 × 2 = 6, which make 72. "
                             "In the figure, set the side to 6, the first number to 3 and the second number to 2."},
                    {"kind": "reason",
                     "text": "Now let the side of the square be x. The four pieces are x², 3x, 2x and 6. "
                             "So (x + 3)(x + 2) = x² + 3x + 2x + 6, which is x² + 5x + 6. "
                             "Each part of one bracket multiplies each part of the other."},
                    {"kind": "name",
                     "text": "An expression like x² + 5x + 6, whose highest power of x is x², is called a quadratic expression. "
                             "To expand two brackets, multiply each term of one by each term of the other. "
                             "That makes four products, and the middle two are like terms."},
                    {"kind": "example",
                     "text": "Expand (x + 5)(x − 2). Draw a grid with x and 5 along the top and x and −2 down the side. "
                             "The four boxes hold x², 5x, −2x and −10. The middle pair make 5x − 2x = 3x. "
                             "So (x + 5)(x − 2) = x² + 3x − 10."},
                    {"kind": "mistake",
                     "text": "The famous trap is to write (x + 3)² as x² + 9. But (x + 3)² is (x + 3)(x + 3), "
                             "and the square has two strips of 3x as well as its corners. So it is x² + 6x + 9. "
                             "In the figure, set both numbers to 3 and look at the two blue strips. "
                             "Test with x = 4: 7² = 49, and 16 + 24 + 9 = 49."},
                    {"kind": "turn",
                     "text": "Expand and simplify (x + 4)(x + 6).",
                     "answer": "x² + 10x + 24",
                     "answerKey": k.one(k.forms("x^2+10x+24", "24+10x+x^2"), accepts=["x² + 10x + 24", "x^2+10x+24",
                                                                                      "x squared + 10x + 24"],
                                        rejects=["x² + 24", "x² + 10x + 10", "2x + 10"])},
                    {"kind": "sayBack",
                     "text": "Multiply each term in one bracket by each term in the other, then collect the like terms."},
                ],
            },
            {
                "heading": "4.7 A square with a corner cut off",
                "teaches": ["difference-of-two-squares"],
                "steps": [
                    {"kind": "question",
                     "text": "Work out 53² − 47² with no calculator. Squaring both numbers takes a long time. "
                             "Is there a quicker way?"},
                    {"kind": "idea",
                     "text": "Try smaller numbers first. 5² − 3² = 25 − 9 = 16, and (5 − 3) × (5 + 3) = 2 × 8 = 16 as well. "
                             "7² − 2² = 49 − 4 = 45, and 5 × 9 = 45. "
                             "Each time, one square take away the other equals the gap times the total."},
                    {"kind": "picture",
                     "text": "Draw a 5 by 5 square and cut a 3 by 3 square from one corner. "
                             "The L-shape left over holds 16 small squares. "
                             "Cut the L into two strips and lay them end to end. They make a rectangle 2 wide and 8 long."},
                    {"kind": "reason",
                     "text": "The same cut works for any two numbers. "
                             "A square of side a with a corner of side b cut away leaves an L-shape. "
                             "It always rearranges into a rectangle a − b wide and a + b long. So a² − b² = (a − b)(a + b)."},
                    {"kind": "name",
                     "text": "An expression of the form a² − b² is called the difference of two squares. "
                             "It factorises as (a − b)(a + b). "
                             "Expanding shows why: the middle terms −ab and +ab cancel, leaving a² − b²."},
                    {"kind": "example",
                     "text": "Back to 53² − 47². It is (53 − 47)(53 + 47) = 6 × 100 = 600. "
                             "The same idea factorises x² − 49, because 49 = 7². So x² − 49 = (x − 7)(x + 7)."},
                    {"kind": "mistake",
                     "text": "The trap is to treat a² − b² as (a − b)². Test it: 5² − 3² is 16, but (5 − 3)² is only 4. "
                             "A second trap is a sum of two squares. "
                             "x² + 49 does not split this way, because the middle terms would not cancel."},
                    {"kind": "turn",
                     "text": "Work out 64² − 36² without a calculator.",
                     "answer": "2,800",
                     "answerKey": k.one(k.num("2800"), accepts=["2800", "2,800", "= 2800"], rejects=["784", "28", "100", "2880"])},
                    {"kind": "sayBack",
                     "text": "A difference of two squares, a² − b², factorises as (a − b)(a + b)."},
                ],
            },
        ],
        "callouts": [
            {"kind": "predict", "title": "Predict first",
             "body": "Before you touch the figure, predict: is (x + 3)² the same as x² + 9? "
                     "Then set both numbers to 3 and count the pieces."},
            {"kind": "check", "title": "Explain it",
             "body": "Explain to a friend why 3(x + 4) is 3x + 12 and not 3x + 4. Draw the rectangle to show it."},
            {"kind": "careful", "title": "Test with a number",
             "body": "After you expand or factorise, put a small number such as x = 2 into both forms. "
                     "If the two answers differ, there is a slip somewhere."},
        ],
        "debate": {
            "id": "debate-ch04-brackets",
            "oupUnitNumber": 2,
            "title": "Squaring a bracket",
            "contextPrompt": "Rohan and Priya each multiply out (x + 5)².",
            "speakerAName": "Rohan",
            "speakerAClaim": "Square each part. (x + 5)² = x² + 25.",
            "speakerBName": "Priya",
            "speakerBClaim": "(x + 5)² is (x + 5)(x + 5), which is x² + 10x + 25.",
            "choices": [
                {"id": "ch04-a", "speakerLabel": "Rohan is right (x² + 25)",
                 "reasoningStatement": "A square of a bracket is the square of each part.",
                 "isCorrect": False,
                 "socraticRebuttal": "Try x = 1. (1 + 5)² = 36, but 1 + 25 = 26. "
                                     "Draw the square of side x + 5. What fills the two strips beside the x² piece?"},
                {"id": "ch04-b", "speakerLabel": "Priya is right (x² + 10x + 25)",
                 "reasoningStatement": "Each term of one bracket multiplies each term of the other.",
                 "isCorrect": True,
                 "socraticRebuttal": "Yes. The two strips are 5x each, so together they add 10x. "
                                     "Check with x = 1: 1 + 10 + 25 = 36, and 6² = 36."},
                {"id": "ch04-c", "speakerLabel": "Neither. It is 2x + 10.",
                 "reasoningStatement": "Squaring means doubling.",
                 "isCorrect": False,
                 "socraticRebuttal": "Squaring means multiplying a number by itself, not by 2. "
                                     "When x = 1, (x + 5)² is 36, but 2x + 10 is only 12."},
            ],
            "invariantTakeaway": "A squared bracket is two brackets multiplied: (a + b)² = a² + 2ab + b².",
        },
        "keyTerms": [
            "Area", "Variable", "Expression", "Substitution", "Term", "Coefficient", "Like terms",
            "Expanding brackets", "Factorising", "Quadratic expression", "Difference of two squares",
        ],
        "widgets": ["w_algebra_area_tiles", "w_difference_of_squares_slicer"],
        "widgetText": {
            "w_algebra_area_tiles": {
                "title": "Two brackets as a rectangle",
                "challengePrompt": "Set the side to 5, the first number to 2 and the second number to 3. "
                                   "Predict the area of each of the four pieces. Then read the rectangle.",
                "cutaway": "The red square is 5 by 5, so it holds 25. The blue strips hold 2 × 5 = 10 and 3 × 5 = 15. "
                           "The amber corner holds 2 × 3 = 6. Together that is 56, and 7 × 8 = 56.",
                "idealised": "The rule: (x + a)(x + b) = x² + (a + b)x + ab",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Set the side to 4, the first number to 3 and the second number to 2."},
                    {"title": "2. Notice", "caption": "The red square is x², the blue strips are 3x and 2x, and the amber corner is 6."},
                    {"title": "3. Match the rule", "caption": "3x and 2x are like terms, so they join to make 5x. The green line reads x² + 5x + 6."},
                    {"title": "4. Push it further", "caption": "Set both numbers to 3. The two strips are the same size now. What is (x + 3)² multiplied out?"},
                    {"title": "5. Draw it", "caption": "Draw the rectangle for (x + 2)(x + 1) in your journal and write the area in each piece."},
                ],
            },
            "w_difference_of_squares_slicer": {
                "title": "A square with a corner cut away",
                "challengePrompt": "Set the side to 6 and the first number to 2. "
                                   "Predict 6² − 2² before you read the amber lines.",
                "cutaway": "6² − 2² = 36 − 4 = 32. The amber lines show the same number as 4 × 8, which is (6 − 2) × (6 + 2).",
                "idealised": "The rule: a² − b² = (a − b)(a + b)",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Set the side to 5 and the first number to 3. The amber lines show 5² − 3²."},
                    {"title": "2. Notice", "caption": "25 − 9 = 16, and the amber lines give 2 × 8, which is also 16."},
                    {"title": "3. Match the rule", "caption": "2 is the side take away 3, and 8 is the side add 3. So 5² − 3² = (5 − 3)(5 + 3)."},
                    {"title": "4. Push it further", "caption": "Set the side to 3 and the first number to 3. Predict the answer, and say why."},
                    {"title": "5. Draw it", "caption": "Draw a 5 by 5 square, cut a 3 by 3 corner from it, and lay the rest out as a 2 by 8 rectangle."},
                ],
            },
        },
        "atlasLessons": [
            {
                "title": "Chapter 4 · Multiplying out a bracket",
                "question": "Why does the number outside a bracket multiply every term inside?",
                "explanation": "A bracket is one amount, so 4(x + 3) means four lots of x + 3. "
                               "Four lots hold four x's and four 3s, which is 4x + 12.",
                "limits": "The rule: a(b + c) = ab + ac",
            },
            {
                "title": "Chapter 4 · Two brackets",
                "question": "Why does (x + 3)(x + 2) have four pieces?",
                "explanation": "Each bracket is one side of a rectangle, cut into two lengths. "
                               "Two lengths along the top and two down the side make four pieces. "
                               "They are x², 3x, 2x and 6, and the two strips join to make 5x.",
                "limits": "The rule: (x + a)(x + b) = x² + (a + b)x + ab",
            },
            {
                "title": "Chapter 4 · The corner cut away",
                "question": "Why is 53² − 47² the same as 6 × 100?",
                "explanation": "Cut a 47 by 47 square from the corner of a 53 by 53 square. "
                               "The L-shape left over rearranges into a rectangle 6 wide and 100 long.",
                "limits": "The rule: a² − b² = (a − b)(a + b)",
            },
        ],
        "visualMathTips": {
            "tip-binomial-square": {
                "title": "Why (a + b)² is not a² + b²",
                "visualIntuition": "Draw a square of side a + b. Mark a and b along the top and down the side, and cut it into four pieces.",
                "ahaMoment": "There are the corner squares a² and b², and also two strips of area ab. "
                             "Leave out the 2ab and the square has two gaps.",
                "formula": "(a + b)² = a² + 2ab + b²",
            },
        },
        "schoolTopics": {
            "2.1": "An expression has no = sign, such as 3x + 2. "
                   "An equation is true for only some values of x, such as 3x + 2 = 11. "
                   "An identity is true for every value, such as 2(x + 1) = 2x + 2.",
            "2.2": "A number outside a bracket multiplies each term inside, signs included: −3(x − 5) = −3x + 15. "
                   "For two brackets, multiply each term of one by each term of the other, then collect like terms.",
            "2.3": "Take the HCF of every term outside a bracket, numbers and letters both: 6x² − 9x = 3x(2x − 3). "
                   "Then check that nothing common is left inside. A difference of two squares factorises as (a − b)(a + b).",
            "2.4": "Put each number in a bracket as you substitute it. When x = −4, x² is (−4)² = 16, but −x² is −16. "
                   "Work out powers before you multiply.",
        },
        "schoolQuestions": {
            "q-oup-ch02-sb": {
                "workedExample": "Step 1: The 4 multiplies both terms in the first bracket. 4(2x − 3) = 8x − 12.\n"
                                 "Step 2: The −3 multiplies both terms in the second bracket. −3 × x = −3x and −3 × −5 = +15.\n"
                                 "Step 3: Collect like terms. 8x − 3x = 5x and −12 + 15 = 3.\n"
                                 "Step 4: The answer is 5x + 3. The number on its own is +3, because taking away 3 lots of −5 adds 15.",
                "fadedPrompt": "4(2x − 3) − 3(x − 5) = 8x − 12 − 3x + 15, which simplifies to ___.",
            },
            "q-oup-ch02-wb-focus": {
                "workedExample": "Step 1: The HCF of 18 and 12 is 6.\n"
                                 "Step 2: Both terms have at least one a and at least one b. So the HCF of the two terms is 6ab.\n"
                                 "Step 3: Divide each term by 6ab. 18a²b ÷ 6ab = 3a and 12ab² ÷ 6ab = 2b.\n"
                                 "Step 4: So 18a²b − 12ab² = 6ab(3a − 2b). Check by expanding: 6ab × 3a = 18a²b and 6ab × 2b = 12ab².",
                "fadedPrompt": "The HCF of the two terms is 6ab. Divide each term by it: 18a²b − 12ab² = 6ab(___).",
            },
            "q-oup-ch02-wb-practice": {
                "workedExample": "Step 1: The big rectangle has area 6(2x + 5) = 12x + 30.\n"
                                 "Step 2: The piece cut out has area 4(x − 2) = 4x − 8.\n"
                                 "Step 3: Take the small area from the big one. 12x + 30 − (4x − 8) = 12x + 30 − 4x + 8.\n"
                                 "Step 4: Collect like terms. The area left is 8x + 38 cm².",
                "fadedPrompt": "The area left is (12x + 30) − (4x − 8) = ___ cm².",
            },
            "q-oup-ch02-wb-challenge": {
                "workedExample": "Step 1: This is a difference of two squares, so a² − b² = (a − b)(a + b).\n"
                                 "Step 2: Here a = 2026 and b = 2024. So a − b = 2 and a + b = 4050.\n"
                                 "Step 3: Multiply: 2 × 4050 = 8100.\n"
                                 "Step 4: So 2026² − 2024² = 8100, with no big squares to work out.",
                "fadedPrompt": "2026² − 2024² = (2026 − 2024)(2026 + 2024) = 2 × 4050 = ___.",
            },
        },
    }


def cards(k):
    """The concept cards this chapter teaches. Area is in bedrock.py."""
    return {
        "variable": {
            "name": "Variable",
            "aliases": ["variable", "variables"],
            "oneSentence": "A letter that stands for a number, which can change from one case to the next.",
            "picture": "A taxi charges ₹12 for each kilometre, so a ride of d km costs 12d rupees. "
                       "Here d is the variable. It is 3 on a short ride and 20 on a long one.",
            "steps": [
                "Choose a letter and say what number it stands for, with its unit.",
                "Write the rule with the letter in place of the number.",
                "A number written next to a letter means multiply: 12d means 12 × d.",
                "In one problem, the same letter means the same number everywhere.",
            ],
            "workedExample": "A box holds n pencils. Kym has 3 boxes and 5 loose pencils, so she has 3n + 5 pencils. "
                             "If n = 10, that is 35 pencils.",
            "check": {
                "prompt": "A bag of rice weighs w kg. What do 4 bags weigh, in kg, when w = 5?",
                "answer": "20 kg",
                "answerKey": k.one(k.num("20"), accepts=["20", "20 kg", "= 20"], rejects=["9", "45", "1.25"]),
            },
            "mixUp": {
                "name": "a label",
                "how": "In 12d, the d is the number of kilometres, not the word kilometre. 12d means 12 times that number.",
            },
            "standsOn": [],
        },
        "expression": {
            "name": "Expression",
            "aliases": ["expression", "expressions", "algebraic expression"],
            "oneSentence": "Numbers, letters and signs joined into a rule that stands for a number, with no = sign.",
            "picture": "A cinema ticket costs ₹150 and a tub of popcorn costs ₹80. "
                       "For t tickets and p tubs the cost is 150t + 80p rupees. That rule is an expression.",
            "steps": [
                "Read the words and find the amounts that can change. Give each one a letter.",
                "Join the parts with +, −, × or ÷ to match the words.",
                "Leave out the × sign, so 3 × n is written 3n.",
                "An expression has no = sign. It has a value once you know the letters.",
            ],
            "workedExample": "Write an expression for 5 less than double a number n. Double n is 2n. "
                             "Five less than that is 2n − 5.",
            "check": {
                "prompt": "Write an expression for 7 more than three times a number x.",
                "answer": "3x + 7",
                "answerKey": k.one(k.forms("3x+7", "7+3x"), accepts=["3x + 7", "7 + 3x", "3x+7"],
                                   rejects=["7x + 3", "3(x + 7)", "10x"]),
            },
            "mixUp": {
                "name": "a statement with an = sign",
                "how": "2n − 5 is an expression, with a value for every n. "
                       "2n − 5 = 9 is a statement, and it is true only when n = 7.",
            },
            "standsOn": ["variable"],
        },
        "substitution": {
            "name": "Substitution",
            "aliases": ["substitution", "substitute", "substituting", "substituted"],
            "oneSentence": "Putting a number in place of a letter to find the value of an expression.",
            "picture": "A taxi fare is 50 + 12d rupees for a ride of d km. For a 10 km ride, put 10 in place of d. "
                       "The fare is 50 + 12 × 10 = ₹170.",
            "steps": [
                "Write the expression again with a bracket in place of each letter.",
                "Put each number in its bracket, sign and all.",
                "Work out powers first, then × and ÷, then + and −.",
            ],
            "workedExample": "Find 2x² + 3 when x = −4. Write 2 × (−4)² + 3. "
                             "(−4)² = 16, so the value is 2 × 16 + 3 = 35.",
            "check": {
                "prompt": "Find the value of 5y − 2 when y = −3.",
                "answer": "−17",
                "answerKey": k.one(k.num("-17"), accepts=["-17", "−17", "= -17"], rejects=["13", "17", "-13"]),
            },
            "mixUp": {
                "name": "squaring without a bracket",
                "how": "When x = −4, x² is (−4)² = 16. Writing −4² instead means −(4 × 4), which is −16.",
            },
            "standsOn": ["expression", "negative-number"],
            "footing": "negative-numbers",
        },
        "term": {
            "name": "Term",
            "aliases": ["terms of an expression", "terms of the expression", "term of an expression", "algebraic term",
                        "algebraic terms"],
            "oneSentence": "One part of an expression, joined to the rest by a + or − sign.",
            "picture": "A bill of 15s + 10c − 5 rupees has three terms: 15s, 10c and −5. The −5 might be a ₹5 discount.",
            "steps": [
                "Split the expression at each + and − sign that is not inside a bracket.",
                "Keep each sign with the part after it, so the terms of 4x − 7 are 4x and −7.",
                "A part with no letter, such as −7, is called the constant term.",
                "One term can hold several letters multiplied together, such as 3ab.",
            ],
            "workedExample": "How many terms has 2x² − 5x + 3y − 1? Split at the signs to get 2x², −5x, 3y and −1. "
                             "There are four terms.",
            "check": {
                "prompt": "How many terms has 6x − 2y + 5 − x²?",
                "answer": "4",
                "answerKey": k.one(k.num("4"), accepts=["4", "4 terms", "= 4"], rejects=["3", "2", "5"]),
            },
            "mixUp": {
                "name": "a factor of a term",
                "how": "In 3ab, the 3, the a and the b are multiplied, so 3ab is one term. Terms are joined by + and −, not by ×.",
            },
            "standsOn": ["expression"],
        },
        "coefficient": {
            "name": "Coefficient",
            "aliases": ["coefficient", "coefficients"],
            "oneSentence": "The number that multiplies the letters in a term.",
            "picture": "In 7p, the 7 says how many p's there are, so 7 is the coefficient of p. "
                       "In −3x the coefficient is −3, sign included.",
            "steps": [
                "Find the term that holds the letter you want.",
                "Read the number in front of the letters, with its sign.",
                "If no number is written, the coefficient is 1, or −1 for a term such as −y.",
            ],
            "workedExample": "In 5x² − x + 8, the coefficient of x² is 5 and the coefficient of x is −1. "
                             "The 8 has no letter, so it is the constant term.",
            "check": {
                "prompt": "What is the coefficient of y in 4x − 9y + 2?",
                "answer": "−9",
                "answerKey": k.one(k.num("-9"), accepts=["-9", "−9", "= -9"], rejects=["9", "4", "2"]),
            },
            "mixUp": {
                "name": "the power",
                "how": "In 3x², the coefficient is 3 and the power is 2. "
                       "The coefficient multiplies, and the power says how many x's are multiplied together.",
            },
            "standsOn": ["term", "variable"],
        },
        "like-terms": {
            "name": "Like terms",
            "aliases": ["like terms", "like term", "unlike terms"],
            "oneSentence": "Terms with exactly the same letters and powers, which can be added into one term.",
            "picture": "3 mangoes and 4 mangoes make 7 mangoes, but 3 mangoes and 4 apples stay as they are. "
                       "So 3m + 4m = 7m, but 3m + 4a cannot be made shorter.",
            "steps": [
                "Mark each term with its letters and powers, and keep its sign.",
                "Group the terms whose letters and powers match exactly.",
                "Add the coefficients in each group.",
                "Write the groups one after another. Terms with no letter make a group of their own.",
            ],
            "workedExample": "Simplify 4x² + 3x − x² + 5x. The x² terms make 4x² − x² = 3x². "
                             "The x terms make 3x + 5x = 8x. The answer is 3x² + 8x.",
            "check": {
                "prompt": "Simplify 8a − 3b + 2a + 5b.",
                "answer": "10a + 2b",
                "answerKey": k.one(k.forms("10a+2b", "2b+10a"), accepts=["10a + 2b", "2b + 10a", "10a+2b"],
                                   rejects=["12ab", "10a + 8b", "6a + 2b"]),
            },
            "mixUp": {
                "name": "x and x²",
                "how": "x and x² are not like terms. When x = 5, x is 5 but x² is 25, so they count different things.",
            },
            "standsOn": ["term", "coefficient"],
        },
        "expanding-brackets": {
            "name": "Expanding brackets",
            "aliases": ["expanding brackets", "expand", "expanding", "expanded", "multiplying out", "multiply out"],
            "oneSentence": "Multiplying out a bracket, so that the number outside multiplies every term inside.",
            "picture": "5 friends each pay ₹40 for a ticket and ₹20 for snacks. "
                       "The total is 5 × 40 + 5 × 20 = ₹300, the same as 5 × 60.",
            "steps": [
                "Multiply the term outside by the first term inside.",
                "Multiply it by every other term inside, keeping each sign.",
                "A minus sign outside changes the sign of every term inside.",
                "Collect like terms if there are any.",
            ],
            "workedExample": "Expand −2(3x − 7). −2 × 3x = −6x and −2 × −7 = +14. So −2(3x − 7) = −6x + 14.",
            "check": {
                "prompt": "Expand 6(2x − 5).",
                "answer": "12x − 30",
                "answerKey": k.one(k.forms("12x-30", "-30+12x"), accepts=["12x − 30", "12x-30", "-30 + 12x"],
                                   rejects=["12x − 5", "12x + 30", "8x − 30"]),
            },
            "mixUp": {
                "name": "multiplying only the first term",
                "how": "6(2x − 5) is not 12x − 5. Six lots of 2x − 5 hold six 2x's and six 5s, so it is 12x − 30.",
            },
            "standsOn": ["expression", "area", "negative-number"],
            "footing": "distributive-law",
        },
        "factorising": {
            "name": "Factorising",
            "aliases": ["factorising", "factorise", "factorised", "factorises", "factorisation"],
            "oneSentence": "Writing an expression as a product, by taking a common factor outside a bracket.",
            "picture": "₹24 + ₹36 can be paid as 12 lots of ₹2 + ₹3, because 12 divides both. "
                       "In the same way, 24x + 36 = 12(2x + 3).",
            "steps": [
                "Find the HCF of the numbers in every term.",
                "Find the letters that every term has, with the lowest power of each.",
                "Write that HCF outside a bracket.",
                "Divide each term by the HCF to fill the bracket, then check by expanding.",
            ],
            "workedExample": "Factorise 15x² − 10x. The HCF of 15 and 10 is 5, and both terms have an x, so the HCF is 5x. "
                             "15x² ÷ 5x = 3x and 10x ÷ 5x = 2. The answer is 5x(3x − 2).",
            "check": {
                "prompt": "Factorise 8x + 20 completely.",
                "answer": "4(2x + 5)",
                "answerKey": k.one(k.forms("4(2x+5)", "4(5+2x)"), accepts=["4(2x + 5)", "4(2x+5)", "4(5 + 2x)"],
                                   rejects=["2(4x + 10)", "4(2x + 20)", "8(x + 20)"]),
            },
            "mixUp": {
                "with": "expanding-brackets",
                "how": "Factorising and expanding undo each other. Expanding turns 4(2x + 5) into 8x + 20, and factorising turns it back.",
            },
            "standsOn": ["expanding-brackets", "hcf"],
            "footing": "factors-and-multiples",
        },
        "quadratic-expression": {
            "name": "Quadratic expression",
            "aliases": ["quadratic expression", "quadratic expressions"],
            "oneSentence": "An expression whose highest power of the letter is 2, such as x² + 5x + 6.",
            "picture": "A square photo of side x cm, made 3 cm longer and 2 cm taller, has area (x + 3)(x + 2). "
                       "Multiplied out, that is x² + 5x + 6 square centimetres.",
            "steps": [
                "To expand two brackets, multiply each term of the first by each term of the second.",
                "A grid with one bracket along the top and one down the side keeps the four products in order.",
                "Collect the two middle products, which are like terms.",
                "Check by putting a small number in for x in both forms.",
            ],
            "workedExample": "Expand (x − 4)(x + 3). The four products are x², 3x, −4x and −12. "
                             "The middle pair make −x. So the answer is x² − x − 12.",
            "check": {
                "prompt": "Expand (x + 2)(x + 7).",
                "answer": "x² + 9x + 14",
                "answerKey": k.one(k.forms("x^2+9x+14", "14+9x+x^2"), accepts=["x² + 9x + 14", "x^2+9x+14",
                                                                               "x squared + 9x + 14"],
                                   rejects=["x² + 14", "x² + 9x + 9", "2x + 9"]),
            },
            "mixUp": {
                "name": "squaring each part",
                "how": "(x + 3)² is not x² + 9. Multiply it out as (x + 3)(x + 3), and the two strips give x² + 6x + 9.",
            },
            "standsOn": ["expanding-brackets", "power"],
        },
        "difference-of-two-squares": {
            "name": "Difference of two squares",
            "aliases": ["difference of two squares", "difference of squares"],
            "oneSentence": "An expression of the form a² − b², which factorises as (a − b)(a + b).",
            "picture": "Cut a 4 by 4 square from the corner of a 6 by 6 square. "
                       "The 20 small squares left over rearrange into a rectangle 2 wide and 10 long.",
            "steps": [
                "Check that the expression is one square take away another.",
                "Write each square as something squared, so x² − 25 is x² − 5².",
                "Write the difference times the sum: (x − 5)(x + 5).",
                "With numbers, use it to skip the squaring: 21² − 19² = 2 × 40 = 80.",
            ],
            "workedExample": "Factorise 4y² − 9. 4y² is (2y)² and 9 is 3². So 4y² − 9 = (2y − 3)(2y + 3).",
            "check": {
                "prompt": "Work out 18² − 12² without a calculator.",
                "answer": "180",
                "answerKey": k.one(k.num("180"), accepts=["180", "= 180", "6 × 30 = 180"], rejects=["36", "6", "30"]),
            },
            "mixUp": {
                "name": "the square of a difference",
                "how": "a² − b² is not (a − b)². 5² − 3² is 16, but (5 − 3)² is only 4.",
            },
            "standsOn": ["quadratic-expression", "factorising"],
        },
    }


def sums():
    """Every sum chapter 4, its cards and its school unit text state, recomputed. test_book_maths.py checks computed == stated."""
    return [
        # Skill card
        ("3(2x − 5) = 6x − 15", same(lambda x: 3 * (2 * x - 5), lambda x: 6 * x - 15), True),
        ("12y + 18 = 6(2y + 3)", (gcd(12, 18), same(lambda y: 12 * y + 18, lambda y: 6 * (2 * y + 3))), (6, True)),
        ("41² − 39²", (41 ** 2 - 39 ** 2, (41 - 39) * (41 + 39)), (160, 160)),
        # Bridge, figure lines, widgets and Atlas lessons
        ("the 7 by 6 rectangle", (4 * 4, 3 * 4, 2 * 4, 3 * 2, 16 + 12 + 8 + 6, 7 * 6), (16, 12, 8, 6, 42, 42)),
        ("(x + 3)(x + 2) = x² + 5x + 6", same(lambda x: (x + 3) * (x + 2), lambda x: x * x + 5 * x + 6), True),
        ("side 5, numbers 2 and 3", (5 * 5, 2 * 5, 3 * 5, 2 * 3, 25 + 10 + 15 + 6, 7 * 8), (25, 10, 15, 6, 56, 56)),
        ("(x + 3)² = x² + 6x + 9", same(lambda x: (x + 3) ** 2, lambda x: x * x + 6 * x + 9), True),
        ("(x + 2)(x + 1) = x² + 3x + 2", same(lambda x: (x + 2) * (x + 1), lambda x: x * x + 3 * x + 2), True),
        ("6² − 2²", (6 ** 2 - 2 ** 2, 36 - 4, (6 - 2) * (6 + 2)), (32, 32, 32)),
        ("5² − 3²", (25 - 9, 2 * 8, 5 - 3, 5 + 3), (16, 16, 2, 8)),
        ("3² − 3²", (3 ** 2 - 3 ** 2, (3 - 3) * (3 + 3)), (0, 0)),
        ("4(x + 3) = 4x + 12", same(lambda x: 4 * (x + 3), lambda x: 4 * x + 12), True),
        ("53² − 47²", (53 ** 2 - 47 ** 2, 53 - 47, 53 + 47, 6 * 100), (600, 6, 100, 600)),
        ("(a + b)² = a² + 2ab + b²", same(lambda a, b: (a + b) ** 2, lambda a, b: a * a + 2 * a * b + b * b, 2), True),
        ("a² − b² = (a − b)(a + b)", same(lambda a, b: a * a - b * b, lambda a, b: (a - b) * (a + b), 2), True),
        ("a(b + c) = ab + ac", same(lambda a, b, c: a * (b + c), lambda a, b, c: a * b + a * c, 3), True),
        ("(x + a)(x + b) = x² + (a + b)x + ab",
         same(lambda x, a, b: (x + a) * (x + b), lambda x, a, b: x * x + (a + b) * x + a * b, 3), True),
        # Debate
        ("(x + 5)² = x² + 10x + 25", same(lambda x: (x + 5) ** 2, lambda x: x * x + 10 * x + 25), True),
        ("(x + 5)² at x = 1, and the wrong answers", ((1 + 5) ** 2, 1 + 25, 1 + 10 + 25, 6 ** 2, 2 * 1 + 10), (36, 26, 36, 36, 12)),
        # 4.1 Letters for numbers
        ("Kym's and Aarav's bills", (3 * 15 + 2 * 10, 5 * 15 + 1 * 10), (65, 85)),
        ("15s with s = 2", 15 * 2, 30),
        ("4 pens and 2 notebooks", (12 * 4, 30 * 2, 12 * 4 + 30 * 2), (48, 60, 108)),
        # 4.2 Putting numbers in
        ("Meera's bill", (15 * 4, 10 * 3, 15 * 4 + 10 * 3), (60, 30, 90)),
        ("(−3)² and −3²", ((-3) * (-3), -(3 * 3)), (9, -9)),
        ("3x² − 2y at x = −2, y = 5", ((-2) ** 2, 3 * (-2) ** 2 - 2 * 5, 12 - 10), (4, 2, 2)),
        ("the two slips", (3 * -4 - 10, (3 * -2) ** 2 - 10), (-22, 26)),
        # 4.3 Tidying up
        ("3 + 4 packs and 2 + 1 erasers", (3 + 4, 2 + 1), (7, 3)),
        ("3p + 2e + 4p + e = 7p + 3e", same(lambda p, e: 3 * p + 2 * e + 4 * p + e, lambda p, e: 7 * p + 3 * e, 2), True),
        ("7p + 3e at p = 20, e = 5", (7 * 20, 3 * 5, 7 * 20 + 3 * 5, 10 * 20, 10 * 5), (140, 15, 155, 200, 50)),
        ("5a + 3b − 2a + b = 3a + 4b", same(lambda a, b: 5 * a + 3 * b - 2 * a + b, lambda a, b: 3 * a + 4 * b, 2), True),
        ("5 + 3 − 2 + 1, the number in the slip 7ab", 5 + 3 - 2 + 1, 7),
        ("x and x² at 3", (3, 3 ** 2), (3, 9)),
        # 4.4 Multiplying out a bracket
        ("the kits", (4 * 80, 4 * 65, 4 * 15, 4 * 65 + 4 * 15, 65 + 15), (320, 260, 60, 320, 80)),
        ("5(2y − 1) = 10y − 5", same(lambda y: 5 * (2 * y - 1), lambda y: 10 * y - 5), True),
        ("3(2x + 5) − 2(x − 4) = 4x + 23",
         (same(lambda x: 3 * (2 * x + 5) - 2 * (x - 4), lambda x: 4 * x + 23), -2 * -4, 6 - 2, 15 + 8), (True, 8, 4, 23)),
        ("−2(x − 4) = −2x + 8", same(lambda x: -2 * (x - 4), lambda x: -2 * x + 8), True),
        ("3(2x + 5) is not 6x + 5", same(lambda x: 3 * (2 * x + 5), lambda x: 6 * x + 5), False),
        # 4.5 Putting the bracket back
        ("42 tiles, 6 wide", 42 // 6, 7),
        ("12x + 18 = 6(2x + 3) = 2(6x + 9)",
         (same(lambda x: 12 * x + 18, lambda x: 6 * (2 * x + 3)), same(lambda x: 12 * x + 18, lambda x: 2 * (6 * x + 9)),
          gcd(6, 9), gcd(12, 18)), (True, True, 3, 6)),
        ("5x² + 15x = 5x(x + 3)", same(lambda x: 5 * x * x + 15 * x, lambda x: 5 * x * (x + 3)), True),
        ("20p²q + 8pq = 4pq(5p + 2) = 2p(10pq + 4q)",
         (gcd(20, 8), same(lambda p, q: 20 * p * p * q + 8 * p * q, lambda p, q: 4 * p * q * (5 * p + 2), 2),
          same(lambda p, q: 20 * p * p * q + 8 * p * q, lambda p, q: 2 * p * (10 * p * q + 4 * q), 2), gcd(10, 4)),
         (4, True, True, 2)),
        ("3x + 3 = 3(x + 1)", same(lambda x: 3 * x + 3, lambda x: 3 * (x + 1)), True),
        # 4.6 Two brackets
        ("the photo", (9 * 8, 6 * 6 + 3 * 2, 6 * 6, 3 * 6, 6 * 2, 3 * 2, 36 + 18 + 12 + 6), (72, 42, 36, 18, 12, 6, 72)),
        ("(x + 5)(x − 2) = x² + 3x − 10", (same(lambda x: (x + 5) * (x - 2), lambda x: x * x + 3 * x - 10), 5 - 2), (True, 3)),
        ("(x + 3)² is not x² + 9", same(lambda x: (x + 3) ** 2, lambda x: x * x + 9), False),
        ("(x + 3)² at x = 4", (7 ** 2, 16 + 24 + 9), (49, 49)),
        # 4.7 A square with a corner cut off
        ("5² − 3² and 7² − 2²", (25 - 9, 2 * 8, 49 - 4, (7 - 2) * (7 + 2)), (16, 16, 45, 45)),
        ("the L-shape", (5 * 5 - 3 * 3, (5 - 3) * (5 + 3)), (16, 16)),
        ("x² − 49 = (x − 7)(x + 7)", (7 ** 2, same(lambda x: x * x - 49, lambda x: (x - 7) * (x + 7))), (49, True)),
        ("(5 − 3)²", (5 - 3) ** 2, 4),
        ("64² − 36²", (64 ** 2 - 36 ** 2, (64 - 36) * (64 + 36), (64 - 36) ** 2), (2800, 2800, 784)),
        # Callout
        ("3(x + 4) = 3x + 12", same(lambda x: 3 * (x + 4), lambda x: 3 * x + 12), True),
        # Cards
        ("taxi d km", (12 * 3, 12 * 20), (36, 240)),
        ("3n + 5 at n = 10", 3 * 10 + 5, 35),
        ("2n − 5 = 9", 2 * 7 - 5, 9),
        ("taxi fare for 10 km", 50 + 12 * 10, 170),
        ("2x² + 3 at x = −4", ((-4) ** 2, 2 * 16 + 3, -(4 * 4)), (16, 35, -16)),
        ("15s + 10c − 5 has three terms", len(["15s", "10c", "-5"]), 3),
        ("2x² − 5x + 3y − 1 has four terms", len(["2x^2", "-5x", "3y", "-1"]), 4),
        ("4x² + 3x − x² + 5x = 3x² + 8x", same(lambda x: 4 * x * x + 3 * x - x * x + 5 * x, lambda x: 3 * x * x + 8 * x), True),
        ("x and x² at 5", (5, 5 ** 2), (5, 25)),
        ("the friends' tickets", (5 * 40 + 5 * 20, 5 * 60), (300, 300)),
        ("−2(3x − 7) = −6x + 14", (same(lambda x: -2 * (3 * x - 7), lambda x: -6 * x + 14), -2 * -7), (True, 14)),
        ("6(2x − 5) = 12x − 30", same(lambda x: 6 * (2 * x - 5), lambda x: 12 * x - 30), True),
        ("24x + 36 = 12(2x + 3)", (gcd(24, 36), 24 // 12, 36 // 12, same(lambda x: 24 * x + 36, lambda x: 12 * (2 * x + 3))),
         (12, 2, 3, True)),
        ("15x² − 10x = 5x(3x − 2)", (gcd(15, 10), same(lambda x: 15 * x * x - 10 * x, lambda x: 5 * x * (3 * x - 2))), (5, True)),
        ("4(2x + 5) = 8x + 20", same(lambda x: 4 * (2 * x + 5), lambda x: 8 * x + 20), True),
        ("(x − 4)(x + 3) = x² − x − 12", same(lambda x: (x - 4) * (x + 3), lambda x: x * x - x - 12), True),
        ("6 by 6 with a 4 by 4 corner cut", (36 - 16, 6 - 4, 6 + 4, 2 * 10), (20, 2, 10, 20)),
        ("x² − 25 = (x − 5)(x + 5)", same(lambda x: x * x - 25, lambda x: (x - 5) * (x + 5)), True),
        ("21² − 19²", (21 ** 2 - 19 ** 2, 2 * 40), (80, 80)),
        ("4y² − 9 = (2y − 3)(2y + 3)", same(lambda y: 4 * y * y - 9, lambda y: (2 * y - 3) * (2 * y + 3)), True),
        # School unit 2: topic summaries and worked examples
        ("3x + 2 = 11 when x = 3", 3 * 3 + 2, 11),
        ("2(x + 1) = 2x + 2", same(lambda x: 2 * (x + 1), lambda x: 2 * x + 2), True),
        ("−3(x − 5) = −3x + 15", same(lambda x: -3 * (x - 5), lambda x: -3 * x + 15), True),
        ("6x² − 9x = 3x(2x − 3)", same(lambda x: 6 * x * x - 9 * x, lambda x: 3 * x * (2 * x - 3)), True),
        ("x = −4: x² and −x²", ((-4) ** 2, -((-4) ** 2)), (16, -16)),
        ("4(2x − 3) − 3(x − 5) = 5x + 3",
         (same(lambda x: 4 * (2 * x - 3), lambda x: 8 * x - 12), -3 * -5, 8 - 3, -12 + 15,
          same(lambda x: 4 * (2 * x - 3) - 3 * (x - 5), lambda x: 5 * x + 3)), (True, 15, 5, 3, True)),
        ("18a²b − 12ab² = 6ab(3a − 2b)",
         (gcd(18, 12), same(lambda a, b: 18 * a * a * b - 12 * a * b * b, lambda a, b: 6 * a * b * (3 * a - 2 * b), 2)), (6, True)),
        ("the rectangle with a piece cut out",
         (same(lambda x: 6 * (2 * x + 5), lambda x: 12 * x + 30), same(lambda x: 4 * (x - 2), lambda x: 4 * x - 8),
          same(lambda x: 6 * (2 * x + 5) - 4 * (x - 2), lambda x: 8 * x + 38)), (True, True, True)),
        ("2026² − 2024²", (2026 - 2024, 2026 + 2024, 2 * 4050, 2026 ** 2 - 2024 ** 2), (2, 4050, 8100, 8100)),
    ]


def answers():
    """Chapter 4's turn answers and its cards' check answers, computed."""
    hcf = gcd(14, 21)
    return {
        "ch04-s1-turn": written((20, "a"), (10, "k")),
        "ch04-s2-turn": (-3) ** 2 + 4 * (-3),
        "ch04-s3-turn": written((6 - 1, "x"), (2 + 5, "y")),
        "ch04-s4-turn": written((4 * 2 + 3, "x"), (4 * 3 + 3 * -2, "")),
        "ch04-s5-turn": f"{hcf}({written((14 // hcf, 'y'), (-21 // hcf, ''))})",
        "ch04-s6-turn": written((1, "x^2"), (4 + 6, "x"), (4 * 6, "")),
        "ch04-s7-turn": (64 - 36) * (64 + 36),
        "variable-check": 4 * 5,
        "expression-check": written((3, "x"), (7, "")),
        "substitution-check": 5 * -3 - 2,
        "term-check": len(["6x", "-2y", "5", "-x^2"]),
        "coefficient-check": -9,
        "like-terms-check": written((8 + 2, "a"), (-3 + 5, "b")),
        "expanding-brackets-check": written((6 * 2, "x"), (6 * -5, "")),
        "factorising-check": f"{gcd(8, 20)}({written((8 // gcd(8, 20), 'x'), (20 // gcd(8, 20), ''))})",
        "quadratic-expression-check": written((1, "x^2"), (2 + 7, "x"), (2 * 7, "")),
        "difference-of-two-squares-check": (18 - 12) * (18 + 12),
    }
