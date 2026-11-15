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
        card(pack, "lcm")["standsOn"].append("ratio")
        card(pack, "power")["standsOn"] = ["square-root"]
        card(pack, "factor")["aliases"].append("multiples")
        self.assertFails(pack, "hcf has no oneSentence", 'lcm stands on "ratio"', "power stands on a loop",
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


class LinkerTest(unittest.TestCase):
    linker = content_checks.linker_for(PACK)

    def concepts(self, text, **kwargs):
        return [link["concept"] for link in self.linker.links(text, **kwargs)]

    def test_longest_phrase_wins(self):
        self.assertEqual(self.concepts("The highest common factor of 12 and 18"), ["hcf"])
        self.assertEqual(self.concepts("Its prime factors are 2 and 3"), ["prime-factors"])

    def test_stop_phrase_links_nothing(self):
        self.assertEqual(self.concepts("The scale factor is 2"), [])

    def test_word_edges(self):
        self.assertEqual(self.concepts("Factorise it, a powerful idea"), [])
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
