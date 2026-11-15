"""
Every number the book states is recomputed here (plan risk R6, acceptance A5).

Each book file (bedrock.py and every chapter in the exporter's BOOK_CHAPTERS) exports:

  sums()     a list of (label, computed, stated): `computed` is real Python arithmetic, `stated` the value the
             text states. They must be equal.
  answers()  {id: computed answer} for every "Your turn" step (`chNN-sK-turn`) and every card check
             (`<card id>-check`) in the file. A number, a tuple of factors (2, 3, 3, 5), or a string form such
             as "7^8". The real marker must mark it right.

The marker must also mark each listed `accepts` sample right and each `rejects` sample wrong, and every turn
and check needs at least one accept and two rejects.
"""

import math
import types
import unittest
from fractions import Fraction

import answer_marking as marking
import export_kymmaths_pack as exporter
from book import concepts

K = exporter.helpers()
NEVER_RIGHT = ["", "   ", "I have no idea about this, can you check"]


def book_modules():
    modules = list(concepts.card_modules(K))
    return modules + [module for module in exporter.BOOK_CHAPTERS if module not in modules]


def answer_keys(module):
    """{id: (stated answer, answer key)} for the turns and card checks a book file writes."""
    keys = {}
    if hasattr(module, "build"):
        spec = module.build(K)
        for index, section in enumerate(spec["sections"], start=1):
            for step in section["steps"]:
                if step["kind"] == "turn":
                    keys[f"ch{spec['number']:02d}-s{index}-turn"] = (step.get("answer"), step.get("answerKey"))
    if hasattr(module, "cards"):
        for cid, card in module.cards(K).items():
            keys[f"{cid}-check"] = (card["check"].get("answer"), card["check"].get("answerKey"))
    return keys


def render(value):
    if isinstance(value, tuple):
        return " × ".join(render(part) for part in value)
    if isinstance(value, Fraction):
        return str(value.numerator) if value.denominator == 1 else f"{value.numerator}/{value.denominator}"
    return str(value)


def same(computed, stated):
    if isinstance(computed, float) or isinstance(stated, float):
        return math.isclose(computed, stated, rel_tol=1e-9, abs_tol=1e-9)
    return computed == stated


def sum_failures(module):
    name = getattr(module, "__name__", "?")
    if not hasattr(module, "sums"):
        return [f"{name} has no sums()"]
    found = module.sums()
    out = [f"{name} sums() is empty"] if not found else []
    out += [f"{name}: {label} computes to {computed!r}, but the text says {stated!r}"
            for label, computed, stated in found if not same(computed, stated)]
    return out


def answer_failures(module):
    name = getattr(module, "__name__", "?")
    keys = answer_keys(module)
    if not keys:
        return []
    if not hasattr(module, "answers"):
        return [f"{name} has no answers()"]
    answers = module.answers()
    out = [f"{name}: no computed answer for {aid}" for aid in keys if aid not in answers]
    out += [f"{name}: answers() has {aid}, which is no turn or card check" for aid in answers if aid not in keys]
    for aid, (stated, key) in keys.items():
        if not key:
            out.append(f"{name}: {aid} has no answer key")
            continue
        if aid in answers and not marking.mark(key, render(answers[aid]))[0]:
            out.append(f"{name}: {aid} computes to {render(answers[aid])!r}, which its key marks wrong")
        if stated and not marking.mark(key, stated)[0]:
            out.append(f"{name}: {aid} states {stated!r}, which its key marks wrong")
        if len(key["accepts"]) < 1 or len(key["rejects"]) < 2:
            out.append(f"{name}: {aid} needs at least 1 accepted and 2 rejected samples")
        out += [f"{name}: {aid} marks its accepted sample {sample!r} wrong"
                for sample in key["accepts"] if not marking.mark(key, sample)[0]]
        out += [f"{name}: {aid} marks its rejected sample {sample!r} right"
                for sample in key["rejects"] + NEVER_RIGHT if marking.mark(key, sample)[0]]
    return out


class BookMathsTest(unittest.TestCase):
    def test_book_files_are_found(self):
        names = [module.__name__ for module in book_modules()]
        self.assertIn("book.bedrock", names)
        self.assertIn("book.ch01", names)

    def test_every_stated_sum_is_right(self):
        for module in book_modules():
            with self.subTest(module=module.__name__):
                self.assertEqual(sum_failures(module), [])

    def test_every_turn_and_card_check_is_computed_and_marked(self):
        for module in book_modules():
            with self.subTest(module=module.__name__):
                self.assertEqual(answer_failures(module), [])

    def test_a_wrong_sum_fails(self):
        fixture = types.SimpleNamespace(__name__="fixture", sums=lambda: [("2 + 2", 2 + 2, 5), ("2 + 3", 2 + 3, 5)])
        failures = sum_failures(fixture)
        self.assertEqual(len(failures), 1, failures)
        self.assertIn("2 + 2 computes to 4, but the text says 5", failures[0])

    def test_a_missing_answer_and_a_weak_key_fail(self):
        key = K.one(K.num("4"), accepts=["4"], rejects=["5"])
        cards = {"four": {"check": {"answer": "4", "answerKey": key}}}
        fixture = types.SimpleNamespace(__name__="fixture", cards=lambda k: cards, answers=lambda: {})
        failures = answer_failures(fixture)
        self.assertTrue(any("no computed answer for four-check" in line for line in failures), failures)
        self.assertTrue(any("needs at least 1 accepted and 2 rejected" in line for line in failures), failures)

    def test_a_computed_answer_the_key_rejects_fails(self):
        key = K.one(K.num("4"), accepts=["4"], rejects=["5", "6"])
        cards = {"four": {"check": {"answer": "4", "answerKey": key}}}
        fixture = types.SimpleNamespace(__name__="fixture", cards=lambda k: cards, answers=lambda: {"four-check": 2 + 3})
        self.assertEqual(answer_failures(fixture), ["fixture: four-check computes to '5', which its key marks wrong"])


if __name__ == "__main__":
    unittest.main()
