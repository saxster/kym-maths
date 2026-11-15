#!/usr/bin/env python3
"""
Rewrites only the `misconceptions` and `footings` sections of the seed pack, and the
`stuck` sheet of each school question.

The checked-in pack has hand edits the full exporter does not reproduce, so a full
export would overwrite them. This runs the exporter's builders and checks, then
splices those parts into the existing JSON and leaves the rest as it is. Where a
school question in the pack differs from the exporter's, it is reported, not overwritten.
"""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import export_kymmaths_pack as exporter  # noqa: E402


def splice_stuck(pack_questions, built_questions):
    built = {question["id"]: question for question in built_questions}
    drift = []
    for question in pack_questions:
        source = built.get(question["id"])
        if source is None:
            drift.append(f"{question['id']}: not built by the exporter")
            continue
        fields = sorted(field for field in (set(question) | set(source)) - {"stuck"}
                        if question.get(field) != source.get(field))
        if fields:
            drift.append(f"{question['id']}: {', '.join(fields)}")
        question.pop("stuck", None)
        if "stuck" in source:
            question["stuck"] = source["stuck"]
    return drift


def main():
    questions = exporter.build_school_questions()
    misconceptions = exporter.build_misconceptions()
    footings = exporter.build_footings()

    pack = json.loads(exporter.PACK_OUT.read_text(encoding="utf-8"))
    pack["misconceptions"] = misconceptions
    pack["footings"] = footings
    drift = splice_stuck(pack["schoolQuestions"], questions)
    exporter.PACK_OUT.write_text(json.dumps(pack, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    probes = sum(len(f["probes"]) for f in footings)
    sheets = sum("stuck" in q for q in pack["schoolQuestions"])
    print(f"Spliced {len(misconceptions)} misconceptions, {len(footings)} footings ({probes} probes) "
          f"and {sheets} stuck sheets.")
    for line in drift:
        print(f"Left as it is in the pack, differs from the exporter: {line}")


if __name__ == "__main__":
    main()
