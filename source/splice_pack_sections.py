#!/usr/bin/env python3
"""
Rewrites only the `misconceptions` and `footings` sections of the seed pack.

The checked-in pack has hand edits the full exporter does not reproduce, so a full
export would overwrite them. This runs the exporter's builders and checks, then
splices those two sections into the existing JSON and leaves the rest as it is.
"""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import export_kymmaths_pack as exporter  # noqa: E402


def main():
    exporter.build_school_questions()
    misconceptions = exporter.build_misconceptions()
    footings = exporter.build_footings()

    pack = json.loads(exporter.PACK_OUT.read_text(encoding="utf-8"))
    pack["misconceptions"] = misconceptions
    pack["footings"] = footings
    exporter.PACK_OUT.write_text(json.dumps(pack, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    probes = sum(len(f["probes"]) for f in footings)
    print(f"Spliced {len(misconceptions)} misconceptions and {len(footings)} footings ({probes} probes).")


if __name__ == "__main__":
    main()
