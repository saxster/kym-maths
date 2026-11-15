"""
Small arithmetic helpers for the book files' `sums()` and `answers()`, which test_book_maths.py checks.

Decimals are written as Fraction("1.41") so a stated 1.9881 compares exactly.
"""

from decimal import ROUND_HALF_UP, Decimal
from fractions import Fraction
from math import gcd, isqrt, lcm, prod

__all__ = ["Fraction", "gcd", "lcm", "isqrt", "prod", "factors", "is_prime", "prime_factors", "multiples",
           "common_multiples", "mixed", "round_dp", "round_sf", "recurring", "terminates", "decimal_digits",
           "percent", "multiplier", "compound", "nearest", "share"]


def factors(n):
    return [d for d in range(1, n + 1) if n % d == 0]


def is_prime(n):
    return len(factors(n)) == 2


def prime_factors(n):
    """The prime factors of n, smallest first, as a tuple: 90 → (2, 3, 3, 5)."""
    out, d = [], 2
    while n > 1:
        while n % d == 0:
            out.append(d)
            n //= d
        d += 1
    return tuple(out)


def multiples(n, count):
    return [n * i for i in range(1, count + 1)]


def common_multiples(a, b, below):
    return [m for m in range(1, below) if m % a == 0 and m % b == 0]


def mixed(value):
    """A fraction bigger than 1 as a mixed-number string: 19/12 → "1 7/12"."""
    whole, rest = divmod(value.numerator, value.denominator)
    return f"{whole} {rest}/{value.denominator}"


def round_dp(text, places):
    """Round a decimal written as a string to a number of decimal places, halves up: ("7.286", 2) → 7.29."""
    return Fraction(Decimal(text).quantize(Decimal(1).scaleb(-places), rounding=ROUND_HALF_UP))


def round_sf(text, figures):
    """Round a number written as a string to a number of significant figures, halves up: ("32846", 2) → 33000."""
    value = Decimal(text)
    return Fraction(value.quantize(Decimal(1).scaleb(value.adjusted() - figures + 1), rounding=ROUND_HALF_UP))


def recurring(block):
    """The fraction equal to 0.(block repeated for ever): "36" → 4/11."""
    return Fraction(int(block), 10 ** len(block) - 1)


def terminates(value):
    """True when the fraction's decimal stops: its denominator in simplest form has no prime but 2 and 5."""
    return set(prime_factors(value.denominator)) <= {2, 5}


def decimal_digits(top, bottom, count):
    """The first `count` digits after the decimal point of top ÷ bottom, by long division, as a string."""
    digits, rest = [], top % bottom
    for _ in range(count):
        rest *= 10
        digits.append(str(rest // bottom))
        rest %= bottom
    return "".join(digits)


def percent(n):
    """n per cent as a fraction: 35 → 7/20."""
    return Fraction(n, 100)


def multiplier(change):
    """The multiplier for a percentage change: +20 → 6/5 (1.2), −15 → 17/20 (0.85)."""
    return 1 + Fraction(change, 100)


def compound(start, change, years):
    """What `start` becomes after `years` of the same percentage change each year, exactly."""
    return start * multiplier(change) ** years


def nearest(value):
    """A fraction rounded to the nearest whole number, halves up."""
    return (value + Fraction(1, 2)).__floor__()


def share(total, *parts):
    """A total shared in a ratio: (320, 3, 5) → [120, 200]."""
    one = Fraction(total, sum(parts))
    return [part * one for part in parts]
