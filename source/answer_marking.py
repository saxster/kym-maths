"""
A Python reading of the app's answer marker (KymMaths/Core/Learning/AnswerKey.swift),
close enough for the exporter to refuse content that is plainly wrong before it
reaches the pack. The Swift tests run the real marker and have the last word.
"""

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
        self.numbers = read_numbers(normalised)
        self.words = words_of(normalised)
        self.tight = tighten(normalised)

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
    if kind == "words":
        if any(text.contains_phrase(word) for word in matcher.get("forbid", [])):
            return False
        return all(any(text.contains_phrase(word) for word in group) for group in matcher["groups"])
    if kind == "all":
        return all(matches(m, text) for m in matcher["of"])
    raise ValueError(f"unknown matcher kind {kind}")


def mark(answer_key, raw):
    """Returns (is_correct, the misconception id of the first matching mistake or None)."""
    text = AnswerText(raw)
    is_correct = bool(answer_key["parts"]) and all(
        any(matches(m, text) for m in part["anyOf"]) for part in answer_key["parts"]
    )
    if is_correct:
        return True, None
    slip = next((m["misconception"] for m in answer_key["mistakes"] if any(matches(x, text) for x in m["anyOf"])), None)
    return False, slip


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
