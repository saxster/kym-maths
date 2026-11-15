"""
The ids saved learner answers key on, read from a pack. `fixtures/baseline_ids.json` holds them as they
were at the baseline commit; `missing` lists any that a later pack has lost. New ids are allowed.
"""


def ids(pack):
    return {
        "chapters": [chapter["id"] for chapter in pack["chapters"]],
        "callouts": [callout["id"] for chapter in pack["chapters"] for callout in chapter["callouts"]],
        "sections": [section["id"] for chapter in pack["chapters"] for section in chapter["sections"]],
        "widgets": [widget["id"] for widget in pack["widgets"]],
        "atlasLessons": [lesson["id"] for lesson in pack["atlasLessons"]],
        "visualMathTips": [tip["id"] for tip in pack["visualMathTips"]],
        "schoolQuestions": [question["id"] for question in pack["schoolQuestions"]],
    }


def counts(pack):
    found = ids(pack)
    return {kind: len(found[kind]) for kind in ("chapters", "widgets", "atlasLessons", "visualMathTips", "schoolQuestions")}


def missing(pack, baseline):
    found = {kind: set(values) for kind, values in ids(pack).items()}
    return [f"{kind}: {value}" for kind, values in ids_only(baseline).items() for value in values
            if value not in found[kind]]


def ids_only(baseline):
    return {kind: values for kind, values in baseline.items() if isinstance(values, list)}
