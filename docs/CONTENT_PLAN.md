# Plan: rewrite chapters 0 and 2 to 20, and the school room, to the content brief

Mode: fallback for the prose, with executable content checks as its evidence. TDD for the code in Stage 0.
Why this mode: prose quality has no unit test, but the brief's seven checks, the answer marker and a device walk-through are all runnable; the code changes have ordinary test seams.
Revision: 1 (2026-11-15)
Status: ready. Four decisions carry a default and do not block (see Decisions).
Baseline: commit `e416fa8` on branch `content-ch1` (chapter 1, 11 concept cards, links, seven checks).

Read `docs/CONTENT_BRIEF.md` first. It is the standard. This plan is the order of work and the proof that each piece is done.

## Goal

Kym, 12, can open any of the 21 chapters and any of the 64 school questions and find the same thing she finds in chapter 1 today: an idea explained from a question in her world, in short sentences, with every technical word and symbol linked to a card that reminds her what it means and how to work it out.

Her father relies on the checks. They must fail when the standard slips, in any chapter, without anyone remembering to look.

## What exists after chapter 1 (do not rebuild)

| Piece | Where |
|---|---|
| The model chapter to copy the shape of | `source/book/ch01.py` |
| The 11 cards and the stop list | `source/book/concepts.py` |
| Registry of rewritten chapters | `BOOK_CHAPTERS` in `source/export_kymmaths_pack.py` |
| Getting content into the pack | `python3 splice_pack_sections.py` from `source/`. Never a full export. |
| The seven checks and their failing fixtures | `source/content_checks.py`, `source/test_content_checks.py` |
| Link finder, Python and Swift, pinned together | `source/concept_links.py`, `Core/Learning/ConceptLinker.swift`, `Tests/Golden/concept-links.json` |
| Linked text, the card sheet, the nine-step section view | `ConceptText.swift`, `ConceptCardSheet.swift`, `TeachingStepsView.swift` |
| Deep links for screenshots | `chapter/<n>`, `concept/<id>`, `proof/<n>` through `scripts/screens.sh` |

Measured cost of chapter 1: 2,899 words of hand-written text, 11 cards, about 35 minutes of agent time for wiring and 15 minutes for the device walk-through. The wiring is now done once, so later chapters cost the prose, the cards and the walk-through.

## Constraints

- Reuse: everything in the table above. One link rule, one card sheet, one section view.
- Allowed changes: `source/book/**`, `source/*.py`, `KymMaths/KymMaths/**`, `KymMaths/Tests/**`, `KymMaths/scripts/screens.d/**`, `docs/CONTENT_BRIEF.md`, this file.
- Do not touch: the vendored Atlas copy, `kym_mathgames`, `teaching_kit`. Do not run the full exporter over the checked-in pack.
- Ids are permanent. Every chapter keeps `chNN-c-predict`, `chNN-c-aha`, `chNN-c-trap` and section ids `chNN-s1…` in order, because saved answers key on them. Widget, Atlas lesson, tip and question ids never change.
- Pinned counts stay: 21 chapters, 47 widgets, 63 Atlas lessons, 8 tips, 64 questions.
- Answer keys change only when wrong, and the commit says so.
- No commit, push or merge without the user asking. One commit per chapter when they do.
- Prose is written by the strongest model at full effort (`judgment and prose: claude:fable@max`). Code goes to `feature: claude:opus@high`. Device walk-throughs go to a verifier subagent that returns a text verdict and file paths.

## Definitions

- **Rewritten chapter**: a chapter whose record comes from `source/book/chNN.py` and is listed in `BOOK_CHAPTERS`. The checks apply to rewritten chapters and to every card.
- **Card**: one concept, with the fields in the brief. A card with an empty `standsOn` is **bedrock**: something she already knows.
- **Taught**: a card is taught by the section whose `teaches` lists it. Its name first appears in that section's "What it's called" step.
- **Chapter slice**: one chapter taken through every step of "The chapter slice" below, ending in passing checks and a device walk-through.
- **Beyond the school book**: no school unit teaches it. Measured from the pack's unit links and subtitles, these are chapters 0, 12, 16, 17, 18 and 20. The brief used to say 13 to 20; that was wrong and is corrected.

## Decisions (each has a default; tell the session if you want the other)

| ID | Question | Default the session will use | Why |
|---|---|---|---|
| D1 | Rewrite a chapter's school questions with the chapter, or all 64 at the end? | With the chapter. Each slice also rewrites the worked examples and stuck sheets of the school unit that chapter maps to. | The cards are fresh, and the school room is what she uses for school this term. The brief's order put it last. |
| D2 | Every section shows the same "Try it" figure. Keep? | Show the figure only beside the sections that name it. A section gets an optional `figure` field. | In chapter 1 the turning arrow sits beside the square-root section. |
| D3 | The "Turn it round · the figure in 3D" box is empty in the app and its caption is a file path. | Hide the box when the 3D figure does not load, and put the caption in plain words. Loading the 3D figures offline is audit item D8 and stays out of scope. | A blank box with a path under it is the first thing she sees. |
| D4 | Is chapter 0 (sets and logic) in her printed school book? | Treat it as beyond the school book until someone checks the book. | No school unit links to it. Audit D11 needs the printed book. |

## Risks found in chapter 1 that grow with 200 cards

| ID | Risk | What Stage 0 does about it |
|---|---|---|
| R1 | Everyday words are also maths words: set, term, power, mean, range, limit, net, face, plan, event, similar, function, product, base, sample. "Set the sliders to 24" would link to the Set card. | A card for one of these never takes the bare word as a name it links on. It uses unambiguous forms ("a set", "the set of", "sets"). The splice prints every new link with 40 characters of context, and the writer reads that list. |
| R2 | One name, two ideas: term (algebra, sequence), tangent (trigonometry, line), square (number, shape), range (data, function), base (power, triangle). Check 2 already refuses a name owned by two cards. | Decide the owner before writing. The table below names each clash in the chapter where it lands. |
| R3 | "scale factor" and "power set" are stop phrases today. Chapters 11 and 0 teach them. | When the card arrives, delete the stop phrase. The longer name then wins over "factor" and "power". |
| R4 | Check 6 says a chapter may use only bedrock cards or cards taught by an earlier chapter. | Rewrite in the order below. Chapter 0 must not lean on chapter 1's non-bedrock cards. |
| R5 | All cards live in one file, so two writers cannot work at once. | Move each card into the chapter file that teaches it, with a `bedrock.py` for bedrock cards. `concepts.py` becomes the merge. |
| R6 | Arithmetic in chapter 1 was checked by a throwaway script. | Make it a test that stays (A5). |
| R7 | A chapter going from 3 sections to 5 shifts the step she had reached. Some text may be copied into the database on first launch. | In session 1, install the new build over an old one with saved progress and look (A12). |

## Stage 0: groundwork, before chapter 0 (code, TDD, one session)

Each item names its failing test first.

| ID | Change | Test that fails first |
|---|---|---|
| G1 | Cards live with their chapter (R5). No card text changes. | `test_content_checks`: the pack built from split files equals the checked-in pack. |
| G2 | The splice prints a "new links" report: concept, matched text, context, for every string in the golden file (R1). | Unit test on a fixture text with one true and one false link. |
| G3 | Check 8, ambiguous words: a listed everyday word may not be a bare card name. | Fixture card with the name "set". |
| G4 | `source/test_book_maths.py`: each chapter file exports its sums as assertions, and every "Your turn" and card check answer is recomputed (R6). | A fixture with 2 + 2 = 5. |
| G5 | "Who is right?" text moves from `MathematicalDebateCatalog` in Swift into the chapter file, so the checks read it. Chapter 1's is moved first. The layout stays. | Swift test: chapter 1's scenario text equals the pack's. Python: a banned word in a debate fails check 3. |
| G6 | The skill card shows on the chapter's first screen: what she can do after, the device-off check, what it stands on. Beyond-school chapters say so there. | Swift test on the first beat of chapter 1; a pack flag `beyondSchoolBook` decodes. |
| G7 | Figure only beside sections that name it (D2). | Swift test: chapter 1 section 1.5 has no figure, section 1.1 has. |
| G8 | Hide the empty 3D box and replace the path caption (D3). | Device shot of `chapter/1`: no "Atlas route" text (source check on `index.html` and `build_html_book`). |
| G9 | A card keeps its scroll position and typed answer when she comes back to it. | Swift test on the sheet's trail state. |
| G10 | Checks 3 and 4 gain a whole-pack report mode that lists failures without stopping, so progress is a number. | Unit test: the report counts a banned word in an unrewritten chapter and exits 0. |
| G11 | Carry-over from chapter 1: iPhone shots of one section and one card, and `xcodebuild build -scheme KymMaths` for the Mac. | The two commands succeed and a verifier reads the shots. |
| G12 | Plain labels on the wrappers Swift adds to every chapter: "Visual Intuition → Symbolic Formula", "Locking In Chapter", "PEER DEBATE · SPOT THE FLAW", `invariantTakeaway` shown as "The big idea". | Swift test: no banned word in any beat title or eyebrow for chapter 1. |

Ask the user for Kym's read-aloud notes on chapter 1 at the start of Stage 0. Every stumble becomes an edit to the brief before any new chapter is written. If she has not read it yet, carry on and apply the notes when they arrive.

## The chapter slice (repeat for each chapter)

1. **Read.** The chapter's record in the pack, its school unit's topics and four questions, its figure in `index.html` (`case N:` in `drawSandbox`, `CH_SLIDERS[N]`), and its lines in `docs/AUDIT_2026-11-15.md` (CT-5 to CT-24, around line 320).
2. **Skill card first.** Skill, device-off check with its answer, why it matters, what it stands on, what it unlocks. No skill, no chapter.
3. **Card list.** Start from the draft in the table below. For each card decide: bedrock or not, what it stands on (two taps to bedrock at most), its unambiguous names, its mix-up partner, its footing if one of the 22 fits. Settle R2 clashes now.
4. **Sections.** One idea per section, usually four to six, in teaching order. Each has the nine steps in order. Numbers before letters. The "Picture it" step points at the chapter's real figure, with the slider values that show the idea.
5. **The rest of the chapter file.** Plain title and subtitle, the opening question, the bridge text and its three coloured terms, three callouts with the old ids, key terms equal to the card names, text for each of the chapter's figures, its three Atlas lessons, its tip if it has one, and its "Who is right?" text.
6. **School unit (D1).** For the unit's four questions: a worked example where every step gives its reason, the faded prompt, and the stuck sheet wording. Also the unit's topic summaries. Answer keys stay.
7. **Figure labels.** Plain words in `index.html` and in `build_html_book` for that chapter's sliders, captions and readout. Fix the figure defects the audit lists for that chapter.
8. **Register.** Add the module to `BOOK_CHAPTERS`. Delete the chapter's tuple from `raw_specs`. Delete a sentence template when its last user is gone.
9. **Check.** Run the four commands in "Done when". Read the new-links report (G2) for false links.
10. **Look.** A verifier subagent walks the chapter on the iPad simulator: one section in each reading mode, one new card to its bottom, one "Your turn", one school question of the unit. It reports jargon, file paths, clipped text and default-blue links.
11. **Stop at the volume gate** (below). Do not commit unless asked.

## Order and the draft card list

Titles and cards are drafts for the writer to improve. School unit numbers come from the pack. "Beyond" means the first screen says it goes past her school book.

| Order | Ch | Draft plain title | School unit | Draft new cards | Watch for |
|---|---|---|---|---|---|
| 1 | 0 | Sets and logic | none (beyond, D4) | set, member, subset ⊆, union ∪, intersection ∩, complement A′, universal set, Venn diagram, power set, if-then statement ⇒, contrapositive, counterexample, truth table, De Morgan's laws | R1 "set". R3 "power set". R4. CT-8: the figure lets the union exceed the universe. |
| 2 | 2 | Fractions and recurring decimals | 6 | fraction, denominator, equivalent fractions, improper fraction, mixed number, reciprocal, terminating decimal, recurring decimal, decimal place, significant figures | Footings `fractions`, `rounding`, `place-value`. Formula 10ᵏx − x arrives last, after a worked 0.333… |
| 3 | 3 | Ratio, percentages and growth | 9 and 12 | ratio, proportion, unitary method, percentage, percentage multiplier, reverse percentage, compound growth, rule of 72 | Two school units. Footings `ratio-and-proportion`, `percentages`, `multiply-or-divide`. |
| | | **Gate: Volume I. Kym reads one of 0, 2, 3 aloud.** | | | |
| 4 | 4 | Brackets and factorising | 2 | variable, expression, term, coefficient, like terms, expanding brackets, factorising, quadratic expression, difference of two squares | R2: "term" belongs to algebra here. Tip `tip-binomial-square`. Footing `distributive-law`. |
| 5 | 5 | Equations, formulas and inequalities | 7 | equation, solution, inverse operation, substitution, formula, subject of a formula, inequality | Footing `inverse-operations`. |
| 6 | 6 | Sequences and the nth term | 11 | sequence, term-to-term rule, nth term, common difference, second difference, arithmetic series, Fibonacci sequence, golden ratio | R2: a sequence's "term" links to nothing new; say "number in the sequence" until the card name "nth term". Tip `tip-gauss-sum`. Footing `nth-term`. |
| 7 | 7 | Straight-line graphs | 14 | function, coordinates, gradient, y-intercept, x-intercept, equation of a line, parallel lines, perpendicular lines, distance–time graph, speed | R1 "function". Footing `coordinates-and-gradient`. Title drops "Kinematics". |
| | | **Gate: Volume II. Kym reads one aloud.** | | | |
| 8 | 8 | Angles and proof | 8 | angle, transversal, alternate angles, corresponding angles, co-interior angles, vertically opposite angles, interior angle, exterior angle, polygon, midpoint, proof | Footing `angle-facts`. |
| 9 | 9 | Constructions, bearings and nets | 3 | locus, perpendicular bisector, angle bisector, congruent triangles, quadrilateral family, bearing, plan and elevation, net, vertex edge and face, Euler's formula | R1 "net", "face", "plan". |
| 10 | 10 | Circles, prisms and volume | 5 | radius, diameter, circumference, π, area, sector, trapezium, prism, cross-section, volume, surface area, Cavalieri's principle | Tip `tip-circle-area`. Footings `area-and-perimeter`, `units-and-scale`. Title drops "Mensuration". |
| 11 | 11 | Moving and resizing shapes | 13 | transformation, translation, column vector, reflection, mirror line, rotation, centre of rotation, enlargement, scale factor, centre of enlargement, congruent, similar, area scale factor | R3 "scale factor". R1 "similar". Footing `transformations`. Column vector is taught here and reused in 19. |
| 12 | 12 | Pythagoras and trigonometry | none (beyond) | right-angled triangle, hypotenuse, Pythagoras' theorem, unit circle, sine, cosine, tangent, θ, radian, identity, sine rule, cosine rule | R2: "tangent" belongs to trigonometry here. Tip `tip-pythag-trig`. |
| | | **Gate: Volume III. Kym reads one aloud.** | | | |
| 13 | 13 | Samples you can trust | 4 | population, sample, random sample, stratified sample, systematic sample, bias, survivorship bias, mean, standard error | R1 "sample", "mean". Standard error is beyond; say so in its section. |
| 14 | 14 | Spread: histograms and standard deviation | 10 | time series, moving average, stem-and-leaf diagram, histogram, class width, frequency density, median, quartile, interquartile range, Σ, variance, standard deviation σ | R2 "range". Footing `spread-and-density`. |
| 15 | 15 | Counting outcomes | 15 | probability, outcome, sample space, experimental probability, mutually exclusive, independent events, tree diagram, factorial n!, permutation, combination, bell curve | R1 "event". CT-12: say "if independent". Footings `equally-likely-outcomes`, `the-right-total`. |
| 16 | 16 | Bayes: updating a belief | none (beyond) | conditional probability, prior, sensitivity, specificity, false positive, posterior, base rate, likelihood ratio, Bayes' theorem | Tip `tip-bayes-square`. Work in 1,000 people before any formula. |
| | | **Gate: Volume IV. Kym reads one aloud.** | | | |
| 17 | 17 | Slopes of curves | none (beyond) | limit, secant, tangent line, rate of change, derivative, power rule, stationary point, maximum and minimum | R1 "limit". R2: "tangent line" is its own card; bare "tangent" stays with chapter 12. |
| 18 | 18 | Areas under curves | none (beyond) | Riemann sum, midpoint rule, definite integral ∫, antiderivative, fundamental theorem of calculus, signed area | Tip `tip-calculus-ftc`. |
| 19 | 19 | Vectors | 16 | position vector, adding vectors, zero vector, magnitude \|v\|, scalar multiple, collinear, dot product | CT-5: the figure shows a dot product for an angle the vectors do not have. CT-12: the chapter contradicts itself. Footing `vectors`. |
| 20 | 20 | Matrices | none (beyond) | linear transformation, basis vectors, matrix, matrix multiplication, determinant det, singular matrix, eigenvector, eigenvalue λ | Tip `tip-matrix-det` is wrong today: the box minus four triangles leaves ad + bc, and two b × c rectangles must go too (audit item 11). |
| | | **Gate: Volume V. Kym reads one aloud.** | | | |

About 190 new cards, so about 200 in all. The symbol cards the brief lists are covered: ∪ and ∩ (0), √ (1, done), π (10), θ (12), Σ (14), n! (15), ∫ (18), |v| (19), det (20).

## After the chapters

| Stage | Work | Count |
|---|---|---|
| S1 | School questions not reached through D1, and all unit topic summaries and watch-outs. Check 5 runs across worked examples, so no two questions share a sentence. | whatever D1 left of 64 |
| S2 | Misconceptions and footings: run checks 3 and 4, fix failures, keep meanings. | 55 and 22 |
| S3 | Pólya prompts, speed-maths decks, diagram plates, explorer summaries, cross-subject bridges, volume titles ("The Horizon", "Mensuration"). | 4, 6, 16, 4, 8, 5 |
| S4 | Screen titles and button labels around the content, and any remaining figure labels in `index.html` (22 "Invariant" and 5 "Horizon" labels today). | by grep |
| S5 | Turn the checks on for the whole pack. Delete `raw_specs`, the sentence templates and the stop phrases that became cards. | once |

## Acceptance criteria

| ID | Given / when | Observable result | Source |
|---|---|---|---|
| A1 | The splice script runs | It reports chapters 0 to 20 as rewritten and "Content checks passed". No kept field drifts. | brief, rules for the work |
| A2 | Any chapter breaks one of the seven checks, or check 8 | The splice and the exporter stop and name the string. Nothing is written. | brief, checks |
| A3 | Any key term or listed symbol | It is the name of a card, and its first use in a section is a link in both the Python and Swift link finders. | brief, linking rules |
| A4 | The pack is searched for a sentence of six or more words used twice across chapters, or across worked examples | None is found, and the exporter holds no sentence template. | brief, check 5 |
| A5 | Every "Your turn", card check and worked sum | The real marker marks each listed right answer right and each listed wrong answer wrong, and `test_book_maths.py` recomputes every sum. | brief: every number is checked by code |
| A6 | A beyond-school chapter (0, 12, 16, 17, 18, 20) opens | Its first screen says it goes past her school book and names the cards it stands on. | brief |
| A7 | Any chapter | It has a skill card with a device-off check and an answer, shown on its first screen. | global rule: learning starts from the skill |
| A8 | Before and after the work | Every callout, section, widget, lesson, tip and question id that existed at the baseline still exists. Counts are 21, 47, 63, 8, 64. | saved answers key on ids |
| A9 | Each chapter, on the iPad simulator | A verifier finds no clipped text, no file path, no banned word in a label, no default-blue link, and a card opens from a link and closes back to the same place. | chapter 1 walk-through |
| A10 | Each volume | Kym has read one chapter aloud, and each stumble is a dated line in `docs/READ_ALOUD_LOG.md` with the fix made to the text or the brief. | brief, done means |
| A11 | The new-links report for a slice | The writer has read it. No link lands on an everyday use of a word. | R1 |
| A12 | The new build is installed over a build with saved chapter progress | Chapters show the new text, saved answers are still there, and the app does not crash on a chapter whose section count changed. | R7 |

## Verification

| ID | Evidence | Expected | Reject when |
|---|---|---|---|
| A1, A2, A4 | `python3 -m unittest` and `python3 splice_pack_sections.py` in `source/` | all tests pass; checks passed; chapters 0 to 20 listed | any check is skipped for a chapter, or a fixture test is deleted |
| A3 | Swift test "golden agreement" in `Tests/ConceptLinkTests.swift`; check 1 | every golden entry reproduced | the golden file omits a rewritten chapter's strings |
| A5 | `MarkingTests` card and turn samples; `python3 -m unittest test_book_maths` | pass | a turn has fewer than 1 accepted and 2 rejected samples |
| A6, A7 | Swift tests from G6; device shot of each chapter's first screen | text present | the skill card is in the pack but not on screen |
| A8 | A test that compares ids against a list saved from the baseline commit | equal | an id is renamed "for clarity" |
| A9, A11 | Verifier subagent report with screenshot paths under `KymMaths/build/`; the new-links report | PASS on each item | the verifier could not tap and reports from screenshots of the first screen only |
| A10 | `docs/READ_ALOUD_LOG.md` | one dated entry per volume | an entry has no fix |
| A12 | Install baseline build, read a chapter, install new build, open the same chapter | text is new, answers kept | not tried |

## Sessions (estimates from chapter 1's measured cost, not promises)

| Session | Contents | Ends with |
|---|---|---|
| 1 | Stage 0, then chapter 0 | the full slice proven on a second chapter |
| 2 | Chapters 2 and 3 | Volume I gate |
| 3 | Chapters 4 to 7 | Volume II gate |
| 4 | Chapters 8 to 12 | Volume III gate |
| 5 | Chapters 13 to 16 | Volume IV gate |
| 6 | Chapters 17 to 20 | Volume V gate |
| 7 | S1 to S5 and the final audit | A1 to A12 all proven |

A chapter is about 3,000 words of text plus about ten cards. After G1, the chapters of one volume can be written in parallel, one writer per chapter in its own worktree, with the lead merging, settling name clashes and running the checks. Each session starts by reading the brief, this plan and `ch01.py`, and ends by updating the progress table below.

## Done when

Working directory: `/Users/amarsukhi/src/MyCode/kym_maths`

| Check | Command | Required result |
|---|---|---|
| Content | `cd source && python3 -m unittest` | all pass |
| Pack | `cd source && python3 splice_pack_sections.py` | "Content checks passed", chapters 0 to 20 |
| App logic | `cd KymMaths && set -o pipefail && swift test 2>&1 \| tail -n 40` | all pass (210 at the baseline) |
| Design rules | `cd KymMaths && scripts/check-design.sh` | no file beyond the three that failed at the baseline |
| Real run | `cd KymMaths && KYM_ONLY="chapter concept proof" scripts/screens.sh build/<name>` then the verifier walk | A9 passes for the chapter |
| Mac and iPhone | `xcodebuild build -scheme KymMaths` and iPhone shots, once per volume | builds; a verifier reads the shots |

The work is finished when A1 to A12 hold for the whole pack and the brief's "Done means" list is true.

## Out of scope

- Loading the 3D Atlas figures offline (audit D8) and the three chapter numbering schemes (audit D12).
- New questions for the 46 sections that have none (CT-9), and real workbook page numbers (CT-10 needs the printed book).
- Redesigning "Who is right?" so a choice does not show its reason. Logged in chapter 1's walk-through; it is a layout decision.
- Making the full exporter reproduce the checked-in pack for sections this plan does not rewrite.
- New figures. Where a chapter's figure cannot show an idea, the step says so and uses paper, as chapter 1 section 1.4 does.

## Progress

| Ch | Slice done | Checks pass | Walk-through | Read aloud | Commit |
|---|---|---|---|---|---|
| 1 | yes | yes | yes (iPad) | waiting | `e416fa8` |
| Stage 0 | | | | | |
| 0, 2 to 20 | | | | | |

## Contract amendments

| Revision | Reason and evidence | Changed cases, scope or checks | Accepted by |
|---|---|---|---|

## Audit receipt

Verdict: not yet audited.
