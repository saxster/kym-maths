"""
Small arithmetic helpers for the book files' `sums()` and `answers()`, which test_book_maths.py checks.

Decimals are written as Fraction("1.41") so a stated 1.9881 compares exactly.
"""

from fractions import Fraction
from math import gcd, isqrt, lcm, prod

__all__ = ["Fraction", "gcd", "lcm", "isqrt", "prod", "factors", "is_prime", "prime_factors", "multiples",
           "common_multiples"]


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
