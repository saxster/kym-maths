"""
Chapter 20, written by hand to docs/CONTENT_BRIEF.md. It goes beyond the school book and rewrites q-oup-ch16-wb-challenge.

Each section teaches one idea in nine steps, in this order: question, idea, picture, reason, name,
example, mistake, turn, sayBack. A section's `teaches` lists the concept cards whose names first
appear in its `name` step. `build(k)` returns the chapter and `cards(k)` its concept cards; both take the
exporter's answer-key helpers.
"""


def mat_vec(m, v):
    return (m[0][0] * v[0] + m[0][1] * v[1], m[1][0] * v[0] + m[1][1] * v[1])


def det2(a, b, c, d):
    return a * d - b * c


def build(k):
    return {
        "number": 20,
        "title": "Matrices",
        "subtitle": "Beyond the school book · Moving the grid with two arrows, "
                    "measuring stretched area with ad − bc, and finding directions that do not turn",
        "hookSummary": "When you pinch-zoom or rotate a photo on a screen, the tablet moves millions of pixels at once. "
                       "How can four numbers tell every point on the grid where to land?",
        "beyondSchoolBook": True,
        "skillCard": {
            "skill": "Reading the columns of a 2×2 matrix, multiplying a matrix by a vector, finding the determinant ad − bc, and spotting eigenvectors",
            "sheCan": {
                "prompt": "With no calculator: for the 2×2 matrix A = [[3, 1], [2, 4]], where does it send the vector (2, 1)? "
                          "What is its determinant det(A) = ad − bc, and what does A do to the area of a triangle of area 5 cm²?",
                "answer": "A sends (2, 1) to 2 × (3, 2) + 1 × (1, 4) = (6 + 1, 4 + 4) = (7, 8). "
                          "Its determinant is (3 × 4) − (1 × 2) = 12 − 2 = 10, so the triangle's area becomes 10 × 5 = 50 cm².",
            },
            "whyItMatters": "Every 3D game, robot arm and medical scanner runs on matrices. "
                            "They package an entire grid move into four numbers a computer can multiply at once.",
            "standsOn": [
                "Chapter 10: the area of a rectangle and a parallelogram",
                "Chapter 11: transformations and area scale factors",
                "Chapter 19: column vectors and scalar multiples",
            ],
            "unlocks": [
                "Computer graphics: rotating, shearing and projecting 3D worlds onto a screen",
                "Engineering: solving systems of many simultaneous equations at once",
                "Data science: principal directions and page-ranking eigenvectors",
            ],
        },
        "intuitionToFormula": {
            "concreteAction": "In the figure, set the first column to (2, 1) and the second column to (1, 2), and look at the amber parallelogram.",
            "ahaInvariant": "The 1 × 1 unit square stretches into an amber parallelogram whose area is ad − bc = 2(2) − 1(1) = 3. "
                            "And any arrow along the diagonal (1, 1) is stretched by 3 without turning at all.",
            "formulaDisplay": "[[a, b], [c, d]] [x, y]ᵀ = x(a, c) + y(b, d),   det(A) = ad − bc,   Av = λv",
            "termMappings": [
                {"symbol": "Column 1 (a, c)", "visualPart": "The red arrow where (1, 0) lands", "colorRole": "red",
                 "meaning": "The new step for every 1 unit across"},
                {"symbol": "Column 2 (b, d)", "visualPart": "The blue arrow where (0, 1) lands", "colorRole": "blue",
                 "meaning": "The new step for every 1 unit up"},
                {"symbol": "det(A) = ad − bc", "visualPart": "The amber parallelogram between the red and blue arrows", "colorRole": "amber",
                 "meaning": "How many times bigger every area becomes"},
                {"symbol": "Av = λv", "visualPart": "The green directions that stretch by λ without turning", "colorRole": "green",
                 "meaning": "Eigenvectors and their stretch factors (eigenvalues)"},
            ],
            "atlasFigureRef": "maths/ch20-matrices-eigen/index.html",
        },
        "sections": [
            {
                "heading": "20.1 Two arrows that move the whole grid",
                "teaches": ["basis-vectors", "linear-transformation", "matrix"],
                "steps": [
                    {"kind": "question",
                     "text": "Every point (x, y) is x steps of (1, 0) plus y steps of (0, 1). "
                             "If a grid move sends (1, 0) to (3, 2) and (0, 1) to (1, 4), where must the point (2, 1) land?"},
                    {"kind": "idea",
                     "text": "It must land at 2 lots of (3, 2) plus 1 lot of (1, 4), which is (6, 4) + (1, 4) = (7, 8). "
                             "Knowing where the two unit arrows land tells you where every point on the plane lands."},
                    {"kind": "picture",
                     "text": "Draw the red unit arrow (1, 0) and the blue unit arrow (0, 1). "
                             "Watch them land at (3, 2) and (1, 4), carrying the whole grid with them."},
                    {"kind": "reason",
                     "text": "Why do those two arrows control the whole grid? "
                             "When grid lines stay straight, parallel and evenly spaced and (0, 0) stays put, "
                             "2 steps across and 1 step up must become 2 red arrows plus 1 blue arrow."},
                    {"kind": "name",
                     "text": "The unit step across î = (1, 0) and unit step up ĵ = (0, 1) are the basis vectors. "
                             "A move of the plane that keeps grid lines straight, parallel and evenly spaced with the origin fixed is a linear transformation. "
                             "Writing the landed red arrow (a, c) and blue arrow (b, d) as two columns makes a 2×2 matrix, [[a, b], [c, d]]."},
                    {"kind": "example",
                     "text": "The matrix [[2, 0], [0, 3]] has first column (2, 0) and second column (0, 3). "
                             "It stretches every x-coordinate by 2 and every y-coordinate by 3, sending (4, 5) to (8, 15)."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to read the rows of [[3, 1], [2, 4]] as the two landed arrows. "
                             "Read down the columns: column 1 is (3, 2) where î lands, and column 2 is (1, 4) where ĵ lands."},
                    {"kind": "turn",
                     "text": "A linear transformation sends î = (1, 0) to (4, 1) and ĵ = (0, 1) to (2, 3). "
                             "Where does it send the vector (1, 2)?",
                     "answer": "(8, 7)",
                     "answerKey": k.one(k.seq("8", "7"), accepts=["(8, 7)", "8, 7"], rejects=["(6, 4)", "(9, 5)", "(7, 8)"])},
                    {"kind": "sayBack",
                     "text": "A 2×2 matrix records where the basis vectors î and ĵ land in its two columns, sending (x, y) to x × (column 1) + y × (column 2)."},
                ],
            },
            {
                "heading": "20.2 Doing one transformation after another",
                "teaches": ["matrix-multiplication"],
                "steps": [
                    {"kind": "question",
                     "text": "First reflect a shape across the x-axis, then rotate it 90° anticlockwise. "
                             "Do you get the same result if you rotate first and reflect second?"},
                    {"kind": "idea",
                     "text": "No. Follow the basis vector î = (1, 0): reflecting in the x-axis keeps it at (1, 0), and rotating 90° sends it to (0, 1). "
                             "In the reverse order, rotating 90° sends (1, 0) to (0, 1), and reflecting in the x-axis flips that to (0, −1)."},
                    {"kind": "picture",
                     "text": "Hold a book flat on the desk: flip it left-to-right then turn it 90° clockwise; "
                             "now start again, turn it 90° clockwise first, then flip it left-to-right. The cover ends up facing a different way."},
                    {"kind": "reason",
                     "text": "How do we combine matrix B followed by matrix A into one matrix AB? "
                             "Apply A to B's first column, then apply A to B's second column."},
                    {"kind": "name",
                     "text": "Combining two linear transformations by letting the left matrix act on each column of the right matrix is matrix multiplication. "
                             "Each entry of AB is a row-by-column dot product, and usually AB ≠ BA."},
                    {"kind": "example",
                     "text": "For A = [[1, 2], [0, 1]] and B = [[2, 0], [1, 3]], "
                             "A sends B's first column (2, 1) to (1×2 + 2×1, 0×2 + 1×1) = (4, 1), "
                             "and B's second column (0, 3) to (1×0 + 2×3, 0×0 + 1×3) = (6, 3), so AB = [[4, 6], [1, 3]]."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to multiply the four numbers in matching positions, top-left by top-left. "
                             "Instead, multiply each row of the left matrix by each column of the right matrix."},
                    {"kind": "turn",
                     "text": "Multiply the matrix [[2, 1], [0, 3]] by the column vector (4, 2).",
                     "answer": "(10, 6)",
                     "answerKey": k.one(k.seq("10", "6"), accepts=["(10, 6)", "10, 6"], rejects=["(8, 6)", "(6, 10)", "(8, 2)"])},
                    {"kind": "sayBack",
                     "text": "Matrix multiplication applies the left matrix to each column of the right matrix, and the order of multiplication matters."},
                ],
            },
            {
                "heading": "20.3 Why the area of the parallelogram is ad − bc",
                "figure": True,
                "teaches": ["determinant", "singular-matrix"],
                "steps": [
                    {"kind": "question",
                     "text": "The matrix [[a, b], [c, d]] turns the 1 × 1 unit square into a tilted parallelogram spanned by (a, c) and (b, d). "
                             "What is the area of that parallelogram?"},
                    {"kind": "idea",
                     "text": "ad − bc. Fit the parallelogram inside an (a + b) by (c + d) rectangle of area ac + ad + bc + bd. "
                             "Subtract four corner triangles (area ac + bd) and two b × c rectangles (area 2bc) to leave ad − bc."},
                    {"kind": "picture",
                     "text": "In the figure, set a = 2, b = 1 and d = 2. "
                             "The amber parallelogram between (2, 1) and (1, 2) has area 2(2) − 1(1) = 3."},
                    {"kind": "reason",
                     "text": "What happens when the two columns point along the same line, such as (2, 1) and (4, 2)? "
                             "The parallelogram squashes flat onto a single line with zero width, and ad − bc = 2(2) − 4(1) = 0."},
                    {"kind": "name",
                     "text": "The signed area scale factor of a 2×2 matrix [[a, b], [c, d]] is its determinant, written det(A) = ad − bc. "
                             "A matrix whose determinant is 0 squashes 2D space onto a line (or a point) and cannot be undone; it is called a singular matrix."},
                    {"kind": "example",
                     "text": "For A = [[3, 1], [2, 4]], det(A) = (3 × 4) − (1 × 2) = 12 − 2 = 10. "
                             "Because every unit square is multiplied in area by 10, a triangle of area 5 cm² is transformed to area 10 × 5 = 50 cm²."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to add the products ad + bc instead of subtracting ad − bc. "
                             "Test the identity matrix [[1, 0], [0, 1]] or two equal columns [[1, 1], [1, 1]]: equal columns must collapse to area 1 − 1 = 0."},
                    {"kind": "turn",
                     "text": "Calculate the determinant det(A) = ad − bc of the matrix A = [[4, 1], [2, 3]].",
                     "answer": "10",
                     "answerKey": k.one(k.num("10"), accepts=["10", "det(A) = 10"], rejects=["14", "5", "-10"])},
                    {"kind": "sayBack",
                     "text": "The determinant det(A) = ad − bc tells you how many times bigger every area becomes; when det(A) = 0, the matrix is singular."},
                ],
            },
            {
                "heading": "20.4 Arrows that stretch without turning",
                "teaches": ["eigenvector", "eigenvalue"],
                "steps": [
                    {"kind": "question",
                     "text": "When the matrix A = [[2, 1], [1, 2]] stretches the plane, most vectors get knocked off their starting line. "
                             "What happens to the diagonal vector v = (1, 1)?"},
                    {"kind": "idea",
                     "text": "A sends (1, 1) to (2×1 + 1×1, 1×1 + 2×1) = (3, 3), which is 3 × (1, 1). "
                             "It stays on the exact same 45° line and stretches to 3 times its length."},
                    {"kind": "picture",
                     "text": "Draw the two diagonal lines y = x through (1, 1) and y = −x through (1, −1). "
                             "Under [[2, 1], [1, 2]], the first diagonal stretches by 3 and the second diagonal stays at 1 × (1, −1)."},
                    {"kind": "reason",
                     "text": "Why do we care about the directions that do not turn? "
                             "Along those two axes, the matrix stretches by 3 in one direction and 1 in the other, scaling area by 3 × 1 = 3."},
                    {"kind": "name",
                     "text": "A non-zero vector v that a matrix A stretches without turning, so that Av = λv, is an eigenvector of A. "
                             "The scale factor λ (the Greek letter lambda) is its eigenvalue."},
                    {"kind": "example",
                     "text": "For A = [[2, 1], [1, 2]] and v = (1, −1), multiplying gives Av = (2 − 1, 1 − 2) = (1, −1) = 1 × v. "
                             "So (1, −1) is an eigenvector with eigenvalue λ = 1."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to call the zero vector (0, 0) an eigenvector because A(0, 0) = (0, 0). "
                             "The zero vector has no direction to keep; an eigenvector must be a non-zero vector."},
                    {"kind": "turn",
                     "text": "The matrix A = [[4, 2], [1, 3]] sends the eigenvector v = (2, 1) to Av = (10, 5). "
                             "Since (10, 5) = λ(2, 1), what is the eigenvalue λ?",
                     "answer": "5",
                     "answerKey": k.one(k.num("5"), accepts=["5", "λ = 5"], rejects=["2", "10", "15"])},
                    {"kind": "sayBack",
                     "text": "An eigenvector v stays on its own line when multiplied by A (Av = λv), and the stretch factor λ is its eigenvalue."},
                ],
            },
        ],
        "callouts": [
            {"kind": "predict", "title": "Predict first",
             "body": "In the figure, set all four entries to 1.5 (a = 1.5, b = 1.5, d = 1.5). "
                     "Predict what the determinant ad − bc will be when the two basis arrows lie on top of each other."},
            {"kind": "check", "title": "Explain it",
             "body": "Explain to a friend why a 2×2 rotation matrix through any angle θ always has determinant cos²θ + sin²θ = 1."},
            {"kind": "careful", "title": "Columns, not rows",
             "body": "When reading where a matrix sends the unit arrows î = (1, 0) and ĵ = (0, 1), always read down the first and second columns."},
        ],
        "debate": {
            "id": "debate-ch20-matrices",
            "oupUnitNumber": 13,
            "title": "When every entry is positive, can the area still be zero?",
            "contextPrompt": "The matrix A = [[2, 4], [1, 2]] transforms the 1 × 1 unit square. Asha and Rohan debate the area of the transformed shape.",
            "speakerAName": "Asha",
            "speakerAClaim": "Every number in [[2, 4], [1, 2]] is positive and at least 1, so the unit square must stretch into a bigger parallelogram.",
            "speakerBName": "Rohan",
            "speakerBClaim": "Column 2 is (4, 2), which is 2 times column 1, (2, 1). Both basis vectors land on the same line, so det(A) = 2(2) − 4(1) = 0 and the area collapses to 0.",
            "choices": [
                {"id": "ch20-a", "speakerLabel": "Asha is right (the area grows)",
                 "reasoningStatement": "Positive matrix entries always expand area.",
                 "isCorrect": False,
                 "socraticRebuttal": "Plot the two columns (2, 1) and (4, 2): both have gradient 1/2, so there is zero width between them."},
                {"id": "ch20-b", "speakerLabel": "Rohan is right (det(A) = 2(2) − 4(1) = 0)",
                 "reasoningStatement": "When one column is a scalar multiple of the other, the 2D square squashes flat onto a 1D line of area 0.",
                 "isCorrect": True,
                 "socraticRebuttal": "Yes. Because (4, 2) = 2 × (2, 1), both basis arrows lie on the line y = ½x, and det(A) = 4 − 4 = 0."},
                {"id": "ch20-c", "speakerLabel": "Neither. The area becomes negative.",
                 "reasoningStatement": "Subtracting bc makes the area negative.",
                 "isCorrect": False,
                 "socraticRebuttal": "Here ad = 4 and bc = 4, so ad − bc = 4 − 4 = 0."},
            ],
            "invariantTakeaway": "The determinant det(A) = ad − bc measures the area scale factor; if one column is a multiple of the other, det(A) = 0.",
        },
        "keyTerms": ["Basis vectors", "Linear transformation", "Matrix", "Matrix multiplication",
                     "Determinant", "Singular matrix", "Eigenvector", "Eigenvalue"],
        "widgets": ["w_atlas_linear_algebra", "w_atlas_matrix_sandbox"],
        "widgetText": {
            "w_atlas_linear_algebra": {
                "title": "Basis columns and the determinant parallelogram",
                "challengePrompt": "Set a = 2, b = 1 and d = 2 in the figure. "
                                   "Compare the area det(A) = ad − bc with the product of the two eigenvalues λ₁ × λ₂.",
                "cutaway": "The red arrow is column 1 and the blue arrow is column 2. "
                           "They span an amber parallelogram of area ad − bc, which also equals the product of the two eigenvalues λ₁ × λ₂.",
                "idealised": "The rule: det([[a, b], [c, d]]) = ad − bc = λ₁ × λ₂",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Set column 1 x (a) to 2, off-diagonal (b) to 1, and column 2 y (d) to 2."},
                    {"title": "2. Notice", "caption": "The amber parallelogram has area 2 × 2 − 1 × 1 = 3."},
                    {"title": "3. Match the rule", "caption": "The eigenvalues are λ₁ = 3 and λ₂ = 1, and 3 × 1 = 3 = det(A)."},
                    {"title": "4. Push it further", "caption": "Set a = 1.5, b = 1.5 and d = 1.5 so both arrows line up: det(A) drops to 0."},
                    {"title": "5. Draw it", "caption": "Draw the parallelogram spanned by (2, 1) and (1, 2) inside a 3 × 3 square and check its area is 3."},
                ],
            },
            "w_atlas_matrix_sandbox": {
                "title": "Stretching along eigenvector axes",
                "challengePrompt": "Set the off-diagonal slider b to 0 so the matrix is [[a, 0], [0, d]]. "
                                   "Predict which two directions are the eigenvectors and what their eigenvalues are.",
                "cutaway": "When b = 0, the red arrow stays on the x-axis with length a and the blue arrow stays on the y-axis with length d. "
                           "The axes themselves are the eigenvectors, with eigenvalues a and d.",
                "idealised": "The rule: Av = λv along each eigenvector axis",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Set a to 2.5, b to 0, and d to 1.5."},
                    {"title": "2. Notice", "caption": "The amber shape is a 2.5 by 1.5 rectangle of area 3.75."},
                    {"title": "3. Match the rule", "caption": "The eigenvalues are λ₁ = 2.5 and λ₂ = 1.5."},
                    {"title": "4. Push it further", "caption": "Slide b to −1.0 and watch the parallelogram shear while det(A) = ad − b²."},
                    {"title": "5. Draw it", "caption": "Write down a 2×2 matrix that doubles x and triples y, and find its determinant."},
                ],
            },
        },
        "atlasLessons": [
            {
                "title": "Chapter 20 · Reading a matrix by its columns",
                "question": "Why do the two columns of a 2×2 matrix tell you where every point (x, y) goes?",
                "explanation": "Every vector (x, y) is x î + y ĵ. "
                               "A linear transformation keeps sums and scalar multiples, so (x, y) lands at x × (column 1) + y × (column 2).",
                "limits": "The rule: [[a, b], [c, d]] (x, y) = (ax + by, cx + dy)",
            },
            {
                "title": "Chapter 20 · Subtracting the corners for ad − bc",
                "question": "Why is the area of the parallelogram spanned by (a, c) and (b, d) equal to ad − bc?",
                "explanation": "It fits inside an (a + b) by (c + d) bounding box. "
                               "Subtracting the four right-angled triangles around the edges (area ac + bd) and the two b × c corner rectangles (area 2bc) leaves ad − bc.",
                "limits": "The rule: det([[a, b], [c, d]]) = ad − bc",
            },
            {
                "title": "Chapter 20 · Eigenvectors as the steady axes of a transformation",
                "question": "What makes an eigenvector different from other vectors when a matrix acts on the plane?",
                "explanation": "Most vectors both stretch and turn when multiplied by A. "
                               "An eigenvector v stays on its own line, so Av = λv.",
                "limits": "The rule: Av = λv for a non-zero eigenvector v",
            },
        ],
        "visualMathTips": {
            "tip-matrix-det": {
                "title": "Why det(A) = ad − bc is area",
                "visualIntuition": "Place the parallelogram spanned by (a, c) and (b, d) inside a bounding rectangle of width a + b and height c + d.",
                "ahaMoment": "Taking away four right-angled triangles (total area ac + bd) and two b × c corner rectangles (total area 2bc) from (a + b)(c + d) leaves ad − bc.",
                "formula": "Area = det(A) = ad − bc",
            },
        },
        "schoolQuestions": {
            "q-oup-ch16-wb-challenge": {
                "workedExample": "Step 1: For A = [[3, 1], [2, 4]], the determinant is det(A) = (3 × 4) − (1 × 2) = 12 − 2 = 10.\n"
                                 "Step 2: The determinant is the area scale factor of the transformation.\n"
                                 "Step 3: Multiply the original triangle's area by 10: 10 × 5 cm² = 50 cm².",
                "fadedPrompt": "det(A) = (3 × 4) − (1 × 2) = ___, so the new area is 10 × 5 = ___ cm².",
            },
        },
    }


def cards(k):
    """The concept cards chapter 20 teaches."""
    return {
        "basis-vectors": {
            "name": "Basis vectors",
            "aliases": ["basis vectors", "basis vector", "î", "ĵ"],
            "oneSentence": "The two unit building-block arrows î = (1, 0) (1 step right) and ĵ = (0, 1) (1 step up) from which every vector (x, y) = xî + yĵ is built.",
            "picture": "A red arrow î of length 1 along the x-axis and a blue arrow ĵ of length 1 along the y-axis.",
            "steps": [
                "Write any vector (x, y) as x lots of î = (1, 0) plus y lots of ĵ = (0, 1).",
                "Find where a transformation sends î and where it sends ĵ.",
                "Combine x times the new î with y times the new ĵ.",
            ],
            "workedExample": "The vector (5, −3) is 5î − 3ĵ = 5(1, 0) − 3(0, 1).",
            "check": {
                "prompt": "If you take 4 steps of î = (1, 0) and 7 steps of ĵ = (0, 1), what column vector do you get?",
                "answer": "(4, 7)",
                "answerKey": k.one(k.seq("4", "7"), accepts=["(4, 7)", "4, 7"], rejects=["(7, 4)", "(1, 1)", "11"]),
            },
            "mixUp": {
                "name": "swapping î and ĵ",
                "how": "î = (1, 0) is the horizontal unit step; ĵ = (0, 1) is the vertical unit step.",
            },
            "standsOn": ["column-vector", "coordinates"],
        },
        "linear-transformation": {
            "name": "Linear transformation",
            "aliases": ["linear transformation", "linear transformations"],
            "oneSentence": "A move of the plane that keeps the origin (0, 0) fixed and keeps all grid lines straight, parallel and evenly spaced.",
            "picture": "A square grid stretched and tilted into an evenly spaced parallelogram grid with (0, 0) pinned in place.",
            "steps": [
                "Check that the origin (0, 0) stays at (0, 0).",
                "Check that straight grid lines stay straight, parallel and evenly spaced.",
                "Record where î = (1, 0) and ĵ = (0, 1) land to describe the whole move.",
            ],
            "workedExample": "Rotations about (0, 0), reflections through (0, 0), enlargements from (0, 0) and shears are all linear transformations.",
            "check": {
                "prompt": "Where must every linear transformation send the origin?",
                "answer": "(0, 0)",
                "answerKey": k.one(k.seq("0", "0"), accepts=["(0, 0)", "0, 0"], rejects=["(1, 0)", "(1, 1)", "(0, 1)"]),
            },
            "mixUp": {
                "with": "translation",
                "how": "A translation slides the origin (0, 0) to a new point, so a non-zero translation is not a linear transformation.",
            },
            "standsOn": ["transformation", "coordinates"],
        },
        "matrix": {
            "name": "Matrix",
            "aliases": ["matrix", "matrices", "2×2 matrix", "2×2 matrices"],
            "oneSentence": "A rectangular grid of numbers [[a, b], [c, d]] whose columns record where the basis vectors î and ĵ land under a linear transformation.",
            "picture": "A 2×2 box with red column 1 = (a, c) on the left and blue column 2 = (b, d) on the right.",
            "steps": [
                "Read down the first column (a, c) to see where î = (1, 0) lands.",
                "Read down the second column (b, d) to see where ĵ = (0, 1) lands.",
                "To transform (x, y), compute x(a, c) + y(b, d) = (ax + by, cx + dy).",
            ],
            "workedExample": "The matrix [[3, 1], [2, 4]] has first column (3, 2) and second column (1, 4).",
            "check": {
                "prompt": "Where does the matrix [[5, 2], [1, 6]] send the basis vector î = (1, 0)?",
                "answer": "(5, 1)",
                "answerKey": k.one(k.seq("5", "1"), accepts=["(5, 1)", "5, 1"], rejects=["(5, 2)", "(2, 6)", "(1, 6)"]),
            },
            "mixUp": {
                "name": "reading across the top row instead of down the first column",
                "how": "(5, 2) is the top row; the image of î = (1, 0) is the first column, (5, 1).",
            },
            "standsOn": [],
        },
        "matrix-multiplication": {
            "name": "Matrix multiplication",
            "aliases": ["matrix multiplication", "multiplying matrices"],
            "oneSentence": "Applying one matrix after another by taking the dot product of each row of the left matrix with each column of the right.",
            "picture": "Row (a, b) meeting column (x, y) to give ax + by on top, and row (c, d) meeting (x, y) to give cx + dy below.",
            "steps": [
                "Take the top row of the matrix and form its dot product with the column vector: ax + by.",
                "Take the bottom row of the matrix and form its dot product with the column vector: cx + dy.",
                "Remember that for two matrices, AB means 'apply B first, then apply A'.",
            ],
            "workedExample": "[[3, 1], [2, 4]] multiplied by (2, 5) gives (3×2 + 1×5, 2×2 + 4×5) = (11, 24).",
            "check": {
                "prompt": "Multiply the matrix [[2, 3], [1, 4]] by the column vector (3, 1).",
                "answer": "(9, 7)",
                "answerKey": k.one(k.seq("9", "7"), accepts=["(9, 7)", "9, 7"], rejects=["(6, 4)", "(7, 9)", "(5, 5)"]),
            },
            "mixUp": {
                "name": "reversing the order of two matrices",
                "how": "Matrix multiplication is not commutative: AB and BA usually give different results.",
            },
            "standsOn": ["matrix", "dot-product"],
        },
        "determinant": {
            "name": "Determinant",
            "symbol": "det",
            "aliases": ["determinant", "determinants", "det"],
            "oneSentence": "For a 2×2 matrix [[a, b], [c, d]], the number det(A) = ad − bc, which gives the signed area of the parallelogram formed by its two columns.",
            "picture": "The 1 × 1 unit square stretched into an amber parallelogram of area ad − bc.",
            "steps": [
                "Multiply the main diagonal entries: a × d.",
                "Multiply the other diagonal entries: b × c.",
                "Subtract: det(A) = ad − bc. Multiply any shape's area by |det(A)| to find its new area.",
            ],
            "workedExample": "For [[5, 2], [3, 4]], the determinant is (5 × 4) − (2 × 3) = 20 − 6 = 14.",
            "check": {
                "prompt": "What is the determinant det(A) of the matrix A = [[6, 2], [1, 3]]?",
                "answer": "16",
                "answerKey": k.one(k.num("16"), accepts=["16", "det(A) = 16"], rejects=["20", "18", "-16"]),
            },
            "mixUp": {
                "name": "adding ad + bc instead of subtracting",
                "how": "Always subtract the off-diagonal product: (6 × 3) − (2 × 1) = 18 − 2 = 16, not 18 + 2 = 20.",
            },
            "standsOn": ["matrix", "area"],
        },
        "singular-matrix": {
            "name": "Singular matrix",
            "aliases": ["singular matrix", "singular matrices", "singular"],
            "oneSentence": "A matrix whose determinant is 0, because its columns lie on the same line and squash 2D space down to zero area.",
            "picture": "Both basis arrows landing on the same line, flattening the unit square into a thin segment with area 0.",
            "steps": [
                "Compute the determinant ad − bc.",
                "If ad − bc = 0, one column is a scalar multiple of the other.",
                "Conclude that the matrix is singular and cannot be reversed.",
            ],
            "workedExample": "For [[2, 6], [1, 3]], det = (2 × 3) − (6 × 1) = 6 − 6 = 0, so the matrix is singular.",
            "check": {
                "prompt": "The matrix [[3, 6], [2, k]] is singular (its determinant is 0). What is the value of k?",
                "answer": "4",
                "answerKey": k.one(k.num("4"), accepts=["4", "k = 4"], rejects=["12", "3", "-4"]),
            },
            "mixUp": {
                "name": "thinking only the all-zero matrix is singular",
                "how": "A matrix full of positive numbers like [[3, 6], [2, 4]] is still singular whenever ad = bc.",
            },
            "standsOn": ["determinant"],
        },
        "eigenvector": {
            "name": "Eigenvector",
            "aliases": ["eigenvector", "eigenvectors"],
            "oneSentence": "A non-zero vector v whose direction is unchanged when multiplied by a matrix A, so that Av = λv is a scalar multiple of v.",
            "picture": "Green arrows along the special axes of a stretch that grow or shrink along their own line while other arrows turn.",
            "steps": [
                "Multiply the matrix A by the non-zero candidate vector v.",
                "Check whether the output Av is a scalar multiple λv of the input v.",
                "If yes, v is an eigenvector of A.",
            ],
            "workedExample": "For A = [[3, 0], [0, 5]], A(1, 0) = (3, 0) = 3(1, 0), so (1, 0) is an eigenvector.",
            "check": {
                "prompt": "For A = [[2, 1], [1, 2]], multiplying A by v = (1, 1) gives (3, 3) = 3v. "
                          "If you use w = (5, 5) on the same line, what is Aw?",
                "answer": "(15, 15)",
                "answerKey": k.one(k.seq("15", "15"), accepts=["(15, 15)", "15, 15"], rejects=["(10, 10)", "(5, 5)", "(8, 8)"]),
            },
            "mixUp": {
                "with": "eigenvalue",
                "how": "The eigenvector is the arrow v = (1, 1) that keeps its direction; the eigenvalue is the number λ = 3 that it stretches by.",
            },
            "standsOn": ["matrix", "scalar-multiple", "angle"],
        },
        "eigenvalue": {
            "name": "Eigenvalue",
            "symbol": "λ",
            "aliases": ["eigenvalue", "eigenvalues", "λ"],
            "oneSentence": "The scale factor λ (lambda) by which a matrix stretches or flips its eigenvector: Av = λv.",
            "picture": "An eigenvector arrow of length 1 stretched to length λ along its own line.",
            "steps": [
                "Compute Av for an eigenvector v.",
                "Divide a non-zero component of Av by the matching component of v.",
                "Check that λ₁ × λ₂ equals det(A) and λ₁ + λ₂ equals a + d.",
            ],
            "workedExample": "When A sends the eigenvector (1, 2) to (4, 8), the eigenvalue is λ = 4 ÷ 1 = 4.",
            "check": {
                "prompt": "A matrix A sends its eigenvector v = (3, −1) to Av = (18, −6). What is the eigenvalue λ?",
                "answer": "6",
                "answerKey": k.one(k.num("6"), accepts=["6", "λ = 6"], rejects=["15", "3", "-6"]),
            },
            "mixUp": {
                "with": "determinant",
                "how": "An eigenvalue λ stretches length along one special line; the determinant λ₁ × λ₂ scales 2D area.",
            },
            "standsOn": ["eigenvector", "determinant"],
        },
    }


def sums():
    """Every sum chapter 20 and its cards state, recomputed."""
    A = [[3, 1], [2, 4]]
    return [
        # Skill card and school question q-oup-ch16-wb-challenge
        ("skill A(2,1), det(A), 10*5", (mat_vec(A, (2, 1)), det2(3, 1, 2, 4), 10 * 5), ((7, 8), 10, 50)),
        # Bridge & 20.3
        ("bridge [[2,1],[1,2]] det and eigen",
         (det2(2, 1, 1, 2), mat_vec([[2, 1], [1, 2]], (1, 1)), mat_vec([[2, 1], [1, 2]], (1, -1))),
         (3, (3, 3), (1, -1))),
        # 20.1
        ("20.1 [[2,0],[0,3]] on (4,5)", mat_vec([[2, 0], [0, 3]], (4, 5)), (8, 15)),
        ("turn 20.1 [[4,2],[1,3]] on (1,2)", mat_vec([[4, 2], [1, 3]], (1, 2)), (8, 7)),
        # 20.2
        ("20.2 AB columns",
         (mat_vec([[1, 2], [0, 1]], (2, 1)), mat_vec([[1, 2], [0, 1]], (0, 3))),
         ((4, 1), (6, 3))),
        ("turn 20.2 [[2,1],[0,3]] on (4,2)", mat_vec([[2, 1], [0, 3]], (4, 2)), (10, 6)),
        # 20.3 and debate
        ("20.3 singular [[2,4],[1,2]]", det2(2, 4, 1, 2), 0),
        ("turn 20.3 det([[4,1],[2,3]])", (det2(4, 1, 2, 3), 4 * 3 + 1 * 2), (10, 14)),
        # 20.4
        ("turn 20.4 [[4,2],[1,3]] on (2,1)", (mat_vec([[4, 2], [1, 3]], (2, 1)), 10 // 2), ((10, 5), 5)),
        # Widgets
        ("widget sandbox", (det2(1.5, 1.5, 1.5, 1.5), 2.5 * 1.5), (0.0, 3.75)),
        # Cards
        ("matrix-multiplication card and check",
         (mat_vec([[3, 1], [2, 4]], (2, 5)), mat_vec([[2, 3], [1, 4]], (3, 1))),
         ((11, 24), (9, 7))),
        ("determinant card and check", (det2(5, 2, 3, 4), det2(6, 2, 1, 3), 6 * 3 + 2 * 1), (14, 16, 20)),
        ("singular-matrix card and check", (det2(2, 6, 1, 3), (6 * 2) // 3), (0, 4)),
        ("eigenvector check", mat_vec([[2, 1], [1, 2]], (5, 5)), (15, 15)),
        ("eigenvalue card and check", (8 // 2, 18 // 3), (4, 6)),
    ]


def answers():
    """Chapter 20's turn answers and its cards' check answers, computed."""
    fmt = lambda v: f"({v[0]}, {v[1]})".replace("-", "−")
    return {
        "ch20-s1-turn": fmt(mat_vec([[4, 2], [1, 3]], (1, 2))),
        "ch20-s2-turn": fmt(mat_vec([[2, 1], [0, 3]], (4, 2))),
        "ch20-s3-turn": det2(4, 1, 2, 3),
        "ch20-s4-turn": mat_vec([[4, 2], [1, 3]], (2, 1))[0] // 2,
        "basis-vectors-check": fmt((4, 7)),
        "linear-transformation-check": fmt((0, 0)),
        "matrix-check": fmt((5, 1)),
        "matrix-multiplication-check": fmt(mat_vec([[2, 3], [1, 4]], (3, 1))),
        "determinant-check": det2(6, 2, 1, 3),
        "singular-matrix-check": (6 * 2) // 3,
        "eigenvector-check": fmt(mat_vec([[2, 1], [1, 2]], (5, 5))),
        "eigenvalue-check": 18 // 3,
    }
