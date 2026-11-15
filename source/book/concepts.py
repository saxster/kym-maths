"""
Concept cards: one short page per technical word or symbol.

Any learner text that uses one of a card's `aliases` links to the card. The standard for a card
is in docs/CONTENT_BRIEF.md. A card lives in the file of the chapter that teaches it, as that file's
`cards(k)`, and bedrock cards, which stand on nothing, live in `bedrock.py`. `build(k)` merges them:
bedrock first, then each chapter in the exporter's `BOOK_CHAPTERS` that has `cards`. Registering a
chapter there is the one line that brings in its cards. `k` is the exporter module, with its answer-key
helpers (num, forms, one), so no book file imports the exporter.
"""

from itertools import permutations

from book import bedrock

# Phrases that contain an alias but mean something else. They are matched like aliases and never link.
STOP_PHRASES = [
    "scale factor", "scale factors", "conversion factor", "multiple choice", "multiple-choice",
]


def product_forms(k, *factors):
    """Every order of a product, so 2 × 3 × 5 and 5 × 2 × 3 both mark right."""
    orders = sorted({"*".join(order) for order in permutations(factors)})
    return k.forms(*orders)


def card_modules(k):
    return [bedrock] + [module for module in k.BOOK_CHAPTERS if hasattr(module, "cards")]


def merge(groups):
    """One dict of cards from (source name, cards) pairs. A card id defined in two files stops the build."""
    merged, owner = {}, {}
    for source, cards in groups:
        for cid, card in cards.items():
            if cid in merged:
                raise SystemExit(f"Concept card \"{cid}\" is defined in both {owner[cid]} and {source}")
            merged[cid], owner[cid] = card, source
    return merged


def build(k):
    return merge((module.__name__, module.cards(k)) for module in card_modules(k))
