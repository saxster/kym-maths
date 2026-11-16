"""
The seven checks from docs/CONTENT_BRIEF.md, and the ones docs/CONTENT_PLAN.md adds, run before the exporter or the splice script writes anything.

They apply to rewritten content: the chapters that come from source/book/, their widget, Atlas and tip
text, every concept card, and the school topic summaries and question text a chapter file writes.
`problems(pack, rewritten, authored)` lists every failure; `require_clean` stops the run when there is one.
"""

import re
import unicodedata

from concept_links import Linker, fold

STEP_KINDS = ["question", "idea", "picture", "reason", "name", "example", "mistake", "turn", "sayBack"]
BANNED = ["invariant", "lockstep", "horizon", "symbolic", "anatomy", "duality", "renormalise", "heuristic",
          "mensuration", "kinematics", "don't worry", "it's easy", "simply", "just", "obviously", "clearly"]
# Everyday words that are also maths words. A card links on "a set" or "sets", never on the bare word,
# or "set the sliders to 24" would open the Set card (check 8).
AMBIGUOUS = {"set", "term", "power", "mean", "range", "limit", "net", "face", "plan", "event", "similar", "function",
             "product", "base", "sample"}
# A section whose steps point at the chapter's figure carries `"figure": true`, and only that section (check 9).
FIGURE_PHRASE = "in the figure"
MAX_SENTENCE_WORDS = 25
SHARED_SENTENCE_WORDS = 6
CARD_TEXT_FIELDS = ["name", "oneSentence", "picture", "workedExample"]


def has_letter(token):
    return any(unicodedata.category(char).startswith("L") for char in token)


def sentences(text):
    return [part for part in re.split(r"(?<=[.?!])\s+", text.strip()) if part]


def word_count(sentence):
    return sum(1 for token in sentence.split() if has_letter(token))


# ---------------------------------------------------------------------------
# What the learner reads
# ---------------------------------------------------------------------------

def chapter_record_strings(chapter, legend=True):
    """(where, text) for every string a learner reads in a chapter record, in reading order."""
    tag = f"ch{chapter['number']:02d}"
    out = [(f"{tag} title", chapter["title"]), (f"{tag} subtitle", chapter["subtitle"]),
           (f"{tag} hookSummary", chapter["hookSummary"])]
    skill = chapter.get("skillCard")
    if skill:
        out += [(f"{tag} skillCard.skill", skill.get("skill", "")),
                (f"{tag} skillCard.sheCan.prompt", skill.get("sheCan", {}).get("prompt", "")),
                (f"{tag} skillCard.sheCan.answer", skill.get("sheCan", {}).get("answer", "")),
                (f"{tag} skillCard.whyItMatters", skill.get("whyItMatters", ""))]
        out += [(f"{tag} skillCard.standsOn", text) for text in skill.get("standsOn", [])]
        out += [(f"{tag} skillCard.unlocks", text) for text in skill.get("unlocks", [])]
    bridge = chapter["intuitionToFormula"]
    out += [(f"{tag} concreteAction", bridge["concreteAction"]), (f"{tag} ahaInvariant", bridge["ahaInvariant"])]
    if legend:
        out.append((f"{tag} formulaDisplay", bridge["formulaDisplay"]))
        for term in bridge["termMappings"]:
            out += [(f"{tag} termMapping", term[field]) for field in ("symbol", "visualPart", "meaning")]
    for section in chapter["sections"]:
        out.append((f"{section['id']} heading", section["heading"]))
        if "steps" in section:
            out += [(step["id"], step["text"]) for step in section["steps"]]
        else:
            out.append((f"{section['id']} excerpt", section["excerpt"]))
    for callout in chapter["callouts"]:
        out += [(f"{callout['id']} title", callout["title"]), (f"{callout['id']} body", callout["body"])]
    out += [(f"{tag} keyTerm", term) for term in chapter["keyTerms"]]
    debate = chapter.get("debate")
    if debate:
        out += [(f"{tag} debate.{field}", debate[field])
                for field in ("title", "contextPrompt", "speakerAName", "speakerAClaim", "speakerBName", "speakerBClaim")]
        for choice in debate["choices"]:
            out += [(f"{tag} debate.{choice['id']}.{field}", choice[field])
                    for field in ("speakerLabel", "reasoningStatement", "socraticRebuttal")]
        out.append((f"{tag} debate.invariantTakeaway", debate["invariantTakeaway"]))
    return out


def chapter_side_strings(pack, number):
    """(where, text) for the widget, Atlas lesson and tip text that belongs to a chapter."""
    out = []
    for widget in pack["widgets"]:
        if widget["chapter"] == number:
            out += [(f"{widget['id']} {field}", widget[field]) for field in ("title", "challengePrompt", "cutaway", "idealised")]
            for step in widget["watchSteps"]:
                out += [(f"{widget['id']} watchStep", step["title"]), (f"{widget['id']} watchStep", step["caption"])]
    for lesson in pack["atlasLessons"]:
        if lesson["chapter"] == number:
            out += [(f"{lesson['id']} {field}", lesson[field]) for field in ("title", "question", "explanation", "limits")]
            out += [(f"{lesson['id']} story", story) for story in lesson["stories"]]
    for tip in pack["visualMathTips"]:
        if tip["chapter"] == number:
            out += [(f"{tip['id']} {field}", tip[field]) for field in ("title", "visualIntuition", "ahaMoment", "formula")]
    return out


def chapter_strings(pack, number, legend=True):
    chapter = next(ch for ch in pack["chapters"] if ch["number"] == number)
    return chapter_record_strings(chapter, legend) + chapter_side_strings(pack, number)


def card_strings(card):
    """(where, text) for every string a learner reads on a concept card."""
    cid = card.get("id", "?")
    out = [(f"card {cid} {field}", card[field]) for field in CARD_TEXT_FIELDS + ["short", "symbol", "bigNumbers"]
           if isinstance(card.get(field), str)]
    out += [(f"card {cid} step", step) for step in card.get("steps", [])]
    check = card.get("check", {})
    out += [(f"card {cid} check.{field}", check[field]) for field in ("prompt", "answer") if isinstance(check.get(field), str)]
    mix_up = card.get("mixUp", {})
    out += [(f"card {cid} mixUp.{field}", mix_up[field]) for field in ("name", "how") if isinstance(mix_up.get(field), str)]
    out += [(f"card {cid} usedIn", use["label"]) for use in card.get("usedIn", [])]
    return out


def school_strings(pack, authored=None):
    """(where, text) for the school text a chapter file rewrites.

    `authored` is {"topics": codes, "questions": ids}. Each authored topic gives its summary; each authored
    question gives its worked example, faded prompt and the text of its stuck sheet.
    """
    authored = authored or {}
    topics, question_ids = authored.get("topics", set()), authored.get("questions", set())
    out = [(f"topic {topic['code']} summary", topic["summary"])
           for unit in pack["schoolTextbook"]["units"] for topic in unit["topics"] if topic["code"] in topics]
    for question in pack["schoolQuestions"]:
        qid = question["id"]
        if qid not in question_ids:
            continue
        out += [(f"{qid} {field}", question[field]) for field in ("workedExample", "fadedPrompt")]
        sheet = question.get("stuck")
        if not sheet:
            continue
        out.append((f"{qid} stuck.sister", sheet["sister"]))
        for step in sheet["steps"]:
            out += [(f"{step['id']} {field}", step[field]) for field in ("prompt", "answer", "working")]
            out += [(f"{step['id']} {slip['misconception']} nextStep", slip["nextStep"])
                    for slip in step["answerKey"]["mistakes"]]
    return out


def rewritten_strings(pack, rewritten, authored=None):
    out = [item for number in sorted(rewritten) for item in chapter_strings(pack, number)]
    return out + [item for card in pack["concepts"] for item in card_strings(card)] + school_strings(pack, authored)


def linker_for(pack):
    return Linker({card["id"]: card for card in pack["concepts"]}, pack["conceptStopPhrases"])


# ---------------------------------------------------------------------------
# The checks
# ---------------------------------------------------------------------------

def check_terms_are_cards(pack, rewritten):
    names = {card["name"] for card in pack["concepts"]}
    ids = {card["id"] for card in pack["concepts"]}
    out = []
    for chapter in pack["chapters"]:
        if chapter["number"] not in rewritten:
            continue
        out += [f"1 key term: {chapter['id']} key term \"{term}\" is not the name of a concept card"
                for term in chapter["keyTerms"] if term not in names]
        for section in chapter["sections"]:
            out += [f"1 key term: {section['id']} teaches \"{cid}\", which is not a concept card"
                    for cid in section.get("teaches", []) if cid not in ids]
    return out


def check_cards(pack):
    out = []
    cards = {card.get("id"): card for card in pack["concepts"]}
    footings = {footing["id"] for footing in pack["footings"]}
    for cid, card in cards.items():
        for field in CARD_TEXT_FIELDS:
            if not isinstance(card.get(field), str) or not card[field].strip():
                out.append(f"2 card: {cid} has no {field}")
        for field in ("aliases", "steps"):
            if not card.get(field):
                out.append(f"2 card: {cid} has no {field}")
        check = card.get("check") or {}
        for field in ("id", "prompt", "answer", "answerKey"):
            if not check.get(field):
                out.append(f"2 card: {cid} check has no {field}")
        mix_up = card.get("mixUp") or {}
        if not mix_up.get("how"):
            out.append(f"2 card: {cid} mixUp has no how")
        if not (mix_up.get("with") or mix_up.get("name")):
            out.append(f"2 card: {cid} mixUp names nothing to tell it apart from")
        if mix_up.get("with") and mix_up["with"] not in cards:
            out.append(f"2 card: {cid} mixUp.with \"{mix_up['with']}\" is not a card")
        if not isinstance(card.get("standsOn"), list):
            out.append(f"2 card: {cid} has no standsOn list")
        out += [f"2 card: {cid} stands on \"{other}\", which is not a card"
                for other in card.get("standsOn", []) if other not in cards]
        if "footing" in card and card["footing"] not in footings:
            out.append(f"2 card: {cid} footing \"{card['footing']}\" is not a footing")
        if not isinstance(card.get("usedIn"), list):
            out.append(f"2 card: {cid} has no usedIn list")

    def depth(cid, path):
        if cid in path:
            return None
        below = [cards[other] for other in cards[cid].get("standsOn", []) if other in cards]
        if not below:
            return 0
        depths = [depth(card["id"], path | {cid}) for card in below]
        return None if None in depths else 1 + min(depths)

    for cid in cards:
        found = depth(cid, frozenset())
        if found is None:
            out.append(f"2 card: {cid} stands on a loop")
        elif found > 2:
            out.append(f"2 card: {cid} is {found} steps from a card that stands on nothing; the limit is 2")

    owners = {}
    for cid, card in cards.items():
        for alias in card.get("aliases", []):
            owners.setdefault(fold(alias), set()).add(cid)
    out += [f"2 card: alias \"{alias}\" belongs to {', '.join(sorted(ids))}"
            for alias, ids in owners.items() if len(ids) > 1]
    return out


def check_ambiguous_aliases(pack):
    return [f"8 ambiguous word: card {card.get('id')} alias \"{alias}\" is the everyday word \"{fold(alias).strip()}\"; "
            "use a longer form that only means the maths"
            for card in pack["concepts"] for alias in card.get("aliases", []) if fold(alias).strip() in AMBIGUOUS]


def check_banned_words(strings):
    pattern = re.compile(r"(?<![\w’'])(" + "|".join(re.escape(word) for word in BANNED) + r")(?![\w’'])", re.IGNORECASE)
    out = []
    for where, text in strings:
        normal = text.replace("’", "'")
        out += [f"3 banned word: {where} uses \"{hit.group(1)}\"" for hit in pattern.finditer(normal)]
        if "!" in re.sub(r"(?:\b[nkr]|[0-9)])!", "", text):
            out.append(f"3 banned word: {where} has an exclamation mark")
    return out


def check_sentence_length(strings):
    return [f"4 long sentence: {where} has a sentence of {word_count(sentence)} words: \"{sentence}\""
            for where, text in strings for sentence in sentences(text) if word_count(sentence) > MAX_SENTENCE_WORDS]


def check_shared_sentences(pack, rewritten):
    def key(sentence):
        return " ".join(fold(sentence).split())

    owners = {}
    for chapter in pack["chapters"]:
        for _, text in chapter_strings(pack, chapter["number"]):
            for sentence in sentences(text):
                if word_count(sentence) >= SHARED_SENTENCE_WORDS:
                    owners.setdefault(key(sentence), set()).add(chapter["number"])
    out = []
    for number in sorted(rewritten):
        reported = set()
        for where, text in chapter_strings(pack, number):
            for sentence in sentences(text):
                chapters = owners.get(key(sentence), set())
                if len(chapters) > 1 and key(sentence) not in reported:
                    reported.add(key(sentence))
                    others = ", ".join(str(n) for n in sorted(chapters - {number}))
                    out.append(f"5 shared sentence: {where} \"{sentence}\" also appears in chapter {others}")
    return out


def check_order(pack, rewritten):
    linker = linker_for(pack)
    cards = {card["id"]: card for card in pack["concepts"]}
    taught_by = {}
    for chapter in pack["chapters"]:
        if chapter["number"] in rewritten:
            for section in chapter["sections"]:
                for cid in section.get("teaches", []):
                    taught_by.setdefault(cid, chapter["number"])
    out = []
    for chapter in sorted((ch for ch in pack["chapters"] if ch["number"] in rewritten), key=lambda ch: ch["number"]):
        earlier = set()
        taught_here = set()
        for section in chapter["sections"]:
            steps = section.get("steps", [])
            kinds = [step["kind"] for step in steps]
            if kinds != STEP_KINDS:
                out.append(f"6 order: {section['id']} steps are {kinds}, not the nine kinds in order")
            name_step = next((step for step in steps if step["kind"] == "name"), None)
            named = linker.concepts_in(name_step["text"]) if name_step else set()
            out += [f"6 order: {section['id']} teaches {cid} but its name step does not name it"
                    for cid in section.get("teaches", []) if cid not in named]
            for step in steps:
                if step is name_step:
                    out += [f"6 order: {cid} is used in an earlier step than {section['id']}'s name step"
                            for cid in section.get("teaches", []) if cid in earlier]
                    taught_here |= set(section.get("teaches", []))
                earlier |= linker.concepts_in(step["text"])
        used = set()
        for _, text in chapter_strings(pack, chapter["number"], legend=False):
            used |= linker.concepts_in(text)
        for cid in sorted(used - taught_here):
            if cid in cards and cards[cid]["standsOn"] and not (taught_by.get(cid, chapter["number"]) < chapter["number"]):
                out.append(f"6 order: {chapter['id']} uses {cid}, which stands on other cards and no earlier chapter teaches")
    return out


def check_skill_cards(pack, rewritten):
    out = []
    for chapter in pack["chapters"]:
        if chapter["number"] not in rewritten:
            continue
        skill = chapter.get("skillCard")
        if not skill:
            out.append(f"7 skill card: {chapter['id']} has no skill card")
            continue
        she_can = skill.get("sheCan") or {}
        filled = {
            "skill": skill.get("skill"), "sheCan.prompt": she_can.get("prompt"), "sheCan.answer": she_can.get("answer"),
            "whyItMatters": skill.get("whyItMatters"), "standsOn": skill.get("standsOn"), "unlocks": skill.get("unlocks"),
        }
        out += [f"7 skill card: {chapter['id']} skill card has no {field}" for field, value in filled.items() if not value]
        beyond = chapter.get("beyondSchoolBook")
        if not isinstance(beyond, bool):
            out.append(f"7 skill card: {chapter['id']} has no beyondSchoolBook true or false")
        elif beyond and not skill.get("standsOn"):
            out.append(f"7 skill card: {chapter['id']} goes beyond the school book, so its skill card must name what it stands on")
    return out


def check_figures(pack, rewritten):
    out = []
    for chapter in pack["chapters"]:
        if chapter["number"] not in rewritten:
            continue
        for section in chapter["sections"]:
            says = any(FIGURE_PHRASE in fold(step["text"]) for step in section.get("steps", []))
            flagged = section.get("figure") is True
            if says and not flagged:
                out.append(f"9 figure: {section['id']} says \"In the figure\" but has no \"figure\": true")
            elif flagged and not says:
                out.append(f"9 figure: {section['id']} has \"figure\": true but no step says \"In the figure\"")
    return out


def problems(pack, rewritten, authored=None):
    """Every failure. `authored` is {"topics": codes, "questions": ids} of school text a chapter file writes;
    checks 3 and 4 read it too. Leaving it out means none."""
    strings = rewritten_strings(pack, rewritten, authored)
    return (check_terms_are_cards(pack, rewritten) + check_cards(pack) + check_banned_words(strings)
            + check_sentence_length(strings) + check_shared_sentences(pack, rewritten)
            + check_order(pack, rewritten) + check_skill_cards(pack, rewritten) + check_ambiguous_aliases(pack)
            + check_figures(pack, rewritten))


def require_clean(pack, rewritten, authored=None):
    found = problems(pack, rewritten, authored)
    if found:
        raise SystemExit("Content checks failed; nothing was written:\n" + "\n".join(f"  {line}" for line in found))


# ---------------------------------------------------------------------------
# Whole-pack report: checks 3 and 4 over every chapter and card, counted, never stopping
# ---------------------------------------------------------------------------

def report(pack):
    """{"chNN": {"banned", "long"}, "cards": {...}, "total": {...}}: check 3 and 4 failures over the whole pack."""
    def counts(strings):
        return {"banned": len(check_banned_words(strings)), "long": len(check_sentence_length(strings))}

    found = {chapter["id"]: counts(chapter_strings(pack, chapter["number"])) for chapter in pack["chapters"]}
    found["cards"] = counts([item for card in pack["concepts"] for item in card_strings(card)])
    found["total"] = {kind: sum(row[kind] for row in found.values()) for kind in ("banned", "long")}
    return found


def report_lines(pack):
    rows = report(pack)
    lines = [f"{'':8}{'banned':>8}{'long':>8}"]
    lines += [f"{name:8}{row['banned']:>8}{row['long']:>8}" for name, row in rows.items() if name != "total"]
    lines.append(f"{'Total':8}{rows['total']['banned']:>8}{rows['total']['long']:>8}")
    return lines


def main(argv):
    if argv != ["--report"]:
        print("Usage: python3 content_checks.py --report")
        return 2
    import json

    import export_kymmaths_pack as exporter
    pack = json.loads(exporter.PACK_OUT.read_text(encoding="utf-8"))
    print("Checks 3 (banned words) and 4 (sentences over 25 words), every chapter and card:")
    print("\n".join(report_lines(pack)))
    return 0


if __name__ == "__main__":
    import sys
    sys.exit(main(sys.argv[1:]))
