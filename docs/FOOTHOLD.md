# Split it, crack one piece

The Pólya room's spine. A hard problem is usually two or three easy ones stuck together. The skill is to split it, find the one piece you can solve with only what you're given, and use that answer to open the rest. We call that piece the **foothold**.

This page holds the skill card, written before any view code, in the format of `kym_mathgames/docs/SKILL_CHAINS.md`. The worked problems live in `KymMaths/KymMaths/Features/PolyaFluency/Foothold.swift`, with tests that fail when a problem has no dead end or points at a piece that isn't there. Where this page and the code disagree, the code wins and this page gets fixed.

## Skill card

| Field | |
|---|---|
| Skill | Split and crack: find the foothold |
| She can do, device off (the check) | "10 pens and 4 notebooks cost ₹280. 10 pens and 7 notebooks cost ₹400. What does a pen cost?" She names the pieces, says which one she can crack first and why ("the 3 extra notebooks cost ₹120"), and builds back up. **A pen costs ₹12.** |
| Why it matters | Most hard exam questions are easy questions stuck together. Knowing where to start turns "I'm stuck" into "I'll start here". Outside school it is how any big job gets planned. |
| Stands on | Bar models (comparing two bars), subtraction as a difference, Pythagoras (for the stretch problem) |
| Unlocks | Simultaneous equations by elimination (the pens problem is elimination in words). The geometry composites in `docs/MOTIF_SPINE.md`, each of which is two motifs. Proof: a lemma is a foothold. |

## Two kinds of "smaller"

Children mix these up, so the room names both.

1. **A piece of the problem.** Solve one part: the speed, the gap, the cost of the extra notebooks. This is the foothold.
2. **A smaller version of the problem.** Same problem, tiny numbers: n = 1, 2, 3. This is Pólya's "simpler case". It finds a pattern, not a piece.

## Choosing the piece is the skill

Splitting is easy. Choosing is hard. A piece is a foothold only when the facts you're given are enough to solve it on its own. Two kinds of piece look tempting and aren't:

- **The piece nothing talks about alone.** Every fact ties it to something else, so there is nothing to grip.
- **The piece that isn't smaller.** It is the whole problem in different clothes.

Every worked problem below has at least one of each kind of dead end, so she practises turning a piece down.

## Three levels

1. **With the picture.** The "Find the foothold" card offers three pieces and says why each one is or isn't a foothold. *Built.*
2. **In her head.** Before the pieces appear, she writes the piece she would crack first, in her own words. The pieces stay hidden until she asks. *Built, as an optional field.*
3. **Knows when.** A bare problem with no pieces offered, and she starts in the right place. *Not built.* The four stages' prompts ("Which piece can I solve right now?") are the nearest thing.

## The four stages, with the foothold in each

| Stage | The new question |
|---|---|
| 1 Understand | What smaller questions hide inside this one? List the pieces. |
| 2 Plan | Which piece can I solve right now, with only what I'm given? Start there. |
| 3 Carry out | What did my first piece give me, and which piece does it open next? |
| 4 Look back | Did my pieces fit back together? Which piece was the key one? |

The train problem now tags each step: piece found (stage 2), piece solved, piece used, whole solved (stage 3), key piece named (stage 4).

## Worked problems

Ordered easiest first. The pens problem is the train problem's move again (compare two cases, subtract), so she meets it twice.

### F1 Two shopping bills

10 pens and 4 notebooks cost ₹280. 10 pens and 7 notebooks cost ₹400. What does a pen cost?

| Piece | Foothold? | Why |
|---|---|---|
| Find the price of a pen first | No | Both bills mix pens with notebooks. No fact talks about pens alone. |
| Compare the bills: what do the 3 extra notebooks cost? | **Yes** | The pens are the same in both bills, so the difference is only notebooks: ₹400 − ₹280 = ₹120. |
| Add the two bills together | No | 20 pens and 11 notebooks cost ₹680. That's a bigger problem with the same two unknowns, not a piece. |

Build back up. 3 notebooks cost ₹120, so 1 notebook costs ₹40. 4 notebooks cost ₹160, so 10 pens cost ₹280 − ₹160 = ₹120. **A pen costs ₹12.** Check: 10 × 12 + 7 × 40 = 120 + 280 = 400 ✓.

### F2 Father and son

A father is 3 times as old as his son. In 12 years he will be twice as old. How old are they now?

| Piece | Foothold? | Why |
|---|---|---|
| Find the father's age first | No | Every fact ties the father to the son. Nothing talks about him alone. |
| Find their ages in 12 years | No | That's the same problem moved 12 years on. It isn't smaller. |
| Find the age gap. It never changes. | **Yes** | The gap is the same now and in 12 years. That one fact links the two moments. |

Build back up. Now the son is 1 unit and the father 3 units, so the gap is 2 units. In 12 years the father is twice the son, so the gap equals the son's age then. The gap hasn't changed, so the son will be 2 units old. He is 1 unit now, so 1 unit is 12 years. **Son 12, father 36.** Check: in 12 years, 48 = 2 × 24 ✓.

### F3 A rectangle from its edge and its diagonal (stretch)

A rectangle's perimeter is 34 cm and its diagonal is 13 cm. Find its area.

| Piece | Foothold? | Why |
|---|---|---|
| Find the length and the width first | No | You might guess 12 and 5. Make the diagonal 14 cm and no neat pair works, yet the area is still easy (46.5 cm²). You don't need them. |
| Find length + width from the perimeter | **Yes** | Half the perimeter is length + width = 17. One fact, one step. |
| Get the area straight from 34 and 13 | No | No rule takes a perimeter and a diagonal straight to an area. That's the whole problem, not a piece of it. |

Build back up. Length + width = 34 ÷ 2 = 17. The diagonal makes a right triangle, so length² + width² = 13² = 169 (Pythagoras). (length + width)² = length² + width² + 2 × area, so 289 = 169 + 2 × area. **Area = 60 cm².** Check: 12 × 5 = 60, 12 + 5 = 17 and 12² + 5² = 169 ✓.
