# KymMaths redesign: Byrne meets Tufte, in the app

Target: the Figma file `qR5ULxwcOZruADJRXTtdTk` (20 screens). Each screen is exported to
`docs/redesign/figma/NN-name.png`, and the component sheet to `figma/00-components.png`.
The app as it was is in `docs/redesign/before/`. Branch: `byrne-redesign`.

## What the reader gets

A child opens the book and meets a question before a definition. The maths is drawn in three
colours that mean the same thing in the words and in the figure. History and their own handwriting
live in a margin. Every page says what it stands on and what it unlocks. Progress is four honest
lamps, never streaks or points. Each screen asks for one thing.

## Rules every screen follows

1. **Wonder first.** A room or chapter opens with a question in italic serif (`WonderQuestion`).
2. **Byrne colours are for maths only.** Red is the thing that moves or changes, yellow the thing
   that stays the same, blue the given or starting thing. The same colour is used in the sentence
   (`Text(byrne:)` markup) and in the figure (`ByrneRole`). Chrome is ink, paper and brass.
3. **A margin.** Sidenotes, a history note and one handwritten note (`MarginNote`) sit beside
   reading text at regular width and drop below it at compact width (`ReadingSpread`).
4. **Stands on / Unlocks** (`ChainCard`) on every chapter, topic and proposition.
5. **Honest lamps.** `SkillLamps` (With the picture, In letters, In your head, Knows when) and
   `StatusTag` (Locked, Not started, Working on it, With help, Proven, Secure). No streaks, XP,
   percentages of "mastery" or engine names.
6. **One thing per screen.** At most one filled button (`InkButtonStyle`, or the kit's
   `BrassButtonStyle` where brass is the action). Everything else is `OutlineButtonStyle` or a
   brass text link (`TextLinkButtonStyle`, "Read the chapter →").
7. **Engine words live with the grown-up.** FSRS, BKT, CPA, Wolfram, Gemini, SHA, KORA,
   Constitution and Council appear only in Settings under "For the grown-up".
   `scripts/check-design.sh` fails when they leak.
8. **Quiet paper, loud proof.** Paper and hairlines everywhere; colour and weight only where a
   proof or figure is.

## Decisions (log in `DECISIONS.md`)

- teaching_kit is not changed. Six apps and two goldens depend on its tokens. Chrome uses the
  kit's Paper and Dusk themes, which sit within a few RGB steps of the Figma paper and ink.
  Byrne, state, wash and margin tones are app tokens in `KymMaths/Design/Patterned/`.
- The default theme becomes Follow System (Paper by day, Dusk at night). A stored Vivid, the
  old default, moves once to Follow System. Any other stored choice is kept.
- Typefaces are system ones, so nothing is downloaded or bundled. New York stands in for
  Newsreader, SF for Inter, New York italic for STIX, and Bradley Hand for Caveat.
- Rooms are renamed: Today, School book, The Patterned World, Atlas, Pólya & Speed, Journal,
  Coach, Euclid's Workshop. Deadlines and Settings move to the foot of the sidebar.
- No new learning data is invented. Wonder questions, chains and margin notes come from what
  the seed pack already has (hook summaries, callouts, chapter order, key terms). Where the design
  needs text the data lacks, the room uses the nearest real field and the gap goes in the room's
  report.

## Phases

Each phase ends in a check. A phase does not start until the one before it is green.

### Phase 0. Baseline (done)

- `scripts/screens.sh <dir>` builds the iPad app, opens each room with `-KymDeepLink` and saves
  11 PNGs. Baseline in `before/`. 143 tests pass.

### Phase 1. Foundation (one agent, serial)

1. Theme default and the Vivid move, with a test.
2. `Design/Patterned/`: `ByrneRole` and `PatternedPalette` (Paper and Night values from Figma),
   `PatternedType` (the Figma text styles on system faces), and the components named above plus
   `Kicker`, `.paperCard()`, `PathStepRow`, `ProgressRule`, `LockedNote`, `HandNote`.
3. `MathsFigureColor` red, blue and amber move to the Byrne values, so every existing figure
   recolours at once.
4. The shell: sidebar with the Byrne mark, renamed rooms, an "Up next" card, Deadlines and
   Settings at the foot, the sidebar kept open on iPad.
5. `JournalSecondaryButtonStyle` becomes the outline button, so every room's secondary buttons
   change together.
6. `scripts/check-design.sh`: jargon outside Settings, and more than one filled button per file
   (files with sheets are listed with their count).
7. A gallery view (`PatternedGallery`, DEBUG only, `-KymDeepLink gallery`) that draws every
   component in Paper and Dusk, so the pieces are checked once, not in every room.

Check: `swift build`, `swift test`, consumer lint, `check-design.sh` (jargon may still fail in
rooms not yet done), iPad build, gallery screenshot in light and dark.

### Phase 2. Rooms (six agents in parallel, one per group of files)

Each agent works in its own git worktree with its own simulator and build folder, edits only its
own files, commits nothing, and returns a patch plus before/after screenshots.

| Agent | Files | Figma |
|---|---|---|
| today | TodayHomeView (with the Daily Flow sheet) | 01, 02 |
| school | SchoolMathsHomeView, QuestionProofPracticeView, MathsScratchpadView, TextbookPageScannerSheet | 03, 04, 05, 13 |
| patterned | PatternedWorldHomeView, PatternedWorldWebStageView, `PatternedWorldBook/index.html` styles | 06, 07, 08 |
| atlas-polya | LabsAtlasHomeView, PolyaFluencyHomeView | 09, 10, 11 |
| journal-coach | MathsJournalHomeView, MathsCoachView, TutorCanvasView, CalendarHomeView, MathsSettingsSheet | 12, 14, 15, 20 |
| euclid | `Features/EuclidWorkshop/*` | 16, 17, 18, 19 |

Shared files (`Design/`, `Core/`, `JournalBridges.swift`) are frozen in this phase. A room that
needs a new shared piece builds it privately in its own file and names it in its report, so it
can be promoted later. Additive changes to `Core/` (a new computed property) are allowed and must
be listed.

Check, per agent: `swift build`, the iPad build in its worktree, `check-design.sh` on its files,
and its screens beside the Figma targets.

### Phase 3. Integrate and prove

1. Apply the six patches; `xcodegen generate` rebuilds the project file.
2. Full gate: `swift build`, `swift test`, iPad build, consumer lint, `check-design.sh`.
3. `scripts/screens.sh docs/redesign/after` in light, and again in dark.
4. An independent reviewer compares `after/` with `figma/` screen by screen and returns a
   verdict and a ranked list of gaps. Gaps that break a rule above are fixed and re-shot.
5. `DESIGN.md` is rewritten to describe the new system.

## Definition of done

- Every room and sheet draws with the Patterned tokens and components and follows the eight rules.
- `check-design.sh` passes with no exceptions outside Settings.
- `swift build`, `swift test` (143 or more), the iPad build and the consumer lint pass.
- After screenshots exist in light and dark, and the reviewer's remaining gaps are listed as
  known, with a reason each.
- Nothing is committed or pushed without the user's say.
