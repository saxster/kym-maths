# Independent review, 2026-11-15

An Opus reviewer with no prior context compared `after/` and `after/dark/` with `figma/`.
Its verdict: chrome, type and the one-filled-button rule match Figma; it found engine words,
green in figures, statement openers, incomplete margins and chains, and dark-mode figures left
cream.

## Fixed after the review

- Engine and library words in reader copy (`@saxster/atlas`, CPA section headings, "OUP Ch"
  subtitles, the coach's "Concrete → Pictorial" line). Fixed in the seed data (decision 14), with
  a one-line fix-up for the starter journal note in books seeded before.
- School book chapter card had no Stands on / Unlocks. It now shows the chapter before and the
  Patterned World chapters it goes deeper into.
- Chapter figure was fixed at 600pt, cutting off its own buttons. It now grows to the page's
  height. The HCF and LCM boxes fit the figure's width.
- Deadlines, Settings and the Coach's "how it works" sheets were form-sized (about 60% of the
  screen). They are page-sized now.
- Dark mode: empty tracks and fields were near-black holes on Dusk. The night sunk tone sits one
  step above the surface now.
- Settings toggles were green. They are ink, like a chosen chip.
- Journal notes on Cornell paper had the cue rule running through the text. The cue column is
  the Questions field beside it, so notes draw on lined paper and start past the margin.

A second, fresh checker confirmed each fix against the re-shot screens.

## Known gaps, with reasons

| Gap | Screens | Why it stays |
|---|---|---|
| Green used in figures | 02, 07, 09, 11, 16, 19 | Decision 13: a fourth figure role tied to proof text. |
| Some rooms open on a statement, not a question | 01, 03, 06, 07, 09 | Decision 5: the seed pack has no wonder questions; the hook statement stands in. Writing ~60 questions is content work. |
| Margin has no history note or handwritten note | 06, 07, 10 | Decision 5: no history notes exist in the data. |
| Figure plates stay cream in dark mode | 10, 11, 16–19 | Figures draw with fixed paper-tuned colours (`MathsFigureColor`). A night set for every figure is its own pass. |
| Dark surfaces are cool grey, not Figma's warm night | all dark | Decision 1: teaching_kit's Dusk is shared by six apps and is not changed. |
| Euclid I.1 shows no Stands on | 16 | I.1 is the first proposition; it stands on the postulates, which the spine does not model as nodes. |
| Sheets in Figma are taller than form sheets on iPad | 14, 15b, 20 | Fixed with page sizing; content below the fold scrolls. |
| Labels sitting on strokes, truncated lab names, caret notation (`e^(iπ)`) | 07, 09, 11 | Web-book canvas figures; each needs its own label layout pass. |
| Card inside a card | 02, 07, 09, 19 | The figure stage draws its own frame inside the page's figure card; removing it means reworking the web book's CSS for every figure. |
| Empty box under "Reset the view" | 07 | The figure now shows its full height, including the 3D stage, which was blank when the simulator shot was taken. Unverified on a device. |
| Polish items (practice dots on the timeline, letters on AB, ∠ glyph size, PAPER label alignment) | 04, 05, 13, 14, 17, 19 | Visible but break no rule; left for a polish pass. |
