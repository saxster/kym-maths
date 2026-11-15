"""Saved answers key on ids, so every id the pack had at the baseline commit must still be there (plan A8)."""

import copy
import json
import unittest
from pathlib import Path

import export_kymmaths_pack as exporter
import pack_ids

PACK = json.loads(exporter.PACK_OUT.read_text(encoding="utf-8"))
BASELINE = json.loads((Path(__file__).resolve().parent / "fixtures" / "baseline_ids.json").read_text(encoding="utf-8"))


class PackIdsTest(unittest.TestCase):
    def test_every_baseline_id_still_exists(self):
        self.assertEqual(pack_ids.missing(PACK, BASELINE), [])

    def test_pinned_counts(self):
        self.assertEqual(pack_ids.counts(PACK), {
            "chapters": 21, "widgets": 47, "atlasLessons": 63, "visualMathTips": 8, "schoolQuestions": 64,
        })

    def test_a_renamed_id_is_reported(self):
        pack = copy.deepcopy(PACK)
        pack["chapters"][1]["sections"][0]["id"] = "ch01-s1-renamed"
        pack["widgets"][0]["id"] = "w_renamed"
        missing = pack_ids.missing(pack, BASELINE)
        self.assertIn("sections: ch01-s1", missing)
        self.assertIn(f"widgets: {PACK['widgets'][0]['id']}", missing)

    def test_a_new_section_id_is_allowed(self):
        pack = copy.deepcopy(PACK)
        pack["chapters"][0]["sections"].append({**pack["chapters"][0]["sections"][-1], "id": "ch00-s4"})
        self.assertEqual(pack_ids.missing(pack, BASELINE), [])


if __name__ == "__main__":
    unittest.main()
