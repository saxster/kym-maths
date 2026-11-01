# The Patterned World — Master Book Plan & Intuition-to-Formula Syllabus

**Subtitle:** *Mathematics from the Empty Set & Mumbai Monsoon to Euclid, Bayes, Calculus & Eigenvalues*  
**Audience:** Kym (Age 12, Stage 8 / Grade 7–8, Mumbai)  
**School Anchor:** *Oxford University Press — Cambridge Lower Secondary Complete Mathematics 8 (Second Edition)* by Deborah Barton (`Ch 1–16` + `Reviews A, B, C`, pp. 5–260)  
**Visual Engine:** `@saxster/atlas` (`../visualisations/atlas`) 3D/2D Paper-and-Ink Stage + Singapore CPA Bar-Model & Geometric-Symbolic Lockstep

---

## Core Pedagogical Law: Concrete Manipulation → Visual "Aha!" Invariant → Symbolic Formula

Every chapter in *The Patterned World* obeys a strict 4-stage bridge so that a formula is never a naked rule to memorize, and a visualization is never a toy that leaves Kym unable to calculate:

1. **Concrete Action (*Touch*):** Kym manipulates a geometric object, bar model, pegboard, or 3D basis vector (`draggable` on the `@saxster/atlas` stage).
2. **Visual "Aha!" Invariant (*See*):** She observes what stays constant while everything else moves (e.g., shearing a card deck preserves base $\times$ height; slicing a parallelogram makes a rectangle; folding the two leg-squares onto the hypotenuse square covers $\sin^2\theta + \cos^2\theta = 1$).
3. **Colour-Locked Formula Anatomy (*Translate*):** Every symbol in the equation is colour-matched to the exact geometric piece that generates it:
   - **Red (`--proton`):** Vertical / active / numerator / first basis column $A\hat{\imath}$ / $\sin\theta$ / $\Delta y$ / True Positives.
   - **Blue (`--electron`):** Horizontal / reference / second basis column $A\hat{\jmath}$ / $\cos\theta$ / step $h$ / Riemann strips.
   - **Amber (`--ochre`):** Interaction / area / error / false-positive term / $\det(A) = ad - bc$.
   - **Green (`--green`):** Invariant axis / equilibrium / eigenvector $A\mathbf{v} = \lambda\mathbf{v}$.
4. **Symbolic Power (*Calculate & Generalise*):** Kym uses the earned formula forward, backward (changing the subject), and at extreme limits ($h \to 0$, $\det \to 0$, $\theta \to 90^\circ$).

---

## 5 Volumes · 21 Chapters (`Ch 0` – `Ch 20`)

### Volume I — The Grammar of Truth, Sets & Number Architecture
- **Ch 0:** *Sets, Venn Regions & The Laws of Thought* (Set Theory $\cup, \cap, A', \varnothing, \mathcal{P}(A)$, Inclusion–Exclusion $|A\cup B| = |A| + |B| - |A\cap B|$, Propositional Logic $p \Rightarrow q$, Contrapositive, De Morgan's Laws)
- **Ch 1:** *The Directed Number Line, Primes & The Laws of Indices* (OUP Ch 1: `1.1–1.6`, negative multiplication rotation proof, prime factor trees, HCF $\times$ LCM $= ab$, index laws, $\sqrt{2}$ irrationality proof)
- **Ch 2:** *Fractions, Recurring Decimals & The Scaling Engine* (OUP Ch 6: `6.1–6.5`, decimal shift invariant, $10^k x - x$ algebraic proof for recurring decimals, reciprocal area division)
- **Ch 3:** *Ratios, Percentages & Exponential Compounding* (OUP Ch 9 `9.1–9.4` & Ch 12 `12.1–12.4`, Singapore Unitary Bar Model, sequential multipliers, `@saxster/atlas` `economics/compound` ₹1,000/month machine)

### Volume II — The Singapore Bar-Model & Algebraic Machine
- **Ch 4:** *From Bar Models to Algebraic Expressions* (OUP Ch 2: `2.1–2.4`, area-array distributive law $a(b+c)=ab+ac$, HCF factorisation, difference of two squares $a^2-b^2=(a-b)(a+b)$)
- **Ch 5:** *The Balance Beam: Equations, Formulae & Inequalities* (OUP Ch 7: `7.1–7.4`, inverse-operation onion peeling, changing the subject of a formula, inequality sign-flip on multiplying by $-1$)
- **Ch 6:** *Patterns in Time: Sequences, $n$th Terms & Gauss's Sum* (OUP Ch 11: `11.1–11.2`, first differences = slope $d$, second differences = $2a$ quadratic sequences, Gauss's $180^\circ$-rotated staircase $S_n = \frac{n}{2}(a_1+a_n)$)
- **Ch 7:** *Functions, Linear Graphs & Kinematics* (OUP Ch 14: `14.1–14.3`, $y = mx + c$, gradient $m = \Delta y/\Delta x$, distance-time & speed-time area/slope duality)

### Volume III — Euclid's Compass, Mensuration & Trigonometry
- **Ch 8:** *Angle Chasing, Parallel Lines & Deductive Proof* (OUP Ch 8: `8.1–8.3`, Z/F/C parallel angle invariants, exterior angle theorem $\ext = \alpha + \beta$, midpoint vector average)
- **Ch 9:** *Compass & Straightedge: Locus, Quadrilaterals & 3D Nets* (OUP Ch 3: `3.1–3.5`, equidistant circle-intersection loci, perpendicular & angle bisectors, 3-figure bearings, Euler's $V - E + F = 2$)
- **Ch 10:** *Slicing Space: Circles, Prisms, Pyramids & Archimedes' $\pi$* (OUP Ch 5: `5.1–5.5`, unrolling $C = 2\pi r$, alternating sector rearrangement $A = \pi r^2$, shear-invariant parallelogram & trapezium area, prism & pyramid volumes)
- **Ch 11:** *Symmetry & Motion: Translations, Reflections, Rotations & Enlargements* (OUP Ch 13: `13.1–13.5`, rigid isometries vs. similarity scale factor $k$, area scaling by $k^2$, volume scaling by $k^3$)
- **Ch 12:** *Shadows of the Circle: Pythagoras, Sine, Cosine & Radians* (`@saxster/atlas` `maths/unit-circle`: Garfield's trapezium proof of $a^2+b^2=c^2$, SOHCAHTOA, unit-circle shadows $\sin\theta, \cos\theta, \tan\theta$, $\sin^2\theta+\cos^2\theta=1$, radian arc $s=r\theta$, Sine & Cosine Rules)

### Volume IV — Data Forensics, Uncertainty & Bayes' Theorem
- **Ch 13:** *How Not to Be Fooled by a Sample* (OUP Ch 4: `4.1–4.2`, census vs. sample, simple random/stratified/systematic sampling, Abraham Wald's survivorship-bias bomber plot, `@saxster/atlas` `statistics/error` $\sigma/\sqrt{n}$)
- **Ch 14:** *Seeing the Distribution: Histograms, Spread & Standard Deviation* (OUP Ch 10: `10.1–10.4`, time-series moving averages, back-to-back stem-and-leaf, frequency density = frequency $\div$ class width, variance & $\sigma$)
- **Ch 15:** *Counting Worlds: Sample Spaces, Permutations & Combinations* (OUP Ch 15: `15.1–15.4`, `@saxster/atlas` `statistics/galton` 500-ball binomial board, $n!$, ${}^nP_r$, ${}^nC_r$, Pascal's triangle)
- **Ch 16:** *Updating Belief: Conditional Probability & Bayes' Theorem* (`@saxster/atlas` `statistics/bayes` & `statistics/hypothesis`: 1,000-person unit-square partition, $P(A\mid B) = \frac{P(B\mid A)P(A)}{P(B)}$, base-rate fallacy, likelihood ratios)

### Volume V — The Horizon: Calculus, Vectors & Linear Algebra
- **Ch 17:** *Zooming In Forever: Limits, Secants & Derivatives* (`@saxster/atlas` `maths/calculus` pp. 0–2: secant slope $\frac{f(x+h)-f(x)}{h} \to f'(x)$, power rule $\frac{d}{dx}(x^n)=nx^{n-1}$ from rectangle growth, stationary points $f'(x)=0$)
- **Ch 18:** *Slicing to Infinity: Riemann Sums & The Fundamental Theorem of Calculus* (`@saxster/atlas` `maths/calculus` pp. 3–5: midpoint Riemann bars, $\int_a^b f'(t)\,dt = f(b)-f(a)$ why slope and area are inverses)
- **Ch 19:** *Arrows in Space: Vectors, Dot Products & Geometric Proofs* (OUP Ch 16 Bonus Chapter: `16.1–16.2`, column vectors $\binom{x}{y}$, triangle law $\vec{AB}+\vec{BC}=\vec{AC}$, magnitude $|\mathbf{v}|=\sqrt{x^2+y^2}$, dot product $\mathbf{u}\cdot\mathbf{v}=|\mathbf{u}||\mathbf{v}|\cos\theta$, midpoint/centroid vector proofs)
- **Ch 20:** *Stretching the Plane: $2\times 2$ Matrices, Determinants & Eigenvectors* (`@saxster/atlas` `maths/linear-algebra` & `maths/matrix-sandbox`: basis columns $A\hat{\imath}, A\hat{\jmath}$, determinant area scale $\det(A)=ad-bc$, singular collapse $\det=0$, invariant eigen-axes $A\mathbf{v}=\lambda\mathbf{v}$)
