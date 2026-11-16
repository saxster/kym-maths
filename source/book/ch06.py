"""
Chapter 6, written by hand to docs/CONTENT_BRIEF.md. It carries school unit 11.

Each section teaches one idea in nine steps, in this order: question, idea, picture, reason, name,
example, mistake, turn, sayBack. A section's `teaches` lists the concept cards whose names first
appear in its `name` step. `build(k)` returns the chapter and `cards(k)` its concept cards; both take the
exporter's answer-key helpers. Every section starts from matchsticks, tiles or seats before any letter.

`schoolTopics` and `schoolQuestions` rewrite the topic summaries, worked examples and faded prompts of
school unit 11. The answer keys and stuck sheets stay in the exporter.
"""

from book.arithmetic import Fraction


def terms(first, step, count):
    """The first `count` terms of the list that starts at `first` and adds `step` each time."""
    return [first + step * i for i in range(count)]


def gaps(values):
    """Each term taken from the next one."""
    return [b - a for a, b in zip(values, values[1:])]


def nth(rule, count=6):
    """The rule's terms for positions 1 to `count`."""
    return [rule(n) for n in range(1, count + 1)]


def position(rule_a, rule_b, value):
    """The position n with rule_a·n + rule_b = value, as a Fraction."""
    return Fraction(value - rule_b, rule_a)


def build(k):
    return {
        "number": 6,
        "title": "Sequences and the nth term",
        "subtitle": "School book chapter 11 · Term-to-term rules, the nth term, quadratic sequences and adding a staircase",
        "hookSummary": "A row of 10 squares made of matchsticks needs 31 matches, not 40. "
                       "How many does a row of 100 squares need, without counting?",
        "beyondSchoolBook": False,
        "skillCard": {
            "skill": "Finding and using the nth term of a sequence",
            "sheCan": {
                "prompt": "With no calculator: find the nth term of 6, 11, 16, 21. Is 100 a term of it? Work out 1 + 2 + 3 + … + 50.",
                "answer": "5n + 1. No, because 5n + 1 = 100 gives n = 19.8. 1275.",
            },
            "whyItMatters": "A rule for the nth term jumps straight to the 100th term without writing out the 99 before it. "
                            "The same habit, finding the rule behind a list, is how a line drawn on a grid is read in the next chapter.",
            "standsOn": [
                "Chapter 4: expressions and substitution",
                "Chapter 5: solving an equation",
                "Square numbers and the times tables",
            ],
            "unlocks": [
                "Chapter 7: lines drawn on a grid, whose points go up in equal steps",
                "Adding up equal steps, as in saving the same amount each month",
                "Later chapters on sequences that grow by multiplying",
            ],
        },
        "intuitionToFormula": {
            "concreteAction": "Set the terms to 5, the first term to 1 and the common difference to 1. "
                              "The red columns make a staircase 1, 2, 3, 4, 5 high.",
            "ahaInvariant": "A blue copy of the staircase, turned upside down, fills the gaps above it. "
                            "Every column is then 6 high, so the rectangle holds 5 × 6 = 30 squares and one staircase holds 15.",
            "formulaDisplay": "Tₙ = a + (n − 1)d   and   1 + 2 + … + n = n(n + 1) ÷ 2",
            "termMappings": [
                {"symbol": "a, a + d, a + 2d, …", "visualPart": "The red columns", "colorRole": "red",
                 "meaning": "The terms of the sequence"},
                {"symbol": "the same terms in reverse", "visualPart": "The blue columns", "colorRole": "blue",
                 "meaning": "A copy turned upside down"},
                {"symbol": "Tₙ = a + (n − 1)d", "visualPart": "The green line", "colorRole": "green",
                 "meaning": "The nth term of the red staircase"},
                {"symbol": "n(first + last) ÷ 2", "visualPart": "The amber line", "colorRole": "amber",
                 "meaning": "Half the rectangle is the sum of the terms"},
            ],
            "atlasFigureRef": "maths/ch06-sequences-gauss/index.html",
        },
        "sections": [
            {
                "heading": "6.1 What comes next?",
                "teaches": ["sequence", "term-to-term-rule"],
                "steps": [
                    {"kind": "question",
                     "text": "Kym makes a row of squares from matchsticks. 1 square uses 4 matches, 2 squares use 7 and 3 squares use 10. "
                             "How many matches do 4 squares use? And 10 squares?"},
                    {"kind": "idea",
                     "text": "Each new square adds 3 matches, so 4 squares use 13. "
                             "Keep adding 3: 16, 19, 22, 25, 28 and 31. A row of 10 squares uses 31 matches."},
                    {"kind": "picture",
                     "text": "Draw the rows of 1, 2, 3 and 4 squares, one under another. Write the count of matches beside each row: 4, 7, 10, 13. "
                             "Between each pair of counts, write + 3."},
                    {"kind": "reason",
                     "text": "Why 3 and not 4? The first square needs 4 matches. "
                             "Each square after it borrows its left side from the square before, so it needs only 3 new matches."},
                    {"kind": "name",
                     "text": "A list of numbers made by a rule is called a sequence. Each number in it is a term. "
                             "A rule that makes each term from the one before, like \"add 3\", is a term-to-term rule. "
                             "The first term and the term-to-term rule fix every term after them."},
                    {"kind": "example",
                     "text": "Start at 2 and double each time: 2, 4, 8, 16, 32. The term-to-term rule is \"multiply by 2\". "
                             "Start at 50 and take away 6 each time: 50, 44, 38, 32. The rule there is \"subtract 6\"."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to say 10 squares need 10 × 4 = 40 matches. "
                             "That counts each shared side twice. A row of 10 squares has 9 shared sides, and 40 − 9 = 31."},
                    {"kind": "turn",
                     "text": "A sequence starts 3, 10, 17, 24. What is the next term?",
                     "answer": "31",
                     "answerKey": k.one(k.num("31"), accepts=["31", "= 31", "the next term is 31"], rejects=["28", "30", "38"])},
                    {"kind": "sayBack",
                     "text": "A sequence follows a rule, and a term-to-term rule makes each term from the one before."},
                ],
            },
            {
                "heading": "6.2 Equal steps",
                "teaches": ["common-difference", "arithmetic-sequence", "geometric-sequence"],
                "steps": [
                    {"kind": "question",
                     "text": "Look at 5, 9, 13, 17, 21 and at 2, 4, 8, 16, 32. Both lists grow. "
                             "Which one grows by the same amount every time?"},
                    {"kind": "idea",
                     "text": "Take each term away from the next one. For the first list the gaps are 4, 4, 4 and 4. "
                             "For the second they are 2, 4, 8 and 16. Only the first list grows in equal steps."},
                    {"kind": "picture",
                     "text": "Draw each list as a row of columns, as tall as its terms. "
                             "The first row climbs like a staircase with every step 4 high. The second row's steps keep doubling."},
                    {"kind": "reason",
                     "text": "Why look at the gaps? Equal gaps mean the term-to-term rule is \"add the same number\". "
                             "Then you can jump ahead without listing every term, as the next section shows."},
                    {"kind": "name",
                     "text": "When the gap between neighbouring terms is always the same, that gap is the common difference. "
                             "A sequence with a common difference is an arithmetic sequence. "
                             "A sequence that multiplies by the same number each time, like 2, 4, 8, 16, is a geometric sequence."},
                    {"kind": "example",
                     "text": "In 7, 4, 1, −2, −5 each term is 3 less than the one before. "
                             "So it is an arithmetic sequence with common difference −3, and its next term is −8."},
                    {"kind": "mistake",
                     "text": "One slip is to give the common difference of 40, 35, 30 as 5. "
                             "The terms go down, and 35 − 40 = −5. "
                             "Another slip is to call 1, 4, 9, 16 arithmetic. Its gaps are 3, 5 and 7, which are not equal."},
                    {"kind": "turn",
                     "text": "What is the common difference of 11, 8, 5, 2?",
                     "answer": "−3",
                     "answerKey": k.one(k.num("-3"), accepts=["−3", "-3", "d = −3"], rejects=["3", "2", "−2"])},
                    {"kind": "sayBack",
                     "text": "An arithmetic sequence goes up or down by its common difference every time."},
                ],
            },
            {
                "heading": "6.3 Jumping to any term",
                "teaches": ["nth-term"],
                "steps": [
                    {"kind": "question",
                     "text": "The matchstick rows used 4, 7, 10 and 13 matches. "
                             "How many matches does a row of 100 squares use, without listing 100 terms?"},
                    {"kind": "idea",
                     "text": "The counts go up by 3, like the 3 times table: 3, 6, 9, 12. "
                             "Each count is 1 more than that: 4, 7, 10, 13. So 100 squares use 3 × 100 + 1 = 301 matches."},
                    {"kind": "picture",
                     "text": "Make a table with three rows. The top row is the position: 1, 2, 3, 4. "
                             "The middle row is 3 times the position: 3, 6, 9, 12. The bottom row is the matches: 4, 7, 10, 13."},
                    {"kind": "reason",
                     "text": "Why 3 times the position? Every square adds 3 matches, so n squares add up to 3n of them. "
                             "The + 1 is the single match on the far left that starts the row."},
                    {"kind": "name",
                     "text": "A rule that gives a term from its position n is called the nth term, or the position-to-term rule. "
                             "For the matchsticks it is 3n + 1. "
                             "In an arithmetic sequence, the number in front of n is the common difference."},
                    {"kind": "example",
                     "text": "Find the nth term of 5, 8, 11, 14. The common difference is 3, so start from 3n: 3, 6, 9, 12. "
                             "Each term is 2 more, so the nth term is 3n + 2. The 20th term is 3 × 20 + 2 = 62."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to write n + 3, because the terms go up by 3. That gives 4, 5, 6, 7. "
                             "Another slip is to add the first term, as in 3n + 5, which starts at 8. "
                             "Test n = 1 and n = 2 before you trust a rule."},
                    {"kind": "turn",
                     "text": "Find the nth term of 9, 14, 19, 24.",
                     "answer": "5n + 4",
                     "answerKey": k.one(k.forms("5n+4", "4+5n"), accepts=["5n + 4", "4 + 5n", "Tₙ = 5n + 4"],
                                        rejects=["n + 5", "5n + 9", "5n"])},
                    {"kind": "sayBack",
                     "text": "Start the nth term from the common difference times n, then fix it so the first term is right."},
                ],
            },
            {
                "heading": "6.4 Is it in the list?",
                "teaches": [],
                "steps": [
                    {"kind": "question",
                     "text": "In a hall, row 1 has 12 seats and each row has 3 more seats than the row in front. "
                             "Which row has 57 seats? Does any row have exactly 50?"},
                    {"kind": "idea",
                     "text": "The rows have 12, 15, 18, … seats. They go up by 3, so start from 3n: 3, 6, 9. "
                             "Each row has 9 more than that, so row n has 3n + 9. For 57 seats, 3n + 9 = 57, so 3n = 48 and n = 16. For 50 seats, 3n = 41 and n = 13⅔."},
                    {"kind": "picture",
                     "text": "Draw a number line and mark the seat counts 12, 15, 18 and on up to 57. "
                             "The number 50 falls between 48 and 51, which are rows 13 and 14."},
                    {"kind": "reason",
                     "text": "Why does 13⅔ mean no? Positions count rows: the 1st, the 2nd, the 3rd. "
                             "There is no row 13⅔, so no row has exactly 50 seats."},
                    {"kind": "name",
                     "text": "To test whether a number is a term, set the nth term equal to it and solve the equation. "
                             "A whole number answer is its position. Any other answer means it is not a term."},
                    {"kind": "example",
                     "text": "Is 99 a term of 7n − 6? Solve 7n − 6 = 99. Then 7n = 105, so n = 15. "
                             "Yes, 99 is the 15th term. Check: 7 × 15 − 6 = 99."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to put 50 in place of n: 3 × 50 + 9 = 159. "
                             "That finds how many seats row 50 has. It does not find which row has 50 seats."},
                    {"kind": "turn",
                     "text": "Which term of 5n − 2 is 83?",
                     "answer": "the 17th",
                     "answerKey": k.one(k.num("17"), accepts=["17", "the 17th", "n = 17"], rejects=["413", "16.2", "81"])},
                    {"kind": "sayBack",
                     "text": "Set the nth term equal to the number and solve. A whole number answer is its position."},
                ],
            },
            {
                "heading": "6.5 When the steps grow",
                "teaches": ["quadratic-sequence"],
                "steps": [
                    {"kind": "question",
                     "text": "Kym builds squares of tiles: 1 tile, then 4, then 9, then 16. "
                             "The gaps are 3, 5 and 7, so they are not equal. Is there still a rule?"},
                    {"kind": "idea",
                     "text": "The gaps 3, 5 and 7 are the first differences. Find the gaps between them: 5 − 3 = 2 and 7 − 5 = 2. Those are equal. "
                             "The tile counts are 1 × 1, 2 × 2, 3 × 3 and 4 × 4, so the nth one is n²."},
                    {"kind": "picture",
                     "text": "Draw the squares of 1, 4 and 9 tiles inside one another. "
                             "Each new square adds an L-shaped border of 3, then 5, then 7 tiles."},
                    {"kind": "reason",
                     "text": "Why does each border grow by 2? A 3 by 3 square becomes 4 by 4 when you add a row of 3, a column of 3 and 1 corner. "
                             "From n by n, the border is n + n + 1 = 2n + 1 tiles, which goes up by 2 each time."},
                    {"kind": "name",
                     "text": "The gaps between the first differences are the second differences. "
                             "When the second differences are equal, and not 0, the list is a quadratic sequence. "
                             "Its nth term has an n², and the number in front of n² is half the second difference."},
                    {"kind": "example",
                     "text": "Take 2, 6, 12, 20, 30. The first differences are 4, 6, 8, 10, and the second differences are all 2, so start from n². "
                             "Take away 1, 4, 9, 16, 25 to leave 1, 2, 3, 4, 5, which is n. So the nth term is n² + n."},
                    {"kind": "mistake",
                     "text": "The usual slip is to put the second difference itself in front of n². "
                             "With a second difference of 2, the rule 2n² gives 2, 8, 18, not 1, 4, 9. "
                             "Halve the second difference first."},
                    {"kind": "turn",
                     "text": "Find the nth term of 4, 7, 12, 19, 28.",
                     "answer": "n² + 3",
                     "answerKey": k.one(k.forms("n^2+3", "3+n^2"), accepts=["n² + 3", "n^2 + 3", "3 + n²"],
                                        rejects=["2n² + 3", "n² + 2", "3n + 1"])},
                    {"kind": "sayBack",
                     "text": "Equal second differences mean a quadratic sequence, with half the second difference in front of n²."},
                ],
            },
            {
                "heading": "6.6 Adding up a staircase",
                "figure": True,
                "teaches": ["triangular-number"],
                "steps": [
                    {"kind": "question",
                     "text": "A teacher once asked a class to add every whole number from 1 to 100. "
                             "A boy called Gauss gave the answer in about a minute. How could he be so quick?"},
                    {"kind": "idea",
                     "text": "Try 1 to 10 first. Pair the first number with the last: 1 + 10 = 11, then 2 + 9 = 11, and so on. "
                             "There are 5 pairs of 11, which make 55. From 1 to 100 there are 50 pairs of 101, which make 5050."},
                    {"kind": "picture",
                     "text": "In the figure, set the terms to 5, the first term to 1 and the common difference to 1. "
                             "The red staircase 1, 2, 3, 4, 5 and the blue copy above it make a rectangle 5 wide and 6 high."},
                    {"kind": "reason",
                     "text": "Why is every column the same height? Moving right, the red step rises by 1 and the blue step falls by 1. "
                             "So each column stays 6 high, the rectangle holds 30 squares, and one staircase holds 15."},
                    {"kind": "name",
                     "text": "The totals 1, 3, 6, 10, 15 of 1 + 2 + … + n are the triangular numbers, and the nth one is n(n + 1) ÷ 2. "
                             "The same pairing adds any arithmetic sequence. "
                             "Multiply the number of terms by the first term plus the last, then halve."},
                    {"kind": "example",
                     "text": "Add 2 + 5 + 8 + … + 29. The nth term is 3n − 1, and 3n − 1 = 29 gives n = 10, so there are 10 terms. "
                             "The sum is 10 × (2 + 29) ÷ 2 = 155."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to forget the halving and say 1 + 2 + … + 100 = 100 × 101 = 10,100. "
                             "The rectangle holds two staircases, so that counts every number twice."},
                    {"kind": "turn",
                     "text": "Work out 1 + 2 + 3 + … + 40.",
                     "answer": "820",
                     "answerKey": k.one(k.num("820"), accepts=["820", "= 820", "40 × 41 ÷ 2 = 820"], rejects=["1640", "800", "780"])},
                    {"kind": "sayBack",
                     "text": "To add equal steps, multiply the number of terms by the first term plus the last, and halve."},
                ],
            },
        ],
        "callouts": [
            {"kind": "predict", "title": "Predict first",
             "body": "Predict 1 + 2 + 3 + … + 8 in your head. "
                     "Then set the terms to 8, the first term to 1 and the common difference to 1, and read the amber line."},
            {"kind": "check", "title": "Explain it",
             "body": "Explain to a friend why a row of 10 matchstick squares needs 31 matches and not 40."},
            {"kind": "careful", "title": "Test your rule",
             "body": "Before you use a rule to go further, try it on the terms you already have. "
                     "Every one of them should fit."},
        ],
        "debate": {
            "id": "debate-ch06-sequences",
            "oupUnitNumber": 11,
            "title": "Twice as many squares",
            "contextPrompt": "A row of 10 matchstick squares uses 31 matches, and the nth term is 3n + 1. "
                             "Ishaan and Tara work out the matches for a row of 20 squares.",
            "speakerAName": "Ishaan",
            "speakerAClaim": "20 squares is twice 10 squares, so it needs twice 31. That is 62 matches.",
            "speakerBName": "Tara",
            "speakerBClaim": "Put n = 20 in the nth term. 3 × 20 + 1 = 61 matches.",
            "choices": [
                {"id": "ch06-a", "speakerLabel": "Ishaan is right (62)",
                 "reasoningStatement": "Twice the squares always needs twice the matches.",
                 "isCorrect": False,
                 "socraticRebuttal": "Put two rows of 10 squares end to end. Where they meet, two matches stand side by side. "
                                     "Do you need both of them?"},
                {"id": "ch06-b", "speakerLabel": "Tara is right (61)",
                 "reasoningStatement": "The nth term gives any term from its position.",
                 "isCorrect": True,
                 "socraticRebuttal": "Yes. Doubling 3n + 1 gives 6n + 2, which counts the starting match twice. "
                                     "The real rule adds that match only once."},
                {"id": "ch06-c", "speakerLabel": "Neither. It is 80.",
                 "reasoningStatement": "Each square has 4 sides, and 20 × 4 = 80.",
                 "isCorrect": False,
                 "socraticRebuttal": "Count the matches in a row of 2 squares. Is it 8, or does one side belong to both?"},
            ],
            "invariantTakeaway": "An nth term like 3n + 1 does not double when n doubles. Find any term by putting its position into the rule.",
        },
        "keyTerms": ["Sequence", "Term-to-term rule", "Common difference", "Arithmetic sequence", "Geometric sequence",
                     "nth term", "Quadratic sequence", "Triangular number"],
        "widgets": ["w_gauss_staircase_sum", "w_sequence_difference_engine"],
        "widgetText": {
            "w_gauss_staircase_sum": {
                "title": "Two staircases make a rectangle",
                "challengePrompt": "Set the terms to 6, the first term to 1 and the common difference to 1. "
                                   "Predict 1 + 2 + … + 6 before you read the amber line.",
                "cutaway": "The red staircase 1 to 6 and its blue copy turned upside down make a rectangle 6 wide and 7 high. "
                           "That is 42 squares, so one staircase is 21.",
                "idealised": "The rule: 1 + 2 + … + n = n(n + 1) ÷ 2",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Set the terms to 4, the first term to 1 and the common difference to 1."},
                    {"title": "2. Notice", "caption": "Every column, red and blue together, is 5 high."},
                    {"title": "3. Match the rule", "caption": "The rectangle is 4 × 5 = 20, and half of it is 10, which is 1 + 2 + 3 + 4."},
                    {"title": "4. Push it further", "caption": "Set the first term to 3 and the common difference to 2. Are the columns still all the same height?"},
                    {"title": "5. Draw it", "caption": "Draw the two staircases for 2 + 4 + 6 + 8 in your journal and find the sum."},
                ],
            },
            "w_sequence_difference_engine": {
                "title": "Finding the rule from the gaps",
                "challengePrompt": "Write down 2, 6, 12, 20, 30. Predict whether its first differences or its second differences are equal.",
                "cutaway": "The first differences are 4, 6, 8 and 10. The second differences are all 2, so the nth term starts with n².",
                "idealised": "The rule: equal first differences d give dn + c, and equal second differences 2a give an² + …",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Write the sequence 3, 7, 11, 15, 19 and the gaps under it."},
                    {"title": "2. Notice", "caption": "The gaps are all 4, so the nth term starts with 4n."},
                    {"title": "3. Match the rule", "caption": "4n gives 4, 8, 12, so take 1 away: the nth term is 4n − 1."},
                    {"title": "4. Push it further", "caption": "Try 1, 4, 9, 16, 25. The first gaps change, so find the gaps of the gaps."},
                    {"title": "5. Draw it", "caption": "Draw the tile squares for 1, 4 and 9, and colour each new L-shaped border."},
                ],
            },
        },
        "atlasLessons": [
            {
                "title": "Chapter 6 · Equal steps",
                "question": "How can you tell whether a list of numbers goes up in equal steps?",
                "explanation": "Take each term away from the next one. "
                               "If every gap is the same, the list is an arithmetic sequence and that gap is its common difference.",
                "limits": "The rule: equal gaps d give the nth term dn + c",
            },
            {
                "title": "Chapter 6 · Jumping to the 100th term",
                "question": "Why does the number in front of n match the gap between terms?",
                "explanation": "Each step along the list adds the same gap d. "
                               "After n steps, the gaps add up to dn, and a fixed number corrects the start.",
                "limits": "The rule: Tₙ = a + (n − 1)d",
            },
            {
                "title": "Chapter 6 · Two staircases make a rectangle",
                "question": "Why is 1 + 2 + … + n half of n × (n + 1)?",
                "explanation": "Turn a copy of the staircase upside down and set it on top. "
                               "Every column then reaches n + 1, so the two staircases fill a rectangle n by n + 1.",
                "limits": "The rule: 1 + 2 + … + n = n(n + 1) ÷ 2",
            },
        ],
        "visualMathTips": {
            "tip-gauss-sum": {
                "title": "Why 1 + 2 + … + n is half of n(n + 1)",
                "visualIntuition": "Build a staircase of 1, 2, 3, … up to n blocks. Make a copy and turn it upside down.",
                "ahaMoment": "Set the copy on top, and every column reaches n + 1. "
                             "The two staircases fill a rectangle n by n + 1, so one staircase is half of it.",
                "formula": "1 + 2 + … + n = n(n + 1) ÷ 2",
            },
        },
        "schoolTopics": {
            "11.1": "A term-to-term rule makes each term from the one before, like add 4 or multiply by 2. "
                    "Equal gaps make an arithmetic sequence. Multiplying by the same number each time makes a geometric sequence.",
            "11.2": "The nth term gives any term from its position n. For equal gaps d it is dn + c. "
                    "Equal second differences give a quadratic sequence with an n². "
                    "To add an arithmetic sequence, multiply the number of terms by the first plus the last, then halve.",
        },
        "schoolQuestions": {
            "q-oup-ch11-sb": {
                "workedExample": "Step 1: The gaps are all 4, so start from 4n: 4, 8, 12. Each term is 3 more, so Tₙ = 4n + 3.\n"
                                 "Step 2: The 20th term is 4 × 20 + 3 = 83.\n"
                                 "Step 3: Pair the first and last terms. There are 20 terms, so 10 pairs of 7 + 83 = 90.\n"
                                 "Step 4: The sum of the first 20 terms is 10 × 90 = 900.",
                "fadedPrompt": "Tₙ = 4n + 3 and the 20th term is 83. The sum is 10 × (7 + 83) = ___.",
            },
            "q-oup-ch11-wb-focus": {
                "workedExample": "Step 1: Set the nth term equal to 150. 4n + 3 = 150.\n"
                                 "Step 2: Take 3 from both sides. 4n = 147.\n"
                                 "Step 3: Divide by 4. n = 36.75, which is not a whole number.\n"
                                 "Step 4: So 150 is not a term. The 36th term is 147 and the 37th is 151.",
                "fadedPrompt": "4n + 3 = 150 gives 4n = 147 and n = ___, so 150 ___ a term.",
            },
            "q-oup-ch11-wb-practice": {
                "workedExample": "Step 1: The first differences are 5, 7, 9, 11, and the second differences are all 2.\n"
                                 "Step 2: Half of 2 is 1, so start from n²: 1, 4, 9, 16, 25.\n"
                                 "Step 3: Take n² away from each term: 2, 4, 6, 8, 10. That is 2n.\n"
                                 "Step 4: So Tₙ = n² + 2n. Check the 5th term: 25 + 10 = 35.",
                "fadedPrompt": "The terms minus n² are 2, 4, 6, 8, 10, so Tₙ = n² + ___.",
            },
            "q-oup-ch11-wb-challenge": {
                "workedExample": "Step 1: Pair the first number with the last. 1 + 200 = 201, and 2 + 199 = 201.\n"
                                 "Step 2: There are 200 numbers, so there are 100 pairs.\n"
                                 "Step 3: The sum is 100 × 201 = 20,100.\n"
                                 "Step 4: Check with the rule n(n + 1) ÷ 2: 200 × 201 ÷ 2 = 20,100.",
                "fadedPrompt": "100 pairs, each adding to 201, make ___.",
            },
        },
    }


def cards(k):
    """The concept cards this chapter teaches."""
    return {
        "sequence": {
            "name": "Sequence",
            "aliases": ["sequence", "sequences"],
            "oneSentence": "A list of numbers in order, made by a rule, where each number is called a term.",
            "picture": "The odd numbers 1, 3, 5, 7, 9 in a row, each one 2 more than the one before.",
            "steps": [
                "Write the terms in order, separated by commas.",
                "Look for the rule that makes each term.",
                "Use the rule to find the terms that come next.",
            ],
            "workedExample": "The rule is \"start at 1 and multiply by 3\". The terms are 1, 3, 9, 27 and 81.",
            "check": {
                "prompt": "A sequence starts at 6 and adds 5 each time. What is its 4th term?",
                "answer": "21",
                "answerKey": k.one(k.num("21"), accepts=["21", "= 21", "the 4th term is 21"], rejects=["26", "20", "16"]),
            },
            "mixUp": {
                "name": "a set of numbers",
                "how": "In a sequence the order matters. 1, 3, 5 and 5, 3, 1 are different sequences, but the same set.",
            },
            "standsOn": [],
        },
        "term-to-term-rule": {
            "name": "Term-to-term rule",
            "aliases": ["term-to-term rule", "term-to-term rules"],
            "oneSentence": "A rule that makes each term of a sequence from the term before it.",
            "picture": "A chain of boxes 5, 8, 11, 14, with an arrow marked + 3 between each pair.",
            "steps": [
                "Look at how each term follows from the one before.",
                "Write the rule, such as add 3 or multiply by 2.",
                "Say the first term too, because the rule needs a start.",
            ],
            "workedExample": "In 80, 40, 20, 10, each term is half the one before. The term-to-term rule is divide by 2.",
            "check": {
                "prompt": "A sequence starts at 1, and its term-to-term rule is multiply by 2 then add 1. What is the 4th term?",
                "answer": "15",
                "answerKey": k.one(k.num("15"), accepts=["15", "= 15", "the 4th term is 15"], rejects=["7", "31", "9"]),
            },
            "mixUp": {
                "with": "nth-term",
                "how": "A term-to-term rule needs the term before. The nth term gives any term straight from its position.",
            },
            "standsOn": ["sequence"],
        },
        "common-difference": {
            "name": "Common difference",
            "aliases": ["common difference", "common differences"],
            "oneSentence": "The amount added each time in a sequence that goes up or down in equal steps.",
            "picture": "A staircase whose steps are all the same height. That height is the common difference.",
            "steps": [
                "Take each term away from the term after it.",
                "If every answer is the same, that answer is the common difference.",
                "If the terms go down, the common difference is negative.",
            ],
            "workedExample": "In 20, 17, 14, 11, each gap is 17 − 20 = −3. The common difference is −3.",
            "check": {
                "prompt": "What is the common difference of 2.5, 4, 5.5, 7?",
                "answer": "1.5",
                "answerKey": k.one(k.num("1.5"), accepts=["1.5", "d = 1.5", "1.5 each time"], rejects=["2.5", "−1.5", "4.5"]),
            },
            "mixUp": {
                "name": "subtracting the wrong way",
                "how": "Always take a term from the one after it. For 9, 6, 3, that is 6 − 9 = −3, not 3.",
            },
            "standsOn": ["sequence"],
        },
        "arithmetic-sequence": {
            "name": "Arithmetic sequence",
            "aliases": ["arithmetic sequence", "arithmetic sequences", "linear sequence", "linear sequences"],
            "oneSentence": "A sequence that goes up or down by the same common difference each time.",
            "picture": "Fence posts placed every 4 m along a road, at 0 m, 4 m, 8 m and 12 m.",
            "steps": [
                "Find the gaps between neighbouring terms.",
                "Check that every gap is the same.",
                "If they are, the sequence is arithmetic, and its nth term has the form dn + c.",
            ],
            "workedExample": "6, 10, 14, 18 has gaps of 4 each time, so it is arithmetic. 3, 6, 12, 24 has gaps 3, 6, 12, so it is not.",
            "check": {
                "prompt": "Which of these is an arithmetic sequence: 1, 4, 9, 16 or 1, 4, 7, 10?",
                "answer": "1, 4, 7, 10",
                "answerKey": k.one(k.seq("1", "4", "7", "10"), accepts=["1, 4, 7, 10", "1,4,7,10"],
                                   rejects=["1, 4, 9, 16", "1, 4, 9", "4, 7, 10"]),
            },
            "mixUp": {
                "with": "geometric-sequence",
                "how": "An arithmetic sequence adds the same number each time. A geometric sequence multiplies by the same number.",
            },
            "standsOn": ["sequence", "common-difference"],
        },
        "geometric-sequence": {
            "name": "Geometric sequence",
            "aliases": ["geometric sequence", "geometric sequences", "common ratio"],
            "oneSentence": "A sequence that multiplies by the same number each time.",
            "picture": "A sheet of paper folded in half again and again. The layers go 1, 2, 4, 8, 16.",
            "steps": [
                "Divide each term by the term before it.",
                "If every answer is the same, the sequence is geometric.",
                "That answer is the common ratio.",
            ],
            "workedExample": "In 5, 15, 45, 135, each term is 3 times the one before. The common ratio is 3, and the next term is 405.",
            "check": {
                "prompt": "What is the next term of the geometric sequence 3, 6, 12, 24?",
                "answer": "48",
                "answerKey": k.one(k.num("48"), accepts=["48", "= 48", "the next term is 48"], rejects=["36", "30", "27"]),
            },
            "mixUp": {
                "with": "arithmetic-sequence",
                "how": "2, 4, 6, 8 adds 2 each time, so it is arithmetic. 2, 4, 8, 16 doubles each time, so it is geometric.",
            },
            "standsOn": ["sequence"],
        },
        "nth-term": {
            "name": "nth term",
            "aliases": ["nth term", "nth terms", "position-to-term rule", "position-to-term rules", "Tₙ"],
            "oneSentence": "A rule that gives any term of a sequence from its position n.",
            "picture": "A table of positions 1, 2, 3, 4 above the terms 7, 9, 11, 13, with the rule 2n + 5 beside it.",
            "steps": [
                "Find the common difference d.",
                "Write dn, and list its values for n = 1, 2, 3.",
                "Find what to add to dn to reach each term.",
                "Test the rule with n = 1 and n = 2.",
            ],
            "workedExample": "For 10, 13, 16, 19, the common difference is 3. 3n gives 3, 6, 9, so add 7. The nth term is 3n + 7.",
            "check": {
                "prompt": "Find the nth term of 1, 6, 11, 16.",
                "answer": "5n − 4",
                "answerKey": k.one(k.forms("5n-4", "-4+5n"), accepts=["5n − 4", "5n - 4", "Tₙ = 5n − 4"],
                                   rejects=["5n + 1", "n + 5", "5n − 1"]),
            },
            "mixUp": {
                "with": "term-to-term-rule",
                "how": "\"Add 5\" is a term-to-term rule. 5n − 4 is the nth term, and it gives the 100th term at once: 496.",
            },
            "standsOn": ["sequence", "expression"],
        },
        "quadratic-sequence": {
            "name": "Quadratic sequence",
            "aliases": ["quadratic sequence", "quadratic sequences", "second difference", "second differences"],
            "oneSentence": "A sequence whose second differences are equal and not 0, so its nth term has an n².",
            "picture": "Squares of tiles 1, 4, 9, 16. Each new square adds an L-shaped border 2 tiles bigger than the last.",
            "steps": [
                "Find the first differences, then the differences between them.",
                "If the second differences are equal, halve one to get the number in front of n².",
                "Take that many n² away from each term.",
                "Find the nth term of what is left, and add it on.",
            ],
            "workedExample": "For 3, 9, 19, 33, the second differences are all 4. Half of 4 is 2, so start with 2n²: 2, 8, 18, 32. "
                             "What is left is 1 each time, so the nth term is 2n² + 1.",
            "check": {
                "prompt": "Find the nth term of 0, 3, 8, 15, 24.",
                "answer": "n² − 1",
                "answerKey": k.one(k.forms("n^2-1", "-1+n^2"), accepts=["n² − 1", "n^2 - 1", "Tₙ = n² − 1"],
                                   rejects=["n² + 1", "2n² − 1", "3n − 3"]),
            },
            "mixUp": {
                "name": "using the whole second difference",
                "how": "A second difference of 6 means 3n², not 6n². The number in front of n² is half the second difference.",
            },
            "standsOn": ["nth-term", "common-difference"],
        },
        "triangular-number": {
            "name": "Triangular number",
            "aliases": ["triangular number", "triangular numbers"],
            "oneSentence": "A number you get by adding 1 + 2 + 3 + … up to some n, which equals n(n + 1) ÷ 2.",
            "picture": "Rows of dots 1, 2, 3, 4 stacked into a triangle. The triangles hold 1, 3, 6 and 10 dots.",
            "steps": [
                "Pair the first and last numbers, which add to n + 1.",
                "Count the pairs, which is half of n.",
                "Multiply: n(n + 1) ÷ 2.",
            ],
            "workedExample": "The 12th triangular number is 1 + 2 + … + 12 = 12 × 13 ÷ 2 = 78.",
            "check": {
                "prompt": "What is the 9th triangular number?",
                "answer": "45",
                "answerKey": k.one(k.num("45"), accepts=["45", "= 45", "9 × 10 ÷ 2 = 45"], rejects=["90", "81", "36"]),
            },
            "mixUp": {
                "name": "a square number",
                "how": "The 4th square number is 4 × 4 = 16. The 4th triangular number is 1 + 2 + 3 + 4 = 10.",
            },
            "standsOn": ["sequence"],
        },
    }


def sums():
    """Every sum chapter 6, its cards and its school unit text state, recomputed. test_book_maths.py checks computed == stated."""
    matches = lambda n: 3 * n + 1
    return [
        # Skill card
        ("6, 11, 16, 21 is 5n + 1", nth(lambda n: 5 * n + 1, 4), [6, 11, 16, 21]),
        ("5n + 1 = 100", position(5, 1, 100), Fraction("19.8")),
        ("1 + … + 50", sum(range(1, 51)), 1275),
        # Hook, bridge and figure
        ("10 squares of matches", (matches(10), 10 * 4), (31, 40)),
        ("the staircase 1 to 5", (terms(1, 1, 5), 1 + 5, 5 * 6, sum(range(1, 6))), ([1, 2, 3, 4, 5], 6, 30, 15)),
        # 6.1 What comes next?
        ("the matchstick rows", nth(matches, 10), [4, 7, 10, 13, 16, 19, 22, 25, 28, 31]),
        ("each new square adds 3", gaps(nth(matches, 4)), [3, 3, 3]),
        ("double from 2", [2 * 2 ** i for i in range(5)], [2, 4, 8, 16, 32]),
        ("subtract 6 from 50", terms(50, -6, 4), [50, 44, 38, 32]),
        ("the shared sides", (10 - 1, 40 - 9), (9, 31)),
        ("3, 10, 17, 24 and next", (gaps([3, 10, 17, 24]), 24 + 7, 24 + 4, 24 + 6, 24 + 14), ([7, 7, 7], 31, 28, 30, 38)),
        # 6.2 Equal steps
        ("the gaps of the two lists", (gaps([5, 9, 13, 17, 21]), gaps([2, 4, 8, 16, 32])), ([4, 4, 4, 4], [2, 4, 8, 16])),
        ("7, 4, 1, −2, −5", (gaps([7, 4, 1, -2, -5]), -5 - 3), ([-3, -3, -3, -3], -8)),
        ("40, 35, 30", gaps([40, 35, 30]), [-5, -5]),
        ("1, 4, 9, 16 is not arithmetic", gaps([1, 4, 9, 16]), [3, 5, 7]),
        ("1, 4, 7, 10 is arithmetic", gaps([1, 4, 7, 10]), [3, 3, 3]),
        ("11, 8, 5, 2", gaps([11, 8, 5, 2]), [-3, -3, -3]),
        # 6.3 Jumping to any term
        ("3n and 3n + 1", (nth(lambda n: 3 * n, 4), nth(matches, 4), matches(100)), ([3, 6, 9, 12], [4, 7, 10, 13], 301)),
        ("5, 8, 11, 14 is 3n + 2", (nth(lambda n: 3 * n + 2, 4), 3 * 20 + 2), ([5, 8, 11, 14], 62)),
        ("the slips n + 3 and 3n + 5", (nth(lambda n: n + 3, 4), 3 * 1 + 5), ([4, 5, 6, 7], 8)),
        ("9, 14, 19, 24 is 5n + 4", nth(lambda n: 5 * n + 4, 4), [9, 14, 19, 24]),
        # 6.4 Is it in the list?
        ("the seats", (nth(lambda n: 3 * n + 9, 3), position(3, 9, 57), 57 - 9, 50 - 9, position(3, 9, 50)),
         ([12, 15, 18], 16, 48, 41, 13 + Fraction(2, 3))),
        ("start from 3n, then 9 more", (nth(lambda n: 3 * n, 3), 12 - 3), ([3, 6, 9], 9)),
        ("rows 13 and 14", (3 * 13 + 9, 3 * 14 + 9, 3 * 16 + 9), (48, 51, 57)),
        ("99 in 7n − 6", (position(7, -6, 99), 99 + 6, 7 * 15 - 6), (15, 105, 99)),
        ("the slip 3 × 50 + 9", 3 * 50 + 9, 159),
        ("83 in 5n − 2", (position(5, -2, 83), 5 * 83 - 2, Fraction(83 - 2, 5), 83 - 2), (17, 413, Fraction("16.2"), 81)),
        # 6.5 When the steps grow
        ("square numbers", (nth(lambda n: n * n, 4), gaps([1, 4, 9, 16]), gaps(gaps([1, 4, 9, 16]))), ([1, 4, 9, 16], [3, 5, 7], [2, 2])),
        ("3 by 3 to 4 by 4", (3 + 3 + 1, 4 * 4 - 3 * 3), (7, 7)),
        ("each border is 2n + 1", all((n + 1) ** 2 - n ** 2 == 2 * n + 1 for n in range(1, 20)), True),
        ("2, 6, 12, 20, 30", (gaps([2, 6, 12, 20, 30]), gaps(gaps([2, 6, 12, 20, 30])), nth(lambda n: n * n + n, 5)),
         ([4, 6, 8, 10], [2, 2, 2], [2, 6, 12, 20, 30])),
        ("what is left after n²", [t - n * n for n, t in zip(range(1, 6), [2, 6, 12, 20, 30])], [1, 2, 3, 4, 5]),
        ("the slip 2n²", nth(lambda n: 2 * n * n, 3), [2, 8, 18]),
        ("4, 7, 12, 19, 28", (gaps(gaps([4, 7, 12, 19, 28])), nth(lambda n: n * n + 3, 5)), ([2, 2, 2], [4, 7, 12, 19, 28])),
        # 6.6 Adding up a staircase
        ("1 to 10 in pairs", (1 + 10, 2 + 9, 5 * 11, sum(range(1, 11))), (11, 11, 55, 55)),
        ("1 to 100 in pairs", (50 * 101, sum(range(1, 101)), 100 * 101), (5050, 5050, 10100)),
        ("triangular numbers", [n * (n + 1) // 2 for n in range(1, 6)], [1, 3, 6, 10, 15]),
        ("2 + 5 + … + 29", (position(3, -1, 29), sum(terms(2, 3, 10)), 10 * (2 + 29) // 2, terms(2, 3, 10)[-1]), (10, 155, 155, 29)),
        ("1 + … + 40", (sum(range(1, 41)), 40 * 41, 40 * 20, 39 * 40 // 2), (820, 1640, 800, 780)),
        # Callouts, debate, widgets and lessons
        ("1 + … + 8", sum(range(1, 9)), 36),
        ("20 squares", (matches(20), 2 * matches(10), 20 * 4, 2 * 3 * 1 + 2 * 1), (61, 62, 80, 8)),
        ("1 to 6 as a rectangle", (6 * 7, 6 * 7 // 2, sum(range(1, 7))), (42, 21, 21)),
        ("1 to 4 as a rectangle", (1 + 4, 4 * 5, 20 // 2, sum(range(1, 5))), (5, 20, 10, 10)),
        ("3, 5, 7, 9 columns", [a + b for a, b in zip(terms(3, 2, 4), reversed(terms(3, 2, 4)))], [12, 12, 12, 12]),
        ("2 + 4 + 6 + 8", sum([2, 4, 6, 8]), 4 * (2 + 8) // 2),
        ("3, 7, 11, 15, 19 is 4n − 1", (gaps([3, 7, 11, 15, 19]), nth(lambda n: 4 * n, 3), nth(lambda n: 4 * n - 1, 5)),
         ([4, 4, 4, 4], [4, 8, 12], [3, 7, 11, 15, 19])),
        # Cards
        ("the odd numbers", terms(1, 2, 5), [1, 3, 5, 7, 9]),
        ("1 times 3", [3 ** i for i in range(5)], [1, 3, 9, 27, 81]),
        ("6 add 5", (terms(6, 5, 4)[-1], 6 + 5 * 4, 5 * 4, 6 + 10), (21, 26, 20, 16)),
        ("5, 8, 11, 14 chain", gaps([5, 8, 11, 14]), [3, 3, 3]),
        ("80 halving", [80 // 2 ** i for i in range(4)], [80, 40, 20, 10]),
        ("× 2 then + 1 from 1", [1, 2 * 1 + 1, 2 * 3 + 1, 2 * 7 + 1, 2 * 15 + 1], [1, 3, 7, 15, 31]),
        ("20, 17, 14, 11", gaps([20, 17, 14, 11]), [-3, -3, -3]),
        ("2.5, 4, 5.5, 7", gaps([Fraction("2.5"), 4, Fraction("5.5"), 7]), [Fraction("1.5")] * 3),
        ("9, 6, 3", gaps([9, 6, 3]), [-3, -3]),
        ("fence posts", terms(0, 4, 4), [0, 4, 8, 12]),
        ("6, 10, 14, 18 and 3, 6, 12, 24", (gaps([6, 10, 14, 18]), gaps([3, 6, 12, 24])), ([4, 4, 4], [3, 6, 12])),
        ("folded paper", [2 ** i for i in range(5)], [1, 2, 4, 8, 16]),
        ("5, 15, 45, 135", ([Fraction(b, a) for a, b in zip([5, 15, 45], [15, 45, 135])], 135 * 3), ([3, 3, 3], 405)),
        ("3, 6, 12, 24 next", (24 * 2, 24 + 12, 24 + 6, 24 + 3), (48, 36, 30, 27)),
        ("2n + 5", nth(lambda n: 2 * n + 5, 4), [7, 9, 11, 13]),
        ("10, 13, 16, 19 is 3n + 7", nth(lambda n: 3 * n + 7, 4), [10, 13, 16, 19]),
        ("1, 6, 11, 16 is 5n − 4", (nth(lambda n: 5 * n - 4, 4), 5 * 100 - 4), ([1, 6, 11, 16], 496)),
        ("3, 9, 19, 33 is 2n² + 1", (gaps(gaps([3, 9, 19, 33])), nth(lambda n: 2 * n * n, 4), nth(lambda n: 2 * n * n + 1, 4)),
         ([4, 4], [2, 8, 18, 32], [3, 9, 19, 33])),
        ("0, 3, 8, 15, 24 is n² − 1", nth(lambda n: n * n - 1, 5), [0, 3, 8, 15, 24]),
        ("dots in a triangle", [n * (n + 1) // 2 for n in range(1, 5)], [1, 3, 6, 10]),
        ("the 12th triangular number", (sum(range(1, 13)), 12 * 13 // 2), (78, 78)),
        ("the 9th triangular number", (9 * 10 // 2, 9 * 10, 9 * 9, 8 * 9 // 2), (45, 90, 81, 36)),
        ("the 4th square and triangular numbers", (4 * 4, 1 + 2 + 3 + 4), (16, 10)),
        # School unit 11
        ("7, 11, 15, 19, 23", (nth(lambda n: 4 * n + 3, 5), 4 * 20 + 3, 10 * (7 + 83), sum(nth(lambda n: 4 * n + 3, 20))),
         ([7, 11, 15, 19, 23], 83, 900, 900)),
        ("150 in 4n + 3", (150 - 3, position(4, 3, 150), 4 * 36 + 3, 4 * 37 + 3), (147, Fraction("36.75"), 147, 151)),
        ("3, 8, 15, 24, 35", (gaps([3, 8, 15, 24, 35]), [t - n * n for n, t in zip(range(1, 6), [3, 8, 15, 24, 35])],
                              nth(lambda n: n * n + 2 * n, 5)),
         ([5, 7, 9, 11], [2, 4, 6, 8, 10], [3, 8, 15, 24, 35])),
        ("1 + … + 200", (sum(range(1, 201)), 100 * 201, 200 * 201 // 2), (20100, 20100, 20100)),
    ]


def answers():
    """Chapter 6's turn answers and its cards' check answers, computed."""
    return {
        "ch06-s1-turn": 24 + 7,
        "ch06-s2-turn": 8 - 11,
        "ch06-s3-turn": "5n + 4",
        "ch06-s4-turn": f"the {position(5, -2, 83)}th",
        "ch06-s5-turn": "n^2 + 3",
        "ch06-s6-turn": sum(range(1, 41)),
        "sequence-check": 6 + 5 * 3,
        "term-to-term-rule-check": 2 * (2 * (2 * 1 + 1) + 1) + 1,
        "common-difference-check": Fraction("1.5"),
        "arithmetic-sequence-check": next(", ".join(map(str, s)) for s in ([1, 4, 9, 16], [1, 4, 7, 10]) if len(set(gaps(s))) == 1),
        "geometric-sequence-check": 24 * 2,
        "nth-term-check": "5n - 4",
        "quadratic-sequence-check": "n^2 - 1",
        "triangular-number-check": 9 * 10 // 2,
    }
