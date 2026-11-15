# Brief for a room agent

You are redrawing one group of KymMaths screens to match the Figma redesign. KymMaths is a
SwiftUI maths textbook for one child (Kym), on iPad and macOS. Your prompt names your group,
your worktree, your simulator and your files. Everything below applies to every group.

## Read first

1. `docs/redesign/PLAN.md` (the eight rules) and `docs/redesign/DECISIONS.md`.
2. Your Figma targets in `docs/redesign/figma/` (PNG per screen) and `figma/00-components.png`.
   Your current screens are in `docs/redesign/before/` (dark, old Vivid theme).
3. The component kit in `KymMaths/KymMaths/Design/Patterned/`: `PatternedComponents.swift`,
   `PatternedType.swift`, `PatternedPalette.swift`, `ByrneText.swift`. `PatternedGallery.swift`
   shows each one in use. The kit's own pieces (`EditorialHeader`, `BrassButtonStyle`,
   `.standardType(...)`, `@Environment(\.standardTheme)`, `StandardSpacing`, `StandardRadius`)
   come from teaching_kit through `App/KymDesignExport.swift`.
4. Your own files, in full, before you change them.

## What to do

Redraw your screens so they read like the Figma ones, using the Patterned pieces and the
theme. Concretely:

- Colours come from `theme` (`bg`, `surface`, `ink`, `brass`, `mute(theme.ink)`, `hairline()`)
  and `theme.patterned` (Byrne roles, proven, assisted, locked, margin). Replace `Color.kymaia*`
  and hard-coded colours in your files. Byrne red, yellow and blue are for maths only.
- Type comes from `.patternedType(...)` for reading text and `.standardType(...)` for UI. Replace
  `Typography.*` and `.font(.system(...))` in your files, except monospaced input fields where
  digits must line up.
- Cards are `.paperCard()`; section labels are `Kicker`; a room opens with an `EditorialHeader`
  or the Figma room header and, where the Figma screen has one, a `WonderQuestion`.
- Status is `StatusTag` and `SkillLamps`. No streaks, XP, points, percentages of mastery.
- One filled button per screen (`InkButtonStyle` or `BrassButtonStyle`). The rest are
  `OutlineButtonStyle` or `TextLinkButtonStyle`.
- Copy is plain, warm English for a twelve-year-old. Engine words (FSRS, BKT, CPA, Wolfram,
  Gemini, OpenAI, SHA, KORA, Constitution, Council, Brilliant, Mastery, Streak, XP) leave every
  user-visible string outside Settings. `scripts/check-design.sh` enforces this.
- Keep every behaviour. Do not remove a feature, an action, a binding or a data path. Restyle
  and re-word; reorder sections when the Figma screen does. If a feature has no place in the
  Figma screen, keep it lower on the page or behind a disclosure, and say so in your report.
- Do not invent learning data (history notes, chains, lamps). Use the nearest real field from
  the store or seed pack. Name each gap in your report.
- Regular width shows the margin beside the reading text (`ReadingSpread`). Check that compact
  width still works by reading your layout code; screenshots are iPad only.
- Keep accessibility: 44 pt targets, labels on icon buttons, Dynamic Type through the type
  modifiers.

## Boundaries

- Edit only your files, plus new files you create inside your feature folder. A new shared piece
  you need goes in a new file in your folder and is named in your report so it can be promoted.
- Frozen: `KymMaths/KymMaths/Design/**`, `KymMaths/KymMaths/App/**`, `KymMaths/project.yml`,
  `KymMaths/scripts/screens.sh`, `KymMaths/scripts/check-design.sh`, and other groups' files.
  `KymMaths/KymMaths/Core/**` allows additive changes only (a new computed property or
  method); list each one in your report.
- You may add `KymMaths/scripts/screens.d/<your-group>.sh` with extra `shot` lines for your
  sheets. `shot <link> <seconds> <name> [launch args]`. A deep link's unused path parts reach
  your room as `store.deepLinkTail` (for example `school/1/scanner` gives `["scanner"]`), so read
  it in your view (in `.onAppear` or `.task`) to open a sheet or mode for a screenshot.
- Never touch `../teaching_kit`. Never run `git add`, `commit`, `stash`, `checkout`, `reset` or
  `clean`. Your worktree's index is the baseline; your work is the unstaged diff.
- If you add a Swift file, run `/opt/homebrew/bin/xcodegen generate` in `KymMaths/` before the iPad
  build. The project file change is expected and is regenerated on merge.

## Checks (run from `KymMaths/` in your worktree)

1. `swift build 2>&1 | tail -n 5` passes.
2. `scripts/check-design.sh <each of your files>` passes.
3. `swift test 2>&1 | tail -n 5` passes (150 or so tests, about a minute).
4. Screens, light then dark, on your own simulator:
   `KYM_SIM=<udid> KYM_ONLY="<your links>" scripts/screens.sh ../docs/redesign/rooms/<group>`
   `KYM_APPEARANCE=dark KYM_SIM=<udid> KYM_ONLY="<your links>" scripts/screens.sh ../docs/redesign/rooms/<group>/dark`
   Look at each PNG beside its Figma target. Fix what differs, then shoot again. Two or three
   rounds is normal. Before you finish, shut your simulator down with `xcrun simctl shutdown <udid>`.

## Report (under 350 words, plain sentences)

1. Files changed and created.
2. Additive `Core/` changes, and shared pieces worth promoting.
3. Data gaps where the Figma screen wanted text the data lacks.
4. Features kept but moved or folded away.
5. The checks you ran and their last result, with the screenshot paths.
6. Remaining differences from Figma, each with a reason.
