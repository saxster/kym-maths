# KymMaths Design System & Architecture Charter

## 1. Visual Direction: The Standard
`KymMaths` draws in **The Standard**, the design system it shares with the other subject apps and apple_poem. Tokens, colours, type, spacing, radii, motion and the screen components are defined once in teaching_kit; read [`teaching_kit/docs/STANDARD.md`](../../teaching_kit/docs/STANDARD.md) for the values. Do not restate them here.
- **Themes:** the six Standard themes plus Follow System, Vivid by default. The choice is stored under `curatedColorScheme`; `Design/AppTheme.swift` moves a choice from the old catalogue to its Standard theme (`euclid` → Paper, `hearth` and `scholar` → Warm, `dusk` → Dusk, every other old id → Vivid). The picker is the kit's `StandardThemeMenu` in the toolbar and `StandardThemeGallery` in Settings.
- **Tokens in screens:** `Features/` reads `Color.kymaia*`, `Font.kymaia*` or `.standardType(_:)`, and `CornerRadius.*` or `StandardRadius.*`. Fixed sizes and colours that belong to a drawn figure live in `MathsFigureType`, `MathsFigureRadius` and `MathsFigureColor` (`Design/SemanticStyles.swift`). `node teaching_kit/scripts/check-consumers.mjs --lint` fails on drift.
- **Screen patterns:** each room opens with `EditorialHeader`. Selection strips use `MathsFilterChip` (the kit's `StandardFilterChip` plus a state symbol) and one-shot actions use `PillButton`. A screen has at most one `BrassButtonStyle` action. Panels nested in a card use `.quietPanelBackground()`, the `QuietPanel` chrome. Empty states use `EmptyStateCard`. Pólya's four stages use `StageDial`.

## 2. School Spine, Built-In Singapore Companion Workbook & Advanced Horizon
- Kym's school textbook is **Oxford University Press — Cambridge Lower Secondary Complete Mathematics 8 (Second Edition)** by **Deborah Barton** (`Ch 1–16` + `Reviews A, B, C`, pp. 5–260).
- Because the school provides only the Student Book without a separate Workbook, `KymMaths` builds in a **3-Tier Singapore & Checkpoint Companion Workbook** (`Foundation & Fluency` · `Singapore Bar-Model & Checkpoint Application` · `Olympiad & Horizon Stretch`) plus a **21-Template Wolfram-Verified Infinite Workbook Generator** for every chapter.
- `KymMaths` provides a **3-Lens Filter** in the OUP & Singapore Maths 8 room:
  1. **OUP Maths 8 Core (Ch 1–16)** *(Default)*: All 16 chapters (`1.1`–`16.2`) in exact printed order, preserving Kym's completed (`✓`) Chapters 3, 5, 12 and active (`○`) Chapters 1, 2, 6, 7, 9.
  2. **+ Singapore CPA & Companion Workbook**: Injects Singapore Bar-Model decompositions, Al-Khwarizmi area boxes, Pólya heuristics, and the 3-tier Companion Workbook.
  3. **Full Horizon (Set Theory & Logic, Trig, Bayes, Calculus & Linear Algebra)**: Cross-wires every school chapter directly into the 5 Volumes and 21 Chapters of ***The Patterned World***.
- Shared App Group (`group.com.kymaia.science`) synchronises STEM progress, Question Proofs, FSRS cards, and deadlines across `KymMaths`, `KymBio`, `KymChem`, and `KymPhysics`.

## 3. Pedagogical Honesty Guardrails
- **Three-Stage Readiness:** *1. Material in → 2. Checked learning → 3. Independent proof & spaced study*.
- **No False Mastery:** Viewing a Worked Example or Faded Completion marks the current attempt as `assisted`; independent proof (`proven` today, `secure` across 2+ calendar days) requires answering from a fresh attempt with zero hints.
- **No AI Rewriting of Retrieval:** Every learner answer field uses `.learnerTextInput(.retrieval)`, disabling autocorrect and Apple Intelligence Writing Tools (`.writingToolsBehavior(.disabled)`).
