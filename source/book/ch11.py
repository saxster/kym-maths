"""
Chapter 11, written by hand to docs/CONTENT_BRIEF.md. It carries school unit 13.

Each section teaches one idea in nine steps, in this order: question, idea, picture, reason, name,
example, mistake, turn, sayBack. A section's `teaches` lists the concept cards whose names first
appear in its `name` step. `build(k)` returns the chapter and `cards(k)` its concept cards; both take the
exporter's answer-key helpers. Every section starts from something she can hold or move: a paper
triangle, a treasure map, a mirror, a clock, a folded square, a torch, a photo, a floor tile.

A column vector is written in a line of text as "3 over −4": the step across, then the step up.

`schoolTopics` and `schoolQuestions` rewrite the topic summaries, worked examples and faded prompts of
school unit 13. The answer keys and stuck sheets stay in the exporter.
"""

from book.arithmetic import Fraction


def translate(p, across, up):
    """A point slid by a step across and a step up."""
    return (p[0] + across, p[1] + up)


def reflect_in_y_axis(p):
    return (-p[0], p[1])


def reflect_in_x_axis(p):
    return (p[0], -p[1])


def reflect_in_y_equals_x(p):
    return (p[1], p[0])


def half_turn(p):
    """A rotation of 180° about the origin."""
    return (-p[0], -p[1])


def quarter_turn_anticlockwise(p):
    """A rotation of 90° anticlockwise about the origin."""
    return (-p[1], p[0])


def quarter_turn_clockwise(p):
    """A rotation of 90° clockwise about the origin."""
    return (p[1], -p[0])


def enlarge(p, centre, factor):
    """A point enlarged about a centre: the step from the centre, multiplied by the scale factor."""
    return (centre[0] + factor * (p[0] - centre[0]), centre[1] + factor * (p[1] - centre[1]))


def point(p):
    """A point as the text writes it."""
    def show(v):
        v = Fraction(v)
        return str(int(v)) if v.denominator == 1 else str(float(v))
    return f"({show(p[0])}, {show(p[1])})"


def build(k):
    return {
        "number": 11,
        "title": "Moving and resizing shapes",
        "subtitle": "School book chapter 13 · Sliding, flipping, turning and enlarging shapes on a grid",
        "hookSummary": "A torch makes a shadow of a cut-out triangle, twice as tall on the wall. "
                       "Is the shadow's area twice as big too?",
        "beyondSchoolBook": False,
        "skillCard": {
            "skill": "Sliding, flipping, turning and enlarging shapes on a grid, and saying what each move keeps the same",
            "sheCan": {
                "prompt": "With no calculator: slide the point (2, 5) by 3 across and −1 up. "
                          "Turn the point (4, 1) through 180° about (0, 0). "
                          "A triangle of area 4 cm² is enlarged by scale factor 3. What is its new area?",
                "answer": "The slide gives (5, 4). The half turn gives (−4, −1). The new area is 3 × 3 × 4 = 36 cm².",
            },
            "whyItMatters": "Every computer game slides, turns and resizes its pictures with these rules. "
                            "Maps, models and photo prints are enlargements, so their lengths and areas follow the same rules.",
            "standsOn": [
                "Chapter 7: points on a grid, written as coordinates",
                "Chapter 9: the perpendicular bisector, and shapes that match exactly",
                "Chapter 3: ratio",
            ],
            "unlocks": [
                "Chapter 12: right-angled triangles, where matching triangles share their ratios",
                "Chapter 19: vectors, which grow out of this chapter's column vectors",
                "Chapter 20: matrices, which do every move in this chapter with four numbers",
            ],
        },
        "intuitionToFormula": {
            "concreteAction": "Set the scale factor to 2 and the centre to (0, 0). "
                              "Dashed lines run from the centre C through each corner of the blue triangle PQR.",
            "ahaInvariant": "Each corner of the red triangle P′Q′R′ is twice as far from C as the matching corner of PQR. "
                            "And 4 copies of PQR fit inside P′Q′R′.",
            "formulaDisplay": "CP′ = k × CP,   new area = k² × old area",
            "termMappings": [
                {"symbol": "CP", "visualPart": "The blue triangle PQR, and its distance from C", "colorRole": "blue",
                 "meaning": "The shape you start with"},
                {"symbol": "k × CP", "visualPart": "The red triangle P′Q′R′, k times as far from C", "colorRole": "red",
                 "meaning": "Every distance from the centre, multiplied by the scale factor"},
                {"symbol": "k²", "visualPart": "The green lines that cut P′Q′R′ into copies of PQR", "colorRole": "green",
                 "meaning": "How many copies of the old area fit inside the new one"},
            ],
            "atlasFigureRef": "maths/linear-algebra/index.html#1",
        },
        "sections": [
            {
                "heading": "11.1 Sliding a shape",
                "teaches": ["transformation", "translation"],
                "steps": [
                    {"kind": "question",
                     "text": "Slide a paper triangle across a squared page, 4 squares right and 1 square up, without turning it. "
                             "What changes, and what stays the same?"},
                    {"kind": "idea",
                     "text": "Only its place changes. Every corner moves 4 squares right and 1 square up. "
                             "Its shape, its size and the way it faces stay the same."},
                    {"kind": "picture",
                     "text": "On squared paper, draw a triangle with corners at (1, 1), (3, 1) and (1, 2). "
                             "Add 4 to each x-coordinate and 1 to each y-coordinate, and draw the new triangle."},
                    {"kind": "reason",
                     "text": "Why does every side keep its length? Every corner moves by the same amount. "
                             "So the gap between any two corners does not change."},
                    {"kind": "name",
                     "text": "A change that moves or resizes a shape is a transformation. "
                             "The shape you start with is the object, and the result is the image. "
                             "A slide with no turning is a translation."},
                    {"kind": "example",
                     "text": "Translate the triangle 4 right and 1 up. "
                             "The corner (1, 1) goes to (5, 2), (3, 1) goes to (7, 2), and (1, 2) goes to (5, 3)."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to move one corner and redraw the rest by eye. "
                             "Every corner must move by the same amount, or the shape bends out of true."},
                    {"kind": "turn",
                     "text": "The point (2, 6) is translated 3 squares left and 4 squares down. Where does it land?",
                     "answer": "(−1, 2)",
                     "answerKey": k.one(k.seq("-1", "2"), accepts=["(−1, 2)", "(-1, 2)", "−1, 2"],
                                        rejects=["(5, 10)", "(−1, 10)", "(5, 2)"])},
                    {"kind": "sayBack",
                     "text": "A translation slides every point of a shape by the same amount. Its shape, its size and the way it faces stay the same."},
                ],
            },
            {
                "heading": "11.2 Two numbers for a slide",
                "teaches": ["column-vector"],
                "steps": [
                    {"kind": "question",
                     "text": "A treasure map says: walk 5 steps east, then 2 steps south. "
                             "How can you write that slide with only two numbers?"},
                    {"kind": "idea",
                     "text": "Write the steps across first and the steps up second. "
                             "A step south is a step up of −1, so 2 steps south is −2. The slide is 5, then −2."},
                    {"kind": "picture",
                     "text": "Draw an arrow on squared paper from (0, 0) to (5, −2). "
                             "It goes 5 squares across and 2 squares down."},
                    {"kind": "reason",
                     "text": "Why a minus sign? Steps to the left and steps down go the opposite way to the axes. "
                             "So they are negative numbers, as on a number line."},
                    {"kind": "name",
                     "text": "A column vector writes a translation as two numbers in a column, the step across on top and the step up below. "
                             "In a line of text this book writes it as 5 over −2."},
                    {"kind": "example",
                     "text": "The column vector 3 over 4 moves the point (1, 2) to (1 + 3, 2 + 4), which is (4, 6)."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to read the top number as the step up. "
                             "3 over 4 means 3 across and 4 up, not 3 up and 4 across."},
                    {"kind": "turn",
                     "text": "Translate the point (2, 5) by the column vector 3 over −4. Where does it land?",
                     "answer": "(5, 1)",
                     "answerKey": k.one(k.seq("5", "1"), accepts=["(5, 1)", "5, 1", "(5,1)"],
                                        rejects=["(5, 9)", "(−2, 8)", "(−1, 9)"])},
                    {"kind": "sayBack",
                     "text": "A column vector has the step across on top and the step up below. Add them to a point's coordinates to slide it."},
                ],
            },
            {
                "heading": "11.3 Mirror images",
                "teaches": ["reflection"],
                "steps": [
                    {"kind": "question",
                     "text": "Hold a letter b up to a mirror. Why does it look like a d?"},
                    {"kind": "idea",
                     "text": "A mirror sends each point to the other side, the same distance away. "
                             "The round part on the right of the b ends up on the left."},
                    {"kind": "picture",
                     "text": "On squared paper, use the y-axis as a mirror. Plot (3, 2), count 3 squares to the mirror and 3 more beyond it. "
                             "You land on (−3, 2)."},
                    {"kind": "reason",
                     "text": "Why the same distance on each side? The mirror is the perpendicular bisector of each point and its image. "
                             "It crosses the line between them halfway, at a right angle."},
                    {"kind": "name",
                     "text": "Flipping a shape over a line is a reflection, and the line is the mirror line. "
                             "Reflecting in the y-axis changes the sign of the x-coordinate."},
                    {"kind": "example",
                     "text": "Reflect the point (4, 1) in the x-axis. "
                             "It is 1 square above the mirror, so its image is 1 square below, at (4, −1)."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to measure to the mirror along a slant. "
                             "Always count straight across to the mirror, at a right angle to it."},
                    {"kind": "turn",
                     "text": "Reflect the point (5, 3) in the y-axis. Where is its image?",
                     "answer": "(−5, 3)",
                     "answerKey": k.one(k.seq("-5", "3"), accepts=["(−5, 3)", "(-5, 3)", "−5, 3"],
                                        rejects=["(5, −3)", "(−5, −3)", "(3, 5)"])},
                    {"kind": "sayBack",
                     "text": "A reflection sends each point to the far side of the mirror line, the same distance away, measured straight across."},
                ],
            },
            {
                "heading": "11.4 Turning about a point",
                "teaches": ["rotation"],
                "steps": [
                    {"kind": "question",
                     "text": "A clock hand turns about the pin in the middle. "
                             "It points at 12. Where does its tip point after a quarter turn clockwise?"},
                    {"kind": "idea",
                     "text": "At 3. The tip stays the same distance from the pin, and sweeps through 90°."},
                    {"kind": "picture",
                     "text": "Plot (3, 1) and the point (0, 0). Lay tracing paper over them, pin it at (0, 0) with a pencil, and give it a half turn. "
                             "The dot lands on (−3, −1)."},
                    {"kind": "reason",
                     "text": "Why do both signs change in a half turn? A half turn sends every point straight through the pin. "
                             "It ends up the same distance away on the other side."},
                    {"kind": "name",
                     "text": "Turning a shape about a fixed point is a rotation, and the fixed point is the centre of rotation. "
                             "To describe one, give the centre, the angle, and clockwise or anticlockwise."},
                    {"kind": "example",
                     "text": "Rotate (4, 1) by 90° anticlockwise about (0, 0). "
                             "The step 4 across and 1 up turns into 1 to the left and 4 up, so the image is (−1, 4)."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to turn about a corner of the shape and forget the centre. "
                             "Ask which point stays still, and turn about that one."},
                    {"kind": "turn",
                     "text": "Rotate the point (2, 5) by 180° about (0, 0). Where does it land?",
                     "answer": "(−2, −5)",
                     "answerKey": k.one(k.seq("-2", "-5"), accepts=["(−2, −5)", "(-2, -5)", "−2, −5"],
                                        rejects=["(−2, 5)", "(2, −5)", "(5, 2)"])},
                    {"kind": "sayBack",
                     "text": "A rotation turns every point about one centre through the same angle. Describe it by its centre, its angle and its direction."},
                ],
            },
            {
                "heading": "11.5 Shapes that fit themselves",
                "teaches": ["symmetry"],
                "steps": [
                    {"kind": "question",
                     "text": "Fold a paper square so that the two halves match exactly. How many different folds work?"},
                    {"kind": "idea",
                     "text": "Four: two folds across the middle and two folds from corner to corner. "
                             "Each fold is a mirror that leaves the square looking as it did."},
                    {"kind": "picture",
                     "text": "Draw a square and its four folds. Put a dot in one corner, give the square a quarter turn, "
                             "and watch it fit its outline again."},
                    {"kind": "reason",
                     "text": "Why does a quarter turn fit? The four sides are equal and the four corners are equal. "
                             "So after a quarter turn, each side lands where its neighbour was."},
                    {"kind": "name",
                     "text": "A mirror line that flips a shape onto itself is a line of symmetry. "
                             "A shape that fits onto itself in less than a full turn has rotational symmetry. "
                             "Its order is how many times it fits in one full turn."},
                    {"kind": "example",
                     "text": "A rectangle that is not a square has 2 lines of symmetry. "
                             "A half turn fits it onto itself, so its order of rotational symmetry is 2."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to count a rectangle's corner-to-corner folds as lines of symmetry. "
                             "Fold one that way and its corners do not meet."},
                    {"kind": "turn",
                     "text": "A regular hexagon has 6 equal sides and 6 equal corners. What is its order of rotational symmetry?",
                     "answer": "6",
                     "answerKey": k.one(k.num("6"), accepts=["6", "order 6", "6 times"], rejects=["3", "2", "12"])},
                    {"kind": "sayBack",
                     "text": "A line of symmetry flips a shape onto itself. The order of rotational symmetry counts how often it fits in one full turn."},
                ],
            },
            {
                "heading": "11.6 Growing from a point",
                "figure": True,
                "teaches": ["enlargement", "scale-factor"],
                "steps": [
                    {"kind": "question",
                     "text": "A torch shines on a cut-out triangle, and its shadow on the wall is twice as tall. "
                             "Where do the edges of the light all meet?"},
                    {"kind": "idea",
                     "text": "At the torch bulb. Each ray starts there, passes a corner of the cut-out, "
                             "and goes on to twice that distance to reach the shadow."},
                    {"kind": "picture",
                     "text": "In the figure, set the top slider to 2 and the centre to (0, 0). "
                             "Each dashed line runs from C through a corner of PQR to a corner of P′Q′R′."},
                    {"kind": "reason",
                     "text": "Why is P′ twice as far from C as P? Each corner moves along its own line from C, to twice the distance. "
                             "So every side doubles as well."},
                    {"kind": "name",
                     "text": "Growing or shrinking a shape from a fixed point like this is an enlargement, and the point is the centre of enlargement. "
                             "The number every length is multiplied by is the scale factor."},
                    {"kind": "example",
                     "text": "Enlarge P(3, 3) by scale factor 2 about C(0, 0). "
                             "P is 3 across and 3 up from C, so P′ is 6 across and 6 up, at (6, 6). "
                             "With scale factor ½, P′ would be at (1.5, 1.5), and the shape would shrink."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to double the sides and draw the image anywhere. "
                             "The centre fixes where it goes, so measure every distance from C."},
                    {"kind": "turn",
                     "text": "Enlarge the point (2, 1) by scale factor 3 about (0, 0). Where does it land?",
                     "answer": "(6, 3)",
                     "answerKey": k.one(k.seq("6", "3"), accepts=["(6, 3)", "6, 3", "(6,3)"],
                                        rejects=["(5, 4)", "(6, 1)", "(2, 3)"])},
                    {"kind": "sayBack",
                     "text": "An enlargement multiplies every distance from its centre by the scale factor. The image keeps its shape and the way it faces."},
                ],
            },
            {
                "heading": "11.7 Same shape, different size",
                "teaches": ["similar-shapes"],
                "steps": [
                    {"kind": "question",
                     "text": "A photo is printed 10 cm wide and 15 cm tall. A bigger print is 20 cm wide. "
                             "How tall must it be so that nobody in it looks stretched?"},
                    {"kind": "idea",
                     "text": "30 cm. The width has doubled, so the height must double too. "
                             "Every length is multiplied by the same number."},
                    {"kind": "picture",
                     "text": "Draw a triangle with sides of 3 cm, 4 cm and 5 cm. Draw a second one with every side doubled: 6 cm, 8 cm and 10 cm. "
                             "Measure the angles of both."},
                    {"kind": "reason",
                     "text": "Why do the angles match? The second triangle is an enlargement of the first, and an enlargement keeps every angle. "
                             "Only the lengths change, all by one scale factor."},
                    {"kind": "name",
                     "text": "Shapes like these are similar shapes: one is an enlargement of the other. "
                             "Their angles are equal, and every pair of matching sides is in the same ratio. "
                             "Congruent shapes are the case with scale factor 1."},
                    {"kind": "example",
                     "text": "A triangle with sides of 4, 6 and 8 cm matches one with sides of 6, 9 and 12 cm. "
                             "Each side is multiplied by 1.5, so the two are similar shapes."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to add the same amount to each side. "
                             "Adding 2 cm to each side of the 3, 4, 5 triangle gives 5, 6, 7, which is a different shape."},
                    {"kind": "turn",
                     "text": "Two triangles are similar shapes. The small one has sides of 3 cm, 4 cm and 5 cm. "
                             "The large one's shortest side is 6 cm. How long is its longest side?",
                     "answer": "10 cm",
                     "answerKey": k.one(k.num("10"), accepts=["10", "10 cm", "10cm"], rejects=["8", "7", "5"])},
                    {"kind": "sayBack",
                     "text": "Similar shapes have equal angles, and every length in one is the matching length in the other times one scale factor."},
                ],
            },
            {
                "heading": "11.8 What happens to the area",
                "teaches": ["area-scale-factor"],
                "steps": [
                    {"kind": "question",
                     "text": "A square floor tile with 1 cm sides is enlarged by scale factor 3. "
                             "Is the new tile 3 times as big?"},
                    {"kind": "idea",
                     "text": "No. The new tile is 3 cm by 3 cm, and 9 of the small tiles fit inside it."},
                    {"kind": "picture",
                     "text": "Draw a 1 cm square, a 2 cm square and a 3 cm square on squared paper. "
                             "Count the 1 cm squares inside each one: 1, then 4, then 9."},
                    {"kind": "reason",
                     "text": "Why k × k? An area spreads across and up at once. "
                             "Both directions are multiplied by the scale factor k, so the area is multiplied by k twice."},
                    {"kind": "name",
                     "text": "The number an area is multiplied by is the area scale factor. "
                             "For an enlargement with scale factor k it is k². Volumes are multiplied by k³."},
                    {"kind": "example",
                     "text": "A triangle of area 6 cm² is enlarged by scale factor 3. "
                             "Its new area is 3² × 6 = 9 × 6 = 54 cm²."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to multiply the area by the scale factor itself. "
                             "Doubling every side of a 5 cm² shape gives 20 cm², not 10 cm²."},
                    {"kind": "turn",
                     "text": "A shape with an area of 5 cm² is enlarged by scale factor 4. What is its new area?",
                     "answer": "80 cm²",
                     "answerKey": k.one(k.num("80"), accepts=["80", "80 cm²", "80 cm2"], rejects=["20", "25", "9"])},
                    {"kind": "sayBack",
                     "text": "When lengths are multiplied by k, areas are multiplied by k², and volumes by k³."},
                ],
            },
        ],
        "callouts": [
            {"kind": "predict", "title": "Predict first",
             "body": "Set the top slider to 3. "
                     "Predict how many copies of the small blue triangle will fit inside the red one, then look."},
            {"kind": "check", "title": "Explain it",
             "body": "Explain to a friend why sliding, flipping or turning a shape never changes its area, "
                     "but growing it from a point does."},
            {"kind": "careful", "title": "Measure from the centre",
             "body": "When a shape turns or grows, every distance is measured from the centre. "
                     "Pick the wrong centre and the image lands in the wrong place."},
        ],
        "debate": {
            "id": "debate-ch11-transformations",
            "oupUnitNumber": 13,
            "title": "Can an enlargement make a shape smaller?",
            "contextPrompt": "A triangle is enlarged by scale factor ½ about a point C. "
                             "Asha and Rohan argue about the result.",
            "speakerAName": "Asha",
            "speakerAClaim": "Enlarging means making bigger. A scale factor of ½ is not allowed.",
            "speakerBName": "Rohan",
            "speakerBClaim": "A scale factor of ½ halves every distance from C. "
                             "It is still an enlargement, and the image is smaller.",
            "choices": [
                {"id": "ch11-a", "speakerLabel": "Asha is right (it must grow)",
                 "reasoningStatement": "In everyday words, to enlarge is to make bigger.",
                 "isCorrect": False,
                 "socraticRebuttal": "Follow the rule: multiply the distance from C by ½. "
                                     "Does anything in the rule stop you using ½?"},
                {"id": "ch11-b", "speakerLabel": "Rohan is right (it can shrink)",
                 "reasoningStatement": "The rule works for any scale factor, and ½ halves every length.",
                 "isCorrect": True,
                 "socraticRebuttal": "Yes. The image has the same shape and the same angles, "
                                     "with every side half as long. In maths the word covers shrinking too."},
                {"id": "ch11-c", "speakerLabel": "Neither. It depends where C is.",
                 "reasoningStatement": "If C is inside the triangle, the image might grow.",
                 "isCorrect": False,
                 "socraticRebuttal": "Put C anywhere and halve the distance from C to each corner. "
                                     "How long is each side of the image now?"},
            ],
            "invariantTakeaway": "In maths an enlargement can shrink a shape: a scale factor between 0 and 1 makes every length smaller.",
        },
        "keyTerms": ["Transformation", "Translation", "Column vector", "Reflection", "Rotation", "Line and rotational symmetry",
                     "Enlargement", "Scale factor", "Similar shapes", "Area scale factor"],
        "widgets": ["w_transformation_isometry_stage", "w_enlargement_ray_scaler"],
        "widgetText": {
            "w_transformation_isometry_stage": {
                "title": "A whole grid moved at once",
                "challengePrompt": "Open the page called Shear and rotation. "
                                   "Before you move anything, predict whether the square's area will change.",
                "cutaway": "A shear slides each row of the grid sideways, like pushing a pile of cards. "
                           "The square leans over, but its bottom and its height stay 1, so its area stays 1.",
                "idealised": "Beyond this chapter: a whole grid can be slid, turned or leaned in one move",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Open the page called Shear and rotation, and watch the grid."},
                    {"title": "2. Notice", "caption": "The grid lines stay straight, parallel and evenly spaced."},
                    {"title": "3. Match the rule", "caption": "The square leans, but its bottom and height stay 1, so its area stays 1."},
                    {"title": "4. Push it further", "caption": "Find the move on the page that turns the grid without stretching it."},
                    {"title": "5. Draw it", "caption": "Draw a square on squared paper, then the same square slid, flipped and turned."},
                ],
            },
            "w_enlargement_ray_scaler": {
                "title": "Areas under a stretch",
                "challengePrompt": "Open the page called The determinant is area. "
                                   "Predict whether the stretched square covers more or less than 1 square.",
                "cutaway": "Every small square of the grid is stretched by the same amount. "
                           "So the area of every shape on the grid is multiplied by one number.",
                "idealised": "The rule: an enlargement with scale factor k multiplies every area by k²",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Open the page called The determinant is area."},
                    {"title": "2. Notice", "caption": "Every small square inside the big one grows by the same amount."},
                    {"title": "3. Match the rule", "caption": "The area grows from 1 to 1.625, the same number for every shape on the grid."},
                    {"title": "4. Push it further", "caption": "For an enlargement with scale factor 2, predict what number the area is multiplied by."},
                    {"title": "5. Draw it", "caption": "Draw a 1 cm square and its enlargement with scale factor 3, and count the squares inside."},
                ],
            },
        },
        "atlasLessons": [
            {
                "title": "Chapter 11 · Lines from the centre",
                "question": "Why does an enlargement keep a shape's angles?",
                "explanation": "Every corner moves along its own line from the centre, to k times as far. "
                               "Every side is multiplied by k, so the shape stays the same, only bigger or smaller.",
                "limits": "The rule: an enlargement with scale factor k multiplies every length by k",
            },
            {
                "title": "Chapter 11 · Moves that keep the size",
                "question": "Why do a translation, a reflection and a rotation never change an area?",
                "explanation": "Each one moves every point but keeps the distance between any two points. "
                               "The image is congruent to the object, so its area is the same.",
                "limits": "The rule: translations, reflections and rotations give congruent images",
            },
            {
                "title": "Chapter 11 · Copies inside the image",
                "question": "Why does scale factor 3 make an area 9 times as big?",
                "explanation": "Each length is 3 times as long, across and up at once. "
                               "So 3 × 3 = 9 copies of the shape fit inside the image.",
                "limits": "The rule: lengths × k, areas × k², volumes × k³",
            },
        ],
        "visualMathTips": {},
        "schoolTopics": {
            "13.1": "A translation slides a shape without turning it. It is written as a column vector, the step across on top and the step up below. "
                    "The shape's size and the way it faces stay the same.",
            "13.2": "A reflection flips a shape over a mirror line. Each point and its image are the same distance from the mirror, "
                    "measured at a right angle. Reflecting in the line y = x swaps the two coordinates.",
            "13.3": "A rotation turns a shape about a centre of rotation. "
                    "To describe one, give the centre, the angle, and clockwise or anticlockwise.",
            "13.4": "A line of symmetry flips a shape onto itself. The order of rotational symmetry counts how many times a shape fits onto itself in one full turn. "
                    "A cube can be cut into two mirror halves in 9 ways.",
            "13.5": "An enlargement multiplies every distance from the centre of enlargement by the scale factor k. "
                    "Lengths are multiplied by k, areas by k² and volumes by k³.",
        },
        "schoolQuestions": {
            "q-oup-ch13-sb": {
                "workedExample": "Step 1: The step from C(1, 1) to A(2, 3) is 1 across and 2 up.\n"
                                 "Step 2: Multiply the step by the scale factor 3: 3 across and 6 up.\n"
                                 "Step 3: Add it to C. The image of A is at (1 + 3, 1 + 6) = (4, 7).\n"
                                 "Step 4: The area is multiplied by 3² = 9, so the image has area 9 × 6 = 54 cm².",
                "fadedPrompt": "The step from C to A is 1 across and 2 up, so the step to its image is 3 across and 6 up. "
                               "The image of A is at (4, 7), and the area is 3² × 6 = ___ cm².",
            },
            "q-oup-ch13-wb-focus": {
                "workedExample": "Step 1: The line y = x runs through (0, 0), (1, 1) and (2, 2), at 45° to the axes.\n"
                                 "Step 2: Reflecting in it swaps the x-coordinate and the y-coordinate.\n"
                                 "Step 3: So P(−3, 5) goes to (5, −3).\n"
                                 "Step 4: Check: halfway between P and P′ is (1, 1), which is on the mirror line.",
                "fadedPrompt": "Reflecting in y = x swaps the coordinates, so P(−3, 5) goes to P′ = ___.",
            },
            "q-oup-ch13-wb-practice": {
                "workedExample": "Step 1: Q is 4 across and 1 up from the centre (0, 0).\n"
                                 "Step 2: A quarter turn anticlockwise turns a step across into a step up, and a step up into a step left.\n"
                                 "Step 3: So 4 across becomes 4 up, and 1 up becomes 1 to the left.\n"
                                 "Step 4: Q′ = (−1, 4). Check: Q and Q′ are the same distance from (0, 0).",
                "fadedPrompt": "Q is 4 across and 1 up. After a quarter turn anticlockwise it is 1 to the left and 4 up, so Q′ = ___.",
            },
            "q-oup-ch13-wb-challenge": {
                "workedExample": "Step 1: The step from C(3, 2) to R(5, 3) is 2 across and 1 up.\n"
                                 "Step 2: Multiply the step by −2: 4 to the left and 2 down.\n"
                                 "Step 3: Add it to C: R′ = (3 − 4, 2 − 2) = (−1, 0).\n"
                                 "Step 4: A negative scale factor puts the image on the other side of the centre, upside down.",
                "fadedPrompt": "The step from C to R is 2 across and 1 up. Times −2 it is 4 left and 2 down, so R′ = ___.",
            },
        },
    }


def cards(k):
    """The concept cards this chapter teaches."""
    return {
        "transformation": {
            "name": "Transformation",
            "aliases": ["transformation", "transformations"],
            "oneSentence": "A change that moves, turns, flips or resizes a shape. The shape you start with is the object, and the result is the image.",
            "picture": "A paper triangle slid across a page, flipped over, turned, and photocopied larger.",
            "steps": [
                "Name the object, the shape you start with.",
                "Say what the move does: slide, flip, turn or resize.",
                "Draw the image, the shape the move makes.",
            ],
            "workedExample": "Sliding a triangle 4 squares right is a transformation. The triangle you start with is the object, and the slid one is its image.",
            "check": {
                "prompt": "A triangle with sides of 3, 4 and 5 cm is slid 6 squares to the right. How long is its longest side now, in cm?",
                "answer": "5 cm",
                "answerKey": k.one(k.num("5"), accepts=["5", "5 cm", "5cm"], rejects=["11", "6", "30"]),
            },
            "mixUp": {
                "name": "only moving",
                "how": "A transformation can also resize a shape. Slides, flips and turns keep the size, but an enlargement changes it.",
            },
            "standsOn": ["coordinates"],
            "footing": "transformations",
        },
        "translation": {
            "name": "Translation",
            "aliases": ["translation", "translations"],
            "oneSentence": "A slide with no turning: every point of the shape moves the same distance in the same direction.",
            "picture": "A chess piece slid across the board without lifting or turning it.",
            "steps": [
                "Read how far the shape moves across and how far up.",
                "Move every corner by that amount.",
                "Join the new corners. The image faces the same way as the object.",
            ],
            "workedExample": "Translate (1, 2) by 3 across and 4 up. The image is (1 + 3, 2 + 4) = (4, 6).",
            "check": {
                "prompt": "The point (4, −1) is translated 2 squares left and 5 squares up. Where does it land?",
                "answer": "(2, 4)",
                "answerKey": k.one(k.seq("2", "4"), accepts=["(2, 4)", "2, 4", "(2,4)"], rejects=["(6, 4)", "(2, −6)", "(9, 1)"]),
            },
            "mixUp": {
                "with": "rotation",
                "how": "A translation never turns the shape. A rotation turns it about a centre.",
            },
            "standsOn": ["transformation", "coordinates"],
        },
        "column-vector": {
            "name": "Column vector",
            "aliases": ["column vector", "column vectors"],
            "oneSentence": "Two numbers in a column that describe a translation: the step across on top, the step up below.",
            "picture": "An arrow on squared paper, 5 squares across and 2 squares down, labelled 5 over −2.",
            "steps": [
                "Read the top number as the step across. Positive is right, negative is left.",
                "Read the bottom number as the step up. Positive is up, negative is down.",
                "Add the two steps to the point's x-coordinate and y-coordinate.",
            ],
            "workedExample": "Translate (6, 1) by the column vector −2 over 3. The image is (6 − 2, 1 + 3) = (4, 4).",
            "check": {
                "prompt": "Translate the point (−3, 2) by the column vector 4 over −6. Where does it land?",
                "answer": "(1, −4)",
                "answerKey": k.one(k.seq("1", "-4"), accepts=["(1, −4)", "(1, -4)", "1, −4"], rejects=["(3, −1)", "(−7, 8)", "(1, 8)"]),
            },
            "mixUp": {
                "with": "coordinates",
                "how": "Coordinates give a place on the grid. A column vector gives a move, which can start from any place.",
            },
            "standsOn": ["translation", "negative-number"],
        },
        "reflection": {
            "name": "Reflection",
            "aliases": ["reflection", "reflections", "mirror line", "mirror lines"],
            "oneSentence": "A flip over a mirror line. Each point lands the same distance away on the other side, measured at a right angle.",
            "picture": "A letter b held up to a mirror, looking like a d.",
            "steps": [
                "Find the mirror line.",
                "From each corner, count straight across to the mirror at a right angle.",
                "Count the same distance beyond it, and mark the image corner.",
            ],
            "workedExample": "Reflect (2, 3) in the y-axis. It is 2 squares right of the mirror, so its image is 2 squares left, at (−2, 3).",
            "check": {
                "prompt": "Reflect the point (2, −7) in the x-axis. Where is its image?",
                "answer": "(2, 7)",
                "answerKey": k.one(k.seq("2", "7"), accepts=["(2, 7)", "2, 7", "(2,7)"], rejects=["(−2, −7)", "(−2, 7)", "(7, 2)"]),
            },
            "mixUp": {
                "name": "a half turn",
                "how": "A reflection flips the shape over, so its image faces the other way round. A half turn spins it about a point.",
            },
            "standsOn": ["transformation", "perpendicular-bisector", "coordinates"],
        },
        "rotation": {
            "name": "Rotation",
            "aliases": ["rotation", "rotations", "centre of rotation", "centres of rotation"],
            "oneSentence": "A turn about a fixed point, the centre of rotation, through an angle, clockwise or anticlockwise.",
            "picture": "A clock hand turning about the pin in the middle.",
            "steps": [
                "Find the centre of rotation, the point that stays still.",
                "Turn each corner about it through the angle, in the right direction.",
                "Check that each corner is the same distance from the centre as before.",
            ],
            "workedExample": "A half turn about (0, 0) sends (3, 1) to (−3, −1). Both signs change, and the distance from (0, 0) stays the same.",
            "check": {
                "prompt": "Rotate the point (3, 2) by 90° clockwise about (0, 0). Where does it land?",
                "answer": "(2, −3)",
                "answerKey": k.one(k.seq("2", "-3"), accepts=["(2, −3)", "(2, -3)", "2, −3"], rejects=["(−2, 3)", "(−3, −2)", "(3, −2)"]),
            },
            "mixUp": {
                "with": "reflection",
                "how": "A rotation keeps the shape the same way round. A reflection flips it over, like a mirror image.",
            },
            "standsOn": ["transformation", "angle"],
        },
        "symmetry": {
            "name": "Line and rotational symmetry",
            "aliases": ["line of symmetry", "lines of symmetry", "rotational symmetry", "order of rotational symmetry"],
            "oneSentence": "A line of symmetry flips a shape onto itself. Rotational symmetry means a turn of less than a full turn fits it onto itself.",
            "picture": "A paper square folded corner to corner, its halves matching exactly.",
            "steps": [
                "Look for each fold that makes the two halves match. Each one is a line of symmetry.",
                "Turn the shape slowly through one full turn.",
                "Count how many times it fits its outline. That count is its order of rotational symmetry.",
            ],
            "workedExample": "An equilateral triangle has 3 lines of symmetry, and it fits its outline 3 times in a full turn, so its order is 3.",
            "check": {
                "prompt": "How many lines of symmetry does a square have?",
                "answer": "4",
                "answerKey": k.one(k.num("4"), accepts=["4", "4 lines", "4 lines of symmetry"], rejects=["2", "8", "1"]),
            },
            "mixUp": {
                "name": "order 1",
                "how": "Every shape fits itself once in a full turn. A shape with order 1 has no rotational symmetry.",
            },
            "standsOn": ["reflection", "rotation", "polygon"],
        },
        "enlargement": {
            "name": "Enlargement",
            "aliases": ["enlargement", "enlargements", "centre of enlargement", "centres of enlargement"],
            "oneSentence": "A resize from a fixed point, the centre of enlargement: every distance from it is multiplied by the same number.",
            "picture": "A torch shining on a cut-out triangle, making a bigger shadow on the wall.",
            "steps": [
                "Find the step from the centre to a corner.",
                "Multiply the step by the scale factor.",
                "Add it to the centre to place the image corner. Repeat for each corner.",
            ],
            "workedExample": "Enlarge (3, 2) by scale factor 2 about (1, 1). The step is 2 across and 1 up, doubled to 4 and 2, so the image is (5, 3).",
            "check": {
                "prompt": "Enlarge the point (1, 4) by scale factor 2 about (0, 0). Where does it land?",
                "answer": "(2, 8)",
                "answerKey": k.one(k.seq("2", "8"), accepts=["(2, 8)", "2, 8", "(2,8)"], rejects=["(3, 6)", "(1, 8)", "(2, 4)"]),
            },
            "mixUp": {
                "name": "only bigger",
                "how": "In maths an enlargement can shrink a shape too, when the scale factor is between 0 and 1.",
            },
            "standsOn": ["transformation", "ratio"],
            "footing": "transformations",
        },
        "scale-factor": {
            "name": "Scale factor",
            "aliases": ["scale factor", "scale factors"],
            "oneSentence": "The number every length is multiplied by in an enlargement.",
            "picture": "A 2 cm side drawn beside its 6 cm image: three times as long.",
            "steps": [
                "Pick a side of the object and the matching side of the image.",
                "Divide the image length by the object length.",
                "Check that every other pair of sides gives the same answer.",
            ],
            "workedExample": "A 4 cm side becomes 10 cm. The scale factor is 10 ÷ 4 = 2.5.",
            "check": {
                "prompt": "A side of 5 cm becomes 15 cm after an enlargement. What is the scale factor?",
                "answer": "3",
                "answerKey": k.one(k.num("3"), accepts=["3", "× 3", "k = 3"], rejects=["10", "20", "75"]),
            },
            "mixUp": {
                "name": "the amount added",
                "how": "A scale factor multiplies each length. Adding the same amount to each side changes the shape.",
            },
            "standsOn": ["enlargement", "ratio"],
        },
        "similar-shapes": {
            "name": "Similar shapes",
            "aliases": ["similar shapes", "similar triangles", "mathematically similar"],
            "oneSentence": "Shapes where one is an enlargement of the other: equal angles, and matching sides all in one ratio.",
            "picture": "A small photo and a big print of it, with nobody stretched.",
            "steps": [
                "Match each side of one shape with a side of the other.",
                "Divide each pair to find the scale factor.",
                "If every pair gives the same scale factor, and the angles match, the shapes are similar shapes.",
            ],
            "workedExample": "Triangles with sides 2, 3, 4 and 6, 9, 12 are similar shapes: every side is multiplied by 3.",
            "check": {
                "prompt": "Two rectangles are similar shapes. One is 2 cm by 5 cm. The other has a short side of 6 cm. How long is its long side, in cm?",
                "answer": "15 cm",
                "answerKey": k.one(k.num("15"), accepts=["15", "15 cm", "15cm"], rejects=["9", "12", "30"]),
            },
            "mixUp": {
                "with": "congruent",
                "how": "Congruent shapes are the same size. Similar shapes can be different sizes, with one scale factor between them.",
            },
            "standsOn": ["enlargement", "angle", "ratio"],
        },
        "area-scale-factor": {
            "name": "Area scale factor",
            "aliases": ["area scale factor", "area scale factors"],
            "oneSentence": "The number an area is multiplied by in an enlargement. With scale factor k it is k².",
            "picture": "A 1 cm square tile beside a 3 cm square tile, with 9 small tiles fitting inside the big one.",
            "steps": [
                "Find the scale factor k.",
                "Multiply it by itself to get k².",
                "Multiply the old area by k² to get the new area.",
            ],
            "workedExample": "A rug of 2 m² is copied with scale factor 3. Its area is multiplied by 3² = 9, so the copy is 18 m².",
            "check": {
                "prompt": "A shape is enlarged by scale factor 5. What number is its area multiplied by?",
                "answer": "25",
                "answerKey": k.one(k.num("25"), accepts=["25", "× 25", "25 times"], rejects=["5", "10", "125"]),
            },
            "mixUp": {
                "with": "scale-factor",
                "how": "The scale factor multiplies each length. The area scale factor is that number times itself.",
            },
            "standsOn": ["scale-factor", "area"],
        },
    }


def sums():
    """Every sum chapter 11, its cards and its school unit text state, recomputed. test_book_maths.py checks computed == stated."""
    tri = [(1, 1), (3, 1), (1, 2)]
    return [
        # Skill card
        ("skill slide", translate((2, 5), 3, -1), (5, 4)),
        ("skill half turn", half_turn((4, 1)), (-4, -1)),
        ("skill area", 3 * 3 * 4, 36),
        # Figure and callouts
        ("figure k = 2 copies", 2 * 2, 4),
        ("predict k = 3 copies", 3 * 3, 9),
        ("figure PQR area", Fraction(1, 2) * 2 * 1, 1),
        # 11.1 Sliding a shape
        ("triangle slid 4, 1", [translate(p, 4, 1) for p in tri], [(5, 2), (7, 2), (5, 3)]),
        ("turn 11.1", (translate((2, 6), -3, -4), translate((2, 6), 3, 4), translate((2, 6), -3, 4), translate((2, 6), 3, -4)),
         ((-1, 2), (5, 10), (-1, 10), (5, 2))),
        # 11.2 Two numbers for a slide
        ("2 steps south", -1 * 2, -2),
        ("3 over 4", translate((1, 2), 3, 4), (4, 6)),
        ("turn 11.2", (translate((2, 5), 3, -4), translate((2, 5), 3, 4), translate((2, 5), -4, 3), translate((2, 5), -3, 4)),
         ((5, 1), (5, 9), (-2, 8), (-1, 9))),
        # 11.3 Mirror images
        ("(3, 2) in the y-axis", reflect_in_y_axis((3, 2)), (-3, 2)),
        ("(4, 1) in the x-axis", reflect_in_x_axis((4, 1)), (4, -1)),
        ("turn 11.3", (reflect_in_y_axis((5, 3)), reflect_in_x_axis((5, 3)), half_turn((5, 3)), reflect_in_y_equals_x((5, 3))),
         ((-5, 3), (5, -3), (-5, -3), (3, 5))),
        # 11.4 Turning about a point
        ("clock quarter turn", (12 + 3) % 12, 3),
        ("(3, 1) half turn", half_turn((3, 1)), (-3, -1)),
        ("(4, 1) quarter turn", quarter_turn_anticlockwise((4, 1)), (-1, 4)),
        ("turn 11.4", (half_turn((2, 5)), reflect_in_y_axis((2, 5)), reflect_in_x_axis((2, 5)), reflect_in_y_equals_x((2, 5))),
         ((-2, -5), (-2, 5), (2, -5), (5, 2))),
        # 11.5 Shapes that fit themselves
        ("square: 4 folds, order 4", (2 + 2, Fraction(360, 90)), (4, 4)),
        ("rectangle order", Fraction(360, 180), 2),
        ("hexagon", (Fraction(360, 60), 6 + 6), (6, 12)),
        # 11.6 Growing from a point
        ("P(3, 3) × 2", enlarge((3, 3), (0, 0), 2), (6, 6)),
        ("P(3, 3) × ½", enlarge((3, 3), (0, 0), Fraction(1, 2)), (Fraction(3, 2), Fraction(3, 2))),
        ("turn 11.6", (enlarge((2, 1), (0, 0), 3), translate((2, 1), 3, 3), (2 * 3, 1)), ((6, 3), (5, 4), (6, 1))),
        # 11.7 Same shape, different size
        ("photo", (Fraction(20, 10), 15 * 2), (2, 30)),
        ("3, 4, 5 doubled", tuple(2 * s for s in (3, 4, 5)), (6, 8, 10)),
        ("4, 6, 8 × 1.5", tuple(Fraction(3, 2) * s for s in (4, 6, 8)), (6, 9, 12)),
        ("3, 4, 5 plus 2", (tuple(s + 2 for s in (3, 4, 5)), 3 ** 2 + 4 ** 2 == 5 ** 2, 5 ** 2 + 6 ** 2 == 7 ** 2),
         ((5, 6, 7), True, False)),
        ("turn 11.7", (Fraction(6, 3) * 5, Fraction(6, 3) * 4, 5 + 6 - 3 - 1), (10, 8, 7)),
        # 11.8 What happens to the area
        ("tile × 3", 3 * 3, 9),
        ("squares 1, 2, 3", tuple(s * s for s in (1, 2, 3)), (1, 4, 9)),
        ("area 6 × 3²", (3 ** 2, 3 ** 2 * 6), (9, 54)),
        ("5 cm² × 2", (2 ** 2 * 5, 2 * 5), (20, 10)),
        ("turn 11.8", (4 ** 2 * 5, 4 * 5, 5 * 5, 3 ** 2), (80, 20, 25, 9)),
        # Debate
        ("scale factor ½", enlarge((4, 2), (0, 0), Fraction(1, 2)), (2, 1)),
        # Widgets and lessons
        ("lesson 3 × 3", 3 * 3, 9),
        ("widget k = 2", 2 ** 2, 4),
        # Cards
        ("3, 4, 5 slid", 5, 5),
        ("translation card", translate((1, 2), 3, 4), (4, 6)),
        ("translation check", (translate((4, -1), -2, 5), translate((4, -1), 2, 5), translate((4, -1), -2, -5), translate((4, -1), 5, 2)),
         ((2, 4), (6, 4), (2, -6), (9, 1))),
        ("column vector card", translate((6, 1), -2, 3), (4, 4)),
        ("column vector check", (translate((-3, 2), 4, -6), translate((-3, 2), -6, 4)), ((1, -4), (-9, 6))),
        ("reflection card", reflect_in_y_axis((2, 3)), (-2, 3)),
        ("reflection check", (reflect_in_x_axis((2, -7)), half_turn((2, -7)), reflect_in_y_axis((2, -7))),
         ((2, 7), (-2, 7), (-2, -7))),
        ("rotation card", half_turn((3, 1)), (-3, -1)),
        ("rotation check", (quarter_turn_clockwise((3, 2)), quarter_turn_anticlockwise((3, 2)), half_turn(reflect_in_y_equals_x((3, 2)))),
         ((2, -3), (-2, 3), (-2, -3))),
        ("equilateral triangle", Fraction(360, 120), 3),
        ("enlargement card", enlarge((3, 2), (1, 1), 2), (5, 3)),
        ("enlargement check", (enlarge((1, 4), (0, 0), 2), translate((1, 4), 2, 2)), ((2, 8), (3, 6))),
        ("scale factor card", Fraction(10, 4), Fraction(5, 2)),
        ("scale factor check", (Fraction(15, 5), 15 - 5, 15 + 5, 15 * 5), (3, 10, 20, 75)),
        ("similar card", tuple(3 * s for s in (2, 3, 4)), (6, 9, 12)),
        ("similar check", (Fraction(6, 2) * 5, 5 + 6 - 2, 2 * 6), (15, 9, 12)),
        ("area scale factor card", (3 ** 2, 9 * 2), (9, 18)),
        ("area scale factor check", (5 ** 2, 2 * 5, 5 ** 3), (25, 10, 125)),
        # School unit 13
        ("13.4 cube", 3 + 6, 9),
        ("enlarge A(2, 3)", (enlarge((2, 3), (1, 1), 3), 3 ** 2 * 6), ((4, 7), 54)),
        ("reflect P(−3, 5) in y = x", (reflect_in_y_equals_x((-3, 5)), (Fraction(-3 + 5, 2), Fraction(5 - 3, 2))), ((5, -3), (1, 1))),
        ("rotate Q(4, 1)", quarter_turn_anticlockwise((4, 1)), (-1, 4)),
        ("enlarge R(5, 3) by −2", enlarge((5, 3), (3, 2), -2), (-1, 0)),
    ]


def answers():
    """Chapter 11's turn answers and its cards' check answers, computed."""
    return {
        "ch11-s1-turn": point(translate((2, 6), -3, -4)),
        "ch11-s2-turn": point(translate((2, 5), 3, -4)),
        "ch11-s3-turn": point(reflect_in_y_axis((5, 3))),
        "ch11-s4-turn": point(half_turn((2, 5))),
        "ch11-s5-turn": Fraction(360, 60),
        "ch11-s6-turn": point(enlarge((2, 1), (0, 0), 3)),
        "ch11-s7-turn": Fraction(6, 3) * 5,
        "ch11-s8-turn": 4 ** 2 * 5,
        "transformation-check": 5,
        "translation-check": point(translate((4, -1), -2, 5)),
        "column-vector-check": point(translate((-3, 2), 4, -6)),
        "reflection-check": point(reflect_in_x_axis((2, -7))),
        "rotation-check": point(quarter_turn_clockwise((3, 2))),
        "symmetry-check": 4,
        "enlargement-check": point(enlarge((1, 4), (0, 0), 2)),
        "scale-factor-check": Fraction(15, 5),
        "similar-shapes-check": Fraction(6, 2) * 5,
        "area-scale-factor-check": 5 ** 2,
    }
