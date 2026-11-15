# Name the slip

When Kym's answer to a school question is wrong in a way we expected, the app names the slip and points at the one step to recheck, never at the answer. The slips live in `source/export_kymmaths_pack.py` (`MISCONCEPTIONS` and each key's `mistakes`) and are exported to the seed pack. `KymMaths/Tests/MistakeTests.swift` fails when an example isn't marked as its slip or a next step gives a number away. 61 of the 64 questions name at least one slip; the three marked by words (ch03-wb-practice, ch04-wb-practice, ch11-wb-focus) name none, because a wrong explanation has no single wrong answer to recognise. Where this page and the code disagree, the code wins.

## Skill card

| Field | |
|---|---|
| Skill | Name the slip |
| She can do, device off (the check) | Shown "(−2) × 8 = 16", she names the slip ("the minus sign got lost") and the rule that fixes it ("a negative times a positive is negative"). |
| Why it matters | Checking an answer against the two or three usual slips for that question type before handing it in is how marks are saved in exams. |
| Stands on | The topic skill itself: she can't name a slip in a method she can't do. |
| Unlocks | Find the step underneath (below), and checking her own work. |

## Three levels

1. **With the picture.** After a wrong answer the result card names the slip and the step to recheck. *Built.*
2. **In her head.** Before marking, she says which slip she checked for. *Not built.*
3. **Knows when.** She checks for the usual slips unprompted. *Not built.* Each saved attempt keeps `lastMistakeId` as the evidence.

## Registry

| id | Name | Questions |
|---|---|---|
| `sign-of-product` | You got a sign wrong multiplying or dividing | ch01-wb-focus, ch02-sb, ch02-wb-practice, ch16-sb |
| `dropped-minus` | You lost a minus sign | ch02-wb-focus, ch08-sb, ch13-wb-focus, ch13-wb-practice, ch13-wb-challenge, ch16-wb-focus, ch16-wb-challenge |
| `rearranged-sign` | You got a sign wrong moving a term across | ch03-wb-focus, ch07-sb, ch07-wb-focus, ch07-wb-practice, ch07-wb-challenge, ch08-sb, ch08-wb-practice, ch14-sb, ch14-wb-focus |
| `expand-first-term-only` | You multiplied only the first term in the bracket | ch02-sb, ch02-wb-practice, ch07-wb-focus, ch07-wb-challenge, ch14-wb-challenge |
| `lcm-as-product` | You took the LCM as the numbers multiplied together | ch01-sb, ch01-wb-practice, ch01-wb-challenge |
| `hcf-lcm-swapped` | You mixed up HCF and LCM | ch01-sb, ch01-wb-practice |
| `stopped-early` | You stopped one step too soon | ch01-wb-challenge, ch02-wb-challenge, ch08-wb-challenge, ch09-wb-challenge, ch12-sb, ch13-wb-challenge |
| `common-factor-left` | You left a common factor in | ch02-wb-focus, ch06-sb, ch12-wb-challenge |
| `square-of-difference` | You treated a² − b² as (a − b)² | ch02-wb-challenge |
| `back-bearing` | You did not turn round for the back-bearing | ch03-sb |
| `added-sides` | You added lengths instead of using Pythagoras | ch03-wb-challenge, ch16-sb |
| `forgot-square-root` | You forgot the square root | ch03-wb-challenge, ch04-wb-challenge, ch07-sb, ch10-wb-practice, ch16-sb |
| `equal-split` | You split the sample equally, not in proportion | ch04-sb |
| `multiplied-instead-of-divided` | You multiplied when you needed to divide | ch04-wb-focus, ch06-wb-challenge, ch09-sb, ch09-wb-focus |
| `divided-wrong-way-round` | You divided the wrong way round | ch04-wb-focus, ch10-sb, ch14-sb |
| `unit-slip` | You mixed up the units | ch05-sb |
| `forgot-half` | You forgot to halve | ch05-sb, ch08-wb-focus, ch11-sb, ch11-wb-challenge, ch14-wb-challenge, ch16-wb-practice |
| `radius-diameter-mixed` | You mixed up the radius and the diameter | ch05-wb-focus, ch05-wb-challenge |
| `power-as-multiply` | You multiplied by the power instead of raising to it | ch05-wb-focus |
| `height-slant-mixed` | You mixed up the slanted side and the height | ch05-wb-practice |
| `missing-edges` | You left out some edges of the shape | ch05-wb-practice, ch05-wb-challenge |
| `truncated` | You cut digits off instead of rounding | ch05-wb-challenge, ch06-wb-focus |
| `recurring-as-terminating` | You treated the recurring decimal as if it stopped | ch06-sb |
| `decimal-places-not-sf` | You rounded to decimal places, not significant figures | ch06-wb-focus |
| `place-value-shift` | You shifted the place value | ch06-wb-focus, ch09-wb-focus |
| `split-mixed-number` | You worked on the whole numbers and fractions separately | ch06-wb-practice, ch06-wb-challenge |
| `added-denominators` | You added or subtracted the denominators | ch06-wb-practice |
| `inequality-not-flipped` | You did not reverse the inequality sign | ch07-wb-practice |
| `co-interior-as-equal` | You made co-interior angles equal | ch08-wb-practice |
| `half-difference` | You halved the difference instead of averaging | ch08-wb-focus |
| `swapped-coordinates` | You swapped x and y | ch08-wb-focus, ch14-wb-challenge |
| `interior-for-exterior` | You used the interior angle instead of the exterior | ch08-wb-challenge |
| `percent-of-wrong-amount` | You took the percentage of the wrong amount | ch09-sb, ch15-sb |
| `percentages-cancel` | You let the two percentages cancel out | ch09-wb-practice |
| `simple-not-compound` | You used simple interest instead of compound | ch09-wb-challenge |
| `density-as-frequency` | You mixed up frequency and frequency density | ch10-sb, ch10-wb-challenge |
| `boundary-for-width` | You used a class boundary instead of the class width | ch10-wb-challenge |
| `range-for-iqr` | You found the range, not the interquartile range | ch10-wb-focus |
| `off-by-one` | You were one step out | ch11-sb, ch11-wb-practice, ch11-wb-challenge |
| `wrong-units-for-difference` | You matched the difference to the wrong units | ch12-sb |
| `area-by-length-factor` | You scaled an area by the length factor | ch12-wb-focus, ch13-sb |
| `direct-for-inverse` | You used direct proportion where it is inverse | ch12-wb-practice |
| `unmatched-middle` | You joined the ratios without matching the shared part | ch12-wb-challenge |
| `centre-ignored` | You enlarged from the origin, not the centre | ch13-sb, ch13-wb-challenge |
| `wrong-mirror-line` | You reflected in the wrong mirror line | ch13-wb-focus |
| `wrong-turn-direction` | You turned the wrong way | ch13-wb-practice |
| `inverse-wrong-order` | You undid the steps in the wrong order | ch14-wb-focus |
| `inverse-as-reciprocal` | You took one over f instead of the inverse | ch14-wb-focus |
| `perpendicular-gradient` | You did not both flip and negate the gradient | ch14-wb-practice |
| `conditional-reversed` | You turned the condition round | ch15-sb |
| `wrong-total` | You divided by the wrong total | ch15-sb |
| `unequal-outcomes` | You treated the sums as equally likely | ch15-wb-focus |
| `order-mixed` | You mixed up whether order matters | ch15-wb-focus, ch15-wb-challenge |
| `with-replacement` | You forgot the first marble stays out | ch15-wb-practice |
| `vector-combined-wrongly` | You combined the vectors the wrong way | ch16-wb-focus, ch16-wb-practice |

# Find the step underneath

When the same named slip comes back a second time, on the same question after the repair failed or on another question, the app stops and walks back to the smaller skill the slip rests on: its footing. Hand in on that question stays shut until she has checked the footing with three short probes. Two right in a row passes; three probes end it either way, and a miss shows the footing's teach line and the answer. A pass resets the count; a miss lets her go back to the question but keeps the count, so the next same slip walks back again.

The footings live in `source/export_kymmaths_pack.py` (`FOOTINGS`, and `STANDS_ON` maps each slip to one). `source/splice_pack_sections.py` writes them and the misconception registry into the seed pack without a full export. The count lives in `slip_tallies` in `state.sqlite`; the rule is `WalkBackRule`. `KymMaths/Tests/WalkBackTests.swift` fails when a slip has no footing, a probe's own answer is marked wrong, or a teach line gives away a probe's answer.

## Skill card

| Field | |
|---|---|
| Skill | Find the step underneath |
| She can do, device off (the check) | When a slip comes back twice, she names the smaller skill it rests on and checks it on paper with a tiny example before going on. Losing the minus sign twice, she says "it rests on multiplying negatives", writes (−3) × (−2) = 6 and 6 ÷ (−3) = −2, then goes back to the question. |
| Why it matters | A slip that repeats is rarely carelessness: it shows a gap in an earlier skill. Fixing that skill stops the slip in every topic built on it, not just the question in front of her. |
| Stands on | Name the slip (above): she can't find what a slip rests on until she can name the slip. |
| Unlocks | The "Stuck?" micro-worksheet (feature #3). |

## Three levels

1. **With the picture.** The app names the footing and runs the three probes. *Built.*
2. **In her head.** On the second slip she names the footing before the app does. *Not built.*
3. **Knows when.** She checks the footing unprompted when a slip repeats. *Not built.* `slip_tallies` keeps each slip's count and the last check's result as the evidence.

## Footings

| id | Skill | Slips that stand on it |
|---|---|---|
| `negative-numbers` | Multiply and divide negative numbers | `sign-of-product`, `dropped-minus`, `inequality-not-flipped` |
| `inverse-operations` | Undo each step with its inverse | `rearranged-sign`, `inverse-wrong-order`, `inverse-as-reciprocal` |
| `distributive-law` | Multiply every term inside a bracket | `expand-first-term-only`, `square-of-difference` |
| `factors-and-multiples` | Find the HCF and LCM, and cancel fully | `lcm-as-product`, `hcf-lcm-swapped`, `common-factor-left` |
| `squares-and-roots` | Square a number and undo it with a square root | `forgot-square-root`, `added-sides`, `power-as-multiply` |
| `fractions` | Use a common denominator and improper fractions | `added-denominators`, `split-mixed-number` |
| `rounding` | Round to decimal places and significant figures | `truncated`, `decimal-places-not-sf` |
| `place-value` | Multiply and divide by 10, 100 and decimals | `place-value-shift`, `recurring-as-terminating` |
| `multiply-or-divide` | Choose multiply or divide, and which way round | `multiplied-instead-of-divided`, `divided-wrong-way-round` |
| `ratio-and-proportion` | Work out what one part is worth | `equal-split`, `direct-for-inverse`, `unmatched-middle`, `wrong-units-for-difference` |
| `percentages` | Use a multiplier for a percentage change | `percent-of-wrong-amount`, `percentages-cancel`, `simple-not-compound` |
| `units-and-scale` | Convert units, and square the factor for areas | `unit-slip`, `area-by-length-factor` |
| `area-and-perimeter` | Use the right lengths in area and perimeter | `forgot-half`, `height-slant-mixed`, `radius-diameter-mixed`, `missing-edges` |
| `angle-facts` | Use angle facts for parallel lines, polygons and bearings | `co-interior-as-equal`, `interior-for-exterior`, `back-bearing` |
| `coordinates-and-gradient` | Find a midpoint and a gradient from coordinates | `swapped-coordinates`, `half-difference`, `perpendicular-gradient` |
| `transformations` | Reflect, rotate and enlarge a point | `centre-ignored`, `wrong-mirror-line`, `wrong-turn-direction` |
| `equally-likely-outcomes` | List equally likely outcomes and count each once | `unequal-outcomes`, `order-mixed` |
| `the-right-total` | Use the right total for a probability | `conditional-reversed`, `wrong-total`, `with-replacement` |
| `spread-and-density` | Find class width, frequency density and quartiles | `density-as-frequency`, `boundary-for-width`, `range-for-iqr` |
| `vectors` | Add and subtract column vectors | `vector-combined-wrongly` |
| `nth-term` | Find and use the nth term of a sequence | `off-by-one` |
| `answer-the-question` | Check you answered what was asked | `stopped-early` |
