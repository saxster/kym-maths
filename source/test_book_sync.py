"""Supplemental check that index.html stays synced with build_html_book() and uses plain English."""

import unittest

import export_kymmaths_pack as exporter

PAGE = exporter.BOOK_OUT.read_text(encoding="utf-8")


class BookSyncAndPlainEnglishTest(unittest.TestCase):
    def test_index_matches_exporter_and_uses_embed_and_plain_english(self):
        chapters = exporter.build_chapters()
        explorers = exporter.build_explorers()
        widgets = exporter.build_widgets(chapters)
        generated = exporter.build_html_book(chapters, explorers, widgets)
        self.assertEqual(PAGE, generated, "index.html drifted from build_html_book()")
        ch19 = next(c for c in chapters if c["number"] == 19)
        self.assertEqual(ch19["intuitionToFormula"]["atlasFigureRef"], "maths/multivariable/index.html#2")
        self.assertIn("embed=1", PAGE)
        self.assertNotIn("Bland", PAGE)
        self.assertNotIn("Wild &amp; Whacky", PAGE)
        self.assertNotIn("MAD ATELIER", PAGE)


if __name__ == "__main__":
    unittest.main()
