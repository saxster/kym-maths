"""The Python expression reader agrees with the Swift one on every case in the shared golden file."""

import json
import unittest
from pathlib import Path

import answer_marking as marking
import export_kymmaths_pack as exporter

GOLDEN = Path(__file__).resolve().parent.parent / "KymMaths" / "Tests" / "Golden" / "expression-reading.json"


def factorised_text(node):
    shape, bracket = marking.factorisation(node)
    return f"{shape}: {marking.display(bracket)}" if bracket is not None else shape


class ExpressionReadingTest(unittest.TestCase):
    def test_golden_cases(self):
        cases = json.loads(GOLDEN.read_text(encoding="utf-8"))
        self.assertGreater(len(cases), 20)
        for case in cases:
            with self.subTest(input=case["input"]):
                node = marking.parse_expression(case["input"])
                self.assertEqual(None if node is None else marking.display(node), case["readsAs"])
                if "preview" in case:
                    self.assertEqual(marking.reads_as(case["input"]), case["preview"])
                if node is None:
                    continue
                self.assertEqual(marking.expansion(node), case["expanded"])
                self.assertEqual(factorised_text(node), case["factorised"])
                if "equivalentTo" in case:
                    target = marking.parse_expression(case["equivalentTo"])
                    self.assertIsNotNone(target)
                    self.assertEqual(marking.equivalent(node, target), case["equivalent"])

    def test_unfinished_answers_name_the_slip(self):
        factorise = {"parts": [{"label": "answer", "anyOf": [exporter.expr("6ab(3a-2b)", "factorised")]}], "mistakes": []}
        expand = {"parts": [{"label": "answer", "anyOf": [exporter.expr("5x+3", "expanded")]}], "mistakes": []}
        self.assertEqual(marking.mark(factorise, "6a(3ab − 2b²)"), (False, "common-factor-left"))
        self.assertEqual(marking.mark(factorise, "18a²b − 12ab²"), (False, "stopped-early"))
        self.assertEqual(marking.mark(factorise, "6ab(3a + 2b)"), (False, None))
        self.assertEqual(marking.mark(expand, "2(x + 3) + 3(x − 1)"), (False, "stopped-early"))
        self.assertEqual(marking.mark(expand, "2x + 3x + 3"), (False, "stopped-early"))
        self.assertEqual(marking.mark(expand, "x·5 + 3"), (True, None))
        self.assertIn("(3ab−2b²)", marking.unfinished("factorised", marking.parse_expression("6a(3ab-2b^2)"))[1])

    def test_unfinished_ids_are_in_the_registry(self):
        self.assertEqual(exporter.MISCONCEPTIONS["stopped-early"], "You stopped one step too soon")
        self.assertEqual(exporter.MISCONCEPTIONS["common-factor-left"], "You left a common factor in")

    def test_an_expression_matcher_needs_a_value_that_reads(self):
        with self.assertRaises(SystemExit):
            exporter.expr("x > 4")
        self.assertEqual(exporter.expr("5x+3"), {"kind": "expression", "value": "5x+3"})
        self.assertEqual(exporter.expr("5x+3", "expanded")["form"], "expanded")


if __name__ == "__main__":
    unittest.main()
