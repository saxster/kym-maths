"""
Chapter 19, written by hand to docs/CONTENT_BRIEF.md. It maps to OUP Unit 16 (Vectors).

Each section teaches one idea in nine steps, in this order: question, idea, picture, reason, name,
example, mistake, turn, sayBack. A section's `teaches` lists the concept cards whose names first
appear in its `name` step. `build(k)` returns the chapter and `cards(k)` its concept cards; both take the
exporter's answer-key helpers.
"""

import math


def vec_add(u, v):
    return (u[0] + v[0], u[1] + v[1])


def vec_sub(u, v):
    return (u[0] - v[0], u[1] - v[1])


def vec_scale(k, u):
    return (k * u[0], k * u[1])


def vec_mag(u):
    sq = u[0] ** 2 + u[1] ** 2
    root = math.isqrt(sq)
    return root if root * root == sq else round(math.sqrt(sq), 2)


def dot_prod(u, v):
    return u[0] * v[0] + u[1] * v[1]


def build(k):
    return {
        "number": 19,
        "title": "Vectors",
        "subtitle": "School book chapter 16 · Chaining journeys nose to tail, finding arrow lengths with Pythagoras, "
                    "proving midsegments, and testing right angles with the dot product",
        "hookSummary": "Walk 3 steps East and 4 steps North, then 2 steps East and 1 step South. "
                       "Where do you finish, and how far in a straight line are you from where you started?",
        "beyondSchoolBook": False,
        "skillCard": {
            "skill": "Adding, subtracting and scaling column vectors, finding their magnitude with Pythagoras' theorem, and using vectors to prove lines are parallel or collinear",
            "sheCan": {
                "prompt": "With no calculator: for column vectors a = (3, 4) and b = (2, −1), work out 2a − 3b and find the exact length of a. "
                          "And if AB = (4, −2) and BC = (−1, 7), what is the single journey AC?",
                "answer": "2a − 3b = (6 − 6, 8 − (−3)) = (0, 11). "
                          "The length of a is √(3² + 4²) = √25 = 5. "
                          "And AC = AB + BC = (4 − 1, −2 + 7) = (3, 5).",
            },
            "whyItMatters": "Pilots correcting for wind, game engines moving characters and physicists adding forces all use arrows with both length and direction.",
            "standsOn": [
                "Chapter 8: parallel lines and midpoints",
                "Chapter 11: column vectors for translations",
                "Chapter 12: Pythagoras' theorem and cosine",
            ],
            "unlocks": [
                "Chapter 20: matrices that transform every vector in the plane at once",
                "Physics: resolving forces on a ramp and adding velocities",
                "3D graphics: lighting and camera angles using the dot product",
            ],
        },
        "intuitionToFormula": {
            "concreteAction": "In the figure, slide the horizontal steps of vector a and vector b, then turn the angle between them to 90°.",
            "ahaInvariant": "Placing the tail of b at the tip of a makes the shortcut from start to finish equal to a + b. "
                            "When the angle between two vectors reaches 90°, their dot product drops to 0.",
            "formulaDisplay": "AB = b − a,   |v| = √(x² + y²),   a · b = x₁x₂ + y₁y₂ = |a||b| cos θ",
            "termMappings": [
                {"symbol": "a + b", "visualPart": "The green shortcut arrow from the tail of a to the tip of b", "colorRole": "green",
                 "meaning": "The single displacement that replaces the two-stage journey"},
                {"symbol": "|v| = √(x² + y²)", "visualPart": "The length of the arrow as the hypotenuse of its steps", "colorRole": "red",
                 "meaning": "Straight-line distance found by Pythagoras' theorem"},
                {"symbol": "a · b", "visualPart": "How much one vector points along the other", "colorRole": "amber",
                 "meaning": "Zero when the two vectors meet at a right angle (90°)"},
            ],
            "atlasFigureRef": "maths/multivariable/index.html#2",
        },
        "sections": [
            {
                "heading": "19.1 Nose-to-tail journeys and going backwards",
                "figure": True,
                "teaches": ["position-vector", "adding-vectors", "zero-vector"],
                "steps": [
                    {"kind": "question",
                     "text": "From the origin O(0, 0), point A is at (2, 5) and point B is at (6, 8). "
                             "How do you travel from A to B by going back through O?"},
                    {"kind": "idea",
                     "text": "Walk backwards from A to O, which is (−2, −5), and then forwards from O to B, which is (6, 8). "
                             "Together that is (6 − 2, 8 − 5) = (4, 3), so AB = OB − OA."},
                    {"kind": "picture",
                     "text": "In the figure, follow the red arrow a from the start, then the blue arrow b from the red tip. "
                             "The green arrow goes straight from the first tail to the second tip."},
                    {"kind": "reason",
                     "text": "Why does AB equal OB − OA and not OA − OB? "
                             "Starting at A and adding AB lands you at B: OA + AB = OB, so subtracting OA gives AB = OB − OA, 'destination minus start'."},
                    {"kind": "name",
                     "text": "The vector from the origin O to a point A is the position vector of A, written OA or a. "
                             "Chaining two vectors nose to tail by adding their steps is adding vectors (AB + BC = AC). "
                             "A journey that finishes where it started, such as AB + BA = (0, 0), gives the zero vector, written 0."},
                    {"kind": "example",
                     "text": "If AB = (4, −2) and BC = (−1, 7), then by adding vectors AC = AB + BC = (4 + (−1), −2 + 7) = (3, 5)."},
                    {"kind": "mistake",
                     "text": "The tempting slip when finding AB from position vectors is to subtract in the order OA − OB. "
                             "Always do destination minus start: AB = OB − OA."},
                    {"kind": "turn",
                     "text": "Point A has position vector OA = (1, 4) and point B has position vector OB = (6, 2). "
                             "What is the column vector AB = OB − OA?",
                     "answer": "(5, −2)",
                     "answerKey": k.one(k.seq("5", "-2"), accepts=["(5, −2)", "(5, -2)", "5, -2"], rejects=["(-5, 2)", "(7, 6)", "(5, 2)"])},
                    {"kind": "sayBack",
                     "text": "Position vectors start at O; adding vectors chains them nose to tail (AB + BC = AC), and AB = OB − OA."},
                ],
            },
            {
                "heading": "19.2 Length of an arrow and stretching it",
                "teaches": ["magnitude", "scalar-multiple"],
                "steps": [
                    {"kind": "question",
                     "text": "A drone flies along the column vector a = (3, 4), moving 3 m East and 4 m North. "
                             "How far is it in a straight line from its take-off spot, and where does 2a take it?"},
                    {"kind": "idea",
                     "text": "The 3 m step across and 4 m step up make a right-angled triangle, so the straight-line distance is √(3² + 4²) = √25 = 5 m. "
                             "And 2a doubles both steps to (6, 8), which is 10 m long in the same direction."},
                    {"kind": "picture",
                     "text": "Draw the right-angled triangle with base 3 and height 4 under the arrow (3, 4), then extend the arrow to twice its length at (6, 8)."},
                    {"kind": "reason",
                     "text": "Why does (−3)² still give +9 when a component is negative? "
                             "In v = (5, −12), the step −12 goes downwards, but its length is 12, and (−12)² = +144."},
                    {"kind": "name",
                     "text": "The length of a vector v = (x, y), found by Pythagoras' theorem √(x² + y²), is its magnitude, written |v|. "
                             "Multiplying both steps of v by a number k gives a scalar multiple, kv = (kx, ky)."},
                    {"kind": "example",
                     "text": "For a = (3, 4) and b = (2, −1), the combination 2a − 3b is (6, 8) − (6, −3) = (0, 11), "
                             "and the magnitude |a| is √(3² + 4²) = 5."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to think |a + b| equals |a| + |b|. "
                             "For a = (3, 4) of magnitude 5 and b = (5, −4), the sum a + b is (8, 0) of magnitude 8, which is shorter than the two separate paths."},
                    {"kind": "turn",
                     "text": "Find the magnitude |v| of the column vector v = (5, −12).",
                     "answer": "13",
                     "answerKey": k.one(k.num("13"), accepts=["13", "|v| = 13"], rejects=["7", "17", "169"])},
                    {"kind": "sayBack",
                     "text": "The magnitude |v| = √(x² + y²) is the arrow's length by Pythagoras, and a scalar multiple kv scales both components by k."},
                ],
            },
            {
                "heading": "19.3 Proving two lines are parallel or in one line",
                "teaches": ["collinear"],
                "steps": [
                    {"kind": "question",
                     "text": "In triangle OAB, M is the midpoint of OA and N is the midpoint of OB. "
                             "How can vectors prove in one line that MN is both parallel to AB and half as long?"},
                    {"kind": "idea",
                     "text": "Write OA = a and OB = b, so AB = b − a. "
                             "To go from M to N, go ½a back to O and ½b out to N: MN = −½a + ½b = ½(b − a) = ½AB."},
                    {"kind": "picture",
                     "text": "Draw triangle OAB with M halfway along OA and N halfway along OB. "
                             "Mark AB as b − a and the midsegment MN as ½(b − a)."},
                    {"kind": "reason",
                     "text": "Why does MN = ½AB prove two geometric facts at once? "
                             "MN is a scalar multiple of AB, so they are parallel, and the ½ shows MN is half as long."},
                    {"kind": "name",
                     "text": "Points that lie on the same straight line are collinear. "
                             "If AB is a scalar multiple of BC, they are parallel and share B, so A, B and C are collinear."},
                    {"kind": "example",
                     "text": "If AB = (2, 3) and BC = (6, 9), then BC = 3 × AB. "
                             "Because BC is a scalar multiple of AB and they share point B, the points A, B and C are collinear."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to stop after saying 'BC = 3 × AB so they are parallel'. "
                             "Parallel lines can be separate; you must also state that they share the common point B to prove A, B and C are collinear."},
                    {"kind": "turn",
                     "text": "Given AB = (3, −2) and BC = (k, −6), for what value of k are the points A, B and C collinear?",
                     "answer": "9",
                     "answerKey": k.one(k.num("9"), accepts=["9", "k = 9"], rejects=["6", "-9", "1"])},
                    {"kind": "sayBack",
                     "text": "When one vector is a scalar multiple of another they are parallel; if they also share a point, the three points are collinear."},
                ],
            },
            {
                "heading": "19.4 Testing for a right angle with the dot product",
                "teaches": ["dot-product"],
                "steps": [
                    {"kind": "question",
                     "text": "Without a grid or protractor, how can you tell in two seconds that u = (3, 4) and v = (−4, 3) meet at 90°?"},
                    {"kind": "idea",
                     "text": "Multiply their x-steps together, multiply their y-steps together, and add: 3 × (−4) + 4 × 3 = −12 + 12 = 0. "
                             "Whenever that sum is 0 for two non-zero vectors, the angle between them is 90°."},
                    {"kind": "picture",
                     "text": "Draw u = (3, 4) going 3 across and 4 up, and v = (−4, 3) going 4 left and 3 up. "
                             "The second triangle is the first triangle turned through 90°."},
                    {"kind": "reason",
                     "text": "Why does x₁x₂ + y₁y₂ equal 0 at 90°? This formula goes past the school book. "
                             "By the cosine rule on u, v and u − v, x₁x₂ + y₁y₂ = |u||v| cos θ, and cos 90° = 0."},
                    {"kind": "name",
                     "text": "For u = (x₁, y₁) and v = (x₂, y₂), the number x₁x₂ + y₁y₂ = |u||v| cos θ is the dot product, written u · v. "
                             "Notice that the dot product of two vectors is a single number (a scalar), not a vector."},
                    {"kind": "example",
                     "text": "For u = (2, 5) and v = (4, −1), the dot product is u · v = (2 × 4) + (5 × (−1)) = 8 − 5 = 3. "
                             "Since 3 > 0, the angle between them is acute (less than 90°)."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to write the dot product as a column vector (x₁x₂, y₁y₂). "
                             "Add the two products together so the answer is a single number."},
                    {"kind": "turn",
                     "text": "Calculate the dot product u · v of u = (4, 3) and v = (2, −1).",
                     "answer": "5",
                     "answerKey": k.one(k.num("5"), accepts=["5", "u · v = 5"], rejects=["11", "8", "-3"])},
                    {"kind": "sayBack",
                     "text": "The dot product u · v = x₁x₂ + y₁y₂ = |u||v| cos θ is a single number that equals 0 whenever two vectors are perpendicular."},
                ],
            },
        ],
        "callouts": [
            {"kind": "predict", "title": "Predict first",
             "body": "In the figure, set the angle between the two vectors to 90°. "
                     "Predict what value the dot product will show before you move the angle slider."},
            {"kind": "check", "title": "Explain it",
             "body": "Explain to a friend why walking 3 m East and 4 m North gives a vector of magnitude 5 m, not 7 m."},
            {"kind": "careful", "title": "Destination minus start",
             "body": "To find the vector AB from position vectors OA and OB, always subtract the starting point from the finishing point: AB = OB − OA."},
        ],
        "debate": {
            "id": "debate-ch19-vectors",
            "oupUnitNumber": 16,
            "title": "Do vector lengths add up directly?",
            "contextPrompt": "A drone flies along vector a = (3, 4) of magnitude 5 m, and then along vector b = (5, −4). Asha and Rohan debate the magnitude of the resultant journey a + b.",
            "speakerAName": "Asha",
            "speakerAClaim": "To find the length of a + b, add the two separate lengths together: |a| + |b|.",
            "speakerBName": "Rohan",
            "speakerBClaim": "Add the components first: a + b = (3 + 5, 4 − 4) = (8, 0). The +4 North and −4 South cancel out, leaving a straight 8 m journey East.",
            "choices": [
                {"id": "ch19-a", "speakerLabel": "Asha is right (add the two lengths)",
                 "reasoningStatement": "The magnitude of a sum is the sum of the magnitudes.",
                 "isCorrect": False,
                 "socraticRebuttal": "Lengths add directly only when both vectors point in the exact same direction. Here the second leg turns back South."},
                {"id": "ch19-b", "speakerLabel": "Rohan is right (a + b = (8, 0), magnitude 8 m)",
                 "reasoningStatement": "Vectors add nose to tail by their horizontal and vertical steps, and the straight shortcut is shorter than the detour.",
                 "isCorrect": True,
                 "socraticRebuttal": "Yes. Adding components gives (3 + 5, 4 − 4) = (8, 0), which has magnitude 8 m."},
                {"id": "ch19-c", "speakerLabel": "Neither. Multiply the components to get (15, −16).",
                 "reasoningStatement": "Combining two vectors multiplies their steps.",
                 "isCorrect": False,
                 "socraticRebuttal": "Walking 3 m East and then 5 m East puts you 3 + 5 = 8 m East, not 15 m."},
            ],
            "invariantTakeaway": "Add vectors by their components nose to tail first, then find the magnitude of the resultant vector.",
        },
        "keyTerms": ["Column vector", "Position vector", "Adding vectors", "Zero vector",
                     "Magnitude", "Scalar multiple", "Collinear", "Dot product"],
        "widgets": ["w_vector_tip_to_tail_lab", "w_vector_geometric_proof_studio"],
        "widgetText": {
            "w_vector_tip_to_tail_lab": {
                "title": "Chaining vectors nose to tail",
                "challengePrompt": "Change the lengths of vectors a and b and the angle between them. "
                                   "Watch the green resultant arrow a + b and the dot product.",
                "cutaway": "Placing the tail of b at the tip of a forms a triangle whose third side is the resultant a + b. "
                           "At 90°, the two vectors are perpendicular and their dot product is 0.",
                "idealised": "The rule: a + b = (x₁ + x₂, y₁ + y₂), and a · b = |a||b| cos θ",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Set vector a to 3 and vector b to 4, with 90° between them."},
                    {"title": "2. Notice", "caption": "At 90° the dot product is 0 and the resultant length is √(3² + 4²) = 5."},
                    {"title": "3. Match the rule", "caption": "Close the angle to 0°: both arrows line up and the resultant length is 3 + 4 = 7."},
                    {"title": "4. Push it further", "caption": "Open the angle to 120° and notice that the dot product becomes negative."},
                    {"title": "5. Draw it", "caption": "Draw a = (3, 1) and b = (1, 3) nose to tail on squared paper and read off a + b = (4, 4)."},
                ],
            },
            "w_vector_geometric_proof_studio": {
                "title": "Vector proof of the triangle midsegment",
                "challengePrompt": "Follow the path from midpoint M of OA through O to midpoint N of OB. "
                                   "Express MN in terms of a and b and compare it with AB = b − a.",
                "cutaway": "Because OM = ½a and ON = ½b, the vector from M to N is ON − OM = ½b − ½a = ½(b − a) = ½AB. "
                           "One line of vector algebra proves MN is both parallel to AB and half its length.",
                "idealised": "The rule: MN = ½(b − a) = ½AB",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Label OA as vector a and OB as vector b, so AB = b − a."},
                    {"title": "2. Notice", "caption": "Midpoint M sits at ½a and midpoint N sits at ½b."},
                    {"title": "3. Match the rule", "caption": "Travel from M to N via O: MN = −½a + ½b = ½(b − a)."},
                    {"title": "4. Push it further", "caption": "What if P and Q sit one third of the way along OA and OB? Then PQ = ⅓AB."},
                    {"title": "5. Draw it", "caption": "Draw any triangle OAB, mark the midpoints M and N, and label MN = ½(b − a)."},
                ],
            },
        },
        "atlasLessons": [
            {
                "title": "Chapter 19 · Why vectors add nose to tail",
                "question": "Why do we add the x-steps and y-steps separately when chaining two vectors?",
                "explanation": "A step of x₁ East followed by x₂ East puts you x₁ + x₂ East. "
                               "A step of y₁ North followed by y₂ North puts you y₁ + y₂ North.",
                "limits": "The rule: (x₁, y₁) + (x₂, y₂) = (x₁ + x₂, y₁ + y₂)",
            },
            {
                "title": "Chapter 19 · Proving geometry with scalar multiples",
                "question": "How does showing u = kv prove two lines are parallel?",
                "explanation": "Multiplying both steps of v by k scales the length by |k| while keeping the slope y ÷ x unchanged. "
                               "So u and v share the same direction.",
                "limits": "The rule: u = kv means u is parallel to v and |k| times as long",
            },
            {
                "title": "Chapter 19 · The dot product and right angles",
                "question": "Why is the dot product u · v equal to 0 when two vectors are perpendicular?",
                "explanation": "The dot product measures |u||v| cos θ, the length of one vector multiplied by the shadow of the other along it. "
                               "At 90° a vector casts zero shadow along the line perpendicular to it.",
                "limits": "The rule: u · v = x₁x₂ + y₁y₂ = 0 at 90°",
            },
        ],
        "visualMathTips": {},
        "schoolTopics": {
            "16.1": "A vector has both magnitude (length) and direction, written as a column vector (x, y). "
                    "Multiplying by a scalar scales both components, and the magnitude is |v| = √(x² + y²) by Pythagoras' theorem.",
            "16.2": "Vectors add nose to tail by the triangle law AB + BC = AC, and AB = OB − OA. "
                    "Showing one vector is a scalar multiple of another proves they are parallel, or collinear if they share a point.",
        },
        "schoolQuestions": {
            "q-oup-ch16-sb": {
                "workedExample": "Step 1: Scale each vector: 2a = 2(3, 4) = (6, 8) and 3b = 3(2, −1) = (6, −3).\n"
                                 "Step 2: Subtract component by component: 2a − 3b = (6 − 6, 8 − (−3)) = (0, 11).\n"
                                 "Step 3: By Pythagoras' theorem, |a| = √(3² + 4²) = √(9 + 16) = √25 = 5.",
                "fadedPrompt": "2a − 3b = (0, 11) and |a| = √(3² + 4²) = ___.",
            },
            "q-oup-ch16-wb-focus": {
                "workedExample": "Step 1: Chain the journeys nose to tail using the triangle law: AC = AB + BC.\n"
                                 "Step 2: Add the horizontal and vertical components: (4 + (−1), −2 + 7) = (3, 5).",
                "fadedPrompt": "AC = AB + BC = (4 − 1, −2 + 7) = ___.",
            },
            "q-oup-ch16-wb-practice": {
                "workedExample": "Step 1: Since M is the midpoint of OA and N is the midpoint of OB, OM = ½a and ON = ½b.\n"
                                 "Step 2: Go from M to O and then from O to N: MN = −OM + ON = −½a + ½b = ½(b − a).",
                "fadedPrompt": "MN = ON − OM = ½b − ½a = ___.",
            },
        },
    }


def cards(k):
    """The concept cards chapter 19 teaches."""
    return {
        "position-vector": {
            "name": "Position vector",
            "aliases": ["position vector", "position vectors"],
            "oneSentence": "The vector from the origin O(0, 0) to a point P, whose components match the coordinates of P.",
            "picture": "An arrow pinned at the origin O(0, 0) pointing out to P(3, 4).",
            "steps": [
                "Read the coordinates (x, y) of the point P.",
                "Write those steps as the column vector OP = (x, y) starting at the origin O.",
                "To find the vector from A to B, subtract: AB = OB − OA.",
            ],
            "workedExample": "If A is (2, 1) and B is (7, 5), their position vectors are OA = (2, 1) and OB = (7, 5), so AB = (7 − 2, 5 − 1) = (5, 4).",
            "check": {
                "prompt": "Points A and B have position vectors OA = (3, 2) and OB = (8, 9). What is the vector AB?",
                "answer": "(5, 7)",
                "answerKey": k.one(k.seq("5", "7"), accepts=["(5, 7)", "5, 7"], rejects=["(-5, -7)", "(11, 11)", "(7, 5)"]),
            },
            "mixUp": {
                "name": "subtracting start minus destination",
                "how": "OA − OB = (−5, −7) points backwards from B to A. For AB, always compute OB − OA = (5, 7).",
            },
            "standsOn": ["column-vector", "coordinates"],
        },
        "adding-vectors": {
            "name": "Adding vectors",
            "aliases": ["adding vectors", "triangle law", "vector addition"],
            "oneSentence": "Chaining two vectors nose to tail by adding their horizontal steps and adding their vertical steps: AB + BC = AC.",
            "picture": "Red arrow a followed nose-to-tail by blue arrow b, with green arrow a + b taking the straight shortcut.",
            "steps": [
                "Place the tail of the second vector at the tip of the first.",
                "Add the top numbers (horizontal steps) together.",
                "Add the bottom numbers (vertical steps) together.",
            ],
            "workedExample": "Adding (3, 2) and (4, −5) gives (3 + 4, 2 + (−5)) = (7, −3).",
            "check": {
                "prompt": "If AB = (2, 6) and BC = (5, −1), what is AC = AB + BC?",
                "answer": "(7, 5)",
                "answerKey": k.one(k.seq("7", "5"), accepts=["(7, 5)", "7, 5"], rejects=["(-3, 7)", "(7, 7)", "(10, -6)"]),
            },
            "mixUp": {
                "name": "adding top to bottom inside the same vector",
                "how": "Keep horizontal steps with horizontal steps (2 + 5 = 7) and vertical steps with vertical steps (6 − 1 = 5).",
            },
            "standsOn": ["column-vector", "negative-number"],
            "footing": "vectors",
        },
        "zero-vector": {
            "name": "Zero vector",
            "aliases": ["zero vector", "zero vectors"],
            "oneSentence": "The vector (0, 0), written 0, which has length 0 and represents a journey that finishes where it started.",
            "picture": "Walking along AB from A to B and then along BA = −AB back to A, ending with zero net displacement.",
            "steps": [
                "Add a vector v = (x, y) to its opposite −v = (−x, −y).",
                "Both components cancel to 0: (x − x, y − y) = (0, 0).",
                "Any closed loop of vectors, such as AB + BC + CA, adds to the zero vector.",
            ],
            "workedExample": "For AB = (4, −3) and BA = (−4, 3), the round trip is AB + BA = (0, 0).",
            "check": {
                "prompt": "In any triangle ABC, what is the sum of the three vectors AB + BC + CA around the closed loop?",
                "answer": "(0, 0)",
                "answerKey": k.one(k.seq("0", "0"), k.num("0"), accepts=["(0, 0)", "0", "0, 0"], rejects=["1", "2", "(1, 1)"]),
            },
            "mixUp": {
                "name": "total distance walked around the loop",
                "how": "You walked a positive perimeter around the triangle, but your net displacement from A back to A is (0, 0).",
            },
            "standsOn": ["adding-vectors"],
        },
        "magnitude": {
            "name": "Magnitude",
            "symbol": "|v|",
            "aliases": ["magnitude", "magnitudes", "|v|", "|a|", "|b|"],
            "oneSentence": "The straight-line length of a vector v = (x, y), found by Pythagoras' theorem: |v| = √(x² + y²).",
            "picture": "The hypotenuse of a right-angled triangle with horizontal leg x and vertical leg y.",
            "steps": [
                "Square the horizontal step x² and square the vertical step y² (both squares are positive).",
                "Add the two squares together: x² + y².",
                "Take the square root: √(x² + y²).",
            ],
            "workedExample": "For v = (−6, 8), the magnitude is |v| = √((−6)² + 8²) = √(36 + 64) = √100 = 10.",
            "check": {
                "prompt": "What is the magnitude |v| of the vector v = (8, 15)?",
                "answer": "17",
                "answerKey": k.one(k.num("17"), accepts=["17", "|v| = 17"], rejects=["23", "289", "7"]),
            },
            "mixUp": {
                "name": "adding the components 8 + 15 = 23",
                "how": "Walking 8 across and 15 up is 23 along the grid lines, but the straight-line magnitude is √(64 + 225) = √289 = 17.",
            },
            "standsOn": ["column-vector", "pythagoras-theorem", "square-root"],
        },
        "scalar-multiple": {
            "name": "Scalar multiple",
            "aliases": ["scalar multiple", "scalar multiples"],
            "oneSentence": "A vector kv = (kx, ky) made by multiplying both components of v by k, scaling its length by |k|.",
            "picture": "Vector a, then 2a twice as long in the same direction, and −a pointing the opposite way.",
            "steps": [
                "Multiply the top component by the number k.",
                "Multiply the bottom component by the same number k.",
                "If one vector is a non-zero scalar multiple of another, the two vectors are parallel.",
            ],
            "workedExample": "For v = (3, −2), the scalar multiple 4v is (4 × 3, 4 × (−2)) = (12, −8).",
            "check": {
                "prompt": "If a = (2, −5), what is the scalar multiple 3a?",
                "answer": "(6, −15)",
                "answerKey": k.one(k.seq("6", "-15"), accepts=["(6, −15)", "(6, -15)", "6, -15"], rejects=["(5, -2)", "(6, 15)", "(2, -15)"]),
            },
            "mixUp": {
                "name": "multiplying only the top component",
                "how": "Both the horizontal step and the vertical step must be multiplied by 3 so the direction stays the same.",
            },
            "standsOn": ["column-vector", "scale-factor"],
        },
        "collinear": {
            "name": "Collinear",
            "aliases": ["collinear", "collinear points"],
            "oneSentence": "Points that lie on one straight line, proven by showing AB is a scalar multiple of BC and shares point B.",
            "picture": "Three points A, B and C on one straight ruler edge, where BC = 2 × AB.",
            "steps": [
                "Find the vector AB and the vector BC (or AC).",
                "Show that one vector is a scalar multiple of the other, so they are parallel.",
                "State that they share the common point B, so A, B and C lie on the same straight line.",
            ],
            "workedExample": "AB = (1, 3) and BC = (4, 12) = 4 × AB. Since AB and BC are parallel and share B, the points A, B and C are collinear.",
            "check": {
                "prompt": "Points A, B and C are collinear, with AB = (2, 5) and BC = 3 × AB. What is the vector AC = AB + BC?",
                "answer": "(8, 20)",
                "answerKey": k.one(k.seq("8", "20"), accepts=["(8, 20)", "8, 20"], rejects=["(6, 15)", "(5, 8)", "(4, 10)"]),
            },
            "mixUp": {
                "with": "parallel-lines",
                "how": "Two vectors can be parallel anywhere on the grid; collinear points must also share a point so they lie on the same line.",
            },
            "standsOn": ["scalar-multiple", "gradient"],
        },
        "dot-product": {
            "name": "Dot product",
            "aliases": ["dot product", "dot products", "scalar product"],
            "oneSentence": "For u = (x₁, y₁) and v = (x₂, y₂), the number u · v = x₁x₂ + y₁y₂ = |u||v| cos θ, which is 0 at 90°.",
            "picture": "Two perpendicular arrows u = (3, 4) and v = (−4, 3) whose dot product 3(−4) + 4(3) = 0 confirms the right angle.",
            "steps": [
                "Multiply the two x-components together: x₁ × x₂.",
                "Multiply the two y-components together: y₁ × y₂.",
                "Add the two products: x₁x₂ + y₁y₂. If the sum is 0, the vectors are perpendicular.",
            ],
            "workedExample": "For u = (5, 2) and v = (3, −1), u · v = (5 × 3) + (2 × (−1)) = 15 − 2 = 13.",
            "check": {
                "prompt": "Find the dot product u · v of the perpendicular vectors u = (2, 6) and v = (3, −1).",
                "answer": "0",
                "answerKey": k.one(k.num("0"), accepts=["0", "u · v = 0"], rejects=["12", "6", "-6"]),
            },
            "mixUp": {
                "name": "leaving the answer as a vector (6, −6)",
                "how": "The dot product adds the two products 6 + (−6) = 0 to produce one scalar number, not a column vector.",
            },
            "standsOn": ["magnitude", "cosine", "angle"],
        },
    }


def sums():
    """Every sum chapter 19 and its cards state, recomputed."""
    a = (3, 4)
    b = (2, -1)
    return [
        # Hook, skill card and school unit 16
        ("hook walk", (3 + 2, 4 - 1), (5, 3)),
        ("skill 2a - 3b and |a|", (vec_sub(vec_scale(2, a), vec_scale(3, b)), vec_mag(a)), ((0, 11), 5)),
        ("skill AC = AB + BC", vec_add((4, -2), (-1, 7)), (3, 5)),
        # 19.1
        ("19.1 AB = OB - OA", vec_sub((6, 8), (2, 5)), (4, 3)),
        ("turn 19.1", vec_sub((6, 2), (1, 4)), (5, -2)),
        # 19.2 and debate
        ("19.2 2a and |2a|", (vec_scale(2, a), vec_mag(vec_scale(2, a))), ((6, 8), 10)),
        ("debate (3,4) + (5,-4)", (vec_add((3, 4), (5, -4)), vec_mag((8, 0))), ((8, 0), 8)),
        ("turn 19.2 |(5, -12)|", (5 ** 2 + (-12) ** 2, vec_mag((5, -12))), (169, 13)),
        # 19.3
        ("19.3 collinear example and turn", (vec_scale(3, (2, 3)), 3 * (-6 // -2)), ((6, 9), 9)),
        # 19.4
        ("19.4 dot products", (dot_prod((3, 4), (-4, 3)), dot_prod((2, 5), (4, -1)), dot_prod((4, 3), (2, -1))), (0, 3, 5)),
        # Widgets
        ("widget tip to tail", (vec_mag((3, 4)), 3 + 4, vec_add((3, 1), (1, 3))), (5, 7, (4, 4))),
        # Cards
        ("position-vector card and check", (vec_sub((7, 5), (2, 1)), vec_sub((8, 9), (3, 2))), ((5, 4), (5, 7))),
        ("adding-vectors card and check", (vec_add((3, 2), (4, -5)), vec_add((2, 6), (5, -1))), ((7, -3), (7, 5))),
        ("zero-vector card", vec_add((4, -3), (-4, 3)), (0, 0)),
        ("magnitude card and check", (vec_mag((-6, 8)), 8 ** 2 + 15 ** 2, vec_mag((8, 15)), 8 + 15), (10, 289, 17, 23)),
        ("scalar-multiple card and check", (vec_scale(4, (3, -2)), vec_scale(3, (2, -5))), ((12, -8), (6, -15))),
        ("collinear card and check", (vec_scale(4, (1, 3)), vec_add((2, 5), vec_scale(3, (2, 5)))), ((4, 12), (8, 20))),
        ("dot-product card and check", (dot_prod((5, 2), (3, -1)), dot_prod((2, 6), (3, -1))), (13, 0)),
    ]


def answers():
    """Chapter 19's turn answers and its cards' check answers, computed."""
    fmt = lambda v: f"({v[0]}, {v[1]})".replace("-", "−")
    return {
        "ch19-s1-turn": fmt(vec_sub((6, 2), (1, 4))),
        "ch19-s2-turn": vec_mag((5, -12)),
        "ch19-s3-turn": 3 * (-6 // -2),
        "ch19-s4-turn": dot_prod((4, 3), (2, -1)),
        "position-vector-check": fmt(vec_sub((8, 9), (3, 2))),
        "adding-vectors-check": fmt(vec_add((2, 6), (5, -1))),
        "zero-vector-check": fmt((0, 0)),
        "magnitude-check": vec_mag((8, 15)),
        "scalar-multiple-check": fmt(vec_scale(3, (2, -5))),
        "collinear-check": fmt(vec_add((2, 5), vec_scale(3, (2, 5)))),
        "dot-product-check": dot_prod((2, 6), (3, -1)),
    }
