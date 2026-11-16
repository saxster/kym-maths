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
import sys
from pathlib import Path

import answer_marking as marking
import concept_links
import content_checks
from book import ch00 as book_ch00
from book import ch01 as book_ch01
from book import ch02 as book_ch02
from book import ch03 as book_ch03
from book import ch04 as book_ch04
from book import ch05 as book_ch05
from book import ch06 as book_ch06
from book import ch07 as book_ch07
from book import ch08 as book_ch08
from book import ch09 as book_ch09
from book import ch10 as book_ch10
from book import ch11 as book_ch11
from book import concepts as book_concepts

ROOT = Path(__file__).resolve().parent.parent
PACK_OUT = ROOT / "KymMaths" / "KymMaths" / "Resources" / "ContentPacks" / "kymmaths-seed-pack.json"
BOOK_OUT = ROOT / "KymMaths" / "KymMaths" / "Resources" / "PatternedWorldBook" / "index.html"
GOLDEN_OUT = ROOT / "KymMaths" / "Tests" / "Golden" / "concept-links.json"

# Chapters rewritten by hand to docs/CONTENT_BRIEF.md. The content checks apply to these.
BOOK_CHAPTERS = (book_ch00, book_ch01, book_ch02, book_ch03, book_ch04, book_ch05, book_ch06, book_ch07, book_ch08, book_ch09, book_ch10, book_ch11)
# Saved learner responses key on callout ids, so a rewritten chapter keeps the old ids.
CALLOUT_ID_SUFFIX = {"predict": "predict", "check": "aha", "careful": "trap"}


def helpers():
    """This module, which the book files take as `k` for its answer-key helpers."""
    return sys.modules[__name__]


def book_specs():
    return {spec["number"]: spec for spec in (module.build(helpers()) for module in BOOK_CHAPTERS)}


def rewritten_chapters():
    return set(book_specs())


def book_chapter_record(spec, volumes):
    num = spec["number"]
    volume = next(v for v in volumes if num in v["chapters"])
    sections = []
    for index, section in enumerate(spec["sections"], start=1):
        section_id = f"ch{num:02d}-s{index}"
        steps = []
        for step in section["steps"]:
            record = {"id": f"{section_id}-{step['kind']}", "kind": step["kind"], "text": step["text"]}
            if "answerKey" in step:
                record["answer"] = step["answer"]
                record["answerKey"] = step["answerKey"]
            steps.append(record)
        idea = next(step["text"] for step in section["steps"] if step["kind"] == "idea")
        record = {
            "id": section_id,
            "heading": section["heading"],
            "excerpt": idea,
            "teaches": section["teaches"],
            "steps": steps,
        }
        if section.get("figure"):
            record["figure"] = True
        sections.append(record)
    record = {
        "id": f"ch{num:02d}",
        "number": num,
        "volumeNumber": volume["number"],
        "volumeTitle": volume["title"],
        "title": spec["title"],
        "subtitle": spec["subtitle"],
        "hookSummary": spec["hookSummary"],
        "beyondSchoolBook": spec.get("beyondSchoolBook"),
        "skillCard": spec["skillCard"],
        "intuitionToFormula": spec["intuitionToFormula"],
        "sections": sections,
        "callouts": [
            {"id": f"ch{num:02d}-c-{CALLOUT_ID_SUFFIX[callout['kind']]}", **callout} for callout in spec["callouts"]
        ],
        "keyTerms": spec["keyTerms"],
        "widgets": spec["widgets"],
    }
    if "debate" in spec:
        # Decodes straight into the app's MathematicalDebateScenario.
        debate = dict(spec["debate"])
        record["debate"] = {"id": debate.pop("id"), "chapterNumber": num, **debate}
    return record


def book_widget_text():
    return {wid: text for spec in book_specs().values() for wid, text in spec["widgetText"].items()}


def book_atlas_lessons():
    """Atlas lesson id → the fields the book file writes for it."""
    return {
        f"atlas-ch{num:02d}-{index}": lesson
        for num, spec in book_specs().items()
        for index, lesson in enumerate(spec["atlasLessons"], start=1)
    }


def book_tips():
    return {tid: tip for spec in book_specs().values() for tid, tip in spec["visualMathTips"].items()}


# The school question fields a chapter file may rewrite. Answer keys, model answers and stuck sheets stay here.
SCHOOL_QUESTION_FIELDS = {"workedExample", "fadedPrompt"}


def _merge_school_text(key):
    merged = {}
    for num, spec in sorted(book_specs().items()):
        for item_id, value in spec.get(key, {}).items():
            if item_id in merged:
                raise SystemExit(f"{key} \"{item_id}\" is written by two chapter files; chapter {num} is the second")
            merged[item_id] = value
    return merged


def book_school_topics():
    """School topic code → the `summary` a chapter file writes for it."""
    return _merge_school_text("schoolTopics")


def book_school_questions():
    """School question id → the `workedExample` and `fadedPrompt` a chapter file writes for it."""
    return _merge_school_text("schoolQuestions")


def book_school_authored():
    """The school topic codes and question ids a chapter file writes, which the content checks also read."""
    return {"topics": set(book_school_topics()), "questions": set(book_school_questions())}


def build_concepts(chapters):
    """The concept cards, each with `usedIn`: the rewritten chapters that list it as a key term, then the cards that stand on it."""
    cards = book_concepts.build(helpers())
    concepts = []
    for cid, card in cards.items():
        used_in = [
            {"chapter": ch["number"], "label": f"Chapter {ch['number']} · {ch['title']}"}
            for ch in chapters
            if "skillCard" in ch and card["name"] in ch["keyTerms"]
        ]
        used_in += [{"concept": other, "label": cards[other]["name"]}
                    for other, other_card in cards.items() if cid in other_card["standsOn"]]
        record = {"id": cid}
        for field in ("name", "short", "symbol", "aliases", "oneSentence", "picture", "steps", "bigNumbers",
                      "workedExample"):
            if field in card:
                record[field] = card[field]
        record["check"] = {"id": f"{cid}-check", **card["check"]}
        record["mixUp"] = card["mixUp"]
        record["standsOn"] = card["standsOn"]
        if "footing" in card:
            record["footing"] = card["footing"]
        record["usedIn"] = used_in
        concepts.append(record)
    return concepts


def build_concept_stop_phrases():
    return list(book_concepts.STOP_PHRASES)


def concept_link_golden(pack):
    """Texts and the links the Python linker finds in them, which the app's ConceptLinker must reproduce.

    A section's steps share one scope, as they do on screen, so `linked` lists the concepts already
    linked by the steps before it.
    """
    linker = content_checks.linker_for(pack)
    entries = []

    def add(text, exclude=None, linked=()):
        links = linker.links(text, exclude=exclude, linked=linked)
        entries.append({"text": text, "exclude": exclude, "linked": sorted(linked), "links": links})
        return {link["concept"] for link in links}

    for number in sorted(rewritten_chapters()):
        chapter = next(ch for ch in pack["chapters"] if ch["number"] == number)
        step_ids = {step["id"] for section in chapter["sections"] for step in section.get("steps", [])}
        for where, text in content_checks.chapter_strings(pack, number):
            if where not in step_ids:
                add(text)
        for section in chapter["sections"]:
            linked = set()
            for step in section.get("steps", []):
                linked |= add(step["text"], linked=linked)
    for card in pack["concepts"]:
        for _, text in content_checks.card_strings(card):
            add(text, exclude=card["id"])
    authored_questions = book_school_questions()
    for question in pack["schoolQuestions"]:
        fields = ["prompt", "workedExample"] if question["unitNumber"] == 1 else []
        if question["id"] in authored_questions:
            fields += [field for field in ("prompt", "workedExample", "fadedPrompt") if field not in fields]
        for field in fields:
            add(question[field])
    authored_topics = book_school_topics()
    for unit in pack["schoolTextbook"]["units"]:
        for topic in unit["topics"]:
            if topic["code"] in authored_topics:
                add(topic["summary"])
    for footing in pack["footings"]:
        add(footing["teach"])
    return entries


def write_golden(pack):
    """Writes the golden link file and returns its entries."""
    entries = concept_link_golden(pack)
    GOLDEN_OUT.parent.mkdir(parents=True, exist_ok=True)
    GOLDEN_OUT.write_text(json.dumps(entries, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return entries


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
            "maths/ch16-trigonometry-unit-circle/index.html#1",
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
            "maths/ch11-data-histograms/index.html",
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
            "Advanced Probability · @saxster/atlas Bayes Explorer: why a positive result from a 95% accurate test on a 2% condition is right only 28% of the time",
            "Evidence never acts in a vacuum — it slices and renormalizes the prior base rate inside a 1,000-person unit square.",
            "Open the @saxster/atlas Bayes Unit-Square Explorer (`statistics/bayes`): set prevalence p = 2%, sensitivity = 95%, false-positive rate = 5%, and screen 1,000 people.",
            "Conditioning on a positive test throws away everyone who tested negative! What remains is just two bars: 19 True Positives (red) from the 20 sick people, and 49 False Positives (amber) from the 980 healthy people — so P(D | +) = 19 / (19 + 49) ≈ 27.9%!",
            "P(D | +) = [ P(+ | D) P(D) ] / [ P(+ | D) P(D) + P(+ | ¬D) P(¬D) ]",
            [
                {"symbol": "P(+ | D) P(D)", "visualPart": "Red True-Positive rectangle (19 of 1,000)", "colorRole": "red", "meaning": "Sick people correctly flagged positive"},
                {"symbol": "P(+ | ¬D) P(¬D)", "visualPart": "Amber False-Positive rectangle (49 of 1,000)", "colorRole": "amber", "meaning": "Healthy people falsely flagged positive"},
                {"symbol": "Red / (Red + Amber)", "visualPart": "Isolated posterior bar on the right of the 3D board", "colorRole": "green", "meaning": "Share of all positive tests that are genuinely sick"}
            ],
            "maths/ch17-bayes-probability/index.html",
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
            "maths/ch18-differential-calculus/index.html",
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
            "maths/ch19-integral-calculus/index.html",
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
            "maths/ch15-linear-graphs-inequalities/index.html",
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
            "maths/ch20-matrices-eigen/index.html",
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
                    "body": f"Before moving the slider in {widget_title(widgets[0])}, predict which geometric quantity changes and which invariant stays locked.",
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
    chapters += [book_chapter_record(spec, build_volumes()) for spec in book_specs().values()]
    return sorted(chapters, key=lambda ch: ch["number"])


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


# Widgets that share a chapter but show a different atlas page need their own text.
# Numbers and colours here come from the routed page's model.js and chapter.js.
WIDGET_OVERRIDES = {
    "w_bearings_back_bearing_radar": {
        "challengePrompt": "Set the bearing of B from A, measured clockwise from North in three figures. Predict the back bearing of A from B, then check it on the radar: 065° gives 245°.",
        "cutaway": "The North lines at A and B are parallel, so the way back points exactly opposite the way out. Back bearing = forward + 180° when the forward bearing is under 180°, and forward − 180° otherwise. At 065° the co-interior angle at B is 115° and the back bearing is 245°.",
        "idealised": "Formula Anatomy: back bearing = forward ± 180°, always written in three figures (065° → 245°)",
        "watchSteps": [
            {"title": "1. Concrete Touch", "caption": "Drag the forward-bearing slider between 25° and 160° and watch the amber ray from A to B turn clockwise from North."},
            {"title": "2. Spot the Invariant ('Aha!')", "caption": "The back bearing is always the forward bearing plus 180°: 065° + 180° = 245°."},
            {"title": "3. Colour-Map the Symbols", "caption": "The green arrows are the parallel North lines at A and B. The amber ray is the path from A to B, read one way for the bearing and the other way for the back bearing."},
            {"title": "4. Test a Boundary Case", "caption": "On paper, start from 245°. It is over 180°, so subtract instead: 245° − 180° = 065°, back where you began."},
            {"title": "5. Stamp & Sketch in Journal", "caption": "Write both bearings with three figures (065°, not 65°) in your Cornell Proof & Construction Journal."},
        ],
    },
    "w_polyhedron_net_folder": {
        "challengePrompt": "Slide the net fold from 0 (flat) to 1 (closed) to fold six squares into a cube. Count its vertices, edges and faces, then check V − E + F = 2 for the tetrahedron, the cube and the octahedron.",
        "cutaway": "Folding a net joins edges and corners together but never adds or removes a face. The cube has 8 vertices, 12 edges and 6 faces: 8 − 12 + 6 = 2. The tetrahedron gives 4 − 6 + 4 = 2 and the octahedron 6 − 12 + 8 = 2.",
        "idealised": "Formula Anatomy: V − E + F = 2 (tetrahedron 4 − 6 + 4, cube 8 − 12 + 6, octahedron 6 − 12 + 8)",
        "watchSteps": [
            {"title": "1. Concrete Touch", "caption": "Set the net fold to 0 to lay the cube open, then slide it to 1 to close it."},
            {"title": "2. Spot the Invariant ('Aha!')", "caption": "Count the closed cube: 8 corners, 12 edges, 6 faces. 8 − 12 + 6 = 2."},
            {"title": "3. Colour-Map the Symbols", "caption": "The amber wireframe is the folded cube: its corners are V, its struts are E and its square faces are F."},
            {"title": "4. Test a Boundary Case", "caption": "Count two other solids on paper: the tetrahedron gives 4 − 6 + 4 = 2 and the octahedron 6 − 12 + 8 = 2."},
            {"title": "5. Stamp & Sketch in Journal", "caption": "Sketch a cube net in your Cornell Proof & Construction Journal and label V, E and F."},
        ],
    },
    "w_pythagoras_garfield_proof": {
        "title": "Pythagoras: Three Squares Under P",
        "atlasRoute": "maths/unit-circle/index.html#3",
        "challengePrompt": "Watch P sway between 20° and 70° on the unit circle and follow the three squares on the right triangle under P. Check that the red square and the blue square together always cover the grey square on the radius: sin²θ + cos²θ = 1.",
        "cutaway": "This page shows Pythagoras on one right triangle, the one with hypotenuse 1. Its sides are cos θ across (blue) and sin θ up (red), so the squares on them are cos²θ and sin²θ, and together they match the grey 1² square on the radius. It checks the theorem at every angle; it does not prove it.",
        "idealised": "Formula Anatomy: sin²θ + cos²θ = 1², the squares on the two legs and the hypotenuse of the triangle under P",
        "watchSteps": [
            {"title": "1. Concrete Touch", "caption": "Click the triangle under P: the red, blue and grey squares fold part way up off the board."},
            {"title": "2. Spot the Invariant ('Aha!')", "caption": "Red plus blue covers grey at every angle. At 30°: (½)² + (√3/2)² = ¼ + ¾ = 1."},
            {"title": "3. Colour-Map the Symbols", "caption": "Red is the square on the side up, sin θ. Blue is the square on the side across, cos θ. Grey is the square on the radius, 1."},
            {"title": "4. Test a Boundary Case", "caption": "On paper, take θ = 0°: the red square vanishes and the blue square is the whole grey one, 0 + 1 = 1."},
            {"title": "5. Stamp & Sketch in Journal", "caption": "Draw the triangle and its three squares in your Cornell Proof & Construction Journal."},
        ],
    },
}


def widget_title(wid):
    """The name a learner sees for a widget: its override title, else one made from its id."""
    derived = wid.replace("w_atlas_", "3D Atlas: ").replace("w_", "").replace("_", " ").title()
    return WIDGET_OVERRIDES.get(wid, {}).get("title", derived)


def build_widgets(chapters):
    book_text = book_widget_text()
    widgets = []
    for ch in chapters:
        ch_num = ch["number"]
        bridge = ch["intuitionToFormula"]
        for idx, wid in enumerate(ch["widgets"]):
            is_3d = "atlas" in wid or ch_num in (3, 10, 12, 13, 15, 16, 17, 18, 19, 20)
            title = widget_title(wid)
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
                **WIDGET_OVERRIDES.get(wid, {}),
                **book_text.get(wid, {}),
            })
    return widgets


def build_atlas_lessons(chapters):
    book_lessons = book_atlas_lessons()
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
            lesson_id = f"atlas-ch{ch_num:02d}-{s_idx}"
            lessons.append({
                "id": lesson_id,
                "widget": w0,
                "title": f"Ch {ch_num}.{s_idx} · {ch['title']} ({stage_name})",
                "chapter": ch_num,
                "figure": bridge["atlasFigureRef"],
                "question": q,
                "explanation": exp,
                "limits": f"Formula: {bridge['formulaDisplay']}",
                "sources": ["Oxford Complete Mathematics 8 (2nd Ed.)", "Atlas figures"],
                "stories": [ch["hookSummary"]],
                **book_lessons.get(lesson_id, {}),
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

    summaries = book_school_topics()
    unknown = sorted(set(summaries) - {code for unit in raw_units for code, *_ in unit[-1]})
    if unknown:
        raise SystemExit(f"schoolTopics for unknown topic codes: {unknown}")

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
                "summary": summaries.get(code, summary),
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


# ---------------------------------------------------------------------------
# Answer keys for the 64 school questions.
#
# A key lists the parts an answer must contain; every part is required. Each
# part passes when any one of its matchers does:
#   num    a number that stands on its own in the answer (not a coefficient)
#   seq    numbers in this order with nothing between them (points, ratios)
#   forms  an exact expression, spacing ignored; list every form you accept
#   words  every group needs one whole-word hit; any `forbid` word fails it
#   all_of every listed matcher must pass
# `accepts` and `rejects` are sample answers. The app's tests run them through
# the real marker, so a key that marks its own samples wrongly fails the build.
# ---------------------------------------------------------------------------

def num(value, tolerance=0, simplest=False):
    matcher = {"kind": "number", "value": value}
    if tolerance:
        matcher["tolerance"] = tolerance
    if simplest:
        matcher["simplest"] = True
    return matcher


def seq(*values, ignoring=()):
    matcher = {"kind": "sequence", "values": list(values)}
    if ignoring:
        matcher["ignoring"] = list(ignoring)
    return matcher


def forms(*values):
    return [{"kind": "form", "value": value} for value in values]


def words(*groups, forbid=()):
    matcher = {"kind": "words", "groups": [list(group) for group in groups]}
    if forbid:
        matcher["forbid"] = list(forbid)
    return matcher


def all_of(*matchers):
    return {"kind": "all", "of": list(matchers)}


def part(label, *matchers):
    any_of = []
    for matcher in matchers:
        any_of.extend(matcher if isinstance(matcher, list) else [matcher])
    return {"label": label, "anyOf": any_of}


MISCONCEPTIONS = {
    "sign-of-product": "You got a sign wrong multiplying or dividing",
    "dropped-minus": "You lost a minus sign",
    "rearranged-sign": "You got a sign wrong moving a term across",
    "expand-first-term-only": "You multiplied only the first term in the bracket",
    "lcm-as-product": "You took the LCM as the numbers multiplied together",
    "hcf-lcm-swapped": "You mixed up HCF and LCM",
    "stopped-early": "You stopped one step too soon",
    "common-factor-left": "You left a common factor in",
    "square-of-difference": "You treated a² − b² as (a − b)²",
    "back-bearing": "You did not turn round for the back-bearing",
    "added-sides": "You added lengths instead of using Pythagoras",
    "forgot-square-root": "You forgot the square root",
    "equal-split": "You split the sample equally, not in proportion",
    "multiplied-instead-of-divided": "You multiplied when you needed to divide",
    "divided-wrong-way-round": "You divided the wrong way round",
    "unit-slip": "You mixed up the units",
    "forgot-half": "You forgot to halve",
    "radius-diameter-mixed": "You mixed up the radius and the diameter",
    "power-as-multiply": "You multiplied by the power instead of raising to it",
    "height-slant-mixed": "You mixed up the slanted side and the height",
    "missing-edges": "You left out some edges of the shape",
    "truncated": "You cut digits off instead of rounding",
    "recurring-as-terminating": "You treated the recurring decimal as if it stopped",
    "decimal-places-not-sf": "You rounded to decimal places, not significant figures",
    "place-value-shift": "You shifted the place value",
    "split-mixed-number": "You worked on the whole numbers and fractions separately",
    "added-denominators": "You added or subtracted the denominators",
    "inequality-not-flipped": "You did not reverse the inequality sign",
    "co-interior-as-equal": "You made co-interior angles equal",
    "half-difference": "You halved the difference instead of averaging",
    "swapped-coordinates": "You swapped x and y",
    "interior-for-exterior": "You used the interior angle instead of the exterior",
    "percent-of-wrong-amount": "You took the percentage of the wrong amount",
    "percentages-cancel": "You let the two percentages cancel out",
    "simple-not-compound": "You used simple interest instead of compound",
    "density-as-frequency": "You mixed up frequency and frequency density",
    "boundary-for-width": "You used a class boundary instead of the class width",
    "range-for-iqr": "You found the range, not the interquartile range",
    "off-by-one": "You were one step out",
    "wrong-units-for-difference": "You matched the difference to the wrong units",
    "area-by-length-factor": "You scaled an area by the length factor",
    "direct-for-inverse": "You used direct proportion where it is inverse",
    "unmatched-middle": "You joined the ratios without matching the shared part",
    "centre-ignored": "You enlarged from the origin, not the centre",
    "wrong-mirror-line": "You reflected in the wrong mirror line",
    "wrong-turn-direction": "You turned the wrong way",
    "inverse-wrong-order": "You undid the steps in the wrong order",
    "inverse-as-reciprocal": "You took one over f instead of the inverse",
    "perpendicular-gradient": "You did not both flip and negate the gradient",
    "conditional-reversed": "You turned the condition round",
    "wrong-total": "You divided by the wrong total",
    "unequal-outcomes": "You treated the sums as equally likely",
    "order-mixed": "You mixed up whether order matters",
    "with-replacement": "You forgot the first marble stays out",
    "vector-combined-wrongly": "You combined the vectors the wrong way",
}


def mistake(misconception_id, *matchers, next_step, examples):
    if misconception_id not in MISCONCEPTIONS:
        raise SystemExit(f"Unknown misconception id: {misconception_id}")
    if not examples:
        raise SystemExit(f"Mistake {misconception_id} has no examples")
    if not next_step.endswith("."):
        raise SystemExit(f"Mistake {misconception_id} next step must be one sentence ending in a full stop")
    return {
        "misconception": misconception_id,
        "name": MISCONCEPTIONS[misconception_id],
        "anyOf": part("", *matchers)["anyOf"],
        "nextStep": next_step,
        "examples": list(examples),
    }


def key(parts, accepts, rejects, mistakes=()):
    return {"parts": parts, "accepts": accepts, "rejects": rejects, "mistakes": list(mistakes)}


def one(*matchers, accepts, rejects, mistakes=()):
    return key([part("answer", *matchers)], accepts, rejects, mistakes)


# ---------------------------------------------------------------------------
# Footings: the smaller skill each slip rests on. When the same slip comes back,
# the app checks its footing with three short probes before Kym tries again.
# A teach line is shown after a missed probe, so its example must not give away
# another probe's answer; the app's tests check that.
# ---------------------------------------------------------------------------

def probe(prompt, answer_key, answer):
    return {"prompt": prompt, "answer": answer, "answerKey": answer_key}


def footing(skill, teach, probes):
    return {"skill": skill, "teach": teach, "probes": probes}


FOOTINGS = {
    "negative-numbers": footing(
        skill="Multiply and divide negative numbers",
        teach="Same signs make a positive and different signs make a negative, so (−3) × (−2) = 6 and 6 ÷ (−3) = −2, and a minus sign stays with its number through every step. Multiplying or dividing both sides of an inequality by a negative number turns the sign round: −x < 2 becomes x > −2.",
        probes=[
            probe("Work out (−5) × (−4) ÷ (−2).",
                  one(num("-10"), accepts=["-10", "−10", "= -10"], rejects=["10", "-40", "40"]),
                  answer="−10"),
            probe("Work out 2 × 3 − 4 × 5.",
                  one(num("-14"), accepts=["-14", "6 − 20 = −14", "= -14"], rejects=["14", "10", "-26"]),
                  answer="−14"),
            probe("Solve −2x < 8.",
                  one(forms("x>-4", "-4<x"), accepts=["x > −4", "x>-4", "-4 < x"], rejects=["x < -4", "x > 4", "x < 4"]),
                  answer="x > −4"),
        ]),
    "inverse-operations": footing(
        skill="Undo each step with its inverse",
        teach="Undo the last step first and do the same to both sides: for x/2 + 3 = 8, take 3 from both sides to get x/2 = 5, then multiply by 2 to get x = 10. An inverse function f⁻¹ makes those undo steps; it is not 1 ÷ f.",
        probes=[
            probe("Solve x + 9 = 4.",
                  one(num("-5"), accepts=["x = −5", "-5", "x=-5"], rejects=["13", "5", "x = 13"]),
                  answer="x = −5"),
            probe("Solve x/4 − 3 = 2.",
                  one(num("20"), accepts=["x = 20", "20", "x=20"], rejects=["11", "5", "-4"]),
                  answer="x = 20"),
            probe("f(x) = 2x + 1. Find f⁻¹(9).",
                  one(num("4"), accepts=["4", "f⁻¹(9) = 4", "= 4"], rejects=["1/19", "19", "5"]),
                  answer="4"),
        ]),
    "distributive-law": footing(
        skill="Multiply every term inside a bracket",
        teach="The number outside a bracket multiplies each term inside it: −3(x − 4) = −3x + 12. A squared bracket is two brackets, so (x + 2)² = (x + 2)(x + 2) = x² + 4x + 4, not x² + 4.",
        probes=[
            probe("Expand −2(x − 5).",
                  one(forms("-2x+10", "10-2x"), accepts=["−2x + 10", "-2x+10", "10 − 2x"],
                      rejects=["-2x - 5", "-2x - 10", "2x + 10", "-2x + 5"]),
                  answer="−2x + 10"),
            probe("Expand (x + 3)².",
                  one(forms("x^2+6x+9"), accepts=["x² + 6x + 9", "x^2+6x+9", "= x² + 6x + 9"],
                      rejects=["x² + 9", "x² + 3x + 9", "x² + 6x + 6"]),
                  answer="x² + 6x + 9"),
            probe("Work out 7² − 3², then (7 − 3)².",
                  key([part("7² − 3²", num("40")), part("(7 − 3)²", num("16"))],
                      accepts=["40 and 16", "40, 16", "49 − 9 = 40 and 4² = 16"],
                      rejects=["16 and 16", "40 and 40", "16"]),
                  answer="40 and 16"),
        ]),
    "factors-and-multiples": footing(
        skill="Find the HCF and LCM, and cancel fully",
        teach="The HCF is the biggest number that divides both, and the LCM is the smallest number both divide into: for 4 and 10, the HCF is 2 and the LCM is 20, not 4 × 10 = 40. Cancel a fraction by the HCF so nothing common is left, as in 10/15 = 2/3.",
        probes=[
            probe("Find the LCM of 6 and 8.",
                  one(num("24"), accepts=["24", "LCM = 24", "lcm 24"], rejects=["48", "2", "12"]),
                  answer="24"),
            probe("Find the HCF of 18 and 24.",
                  one(num("6"), accepts=["6", "HCF = 6", "hcf 6"], rejects=["72", "3", "2"]),
                  answer="6"),
            probe("Write 18/24 in its simplest form.",
                  one(num("3/4", simplest=True), accepts=["3/4", "= 3/4", "18/24 = 3/4"], rejects=["9/12", "6/8", "18/24"]),
                  answer="3/4"),
        ]),
    "squares-and-roots": footing(
        skill="Square a number and undo it with a square root",
        teach="Squaring multiplies a number by itself, so 5² = 5 × 5 = 25, not 10, and a square root undoes it: √25 = 5. In a right-angled triangle, square the two shorter sides, add, then take the square root: 3² + 4² = 25, so the longest side is 5.",
        probes=[
            probe("Work out 6².",
                  one(num("36"), accepts=["36", "6 × 6 = 36", "= 36"], rejects=["12", "8", "6"]),
                  answer="36"),
            probe("x² = 64 and x is positive. Find x.",
                  one(num("8"), accepts=["x = 8", "8", "x=8"], rejects=["32", "64", "4096"]),
                  answer="x = 8"),
            probe("A right-angled triangle has shorter sides 5 cm and 12 cm. Find the longest side.",
                  one(num("13"), accepts=["13", "13 cm", "√169 = 13"], rejects=["17", "169", "7"]),
                  answer="13 cm"),
        ]),
    "fractions": footing(
        skill="Use a common denominator and improper fractions",
        teach="Add or subtract fractions only once they share a denominator: 1/2 + 1/3 = 3/6 + 2/6 = 5/6, never 2/5. Turn a mixed number into an improper fraction first, so 1 1/2 is 3/2.",
        probes=[
            probe("Work out 1/3 + 1/4.",
                  one(num("7/12"), accepts=["7/12", "4/12 + 3/12 = 7/12", "= 7/12"], rejects=["2/7", "2/12", "1/7"]),
                  answer="7/12"),
            probe("Work out 2 1/3 − 1 2/3.",
                  one(num("2/3"), accepts=["2/3", "7/3 − 5/3 = 2/3", "= 2/3"], rejects=["1 1/3", "1/3", "-1/3"]),
                  answer="2/3"),
            probe("Work out 2 1/2 × 1 1/5.",
                  one(num("3"), accepts=["3", "5/2 × 6/5 = 3", "= 3"], rejects=["2 1/10", "2", "21/10"]),
                  answer="3"),
        ]),
    "rounding": footing(
        skill="Round to decimal places and significant figures",
        teach="Look at the digit after the last one you keep and round up if it is 5 or more, so 2.367 to 2 decimal places is 2.37, not 2.36. Significant figures start at the first digit that is not zero: 0.005281 to 2 significant figures is 0.0053.",
        probes=[
            probe("Round 4.2861 to 2 decimal places.",
                  one(num("4.29"), accepts=["4.29", "= 4.29", "4.29 (2 dp)"], rejects=["4.28", "4.3", "4.286"]),
                  answer="4.29"),
            probe("Round 0.07368 to 2 significant figures.",
                  one(num("0.074"), accepts=["0.074", "= 0.074", ".074"], rejects=["0.07", "0.073", "0.0737"]),
                  answer="0.074"),
            probe("Round 52,718 to 2 significant figures.",
                  one(num("53000"), accepts=["53,000", "53000", "= 53000"], rejects=["52,000", "53", "52"]),
                  answer="53,000"),
        ]),
    "place-value": footing(
        skill="Multiply and divide by 10, 100 and decimals",
        teach="Multiplying by 100 moves every digit two places to the left, so 0.47 × 100 = 47, and a recurring decimal never stops, so 10 × 0.333… take away 0.333… is exactly 3. To divide by a decimal, multiply both numbers by 10 until it is whole: 12 ÷ 0.3 = 120 ÷ 3 = 40.",
        probes=[
            probe("Work out 0.36 × 100.",
                  one(num("36"), accepts=["36", "= 36", "0.36 × 100 = 36"], rejects=["3.6", "360", "0.0036"]),
                  answer="36"),
            probe("Work out 36 ÷ 0.4.",
                  one(num("90"), accepts=["90", "360 ÷ 4 = 90", "= 90"], rejects=["9", "14.4", "900"]),
                  answer="90"),
            probe("x = 0.555…, where the fives go on for ever. Work out 10x − x.",
                  one(num("5"), accepts=["5", "9x = 5", "5.555… − 0.555… = 5"], rejects=["4.995", "5.55", "0.5"]),
                  answer="5"),
        ]),
    "multiply-or-divide": footing(
        skill="Choose multiply or divide, and which way round",
        teach="Ask what one of something is worth: if 4 pens cost £6, one pen costs 6 ÷ 4 = £1.50, and the amount you share out goes first. Dividing by a number less than 1 gives a bigger answer, so 2 ÷ 0.5 = 4.",
        probes=[
            probe("A car goes 75 km on 6 litres of fuel. How far does it go on 1 litre?",
                  one(num("12.5"), accepts=["12.5", "12.5 km", "75 ÷ 6 = 12.5"], rejects=["0.08", "450", "81"]),
                  answer="12.5 km"),
            probe("How many 0.25 kg bags can be filled from 3 kg of rice?",
                  one(num("12"), accepts=["12", "12 bags", "3 ÷ 0.25 = 12"], rejects=["0.75", "1.2", "0.083"]),
                  answer="12"),
            probe("A 1.5 m ribbon is cut into pieces 0.3 m long. How many pieces are there?",
                  one(num("5"), accepts=["5", "5 pieces", "1.5 ÷ 0.3 = 5"], rejects=["0.45", "0.2", "45"]),
                  answer="5"),
        ]),
    "ratio-and-proportion": footing(
        skill="Work out what one part is worth",
        teach="Find one part first: to share 45 in the ratio 4 : 5, there are 9 parts, so one part is 5 and the shares are 20 and 25. If more workers do the same job, it takes less time: 2 workers taking 6 hours means 1 worker takes 12 hours.",
        probes=[
            probe("Share 60 in the ratio 2 : 3.",
                  key([part("smaller share", num("24")), part("larger share", num("36"))],
                      accepts=["24 and 36", "24, 36", "£24 and £36"],
                      rejects=["30 and 30", "12 and 18", "24", "20 and 40"]),
                  answer="24 and 36"),
            probe("4 workers paint a fence in 6 days. How long would 8 workers take at the same rate?",
                  one(num("3"), accepts=["3", "3 days", "24 ÷ 8 = 3"], rejects=["12", "2", "1.5"]),
                  answer="3 days"),
            probe("Two amounts are in the ratio 2 : 5. The larger is 15 more than the smaller. What is the smaller amount?",
                  one(num("10"), accepts=["10", "= 10", "3 parts = 15, so 2 parts = 10"], rejects=["6", "5", "3"]),
                  answer="10"),
        ]),
    "percentages": footing(
        skill="Use a multiplier for a percentage change",
        teach="A percentage change is one multiplication: a 30% decrease is × 0.7 and a 5% increase is × 1.05. Two changes multiply, so up 40% then down 40% is × 1.4 × 0.6 = × 0.84, and to undo a change you divide by its multiplier.",
        probes=[
            probe("What do you multiply by to decrease an amount by 15%?",
                  one(num("0.85"), accepts=["0.85", "× 0.85", "multiply by 0.85"], rejects=["0.15", "1.15", "1.85"]),
                  answer="0.85"),
            probe("A price rises by 10%, then rises by 10% again. What single multiplier does the same?",
                  one(num("1.21"), accepts=["1.21", "1.1 × 1.1 = 1.21", "× 1.21"], rejects=["1.2", "1.1", "0.21"]),
                  answer="1.21"),
            probe("After a 20% increase, a coat costs £60. What did it cost before the increase?",
                  one(num("50"), accepts=["50", "£50", "60 ÷ 1.2 = 50"], rejects=["48", "72", "40"]),
                  answer="£50"),
        ]),
    "units-and-scale": footing(
        skill="Convert units, and square the factor for areas",
        teach="Change every length to the same unit before you calculate: 1 m = 100 cm, so 3.2 m = 320 cm. An area scales by the square of the length factor, so 1 m² = 100 × 100 = 10,000 cm², and doubling every length makes an area 4 times as big.",
        probes=[
            probe("Write 2.5 m in centimetres.",
                  one(num("250"), accepts=["250", "250 cm", "= 250 cm"], rejects=["25", "2500", "0.025"]),
                  answer="250 cm"),
            probe("How many cm² are there in 3 m²?",
                  one(num("30000"), accepts=["30,000", "30000 cm²", "3 × 10,000 = 30,000"], rejects=["300", "3000", "900"]),
                  answer="30,000 cm²"),
            probe("A shape has area 5 cm². It is enlarged by scale factor 3. What is its new area?",
                  one(num("45"), accepts=["45", "45 cm²", "5 × 9 = 45"], rejects=["15", "135", "8"]),
                  answer="45 cm²"),
        ]),
    "area-and-perimeter": footing(
        skill="Use the right lengths in area and perimeter",
        teach="A triangle's area is half of base × perpendicular height, so base 6 cm and height 4 cm give 12 cm², and a slanted side is never the height. Use the radius in πr², and add every edge for a perimeter: a quarter circle of radius 2 cm has perimeter π + 4.",
        probes=[
            probe("A triangle has base 12 cm, a slanted side 10 cm and perpendicular height 8 cm. Find its area.",
                  one(num("48"), accepts=["48", "48 cm²", "1/2 × 12 × 8 = 48"], rejects=["96", "60", "120"]),
                  answer="48 cm²"),
            probe("A semicircle has diameter 10 cm. Find its perimeter, using π = 3.14.",
                  one(num("25.7", tolerance=0.05), accepts=["25.7", "25.7 cm", "15.7 + 10 = 25.7"], rejects=["15.7", "41.4", "31.4"]),
                  answer="25.7 cm"),
            probe("A circle has diameter 12 cm. Find its area in terms of π.",
                  one(forms("36π", "36pi"), accepts=["36π", "36π cm²", "A = 36π"], rejects=["144π", "12π", "6π"]),
                  answer="36π cm²"),
        ]),
    "angle-facts": footing(
        skill="Use angle facts for parallel lines, polygons and bearings",
        teach="Co-interior angles between parallel lines add to 180°, and an exterior angle of a polygon is 180° take away the interior angle, so an interior angle of 108° has exterior angle 72°. A back-bearing is the bearing plus 180°, or minus 180° if that passes 360°: the back-bearing of 050° is 230°.",
        probes=[
            probe("Two parallel lines are cut by a transversal. One co-interior angle is 115°. Find the other.",
                  one(num("65"), accepts=["65", "65°", "180 − 115 = 65"], rejects=["115", "245", "25"]),
                  answer="65°"),
            probe("Each interior angle of a regular polygon is 150°. What is each exterior angle?",
                  one(num("30"), accepts=["30", "30°", "180 − 150 = 30"], rejects=["150", "210", "24"]),
                  answer="30°"),
            probe("The bearing of B from A is 120°. What is the bearing of A from B?",
                  one(num("300"), accepts=["300", "300°", "120 + 180 = 300"], rejects=["120", "240", "060"]),
                  answer="300°"),
        ]),
    "coordinates-and-gradient": footing(
        skill="Find a midpoint and a gradient from coordinates",
        teach="The midpoint averages the x-coordinates and then the y-coordinates, keeping x first: the midpoint of (1, 2) and (5, 10) is (3, 6). Gradient is change in y ÷ change in x, and a perpendicular gradient flips it and changes its sign, so 2/3 becomes −3/2.",
        probes=[
            probe("Find the midpoint of (2, 3) and (8, 11).",
                  one(seq("5", "7"), accepts=["(5, 7)", "5, 7", "M = (5, 7)"], rejects=["(3, 4)", "(7, 5)", "(10, 14)"]),
                  answer="(5, 7)"),
            probe("Find the gradient of the line through (2, 1) and (5, 13).",
                  one(num("4"), accepts=["4", "12/3 = 4", "m = 4"], rejects=["1/4", "12", "3"]),
                  answer="4"),
            probe("A line has gradient 3. What is the gradient of a line perpendicular to it?",
                  one(num("-1/3"), accepts=["-1/3", "−1/3", "m = -1/3"], rejects=["1/3", "-3", "3"]),
                  answer="−1/3"),
        ]),
    "transformations": footing(
        skill="Reflect, rotate and enlarge a point",
        teach="Check the mirror line or centre before you move: reflecting (3, 4) in the y-axis gives (−3, 4), and a 90° turn clockwise about the origin takes (x, y) to (y, −x). To enlarge about a centre, multiply the step from the centre to the point, then add it back on: (3, 2) from centre (1, 1) by scale factor 3 is (7, 4).",
        probes=[
            probe("Reflect the point (2, 5) in the x-axis.",
                  one(seq("2", "-5"), accepts=["(2, −5)", "(2, -5)", "2, -5"], rejects=["(-2, 5)", "(5, 2)", "(2, 5)"]),
                  answer="(2, −5)"),
            probe("Rotate the point (3, 1) through 90° clockwise about the origin.",
                  one(seq("1", "-3"), accepts=["(1, −3)", "(1, -3)", "1, -3"], rejects=["(-1, 3)", "(-3, -1)", "(1, 3)"]),
                  answer="(1, −3)"),
            probe("Enlarge the point (4, 3) by scale factor 2, centre (1, 1).",
                  one(seq("7", "5"), accepts=["(7, 5)", "7, 5", "R′ = (7, 5)"], rejects=["(8, 6)", "(6, 4)", "(5, 3)"]),
                  answer="(7, 5)"),
        ]),
    "equally-likely-outcomes": footing(
        skill="List equally likely outcomes and count each once",
        teach="List every outcome so each one is equally likely: a coin and a spinner numbered 1 to 3 give H1, H2, H3, T1, T2 and T3, six outcomes. When order does not matter, a pair like AB is the same as BA, so count it once.",
        probes=[
            probe("Two fair coins are flipped. What is the probability of one head and one tail?",
                  one(num("1/2"), accepts=["1/2", "2/4", "0.5"], rejects=["1/3", "1/4", "2/3"]),
                  answer="1/2"),
            probe("Two fair dice are rolled. What is the probability that the total is 3?",
                  one(num("1/18"), accepts=["1/18", "2/36", "2/36 = 1/18"], rejects=["1/36", "1/11", "1/6"]),
                  answer="2/36 = 1/18"),
            probe("How many different pairs can you choose from 4 people, if order does not matter?",
                  one(num("6"), accepts=["6", "6 pairs", "12 ÷ 2 = 6"], rejects=["12", "16", "8"]),
                  answer="6"),
        ]),
    "the-right-total": footing(
        skill="Use the right total for a probability",
        teach="The total is the group you are picking from at that moment. If 1 of 10 sweets is eaten, the next pick is out of 9, and if you are told the person wears glasses, the total is only the people who wear glasses.",
        probes=[
            probe("A bag has 4 red and 2 blue counters. A red counter is taken out and not put back. What is the probability that the next counter is red?",
                  one(num("3/5"), accepts=["3/5", "0.6", "= 3/5"], rejects=["2/3", "4/6", "3/6"]),
                  answer="3/5"),
            probe("In a club of 20, 12 play football and 3 of those also play chess. A football player is picked at random. What is the probability that they play chess?",
                  one(num("1/4"), accepts=["1/4", "3/12", "0.25"], rejects=["3/20", "12/20", "3/17"]),
                  answer="3/12 = 1/4"),
            probe("In a class of 30, 15 wear glasses and 10 are left-handed. 5 are left-handed and wear glasses. A student who wears glasses is picked. What is the probability they are left-handed?",
                  one(num("1/3", tolerance=0.001), accepts=["1/3", "5/15", "0.333"], rejects=["1/2", "5/10", "1/6"]),
                  answer="5/15 = 1/3"),
        ]),
    "spread-and-density": footing(
        skill="Find class width, frequency density and quartiles",
        teach="Class width is the upper boundary take away the lower one, and frequency density is frequency ÷ class width: 10 ≤ x < 40 has width 30, so frequency 60 gives density 2. The interquartile range is the upper quartile minus the lower quartile, not the largest value minus the smallest.",
        probes=[
            probe("The class 20 ≤ t < 35 has frequency 45. Find its frequency density.",
                  one(num("3"), accepts=["3", "45 ÷ 15 = 3", "= 3"], rejects=["45", "1.29", "2.25"]),
                  answer="3"),
            probe("A histogram bar for 0 ≤ x < 5 has frequency density 4. How many values are in that class?",
                  one(num("20"), accepts=["20", "4 × 5 = 20", "= 20"], rejects=["4", "0.8", "1.25"]),
                  answer="20"),
            probe("Find the interquartile range of 1, 3, 8, 9, 12, 20, 24.",
                  one(num("17"), accepts=["17", "IQR = 17", "20 − 3 = 17"], rejects=["23", "9", "3"]),
                  answer="17"),
        ]),
    "vectors": footing(
        skill="Add and subtract column vectors",
        teach="Add or subtract the top numbers, then the bottom numbers: (2, 5) − (3, 1) = (−1, 4). To go from P to Q, go back to O and then out again, so PQ = −p + q.",
        probes=[
            probe("Work out the column vector (3, 2) + (1, −4).",
                  one(seq("4", "-2"), accepts=["(4, −2)", "(4, -2)", "4, -2"], rejects=["(4, 2)", "(2, 6)", "(3, -8)"]),
                  answer="(4, −2)"),
            probe("Work out the column vector (5, 1) − (2, 3).",
                  one(seq("3", "-2"), accepts=["(3, −2)", "(3, -2)", "3, -2"], rejects=["(7, 4)", "(3, 2)", "(-3, 2)"]),
                  answer="(3, −2)"),
            probe("OA = a and OB = b. Write the vector AB in terms of a and b.",
                  one(forms("b-a", "-a+b"), accepts=["b − a", "AB = b - a", "-a + b"], rejects=["a − b", "a + b", "b + a"]),
                  answer="b − a"),
        ]),
    "nth-term": footing(
        skill="Find and use the nth term of a sequence",
        teach="Sequences start at n = 1, so test a rule by putting n = 1 and n = 2 back in: for 2, 7, 12, … the rule 5n − 3 gives 2, then 7. Counting from 3 to 6 including both ends gives 4 numbers, not 3.",
        probes=[
            probe("Find the nth term of 5, 8, 11, 14, …",
                  one(forms("3n+2", "2+3n"), accepts=["3n + 2", "3n+2", "nth term = 3n + 2"], rejects=["3n + 5", "n + 3", "3n"]),
                  answer="3n + 2"),
            probe("The nth term of a sequence is 4n − 1. Find the 10th term.",
                  one(num("39"), accepts=["39", "4 × 10 − 1 = 39", "= 39"], rejects=["40", "35", "43"]),
                  answer="39"),
            probe("How many whole numbers are there from 5 to 12, counting both 5 and 12?",
                  one(num("8"), accepts=["8", "12 − 5 + 1 = 8", "= 8"], rejects=["7", "17", "6"]),
                  answer="8"),
        ]),
    "answer-the-question": footing(
        skill="Check you answered what was asked",
        teach="Before you write the answer, reread the last line of the question. If a = 5 and it asks for 3a − 2, then 5 is only a step and 13 is the answer.",
        probes=[
            probe("A shirt costs £20. It is reduced by 15%. What is the new price?",
                  one(num("17"), accepts=["17", "£17", "20 − 3 = 17"], rejects=["3", "23", "5"]),
                  answer="£17"),
            probe("3x = 12. Find the value of 2x + 1.",
                  one(num("9"), accepts=["9", "= 9", "x = 4, so 2x + 1 = 9"], rejects=["4", "8", "25"]),
                  answer="9"),
            probe("A rectangle has perimeter 30 cm and length 9 cm. Find its area.",
                  one(num("54"), accepts=["54", "54 cm²", "9 × 6 = 54"], rejects=["6", "270", "21"]),
                  answer="54 cm²"),
        ]),
}

STANDS_ON = {
    "sign-of-product": "negative-numbers",
    "dropped-minus": "negative-numbers",
    "inequality-not-flipped": "negative-numbers",
    "rearranged-sign": "inverse-operations",
    "inverse-wrong-order": "inverse-operations",
    "inverse-as-reciprocal": "inverse-operations",
    "expand-first-term-only": "distributive-law",
    "square-of-difference": "distributive-law",
    "lcm-as-product": "factors-and-multiples",
    "hcf-lcm-swapped": "factors-and-multiples",
    "common-factor-left": "factors-and-multiples",
    "forgot-square-root": "squares-and-roots",
    "added-sides": "squares-and-roots",
    "power-as-multiply": "squares-and-roots",
    "added-denominators": "fractions",
    "split-mixed-number": "fractions",
    "truncated": "rounding",
    "decimal-places-not-sf": "rounding",
    "place-value-shift": "place-value",
    "recurring-as-terminating": "place-value",
    "multiplied-instead-of-divided": "multiply-or-divide",
    "divided-wrong-way-round": "multiply-or-divide",
    "equal-split": "ratio-and-proportion",
    "direct-for-inverse": "ratio-and-proportion",
    "unmatched-middle": "ratio-and-proportion",
    "wrong-units-for-difference": "ratio-and-proportion",
    "percent-of-wrong-amount": "percentages",
    "percentages-cancel": "percentages",
    "simple-not-compound": "percentages",
    "unit-slip": "units-and-scale",
    "area-by-length-factor": "units-and-scale",
    "forgot-half": "area-and-perimeter",
    "height-slant-mixed": "area-and-perimeter",
    "radius-diameter-mixed": "area-and-perimeter",
    "missing-edges": "area-and-perimeter",
    "co-interior-as-equal": "angle-facts",
    "interior-for-exterior": "angle-facts",
    "back-bearing": "angle-facts",
    "swapped-coordinates": "coordinates-and-gradient",
    "half-difference": "coordinates-and-gradient",
    "perpendicular-gradient": "coordinates-and-gradient",
    "centre-ignored": "transformations",
    "wrong-mirror-line": "transformations",
    "wrong-turn-direction": "transformations",
    "unequal-outcomes": "equally-likely-outcomes",
    "order-mixed": "equally-likely-outcomes",
    "conditional-reversed": "the-right-total",
    "wrong-total": "the-right-total",
    "with-replacement": "the-right-total",
    "density-as-frequency": "spread-and-density",
    "boundary-for-width": "spread-and-density",
    "range-for-iqr": "spread-and-density",
    "vector-combined-wrongly": "vectors",
    "off-by-one": "nth-term",
    "stopped-early": "answer-the-question",
}


DECREASE_WORDS = ["decrease", "decreases", "decreased", "down", "less", "lower", "loss", "fall", "falls",
                  "drop", "drops", "reduction", "reduced", "smaller"]
INCREASE_WORDS = ["increase", "increases", "increased", "up", "more", "gain"]

ANSWER_KEYS = {
    # Chapter 1
    "q-oup-ch01-sb": key(
        [part("HCF", num("24")), part("LCM", num("360"))],
        accepts=["HCF = 24, LCM = 360", "24 and 360", "hcf 24 lcm 360"],
        rejects=["HCF = 12, LCM = 360", "24", "360", "HCF = 240, LCM = 3600"],
        mistakes=[
            mistake("hcf-lcm-swapped", forms("hcf=72", "hcf is 72", "lcm=120", "lcm is 120"),
                    next_step="The HCF takes the lower power of each shared prime and the LCM the higher power of every prime, so check which rule you used for each.",
                    examples=["HCF = 72, LCM = 360", "HCF = 24, LCM = 120"]),  # highest powers used for the HCF (2³ × 3² = 72), or lowest for the LCM (2³ × 3 × 5 = 120)
            mistake("lcm-as-product", num("8640"),
                    next_step="The LCM uses each prime once at its highest power, so rebuild it from the two prime factor lists.",
                    examples=["HCF = 24, LCM = 8640"]),  # 72 × 120 = 8640 taken as the LCM
        ]),
    "q-oup-ch01-wb-focus": one(
        num("-16"),
        accepts=["-16", "−16", "= -16"],
        rejects=["16", "−160", "-1.6", "-8"],
        mistakes=[
            mistake("sign-of-product", num("16"), num("0"),
                    next_step="Count the minus signs in each multiplication and division: an odd number of them makes the result negative.",
                    examples=["16", "0"]),  # 24 ÷ (−3) taken as +8 and (−2)³ as +8 give 16; one of the two gives 0
        ]),
    "q-oup-ch01-wb-practice": one(
        num("72"),
        accepts=["72", "72 seconds", "72s", "after 72 seconds"],
        rejects=["432", "6", "42 seconds", "7.2"],
        mistakes=[
            mistake("hcf-lcm-swapped", num("6"),
                    next_step="They flash together at a time both cycles reach, so look for a shared multiple, not a shared factor.",
                    examples=["6", "6 seconds"]),  # HCF(18, 24) = 6
            mistake("lcm-as-product", num("432"),
                    next_step="Multiplying gives a common multiple, but list the multiples of each and look for an earlier one they share.",
                    examples=["432"]),  # 18 × 24 = 432
        ]),
    "q-oup-ch01-wb-challenge": one(
        num("60"),
        accepts=["60", "b = 60", "b=60"],
        rejects=["b = 15", "6", "600", "2160"],
        mistakes=[
            mistake("stopped-early", num("2160"),
                    next_step="HCF × LCM equals a × b, so there is one more step to get b on its own.",
                    examples=["2160"]),  # 12 × 180 = 2160, never divided by a
            mistake("lcm-as-product", num("5"),
                    next_step="a × b equals HCF × LCM, not the LCM alone, so put the HCF back into the equation.",
                    examples=["b = 5"]),  # 180 ÷ 36 = 5, taking LCM = a × b
        ]),
    # Chapter 2
    "q-oup-ch02-sb": one(
        forms("5x+3", "3+5x"),
        accepts=["5x+3", "5x + 3", "3 + 5x", "= 5x + 3"],
        rejects=["5x - 3", "5x + 27", "5x", "11x + 3", "5x+3x"],
        mistakes=[
            mistake("sign-of-product", forms("5x-27", "-27+5x", "11x+3", "3+11x"),
                    next_step="Multiply the minus in front of the second bracket by each term inside it, and check the sign of each product.",
                    examples=["5x − 27", "11x + 3"]),  # (−3)(−5) taken as −15, or (−3)(x) as +3x
            mistake("expand-first-term-only", forms("5x-7", "-7+5x", "5x+12", "12+5x"),
                    next_step="Check that the number outside each bracket multiplies every term inside it, not just the first.",
                    examples=["5x − 7", "5x + 12"]),  # −3(x − 5) as −3x + 5, or 4(2x − 3) as 8x − 3
        ]),
    "q-oup-ch02-wb-focus": one(
        forms("6ab(3a-2b)", "6ab (3a-2b)", "6ba(3a-2b)", "6ba (3a-2b)", "6ab(-2b+3a)", "(3a-2b)6ab",
              "6ab*(3a-2b)", "-6ab(2b-3a)"),
        accepts=["6ab(3a − 2b)", "6ab(3a-2b)", "6ab (3a - 2b)", "6ba(3a-2b)"],
        rejects=["6a(3ab − 2b²)", "6ab(3a + 2b)", "3ab(6a − 4b)", "6ab"],
        mistakes=[
            mistake("common-factor-left", forms("6a(3ab-2b^2)", "6b(3a^2-2ab)", "3ab(6a-4b)", "2ab(9a-6b)", "6(3a^2b-2ab^2)"),
                    next_step="Look inside your bracket: if its terms still share a number or a letter, take that out as well.",
                    examples=["6a(3ab − 2b²)", "3ab(6a − 4b)"]),  # only part of 6ab taken out
            mistake("dropped-minus", forms("6ab(3a+2b)", "6ab (3a+2b)", "6ba(3a+2b)"),
                    next_step="Multiply your bracket back out and compare each sign with the question.",
                    examples=["6ab(3a + 2b)"]),  # −12ab² ÷ 6ab written as +2b
        ]),
    "q-oup-ch02-wb-practice": one(
        forms("8x+38", "38+8x", "2(4x+19)"),
        accepts=["8x + 38", "8x+38 cm²", "8x + 38cm^2", "38 + 8x"],
        rejects=["8x + 22", "8x", "16x + 38", "8x − 38"],
        mistakes=[
            mistake("sign-of-product", forms("8x+22", "22+8x"),
                    next_step="Taking away the small rectangle subtracts every term of its area, so check the sign of each term after the minus.",
                    examples=["8x + 22"]),  # −4 × (−2) taken as −8
            mistake("expand-first-term-only", forms("8x+13", "13+8x", "8x+32", "32+8x"),
                    next_step="Check that each width multiplies both terms of its length, not just the first.",
                    examples=["8x + 13", "8x + 32"]),  # 6(2x + 5) as 12x + 5, or 4(x − 2) as 4x − 2
        ]),
    "q-oup-ch02-wb-challenge": one(
        num("8100"),
        accepts=["8100", "8,100", "4050 × 2 = 8100"],
        rejects=["810", "4050", "8", "81000"],
        mistakes=[
            mistake("square-of-difference", num("4"),
                    next_step="a² − b² is not (a − b)², so write it as the product of two brackets before you work anything out.",
                    examples=["4"]),  # (2026 − 2024)² = 2² = 4
            mistake("stopped-early", num("4050"), num("2"),
                    next_step="You have worked out one bracket, so work out the other and multiply them together.",
                    examples=["4050", "2"]),  # stopped at one bracket: 2026 + 2024 = 4050 or 2026 − 2024 = 2
        ]),
    # Chapter 3
    "q-oup-ch03-sb": one(
        num("248"),
        accepts=["248", "248°", "068 + 180 = 248"],
        rejects=["068", "112", "292", "68"],
        mistakes=[
            mistake("back-bearing", num("112"), num("68"),
                    next_step="From the buoy you face back towards the harbour, the opposite way, so turn half a full turn from the outward bearing.",
                    examples=["112°", "068°"]),  # 180 − 068 = 112, or the outward bearing 068 kept
        ]),
    "q-oup-ch03-wb-focus": one(
        num("12"),
        accepts=["12", "12 edges", "E = 12"],
        rejects=["16", "14", "2", "120"],
        mistakes=[
            mistake("rearranged-sign", num("16"), num("-12"),
                    next_step="Put V and F into the formula first, then move E across carefully, changing its sign as it crosses.",
                    examples=["16", "E = -12"]),  # E = 6 + 8 + 2, or −E = −12 left as E = −12
        ]),
    "q-oup-ch03-wb-practice": key(
        [part("the right angle", words(["bac", "cab", "angle a", "at a", "a 90", "a is 90"])),
         part("the locus", words(["equidistant", "equal distance", "same distance", "equally distant", "equally far"]))],
        accepts=["Angle BAC = 90°; locus equidistant from A and B", "angle A, points equidistant from A and B",
                 "BAC. All points the same distance from A and B", "∠A = 90, equidistant from A and B"],
        rejects=["Angle ABC = 90°; equidistant from A and B", "angle C, the midpoint of AB", "BAC", "90"]),
    "q-oup-ch03-wb-challenge": one(
        num("20"),
        accepts=["20", "20 km", "20km", "√400 = 20"],
        rejects=["28", "4", "400", "200"],
        mistakes=[
            mistake("added-sides", num("28"),
                    next_step="The two legs of the journey meet at a right angle, so the direct distance is the longest side of a right triangle.",
                    examples=["28", "28 km"]),  # 12 + 16 = 28
            mistake("forgot-square-root", num("400"),
                    next_step="You have found the longest side squared, so take one more step to get the side itself.",
                    examples=["400"]),  # 12² + 16² = 400 with no square root
        ]),
    # Chapter 4
    "q-oup-ch04-sb": key(
        [part("the three sample sizes", seq("20", "15", "15", ignoring=("7", "8", "9")))],
        accepts=["20, 15, 15", "Year 7: 20, Year 8: 15, Year 9: 15", "20 Year 7, 15 Year 8 and 15 Year 9", "20,15,15"],
        rejects=["17, 17, 16", "240, 180, 180", "20, 15", "15, 15, 20", "24, 18, 18"],
        mistakes=[
            mistake("equal-split", seq("17", "17", "16", ignoring=("7", "8", "9")), seq("16", "17", "17", ignoring=("7", "8", "9")),
                    next_step="Each year's share of the sample should match its share of the whole school, so work out each year's fraction of the total first.",
                    examples=["17, 17, 16", "Year 7: 16, Year 8: 17, Year 9: 17"]),  # 50 ÷ 3 ≈ 17 for each year
        ]),
    "q-oup-ch04-wb-focus": one(
        num("30"),
        accepts=["30", "k = 30", "every 30th student"],
        rejects=["20", "600", "3", "12000"],
        mistakes=[
            mistake("multiplied-instead-of-divided", num("12000"),
                    next_step="The interval is the gap between chosen students, so ask how many students on the list there are for each one chosen.",
                    examples=["12000"]),  # 600 × 20 = 12000
            mistake("divided-wrong-way-round", num("1/30", tolerance=0.001),
                    next_step="The interval should be a whole number of students, so check which number goes on top when you divide.",
                    examples=["1/30", "0.033"]),  # 20 ÷ 600 = 1/30
        ]),
    "q-oup-ch04-wb-practice": key(
        [part("the reason", words(
            ["exercise", "exercises", "exercisers", "exercising", "active", "fit", "fitter", "sporty", "gym",
             "workout", "work out", "train"],
            ["more", "already", "habitual", "regular", "regularly", "often", "a lot", "lots", "too high",
             "higher", "overestimate", "overestimates", "keen"]))],
        accepts=["Selection bias towards habitual early-morning exercisers",
                 "People at a gym at 6 am already exercise a lot, so the average would be too high",
                 "they exercise more than most people"],
        rejects=["because it is biased", "it is too early in the morning", "Mumbai is a big city", "I do not know"]),
    "q-oup-ch04-wb-challenge": one(
        num("4"), forms("4n"), words(["quadruple", "quadrupled", "four"]),
        accepts=["Multiply sample size by 4", "4", "×4", "4 times", "quadruple it", "four times bigger"],
        rejects=["2", "double it", "16", "half"],
        mistakes=[
            mistake("forgot-square-root", num("2"), words(["double", "doubled", "doubling", "twice"]),
                    next_step="The error depends on the square root of n, so ask what n must become for its square root to double.",
                    examples=["2", "double it"]),  # SE read as σ ÷ n, so doubling n would halve it
        ]),
    # Chapter 5
    "q-oup-ch05-sb": one(
        num("375"),
        accepts=["375", "375 litres", "375 L", "375l", "375,000 cm³ = 375 litres"],
        rejects=["375000", "37.5 litres", "3750", "0.375"],
        mistakes=[
            mistake("unit-slip", num("375000"), num("3750"), num("3.75"),
                    next_step="Put every length in centimetres before you multiply, then change cubic centimetres to litres at the end.",
                    examples=["375000 litres", "3750", "3.75 litres"]),  # 375,000 cm³ left unconverted, or the 2.5 m length used as 2.5 cm
            mistake("forgot-half", num("750"), num("750000"),
                    next_step="Check the trapezium's area: average the two parallel sides before you multiply by the height.",
                    examples=["750 litres"]),  # (40 + 60) × 30 × 250 with no ½
        ]),
    "q-oup-ch05-wb-focus": key(
        [part("circumference", num("44")), part("area", num("154"))],
        accepts=["C = 44 cm, A = 154 cm²", "44 and 154", "circumference 44cm area 154cm^2"],
        rejects=["C = 10 cm", "C = 1", "44", "154", "C = 22, A = 154", "C = 44, A = 49"],
        mistakes=[
            mistake("radius-diameter-mixed", num("22"), num("616"),
                    next_step="Circumference uses the diameter, which is twice the radius, while the area squares the radius itself.",
                    examples=["C = 22, A = 154", "C = 44, A = 616"]),  # C = 22/7 × 7, or A = 22/7 × 14²
            mistake("power-as-multiply", forms("a=44", "area=44"),
                    next_step="r² means r times r, so recheck the area with the radius multiplied by itself.",
                    examples=["C = 44, A = 44"]),  # A = 22/7 × 7 × 2 = 44
        ]),
    "q-oup-ch05-wb-practice": key(
        [part("perimeter", num("48")), part("area", num("112"))],
        accepts=["Perimeter = 48 cm, Area = 112 cm²", "48, 112", "P=48 A=112"],
        rejects=["Perimeter = 44, Area = 112", "48 and 140", "112", "24 and 112"],
        mistakes=[
            mistake("height-slant-mixed", num("140"), num("44"),
                    next_step="Area uses the height that meets the base at a right angle, while the perimeter goes round the actual sides.",
                    examples=["48 and 140", "Perimeter = 44, Area = 112"]),  # area 14 × 10 = 140, or perimeter 2 × (14 + 8) = 44
            mistake("missing-edges", num("24"),
                    next_step="A parallelogram has four sides, so trace all the way round and add every side.",
                    examples=["24 and 112"]),  # 14 + 10 = 24, two sides only
        ]),
    "q-oup-ch05-wb-challenge": one(
        num("30.5"),
        accepts=["30.5", "30.5 cm", "30.5cm"],
        rejects=["10.5", "31", "30", "20.5"],
        mistakes=[
            mistake("missing-edges", num("10.5", tolerance=0.05), num("20.5", tolerance=0.05),
                    next_step="Trace the sector's outline: one curved edge and two straight edges, each a radius long.",
                    examples=["10.5", "10.47", "20.5"]),  # arc 2π × 10 ÷ 6 = 10.47 alone, or with one radius: 20.47
            mistake("radius-diameter-mixed", num("25.2", tolerance=0.05),
                    next_step="The arc is a sixth of the whole circumference, and the circumference uses the diameter, not the radius.",
                    examples=["25.2"]),  # π × 10 ÷ 6 + 20 = 25.24
            mistake("truncated", num("30.4"),
                    next_step="Look at the digit after the first decimal place to decide whether to round up.",
                    examples=["30.4"]),  # 30.47 cut to 30.4
        ]),
    # Chapter 6
    "q-oup-ch06-sb": key(
        [part("the subtraction step", forms("99x", "27/99")),
         part("the fraction in simplest form", num("3/11", simplest=True))],
        accepts=["100x − x = 99x = 27, so x = 27/99 = 3/11", "99x = 27 so x = 3/11", "x = 27/99 = 3/11"],
        rejects=["3/11", "27/99", "99x = 27, x = 27/99", "it equals 3/11 because 3 ÷ 11 = 0.2727"],
        mistakes=[
            mistake("recurring-as-terminating", num("27/100"),
                    next_step="The digits repeat for ever, so multiply x by the power of ten that shifts one full repeat, then subtract x.",
                    examples=["x = 27/100"]),  # 0.27 read as if the decimal stopped
            mistake("common-factor-left", forms("9/33", "27/99"),
                    next_step="Check whether the top and bottom of your fraction still share a factor, and divide it out.",
                    examples=["99x = 27, so x = 9/33", "x = 27/99"]),  # 27/99 divided by 3 only, or not at all
        ]),
    "q-oup-ch06-wb-focus": one(
        num("0.00409"),
        accepts=["0.00409", ".00409"],
        rejects=["0.0041", "0.004", "0.00408", "0.004086", "409"],
        mistakes=[
            mistake("decimal-places-not-sf", num("0.004"),
                    next_step="Significant figures start at the first non-zero digit, so count from there, not from the decimal point.",
                    examples=["0.004"]),  # rounded to 3 decimal places
            mistake("truncated", num("0.00408"),
                    next_step="Look at the digit after the last one you keep to decide whether to round up.",
                    examples=["0.00408"]),  # 0.0040862 cut after the 8
            mistake("place-value-shift", num("409"),
                    next_step="Keep the zeros that hold the digits in place after the decimal point, and round only the digits after them.",
                    examples=["409"]),  # the leading zeros dropped
        ]),
    "q-oup-ch06-wb-practice": one(
        forms("2 5/12", "2 and 5/12"),
        accepts=["2 5/12", "= 2 5/12", "2 and 5/12"],
        rejects=["2", "29/12", "2 10/24", "5/12", "3 5/12", "2 7/12"],
        mistakes=[
            mistake("split-mixed-number", num("43/12"), forms("3 and 7/12"),
                    next_step="Turn both mixed numbers into improper fractions, or borrow a whole, before you subtract the fraction parts.",
                    examples=["3 7/12", "43/12"]),  # 4 − 1 = 3, then 3/4 − 1/6 = 7/12 taken the wrong way round
            mistake("added-denominators", num("2"),
                    next_step="Give both fractions the same denominator before you subtract, and keep that denominator in the answer.",
                    examples=["2"]),  # 3 + (1 − 3)/(6 − 4) = 3 − 1 = 2
        ]),
    "q-oup-ch06-wb-challenge": one(
        num("5/4"),
        accepts=["5/4", "1 1/4", "1.25", "5/4 or 1 1/4"],
        rejects=["4/5", "5", "1/4", "36/25", "125"],
        mistakes=[
            mistake("multiplied-instead-of-divided", num("64/45"),
                    next_step="Dividing by a fraction means multiplying by its reciprocal, so check you turned the divisor upside down.",
                    examples=["64/45"]),  # 12/5 × 16/15 × 5/9 = 64/45, the divisor never flipped
            mistake("split-mixed-number", num("40/9"),
                    next_step="Turn each mixed number into an improper fraction before you divide.",
                    examples=["40/9", "4 4/9"]),  # 2 ÷ 1 = 2 and 2/5 ÷ 1/15 = 6, so 8 × 5/9
        ]),
    # Chapter 7
    "q-oup-ch07-sb": key(
        [part("the formula for u", forms("√(v^2-2as)", "√v^2-2as", "(v^2-2as)^(1/2)", "(v^2-2as)^0.5",
                                         "√(v*v-2as)", "√(v^2-2*a*s)", "√(-2as+v^2)")),
         part("the value of u", num("7"))],
        accepts=["u = √(v² − 2as) = 7", "u = sqrt(v^2 - 2as), u = 7", "u = square root of (v^2 − 2as) = 7"],
        rejects=["u = 7", "u = √(v² + 2as) = 7", "u = v² − 2as = 49", "u = √(v² − 2as)"],
        mistakes=[
            mistake("rearranged-sign", forms("√(v^2+2as)", "√v^2+2as"), num("17"),
                    next_step="To get u² alone you take 2as away from both sides, so check the sign in front of 2as.",
                    examples=["u = √(v² + 2as) = 17", "17"]),  # 2as added instead of subtracted: √(169 + 120) = 17
            mistake("forgot-square-root", num("49"), forms("u=v^2-2as"),
                    next_step="You have u² on its own, so take one more step to get u itself.",
                    examples=["u = v² − 2as = 49", "49"]),  # stopped at u² = 169 − 120 = 49
        ]),
    "q-oup-ch07-wb-focus": one(
        num("3"),
        accepts=["3", "x = 3", "x=3", "7x = 21 so x = 3"],
        rejects=["x = 7", "21", "x = -3", "3x", "x = 13/7"],
        mistakes=[
            mistake("expand-first-term-only", num("13/7"), num("17/7"),
                    next_step="Check that each number outside a bracket multiplies both terms inside it.",
                    examples=["x = 13/7", "x = 17/7"]),  # 3(x + 4) as 3x + 4 gives 7x = 13; 5(2x − 1) as 10x − 1 gives 7x = 17
            mistake("rearranged-sign", num("11/7"), num("21/13"),
                    next_step="When a term crosses the equals sign its sign changes, so recheck each move.",
                    examples=["x = 11/7", "x = 21/13"]),  # 10x − 5 = 3x + 16 with −5 moved as −5 gives 7x = 11; 3x moved as +3x gives 13x = 21
        ]),
    "q-oup-ch07-wb-practice": one(
        forms("x≤4", "4≥x"),
        accepts=["x ≤ 4 (largest integer 4)", "x <= 4, largest integer is 4", "4 ≥ x so the largest integer is 4", "x≤4"],
        rejects=["x ≥ 4", "4", "x < 4", "x ≤ -4", "x = 4"],
        mistakes=[
            mistake("inequality-not-flipped", forms("x≥4", "4≤x"),
                    next_step="Dividing both sides by a negative number reverses the inequality sign, so check whether you did that.",
                    examples=["x ≥ 4", "x >= 4"]),  # −3x ≥ −12 divided by −3 without reversing
            mistake("rearranged-sign", forms("x≤-16/3", "x≥-16/3"),
                    next_step="Take 14 from both sides first and check the sign of what is left on the right.",
                    examples=["x ≤ −16/3"]),  # 14 moved across as +14: −3x ≥ 16
        ]),
    "q-oup-ch07-wb-challenge": one(
        forms("(y+2)/(y-3)", "(2+y)/(y-3)", "(y+2)/(-3+y)", "(-y-2)/(3-y)", "-(y+2)/(3-y)"),
        accepts=["x = (y + 2) / (y − 3)", "(y+2)/(y-3)", "x=(2+y)/(y-3)"],
        rejects=["x = (y − 2) / (y + 3)", "x = y + 2 / y − 3", "x = (y + 2) / (3 − y)", "x = (3x + 2) / (x − 1)"],
        mistakes=[
            mistake("rearranged-sign", forms("(2-y)/(y-3)", "(-y+2)/(y-3)", "(y+2)/(y+3)", "(2+y)/(y+3)"),
                    next_step="Collect the x terms on one side and the rest on the other, changing the sign of each term that crosses.",
                    examples=["x = (2 − y)/(y − 3)", "x = (y + 2)/(y + 3)"]),  # xy − y = 3x + 2 with −y moved as −y, or 3x moved as +3x
            mistake("expand-first-term-only", forms("3/(y-3)"),
                    next_step="When you multiply both sides by the bottom of the fraction, check that y multiplies both terms in that bracket.",
                    examples=["x = 3/(y − 3)"]),  # y(x − 1) as xy − 1 gives x(y − 3) = 3
        ]),
    # Chapter 8
    "q-oup-ch08-sb": key(
        [part("x", num("40")), part("angle ACD", num("155"))],
        accepts=["x = 40, ∠ACD = 155°", "40 and 155", "x=40 ACD=155"],
        rejects=["x = 40", "155", "x = 40, ACD = 165", "x = 20, ACD = 75"],
        mistakes=[
            mistake("rearranged-sign", num("30"), num("115"),
                    next_step="When you move the −5 across the equals sign it changes sign, so recheck that step.",
                    examples=["x = 30, ACD = 115"]),  # 4x − 5 = 3x + 35 solved as x = 35 − 5
            mistake("dropped-minus", num("165"),
                    next_step="Put your x back into the expression for angle ACD and check the sign of its last term.",
                    examples=["x = 40, ACD = 165"]),  # 4 × 40 + 5 = 165
        ]),
    "q-oup-ch08-wb-focus": one(
        seq("3", "2"),
        accepts=["M = (3, 2)", "(3,2)", "3, 2", "x = 3, y = 2"],
        rejects=["(2, 3)", "(7, 5)", "(3, -2)", "(6, 4)", "(-7, 5)"],
        mistakes=[
            mistake("forgot-half", seq("6", "4"),
                    next_step="The midpoint is halfway, so after adding the coordinates, finish by halving.",
                    examples=["(6, 4)"]),  # (−4 + 10, 7 + (−3)) not halved
            mistake("half-difference", seq("7", "-5"), seq("-7", "5"),
                    next_step="A midpoint averages the two points, so add each pair of coordinates rather than subtracting.",
                    examples=["(7, -5)", "(-7, 5)"]),  # (10 − (−4)) ÷ 2 and (−3 − 7) ÷ 2, or the other way round
            mistake("swapped-coordinates", seq("2", "3"),
                    next_step="Write the x-coordinate first and the y-coordinate second.",
                    examples=["(2, 3)"]),  # y written before x
        ]),
    "q-oup-ch08-wb-practice": one(
        num("35"),
        accepts=["35", "y = 35", "5y = 175, y = 35"],
        rejects=["y = 15", "175", "y = 17", "3.5"],
        mistakes=[
            mistake("co-interior-as-equal", num("-15"),
                    next_step="Co-interior angles sit on the same side between the parallel lines, so they add to a straight angle rather than being equal.",
                    examples=["y = -15"]),  # 3y + 10 = 2y − 5
            mistake("rearranged-sign", num("37"),
                    next_step="When you move the +5 across the equals sign it becomes −5, so recheck that step.",
                    examples=["y = 37"]),  # 5y + 5 = 180 solved as 5y = 185
        ]),
    "q-oup-ch08-wb-challenge": one(
        num("15"),
        accepts=["15", "15 sides", "n = 15", "360/24 = 15"],
        rejects=["24", "156", "12", "16", "150"],
        mistakes=[
            mistake("stopped-early", num("24"),
                    next_step="You have the exterior angle, so now use what all the exterior angles of a polygon add up to.",
                    examples=["24", "24°"]),  # 180 − 156 = 24, the exterior angle
            mistake("interior-for-exterior", num("2.3", tolerance=0.05),
                    next_step="Find the exterior angle first, since the exterior angles, not the interior ones, add up to a full turn.",
                    examples=["2.3"]),  # 360 ÷ 156 ≈ 2.31
        ]),
    # Chapter 9
    "q-oup-ch09-sb": one(
        num("2400"),
        accepts=["2400", "₹2,400", "Rs 2400", "2040 ÷ 0.85 = 2400"],
        rejects=["2346", "2040", "1734", "240", "24000"],
        mistakes=[
            mistake("percent-of-wrong-amount", num("2346"),
                    next_step="The 15% came off the original price, not the sale price, so the sale price is 85% of the number you want.",
                    examples=["2346"]),  # 2040 + 15% of 2040
            mistake("multiplied-instead-of-divided", num("1734"),
                    next_step="Undoing a multiplier means dividing by it, so check which way you used it.",
                    examples=["1734"]),  # 2040 × 0.85
        ]),
    "q-oup-ch09-wb-focus": one(
        num("240"),
        accepts=["240", "= 240", "3600 ÷ 15 = 240"],
        rejects=["24", "2.4", "5.4", "2400"],
        mistakes=[
            mistake("multiplied-instead-of-divided", num("5.4"),
                    next_step="The question divides by 0.15, so check you did not multiply instead.",
                    examples=["5.4"]),  # 36 × 0.15
            mistake("place-value-shift", num("24"), num("2400"),
                    next_step="Multiply both numbers by the same power of ten to clear the decimal, and check you used the same power on each.",
                    examples=["24", "2400"]),  # 36 ÷ 1.5 or 36 ÷ 0.015
        ]),
    "q-oup-ch09-wb-practice": key(
        [part("the net change", num("-4"), all_of(num("4"), words(DECREASE_WORDS, forbid=INCREASE_WORDS)))],
        accepts=["−4%", "-4", "a 4% decrease", "4% decrease", "it goes down by 4%"],
        rejects=["4%", "0%", "no change", "4% increase", "-40%", "0"],
        mistakes=[
            mistake("percentages-cancel", num("0"), words(["no change", "unchanged", "cancel", "cancels", "same"]),
                    next_step="The 20% decrease is taken from the bigger, increased price, so write each change as a multiplier and multiply them.",
                    examples=["0%", "no change"]),  # +20% and −20% assumed to cancel
        ]),
    "q-oup-ch09-wb-challenge": one(
        num("16550"),
        accepts=["16550", "₹16,550", "16,550", "66,550 − 50,000 = 16,550"],
        rejects=["66550", "15000", "₹66,550", "1655", "16500"],
        mistakes=[
            mistake("simple-not-compound", num("15000"),
                    next_step="Compound interest is worked out on the new total each year, so grow the amount one year at a time.",
                    examples=["15000"]),  # 3 × 10% of 50,000
            mistake("stopped-early", num("66550"),
                    next_step="That is the total in the account, and the interest is only the part added on top of what was put in.",
                    examples=["66550", "₹66,550"]),  # 50,000 × 1.1³ = 66,550, the total
        ]),
    # Chapter 10
    "q-oup-ch10-sb": key(
        [part("the first class", num("1.5")), part("the second class", num("2.5"))],
        accepts=["1.5 and 2.5", "FD₁ = 1.5 and FD₂ = 2.5", "30/20 = 1.5, 25/10 = 2.5", "1.5, 2.5"],
        rejects=["1.5", "2.5", "30 and 25", "0.67 and 0.4", "15 and 25"],
        mistakes=[
            mistake("divided-wrong-way-round", num("2/3", tolerance=0.01), num("0.4"),
                    next_step="Frequency density is frequency per unit of class width, so check which number goes on top.",
                    examples=["0.67 and 0.4"]),  # 20 ÷ 30 and 10 ÷ 25
            mistake("density-as-frequency", num("30"), num("25"),
                    next_step="The frequency is only part of it, so divide by how wide each class is.",
                    examples=["30 and 25"]),  # the frequencies given unchanged
        ]),
    "q-oup-ch10-wb-focus": key(
        [part("median", num("20")), part("IQR", num("14"))],
        accepts=["Median = 20, IQR = 14", "20 and 14", "median 20, IQR = 29 − 15 = 14"],
        rejects=["Median = 20", "IQR = 14", "median 17, IQR 14", "20 and 19", "median 24, IQR 12"],
        mistakes=[
            mistake("range-for-iqr", num("19"),
                    next_step="The interquartile range runs from the lower quartile to the upper quartile, not from the smallest value to the largest.",
                    examples=["Median = 20, IQR = 19", "20 and 19"]),  # 31 − 12 = 19, the range
        ]),
    "q-oup-ch10-wb-practice": one(
        num("2.83", tolerance=0.03), forms("√8", "√(8)", "2√2"),
        accepts=["σ = √8 ≈ 2.83", "2.83", "2.828", "√8", "2√2", "sqrt(8)", "2.8"],
        rejects=["8", "3.16", "√10", "2", "4", "σ = 8"],
        mistakes=[
            mistake("forgot-square-root", num("8"),
                    next_step="You have found the variance, and the standard deviation needs one more step.",
                    examples=["σ = 8", "8"]),  # variance 40 ÷ 5 = 8 with no square root
        ]),
    "q-oup-ch10-wb-challenge": one(
        num("48"),
        accepts=["48", "48 observations", "15 × 3.2 = 48"],
        rejects=["3.2", "15", "80", "4.8", "32"],
        mistakes=[
            mistake("density-as-frequency", num("3.2"),
                    next_step="Frequency density is frequency per unit of class width, so turn it back into a frequency using the width.",
                    examples=["3.2"]),  # the density given as the frequency
            mistake("boundary-for-width", num("80"), num("32"),
                    next_step="The class width is the gap between the two boundaries, not either boundary itself.",
                    examples=["80", "32"]),  # 3.2 × 25 or 3.2 × 10
        ]),
    # Chapter 11
    "q-oup-ch11-sb": key(
        [part("the nth term", forms("4n+3", "3+4n")), part("the sum of 20 terms", num("900"))],
        accepts=["Tₙ = 4n + 3, S₂₀ = 900", "4n+3 900", "4n + 3 and 900", "T_n = 3 + 4n, sum = 900"],
        rejects=["4n + 3", "900", "4n + 7, 900", "4n + 3, 830", "n + 4, 900"],
        mistakes=[
            mistake("off-by-one", forms("4n+7", "7+4n"),
                    next_step="Put n equal to one in your formula and check that it gives the first term.",
                    examples=["4n + 7, 900"]),  # the first term 7 used as the constant
            mistake("off-by-one", num("940"),
                    next_step="Use your nth term formula to find the twentieth term, then pair the terms again.",
                    examples=["4n + 3, 940"]),  # T₂₀ = 7 + 20 × 4 = 87, so 10 × 94
            mistake("forgot-half", num("1800"),
                    next_step="Pairing the first and last terms uses up two terms each time, so recount how many pairs there are.",
                    examples=["4n + 3, 1800"]),  # 20 pairs × 90
        ]),
    "q-oup-ch11-wb-focus": key(
        [part("yes or no", words(["no", "not", "doesn't", "isn't", "cannot", "can't", "never"], forbid=["yes"])),
         part("the reason", num("147"), num("147/4"), words(["integer", "whole"]))],
        accepts=["No, because 4n + 3 = 150 gives 4n = 147, which is not an integer",
                 "No. 4n = 147 and 147 is not a multiple of 4", "no, n would be 36.75",
                 "No because n is not a whole number", "It does not, 147/4 is not an integer"],
        rejects=["I do not know", "Yes", "No", "yes because 147/4 is not whole", "Yes, n = 36.75",
                 "no because it is too big"]),
    "q-oup-ch11-wb-practice": one(
        forms("n^2+2n", "2n+n^2", "n(n+2)", "n (n+2)", "n(2+n)", "(n+1)^2-1", "n*n+2n"),
        accepts=["Tₙ = n² + 2n", "n^2 + 2n", "n(n+2)", "n squared + 2n"],
        rejects=["n² + 2", "n² + 2n + 1", "2n + 1", "n^2"],
        mistakes=[
            mistake("off-by-one", forms("n^2-1", "-1+n^2"),
                    next_step="Put n equal to one in your formula and check that it gives the first term.",
                    examples=["n² − 1"]),  # one less than the square numbers, with n² where (n + 1)² belongs
        ]),
    "q-oup-ch11-wb-challenge": one(
        num("20100"),
        accepts=["20100", "20,100", "200 × 201 ÷ 2 = 20100"],
        rejects=["20000", "40200", "2010", "201", "20200"],
        mistakes=[
            mistake("forgot-half", num("40200"),
                    next_step="Pairing the list with itself reversed counts every number twice, so check that you halved.",
                    examples=["40200"]),  # 200 × 201 with no ÷ 2
            mistake("off-by-one", num("20000"), num("19900"), num("20200"),
                    next_step="Check the formula n(n + 1) ÷ 2 with n equal to the last number, and count your pairs again.",
                    examples=["20000", "19900", "20200"]),  # 200 × 200, 200 × 199 or 200 × 202, then ÷ 2
        ]),
    # Chapter 12
    "q-oup-ch12-sb": one(
        num("4320"),
        accepts=["4320", "₹4,320", "16 × 270 = 4320"],
        rejects=["270", "1350", "432", "2160", "4,300"],
        mistakes=[
            mistake("wrong-units-for-difference", num("2700"), num("7200"),
                    next_step="The ₹1,350 is the gap between Meera and Kym, so it matches the difference in their units, not either share alone.",
                    examples=["2700", "7200"]),  # 1350 ÷ 8 × 16 = 2700, or 1350 ÷ 3 × 16 = 7200
            mistake("stopped-early", num("270"),
                    next_step="That is one unit, so count how many units the whole prize has.",
                    examples=["270"]),  # 1350 ÷ 5 = 270, one unit
        ]),
    "q-oup-ch12-wb-focus": one(
        num("35000"),
        accepts=["35000", "35,000 cm²", "35000 cm^2"],
        rejects=["350", "3500", "350000", "0.00035", "35"],
        mistakes=[
            mistake("area-by-length-factor", num("350"),
                    next_step="A square metre is a square a hundred centimetres on each side, so multiply by the conversion twice.",
                    examples=["350", "350 cm²"]),  # 3.5 × 100
        ]),
    "q-oup-ch12-wb-practice": one(
        num("4"),
        accepts=["4", "4 hours", "4h", "60 ÷ 15 = 4"],
        rejects=["40 hours", "25", "25 hours", "2.5", "10"],
        mistakes=[
            mistake("direct-for-inverse", num("25"),
                    next_step="More pumps should finish faster, so check whether your answer went up or down.",
                    examples=["25", "25 hours"]),  # 10 × 15 ÷ 6 = 25
        ]),
    "q-oup-ch12-wb-challenge": one(
        seq("9", "12", "14"),
        accepts=["9 : 12 : 14", "9:12:14", "A : B : C = 9 : 12 : 14", "9, 12, 14"],
        rejects=["3 : 4 : 7", "18 : 24 : 28", "9 : 12", "3 : 6 : 7", "14 : 12 : 9"],
        mistakes=[
            mistake("unmatched-middle", seq("3", "4", "7"), seq("3", "6", "7"),
                    next_step="B has a different number of parts in each ratio, so scale both ratios until B is the same before you join them.",
                    examples=["3 : 4 : 7", "3 : 6 : 7"]),  # 3 : 4 and 6 : 7 joined without matching B
            mistake("common-factor-left", seq("18", "24", "28"),
                    next_step="Check whether all three numbers still share a factor, and divide it out.",
                    examples=["18 : 24 : 28"]),  # B matched at 4 × 6 = 24 but not simplified
        ]),
    # Chapter 13
    "q-oup-ch13-sb": key(
        [part("the image point", seq("4", "7")), part("the image area", num("54"))],
        accepts=["A′ = (4, 7), Area = 54 cm²", "(4,7) and 54", "A' = (4, 7) area 54"],
        rejects=["(4, 7)", "54", "(6, 9), 54", "(4, 7), 18", "(7, 4), 54"],
        mistakes=[
            mistake("centre-ignored", seq("6", "9"),
                    next_step="Measure from the centre of enlargement to A, multiply that step by the scale factor, then add it back on to the centre.",
                    examples=["(6, 9), 54"]),  # (2, 3) × 3 from the origin
            mistake("area-by-length-factor", num("18"),
                    next_step="Lengths grow by the scale factor, but area grows by the scale factor times itself.",
                    examples=["(4, 7), 18"]),  # 6 × 3
        ]),
    "q-oup-ch13-wb-focus": one(
        seq("5", "-3"),
        accepts=["P′ = (5, −3)", "(5, -3)", "(5,-3)", "5, -3"],
        rejects=["P′ = (3, −5)", "(-3, 5)", "(5, 3)", "(-5, 3)", "(3, 5)"],
        mistakes=[
            mistake("wrong-mirror-line", seq("-5", "3"), seq("3", "5"), seq("-3", "-5"),
                    next_step="Reflecting in y = x swaps the two coordinates and nothing else, so check which line you reflected in.",
                    examples=["(-5, 3)", "(3, 5)", "(-3, -5)"]),  # reflected in y = −x, the y-axis or the x-axis
            mistake("dropped-minus", seq("5", "3"),
                    next_step="Swap the coordinates but keep each one's sign as it moves.",
                    examples=["(5, 3)"]),  # swapped, then the minus on −3 lost
        ]),
    "q-oup-ch13-wb-practice": one(
        seq("-1", "4"),
        accepts=["Q′ = (−1, 4)", "(-1, 4)", "(-1,4)"],
        rejects=["(1, -4)", "(4, 1)", "(1, 4)", "(-4, 1)", "(4, -1)"],
        mistakes=[
            mistake("wrong-turn-direction", seq("1", "-4"),
                    next_step="Anticlockwise turns the opposite way to a clock's hands, so sketch the point and give it a quarter turn that way.",
                    examples=["(1, -4)"]),  # turned 90° clockwise
            mistake("dropped-minus", seq("1", "4"),
                    next_step="A quarter turn swaps the coordinates and changes one sign, so check which one becomes negative.",
                    examples=["(1, 4)"]),  # coordinates swapped, the minus on the new x lost
        ]),
    "q-oup-ch13-wb-challenge": one(
        seq("-1", "0"),
        accepts=["R′ = (−1, 0)", "(-1, 0)", "(-1,0)"],
        rejects=["(7, 4)", "(-1, 4)", "(1, 0)", "(-4, -2)", "(-10, -6)"],
        mistakes=[
            mistake("centre-ignored", seq("-10", "-6"),
                    next_step="Measure from the centre of enlargement to R, not from the origin, then scale that step.",
                    examples=["(-10, -6)"]),  # (5, 3) × −2 from the origin
            mistake("stopped-early", seq("-4", "-2"),
                    next_step="You have the scaled step from the centre, so add it on to the centre's coordinates.",
                    examples=["(-4, -2)"]),  # (2, 1) × −2 never added back on to C
            mistake("dropped-minus", seq("7", "4"),
                    next_step="A negative scale factor sends the image through the centre to the other side, so recheck the sign on your step.",
                    examples=["(7, 4)"]),  # scale factor used as +2: (3, 2) + (4, 2)
        ]),
    # Chapter 14
    "q-oup-ch14-sb": key(
        [part("the equation", forms("2x+5", "5+2x")), part("the x-intercept", num("-2.5"))],
        accepts=["y = 2x + 5, x-intercept = −2.5", "y=2x+5 -2.5", "y = 2x + 5 and (−2.5, 0)", "y=2x+5, x = -5/2"],
        rejects=["y = 2x + 5", "-2.5", "y = 2x + 5, x = 2.5", "y = 2x + 3, −1.5", "y = 12x + 5, -2.5"],
        mistakes=[
            mistake("divided-wrong-way-round", forms("0.5x+2", "1/2x+2", "x/2+2"),
                    next_step="Gradient is the rise in y divided by the run in x, so check which change goes on top.",
                    examples=["y = 0.5x + 2, -4"]),  # run ÷ rise = 6 ÷ 12
            mistake("rearranged-sign", num("2.5"),
                    next_step="To find where the line crosses the x-axis, set y to zero and move the constant across, changing its sign.",
                    examples=["y = 2x + 5, x = 2.5"]),  # 0 = 2x + 5 solved as 2x = 5
        ]),
    "q-oup-ch14-wb-focus": one(
        forms("(x+7)/3", "(7+x)/3", "x/3+7/3", "7/3+x/3", "1/3(x+7)", "1/3 (x+7)", "1/3x+7/3", "(x+7)*1/3"),
        accepts=["f⁻¹(x) = (x + 7) / 3", "(x+7)/3", "y = (x + 7)/3", "f^-1(x) = x/3 + 7/3"],
        rejects=["(x − 7) / 3", "3x + 7", "x + 7 / 3", "(x + 7) / 3x", "1 / (3x − 7)"],
        mistakes=[
            mistake("rearranged-sign", forms("(x-7)/3", "x/3-7/3", "1/3(x-7)"),
                    next_step="Undo each step with its opposite operation, so check the sign of the number you moved.",
                    examples=["(x − 7) / 3"]),  # y = 3x − 7 rearranged as 3x = y − 7
            mistake("inverse-wrong-order", forms("x/3+7", "7+x/3", "1/3x+7"),
                    next_step="Undo the steps in reverse order, because the last thing f does to x is the first thing you undo.",
                    examples=["x/3 + 7"]),  # divided by 3 before adding 7
            mistake("inverse-as-reciprocal", forms("1/(3x-7)"),
                    next_step="An inverse function undoes f, which is not the same as one over f, so reverse each step of f instead.",
                    examples=["1 / (3x − 7)"]),  # f⁻¹ read as 1 ÷ f(x)
        ]),
    "q-oup-ch14-wb-practice": one(
        forms("-1/2x+3", "-x/2+3", "3-1/2x", "3-x/2", "-0.5x+3", "3-0.5x", "-(1/2)x+3", "3-(1/2)x",
              "-1/2*x+3", "-(x/2)+3"),
        accepts=["y = −½x + 3", "y = -1/2x + 3", "y = -x/2 + 3", "y = 3 - 0.5x", "y = -0.5x + 3"],
        rejects=["y = 2x + 3", "y = ½x + 3", "y = −2x + 3", "y = −½x + 5", "y = -1/2x"],
        mistakes=[
            mistake("perpendicular-gradient", forms("1/2x+3", "x/2+3", "0.5x+3", "3+1/2x", "3+x/2", "3+0.5x", "-2x+3", "3-2x", "2x+3", "3+2x"),
                    next_step="A perpendicular gradient is the original turned upside down with its sign changed, so check you did both.",
                    examples=["y = ½x + 3", "y = −2x + 3", "y = 2x + 3"]),  # the gradient only flipped (½), only negated (−2), or kept (2)
        ]),
    "q-oup-ch14-wb-challenge": one(
        seq("2", "4"), all_of(*forms("x=2"), *forms("y=4")),
        accepts=["(2, 4)", "x = 2, y = 4", "y = 4 and x = 2", "(2,4)"],
        rejects=["(4, 2)", "(2, 8)", "x = 2", "(3, 7)", "(-2, 4)"],
        mistakes=[
            mistake("swapped-coordinates", seq("4", "2"),
                    next_step="Write the x value first and the y value second, and check the pair in both equations.",
                    examples=["(4, 2)"]),  # y written before x
            mistake("forgot-half", seq("2", "8"),
                    next_step="After you find x, solve for y in one equation and check you divided by its coefficient.",
                    examples=["(2, 8)"]),  # 2y = 10 − 2 = 8 left as y = 8
            mistake("expand-first-term-only", num("12/7"),
                    next_step="When you put the expression for y into the other equation, check its multiplier reaches both terms of the bracket.",
                    examples=["x = 12/7"]),  # x + 2(3x − 2) as x + 6x − 2, so 7x = 12
        ]),
    # Chapter 15
    "q-oup-ch15-sb": key(
        [part("true positives", num("19")), part("false positives", num("49")),
         part("P(D | +)", num("19/68", tolerance=0.0006), num("27.9", tolerance=0.11))],
        accepts=["TP = 19, FP = 49, P(D|+) = 19/68 ≈ 27.9%", "19, 49, 19/68",
                 "19 true positives, 49 false positives, 27.9%", "19 and 49, so 0.279"],
        rejects=["19, 49", "19/68", "20, 49, 29%", "19, 49, 95%", "19, 49, 19/49"],
        mistakes=[
            mistake("percent-of-wrong-amount", num("50"),
                    next_step="False positives come only from the people without the trait, so take the false-positive rate of that group, not of everyone.",
                    examples=["19, 50, 19/69"]),  # 5% of 1,000 instead of 5% of 980
            mistake("conditional-reversed", num("95"), num("0.95"),
                    next_step="The question asks for the chance of having the trait given a positive test, so start from all the positive tests.",
                    examples=["19, 49, 95%"]),  # P(+ | D) given as P(D | +)
            mistake("wrong-total", num("19/49"), num("19/1000"),
                    next_step="Divide the true positives by everyone who tested positive, true and false together.",
                    examples=["19, 49, 19/49", "19, 49, 19/1000"]),  # TP ÷ FP, or TP ÷ everyone
        ]),
    "q-oup-ch15-wb-focus": one(
        num("1/9", tolerance=0.0012),
        accepts=["1/9", "4/36", "4/36 = 1/9", "0.111", "0.11"],
        rejects=["1/12", "1/6", "9", "4", "5/36", "1/36"],
        mistakes=[
            mistake("unequal-outcomes", num("1/11", tolerance=0.001),
                    next_step="The eleven possible sums are not equally likely, so count the ordered pairs of dice instead.",
                    examples=["1/11"]),  # one sum out of the eleven sums from 2 to 12
            mistake("order-mixed", num("1/18", tolerance=0.001),
                    next_step="The two dice are different, so three-then-six and six-then-three count as separate outcomes.",
                    examples=["1/18", "2/36"]),  # (3, 6) and (4, 5) counted once each: 2/36
        ]),
    "q-oup-ch15-wb-practice": one(
        num("5/14", tolerance=0.0008),
        accepts=["5/14", "20/56", "20/56 = 5/14", "0.357", "5/8 × 4/7 = 20/56"],
        rejects=["25/64", "5/8", "15/56", "3/28", "0.4"],
        mistakes=[
            mistake("with-replacement", num("25/64"), num("5/16"),
                    next_step="After the first red is taken out there is one red fewer and one marble fewer in the bag, so change both numbers for the second draw.",
                    examples=["25/64", "5/16"]),  # 5/8 × 5/8, or 5/8 × 4/8
        ]),
    "q-oup-ch15-wb-challenge": one(
        num("56"),
        accepts=["56", "56 committees", "8 × 7 × 6 ÷ 6 = 56"],
        rejects=["336", "24", "512", "5.6", "28"],
        mistakes=[
            mistake("order-mixed", num("336"),
                    next_step="A committee is the same whichever order its members are picked in, so divide by the number of ways to order three people.",
                    examples=["336"]),  # 8 × 7 × 6 with order counted
        ]),
    # Chapter 16
    "q-oup-ch16-sb": key(
        [part("2a − 3b", seq("0", "11")), part("the magnitude of a", num("5"))],
        accepts=["2a − 3b = (0, 11)ᵀ and |a| = 5", "(0, 11) and 5", "(0,11), |a| = 5"],
        rejects=["(0, 11)", "5", "(12, 5), 5", "(0, 11), 25", "(0, 5), 5", "(0, 11), 7"],
        mistakes=[
            mistake("sign-of-product", seq("0", "5"),
                    next_step="Work out 3b one component at a time and check the sign of minus three times minus one.",
                    examples=["(0, 5), 5"]),  # 8 − 3 × (−1) worked as 8 − 3
            mistake("added-sides", num("7"),
                    next_step="The magnitude is the length of the arrow, the longest side of a right triangle, so use Pythagoras on the components.",
                    examples=["(0, 11), 7"]),  # 3 + 4 = 7
            mistake("forgot-square-root", num("25"),
                    next_step="You have the length squared, so take one more step to get the length.",
                    examples=["(0, 11), 25"]),  # 3² + 4² = 25 with no square root
        ]),
    "q-oup-ch16-wb-focus": one(
        seq("3", "5"),
        accepts=["AC = (3, 5)ᵀ", "(3, 5)", "(3,5)", "3, 5"],
        rejects=["(5, 3)", "(5, -9)", "(3, 9)", "(-4, -14)", "(3, -5)"],
        mistakes=[
            mistake("vector-combined-wrongly", seq("5", "-9"),
                    next_step="Going from A to B and then from B to C means adding the two vectors, component by component.",
                    examples=["(5, -9)"]),  # AB − BC = (4 − (−1), −2 − 7)
            mistake("dropped-minus", seq("3", "9"),
                    next_step="Add the bottom components again, keeping the minus sign on the first one.",
                    examples=["(3, 9)"]),  # −2 read as 2: 2 + 7 = 9
        ]),
    "q-oup-ch16-wb-practice": one(
        forms("1/2(b-a)", "1/2 (b-a)", "(1/2)(b-a)", "(b-a)/2", "(-a+b)/2", "1/2b-1/2a", "b/2-a/2", "0.5(b-a)",
              "0.5b-0.5a", "-1/2a+1/2b", "-a/2+b/2", "1/2*(b-a)", "1/2(-a+b)"),
        accepts=["MN = ½(b − a)", "1/2(b - a)", "(b - a)/2", "½b − ½a", "MN = ½(b − a) = ½AB"],
        rejects=["½(a − b)", "b − a", "½(a + b)", "2(b − a)", "½ab"],
        mistakes=[
            mistake("vector-combined-wrongly", forms("1/2(a-b)", "1/2 (a-b)", "(a-b)/2", "1/2a-1/2b", "a/2-b/2", "0.5(a-b)"),
                    next_step="Go from M to N by heading back from M to O and then out from O to N, and check the direction of each piece.",
                    examples=["½(a − b)"]),  # MN taken as OM − ON
            mistake("vector-combined-wrongly", forms("1/2(a+b)", "1/2 (a+b)", "(a+b)/2", "1/2a+1/2b", "a/2+b/2", "0.5(a+b)"),
                    next_step="Going from M to N starts by going back along OM, which reverses its direction.",
                    examples=["½(a + b)"]),  # MN taken as OM + ON
            mistake("forgot-half", forms("b-a", "-a+b"),
                    next_step="M and N are midpoints, so OM and ON are only half of a and b.",
                    examples=["b − a"]),  # AB found instead of MN
        ]),
    "q-oup-ch16-wb-challenge": key(
        [part("the determinant", num("10")), part("the new area", num("50"))],
        accepts=["det(A) = 10; new area = 50 cm²", "10 and 50", "det = 10, area 50"],
        rejects=["10", "50", "det = 14, area = 70", "det = 10, area = 15", "10, 5"],
        mistakes=[
            mistake("dropped-minus", num("14"), num("70"),
                    next_step="The determinant is ad minus bc, so check you subtracted the second product.",
                    examples=["det = 14, area = 70"]),  # 3 × 4 + 1 × 2 = 14
        ]),
}


# ---------------------------------------------------------------------------
# Stuck sheets: a smaller twin of each school question, solved by the same
# method with friendlier numbers, one short step at a time. Nothing on a sheet
# may show the original question's answer; build_stuck_sheets checks that.
# A worded question may go without a sheet when any twin would give its answer away.
# ---------------------------------------------------------------------------

def stuck_step(prompt, answer_key, answer, working):
    return {"prompt": prompt, "answer": answer, "working": working, "answerKey": answer_key}


def stuck_sheet(sister, steps):
    return {"sister": sister, "steps": steps}


ADD_WORDS = words(["add", "adds", "added", "adding", "plus"], forbid=["subtract", "take", "takes", "minus"])

STUCK_SHEETS = {
    # Chapter 1
    "q-oup-ch01-sb": stuck_sheet(
        "Find the HCF and LCM of 12 and 18 using prime factors.",
        [
            stuck_step("Write 12 as a product of prime factors, using powers.",
                       one(forms("2^2*3", "3*2^2", "2*2*3", "2*3*2", "3*2*2"),
                           accepts=["2² × 3", "12 = 2 × 2 × 3"], rejects=["2 × 6", "3 × 4", "2³ × 3", "2 × 3"]),
                       answer="2² × 3", working="12 = 2 × 6 = 2 × 2 × 3, which is 2² × 3."),
            stuck_step("Now write 18 the same way.",
                       one(forms("2*3^2", "3^2*2", "2*3*3", "3*3*2", "3*2*3"),
                           accepts=["2 × 3²", "18 = 2 × 3 × 3"], rejects=["2 × 9", "3 × 6", "2² × 3", "2 × 3"]),
                       answer="2 × 3²", working="18 = 2 × 9 = 2 × 3 × 3, which is 2 × 3²."),
            stuck_step("The HCF takes each shared prime at its lower power. What is the HCF of 12 and 18?",
                       one(num("6"), accepts=["6", "HCF = 6"], rejects=["36", "3", "2", "12"],
                           mistakes=[mistake("hcf-lcm-swapped", num("36"),
                                             next_step="For the HCF take the lower power of each prime both numbers share.",
                                             examples=["36"])]),
                       answer="6", working="Both numbers share one 2 and one 3, so the HCF is 2 × 3 = 6."),
            stuck_step("The LCM takes every prime at its higher power. What is the LCM?",
                       one(num("36"), accepts=["36", "LCM = 36"], rejects=["216", "6", "72", "18"],
                           mistakes=[mistake("lcm-as-product", num("216"),
                                             next_step="Multiplying gives a common multiple, but the LCM uses each prime once at its higher power.",
                                             examples=["216"]),
                                     mistake("hcf-lcm-swapped", num("6"),
                                             next_step="For the LCM take the higher power of every prime.",
                                             examples=["6"])]),
                       answer="36", working="The higher powers are 2² and 3², so the LCM is 4 × 9 = 36."),
        ]),
    "q-oup-ch01-wb-focus": stuck_sheet(
        "Work out (−4) × (−3) ÷ (−2) + (−2)³.",
        [
            stuck_step("Start with (−4) × (−3).",
                       one(num("12"), accepts=["12"], rejects=["-12", "7", "-7"],
                           mistakes=[mistake("sign-of-product", num("-12"),
                                             next_step="Two negatives multiplied make a positive.", examples=["−12"])]),
                       answer="12", working="Two negatives make a positive, so (−4) × (−3) = 12."),
            stuck_step("Now divide that by (−2).",
                       one(num("-6"), accepts=["−6"], rejects=["6", "-24", "24"],
                           mistakes=[mistake("sign-of-product", num("6"),
                                             next_step="A positive divided by a negative is negative.", examples=["6"])]),
                       answer="−6", working="A positive divided by a negative is negative, so 12 ÷ (−2) = −6."),
            stuck_step("Work out (−2)³.",
                       one(num("-8"), accepts=["−8"], rejects=["8", "-6", "-2"],
                           mistakes=[mistake("sign-of-product", num("8"),
                                             next_step="Three negatives multiplied together make a negative.", examples=["8"]),
                                     mistake("power-as-multiply", num("-6"),
                                             next_step="A cube means the number times itself three times, not times three.",
                                             examples=["−6"])]),
                       answer="−8", working="(−2) × (−2) = 4, and 4 × (−2) = −8."),
            stuck_step("Add the two parts: (−6) + (−8).",
                       one(num("-14"), accepts=["−14"], rejects=["14", "2", "-2", "-48"],
                           mistakes=[mistake("dropped-minus", num("14"), num("2"), num("-2"),
                                             next_step="Adding a negative takes you further below zero.",
                                             examples=["14", "−2"])]),
                       answer="−14", working="Adding −8 to −6 goes 8 further below zero, which is −14."),
        ]),
    "q-oup-ch01-wb-practice": stuck_sheet(
        "Two lights flash every 4 seconds and every 6 seconds. They flash together now. After how many seconds will they next flash together?",
        [
            stuck_step("List the first five multiples of 4.",
                       one(seq("4", "8", "12", "16", "20"), accepts=["4, 8, 12, 16, 20"],
                           rejects=["1, 2, 4", "4, 8, 12", "6, 12, 18, 24, 30"]),
                       answer="4, 8, 12, 16, 20", working="Count up in 4s: 4, 8, 12, 16, 20."),
            stuck_step("List the first four multiples of 6.",
                       one(seq("6", "12", "18", "24"), accepts=["6, 12, 18, 24"],
                           rejects=["1, 2, 3, 6", "6, 12, 18", "4, 8, 12, 16"]),
                       answer="6, 12, 18, 24", working="Count up in 6s: 6, 12, 18, 24."),
            stuck_step("Which is the smallest number in both lists?",
                       one(num("12"), accepts=["12", "12 seconds"], rejects=["24", "2", "10"],
                           mistakes=[mistake("lcm-as-product", num("24"),
                                             next_step="Multiplying gives a shared multiple, but look for an earlier one in both lists.",
                                             examples=["24"]),
                                     mistake("hcf-lcm-swapped", num("2"),
                                             next_step="They flash together at a multiple of both, not a factor of both.",
                                             examples=["2"])]),
                       answer="12 seconds", working="12 is in both lists and nothing smaller is, so they flash together after 12 seconds."),
        ]),
    "q-oup-ch01-wb-challenge": stuck_sheet(
        "HCF(a, b) = 2, LCM(a, b) = 12 and a = 4. Find b using HCF × LCM = a × b.",
        [
            stuck_step("Work out HCF × LCM.",
                       one(num("24"), accepts=["24"], rejects=["14", "6", "10"]),
                       answer="24", working="2 × 12 = 24."),
            stuck_step("Write the equation with a = 4 put in.",
                       one(forms("4b=24", "24=4b", "4*b=24", "b*4=24"),
                           accepts=["4b = 24", "4 × b = 24"], rejects=["b = 24", "4 + b = 24", "2b = 24"]),
                       answer="4b = 24", working="a × b is 4 × b, so 4b = 24."),
            stuck_step("Find b.",
                       one(num("6"), accepts=["6", "b = 6"], rejects=["24", "96", "3", "20"],
                           mistakes=[mistake("stopped-early", num("24"),
                                             next_step="That is a × b, so divide by a to get b on its own.", examples=["24"]),
                                     mistake("multiplied-instead-of-divided", num("96"),
                                             next_step="To undo times 4, divide by 4.", examples=["96"]),
                                     mistake("lcm-as-product", num("3"),
                                             next_step="a × b equals HCF × LCM, not the LCM alone.", examples=["b = 3"])]),
                       answer="b = 6", working="24 ÷ 4 = 6, so b = 6."),
        ]),
    # Chapter 2
    "q-oup-ch02-sb": stuck_sheet(
        "Expand and simplify 2(2x + 1) − 2(x − 4).",
        [
            stuck_step("Expand 2(2x + 1).",
                       one(forms("4x+2", "2+4x"), accepts=["4x + 2"], rejects=["4x + 1", "2x + 2", "4x"],
                           mistakes=[mistake("expand-first-term-only", forms("4x+1", "1+4x"),
                                             next_step="Multiply every term inside the bracket, not only the first.",
                                             examples=["4x + 1"])]),
                       answer="4x + 2", working="2 × 2x = 4x and 2 × 1 = 2, so 4x + 2."),
            stuck_step("Expand −2(x − 4). Keep the sign in front.",
                       one(forms("-2x+8", "8-2x"), accepts=["−2x + 8"], rejects=["-2x - 8", "2x + 8", "-2x - 4"],
                           mistakes=[mistake("sign-of-product", forms("-2x-8", "-8-2x"),
                                             next_step="A negative times a negative is positive.", examples=["−2x − 8"]),
                                     mistake("expand-first-term-only", forms("-2x-4"),
                                             next_step="Multiply every term inside the bracket by the number outside.",
                                             examples=["−2x − 4"]),
                                     mistake("dropped-minus", forms("2x+8", "2x-8"),
                                             next_step="Keep the minus sign in front of the bracket.", examples=["2x + 8"])]),
                       answer="−2x + 8", working="−2 × x = −2x and −2 × −4 = +8, so −2x + 8."),
            stuck_step("Collect the like terms in 4x + 2 − 2x + 8.",
                       one(forms("2x+10", "10+2x"), accepts=["2x + 10"], rejects=["6x + 10", "2x - 6", "2x + 6"],
                           mistakes=[mistake("dropped-minus", forms("6x+10", "10+6x"),
                                             next_step="Take the x terms away: 4x minus 2x.", examples=["6x + 10"]),
                                     mistake("sign-of-product", forms("2x-6", "-6+2x"),
                                             next_step="The second bracket gave plus 8, so check the sign of each number.",
                                             examples=["2x − 6"])]),
                       answer="2x + 10", working="4x − 2x = 2x and 2 + 8 = 10, so 2x + 10."),
        ]),
    "q-oup-ch02-wb-focus": stuck_sheet(
        "Factorise completely: 6x²y − 4xy².",
        [
            stuck_step("What is the HCF of 6 and 4?",
                       one(num("2"), accepts=["2"], rejects=["12", "24", "1", "4"],
                           mistakes=[mistake("hcf-lcm-swapped", num("12"),
                                             next_step="The HCF is the biggest number that goes into both.", examples=["12"])]),
                       answer="2", working="2 goes into both 6 and 4, and no bigger number does."),
            stuck_step("Which letters are in both terms? Write the part they share as one term.",
                       one(forms("xy", "yx"), accepts=["xy"], rejects=["x²y²", "x", "y"]),
                       answer="xy", working="Each term has at least one x and one y, so they share xy."),
            stuck_step("Divide each term by 2xy. What is left from each?",
                       key([part("the first term", forms("3x")), part("the second term", forms("2y", "-2y"))],
                           accepts=["3x and 2y", "3x, −2y"], rejects=["3x", "6x and 4y", "3xy and 2xy"]),
                       answer="3x and 2y", working="6x²y ÷ 2xy = 3x and 4xy² ÷ 2xy = 2y."),
            stuck_step("Write the full factorised form.",
                       one(forms("2xy(3x-2y)", "2yx(3x-2y)", "2xy (3x-2y)", "(3x-2y)2xy", "2xy(-2y+3x)", "2xy*(3x-2y)"),
                           accepts=["2xy(3x − 2y)"],
                           rejects=["2xy(3x + 2y)", "xy(6x − 4y)", "2(3x²y − 2xy²)", "2x(3xy − 2y²)"],
                           mistakes=[mistake("common-factor-left",
                                             forms("xy(6x-4y)", "2(3x^2y-2xy^2)", "2x(3xy-2y^2)", "2y(3x^2-2xy)",
                                                   "x(6xy-4y^2)", "y(6x^2-4xy)"),
                                             next_step="Look inside the bracket: if both terms still share a factor, take it out too.",
                                             examples=["xy(6x − 4y)", "2x(3xy − 2y²)"]),
                                     mistake("dropped-minus", forms("2xy(3x+2y)"),
                                             next_step="The second term was being taken away, so keep its minus sign inside the bracket.",
                                             examples=["2xy(3x + 2y)"])]),
                       answer="2xy(3x − 2y)", working="Take 2xy outside and put 3x − 2y inside, giving 2xy(3x − 2y)."),
        ]),
    "q-oup-ch02-wb-practice": stuck_sheet(
        "A rectangle (x + 4) cm long and 3 cm wide has a smaller rectangle (x − 1) cm long and 2 cm wide cut out of it. Write a simplified expression for the area left.",
        [
            stuck_step("Find the area of the big rectangle, 3(x + 4).",
                       one(forms("3x+12", "12+3x"), accepts=["3x + 12"], rejects=["3x + 4", "x + 12", "3x + 7"],
                           mistakes=[mistake("expand-first-term-only", forms("3x+4", "4+3x"),
                                             next_step="Multiply both terms in the bracket by 3.", examples=["3x + 4"])]),
                       answer="3x + 12", working="3 × x = 3x and 3 × 4 = 12, so 3x + 12."),
            stuck_step("Find the area of the small rectangle, 2(x − 1).",
                       one(forms("2x-2", "-2+2x"), accepts=["2x − 2"], rejects=["2x - 1", "2x + 2", "x - 2"],
                           mistakes=[mistake("expand-first-term-only", forms("2x-1", "-1+2x"),
                                             next_step="Multiply both terms in the bracket by the number outside.",
                                             examples=["2x − 1"])]),
                       answer="2x − 2", working="2 × x = 2x and 2 × −1 = −2, so 2x − 2."),
            stuck_step("Take the small area from the big one: (3x + 12) − (2x − 2).",
                       one(forms("x+14", "14+x"), accepts=["x + 14"], rejects=["x + 10", "5x + 10", "x - 14"],
                           mistakes=[mistake("sign-of-product", forms("x+10", "10+x"),
                                             next_step="Taking away a negative adds it, so the minus 2 becomes plus.",
                                             examples=["x + 10"])]),
                       answer="x + 14", working="3x − 2x = x and 12 − (−2) = 14, so x + 14."),
        ]),
    "q-oup-ch02-wb-challenge": stuck_sheet(
        "Using a² − b² = (a − b)(a + b), work out 53² − 47² without a calculator.",
        [
            stuck_step("Here a = 53 and b = 47. What is a − b?",
                       one(num("6"), accepts=["6"], rejects=["100", "-6", "4"]),
                       answer="6", working="53 − 47 = 6."),
            stuck_step("What is a + b?",
                       one(num("100"), accepts=["100"], rejects=["6", "90", "110"]),
                       answer="100", working="53 + 47 = 100."),
            stuck_step("Multiply them to get 53² − 47².",
                       one(num("600"), accepts=["600"], rejects=["36", "100", "60", "6000"],
                           mistakes=[mistake("square-of-difference", num("36"),
                                             next_step="a² − b² is (a − b) times (a + b), not (a − b) squared.",
                                             examples=["36"]),
                                     mistake("stopped-early", num("100"), num("6"),
                                             next_step="That is one bracket; multiply it by the other one.", examples=["100"])]),
                       answer="600", working="6 × 100 = 600."),
        ]),
    # Chapter 3
    "q-oup-ch03-sb": stuck_sheet(
        "A boat sails from a harbour on a bearing of 050° to a buoy. Find the bearing of the harbour from the buoy.",
        [
            stuck_step("How many degrees is a half turn?",
                       one(num("180"), accepts=["180", "180°"], rejects=["90", "360", "50"]),
                       answer="180°", working="A full turn is 360°, so a half turn is 180°."),
            stuck_step("50 is less than 180. Do you add or subtract 180° to turn round?",
                       one(ADD_WORDS, accepts=["add", "add 180"], rejects=["subtract", "take away", "minus"]),
                       answer="Add", working="Below 180 you add 180, so the bearing stays under 360."),
            stuck_step("Find the bearing of the harbour from the buoy.",
                       one(num("230"), accepts=["230°", "230"], rejects=["130", "50", "310", "410"],
                           mistakes=[mistake("back-bearing", num("130"), num("50"),
                                             next_step="The way back points the opposite way, half a turn from the way out.",
                                             examples=["130", "050"])]),
                       answer="230°", working="50 + 180 = 230, so the bearing is 230°."),
        ]),
    "q-oup-ch03-wb-focus": stuck_sheet(
        "A square-based pyramid has 5 vertices (V = 5). Use Euler's formula V − E + F = 2 to find its number of edges E.",
        [
            stuck_step("Count the faces F: one square base and the triangles round it. Give the total.",
                       one(num("5"), accepts=["5", "F = 5"], rejects=["4", "6", "8"]),
                       answer="F = 5", working="There are 4 triangles and 1 square, so F = 5."),
            stuck_step("Put V = 5 and F = 5 into V − E + F = 2 and add the numbers.",
                       one(forms("10-e=2", "2=10-e", "-e+10=2"), accepts=["10 − E = 2"],
                           rejects=["E = 2", "5 − E = 2", "10 + E = 2"]),
                       answer="10 − E = 2", working="5 − E + 5 = 2, which is 10 − E = 2."),
            stuck_step("Find E.",
                       one(num("8"), accepts=["8", "E = 8"], rejects=["-8", "2", "10"],
                           mistakes=[mistake("rearranged-sign", num("-8"),
                                             next_step="Add E to both sides first so it is positive, then take 2 from both sides.",
                                             examples=["E = −8"])]),
                       answer="E = 8", working="10 − 2 = 8, so E = 8."),
        ]),
    "q-oup-ch03-wb-challenge": stuck_sheet(
        "A boat sails 3 km on a bearing of 030° and then 4 km on a bearing of 120°. Find its direct distance from the start.",
        [
            stuck_step("How many degrees does the boat turn between the two legs?",
                       one(num("90"), accepts=["90", "90°"], rejects=["150", "30", "120"]),
                       answer="90°", working="120 − 30 = 90, so the two legs meet at a right angle."),
            stuck_step("Use Pythagoras: work out 3² + 4².",
                       one(num("25"), accepts=["25"], rejects=["7", "14", "49"],
                           mistakes=[mistake("added-sides", num("7"),
                                             next_step="Square each length before you add.", examples=["7"]),
                                     mistake("power-as-multiply", num("14"),
                                             next_step="3² means 3 times 3, not 3 times 2.", examples=["14"])]),
                       answer="25", working="9 + 16 = 25."),
            stuck_step("Find the direct distance.",
                       one(num("5"), accepts=["5 km", "5"], rejects=["25", "7", "12.5"],
                           mistakes=[mistake("forgot-square-root", num("25"),
                                             next_step="That is the distance squared, so take the square root.", examples=["25"]),
                                     mistake("added-sides", num("7"),
                                             next_step="The straight line back is shorter than the two legs added together.",
                                             examples=["7"])]),
                       answer="5 km", working="√25 = 5, so the boat is 5 km from the start."),
        ]),
    # Chapter 4
    "q-oup-ch04-sb": stuck_sheet(
        "A club has 24 juniors, 12 seniors and 12 veterans. Design a stratified sample of 12 members.",
        [
            stuck_step("How many members are there in total?",
                       one(num("48"), accepts=["48"], rejects=["36", "24", "12"]),
                       answer="48", working="24 + 12 + 12 = 48."),
            stuck_step("Juniors are 24 out of 48. How many juniors go in the sample?",
                       one(num("6"), accepts=["6"], rejects=["4", "24", "12"],
                           mistakes=[mistake("equal-split", num("4"),
                                             next_step="Each group's share of the sample matches its share of the club.",
                                             examples=["4"])]),
                       answer="6", working="24/48 is a half, and half of 12 is 6."),
            stuck_step("How many seniors go in the sample?",
                       one(num("3"), accepts=["3"], rejects=["4", "6", "12"],
                           mistakes=[mistake("equal-split", num("4"),
                                             next_step="Each group's share of the sample matches its share of the club.",
                                             examples=["4"])]),
                       answer="3", working="12/48 is a quarter, and a quarter of 12 is 3."),
            stuck_step("Write the sample sizes for juniors, seniors and veterans.",
                       one(seq("6", "3", "3"), accepts=["6, 3, 3"], rejects=["4, 4, 4", "6, 3", "3, 3, 6"],
                           mistakes=[mistake("equal-split", seq("4", "4", "4"),
                                             next_step="Bigger groups get more places, in proportion to their size.",
                                             examples=["4, 4, 4"])]),
                       answer="6, 3, 3", working="Veterans match seniors, so the sample is 6 juniors, 3 seniors and 3 veterans."),
        ]),
    "q-oup-ch04-wb-focus": stuck_sheet(
        "Choose 5 people from a list of 40 using systematic sampling, starting at person 3. Find the interval k and list who is chosen.",
        [
            stuck_step("Find the sampling interval k.",
                       one(num("8"), accepts=["8", "k = 8", "40 ÷ 5"], rejects=["5", "200", "1/8"],
                           mistakes=[mistake("divided-wrong-way-round", num("1/8"),
                                             next_step="Divide the list size by the sample size.", examples=["1/8"]),
                                     mistake("multiplied-instead-of-divided", num("200"),
                                             next_step="The interval is how many places you move each time, so share the list out.",
                                             examples=["200"])]),
                       answer="k = 8", working="40 ÷ 5 = 8, so k = 8."),
            stuck_step("Person 3 is first. Who is next?",
                       one(num("11"), accepts=["11", "person 11"], rejects=["4", "8", "24"]),
                       answer="11", working="3 + 8 = 11."),
            stuck_step("List all 5 people chosen.",
                       one(seq("3", "11", "19", "27", "35"), accepts=["3, 11, 19, 27, 35"],
                           rejects=["3, 11, 19", "8, 16, 24, 32, 40", "3, 8, 13, 18, 23"]),
                       answer="3, 11, 19, 27, 35", working="Keep adding 8: 3, 11, 19, 27, 35."),
        ]),
    "q-oup-ch04-wb-practice": stuck_sheet(
        "Why would surveying only people leaving a library on a Saturday give a biased estimate of how much people in a town read?",
        [
            stuck_step("Are people leaving a library likely to read more or less than most people?",
                       one(words(["more"], forbid=["less", "fewer", "lower"]),
                           accepts=["more", "they read more"], rejects=["less", "the same", "fewer"]),
                       answer="More", working="People who spend their day off at a library are likely to read more than most."),
            stuck_step("So would the survey's estimate come out too high or too low?",
                       one(words(["high", "higher", "over", "overestimate"], forbid=["low", "lower", "under", "underestimate"]),
                           accepts=["too high", "high"], rejects=["too low", "low", "about right"]),
                       answer="Too high", working="The keen readers pull the average up, so it comes out too high."),
            stuck_step("Give the reason in one sentence.",
                       one(words(["read", "reads", "reader", "readers", "reading", "books", "library"],
                                 ["more", "already", "a lot", "lots", "keen", "too high", "higher", "overestimate",
                                  "overestimates", "often", "regular", "regularly"]),
                           accepts=["People at a library already read a lot, so the estimate is too high."],
                           rejects=["Some people were asked.", "The sample is too small.", "It is a Saturday."]),
                       answer="People at a library already read more than most, so the estimate is too high.",
                       working="Library visitors already read more than most people, so the estimate is too high."),
        ]),
    "q-oup-ch04-wb-challenge": stuck_sheet(
        "The standard error of a sample mean is SE = σ / √n. By what factor must n increase to cut the error to a third?",
        [
            stuck_step("Try n = 100. Work out √100.",
                       one(num("10"), accepts=["10"], rejects=["50", "100", "1"]),
                       answer="10", working="10 × 10 = 100, so √100 = 10."),
            stuck_step("Now try n = 900. Work out √900.",
                       one(num("30"), accepts=["30"], rejects=["90", "300", "450"]),
                       answer="30", working="30 × 30 = 900, so √900 = 30."),
            stuck_step("√n went from 10 to 30. How many times smaller is the error σ / √n now?",
                       one(num("3"), accepts=["3", "3 times"], rejects=["9", "20", "30"]),
                       answer="3 times", working="√n grew 3 times, so σ / √n is 3 times smaller."),
            stuck_step("So by what factor did n increase?",
                       one(num("9"), accepts=["9", "9 times"], rejects=["3", "800", "90"],
                           mistakes=[mistake("forgot-square-root", num("3"),
                                             next_step="The error depends on √n, so n has to grow by the square of that factor.",
                                             examples=["3"])]),
                       answer="9 times", working="900 ÷ 100 = 9, so n must be 9 times bigger."),
        ]),
    # Chapter 5
    "q-oup-ch05-sb": stuck_sheet(
        "A trough is a prism 2 m long. Its cross-section is a trapezium with parallel sides 10 cm and 30 cm and height 20 cm. Find its volume in litres.",
        [
            stuck_step("Find the area of the trapezium: ½(a + b) × h.",
                       one(num("400"), accepts=["400", "400 cm²"], rejects=["800", "600", "40"],
                           mistakes=[mistake("forgot-half", num("800"),
                                             next_step="The trapezium formula halves the sum of the parallel sides.",
                                             examples=["800"])]),
                       answer="400 cm²", working="½ × (10 + 30) × 20 = 20 × 20 = 400 cm²."),
            stuck_step("Change the length 2 m into cm.",
                       one(num("200"), accepts=["200", "200 cm"], rejects=["20", "2000", "2"],
                           mistakes=[mistake("unit-slip", num("20"), num("2000"),
                                             next_step="There are 100 cm in a metre.", examples=["20", "2000"])]),
                       answer="200 cm", working="2 × 100 = 200 cm."),
            stuck_step("Volume = area × length. Find it in cm³.",
                       one(num("80000"), accepts=["80000", "80,000 cm³"], rejects=["800", "8000", "600"],
                           mistakes=[mistake("unit-slip", num("800"),
                                             next_step="Use the length in cm so both numbers are in the same units.",
                                             examples=["800"])]),
                       answer="80,000 cm³", working="400 × 200 = 80,000 cm³."),
            stuck_step("1 litre is 1000 cm³. How many litres is that?",
                       one(num("80"), accepts=["80", "80 litres"], rejects=["800", "8", "80000"],
                           mistakes=[mistake("unit-slip", num("80000"), num("8"), num("800"),
                                             next_step="Divide the cm³ by the number of cm³ in one litre.",
                                             examples=["80000", "8"])]),
                       answer="80 litres", working="80,000 ÷ 1000 = 80 litres."),
        ]),
    "q-oup-ch05-wb-focus": stuck_sheet(
        "Find the circumference and area of a circle of radius 10 cm (use π ≈ 3.14).",
        [
            stuck_step("What is the diameter?",
                       one(num("20"), accepts=["20", "20 cm"], rejects=["5", "10", "100"]),
                       answer="20 cm", working="The diameter is twice the radius: 2 × 10 = 20 cm."),
            stuck_step("Circumference = π × d. Work it out.",
                       one(num("62.8"), accepts=["62.8", "62.8 cm"], rejects=["31.4", "314", "6.28"],
                           mistakes=[mistake("radius-diameter-mixed", num("31.4"),
                                             next_step="Circumference is π times the diameter, not the radius.",
                                             examples=["31.4"])]),
                       answer="62.8 cm", working="3.14 × 20 = 62.8 cm."),
            stuck_step("Work out r².",
                       one(num("100"), accepts=["100"], rejects=["20", "10", "1000"],
                           mistakes=[mistake("power-as-multiply", num("20"),
                                             next_step="r² means r times r, not r times 2.", examples=["20"])]),
                       answer="100", working="10 × 10 = 100."),
            stuck_step("Area = π × r². Work it out.",
                       one(num("314"), accepts=["314", "314 cm²"], rejects=["62.8", "1256", "31.4"],
                           mistakes=[mistake("radius-diameter-mixed", num("1256"),
                                             next_step="The area uses the radius squared, not the diameter squared.",
                                             examples=["1256"])]),
                       answer="314 cm²", working="3.14 × 100 = 314 cm²."),
        ]),
    "q-oup-ch05-wb-practice": stuck_sheet(
        "A parallelogram has base 6 cm, slanted side 5 cm and perpendicular height 4 cm. Find its perimeter and its area.",
        [
            stuck_step("Find the perimeter: add all four sides.",
                       one(num("22"), accepts=["22", "22 cm"], rejects=["11", "20", "24"],
                           mistakes=[mistake("missing-edges", num("11"),
                                             next_step="A parallelogram has two of each side, so count all of them.",
                                             examples=["11"]),
                                     mistake("height-slant-mixed", num("20"),
                                             next_step="The perimeter goes round the edges, so use the slanted side, not the height.",
                                             examples=["20"])]),
                       answer="22 cm", working="6 + 5 + 6 + 5 = 22 cm."),
            stuck_step("For the area, which length goes with the base: the slanted side or the height?",
                       one(words(["height", "perpendicular"], forbid=["slant", "slanted", "side"]),
                           accepts=["the height", "perpendicular height"], rejects=["the slanted side", "slant", "side"]),
                       answer="The height", working="Area uses the perpendicular height, the straight-up distance from the base to the top."),
            stuck_step("Find the area.",
                       one(num("24"), accepts=["24", "24 cm²"], rejects=["30", "20", "12"],
                           mistakes=[mistake("height-slant-mixed", num("30"),
                                             next_step="Use the perpendicular height, not the slanted side.", examples=["30"])]),
                       answer="24 cm²", working="6 × 4 = 24 cm²."),
        ]),
    "q-oup-ch05-wb-challenge": stuck_sheet(
        "A round cake of radius 6 cm is cut into 4 equal slices. Find the perimeter of one slice to 1 decimal place.",
        [
            stuck_step("Find the whole circumference, 2πr.",
                       one(num("37.7", tolerance=0.05), forms("12π", "12pi"), accepts=["37.7", "12π"],
                           rejects=["18.8", "113.1", "36"],
                           mistakes=[mistake("radius-diameter-mixed", num("18.85", tolerance=0.05), forms("6π"),
                                             next_step="The circumference is 2πr, so double the radius first.",
                                             examples=["18.85", "6π"])]),
                       answer="12π ≈ 37.7 cm", working="2 × π × 6 = 12π, which is about 37.7 cm."),
            stuck_step("One slice has a quarter of the curved edge. Find that length.",
                       one(num("9.42", tolerance=0.01), forms("3π", "3pi"), accepts=["9.42", "3π"],
                           rejects=["37.7", "4.71", "18.85"]),
                       answer="3π ≈ 9.42 cm", working="12π ÷ 4 = 3π, which is about 9.42 cm."),
            stuck_step("Add the two straight edges to find the perimeter of one slice.",
                       one(num("21.4", tolerance=0.05), accepts=["21.4", "21.4 cm"], rejects=["9.4", "15.4", "33.4"],
                           mistakes=[mistake("missing-edges", num("9.4", tolerance=0.05), num("15.4", tolerance=0.05),
                                             next_step="A slice has two straight edges, each one a radius, as well as the curved one.",
                                             examples=["9.4", "15.4"])]),
                       answer="21.4 cm", working="9.42 + 6 + 6 = 21.42, which is 21.4 cm to 1 decimal place."),
        ]),
    # Chapter 6
    "q-oup-ch06-sb": stuck_sheet(
        "Write the recurring decimal x = 0.666… (0.6̇) as a fraction in simplest form.",
        [
            stuck_step("One digit repeats, so multiply x by 10. What is 10x?",
                       one(num("6.666", tolerance=0.01), accepts=["6.666…", "6.67"], rejects=["0.666", "66.6", "6"]),
                       answer="10x = 6.666…", working="Multiplying by 10 moves every digit one place, so 10x is 6.666 recurring."),
            stuck_step("Take x = 0.666… away from 10x = 6.666… to find 9x.",
                       one(num("6"), accepts=["6", "9x = 6"], rejects=["6.666", "0.666", "9"]),
                       answer="9x = 6", working="The recurring parts cancel, so 9x = 6."),
            stuck_step("Write x as a fraction in simplest form.",
                       one(num("2/3", simplest=True), accepts=["2/3", "x = 2/3"], rejects=["6/9", "3/2", "0.666"],
                           mistakes=[mistake("common-factor-left", forms("6/9"),
                                             next_step="The top and bottom still share a factor, so divide both by it.",
                                             examples=["6/9"])]),
                       answer="x = 2/3", working="x = 6/9, and dividing top and bottom by 3 gives 2/3."),
        ]),
    "q-oup-ch06-wb-focus": stuck_sheet(
        "Round 0.05276 to 3 significant figures.",
        [
            stuck_step("Which digit is the first significant figure?",
                       one(num("5"), accepts=["5"], rejects=["0", "2", "7"],
                           mistakes=[mistake("decimal-places-not-sf", num("0"),
                                             next_step="Leading zeros only hold the place, so start counting at the first digit that is not zero.",
                                             examples=["0"])]),
                       answer="5", working="Zeros before the first non-zero digit do not count, so it is the 5."),
            stuck_step("Keep three significant figures and drop the rest, before any rounding.",
                       one(num("0.0527"), accepts=["0.0527"], rejects=["0.052", "0.05276", "0.0528"]),
                       answer="0.0527", working="Counting 5, 2 and 7 gives 0.0527, with the 6 left over."),
            stuck_step("The next digit is 6. Round to 3 significant figures.",
                       one(num("0.0528"), accepts=["0.0528"], rejects=["0.0527", "0.053", "528", "0.05"],
                           mistakes=[mistake("truncated", num("0.0527"),
                                             next_step="A next digit of 5 or more rounds the last kept digit up.",
                                             examples=["0.0527"]),
                                     mistake("decimal-places-not-sf", num("0.053"),
                                             next_step="Count significant figures from the first non-zero digit, not decimal places.",
                                             examples=["0.053"]),
                                     mistake("place-value-shift", num("528"),
                                             next_step="Keep the zeros that hold the place after the decimal point.",
                                             examples=["528"])]),
                       answer="0.0528", working="The 6 rounds the 7 up to 8, so 0.0528."),
        ]),
    "q-oup-ch06-wb-practice": stuck_sheet(
        "Work out 3 1/3 − 1 1/2 as a mixed number in simplest form.",
        [
            stuck_step("Write 3 1/3 as an improper fraction.",
                       one(forms("10/3"), accepts=["10/3"], rejects=["4/3", "3/3", "31/3"]),
                       answer="10/3", working="3 wholes are 9 thirds, and 1 more third makes 10/3."),
            stuck_step("Write 1 1/2 as an improper fraction.",
                       one(forms("3/2"), accepts=["3/2"], rejects=["2/2", "11/2", "2/3"]),
                       answer="3/2", working="1 whole is two halves, and one more half makes 3/2."),
            stuck_step("Write both over a denominator of 6.",
                       key([part("the first", forms("20/6")), part("the second", forms("9/6"))],
                           accepts=["20/6 and 9/6"], rejects=["10/6 and 3/6", "20/6", "2/6 and 3/6"]),
                       answer="20/6 and 9/6", working="10/3 = 20/6 and 3/2 = 9/6."),
            stuck_step("Subtract, and write the answer as a mixed number.",
                       one(forms("1 5/6", "1 and 5/6"), accepts=["1 5/6"], rejects=["11/6", "2 1/6", "1 1/6"],
                           mistakes=[mistake("split-mixed-number", forms("2 1/6", "2 and 1/6"),
                                             next_step="Turn both into improper fractions before you subtract, rather than working on wholes and parts apart.",
                                             examples=["2 1/6"])]),
                       answer="1 5/6", working="20/6 − 9/6 = 11/6, which is 1 5/6."),
        ]),
    "q-oup-ch06-wb-challenge": stuck_sheet(
        "Find the exact value of (1 1/2 ÷ 2 1/4) × 3/4.",
        [
            stuck_step("Write 1 1/2 and 2 1/4 as improper fractions.",
                       key([part("1 1/2", forms("3/2")), part("2 1/4", forms("9/4"))],
                           accepts=["3/2 and 9/4"], rejects=["3/2 and 7/4", "2/2 and 9/4", "11/2 and 21/4"]),
                       answer="3/2 and 9/4", working="1 1/2 = 3/2 and 2 1/4 = 9/4."),
            stuck_step("Divide 3/2 by 9/4: flip the second fraction and multiply.",
                       one(num("2/3"), accepts=["2/3", "12/18"], rejects=["27/8", "3/2", "9/8"],
                           mistakes=[mistake("multiplied-instead-of-divided", num("27/8"),
                                             next_step="To divide by a fraction, flip it over and then multiply.",
                                             examples=["27/8"])]),
                       answer="2/3", working="3/2 × 4/9 = 12/18, which is 2/3."),
            stuck_step("Multiply by 3/4.",
                       one(num("1/2"), accepts=["1/2", "6/12", "0.5"], rejects=["3/4", "2/3", "8/9"]),
                       answer="1/2", working="2/3 × 3/4 = 6/12, which is 1/2."),
        ]),
    # Chapter 7
    "q-oup-ch07-sb": stuck_sheet(
        "Make b the subject of c² = a² + b² (with b > 0), then find b when c = 5 and a = 3.",
        [
            stuck_step("Get b² on its own.",
                       one(forms("b^2=c^2-a^2", "c^2-a^2=b^2", "b^2=-a^2+c^2"), accepts=["b² = c² − a²"],
                           rejects=["b² = c² + a²", "b = c − a", "b² = a² − c²"],
                           mistakes=[mistake("rearranged-sign", forms("b^2=c^2+a^2", "b^2=a^2+c^2", "b^2=a^2-c^2"),
                                             next_step="Moving a² across the equals sign changes its sign.",
                                             examples=["b² = c² + a²"])]),
                       answer="b² = c² − a²", working="Take a² from both sides to get b² = c² − a²."),
            stuck_step("Now write b on its own.",
                       one(forms("b=√(c^2-a^2)", "b=√c^2-a^2", "√(c^2-a^2)"), accepts=["b = √(c² − a²)"],
                           rejects=["b = c − a", "b = c² − a²", "b = √c − √a"],
                           mistakes=[mistake("forgot-square-root", forms("b=c^2-a^2"),
                                             next_step="You have b², so undo the square.", examples=["b = c² − a²"])]),
                       answer="b = √(c² − a²)", working="Square root both sides to get b = √(c² − a²)."),
            stuck_step("Put in c = 5 and a = 3. What is c² − a²?",
                       one(num("16"), accepts=["16"], rejects=["4", "34", "2"],
                           mistakes=[mistake("rearranged-sign", num("34"),
                                             next_step="It is c² take away a², so subtract.", examples=["34"])]),
                       answer="16", working="25 − 9 = 16."),
            stuck_step("So what is b?",
                       one(num("4"), accepts=["4", "b = 4"], rejects=["16", "2", "8"],
                           mistakes=[mistake("forgot-square-root", num("16"),
                                             next_step="That is b², so take its square root.", examples=["16"])]),
                       answer="b = 4", working="√16 = 4, so b = 4."),
        ]),
    "q-oup-ch07-wb-focus": stuck_sheet(
        "Solve 2(2x − 1) = 2(x + 1) + 4.",
        [
            stuck_step("Expand the left side, 2(2x − 1).",
                       one(forms("4x-2", "-2+4x"), accepts=["4x − 2"], rejects=["4x - 1", "2x - 2", "4x + 2"],
                           mistakes=[mistake("expand-first-term-only", forms("4x-1"),
                                             next_step="Multiply both terms in the bracket by the number outside.",
                                             examples=["4x − 1"])]),
                       answer="4x − 2", working="2 × 2x = 4x and 2 × −1 = −2, so 4x − 2."),
            stuck_step("Expand and simplify the right side, 2(x + 1) + 4.",
                       one(forms("2x+6", "6+2x"), accepts=["2x + 6"], rejects=["2x + 5", "2x + 2", "x + 6"],
                           mistakes=[mistake("expand-first-term-only", forms("2x+5", "5+2x"),
                                             next_step="Multiply both terms in the bracket before adding on the last number.",
                                             examples=["2x + 5"])]),
                       answer="2x + 6", working="2(x + 1) is 2x + 2, and adding 4 gives 2x + 6."),
            stuck_step("Get the x terms on one side and the numbers on the other.",
                       one(forms("2x=8", "8=2x"), accepts=["2x = 8"], rejects=["2x = 4", "6x = 8", "x = 8"],
                           mistakes=[mistake("rearranged-sign", forms("2x=4", "6x=8", "4=2x", "8=6x", "6x=4", "2x=-8"),
                                             next_step="Moving a term across the equals sign changes its sign.",
                                             examples=["2x = 4", "6x = 8"])]),
                       answer="2x = 8", working="4x − 2x = 2x and 6 + 2 = 8, so 2x = 8."),
            stuck_step("Find x.",
                       one(num("4"), accepts=["4", "x = 4"], rejects=["16", "8", "2"],
                           mistakes=[mistake("multiplied-instead-of-divided", num("16"),
                                             next_step="To undo 2 times x, divide both sides by 2.", examples=["16"])]),
                       answer="x = 4", working="8 ÷ 2 = 4, so x = 4."),
        ]),
    "q-oup-ch07-wb-practice": stuck_sheet(
        "Solve the inequality 11 − 2x ≥ 5 and state the largest integer x that satisfies it.",
        [
            stuck_step("Take 11 from both sides.",
                       one(forms("-2x≥-6", "-6≤-2x"), accepts=["−2x ≥ −6", "-2x >= -6"],
                           rejects=["2x ≥ -6", "-2x ≥ 6", "-2x ≥ 16"],
                           mistakes=[mistake("rearranged-sign", forms("-2x≥16"),
                                             next_step="Taking 11 away from 5 gives a negative number.", examples=["−2x ≥ 16"]),
                                     mistake("dropped-minus", forms("-2x≥6"),
                                             next_step="5 take away 11 is below zero.", examples=["−2x ≥ 6"])]),
                       answer="−2x ≥ −6", working="5 − 11 = −6, so −2x ≥ −6."),
            stuck_step("Divide both sides by −2.",
                       one(forms("x≤3", "3≥x"), accepts=["x ≤ 3", "x <= 3"], rejects=["x ≥ 3", "x ≤ -3", "x = 3"],
                           mistakes=[mistake("inequality-not-flipped", forms("x≥3", "3≤x"),
                                             next_step="Dividing by a negative number turns the inequality sign round.",
                                             examples=["x ≥ 3"]),
                                     mistake("dropped-minus", forms("x≤-3", "x≥-3"),
                                             next_step="A negative divided by a negative is positive.", examples=["x ≤ −3"])]),
                       answer="x ≤ 3", working="−6 ÷ −2 = 3 and the sign turns round, so x ≤ 3."),
            stuck_step("What is the largest integer x can be?",
                       one(num("3"), accepts=["3", "x = 3"], rejects=["2", "-3", "1"]),
                       answer="3", working="x can equal 3, so 3 is the largest integer."),
        ]),
    "q-oup-ch07-wb-challenge": stuck_sheet(
        "Make x the subject of y = (x + 5)/(x − 1).",
        [
            stuck_step("Multiply both sides by (x − 1).",
                       one(forms("y(x-1)=x+5", "x+5=y(x-1)", "(x-1)y=x+5"), accepts=["y(x − 1) = x + 5"],
                           rejects=["y = x + 5", "yx - 1 = x + 5", "y(x + 1) = x + 5"]),
                       answer="y(x − 1) = x + 5", working="Multiplying by (x − 1) clears the fraction, so y(x − 1) = x + 5."),
            stuck_step("Expand the bracket.",
                       one(forms("xy-y=x+5", "yx-y=x+5"), accepts=["xy − y = x + 5"],
                           rejects=["xy - 1 = x + 5", "xy + y = x + 5", "xy = x + 5"],
                           mistakes=[mistake("expand-first-term-only", forms("xy-1=x+5", "yx-1=x+5"),
                                             next_step="Multiply y by both terms in the bracket.", examples=["xy − 1 = x + 5"])]),
                       answer="xy − y = x + 5", working="y × x = xy and y × −1 = −y, so xy − y = x + 5."),
            stuck_step("Get the x terms on one side and the rest on the other.",
                       one(forms("xy-x=y+5", "yx-x=y+5", "xy-x=5+y", "yx-x=5+y"), accepts=["xy − x = y + 5"],
                           rejects=["xy - x = y - 5", "xy + x = y + 5", "xy = y + 5"],
                           mistakes=[mistake("rearranged-sign", forms("xy-x=y-5", "xy+x=y+5", "yx-x=y-5", "yx+x=y+5", "xy-x=5-y"),
                                             next_step="Each term changes sign when it crosses the equals sign.",
                                             examples=["xy − x = y − 5"])]),
                       answer="xy − x = y + 5", working="Take x from both sides and add y to both sides, so xy − x = y + 5."),
            stuck_step("Take x out as a factor, then divide to get x on its own.",
                       one(forms("x=(y+5)/(y-1)", "x=(5+y)/(y-1)", "(y+5)/(y-1)", "(5+y)/(y-1)", "x=(y+5)/(-1+y)"),
                           accepts=["x = (y + 5)/(y − 1)"],
                           rejects=["x = (y - 5)/(y - 1)", "x = (y + 5)/(y + 1)", "x(y - 1) = y + 5"]),
                       answer="x = (y + 5)/(y − 1)", working="x(y − 1) = y + 5, so x = (y + 5)/(y − 1)."),
        ]),
    # Chapter 8
    "q-oup-ch08-sb": stuck_sheet(
        "In a triangle, two interior angles are (x + 5)° and (x + 15)°. The exterior angle opposite them is (3x − 10)°. Find x and the exterior angle.",
        [
            stuck_step("The exterior angle equals the two opposite interior angles added. Add (x + 5) and (x + 15).",
                       one(forms("2x+20", "20+2x"), accepts=["2x + 20"], rejects=["x + 20", "2x + 15", "2x + 75"]),
                       answer="2x + 20", working="x + x = 2x and 5 + 15 = 20, so 2x + 20."),
            stuck_step("Solve 3x − 10 = 2x + 20.",
                       one(num("30"), accepts=["30", "x = 30"], rejects=["10", "-30", "6"],
                           mistakes=[mistake("rearranged-sign", num("10"),
                                             next_step="Moving the minus 10 across the equals sign makes it plus 10.",
                                             examples=["x = 10"])]),
                       answer="x = 30", working="Take 2x from both sides and add 10 to both, so x = 30."),
            stuck_step("Find the exterior angle, 3x − 10.",
                       one(num("80"), accepts=["80", "80°"], rejects=["100", "90", "20"],
                           mistakes=[mistake("dropped-minus", num("100"),
                                             next_step="The angle is 3x take away 10, so keep the minus.", examples=["100"])]),
                       answer="80°", working="3 × 30 − 10 = 80, so the exterior angle is 80°."),
        ]),
    "q-oup-ch08-wb-focus": stuck_sheet(
        "Find the midpoint M of the line joining A(1, 5) and B(7, 9).",
        [
            stuck_step("Add the two x-coordinates.",
                       one(num("8"), accepts=["8"], rejects=["6", "4", "-6"],
                           mistakes=[mistake("half-difference", num("6"), num("-6"),
                                             next_step="For the midpoint you add the coordinates, not subtract them.",
                                             examples=["6"])]),
                       answer="8", working="1 + 7 = 8."),
            stuck_step("Take half of it.",
                       one(num("4"), accepts=["4", "x = 4"], rejects=["8", "16", "3"],
                           mistakes=[mistake("forgot-half", num("8"),
                                             next_step="The midpoint is halfway, so halve the total.", examples=["8"])]),
                       answer="4", working="Half of 8 is 4."),
            stuck_step("Do the same for the y-coordinates: add them and take half.",
                       one(num("7"), accepts=["7", "y = 7"], rejects=["14", "2", "4"],
                           mistakes=[mistake("forgot-half", num("14"),
                                             next_step="Add the y-coordinates and then halve the total.", examples=["14"])]),
                       answer="7", working="5 + 9 = 14, and half of 14 is 7."),
            stuck_step("Write the midpoint M.",
                       one(seq("4", "7"), accepts=["(4, 7)", "M = (4, 7)"], rejects=["(7, 4)", "(8, 14)", "(4, 14)"],
                           mistakes=[mistake("swapped-coordinates", seq("7", "4"),
                                             next_step="The x-coordinate comes first in the brackets.", examples=["(7, 4)"]),
                                     mistake("forgot-half", seq("8", "14"),
                                             next_step="Both totals need halving.", examples=["(8, 14)"])]),
                       answer="(4, 7)", working="x comes first and then y, so M = (4, 7)."),
        ]),
    "q-oup-ch08-wb-practice": stuck_sheet(
        "Two parallel lines are cut by a transversal. Two co-interior angles are (2y + 20)° and (y + 10)°. Find y.",
        [
            stuck_step("What do co-interior angles add up to?",
                       one(num("180"), accepts=["180", "180°"], rejects=["90", "360", "0"]),
                       answer="180°", working="Co-interior angles between parallel lines add up to 180°."),
            stuck_step("Add the two angles and simplify.",
                       one(forms("3y+30", "30+3y"), accepts=["3y + 30"], rejects=["2y + 30", "3y + 10", "3y + 20"]),
                       answer="3y + 30", working="2y + y = 3y and 20 + 10 = 30, so 3y + 30."),
            stuck_step("Solve 3y + 30 = 180.",
                       one(num("50"), accepts=["50", "y = 50"], rejects=["70", "150", "60"],
                           mistakes=[mistake("rearranged-sign", num("70"),
                                             next_step="Moving plus 30 across the equals sign makes it minus 30.",
                                             examples=["y = 70"]),
                                     mistake("stopped-early", num("150"),
                                             next_step="That is 3y, so one more step gets y on its own.", examples=["150"])]),
                       answer="y = 50", working="3y = 150, so y = 50."),
        ]),
    "q-oup-ch08-wb-challenge": stuck_sheet(
        "Each interior angle of a regular polygon is 120°. How many sides does it have?",
        [
            stuck_step("Find each exterior angle.",
                       one(num("60"), accepts=["60", "60°"], rejects=["120", "240", "30"]),
                       answer="60°", working="An interior and an exterior angle make a straight line, so 180 − 120 = 60°."),
            stuck_step("What do the exterior angles of any polygon add up to?",
                       one(num("360"), accepts=["360", "360°"], rejects=["180", "540", "720"]),
                       answer="360°", working="Walking once round any polygon turns you through 360°."),
            stuck_step("How many sides does it have?",
                       one(num("6"), accepts=["6", "6 sides"], rejects=["3", "60", "12"],
                           mistakes=[mistake("interior-for-exterior", num("3"),
                                             next_step="Divide by the exterior angle, not the interior one.", examples=["3"]),
                                     mistake("stopped-early", num("60"),
                                             next_step="That is the exterior angle; now find how many of them fit into a full turn.",
                                             examples=["60"])]),
                       answer="6 sides", working="360 ÷ 60 = 6, so it has 6 sides."),
        ]),
    # Chapter 9
    "q-oup-ch09-sb": stuck_sheet(
        "After a 20% discount, a bag costs ₹400. Find its price before the discount.",
        [
            stuck_step("What multiplier gives a 20% decrease?",
                       one(num("0.8"), accepts=["0.8", "0.80"], rejects=["0.2", "1.2", "20"]),
                       answer="0.8", working="100% − 20% = 80%, which is 0.8."),
            stuck_step("Write an equation for the original price P.",
                       one(forms("0.8p=400", "400=0.8p", "p*0.8=400", "0.8*p=400"), accepts=["0.8P = 400"],
                           rejects=["P = 400 × 0.8", "1.2P = 400", "0.2P = 400"]),
                       answer="0.8P = 400", working="The original price times 0.8 is 400, so 0.8P = 400."),
            stuck_step("Find P.",
                       one(num("500"), accepts=["₹500", "500"], rejects=["480", "320", "2000"],
                           mistakes=[mistake("percent-of-wrong-amount", num("480"),
                                             next_step="The 20% came off the original price, not the sale price.",
                                             examples=["480"]),
                                     mistake("multiplied-instead-of-divided", num("320"),
                                             next_step="To undo times 0.8, divide by 0.8.", examples=["320"])]),
                       answer="₹500", working="400 ÷ 0.8 = 500, so the price was ₹500."),
        ]),
    "q-oup-ch09-wb-focus": stuck_sheet(
        "Work out 12 ÷ 0.4 without a calculator.",
        [
            stuck_step("You are dividing by a number less than 1. Is the answer bigger or smaller than 12?",
                       one(words(["bigger", "larger", "greater", "more"], forbid=["smaller", "less", "lower"]),
                           accepts=["bigger"], rejects=["smaller", "the same", "less"]),
                       answer="Bigger", working="Dividing by a number less than 1 makes the answer bigger."),
            stuck_step("Multiply 0.4 by 10 to make a whole number.",
                       one(num("4"), accepts=["4"], rejects=["40", "0.04", "14"]),
                       answer="4", working="0.4 × 10 = 4."),
            stuck_step("Multiply 12 by 10 too, so the answer stays the same.",
                       one(num("120"), accepts=["120"], rejects=["12", "1200", "22"]),
                       answer="120", working="12 × 10 = 120."),
            stuck_step("Now divide 120 by 4.",
                       one(num("30"), accepts=["30"], rejects=["3", "300", "4.8", "480"],
                           mistakes=[mistake("place-value-shift", num("3"), num("300"),
                                             next_step="Check the place value: 120 is twelve tens.", examples=["3", "300"]),
                                     mistake("multiplied-instead-of-divided", num("4.8"),
                                             next_step="You need 12 shared into groups of 0.4, so divide.", examples=["4.8"])]),
                       answer="30", working="120 ÷ 4 = 30, so 12 ÷ 0.4 = 30."),
        ]),
    "q-oup-ch09-wb-practice": stuck_sheet(
        "A price goes up by 10% and then down by 10%. What is the overall percentage change?",
        [
            stuck_step("What multiplier gives a 10% increase?",
                       one(num("1.1"), accepts=["1.1", "1.10"], rejects=["0.1", "1.01", "110"]),
                       answer="1.1", working="100% + 10% = 110%, which is 1.1."),
            stuck_step("What multiplier gives a 10% decrease?",
                       one(num("0.9"), accepts=["0.9"], rejects=["0.1", "1.1", "90"]),
                       answer="0.9", working="100% − 10% = 90%, which is 0.9."),
            stuck_step("Multiply the two multipliers.",
                       one(num("0.99"), accepts=["0.99"], rejects=["1", "0.9", "2"],
                           mistakes=[mistake("percentages-cancel", num("1"),
                                             next_step="The 10% off is taken from a bigger price than the 10% on was.",
                                             examples=["1"])]),
                       answer="0.99", working="1.1 × 0.9 = 0.99."),
            stuck_step("What is the overall percentage change?",
                       key([part("the change", num("-1"), all_of(num("1"), words(DECREASE_WORDS, forbid=INCREASE_WORDS)))],
                           accepts=["−1%", "a 1% decrease", "down 1%"], rejects=["1%", "-10%", "1% increase"],
                           mistakes=[mistake("percentages-cancel", num("0"), words(["no change", "unchanged", "same"]),
                                             next_step="Compare the final multiplier with what you started with.",
                                             examples=["0%", "no change"]),
                                     mistake("stopped-early", num("0.99"),
                                             next_step="That is the multiplier; turn it into a percentage change.",
                                             examples=["0.99"])]),
                       answer="−1%", working="0.99 is 1% less than 1, so the price falls by 1%."),
        ]),
    "q-oup-ch09-wb-challenge": stuck_sheet(
        "₹1,000 is invested at 10% a year compound interest for 2 years. Find the total interest earned.",
        [
            stuck_step("What is it worth after 1 year?",
                       one(num("1100"), accepts=["1100", "₹1,100"], rejects=["100", "1010", "2000"]),
                       answer="₹1,100", working="10% of 1000 is 100, so 1000 + 100 = 1100."),
            stuck_step("What is it worth after 2 years?",
                       one(num("1210"), accepts=["1210", "₹1,210"], rejects=["1200", "1110", "1300"],
                           mistakes=[mistake("simple-not-compound", num("1200"),
                                             next_step="In year two the interest is on the new amount, not the first one.",
                                             examples=["1200"])]),
                       answer="₹1,210", working="10% of 1100 is 110, so 1100 + 110 = 1210."),
            stuck_step("How much interest is that in total?",
                       one(num("210"), accepts=["210", "₹210"], rejects=["1210", "200", "110"],
                           mistakes=[mistake("stopped-early", num("1210"),
                                             next_step="That is the whole amount; take away what was put in.", examples=["1210"]),
                                     mistake("simple-not-compound", num("200"),
                                             next_step="Year two earns interest on the interest too.", examples=["200"])]),
                       answer="₹210", working="1210 − 1000 = 210."),
        ]),
    # Chapter 10
    "q-oup-ch10-sb": stuck_sheet(
        "The class 0 ≤ m < 10 kg has frequency 20, and 10 ≤ m < 15 kg has frequency 15. Find the frequency density of each class.",
        [
            stuck_step("What is the width of the first class?",
                       one(num("10"), accepts=["10", "10 kg"], rejects=["20", "5", "0"]),
                       answer="10 kg", working="10 − 0 = 10."),
            stuck_step("Frequency density = frequency ÷ class width. Find it for the first class.",
                       one(num("2"), accepts=["2"], rejects=["0.5", "20", "200"],
                           mistakes=[mistake("divided-wrong-way-round", num("0.5"),
                                             next_step="Put the frequency on top and the width underneath.", examples=["0.5"]),
                                     mistake("density-as-frequency", num("20"),
                                             next_step="The frequency is the count; density spreads it over the width.",
                                             examples=["20"])]),
                       answer="2", working="20 ÷ 10 = 2."),
            stuck_step("What is the width of the second class?",
                       one(num("5"), accepts=["5", "5 kg"], rejects=["15", "10", "25"],
                           mistakes=[mistake("boundary-for-width", num("15"),
                                             next_step="Width is the top boundary take away the bottom one.", examples=["15"])]),
                       answer="5 kg", working="15 − 10 = 5."),
            stuck_step("Find the frequency density of the second class.",
                       one(num("3"), accepts=["3"], rejects=["1/3", "15", "75"],
                           mistakes=[mistake("divided-wrong-way-round", num("1/3"), num("0.333", tolerance=0.001),
                                             next_step="Put the frequency on top and the width underneath.", examples=["1/3"]),
                                     mistake("density-as-frequency", num("15"),
                                             next_step="The frequency is the count; density spreads it over the width.",
                                             examples=["15"])]),
                       answer="3", working="15 ÷ 5 = 3."),
        ]),
    "q-oup-ch10-wb-focus": stuck_sheet(
        "Find the median and interquartile range of the ordered data 3, 5, 6, 8, 10, 11, 13.",
        [
            stuck_step("There are 7 values. Find the median, the middle one.",
                       one(num("8"), accepts=["8"], rejects=["7", "6", "10"]),
                       answer="8", working="The 4th of the 7 values is in the middle, and it is 8."),
            stuck_step("Find the lower quartile, the middle of the values below the median.",
                       one(num("5"), accepts=["5"], rejects=["3", "6", "4"]),
                       answer="5", working="Below 8 are 3, 5 and 6, and the middle of those is 5."),
            stuck_step("Find the upper quartile.",
                       one(num("11"), accepts=["11"], rejects=["10", "13", "12"]),
                       answer="11", working="Above 8 are 10, 11 and 13, and the middle of those is 11."),
            stuck_step("IQR = upper quartile − lower quartile. Work it out.",
                       one(num("6"), accepts=["6", "IQR = 6"], rejects=["10", "16", "8"],
                           mistakes=[mistake("range-for-iqr", num("10"),
                                             next_step="The IQR uses the quartiles, not the smallest and largest values.",
                                             examples=["10"])]),
                       answer="6", working="11 − 5 = 6."),
        ]),
    "q-oup-ch10-wb-practice": stuck_sheet(
        "Find the population standard deviation σ of 1, 3, 5, 7.",
        [
            stuck_step("Find the mean.",
                       one(num("4"), accepts=["4"], rejects=["16", "5", "3"]),
                       answer="4", working="1 + 3 + 5 + 7 = 16, and 16 ÷ 4 = 4."),
            stuck_step("Square how far each value is from the mean.",
                       one(seq("9", "1", "1", "9"), accepts=["9, 1, 1, 9"], rejects=["3, 1, 1, 3", "-3, -1, 1, 3", "1, 9, 25, 49"]),
                       answer="9, 1, 1, 9", working="The values are 3, 1, 1 and 3 away from 4, and squaring gives 9, 1, 1 and 9."),
            stuck_step("Find the variance, the mean of those squares.",
                       one(num("5"), accepts=["5"], rejects=["20", "4", "2.24"],
                           mistakes=[mistake("stopped-early", num("20"),
                                             next_step="That is the total; share it between the four values.", examples=["20"])]),
                       answer="5", working="9 + 1 + 1 + 9 = 20, and 20 ÷ 4 = 5."),
            stuck_step("Take the square root to find σ, to two decimal places.",
                       one(num("2.24", tolerance=0.005), forms("√5"), accepts=["2.24", "√5"], rejects=["5", "2.5", "25"],
                           mistakes=[mistake("forgot-square-root", num("5"),
                                             next_step="That is the variance; σ is its square root.", examples=["5"])]),
                       answer="σ ≈ 2.24", working="√5 is about 2.236, so σ = 2.24 to two decimal places."),
        ]),
    "q-oup-ch10-wb-challenge": stuck_sheet(
        "A histogram bar for 10 ≤ t < 15 s has frequency density 4. How many observations are in this class?",
        [
            stuck_step("What is the class width?",
                       one(num("5"), accepts=["5", "5 s"], rejects=["15", "10", "25"],
                           mistakes=[mistake("boundary-for-width", num("15"), num("10"),
                                             next_step="Width is the top boundary take away the bottom one.", examples=["15"])]),
                       answer="5 s", working="15 − 10 = 5."),
            stuck_step("To get the frequency from the density, do you multiply or divide by the width?",
                       one(words(["multiply", "times", "multiplied"], forbid=["divide", "divided", "share"]),
                           accepts=["multiply"], rejects=["divide", "add", "subtract"]),
                       answer="Multiply", working="Density is frequency ÷ width, so frequency is density × width."),
            stuck_step("Find the frequency.",
                       one(num("20"), accepts=["20"], rejects=["4", "60", "1.25"],
                           mistakes=[mistake("density-as-frequency", num("4"),
                                             next_step="The density is per unit of width, so scale it up by the width.",
                                             examples=["4"]),
                                     mistake("boundary-for-width", num("60"), num("40"),
                                             next_step="Use the width of the class, not one of its boundaries.",
                                             examples=["60"])]),
                       answer="20", working="4 × 5 = 20 observations."),
        ]),
    # Chapter 11
    "q-oup-ch11-sb": stuck_sheet(
        "Find the nth term of 6, 8, 10, 12, … and the sum of its first 10 terms.",
        [
            stuck_step("What is the common difference?",
                       one(num("2"), accepts=["2", "d = 2"], rejects=["6", "4", "-2"]),
                       answer="2", working="Each term is 2 more than the one before."),
            stuck_step("Step back one term from 6 to find the zero term.",
                       one(num("4"), accepts=["4"], rejects=["6", "8", "2"],
                           mistakes=[mistake("off-by-one", num("6"),
                                             next_step="Go back one step before the first term.", examples=["6"])]),
                       answer="4", working="6 − 2 = 4."),
            stuck_step("Write the nth term.",
                       one(forms("2n+4", "4+2n", "2(n+2)"), accepts=["Tₙ = 2n + 4", "2n + 4"],
                           rejects=["2n + 6", "n + 4", "4n + 2"],
                           mistakes=[mistake("off-by-one", forms("2n+6", "6+2n"),
                                             next_step="The number on the end is the zero term, the one before the first.",
                                             examples=["2n + 6"])]),
                       answer="Tₙ = 2n + 4", working="The difference 2 goes with n and the zero term 4 goes on the end."),
            stuck_step("Find the 10th term.",
                       one(num("24"), accepts=["24", "T₁₀ = 24"], rejects=["26", "20", "22"],
                           mistakes=[mistake("off-by-one", num("26"),
                                             next_step="Put n = 10 into the nth term and check the first term comes out right.",
                                             examples=["26"])]),
                       answer="24", working="2 × 10 + 4 = 24."),
            stuck_step("Each pair, first with last, makes 6 + 24 = 30, and there are 5 pairs. Find the sum of the first 10 terms.",
                       one(num("150"), accepts=["150", "S₁₀ = 150"], rejects=["300", "30", "240"],
                           mistakes=[mistake("forgot-half", num("300"),
                                             next_step="Ten terms make only five pairs.", examples=["300"]),
                                     mistake("off-by-one", num("160"),
                                             next_step="Check the 10th term before you pair it up.", examples=["160"])]),
                       answer="150", working="5 × 30 = 150."),
        ]),
    "q-oup-ch11-wb-focus": stuck_sheet(
        "Does the number 50 belong to the sequence Tₙ = 3n + 2? Show it with algebra.",
        [
            stuck_step("Set the nth term equal to 50.",
                       one(forms("3n+2=50", "50=3n+2"), accepts=["3n + 2 = 50"],
                           rejects=["3n = 50", "n + 2 = 50", "3n + 2 = 48"]),
                       answer="3n + 2 = 50", working="If 50 is a term, then 3n + 2 = 50 for some n."),
            stuck_step("Take 2 from both sides.",
                       one(forms("3n=48", "48=3n"), accepts=["3n = 48"], rejects=["3n = 52", "3n = 50", "n = 48"],
                           mistakes=[mistake("rearranged-sign", forms("3n=52", "52=3n"),
                                             next_step="Moving plus 2 across the equals sign makes it minus 2.",
                                             examples=["3n = 52"])]),
                       answer="3n = 48", working="50 − 2 = 48, so 3n = 48."),
            stuck_step("Find n.",
                       one(num("16"), accepts=["16", "n = 16"], rejects=["144", "45", "51"]),
                       answer="n = 16", working="48 ÷ 3 = 16."),
            stuck_step("Is n a whole number, and so is 50 in the sequence?",
                       one(words(["yes"], forbid=["no", "not", "isn't", "doesn't", "cannot", "can't", "never"]),
                           accepts=["yes", "yes, it is the 16th term"], rejects=["no", "it is not", "it isn't"]),
                       answer="Yes", working="16 is a whole number, so 50 is the 16th term."),
        ]),
    "q-oup-ch11-wb-practice": stuck_sheet(
        "Find the nth term of the quadratic sequence 4, 7, 12, 19, 28, …",
        [
            stuck_step("Write the first differences.",
                       one(seq("3", "5", "7", "9"), accepts=["3, 5, 7, 9"], rejects=["3, 5, 7", "2, 2, 2", "4, 7, 12"]),
                       answer="3, 5, 7, 9", working="7 − 4 = 3, 12 − 7 = 5, 19 − 12 = 7 and 28 − 19 = 9."),
            stuck_step("What is the second difference?",
                       one(num("2"), accepts=["2"], rejects=["3", "1", "4"]),
                       answer="2", working="The first differences go up by 2 each time."),
            stuck_step("Halve the second difference to get the number in front of the squared term. Write that term.",
                       one(forms("n^2", "1n^2"), accepts=["n²"], rejects=["2n²", "2n", "n"],
                           mistakes=[mistake("forgot-half", forms("2n^2"),
                                             next_step="The number in front of the squared term is half the second difference.",
                                             examples=["2n²"])]),
                       answer="n²", working="Half of 2 is 1, so the term is n²."),
            stuck_step("Take n² away from each term. What is left each time?",
                       one(num("3"), accepts=["3"], rejects=["1", "4", "2"]),
                       answer="3", working="4 − 1, 7 − 4 and 12 − 9 all give 3."),
            stuck_step("Write the nth term.",
                       one(forms("n^2+3", "3+n^2"), accepts=["n² + 3"], rejects=["n² + 2", "2n² + 3", "3n + 1"]),
                       answer="n² + 3", working="The n² part and the 3 left over give n² + 3."),
        ]),
    "q-oup-ch11-wb-challenge": stuck_sheet(
        "Using Gauss's pairing, work out 1 + 2 + 3 + … + 10.",
        [
            stuck_step("Pair the first and last numbers, 1 and 10. What does each pair add to?",
                       one(num("11"), accepts=["11"], rejects=["10", "9", "12"]),
                       answer="11", working="1 + 10 = 11, and 2 + 9 = 11 as well."),
            stuck_step("How many pairs are there?",
                       one(num("5"), accepts=["5"], rejects=["10", "11", "4"],
                           mistakes=[mistake("forgot-half", num("10"),
                                             next_step="Each pair uses two numbers, so there are half as many pairs as numbers.",
                                             examples=["10"])]),
                       answer="5", working="10 numbers make 5 pairs."),
            stuck_step("Find the total.",
                       one(num("55"), accepts=["55"], rejects=["110", "50", "45"],
                           mistakes=[mistake("forgot-half", num("110"),
                                             next_step="Count the pairs again: each one uses two numbers.", examples=["110"]),
                                     mistake("off-by-one", num("45"), num("50"),
                                             next_step="Check the pairs run all the way from 1 to 10.", examples=["45"])]),
                       answer="55", working="5 × 11 = 55."),
        ]),
    # Chapter 12
    "q-oup-ch12-sb": stuck_sheet(
        "Ali, Ben and Cal share some money in the ratio 1 : 2 : 4. Cal gets ₹30 more than Ali. Find the total.",
        [
            stuck_step("How many more parts does Cal have than Ali?",
                       one(num("3"), accepts=["3"], rejects=["4", "5", "2"]),
                       answer="3", working="4 − 1 = 3 parts."),
            stuck_step("Those parts are worth ₹30. What is one part worth?",
                       one(num("10"), accepts=["10", "₹10"], rejects=["30", "7.5", "90"],
                           mistakes=[mistake("wrong-units-for-difference", num("7.5"), num("30"),
                                             next_step="The ₹30 matches the gap in parts between Cal and Ali, not Cal's share.",
                                             examples=["7.5"])]),
                       answer="₹10", working="30 ÷ 3 = 10, so one part is ₹10."),
            stuck_step("How many parts are there altogether?",
                       one(num("7"), accepts=["7"], rejects=["8", "6", "3"]),
                       answer="7", working="1 + 2 + 4 = 7."),
            stuck_step("Find the total.",
                       one(num("70"), accepts=["₹70", "70"], rejects=["10", "30", "40"],
                           mistakes=[mistake("stopped-early", num("10"),
                                             next_step="That is one part; multiply by the number of parts.", examples=["10"])]),
                       answer="₹70", working="7 × 10 = 70, so the total is ₹70."),
        ]),
    "q-oup-ch12-wb-focus": stuck_sheet(
        "Convert 2 m² into cm².",
        [
            stuck_step("How many cm are in 1 m?",
                       one(num("100"), accepts=["100"], rejects=["10", "1000", "1"]),
                       answer="100", working="1 m = 100 cm."),
            stuck_step("A square 1 m by 1 m is 100 cm by 100 cm. How many cm² is that?",
                       one(num("10000"), accepts=["10000", "10,000"], rejects=["100", "1000", "200"],
                           mistakes=[mistake("area-by-length-factor", num("100"),
                                             next_step="Area has two lengths, so multiply by the factor twice.", examples=["100"])]),
                       answer="10,000 cm²", working="100 × 100 = 10,000, so 1 m² = 10,000 cm²."),
            stuck_step("Now convert 2 m².",
                       one(num("20000"), accepts=["20000", "20,000 cm²"], rejects=["200", "2000", "10000"],
                           mistakes=[mistake("area-by-length-factor", num("200"),
                                             next_step="Use the square factor from the last step, not the length factor.",
                                             examples=["200"])]),
                       answer="20,000 cm²", working="2 × 10,000 = 20,000 cm²."),
        ]),
    "q-oup-ch12-wb-practice": stuck_sheet(
        "3 taps fill a tank in 10 minutes. How long would 5 identical taps take?",
        [
            stuck_step("With more taps, does the job take more time or less time?",
                       one(words(["less", "shorter", "quicker", "faster"], forbid=["more", "longer", "slower"]),
                           accepts=["less", "less time"], rejects=["more", "the same", "longer"]),
                       answer="Less", working="More taps share the work, so it takes less time."),
            stuck_step("How many tap-minutes does the job take in all?",
                       one(num("30"), accepts=["30"], rejects=["13", "3.3", "10"]),
                       answer="30", working="3 taps × 10 minutes = 30 tap-minutes."),
            stuck_step("Share those tap-minutes between 5 taps.",
                       one(num("6"), accepts=["6", "6 minutes"], rejects=["150", "16.7", "2"],
                           mistakes=[mistake("direct-for-inverse", num("16.7", tolerance=0.05),
                                             next_step="More taps means less time, so the time goes down, not up.",
                                             examples=["16.7", "50/3"])]),
                       answer="6 minutes", working="30 ÷ 5 = 6 minutes."),
        ]),
    "q-oup-ch12-wb-challenge": stuck_sheet(
        "A : B = 1 : 2 and B : C = 3 : 4. Find A : B : C in simplest whole numbers.",
        [
            stuck_step("B is 2 in one ratio and 3 in the other. What is the smallest number both go into?",
                       one(num("6"), accepts=["6"], rejects=["5", "12", "1"]),
                       answer="6", working="6 is the lowest common multiple of 2 and 3."),
            stuck_step("Scale A : B = 1 : 2 so that B is 6.",
                       one(seq("3", "6"), accepts=["3 : 6"], rejects=["1 : 6", "6 : 12", "2 : 6"]),
                       answer="3 : 6", working="Multiply both parts by 3 to get 3 : 6."),
            stuck_step("Scale B : C = 3 : 4 so that B is 6.",
                       one(seq("6", "8"), accepts=["6 : 8"], rejects=["6 : 7", "3 : 8", "6 : 4"]),
                       answer="6 : 8", working="Multiply both parts by 2 to get 6 : 8."),
            stuck_step("Write A : B : C.",
                       one(seq("3", "6", "8"), accepts=["3 : 6 : 8"], rejects=["1 : 2 : 4", "1 : 3 : 4", "3 : 6 : 4"],
                           mistakes=[mistake("unmatched-middle", seq("1", "2", "4"), seq("1", "3", "4"), seq("1", "2", "3", "4"),
                                             next_step="Make B the same number in both ratios before joining them.",
                                             examples=["1 : 2 : 4", "1 : 3 : 4"])]),
                       answer="3 : 6 : 8", working="B is 6 in both, so A : B : C = 3 : 6 : 8."),
        ]),
    # Chapter 13
    "q-oup-ch13-sb": stuck_sheet(
        "Triangle T has area 5 cm² and a vertex A(3, 4). It is enlarged by scale factor 2 about centre C(1, 2). Find the image A′ and the image area.",
        [
            stuck_step("Find the step from C to A.",
                       one(seq("2", "2"), accepts=["(2, 2)"], rejects=["(4, 6)", "(-2, -2)", "(3, 4)"]),
                       answer="(2, 2)", working="3 − 1 = 2 across and 4 − 2 = 2 up."),
            stuck_step("Multiply the step by the scale factor.",
                       one(seq("4", "4"), accepts=["(4, 4)"], rejects=["(2, 2)", "(6, 8)", "(4, 2)"]),
                       answer="(4, 4)", working="2 × 2 = 4 across and 2 × 2 = 4 up."),
            stuck_step("Add it to C to find A′.",
                       one(seq("5", "6"), accepts=["(5, 6)", "A′ = (5, 6)"], rejects=["(6, 8)", "(4, 4)", "(7, 10)"],
                           mistakes=[mistake("centre-ignored", seq("6", "8"),
                                             next_step="Measure the enlargement from the centre, not from the origin.",
                                             examples=["(6, 8)"]),
                                     mistake("stopped-early", seq("4", "4"),
                                             next_step="That is the step from the centre; now add it on to the centre.",
                                             examples=["(4, 4)"])]),
                       answer="A′ = (5, 6)", working="1 + 4 = 5 and 2 + 4 = 6, so A′ = (5, 6)."),
            stuck_step("Find the image area.",
                       one(num("20"), accepts=["20", "20 cm²"], rejects=["10", "5", "40"],
                           mistakes=[mistake("area-by-length-factor", num("10"),
                                             next_step="Lengths double, so area grows by the scale factor squared.",
                                             examples=["10"])]),
                       answer="20 cm²", working="Area scales by 2² = 4, so 5 × 4 = 20 cm²."),
        ]),
    "q-oup-ch13-wb-focus": stuck_sheet(
        "Reflect the point P(−2, 6) in the line y = x.",
        [
            stuck_step("Reflecting in y = x swaps the coordinates. What is the new x-coordinate?",
                       one(num("6"), accepts=["6", "x = 6"], rejects=["-6", "-2", "2"]),
                       answer="6", working="The old y-coordinate, 6, becomes the new x."),
            stuck_step("What is the new y-coordinate?",
                       one(num("-2"), accepts=["−2", "y = −2"], rejects=["2", "6", "-6"],
                           mistakes=[mistake("dropped-minus", num("2"),
                                             next_step="The coordinates swap places but keep their signs.", examples=["2"])]),
                       answer="−2", working="The old x-coordinate, −2, becomes the new y."),
            stuck_step("Write the image point.",
                       one(seq("6", "-2"), accepts=["(6, −2)"], rejects=["(-2, 6)", "(-6, 2)", "(6, 2)"],
                           mistakes=[mistake("wrong-mirror-line", seq("-6", "2"), seq("2", "6"), seq("-2", "-6"),
                                             next_step="In y = x the two coordinates swap places and nothing else changes.",
                                             examples=["(−6, 2)", "(−2, −6)"]),
                                     mistake("dropped-minus", seq("6", "2"),
                                             next_step="Keep the minus sign when the coordinates swap.", examples=["(6, 2)"])]),
                       answer="(6, −2)", working="The coordinates swap, so the image is (6, −2)."),
        ]),
    "q-oup-ch13-wb-practice": stuck_sheet(
        "Rotate the point Q(3, 2) by 90° anticlockwise about the origin.",
        [
            stuck_step("Q is in the top right quarter of the grid. Which quarter does a 90° anticlockwise turn take it to?",
                       one(words(["top left", "upper left", "second"], forbid=["right", "bottom", "lower"]),
                           accepts=["top left"], rejects=["bottom right", "top right", "bottom left"]),
                       answer="Top left", working="Anticlockwise from the top right goes up and over to the top left."),
            stuck_step("A 90° anticlockwise turn sends (x, y) to (−y, x). What is the new x-coordinate?",
                       one(num("-2"), accepts=["−2"], rejects=["2", "3", "-3"],
                           mistakes=[mistake("dropped-minus", num("2"),
                                             next_step="In the top left quarter, x is negative.", examples=["2"])]),
                       answer="−2", working="The new x is minus the old y, so −2."),
            stuck_step("Write the image point Q′.",
                       one(seq("-2", "3"), accepts=["(−2, 3)"], rejects=["(2, -3)", "(2, 3)", "(-3, 2)"],
                           mistakes=[mistake("wrong-turn-direction", seq("2", "-3"),
                                             next_step="Anticlockwise turns the opposite way to a clock's hands.",
                                             examples=["(2, −3)"]),
                                     mistake("dropped-minus", seq("2", "3"),
                                             next_step="In the top left quarter, x is negative and y is positive.",
                                             examples=["(2, 3)"])]),
                       answer="(−2, 3)", working="The new y is the old x, so Q′ = (−2, 3)."),
        ]),
    "q-oup-ch13-wb-challenge": stuck_sheet(
        "Enlarge the point P(4, 5) by scale factor −2 about centre C(2, 3).",
        [
            stuck_step("Find the step from C to P.",
                       one(seq("2", "2"), accepts=["(2, 2)"], rejects=["(6, 8)", "(-2, -2)", "(4, 5)"]),
                       answer="(2, 2)", working="4 − 2 = 2 across and 5 − 3 = 2 up."),
            stuck_step("Multiply the step by −2.",
                       one(seq("-4", "-4"), accepts=["(−4, −4)"], rejects=["(4, 4)", "(0, 0)", "(-2, -2)"],
                           mistakes=[mistake("dropped-minus", seq("4", "4"),
                                             next_step="A negative scale factor sends the point through the centre to the other side.",
                                             examples=["(4, 4)"])]),
                       answer="(−4, −4)", working="2 × −2 = −4 for each part."),
            stuck_step("Add it to C to find P′.",
                       one(seq("-2", "-1"), accepts=["(−2, −1)"], rejects=["(-4, -4)", "(6, 7)", "(-8, -10)"],
                           mistakes=[mistake("stopped-early", seq("-4", "-4"),
                                             next_step="That is the step from the centre; add it on to the centre.",
                                             examples=["(−4, −4)"]),
                                     mistake("centre-ignored", seq("-8", "-10"),
                                             next_step="Measure from the centre, not from the origin.", examples=["(−8, −10)"]),
                                     mistake("dropped-minus", seq("6", "7"),
                                             next_step="The image lands on the far side of the centre from P.",
                                             examples=["(6, 7)"])]),
                       answer="P′ = (−2, −1)", working="2 + (−4) = −2 and 3 + (−4) = −1, so P′ = (−2, −1)."),
        ]),
    # Chapter 14
    "q-oup-ch14-sb": stuck_sheet(
        "Find the equation of the line through A(1, 9) and B(3, 15) in the form y = mx + c, and say where it crosses the x-axis.",
        [
            stuck_step("Find the gradient m: change in y ÷ change in x.",
                       one(num("3"), accepts=["3", "m = 3"], rejects=["1/3", "6", "2"],
                           mistakes=[mistake("divided-wrong-way-round", num("1/3"),
                                             next_step="Gradient is the change in y over the change in x.", examples=["1/3"])]),
                       answer="m = 3", working="(15 − 9) ÷ (3 − 1) = 6 ÷ 2 = 3."),
            stuck_step("Put A(1, 9) into y = 3x + c to find c.",
                       one(num("6"), accepts=["6", "c = 6"], rejects=["12", "9", "-6"],
                           mistakes=[mistake("rearranged-sign", num("12"),
                                             next_step="Take 3 from both sides; do not add it.", examples=["12"])]),
                       answer="c = 6", working="9 = 3 × 1 + c, so c = 6."),
            stuck_step("Write the equation.",
                       one(forms("y=3x+6", "y=6+3x", "3x+6"), accepts=["y = 3x + 6"],
                           rejects=["y = 3x + 12", "y = 6x + 3", "y = x + 6"]),
                       answer="y = 3x + 6", working="m = 3 and c = 6, so y = 3x + 6."),
            stuck_step("It crosses the x-axis where y = 0. Find x there.",
                       one(num("-2"), accepts=["−2", "x = −2"], rejects=["2", "-6", "6"],
                           mistakes=[mistake("rearranged-sign", num("2"),
                                             next_step="Take 6 from both sides before you divide.", examples=["x = 2"])]),
                       answer="x = −2", working="0 = 3x + 6, so 3x = −6 and x = −2."),
        ]),
    "q-oup-ch14-wb-focus": stuck_sheet(
        "For the function f(x) = 2x + 5, find the inverse function f⁻¹(x).",
        [
            stuck_step("f doubles x. What does it do next?",
                       one(ADD_WORDS, accepts=["adds 5", "add 5"], rejects=["takes away 5", "multiplies by 5", "subtract 5"]),
                       answer="It adds 5", working="f doubles x and then adds 5."),
            stuck_step("Write y = 2x + 5, then take 5 from both sides.",
                       one(forms("y-5=2x", "2x=y-5", "-5+y=2x"), accepts=["y − 5 = 2x"],
                           rejects=["y + 5 = 2x", "y = 2x", "y - 5 = x"],
                           mistakes=[mistake("rearranged-sign", forms("y+5=2x", "2x=y+5"),
                                             next_step="Taking away from one side means taking away from the other.",
                                             examples=["y + 5 = 2x"])]),
                       answer="y − 5 = 2x", working="Taking 5 from both sides leaves y − 5 = 2x."),
            stuck_step("Divide both sides by 2 to get x on its own.",
                       one(forms("x=(y-5)/2", "(y-5)/2=x", "x=y/2-5/2", "x=1/2(y-5)"), accepts=["x = (y − 5)/2"],
                           rejects=["x = (y + 5)/2", "x = 2(y - 5)", "x = y - 5"],
                           mistakes=[mistake("inverse-wrong-order", forms("x=y/2-5"),
                                             next_step="Divide the whole of the left side, not only the y.", examples=["x = y/2 − 5"])]),
                       answer="x = (y − 5)/2", working="(y − 5) ÷ 2 gives x = (y − 5)/2."),
            stuck_step("Swap y for x to write f⁻¹(x).",
                       one(forms("(x-5)/2", "x/2-5/2", "1/2(x-5)", "1/2x-5/2", "(-5+x)/2", "0.5x-2.5"),
                           accepts=["f⁻¹(x) = (x − 5)/2", "(x − 5)/2"],
                           rejects=["(x + 5)/2", "1/(2x + 5)", "x/2 - 5", "2x - 5"],
                           mistakes=[mistake("inverse-as-reciprocal", forms("1/(2x+5)"),
                                             next_step="The inverse undoes f; it is not one over f.", examples=["1/(2x + 5)"]),
                                     mistake("inverse-wrong-order", forms("x/2-5", "1/2x-5"),
                                             next_step="Undo the steps in reverse: take away first, then halve.",
                                             examples=["x/2 − 5"]),
                                     mistake("rearranged-sign", forms("(x+5)/2", "x/2+5/2", "1/2(x+5)"),
                                             next_step="f adds, so its inverse takes away.", examples=["(x + 5)/2"])]),
                       answer="f⁻¹(x) = (x − 5)/2", working="Write x in place of y, so f⁻¹(x) = (x − 5)/2."),
        ]),
    "q-oup-ch14-wb-practice": stuck_sheet(
        "Find the equation of the line perpendicular to y = 3x + 1 that passes through (0, 2).",
        [
            stuck_step("What is the gradient of y = 3x + 1?",
                       one(num("3"), accepts=["3", "m = 3"], rejects=["1", "-3", "1/3"]),
                       answer="3", working="The number in front of x is the gradient, so it is 3."),
            stuck_step("Find the gradient of a line perpendicular to it.",
                       one(num("-1/3"), accepts=["−1/3", "-⅓"], rejects=["1/3", "-3", "3"],
                           mistakes=[mistake("perpendicular-gradient", num("1/3"), num("-3"),
                                             next_step="Flip the gradient over and change its sign.", examples=["1/3", "−3"])]),
                       answer="−1/3", working="Flip 3 over to get 1/3 and change the sign, so −1/3."),
            stuck_step("c is where the line crosses the y-axis. What is c?",
                       one(num("2"), accepts=["2", "c = 2"], rejects=["0", "-2", "3"]),
                       answer="c = 2", working="The line passes through (0, 2), which is on the y-axis, so c = 2."),
            stuck_step("Write the equation.",
                       one(forms("y=-1/3x+2", "y=-x/3+2", "y=2-1/3x", "y=2-x/3", "-1/3x+2", "-x/3+2", "2-1/3x", "2-x/3",
                                 "y=-(1/3)x+2"),
                           accepts=["y = −1/3x + 2", "y = −x/3 + 2"],
                           rejects=["y = 1/3x + 2", "y = -3x + 2", "y = 3x + 2"],
                           mistakes=[mistake("perpendicular-gradient", forms("1/3x+2", "-3x+2", "x/3+2"),
                                             next_step="The perpendicular gradient is flipped and has the opposite sign.",
                                             examples=["y = 1/3x + 2", "y = −3x + 2"])]),
                       answer="y = −1/3x + 2", working="m = −1/3 and c = 2, so y = −1/3x + 2."),
        ]),
    "q-oup-ch14-wb-challenge": stuck_sheet(
        "Find where the lines y = 2x − 1 and x + y = 8 cross.",
        [
            stuck_step("Put y = 2x − 1 into x + y = 8.",
                       one(forms("x+2x-1=8", "x+(2x-1)=8", "3x-1=8"), accepts=["x + 2x − 1 = 8"],
                           rejects=["x + 2x = 8", "2x - 1 = 8", "x + 2x + 1 = 8"]),
                       answer="x + 2x − 1 = 8", working="Replace y with 2x − 1 to get x + 2x − 1 = 8."),
            stuck_step("Solve it for x.",
                       one(num("3"), accepts=["3", "x = 3"], rejects=["7/3", "9", "2"],
                           mistakes=[mistake("rearranged-sign", num("7/3"),
                                             next_step="Add 1 to both sides, because it is being taken away.",
                                             examples=["x = 7/3"])]),
                       answer="x = 3", working="3x − 1 = 8, so 3x = 9 and x = 3."),
            stuck_step("Find y.",
                       one(num("5"), accepts=["5", "y = 5"], rejects=["3", "-5", "8"]),
                       answer="y = 5", working="y = 8 − 3 = 5."),
            stuck_step("Write the point where they cross.",
                       one(seq("3", "5"), accepts=["(3, 5)"], rejects=["(5, 3)", "(3, 8)", "(9, 5)"],
                           mistakes=[mistake("swapped-coordinates", seq("5", "3"),
                                             next_step="Write x first, then y.", examples=["(5, 3)"])]),
                       answer="(3, 5)", working="x = 3 and y = 5, so the point is (3, 5)."),
        ]),
    # Chapter 15
    "q-oup-ch15-sb": stuck_sheet(
        "A trait is in 10% of a group of 100 people. A test finds 90% of the people who have it, and wrongly flags 10% of the people who do not. If someone tests positive, what is the chance they have the trait?",
        [
            stuck_step("How many of the 100 have the trait?",
                       one(num("10"), accepts=["10"], rejects=["90", "1", "100"]),
                       answer="10", working="10% of 100 is 10."),
            stuck_step("How many of those test positive?",
                       one(num("9"), accepts=["9"], rejects=["10", "90", "1"]),
                       answer="9", working="90% of 10 is 9."),
            stuck_step("How many people without the trait test positive?",
                       one(num("9"), accepts=["9"], rejects=["10", "90", "81"],
                           mistakes=[mistake("percent-of-wrong-amount", num("10"),
                                             next_step="Take the 10% of the people without the trait, not of everyone.",
                                             examples=["10"])]),
                       answer="9", working="90 people do not have it, and 10% of 90 is 9."),
            stuck_step("Out of everyone who tests positive, what fraction has the trait?",
                       one(num("1/2"), num("50"), accepts=["1/2", "9/18", "50%"], rejects=["9/10", "9/100", "1/10"],
                           mistakes=[mistake("conditional-reversed", num("9/10"), num("90"),
                                             next_step="You need the chance of the trait given a positive, so divide by everyone who tested positive.",
                                             examples=["9/10"]),
                                     mistake("wrong-total", num("9/100"),
                                             next_step="Divide by the people who tested positive, not by everyone.",
                                             examples=["9/100"])]),
                       answer="9/18 = 1/2", working="9 + 9 = 18 test positive and 9 of them have it, so 9/18 = 1/2."),
        ]),
    "q-oup-ch15-wb-focus": stuck_sheet(
        "Two fair six-sided dice are rolled. What is the probability that their total is 4?",
        [
            stuck_step("How many equally likely outcomes are there?",
                       one(num("36"), accepts=["36"], rejects=["12", "11", "6"],
                           mistakes=[mistake("unequal-outcomes", num("11"),
                                             next_step="Count each die's result separately: 6 ways for the first and 6 for the second.",
                                             examples=["11"])]),
                       answer="36", working="6 × 6 = 36."),
            stuck_step("List the outcomes that make 4, and count them.",
                       one(num("3"), accepts=["3", "(1, 3), (2, 2), (3, 1)"], rejects=["2", "4", "1"],
                           mistakes=[mistake("order-mixed", num("2"),
                                             next_step="One number on the first die and another on the second is different from the other way round.",
                                             examples=["2"])]),
                       answer="3", working="(1, 3), (2, 2) and (3, 1) make 4, so there are 3."),
            stuck_step("Find the probability.",
                       one(num("1/12", tolerance=0.001), accepts=["1/12", "3/36"], rejects=["1/11", "1/18", "3/11"],
                           mistakes=[mistake("unequal-outcomes", num("1/11", tolerance=0.001), num("3/11", tolerance=0.001),
                                             next_step="There are 36 outcomes, all equally likely, so divide by that.",
                                             examples=["1/11"]),
                                     mistake("order-mixed", num("1/18", tolerance=0.001),
                                             next_step="Count both orders of each pair.", examples=["1/18"])]),
                       answer="3/36 = 1/12", working="3/36 = 1/12."),
        ]),
    "q-oup-ch15-wb-practice": stuck_sheet(
        "A bag has 3 red and 2 blue marbles. Two are taken out without replacement. Find the probability that both are red.",
        [
            stuck_step("What is the chance the first is red?",
                       one(num("3/5"), accepts=["3/5", "0.6"], rejects=["2/5", "3/2", "1/3"]),
                       answer="3/5", working="3 of the 5 marbles are red, so 3/5."),
            stuck_step("One red is now out. What is the chance the second is red?",
                       one(num("1/2"), accepts=["1/2", "2/4"], rejects=["3/5", "2/5", "3/4"],
                           mistakes=[mistake("with-replacement", num("3/5"), num("3/4"),
                                             next_step="After one red is out, count the reds and the total again.",
                                             examples=["3/5"])]),
                       answer="2/4 = 1/2", working="2 red are left out of 4, so 2/4 = 1/2."),
            stuck_step("Multiply to find the chance both are red.",
                       one(num("3/10"), accepts=["3/10", "6/20", "0.3"], rejects=["9/25", "1/2", "11/10"],
                           mistakes=[mistake("with-replacement", num("9/25"),
                                             next_step="The second draw has one fewer marble, so use your second answer.",
                                             examples=["9/25"])]),
                       answer="3/10", working="3/5 × 1/2 = 3/10."),
        ]),
    "q-oup-ch15-wb-challenge": stuck_sheet(
        "How many teams of 2 can be chosen from 5 players?",
        [
            stuck_step("Pick a first player, then a second, in order. How many ways is that?",
                       one(num("20"), accepts=["20"], rejects=["10", "25", "9"]),
                       answer="20", working="5 choices and then 4 gives 5 × 4 = 20."),
            stuck_step("In how many orders can the same pair be picked?",
                       one(num("2"), accepts=["2"], rejects=["1", "4", "20"]),
                       answer="2", working="A then B, or B then A, makes 2 orders."),
            stuck_step("How many different teams are there?",
                       one(num("10"), accepts=["10"], rejects=["20", "40", "5"],
                           mistakes=[mistake("order-mixed", num("20"),
                                             next_step="A team is the same whichever order its players were picked in.",
                                             examples=["20"])]),
                       answer="10", working="20 ÷ 2 = 10."),
        ]),
    # Chapter 16
    "q-oup-ch16-sb": stuck_sheet(
        "Given column vectors a = (6, 8) and b = (2, −1), work out a − 2b and the magnitude |a|.",
        [
            stuck_step("Work out 2b.",
                       one(seq("4", "-2"), accepts=["(4, −2)"], rejects=["(4, 2)", "(2, -1)", "(4, -1)"],
                           mistakes=[mistake("sign-of-product", seq("4", "2"),
                                             next_step="A positive times a negative is negative.", examples=["(4, 2)"])]),
                       answer="(4, −2)", working="2 × 2 = 4 and 2 × −1 = −2."),
            stuck_step("Work out a − 2b.",
                       one(seq("2", "10"), accepts=["(2, 10)"], rejects=["(2, 6)", "(10, 6)", "(4, 9)"],
                           mistakes=[mistake("sign-of-product", seq("2", "6"),
                                             next_step="Taking away a negative is the same as adding it.", examples=["(2, 6)"])]),
                       answer="(2, 10)", working="6 − 4 = 2 and 8 − (−2) = 10."),
            stuck_step("For |a|, square each part of a and add.",
                       one(num("100"), accepts=["100"], rejects=["14", "28", "48"],
                           mistakes=[mistake("added-sides", num("14"),
                                             next_step="Square each part before you add.", examples=["14"])]),
                       answer="100", working="6² + 8² = 36 + 64 = 100."),
            stuck_step("Take the square root to find |a|.",
                       one(num("10"), accepts=["10", "|a| = 10"], rejects=["100", "14", "20"],
                           mistakes=[mistake("forgot-square-root", num("100"),
                                             next_step="That is |a| squared, so take the square root.", examples=["100"])]),
                       answer="|a| = 10", working="√100 = 10."),
        ]),
    "q-oup-ch16-wb-focus": stuck_sheet(
        "AB = (2, 1) and BC = (4, −4). Find the resultant vector AC.",
        [
            stuck_step("To go from A to C through B, do you add or subtract the two vectors?",
                       one(ADD_WORDS, accepts=["add"], rejects=["subtract", "take away", "minus"]),
                       answer="Add", working="Going A to B and then B to C means adding the two journeys."),
            stuck_step("Add the top numbers.",
                       one(num("6"), accepts=["6"], rejects=["-2", "2", "8"],
                           mistakes=[mistake("vector-combined-wrongly", num("-2"),
                                             next_step="Add the two journeys; do not take one from the other.", examples=["−2"])]),
                       answer="6", working="2 + 4 = 6."),
            stuck_step("Add the bottom numbers.",
                       one(num("-3"), accepts=["−3"], rejects=["3", "5", "-5"],
                           mistakes=[mistake("dropped-minus", num("3"),
                                             next_step="Adding a negative number moves you down.", examples=["3"]),
                                     mistake("vector-combined-wrongly", num("5"),
                                             next_step="Add the bottom numbers; do not subtract them.", examples=["5"])]),
                       answer="−3", working="1 + (−4) = −3."),
            stuck_step("Write AC.",
                       one(seq("6", "-3"), accepts=["(6, −3)"], rejects=["(-2, 5)", "(6, 3)", "(-3, 6)"],
                           mistakes=[mistake("vector-combined-wrongly", seq("-2", "5"),
                                             next_step="AC is AB followed by BC, so add them.", examples=["(−2, 5)"]),
                                     mistake("dropped-minus", seq("6", "3"),
                                             next_step="Keep the minus sign on the bottom number.", examples=["(6, 3)"])]),
                       answer="(6, −3)", working="The top is 6 and the bottom is −3, so AC = (6, −3)."),
        ]),
    "q-oup-ch16-wb-practice": stuck_sheet(
        "In triangle OPQ, OP = p and OQ = q. M is the midpoint of OP. Express MQ in terms of p and q.",
        [
            stuck_step("Write OM in terms of p.",
                       one(forms("1/2p", "p/2", "0.5p", "(1/2)p"), accepts=["½p", "OM = ½p"], rejects=["p", "2p", "-1/2p"],
                           mistakes=[mistake("forgot-half", forms("p", "om=p"),
                                             next_step="M is halfway along OP, so OM is only part of it.", examples=["p"])]),
                       answer="OM = ½p", working="M is halfway along OP, so OM = ½p."),
            stuck_step("Write MO, going back the other way.",
                       one(forms("-1/2p", "-p/2", "-0.5p", "-(1/2)p"), accepts=["−½p"], rejects=["½p", "-p", "-2p"],
                           mistakes=[mistake("vector-combined-wrongly", forms("1/2p", "p/2", "0.5p"),
                                             next_step="Going the opposite way changes the sign of the vector.", examples=["½p"])]),
                       answer="MO = −½p", working="Going backwards flips the sign, so MO = −½p."),
            stuck_step("Find MQ by going from M to O and then from O to Q.",
                       one(forms("-1/2p+q", "q-1/2p", "-p/2+q", "q-p/2", "-0.5p+q", "q-0.5p", "1/2(2q-p)"),
                           accepts=["MQ = q − ½p", "−½p + q"], rejects=["½p + q", "q - p", "p - q"],
                           mistakes=[mistake("vector-combined-wrongly", forms("1/2p+q", "q+1/2p", "p/2+q", "q+p/2", "1/2p-q", "p/2-q"),
                                             next_step="MQ starts by heading back from M to O, the opposite of OM.",
                                             examples=["½p + q"]),
                                     mistake("forgot-half", forms("q-p", "-p+q"),
                                             next_step="M is the midpoint, so the step from M to O is only half of p.",
                                             examples=["q − p"])]),
                       answer="MQ = −½p + q", working="MQ = MO + OQ, which is −½p + q."),
        ]),
    "q-oup-ch16-wb-challenge": stuck_sheet(
        "A triangle of area 4 cm² is transformed by the matrix A = [[2, 1], [1, 3]]. Find det(A) = ad − bc and the new area.",
        [
            stuck_step("Work out ad, the top-left number times the bottom-right one.",
                       one(num("6"), accepts=["6"], rejects=["2", "3", "5"]),
                       answer="6", working="2 × 3 = 6."),
            stuck_step("Work out bc, the other two numbers multiplied.",
                       one(num("1"), accepts=["1"], rejects=["2", "0", "6"]),
                       answer="1", working="1 × 1 = 1."),
            stuck_step("Find the determinant, ad − bc.",
                       one(num("5"), accepts=["5", "det = 5"], rejects=["7", "6", "-5"],
                           mistakes=[mistake("dropped-minus", num("7"),
                                             next_step="The determinant takes bc away from ad.", examples=["7"])]),
                       answer="det(A) = 5", working="6 − 1 = 5."),
            stuck_step("The determinant scales area. Find the new area.",
                       one(num("20"), accepts=["20", "20 cm²"], rejects=["28", "9", "5"],
                           mistakes=[mistake("dropped-minus", num("28"),
                                             next_step="Check the determinant first: it is ad minus bc.", examples=["28"])]),
                       answer="20 cm²", working="4 × 5 = 20 cm²."),
        ]),
}


def _words_only(answer_key):
    return any(all(m["kind"] == "words" for m in part_["anyOf"]) for part_ in answer_key["parts"])


def _magnitudes(answer_key):
    found = set()

    def visit(matcher):
        if matcher["kind"] == "number":
            found.add(abs(marking.number(matcher["value"])))
        elif matcher["kind"] == "sequence":
            found.update(abs(marking.number(v)) for v in matcher["values"])
        elif matcher["kind"] == "form":
            found.update(abs(value) for value, _ in marking.AnswerText(matcher["value"]).numbers)
        elif matcher["kind"] == "all":
            for inner in matcher["of"]:
                visit(inner)

    for part_ in answer_key["parts"]:
        for matcher in part_["anyOf"]:
            visit(matcher)
    return found


def build_stuck_sheets(questions):
    by_id = {question["id"]: question for question in questions}
    unknown = sorted(set(STUCK_SHEETS) - set(by_id))
    if unknown:
        raise SystemExit(f"Stuck sheets for unknown questions: {unknown}")
    missing = sorted(qid for qid, question in by_id.items()
                     if qid not in STUCK_SHEETS and not _words_only(question["answerKey"]))
    if missing:
        raise SystemExit(f"Questions marked by a number, sequence or form need a stuck sheet: {missing}")

    sheets = {}
    for qid, spec in STUCK_SHEETS.items():
        original = by_id[qid]["answerKey"]
        if not 3 <= len(spec["steps"]) <= 5:
            raise SystemExit(f"{qid} stuck sheet needs 3 to 5 steps, has {len(spec['steps'])}")
        shown = [("sister", spec["sister"])]
        steps = []
        for n, step in enumerate(spec["steps"], start=1):
            step_id = f"{qid}-step-{n}"
            step_key = step["answerKey"]
            if not step["working"].endswith("."):
                raise SystemExit(f"{step_id} working must be one sentence ending in a full stop")
            if len(step_key["rejects"]) < 3:
                raise SystemExit(f"{step_id} needs at least 3 wrong samples")
            for answer in [step["answer"], *step_key["accepts"]]:
                if not marking.mark(step_key, answer)[0]:
                    raise SystemExit(f"{step_id} key rejects its own answer \"{answer}\"")
            for answer in [*step_key["rejects"], "", step["prompt"]]:
                if marking.mark(step_key, answer)[0]:
                    raise SystemExit(f"{step_id} key accepts \"{answer}\"")
            answer_numbers = _magnitudes(step_key)
            for slip in step_key["mistakes"]:
                for example in slip["examples"]:
                    if marking.mark(step_key, example) != (False, slip["misconception"]):
                        raise SystemExit(f"{step_id} example \"{example}\" does not name {slip['misconception']}")
                shared = answer_numbers & {abs(value) for value, _ in marking.AnswerText(slip["nextStep"]).numbers}
                if shared:
                    raise SystemExit(f"{step_id} {slip['misconception']} next step shows {sorted(map(str, shared))}")
                next_text = marking.AnswerText(slip["nextStep"])
                if any(marking.matches(m, next_text) for part_ in step_key["parts"] for m in part_["anyOf"]):
                    raise SystemExit(f"{step_id} {slip['misconception']} next step is itself a right answer")
                shown.append((f"{step_id} {slip['misconception']} next step", slip["nextStep"]))
            shown += [(f"{step_id} prompt", step["prompt"]), (f"{step_id} answer", step["answer"]),
                      (f"{step_id} working", step["working"])]
            steps.append({"id": step_id, **step})
        for where, text in shown:
            if marking.gives_away(original, text):
                raise SystemExit(f"{qid} stuck sheet gives the answer away in its {where}: {text}")
        sheets[qid] = {"sister": spec["sister"], "steps": steps}
    return sheets


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
            "Find the exact circumference and area of a circle of radius r = 7 cm (use π ≈ 22/7).",
            "C = 44 cm, A = 154 cm²",
            "A parallelogram has base 14 cm, slanted side 10 cm, and perpendicular height 8 cm. Calculate its perimeter and its area.",
            "Perimeter = 48 cm, Area = 112 cm²",
            "A circular pizza of radius 10 cm is cut into 6 equal sectors. Find the perimeter of one sector to 1 decimal place.",
            "30.5 cm"
        ),
        (
            6, "6.3", 2, "w_recurring_decimal_tail_canceller",
            "Prove algebraically that the recurring decimal x = 0.272727… (0.2̇7̇) equals 3/11 in simplest form.",
            "Step 1: Let x = 0.272727… (period k = 2 digits).\nStep 2: Multiply by 10² = 100: 100x = 27.272727…\nStep 3: Subtract x: 99x = 27 ⇒ x = 27/99 = 3/11.",
            "100x = 27.2727… and x = 0.2727…, so 99x = 27 and x = 27/99 = ___.",
            "3/11",
            "3/11 because 100x − x = 99x = 27, so x = 27/99 which simplifies on dividing by 9 to 3/11.",
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
        sb_prompt, sb_worked, sb_faded, sb_faded_ans, sb_model,
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
            "linkedChapter": ch_num,
            "linkedWidget": wid,
        })
    question_ids = {question["id"] for question in questions}
    # A chapter file's worked example and faded prompt replace these before the answer keys and stuck sheets are attached.
    authored = book_school_questions()
    unknown = sorted(set(authored) - question_ids)
    if unknown:
        raise SystemExit(f"schoolQuestions for unknown question ids: {unknown}")
    for qid, fields in sorted(authored.items()):
        extra = sorted(set(fields) - SCHOOL_QUESTION_FIELDS)
        if extra:
            raise SystemExit(f"schoolQuestions \"{qid}\" writes {extra}; a chapter file may write only "
                             f"{sorted(SCHOOL_QUESTION_FIELDS)}")
    for question in questions:
        question.update(authored.get(question["id"], {}))
    if question_ids != set(ANSWER_KEYS):
        raise SystemExit(f"Answer keys and questions differ: {sorted(question_ids ^ set(ANSWER_KEYS))}")
    for question in questions:
        question["answerKey"] = ANSWER_KEYS[question["id"]]
    stuck_sheets = build_stuck_sheets(questions)
    for question in questions:
        if question["id"] in stuck_sheets:
            question["stuck"] = stuck_sheets[question["id"]]
    used = {m["misconception"] for answer_key in ANSWER_KEYS.values() for m in answer_key["mistakes"]}
    if used != set(MISCONCEPTIONS):
        raise SystemExit(f"Misconceptions no question uses: {sorted(set(MISCONCEPTIONS) - used)}")
    return questions


def build_misconceptions():
    if set(STANDS_ON) != set(MISCONCEPTIONS):
        raise SystemExit(f"Misconceptions without a footing, or unknown ones: {sorted(set(STANDS_ON) ^ set(MISCONCEPTIONS))}")
    unknown = sorted(set(STANDS_ON.values()) - set(FOOTINGS))
    if unknown:
        raise SystemExit(f"Unknown footing ids: {unknown}")
    return [
        {"id": misconception_id, "name": name, "standsOn": STANDS_ON[misconception_id]}
        for misconception_id, name in MISCONCEPTIONS.items()
    ]


def build_footings():
    unused = sorted(set(FOOTINGS) - set(STANDS_ON.values()))
    if unused:
        raise SystemExit(f"Footings no misconception stands on: {unused}")
    footings = []
    for footing_id, spec in FOOTINGS.items():
        if len(spec["probes"]) != 3:
            raise SystemExit(f"Footing {footing_id} needs exactly 3 probes, has {len(spec['probes'])}")
        if not spec["teach"].endswith("."):
            raise SystemExit(f"Footing {footing_id} teach must end in a full stop")
        probes = [{"id": f"{footing_id}-{n}", **p} for n, p in enumerate(spec["probes"], start=1)]
        footings.append({"id": footing_id, "skill": spec["skill"], "teach": spec["teach"], "probes": probes})
    return footings


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
    overrides = book_tips()
    return [{**tip, **overrides.get(tip["id"], {})} for tip in _visual_math_tips()]


def _visual_math_tips():
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
            "title": "Why a Positive Result from a 95% Accurate Test Is Wrong 72% of the Time",
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
            "ahaMoment": "The unit 1×1 square deforms into a parallelogram whose bounding box (a+b)(c+d), minus four right triangles and two b×c rectangles, leaves exact area ad − bc!",
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
#atlas-card[hidden] {{ display: none; }}
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
  cursor: pointer;
  transition: transform 0.15s ease, box-shadow 0.15s ease;
}}
.term-pill.active-role {{
  transform: translateY(-1px);
  box-shadow: 0 0 0 2px var(--ink);
  font-weight: 600;
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

<section class="card" id="atlas-card" hidden>
  <div style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:8px;margin-bottom:10px;">
    <div>
      <div class="kicker">3 · EMBEDDED @SAXSTER/ATLAS 3D/2D TEACHING STAGE (../visualisations/atlas)</div>
      <div style="font-size:13px;color:var(--muted);" id="atlas-caption">Drag to turn the figure. Tap a part to look closer.</div>
    </div>
    <div style="display:flex;gap:8px;flex-wrap:wrap;">
      <button class="btn secondary" id="btn-stage-primary">3D Chapter Apparatus</button>
      <button class="btn secondary" id="btn-stage-companion">Companion Deep-Dive Book</button>
      <button class="btn secondary" id="btn-reload-atlas">Reset 3D Camera</button>
    </div>
  </div>
  <iframe class="atlas-frame" id="atlas-iframe" title="Atlas 3D Figure" src="./atlas/examples/maths/ch00-sets-logic/index.html"></iframe>
</section>

<script>
const CHAPTERS = {chapters_json};
const EXPLORERS = {explorers_json};
let currentChapter = 0;

const COMPANION_BOOKS = {{
  0: 'concepts/index.html#maths',
  1: 'concepts/index.html#exponential',
  2: 'concepts/index.html#maths',
  3: 'economics/compound/index.html',
  4: 'maths/linear-algebra/index.html',
  5: 'concepts/index.html#balance',
  6: 'concepts/index.html#maths',
  7: 'concepts/index.html#slope',
  8: 'maths/unit-circle/index.html',
  9: 'maths/cross-sections/index.html',
  10: 'maths/cross-sections/index.html',
  11: 'maths/linear-algebra/index.html#1',
  12: 'maths/unit-circle/index.html',
  13: 'statistics/error/index.html',
  14: 'statistics/hypothesis/index.html',
  15: 'statistics/galton/index.html',
  16: 'statistics/bayes/index.html',
  17: 'maths/calculus/index.html',
  18: 'maths/calculus/index.html#3',
  19: 'maths/multivariable/index.html#2',
  20: 'maths/matrix-sandbox/index.html',
}};

const CH_SLIDERS = {{
  0:  [{{lbl:'In A (cricket):',min:8,max:22,step:1,val:18,u:''}}, {{lbl:'In B (football):',min:6,max:20,step:1,val:15,u:''}}, {{lbl:'In both:',min:0,max:20,step:1,val:7,u:''}}],
  1:  [{{lbl:'First number:',min:6,max:48,step:6,val:24,u:''}}, {{lbl:'Second number:',min:6,max:60,step:6,val:36,u:''}}, {{lbl:'Turns:',min:0,max:2,step:1,val:2,u:''}}],
  2:  [{{lbl:'Repeating digits:',min:9,max:81,step:9,val:36,u:''}}, {{lbl:'Whole number:',min:1,max:5,step:1,val:3,u:''}}, {{lbl:'Bottom of the fraction:',min:2,max:6,step:1,val:4,u:''}}],
  3:  [{{lbl:'Parts for A:',min:1,max:6,step:1,val:3,u:''}}, {{lbl:'Parts for B:',min:2,max:8,step:1,val:5,u:''}}, {{lbl:'Interest rate:',min:4,max:15,step:1,val:8,u:'%'}}],
  4:  [{{lbl:'Side x:',min:3,max:6,step:1,val:4,u:''}}, {{lbl:'First number:',min:1,max:3,step:1,val:3,u:''}}, {{lbl:'Second number:',min:1,max:3,step:1,val:2,u:''}}],
  5:  [{{lbl:'Bags:',min:2,max:6,step:1,val:4,u:''}}, {{lbl:'Loose marbles:',min:1,max:9,step:1,val:3,u:''}}, {{lbl:'Marbles in a bag:',min:1,max:5,step:1,val:3,u:''}}],
  6:  [{{lbl:'Number of terms:',min:3,max:8,step:1,val:5,u:''}}, {{lbl:'First term:',min:1,max:4,step:1,val:1,u:''}}, {{lbl:'Common difference:',min:1,max:3,step:1,val:1,u:''}}],
  7:  [{{lbl:'Gradient:',min:-3,max:3,step:0.5,val:2,u:''}}, {{lbl:'Crosses the y-axis at:',min:-3,max:3,step:1,val:1,u:''}}, {{lbl:'Step across:',min:1,max:3,step:1,val:1,u:''}}],
  8:  [{{lbl:'Angle at A:',min:30,max:65,step:5,val:50,u:'°'}}, {{lbl:'Angle at B:',min:30,max:65,step:5,val:60,u:'°'}}, {{lbl:'Sides of the shape:',min:3,max:8,step:1,val:6,u:''}}],
  9:  [{{lbl:'Length of AB:',min:4,max:8,step:1,val:6,u:' cm'}}, {{lbl:'Compass opening:',min:2,max:5,step:0.5,val:4,u:' cm'}}, {{lbl:'Height of P above AB:',min:0,max:4,step:1,val:2,u:' cm'}}],
  10: [{{lbl:'Radius:',min:2,max:6,step:1,val:4,u:' cm'}}, {{lbl:'Number of slices:',min:4,max:24,step:2,val:12,u:''}}, {{lbl:'Angle of the green slice:',min:0,max:360,step:30,val:90,u:'°'}}],
  11: [{{lbl:'Scale factor:',min:0.5,max:3,step:0.5,val:2,u:''}}, {{lbl:'Centre across:',min:0,max:3,step:1,val:0,u:''}}, {{lbl:'Centre up:',min:0,max:2,step:1,val:0,u:''}}],
  12: [{{lbl:'Leg a:',min:3,max:8,step:1,val:3,u:''}}, {{lbl:'Leg b:',min:3,max:8,step:1,val:4,u:''}}, {{lbl:'Angle θ:',min:0,max:360,step:15,val:50,u:'°'}}],
  13: [{{lbl:'Pop SD σ:',min:6,max:24,step:2,val:12,u:''}}, {{lbl:'Sample size n:',min:4,max:64,step:4,val:16,u:''}}, {{lbl:'Engine hits:',min:0,max:5,step:1,val:1,u:''}}],
  14: [{{lbl:'Wide bin Δx₃:',min:10,max:40,step:5,val:25,u:'min'}}, {{lbl:'Wide bin freq f₃:',min:15,max:60,step:5,val:30,u:''}}, {{lbl:'IQR Q₃ − Q₁:',min:10,max:30,step:2,val:18,u:''}}],
  15: [{{lbl:'Galton rows n:',min:4,max:10,step:1,val:6,u:''}}, {{lbl:'Successes k:',min:0,max:6,step:1,val:3,u:''}}, {{lbl:'Drop prob p:',min:30,max:70,step:10,val:50,u:'%'}}],
  16: [{{lbl:'Prevalence p:',min:1,max:20,step:1,val:2,u:'%'}}, {{lbl:'Sensitivity:',min:80,max:99,step:1,val:95,u:'%'}}, {{lbl:'False-pos rate:',min:1,max:20,step:1,val:5,u:'%'}}],
  17: [{{lbl:'Anchor x₀:',min:0.5,max:2.5,step:0.25,val:1.25,u:''}}, {{lbl:'Step h = Δx:',min:0.05,max:1.0,step:0.05,val:0.45,u:''}}, {{lbl:'Square side x:',min:1,max:4,step:0.5,val:2,u:''}}],
  18: [{{lbl:'Upper bound x:',min:1.0,max:3.0,step:0.2,val:2.4,u:''}}, {{lbl:'Riemann slabs N:',min:4,max:20,step:2,val:8,u:''}}, {{lbl:'Slope rate k:',min:0.5,max:1.5,step:0.25,val:1.0,u:''}}],
  19: [{{lbl:'Vector a_x:',min:1,max:5,step:0.5,val:3.5,u:''}}, {{lbl:'Vector b_x:',min:1,max:4,step:0.5,val:2.0,u:''}}, {{lbl:'Angle between:',min:0,max:120,step:15,val:60,u:'°'}}],
  20: [{{lbl:'Col 1 x (a):',min:0.5,max:2.5,step:0.25,val:2.0,u:''}}, {{lbl:'Off-diag (b=c):',min:-1.5,max:1.5,step:0.25,val:1.0,u:''}}, {{lbl:'Col 2 y (d):',min:0.5,max:2.5,step:0.25,val:2.0,u:''}}],
}};

function applyChapterSliders(chNum) {{
  const specs = CH_SLIDERS[chNum] || CH_SLIDERS[0];
  ['a', 'b', 'c'].forEach((k, idx) => {{
    const s = specs[idx];
    const inp = document.getElementById(`param-${{k}}`);
    document.getElementById(`lbl-${{k}}`).textContent = s.lbl;
    inp.min = s.min; inp.max = s.max; inp.step = s.step; inp.value = s.val;
    inp.dataset.unit = s.u || '';
  }});
}}

function parseHash() {{
  const h = (window.location.hash || '').replace('#', '');
  if (h.startsWith('ch')) {{
    const n = parseInt(h.slice(2), 10);
    if (!isNaN(n) && n >= 0 && n < CHAPTERS.length) currentChapter = n;
  }}
}}

function setAtlasRoute(relPath) {{
  const iframe = document.getElementById('atlas-iframe');
  const targetSrc = `./atlas/examples/${{relPath}}`;
  if (iframe.getAttribute('data-src') !== targetSrc) {{
    iframe.setAttribute('data-src', targetSrc);
    document.getElementById('atlas-card').hidden = true;
    iframe.src = targetSrc;
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
    `<div class="term-pill ${{tm.colorRole}}" data-role="${{tm.colorRole}}" data-symbol="${{tm.symbol}}"><b>${{tm.symbol}}</b> → ${{tm.visualPart}}: ${{tm.meaning}}</div>`
  ).join('');
  termsEl.querySelectorAll('.term-pill').forEach(pill => {{
    pill.addEventListener('click', () => {{
      const role = pill.getAttribute('data-role') || '';
      const sym = pill.getAttribute('data-symbol') || '';
      window.highlightFormulaTerm(role);
      if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.kymmathsBridge) {{
        window.webkit.messageHandlers.kymmathsBridge.postMessage({{ type: 'termHighlighted', colorRole: role, symbol: sym }});
      }}
    }});
  }});

  applyChapterSliders(ch.number);
  setAtlasRoute(br.atlasFigureRef);
  drawSandbox();
}}

window.highlightedRole = null;
window.highlightFormulaTerm = function(role) {{
  window.highlightedRole = role || null;
  document.querySelectorAll('.term-pill').forEach(pill => {{
    if (role && pill.getAttribute('data-role') === role) {{
      pill.classList.add('active-role');
    }} else {{
      pill.classList.remove('active-role');
    }}
  }});
  drawSandbox();
}};

window.selectChapter = function(n) {{
  const idx = Math.max(0, Math.min(CHAPTERS.length - 1, parseInt(n, 10) || 0));
  if (currentChapter !== idx) {{
    currentChapter = idx;
    renderChapter();
  }}
}};

function gcd(x, y) {{
  let a = Math.abs(Math.round(x)), b = Math.abs(Math.round(y));
  while (b !== 0) {{ const t = b; b = a % b; a = t; }}
  return Math.max(1, a);
}}

function comb(n, k) {{
  if (k < 0 || k > n) return 0;
  let res = 1;
  for (let i = 1; i <= k; i++) res = (res * (n - i + 1)) / i;
  return Math.round(res);
}}

function drawArrow(ctx, x1, y1, x2, y2, color, lw = 2.5) {{
  const dx = x2 - x1, dy = y2 - y1, ang = Math.atan2(dy, dx);
  ctx.save();
  ctx.strokeStyle = color; ctx.fillStyle = color; ctx.lineWidth = lw;
  ctx.beginPath(); ctx.moveTo(x1, y1); ctx.lineTo(x2, y2); ctx.stroke();
  ctx.beginPath();
  ctx.moveTo(x2, y2);
  ctx.lineTo(x2 - 9 * Math.cos(ang - 0.42), y2 - 9 * Math.sin(ang - 0.42));
  ctx.lineTo(x2 - 9 * Math.cos(ang + 0.42), y2 - 9 * Math.sin(ang + 0.42));
  ctx.closePath(); ctx.fill();
  ctx.restore();
}}

function drawSandbox() {{
  const ch = CHAPTERS[currentChapter] || CHAPTERS[0];
  const inpA = document.getElementById('param-a');
  const inpB = document.getElementById('param-b');
  const inpC = document.getElementById('param-c');
  const a = parseFloat(inpA.value);
  const b = parseFloat(inpB.value);
  const c = parseFloat(inpC.value);
  document.getElementById('val-a').textContent = a + (inpA.dataset.unit || '');
  document.getElementById('val-b').textContent = b + (inpB.dataset.unit || '');
  document.getElementById('val-c').textContent = c + (inpC.dataset.unit || '');

  const canvas = document.getElementById('sim-canvas');
  const dpr = Math.min(window.devicePixelRatio || 1, 2);
  const cssW = canvas.clientWidth || 560;
  const cssH = canvas.clientHeight || 290;
  if (canvas.width !== Math.round(cssW * dpr) || canvas.height !== Math.round(cssH * dpr)) {{
    canvas.width = Math.round(cssW * dpr);
    canvas.height = Math.round(cssH * dpr);
  }}
  const ctx = canvas.getContext('2d');
  ctx.save();
  ctx.scale(dpr, dpr);
  const w = cssW, h = cssH;
  ctx.clearRect(0, 0, w, h);

  const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
  const red = isDark ? '#FF7A70' : '#C83E37';
  const blue = isDark ? '#68B0F8' : '#2E66B8';
  const amber = isDark ? '#F5B945' : '#C88A1E';
  const green = isDark ? '#4ADE9B' : '#1E7A50';
  const ink = isDark ? '#F5F2FC' : '#1C1726';
  const muted = isDark ? '#A6A0BE' : '#5D566B';

  ctx.font = '600 12.5px -apple-system, BlinkMacSystemFont, sans-serif';
  let readoutHtml = '';

  switch (ch.number) {{
    case 0: {{
      // Ch 0: two circles in a class of 30. The middle can't be more than the smaller circle,
      // and can't be so small that the two circles hold more than 30 between them.
      const A = Math.round(a), B = Math.round(b);
      const least = Math.max(0, A + B - 30), most = Math.min(A, B);
      const inter = Math.min(most, Math.max(least, Math.round(c)));
      if (inter !== Math.round(c)) {{
        inpC.value = inter;
        document.getElementById('val-c').textContent = inter + (inpC.dataset.unit || '');
      }}
      const onlyA = A - inter, onlyB = B - inter;
      const union = onlyA + onlyB + inter;
      const outside = 30 - union;
      ctx.strokeStyle = green; ctx.fillStyle = green + '14'; ctx.lineWidth = 2;
      ctx.fillRect(24, 22, w - 48, h - 44); ctx.strokeRect(24, 22, w - 48, h - 44);
      ctx.fillStyle = green; ctx.fillText(`All 30 students · outside both circles: ${{outside}}`, 36, 44);
      const cxA = w * 0.39, cxB = w * 0.59, cy = h * 0.56, r = 74;
      ctx.fillStyle = red + '28'; ctx.strokeStyle = red; ctx.lineWidth = 2.5;
      ctx.beginPath(); ctx.arc(cxA, cy, r, 0, Math.PI * 2); ctx.fill(); ctx.stroke();
      ctx.fillStyle = blue + '28'; ctx.strokeStyle = blue;
      ctx.beginPath(); ctx.arc(cxB, cy, r, 0, Math.PI * 2); ctx.fill(); ctx.stroke();
      ctx.fillStyle = red; ctx.fillText('A · cricket', cxA - r - 10, cy - r - 10);
      ctx.fillStyle = blue; ctx.fillText('B · football', cxB + r - 60, cy - r - 10);
      ctx.fillStyle = red; ctx.fillText(`A only: ${{onlyA}}`, cxA - 60, cy + 4);
      ctx.fillStyle = amber; ctx.fillText(`Both: ${{inter}}`, (cxA + cxB) / 2 - 22, cy + 4);
      ctx.fillStyle = blue; ctx.fillText(`B only: ${{onlyB}}`, cxB + 12, cy + 4);
      const limit = inter === least && least > 0
        ? `<br>The middle can't go below ${{A}} + ${{B}} − 30 = ${{least}}, or the circles would hold more than 30 students.`
        : '';
      readoutHtml = `In A: ${{A}} · In B: ${{B}} · In both: ${{inter}}<br><b>In at least one: ${{A}} + ${{B}} − ${{inter}} = ${{union}}</b> · Outside both: <b>${{outside}}</b>${{limit}}`;
      break;
    }}
    case 1: {{
      // Ch 1: turning round on the number line, and the HCF and LCM bars
      const A = Math.round(a), B = Math.round(b), flips = Math.round(c);
      const hcf = gcd(A, B), lcm = (A * B) / hcf;
      const yLine = 88, cx = w * 0.5;
      drawArrow(ctx, 40, yLine, w - 40, yLine, muted, 1.8);
      ctx.fillStyle = ink; ctx.fillText('0', cx - 4, yLine + 18);
      const dir = flips % 2 === 0 ? 1 : -1;
      drawArrow(ctx, cx, yLine, cx + dir * 120, yLine, dir > 0 ? green : red, 3.2);
      for (let f = 0; f < flips; f++) {{
        ctx.strokeStyle = amber; ctx.lineWidth = 2;
        ctx.beginPath(); ctx.arc(cx, yLine, 42 + f * 18, f * Math.PI, (f + 1) * Math.PI, true); ctx.stroke();
      }}
      const facing = `${{flips}} turn${{flips === 1 ? '' : 's'}}: facing ${{dir > 0 ? 'forward (+)' : 'backward (−)'}}`;
      ctx.fillStyle = amber; ctx.fillText(facing, 36, 34);
      // HCF & LCM bars
      ctx.fillStyle = blue + '33'; ctx.strokeStyle = blue; ctx.lineWidth = 2;
      ctx.fillRect(48, 155, 190, 44); ctx.strokeRect(48, 155, 190, 44);
      ctx.fillStyle = blue; ctx.fillText(`HCF(${{A}}, ${{B}}) = ${{hcf}}`, 64, 182);
      ctx.fillStyle = amber + '33'; ctx.strokeStyle = amber;
      ctx.fillRect(260, 155, 240, 44); ctx.strokeRect(260, 155, 240, 44);
      ctx.fillStyle = amber; ctx.fillText(`LCM(${{A}}, ${{B}}) = ${{lcm}}`, 276, 182);
      ctx.fillStyle = green; ctx.fillText(`Check: HCF × LCM = ${{hcf}} × ${{lcm}} = ${{hcf * lcm}} = ${{A}} × ${{B}}`, 48, 232);
      readoutHtml = `${{facing}} · <b>HCF(${{A}}, ${{B}}) = ${{hcf}}</b> and <b>LCM(${{A}}, ${{B}}) = ${{lcm}}</b> · Check: HCF × LCM = ${{hcf}} × ${{lcm}} = ${{hcf * lcm}} = ${{A}} × ${{B}}`;
      break;
    }}
    case 2: {{
      // Ch 2: take the number away from 100 lots of it, and count how many pieces of a fraction fit
      const blk = Math.round(a), g = gcd(blk, 99), sNum = blk / g, sDen = 99 / g;
      const bStr = String(blk).padStart(2, '0');
      ctx.fillStyle = red + '28'; ctx.strokeStyle = red; ctx.lineWidth = 2;
      ctx.fillRect(42, 42, w - 84, 42); ctx.strokeRect(42, 42, w - 84, 42);
      ctx.fillStyle = red; ctx.fillText(`100 × the number = ${{blk}}.${{bStr}}${{bStr}}${{bStr}}…`, 56, 68);
      ctx.fillStyle = blue + '28'; ctx.strokeStyle = blue;
      ctx.fillRect(118, 96, w - 160, 42); ctx.strokeRect(118, 96, w - 160, 42);
      ctx.fillStyle = blue; ctx.fillText(`− 1 × the number = 0.${{bStr}}${{bStr}}${{bStr}}…`, 128, 122);
      ctx.fillStyle = green + '28'; ctx.strokeStyle = green;
      ctx.fillRect(42, 154, w - 84, 44); ctx.strokeRect(42, 154, w - 84, 44);
      ctx.fillStyle = green; ctx.fillText(`99 × the number = ${{blk}}, so it is ${{blk}}/99 = ${{sNum}}/${{sDen}}`, 56, 181);
      const q = (b * c) / 2;
      ctx.fillStyle = amber; ctx.fillText(`How many pieces of 2/${{c}} fit in ${{b}}? ${{b}} ÷ 2/${{c}} = ${{b}} × ${{c}}/2 = ${{q}}`, 42, 235);
      readoutHtml = `100 lots take away 1 lot leaves 99 lots, so 99 × the number = ${{blk}} and <b>0.${{bStr}}${{bStr}}… = ${{sNum}}/${{sDen}}</b> · Dividing: <b>${{b}} ÷ 2/${{c}} = ${{b}} × ${{c}}/2 = ${{q}}</b>`;
      break;
    }}
    case 3: {{
      // Ch 3: sharing in a ratio with bars of equal parts, and ₹1,000 left for 20 years
      const pA = Math.round(a), pB = Math.round(b), rate = c / 100;
      // Each bar's label sits above it, and every text line is short, so nothing runs off a phone's narrow canvas
      const uW = 26, yA = 40, yB = 96;
      const parts = (n) => `${{n}} ${{n === 1 ? 'part' : 'parts'}}`;
      ctx.fillStyle = red; ctx.fillText(`A: ${{parts(pA)}} = ₹${{pA * 40}}`, 46, yA - 8);
      for (let i = 0; i < pA; i++) {{
        ctx.fillStyle = red + '30'; ctx.strokeStyle = red; ctx.lineWidth = 2;
        ctx.fillRect(46 + i * (uW + 4), yA, uW, uW); ctx.strokeRect(46 + i * (uW + 4), yA, uW, uW);
      }}
      ctx.fillStyle = blue; ctx.fillText(`B: ${{parts(pB)}} = ₹${{pB * 40}}`, 46, yB - 8);
      for (let i = 0; i < pB; i++) {{
        ctx.fillStyle = blue + '30'; ctx.strokeStyle = blue; ctx.lineWidth = 2;
        ctx.fillRect(46 + i * (uW + 4), yB, uW, uW); ctx.strokeRect(46 + i * (uW + 4), yB, uW, uW);
      }}
      ctx.fillStyle = muted; ctx.fillText(`1 part = ₹40 · ${{pA + pB}} parts = ₹${{(pA + pB) * 40}}`, 46, 150);
      // What ₹1,000 grows to in 20 years
      const simp20 = 1000 * (1 + 20 * rate), comp20 = 1000 * Math.pow(1 + rate, 20);
      const rupees = (x) => '₹' + Math.round(x).toLocaleString('en-IN');
      ctx.fillStyle = amber; ctx.fillText(`₹1,000 for 20 years at ${{c}}%`, 46, 178);
      ctx.fillText(`simple interest: ${{rupees(simp20)}}`, 46, 196);
      ctx.fillText(`compound interest: ${{rupees(comp20)}}`, 46, 214);
      ctx.fillStyle = green; ctx.fillText('Up 20%, then down 20%:', 46, 242);
      ctx.fillText('1.2 × 0.8 = 0.96', 46, 260);
      readoutHtml = `A : B = ${{pA}} : ${{pB}} and 1 part = ₹40, so A gets <b>₹${{pA * 40}}</b> and B gets <b>₹${{pB * 40}}</b> · ₹1,000 at ${{c}}% for 20 years: <b>${{rupees(comp20)}}</b> with compound interest, ${{rupees(simp20)}} with simple interest`;
      break;
    }}
    case 4: {{
      // Ch 4: the rectangle (x + p)(x + q) cut into four pieces, and x² − p² from the same side and first number
      const x = Math.round(a), p = Math.round(b), q = Math.round(c), u = 16, x0 = 46, y0 = 26;
      const centre = (text, cx, cy) => ctx.fillText(text, cx - ctx.measureText(text).width / 2, cy + 4);
      const piece = (px, py, pw, ph, colour, alpha, label) => {{
        ctx.fillStyle = colour + alpha; ctx.strokeStyle = colour; ctx.lineWidth = 2;
        ctx.fillRect(px, py, pw, ph); ctx.strokeRect(px, py, pw, ph);
        ctx.fillStyle = colour; centre(label, px + pw / 2, py + ph / 2);
      }};
      const coef = (n) => (n === 1 ? 'x' : `${{n}}x`);
      piece(x0, y0, x * u, x * u, red, '30', 'x²');
      piece(x0 + x * u, y0, p * u, x * u, blue, '30', coef(p));
      piece(x0, y0 + x * u, x * u, q * u, blue, '30', coef(q));
      piece(x0 + x * u, y0 + x * u, p * u, q * u, amber, '38', `${{p * q}}`);
      ctx.fillStyle = muted;
      centre('x', x0 + x * u / 2, y0 - 10); centre(`${{p}}`, x0 + x * u + p * u / 2, y0 - 10);
      centre('x', x0 - 12, y0 + x * u / 2); centre(`${{q}}`, x0 - 12, y0 + x * u + q * u / 2);
      const tot = (x + p) * (x + q), dos = x * x - p * p;
      ctx.fillStyle = green; ctx.fillText(`(x + ${{p}})(x + ${{q}}) = x² + ${{coef(p + q)}} + ${{p * q}}`, 46, 194);
      ctx.fillStyle = ink; ctx.fillText(`When x = ${{x}}: ${{x + p}} × ${{x + q}} = ${{tot}}`, 46, 212);
      ctx.fillText(`and ${{x * x}} + ${{p * x}} + ${{q * x}} + ${{p * q}} = ${{tot}}`, 46, 230);
      ctx.fillStyle = amber; ctx.fillText('Difference of two squares:', 46, 254);
      ctx.fillText(`${{x}}² − ${{p}}² = ${{x - p}} × ${{x + p}} = ${{dos}}`, 46, 272);
      readoutHtml = `(x + ${{p}})(x + ${{q}}) = <b style="color:${{red}}">x²</b> + <b style="color:${{blue}}">${{coef(p + q)}}</b> + <b style="color:${{amber}}">${{p * q}}</b> · when x = ${{x}}, the rectangle is ${{x + p}} × ${{x + q}} = <b>${{tot}}</b> · ${{x}}² − ${{p}}² = ${{x - p}} × ${{x + p}} = <b>${{dos}}</b>`;
      break;
    }}
    case 5: {{
      // Ch 5: a balance with bags and loose marbles on the left and their total on the right
      const n = Math.round(a), loose = Math.round(b), m = Math.round(c), R = n * m + loose, by = 118;
      ctx.strokeStyle = ink; ctx.lineWidth = 3;
      ctx.beginPath(); ctx.moveTo(40, by); ctx.lineTo(260, by); ctx.stroke();
      ctx.fillStyle = muted;
      ctx.beginPath(); ctx.moveTo(150, by); ctx.lineTo(136, by + 24); ctx.lineTo(164, by + 24); ctx.closePath(); ctx.fill();
      ctx.lineWidth = 2;
      ctx.strokeStyle = ink + '55'; ctx.strokeRect(40, 56, 100, 56); ctx.strokeRect(160, 56, 100, 56);
      ctx.fillStyle = muted; ctx.fillText('Left pan', 40, 48); ctx.fillText('Right pan', 160, 48);
      for (let i = 0; i < n; i++) {{
        ctx.fillStyle = red + '30'; ctx.strokeStyle = red;
        ctx.fillRect(46 + i * 15, 62, 12, 16); ctx.strokeRect(46 + i * 15, 62, 12, 16);
      }}
      const dot = (x, y, colour) => {{ ctx.fillStyle = colour; ctx.beginPath(); ctx.arc(x, y, 3.2, 0, Math.PI * 2); ctx.fill(); }};
      for (let i = 0; i < loose; i++) dot(50 + i * 10, 98, blue);
      for (let i = 0; i < R; i++) dot(166 + (i % 11) * 8.6, 63 + Math.floor(i / 11) * 12, amber);
      ctx.fillStyle = muted; ctx.fillText(`${{n}} bags and ${{loose}} marble${{loose === 1 ? '' : 's'}} balance ${{R}}`, 46, 168);
      ctx.fillStyle = green; ctx.fillText(`${{n}}b + ${{loose}} = ${{R}}`, 46, 194);
      ctx.fillStyle = ink; ctx.fillText(`Take ${{loose}} off both pans: ${{n}}b = ${{R - loose}}`, 46, 212);
      ctx.fillText(`Share among ${{n}} bags: b = ${{m}}`, 46, 230);
      ctx.fillStyle = muted; ctx.fillText(`Check: ${{n}} × ${{m}} + ${{loose}} = ${{R}}`, 46, 254);
      readoutHtml = `<b style="color:${{red}}">${{n}}b</b> + <b style="color:${{blue}}">${{loose}}</b> = <b style="color:${{amber}}">${{R}}</b>, so <b>b = ${{m}}</b>`;
      break;
    }}
    case 6: {{
      // Ch 6: a staircase of terms and its upside-down copy make a rectangle
      const n = Math.round(a), first = Math.round(b), d = Math.round(c);
      const last = first + (n - 1) * d, pair = first + last, sum = n * pair / 2, k = first - d;
      const bw = Math.min(28, 220 / n), uH = Math.min(14, 130 / pair), x0 = 46, base = 150;
      for (let i = 0; i < n; i++) {{
        const term = first + i * d, h1 = term * uH, h2 = (pair - term) * uH, x = x0 + i * bw;
        ctx.lineWidth = 1.6;
        ctx.fillStyle = red + '38'; ctx.strokeStyle = red;
        ctx.fillRect(x, base - h1, bw - 3, h1); ctx.strokeRect(x, base - h1, bw - 3, h1);
        ctx.fillStyle = blue + '30'; ctx.strokeStyle = blue;
        ctx.fillRect(x, base - h1 - h2, bw - 3, h2); ctx.strokeRect(x, base - h1 - h2, bw - 3, h2);
      }}
      const all = Array.from({{length: n}}, (_, i) => first + i * d).join(', ');
      const terms = all.length <= 26 ? all : `${{first}}, ${{first + d}}, …, ${{last}}`;
      const rule = (d === 1 ? 'n' : `${{d}}n`) + (k === 0 ? '' : k > 0 ? ` + ${{k}}` : ` − ${{-k}}`);
      ctx.fillStyle = muted; ctx.fillText(`Terms: ${{terms}}`, 46, 168);
      ctx.fillStyle = green; ctx.fillText(`nth term: ${{rule}}`, 46, 194);
      ctx.fillStyle = ink; ctx.fillText(`Each column: ${{first}} + ${{last}} = ${{pair}}`, 46, 212);
      ctx.fillText(`Rectangle: ${{n}} × ${{pair}} = ${{n * pair}}`, 46, 230);
      ctx.fillStyle = amber; ctx.fillText(`Sum of the terms: ${{n * pair}} ÷ 2 = ${{sum}}`, 46, 254);
      readoutHtml = `<b style="color:${{red}}">${{terms}}</b> · sum = ${{n}} × ${{pair}} ÷ 2 = <b>${{sum}}</b>`;
      break;
    }}
    case 7: {{
      // Ch 7: the line y = mx + c on a grid, with a step under it
      const m = a, k = Math.round(b), run = Math.round(c), rise = m * run;
      const ox = 160, oy = 86, sc = 12, num = v => String(Math.round(v * 100) / 100).replace('-', '−');
      ctx.save(); ctx.beginPath(); ctx.rect(40, 20, 240, 132); ctx.clip();
      ctx.strokeStyle = ink + '18'; ctx.lineWidth = 1;
      for (let i = -10; i <= 10; i++) {{ ctx.beginPath(); ctx.moveTo(ox + i * sc, 20); ctx.lineTo(ox + i * sc, 152); ctx.stroke(); }}
      for (let j = -5; j <= 5; j++) {{ ctx.beginPath(); ctx.moveTo(40, oy - j * sc); ctx.lineTo(280, oy - j * sc); ctx.stroke(); }}
      ctx.strokeStyle = muted; ctx.lineWidth = 1.5;
      ctx.beginPath(); ctx.moveTo(40, oy); ctx.lineTo(280, oy); ctx.moveTo(ox, 20); ctx.lineTo(ox, 152); ctx.stroke();
      ctx.strokeStyle = blue; ctx.lineWidth = 2.6;
      ctx.beginPath(); ctx.moveTo(ox - 10 * sc, oy - (-10 * m + k) * sc); ctx.lineTo(ox + 10 * sc, oy - (10 * m + k) * sc); ctx.stroke();
      const sx = m === 0 ? -run / 2 : Math.max(-10, Math.min(10 - run, -k / m - run / 2)), sy = m * sx + k;
      ctx.lineWidth = 2.2;
      ctx.strokeStyle = ink; ctx.beginPath(); ctx.moveTo(ox + sx * sc, oy - sy * sc); ctx.lineTo(ox + (sx + run) * sc, oy - sy * sc); ctx.stroke();
      ctx.strokeStyle = red; ctx.beginPath(); ctx.moveTo(ox + (sx + run) * sc, oy - sy * sc); ctx.lineTo(ox + (sx + run) * sc, oy - (sy + rise) * sc); ctx.stroke();
      ctx.fillStyle = green; ctx.beginPath(); ctx.arc(ox, oy - k * sc, 4.5, 0, Math.PI * 2); ctx.fill();
      ctx.restore();
      ctx.fillStyle = muted; ctx.fillText('x', 284, oy + 4); ctx.fillText('y', ox - 4, 15);
      const mx = m === 0 ? '' : m === 1 ? 'x' : m === -1 ? '−x' : `${{num(m)}}x`;
      const eq = m === 0 ? num(k) : mx + (k === 0 ? '' : k > 0 ? ` + ${{k}}` : ` − ${{-k}}`);
      const step = rise === 0 ? `${{run}} across, flat` : `${{run}} across, ${{num(Math.abs(rise))}} ${{rise > 0 ? 'up' : 'down'}}`;
      const thirds = v => {{ const t = Math.round(v * 3); if (Math.abs(v * 3 - t) > 1e-9 || t % 3 === 0) return num(v); const a = Math.abs(t), w = Math.floor(a / 3); return (t < 0 ? '−' : '') + (w || '') + (a % 3 === 1 ? '⅓' : '⅔'); }};
      const xCross = m !== 0 ? `Crosses the x-axis at x = ${{thirds(-k / m)}}` : k === 0 ? 'Lies along the x-axis' : 'Never crosses the x-axis';
      ctx.fillStyle = blue; ctx.fillText(`Line: y = ${{eq}}`, 46, 168);
      ctx.fillStyle = green; ctx.fillText(`Crosses the y-axis at (0, ${{num(k)}})`, 46, 194);
      ctx.fillStyle = ink; ctx.fillText(`Step: ${{step}}`, 46, 212);
      ctx.fillStyle = red; ctx.fillText(`Gradient: ${{num(rise)}} ÷ ${{run}} = ${{num(m)}}`, 46, 230);
      ctx.fillStyle = amber; ctx.fillText(xCross, 46, 254);
      readoutHtml = `<b style="color:${{blue}}">y = ${{eq}}</b> · gradient <b>${{num(m)}}</b> · crosses the y-axis at <b>(0, ${{num(k)}})</b>`;
      break;
    }}
    case 8: {{
      // Ch 8: a triangle, the line through C parallel to AB, and the outside angle at B
      const A = Math.round(a), B = Math.round(b), C = 180 - A - B, n = Math.round(c);
      const rad = d => d * Math.PI / 180, base = 134, xA = 52;
      const hUnit = Math.sin(rad(A)) * Math.sin(rad(B)) / Math.sin(rad(A + B));
      const L = Math.min(165, 100 / hUnit), xB = xA + L, ac = L * Math.sin(rad(B)) / Math.sin(rad(A + B));
      const xC = xA + ac * Math.cos(rad(A)), yC = base - ac * Math.sin(rad(A));
      const wedge = (x, y, r, s, e, col) => {{
        ctx.beginPath(); ctx.moveTo(x, y); ctx.arc(x, y, r, s, e); ctx.closePath();
        ctx.fillStyle = col + '40'; ctx.fill();
        ctx.strokeStyle = col; ctx.lineWidth = 1.6; ctx.beginPath(); ctx.arc(x, y, r, s, e); ctx.stroke();
      }};
      const label = (x, y, r, mid, text, col) => {{
        const rr = Math.max(r, 13 / Math.max(0.2, Math.abs(Math.sin(mid))));
        ctx.fillStyle = col; ctx.fillText(text, x + rr * Math.cos(mid), y + rr * Math.sin(mid) + 4);
      }};
      ctx.setLineDash([6, 4]); ctx.strokeStyle = green; ctx.lineWidth = 2;
      ctx.beginPath(); ctx.moveTo(40, yC); ctx.lineTo(280, yC); ctx.stroke(); ctx.setLineDash([]);
      wedge(xA, base, 18, -rad(A), 0, red);
      wedge(xB, base, 18, -Math.PI, rad(B) - Math.PI, blue);
      wedge(xB, base, 22, rad(B) - Math.PI, 0, amber);
      wedge(xC, yC, 16, 0, rad(B), blue);
      wedge(xC, yC, 16, rad(B), Math.PI - rad(A), muted);
      wedge(xC, yC, 16, Math.PI - rad(A), Math.PI, red);
      ctx.strokeStyle = ink; ctx.lineWidth = 2.4;
      ctx.beginPath(); ctx.moveTo(xA, base); ctx.lineTo(xB + 58, base); ctx.stroke();
      ctx.beginPath(); ctx.moveTo(xA, base); ctx.lineTo(xC, yC); ctx.lineTo(xB, base); ctx.stroke();
      ctx.font = '600 11px -apple-system, BlinkMacSystemFont, sans-serif'; ctx.textAlign = 'center';
      label(xA, base, 32, -rad(A) / 2, `${{A}}°`, red);
      label(xB, base, 32, rad(B) / 2 - Math.PI, `${{B}}°`, blue);
      label(xB, base, 36, (rad(B) - Math.PI) / 2, `${{180 - B}}°`, amber);
      label(xC, yC, 30, rad(B) / 2, `${{B}}°`, blue);
      label(xC, yC, 30, (rad(B) + Math.PI - rad(A)) / 2, `${{C}}°`, muted);
      label(xC, yC, 30, Math.PI - rad(A) / 2, `${{A}}°`, red);
      ctx.fillStyle = ink; ctx.fillText('A', xA - 10, base + 12); ctx.fillText('B', xB, base + 14); ctx.fillText('C', xC, yC - 7);
      ctx.textAlign = 'left'; ctx.font = '600 12.5px -apple-system, BlinkMacSystemFont, sans-serif';
      const total = (n - 2) * 180;
      ctx.fillStyle = ink; ctx.fillText(`Triangle: ${{A}}° + ${{B}}° + ${{C}}° = 180°`, 46, 168);
      ctx.fillStyle = amber; ctx.fillText(`Outside angle at B: ${{180 - B}}°`, 46, 194);
      ctx.fillText(`That is ${{A}}° + ${{C}}°, at A and C`, 46, 212);
      ctx.fillStyle = muted; ctx.fillText(`${{n === 8 ? 'An' : 'A'}} ${{n}}-sided shape cuts into ${{n - 2}} triangle${{n === 3 ? '' : 's'}}`, 46, 230);
      ctx.fillText(`Its inside angles add to ${{total}}°`, 46, 254);
      readoutHtml = `<b style="color:${{red}}">${{A}}°</b> + <b style="color:${{blue}}">${{B}}°</b> + ${{C}}° = <b>180°</b> · outside angle at B <b style="color:${{amber}}">${{180 - B}}°</b>`;
      break;
    }}
    case 9: {{
      // Ch 9: equal compass arcs from A and B, the perpendicular bisector through their crossings, and a point P on it
      const ab = a, r = b, hP = c, s = 14, xm = 160, yM = 85, half = ab / 2;
      const xA = xm - half * s, xB = xm + half * s;
      const cm = v => {{ const t = Math.round(v * 10) / 10; return Math.abs(v - t) < 1e-9 ? `${{t}} cm` : `about ${{t.toFixed(1)}} cm`; }};
      const cross = r > half + 1e-9, touch = Math.abs(r - half) < 1e-9;
      const hx = cross ? Math.sqrt(r * r - half * half) : 0;
      const arcAround = (x, y, ang, sp) => {{ ctx.beginPath(); ctx.arc(x, y, r * s, ang - sp, ang + sp); ctx.stroke(); }};
      ctx.strokeStyle = blue; ctx.lineWidth = 1.8;
      if (cross) {{
        for (const sy of [-1, 1]) {{
          const py = yM + sy * hx * s;
          arcAround(xA, yM, Math.atan2(py - yM, xm - xA), 0.3);
          arcAround(xB, yM, Math.atan2(py - yM, xm - xB), 0.3);
        }}
      }} else {{
        arcAround(xA, yM, 0, 0.6); arcAround(xB, yM, Math.PI, 0.6);
      }}
      ctx.strokeStyle = ink; ctx.lineWidth = 2.4;
      ctx.beginPath(); ctx.moveTo(xA, yM); ctx.lineTo(xB, yM); ctx.stroke();
      const dot = (x, y, col, rad) => {{ ctx.fillStyle = col; ctx.beginPath(); ctx.arc(x, y, rad, 0, 2 * Math.PI); ctx.fill(); }};
      const yP = yM - hP * s;
      if (cross) {{
        ctx.strokeStyle = red; ctx.lineWidth = 2.4;
        ctx.beginPath(); ctx.moveTo(xm, Math.max(20, yM - hx * s - 10)); ctx.lineTo(xm, Math.min(150, yM + hx * s + 10)); ctx.stroke();
        ctx.lineWidth = 1.4; ctx.strokeRect(xm, yM - 8, 8, 8);
        dot(xm, yM - hx * s, blue, 3); dot(xm, yM + hx * s, blue, 3);
        ctx.setLineDash([5, 4]); ctx.strokeStyle = green; ctx.lineWidth = 2;
        ctx.beginPath(); ctx.moveTo(xA, yM); ctx.lineTo(xm, yP); ctx.lineTo(xB, yM); ctx.stroke(); ctx.setLineDash([]);
        dot(xm, yP, green, 4);
      }}
      dot(xA, yM, ink, 3.5); dot(xB, yM, ink, 3.5); dot(xm, yM, muted, 3);
      ctx.font = '600 11px -apple-system, BlinkMacSystemFont, sans-serif'; ctx.textAlign = 'center';
      ctx.fillStyle = ink; ctx.fillText('A', xA - 11, yM + 4); ctx.fillText('B', xB + 11, yM + 4);
      ctx.fillStyle = muted; ctx.fillText('M', xm + 12, yM + 15);
      if (cross) {{ ctx.fillStyle = green; ctx.fillText('P', xm - 12, yP - 5); }}
      ctx.textAlign = 'left'; ctx.font = '600 12.5px -apple-system, BlinkMacSystemFont, sans-serif';
      ctx.fillStyle = ink; ctx.fillText(`AB = ${{ab}} cm, so M is ${{cm(half)}} from A`, 46, 168);
      if (cross) {{
        ctx.fillStyle = blue; ctx.fillText(`Arcs of ${{r}} cm cross twice`, 46, 194);
        ctx.fillStyle = red; ctx.fillText('Red line: through both crossings', 46, 212);
        ctx.fillStyle = green; ctx.fillText(hP === 0 ? 'P is at M' : `P is ${{hP}} cm above M`, 46, 230);
        ctx.fillText(`PA = PB = ${{cm(Math.hypot(half, hP))}}`, 46, 254);
        readoutHtml = `PA = <b style="color:${{green}}">${{cm(Math.hypot(half, hP))}}</b> = PB · M is <b>${{cm(half)}}</b> from A and from B`;
      }} else {{
        ctx.fillStyle = amber; ctx.fillText(touch ? `Arcs of ${{r}} cm only touch, at M` : `Arcs of ${{r}} cm do not meet`, 46, 194);
        ctx.fillText(`Open wider than ${{cm(half)}}`, 46, 212);
        ctx.fillStyle = muted; ctx.fillText('No red line to draw yet', 46, 230);
        readoutHtml = `The arcs do not cross: open the compasses wider than <b>${{cm(half)}}</b>`;
      }}
      break;
    }}
    case 10: {{
      // Ch 10: a circle cut into equal slices, the slices laid top to tail as a strip πr long and r tall, and a green slice
      const r = a, n = b, ang = c, s = 7, R = r * s, cx = 76, cy = 85, x0 = 138;
      const half = Math.PI / n, w = 2 * R * Math.sin(half), yTop = cy - R / 2, yBot = cy + R / 2;
      const one = v => (Math.round(v * 10) / 10).toFixed(1);
      const wedge = (x, y, mid, fill) => {{
        ctx.beginPath(); ctx.moveTo(x, y); ctx.arc(x, y, R, mid - half, mid + half); ctx.closePath();
        ctx.fillStyle = fill; ctx.fill(); ctx.strokeStyle = muted; ctx.lineWidth = 0.8; ctx.stroke();
      }};
      ctx.save();
      for (let i = 0; i < n; i++) {{
        ctx.globalAlpha = i % 2 ? 0.16 : 0.32;
        wedge(cx, cy, -Math.PI / 2 + (2 * i + 1) * half, blue);
      }}
      if (ang > 0) {{
        ctx.globalAlpha = 0.55; ctx.fillStyle = green; ctx.beginPath(); ctx.moveTo(cx, cy);
        ctx.arc(cx, cy, R, -Math.PI / 2, -Math.PI / 2 + ang * Math.PI / 180); ctx.closePath(); ctx.fill();
      }}
      ctx.globalAlpha = 1; ctx.strokeStyle = ink; ctx.lineWidth = 1.6;
      ctx.beginPath(); ctx.arc(cx, cy, R, 0, 2 * Math.PI); ctx.stroke();
      for (let k = 0; k < n / 2; k++) {{
        ctx.globalAlpha = 0.32; wedge(x0 + w / 2 + k * w, yBot, -Math.PI / 2, blue);
        ctx.globalAlpha = 0.16; wedge(x0 + w + k * w, yTop, Math.PI / 2, blue);
        ctx.globalAlpha = 1; ctx.strokeStyle = blue; ctx.lineWidth = 2.4;
        ctx.beginPath(); ctx.arc(x0 + w + k * w, yTop, R, Math.PI / 2 - half, Math.PI / 2 + half); ctx.stroke();
      }}
      ctx.restore();
      ctx.strokeStyle = red; ctx.lineWidth = 2.4;
      ctx.beginPath(); ctx.moveTo(x0 - 6, yBot); ctx.lineTo(x0 - 6, yTop); ctx.stroke();
      ctx.font = '600 11px -apple-system, BlinkMacSystemFont, sans-serif'; ctx.textAlign = 'center';
      ctx.fillStyle = red; ctx.fillText('r', x0 - 13, cy + 4);
      ctx.fillStyle = blue; ctx.fillText('πr', x0 + (n / 2) * w / 2 + w / 2, yBot + 16);
      ctx.textAlign = 'left'; ctx.font = '600 12.5px -apple-system, BlinkMacSystemFont, sans-serif';
      const area = Math.PI * r * r, part = area * ang / 360;
      ctx.fillStyle = ink; ctx.fillText(`r = ${{r}} cm, cut into ${{n}} slices`, 46, 168);
      ctx.fillStyle = blue; ctx.fillText(`Bottom of the strip: πr ≈ ${{one(Math.PI * r)}} cm`, 46, 194);
      ctx.fillStyle = red; ctx.fillText(`Height of the strip: r = ${{r}} cm`, 46, 212);
      ctx.fillStyle = ink; ctx.fillText(`Area: πr × r ≈ ${{one(area)}} cm²`, 46, 230);
      ctx.fillStyle = green;
      ctx.fillText(ang === 0 ? 'Green slice: none yet' : `Green: ${{ang}}/360 of it ≈ ${{one(part)}} cm²`, 46, 254);
      readoutHtml = `Area = π × ${{r}} × ${{r}} ≈ <b>${{one(area)}} cm²</b> · the strip is about ${{one(Math.PI * r)}} cm by ${{r}} cm`;
      break;
    }}
    case 11: {{
      // Ch 11: triangle PQR enlarged about a centre C; green lines cut the image into k × k copies when k is whole
      const k = a, ccx = b, ccy = c, u = 10, ox = 46, oy = 146;
      const X = gx => ox + gx * u, Y = gy => oy - gy * u;
      const fmt = v => String(Math.round(v * 100) / 100);
      const obj = [[3, 3], [5, 3], [3, 4]], names = ['P', 'Q', 'R'];
      const img = obj.map(([x, y]) => [ccx + k * (x - ccx), ccy + k * (y - ccy)]);
      ctx.save();
      ctx.strokeStyle = muted; ctx.globalAlpha = 0.22; ctx.lineWidth = 0.6;
      for (let gx = 0; gx <= 23; gx++) {{ ctx.beginPath(); ctx.moveTo(X(gx), Y(0)); ctx.lineTo(X(gx), Y(12)); ctx.stroke(); }}
      for (let gy = 0; gy <= 12; gy++) {{ ctx.beginPath(); ctx.moveTo(X(0), Y(gy)); ctx.lineTo(X(23), Y(gy)); ctx.stroke(); }}
      ctx.globalAlpha = 1; ctx.setLineDash([4, 4]); ctx.lineWidth = 1;
      obj.forEach((p, i) => {{
        const far = k >= 1 ? img[i] : p;
        ctx.beginPath(); ctx.moveTo(X(ccx), Y(ccy)); ctx.lineTo(X(far[0]), Y(far[1])); ctx.stroke();
      }});
      ctx.setLineDash([]);
      const tri = (pts, fill, stroke, width) => {{
        ctx.beginPath(); ctx.moveTo(X(pts[0][0]), Y(pts[0][1]));
        pts.slice(1).forEach(([x, y]) => ctx.lineTo(X(x), Y(y))); ctx.closePath();
        ctx.fillStyle = fill; ctx.globalAlpha = 0.22; ctx.fill();
        ctx.globalAlpha = 1; ctx.strokeStyle = stroke; ctx.lineWidth = width; ctx.stroke();
      }};
      tri(img, red, red, 2.2);
      const whole = Number.isInteger(k) && k >= 2;
      if (whole) {{
        ctx.strokeStyle = green; ctx.lineWidth = 1.2;
        for (let v = 0; v < 3; v++) {{
          const V = img[v], W1 = img[(v + 1) % 3], W2 = img[(v + 2) % 3];
          for (let i = 1; i < k; i++) {{
            const t = i / k;
            ctx.beginPath();
            ctx.moveTo(X(V[0] + t * (W1[0] - V[0])), Y(V[1] + t * (W1[1] - V[1])));
            ctx.lineTo(X(V[0] + t * (W2[0] - V[0])), Y(V[1] + t * (W2[1] - V[1])));
            ctx.stroke();
          }}
        }}
      }}
      tri(obj, blue, blue, 2);
      ctx.fillStyle = ink; ctx.beginPath(); ctx.arc(X(ccx), Y(ccy), 3.5, 0, 2 * Math.PI); ctx.fill();
      ctx.font = '600 11px -apple-system, BlinkMacSystemFont, sans-serif';
      ctx.fillText('C', X(ccx) - 12, Y(ccy) + 4);
      const offs = [[-13, 4], [4, 12], [-11, -3]];
      ctx.fillStyle = blue; obj.forEach((p, i) => ctx.fillText(names[i], X(p[0]) + offs[i][0], Y(p[1]) + offs[i][1]));
      if (k !== 1) {{
        ctx.fillStyle = red; img.forEach((p, i) => ctx.fillText(names[i] + '′', X(p[0]) + offs[i][0] - 2, Y(p[1]) + offs[i][1]));
      }}
      ctx.restore();
      ctx.textAlign = 'left'; ctx.font = '600 12.5px -apple-system, BlinkMacSystemFont, sans-serif';
      ctx.fillStyle = ink; ctx.fillText(`Scale factor ${{fmt(k)}}, centre C at (${{ccx}}, ${{ccy}})`, 46, 168);
      ctx.fillStyle = blue; ctx.fillText(`PQ = 2 cm, so P′Q′ = ${{fmt(2 * k)}} cm`, 46, 194);
      ctx.fillStyle = red; ctx.fillText(`C to P′ is ${{fmt(k)}} times C to P`, 46, 212);
      ctx.fillStyle = ink; ctx.fillText(`Area × ${{fmt(k * k)}}: 1 cm² becomes ${{fmt(k * k)}} cm²`, 46, 230);
      ctx.fillStyle = green;
      ctx.fillText(whole ? `${{k * k}} copies of PQR fit inside P′Q′R′`
        : k === 1 ? 'Scale factor 1: the same size as PQR'
        : k < 1 ? 'Less than 1: smaller than PQR'
        : 'Not whole: copies do not fit exactly', 46, 254);
      readoutHtml = `Scale factor <b>${{fmt(k)}}</b> · every length × ${{fmt(k)}} · every area × <b>${{fmt(k * k)}}</b>`;
      break;
    }}
    case 12: {{
      // Ch 12: Unit Circle Shadows (cos, sin, tan) & Sine Wave Unrolling
      const rad = (c * Math.PI) / 180, cosV = Math.cos(rad), sinV = Math.sin(rad);
      const cx = 135, cy = 145, r = 84;
      ctx.strokeStyle = muted; ctx.lineWidth = 1.5;
      ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.stroke();
      const px = cx + r * cosV, py = cy - r * sinV;
      ctx.strokeStyle = blue; ctx.lineWidth = 3.2;
      ctx.beginPath(); ctx.moveTo(cx, cy); ctx.lineTo(px, cy); ctx.stroke();
      ctx.strokeStyle = red;
      ctx.beginPath(); ctx.moveTo(px, cy); ctx.lineTo(px, py); ctx.stroke();
      ctx.strokeStyle = green;
      ctx.beginPath(); ctx.moveTo(cx, cy); ctx.lineTo(px, py); ctx.stroke();
      // Unrolled sine wave on right
      const wx0 = 255, ww = 250;
      ctx.strokeStyle = muted + '66'; ctx.lineWidth = 1;
      ctx.beginPath(); ctx.moveTo(wx0, cy); ctx.lineTo(wx0 + ww, cy); ctx.stroke();
      ctx.strokeStyle = red; ctx.lineWidth = 2.2;
      ctx.beginPath();
      for (let d = 0; d <= 360; d += 4) {{
        const sx = wx0 + (d / 360) * ww, sy = cy - r * Math.sin((d * Math.PI) / 180);
        if (d === 0) ctx.moveTo(sx, sy); else ctx.lineTo(sx, sy);
      }}
      ctx.stroke();
      const curWx = wx0 + (c / 360) * ww;
      ctx.setLineDash([4, 3]); ctx.strokeStyle = amber;
      ctx.beginPath(); ctx.moveTo(px, py); ctx.lineTo(curWx, py); ctx.stroke();
      ctx.setLineDash([]);
      ctx.fillStyle = red; ctx.beginPath(); ctx.arc(curWx, py, 5, 0, Math.PI * 2); ctx.fill();
      const hyp = Math.hypot(a, b);
      ctx.fillStyle = ink; ctx.fillText(`Pythagoras: √(${{a}}²+${{b}}²) = ${{hyp.toFixed(2)}} · sin²θ + cos²θ = 1.000`, 42, 258);
      readoutHtml = `θ = ${{c}}° · <b style="color:${{blue}}">cos θ = ${{cosV.toFixed(3)}}</b> · <b style="color:${{red}}">sin θ = ${{sinV.toFixed(3)}}</b> · <b>cos²θ + sin²θ = 1.000</b>`;
      break;
    }}
    case 13: {{
      // Ch 13: Standard Error sigma/sqrt(n) & Wald Survivorship Bias
      const sigma = a, n = b, se = sigma / Math.sqrt(n);
      const cx = 175, baseY = 215, scX = 16;
      ctx.strokeStyle = muted; ctx.lineWidth = 1.5;
      ctx.beginPath(); ctx.moveTo(35, baseY); ctx.lineTo(315, baseY); ctx.stroke();
      ctx.strokeStyle = red; ctx.lineWidth = 2.6;
      ctx.beginPath();
      for (let x = -130; x <= 130; x += 3) {{
        const z = x / (se * scX);
        const y = baseY - 135 * Math.exp(-0.5 * z * z);
        if (x === -130) ctx.moveTo(cx + x, y); else ctx.lineTo(cx + x, y);
      }}
      ctx.stroke();
      ctx.fillStyle = red; ctx.fillText(`±SE = ±${{se.toFixed(2)}}`, cx - 32, baseY + 22);
      // Wald aircraft schematic on right
      ctx.strokeStyle = blue; ctx.lineWidth = 2;
      ctx.strokeRect(360, 75, 140, 28); ctx.strokeRect(415, 42, 30, 95);
      ctx.fillStyle = amber; ctx.fillText(`Wald Bomber: Armour the`, 348, 165);
      ctx.fillText(`MISSING engine hits (${{c}})!`, 348, 185);
      readoutHtml = `Population σ = ${{sigma}}, Sample n = ${{n}} ⇒ <b>Standard Error SE = σ / √n = ${{sigma}} / ${{Math.sqrt(n).toFixed(2)}} = ${{se.toFixed(2)}}</b>`;
      break;
    }}
    case 14: {{
      // Ch 14: Frequency Density Histogram (Area = Frequency)
      const w3 = a, f3 = b, fd3 = f3 / w3;
      const bins = [{{l:'0–10',w:10,f:18,fd:1.8,c:blue}}, {{l:'10–20',w:10,f:24,fd:2.4,c:green}}, {{l:`20–${{20+w3}}`,w:w3,f:f3,fd:fd3,c:red}}];
      let xCur = 54; const yBase = 225, scW = 4.8, scH = 58;
      bins.forEach(bn => {{
        const bw = bn.w * scW, bh = bn.fd * scH;
        ctx.fillStyle = bn.c + '35'; ctx.strokeStyle = bn.c; ctx.lineWidth = 2.2;
        ctx.fillRect(xCur, yBase - bh, bw, bh); ctx.strokeRect(xCur, yBase - bh, bw, bh);
        ctx.fillStyle = ink; ctx.fillText(`f=${{bn.f}}`, xCur + 6, yBase - bh - 6);
        ctx.fillStyle = muted; ctx.fillText(bn.l, xCur + 4, yBase + 18);
        xCur += bw;
      }});
      ctx.fillStyle = red; ctx.fillText(`Wide bin FD = ${{f3}} ÷ ${{w3}} = ${{fd3.toFixed(2)}}`, 320, 92);
      ctx.fillStyle = amber; ctx.fillText(`Area = FD × Δx = ${{fd3.toFixed(2)}} × ${{w3}} = ${{f3}}`, 320, 122);
      readoutHtml = `Wide Class (Δx = ${{w3}}, f = ${{f3}}): <b>Frequency Density = f / Δx = ${{fd3.toFixed(2)}}</b> (Bar Area = ${{f3}})`;
      break;
    }}
    case 15: {{
      // Ch 15: Galton Pegboard & Binomial C(n, k)
      const n = Math.round(a), k = Math.min(n, Math.round(b)), p = c / 100;
      const ways = comb(n, k), prob = ways * Math.pow(p, k) * Math.pow(1 - p, n - k);
      const yBase = 225, bw = Math.min(36, 260 / (n + 1)), x0 = 54;
      let maxP = 0;
      for (let i = 0; i <= n; i++) maxP = Math.max(maxP, comb(n, i) * Math.pow(p, i) * Math.pow(1 - p, n - i));
      for (let i = 0; i <= n; i++) {{
        const pr = comb(n, i) * Math.pow(p, i) * Math.pow(1 - p, n - i);
        const bh = (pr / Math.max(0.01, maxP)) * 145;
        const col = i === k ? red : blue;
        ctx.fillStyle = col + (i === k ? '55' : '28'); ctx.strokeStyle = col; ctx.lineWidth = 2;
        ctx.fillRect(x0 + i * bw, yBase - bh, bw - 3, bh); ctx.strokeRect(x0 + i * bw, yBase - bh, bw - 3, bh);
        ctx.fillStyle = ink; ctx.fillText(comb(n, i), x0 + i * bw + 4, yBase - bh - 6);
      }}
      ctx.fillStyle = red; ctx.fillText(`C(${{n}}, ${{k}}) = ${{ways}} distinct peg paths`, 315, 95);
      ctx.fillStyle = green; ctx.fillText(`P(X = ${{k}}) = ${{(prob * 100).toFixed(1)}}%`, 315, 128);
      readoutHtml = `Galton Board (n = ${{n}}, k = ${{k}}): <b>ⁿCₖ = ${{ways}} paths</b> · Binomial probability <b>P(X = ${{k}}) = ${{(prob * 100).toFixed(2)}}%</b>`;
      break;
    }}
    case 16: {{
      // Ch 16: Bayes 1,000-Person Unit Square Eikosogram
      const prev = a / 100, sens = b / 100, fpr = c / 100;
      const sick = 1000 * prev, healthy = 1000 - sick;
      const tp = sick * sens, fp = healthy * fpr, ppv = (tp / (tp + fp)) * 100;
      const sqX = 48, sqY = 38, sqW = 210, sqH = 185;
      const wD = Math.max(18, prev * sqW * 2.2);
      const hTP = sens * sqH, hFP = Math.max(14, fpr * sqH * 1.8);
      ctx.strokeStyle = ink; ctx.lineWidth = 2; ctx.strokeRect(sqX, sqY, sqW, sqH);
      ctx.fillStyle = red + '66'; ctx.fillRect(sqX, sqY + sqH - hTP, wD, hTP);
      ctx.fillStyle = amber + '66'; ctx.fillRect(sqX + wD, sqY + sqH - hFP, sqW - wD, hFP);
      ctx.fillStyle = red; ctx.fillText(`True Pos (Red): ${{tp.toFixed(1)}}`, 285, 82);
      ctx.fillStyle = amber; ctx.fillText(`False Pos (Amber): ${{fp.toFixed(1)}}`, 285, 112);
      ctx.fillStyle = green; ctx.fillText(`Posterior P(D | +) = ${{ppv.toFixed(1)}}%`, 285, 148);
      // Isolated posterior bar
      const totH = 140, tpBarH = (tp / (tp + fp)) * totH;
      ctx.fillStyle = red; ctx.fillRect(495, 60, 28, tpBarH);
      ctx.fillStyle = amber; ctx.fillRect(495, 60 + tpBarH, 28, totH - tpBarH);
      readoutHtml = `Of 1,000 people: <b>${{tp.toFixed(1)}} True Positives</b> vs <b>${{fp.toFixed(1)}} False Positives</b> ⇒ <b>P(D | +) = ${{ppv.toFixed(1)}}%</b>`;
      break;
    }}
    case 17: {{
      // Ch 17: Differential Calculus — Secant to Tangent & d(x^2) = 2x dx
      const x0 = a, hStep = b, f = x => 0.5 * x * x;
      const y0 = f(x0), y1 = f(x0 + hStep), secSlope = (y1 - y0) / hStep, tanSlope = x0;
      const ox = 54, oy = 235, scX = 72, scY = 42;
      ctx.strokeStyle = blue; ctx.lineWidth = 2.5;
      ctx.beginPath();
      for (let u = 0; u <= 3.2; u += 0.08) {{
        const sx = ox + u * scX, sy = oy - f(u) * scY;
        if (u === 0) ctx.moveTo(sx, sy); else ctx.lineTo(sx, sy);
      }}
      ctx.stroke();
      const px = ox + x0 * scX, py = oy - y0 * scY, qx = ox + (x0 + hStep) * scX, qy = oy - y1 * scY;
      ctx.strokeStyle = amber; ctx.lineWidth = 2.2;
      ctx.beginPath(); ctx.moveTo(px - 35, py + 35 * (secSlope * scY / scX)); ctx.lineTo(qx + 25, qy - 25 * (secSlope * scY / scX)); ctx.stroke();
      ctx.strokeStyle = red; ctx.lineWidth = 2.4;
      ctx.beginPath(); ctx.moveTo(px - 45, py + 45 * (tanSlope * scY / scX)); ctx.lineTo(px + 55, py - 55 * (tanSlope * scY / scX)); ctx.stroke();
      ctx.fillStyle = red; ctx.beginPath(); ctx.arc(px, py, 5, 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = amber; ctx.beginPath(); ctx.arc(qx, qy, 5, 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = red; ctx.fillText(`Tangent f′(${{x0}}) = ${{tanSlope.toFixed(2)}}`, 305, 85);
      ctx.fillStyle = amber; ctx.fillText(`Secant Δy/h = ${{secSlope.toFixed(3)}}`, 305, 115);
      ctx.fillStyle = green; ctx.fillText(`d(x²)/dx = 2x + h = ${{(2*c + hStep).toFixed(2)}} → ${{2*c}}`, 305, 148);
      readoutHtml = `At x₀ = ${{x0}}, step h = ${{hStep}}: Secant = <b>${{secSlope.toFixed(3)}}</b> → Exact Derivative <b>f′(x₀) = ${{tanSlope.toFixed(2)}}</b>`;
      break;
    }}
    case 18: {{
      // Ch 18: Integral Calculus — Midpoint Riemann Bars & FTC Area = Antiderivative
      const upperX = a, N = Math.round(b), kSlope = c, dx = upperX / N;
      const ox = 54, oy = 232, scX = 76, scY = 48;
      let rSum = 0;
      for (let i = 0; i < N; i++) {{
        const xm = (i + 0.5) * dx, ym = kSlope * xm;
        rSum += ym * dx;
        const bx = ox + i * dx * scX, bw = dx * scX, bh = ym * scY;
        ctx.fillStyle = (i === N - 1 ? red : blue) + '38';
        ctx.strokeStyle = i === N - 1 ? red : blue; ctx.lineWidth = 1.6;
        ctx.fillRect(bx, oy - bh, bw, bh); ctx.strokeRect(bx, oy - bh, bw, bh);
      }}
      ctx.strokeStyle = green; ctx.lineWidth = 2.5;
      ctx.beginPath(); ctx.moveTo(ox, oy); ctx.lineTo(ox + 3 * scX, oy - kSlope * 3 * scY); ctx.stroke();
      const exact = 0.5 * kSlope * upperX * upperX;
      ctx.fillStyle = blue; ctx.fillText(`Riemann Sum (${{N}} slabs) = ${{rSum.toFixed(3)}}`, 305, 92);
      ctx.fillStyle = green; ctx.fillText(`Exact ∫₀ˣ kt dt = ½kx² = ${{exact.toFixed(3)}}`, 305, 124);
      ctx.fillStyle = red; ctx.fillText(`FTC: dA/dx = f(x) = ${{(kSlope*upperX).toFixed(2)}}`, 305, 156);
      readoutHtml = `Midpoint Riemann (${{N}} slabs) = <b>${{rSum.toFixed(4)}}</b> · Exact Antiderivative <b>F(${{upperX}}) − F(0) = ${{exact.toFixed(4)}}</b>`;
      break;
    }}
    case 19: {{
      // Ch 19: Vectors Tip-to-Tail Triangle Law & Dot Product
      const ax = a, ay = 1.2, bx = b, by = 2.0, angRad = (c * Math.PI) / 180;
      const ox = 64, oy = 225, sc = 36;
      const p1x = ox + ax * sc, p1y = oy - ay * sc;
      const p2x = p1x + bx * sc, p2y = p1y - by * sc;
      drawArrow(ctx, ox, oy, p1x, p1y, red, 3);
      drawArrow(ctx, p1x, p1y, p2x, p2y, blue, 3);
      drawArrow(ctx, ox, oy, p2x, p2y, green, 3.2);
      ctx.fillStyle = red; ctx.fillText(`a = (${{ax}}, ${{ay}})`, ox + 28, oy - 12);
      ctx.fillStyle = blue; ctx.fillText(`b = (${{bx}}, ${{by}})`, p1x + 14, p1y - 18);
      ctx.fillStyle = green; ctx.fillText(`a + b = (${{(ax+bx).toFixed(1)}}, ${{(ay+by).toFixed(1)}})`, ox + 15, oy - 95);
      const magA = Math.hypot(ax, ay), magB = Math.hypot(bx, by), dot = magA * magB * Math.cos(angRad);
      ctx.fillStyle = amber; ctx.fillText(`Dot Product |a||b|cos(${{c}}°) = ${{dot.toFixed(2)}}`, 305, 175);
      readoutHtml = `Resultant <b>a + b = (${{(ax+bx).toFixed(1)}}, ${{(ay+by).toFixed(1)}})</b> · |a+b| = <b>${{Math.hypot(ax+bx, ay+by).toFixed(2)}}</b> · Dot product = <b>${{dot.toFixed(2)}}</b>`;
      break;
    }}
    default: {{
      // Ch 20: 2x2 Matrix Basis Grid, Determinant Parallelogram & Eigenvectors
      const mA = a, mB = b, mD = c, det = mA * mD - mB * mB;
      const ox = 95, oy = 215, sc = 42;
      const iX = ox + mA * sc, iY = oy - mB * sc;
      const jX = ox + mB * sc, jY = oy - mD * sc;
      const sumX = iX + (jX - ox), sumY = iY + (jY - oy);
      ctx.fillStyle = amber + '38'; ctx.strokeStyle = amber; ctx.lineWidth = 2;
      ctx.beginPath(); ctx.moveTo(ox, oy); ctx.lineTo(iX, iY); ctx.lineTo(sumX, sumY); ctx.lineTo(jX, jY); ctx.closePath();
      ctx.fill(); ctx.stroke();
      drawArrow(ctx, ox, oy, iX, iY, red, 3.2);
      drawArrow(ctx, ox, oy, jX, jY, blue, 3.2);
      ctx.fillStyle = red; ctx.fillText(`Aî = (${{mA}}, ${{mB}})`, iX + 8, iY);
      ctx.fillStyle = blue; ctx.fillText(`Aĵ = (${{mB}}, ${{mD}})`, jX - 24, jY - 10);
      ctx.fillStyle = amber; ctx.fillText(`Area det(A) = ad − bc = ${{det.toFixed(2)}}`, 305, 95);
      const tr = mA + mD, disc = Math.max(0, tr * tr - 4 * det);
      const l1 = 0.5 * (tr + Math.sqrt(disc)), l2 = 0.5 * (tr - Math.sqrt(disc));
      ctx.fillStyle = green; ctx.fillText(`Eigenvalues λ₁ = ${{l1.toFixed(2)}}, λ₂ = ${{l2.toFixed(2)}}`, 305, 128);
      ctx.fillStyle = ink; ctx.fillText(`Check: λ₁ × λ₂ = ${{(l1 * l2).toFixed(2)}} = det(A)`, 305, 160);
      readoutHtml = `Matrix [[${{mA}}, ${{mB}}], [${{mB}}, ${{mD}}]] · <b>det(A) = ${{det.toFixed(2)}}</b> · Eigenvalues <b>λ₁ = ${{l1.toFixed(2)}}, λ₂ = ${{l2.toFixed(2)}}</b>`;
      break;
    }}
  }}

  if (window.highlightedRole) {{
    const ch = CHAPTERS[currentChapter] || CHAPTERS[0];
    const mappings = (ch.intuitionToFormula && ch.intuitionToFormula.termMappings) || [];
    const matched = mappings.find(m => m.colorRole === window.highlightedRole);
    if (matched) {{
      const roleCol = matched.colorRole === 'red' ? red : (matched.colorRole === 'blue' ? blue : (matched.colorRole === 'amber' ? amber : green));
      ctx.save();
      ctx.strokeStyle = roleCol;
      ctx.lineWidth = 3;
      ctx.strokeRect(6, 6, w - 12, h - 12);
      ctx.fillStyle = roleCol;
      ctx.font = 'bold 12px -apple-system, sans-serif';
      ctx.fillText(`Focused Term: ${{matched.symbol}} → ${{matched.visualPart}}`, 16, h - 14);
      ctx.restore();
    }}
  }}
  ctx.restore();
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
document.getElementById('btn-stage-primary').addEventListener('click', () => {{
  const ch = CHAPTERS[currentChapter] || CHAPTERS[0];
  setAtlasRoute(ch.intuitionToFormula.atlasFigureRef);
}});
document.getElementById('btn-stage-companion').addEventListener('click', () => {{
  const ch = CHAPTERS[currentChapter] || CHAPTERS[0];
  setAtlasRoute(COMPANION_BOOKS[ch.number] || ch.intuitionToFormula.atlasFigureRef);
}});
// The 3D figures are not bundled for offline use yet, so the box stays hidden until the
// loaded figure has drawn something: a blank box with no figure is worse than none.
function figureHasContent(frame) {{
  try {{
    const doc = frame.contentDocument;
    return !!(doc && doc.body && doc.body.querySelector('canvas, svg, img, video'));
  }} catch (e) {{
    return false;
  }}
}}
function showAtlasCardIfDrawn() {{
  const frame = document.getElementById('atlas-iframe');
  const card = document.getElementById('atlas-card');
  const src = frame.src;
  card.hidden = !figureHasContent(frame);
  if (card.hidden) setTimeout(() => {{ if (frame.src === src) card.hidden = !figureHasContent(frame); }}, 1500);
}}
document.getElementById('atlas-iframe').addEventListener('load', showAtlasCardIfDrawn);
document.getElementById('atlas-iframe').addEventListener('error', () => {{
  document.getElementById('atlas-card').hidden = true;
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
    window.webkit.messageHandlers.kymmathsBridge.postMessage({{ type: 'stampWidget', widgetId: wid, chapter: ch.number, readout }});
  }}
  document.getElementById('btn-stamp').textContent = 'Challenge Stamped ✓';
}});

window.addEventListener('hashchange', () => {{
  parseHash();
  renderChapter();
}});
window.addEventListener('resize', drawSandbox);

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
        "misconceptions": build_misconceptions(),
        "footings": build_footings(),
        "concepts": build_concepts(chapters),
        "conceptStopPhrases": build_concept_stop_phrases(),
    }
    content_checks.require_clean(pack, rewritten_chapters(), book_school_authored())
    write_golden(pack)

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
