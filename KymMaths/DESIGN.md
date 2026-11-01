# KymMaths Design System & Architecture Charter

## 1. Visual Direction: Apple Journal for iPad + *The Patterned World*
`KymMaths` uses the Apple Journal for iPad design kit (`Design/Journal/`) ported from `KymaiaTutor`:
- **Default Theme (`.journal`):** Soft lavender page (`#F3F1F7` light / `#0E0E12` dark) with lifted pure-white cards (`#FFFFFF` light / `#1C1B22` dark) and iris violet (`#5856D6` / `#7D7AFF`).
- **Signature Mathematics Theme (`.euclid` — *Patterned World*):** Warm drafting rag paper (`#F7F3E8` light / `#0D141C` dark), deep slate ink (`#1B2A38` / `#EDF3F8`), Byrne's *Euclid* Prussian blue (`#1E567C` / `#64B0E2`), and geometric vermilion (`#8A3B28` / `#E0866E`).
- **Mumbai Coastal Theme (`.monsoon` — *Marine Drive*):** Coastal mist (`#F1F5F7` light / `#0C1418` dark), Arabian Sea teal (`#125E7A` / `#57B8D9`), and lantern gold (`#7A4A10` / `#E8B268`).
- **Plus 6 Scholarly Themes:** `Living World`, `Sketchbook`, `Terracotta`, `Scholar`, `Grove`, and `Dusk` — all audited for WCAG AAA (`>= 7.0:1`) body ink and WCAG AA (`>= 4.5:1`) secondary/accent contrast, with full customisation in Settings.

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
