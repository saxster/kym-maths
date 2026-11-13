# Euclid spine

Euclid's Workshop lets Kym build Book I of the Elements with a compass and a straightedge. Each proposition she proves becomes a tool for the next one. This page holds the skill cards, written before any view code, in the format of `kym_mathgames/docs/SKILL_CHAINS.md`.

The data lives in code: `KymMaths/KymMaths/Core/Geometry/EuclidSpine.swift`. `EuclidSpineTests` fails when the graph has a loop, a proof cites a proposition it doesn't list, a built proposition leads nowhere, or a scripted construction misses its goal. This page is the readable version. When the two disagree, the code wins and this page gets fixed.

## The chain

Kym builds six propositions. Read each arrow as "is used by".

```
I.1 ──► I.9 ──► I.10 ──► ch09 (loci)
 │                │
 │                └──────────────────┐
 │                                   ▼
 └────► I.11 ──► I.46 ───────────► I.47 ──► ch12 (Pythagoras, trigonometry)
```

She learns them in the order I.1, I.9, I.10, I.11, I.46, I.47. That is a teaching order, not a dependency: in Euclid, I.11 stands on I.1, not on I.10.

Seven more propositions are accepted, not built. They show as grey nodes, and each one names the chapter that teaches it.

| Prop | Says | Taught in |
|---|---|---|
| I.4 | Side-angle-side: two sides and the angle between them fix a triangle | OUP 3.4 Constructions (ch09) |
| I.8 | Side-side-side: three sides fix a triangle's angles | OUP 3.4 Constructions (ch09) |
| I.14 | Two angles that add to two right angles make a straight line | OUP 8.2 (ch08) |
| I.28 | Co-interior angles that add to two right angles make parallel lines | OUP 8.2 (ch08) |
| I.33 | Joining the ends of equal parallel lines gives equal parallel lines | OUP 3.1 Quadrilaterals (ch09) |
| I.34 | A parallelogram's opposite sides and angles are equal | OUP 3.1 Quadrilaterals (ch09) |
| I.41 | A parallelogram is double a triangle on the same base, between the same parallels | OUP 5.2 (ch10) |

## Skill cards

| Prop | Skill | She can do, device off (the check) | Why it matters | Stands on | Unlocks |
|---|---|---|---|---|---|
| I.1 | Equilateral triangle | With a real compass, build an equilateral triangle on a 6 cm line. **All three sides are 6 cm.** | Two equal circles meet at points the same distance from both centres. Every locus starts here. | Postulates 1 and 3 | I.9, I.10, I.11 |
| I.9 | Bisect an angle | Bisect a 70° angle. **Each half is 35°.** | The angle bisector is the locus the same distance from two lines (OUP 3.5). | I.1, I.8 | I.10 |
| I.10 | Bisect a segment | Find the midpoint of a 7 cm line. **The halves are 3.5 cm, and the lines cross at 90°.** | The perpendicular bisector is the locus the same distance from two points (OUP 3.5, ch09). | I.1, I.9, I.4 | I.47, ch09 |
| I.11 | Perpendicular at a point | Draw a right angle at a point on a line, without a protractor. **A set square fits: 90°.** | Right angles, so squares and the Pythagoras figure. | I.1, I.8 | I.46 |
| I.46 | Square on a segment | Build a square on a 5 cm line. **A diagonal is about 7.1 cm.** | The squares are the area pieces of I.47. | I.11, I.28, I.33, I.34 | I.47 |
| I.47 | Pythagoras | Sketch why the two small squares fill the big one. Then find the longest side when the others are 5 and 12. **Each small square equals the rectangle below it; 25 + 144 = 169, so 13.** | Trigonometry, distance and bearings in ch12 (`bearingsPythagorasDistance`). | I.46, I.10, I.4, I.8, I.14, I.28, I.41 | ch12 |

## Fade path

Each skill fades from the board into her head in three levels, as in `SKILL_CHAINS.md`. Levels are earned in order.

1. **With the picture.** She builds it on the Byrne board, with colour only, the tools and snapping.
2. **In her head.** A Letters layer swaps colour for the school's A, B, C. Then a step-order round dims the board to an outline. She puts the numbered steps in order and names the proposition each step uses. No tools.
3. **Knows when.** A word problem with no figure. She picks the proposition that solves it.

The knows-when problems:

| Prop | Problem |
|---|---|
| I.1 | Three friends want each to stand the same distance from the other two. Two are standing. Where does the third go? |
| I.9 | A path starts at the corner of a field and stays the same distance from both walls. Which way does it run? |
| I.10 | Where can a well go so that it is the same distance from two villages? |
| I.11 | A flagpole must stand at right angles to a straight path, at one marked spot. How do you set it out with a rope and two pegs? |
| I.46 | Mark out a square sandpit along one wall, with each side as long as the wall. |
| I.47 | A ladder is 13 m long and its foot is 5 m from the wall. How high does it reach? |

The device-off checks print on each card. A parent records them with one tap.

## Where this differs from Euclid

The board follows Euclid's rule: every point is given or is where two drawn curves cross. Each proof is written for the board's construction and cites only what that proof uses. Some constructions differ from Heath's text, so their `uses` differ too.

- **No Postulate 2.** The board draws finite segments only. Where Euclid produces a line, the given line is already long enough. I.46's given line runs past both ends of the side. Each side of I.47's triangle runs past its corners.
- **No free points.** Euclid's "take a point D at random" becomes a point already on the board. In I.9, D is B. In I.11, D is the nearer end of the line.
- **No I.3.** In I.9 and I.11, Euclid copies a length with I.3. Here the circle is centred at the vertex, so a single circle cuts off the equal length. The proofs cite Definition 15 (radii are equal) instead, and I.2 and I.3 are not in the spine.
- **I.46.** Euclid raises one perpendicular (I.11), cuts it with I.3, and draws two parallels (I.31). The proof uses I.29 and I.34. Here I.11 raises perpendiculars at both ends. A circle centred at A through B cuts the first at D, and a circle centred at B through A cuts the second at E. DE is joined. The proof uses I.28 (the perpendiculars are parallel), I.33 (so DE is equal and parallel to AB) and I.34 (so every angle is right).
- **I.47's line AL.** Euclid draws AL parallel to BD with I.31. The board has no parallel tool, so AL is dropped onto DE at right angles. A circle centred at A through D cuts DE again at N, and I.10 halves DN at L. This is Euclid's own method in I.12. The proof adds two steps: AL is at right angles to DE (I.8, Definition 10), so it is parallel to BD (I.28). The `uses` list gains I.8, I.10 and I.28 and drops I.31.
- **"Doubles of equals are equal."** Euclid uses this in I.47. Heath counts it as a later addition, not one of the five common notions. The proof cites Common Notion 1 for that step.
- **The plan's first draft** had I.10 unlocking I.11, and I.46 standing on I.31. Both changed for the reasons above.

## Tool conventions

A proven proposition works as a tool on any points, so its scripted construction decides sides by geometry, not by fixed coordinates.

- I.1 puts the apex on the left of the line from its first point to its second.
- I.9 orders its I.1 so the apex lands away from the vertex.
- I.11 puts the perpendicular on the left of A→B.
- I.46 puts the square on the left of its line P→Q.
- I.47 turns each I.46 so its square lands outside the triangle.
