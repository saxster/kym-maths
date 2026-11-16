"""
A Python reading of the app's answer marker (KymMaths/Core/Learning/AnswerKey.swift),
close enough for the exporter to refuse content that is plainly wrong before it
reaches the pack. The Swift tests run the real marker and have the last word.
"""

import math
import re
from fractions import Fraction

SUPERSCRIPTS = dict(zip("⁰¹²³⁴⁵⁶⁷⁸⁹⁻", "0123456789-"))
SUBSCRIPTS = dict(zip("₀₁₂₃₄₅₆₇₈₉ₙ", "0123456789n"))
REPLACEMENTS = {
    "−": "-", "–": "-", "—": "-", "×": "*", "·": "*", "÷": "/", "≈": "=", "’": "'", "′": "'",
    "∠": "angle ", "…": " ", "₹": "", "$": "", "£": "", "ᵀ": "", "°": " ", "%": " ",
}
VULGAR = {"½": "1/2", "¼": "1/4", "¾": "3/4", "⅓": "1/3", "⅔": "2/3"}
UNITS = {
    "cm", "mm", "km", "m", "kg", "g", "l", "ml", "s", "h", "litre", "litres", "liter", "liters",
    "sec", "secs", "second", "seconds", "min", "mins", "hr", "hrs", "hour", "hours", "rs",
    "st", "nd", "rd", "th",
}


def normalise(raw):
    text = "".join(c for c in raw if not 0x0300 <= ord(c) <= 0x036F).lower()
    out, run = [], None
    for c in text:
        if c in SUPERSCRIPTS:
            if run != "^":
                out.append("^")
            out.append(SUPERSCRIPTS[c])
            run = "^"
            continue
        if c in SUBSCRIPTS:
            if run != "_":
                out.append("_")
            out.append(SUBSCRIPTS[c])
            run = "_"
            continue
        run = None
        if c in VULGAR:
            if out and out[-1][-1:].isdigit():
                out.append(" ")
            out.append(VULGAR[c])
        elif c in REPLACEMENTS:
            out.append(REPLACEMENTS[c])
        elif c.isspace():
            out.append(" ")
        else:
            out.append(c)
    joined = "".join(out).replace("<=", "≤").replace(">=", "≥")
    return re.sub(" +", " ", joined).strip()


def tighten(text):
    text = re.sub("square root of|square root|sqrt|root", "√", text)
    text = re.sub(" squared", "^2", text)
    text = re.sub(" cubed", "^3", text)
    text = re.sub(r"(?<=[0-9]) ?(cm|mm|km|kg|ml|litres?|liters?|seconds?|secs?|hours?|hrs?|units?)(\^[0-9])?(?![a-z])", "", text)
    text = re.sub("(?<=[0-9]) ?x ?(?=[0-9])", "*", text)
    text = re.sub(" +- +", "-", text)
    text = re.sub("(?<=[^ ])- +", "-", text)
    text = re.sub(r" *([+*/^=<>≤≥√]) *", r"\1", text)
    text = re.sub(r"\( +", "(", text)
    text = re.sub(r" +\)", ")", text)
    return text.strip()


def words_of(text):
    return [w for w in re.split(r"[^\w']|_", text) if w]


def read_numbers(chars):
    tokens = []
    n = len(chars)

    def char(at):
        return chars[at] if 0 <= at < n else None

    def is_digit(at):
        c = char(at)
        return c is not None and "0" <= c <= "9"

    def scan_integer(start):
        end = start
        while is_digit(end):
            end += 1
        text = chars[start:end]
        if len(text) > 3:
            return text, end
        groups, cursor = [], end
        while char(cursor) == ",":
            group_end = cursor + 1
            while is_digit(group_end):
                group_end += 1
            length = group_end - cursor - 1
            if length not in (2, 3):
                break
            groups.append((chars[cursor + 1:group_end], group_end))
            cursor = group_end
        lengths = [len(g[0]) for g in groups]
        western = len(list(_prefix(lengths, 3)))
        twos = len(list(_prefix(lengths, 2)))
        indian = twos + 1 if twos > 0 and len(lengths) > twos and lengths[twos] == 3 else 0
        used = max(western, indian)
        if used == 0:
            return text, end
        return text + "".join(g[0] for g in groups[:used]), groups[used - 1][1]

    def trailing_run(start):
        end = start
        while char(end) is not None and char(end).isalpha():
            end += 1
        return chars[start:end], end

    def binds_forward(end):
        nxt = char(end)
        if nxt is None:
            return False
        if nxt in "^(√":
            return True
        if not nxt.isalpha():
            return False
        return trailing_run(end)[0] not in UNITS

    index = 0
    while index < n:
        if not (is_digit(index) or (chars[index] == "." and is_digit(index + 1))):
            index += 1
            continue
        start = index
        if chars[index] == ".":
            text, end = "0", index
        else:
            text, end = scan_integer(index)
        is_integer = True
        if char(end) == "." and is_digit(end + 1):
            fraction_end = end + 1
            while is_digit(fraction_end):
                fraction_end += 1
            text += "." + chars[end + 1:fraction_end]
            end = fraction_end
            is_integer = False

        sign_start, negative = start, False
        if char(start - 1) == "-":
            before_minus = char(start - 2)
            if before_minus is None or before_minus in " (=,*/:[":
                negative, sign_start = True, start - 1
            elif before_minus == "^":
                index = end
                continue
        before = char(sign_start - 1)
        if before is not None and (before.isalpha() or before in "_^."):
            index = end
            continue

        value = Fraction(text)
        simplest = True
        consumed = end
        if is_integer:
            slash = end
            while char(slash) == " ":
                slash += 1
            denominator_start = slash + 1
            while char(denominator_start) == " ":
                denominator_start += 1
            if char(slash) == "/" and is_digit(denominator_start):
                bottom_text, bottom_end = scan_integer(denominator_start)
                if not (char(bottom_end) == "." and is_digit(bottom_end + 1)) and int(bottom_text) != 0:
                    value = Fraction(int(text), int(bottom_text))
                    simplest = _gcd(int(text), int(bottom_text)) == 1
                    consumed = bottom_end
            elif char(end) == " " and is_digit(end + 1):
                top_text, top_end = scan_integer(end + 1)
                if char(top_end) == "/" and is_digit(top_end + 1):
                    bottom_text, bottom_end = scan_integer(top_end + 1)
                    top, bottom = int(top_text), int(bottom_text)
                    if top < bottom and not (char(bottom_end) == "." and is_digit(bottom_end + 1)):
                        value = Fraction(int(text) * bottom + top, bottom)
                        simplest = _gcd(top, bottom) == 1
                        consumed = bottom_end

        index = consumed
        if binds_forward(consumed):
            if char(consumed) is not None and char(consumed).isalpha():
                index = trailing_run(consumed)[1]
            continue
        tokens.append((-value if negative else value, simplest))
    return tokens


def _prefix(values, wanted):
    for value in values:
        if value != wanted:
            return
        yield value


def _gcd(a, b):
    while b:
        a, b = b, a % b
    return a


class AnswerText:
    def __init__(self, raw):
        normalised = normalise(raw)
        self.normalised = normalised
        self.numbers = read_numbers(normalised)
        self.words = words_of(normalised)
        self.tight = tighten(normalised)

    @property
    def expressions(self):
        return [expression for _, _, expression in segments(self.normalised) if expression is not None]

    def contains_phrase(self, phrase):
        wanted = words_of(normalise(phrase))
        if not wanted or len(self.words) < len(wanted):
            return False
        return any(self.words[i:i + len(wanted)] == wanted for i in range(len(self.words) - len(wanted) + 1))

    def contains_form(self, form):
        needle = tighten(normalise(form))
        tight = self.tight
        if not needle or len(tight) < len(needle):
            return False
        for start in range(len(tight) - len(needle) + 1):
            if tight[start:start + len(needle)] != needle:
                continue
            before = tight[start - 1] if start > 0 else None
            end = start + len(needle)
            after = tight[end] if end < len(tight) else None
            after_next = tight[end + 1] if end + 1 < len(tight) else None
            open_before = before is None or before in " =,;:"
            if after is None:
                open_after = True
            elif after == ".":
                open_after = not (after_next is not None and after_next.isdigit())
            else:
                open_after = after in " =,;:"
            if open_before and open_after:
                return True
        return False


def number(text):
    return Fraction(text.replace(" ", ""))


def matches(matcher, text):
    kind = matcher["kind"]
    if kind == "number":
        value = number(matcher["value"])
        tolerance = matcher.get("tolerance", 0)
        simplest = matcher.get("simplest", False)
        return any(
            (not simplest or token_simplest)
            and (abs(float(token) - float(value)) <= tolerance + 1e-12 if tolerance else token == value)
            for token, token_simplest in text.numbers
        )
    if kind == "sequence":
        values = [number(v) for v in matcher["values"]]
        ignoring = {number(v) for v in matcher.get("ignoring", [])}
        found = [token for token, _ in text.numbers if token not in ignoring]
        return any(found[i:i + len(values)] == values for i in range(len(found) - len(values) + 1))
    if kind == "form":
        return text.contains_form(matcher["value"])
    if kind == "expression":
        target = parse_expression(matcher["value"])
        form = matcher.get("form", "any")
        return target is not None and any(
            equivalent(expression, target) and form_accepts(form, expression) for expression in text.expressions
        )
    if kind == "words":
        if any(text.contains_phrase(word) for word in matcher.get("forbid", [])):
            return False
        return all(any(text.contains_phrase(word) for word in group) for group in matcher["groups"])
    if kind == "all":
        return all(matches(m, text) for m in matcher["of"])
    raise ValueError(f"unknown matcher kind {kind}")


def mark(answer_key, raw):
    """Returns (is_correct, the misconception id of the first matching mistake or None).

    With no listed mistake matching, an answer equal to a missing part's expression but not in its shape
    names "common-factor-left" or "stopped-early", as the app does.
    """
    text = AnswerText(raw)
    missing = [part for part in answer_key["parts"] if not any(matches(m, text) for m in part["anyOf"])]
    if answer_key["parts"] and not missing:
        return True, None
    slip = next((m["misconception"] for m in answer_key["mistakes"] if any(matches(x, text) for x in m["anyOf"])), None)
    return False, slip or unfinished_slip(missing, text)


def unfinished_slip(missing_parts, text):
    for part in missing_parts:
        for matcher in part["anyOf"]:
            if matcher["kind"] != "expression":
                continue
            target = parse_expression(matcher["value"])
            if target is None:
                continue
            for expression in text.expressions:
                if equivalent(expression, target):
                    slip = unfinished(matcher.get("form", "any"), expression)
                    if slip:
                        return slip[0]
    return None


def gives_away(answer_key, raw):
    """True when the text shows a value or form the key accepts as one of its parts, or answers it whole.

    Worded parts are left to the whole-answer check, since their words also turn up in plain reasoning.
    """
    if mark(answer_key, raw)[0]:
        return True
    text = AnswerText(raw)
    for part in answer_key["parts"]:
        for matcher in part["anyOf"]:
            if matcher["kind"] == "words":
                continue
            if matches(matcher, text):
                return True
            if matcher["kind"] == "number" and matches({**matcher, "value": str(-number(matcher["value"]))}, text):
                return True
    return False


# ---------------------------------------------------------------------------
# Expressions: a mirror of KymMaths/Core/Learning/AnswerExpression.swift. Both read
# KymMaths/Tests/Golden/expression-reading.json in their tests, so they cannot drift.
#
# A node is a tuple: ("num", Fraction), ("sym", letter or π), ("neg", e), ("sum", [terms]),
# ("mul", a, b), ("div", a, b), ("pow", base, exponent), ("root", e), ("group", e).
# ---------------------------------------------------------------------------

PI = "π"
SAMPLE_POINTS = 6
SAMPLE_VALUES = [1.37, 2.91, 0.53, 3.7, -1.21, 1.83, 0.71, 2.29]
SEPARATORS = re.compile(r"([=,;]|\band\b)")
SUPERSCRIPT_DIGITS = dict(zip("0123456789-", "⁰¹²³⁴⁵⁶⁷⁸⁹⁻"))
UNFINISHED_NEXT_STEPS = {
    "bracketLeft": "It is equal, but a bracket is still there. Multiply it out.",
    "likeTermsLeft": "It is equal, but some like terms are not collected yet. Add them together.",
    "notAProduct": "It is equal, but it is not factorised yet. Write it as a product with a bracket.",
}


def parse_expression(raw):
    return parse_normalised(normalise(raw))


def parse_normalised(normalised):
    lexemes = _lex(tighten(normalised))
    if not lexemes:
        return None
    parser = _Parser(lexemes)
    expression = parser.sum()
    return expression if expression is not None and parser.at_end else None


def segments(normalised):
    """(separator, typed, expression) for each piece either side of "=", ",", ";" and "and"."""
    pieces = SEPARATORS.split(normalised)
    out, separator = [], ""
    for index, piece in enumerate(pieces):
        if index % 2:
            separator = piece
            continue
        typed = piece.strip().rstrip(".").strip()
        if typed:
            out.append(("" if not out else separator, typed, parse_normalised(typed)))
    return out


def reads_as(raw):
    normalised = normalise(raw)
    if not any("a" <= c <= "z" or c == PI or c in "^/*" for c in normalised):
        return None
    found = segments(normalised)
    if not any(expression is not None for _, _, expression in found):
        return None
    shown = []
    for separator, typed, expression in found:
        text = display(expression) if expression is not None else typed
        if separator == "":
            shown.append(text)
        elif separator in ("=", "and"):
            shown.append(f" {separator} {text}")
        else:
            shown.append(f"{separator} {text}")
    return "".join(shown)


def _lex(chars):
    out, index, spaced, n = [], 0, False, len(chars)

    def digit(at):
        return at < n and "0" <= chars[at] <= "9"

    while index < n:
        c = chars[index]
        if c == " ":
            spaced = True
            index += 1
            continue
        if digit(index) or (c == "." and digit(index + 1)):
            end = index
            while digit(end):
                end += 1
            if end < n and chars[end] == "." and digit(end + 1):
                end += 1
                while digit(end):
                    end += 1
            text = chars[index:end]
            if len(text.replace(".", "")) > 15:
                return None
            out.append((("num", Fraction(text)), spaced))
            index = end
        elif "a" <= c <= "z":
            end = index
            while end < n and "a" <= chars[end] <= "z":
                end += 1
            run, symbols, at = chars[index:end], [], 0
            while at < len(run):
                if run[at:at + 2] == "pi":
                    symbols.append(PI)
                    at += 2
                else:
                    symbols.append(run[at])
                    at += 1
            # Letters side by side are a product (6ab), but a run of four or more is a word.
            if len(symbols) >= 4:
                return None
            for offset, symbol in enumerate(symbols):
                out.append((("sym", symbol), offset == 0 and spaced))
            index = end
        elif c == PI or c in "+-*/^()√":
            out.append((("sym", PI) if c == PI else ("op", c), spaced))
            index += 1
        else:
            return None
        spaced = False
    return out


class _Parser:
    """^ binds tightest and to the right, then unary minus, then ×, ÷ and side-by-side products at one
    level from the left, so 1/2x is (1/2)x and -x^2 is -(x²)."""

    def __init__(self, lexemes):
        self.lexemes = lexemes
        self.index = 0

    @property
    def at_end(self):
        return self.index == len(self.lexemes)

    def _next(self):
        return self.lexemes[self.index][0] if self.index < len(self.lexemes) else None

    def _take(self, op):
        if self._next() == ("op", op):
            self.index += 1
            return True
        return False

    def sum(self):
        first = self._term()
        if first is None:
            return None
        terms = [first]
        while True:
            if self._take("+"):
                term = self._term()
                if term is None:
                    return None
                terms.append(term)
            elif self._take("-"):
                term = self._term()
                if term is None:
                    return None
                terms.append(("neg", term))
            else:
                break
        return first if len(terms) == 1 else ("sum", terms)

    def _term(self):
        left = self._unary()
        if left is None:
            return None
        while True:
            if self._take("*"):
                kind = "mul"
            elif self._take("/"):
                kind = "div"
            elif self._starts_implicit_factor():
                kind = "mul"
            else:
                return left
            right = self._unary()
            if right is None:
                return None
            left = (kind, left, right)

    def _starts_implicit_factor(self):
        """A space between two letters or two numbers ends the expression: "nth term" and "2 5/12" are not products."""
        if self.index >= len(self.lexemes):
            return False
        token, spaced = self.lexemes[self.index]
        if token in (("op", "("), ("op", "√")):
            return True
        if token[0] in ("num", "sym"):
            if not spaced:
                return True
            return token[0] == "sym" and self.lexemes[self.index - 1][0][0] == "num"
        return False

    def _unary(self):
        if self._take("-"):
            inner = self._unary()
            return None if inner is None else ("neg", inner)
        if self._take("+"):
            return self._unary()
        return self._power()

    def _power(self):
        base = self._primary()
        if base is None or not self._take("^"):
            return base
        exponent = self._unary()
        return None if exponent is None else ("pow", base, exponent)

    def _primary(self):
        token = self._next()
        if token is None:
            return None
        self.index += 1
        if token[0] in ("num", "sym"):
            return token
        if token == ("op", "("):
            inner = self.sum()
            if inner is None or not self._take(")"):
                return None
            return ("group", inner)
        if token == ("op", "√"):
            inner = self._primary()
            return None if inner is None else ("root", inner)
        return None


def value(node, values):
    kind = node[0]
    if kind == "num":
        return float(node[1])
    if kind == "sym":
        return math.pi if node[1] == PI else values.get(node[1], math.nan)
    if kind == "neg":
        return -value(node[1], values)
    if kind == "sum":
        total = 0.0
        for term in node[1]:
            total += value(term, values)
        return total
    if kind == "group":
        return value(node[1], values)
    if kind == "root":
        inner = value(node[1], values)
        return math.nan if inner < 0 else math.sqrt(inner)
    a, b = value(node[1], values), value(node[2], values)
    if kind == "mul":
        return a * b
    if kind == "div":
        return a / b if b != 0 else math.nan
    try:
        return math.pow(a, b)
    except (ValueError, OverflowError):
        return math.nan


def letters(node):
    kind = node[0]
    if kind == "num":
        return set()
    if kind == "sym":
        return set() if node[1] == PI else {node[1]}
    if kind == "sum":
        return set().union(*(letters(term) for term in node[1]))
    return set().union(*(letters(child) for child in node[1:]))


def equivalent(a, b):
    """Equal as algebra: the two agree at six awkward points, each letter getting a different value."""
    names = sorted(letters(a) | letters(b))
    usable = 0
    for point in range(SAMPLE_POINTS):
        values = {letter: SAMPLE_VALUES[(point + 3 * index) % len(SAMPLE_VALUES)] for index, letter in enumerate(names)}
        x, y = value(a, values), value(b, values)
        if not (math.isfinite(x) and math.isfinite(y)):
            continue
        if abs(x - y) > 1e-9 * max(1, abs(x), abs(y)):
            return False
        usable += 1
    return usable >= 3


def _decimal_text(n):
    if n.denominator == 1:
        return str(n.numerator)
    places, scale = 0, 1
    while scale % n.denominator and places < 15:
        scale *= 10
        places += 1
    digits = str(abs(n.numerator) * (scale // n.denominator))
    padded = "0" * max(0, places + 1 - len(digits)) + digits
    return ("-" if n.numerator < 0 else "") + padded[:-places] + "." + padded[-places:]


def _integer_literal(node):
    if node[0] == "num" and node[1].denominator == 1:
        return node[1].numerator
    if node[0] == "neg" and node[1][0] == "num" and node[1][1].denominator == 1:
        return -node[1][1].numerator
    return None


def display(node, top=True):
    """The expression as the preview shows it: x², −, the learner's brackets, × only where a digit follows."""
    kind = node[0]
    if kind == "num":
        return _decimal_text(node[1])
    if kind == "sym":
        return node[1]
    if kind == "neg":
        return "−" + display(node[1], False)
    if kind == "sum":
        plus, minus = (" + ", " − ") if top else ("+", "−")
        out = []
        for index, term in enumerate(node[1]):
            if index == 0:
                out.append(display(term, False))
            elif term[0] == "neg":
                out.append(minus + display(term[1], False))
            else:
                out.append(plus + display(term, False))
        return "".join(out)
    if kind == "mul":
        a, b = node[1], node[2]
        left = display(a, False)
        if a[0] == "div":
            left = f"({left})"
        right = display(b, False)
        if b[0] == "neg":
            right = f"({right})"
        digit_next = bool(right) and (right[0].isdigit() or right[0] == ".")
        bare_root = a[0] == "root" and a[1][0] != "group" and not right.startswith("(")
        return left + (" × " if digit_next or bare_root else "") + right
    if kind == "div":
        right = display(node[2], False)
        if node[2][0] == "neg":
            right = f"({right})"
        return display(node[1], False) + "/" + right
    if kind == "pow":
        base, exponent = node[1], node[2]
        base_text = display(base, False)
        if base[0] not in ("num", "sym", "group"):
            base_text = f"({base_text})"
        k = _integer_literal(exponent)
        if k is not None:
            return base_text + "".join(SUPERSCRIPT_DIGITS[c] for c in str(k))
        if exponent[0] in ("num", "sym", "group"):
            return base_text + "^" + display(exponent, False)
        return base_text + "^(" + display(exponent, False) + ")"
    if kind == "root":
        return "√" + display(node[1], False)
    return "(" + display(node[1], False) + ")"


def _stripped(node):
    while node[0] == "group":
        node = node[1]
    return node


def _is_bracketed_sum(node):
    return node[0] == "group" and _stripped(node)[0] == "sum"


def _has_worked_bracket(node):
    kind = node[0]
    if kind in ("num", "sym"):
        return False
    if kind == "neg":
        return _is_bracketed_sum(node[1]) or _has_worked_bracket(node[1])
    if kind in ("mul", "div"):
        return any(_is_bracketed_sum(child) or _has_worked_bracket(child) for child in node[1:])
    if kind == "pow":
        return _is_bracketed_sum(node[1]) or _has_worked_bracket(node[1]) or _has_worked_bracket(node[2])
    if kind == "sum":
        return any(_has_worked_bracket(term) for term in node[1])
    return _has_worked_bracket(node[1])


def _terms(node):
    if node[0] != "sum":
        return [node]
    out = []
    for term in node[1]:
        out.extend(_terms(_stripped(term)) if _is_bracketed_sum(term) else [term])
    return out


def _factors(node):
    kind = node[0]
    if kind in ("mul", "div"):
        return _factors(node[1]) + _factors(node[2])
    if kind == "neg":
        return _factors(node[1])
    if kind == "group":
        return [node] if _is_bracketed_sum(node) else _factors(node[1])
    return [node]


def _bracket(node):
    if _is_bracketed_sum(node):
        return node
    if node[0] == "pow" and _is_bracketed_sum(node[1]):
        return node[1]
    return None


def _opaque(node):
    return Fraction(1), {f"[{display(node)}]": 1}


def _monomial(node):
    """(coefficient or None, {letter or opaque factor: power}) for one term."""
    kind = node[0]
    if kind == "num":
        return node[1], {}
    if kind == "sym":
        return Fraction(1), {node[1]: 1}
    if kind == "neg":
        coefficient, powers = _monomial(node[1])
        return (None if coefficient is None else -coefficient), powers
    if kind == "group":
        return _opaque(node) if node[1][0] == "sum" else _monomial(node[1])
    if kind in ("mul", "div"):
        sign = 1 if kind == "mul" else -1
        (a, left), (b, right) = _monomial(node[1]), _monomial(node[2])
        if a is None or b is None or (sign < 0 and b == 0):
            coefficient = None
        else:
            coefficient = a * b if sign > 0 else a / b
        powers = dict(left)
        for name, power in right.items():
            powers[name] = powers.get(name, 0) + sign * power
        return coefficient, powers
    if kind == "pow":
        k = _integer_literal(node[2])
        if k is None:
            return _opaque(node)
        coefficient, powers = _monomial(node[1])
        if coefficient is not None and (abs(k) > 64 or (k < 0 and coefficient == 0)):
            coefficient = None
        return (None if coefficient is None else coefficient ** k), {name: power * k for name, power in powers.items()}
    return _opaque(node)


def _signature(node):
    return ",".join(f"{name}^{power}" for name, power in sorted(_monomial(node)[1].items()) if power)


def expansion(node):
    """"ok", "bracketLeft" or "likeTermsLeft"."""
    if _has_worked_bracket(node):
        return "bracketLeft"
    signatures = [_signature(term) for term in _terms(_stripped(node))]
    return "ok" if len(set(signatures)) == len(signatures) else "likeTermsLeft"


def _terms_share_a_factor(terms):
    monomials = [_monomial(term) for term in terms]
    coefficients = [coefficient for coefficient, _ in monomials]
    if all(c is not None and c.denominator == 1 for c in coefficients):
        divisor = 0
        for c in coefficients:
            divisor = math.gcd(divisor, abs(c.numerator))
        if divisor > 1:
            return True
    if not monomials:
        return False
    return any(len(name) == 1 and power > 0 and all(powers.get(name, 0) > 0 for _, powers in monomials)
               for name, power in monomials[0][1].items())


def factorisation(node):
    """("ok", None), ("notAProduct", None) or ("bracketWithCommonFactor", the bracket)."""
    whole = _stripped(node)
    if whole[0] == "sum":
        return "notAProduct", None
    brackets = [b for b in (_bracket(f) for f in _factors(whole)) if b is not None]
    if not brackets:
        return "notAProduct", None
    for bracket in brackets:
        if _terms_share_a_factor(_terms(_stripped(bracket))):
            return "bracketWithCommonFactor", bracket
    return "ok", None


def form_accepts(form, node):
    if form == "expanded":
        return expansion(node) == "ok"
    if form == "factorised":
        return factorisation(node)[0] == "ok"
    return True


def unfinished(form, node):
    """(misconception id, next step) for an answer equal to the target but not in `form` yet, or None."""
    if form == "expanded":
        shape = expansion(node)
        return None if shape == "ok" else ("stopped-early", UNFINISHED_NEXT_STEPS[shape])
    if form == "factorised":
        shape, bracket = factorisation(node)
        if shape == "ok":
            return None
        if bracket is not None:
            return ("common-factor-left", f"It multiplies back to the right expression, but the bracket "
                                          f"{display(bracket)} still has a common factor. Take that out too.")
        return "stopped-early", UNFINISHED_NEXT_STEPS[shape]
    return None
