"""
Bedrock concept cards: ideas she already knows, so each one stands on no other card.

A card that stands on others lives in the file of the chapter that teaches it, as `cards(k)`.
`book/concepts.py` merges them. `cards(k)` takes the exporter's answer-key helpers (num, forms, one).
"""

from book.arithmetic import Fraction, factors, multiples, round_dp


def cards(k):
    return {
        "negative-number": {
            "name": "Negative number",
            "aliases": ["negative number", "negative numbers", "negatives", "directed number", "directed numbers"],
            "oneSentence": "A number less than zero, written with a minus sign in front.",
            "picture": "The night temperature in Shimla is 2 °C. It drops by 5 degrees. It passes zero and lands on −3 °C. "
                       "On a number line, negative numbers sit to the left of 0.",
            "steps": [
                "To add a negative number, move left. 4 + (−6) = −2.",
                "To subtract a negative number, move right. 4 − (−6) = 10.",
                "To multiply or divide, work out the size first. Then count the minus signs.",
                "An even count of minus signs gives a positive answer. An odd count gives a negative answer.",
            ],
            "workedExample": "Work out (−6) × 5. The size is 6 × 5 = 30. There is one minus sign, so the answer is negative. "
                             "(−6) × 5 = −30.",
            "check": {
                "prompt": "Work out (−8) ÷ (−2).",
                "answer": "4",
                "answerKey": k.one(k.num("4"), accepts=["4", "= 4"], rejects=["-4", "16", "-16"]),
            },
            "mixUp": {
                "name": "the take-away sign",
                "how": "In 7 − 3 the sign is an instruction to take away. In −3 it is part of the number.",
            },
            "standsOn": [],
            "footing": "negative-numbers",
        },
        "factor": {
            "name": "Factor",
            "aliases": ["factor", "factors"],
            "oneSentence": "A number that divides exactly into another number, with nothing left over.",
            "picture": "24 students can line up in 4 equal rows of 6. So 4 and 6 are both factors of 24. "
                       "They cannot make 5 equal rows, so 5 is not a factor of 24.",
            "steps": [
                "Try dividing by 1, 2, 3 and so on.",
                "Each time it divides exactly, write down the pair. For 24: 1 × 24, 2 × 12, 3 × 8, 4 × 6.",
                "Stop when the pairs start to repeat. The factors of 24 are 1, 2, 3, 4, 6, 8, 12 and 24.",
            ],
            "workedExample": "Find the factors of 18. The pairs are 1 × 18, 2 × 9 and 3 × 6. 4 and 5 do not divide exactly. "
                             "The next pair would be 6 × 3, which repeats. So the factors are 1, 2, 3, 6, 9 and 18.",
            "check": {
                "prompt": "How many factors does 12 have?",
                "answer": "6",
                "answerKey": k.one(k.num("6"), accepts=["6", "= 6"], rejects=["4", "5", "12"]),
            },
            "mixUp": {
                "with": "multiple",
                "how": "The factors of 12 are 12 or smaller. The multiples of 12 are 12 or bigger.",
            },
            "standsOn": [],
            "footing": "factors-and-multiples",
        },
        "multiple": {
            "name": "Multiple",
            "aliases": ["multiples", "multiple of"],
            "oneSentence": "What you get when you multiply a number by 1, 2, 3 and so on.",
            "picture": "A bus leaves every 6 minutes. It leaves at 6, 12, 18 and 24 minutes past the hour. "
                       "Those times are the multiples of 6.",
            "steps": [
                "Write the number.",
                "Keep adding the same number: 6, 12, 18, 24, 30.",
                "That list is its times table, and it never ends.",
            ],
            "workedExample": "Is 42 a multiple of 6? 6 × 7 = 42, so yes. Is 44? 44 ÷ 6 leaves 2 over, so no.",
            "check": {
                "prompt": "What is the 5th multiple of 7?",
                "answer": "35",
                "answerKey": k.one(k.num("35"), accepts=["35", "= 35"], rejects=["28", "42", "12"]),
            },
            "mixUp": {
                "with": "factor",
                "how": "Multiples of 6 are 6 or bigger: 6, 12, 18. Factors of 6 are 6 or smaller: 1, 2, 3, 6.",
            },
            "standsOn": [],
            "footing": "factors-and-multiples",
        },
        "power": {
            "name": "Power",
            "aliases": ["powers", "power of", "index", "indices"],
            "oneSentence": "A short way to write a number multiplied by itself several times.",
            "picture": "You forward a message to 3 people. Each of them forwards it to 3 more. "
                       "In the 4th round it reaches 3 × 3 × 3 × 3 = 81 people. We write that as 3⁴.",
            "steps": [
                "The big number is the base. It is the number being multiplied.",
                "The small raised number is the index. It says how many times the base appears.",
                "Write it out and multiply. 2⁵ = 2 × 2 × 2 × 2 × 2 = 32.",
            ],
            "workedExample": "Work out 5³. The base is 5 and it appears 3 times. 5 × 5 × 5 = 25 × 5 = 125.",
            "check": {
                "prompt": "Work out 2⁴.",
                "answer": "16",
                "answerKey": k.one(k.num("16"), accepts=["16", "= 16"], rejects=["8", "6", "32"]),
            },
            "mixUp": {
                "name": "multiplying",
                "how": "3⁴ is not 3 × 4. 3 × 4 = 12, but 3⁴ = 3 × 3 × 3 × 3 = 81.",
            },
            "standsOn": [],
        },
        "fraction": {
            "name": "Fraction",
            "aliases": ["fraction", "fractions"],
            "oneSentence": "A number that says how many equal parts of a whole you have.",
            "picture": "Cut a roti into 4 equal pieces and eat 3. You have eaten 3/4 of the roti. "
                       "The 4 says how many pieces make the whole. The 3 says how many you took.",
            "steps": [
                "The bottom number says how many equal parts make one whole.",
                "The top number says how many of those parts you have.",
                "A fraction is also a division. 3/4 means 3 ÷ 4, which is 0.75.",
                "When the top equals the bottom, you have exactly 1 whole. 4/4 = 1.",
            ],
            "workedExample": "What fraction of an hour is 20 minutes? An hour has 60 minutes, so it is 20/60. "
                             "Divide the top and the bottom by 20. It is 1/3 of an hour.",
            "check": {
                "prompt": "A bar of chocolate has 8 equal squares. You eat 3. What fraction is left?",
                "answer": "5/8",
                "answerKey": k.one(k.num("5/8"), accepts=["5/8", "= 5/8"], rejects=["3/8", "5/3", "8/5"]),
            },
            "mixUp": {
                "name": "two separate numbers",
                "how": "3/4 is one number, a little less than 1. It is not a 3 and a 4 sitting side by side.",
            },
            "standsOn": [],
            "footing": "fractions",
        },
        "decimal-place": {
            "name": "Decimal place",
            "short": "d.p.",
            "aliases": ["decimal place", "decimal places", "d.p."],
            "oneSentence": "A position for a digit to the right of the decimal point.",
            "picture": "A price of ₹12.75 has two digits after the point. The 7 is in the first decimal place and stands for 7 tenths. "
                       "The 5 is in the second and stands for 5 hundredths.",
            "steps": [
                "The first place after the point is tenths. The second is hundredths. The third is thousandths.",
                "To count decimal places, count the digits after the point. 3.142 has three.",
                "To round to 2 decimal places, keep two digits after the point and look at the third.",
                "If that third digit is 5 or more, round the last kept digit up.",
            ],
            "workedExample": "Round 3.14159 to 2 decimal places. Keep 3.14 and look at the next digit, which is 1. "
                             "It is less than 5, so the answer is 3.14.",
            "check": {
                "prompt": "Round 7.286 to 2 decimal places.",
                "answer": "7.29",
                "answerKey": k.one(k.num("7.29"), accepts=["7.29", "= 7.29"], rejects=["7.28", "7.3", "7.286"]),
            },
            "mixUp": {
                "with": "significant-figures",
                "how": "Decimal places are counted from the decimal point. "
                       "Significant figures are counted from the first digit that is not zero.",
            },
            "standsOn": [],
            "footing": "place-value",
        },
        "area": {
            "name": "Area",
            "aliases": ["area", "areas"],
            "oneSentence": "The amount of flat space a shape covers, counted in unit squares.",
            "picture": "A classroom floor is laid with square tiles, 8 along and 5 across. "
                       "It holds 8 × 5 = 40 tiles, so its area is 40 tiles.",
            "steps": [
                "Pick a unit square, such as 1 cm by 1 cm.",
                "For a rectangle, count the squares in one row: that is the length.",
                "Count the rows: that is the width.",
                "Multiply, so the area is length × width, in square units such as cm².",
            ],
            "workedExample": "A table top is 12 cm by 9 cm. Its area is 12 × 9 = 108 cm². "
                             "Cut it into a 12 by 5 piece and a 12 by 4 piece, and the areas 60 and 48 still make 108.",
            "check": {
                "prompt": "A rug is 7 m long and 3 m wide. What is its area in m²?",
                "answer": "21 m²",
                "answerKey": k.one(k.num("21"), accepts=["21", "21 m²", "= 21"], rejects=["20", "10", "42"]),
            },
            "mixUp": {
                "name": "the perimeter",
                "how": "The perimeter is the distance round the edge. The 7 m by 3 m rug has area 21 m² but perimeter 20 m.",
            },
            "standsOn": [],
            "footing": "area-and-perimeter",
        },
        "percentage": {
            "name": "Percentage",
            "aliases": ["percentage", "percentages", "per cent", "percent"],
            "oneSentence": "A number out of 100, written with the sign %.",
            "picture": "A test has 100 marks and you score 73. That is 73%. "
                       "A phone showing 40% battery has 40 parts left out of every 100.",
            "steps": [
                "Per cent means out of 100. So 25% is 25/100, which is 1/4 or 0.25.",
                "To find 10% of an amount, divide it by 10. 10% of ₹350 is ₹35.",
                "Build other amounts from 10% and 1%. 30% is three lots of 10%, and 5% is half of 10%.",
                "To write a fraction as a percentage, make its bottom number 100. 3/5 = 60/100 = 60%.",
            ],
            "workedExample": "Find 35% of ₹800. 10% is ₹80, so 30% is ₹240. 5% is half of 10%, which is ₹40. "
                             "35% is ₹240 + ₹40 = ₹280.",
            "check": {
                "prompt": "What is 20% of 250?",
                "answer": "50",
                "answerKey": k.one(k.num("50"), accepts=["50", "= 50"], rejects=["5", "25", "500", "12.5"]),
            },
            "mixUp": {
                "name": "the amount itself",
                "how": "20% is not 20. It is 20 out of every 100, so 20% of 50 is 10 and 20% of 500 is 100.",
            },
            "standsOn": [],
            "footing": "percentages",
        },
    }


def sums():
    """Every sum the bedrock cards state, recomputed. test_book_maths.py checks computed == stated."""
    return [
        # negative-number
        ("Shimla: 2 °C drops by 5 degrees", 2 - 5, -3),
        ("4 + (−6)", 4 + (-6), -2),
        ("4 − (−6)", 4 - (-6), 10),
        ("6 × 5", 6 * 5, 30),
        ("(−6) × 5", (-6) * 5, -30),
        ("(−8) ÷ (−2)", Fraction(-8, -2), 4),
        # factor
        ("4 rows of 6 students", 4 * 6, 24),
        ("5 is not a factor of 24", 24 % 5 != 0, True),
        ("factor pairs of 24", [(d, 24 // d) for d in factors(24) if d * d <= 24], [(1, 24), (2, 12), (3, 8), (4, 6)]),
        ("factors of 24", factors(24), [1, 2, 3, 4, 6, 8, 12, 24]),
        ("factor pairs of 18", [(d, 18 // d) for d in factors(18) if d * d <= 18], [(1, 18), (2, 9), (3, 6)]),
        ("4 and 5 do not divide 18", (18 % 4 != 0, 18 % 5 != 0), (True, True)),
        ("factors of 18", factors(18), [1, 2, 3, 6, 9, 18]),
        ("12 has 6 factors", len(factors(12)), 6),
        ("factors of 12 are 12 or smaller", max(factors(12)), 12),
        # multiple
        ("a bus every 6 minutes", multiples(6, 4), [6, 12, 18, 24]),
        ("keep adding 6", multiples(6, 5), [6, 12, 18, 24, 30]),
        ("6 × 7", 6 * 7, 42),
        ("44 ÷ 6 leaves 2 over", 44 % 6, 2),
        ("5th multiple of 7", multiples(7, 5)[-1], 35),
        ("multiples of 6 start", multiples(6, 3), [6, 12, 18]),
        ("factors of 6", factors(6), [1, 2, 3, 6]),
        # power
        ("3 × 3 × 3 × 3", 3 * 3 * 3 * 3, 81),
        ("3⁴", 3 ** 4, 81),
        ("2⁵ = 2 × 2 × 2 × 2 × 2", 2 ** 5, 2 * 2 * 2 * 2 * 2),
        ("2⁵", 2 ** 5, 32),
        ("5 × 5", 5 * 5, 25),
        ("5³ = 25 × 5", 5 ** 3, 25 * 5),
        ("5³", 5 ** 3, 125),
        ("2⁴", 2 ** 4, 16),
        ("3 × 4", 3 * 4, 12),
        # fraction
        ("3 ÷ 4", Fraction(3, 4), Fraction("0.75")),
        ("4/4", Fraction(4, 4), 1),
        ("20 minutes of an hour", Fraction(20, 60), Fraction(1, 3)),
        ("20 ÷ 20 and 60 ÷ 20", (20 // 20, 60 // 20), (1, 3)),
        ("8 squares, 3 eaten", Fraction(8 - 3, 8), Fraction(5, 8)),
        ("3/4 is a little less than 1", Fraction(3, 4) < 1, True),
        # decimal-place
        ("₹12.75: 7 tenths and 5 hundredths", 12 + Fraction(7, 10) + Fraction(5, 100), Fraction("12.75")),
        ("3.142 has three decimal places", len("3.142".split(".")[1]), 3),
        ("3.14159 to 2 decimal places", round_dp("3.14159", 2), Fraction("3.14")),
        ("the digit after 3.14 is 1", "3.14159"[4], "1"),
        ("7.286 to 2 decimal places", round_dp("7.286", 2), Fraction("7.29")),
        # percentage
        ("25%", (Fraction(25, 100), Fraction(25, 100)), (Fraction(1, 4), Fraction("0.25"))),
        ("10% of ₹350", Fraction(350, 10), 35),
        ("30% and 5% from 10%", (3 * 10, Fraction(10, 2)), (30, 5)),
        ("3/5 as a percentage", (Fraction(3, 5), Fraction(3, 5) * 100), (Fraction(60, 100), 60)),
        ("35% of ₹800 in pieces", (800 // 10, 3 * 80, 80 // 2, 240 + 40), (80, 240, 40, 280)),
        ("35% of ₹800", Fraction(35, 100) * 800, 280),
        ("20% of 250", Fraction(20, 100) * 250, 50),
        ("20% of 50 and of 500", (Fraction(20, 100) * 50, Fraction(20, 100) * 500), (10, 100)),
        # area
        ("8 by 5 tiles", 8 * 5, 40),
        ("the table top", (12 * 9, 12 * 5, 12 * 4, 60 + 48), (108, 60, 48, 108)),
        ("the rug", (7 * 3, 2 * (7 + 3)), (21, 20)),
    ]


def answers():
    """The bedrock cards' check answers, computed."""
    return {
        "negative-number-check": Fraction(-8, -2),
        "factor-check": len(factors(12)),
        "multiple-check": multiples(7, 5)[-1],
        "power-check": 2 ** 4,
        "fraction-check": Fraction(8 - 3, 8),
        "decimal-place-check": round_dp("7.286", 2),
        "percentage-check": Fraction(20, 100) * 250,
        "area-check": 7 * 3,
    }
