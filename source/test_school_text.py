"""Plan step 6: a chapter file rewrites its school unit's worked examples, faded prompts and topic summaries."""

import copy
import json
import unittest
from unittest import mock

import content_checks
import export_kymmaths_pack as exporter
import splice_pack_sections as splice

PACK = json.loads(exporter.PACK_OUT.read_text(encoding="utf-8"))
REWRITTEN = exporter.rewritten_chapters()
QID = "q-oup-ch06-sb"


def question(pack, qid=QID):
    return next(q for q in pack["schoolQuestions"] if q["id"] == qid)


def topic(textbook, code):
    return next(t for unit in textbook["units"] for t in unit["topics"] if t["code"] == code)


def authored(questions=(), topics=()):
    return {"questions": set(questions), "topics": set(topics)}


class SchoolTextChecksTest(unittest.TestCase):
    """Checks 3 and 4 read an authored question's worked example, faded prompt and stuck sheet, and authored topic summaries."""

    def test_3_banned_word_in_an_authored_worked_example_names_the_question(self):
        pack = copy.deepcopy(PACK)
        question(pack)["workedExample"] = "Step 1: Let x = 0.2727….\nStep 2: Now we simply multiply x by 100."
        found = content_checks.problems(pack, REWRITTEN, authored(questions=[QID]))
        self.assertTrue(any(line.startswith("3 banned word") and QID in line and '"simply"' in line for line in found),
                        found)

    def test_an_unauthored_question_is_not_checked(self):
        pack = copy.deepcopy(PACK)
        question(pack)["workedExample"] = "We simply multiply by 100!"
        self.assertEqual(content_checks.problems(pack, REWRITTEN), [])

    def test_4_long_sentence_on_the_second_line_of_a_worked_example(self):
        pack = copy.deepcopy(PACK)
        question(pack)["workedExample"] = "Step 1: Let x = 0.2727….\nStep 2: " + " ".join(["word"] * 25) + "."
        found = [line for line in content_checks.problems(pack, REWRITTEN, authored(questions=[QID]))
                 if line.startswith("4 long sentence")]
        self.assertEqual(len(found), 1, found)
        self.assertIn(QID, found[0])
        self.assertIn("sentence of 26 words", found[0])
        self.assertIn('"Step 2: word', found[0])

    def test_3_faded_prompt_stuck_sheet_and_topic_summary_are_checked(self):
        pack = copy.deepcopy(PACK)
        q = question(pack)
        q["fadedPrompt"] = "Obviously 99x = ___."
        q["stuck"]["sister"] = "Write 0.444… as a fraction!"
        q["stuck"]["steps"][1]["working"] = "The tails clearly cancel."
        topic(pack["schoolTextbook"], "6.3")["summary"] = "Some decimals just stop."
        found = content_checks.problems(pack, REWRITTEN, authored(questions=[QID], topics=["6.3"]))
        for fragment in (f'{QID} fadedPrompt uses "Obviously"', f"{QID} stuck.sister has an exclamation mark",
                         f'{QID}-step-2 working uses "clearly"', 'topic 6.3 summary uses "just"'):
            self.assertTrue(any(fragment in line for line in found), f"no problem mentions {fragment!r}: {found}")

    def test_3_a_mistake_next_step_on_an_authored_stuck_sheet_is_checked(self):
        pack = copy.deepcopy(PACK)
        sheet = next(q for q in pack["schoolQuestions"]
                     if "stuck" in q and any(s["answerKey"]["mistakes"] for s in q["stuck"]["steps"]))
        step = next(s for s in sheet["stuck"]["steps"] if s["answerKey"]["mistakes"])
        step["answerKey"]["mistakes"][0]["nextStep"] = "Obviously look again."
        found = content_checks.problems(pack, REWRITTEN, authored(questions=[sheet["id"]]))
        self.assertTrue(any(line.startswith("3 banned word") and step["id"] in line and "nextStep" in line
                            for line in found), found)


class SpliceSchoolTextTest(unittest.TestCase):
    def test_takes_authored_question_fields_and_reports_other_drift(self):
        pack_questions = copy.deepcopy(PACK["schoolQuestions"])
        built = copy.deepcopy(PACK["schoolQuestions"])
        question({"schoolQuestions": built})["workedExample"] = "Step 1: New."
        question({"schoolQuestions": built})["fadedPrompt"] = "New ___."
        question({"schoolQuestions": built})["modelAnswer"] = "Built model answer."
        old_model = question({"schoolQuestions": pack_questions})["modelAnswer"]
        drift = splice.splice_stuck(pack_questions, built, {QID: {"workedExample", "fadedPrompt"}})
        spliced = question({"schoolQuestions": pack_questions})
        self.assertEqual((spliced["workedExample"], spliced["fadedPrompt"]), ("Step 1: New.", "New ___."))
        self.assertEqual(spliced["modelAnswer"], old_model)
        self.assertEqual(drift, [f"{QID}: modelAnswer"])

    def test_unauthored_question_fields_are_still_drift(self):
        pack_questions = copy.deepcopy(PACK["schoolQuestions"])
        built = copy.deepcopy(PACK["schoolQuestions"])
        question({"schoolQuestions": built})["workedExample"] = "Step 1: New."
        self.assertEqual(splice.splice_stuck(pack_questions, built), [f"{QID}: workedExample"])

    def test_takes_only_the_topic_summary_and_keeps_the_pack_topic_fields(self):
        pack_textbook = copy.deepcopy(PACK["schoolTextbook"])
        built = exporter.build_school_textbook()
        topic(built, "6.3")["summary"] = "A new summary."
        topic(built, "6.4")["summary"] = "Not authored."
        self.assertNotEqual(topic(built, "6.3")["cambridgeWatchouts"], topic(pack_textbook, "6.3")["cambridgeWatchouts"])
        splice.splice_topic_summaries(pack_textbook, built, {"6.3"})
        expected = copy.deepcopy(PACK["schoolTextbook"])
        topic(expected, "6.3")["summary"] = "A new summary."
        self.assertEqual(pack_textbook, expected)


class ExporterSchoolTextTest(unittest.TestCase):
    def test_book_keys_merge_across_chapters_and_a_missing_key_is_empty(self):
        specs = {1: {}, 2: {"schoolTopics": {"6.3": "A."}, "schoolQuestions": {QID: {"fadedPrompt": "B ___."}}},
                 3: {"schoolTopics": {"9.3": "C."}}}
        with mock.patch.object(exporter, "book_specs", return_value=specs):
            self.assertEqual(exporter.book_school_topics(), {"6.3": "A.", "9.3": "C."})
            self.assertEqual(exporter.book_school_questions(), {QID: {"fadedPrompt": "B ___."}})

    def test_a_question_authored_by_two_chapters_stops_the_build(self):
        specs = {2: {"schoolQuestions": {QID: {"fadedPrompt": "B ___."}}},
                 3: {"schoolQuestions": {QID: {"fadedPrompt": "C ___."}}}}
        with mock.patch.object(exporter, "book_specs", return_value=specs):
            with self.assertRaises(SystemExit) as caught:
                exporter.book_school_questions()
        self.assertIn(QID, str(caught.exception))

    def test_authored_fields_override_the_build_and_the_stuck_sheet_stays(self):
        text = {QID: {"workedExample": "Step 1: Let x = 0.2727….\nStep 2: Multiply by 100."}}
        with mock.patch.object(exporter, "book_school_questions", return_value={}):
            plain = question({"schoolQuestions": exporter.build_school_questions()})
        with mock.patch.object(exporter, "book_school_questions", return_value=text):
            built = question({"schoolQuestions": exporter.build_school_questions()})
        self.assertEqual(built["workedExample"], text[QID]["workedExample"])
        self.assertEqual(built["fadedPrompt"], plain["fadedPrompt"])
        self.assertEqual(built["stuck"], plain["stuck"])
        self.assertEqual(built["stuck"], question(PACK)["stuck"])

    def test_an_unknown_question_id_stops_the_build(self):
        with mock.patch.object(exporter, "book_school_questions", return_value={"q-oup-ch99-sb": {"fadedPrompt": "x"}}):
            with self.assertRaises(SystemExit) as caught:
                exporter.build_school_questions()
        self.assertIn("q-oup-ch99-sb", str(caught.exception))

    def test_an_unknown_question_field_stops_the_build(self):
        with mock.patch.object(exporter, "book_school_questions", return_value={QID: {"modelAnswer": "x"}}):
            with self.assertRaises(SystemExit) as caught:
                exporter.build_school_questions()
        self.assertIn("modelAnswer", str(caught.exception))

    def test_authored_topic_summary_overrides_the_build(self):
        with mock.patch.object(exporter, "book_school_topics", return_value={}):
            plain = exporter.build_school_textbook()
        with mock.patch.object(exporter, "book_school_topics", return_value={"6.3": "A new summary."}):
            built = exporter.build_school_textbook()
        self.assertEqual(topic(built, "6.3")["summary"], "A new summary.")
        self.assertEqual(topic(built, "6.4")["summary"], topic(plain, "6.4")["summary"])

    def test_an_unknown_topic_code_stops_the_build(self):
        with mock.patch.object(exporter, "book_school_topics", return_value={"6.9": "A."}):
            with self.assertRaises(SystemExit) as caught:
                exporter.build_school_textbook()
        self.assertIn("6.9", str(caught.exception))

    def test_golden_file_gains_authored_question_text_and_topic_summaries(self):
        with mock.patch.object(exporter, "book_school_questions", return_value={}), \
                mock.patch.object(exporter, "book_school_topics", return_value={}):
            before = [entry["text"] for entry in exporter.concept_link_golden(PACK)]
        q = question(PACK)
        with mock.patch.object(exporter, "book_school_questions", return_value={QID: {"fadedPrompt": "x ___"}}), \
                mock.patch.object(exporter, "book_school_topics", return_value={"6.3": "y"}):
            after = [entry["text"] for entry in exporter.concept_link_golden(PACK)]
        added = list(after)
        for text in before:
            added.remove(text)
        self.assertEqual(sorted(added), sorted([q["prompt"], q["workedExample"], q["fadedPrompt"],
                                                topic(PACK["schoolTextbook"], "6.3")["summary"]]))

    def test_authored_ids_for_the_checks(self):
        with mock.patch.object(exporter, "book_school_questions", return_value={QID: {"fadedPrompt": "x ___"}}), \
                mock.patch.object(exporter, "book_school_topics", return_value={"6.3": "y"}):
            self.assertEqual(exporter.book_school_authored(), {"questions": {QID}, "topics": {"6.3"}})


if __name__ == "__main__":
    unittest.main()
