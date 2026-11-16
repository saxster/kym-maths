# KymMaths Design System & Architecture Charter

## 1. Visual Direction: Byrne meets Tufte

KymMaths reads like a printed maths book: a question first, the maths drawn in three colours that mean the same thing in the words and in the figure, and a margin for history and the learner's own hand. The target is the Figma file `qR5ULxwcOZruADJRXTtdTk`; its 20 screens are exported in [`../docs/redesign/figma/`](../docs/redesign/figma/), the shipped app in [`../docs/redesign/after/`](../docs/redesign/after/) (light) and `after/dark/`. Why each choice was made is in [`../docs/redesign/DECISIONS.md`](../docs/redesign/DECISIONS.md).

### Two layers
- **Chrome, Book Engine & Live Voice come from `TeachingKit`** (`KymDesign`, `KymLearning`, `KymTutorAI`, `KymBookKit`, `KymLiveVoice`): `@Environment(\.standardTheme)` gives `bg`, `surface`, `ink`, `brass`, `mute()`, `hairline()`; spacing is `StandardSpacing`, radii `StandardRadius`, interface text `.standardType(.ui*)`. Values live in [`teaching_kit/docs/STANDARD.md`](../../teaching_kit/docs/STANDARD.md) and [`teaching_kit/docs/BOOK-DESIGN.md`](../../teaching_kit/docs/BOOK-DESIGN.md); do not restate them here.
- **Curious Atelier Identity, *Ligne-Claire* Bookends, *Dummies* × *Head First* Cues & Learning Toolkit come from `KymBookKit` & `KymLiveVoice`:**
  - **Cover & Family AppIcon:** `BookKitCoverBanner` + `BookKitBookIdentity` (`VOL. I · MATHEMATICS`, Oxford Prussian Navy `#182B49`, Euclid I.1 circles + golden equilateral triangle + swallowtail ribbon + stepped fore-edge).
  - **Offline `kymbook://` `@saxster/atlas` Stage & 5-Medium Switcher:** `PatternedWorldBookSchemeHandler` serves `PatternedWorldBook` and ES-module 3D figures over `kymbook://book/...` with live 5-medium switching (`Sketchbook · Textbook · Ligne-claire · Risograph · Mechanism`, defaulting to `paper-ink`) and a drafting-paper dot-grid backdrop.
  - ***Ligne-Claire* Sequential Bookends & *Dummies* × *Head First* Visual Kit:** `BookKitComicStripView` (`BookKitComicPanelArtCanvas` + `BookKitSpeechBalloonTail` + 6-character `BookKitComicWorldBible` repertory cast) for the 4-panel Book Prologue, 2-panel Asymmetric Chapter Opener, and 3-panel Chapter Closer in both step-by-step and full-scroll modes; `BookKitSignpostMedallion` (`.remember`, `.warning`, `.tip`, `.technicalStuff`), `BookKitFiresideDialogueCard`, `BookKitCheatSheetCard` (60-second consolidation), and `BookKitSymbolicAccessoryBar`.
  - **Collapsible Spine, British (`en-GB`) Voice Coach & Integrated Study Toolkit:** Persistent `.detailOnly` spine toggle (`⌘\`), ambient British Desk Tutor bar + `KymLiveBritishVoiceCatalog` (`en-GB` presets George, Charlotte, Alice, Arthur) + `KymLiveFamilyKeychain`, and the 3-view Journal (`Calendar · By chapter · All pages`) with 14-day heat-dot activity strip, timestamped `BookKitVoiceBookmarkParser` voice notes (`1× / 1.5× / 2×`), anti-verbatim `BookKitParaphraseValidator` rule card distillation, 4 `BookKitJournalExemplarCatalog` starter pages, and `BookKitRootGlossaryCatalog`.
- **The book comes from `KymMaths/Design/Patterned/`**: Byrne colours (`ByrneRole` from `KymBookKit`), reading type and the page components below. Fixed figure sizes and colours stay in `MathsFigureType`, `MathsFigureRadius` and `MathsFigureColor` (`Design/SemanticStyles.swift`), whose red, blue and amber are the Byrne values.

### Themes
Follow System is the default: the kit's Paper by day, Dusk at night. `AppTheme.adoptPatternedDefault` moves a learner with no choice, or on Vivid (the old default), there once; any other choice is kept. The picker is `StandardThemeGallery` in Settings; there is no toolbar menu.

### Colour
- **Byrne roles are for maths only.** `ByrneRole.moves` (red, the thing that changes), `.stays` (yellow, the thing that stays the same), `.given` (blue, the starting thing). Read them as `theme.patterned.color(role)` and `.wash(role)`; `theme.patterned` is `.paper` or `.night`. In prose use `ByrneText` markup, `{red:the radius}`, so the word and the figure share a colour.
- **Chrome is ink, paper and brass.** State tones (`proven`, `assisted`, `locked`) and the `margin` and `sunk` fills are also on `theme.patterned`. No other colour appears on a screen.

### Type
`.patternedType(_:)` for reading text, on system faces so nothing is bundled: New York for reading, New York italic for questions and inline maths, Bradley Hand for handwriting, SF for kickers and numerals. Roles: `chapterDisplay` 60, `question` 22, `reading` 19, `readingDefault` 16, `readingSmall` 14, `sidenote` 13, `hand` 21, `mathDisplay` 30, `mathInline` 19, `kicker` 11, `numeral` 28. Each scales with Dynamic Type from the text style it is relative to. Interface labels use the kit's `.standardType(.uiBody)` and friends. Where a `Font` value is needed (Canvas text), use `PatternedType.X.font(size:)` or `StandardType.uiCaption`.

### Rules every screen follows
1. **Wonder first.** A room or chapter opens with `WonderQuestion`, after a `Kicker`.
2. **Byrne colours for maths only** (above).
3. **A margin.** `ReadingSpread` puts `MarginNote` and `HandNote` beside reading text at regular width and below it at compact width.
4. **Stands on / Unlocks.** `ChainCard` on every chapter, topic and proposition.
5. **Honest lamps.** `SkillLamps` (With the picture, In letters, In your head, Knows when) and `StatusTag` over `LearningStatus` (Locked, Not started, Working on it, With help, Proven, Secure). `ProgressRule` for how far through. No streaks, XP, mastery percentages or engine names.
6. **One filled button per screen.** `InkButtonStyle`, or the kit's `BrassButtonStyle` where brass is the action. Everything else is `OutlineButtonStyle` or `TextLinkButtonStyle` ("Read the chapter →").
7. **Engine words live with the grown-up.** FSRS, BKT, CPA, Wolfram, Gemini and the like appear only in Settings under "For the grown-up".
8. **Quiet paper, loud proof.** `.paperCard()` and hairlines everywhere; colour and weight only where a proof or figure is.

### Shared pieces
- Page: `Kicker`, `.paperCard()`, `WonderQuestion`, `HandNote`, `MarginNote`, `ReadingSpread`, `ChainCard`, `PathStepRow`, `LockedNote`.
- Controls: `PatternedChip` (a choice among a few; never the filled button), `.paperField(dashed:emphasis:)` for text entry, `TrailingIconLabelStyle` for "Next →" labels.
- Layout: `.readWidth(_:)` and `.readHeight(_:)` bind a view's size for width-driven layouts.
- Room headers still use the kit's `EditorialHeader` where a room has no wonder question of its own.
- `PatternedGallery` (DEBUG, `-KymDeepLink gallery`) draws every piece in Paper and Dusk. Check a new piece there before using it in a room.

### Checks
- `scripts/check-design.sh` fails on engine words outside Settings and on more than one filled button per file (files with sheets list their count).
- `node ../../teaching_kit/scripts/check-consumers.mjs --lint` fails on token drift: literal corner radii, `.font(.system(size:))`, system text styles and named system colours in `Features/`.
- `scripts/screens.sh <dir>` (with `KYM_APPEARANCE=dark` for Dusk) shoots every room and sheet by deep link; extra shots live in `scripts/screens.d/`.

## 2. School Spine, Built-In Singapore Companion Workbook & Advanced Horizon
- Kym's school textbook is **Oxford University Press — Cambridge Lower Secondary Complete Mathematics 8 (Second Edition)** by **Deborah Barton** (`Ch 1–16` + `Reviews A, B, C`, pp. 5–260).
- Because the school provides only the Student Book without a separate Workbook, `KymMaths` builds in a **3-Tier Singapore & Checkpoint Companion Workbook** (`Foundation & Fluency` · `Singapore Bar-Model & Checkpoint Application` · `Olympiad & Horizon Stretch`) plus a **21-Template Wolfram-Verified Infinite Workbook Generator** for every chapter.
- `KymMaths` provides a **3-Lens Filter** in the OUP & Singapore Maths 8 room:
  1. **OUP Maths 8 Core (Ch 1–16)** *(Default)*: All 16 chapters (`1.1`–`16.2`) in exact printed order, preserving Kym's completed (`✓`) Chapters 3, 5, 12 and active (`○`) Chapters 1, 2, 6, 7, 9.
  2. **+ Singapore CPA & Companion Workbook**: Injects Singapore Bar-Model decompositions, Al-Khwarizmi area boxes, Pólya heuristics, and the 3-tier Companion Workbook.
  3. **Full Horizon (Set Theory & Logic, Trig, Bayes, Calculus & Linear Algebra)**: Cross-wires every school chapter directly into the 5 Volumes and 21 Chapters of ***The Patterned World***.
- Shared App Group (`group.com.kymaia.science`) synchronises STEM progress, Question Proofs, FSRS cards, and deadlines across `KymMaths`, `KymBio`, `KymChem`, `KymPhysics`, and the standalone game companion [`../kym_mathgames`](../../kym_mathgames/README.md) (`kymmathgames://track/<track_id>`).

## 3. Pedagogical Honesty Guardrails
- **Three-Stage Readiness:** *1. Material in → 2. Checked learning → 3. Independent proof & spaced study*.
- **No False Mastery:** Viewing a Worked Example or Faded Completion marks the current attempt as `assisted`; independent proof (`proven` today, `secure` across 2+ calendar days) requires answering from a fresh attempt with zero hints.
- **No AI Rewriting of Retrieval:** Every learner answer field uses `.learnerTextInput(.retrieval)`, disabling autocorrect and Apple Intelligence Writing Tools (`.writingToolsBehavior(.disabled)`).
