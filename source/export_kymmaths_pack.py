#!/usr/bin/env python3
"""
export_kymmaths_pack.py
Compiles the KymMaths Seed Pack (`kymmaths-seed-pack.json`) and Interactive Book
(`Resources/PatternedWorldBook/index.html`), bridging:
1. OUP Cambridge Lower Secondary Complete Mathematics 8 (2nd Ed.) by Deborah Barton (Ch 1-16 + Reviews A, B, C)
2. 3-Tier Built-In Singapore & Checkpoint Companion Workbook (solving the missing school workbook)
3. The Patterned World (5 Volumes, 21 Chapters Ch 0-20: Set Theory & Logic -> Number -> Singapore Algebra ->
   Euclid & Trig -> Data & Bayes -> Calculus, Vectors & Linear Algebra)
4. @saxster/atlas (`../visualisations/atlas`) 3D/2D figures + Intuition -> "Aha!" -> Symbolic Formula bridges
"""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PACK_OUT = ROOT / "KymMaths" / "KymMaths" / "Resources" / "ContentPacks" / "kymmaths-seed-pack.json"
BOOK_OUT = ROOT / "KymMaths" / "KymMaths" / "Resources" / "PatternedWorldBook" / "index.html"


def build_volumes():
    return [
        {
            "id": "vol-1",
            "number": 1,
            "title": "Volume I · The Grammar of Truth, Sets & Number Architecture",
            "chapters": [0, 1, 2, 3],
        },
        {
            "id": "vol-2",
            "number": 2,
            "title": "Volume II · The Singapore Bar-Model & Algebraic Machine",
            "chapters": [4, 5, 6, 7],
        },
        {
            "id": "vol-3",
            "number": 3,
            "title": "Volume III · Euclid's Compass, Mensuration & Trigonometry",
            "chapters": [8, 9, 10, 11, 12],
        },
        {
            "id": "vol-4",
            "number": 4,
            "title": "Volume IV · Data Forensics, Uncertainty & Bayes' Theorem",
            "chapters": [13, 14, 15, 16],
        },
        {
            "id": "vol-5",
            "number": 5,
            "title": "Volume V · The Horizon: Calculus, Vectors & Linear Algebra",
            "chapters": [17, 18, 19, 20],
        },
    ]


def build_chapters():
    raw_specs = [
        (
            0, 1, "Sets, Venn Regions & The Laws of Thought",
            "Set builder notation, Venn partitions, Inclusion–Exclusion, truth tables & De Morgan's duality",
            "Before you calculate with numbers, you classify objects into sets and test statements for truth.",
            "Drag two overlapping circles A and B across a universal set ξ of 30 Mumbai students.",
            "The overlap A ∩ B gets counted once inside |A| and a second time inside |B| — subtracting |A ∩ B| once restores the exact union count!",
            "n(A ∪ B) = n(A) + n(B) − n(A ∩ B)   and   (A ∪ B)′ = A′ ∩ B′",
            [
                {"symbol": "n(A) + n(B)", "visualPart": "Red circle A + Blue circle B", "colorRole": "red", "meaning": "Sum of both circles (double-counts the centre lens)"},
                {"symbol": "− n(A ∩ B)", "visualPart": "Amber centre lens overlap", "colorRole": "amber", "meaning": "Removes the duplicate count of the intersection"},
                {"symbol": "(A ∪ B)′ = A′ ∩ B′", "visualPart": "Green exterior courtyard", "colorRole": "green", "meaning": "Outside both circles equals outside A AND outside B (De Morgan)"}
            ],
            "concepts/index.html#maths",
            ["Set", "Subset ⊆", "Union ∪", "Intersection ∩", "Complement A′", "Power Set P(A)", "Implication p ⇒ q", "Contrapositive ¬q ⇒ ¬p", "De Morgan's Laws"],
            ["w_venn_inclusion_exclusion", "w_truth_table_logic_gates", "w_quantifier_counterexample"]
        ),
        (
            1, 1, "The Directed Number Line, Primes & The Laws of Indices",
            "OUP Ch 1 · Negative integer rotation, prime factor trees, HCF × LCM = ab, index laws & √2 irrationality",
            "Multiplying by −1 is a 180° half-turn on the number line; two half-turns bring you back to positive.",
            "Rotate a vector on the number line by 180° for each negative sign, and stack prime-exponent bars for HCF and LCM.",
            "Two 180° rotations equal 360° (+1), and for any two integers a and b, taking min(exponents) for HCF and max(exponents) for LCM guarantees min + max = total!",
            "(−a)(−b) = +ab,   aᵐ · aⁿ = aᵐ⁺ⁿ,   HCF(a, b) × LCM(a, b) = a × b",
            [
                {"symbol": "−1 × −1 = +1", "visualPart": "Two 180° arc turns on the number line", "colorRole": "red", "meaning": "Reversing a reversal restores forward direction"},
                {"symbol": "HCF(a,b)", "visualPart": "Blue shared prime-factor overlap A ∩ B", "colorRole": "blue", "meaning": "Product of lowest shared prime powers"},
                {"symbol": "LCM(a,b)", "visualPart": "Amber full prime-factor union A ∪ B", "colorRole": "amber", "meaning": "Product of highest prime powers across both numbers"}
            ],
            "concepts/index.html#exponential",
            ["Integer", "Directed Number", "Prime Factorisation", "HCF", "LCM", "Index Laws", "Zero & Negative Indices", "Rational vs Irrational (√2)"],
            ["w_negative_rotation_line", "w_prime_venn_hcf_lcm", "w_index_staircase_surds"]
        ),
        (
            2, 1, "Fractions, Recurring Decimals & The Scaling Engine",
            "OUP Ch 6 · Multiplying & dividing fractions, significant figures & 10ᵏx − x recurring decimal proofs",
            "Dividing by a fraction a/b asks how many b-sized pieces fit inside — which scales by b/a.",
            "Slide a 10ᵏ multiplier bar against a repeating decimal tail 0.ababab… and watch the infinite tails align.",
            "Multiplying x = 0.abab… by 10ᵏ shifts the decimal point by one full period k, so subtracting x cancels the entire infinite tail in one stroke!",
            "x = 0.d₁d₂…dₖ (repeating)  ⇒  (10ᵏ − 1)x = d₁d₂…dₖ  ⇒  x = d₁d₂…dₖ / (10ᵏ − 1)",
            [
                {"symbol": "10ᵏ x", "visualPart": "Red shifted bar with whole period ahead of decimal", "colorRole": "red", "meaning": "Shifts repeating block k places left"},
                {"symbol": "− x", "visualPart": "Blue original infinite tail", "colorRole": "blue", "meaning": "Identical infinite tail after the decimal point cancels to 0"},
                {"symbol": "10ᵏ − 1", "visualPart": "Green denominator of k nines (9, 99, 999)", "colorRole": "green", "meaning": "Exact rational denominator"}
            ],
            "concepts/index.html#maths",
            ["Recurring Decimal", "Terminating Decimal", "Significant Figures", "Reciprocal", "Mixed Numbers", "Area Fraction Model"],
            ["w_recurring_decimal_tail_canceller", "w_fraction_area_division"]
        ),
        (
            3, 1, "Ratios, Percentages & Exponential Compounding",
            "OUP Ch 9 & Ch 12 · Singapore unitary bar models, percentage multipliers & 20-year rupee compounding",
            "A percentage change is a multiplicative scale factor (1 ± r); repeated changes multiply, they never add.",
            "Run the @saxster/atlas ₹1,000/month at 8% machine over 20 years and compare white savings, red simple interest, and amber compound interest.",
            "A +20% rise followed by a −20% drop lands at 1.2 × 0.8 = 0.96 (a 4% loss!), while compounding multiplies by (1 + r)ⁿ so interest itself earns interest!",
            "A(n) = P(1 + r)ⁿ,   Ratio shareᵢ = Total × (wᵢ / ∑ wⱼ)",
            [
                {"symbol": "P", "visualPart": "Blue initial principal bar", "colorRole": "blue", "meaning": "Starting value (100% reference unit)"},
                {"symbol": "(1 + r)ⁿ", "visualPart": "Red & Amber compounding stack columns", "colorRole": "amber", "meaning": "Exponential multiplier over n periods"},
                {"symbol": "wᵢ / ∑ wⱼ", "visualPart": "Green unitary bar-model box", "colorRole": "green", "meaning": "Value of 1 equal unit × k parts"}
            ],
            "economics/compound/index.html",
            ["Unitary Method", "Ratio Partition", "Percentage Multiplier", "Reverse Percentage", "Compound Growth", "Rule of 72"],
            ["w_singapore_ratio_bar_model", "w_compound_multiplier_machine"]
        ),
        (
            4, 2, "From Bar Models to Algebraic Expressions",
            "OUP Ch 2 · Expanding brackets, factorising by HCF, quadratics & Difference of Two Squares",
            "An algebraic bracket a(b + c) is the area of a rectangle of height a and split width b + c.",
            "Tile a partitioned rectangle of sides (x + a) and (x + b), or snip the corner b² from a square a².",
            "When you cut a corner square b² from a² and rotate the remaining strip, it forms a single rectangle of length (a + b) and height (a − b)!",
            "a(b + c) = ab + ac,   (x + a)(x + b) = x² + (a + b)x + ab,   a² − b² = (a − b)(a + b)",
            [
                {"symbol": "x²", "visualPart": "Red main square tile (x by x)", "colorRole": "red", "meaning": "Quadratic core area"},
                {"symbol": "(a + b)x", "visualPart": "Blue flanking rectangles ax and bx", "colorRole": "blue", "meaning": "Linear cross-terms (why (x+a)² ≠ x² + a²!)"},
                {"symbol": "ab", "visualPart": "Amber corner rectangle (a by b)", "colorRole": "amber", "meaning": "Constant product corner"}
            ],
            "concepts/index.html#maths",
            ["Expression", "Term", "Coefficient", "Distributive Law", "Expanding", "Factorising", "Difference of Two Squares"],
            ["w_algebra_area_tiles", "w_difference_of_squares_slicer"]
        ),
        (
            5, 2, "The Balance Beam: Equations, Formulae & Inequalities",
            "OUP Ch 7 · Deriving & solving equations, changing the subject of a formula & inequality number lines",
            "An equation is a balanced beam; changing the subject of a formula peels the onion of operations in reverse order.",
            "Drag weights off a twin-pan balance and flip an inequality interval across 0 by multiplying by −1.",
            "Multiplying a number line by −1 reflects every point across 0 like a mirror — what was further right (>) becomes further left (<)!",
            "ax + b = cx + d  ⇒  x = (d − b) / (a − c),   and   a < b  ⇒  −a > −b",
            [
                {"symbol": "ax − cx", "visualPart": "Red variable bars gathered on left pan", "colorRole": "red", "meaning": "Net unknown units (a − c)x"},
                {"symbol": "d − b", "visualPart": "Blue constant weights on right pan", "colorRole": "blue", "meaning": "Net constant value"},
                {"symbol": "a < b ⇒ −a > −b", "visualPart": "Amber mirror reflection across 0", "colorRole": "amber", "meaning": "Order reverses under negative reflection"}
            ],
            "concepts/index.html#balance",
            ["Equation", "Formula", "Subject of a Formula", "Inverse Operation", "Open vs Closed Circle", "Inequality Flip"],
            ["w_balance_beam_equations", "w_formula_subject_transposer", "w_inequality_mirror_line"]
        ),
        (
            6, 2, "Patterns in Time: Sequences, nth Terms & Gauss's Sum",
            "OUP Ch 11 · Term-to-term vs position-to-term rules, linear & quadratic sequences, and Gauss's staircase",
            "A constant first difference means a linear staircase dn + c; a constant second difference 2a means a quadratic parabola an² + bn + c.",
            "Duplicate an n-step staircase 1 + 2 + … + n, rotate the copy by 180°, and snap it on top of the original.",
            "The two staircases lock together into a solid rectangle of width n and uniform height (n + 1) — so one staircase is exactly half the rectangle!",
            "Tₙ = a₁ + (n − 1)d,   Sₙ = ½ n (a₁ + aₙ),   Quadratic 2nd diff = 2a",
            [
                {"symbol": "d", "visualPart": "Red step riser between consecutive terms", "colorRole": "red", "meaning": "Constant first difference (linear slope)"},
                {"symbol": "a₁ + aₙ", "visualPart": "Blue combined height of flipped Gauss staircase", "colorRole": "blue", "meaning": "First term plus last term in every column"},
                {"symbol": "½ n", "visualPart": "Green half-rectangle area factor", "colorRole": "green", "meaning": "n columns divided by 2 identical staircases"}
            ],
            "concepts/index.html#maths",
            ["Sequence", "Term-to-Term", "nth Term Tₙ", "First Difference", "Second Difference", "Arithmetic Series", "Fibonacci & Golden Ratio"],
            ["w_gauss_staircase_sum", "w_sequence_difference_engine"]
        ),
        (
            7, 2, "Functions, Linear Graphs & Kinematics",
            "OUP Ch 14 · Function machines, y = mx + c, gradient Δy/Δx, parallel/perpendicular lines & speed-time graphs",
            "Every straight line is a constant rate of change m = Δy / Δx anchored at a vertical intercept c.",
            "Slide two points P and Q along a line y = mx + c and inspect the right-angled rise/run staircase.",
            "No matter how wide or narrow you make the horizontal run Δx, the vertical rise Δy scales in the exact same proportion, keeping Δy / Δx = m invariant!",
            "y = mx + c,   m = (y₂ − y₁) / (x₂ − x₁),   m₁ · m₂ = −1 (perpendicular)",
            [
                {"symbol": "Δy = y₂ − y₁", "visualPart": "Red vertical rise segment", "colorRole": "red", "meaning": "Signed vertical change"},
                {"symbol": "Δx = x₂ − x₁", "visualPart": "Blue horizontal run segment", "colorRole": "blue", "meaning": "Signed horizontal step"},
                {"symbol": "c", "visualPart": "Green y-axis crossing (0, c)", "colorRole": "green", "meaning": "Starting value when x = 0"}
            ],
            "concepts/index.html#slope",
            ["Function f(x)", "Gradient m", "y-Intercept c", "x-Intercept", "Parallel Lines", "Perpendicular Gradient −1/m", "Travel Graphs"],
            ["w_linear_graph_slope_explorer", "w_kinematics_travel_graph"]
        ),
        (
            8, 3, "Angle Chasing, Parallel Lines & Deductive Proof",
            "OUP Ch 8 · Alternate, corresponding & co-interior angles, exterior angle of a triangle & midpoint formula",
            "A transversal slicing two parallel lines carries the exact same 4-angle intersection down the track.",
            "Slide the top intersection along a transversal onto the bottom parallel line, and tear the two base angles α, β off a triangle to place them into the exterior angle.",
            "Because a parallel translation changes no angles, α and β fit flush inside the exterior angle next to γ — proving both α + β + γ = 180° and ext = α + β at once!",
            "θ_ext = α + β,   ∑ interior angles of n-gon = (n − 2) × 180°,   M = ((x₁+x₂)/2, (y₁+y₂)/2)",
            [
                {"symbol": "α + β", "visualPart": "Red + Blue remote interior angles translated along parallel line", "colorRole": "red", "meaning": "Fit exactly into the exterior angle"},
                {"symbol": "(n − 2) × 180°", "visualPart": "Amber fan of (n − 2) non-overlapping triangles from one vertex", "colorRole": "amber", "meaning": "Every n-gon triangulates into n − 2 triangles"},
                {"symbol": "((x₁+x₂)/2, (y₁+y₂)/2)", "visualPart": "Green midpoint of the bounding coordinate box", "colorRole": "green", "meaning": "Average of endpoints on each axis"}
            ],
            "concepts/index.html#maths",
            ["Alternate (Z) Angles", "Corresponding (F) Angles", "Co-interior (C) Angles", "Exterior Angle Theorem", "Polygon Triangulation", "Midpoint"],
            ["w_parallel_transversal_proof", "w_exterior_angle_tear_proof"]
        ),
        (
            9, 3, "Compass & Straightedge: Locus, Quadrilaterals & 3D Nets",
            "OUP Ch 3 · Quadrilateral hierarchy, 3D nets & elevations, 3-figure bearings & Euclidean locus constructions",
            "A circle is the locus of points at a fixed distance from one point; two equal circles intersect on the locus equidistant from two points.",
            "Sweep two equal-radius compass arcs from endpoints A and B and connect their intersections P and Q.",
            "Because AP = BP = AQ = BQ = r, the four radii form a rhombus — and the diagonals of a rhombus always bisect each other at 90°!",
            "|PA| = |PB|  ⇔  P lies on perpendicular bisector of AB;   Euler: V − E + F = 2",
            [
                {"symbol": "|PA| = |PB| = r", "visualPart": "Red & Blue equal compass radii from A and B", "colorRole": "red", "meaning": "Rhombus side invariant"},
                {"symbol": "000°–360°", "visualPart": "Amber clockwise bearing arc from North", "colorRole": "amber", "meaning": "Back-bearing differs by ±180°"},
                {"symbol": "V − E + F = 2", "visualPart": "Green 3D polyhedron net topology", "colorRole": "green", "meaning": "Euler characteristic of any convex polyhedron"}
            ],
            "concepts/index.html#maths",
            ["Locus", "Perpendicular Bisector", "Angle Bisector", "SSS / SAS / ASA Triangle Construction", "3-Figure Bearing", "Plan & Elevation", "Euler's Formula"],
            ["w_euclid_compass_locus", "w_bearings_back_bearing_radar", "w_polyhedron_net_folder"]
        ),
        (
            10, 3, "Slicing Space: Circles, Prisms, Pyramids & Archimedes' π",
            "OUP Ch 5 · Circumference, circle area sector rearrangement, parallelogram/trapezium shear & prism/pyramid volumes",
            "Every area and volume formula comes from slicing a curved or slanted shape into a familiar box.",
            "Slice a circle of radius r into 24 sectors and comb-interlock them head-to-tail into a nearly rectangular parallelogram.",
            "Half the circumference (πr) runs along the top and half along the bottom (base = πr), while the radius r stands upright as the height — giving Area = (πr) × r = πr²!",
            "C = 2πr,   A_circle = πr²,   A_trap = ½(a + b)h,   V_prism = A_cross × L",
            [
                {"symbol": "πr", "visualPart": "Blue bottom scalloped arc of comb-interlocked sectors", "colorRole": "blue", "meaning": "Half of circumference 2πr"},
                {"symbol": "r", "visualPart": "Red upright sector radius", "colorRole": "red", "meaning": "Height of the rearranged rectangle"},
                {"symbol": "½(a + b)h", "visualPart": "Green doubled-trapezium parallelogram of base (a + b)", "colorRole": "green", "meaning": "Two identical trapeziums form a parallelogram of base a + b"}
            ],
            "concepts/index.html#circle",
            ["Circumference", "Pi (π)", "Sector Rearrangement", "Cavalieri's Shear Principle", "Trapezium", "Triangular Prism Volume", "Surface Area Net"],
            ["w_circle_sector_rearranger", "w_trapezium_prism_slicer"]
        ),
        (
            11, 3, "Symmetry & Motion: Translations, Reflections, Rotations & Enlargements",
            "OUP Ch 13 · Vector translations, mirror lines, rotational symmetry & enlargement area/volume scaling (k, k², k³)",
            "Translations, reflections, and rotations are rigid isometries; enlargements scale lengths by k, areas by k², and volumes by k³.",
            "Drag the centre of enlargement C and scale factor slider k from −2 to +3 on a coordinate grid.",
            "Every vertex P moves along the ray CP so that |CP′| = |k| · |CP| — and doubling every side (k = 2) packs k² = 4 copies of the original triangle inside the image!",
            "OP′ − OC = k(OP − OC),   Area(Image) = k² · Area(Object),   Vol(Image) = k³ · Vol(Object)",
            [
                {"symbol": "k(OP − OC)", "visualPart": "Red ray vector from centre C to image P′", "colorRole": "red", "meaning": "Multiplies distance from centre of enlargement by k"},
                {"symbol": "k²", "visualPart": "Amber tiled sub-triangles inside enlarged shape", "colorRole": "amber", "meaning": "2D area scales as the square of linear factor k"},
                {"symbol": "k < 0", "visualPart": "Blue inverted ray through centre C", "colorRole": "blue", "meaning": "Negative scale factor enlarges and rotates by 180°"}
            ],
            "maths/linear-algebra/index.html#1",
            ["Isometry", "Translation Vector", "Reflection Line", "Centre of Rotation", "Centre of Enlargement", "Fractional & Negative Scale Factor", "Area Scale k²"],
            ["w_transformation_isometry_stage", "w_enlargement_ray_scaler"]
        ),
        (
            12, 3, "Shadows of the Circle: Pythagoras, Sine, Cosine & Radians",
            "Advanced Geometry & Trig · @saxster/atlas unit-circle (8 pages): Pythagoras, SOHCAHTOA, unit-circle shadows, radians & Cosine Rule",
            "Sine is the vertical shadow of a turning point on the unit circle; cosine is its horizontal shadow.",
            "Open the @saxster/atlas 3D Unit Circle stage: shine level light from the right for sin θ, top light for cos θ, and unfold the three squares on the right triangle.",
            "Because the hypotenuse of the unit-circle triangle is 1, the red vertical shadow is sin θ, the blue horizontal shadow is cos θ, and Pythagoras immediately gives sin²θ + cos²θ = 1² for every angle!",
            "P = (cos θ, sin θ),   sin²θ + cos²θ = 1,   tan θ = sin θ / cos θ,   c² = a² + b² − 2ab cos C",
            [
                {"symbol": "sin θ", "visualPart": "Red vertical shadow bar cast by level light", "colorRole": "red", "meaning": "y-coordinate of P on unit circle (Opposite / Hypotenuse)"},
                {"symbol": "cos θ", "visualPart": "Blue horizontal shadow bar cast by top light", "colorRole": "blue", "meaning": "x-coordinate of P on unit circle (Adjacent / Hypotenuse)"},
                {"symbol": "sin²θ + cos²θ = 1", "visualPart": "Red square + Blue square folding onto Grey radius square", "colorRole": "amber", "meaning": "Pythagorean identity on the unit circle"}
            ],
            "maths/unit-circle/index.html",
            ["Pythagoras' Theorem", "Unit Circle", "Sine (sin θ)", "Cosine (cos θ)", "Tangent (tan θ)", "Radian (s = rθ)", "Pythagorean Identity", "Sine & Cosine Rules"],
            ["w_atlas_unit_circle", "w_pythagoras_garfield_proof", "w_cosine_rule_generaliser"]
        ),
        (
            13, 4, "How Not to Be Fooled by a Sample",
            "OUP Ch 4 · Sampling methods, bias forensics, Abraham Wald's bombers & @saxster/atlas σ/√n standard error",
            "A huge biased sample is worse than a small random one; repeated random samples cluster within ±σ / √n of the truth.",
            "Run the @saxster/atlas Repeated Readings Explorer (`statistics/error`) and toggle survivorship filter on Wald's WWII aircraft.",
            "Bullet holes on returning planes show where a plane can be hit and still fly home — the missing holes on the engines mark where fatal hits occurred!",
            "Stratified nᵢ = n × (Nᵢ / N),   Standard Error SE = σ / √n",
            [
                {"symbol": "Nᵢ / N", "visualPart": "Blue stratum share of total population", "colorRole": "blue", "meaning": "Proportional representation weight"},
                {"symbol": "σ / √n", "visualPart": "Red shrinking standard-error bracket around true mean μ", "colorRole": "red", "meaning": "Quadrupling sample size n halves the error bar"},
                {"symbol": "Selection Bias", "visualPart": "Amber missing-data ghost region (Wald's engine armour)", "colorRole": "amber", "meaning": "Unobserved dropouts skew naive averages"}
            ],
            "statistics/error/index.html",
            ["Population vs Sample", "Simple Random Sample", "Stratified Sample", "Systematic Sample", "Survivorship Bias", "Standard Error σ/√n"],
            ["w_atlas_sampling_error", "w_wald_survivorship_bomber"]
        ),
        (
            14, 4, "Seeing the Distribution: Histograms, Spread & Standard Deviation",
            "OUP Ch 10 · Time-series trends, back-to-back stem-and-leaf, frequency-density histograms, IQR & standard deviation σ",
            "In a true histogram, the area of each bar — not its height — represents frequency.",
            "Change the width Δx of a histogram class interval and watch the bar height adjust so its area stays equal to frequency f.",
            "If one class interval is twice as wide as another, keeping the bar at raw frequency makes it look twice as big by accident — dividing height by class width (Frequency Density = f / Δx) makes Area = FD × Δx = f exact!",
            "Frequency Density = f / Δx,   μ = (∑ xᵢ) / n,   σ = √[ (∑(xᵢ − μ)²) / n ]",
            [
                {"symbol": "f / Δx", "visualPart": "Red bar height (Frequency Density)", "colorRole": "red", "meaning": "Customers per unit width"},
                {"symbol": "FD × Δx = f", "visualPart": "Blue bar area", "colorRole": "blue", "meaning": "Area of rectangle equals exact count f"},
                {"symbol": "σ", "visualPart": "Amber root-mean-square deviation arms from balance fulcrum μ", "colorRole": "amber", "meaning": "Typical distance of data points from the mean"}
            ],
            "statistics/hypothesis/index.html",
            ["Time Series", "Moving Average", "Back-to-Back Stem-and-Leaf", "Frequency Density", "Interquartile Range (IQR)", "Variance & Standard Deviation σ"],
            ["w_histogram_frequency_density", "w_mean_fulcrum_std_dev"]
        ),
        (
            15, 4, "Counting Worlds: Sample Spaces, Permutations & Combinations",
            "OUP Ch 15 · Experimental vs theoretical probability, sample-space grids, @saxster/atlas Galton board, nPr & nCr",
            "Drop 500 balls through rows of 50/50 pegs and binomial combinations C(n, k) build the normal bell curve before your eyes.",
            "Open the @saxster/atlas Galton Pegboard Explorer (`statistics/galton`): predict the slot distribution and drop 500 seeded balls.",
            "To land in slot k after n peg rows, a ball must bounce right k times and left (n − k) times — the number of distinct paths is Pascal's combination C(n, k) = n! / [k!(n − k)!]!",
            "P(A ∩ B) = P(A) · P(B),   ⁿPᵣ = n! / (n − r)!,   ⁿCᵣ = n! / [r!(n − r)!]",
            [
                {"symbol": "n! / (n − r)!", "visualPart": "Red ordered slot choices n × (n−1) × …", "colorRole": "red", "meaning": "Permutations when order matters"},
                {"symbol": "÷ r!", "visualPart": "Blue collapse of r! identical rearrangements", "colorRole": "blue", "meaning": "Divides out order to count combinations C(n,r)"},
                {"symbol": "C(n,k) pᵏ(1−p)ⁿ⁻ᵏ", "visualPart": "Amber Galton pegboard bell column k", "colorRole": "amber", "meaning": "Exact binomial probability of k successes in n trials"}
            ],
            "statistics/galton/index.html",
            ["Sample Space", "Mutually Exclusive", "Independent Events", "Tree Diagram", "Factorial n!", "Permutation nPr", "Combination nCr", "Galton Board & CLT"],
            ["w_atlas_galton_board", "w_combinatorics_tree_builder"]
        ),
        (
            16, 4, "Updating Belief: Conditional Probability & Bayes' Theorem",
            "Advanced Probability · @saxster/atlas Bayes Explorer: why a 95% accurate test on a 2% condition is right only 28% of the time",
            "Evidence never acts in a vacuum — it slices and renormalizes the prior base rate inside a 1,000-person unit square.",
            "Open the @saxster/atlas Bayes Unit-Square Explorer (`statistics/bayes`): set prevalence p = 2%, sensitivity = 95%, false-positive rate = 5%, and screen 1,000 people.",
            "Conditioning on a positive test throws away everyone who tested negative! What remains is just two bars: 19 True Positives (red) from the 20 sick people, and 49 False Positives (amber) from the 980 healthy people — so P(D | +) = 19 / (19 + 49) ≈ 27.9%!",
            "P(D | +) = [ P(+ | D) P(D) ] / [ P(+ | D) P(D) + P(+ | ¬D) P(¬D) ]",
            [
                {"symbol": "P(+ | D) P(D)", "visualPart": "Red True-Positive rectangle (19 of 1,000)", "colorRole": "red", "meaning": "Sick people correctly flagged positive"},
                {"symbol": "P(+ | ¬D) P(¬D)", "visualPart": "Amber False-Positive rectangle (49 of 1,000)", "colorRole": "amber", "meaning": "Healthy people falsely flagged positive"},
                {"symbol": "Red / (Red + Amber)", "visualPart": "Isolated posterior bar on the right of the 3D board", "colorRole": "green", "meaning": "Share of all positive tests that are genuinely sick"}
            ],
            "statistics/bayes/index.html",
            ["Prior Probability P(D)", "Sensitivity P(+|D)", "Specificity", "False Positive P(+|¬D)", "Posterior Probability P(D|+)", "Base-Rate Fallacy", "Likelihood Ratio"],
            ["w_atlas_bayes_square", "w_bayes_natural_frequency_tree"]
        ),
        (
            17, 5, "Zooming In Forever: Limits, Secants & Derivatives",
            "Advanced Calculus I · @saxster/atlas Calculus (pp. 0–2): secant slope to tangent limit, power rule & stationary points",
            "A curve looks straight when you zoom in; its derivative f′(x) is the limit of the secant slope as step h shrinks to zero.",
            "Open @saxster/atlas Calculus (`maths/calculus` pp. 0–2) and slide point Q toward P(1, ½) on f(x) = ½x², or expand a square of side x by dx.",
            "Expanding a square x² by tiny strip dx adds two long strips of area x·dx and a tiny corner (dx)² — dividing Δ(x²)/dx = 2x + dx and letting dx → 0 leaves the exact derivative 2x!",
            "f′(x) = lim_{h→0} [f(x + h) − f(x)] / h,   d/dx (xⁿ) = n xⁿ⁻¹",
            [
                {"symbol": "f(x + h) − f(x)", "visualPart": "Red vertical rise segment Δy between P and Q", "colorRole": "red", "meaning": "Change in height across step h"},
                {"symbol": "h", "visualPart": "Blue horizontal run step", "colorRole": "blue", "meaning": "Step width shrinking toward 0"},
                {"symbol": "f′(x) = 0", "visualPart": "Green level tangent at cubic peak (0, 2) and trough (2, ⅔)", "colorRole": "green", "meaning": "Stationary points (maxima and minima)"}
            ],
            "maths/calculus/index.html",
            ["Limit", "Secant Line", "Tangent Line", "Derivative dy/dx", "Power Rule nxⁿ⁻¹", "Stationary Point f′(x)=0", "Local Maximum & Minimum"],
            ["w_atlas_calculus_derivative", "w_power_rule_square_growth"]
        ),
        (
            18, 5, "Slicing to Infinity: Riemann Sums & The Fundamental Theorem of Calculus",
            "Advanced Calculus II · @saxster/atlas Calculus (pp. 3–5): midpoint Riemann bars, definite integrals & why slope and area are inverses",
            "Adding up infinitely many thin rate-times-time slivers reconstructs total change: integration and differentiation undo each other.",
            "Open @saxster/atlas Calculus (`maths/calculus` pp. 3–5) and compare the blue area under f′(t) = t from 0 to x with the red height of the parabola f(x) = ½x².",
            "Every tiny step dt adds a ribbon of area f′(t)·dt = df — which is the exact tiny rise in height of the original curve f(x)! That is why the area under the slope curve IS the height change f(b) − f(a)!",
            "∫ₐᵇ f(x) dx = lim_{n→∞} ∑ f(xᵢ) Δx = F(b) − F(a)   where F′(x) = f(x)",
            [
                {"symbol": "f(xᵢ) Δx", "visualPart": "Blue midpoint Riemann rectangle of width Δx", "colorRole": "blue", "meaning": "Area of one thin strip"},
                {"symbol": "∫₀ˣ f′(t) dt", "visualPart": "Blue shaded triangle under slope graph f′(t) = t", "colorRole": "blue", "meaning": "Accumulated area under rate curve"},
                {"symbol": "f(x) − f(0)", "visualPart": "Red vertical height bar on antiderivative parabola ½x²", "colorRole": "red", "meaning": "Total net change in height"}
            ],
            "maths/calculus/index.html#3",
            ["Riemann Sum", "Midpoint Rule", "Definite Integral", "Antiderivative", "Fundamental Theorem of Calculus", "Signed Area"],
            ["w_atlas_calculus_integral", "w_ftc_area_slope_duality"]
        ),
        (
            19, 5, "Arrows in Space: Vectors, Dot Products & Geometric Proofs",
            "OUP Ch 16 Bonus Chapter · Column vectors, triangle/parallelogram addition, magnitude |v|, dot product & vector geometry proofs",
            "A vector is a pure displacement (dx, dy) free of any starting point; adding vectors chains journeys tip-to-tail.",
            "Drag vectors a and b tip-to-tail on the grid, and project vector u onto v to measure their dot product.",
            "Because midpoints M of AB and N of AC have position vectors ½b and ½c, the segment MN = ½c − ½b = ½(c − b) = ½BC — proving in one line that the midsegment of ANY triangle is parallel to the base and half its length!",
            "AB = OB − OA,   |v| = √(x² + y²),   u · v = x₁x₂ + y₁y₂ = |u||v| cos θ",
            [
                {"symbol": "a + b", "visualPart": "Red vector a followed tip-to-tail by Blue vector b", "colorRole": "red", "meaning": "Resultant diagonal displacement"},
                {"symbol": "½(b − a)", "visualPart": "Green midsegment vector MN parallel to base AB", "colorRole": "green", "meaning": "Simultaneously proves parallel direction and ½ length"},
                {"symbol": "u · v = 0", "visualPart": "Amber 90° perpendicular shadow (zero projection)", "colorRole": "amber", "meaning": "Perpendicular vectors have zero dot product"}
            ],
            "maths/multivariable/index.html#2",
            ["Column Vector", "Position Vector", "Triangle Law", "Zero Vector", "Magnitude |v|", "Collinear Vectors", "Dot Product u·v", "Vector Midsegment Proof"],
            ["w_vector_tip_to_tail_lab", "w_vector_geometric_proof_studio"]
        ),
        (
            20, 5, "Stretching the Plane: 2×2 Matrices, Determinants & Eigenvectors",
            "Advanced Linear Algebra · @saxster/atlas Linear Algebra & 2×2 Matrix Sandbox: basis columns, det(A) = ad − bc & eigenvectors",
            "A 2×2 matrix is a machine that moves the entire coordinate grid by landing î at column 1 and ĵ at column 2.",
            "Open the @saxster/atlas 2×2 Matrix Sandbox (`maths/matrix-sandbox`) and drag the red tip of Aî = (a, c) and blue tip of Aĵ = (b, d) directly in 3D.",
            "The unit square stretches into an amber parallelogram of signed area det(A) = ad − bc; if the two columns line up, the whole 2D plane collapses onto a 1D line (det = 0), while green eigenvector lines stay on their own span (Av = λv)!",
            "A[x, y]ᵀ = x Aî + y Aĵ,   det(A) = ad − bc,   A v = λ v  ⇔  det(A − λI) = 0",
            [
                {"symbol": "Column 1 (a, c)", "visualPart": "Red draggable basis vector Aî", "colorRole": "red", "meaning": "Where unit horizontal vector (1, 0) lands"},
                {"symbol": "Column 2 (b, d)", "visualPart": "Blue draggable basis vector Aĵ", "colorRole": "blue", "meaning": "Where unit vertical vector (0, 1) lands"},
                {"symbol": "det(A) = ad − bc", "visualPart": "Amber parallelogram spanned by Aî and Aĵ", "colorRole": "amber", "meaning": "Signed area scale factor for any shape in the plane"},
                {"symbol": "A v = λ v", "visualPart": "Green invariant eigenvector axes", "colorRole": "green", "meaning": "Directions stretched by factor λ without rotating"}
            ],
            "maths/matrix-sandbox/index.html",
            ["Linear Transformation", "Basis Vectors î, ĵ", "2×2 Matrix", "Determinant ad − bc", "Singular Matrix (det = 0)", "Matrix Composition RS ≠ SR", "Eigenvector & Eigenvalue λ"],
            ["w_atlas_linear_algebra", "w_atlas_matrix_sandbox"]
        ),
    ]

    volumes_by_num = {v["number"]: v["title"] for v in build_volumes()}
    chapters = []
    for (
        num, vol_num, title, subtitle, hook,
        concrete_action, aha_invariant, formula_display, term_mappings, atlas_ref,
        key_terms, widgets
    ) in raw_specs:
        chapters.append({
            "id": f"ch{num:02d}",
            "number": num,
            "volumeNumber": vol_num,
            "volumeTitle": volumes_by_num[vol_num],
            "title": title,
            "subtitle": subtitle,
            "hookSummary": hook,
            "intuitionToFormula": {
                "concreteAction": concrete_action,
                "ahaInvariant": aha_invariant,
                "formulaDisplay": formula_display,
                "termMappings": term_mappings,
                "atlasFigureRef": atlas_ref,
            },
            "sections": [
                {
                    "id": f"ch{num:02d}-s1",
                    "heading": f"{num}.1 Concrete & Pictorial Intuition (The Visual 'Aha!')",
                    "excerpt": f"{concrete_action} {aha_invariant}",
                },
                {
                    "id": f"ch{num:02d}-s2",
                    "heading": f"{num}.2 Symbolic Lockstep & Formula Anatomy",
                    "excerpt": f"Every piece of the geometry locks onto a symbol in {formula_display}. Once you see why each term exists, you never have to guess a sign or denominator.",
                },
                {
                    "id": f"ch{num:02d}-s3",
                    "heading": f"{num}.3 Singapore Bar-Model, Checkpoint & Olympiad Stretch",
                    "excerpt": f"Apply {title} across Cambridge Stage 8 Checkpoint questions, Singapore multi-step problems, and horizon extensions.",
                },
            ],
            "callouts": [
                {
                    "id": f"ch{num:02d}-c-predict",
                    "kind": "predict",
                    "title": "Predict Before You Drag",
                    "body": f"Before moving the slider in {widgets[0]}, predict which geometric quantity changes and which invariant stays locked.",
                },
                {
                    "id": f"ch{num:02d}-c-aha",
                    "kind": "check",
                    "title": "The Intuition → Formula Bridge",
                    "body": f"{aha_invariant} Formula: {formula_display}",
                },
                {
                    "id": f"ch{num:02d}-c-trap",
                    "kind": "careful",
                    "title": "Classic Algebraic Trap to Avoid",
                    "body": f"Whenever a formula in Chapter {num} looks tempting to shortcut, test a concrete 2×2 area or small integer example (x = 2, y = 3) first!",
                },
            ],
            "keyTerms": key_terms,
            "widgets": widgets,
        })
    return chapters


def build_explorers():
    return [
        {
            "id": "x_number_tower",
            "title": "The Number Tower & Prime Lattice Explorer",
            "subtitle": "From ℕ ⊂ ℤ ⊂ ℚ ⊂ ℝ to prime factor Venn diagrams and irrational surds",
            "symbol": "number.square.fill",
            "linkedChapters": [0, 1, 2, 3],
            "summary": "Explore how every integer factors uniquely into primes, why HCF × LCM = a × b geometrically, and where √2 and π sit between rational fractions.",
        },
        {
            "id": "x_singapore_bar_engine",
            "title": "The Singapore CPA Bar-Model & Function Studio",
            "subtitle": "Concrete → Pictorial → Abstract bar models translating word problems into equations",
            "symbol": "rectangle.split.3x1.fill",
            "linkedChapters": [3, 4, 5, 6, 7],
            "summary": "Build part-whole, comparison, and before-after Singapore bar models and watch the brackets translate into live algebraic equations.",
        },
        {
            "id": "x_euclid_compass",
            "title": "Euclid's Compass, Unit Circle & Trig Shadow Bench",
            "subtitle": "Locus constructions, circle sector rearrangements, and @saxster/atlas unit-circle shadows",
            "symbol": "compass.drawing",
            "linkedChapters": [8, 9, 10, 11, 12],
            "summary": "Construct bisectors, unroll radians, and shine level/top lamps on the 3D unit circle to see sin θ, cos θ, tan θ, and sin²θ + cos²θ = 1.",
        },
        {
            "id": "x_bayes_calculus_bridge",
            "title": "The Bayes, Calculus & 2×2 Matrix Horizon Lab",
            "subtitle": "@saxster/atlas 1,000-person Bayes square, Riemann sums, derivatives & 2×2 eigen-grids",
            "symbol": "function",
            "linkedChapters": [13, 14, 15, 16, 17, 18, 19, 20],
            "summary": "Manipulate the 3D Bayes unit square, shrink secant step h → 0, sum Riemann rectangles, and drag 2×2 basis columns Aî and Aĵ.",
        },
    ]


def build_widgets(chapters):
    widgets = []
    for ch in chapters:
        ch_num = ch["number"]
        bridge = ch["intuitionToFormula"]
        for idx, wid in enumerate(ch["widgets"]):
            is_3d = "atlas" in wid or ch_num in (3, 10, 12, 13, 15, 16, 17, 18, 19, 20)
            title = wid.replace("w_atlas_", "3D Atlas: ").replace("w_", "").replace("_", " ").title()
            widgets.append({
                "id": wid,
                "title": title,
                "chapter": ch_num,
                "is3D": is_3d,
                "atlasRoute": bridge["atlasFigureRef"],
                "challengePrompt": f"Manipulate {title} until the visual invariant locks in, then verify {bridge['formulaDisplay']}.",
                "cutaway": f"Intuition → Formula Lockstep: {bridge['ahaInvariant']}",
                "idealised": f"Formula Anatomy: {bridge['formulaDisplay']}",
                "watchSteps": [
                    {"title": "1. Concrete Touch", "caption": bridge["concreteAction"]},
                    {"title": "2. Spot the Invariant ('Aha!')", "caption": bridge["ahaInvariant"]},
                    {"title": "3. Colour-Map the Symbols", "caption": f"Match red, blue, amber, and green geometry to {bridge['formulaDisplay']}."},
                    {"title": "4. Test a Boundary Case", "caption": "Push the slider to 0, 1, or 90° and verify that the formula predicts the exact extreme state."},
                    {"title": "5. Stamp & Sketch in Journal", "caption": "Freeze the state into your Cornell Proof & Construction Journal."},
                ],
            })
    return widgets


def build_atlas_lessons(chapters):
    lessons = []
    for ch in chapters:
        ch_num = ch["number"]
        bridge = ch["intuitionToFormula"]
        w0 = ch["widgets"][0]
        stages = [
            ("Concrete Manipulation", f"How does touching the geometry of {ch['title']} reveal its structure?", bridge["concreteAction"]),
            ("The Visual 'Aha!' Invariant", f"What stays constant in {ch['title']} when you deform or slice the figure?", bridge["ahaInvariant"]),
            ("Symbolic Formula Lockstep", f"How does the picture translate term-by-term into {bridge['formulaDisplay']}?", f"Every term in {bridge['formulaDisplay']} corresponds to a colour-coded geometric part in {bridge['atlasFigureRef']}."),
        ]
        for s_idx, (stage_name, q, exp) in enumerate(stages, start=1):
            lessons.append({
                "id": f"atlas-ch{ch_num:02d}-{s_idx}",
                "widget": w0,
                "title": f"Ch {ch_num}.{s_idx} · {ch['title']} ({stage_name})",
                "chapter": ch_num,
                "figure": bridge["atlasFigureRef"],
                "question": q,
                "explanation": exp,
                "limits": f"Formula: {bridge['formulaDisplay']}",
                "sources": ["Oxford Complete Mathematics 8 (2nd Ed.)", "@saxster/atlas Visualisations"],
                "stories": [ch["hookSummary"]],
            })
    return lessons


def build_bridges():
    return [
        {
            "id": "bridge-bio-sa-vol",
            "discipline": "biology",
            "sourceBook": "The Living World (KymBio)",
            "sourceRef": "KymBio Ch 3 · Surface-Area-to-Volume Ratio (6L² vs L³)",
            "deepLink": "kymbio://chapter/3",
            "title": "Why Elephants Have Huge Ears & Cells Stay Microscopic (SA:V Scaling)",
            "schoolTopics": ["5.4", "12.2", "13.5"],
            "patternedWorldChapters": [10, 11],
            "summary": "When a cell or organism enlarges by linear scale factor k, its surface area grows as k² while its metabolising volume grows as k³ — so SA/V = 6/L drops inversely with size.",
            "keyEquation": "SA = 6L²,   V = L³   ⇒   SA : V = 6 / L",
            "microCheckQuestion": "If a cubical cell doubles its side length from L = 1 μm to L = 2 μm (k = 2), by what factor does its Surface-Area-to-Volume ratio change?",
            "microCheckAnswer": "Surface area multiplies by 2² = 4 and volume by 2³ = 8, so SA:V halves from 6:1 to 3:1.",
        },
        {
            "id": "bridge-bio-mendel-bayes",
            "discipline": "biology",
            "sourceBook": "The Living World (KymBio)",
            "sourceRef": "KymBio Ch 13 · Mendel's Punnett Squares & Clinical Screening",
            "deepLink": "kymbio://chapter/13",
            "title": "Punnett Grids Are 2×2 Area Diagrams & Medical Tests Obey Bayes' Rule",
            "schoolTopics": ["15.3", "15.4"],
            "patternedWorldChapters": [15, 16],
            "summary": "A Punnett square for Aa × Aa is literally the algebraic expansion (0.5A + 0.5a)² = 0.25AA + 0.50Aa + 0.25aa, and genetic carrier screening relies on Bayes' theorem.",
            "keyEquation": "(p + q)² = p² + 2pq + q² = 1",
            "microCheckQuestion": "In a cross between two heterozygotes (Aa × Aa), given that an offspring shows the dominant phenotype (AA or Aa), what is the conditional probability it is a carrier (Aa)?",
            "microCheckAnswer": "Out of 3 dominant-phenotype boxes (1 AA and 2 Aa), 2 are Aa, so P(Aa | Dominant) = 2/3.",
        },
        {
            "id": "bridge-phys-kinematics-calculus",
            "discipline": "physics",
            "sourceBook": "Atlas of Physics",
            "sourceRef": "Atlas of Physics Ch 1 · Kinematics (Velocity Slope & Displacement Area)",
            "deepLink": "atlas://physics/kinematics",
            "title": "Velocity Is the Derivative of Position; Displacement Is the Area Under v(t)",
            "schoolTopics": ["14.2", "14.3"],
            "patternedWorldChapters": [7, 17, 18],
            "summary": "On a distance-time graph, gradient Δs/Δt is speed. On a speed-time graph, the area of the trapezium under v(t) is distance travelled s = v₀t + ½at².",
            "keyEquation": "v(t) = ds/dt,   Δs = ∫ v(t) dt = v₀t + ½at²",
            "microCheckQuestion": "A train accelerates uniformly from 10 m/s to 30 m/s over 8 seconds. Using the trapezium area under v(t), how far does it travel?",
            "microCheckAnswer": "Area = ½(10 + 30) × 8 = 20 × 8 = 160 m.",
        },
        {
            "id": "bridge-phys-vectors-forces",
            "discipline": "physics",
            "sourceBook": "Atlas of Physics",
            "sourceRef": "Atlas of Physics Ch 2 · Newton's Laws & Inclined Planes",
            "deepLink": "atlas://physics/newton",
            "title": "Resolving Forces on a Ramp with Unit-Circle Sine & Cosine Shadows",
            "schoolTopics": ["3.3", "16.1", "16.2"],
            "patternedWorldChapters": [12, 19],
            "summary": "A block of weight mg on a ramp of angle θ splits into a component mg sin θ pulling down the slope and mg cos θ pressing into the ramp.",
            "keyEquation": "F_parallel = mg sin θ,   F_normal = mg cos θ",
            "microCheckQuestion": "For a 100 N crate on a 30° ramp, what component of gravity pulls it down the slope?",
            "microCheckAnswer": "100 × sin 30° = 100 × 0.5 = 50 N.",
        },
        {
            "id": "bridge-chem-stoichiometry-ratios",
            "discipline": "chemistry",
            "sourceBook": "Atlas of Chemistry",
            "sourceRef": "Atlas of Chemistry · Balancing Equations as Linear Conservation & Mole Ratios",
            "deepLink": "atlas://chemistry/kinetics",
            "title": "Chemical Stoichiometry Is Ratio Partition & First-Order Kinetics Is dy/dt = −ky",
            "schoolTopics": ["12.2", "12.4", "7.2"],
            "patternedWorldChapters": [3, 5, 17],
            "summary": "Balancing a reaction solves a system of linear conservation equations for atoms, and radioactive/chemical decay follows the exponential differential equation dy/dt = −ky.",
            "keyEquation": "N(t) = N₀ (½)^(t / t_{1/2}) = N₀ e^(−kt)",
            "microCheckQuestion": "If a sample of 80 g decays with a half-life of 3 hours, how much remains after 9 hours?",
            "microCheckAnswer": "9 hours is 3 half-lives: 80 × (1/2)³ = 80 / 8 = 10 g.",
        },
        {
            "id": "bridge-econ-compound-rupees",
            "discipline": "economics",
            "sourceBook": "Atlas of Economics",
            "sourceRef": "Atlas of Economics Fig E.1 · ₹1,000 a Month at 8% Compounding Machine",
            "deepLink": "atlas://economics/compound",
            "title": "Why Starting Early Beats Saving Twice as Much Later (The Geometric Series of Wealth)",
            "schoolTopics": ["9.3", "11.2"],
            "patternedWorldChapters": [3, 6],
            "summary": "Saving ₹1,000 a month at 8% for 20 years puts ₹2.40 lakh in, which compounds to ₹5.89 lakh — more than half of the final pot is interest earned on interest.",
            "keyEquation": "A = P(1 + r)ⁿ,   Rule of 72: Doubling Years ≈ 72 / (Rate %)",
            "microCheckQuestion": "Using the Rule of 72, approximately how many years does it take a lump sum to double at 8% annual compound interest?",
            "microCheckAnswer": "72 ÷ 8 = 9 years.",
        },
        {
            "id": "bridge-music-fourier-harmonics",
            "discipline": "physics",
            "sourceBook": "Atlas of Mathematics",
            "sourceRef": "Atlas of Mathematics Ch 5 · Fourier Epicycles & Musical Harmonics",
            "deepLink": "atlas://maths/fourier",
            "title": "Why a Violin and a Flute Playing the Same Note Sound Different (Fourier Series)",
            "schoolTopics": ["6.5", "11.1", "12.2"],
            "patternedWorldChapters": [2, 12, 18],
            "summary": "Pythagoras discovered that string ratios 1:2 (octave) and 2:3 (fifth) make consonance; Fourier proved any periodic sound wave is a sum of spinning unit-circle harmonics bₙ sin(nt).",
            "keyEquation": "f(t) = (4/π)(sin t + ⅓ sin 3t + ⅕ sin 5t + …)",
            "microCheckQuestion": "In the square-wave Fourier series, what is the amplitude ratio of the 3rd harmonic (sin 3t) to the fundamental (sin t)?",
            "microCheckAnswer": "1/3 (radius 4/(3π) vs 4/π).",
        },
        {
            "id": "bridge-cs-boolean-matrices",
            "discipline": "physics",
            "sourceBook": "Atlas of Mathematics",
            "sourceRef": "Atlas of Mathematics · 2×2 Matrix Graphics & Boolean Logic Gates",
            "deepLink": "atlas://maths/matrix-sandbox",
            "title": "How iPad GPUs Rotate 3D Worlds with Matrices & CPUs Think with De Morgan Gates",
            "schoolTopics": ["1.3", "13.3", "16.2"],
            "patternedWorldChapters": [0, 11, 19, 20],
            "summary": "Every pixel and 3D vertex on Kym's iPad is rotated and projected by matrix multiplication, while every CPU transistor evaluates Boolean logic gates (AND, OR, NOT, NAND).",
            "keyEquation": "R_θ = [[cos θ, −sin θ], [sin θ, cos θ]],   ¬(P ∧ Q) ⇔ (¬P) ∨ (¬Q)",
            "microCheckQuestion": "What is the determinant det(R_θ) of a 2D rotation matrix through any angle θ?",
            "microCheckAnswer": "det(R_θ) = cos²θ − (−sin²θ) = cos²θ + sin²θ = 1 (rotation preserves area).",
        },
    ]


def build_school_textbook():
    raw_units = [
        (
            1, "Integers, powers and roots", "number_algebra", "circled", 7, 24, [1], ["bridge-cs-boolean-matrices"],
            [
                ("1.1", "Multiplying and dividing negative integers", 8, "w_negative_rotation_line", "Two negative signs rotate 180° twice (+); odd count of negatives gives negative."),
                ("1.2", "Squares, cubes, roots and indices", 12, "w_index_staircase_surds", "Prime factor powers must be multiples of 2 for squares and multiples of 3 for cubes."),
                ("1.3", "Index notation", 14, "w_index_staircase_surds", "aᵐ × aⁿ = aᵐ⁺ⁿ, aᵐ ÷ aⁿ = aᵐ⁻ⁿ, (aᵐ)ⁿ = aᵐⁿ, a⁰ = 1, a⁻ⁿ = 1/aⁿ."),
                ("1.4", "Prime factorization to find the HCF and LCM", 16, "w_prime_venn_hcf_lcm", "Venn diagram of prime factors: intersection = HCF, union = LCM, HCF × LCM = a × b."),
                ("1.5", "Order of operations", 19, "w_negative_rotation_line", "BIDMAS/BODMAS hierarchy; note −3² = −9 whereas (−3)² = +9."),
                ("1.6", "Natural numbers and rational numbers", 20, "w_index_staircase_surds", "ℕ ⊂ ℤ ⊂ ℚ ⊂ ℝ; rational numbers a/b terminate or recur; √2 is irrational."),
            ]
        ),
        (
            2, "Expressions", "number_algebra", "circled", 25, 36, [4], [],
            [
                ("2.1", "Expressions, formulae and equations", 26, "w_algebra_area_tiles", "Distinguish an expression (no =), an equation (true for specific x), and an identity (true for all x)."),
                ("2.2", "Expanding brackets", 28, "w_algebra_area_tiles", "Area-array model: a(b + c) = ab + ac and (x + a)(x + b) = x² + (a + b)x + ab."),
                ("2.3", "Factorizing expressions", 31, "w_difference_of_squares_slicer", "Extract the full HCF of coefficients and powers; spot a² − b² = (a − b)(a + b)."),
                ("2.4", "Substitution into expressions", 32, "w_algebra_area_tiles", "Wrap negative substituted values in brackets before squaring or multiplying."),
            ]
        ),
        (
            3, "Shapes and mathematical drawings", "geometry_measures", "ticked", 37, 58, [9], ["bridge-phys-vectors-forces"],
            [
                ("3.1", "Quadrilaterals", 38, "w_euclid_compass_locus", "Classify by diagonal properties: rhombus & kite diagonals cross at 90°; rectangle diagonals are equal."),
                ("3.2", "3D shapes", 39, "w_polyhedron_net_folder", "Prisms, pyramids, nets, plans & elevations, and Euler's invariant V − E + F = 2."),
                ("3.3", "Bearings", 44, "w_bearings_back_bearing_radar", "Measure clockwise from North in 3 digits (000°–360°); back-bearing adds or subtracts 180°."),
                ("3.4", "Constructions", 46, "w_euclid_compass_locus", "SSS, SAS, ASA triangle constructions with ruler and compass; keep construction arcs visible."),
                ("3.5", "Bisecting angles and lines", 50, "w_euclid_compass_locus", "Perpendicular bisector = locus equidistant from A and B; angle bisector = locus equidistant from two lines."),
            ]
        ),
        (
            4, "Sampling", "statistics_probability", "upcoming", 59, 64, [13], [],
            [
                ("4.1", "Methods of data collection", 60, "w_atlas_sampling_error", "Primary vs secondary data, questionnaires, two-way tally tables, and avoiding leading questions."),
                ("4.2", "Sampling methods", 61, "w_wald_survivorship_bomber", "Simple random, systematic, and stratified sampling nᵢ = n(Nᵢ/N); survivorship and selection bias."),
            ]
        ),
        (
            5, "Area, perimeter and volume", "geometry_measures", "ticked", 65, 86, [10], ["bridge-bio-sa-vol"],
            [
                ("5.1", "Circumference of a circle", 66, "w_circle_sector_rearranger", "C = πd = 2πr and sector rearrangement A = πr²; arc length & sector area by θ/360°."),
                ("5.2", "Areas of parallelograms and trapeziums", 69, "w_trapezium_prism_slicer", "Use perpendicular height h: parallelogram A = bh; trapezium A = ½(a + b)h."),
                ("5.3", "Volume of a triangular prism", 73, "w_trapezium_prism_slicer", "V = Cross-sectional Area × Length = (½bh) × L; Cylinder V = πr²h."),
                ("5.4", "Surface area of prisms and pyramids", 75, "w_trapezium_prism_slicer", "Unfold 3D net; use Pythagoras to find slant height of triangular faces."),
                ("5.5", "Imperial units", 77, "w_trapezium_prism_slicer", "Miles ↔ km (5 miles ≈ 8 km), inches ↔ cm, pints ↔ litres, pounds ↔ kg."),
            ]
        ),
        (
            6, "Fractions and decimals", "number_algebra", "circled", 87, 105, [2], ["bridge-music-fourier-harmonics"],
            [
                ("6.1", "Multiplying and dividing decimals", 88, "w_fraction_area_division", "Scale numerator and denominator by 10ᵏ so the divisor is a whole number."),
                ("6.2", "Significant figures", 91, "w_fraction_area_division", "Count from the first non-zero digit; round only at the final step of a calculation."),
                ("6.3", "Recurring decimals", 93, "w_recurring_decimal_tail_canceller", "Prime denominators with only 2s and 5s terminate; others recur; convert via (10ᵏ − 1)x."),
                ("6.4", "Subtracting mixed numbers", 97, "w_fraction_area_division", "Convert to improper fractions or borrow 1 whole as d/d when the fraction part is larger."),
                ("6.5", "Multiplying and dividing fractions", 98, "w_fraction_area_division", "Cross-cancel common factors before multiplying; divide by multiplying by the reciprocal."),
            ]
        ),
        (
            7, "Equations, formulae and inequalities", "number_algebra", "circled", 106, 125, [5], ["bridge-chem-stoichiometry-ratios"],
            [
                ("7.1", "Deriving formulae", 107, "w_balance_beam_equations", "Translate Singapore bar models and geometric perimeters/areas into algebraic formulae."),
                ("7.2", "Deriving and solving equations", 110, "w_balance_beam_equations", "Solve linear equations with brackets, fractions, and unknowns on both sides."),
                ("7.3", "Changing the subject of a formula", 117, "w_formula_subject_transposer", "Reverse order of operations; factor out the target variable when it appears twice."),
                ("7.4", "Inequalities", 119, "w_inequality_mirror_line", "Open circle (<, >) vs closed circle (≤, ≥); reverse inequality sign when multiplying/dividing by a negative."),
            ]
        ),
        (
            8, "Geometry", "geometry_measures", "upcoming", 126, 137, [8], [],
            [
                ("8.1", "Exterior angle of a triangle", 128, "w_exterior_angle_tear_proof", "The exterior angle of a triangle equals the sum of the two opposite interior angles (α + β)."),
                ("8.2", "Angles in parallel lines and intersecting lines", 130, "w_parallel_transversal_proof", "Alternate (Z) equal, corresponding (F) equal, co-interior (C) add to 180°, vertically opposite equal."),
                ("8.3", "Midpoint of a line segment", 132, "w_parallel_transversal_proof", "Midpoint M = ((x₁ + x₂)/2, (y₁ + y₂)/2) is the coordinate average of endpoints."),
            ]
        ),
        (
            9, "Decimals, percentages and fractions", "number_algebra", "circled", 138, 148, [3], ["bridge-econ-compound-rupees"],
            [
                ("9.1", "Multiplying by decimals", 139, "w_compound_multiplier_machine", "Multiplying by a decimal between 0 and 1 makes a positive number smaller."),
                ("9.2", "Dividing by decimals", 141, "w_compound_multiplier_machine", "Dividing by 0.1, 0.01, or 0.25 scales the number up (÷ 0.25 = × 4)."),
                ("9.3", "Percentage increase and decrease", 142, "w_compound_multiplier_machine", "Use single multipliers (1 ± r); reverse percentages divide by (1 ± r); compound growth P(1+r)ⁿ."),
                ("9.4", "Simplifying calculations with fractions and decimals", 144, "w_singapore_ratio_bar_model", "Convert between benchmark fractions, decimals, and percentages for rapid cancellation."),
            ]
        ),
        (
            10, "Presenting data and interpreting results", "statistics_probability", "upcoming", 149, 172, [14], [],
            [
                ("10.1", "Time series graphs", 150, "w_histogram_frequency_density", "Plot time on the horizontal axis, identify seasonal cycles, and compute moving-average trends."),
                ("10.2", "Stem-and-leaf diagrams", 151, "w_histogram_frequency_density", "Ordered leaves, mandatory key (e.g. 4 | 2 = 42), back-to-back comparison of median and IQR."),
                ("10.3", "Histograms", 154, "w_histogram_frequency_density", "Continuous bars with zero gaps; for unequal class widths, height = Frequency Density = f / Δx."),
                ("10.4", "Interpreting and comparing data and diagrams", 156, "w_mean_fulcrum_std_dev", "Compare distributions using a measure of central tendency (mean/median) AND spread (IQR/σ)."),
            ]
        ),
        (
            11, "Sequences", "number_algebra", "upcoming", 173, 183, [6], ["bridge-econ-compound-rupees", "bridge-music-fourier-harmonics"],
            [
                ("11.1", "Rules of sequences", 174, "w_sequence_difference_engine", "Term-to-term vs position-to-term rules; arithmetic, geometric, Fibonacci, and quadratic sequences."),
                ("11.2", "The nth term", 176, "w_gauss_staircase_sum", "Linear Tₙ = dn + (a₁ − d); quadratic Tₙ = an² + bn + c where 2nd difference = 2a; Gauss sum Sₙ."),
            ]
        ),
        (
            12, "Ratio and proportion", "number_algebra", "ticked", 184, 193, [3], ["bridge-bio-sa-vol", "bridge-chem-stoichiometry-ratios"],
            [
                ("12.1", "Units of measurement", 185, "w_singapore_ratio_bar_model", "Area conversions square the linear factor (1 m² = 10,000 cm²); volume conversions cube it (1 m³ = 10⁶ cm³)."),
                ("12.2", "Simplifying ratio", 186, "w_singapore_ratio_bar_model", "Convert to the same units first; write in simplest integer form or unitary form 1 : n."),
                ("12.3", "Sharing in a given ratio", 188, "w_singapore_ratio_bar_model", "Singapore Bar Model: find 1 unit = Total ÷ ∑ parts, or from a known difference between parts."),
                ("12.4", "Proportion", 188, "w_singapore_ratio_bar_model", "Direct proportion y = kx vs inverse proportion y = k/x (where x · y = constant)."),
            ]
        ),
        (
            13, "Transformations", "geometry_measures", "upcoming", 194, 211, [11], ["bridge-bio-sa-vol", "bridge-cs-boolean-matrices"],
            [
                ("13.1", "Translations", 195, "w_transformation_isometry_stage", "Specify by column vector (dx, dy); orientation and size remain invariant."),
                ("13.2", "Reflections", 198, "w_transformation_isometry_stage", "Mirror line is the perpendicular bisector of every point P and its image P′ (y = x swaps coordinates)."),
                ("13.3", "Rotations", 200, "w_transformation_isometry_stage", "Specify angle, direction (clockwise/anticlockwise), and centre of rotation (x₀, y₀)."),
                ("13.4", "Symmetry", 201, "w_transformation_isometry_stage", "Lines of reflection symmetry and order of rotational symmetry in 2D polygons and 3D solids."),
                ("13.5", "Enlargements", 204, "w_enlargement_ray_scaler", "Multiply ray distances from centre of enlargement by scale factor k; area scales by k²."),
            ]
        ),
        (
            14, "Functions and graphs", "number_algebra", "upcoming", 212, 229, [7, 17], ["bridge-phys-kinematics-calculus"],
            [
                ("14.1", "Functions", 213, "w_linear_graph_slope_explorer", "One-step and two-step function machines f(x), domain/range mappings, and inverse functions f⁻¹(x)."),
                ("14.2", "Linear graphs", 215, "w_linear_graph_slope_explorer", "y = mx + c, gradient m = Δy/Δx, intercepts, parallel lines (m₁ = m₂), and graphical simultaneous equations."),
                ("14.3", "Real-life graphs", 222, "w_kinematics_travel_graph", "Distance-time gradient = speed; speed-time gradient = acceleration and area = distance travelled."),
            ]
        ),
        (
            15, "Probability", "statistics_probability", "upcoming", 230, 248, [15, 16], ["bridge-bio-mendel-bayes"],
            [
                ("15.1", "The idea of probability", 231, "w_atlas_galton_board", "Probability scale [0, 1], mutually exclusive events ∑ P(Eᵢ) = 1, complement P(A′) = 1 − P(A)."),
                ("15.2", "Experimental probability", 232, "w_atlas_galton_board", "Relative frequency = successes ÷ trials; Law of Large Numbers converges toward theoretical probability."),
                ("15.3", "Theoretical probability", 233, "w_combinatorics_tree_builder", "Equally likely outcomes P(A) = |A| / |ξ|, permutations nPr, combinations nCr."),
                ("15.4", "Combined events", 236, "w_atlas_bayes_square", "Sample-space diagrams, probability trees, conditional probability, and Bayes' theorem P(D|+)."),
            ]
        ),
        (
            16, "BONUS CHAPTER: Vectors", "horizon_advanced", "upcoming", 249, 260, [19, 20], ["bridge-phys-vectors-forces", "bridge-cs-boolean-matrices"],
            [
                ("16.1", "Introduction to vectors", 250, "w_vector_tip_to_tail_lab", "Scalar vs vector, column notation (x, y)ᵀ, equal/negative vectors, scalar multiples, magnitude √(x²+y²)."),
                ("16.2", "Using vectors in geometry", 254, "w_vector_geometric_proof_studio", "Triangle law AB + BC = AC, position vectors, proving collinearity and parallel midsegments, 2×2 matrices."),
            ]
        ),
    ]

    units = []
    for u_num, title, strand, status, p_start, p_end, pw_chaps, bridges, topics in raw_units:
        wb_start = (u_num - 1) * 12 + 1
        wb_end = u_num * 12
        topic_objs = []
        for idx, (code, t_title, lb_page, wid, summary) in enumerate(topics):
            topic_objs.append({
                "id": f"topic-{code.replace('.', '-')}",
                "code": code,
                "title": t_title,
                "learnersBookPage": lb_page,
                "workbookPage": wb_start + idx * 2,
                "discipline": strand,
                "livingWorldChapters": pw_chaps,
                "linkedWidgets": [wid],
                "bridgeIds": bridges,
                "summary": summary,
                "cambridgeWatchouts": [
                    f"Always draw the Concrete → Pictorial bar model or geometric sketch before writing the symbolic formula for {code}.",
                    "Check units, negative signs, and significant figures at the final step.",
                ],
            })
        units.append({
            "id": f"oup-ch-{u_num:02d}",
            "unitNumber": u_num,
            "title": title,
            "discipline": strand,
            "schoolStatus": status,
            "scienceStrands": [strand.replace("_", " ").title(), "Singapore CPA Bar-Model", "Intuition → Formula"],
            "twsStrands": ["Pólya Problem Solving", "Conjecturing & Convincing", "Specialising & Generalising"],
            "scienceInContext": f"OUP Complete Mathematics 8 (2nd Ed.) pp. {p_start}–{p_end} + Built-In 3-Tier Singapore & Checkpoint Companion Workbook.",
            "learnersBookStartPage": p_start,
            "learnersBookEndPage": p_end,
            "workbookStartPage": wb_start,
            "workbookEndPage": wb_end,
            "isCompletedInSchool": status == "ticked",
            "livingWorldChapters": pw_chaps,
            "bridgeIds": bridges,
            "topics": topic_objs,
        })

    return {
        "id": "oup-complete-maths-8-2ed",
        "title": "Cambridge Lower Secondary Complete Mathematics 8 (Second Edition)",
        "authors": "Deborah Barton",
        "publisher": "Oxford University Press",
        "curriculumCode": "0862",
        "learnersBookTotalPages": 260,
        "workbookTotalPages": 192,
        "units": units,
    }


def build_school_questions():
    """
    Generates 64 high-precision questions across all 16 OUP chapters:
    - 1 Student Book Consolidation question per chapter
    - 3 Built-In Companion Workbook questions per chapter (Tier 1: Focus / Foundation, Tier 2: Practice / Singapore Bar-Model, Tier 3: Challenge / Olympiad & Horizon)
    """
    chapter_question_specs = [
        (
            1, "1.4", 1, "w_prime_venn_hcf_lcm",
            "Find the Highest Common Factor (HCF) and Lowest Common Multiple (LCM) of 72 and 120 using prime factorisation, and verify that HCF × LCM = 72 × 120.",
            "Step 1 (Prime Factor Trees): 72 = 2³ × 3² and 120 = 2³ × 3¹ × 5¹.\nStep 2 (Venn Intersection = HCF): Take min powers: 2³ × 3¹ = 24.\nStep 3 (Venn Union = LCM): Take max powers: 2³ × 3² × 5¹ = 360.\nStep 4 (Invariant Check): 24 × 360 = 8640 = 72 × 120.",
            "72 = 2³ × 3² and 120 = 2³ × 3 × 5, so HCF = ___ and LCM = ___.",
            "HCF = 24, LCM = 360",
            "HCF = 24 and LCM = 360 because 72 = 2³ × 3² and 120 = 2³ × 3 × 5; their overlap is 2³ × 3 = 24 and their union is 2³ × 3² × 5 = 360.",
            ["24", "360", "2^3", "prime"],
            "Evaluate (−6) × (−4) ÷ (−3) + (−2)³.",
            "−16",
            "Two Colaba lighthouses flash every 18 seconds and 24 seconds. They flash together at 19:00:00. After how many seconds will they next flash together?",
            "72 seconds",
            "Given that HCF(a, b) = 12, LCM(a, b) = 180, and a = 36, find b using the prime-Venn invariant HCF × LCM = a × b.",
            "b = 60"
        ),
        (
            2, "2.2", 4, "w_algebra_area_tiles",
            "Expand and simplify 4(2x − 3) − 3(x − 5), and explain using the area/number-line model why the constant term becomes +3.",
            "Step 1: Distribute 4 across (2x − 3) → 8x − 12.\nStep 2: Distribute −3 across (x − 5) → −3x + 15 (since (−3)(−5) = +15).\nStep 3: Collect like terms: (8x − 3x) + (−12 + 15) = 5x + 3.",
            "4(2x − 3) − 3(x − 5) = 8x − 12 − 3x + ___ = ___.",
            "5x + 3",
            "5x + 3 because 4(2x − 3) = 8x − 12 and −3(x − 5) = −3x + 15, giving 5x + 3.",
            ["5x", "+ 3", "+15"],
            "Factorise completely: 18a²b − 12ab².",
            "6ab(3a − 2b)",
            "A rectangle of length (2x + 5) cm and width 6 cm has a smaller rectangle of length (x − 2) cm and width 4 cm cut from its interior. Write a simplified expression for the remaining area.",
            "8x + 38 cm²",
            "Using the Difference of Two Squares identity a² − b² = (a − b)(a + b), evaluate 2026² − 2024² mentally without a calculator.",
            "8100"
        ),
        (
            3, "3.3", 9, "w_bearings_back_bearing_radar",
            "A coastguard boat sails from Mumbai Harbour (M) on a three-figure bearing of 068° to a buoy (B). Calculate the back-bearing of Mumbai Harbour (M) from the buoy (B).",
            "Step 1: Draw North arrows at both M and B (parallel vertical lines).\nStep 2: Co-interior angles between North lines add to 180°, or extend the ray MB: a straight line is 180°.\nStep 3: Since 068° < 180°, Back-bearing = 068° + 180° = 248°.",
            "Because North lines are parallel, the back-bearing from B to M is 068° + 180° = ___.",
            "248°",
            "248° because the clockwise angle from North at B equals 068° + 180° = 248° by alternate angles on parallel North lines.",
            ["248", "180", "parallel", "North"],
            "A convex polyhedron has 8 faces (F = 8) and 6 vertices (V = 6). Using Euler's formula V − E + F = 2, find the number of edges E.",
            "12 edges",
            "Triangle ABC is constructed with AB = 8 cm, AC = 6 cm, and BC = 10 cm. Which angle is 90°, and what locus does the perpendicular bisector of AB represent?",
            "Angle BAC = 90°; locus equidistant from A and B",
            "A ship sails 12 km on a bearing of 040° and then 16 km on a bearing of 130°. Find its direct distance from the starting port.",
            "20 km"
        ),
        (
            4, "4.2", 13, "w_wald_survivorship_bomber",
            "A school has 240 Year 7 students, 180 Year 8 students, and 180 Year 9 students (600 total). Design a stratified sample of 50 students.",
            "Step 1: Total population N = 240 + 180 + 180 = 600; sample size n = 50.\nStep 2: Year 7 stratum = (240 / 600) × 50 = 20 students.\nStep 3: Year 8 stratum = (180 / 600) × 50 = 15 students; Year 9 = 15 students.",
            "Year 7 = (240/600) × 50 = ___, Year 8 = ___, Year 9 = ___.",
            "20, 15, 15",
            "Select 20 Year 7 students, 15 Year 8 students, and 15 Year 9 students at random within each year group so every stratum is represented in proportion Nᵢ / N.",
            ["20", "15", "600", "proportion"],
            "To select 20 students from an alphabetical list of 600 using systematic sampling, what sampling interval k should be used?",
            "Every 30th student (k = 30)",
            "Why would surveying only people leaving a sports gym at 6 am produce a biased estimate of average weekly exercise in Mumbai?",
            "Selection bias towards habitual early-morning exercisers",
            "If the standard error of a sample mean is SE = σ / √n, by what factor must the sample size n increase to cut the error bar in half?",
            "Multiply sample size by 4"
        ),
        (
            5, "5.2", 10, "w_trapezium_prism_slicer",
            "A rainwater trough is a prism of length 2.5 m whose cross-section is a trapezium with parallel sides 40 cm and 60 cm and perpendicular height 30 cm. Find its capacity in litres.",
            "Step 1: Cross-sectional trapezium area A = ½(40 + 60) × 30 = 50 × 30 = 1500 cm².\nStep 2: Convert length 2.5 m = 250 cm.\nStep 3: Volume V = 1500 × 250 = 375,000 cm³ = 375 litres (since 1000 cm³ = 1 L).",
            "A = ½(40 + 60) × 30 = 1500 cm²; V = 1500 × 250 cm = ___ litres.",
            "375 litres",
            "375 litres because the trapezium cross-section has area ½(40 + 60) × 30 = 1500 cm² and multiplying by length 250 cm gives 375,000 cm³ = 375 L.",
            ["1500", "375", "trapezium"],
            "Find the exact circumference and area of a circle of radius r = 7 cm (use π ≈ 22/7).",
            "C = 44 cm, A = 154 cm²",
            "A parallelogram has base 14 cm, slanted side 10 cm, and perpendicular height 8 cm. Calculate its perimeter and its area.",
            "Perimeter = 48 cm, Area = 112 cm²",
            "An circular pizza of radius 10 cm is cut into 6 equal sectors. Find the perimeter of one sector to 1 decimal place.",
            "30.5 cm"
        ),
        (
            6, "6.3", 2, "w_recurring_decimal_tail_canceller",
            "Prove algebraically that the recurring decimal x = 0.272727… (0.2̇7̇) equals 3/11 in simplest form.",
            "Step 1: Let x = 0.272727… (period k = 2 digits).\nStep 2: Multiply by 10² = 100: 100x = 27.272727…\nStep 3: Subtract x: 99x = 27 ⇒ x = 27/99 = 3/11.",
            "100x = 27.2727… and x = 0.2727…, so 99x = 27 and x = 27/99 = ___.",
            "3/11",
            "3/11 because 100x − x = 99x = 27, so x = 27/99 which simplifies on dividing by 9 to 3/11.",
            ["99x", "27", "3/11"],
            "Round 0.0040862 to 3 significant figures.",
            "0.00409",
            "Work out 4 1/6 − 1 3/4 as a mixed number in simplest form.",
            "2 5/12",
            "Find the exact value of (2 2/5 ÷ 1 1/15) × 5/9.",
            "5/4 or 1 1/4"
        ),
        (
            7, "7.3", 5, "w_formula_subject_transposer",
            "Make u the subject of the kinematic formula v² = u² + 2as (assuming u > 0), and find u when v = 13, a = 6, s = 10.",
            "Step 1: Subtract 2as from both sides: u² = v² − 2as.\nStep 2: Take the positive square root: u = √(v² − 2as).\nStep 3: Substitute: u = √(13² − 2 × 6 × 10) = √(169 − 120) = √49 = 7.",
            "u² = v² − 2as ⇒ u = √(v² − 2as) = √(169 − 120) = ___.",
            "u = 7",
            "u = √(v² − 2as) = 7 because subtracting 2as isolates u² = 169 − 120 = 49.",
            ["v^2 - 2as", "49", "7"],
            "Solve the equation 5(2x − 1) = 3(x + 4) + 4.",
            "x = 3",
            "Solve the inequality 14 − 3x ≥ 2 and state the largest integer x that satisfies it.",
            "x ≤ 4 (largest integer 4)",
            "Make x the subject of the rational formula y = (3x + 2) / (x − 1).",
            "x = (y + 2) / (y − 3)"
        ),
        (
            8, "8.1", 8, "w_exterior_angle_tear_proof",
            "In triangle ABC, side BC is extended to D. Given ∠BAC = (2x + 15)°, ∠ABC = (x + 20)°, and exterior angle ∠ACD = (4x − 5)°, find x and ∠ACD.",
            "Step 1: By the Exterior Angle Theorem, ∠ACD = ∠BAC + ∠ABC.\nStep 2: 4x − 5 = (2x + 15) + (x + 20) = 3x + 35.\nStep 3: Subtract 3x and add 5: x = 40°. Thus ∠ACD = 4(40) − 5 = 155°.",
            "4x − 5 = 3x + 35 ⇒ x = ___ and ∠ACD = ___.",
            "x = 40, ∠ACD = 155°",
            "x = 40 and ∠ACD = 155° because the exterior angle equals the sum of the two opposite interior angles: 4x − 5 = 3x + 35.",
            ["40", "155", "exterior"],
            "Find the midpoint M of the line segment joining A(−4, 7) and B(10, −3).",
            "M = (3, 2)",
            "Two parallel lines are cut by a transversal. The co-interior angles are (3y + 10)° and (2y − 5)°. Find y.",
            "y = 35",
            "Each interior angle of a regular polygon is 156°. How many sides n does the polygon have?",
            "15 sides (exterior angle = 24°, 360/24 = 15)"
        ),
        (
            9, "9.3", 3, "w_compound_multiplier_machine",
            "After a 15% monsoon discount, a jacket costs ₹2,040. Using a reverse-percentage multiplier, find its original price before the discount.",
            "Step 1: A 15% decrease leaves 100% − 15% = 85% = 0.85 of the original price P.\nStep 2: 0.85 × P = 2040.\nStep 3: Divide by 0.85: P = 2040 ÷ 0.85 = 204000 ÷ 85 = ₹2,400.",
            "0.85 × Original = 2040 ⇒ Original = 2040 ÷ 0.85 = ₹___.",
            "₹2,400",
            "₹2,400 because a 15% reduction corresponds to multiplying the original price by 0.85, so dividing ₹2,040 by 0.85 restores ₹2,400.",
            ["0.85", "2400", "divide"],
            "Evaluate 36 ÷ 0.15 without a calculator.",
            "240",
            "A price increases by 20% and then decreases by 20%. What is the net percentage change?",
            "−4% (a 4% decrease, since 1.2 × 0.8 = 0.96)",
            "₹50,000 is invested at 10% per annum compound interest for 3 years. Find the total interest earned.",
            "₹16,550 (Total = ₹66,550)"
        ),
        (
            10, "10.3", 14, "w_histogram_frequency_density",
            "In a continuous mass survey, the class interval 40 ≤ m < 60 kg has frequency 30, and 60 ≤ m < 70 kg has frequency 25. Calculate the Frequency Density of each class.",
            "Step 1: Class 1 width Δx₁ = 60 − 40 = 20 kg ⇒ FD₁ = 30 ÷ 20 = 1.5.\nStep 2: Class 2 width Δx₂ = 70 − 60 = 10 kg ⇒ FD₂ = 25 ÷ 10 = 2.5.\nStep 3: Even though Class 1 has higher raw count (30 vs 25), Class 2 is more densely packed (FD 2.5 vs 1.5).",
            "FD₁ = 30/20 = ___ and FD₂ = 25/10 = ___.",
            "1.5 and 2.5",
            "FD₁ = 1.5 and FD₂ = 2.5 because Frequency Density = Frequency ÷ Class Width.",
            ["1.5", "2.5", "density", "width"],
            "Find the median and interquartile range (IQR) of the ordered dataset: 12, 15, 17, 20, 24, 29, 31.",
            "Median = 20, IQR = 29 − 15 = 14",
            "Compute the population standard deviation σ of the five numbers: 4, 6, 8, 10, 12.",
            "σ = √8 ≈ 2.83 (mean μ = 8)",
            "A histogram bar for 10 ≤ t < 25 s has Frequency Density 3.2. How many observations lie in this class?",
            "48 observations (15 × 3.2)"
        ),
        (
            11, "11.2", 6, "w_gauss_staircase_sum",
            "Find the nth term formula Tₙ of the linear sequence 7, 11, 15, 19, 23, … and calculate the sum S₂₀ of its first 20 terms using Gauss's pairing method.",
            "Step 1: Common difference d = +4; 0th term c = 7 − 4 = 3 ⇒ Tₙ = 4n + 3.\nStep 2: 20th term T₂₀ = 4(20) + 3 = 83.\nStep 3: Gauss Sum S₂₀ = (20 / 2) × (T₁ + T₂₀) = 10 × (7 + 83) = 900.",
            "Tₙ = 4n + 3, T₂₀ = 83, and S₂₀ = 10 × (7 + 83) = ___.",
            "Tₙ = 4n + 3, S₂₀ = 900",
            "Tₙ = 4n + 3 and S₂₀ = 900 because pairing the 20 terms from both ends gives 10 pairs each summing to 7 + 83 = 90.",
            ["4n + 3", "83", "900"],
            "Does the number 150 belong to the sequence Tₙ = 4n + 3? Justify your answer algebraically.",
            "No, because 4n + 3 = 150 gives 4n = 147, which is not an integer",
            "Find the nth term of the quadratic sequence 3, 8, 15, 24, 35, …",
            "Tₙ = n² + 2n",
            "Using Gauss's staircase formula, evaluate 1 + 2 + 3 + … + 200.",
            "20,100"
        ),
        (
            12, "12.3", 3, "w_singapore_ratio_bar_model",
            "Kym, Aarav, and Meera share a prize in the ratio 3 : 5 : 8. Given that Meera receives ₹1,350 more than Kym, find the total prize using a Singapore Bar Model.",
            "Step 1: Meera has 8 units and Kym has 3 units; difference = 8 − 3 = 5 units.\nStep 2: 5 units = ₹1,350 ⇒ 1 unit = 1350 ÷ 5 = ₹270.\nStep 3: Total units = 3 + 5 + 8 = 16 units ⇒ Total prize = 16 × ₹270 = ₹4,320.",
            "8 − 3 = 5 units = ₹1,350 ⇒ 1 unit = ₹270 ⇒ 16 units = ₹___.",
            "₹4,320",
            "₹4,320 because the 5-unit difference between Meera (8) and Kym (3) equals ₹1,350, making 1 unit = ₹270 and all 16 units = ₹4,320.",
            ["5 units", "270", "4320"],
            "Convert 3.5 m² into cm².",
            "35,000 cm² (multiply by 100² = 10,000)",
            "6 pumps working together empty a flooded basement in 10 hours. How long will 15 identical pumps take?",
            "4 hours (inverse proportion: 6 × 10 = 60 pump-hours ÷ 15 = 4)",
            "The ratio A : B = 3 : 4 and B : C = 6 : 7. Find the combined three-way ratio A : B : C in simplest integer form.",
            "9 : 12 : 14"
        ),
        (
            13, "13.5", 11, "w_enlargement_ray_scaler",
            "Triangle T has area 6 cm² and vertex A(2, 3). It is enlarged by scale factor k = 3 about centre C(1, 1). Find the coordinates of image A′ and the area of image T′.",
            "Step 1: Displacement from C(1, 1) to A(2, 3) is CA = (2−1, 3−1) = (1, 2).\nStep 2: Multiply ray by k = 3: CA′ = 3 × (1, 2) = (3, 6) ⇒ A′ = (1+3, 1+6) = (4, 7).\nStep 3: Area scales by k² = 3² = 9: Area(T′) = 9 × 6 = 54 cm².",
            "CA = (1, 2) ⇒ CA′ = (3, 6) ⇒ A′ = (4, 7), and Area(T′) = 3² × 6 = ___ cm².",
            "A′ = (4, 7), Area = 54 cm²",
            "A′ = (4, 7) and Area = 54 cm² because linear rays from (1, 1) multiply by k = 3 while 2D area multiplies by k² = 9.",
            ["(4, 7)", "54", "k^2", "9"],
            "Reflect the point P(−3, 5) in the line y = x.",
            "P′ = (5, −3)",
            "Rotate the point Q(4, 1) by 90° anticlockwise about the origin (0, 0).",
            "Q′ = (−1, 4)",
            "Enlarge the point R(5, 3) by negative scale factor k = −2 about centre C(3, 2).",
            "R′ = (−1, 0)"
        ),
        (
            14, "14.2", 7, "w_linear_graph_slope_explorer",
            "Find the equation of the straight line passing through A(−2, 1) and B(4, 13) in the form y = mx + c, and state where it crosses the x-axis.",
            "Step 1: Gradient m = (13 − 1) / (4 − (−2)) = 12 / 6 = 2.\nStep 2: Substitute (4, 13) into y = 2x + c ⇒ 13 = 8 + c ⇒ c = 5, so y = 2x + 5.\nStep 3: x-intercept (y = 0): 2x + 5 = 0 ⇒ x = −2.5.",
            "m = 12/6 = 2, y = 2x + 5, and at y = 0, x = ___.",
            "y = 2x + 5, x-intercept = −2.5",
            "y = 2x + 5 and x-intercept (−2.5, 0) because the rise 12 over run 6 gives gradient m = 2.",
            ["2x + 5", "-2.5", "gradient"],
            "For the function f(x) = 3x − 7, find the inverse function f⁻¹(x).",
            "f⁻¹(x) = (x + 7) / 3",
            "Find the equation of the line perpendicular to y = 2x + 5 that passes through (0, 3).",
            "y = −½x + 3",
            "Find the point of intersection of the lines y = 3x − 2 and x + 2y = 10.",
            "(2, 4)"
        ),
        (
            15, "15.4", 16, "w_atlas_bayes_square",
            "A rare genetic trait occurs in 2% of a population (P(D) = 0.02). A screening test has 95% sensitivity (P(+|D) = 0.95) and a 5% false-positive rate (P(+|¬D) = 0.05). Out of 1,000 people, find the number of True Positives, False Positives, and P(D | +).",
            "Step 1 (Natural Frequencies of 1,000): 20 people have D → 0.95 × 20 = 19 test positive (TP).\nStep 2: 980 people do not have D → 0.05 × 980 = 49 test positive (FP).\nStep 3 (Bayes' Rule): Total positive tests = 19 + 49 = 68 ⇒ P(D | +) = 19 / 68 ≈ 27.9%.",
            "TP = 19, FP = 49, so P(D | +) = 19 / (19 + 49) = ___.",
            "19/68 ≈ 27.9%",
            "P(D | +) = 19/68 ≈ 27.9% because among 1,000 people there are 19 true positives and 49 false positives.",
            ["19", "49", "68", "27.9"],
            "Two fair six-sided dice are rolled. What is the probability that their sum is 9?",
            "4/36 = 1/9",
            "A bag contains 5 red and 3 blue marbles. Two marbles are drawn without replacement. Find the probability that both are red.",
            "20/56 = 5/14",
            "How many 3-person committees can be chosen from 8 students (⁸C₃)?",
            "56 committees"
        ),
        (
            16, "16.2", 19, "w_vector_geometric_proof_studio",
            "Given column vectors a = (3, 4)ᵀ and b = (2, −1)ᵀ, calculate 2a − 3b and find the exact magnitude |a|.",
            "Step 1: 2a − 3b = 2(3, 4)ᵀ − 3(2, −1)ᵀ = (6 − 6, 8 − (−3))ᵀ = (0, 11)ᵀ.\nStep 2: By Pythagoras, |a| = √(3² + 4²) = √(9 + 16) = √25 = 5.",
            "2a − 3b = (0, 11)ᵀ and |a| = √(3² + 4²) = ___.",
            "(0, 11)ᵀ and |a| = 5",
            "2a − 3b = (0, 11)ᵀ and |a| = 5 because componentwise subtraction gives (6−6, 8+3) and √(3²+4²) = 5.",
            ["(0, 11)", "5", "Pythagoras"],
            "If AB = (4, −2)ᵀ and BC = (−1, 7)ᵀ, find the resultant vector AC.",
            "AC = (3, 5)ᵀ",
            "In triangle OAB, OA = a, OB = b, M is the midpoint of OA, and N is the midpoint of OB. Express MN in terms of a and b.",
            "MN = ½(b − a) = ½AB",
            "Calculate the determinant det(A) = ad − bc of the 2×2 transformation matrix A = [[3, 1], [2, 4]], and state how much it scales the area of a triangle of area 5 cm².",
            "det(A) = 10; new area = 50 cm²"
        ),
    ]

    questions = []
    for (
        u_num, topic_code, ch_num, wid,
        sb_prompt, sb_worked, sb_faded, sb_faded_ans, sb_model, sb_keywords,
        t1_q, t1_a, t2_q, t2_a, t3_q, t3_a
    ) in chapter_question_specs:
        # 1. Student Book Consolidation item
        questions.append({
            "id": f"q-oup-ch{u_num:02d}-sb",
            "unitNumber": u_num,
            "topicCode": topic_code,
            "sourceBook": "learners_book",
            "bookSection": f"OUP Ch {u_num} Consolidation",
            "tier": "Consolidation",
            "commandWord": "Calculate & Prove",
            "marks": 3,
            "prompt": sb_prompt,
            "workedExample": sb_worked,
            "fadedPrompt": sb_faded,
            "fadedAnswer": sb_faded_ans,
            "modelAnswer": sb_model,
            "markSchemeKeywords": sb_keywords,
            "linkedChapter": ch_num,
            "linkedWidget": wid,
        })
        # 2. Built-In Companion Workbook — Tier 1 (Focus / Fluency)
        questions.append({
            "id": f"q-oup-ch{u_num:02d}-wb-focus",
            "unitNumber": u_num,
            "topicCode": topic_code,
            "sourceBook": "workbook",
            "bookSection": f"Companion Workbook Ch {u_num} · Tier 1",
            "tier": "Focus",
            "commandWord": "Work out",
            "marks": 2,
            "prompt": t1_q,
            "workedExample": f"Apply the core invariant of {topic_code} step by step.",
            "fadedPrompt": f"Target result for {topic_code}: ___",
            "fadedAnswer": t1_a,
            "modelAnswer": t1_a,
            "markSchemeKeywords": [t1_a.split()[0]],
            "linkedChapter": ch_num,
            "linkedWidget": wid,
        })
        # 3. Built-In Companion Workbook — Tier 2 (Practice / Singapore Bar-Model & Checkpoint)
        questions.append({
            "id": f"q-oup-ch{u_num:02d}-wb-practice",
            "unitNumber": u_num,
            "topicCode": topic_code,
            "sourceBook": "workbook",
            "bookSection": f"Companion Workbook Ch {u_num} · Tier 2 (Singapore CPA)",
            "tier": "Practice",
            "commandWord": "Model & Solve",
            "marks": 3,
            "prompt": t2_q,
            "workedExample": f"Sketch the Singapore Bar Model or geometric diagram first, then solve: {t2_a}.",
            "fadedPrompt": f"Singapore Bar-Model solution: ___",
            "fadedAnswer": t2_a,
            "modelAnswer": t2_a,
            "markSchemeKeywords": [t2_a.split()[0]],
            "linkedChapter": ch_num,
            "linkedWidget": wid,
        })
        # 4. Built-In Companion Workbook — Tier 3 (Challenge / Olympiad & Horizon Stretch)
        questions.append({
            "id": f"q-oup-ch{u_num:02d}-wb-challenge",
            "unitNumber": u_num,
            "topicCode": topic_code,
            "sourceBook": "workbook",
            "bookSection": f"Companion Workbook Ch {u_num} · Tier 3 (Olympiad & Horizon)",
            "tier": "Challenge",
            "commandWord": "Prove & Generalise",
            "marks": 4,
            "prompt": t3_q,
            "workedExample": f"Bridge from visual intuition to the symbolic invariant: {t3_a}.",
            "fadedPrompt": f"Horizon invariant result: ___",
            "fadedAnswer": t3_a,
            "modelAnswer": t3_a,
            "markSchemeKeywords": [t3_a.split()[0]],
            "linkedChapter": ch_num,
            "linkedWidget": wid,
        })
    return questions


def build_diagram_plates():
    specs = [
        ("plate-01-venn-demorgan", "Venn Inclusion–Exclusion & De Morgan Regions", "Patterned World Ch 0 · Set Theory", 1, 0, "fig-venn", [
            ("p1-c1", "A ∩ B (Intersection)", 0.50, 0.48, "Overlap of sets A and B"),
            ("p1-c2", "A ∩ B′ (Only A)", 0.30, 0.48, "Elements in A but not B"),
            ("p1-c3", "A′ ∩ B (Only B)", 0.70, 0.48, "Elements in B but not A"),
            ("p1-c4", "(A ∪ B)′ = A′ ∩ B′", 0.16, 0.20, "Exterior complement (De Morgan)"),
        ]),
        ("plate-02-prime-venn", "Prime Factor Venn Diagram (HCF & LCM)", "OUP Ch 1.4 p. 16", 1, 1, "fig-prime-venn", [
            ("p2-c1", "HCF (Shared Prime Overlap)", 0.50, 0.50, "Intersection product = HCF"),
            ("p2-c2", "Unique Primes of A", 0.28, 0.50, "Left crescent factors"),
            ("p2-c3", "Unique Primes of B", 0.72, 0.50, "Right crescent factors"),
            ("p2-c4", "LCM (Product of All Regions)", 0.50, 0.84, "Union product = LCM"),
        ]),
        ("plate-03-algebra-area", "Area-Array Expansion (x + a)(x + b)", "OUP Ch 2.2 p. 28", 2, 4, "fig-area-tiles", [
            ("p3-c1", "x² (Main Square Tile)", 0.34, 0.36, "Top-left x by x square"),
            ("p3-c2", "ax (Right Strip)", 0.72, 0.36, "Top-right a by x rectangle"),
            ("p3-c3", "bx (Bottom Strip)", 0.34, 0.74, "Bottom-left x by b rectangle"),
            ("p3-c4", "ab (Corner Product)", 0.72, 0.74, "Bottom-right a by b corner"),
        ]),
        ("plate-04-euclid-bisector", "Compass Perpendicular & Angle Bisector Locus", "OUP Ch 3.5 p. 50", 3, 9, "fig-bisector", [
            ("p4-c1", "Endpoint A (Compass Centre 1)", 0.24, 0.50, "Left anchor point"),
            ("p4-c2", "Endpoint B (Compass Centre 2)", 0.76, 0.50, "Right anchor point"),
            ("p4-c3", "Arc Intersection P (|PA| = |PB|)", 0.50, 0.20, "Upper rhombus vertex"),
            ("p4-c4", "Perpendicular Bisector (90° Midpoint)", 0.50, 0.50, "Equidistant locus line PQ"),
        ]),
        ("plate-05-bearings-north", "Three-Figure Bearing & Back-Bearing Geometry", "OUP Ch 3.3 p. 44", 3, 9, "fig-bearings", [
            ("p5-c1", "North Reference Arrow (000°)", 0.28, 0.20, "Vertical North line at A"),
            ("p5-c2", "Clockwise Forward Bearing θ", 0.36, 0.38, "3-digit angle from North"),
            ("p5-c3", "Co-interior Angle (180° − θ)", 0.62, 0.44, "Supplementary angle at B"),
            ("p5-c4", "Back-Bearing (θ + 180°)", 0.72, 0.64, "Clockwise reflex angle at B"),
        ]),
        ("plate-06-circle-sectors", "Circle Sector Rearrangement (A = πr²)", "OUP Ch 5.1 p. 66", 5, 10, "fig-circle-pi", [
            ("p6-c1", "Radius r (Vertical Height)", 0.20, 0.52, "Upright side of rearranged comb"),
            ("p6-c2", "Half-Circumference πr (Base)", 0.54, 0.80, "Bottom scalloped arc length"),
            ("p6-c3", "Alternating Sector Wedge", 0.48, 0.48, "1 of 24 comb-interlocked sectors"),
            ("p6-c4", "Area = πr × r = πr²", 0.78, 0.32, "Resulting rectangle formula"),
        ]),
        ("plate-07-trapezium-prism", "Trapezium Shear & Triangular Prism Net", "OUP Ch 5.2–5.4 pp. 69–75", 5, 10, "fig-trapezium", [
            ("p7-c1", "Top Parallel Side a", 0.42, 0.24, "Upper parallel edge"),
            ("p7-c2", "Bottom Parallel Side b", 0.48, 0.76, "Lower parallel edge"),
            ("p7-c3", "Perpendicular Height h", 0.30, 0.50, "90° altitude (never slanted side)"),
            ("p7-c4", "Doubled Base (a + b)", 0.76, 0.50, "Flipped copy makes parallelogram"),
        ]),
        ("plate-08-parallel-angles", "Parallel Transversal & Exterior Angle Proof", "OUP Ch 8.1–8.2 pp. 128–130", 8, 8, "fig-parallel", [
            ("p8-c1", "Alternate Angle (Z-Angle)", 0.46, 0.44, "Equal interior alternate angle"),
            ("p8-c2", "Corresponding Angle (F-Angle)", 0.62, 0.28, "Translated intersection angle"),
            ("p8-c3", "Co-interior Pair (Sums to 180°)", 0.54, 0.58, "C-angles between parallels"),
            ("p8-c4", "Exterior Angle = α + β", 0.80, 0.72, "Sum of remote interior angles"),
        ]),
        ("plate-09-histogram-stem", "Frequency Density Histogram & Box-Whisker Quartiles", "OUP Ch 10.3 p. 154", 10, 14, "fig-histogram", [
            ("p9-c1", "Class Width Δx", 0.36, 0.82, "Horizontal interval span"),
            ("p9-c2", "Frequency Density = f / Δx", 0.22, 0.42, "Vertical axis height"),
            ("p9-c3", "Bar Area = Frequency f", 0.42, 0.52, "FD × Δx = exact count"),
            ("p9-c4", "Interquartile Range (Q₃ − Q₁)", 0.76, 0.34, "Middle 50% spread box"),
        ]),
        ("plate-10-singapore-bar", "Singapore Unitary & Before/After Ratio Bar Model", "OUP Ch 12.3 p. 188", 12, 3, "fig-bar-model", [
            ("p10-c1", "1 Equal Unit Box", 0.26, 0.36, "Fundamental unitary block"),
            ("p10-c2", "Known Difference Bracket", 0.72, 0.36, "Extra units = Δvalue"),
            ("p10-c3", "Total Brace ∑ Units", 0.86, 0.56, "Sum of all parts"),
            ("p10-c4", "Invariant Quantity", 0.48, 0.78, "Unchanged reference in Before/After"),
        ]),
        ("plate-11-enlargement-rays", "Enlargement Ray Centre & k² Area Scaling", "OUP Ch 13.5 p. 204", 13, 11, "fig-enlargement", [
            ("p11-c1", "Centre of Enlargement C", 0.16, 0.76, "Ray origin point"),
            ("p11-c2", "Object Vertex P (1× distance)", 0.40, 0.56, "Original shape corner"),
            ("p11-c3", "Image Vertex P′ (k× distance)", 0.74, 0.28, "Scaled ray destination"),
            ("p11-c4", "k² Tiled Area Copies", 0.68, 0.54, "Area scales as square of k"),
        ]),
        ("plate-12-linear-slope", "Linear Graph y = mx + c & Perpendicular Gradient", "OUP Ch 14.2 p. 215", 14, 7, "fig-linear", [
            ("p12-c1", "y-Intercept (0, c)", 0.28, 0.66, "Crossing on vertical axis"),
            ("p12-c2", "Horizontal Run Δx", 0.52, 0.66, "Step to the right"),
            ("p12-c3", "Vertical Rise Δy = m · Δx", 0.68, 0.42, "Upward climb"),
            ("p12-c4", "Perpendicular Line (m₂ = −1/m)", 0.44, 0.30, "90° rotated slope triangle"),
        ]),
        ("plate-13-unit-circle-trig", "Unit Circle Shadows (sin θ, cos θ, tan θ & sin²θ+cos²θ=1)", "Atlas of Maths Ch 1 · Unit Circle", 16, 12, "fig-unit-circle", [
            ("p13-c1", "Point P = (cos θ, sin θ)", 0.68, 0.30, "Radius-1 point at angle θ"),
            ("p13-c2", "Red Vertical Shadow sin θ", 0.68, 0.52, "Opposite leg / level-light shadow"),
            ("p13-c3", "Blue Horizontal Shadow cos θ", 0.48, 0.68, "Adjacent leg / top-light shadow"),
            ("p13-c4", "Tangent Height tan θ on x = 1", 0.84, 0.24, "Extended ray intersection"),
        ]),
        ("plate-14-bayes-square", "Bayes 1,000-Person Unit Square & Posterior P(D | +)", "Atlas of Stats Fig S.3 · Bayes", 15, 16, "fig-bayes", [
            ("p14-c1", "Base Rate Strip p = P(D)", 0.22, 0.82, "Narrow diseased column width"),
            ("p14-c2", "True Positives TP = p · sens (Red)", 0.22, 0.42, "Sick people testing positive"),
            ("p14-c3", "False Positives FP = (1−p) · fp (Amber)", 0.56, 0.72, "Healthy people testing positive"),
            ("p14-c4", "Posterior Bar TP / (TP + FP)", 0.86, 0.46, "Renormalized positive cohort"),
        ]),
        ("plate-15-calculus-ftc", "Secant-to-Tangent Derivative & Riemann Area (FTC)", "Atlas of Maths Ch 2 · Calculus", 14, 17, "fig-calculus", [
            ("p15-c1", "Horizontal Step h = Δx", 0.42, 0.72, "Run between P and Q"),
            ("p15-c2", "Vertical Rise Δy = f(x+h)−f(x)", 0.58, 0.48, "Secant rise"),
            ("p15-c3", "Tangent Slope Limit f′(x)", 0.32, 0.40, "Instantaneous rate as h → 0"),
            ("p15-c4", "Riemann Strip f(xᵢ) Δx", 0.78, 0.58, "Accumulated integral area"),
        ]),
        ("plate-16-vectors-matrices", "Vector Triangle Law & 2×2 Matrix Determinant Area", "OUP Ch 16 & Atlas Linear Algebra", 16, 20, "fig-matrices", [
            ("p16-c1", "First Basis Column Aî = (a, c)", 0.46, 0.68, "Red landed unit x-vector"),
            ("p16-c2", "Second Basis Column Aĵ = (b, d)", 0.30, 0.34, "Blue landed unit y-vector"),
            ("p16-c3", "Parallelogram Area det(A) = ad − bc", 0.54, 0.46, "Signed 2D area scale factor"),
            ("p16-c4", "Eigenvector Axis (A v = λ v)", 0.78, 0.24, "Invariant unrotated direction"),
        ]),
    ]

    plates = []
    for pid, title, ref, u_num, ch_num, fig_id, callouts in specs:
        plates.append({
            "id": pid,
            "title": title,
            "sourceRef": ref,
            "unitNumber": u_num,
            "chapter": ch_num,
            "figureId": fig_id,
            "aspectRatio": 1.5,
            "callouts": [
                {"id": cid, "label": lbl, "x": x, "y": y, "hint": hint}
                for cid, lbl, x, y, hint in callouts
            ],
        })
    return plates


def build_polya_stages():
    return [
        {
            "id": "polya-1-understand",
            "phaseNumber": 1,
            "title": "1. Understand the Problem",
            "subtitle": "Isolate the unknown, the given data, and the governing condition",
            "symbol": "magnifyingglass.circle.fill",
            "prompts": [
                "What is the unknown? Can I name it or draw it as a Singapore bar segment?",
                "What are the data and units? Are any quantities hidden in words like 'bisects', 'regular', or 'independent'?",
                "What is the invariant condition linking the data to the unknown? Is it enough to determine the unknown?",
            ],
            "exampleProblem": "A train passes a 300 m platform in 24 seconds and passes a standing lamp-post in 9 seconds at constant speed. Find the length of the train.",
            "phaseBreakdown": "Unknown: Train length L. Data: Lamp-post time = 9 s (covers L only); Platform time = 24 s (covers L + 300 m). Invariant: Speed v is constant!",
        },
        {
            "id": "polya-2-plan",
            "phaseNumber": 2,
            "title": "2. Devise a Plan",
            "subtitle": "Select a heuristic: Draw a Bar Model, Try a Simpler Case, Work Backwards, or Look for Symmetry",
            "symbol": "map.fill",
            "prompts": [
                "Can I draw a Concrete → Pictorial bar model or auxiliary geometric line?",
                "What happens in a tiny case (n = 1, 2, 3) — does a pattern of differences emerge?",
                "Can I work backwards from the target or use an extreme case (h → 0, θ = 0° or 90°)?",
            ],
            "exampleProblem": "Compare the two journeys of the train on a single Singapore distance bar.",
            "phaseBreakdown": "Draw two bars: Bar 1 = [Train L] takes 9 s. Bar 2 = [Train L] + [300 m] takes 24 s. The extra 300 m alone takes 24 − 9 = 15 s!",
        },
        {
            "id": "polya-3-execute",
            "phaseNumber": 3,
            "title": "3. Carry Out the Plan",
            "subtitle": "Execute each algebraic or geometric step and check that every step is reversible",
            "symbol": "hammer.fill",
            "prompts": [
                "Can I prove that each step follows from the line above it?",
                "Did I keep units and signs consistent across every operation?",
                "Can I see the geometric meaning of the intermediate number?",
            ],
            "exampleProblem": "Compute the train's speed from the 15-second difference and find L.",
            "phaseBreakdown": "Speed v = 300 m ÷ 15 s = 20 m/s. Since passing the lamp-post takes 9 s, Train length L = 20 m/s × 9 s = 180 m.",
        },
        {
            "id": "polya-4-look-back",
            "phaseNumber": 4,
            "title": "4. Look Back & Generalise",
            "subtitle": "Sanity-check dimensions, test a second method, and turn the result into a reusable formula",
            "symbol": "sparkles.rectangle.stack.fill",
            "prompts": [
                "Does the answer survive a substitution check in the original problem?",
                "Can I derive the general formula for any platform length P and times t₁, t₂?",
                "Where else can I use this 'subtract the two states to isolate the difference' trick?",
            ],
            "exampleProblem": "Verify L = 180 m and write the universal formula.",
            "phaseBreakdown": "Check: (180 + 300) m ÷ 20 m/s = 480 ÷ 20 = 24 s ✓. General Formula: L = P · t₁ / (t₂ − t₁).",
        },
    ]


def build_speed_math_decks():
    return [
        {
            "id": "deck-diff-squares",
            "title": "Difference of Squares Mental Multiplier",
            "subtitle": "Compute (a − b)(a + b) = a² − b² in 2 seconds",
            "heuristic": "Spot the midpoint a and half-gap b: 47 × 53 = (50 − 3)(50 + 3) = 2500 − 9 = 2491.",
            "cards": [
                {"prompt": "38 × 42", "hint": "(40 − 2)(40 + 2)", "answer": "1596"},
                {"prompt": "65² − 35²", "hint": "(65 − 35)(65 + 35)", "answer": "3000"},
                {"prompt": "96 × 104", "hint": "(100 − 4)(100 + 4)", "answer": "9984"},
                {"prompt": "29 × 31", "hint": "30² − 1²", "answer": "899"},
            ],
        },
        {
            "id": "deck-fractions-percents",
            "title": "Fraction · Decimal · Percentage Reflexes",
            "subtitle": "Instant conversion & reciprocal division",
            "heuristic": "Turn division by a decimal into multiplication by its integer reciprocal (÷ 0.125 = × 8).",
            "cards": [
                {"prompt": "45 ÷ 0.125", "hint": "0.125 = 1/8, so 45 × 8", "answer": "360"},
                {"prompt": "0.3̇6̇ as a simplest fraction", "hint": "36 / 99 ÷ 9", "answer": "4/11"},
                {"prompt": "37.5% of 240", "hint": "3/8 × 240", "answer": "90"},
                {"prompt": "Original price if −20% gives ₹640", "hint": "640 ÷ 0.8", "answer": "800"},
            ],
        },
        {
            "id": "deck-indices-surds",
            "title": "Index Laws, Roots & Surd Simplifier",
            "subtitle": "Negative/fractional powers & prime squares",
            "heuristic": "a⁻ⁿ = 1/aⁿ and √(k²m) = k√m.",
            "cards": [
                {"prompt": "2⁵ × 2⁻²", "hint": "2^(5 − 2)", "answer": "8"},
                {"prompt": "Simplify √72", "hint": "√(36 × 2)", "answer": "6√2"},
                {"prompt": "(−3)³ − (−2)⁴", "hint": "−27 − 16", "answer": "-43"},
                {"prompt": "27^(2/3)", "hint": "(³√27)² = 3²", "answer": "9"},
            ],
        },
        {
            "id": "deck-unit-circle-trig",
            "title": "Unit Circle Special Angles & Pythagoras",
            "subtitle": "Exact shadows at 0°, 30°, 45°, 60°, 90°, 180°",
            "heuristic": "Halve an equilateral triangle for 30°/60° (½, √3/2); halve a unit square for 45° (√2/2).",
            "cards": [
                {"prompt": "sin 30° + cos 60°", "hint": "1/2 + 1/2", "answer": "1"},
                {"prompt": "sin²(37°) + cos²(37°)", "hint": "Pythagorean identity on unit circle", "answer": "1"},
                {"prompt": "tan 45°", "hint": "Slope of 45° ray on x = 1", "answer": "1"},
                {"prompt": "180° in radians", "hint": "Half-circumference of unit circle", "answer": "π"},
            ],
        },
        {
            "id": "deck-calculus-power",
            "title": "Derivative Slope & Integral Area Reflexes",
            "subtitle": "Power rule d/dx(xⁿ) = nxⁿ⁻¹ & antiderivatives",
            "heuristic": "Differentiating multiplies by power n and drops exponent by 1; integrating raises exponent by 1 and divides.",
            "cards": [
                {"prompt": "Slope dy/dx of y = x³ at x = 2", "hint": "3x² at x = 2", "answer": "12"},
                {"prompt": "∫₀³ 2x dx", "hint": "[x²]₀³ or triangle area ½ × 3 × 6", "answer": "9"},
                {"prompt": "x-coordinate of minimum of y = x² − 6x + 11", "hint": "dy/dx = 2x − 6 = 0", "answer": "3"},
                {"prompt": "det([[4, 1], [2, 3]])", "hint": "ad − bc = 12 − 2", "answer": "10"},
            ],
        },
        {
            "id": "deck-set-logic-bayes",
            "title": "Sets, Logic & Bayes Odds",
            "subtitle": "Inclusion–Exclusion, contrapositives & natural frequencies",
            "heuristic": "n(A ∪ B) = n(A) + n(B) − n(A ∩ B); Posterior = TP / (TP + FP).",
            "cards": [
                {"prompt": "n(A)=18, n(B)=14, n(A∩B)=6 ⇒ n(A∪B)", "hint": "18 + 14 − 6", "answer": "26"},
                {"prompt": "Number of subsets of a 4-element set", "hint": "2⁴", "answer": "16"},
                {"prompt": "TP = 20, FP = 60 ⇒ P(D | +)", "hint": "20 / (20 + 60)", "answer": "0.25"},
                {"prompt": "⁶C₂ (handshakes among 6 people)", "hint": "6 × 5 ÷ 2", "answer": "15"},
            ],
        },
    ]


def build_visual_math_tips():
    return [
        {
            "id": "tip-neg-mult",
            "title": "Why (−a) × (−b) = +ab",
            "chapter": 1,
            "visualIntuition": "Multiplying by −1 is a 180° rotation around 0 on the number line.",
            "ahaMoment": "Two 180° turns complete a full 360° circle, pointing you back in the positive direction!",
            "formula": "(−1) × (−1) = e^(iπ) · e^(iπ) = e^(2πi) = +1",
        },
        {
            "id": "tip-binomial-square",
            "title": "Why (a + b)² ≠ a² + b²",
            "chapter": 4,
            "visualIntuition": "Draw a square of side (a + b) and slice it into 4 rectangles.",
            "ahaMoment": "Besides the corner squares a² and b², two blue rectangles of area ab sit on the sides — forgetting 2ab leaves two big holes in the square!",
            "formula": "(a + b)² = a² + 2ab + b²",
        },
        {
            "id": "tip-gauss-sum",
            "title": "Why 1 + 2 + … + n = ½n(n + 1)",
            "chapter": 6,
            "visualIntuition": "Build a staircase of 1, 2, …, n blocks, clone it, and flip the clone upside-down.",
            "ahaMoment": "The two staircases interlock into a solid rectangle of width n and height (n + 1)!",
            "formula": "Sₙ = ½ n (n + 1)",
        },
        {
            "id": "tip-circle-area",
            "title": "Why a Circle's Area Is πr²",
            "chapter": 10,
            "visualIntuition": "Slice a circle into 24 pizza sectors and comb them together alternating up and down.",
            "ahaMoment": "The wavy top and bottom each use half the circumference (πr), while the height is the radius r — forming a rectangle of base πr and height r!",
            "formula": "A = (πr) × r = πr²",
        },
        {
            "id": "tip-pythag-trig",
            "title": "Why sin²θ + cos²θ = 1 for Every Angle",
            "chapter": 12,
            "visualIntuition": "On the @saxster/atlas unit circle of radius 1, level light casts vertical shadow sin θ and top light casts horizontal shadow cos θ.",
            "ahaMoment": "Those two shadows are the legs of a right triangle with hypotenuse 1 — so their squares always add to 1² = 1!",
            "formula": "cos²θ + sin²θ = 1² = 1",
        },
        {
            "id": "tip-bayes-square",
            "title": "Why a 95% Accurate Test Can Be 72% Wrong",
            "chapter": 16,
            "visualIntuition": "In the @saxster/atlas 1,000-person unit square at 2% prevalence, only 20 people are sick while 980 are healthy.",
            "ahaMoment": "5% false alarms on 980 healthy people creates 49 false positives (amber), dwarfing the 19 true positives (red)!",
            "formula": "P(D | +) = TP / (TP + FP) = 19 / (19 + 49) ≈ 27.9%",
        },
        {
            "id": "tip-calculus-ftc",
            "title": "Why Slope and Area Are Inverses (FTC)",
            "chapter": 18,
            "visualIntuition": "Compare the blue triangle of area under f′(t) = t with the red height bar of f(x) = ½x².",
            "ahaMoment": "Each thin strip of area f′(t)·dt equals df — the tiny vertical step of the original curve. Summing all tiny rises gives total height f(x) − f(0)!",
            "formula": "∫₀ˣ f′(t) dt = f(x) − f(0)",
        },
        {
            "id": "tip-matrix-det",
            "title": "Why det(A) = ad − bc Is Area",
            "chapter": 20,
            "visualIntuition": "Drag the red basis vector Aî = (a, c) and blue basis vector Aĵ = (b, d) in the @saxster/atlas 2×2 Matrix Sandbox.",
            "ahaMoment": "The unit 1×1 square deforms into a parallelogram whose bounding box (a+b)(c+d) minus four right triangles leaves exact area ad − bc!",
            "formula": "Area(A · Square) = det(A) = ad − bc",
        },
    ]


def build_html_book(chapters, explorers, widgets):
    chapters_json = json.dumps(chapters, ensure_ascii=False)
    explorers_json = json.dumps(explorers, ensure_ascii=False)
    return f"""<!doctype html>
<html lang="en-GB" data-theme="light">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>The Patterned World · KymMaths Interactive Book & Atlas</title>
<style>
:root {{
  --bg: #F5F2FB;
  --card: #FFFFFF;
  --elevated: #ECE6F8;
  --ink: #1C1726;
  --muted: #58506B;
  --accent: #6E56CF;
  --red: #C83E37;
  --blue: #2E66B8;
  --amber: #C88A1E;
  --green: #1E7A50;
  --border: #DCD4EE;
}}
html[data-theme="dark"] {{
  --bg: #110E1A;
  --card: #1B1628;
  --elevated: #251F36;
  --ink: #F5F2FC;
  --muted: #B6ADCA;
  --accent: #A890FF;
  --red: #FF7A70;
  --blue: #68B0F8;
  --amber: #F5B945;
  --green: #4ADE9B;
  --border: #332B4A;
}}
* {{ box-sizing: border-box; }}
body {{
  margin: 0;
  padding: 18px 20px 64px;
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", Inter, system-ui, sans-serif;
  background: var(--bg);
  color: var(--ink);
  line-height: 1.55;
}}
header.book-header {{
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding-bottom: 14px;
  border-bottom: 1px solid var(--border);
  margin-bottom: 18px;
}}
.kicker {{
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: var(--accent);
}}
h1 {{
  font-family: Georgia, "New York", serif;
  font-size: 26px;
  margin: 4px 0;
}}
.subtitle {{
  color: var(--muted);
  font-size: 14px;
}}
.card {{
  background: var(--card);
  border: 1px solid var(--border);
  border-radius: 16px;
  padding: 18px;
  margin-bottom: 16px;
  box-shadow: 0 4px 16px rgba(0,0,0,0.04);
}}
.bridge-grid {{
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 12px;
  margin-top: 12px;
}}
.step-box {{
  background: var(--elevated);
  border-radius: 12px;
  padding: 12px 14px;
}}
.formula-banner {{
  font-family: Georgia, "Times New Roman", serif;
  font-size: 20px;
  font-weight: 600;
  padding: 12px 16px;
  border-left: 4px solid var(--accent);
  background: var(--elevated);
  border-radius: 8px;
  margin: 12px 0;
}}
.term-pills {{
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 10px;
}}
.term-pill {{
  font-size: 12px;
  padding: 6px 10px;
  border-radius: 10px;
  background: var(--elevated);
  border-left: 4px solid var(--accent);
}}
.term-pill.red {{ border-left-color: var(--red); }}
.term-pill.blue {{ border-left-color: var(--blue); }}
.term-pill.amber {{ border-left-color: var(--amber); }}
.term-pill.green {{ border-left-color: var(--green); }}
.interactive-stage {{
  display: grid;
  grid-template-columns: 1.2fr 1fr;
  gap: 16px;
  align-items: center;
}}
@media (max-width: 760px) {{
  .interactive-stage {{ grid-template-columns: 1fr; }}
}}
canvas#sim-canvas {{
  width: 100%;
  height: 290px;
  background: var(--elevated);
  border-radius: 12px;
  border: 1px solid var(--border);
  display: block;
}}
.slider-row {{
  display: flex;
  align-items: center;
  gap: 10px;
  margin: 8px 0;
  font-size: 13px;
}}
.slider-row input[type="range"] {{ flex: 1; accent-color: var(--accent); }}
button.btn {{
  appearance: none;
  border: none;
  background: var(--accent);
  color: #fff;
  font-weight: 600;
  font-size: 13px;
  padding: 8px 14px;
  border-radius: 999px;
  cursor: pointer;
}}
button.btn.secondary {{
  background: var(--elevated);
  color: var(--ink);
  border: 1px solid var(--border);
}}
iframe.atlas-frame {{
  width: 100%;
  height: 440px;
  border: 1px solid var(--border);
  border-radius: 12px;
  background: #f3efe6;
}}
</style>
</head>
<body>
<header class="book-header">
  <div>
    <div class="kicker" id="ch-vol">THE PATTERNED WORLD · INTERACTIVE TEXTBOOK & @SAXSTER/ATLAS</div>
    <h1 id="ch-title">Chapter 0 · Sets, Venn Regions & The Laws of Thought</h1>
    <div class="subtitle" id="ch-subtitle">Concrete Manipulation → Visual "Aha!" Invariant → Actual Formula</div>
  </div>
  <div style="display:flex;gap:8px;flex-wrap:wrap;">
    <button class="btn secondary" id="btn-prev">← Prev</button>
    <button class="btn secondary" id="btn-next">Next →</button>
    <button class="btn" id="btn-stamp">Stamp Challenge ✓</button>
  </div>
</header>

<section class="card">
  <div class="kicker">1 · INTUITION → "AHA!" INVARIANT → ACTUAL FORMULA BRIDGE</div>
  <p id="ch-hook" style="font-family:Georgia,serif;font-size:17px;margin:8px 0;"></p>
  <div class="formula-banner" id="ch-formula"></div>
  <div class="bridge-grid">
    <div class="step-box">
      <div class="kicker">Step 1 · Concrete Action (Touch)</div>
      <div id="ch-concrete" style="font-size:13.5px;margin-top:4px;"></div>
    </div>
    <div class="step-box">
      <div class="kicker">Step 2 · Visual "Aha!" Invariant (See)</div>
      <div id="ch-aha" style="font-size:13.5px;margin-top:4px;"></div>
    </div>
  </div>
  <div class="term-pills" id="ch-terms"></div>
</section>

<section class="card" id="widget-stage-card">
  <div class="kicker">2 · LIVE VISUAL-TO-FORMULA SANDBOX</div>
  <div class="interactive-stage" style="margin-top:10px;">
    <canvas id="sim-canvas" width="560" height="290"></canvas>
    <div>
      <div class="slider-row">
        <label for="param-a" id="lbl-a">Parameter a:</label>
        <input type="range" id="param-a" min="1" max="12" step="0.5" value="6">
        <span id="val-a">6</span>
      </div>
      <div class="slider-row">
        <label for="param-b" id="lbl-b">Parameter b:</label>
        <input type="range" id="param-b" min="1" max="12" step="0.5" value="4">
        <span id="val-b">4</span>
      </div>
      <div class="slider-row">
        <label for="param-c" id="lbl-c">Angle / Split:</label>
        <input type="range" id="param-c" min="0" max="90" step="5" value="30">
        <span id="val-c">30°</span>
      </div>
      <div class="step-box" id="live-readout" style="font-family:ui-monospace,monospace;font-size:12.5px;margin-top:10px;"></div>
    </div>
  </div>
</section>

<section class="card">
  <div style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:8px;margin-bottom:10px;">
    <div>
      <div class="kicker">3 · EMBEDDED @SAXSTER/ATLAS 3D/2D TEACHING FIGURE (../visualisations/atlas)</div>
      <div style="font-size:13px;color:var(--muted);" id="atlas-caption">Interactive Three.js paper-and-ink stage</div>
    </div>
    <button class="btn secondary" id="btn-reload-atlas">Reset 3D Camera</button>
  </div>
  <iframe class="atlas-frame" id="atlas-iframe" title="Atlas 3D Figure" src="./atlas/examples/maths/unit-circle/index.html"></iframe>
</section>

<script>
const CHAPTERS = {chapters_json};
const EXPLORERS = {explorers_json};
let currentChapter = 0;

function parseHash() {{
  const h = (window.location.hash || '').replace('#', '');
  if (h.startsWith('ch')) {{
    const n = parseInt(h.slice(2), 10);
    if (!isNaN(n) && n >= 0 && n < CHAPTERS.length) currentChapter = n;
  }}
}}

function renderChapter() {{
  const ch = CHAPTERS[currentChapter] || CHAPTERS[0];
  const br = ch.intuitionToFormula;
  document.getElementById('ch-vol').textContent = ch.volumeTitle.toUpperCase();
  document.getElementById('ch-title').textContent = `Chapter ${{ch.number}} · ${{ch.title}}`;
  document.getElementById('ch-subtitle').textContent = ch.subtitle;
  document.getElementById('ch-hook').textContent = ch.hookSummary;
  document.getElementById('ch-formula').textContent = br.formulaDisplay;
  document.getElementById('ch-concrete').textContent = br.concreteAction;
  document.getElementById('ch-aha').textContent = br.ahaInvariant;

  const termsEl = document.getElementById('ch-terms');
  termsEl.innerHTML = (br.termMappings || []).map(tm =>
    `<div class="term-pill ${{tm.colorRole}}"><b>${{tm.symbol}}</b> → ${{tm.visualPart}}: ${{tm.meaning}}</div>`
  ).join('');

  const iframe = document.getElementById('atlas-iframe');
  const targetSrc = `./atlas/examples/${{br.atlasFigureRef}}`;
  if (iframe.getAttribute('data-src') !== targetSrc) {{
    iframe.setAttribute('data-src', targetSrc);
    iframe.src = targetSrc;
  }}
  document.getElementById('atlas-caption').textContent = `Atlas route: ${{br.atlasFigureRef}} · Drag to orbit in 3D, click parts to explode & inspect PLATES.`;
  drawSandbox();
}}

function drawSandbox() {{
  const ch = CHAPTERS[currentChapter] || CHAPTERS[0];
  const a = parseFloat(document.getElementById('param-a').value);
  const b = parseFloat(document.getElementById('param-b').value);
  const deg = parseFloat(document.getElementById('param-c').value);
  const rad = deg * Math.PI / 180;
  document.getElementById('val-a').textContent = a;
  document.getElementById('val-b').textContent = b;
  document.getElementById('val-c').textContent = deg + '°';

  const canvas = document.getElementById('sim-canvas');
  const ctx = canvas.getContext('2d');
  const w = canvas.width, h = canvas.height;
  ctx.clearRect(0, 0, w, h);

  const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
  const red = isDark ? '#FF7A70' : '#C83E37';
  const blue = isDark ? '#68B0F8' : '#2E66B8';
  const amber = isDark ? '#F5B945' : '#C88A1E';
  const green = isDark ? '#4ADE9B' : '#1E7A50';
  const ink = isDark ? '#F5F2FC' : '#1C1726';

  ctx.font = '600 13px -apple-system, sans-serif';
  let readoutHtml = '';

  if (ch.number === 0 || ch.number === 1) {{
    // Venn Inclusion-Exclusion & Prime HCF/LCM
    const onlyA = Math.round(a * 2), onlyB = Math.round(b * 2), inter = Math.max(1, Math.round(deg / 15));
    const nA = onlyA + inter, nB = onlyB + inter, union = onlyA + onlyB + inter;
    ctx.strokeStyle = red; ctx.lineWidth = 3;
    ctx.beginPath(); ctx.arc(w*0.38, h*0.52, 74, 0, Math.PI*2); ctx.stroke();
    ctx.strokeStyle = blue;
    ctx.beginPath(); ctx.arc(w*0.60, h*0.52, 74, 0, Math.PI*2); ctx.stroke();
    ctx.fillStyle = ink;
    ctx.fillText(`Only A: ${{onlyA}}`, w*0.26, h*0.52);
    ctx.fillStyle = amber;
    ctx.fillText(`A ∩ B: ${{inter}}`, w*0.45, h*0.52);
    ctx.fillStyle = ink;
    ctx.fillText(`Only B: ${{onlyB}}`, w*0.64, h*0.52);
    readoutHtml = `n(A) = ${{nA}}, n(B) = ${{nB}}, n(A ∩ B) = ${{inter}}<br><b>n(A ∪ B) = ${{nA}} + ${{nB}} − ${{inter}} = ${{union}}</b>`;
  }} else if (ch.number <= 7) {{
    // Singapore Bar Model / Area Tiles / Gauss Staircase
    const scale = 14;
    const rw = Math.min(200, a * scale), bw = Math.min(160, b * scale);
    ctx.fillStyle = red + '33'; ctx.strokeStyle = red; ctx.lineWidth = 2.5;
    ctx.fillRect(60, 60, rw, 80); ctx.strokeRect(60, 60, rw, 80);
    ctx.fillStyle = blue + '33'; ctx.strokeStyle = blue;
    ctx.fillRect(60 + rw, 60, bw, 80); ctx.strokeRect(60 + rw, 60, bw, 80);
    ctx.fillStyle = ink;
    ctx.fillText(`a = ${{a}}`, 60 + rw/2 - 18, 105);
    ctx.fillText(`b = ${{b}}`, 60 + rw + bw/2 - 18, 105);
    ctx.fillStyle = green;
    ctx.fillText(`Total Bar (a + b) = ${{(a + b).toFixed(1)}}   |   Area (a+b)² = ${{((a+b)*(a+b)).toFixed(1)}}`, 60, 185);
    ctx.fillStyle = amber;
    ctx.fillText(`Cross-terms 2ab = ${{(2*a*b).toFixed(1)}} (why (a+b)² ≠ a² + b²!)`, 60, 215);
    readoutHtml = `a² = ${{(a*a).toFixed(1)}}, 2ab = ${{(2*a*b).toFixed(1)}}, b² = ${{(b*b).toFixed(1)}}<br><b>(a + b)² = ${{(a*a).toFixed(1)}} + ${{(2*a*b).toFixed(1)}} + ${{(b*b).toFixed(1)}} = ${{((a+b)**2).toFixed(1)}}</b>`;
  }} else if (ch.number <= 12) {{
    // Unit Circle Shadows & Euclid Geometry
    const cx = 165, cy = 148, r = 92;
    ctx.strokeStyle = ink + '55'; ctx.lineWidth = 1.5;
    ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI*2); ctx.stroke();
    const px = cx + r * Math.cos(rad), py = cy - r * Math.sin(rad);
    ctx.strokeStyle = blue; ctx.lineWidth = 3.5;
    ctx.beginPath(); ctx.moveTo(cx, cy); ctx.lineTo(px, cy); ctx.stroke();
    ctx.strokeStyle = red;
    ctx.beginPath(); ctx.moveTo(px, cy); ctx.lineTo(px, py); ctx.stroke();
    ctx.strokeStyle = green;
    ctx.beginPath(); ctx.moveTo(cx, cy); ctx.lineTo(px, py); ctx.stroke();
    ctx.fillStyle = blue; ctx.fillText(`cos θ = ${{Math.cos(rad).toFixed(3)}}`, 305, 95);
    ctx.fillStyle = red; ctx.fillText(`sin θ = ${{Math.sin(rad).toFixed(3)}}`, 305, 125);
    ctx.fillStyle = amber; ctx.fillText(`sin²θ + cos²θ = 1.000`, 305, 155);
    ctx.fillStyle = green; ctx.fillText(`Circle Area πr² (r=${{a}}) = ${{(Math.PI*a*a).toFixed(1)}}`, 305, 190);
    readoutHtml = `θ = ${{deg}}° (${{rad.toFixed(3)}} rad)<br><b>cos²θ (${{(Math.cos(rad)**2).toFixed(3)}}) + sin²θ (${{(Math.sin(rad)**2).toFixed(3)}}) = 1.000</b>`;
  }} else if (ch.number <= 16) {{
    // Bayes 1,000-Person Square & Frequency Density
    const prev = Math.max(0.01, a / 100);
    const sens = 0.95;
    const fpRate = Math.max(0.01, b / 100);
    const sick = Math.round(1000 * prev);
    const healthy = 1000 - sick;
    const tp = +(sick * sens).toFixed(1);
    const fp = +(healthy * fpRate).toFixed(1);
    const ppv = (tp / (tp + fp)) * 100;
    ctx.fillStyle = red; ctx.fillRect(60, 60, Math.max(18, prev * 600), 150);
    ctx.fillStyle = amber; ctx.fillRect(140, 120, Math.max(28, fpRate * 600), 90);
    ctx.fillStyle = ink;
    ctx.fillText(`True Positives (Red): ${{tp}}`, 280, 95);
    ctx.fillText(`False Positives (Amber): ${{fp}}`, 280, 125);
    ctx.fillStyle = green;
    ctx.fillText(`Posterior P(D | +) = ${{ppv.toFixed(1)}}%`, 280, 165);
    readoutHtml = `Base rate p = ${{(prev*100).toFixed(1)}}%, FP rate = ${{(fpRate*100).toFixed(1)}}%<br><b>P(D | +) = ${{tp}} / (${{tp}} + ${{fp}}) = ${{ppv.toFixed(1)}}%</b>`;
  }} else {{
    // Calculus Slope/Area & 2×2 Matrix Determinant
    const hStep = Math.max(0.05, b / 10);
    const secSlope = a + 0.5 * hStep;
    const det = a * b - 1.5;
    ctx.strokeStyle = blue; ctx.lineWidth = 2.5;
    ctx.beginPath();
    for (let i = 0; i <= 60; i++) {{
      const u = i / 20;
      const sx = 50 + u * 75, sy = 230 - 0.5 * u * u * 36;
      if (i === 0) ctx.moveTo(sx, sy); else ctx.lineTo(sx, sy);
    }}
    ctx.stroke();
    ctx.fillStyle = red;
    ctx.fillText(`Secant Δy/h = ${{secSlope.toFixed(3)}} → Tangent f′(x) = ${{a.toFixed(2)}}`, 255, 95);
    ctx.fillStyle = blue;
    ctx.fillText(`Integral ∫₀ᵃ t dt = ½a² = ${{(0.5*a*a).toFixed(2)}}`, 255, 130);
    ctx.fillStyle = amber;
    ctx.fillText(`2×2 Parallelogram Area det(A) = ${{det.toFixed(2)}}`, 255, 165);
    readoutHtml = `At x = ${{a}}, step h = ${{hStep.toFixed(2)}}:<br><b>f′(x) = ${{a.toFixed(2)}} · Area ∫₀ˣ t dt = ${{(0.5*a*a).toFixed(2)}} · det(A) = ${{det.toFixed(2)}}</b>`;
  }}

  document.getElementById('live-readout').innerHTML = readoutHtml;
}}

['param-a', 'param-b', 'param-c'].forEach(id => {{
  document.getElementById(id).addEventListener('input', drawSandbox);
}});

document.getElementById('btn-prev').addEventListener('click', () => {{
  currentChapter = (currentChapter - 1 + CHAPTERS.length) % CHAPTERS.length;
  window.location.hash = `#ch${{String(currentChapter).padStart(2, '0')}}`;
}});
document.getElementById('btn-next').addEventListener('click', () => {{
  currentChapter = (currentChapter + 1) % CHAPTERS.length;
  window.location.hash = `#ch${{String(currentChapter).padStart(2, '0')}}`;
}});
document.getElementById('btn-reload-atlas').addEventListener('click', () => {{
  const iframe = document.getElementById('atlas-iframe');
  iframe.src = iframe.getAttribute('data-src') || iframe.src;
}});
document.getElementById('btn-stamp').addEventListener('click', () => {{
  const ch = CHAPTERS[currentChapter] || CHAPTERS[0];
  const wid = (ch.widgets && ch.widgets[0]) || `w_ch${{ch.number}}`;
  const readout = document.getElementById('live-readout').innerText.replace(/\\n/g, ' · ');
  if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.kymmathsBridge) {{
    window.webkit.messageHandlers.kymmathsBridge.postMessage({{ widgetId: wid, readout }});
  }}
  document.getElementById('btn-stamp').textContent = 'Challenge Stamped ✓';
}});

window.addEventListener('hashchange', () => {{
  parseHash();
  renderChapter();
}});

parseHash();
renderChapter();
</script>
</body>
</html>
"""


def main():
    volumes = build_volumes()
    chapters = build_chapters()
    explorers = build_explorers()
    widgets = build_widgets(chapters)
    atlas_lessons = build_atlas_lessons(chapters)
    bridges = build_bridges()
    school_textbook = build_school_textbook()
    school_questions = build_school_questions()
    diagram_plates = build_diagram_plates()
    polya_stages = build_polya_stages()
    speed_math_decks = build_speed_math_decks()
    visual_math_tips = build_visual_math_tips()

    pack = {
        "schemaVersion": 1,
        "packId": "kym-maths-stage8-horizon-v1",
        "generatedBy": "source/export_kymmaths_pack.py",
        "volumes": volumes,
        "chapters": chapters,
        "explorers": explorers,
        "atlasLessons": atlas_lessons,
        "widgets": widgets,
        "crossDisciplinaryBridges": bridges,
        "schoolTextbook": school_textbook,
        "schoolQuestions": school_questions,
        "diagramPlates": diagram_plates,
        "polyaStages": polya_stages,
        "speedMathDecks": speed_math_decks,
        "visualMathTips": visual_math_tips,
    }

    PACK_OUT.parent.mkdir(parents=True, exist_ok=True)
    PACK_OUT.write_text(json.dumps(pack, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    BOOK_OUT.parent.mkdir(parents=True, exist_ok=True)
    BOOK_OUT.write_text(build_html_book(chapters, explorers, widgets), encoding="utf-8")

    print(
        f"Exported KymMaths pack: {len(volumes)} volumes, {len(chapters)} chapters, "
        f"{len(widgets)} widgets, {len(atlas_lessons)} atlas lessons, "
        f"{len(school_textbook['units'])} OUP chapters, {len(school_questions)} school+workbook questions, "
        f"{len(diagram_plates)} diagram plates, {len(polya_stages)} Polya stages, "
        f"{len(speed_math_decks)} SpeedMath decks, {len(visual_math_tips)} visual math tips."
    )


if __name__ == "__main__":
    main()
