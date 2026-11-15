# Facts by heart

Each day on Today, Kym warms up with four 20-second sprints, one per family of facts: times and divide, squares and roots, powers, and fractions, decimals and percents. She types each answer on an on-screen keypad. A wrong answer shows the fact whole ("7 × 8 = 56") and the next one comes straight away; the clock never stops. Facts she missed come first next time.

The facts are worked out in code, not typed in: `FactCatalog` in `KymMaths/KymMaths/Core/Learning/FactSprint.swift`. The same file holds the deck (last time's misses first, then the rest shuffled) and the 20-second run. Marking is `SpeedMathAnswerCheck`, so ".125" and "0.125" both pass, and "6/8" fails when the answer is "3/4". Each finished sprint is saved in `fact_sprints` in `state.sqlite`, with the ids of the facts she missed. The band is in `TodayHomeView`, the sprint in `FactSprintSheet`; `kymmaths://today/sprint` opens it. `KymMaths/Tests/FactSprintTests.swift` fails when a fact's own answer is marked wrong, a prompt repeats, or a miss does not come first. Where this page and the code disagree, the code wins.

## Skill card

| Field | |
|---|---|
| Skill | Facts by heart |
| She can do, device off (the check) | Someone reads out 7 × 8, 56 ÷ 7, 13², √144, 2⁶ and 3/8 as a decimal. She answers each within about two seconds, without counting up: 56, 8, 169, 12, 64, 0.375. |
| Why it matters | A fact she has to work out takes the working memory she needs for the method. The HCF and LCM of 72 and 120 needs 72 = 8 × 9 = 2³ × 3² on sight. Out of school: change, prices, "20% off". |
| Stands on | Knowing what multiplying, squaring, powers and fractions mean: she can work each fact out slowly. |
| Unlocks | Prime factorising (chapter 1), simplifying fractions, the index laws, and the Speed "see the shape" decks in Pólya Studio. |

## Three levels

1. **With the picture.** Not needed: she can already work the facts out.
2. **In her head.** The sprint. *Built.*
3. **Knows when.** The Speed decks, where the fact is a step inside a shortcut. *Partly built.*
