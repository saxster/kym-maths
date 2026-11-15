"""
Chapter 5, written by hand to docs/CONTENT_BRIEF.md. It carries school unit 7.

Each section teaches one idea in nine steps, in this order: question, idea, picture, reason, name,
example, mistake, turn, sayBack. A section's `teaches` lists the concept cards whose names first
appear in its `name` step. `build(k)` returns the chapter and `cards(k)` its concept cards; both take the
exporter's answer-key helpers. Every section starts from a number puzzle, a balance or a fare before any letter.

`schoolTopics` and `schoolQuestions` rewrite the topic summaries, worked examples and faded prompts of
school unit 7. The answer keys and stuck sheets stay in the exporter.
"""

from math import isqrt

from book.arithmetic import Fraction

VALUES = range(-6, 7)


def solve_linear(a, b, c, d):
    """The x with a·x + b = c·x + d, as a Fraction."""
    return Fraction(d - b, a - c)


def holds(rule, values=VALUES):
    """The whole numbers from −6 to 6 for which `rule(x)` is true, as a list."""
    return [x for x in values if rule(x)]


def build(k):
    return {
        "number": 5,
        "title": "Equations, formulas and inequalities",
        "subtitle": "School book chapter 7 · Solving equations, writing and turning round formulas, and inequalities",
        "hookSummary": "4 bags of marbles and 3 loose marbles balance 15 marbles. How many marbles are in a bag, without opening one?",
        "beyondSchoolBook": False,
        "skillCard": {
            "skill": "Solving equations and inequalities, and turning a formula round",
            "sheCan": {
                "prompt": "With no calculator: solve 6x − 5 = 2x + 11. Make r the subject of A = 3r + 7. Solve 4 − 2x < 10.",
                "answer": "x = 4. r = (A − 7) ÷ 3. x > −3.",
            },
            "whyItMatters": "Most problems hide one unknown number inside a rule. "
                            "Doing the same to both sides finds it, and turning a formula round answers the question the other way.",
            "standsOn": [
                "Chapter 4: expressions, expanding brackets and substitution",
                "Multiplying and dividing negative numbers",
                "Ordering numbers on a number line",
            ],
            "unlocks": [
                "Chapter 6: finding where a number sits in a list that grows by the same step",
                "Chapter 7: finding where two straight lines cross",
                "Every later chapter that finds a missing length, angle or amount",
            ],
        },
        "intuitionToFormula": {
            "concreteAction": "Set the bags to 4, the loose marbles to 3 and the marbles in a bag to 3. "
                              "The right pan shows 15 marbles.",
            "ahaInvariant": "Take 3 marbles off both pans, and 4 bags balance 12 marbles, so a bag holds 3. "
                            "Each step changes both pans by the same amount, so the beam stays level.",
            "formulaDisplay": "ax + b = c   ⇒   ax = c − b   ⇒   x = (c − b) ÷ a",
            "termMappings": [
                {"symbol": "ax", "visualPart": "The red bags on the left pan", "colorRole": "red",
                 "meaning": "a bags, each holding x marbles"},
                {"symbol": "b", "visualPart": "The blue loose marbles on the left pan", "colorRole": "blue",
                 "meaning": "The marbles outside the bags"},
                {"symbol": "c", "visualPart": "The amber marbles on the right pan", "colorRole": "amber",
                 "meaning": "The total that balances the left pan"},
                {"symbol": "x = (c − b) ÷ a", "visualPart": "The green lines", "colorRole": "green",
                 "meaning": "Take b off both pans, then share among the a bags"},
            ],
            "atlasFigureRef": "maths/ch05-balance-equations/index.html",
        },
        "sections": [
            {
                "heading": "5.1 Think of a number",
                "teaches": ["equation", "inverse-operation"],
                "steps": [
                    {"kind": "question",
                     "text": "Kym says: I thought of a number, multiplied it by 3 and then added 5. I got 26. "
                             "Aarav finds her number without guessing. How does he do it?"},
                    {"kind": "idea",
                     "text": "He runs her steps backwards. Her last step was adding 5, so he takes 5 away: 26 − 5 = 21. "
                             "Before that she multiplied by 3, so he divides by 3: 21 ÷ 3 = 7. Her number was 7."},
                    {"kind": "picture",
                     "text": "Draw a row of boxes joined by arrows: start, then × 3, then + 5, then 26. "
                             "Under it, draw the arrows pointing the other way: 26, then − 5, then ÷ 3. "
                             "The start box fills in as 7."},
                    {"kind": "reason",
                     "text": "Why go back in reverse order? The last thing done is the first thing to undo. "
                             "You take off your shoes before your socks. Check the answer forwards: 7 × 3 = 21 and 21 + 5 = 26."},
                    {"kind": "name",
                     "text": "Kym's puzzle, with n for her number, is 3n + 5 = 26. "
                             "A statement that two expressions are equal is called an equation. It is true for some values of n only. "
                             "Adding and taking away undo each other, and so do multiplying and dividing. They are inverse operations."},
                    {"kind": "example",
                     "text": "Aarav's puzzle is n ÷ 4 − 2 = 3. Undo the last step first: 3 + 2 = 5. "
                             "Then undo the dividing: 5 × 4 = 20. His number was 20. Check: 20 ÷ 4 − 2 = 3."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to undo the steps in the order they were done. "
                             "Dividing 26 by 3 first gives 8⅔, and 8⅔ − 5 = 3⅔. Test it forwards: 3⅔ × 3 + 5 = 16, not 26. "
                             "Another slip is to repeat a step. 26 + 5 does not undo adding 5."},
                    {"kind": "turn",
                     "text": "I think of a number, multiply it by 5 and take away 4. The answer is 31. What was my number?",
                     "answer": "7",
                     "answerKey": k.one(k.num("7"), accepts=["7", "n = 7", "= 7"], rejects=["5.4", "35", "151"])},
                    {"kind": "sayBack",
                     "text": "Undo each step with its inverse operation, starting from the last step."},
                ],
            },
            {
                "heading": "5.2 Keeping the balance",
                "figure": True,
                "teaches": ["solving-equations"],
                "steps": [
                    {"kind": "question",
                     "text": "On a balance, 4 bags of marbles and 3 loose marbles balance 15 loose marbles. "
                             "Every bag holds the same number. How many marbles are in one bag?"},
                    {"kind": "idea",
                     "text": "Take 3 marbles off each pan. The beam stays level, and now 4 bags balance 12 marbles. "
                             "Share the 12 marbles among the 4 bags, so each bag holds 3."},
                    {"kind": "picture",
                     "text": "In the figure, set the bags to 4, the loose marbles to 3 and the marbles in a bag to 3. "
                             "The right pan shows 15. Each green line changes both pans in the same way."},
                    {"kind": "reason",
                     "text": "Why must both pans change together? They are level because both sides weigh the same. "
                             "Take the same amount from each, and they still weigh the same. "
                             "Take it from one pan only, and the beam tips."},
                    {"kind": "name",
                     "text": "With b for the marbles in a bag, the balance is 4b + 3 = 15. "
                             "To solve an equation, do the same thing to both sides until the letter stands alone. "
                             "The value you find, here b = 3, is the solution. Put it back to check: 4 × 3 + 3 = 15."},
                    {"kind": "example",
                     "text": "Bags can sit on both pans. Solve 7x − 4 = 3x + 20. Take 3x from both sides: 4x − 4 = 20. "
                             "Add 4 to both sides: 4x = 24. Divide both sides by 4: x = 6. "
                             "Check: 7 × 6 − 4 = 38, and 3 × 6 + 20 = 38."},
                    {"kind": "mistake",
                     "text": "The common slip is to carry 3x to the other side and keep its sign, which gives 10x − 4 = 20. "
                             "Taking 3x from the right means taking 3x from the left as well. "
                             "If a solution fails its check, look for a step done to one side only."},
                    {"kind": "turn",
                     "text": "Solve 5x + 3 = 2x + 18.",
                     "answer": "x = 5",
                     "answerKey": k.one(k.num("5"), accepts=["x = 5", "5", "x=5"], rejects=["7", "15", "3"])},
                    {"kind": "sayBack",
                     "text": "Do the same to both sides until the letter stands alone, then check the solution."},
                ],
            },
            {
                "heading": "5.3 Brackets and fractions",
                "teaches": [],
                "steps": [
                    {"kind": "question",
                     "text": "Three friends at the cinema each pay for a ticket and ₹8 of popcorn. Together they pay ₹150. "
                             "What does one ticket cost?"},
                    {"kind": "idea",
                     "text": "Each friend paid a third of ₹150, which is ₹50. "
                             "Take off the ₹8 of popcorn, and a ticket costs ₹42."},
                    {"kind": "picture",
                     "text": "Draw three equal bars side by side. Split each bar into a ticket piece and a popcorn piece of 8. "
                             "The three bars together are 150, so one bar is 50 and its ticket piece is 42."},
                    {"kind": "reason",
                     "text": "With t for the ticket price, the bill is 3(t + 8) = 150. "
                             "Dividing both sides by 3 gives t + 8 = 50, so t = 42. "
                             "Expanding first works too: 3t + 24 = 150, so 3t = 126 and t = 42."},
                    {"kind": "name",
                     "text": "Brackets and fractions do not change the method. "
                             "Expand the brackets, or divide both sides by the number outside them. "
                             "To clear a fraction, multiply both sides by its bottom number. "
                             "Then gather the letters on one side and the numbers on the other."},
                    {"kind": "example",
                     "text": "Solve 4(2x − 1) = 3(x + 7). Expand both sides: 8x − 4 = 3x + 21. "
                             "Take 3x from both sides: 5x − 4 = 21. Add 4 to both sides: 5x = 25, so x = 5. "
                             "Check: 4 × 9 = 36, and 3 × 12 = 36."},
                    {"kind": "mistake",
                     "text": "The usual slip with a fraction is to multiply only one term. "
                             "In x/2 + 3 = 7, multiplying both sides by 2 gives x + 6 = 14, not x + 3 = 14. "
                             "The 3 is doubled too. So x = 8, and 8 ÷ 2 + 3 = 7."},
                    {"kind": "turn",
                     "text": "Solve (x − 4)/5 = 3.",
                     "answer": "x = 19",
                     "answerKey": k.one(k.num("19"), accepts=["x = 19", "19", "x=19"], rejects=["11", "15", "4.6"])},
                    {"kind": "sayBack",
                     "text": "Clear the brackets and fractions first, then do the same to both sides as before."},
                ],
            },
            {
                "heading": "5.4 A rule with a name",
                "teaches": ["formula"],
                "steps": [
                    {"kind": "question",
                     "text": "A taxi charges ₹50 to start and ₹12 for each kilometre. What does a 9 km ride cost? "
                             "Can one line give the cost of every ride?"},
                    {"kind": "idea",
                     "text": "A 9 km ride costs 50 + 12 × 9 = ₹158. Every ride costs ₹50 plus 12 times the distance. "
                             "With C for the cost in rupees and d for the distance in km, C = 50 + 12d."},
                    {"kind": "picture",
                     "text": "Make a table of distances and costs. 1 km costs ₹62, 2 km costs ₹74 and 3 km costs ₹86. "
                             "Each extra kilometre adds ₹12, and one rule turns any distance into its cost."},
                    {"kind": "reason",
                     "text": "Why write C = in front, and not only 50 + 12d? The letter C names the amount the rule gives. "
                             "The rule now links two amounts that change together, and a reader can tell which is which."},
                    {"kind": "name",
                     "text": "A rule like C = 50 + 12d, which links two or more quantities with an = sign, is called a formula. "
                             "Each letter stands for a named quantity with a unit. "
                             "To use a formula, substitute the numbers you know."},
                    {"kind": "example",
                     "text": "The perimeter P of a rectangle L cm long and w cm wide is P = 2(L + w). "
                             "A rectangle 7 cm by 4 cm has P = 2 × 11 = 22 cm. "
                             "The formula P = 2L + 2w gives the same answer, because it is the bracket expanded."},
                    {"kind": "mistake",
                     "text": "One slip is to add 50 + 12 first in C = 50 + 12d, which gives 62d. "
                             "Multiplying comes before adding, so a 9 km ride costs ₹158, not ₹558. "
                             "Another slip is to drop the units, so nobody can tell whether d is in km or m."},
                    {"kind": "turn",
                     "text": "A concert ticket costs ₹150, and each order pays a ₹40 booking fee. "
                             "Write a formula for the cost C, in rupees, of an order of n tickets.",
                     "answer": "C = 150n + 40",
                     "answerKey": k.one(k.forms("C=150n+40", "C=40+150n"), accepts=["C = 150n + 40", "C = 40 + 150n", "c=150n+40"],
                                        rejects=["C = 190n", "C = 150 + 40n", "C = 40n + 150"])},
                    {"kind": "sayBack",
                     "text": "A formula links named quantities, and you use it by substituting the ones you know."},
                ],
            },
            {
                "heading": "5.5 Turning a formula round",
                "teaches": ["subject-of-a-formula"],
                "steps": [
                    {"kind": "question",
                     "text": "The taxi's rule is C = 50 + 12d. Meera's ride cost ₹170. How far did she go? "
                             "Is there a rule that turns any cost straight into a distance?"},
                    {"kind": "idea",
                     "text": "Work backwards from the cost. Take away the ₹50 start charge: 170 − 50 = 120. "
                             "Divide by the ₹12 for each kilometre: 120 ÷ 12 = 10. Meera went 10 km."},
                    {"kind": "picture",
                     "text": "Draw the rule as a chain: d, then × 12, then + 50, then C. "
                             "Turn every arrow round: C, then − 50, then ÷ 12, then d."},
                    {"kind": "reason",
                     "text": "Why do the same steps work for any cost? They are inverse operations in reverse order. "
                             "Nothing in them depends on the 170. Write C in place of 170, and the chain gives d = (C − 50) ÷ 12."},
                    {"kind": "name",
                     "text": "The letter standing alone on one side is the subject of the formula. In C = 50 + 12d the subject is C. "
                             "Rewriting it as d = (C − 50)/12 is called changing the subject. "
                             "Do the same to both sides, as when you solve an equation."},
                    {"kind": "example",
                     "text": "Make t the subject of v = u + at. Take u from both sides: v − u = at. "
                             "Divide both sides by a: t = (v − u)/a. "
                             "Check with u = 2, a = 3 and t = 4. Then v = 14, and (14 − 2)/3 = 4."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to write d = C − 50/12. That divides only the 50. "
                             "The whole of C − 50 is divided by 12, so it needs a bracket. "
                             "Test with C = 170: (170 − 50)/12 = 10, but 170 − 50/12 is about 166."},
                    {"kind": "turn",
                     "text": "Make x the subject of y = 4x − 3.",
                     "answer": "x = (y + 3)/4",
                     "answerKey": k.one(k.forms("x=(y+3)/4", "x=(3+y)/4", "x=y/4+3/4", "x=(y+3)÷4"),
                                        accepts=["x = (y + 3)/4", "x = (3 + y)/4", "x = (y + 3) ÷ 4"],
                                        rejects=["x = (y − 3)/4", "x = y + 3/4", "x = 4y + 3"])},
                    {"kind": "sayBack",
                     "text": "To change the subject, undo what was done to the letter, in reverse order, on both sides."},
                ],
            },
            {
                "heading": "5.6 More than, less than",
                "teaches": ["inequality"],
                "steps": [
                    {"kind": "question",
                     "text": "A ride at the fair says riders must be at least 120 cm tall. Kym is 118 cm and Aarav is 120 cm. "
                             "Who can ride, and how do you write the rule?"},
                    {"kind": "idea",
                     "text": "Aarav can ride, because 120 cm counts. Kym cannot. Any height of 120 cm or more is allowed. "
                             "With h for a height in cm, the rule is h ≥ 120."},
                    {"kind": "picture",
                     "text": "On a number line, put a filled dot at 120 and shade everything to its right. "
                             "The filled dot means 120 itself is allowed. "
                             "For the rule h > 120, the dot would be an open circle, because 120 would not be allowed."},
                    {"kind": "reason",
                     "text": "Why can you solve 3x + 4 < 19 like an equation? "
                             "Adding, taking away, and multiplying or dividing by a positive number keep two numbers in the same order. "
                             "So 3x < 15 and x < 5. Test x = 4: 16 < 19 is true. Test x = 6: 22 < 19 is false."},
                    {"kind": "name",
                     "text": "A statement that uses <, >, ≤ or ≥ is called an inequality. Its answer is a whole stretch of numbers. "
                             "On a number line, an open circle leaves the end out and a filled dot puts it in. "
                             "Multiplying or dividing both sides by a negative number turns the sign round."},
                    {"kind": "example",
                     "text": "Solve 5 − 2x > 11. Take 5 from both sides: −2x > 6. "
                             "Divide both sides by −2 and turn the sign round: x < −3. "
                             "Test x = −4: 5 + 8 = 13, and 13 > 11 is true."},
                    {"kind": "mistake",
                     "text": "The famous slip is to divide by −2 and keep the sign, which gives x > −3. "
                             "Test x = 0, which that answer allows: 5 − 0 = 5, and 5 > 11 is false. "
                             "Multiplying by −1 swaps the two sides of 0 on the number line, so the order turns round."},
                    {"kind": "turn",
                     "text": "Solve 7 − 3x ≤ 19.",
                     "answer": "x ≥ −4",
                     "answerKey": k.one(k.forms("x>=-4", "-4<=x"), accepts=["x ≥ −4", "x >= -4", "-4 ≤ x"],
                                        rejects=["x ≤ −4", "x ≥ 4", "x ≤ 4"])},
                    {"kind": "sayBack",
                     "text": "Solve an inequality like an equation, but turn the sign round when you multiply or divide by a negative."},
                ],
            },
        ],
        "callouts": [
            {"kind": "predict", "title": "Predict first",
             "body": "Predict first: 6 bags and 2 loose marbles balance 20 marbles. How many marbles are in a bag? "
                     "Then set the bags to 6 and the loose marbles to 2, and move the last slider until the right pan shows 20."},
            {"kind": "check", "title": "Explain it",
             "body": "Explain to a friend why, to find the number someone thought of, you undo their last step first."},
            {"kind": "careful", "title": "Both sides, every time",
             "body": "Whatever you do to one side of an equation, do to the other side too. "
                     "Then put your answer back into the first equation and check that both sides match."},
        ],
        "debate": {
            "id": "debate-ch05-equations",
            "oupUnitNumber": 7,
            "title": "Dividing by a negative",
            "contextPrompt": "Neha and Kabir each solve −2x < 8.",
            "speakerAName": "Neha",
            "speakerAClaim": "Divide both sides by −2. x < −4.",
            "speakerBName": "Kabir",
            "speakerBClaim": "Dividing by −2 turns the sign round. x > −4.",
            "choices": [
                {"id": "ch05-a", "speakerLabel": "Neha is right (x < −4)",
                 "reasoningStatement": "Whatever you do to one side you do to the other, and the sign stays as it is.",
                 "isCorrect": False,
                 "socraticRebuttal": "Try x = 0. Then −2x is 0, and 0 < 8 is true, so 0 is in the answer. "
                                     "Does x < −4 allow 0?"},
                {"id": "ch05-b", "speakerLabel": "Kabir is right (x > −4)",
                 "reasoningStatement": "Dividing by a negative number turns the order of two numbers round.",
                 "isCorrect": True,
                 "socraticRebuttal": "Yes. Test x = −5, which Kabir's answer leaves out: −2 × −5 = 10, and 10 < 8 is false."},
                {"id": "ch05-c", "speakerLabel": "Neither. It is x < 4.",
                 "reasoningStatement": "The two minus signs cancel.",
                 "isCorrect": False,
                 "socraticRebuttal": "Try x = −10, which x < 4 allows. Then −2x is 20, and 20 < 8 is false."},
            ],
            "invariantTakeaway": "Multiplying or dividing an inequality by a negative number turns its sign round: if a < b, then −a > −b.",
        },
        "keyTerms": ["Equation", "Inverse operation", "Solving an equation", "Formula", "Subject of a formula", "Inequality"],
        "widgets": ["w_balance_beam_equations", "w_formula_subject_transposer", "w_inequality_mirror_line"],
        "widgetText": {
            "w_balance_beam_equations": {
                "title": "A balance for an equation",
                "challengePrompt": "Set the bags to 5 and the loose marbles to 4. "
                                   "Predict how many marbles a bag must hold for the right pan to show 19. Then move the last slider.",
                "cutaway": "5 bags and 4 marbles balance 19 marbles. Take 4 off both pans, and 5 bags balance 15. "
                           "So each bag holds 3.",
                "idealised": "The rule: ax + b = c gives x = (c − b) ÷ a",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Set the bags to 2, the loose marbles to 1 and the marbles in a bag to 4."},
                    {"title": "2. Notice", "caption": "The right pan shows 9 marbles, and the green line reads 2b + 1 = 9."},
                    {"title": "3. Match the rule", "caption": "Take 1 off both pans: 2b = 8. Share between 2 bags: b = 4, the slider's value."},
                    {"title": "4. Push it further", "caption": "Set the loose marbles to 9. What does the right pan show now, and why does b stay 4?"},
                    {"title": "5. Draw it", "caption": "Draw the balance for 3b + 2 = 14 in your journal. Cross out the same marbles on both pans."},
                ],
            },
            "w_formula_subject_transposer": {
                "title": "Turning a formula round",
                "challengePrompt": "The taxi formula is C = 50 + 12d. Predict the distance for a fare of ₹110 before you work it out.",
                "cutaway": "Undo the steps in reverse order. 110 − 50 = 60, and 60 ÷ 12 = 5, so the ride was 5 km.",
                "idealised": "The rule: C = 50 + 12d gives d = (C − 50) ÷ 12",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Write the taxi formula as a chain: d, then × 12, then + 50, then C."},
                    {"title": "2. Notice", "caption": "Each arrow has an inverse. Adding 50 is undone by taking 50 away, and × 12 by ÷ 12."},
                    {"title": "3. Match the rule", "caption": "Run the chain backwards from C, and you get d = (C − 50) ÷ 12."},
                    {"title": "4. Push it further", "caption": "Make r the subject of A = 3r + 7. Then find r when A = 25."},
                    {"title": "5. Draw it", "caption": "Draw the chain for v = u + at forwards and backwards, and read off t."},
                ],
            },
            "w_inequality_mirror_line": {
                "title": "Turning an inequality round",
                "challengePrompt": "Mark 2 and 5 on a number line. "
                                   "Predict what happens to their order when you multiply both by −1.",
                "cutaway": "2 < 5, but −2 > −5. Multiplying by −1 reflects every number across 0, so the order turns round.",
                "idealised": "The rule: if a < b, then −a > −b",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Draw a number line from −6 to 6, and mark 2 and 5."},
                    {"title": "2. Notice", "caption": "Multiply each by −1. The points −2 and −5 sit on the other side of 0, the other way round."},
                    {"title": "3. Match the rule", "caption": "So 2 < 5 becomes −2 > −5. Dividing by a negative number turns the order round too."},
                    {"title": "4. Push it further", "caption": "Solve −3x < 12. Which way does the sign point once you divide by −3?"},
                    {"title": "5. Draw it", "caption": "Draw x ≥ −1 and x < 4 on one number line, with a filled dot and an open circle."},
                ],
            },
        },
        "atlasLessons": [
            {
                "title": "Chapter 5 · The same to both sides",
                "question": "Why does doing the same thing to both sides keep an equation true?",
                "explanation": "An equation says two amounts are equal, like the two pans of a level balance. "
                               "Change both by the same amount, and they are still equal. "
                               "Change one only, and the balance tips.",
                "limits": "The rule: ax + b = c gives x = (c − b) ÷ a",
            },
            {
                "title": "Chapter 5 · Turning a formula round",
                "question": "Why do you undo the steps of a formula in reverse order?",
                "explanation": "A formula builds its subject in steps, such as × 12 and then + 50. "
                               "The last step done sits on the outside, so it comes off first.",
                "limits": "The rule: C = 50 + 12d gives d = (C − 50) ÷ 12",
            },
            {
                "title": "Chapter 5 · When the sign turns round",
                "question": "Why does dividing by a negative number turn an inequality round?",
                "explanation": "Multiplying by −1 reflects every number across 0. "
                               "The number that was further right lands further left, so the bigger one becomes the smaller one.",
                "limits": "The rule: if a < b, then −a > −b",
            },
        ],
        "visualMathTips": {},
        "schoolTopics": {
            "7.1": "Turn words or a diagram into a formula. Give each quantity a letter and a unit. "
                   "A rectangle L cm long and w cm wide has perimeter P = 2(L + w).",
            "7.2": "Do the same to both sides. Expand any brackets, and clear a fraction by multiplying both sides by its bottom number. "
                   "Gather the letter terms on one side, then check the answer in the first equation.",
            "7.3": "To change the subject, undo the steps in reverse order on both sides. "
                   "If the new subject appears twice, gather both terms on one side and factorise to take it out.",
            "7.4": "Solve an inequality like an equation. On a number line, < and > get an open circle, and ≤ and ≥ a filled dot. "
                   "Multiplying or dividing by a negative number turns the sign round.",
        },
        "schoolQuestions": {
            "q-oup-ch07-sb": {
                "workedExample": "Step 1: Take 2as from both sides. u² = v² − 2as.\n"
                                 "Step 2: Take the square root of both sides. Since u > 0, u = √(v² − 2as).\n"
                                 "Step 3: Substitute v = 13, a = 6 and s = 10. u = √(169 − 120) = √49.\n"
                                 "Step 4: So u = 7. Check: 7² + 2 × 6 × 10 = 49 + 120 = 169 = 13².",
                "fadedPrompt": "u² = v² − 2as, so u = √(v² − 2as) = √(169 − 120) = ___.",
            },
            "q-oup-ch07-wb-focus": {
                "workedExample": "Step 1: Expand both sides. 10x − 5 = 3x + 12 + 4, which is 3x + 16.\n"
                                 "Step 2: Take 3x from both sides. 7x − 5 = 16.\n"
                                 "Step 3: Add 5 to both sides. 7x = 21, so x = 3.\n"
                                 "Step 4: Check. 5 × (6 − 1) = 25, and 3 × (3 + 4) + 4 = 25.",
                "fadedPrompt": "10x − 5 = 3x + 16, so 7x = 21 and x = ___.",
            },
            "q-oup-ch07-wb-practice": {
                "workedExample": "Step 1: Take 14 from both sides. −3x ≥ −12.\n"
                                 "Step 2: Divide both sides by −3, and turn the sign round. x ≤ 4.\n"
                                 "Step 3: Test x = 4: 14 − 12 = 2, and 2 ≥ 2 is true. Test x = 5: 14 − 15 = −1, which is less than 2.\n"
                                 "Step 4: So x ≤ 4, and the largest whole number that works is 4.",
                "fadedPrompt": "−3x ≥ −12. Dividing by −3 turns the sign round, so x ___ 4.",
            },
            "q-oup-ch07-wb-challenge": {
                "workedExample": "Step 1: Multiply both sides by x − 1. y(x − 1) = 3x + 2, so xy − y = 3x + 2.\n"
                                 "Step 2: Gather the x terms on one side. xy − 3x = y + 2.\n"
                                 "Step 3: Factorise to take x out. x(y − 3) = y + 2.\n"
                                 "Step 4: Divide both sides by y − 3. x = (y + 2)/(y − 3).",
                "fadedPrompt": "xy − 3x = y + 2, so x(y − 3) = y + 2 and x = ___.",
            },
        },
    }


def cards(k):
    """The concept cards this chapter teaches."""
    return {
        "equation": {
            "name": "Equation",
            "aliases": ["equation", "equations"],
            "oneSentence": "A statement that two expressions are equal, which is true for some values of the letter only.",
            "picture": "A balance with 2 bags and 6 marbles on one pan and 14 marbles on the other. "
                       "It is level only if each bag holds 4 marbles, so 2b + 6 = 14.",
            "steps": [
                "Find the amount you do not know, and give it a letter.",
                "Write each side of the story as an expression.",
                "Join the two expressions with an = sign.",
                "Say what the letter stands for, with its unit.",
            ],
            "workedExample": "Kym is 3 years older than her brother, and their ages add up to 21. "
                             "With a for his age, a + (a + 3) = 21. That is the equation 2a + 3 = 21.",
            "check": {
                "prompt": "Is 4x − 1 = 11 true when x = 3?",
                "answer": "Yes",
                "answerKey": k.one(k.forms("yes", "true"), accepts=["Yes", "yes, 12 − 1 = 11", "true"],
                                   rejects=["no", "false"]),
            },
            "mixUp": {
                "with": "expression",
                "how": "4x − 1 is an expression, with a value for every x. 4x − 1 = 11 is an equation, true only when x = 3.",
            },
            "standsOn": ["expression"],
        },
        "inverse-operation": {
            "name": "Inverse operation",
            "aliases": ["inverse operation", "inverse operations"],
            "oneSentence": "The operation that undoes another: taking away undoes adding, and dividing undoes multiplying.",
            "picture": "Walk 5 steps forward and then 5 steps back, and you are where you started. "
                       "Adding 5 and taking away 5 undo each other in the same way.",
            "steps": [
                "Adding and taking away are inverses of each other.",
                "Multiplying and dividing are inverses of each other, by the same number.",
                "Squaring a positive number and taking its square root are inverses too.",
                "To undo several steps, undo the last one first.",
            ],
            "workedExample": "A number is multiplied by 6 and then 9 is taken away, giving 45. "
                             "Undo the last step: 45 + 9 = 54. Then 54 ÷ 6 = 9.",
            "check": {
                "prompt": "A number is divided by 3 and then 4 is added, giving 10. What was the number?",
                "answer": "18",
                "answerKey": k.one(k.num("18"), accepts=["18", "= 18", "n = 18"], rejects=["42", "2", "26"]),
            },
            "mixUp": {
                "name": "the reciprocal",
                "how": "The inverse of × 4 is ÷ 4, which is the same as × ¼. "
                       "The inverse of + 4 is − 4, not ÷ 4.",
            },
            "standsOn": [],
            "footing": "inverse-operations",
        },
        "solving-equations": {
            "name": "Solving an equation",
            "aliases": ["solve an equation", "solving an equation", "solving equations", "solve the equation",
                        "solution", "solutions"],
            "oneSentence": "Finding the value of the letter that makes an equation true, by doing the same to both sides.",
            "picture": "A level balance stays level when you take the same amount off both pans. "
                       "Keep doing that until one bag sits alone against a pile of marbles.",
            "steps": [
                "Expand any brackets, and clear any fraction.",
                "Gather the letter terms on one side by doing the same to both sides.",
                "Gather the numbers on the other side in the same way.",
                "Divide both sides by the number in front of the letter.",
                "Check the solution in the first equation.",
            ],
            "workedExample": "Solve 9x + 2 = 4x + 27. Take 4x from both sides: 5x + 2 = 27. "
                             "Take 2 from both sides: 5x = 25, so x = 5. Check: 47 = 47.",
            "check": {
                "prompt": "Solve 8x − 7 = 3x + 13.",
                "answer": "x = 4",
                "answerKey": k.one(k.num("4"), accepts=["x = 4", "4", "x=4"], rejects=["2", "1.2", "20"]),
            },
            "mixUp": {
                "name": "changing one side only",
                "how": "Taking 3x from the right of 8x − 7 = 3x + 13 means taking 3x from the left as well. "
                       "Otherwise the two sides are no longer equal.",
            },
            "standsOn": ["equation", "inverse-operation"],
        },
        "formula": {
            "name": "Formula",
            "aliases": ["formula", "formulas", "formulae"],
            "oneSentence": "A rule that links two or more quantities with an = sign, each written as a letter.",
            "picture": "A mobile plan costs ₹199 a month and ₹2 for each extra minute. "
                       "With T for the bill and m for the extra minutes, T = 199 + 2m.",
            "steps": [
                "Name each quantity with a letter, and say its unit.",
                "Write the quantity you want to find on its own, then an = sign.",
                "Write the rule that gives it on the other side.",
                "Test the formula with one case you can work out by hand.",
            ],
            "workedExample": "Each side of a square is s cm long. Its perimeter is P = 4s, and its area is A = s². "
                             "When s = 5, P = 20 cm and A = 25 cm².",
            "check": {
                "prompt": "Use P = 2(L + w) to find the perimeter, in cm, of a rectangle 9 cm by 6 cm.",
                "answer": "30 cm",
                "answerKey": k.one(k.num("30"), accepts=["30", "30 cm", "P = 30"], rejects=["54", "15", "21"]),
            },
            "mixUp": {
                "with": "equation",
                "how": "An equation such as 2x + 1 = 9 has one answer. "
                       "A formula such as P = 4s holds for every value, and links quantities that change together.",
            },
            "standsOn": ["equation", "variable"],
        },
        "subject-of-a-formula": {
            "name": "Subject of a formula",
            "aliases": ["subject of a formula", "subject of the formula", "changing the subject", "change the subject"],
            "oneSentence": "The letter that stands alone on one side of a formula, which the formula tells you how to find.",
            "picture": "In C = 50 + 12d the subject is C, so the formula turns a distance into a cost. "
                       "Rewritten as d = (C − 50) ÷ 12, it turns a cost into a distance.",
            "steps": [
                "List the steps that were done to the new subject, in order.",
                "Undo them in reverse order, doing each one to both sides.",
                "If the new subject appears twice, gather both terms and factorise.",
                "Check with numbers you know.",
            ],
            "workedExample": "Make r the subject of A = 3r + 7. Take 7 from both sides: A − 7 = 3r. "
                             "Divide by 3: r = (A − 7)/3.",
            "check": {
                "prompt": "Make w the subject of P = 2L + 2w.",
                "answer": "w = (P − 2L)/2",
                "answerKey": k.one(k.forms("w=(P-2L)/2", "w=P/2-L", "w=(P-2L)÷2", "w=-L+P/2"),
                                   accepts=["w = (P − 2L)/2", "w = P/2 − L", "w = (P − 2L) ÷ 2"],
                                   rejects=["w = P − 2L/2", "w = (P + 2L)/2", "w = 2P − 2L"]),
            },
            "mixUp": {
                "name": "dividing one term",
                "how": "In w = (P − 2L)/2 the whole of P − 2L is divided by 2. Writing P − 2L/2 divides only the 2L.",
            },
            "standsOn": ["formula", "inverse-operation"],
        },
        "inequality": {
            "name": "Inequality",
            "aliases": ["inequality", "inequalities"],
            "oneSentence": "A statement that one amount is less than or more than another, using <, >, ≤ or ≥.",
            "picture": "A lift carries at most 8 people, so the number of people p must satisfy p ≤ 8. "
                       "On a number line, that is a filled dot at 8 with the shading to its left.",
            "steps": [
                "Solve it like an equation, doing the same to both sides.",
                "When you multiply or divide both sides by a negative number, turn the sign round.",
                "Draw the answer on a number line: an open circle for < or >, a filled dot for ≤ or ≥.",
                "Test one number from inside your answer.",
            ],
            "workedExample": "Solve 2x − 3 ≥ 7. Add 3 to both sides: 2x ≥ 10, so x ≥ 5. "
                             "Draw a filled dot at 5 and shade to the right.",
            "check": {
                "prompt": "Solve −4x > 20.",
                "answer": "x < −5",
                "answerKey": k.one(k.forms("x<-5", "-5>x"), accepts=["x < −5", "x < -5", "-5 > x"],
                                   rejects=["x > −5", "x < 5", "x > 5"]),
            },
            "mixUp": {
                "name": "an open circle and a filled dot",
                "how": "x < 3 leaves 3 out, so it gets an open circle. x ≤ 3 lets 3 in, so it gets a filled dot.",
            },
            "standsOn": ["equation", "negative-number"],
        },
    }


def sums():
    """Every sum chapter 5, its cards and its school unit text state, recomputed. test_book_maths.py checks computed == stated."""
    third = Fraction(26, 3)
    return [
        # Skill card
        ("6x − 5 = 2x + 11", solve_linear(6, -5, 2, 11), 4),
        ("A = 3r + 7 gives r = (A − 7) ÷ 3", all(Fraction(3 * r + 7 - 7, 3) == r for r in VALUES), True),
        ("4 − 2x < 10 means x > −3", holds(lambda x: 4 - 2 * x < 10), holds(lambda x: x > -3)),
        # Bridge, figure and hook
        ("4 bags and 3 marbles balance 15", (solve_linear(4, 3, 0, 15), 15 - 3, 4 * 3 + 3), (3, 12, 15)),
        # 5.1 Think of a number
        ("Kym's number", (26 - 5, 21 // 3, 7 * 3, 21 + 5), (21, 7, 21, 26)),
        ("3n + 5 = 26", solve_linear(3, 5, 0, 26), 7),
        ("n ÷ 4 − 2 = 3", (3 + 2, 5 * 4, Fraction(20, 4) - 2), (5, 20, 3)),
        ("the wrong order", (third, third - 5, (third - 5) * 3 + 5), (Fraction(26, 3), Fraction(11, 3), 16)),
        ("8⅔ and 3⅔", (8 + Fraction(2, 3), 3 + Fraction(2, 3)), (third, third - 5)),
        ("× 5 − 4 = 31, and the slips", ((31 + 4) // 5, Fraction(31 - 4, 5), 31 + 4, 31 * 5 - 4), (7, Fraction("5.4"), 35, 151)),
        # 5.2 Keeping the balance
        ("4b + 3 = 15", (15 - 3, Fraction(12, 4), 4 * 3 + 3), (12, 3, 15)),
        ("7x − 4 = 3x + 20", (solve_linear(7, -4, 3, 20), 7 - 3, 20 + 4, 7 * 6 - 4, 3 * 6 + 20), (6, 4, 24, 38, 38)),
        ("the slip 10x − 4 = 20", 7 + 3, 10),
        ("5x + 3 = 2x + 18", solve_linear(5, 3, 2, 18), 5),
        # 5.3 Brackets and fractions
        ("the cinema", (Fraction(150, 3), 50 - 8, 3 * (42 + 8)), (50, 42, 150)),
        ("3t + 24 = 150", (3 * 8, 150 - 24, Fraction(126, 3)), (24, 126, 42)),
        ("4(2x − 1) = 3(x + 7)", (solve_linear(8, -4, 3, 21), 4 * (2 * 5 - 1), 3 * (5 + 7), 21 + 4), (5, 36, 36, 25)),
        ("x/2 + 3 = 7", (2 * 3, 2 * 7, 14 - 6, Fraction(8, 2) + 3), (6, 14, 8, 7)),
        ("(x − 4)/5 = 3", (3 * 5 + 4, Fraction(19 - 4, 5)), (19, 3)),
        ("the slips for (x − 4)/5 = 3", (15 - 4, 3 * 5, Fraction(3, 5) + 4), (11, 15, Fraction("4.6"))),
        # 5.4 A rule with a name
        ("the 9 km ride", (50 + 12 * 9, 50 + 12, 62 * 9), (158, 62, 558)),
        ("the fare table", [50 + 12 * d for d in (1, 2, 3)], [62, 74, 86]),
        ("P = 2(L + w) for 7 by 4", (7 + 4, 2 * (7 + 4), 2 * 7 + 2 * 4), (11, 22, 22)),
        ("C = 150n + 40 for 2 tickets", 150 * 2 + 40, 340),
        # 5.5 Turning a formula round
        ("Meera's ride", (170 - 50, Fraction(120, 12)), (120, 10)),
        ("d = (C − 50) ÷ 12 undoes C = 50 + 12d", all(Fraction(50 + 12 * d - 50, 12) == d for d in VALUES), True),
        ("v = u + at with u = 2, a = 3, t = 4", (2 + 3 * 4, Fraction(14 - 2, 3)), (14, 4)),
        ("170 − 50/12 is about 166", (round(170 - Fraction(50, 12)), Fraction(170 - 50, 12)), (166, 10)),
        ("x = (y + 3)/4 undoes y = 4x − 3", all(Fraction(4 * x - 3 + 3, 4) == x for x in VALUES), True),
        # 5.6 More than, less than
        ("Kym and Aarav", (118 >= 120, 120 >= 120), (False, True)),
        ("3x + 4 < 19", (19 - 4, 15 // 3, 3 * 4 + 4, 3 * 6 + 4, holds(lambda x: 3 * x + 4 < 19), holds(lambda x: x < 5)),
         (15, 5, 16, 22, holds(lambda x: x < 5), holds(lambda x: 3 * x + 4 < 19))),
        ("5 − 2x > 11", (11 - 5, Fraction(6, -2), 5 - 2 * -4, holds(lambda x: 5 - 2 * x > 11)),
         (6, -3, 13, holds(lambda x: x < -3))),
        ("the slip x > −3 at x = 0", (5 - 2 * 0, 5 > 11), (5, False)),
        ("7 − 3x ≤ 19", (19 - 7, Fraction(12, -3), holds(lambda x: 7 - 3 * x <= 19)), (12, -4, holds(lambda x: x >= -4))),
        # Callouts and debate
        ("6 bags and 2 marbles balance 20", solve_linear(6, 2, 0, 20), Fraction(3)),
        ("−2x < 8", (holds(lambda x: -2 * x < 8), -2 * 0, -2 * -5, -2 * -10, Fraction(8, -2)),
         (holds(lambda x: x > -4), 0, 10, 20, -4)),
        # Widgets and Atlas lessons
        ("5 bags and 4 marbles balance 19", (19 - 4, Fraction(15, 5), 5 * 3 + 4), (15, 3, 19)),
        ("2b + 1 = 9", (2 * 4 + 1, 9 - 1, 8 // 2, 2 * 4 + 9), (9, 8, 4, 17)),
        ("3b + 2 = 14", solve_linear(3, 2, 0, 14), 4),
        ("a fare of ₹110", (110 - 50, 60 // 12), (60, 5)),
        ("A = 3r + 7 at A = 25", Fraction(25 - 7, 3), 6),
        ("−3x < 12", holds(lambda x: -3 * x < 12), holds(lambda x: x > -4)),
        ("2 < 5 and −2 > −5", (2 < 5, -2 > -5), (True, True)),
        # Cards
        ("2b + 6 = 14", solve_linear(2, 6, 0, 14), 4),
        ("Kym and her brother", (solve_linear(2, 3, 0, 21), 9 + 12), (9, 21)),
        ("4x − 1 = 11 at x = 3", 4 * 3 - 1, 11),
        ("× 6 − 9 = 45", (45 + 9, 54 // 6), (54, 9)),
        ("÷ 3 + 4 = 10", ((10 - 4) * 3, Fraction(18, 3) + 4), (18, 10)),
        ("the slips for ÷ 3 + 4 = 10", ((10 + 4) * 3, Fraction(10 - 4, 3), 10 * 3 - 4), (42, 2, 26)),
        ("9x + 2 = 4x + 27", (solve_linear(9, 2, 4, 27), 9 * 5 + 2, 4 * 5 + 27), (5, 47, 47)),
        ("8x − 7 = 3x + 13", solve_linear(8, -7, 3, 13), 4),
        ("T = 199 + 2m at m = 30", 199 + 2 * 30, 259),
        ("the square of side 5", (4 * 5, 5 ** 2), (20, 25)),
        ("P = 2(L + w) for 9 by 6", 2 * (9 + 6), 30),
        ("2x + 1 = 9", solve_linear(2, 1, 0, 9), 4),
        ("w = (P − 2L)/2 undoes P = 2L + 2w",
         all(Fraction(2 * l + 2 * w - 2 * l, 2) == w for l in VALUES for w in VALUES), True),
        ("p ≤ 8", holds(lambda p: p <= 8, range(0, 12)), list(range(0, 9))),
        ("2x − 3 ≥ 7", holds(lambda x: 2 * x - 3 >= 7, range(-10, 11)), holds(lambda x: x >= 5, range(-10, 11))),
        ("−4x > 20", holds(lambda x: -4 * x > 20, range(-10, 11)), holds(lambda x: x < -5, range(-10, 11))),
        # School unit 7
        ("u when v = 13, a = 6, s = 10", (13 ** 2, 2 * 6 * 10, 169 - 120, isqrt(49), 7 ** 2 + 120), (169, 120, 49, 7, 169)),
        ("5(2x − 1) = 3(x + 4) + 4", (solve_linear(10, -5, 3, 16), 3 * 4 + 4, 5 * (6 - 1), 3 * (3 + 4) + 4), (3, 16, 25, 25)),
        ("14 − 3x ≥ 2", (2 - 14, Fraction(-12, -3), 14 - 12, 14 - 15, max(holds(lambda x: 14 - 3 * x >= 2, range(-10, 11)))),
         (-12, 4, 2, -1, 4)),
        ("x = (y + 2)/(y − 3) undoes y = (3x + 2)/(x − 1)",
         all(Fraction(Fraction(3 * x + 2, x - 1) + 2) / (Fraction(3 * x + 2, x - 1) - 3) == x for x in range(2, 9)), True),
    ]


def answers():
    """Chapter 5's turn answers and its cards' check answers, computed."""
    return {
        "ch05-s1-turn": (31 + 4) // 5,
        "ch05-s2-turn": f"x = {solve_linear(5, 3, 2, 18)}",
        "ch05-s3-turn": f"x = {3 * 5 + 4}",
        "ch05-s4-turn": "C = 150n + 40",
        "ch05-s5-turn": "x = (y + 3)/4",
        "ch05-s6-turn": f"x >= {Fraction(19 - 7, -3)}",
        "equation-check": "yes" if 4 * 3 - 1 == 11 else "no",
        "inverse-operation-check": (10 - 4) * 3,
        "solving-equations-check": f"x = {solve_linear(8, -7, 3, 13)}",
        "formula-check": 2 * (9 + 6),
        "subject-of-a-formula-check": "w = (P - 2L)/2",
        "inequality-check": f"x < {Fraction(20, -4)}",
    }
