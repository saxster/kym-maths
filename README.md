# The Patterned World & KymMaths

Mathematics from the tally bone and Singapore bar model to Set Theory & Formal Logic, Trigonometry, Bayesian Inference, Differential & Integral Calculus, and Linear Algebra. Written and built for Kym, aged 12, in Mumbai.

## Architecture

1. **`source/` & `KymMaths/KymMaths/Resources/PatternedWorldBook/` — *The Patterned World* Living Textbook & Interactive Stage:**
   - **5 Volumes, 21 Chapters (`Ch 0`–`Ch 20`)** following the Feynman & 3Blue1Brown principle: concrete puzzle and visual geometry first, misconception confrontation first, never a naked formula.
   - **4 Front-Matter Explorers** (`x_number_tower`, `x_singapore_bar_engine`, `x_euclid_compass`, `x_bayes_calculus_bridge`), **47 Interactive 2D/3D Simulations**, and **63 Spatial Atlas Lessons**.
2. **`KymMaths/` — Native iPadOS 27 & macOS Application:**
   - **The Standard design system** from teaching_kit (`docs/STANDARD.md`): six themes plus Follow System, Vivid by default, chosen from the toolbar or Settings.
   - **OUP *Cambridge Lower Secondary Complete Mathematics 8 (2nd Edition)* by Deborah Barton** (`Ch 1–16`, pp. 7–260) paired with a **Built-In 3-Tier Singapore & Checkpoint Companion Workbook** so Kym never lacks structured workbook practice.
   - **3-Database GRDB Spine (`kb.sqlite`, `state.sqlite`, `mnemosyne.sqlite`)** with FSRS v5 spaced repetition, BKT mastery tracking, and strict assisted-vs-independent `QuestionProofLevel` verification.
   - **Scratchpad:** Split-screen working canvas (finger or Pencil drawing; not PencilKit yet, and ink is not saved) with 8 mathematical stamps (Singapore Bar Model, Coordinate Axes, Unit Circle, 2-Set Venn, Prime Tree, Truth Table, 2×2 Matrix Grid, Number Line) and 16 3-tier Visual Proof & Construction Recall Plates.
   - **Pólya *How to Solve It* Studio, SpeedMath Mental Fluency, Visual MathTips, Socratic AI Coach, and 21 Symbolic/Quantitative Templates (checked by the test suite, not by Wolfram).**
3. **Sibling Game Companion (`../kym_mathgames` — *KymMathGames: The Mathemagician & Olympian's Loom*):**
   - For high-speed 120Hz mental mathemagics and Singapore Math Olympiad flow gameplay on iPad and iPhone (iOS 26.0+ / iPadOS 26.0+), `KymMaths` pairs with the standalone sibling app **[`../kym_mathgames`](../kym_mathgames/README.md)** ([`PRD.md`](../kym_mathgames/PRD.md)) via the shared App Group (`group.com.kymaia.science` & `group.com.kymaia.maths`) and `kymmathgames://track/<track_id>` deep links.
