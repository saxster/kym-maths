"""
Bedrock concept cards: ideas she already knows, so each one stands on no other card.

A card that stands on others lives in the file of the chapter that teaches it, as `cards(k)`.
`book/concepts.py` merges them. `cards(k)` takes the exporter's answer-key helpers (num, forms, one).
"""

from book.arithmetic import Fraction, factors, multiples


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
    ]


def answers():
    """The bedrock cards' check answers, computed."""
    return {
        "negative-number-check": Fraction(-8, -2),
        "factor-check": len(factors(12)),
        "multiple-check": multiples(7, 5)[-1],
        "power-check": 2 ** 4,
    }
