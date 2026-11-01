# KymMaths Curriculum & Visual-Symbolic Bridge Skill

## Core Architecture
- `source/export_kymmaths_pack.py` generates both:
  1. `KymMaths/KymMaths/Resources/ContentPacks/kymmaths-seed-pack.json` (loaded by `SeedPackLoader.shared` and indexed into `kb.sqlite` by `DatabaseManager`).
  2. `KymMaths/KymMaths/Resources/PatternedWorldBook/index.html` (offline interactive reader with embedded `@saxster/atlas` 3D/2D figures, interactive Singapore Bar-Model & Intuition-to-Formula widgets, and bidirectional `kymmathsBridge` WKScriptMessageHandler).
- Vendored `@saxster/atlas` figures from `../visualisations/atlas` live in `KymMaths/KymMaths/Resources/PatternedWorldBook/atlas/`.
