"""
Concept cards: one short page per technical word or symbol.

Any learner text that uses one of a card's `aliases` links to the card. The standard for a card
is in docs/CONTENT_BRIEF.md. `build(k)` takes the exporter's answer-key helpers (num, forms, one)
so this file imports nothing from the exporter.
"""

from itertools import permutations

# Phrases that contain an alias but mean something else. They are matched like aliases and never link.
STOP_PHRASES = [
    "scale factor", "scale factors", "conversion factor", "power set", "multiple choice", "multiple-choice",
]


def product_forms(k, *factors):
    """Every order of a product, so 2 × 3 × 5 and 5 × 2 × 3 both mark right."""
    orders = sorted({"*".join(order) for order in permutations(factors)})
    return k.forms(*orders)


def build(k):
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
                "answerKey": k.one(product_forms(k, "2", "3", "5"),
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
        "power": {
            "name": "Power",
            "aliases": ["power", "powers", "index", "indices"],
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
