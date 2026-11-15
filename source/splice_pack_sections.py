#!/usr/bin/env python3
"""
Rewrites only the parts of the seed pack the exporter now owns, and leaves the rest as it is:
the `misconceptions`, `footings`, `concepts` and `conceptStopPhrases` sections, the `stuck` sheet of
each school question, and each chapter rewritten in source/book/ with its widgets, Atlas lessons and tip.
A chapter file's `schoolQuestions` (worked example, faded prompt) and `schoolTopics` (a topic's summary)
are taken too; a topic's other fields stay as the pack has them.

The checked-in pack has hand edits the full exporter does not reproduce, so a full export would
overwrite them. This runs the exporter's builders and the content checks, then splices those parts into
the existing JSON. A rewritten chapter's widget, Atlas lesson and tip take only the fields the book
file writes; their other fields stay as the pack has them. Where a field the splice keeps differs from
the exporter's, it is reported, not overwritten. The same chapters are written into the figure page's
`const CHAPTERS` line, which holds a copy of the pack's chapters.
"""

import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import content_checks  # noqa: E402
import export_kymmaths_pack as exporter  # noqa: E402

# Atlas lesson stories are the chapter's hook, which the book file writes.
DERIVED_LESSON_FIELDS = {"stories"}
NEW_LINK_CONTEXT = 40


def new_link_lines(old_entries, new_entries):
    """One line per link in the new golden entries that the old ones did not have: concept, matched text, context.

    A link is the same link when its text, concept and offset are the same. Context is up to 40 characters
    either side, with the match in brackets, so a writer can see a link that lands on an everyday word.
    """
    def keys(entries):
        return {(entry["text"], link["concept"], link["offset"]) for entry in entries for link in entry["links"]}

    old = keys(old_entries)
    lines = []
    for entry in new_entries:
        text = entry["text"]
        for link in entry["links"]:
            if (text, link["concept"], link["offset"]) in old:
                continue
            start, end = link["offset"], link["offset"] + len(link["text"])
            before = text[max(0, start - NEW_LINK_CONTEXT):start]
            after = text[end:end + NEW_LINK_CONTEXT]
            context = (("…" if start > NEW_LINK_CONTEXT else "") + before + f"[{link['text']}]" + after
                       + ("…" if end + NEW_LINK_CONTEXT < len(text) else ""))
            lines.append(f"{link['concept']} \"{link['text']}\": {context}")
    return lines


def splice_stuck(pack_questions, built_questions, authored=None):
    """Takes each question's stuck sheet, and its `authored[id]` fields, from the build; reports where the rest differ."""
    authored = authored or {}
    built = {question["id"]: question for question in built_questions}
    drift = []
    for question in pack_questions:
        source = built.get(question["id"])
        if source is None:
            drift.append(f"{question['id']}: not built by the exporter")
            continue
        taken = set(authored.get(question["id"], ()))
        for field in sorted(taken):
            question[field] = source[field]
        fields = sorted(field for field in (set(question) | set(source)) - {"stuck"} - taken
                        if question.get(field) != source.get(field))
        if fields:
            drift.append(f"{question['id']}: {', '.join(fields)}")
        question.pop("stuck", None)
        if "stuck" in source:
            question["stuck"] = source["stuck"]
    return drift


def splice_topic_summaries(pack_textbook, built_textbook, codes):
    """Takes only `summary` from the build for each topic code in `codes`. The pack's other topic fields hold hand edits."""
    built = {topic["code"]: topic for unit in built_textbook["units"] for topic in unit["topics"]}
    for unit in pack_textbook["units"]:
        for topic in unit["topics"]:
            if topic["code"] in codes:
                topic["summary"] = built[topic["code"]]["summary"]


def splice_records(pack_records, built_records, authored):
    """Takes each record's `authored[id]` fields from the build; keeps the rest and reports where they differ."""
    built = {record["id"]: record for record in built_records}
    drift = []
    for record in pack_records:
        fields = authored.get(record["id"])
        if fields is None:
            continue
        source = built[record["id"]]
        for field in fields:
            record[field] = source[field]
        kept = sorted(field for field in (set(record) | set(source)) - set(fields) if record.get(field) != source.get(field))
        if kept:
            drift.append(f"{record['id']}: {', '.join(kept)}")
    return drift


def splice_figure_chapters(chapters):
    page = exporter.BOOK_OUT.read_text(encoding="utf-8")
    line = f"const CHAPTERS = {json.dumps(chapters, ensure_ascii=False)};"
    spliced, count = re.subn(r"^const CHAPTERS = .*;$", lambda _: line, page, count=1, flags=re.M)
    if count != 1:
        raise SystemExit(f"No `const CHAPTERS = …;` line in {exporter.BOOK_OUT}")
    exporter.BOOK_OUT.write_text(spliced, encoding="utf-8")


def main():
    rewritten = exporter.rewritten_chapters()
    chapters = exporter.build_chapters()
    questions = exporter.build_school_questions()

    pack = json.loads(exporter.PACK_OUT.read_text(encoding="utf-8"))
    built_chapters = {chapter["number"]: chapter for chapter in chapters}
    pack["chapters"] = [built_chapters[ch["number"]] if ch["number"] in rewritten else ch for ch in pack["chapters"]]
    pack["misconceptions"] = exporter.build_misconceptions()
    pack["footings"] = exporter.build_footings()
    pack["concepts"] = exporter.build_concepts(chapters)
    pack["conceptStopPhrases"] = exporter.build_concept_stop_phrases()
    school_questions = exporter.book_school_questions()
    school_topics = exporter.book_school_topics()
    drift = splice_stuck(pack["schoolQuestions"], questions,
                         {qid: set(fields) for qid, fields in school_questions.items()})
    splice_topic_summaries(pack["schoolTextbook"], exporter.build_school_textbook(), set(school_topics))

    widget_text = exporter.book_widget_text()
    drift += splice_records(pack["widgets"], exporter.build_widgets(chapters),
                            {wid: set(text) for wid, text in widget_text.items()})
    lessons = exporter.book_atlas_lessons()
    drift += splice_records(pack["atlasLessons"], exporter.build_atlas_lessons(chapters),
                            {lid: set(lesson) | DERIVED_LESSON_FIELDS for lid, lesson in lessons.items()})
    tips = exporter.book_tips()
    drift += splice_records(pack["visualMathTips"], exporter.build_visual_math_tips(),
                            {tid: set(tip) for tid, tip in tips.items()})

    content_checks.require_clean(pack, rewritten, exporter.book_school_authored())
    old_golden = json.loads(exporter.GOLDEN_OUT.read_text(encoding="utf-8")) if exporter.GOLDEN_OUT.exists() else []
    new_links = new_link_lines(old_golden, exporter.write_golden(pack))
    exporter.PACK_OUT.write_text(json.dumps(pack, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    splice_figure_chapters(pack["chapters"])

    probes = sum(len(f["probes"]) for f in pack["footings"])
    sheets = sum("stuck" in q for q in pack["schoolQuestions"])
    print(f"Spliced {len(pack['misconceptions'])} misconceptions, {len(pack['footings'])} footings ({probes} probes), "
          f"{sheets} stuck sheets, {len(pack['concepts'])} concept cards, chapters {sorted(rewritten)} with "
          f"{len(widget_text)} widgets, {len(lessons)} Atlas lessons and {len(tips)} visual tip(s), "
          f"school text for {len(school_questions)} questions and {len(school_topics)} topics. Content checks passed.")
    for line in drift:
        print(f"Left as it is in the pack, differs from the exporter: {line}")
    print(f"New links since the last splice: {len(new_links)}. Read each one for a link on an everyday word.")
    for line in new_links:
        print(f"  {line}")


if __name__ == "__main__":
    main()
