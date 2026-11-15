# Redesign decisions

One entry per call that someone could reasonably have made the other way. Newest last.

## 1. teaching_kit stays as it is

Six apps and two golden-image suites read the kit's tokens. Changing its Paper or Dusk values to
the Figma ones would move all of them for a difference of a few RGB steps. Chrome (paper, ink,
brass, hairlines) uses the kit. Everything the Figma file adds (Byrne red, yellow and blue, their
washes, Proven, With help, Locked, the margin and sunk tones) is an app token in
`KymMaths/Design/Patterned/PatternedPalette.swift`.

## 2. Follow System is the default theme

The book is paper by day and dusk at night, as the Figma Paper and Night screens show. The old
default was Vivid, so a stored Vivid moves once to Follow System
(`AppTheme.adoptPatternedDefault`, flag `kymmaths.theme.patternedDefaultApplied`). Any other
stored choice is the reader's own and is kept. Vivid stays available in Settings.

## 3. System typefaces only

Newsreader, Inter, STIX and Caveat would need bundling and licence notes in an app that ships
offline. New York stands in for Newsreader, SF for Inter, New York italic for STIX, and Bradley
Hand for Caveat. `PatternedType` keeps the Figma sizes and line heights, scaled by Dynamic Type.

## 4. Rooms are renamed and the toolbar goes

Today, School book, The Patterned World, Atlas, Pólya & Speed, Journal, Coach, Euclid's Workshop.
Deadlines and Settings sit at the foot of the sidebar instead of the toolbar, and the toolbar theme
menu is gone (the theme lives in Settings). The sidebar stays open on iPad.

## 5. No invented learning data

Wonder questions, chains and margin notes come from what the seed pack has: hook summaries,
callouts, chapter order and key terms. Where the design wants text the data lacks, a room uses the
nearest real field and names the gap in its report. Fake history notes or made-up lamps would
teach the wrong thing.

## 6. Byrne colours replace the old figure colours everywhere at once

`MathsFigureColor` red, blue and amber now hold the Byrne values, so every existing figure
recolours without touching its code. Byrne yellow is light, so a thin yellow line needs an ink
edge to read on paper.

## 7. The proof studio hangs off the root

Today and School book both set `activePracticeQuestion`, but the sheet was attached inside School
book, so Today's proof buttons did nothing. The sheet now sits on the root view, and
`kymmaths://proof/<unit>` opens it for screenshots.

## 8. Deep links carry a tail for each room

`AppStore.deepLinkTail` holds the path parts a link did not use (`school/3/scanner` leaves
`["scanner"]`). A room reads it to open its own sheet or mode, so screenshot scripts reach every
sheet without each room editing the shared link parser. Extra shots live in
`KymMaths/scripts/screens.d/<room>.sh`.

## 9. Rooms are redrawn in parallel, without commits

Six agents each take a group of rooms in a detached worktree with its own simulator and build
folder. Shared files are frozen while they work. Each returns a patch that is applied in the main
checkout, so nothing is committed until the user says so.

## 10. The shared cards get their own agent

`IntuitionFormulaBridgeCard`, `CPAManipulativeSandboxCard`, `BuggyRuleTrapBanner` and
`MathematicalDebateCardView` in `Design/JournalBridges.swift` draw inside Today, School book and
The Patterned World. A seventh agent restyles them, so no room agent touches a shared file.

## 11. Pieces two rooms built are promoted after the merge

Rooms built privately during Phase 2, so three of them shipped their own width reader, text
field and chip. After the patches landed, each piece that two or more rooms needed moved to
`Design/Patterned/` and the copies were deleted in the same change: `PatternedChip` (replaces
`ChoicePill`, `PaperChoiceChip` and `MathsFilterChip`), `.paperField(dashed:emphasis:)`,
`TrailingIconLabelStyle`, and `.readWidth(_:)` / `.readHeight(_:)`. Pieces only one room uses
(`EuclidPatterned`, `RoomHeaderRow`, `SheetCloseButton`) stay in that room until a second room
needs them.

## 12. Drift is fixed with tokens, not lint exceptions

The merge brought 25 standard-drift hits (literal radii, `.font(.system(size:))`, named colours).
Each was replaced with a kit token or a Patterned role. Canvas text, which cannot take a view
modifier, uses the `Font` constants `StandardType.uiCaption` and `PatternedType.X.font(size:)`.

## 13. Green stays in figures as the proven tone

Byrne drew in red, yellow, blue and black. KymMaths figures have a fourth role, green, for a
checked result (an invariant that held) and, in the Euclid proofs, for a second construction
circle or square that must be told apart from the blue one. It uses the same colour as the
Proven tag, so it means "settled" everywhere. Recolouring it to ink would need the proof text
("the green square") rewritten, which is content, not design. Chrome never uses it, apart from
the Proven tag itself.

## 14. Reader copy is fixed in the seed pack, not at display time

The seed pack named the figure library (`@saxster/atlas`) and labelled sections with method
words ("Symbolic Lockstep", "Concrete → Pictorial"). One rewrite fixed over 300 strings in the seed
pack and the web book, chapter subtitles say "School book Ch N" instead of "OUP Ch N", and the
Atlas room's display-time cleaner was deleted. `check-design.sh` now fails if these come back.
Page citations ("OUP Ch 5.1 p. 66") stay: they point to the real textbook page.
