"""
The figure page's 3D box (plan decision D3, item G8): no file path in its caption, and hidden until a figure loads.

The 3D figures are not vendored for offline use (audit D8), so the box starts hidden and shows only when the
iframe's document has something drawn in it. Both the shipped index.html and the exporter's template are read.
"""

import re
import unittest
from pathlib import Path

import export_kymmaths_pack as exporter

PAGE = exporter.BOOK_OUT.read_text(encoding="utf-8")
TEMPLATE = Path(exporter.__file__).read_text(encoding="utf-8")
SOURCES = {"index.html": PAGE, "build_html_book": TEMPLATE}


class AtlasBoxTest(unittest.TestCase):
    def test_no_route_in_the_caption(self):
        for name, source in SOURCES.items():
            with self.subTest(source=name):
                self.assertFalse("Atlas route" in source, f"{name} still says \"Atlas route\"")
                caption = re.search(r"id=\"atlas-caption\">([^<]*)<", source)
                self.assertIsNotNone(caption)
                self.assertNotIn("/", caption.group(1))
                self.assertNotRegex(source, r"getElementById\('atlas-caption'\)\.textContent = `[^`]*\$\{")

    def test_the_box_starts_hidden_and_shows_only_on_a_loaded_figure(self):
        for name, source in SOURCES.items():
            with self.subTest(source=name):
                self.assertRegex(source, r"<section class=\"card\" id=\"atlas-card\" hidden>")
                self.assertIn("addEventListener('load'", source)
                self.assertIn("figureHasContent", source)
                self.assertRegex(source, r"addEventListener\('error'")


if __name__ == "__main__":
    unittest.main()
