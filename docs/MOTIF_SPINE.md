# Motif spine

The Euclid spine teaches Kym to build a figure. This spine teaches her to spot one. Exam geometry reuses a few named figures again and again. Once she can see "that's an M-shape", the helper line and the answer come next. This page holds the skill cards, written before any view code, in the format of `kym_mathgames/docs/SKILL_CHAINS.md`.

The idea of three layers (prototypes, motifs, composite problems) comes from the Singapore geometry site 几何三层课堂 (dalei.rokoai.fun). We take the structure only. Every problem, number and word on this page is our own.

M1–M5 are built (see Build order). The data lives in `KymMaths/KymMaths/Core/Geometry/MotifSpine.swift`, with a `MotifSpineTests` that fails on a loop, a dead end, or a check whose answer the figure doesn't measure. Where this page and the code disagree, the code wins and this page gets fixed.

## The three layers

1. **Prototypes.** Single facts she already meets in OUP Ch 8 and Ch 3. They are the parts.
2. **Motifs.** Named figures built from two or three prototypes. Each one has a helper line or a short argument she can say aloud.
3. **Composites.** Problems that need two motifs, or a motif plus a prototype. Every step names the motif or fact it uses.

## The chain

Read each arrow as "is used by".

```
P-par ──► M1 M-shape ──────────────► C1 Bent path + isosceles
  │                                    ▲
  │       P-iso ─────────────────────┘ │
  │         │                          │
  ├───────► M4 Bisector + parallel ──► C4 Bisector in a parallelogram
  │         ▲
  │       I.9 (Euclid spine)
  │
  └───────► M5 A-shape ──────────────► ch11 (enlargement), ch12 (trigonometry)

P-line ─┐
        ├─► M2 X-shape ──────────────► C2 Five-point star
P-tri ──┤
        └─► M3 Dart ─────────────────► C3 Angle between two bisectors
```

## Prototypes

These are accepted, not taught here. Each names where she learns it.

| ID | Fact | Taught in |
|---|---|---|
| P-par | Parallel lines: corresponding angles equal (F), alternate angles equal (Z), co-interior angles add to 180° (C) | OUP 8.2 Angles in parallel and intersecting lines (ch08) |
| P-line | Angles on a straight line add to 180°. Vertically opposite angles are equal. | OUP 8.2 (ch08) |
| P-tri | A triangle's angles add to 180°. An exterior angle equals the two interior angles opposite it. | ch08 |
| P-iso | A triangle with two equal sides has two equal angles, and the other way round | ch08 |
| I.9 | Bisect an angle (built in Euclid's Workshop) | `docs/EUCLID_SPINE.md` |

## Motif cards

| ID | Motif | She can do, device off (the check) | The move | Why it matters | Stands on | Unlocks |
|---|---|---|---|---|---|---|
| M1 | M-shape | AB ∥ CD. E is between them, and the bend points toward A and C. ∠ABE = 40°, ∠CDE = 35°. **∠BED = 75°.** | Draw a line through E parallel to AB. It splits ∠BED into two Z-angles. | The helper parallel line is the first construction she invents rather than copies. Bent paths between parallels fill exam angle questions. | P-par | C1 |
| M2 | X-shape | AC and BD cross at O. In △AOB, ∠A = 70° and ∠B = 40°. In △COD, ∠C = 60°. **∠D = 50°.** | The angles at O are vertically opposite, so the other two pairs have the same sum. | Moving an angle sum from one triangle to another without measuring either. It is the engine of the star. | P-line, P-tri | C2 |
| M3 | Dart | ABDC is an arrowhead: D sits inside angle A. ∠A = 50°, ∠ABD = 20°, ∠ACD = 30°. **∠BDC = 100°.** | The notch angle equals the other three added. Extend BD to meet AC, then use the exterior angle twice. | The exterior angle used twice in a row: her first two-step chain. | P-tri | C3 |
| M4 | Bisector + parallel | BD bisects ∠ABC. DE ∥ BC with E on AB. BE = 4 cm. **DE = 4 cm.** | ∠EDB = ∠DBC (Z), and ∠DBC = ∠EBD (bisector). Two equal angles make △BED isosceles. | Turns two angle facts into a length. This is how a parallelogram question hands her a side. | P-par, P-iso, I.9 | C4 |
| M5 | A-shape | DE ∥ BC, D on AB, E on AC. AD = 3, AB = 5, BC = 10. **DE = 6.** | Corresponding angles make the small and big triangles the same shape, so every side scales by AD/AB. | Scale drawings, shadows and maps. Sine and cosine are ratios in an A-shape. | P-par | ch11 (OUP 13, enlargement), ch12 |

### Not yet: the pencil tip

The pencil tip is the M-shape's twin: the bend points away from A and C, and ∠B + ∠E + ∠D = 360°. It joins once a composite needs it. Its first job will be a knows-when distractor for M1: she has to say which way the bend points before she picks the rule.

## Composite cards

| ID | Composite | The check | Steps, each naming its tool | Stands on |
|---|---|---|---|---|
| C1 | Bent path + isosceles | AB ∥ CD. E is between them (M-shape). ∠ABE = 40°, ∠BED = 80°. G is on DC with DG = DE. **∠CDE = 40°, ∠DEG = 70°.** | ∠CDE = 80° − 40° (M1). △DEG has DG = DE, so its base angles are (180° − 40°) ÷ 2 (P-iso, P-tri). | M1, P-iso |
| C2 | Five-point star | A five-point star's tips are 30°, 40°, 35° and 45°. **The fifth tip is 30°.** | Two tips move to the base of the triangle around a third tip (M2). That triangle holds all five, so they add to 180° (P-tri). | M2, P-tri |
| C3 | Angle between two bisectors (stretch) | In △ABC, the bisectors of ∠B and ∠C meet at I. ∠A = 60°. **∠BIC = 120°.** | ABIC is a dart, so ∠BIC = ∠A + half ∠B + half ∠C (M3). ∠B + ∠C = 180° − ∠A (P-tri). So ∠BIC = 90° + ∠A ÷ 2. | M3, I.9 |
| C4 | Bisector in a parallelogram | In parallelogram ABCD, AB = 5 cm and AD = 8 cm. The bisector of ∠A meets BC at E. **BE = 5 cm, EC = 3 cm.** | AD ∥ BC, so M4 makes △ABE isosceles: BE = AB (M4). BC = AD = 8 (Euclid I.34, OUP 3.1). | M4 |

## Fade path

Each motif fades from the board into her head in three levels, as in `SKILL_CHAINS.md`. Levels are earned in order.

1. **With the picture.** She works the check on the motif board. Tapping a given in the question lights only what it names. Tapping the goal lights the target with "?". She drags the free point and sees the rule hold. Then she flips the **break switch**, which removes one condition, and sees the rule fail.
2. **In her head.** The board dims to an outline with the numbers only. She names the motif and says where the helper line goes, then answers. No dragging.
3. **Knows when.** A word problem with no figure. She names the motif that solves it, then solves it.

### Break switches

Each switch removes the one condition the motif needs. The readout shows how far the rule is now off.

| ID | Switch | What she sees |
|---|---|---|
| M1 | AB ∥ CD off: CD tilts | ∠B + ∠D and ∠E drift apart |
| M2 | AC straight off: it bends at O | The angles at O stop matching, and so do the two sums |
| M3 | D leaves the inside of angle A | The shape turns convex, and the four angles add to 360° instead |
| M4 | DE ∥ BC off: DE tilts | BE and DE stop being equal |
| M5 | DE ∥ BC off: DE tilts | AD/AB and DE/BC stop matching |

### Knows-when problems

| ID | Problem |
|---|---|
| M1 | Two shelves are parallel. A wire leaves the top shelf at 40°, bends at a nail between the shelves, and meets the bottom shelf at 35°. Both angles are measured on the side the bend points to. What angle does it make at the nail? |
| M2 | Two sticks cross like open scissors. In the top triangle, the angles at the stick ends are 70° and 40°. In the bottom triangle, one end angle is 60°. What is the other? |
| M3 | An arrowhead kite has a 50° tip, and its back corners are 20° and 30°. What is the angle inside the notch? |
| M4 | Fold a strip of paper with parallel edges, at any angle. The overlap is a triangle with two equal sides. Which motif says why? |
| M5 | A 1.5 m stick casts a 2 m shadow. At the same moment a tree casts a 12 m shadow. How tall is the tree? (9 m) |

The device-off checks print on each card. A parent records them with one tap, as in Euclid's Workshop.

## Build order

1. This page (done).
2. Board primitives beside `ConstructionBoard`: angle arcs with values, parallel marks, a draggable free point and a break switch. Tests re-measure every check above from coordinates (done).
3. M1 end to end: question with tappable givens and goal, the break switch, and the device-off check recorded through the Euclid progress path (done).
4. M2–M5 on the same page, each with its free point and break switch (done). C1–C4 wait until Kym has used the motifs.
