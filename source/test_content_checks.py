import copy
import json
import unittest

import content_checks
import export_kymmaths_pack as exporter
from concept_links import Linker

PACK = json.loads(exporter.PACK_OUT.read_text(encoding="utf-8"))
REWRITTEN = exporter.rewritten_chapters()


def chapter(pack, number=1):
    return next(ch for ch in pack["chapters"] if ch["number"] == number)


def card(pack, cid):
    return next(c for c in pack["concepts"] if c["id"] == cid)


def step(pack, section, kind):
    return next(s for s in chapter(pack)["sections"][section]["steps"] if s["kind"] == kind)


class ContentChecksTest(unittest.TestCase):
    def assertFails(self, pack, *fragments):
        found = content_checks.problems(pack, REWRITTEN)
        for fragment in fragments:
            self.assertTrue(any(fragment in line for line in found), f"no problem mentions {fragment!r}: {found}")

    def fixture(self):
        return copy.deepcopy(PACK)

    def test_real_content_passes(self):
        self.assertEqual(content_checks.problems(PACK, REWRITTEN), [])

    def test_exporter_build_matches_the_pack_for_rewritten_chapters(self):
        built = {ch["number"]: ch for ch in exporter.build_chapters()}
        for number in REWRITTEN:
            self.assertEqual(built[number], chapter(PACK, number))
        self.assertEqual(exporter.build_concepts(exporter.build_chapters()), PACK["concepts"])

    def test_1_key_term_without_a_card(self):
        pack = self.fixture()
        chapter(pack)["keyTerms"].append("Integer")
        chapter(pack)["sections"][0]["teaches"].append("integer")
        self.assertFails(pack, 'key term "Integer" is not the name', 'teaches "integer"')

    def test_2_card_missing_field_dangling_link_loop_and_shared_alias(self):
        pack = self.fixture()
        del card(pack, "hcf")["oneSentence"]
        card(pack, "lcm")["standsOn"].append("no-such-card")
        card(pack, "power")["standsOn"] = ["square-root"]
        card(pack, "factor")["aliases"].append("multiples")
        self.assertFails(pack, "hcf has no oneSentence", 'lcm stands on "no-such-card"', "power stands on a loop",
                         'alias "multiples" belongs to factor, multiple')

    def test_2_card_too_far_from_what_she_knows(self):
        pack = self.fixture()
        card(pack, "power")["standsOn"] = ["prime-factors"]
        self.assertFails(pack, "square-root is 3 steps")

    def test_3_banned_word_and_exclamation_mark(self):
        pack = self.fixture()
        chapter(pack)["hookSummary"] = "Why is it simply true that a minus times a minus makes a plus!"
        self.assertFails(pack, 'uses "simply"', "exclamation mark")

    def test_4_long_sentence(self):
        pack = self.fixture()
        step(pack, 0, "sayBack")["text"] = " ".join(["word"] * 26) + "."
        self.assertFails(pack, "sentence of 26 words")

    def test_5_sentence_shared_with_another_chapter(self):
        pack = self.fixture()
        other = next(c for c in chapter(pack, 4)["callouts"] if c["kind"] == "careful")["body"]
        chapter(pack)["callouts"][2]["body"] = other
        self.assertFails(pack, "5 shared sentence", "also appears in chapter")

    def test_6_term_used_before_its_name_step_and_steps_out_of_order(self):
        pack = self.fixture()
        step(pack, 0, "idea")["text"] += " The highest common factor comes later."
        steps = chapter(pack)["sections"][1]["steps"]
        steps[0], steps[1] = steps[1], steps[0]
        self.assertFails(pack, "hcf is used in an earlier step than ch01-s3's name step",
                         "ch01-s2 steps are", "not the nine kinds in order")

    def test_6_concept_not_taught_yet(self):
        pack = self.fixture()
        for section in chapter(pack)["sections"]:
            section["teaches"] = [cid for cid in section["teaches"] if cid != "irrational-number"]
        self.assertFails(pack, "ch01 uses irrational-number, which stands on other cards")

    def test_7_skill_card_without_an_answer(self):
        pack = self.fixture()
        chapter(pack)["skillCard"]["sheCan"]["answer"] = ""
        self.assertFails(pack, "skill card has no sheCan.answer")
        del chapter(pack)["skillCard"]
        self.assertFails(pack, "ch01 has no skill card")


class DebateTest(unittest.TestCase):
    """G5: the "Who is right?" text lives in the chapter file, so the checks read it."""

    SCENARIO_FIELDS = {"id", "chapterNumber", "oupUnitNumber", "title", "contextPrompt", "speakerAName", "speakerAClaim",
                       "speakerBName", "speakerBClaim", "choices", "invariantTakeaway"}
    CHOICE_FIELDS = {"id", "speakerLabel", "reasoningStatement", "isCorrect", "socraticRebuttal"}

    def test_chapter_1_record_carries_the_debate_in_the_swift_shape(self):
        debate = chapter(PACK)["debate"]
        self.assertEqual(set(debate), self.SCENARIO_FIELDS)
        self.assertEqual((debate["id"], debate["chapterNumber"], debate["oupUnitNumber"]), ("debate-ch01-primes", 1, 1))
        self.assertEqual([choice["id"] for choice in debate["choices"]], ["ch01-a", "ch01-b", "ch01-c"])
        self.assertTrue(all(set(choice) == self.CHOICE_FIELDS for choice in debate["choices"]))
        self.assertEqual([choice["isCorrect"] for choice in debate["choices"]], [False, True, False])

    def test_3_banned_word_in_a_debate_fails(self):
        pack = copy.deepcopy(PACK)
        chapter(pack)["debate"]["choices"][0]["socraticRebuttal"] = "It is obviously not 216."
        found = content_checks.problems(pack, REWRITTEN)
        self.assertTrue(any(line.startswith("3 banned word") and "debate" in line and '"obviously"' in line
                            for line in found), found)


class BeyondSchoolBookTest(unittest.TestCase):
    """G6: a chapter says whether it goes past her school book, and if it does, names what it stands on."""

    def test_chapter_1_is_in_the_school_book(self):
        self.assertIs(chapter(PACK)["beyondSchoolBook"], False)

    def test_7_beyond_school_chapter_with_nothing_to_stand_on_fails(self):
        pack = copy.deepcopy(PACK)
        chapter(pack)["beyondSchoolBook"] = True
        self.assertEqual([line for line in content_checks.problems(pack, REWRITTEN) if line.startswith("7")], [])
        chapter(pack)["skillCard"]["standsOn"] = []
        found = content_checks.problems(pack, REWRITTEN)
        self.assertTrue(any(line.startswith("7 skill card") and "beyond the school book" in line for line in found),
                        found)

    def test_7_chapter_without_the_flag_fails(self):
        pack = copy.deepcopy(PACK)
        del chapter(pack)["beyondSchoolBook"]
        self.assertTrue(any("has no beyondSchoolBook" in line for line in content_checks.problems(pack, REWRITTEN)))


class FigureTest(unittest.TestCase):
    """G7: the figure shows only beside a section whose steps point at it ("In the figure")."""

    def test_chapter_1_sections_that_name_the_figure_carry_it(self):
        self.assertEqual([section.get("figure", False) for section in chapter(PACK)["sections"]],
                         [True, False, True, False, False])
        self.assertNotIn("figure", chapter(PACK)["sections"][1])

    def test_9_figure_flag_and_text_must_agree(self):
        pack = copy.deepcopy(PACK)
        del chapter(pack)["sections"][0]["figure"]
        chapter(pack)["sections"][4]["figure"] = True
        found = [line for line in content_checks.problems(pack, REWRITTEN) if line.startswith("9 figure")]
        self.assertEqual(len(found), 2, found)
        self.assertIn("ch01-s1", found[0])
        self.assertIn("ch01-s5", found[1])


class WholePackReportTest(unittest.TestCase):
    """G10: checks 3 and 4 over the whole pack, counted, never stopping the run."""

    def test_report_counts_a_banned_word_in_an_unrewritten_chapter(self):
        before = content_checks.report(PACK)
        pack = copy.deepcopy(PACK)
        chapter(pack, 13)["hookSummary"] = "Obviously this is clearly a hook."
        after = content_checks.report(pack)
        self.assertEqual(after["ch13"]["banned"], before["ch13"]["banned"] + 2)
        self.assertEqual(after["total"]["banned"], before["total"]["banned"] + 2)
        self.assertEqual(set(after), {f"ch{n:02d}" for n in range(21)} | {"cards", "total"})

    def test_report_mode_exits_0_and_prints_a_total(self):
        import subprocess
        import sys
        run = subprocess.run([sys.executable, "content_checks.py", "--report"], capture_output=True, text=True,
                             cwd=str(exporter.Path(__file__).resolve().parent))
        self.assertEqual(run.returncode, 0, run.stderr)
        self.assertIn("ch05", run.stdout)
        self.assertIn("Total", run.stdout)


class AmbiguousWordTest(unittest.TestCase):
    """Check 8: an everyday word that is also a maths word is never a card's bare alias (risk R1)."""

    def test_8_a_card_named_by_a_bare_everyday_word_fails(self):
        pack = copy.deepcopy(PACK)
        pack["concepts"].append({**copy.deepcopy(card(pack, "factor")), "id": "set", "name": "Set",
                                 "aliases": ["Set", "a set", "the set of"]})
        found = content_checks.problems(pack, REWRITTEN)
        hits = [line for line in found if line.startswith("8 ambiguous")]
        self.assertEqual(len(hits), 1, found)
        self.assertIn('"Set"', hits[0])
        self.assertIn("set", hits[0])

    def test_8_power_keeps_only_unambiguous_aliases(self):
        self.assertNotIn("power", [alias.lower() for alias in card(PACK, "power")["aliases"]])


class CardFilesTest(unittest.TestCase):
    """Cards live in the file of the chapter that teaches them, and bedrock cards in book/bedrock.py (risk R5)."""

    def test_cards_built_from_their_chapter_files_equal_the_pack(self):
        from book import (bedrock, ch01, ch02, ch03, ch04, ch05, ch06, ch07, ch08, ch09, ch10, ch11, ch12,
                          ch13, ch14, ch15, ch16, ch17, ch18, ch19, ch20)
        k = exporter.helpers()
        self.assertEqual(set(bedrock.cards(k)), {"negative-number", "factor", "multiple", "power", "fraction",
                                                 "decimal-place", "percentage", "area", "angle"})
        self.assertEqual(set(ch02.cards(k)), {"numerator-denominator", "equivalent-fractions", "simplest-form",
                                              "common-denominator", "improper-fraction", "mixed-number", "reciprocal",
                                              "significant-figures", "terminating-decimal", "recurring-decimal"})
        self.assertEqual(set(ch03.cards(k)), {"ratio", "unitary-method", "direct-proportion", "inverse-proportion",
                                              "percentage-multiplier", "reverse-percentage", "simple-interest",
                                              "compound-growth", "rule-of-72"})
        self.assertEqual(set(ch04.cards(k)), {"variable", "expression", "substitution", "term", "coefficient",
                                              "like-terms", "expanding-brackets", "factorising", "quadratic-expression",
                                              "difference-of-two-squares"})
        self.assertEqual(set(ch05.cards(k)), {"equation", "inverse-operation", "solving-equations", "formula",
                                              "subject-of-a-formula", "inequality"})
        self.assertEqual(set(ch06.cards(k)), {"sequence", "term-to-term-rule", "common-difference", "arithmetic-sequence",
                                              "geometric-sequence", "nth-term", "quadratic-sequence", "triangular-number"})
        self.assertEqual(set(ch07.cards(k)), {"function-machine", "inverse-function", "coordinates", "gradient",
                                              "intercept", "linear-graph", "parallel-lines", "real-life-graph"})
        self.assertEqual(set(ch08.cards(k)), {"vertically-opposite-angles", "transversal", "corresponding-angles",
                                              "alternate-angles", "co-interior-angles", "proof", "exterior-angle",
                                              "polygon", "interior-angle", "midpoint"})
        self.assertEqual(set(ch09.cards(k)), {"locus", "perpendicular-bisector", "angle-bisector", "congruent",
                                              "quadrilateral", "bearing", "net-of-a-solid", "plan-and-elevation",
                                              "vertices-edges-faces", "eulers-formula"})
        self.assertEqual(set(ch10.cards(k)), {"radius-and-diameter", "pi", "circumference", "trapezium", "area-of-a-circle",
                                              "sector", "volume", "prism", "cross-section", "surface-area",
                                              "cavalieris-principle"})
        self.assertEqual(set(ch11.cards(k)), {"transformation", "translation", "column-vector", "reflection", "rotation",
                                              "symmetry", "enlargement", "scale-factor", "similar-shapes",
                                              "area-scale-factor"})
        self.assertEqual(set(ch12.cards(k)), {"right-angled-triangle", "hypotenuse", "pythagoras-theorem", "theta",
                                              "tangent", "sine", "cosine", "unit-circle", "pythagorean-identity", "radian",
                                              "sine-rule", "cosine-rule"})
        self.assertEqual(set(ch13.cards(k)), {"population", "sample", "random-sample", "systematic-sample",
                                              "stratified-sample", "bias", "survivorship-bias", "mean",
                                              "standard-error"})
        self.assertEqual(set(ch14.cards(k)), {"time-series", "moving-average", "stem-and-leaf-diagram", "median",
                                              "quartile", "interquartile-range", "class-width", "frequency-density",
                                              "histogram", "sigma", "variance", "standard-deviation"})
        self.assertEqual(set(ch15.cards(k)), {"outcome", "sample-space", "probability", "mutually-exclusive",
                                              "experimental-probability", "independent-events", "tree-diagram",
                                              "factorial", "permutation", "combination", "bell-curve"})
        self.assertEqual(set(ch16.cards(k)), {"conditional-probability", "base-rate", "prior", "sensitivity",
                                              "specificity", "false-positive", "posterior", "likelihood-ratio",
                                              "bayes-theorem"})
        self.assertEqual(set(ch17.cards(k)), {"secant-line", "limit", "tangent-line", "rate-of-change",
                                              "derivative", "power-rule", "stationary-point", "maximum-and-minimum"})
        self.assertEqual(set(ch18.cards(k)), {"riemann-sum", "midpoint-rule", "definite-integral", "signed-area",
                                              "antiderivative", "fundamental-theorem-of-calculus"})
        self.assertEqual(set(ch19.cards(k)), {"position-vector", "adding-vectors", "zero-vector", "magnitude",
                                              "scalar-multiple", "collinear", "dot-product"})
        self.assertEqual(set(ch20.cards(k)), {"basis-vectors", "linear-transformation", "matrix",
                                              "matrix-multiplication", "determinant", "singular-matrix",
                                              "eigenvector", "eigenvalue"})
        self.assertEqual(set(ch01.cards(k)), {"prime-number", "prime-factors", "hcf", "lcm", "index-laws",
                                              "square-root", "irrational-number"})
        self.assertTrue(all(card["standsOn"] == [] for card in bedrock.cards(k).values()))
        built = {c["id"]: c for c in exporter.build_concepts(exporter.build_chapters())}
        self.assertEqual(built, {c["id"]: c for c in PACK["concepts"]})

    def test_a_card_id_in_two_files_stops_the_build(self):
        from book import concepts
        with self.assertRaises(SystemExit) as caught:
            concepts.merge([("book.bedrock", {"factor": {"name": "Factor"}}),
                            ("book.ch01", {"factor": {"name": "Factor again"}})])
        self.assertIn("factor", str(caught.exception))
        self.assertIn("book.ch01", str(caught.exception))


class NewLinksReportTest(unittest.TestCase):
    """The splice lists every link the old golden file did not have, so a writer can spot false links (risk R1)."""

    def entries(self, texts):
        linker = Linker({"set": {"aliases": ["set", "sets"]}}, [])
        return [{"text": text, "exclude": None, "linked": [], "links": linker.links(text)} for text in texts]

    def test_reports_true_and_false_links_with_context(self):
        import splice_pack_sections as splice
        true_text = "Write down the set of even numbers between 1 and 9."
        false_text = "In the figure, set the sliders to 24 and 36 and read the blue bar."
        old = self.entries(["Nothing to link here."])
        lines = splice.new_link_lines(old, self.entries(["Nothing to link here.", true_text, false_text]))
        self.assertEqual(len(lines), 2, lines)
        self.assertIn("set", lines[0])
        self.assertIn("Write down the [set] of even numbers", lines[0])
        self.assertIn("In the figure, [set] the sliders to 24", lines[1])

    def test_a_link_already_in_the_old_file_is_not_new(self):
        import splice_pack_sections as splice
        same = self.entries(["the set of even numbers"])
        self.assertEqual(splice.new_link_lines(same, same), [])

    def test_context_is_cut_to_forty_characters_each_side(self):
        import splice_pack_sections as splice
        text = "a" * 60 + " set " + "b" * 60
        line = splice.new_link_lines([], self.entries([text]))[0]
        self.assertIn("…" + "a" * 39 + " [set] " + "b" * 39 + "…", line)


class LinkerTest(unittest.TestCase):
    linker = content_checks.linker_for(PACK)

    def concepts(self, text, **kwargs):
        return [link["concept"] for link in self.linker.links(text, **kwargs)]

    def test_longest_phrase_wins(self):
        self.assertEqual(self.concepts("The highest common factor of 12 and 18"), ["hcf"])
        self.assertEqual(self.concepts("Its prime factors are 2 and 3"), ["prime-factors"])

    def test_stop_phrase_links_nothing(self):
        self.assertEqual(self.concepts("The conversion factor is 2"), [])
        self.assertEqual(self.concepts("The scale factor is 2"), ["scale-factor"])

    def test_word_edges(self):
        self.assertEqual(self.concepts("A factory, a powerful idea"), [])
        self.assertEqual(self.concepts("√2 is about 1.41"), ["square-root"])

    def test_exclude_and_scope(self):
        self.assertEqual(self.concepts("A factor of a factor", exclude="factor"), [])
        self.assertEqual(self.concepts("A factor of a factor"), ["factor"])
        self.assertEqual(self.concepts("Find a factor", linked={"factor"}), [])

    def test_offsets_count_unicode_scalars(self):
        linker = Linker({"square-root": {"aliases": ["√"]}}, [])
        self.assertEqual(linker.links("2³ √9"), [{"concept": "square-root", "text": "√", "offset": 3}])


if __name__ == "__main__":
    unittest.main()
