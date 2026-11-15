# Content brief: make the textbook a joy to understand

This is the standing prompt for every content session on *The Patterned World* and the school room. It replaces the short ask "make the content less intimidating and link the terms". Hand it to any agent or author before they touch a learner-facing string.

## The reader

Kym is 12, in Stage 8, in Mumbai. She reads alone on an iPad or iPhone. She is bright and will notice being talked down to. She has not met most of the words this book currently uses.

The goal for every page: after reading it she can explain the idea to a friend in her own words, and do one example with the device off.

## What is wrong today (measured 2026-11-15)

All numbers come from `kymmaths-seed-pack.json`, the content pack the app ships.

| Finding | Evidence |
|---|---|
| The book barely explains anything | 21 chapters share 1,579 words of explanation. That is about 75 words a chapter, for topics that run from negative numbers to eigenvectors. |
| Most text is a template, not teaching | 3 sentence templates produce all 63 section texts. 32 of 64 worked examples are one of two stock sentences, and the median worked example is 14 words. 44 of 47 widget prompts and all 63 Atlas lessons are templated (audit CT-15). |
| Terms are used and never taught | 146 key terms are listed as bare strings. None has a definition. "Invariant" appears 214 times, "horizon" 83, "lockstep" 65, "symbolic" 37. |
| Symbols arrive before the idea | Chapter titles and subtitles list formulas. The card for "why minus times minus is plus" gives the reason as `e^(iπ) · e^(iπ) = e^(2πi)`. |
| Reminder cards exist but nothing links to them | 22 short teach cards (`footings`) exist. She only sees one after she makes the same mistake twice on a school question. No word in any text links to one. |

So the content is intimidating because it is a syllabus written in an author's shorthand. The fix is to write the explanations that are missing, not to simplify explanations that exist.

## The task

Rewrite every learner-facing string in the pack so that it teaches, and build a concept-card system so that every technical word and symbol links to a short card that reminds her what it means and how to work it out.

Keep every topic, including Bayes, calculus and matrices. Advanced ideas stay. They get explained from the ground up, and they say honestly that they go beyond her school book.

## The explanation standard (Feynman, made checkable)

Each idea is taught in this order. The name and the symbols come last, as labels for something she already understands.

1. **A question worth asking**, set in her world (a bill, a cricket score, a train, a plate of samosas). Never open with a definition or a formula.
2. **The idea in plain words**, using small whole numbers. No letters yet.
3. **A picture or the interactive figure**, with one sentence that says what to look at and what to notice.
4. **The reason it is true.** The actual reason, in her words, not "it can be shown that".
5. **Now the name and the symbols.** "Mathematicians call this the highest common factor, HCF for short." Each symbol is tied to a part of the picture.
6. **One worked example** where every step gives its reason.
7. **The tempting mistake**, why it is tempting, and how to catch it.
8. **Her turn**: one question with the answer checked.
9. **Say it back**: a one-sentence summary she could say to a friend.

## Language rules

- One idea per sentence. Aim for 20 words or fewer. Hard limit 25.
- At most one new term per paragraph. A term never appears before its card exists.
- Numbers before letters. Use x and n only after the idea has worked with real numbers.
- Use her world: rupees, Mumbai, cricket, trains, food. Keep the examples real, not cute.
- Respect, not sweetness. No "don't worry", "it's easy", "simply", "just", "obviously", "clearly". No exclamation marks used as hype. No praise padding.
- Do not dumb down. Give the true reason. If a full proof is beyond her today, say which part is being trusted and where she will meet it later.
- Banned unless the page has taught them first: invariant, lockstep, horizon, symbolic, anatomy, duality, renormalise, heuristic, mensuration, kinematics. Use "what stays the same", "step by step", "stretch", and so on.
- No file paths, route names or tool names in learner text (`statistics/bayes`, "Atlas route", "Cornell Proof & Construction Journal").

## Concept cards

A concept card is a short page that reminds her of one idea. Every technical word, abbreviation and symbol has one.

**What a card holds**

| Field | Rule |
|---|---|
| Name | The term, plus its short form and symbol if it has them |
| In one sentence | What it is, in plain words. No other technical word unless that word is itself linked. |
| Picture it | One everyday situation with small numbers |
| How to work it out | Numbered steps on small numbers. A second method for big numbers when one exists. |
| Worked example | One, with reasons |
| Check yourself | One question, with a marked answer |
| Don't mix it up with | The term she is most likely to confuse it with, linked, and how to tell them apart |
| Stands on | Links to the cards it needs |
| You will use it in | Links to the chapters and cards that need it |

**Linking rules**

- The first use of a term on any screen is a link. A tap opens the card over the page, and closing it returns her to the same place.
- Links work everywhere she reads: chapter text, widget steps, worked examples, stuck sheets, question prompts, coach replies, and inside other cards.
- From any card she can reach something she already knows in two taps or fewer.
- Cards cover symbols too: ∪, ∩, √, π, θ, Σ, ∫, n!, |v|, det.
- Links are found when the text is drawn, from each card's list of names. Authors write plain text and never mark a link by hand. A phrase that contains a card's name but means something else ("scale factor") goes on the stop list in `concepts.py`.
- The 22 existing footings stay as they are: a footing is the three-question check she gets after the same slip twice. A card names the footing that checks it. Do not copy a footing's text into a card.

**Example card, at the standard expected**

> **Highest common factor (HCF)**
>
> *In one sentence.* The biggest number that divides exactly into both numbers.
>
> *Picture it.* You have 12 samosas and 18 jalebis. You want identical plates with nothing left over. The most plates you can make is 6, each with 2 samosas and 3 jalebis. So the HCF of 12 and 18 is 6.
>
> *How to work it out, small numbers.*
> 1. List the factors of each. 12: 1, 2, 3, 4, 6, 12. 18: 1, 2, 3, 6, 9, 18.
> 2. Find the ones in both lists: 1, 2, 3, 6.
> 3. Take the biggest: 6.
>
> *How to work it out, big numbers.* Break each into [prime factors]. 12 = 2 × 2 × 3 and 18 = 2 × 3 × 3. They share one 2 and one 3. Multiply what they share: 2 × 3 = 6.
>
> *Check yourself.* What is the HCF of 20 and 30? (10)
>
> *Don't mix it up with* the [lowest common multiple]. The HCF is never bigger than the smaller number. The LCM is never smaller than the bigger number.
>
> *Stands on:* [factor], [prime factors]. *You will use it in:* simplifying fractions, taking out a common factor in algebra.

**Example rewrite, chapter 1**

Before: "Two 180° rotations equal 360° (+1), and for any two integers a and b, taking min(exponents) for HCF and max(exponents) for LCM guarantees min + max = total!"

After: "Stand at 0 on a number line, facing the positive numbers. Multiplying by −1 means *turn around*. Turn around once and you face the negatives. Turn around twice and you face forward again. That is all (−1) × (−1) = +1 says. Now try (−3) × (−4). The 3 × 4 gives the size, 12. The two minus signs are two about-turns, so you finish facing forward. The answer is +12."

HCF and LCM then get their own section. They do not share a sentence with negative numbers.

## Each chapter starts from its skill

Before writing a chapter, write its skill card in the format of `kym_mathgames/docs/SKILL_CHAINS.md`: the skill, what she can do with the device off (with a check and its answer), why it matters, what it stands on, what it unlocks. A chapter that cannot name its skill is not ready to write.

Chapters 13 to 20 go beyond the Stage 8 school book. Say so on the chapter's first screen, and name the earlier cards each one stands on.

Titles and subtitles are plain. "Chapter 1 · Negative numbers, primes and powers", not a list of formulas.

## Scope: every surface she reads

Chapter hooks and sections, callouts, key terms, widget prompts and steps, Atlas lessons, visual tips, worked examples, faded prompts, stuck sheets, footings, Pólya prompts, speed-maths decks, diagram plates, explorer summaries, cross-subject bridges, and the screen titles and button labels around them.

## Rules for the work

- Rewritten content lives in `source/book/`: one file per chapter (`ch01.py`) and `concepts.py` for the cards. That is the source for everything it holds.
- Put it into the pack with `source/splice_pack_sections.py`, never with a full export. The checked-in pack holds hand edits the exporter cannot reproduce yet, and a full export would erase them. Never hand-edit the JSON pack.
- Write each chapter by hand. Delete the sentence templates as each chapter is rewritten.
- Every number in an example is checked by code or by an existing answer key. Do not change an answer key unless it is wrong, and say so when you do.
- Fix the content defects the audit already lists while you are in the chapter (CT-5 to CT-24 in `docs/AUDIT_2026-11-15.md`).
- Existing tests stay green.

## Checks that must fail when the standard slips

Build these into the exporter or the test suite, so the standard does not depend on anyone remembering it.

1. A key term of a rewritten chapter has no card, or the app's link finder and the exporter's disagree on any learner string.
2. A card is missing a field, links to a card that does not exist, or its "stands on" chain loops.
3. A banned word appears in learner text.
4. A learner sentence is longer than 25 words.
5. The same sentence appears in more than one chapter (catches templates).
6. A formula or symbol appears in a chapter before the section that teaches it.
7. A chapter has no skill card, or its device-off check has no answer.

## Order of work

1. **Slice one: chapter 1, end to end.** Skill card, rewritten text, its concept cards (negative number, factor, multiple, prime number, prime factors, HCF, LCM, power, index laws, square root, irrational number), links that open cards in the book and in the school room, and the seven checks. Stop for review. Kym reads it aloud; every stumble becomes a fix to this brief.
2. Volume I (chapters 0, 2, 3), then Volumes II and III, which carry the school book.
3. Volumes IV and V.
4. The school room: worked examples and stuck sheets for all 64 questions.
5. Everything left in the scope list.

Each chapter is one commit that passes the checks.

## Done means

- Every key term and symbol has a card, and every first use links to it.
- No templated sentence remains.
- The seven checks pass in the test suite.
- Kym has read at least one chapter per volume aloud, and her stumbles are fixed.
