"""
Finds the concept-card links in a piece of learner text.

The app's `ConceptLinker` (KymMaths/Core/Learning/ConceptLinker.swift) implements the same rule, and a
Swift test replays `KymMaths/Tests/Golden/concept-links.json`, which `write_golden` builds from this file.
Offsets count Unicode scalars, which is what a Python string index counts.

The rule: scan left to right; at each position try the longest phrase first among every alias and stop
phrase, ignoring case. A phrase edge that is a letter or digit needs a neighbour on that side that is
neither, so "factorise" does not match "factor". A match that is a stop phrase, belongs to `exclude`, or
belongs to a concept already linked in this scope is consumed with no link. Matches never overlap.
"""

from functools import lru_cache
import unicodedata

LETTER_CATEGORIES = {"Lu", "Ll", "Lt", "Lm", "Lo"}


@lru_cache(maxsize=4096)
def is_word_char(char):
    return unicodedata.category(char) in LETTER_CATEGORIES or unicodedata.numeric(char, None) is not None


def fold(text):
    """Lower case one scalar at a time, so offsets in the folded text match the original."""
    return "".join(low if len(low := char.lower()) == 1 else char for char in text)


class Linker:
    def __init__(self, cards, stop_phrases):
        """`cards` maps concept id to a card with `aliases`."""
        phrases = {}
        for stop in stop_phrases:
            phrases[fold(stop)] = None
        for concept_id, card in cards.items():
            for alias in card["aliases"]:
                phrases.setdefault(fold(alias), concept_id)
        self.phrases = sorted(phrases.items(), key=lambda item: (-len(item[0]), item[0]))
        by_first = {}
        for phrase, concept in self.phrases:
            if phrase:
                by_first.setdefault(phrase[0], []).append((phrase, concept))
        self.phrases_by_first = by_first

    def matches(self, text):
        """Every phrase match, left to right, as (offset, length, concept id or None for a stop phrase)."""
        folded = fold(text)
        found = []
        at = 0
        n = len(folded)
        by_first = self.phrases_by_first
        fits = self._fits
        while at < n:
            candidates = by_first.get(folded[at])
            if not candidates:
                at += 1
                continue
            hit = next(((phrase, concept) for phrase, concept in candidates if fits(folded, at, phrase)), None)
            if hit is None:
                at += 1
                continue
            found.append((at, len(hit[0]), hit[1]))
            at += len(hit[0])
        return found

    @staticmethod
    def _fits(folded, at, phrase):
        end = at + len(phrase)
        if folded[at:end] != phrase:
            return False
        if is_word_char(phrase[0]) and at > 0 and is_word_char(folded[at - 1]):
            return False
        if is_word_char(phrase[-1]) and end < len(folded) and is_word_char(folded[end]):
            return False
        return True

    def links(self, text, exclude=None, linked=()):
        """The links in `text` as dicts {concept, text, offset}. `linked` is the scope's already-linked ids."""
        seen = set(linked)
        out = []
        for offset, length, concept in self.matches(text):
            if concept is None or concept == exclude or concept in seen:
                continue
            seen.add(concept)
            out.append({"concept": concept, "text": text[offset:offset + length], "offset": offset})
        return out

    def concepts_in(self, text):
        """Every concept whose alias appears in `text`, linked or not."""
        return {concept for _, _, concept in self.matches(text) if concept is not None}
