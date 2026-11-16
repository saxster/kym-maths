"""
Chapter 8, written by hand to docs/CONTENT_BRIEF.md. It carries school unit 8.

Each section teaches one idea in nine steps, in this order: question, idea, picture, reason, name,
example, mistake, turn, sayBack. A section's `teaches` lists the concept cards whose names first
appear in its `name` step. `build(k)` returns the chapter and `cards(k)` its concept cards; both take the
exporter's answer-key helpers. Every section starts from crossing roads, railway tracks or a paper triangle.

`schoolTopics` and `schoolQuestions` rewrite the topic summaries, worked examples and faded prompts of
school unit 8. The answer keys and stuck sheets stay in the exporter.
"""

from book.arithmetic import Fraction


def third_angle(*angles):
    """The angle that makes a triangle's angles up to 180°."""
    return 180 - sum(angles)


def angle_sum(sides):
    """The interior angles of a polygon with this many sides add to (n − 2) × 180°."""
    return (sides - 2) * 180


def midpoint(p, q):
    """The point halfway from p to q, as a pair of Fractions."""
    return (Fraction(p[0] + q[0], 2), Fraction(p[1] + q[1], 2))


def point(p):
    """A point as the text writes it, with whole numbers."""
    return f"({int(p[0])}, {int(p[1])})"


def build(k):
    return {
        "number": 8,
        "title": "Angles and proof",
        "subtitle": "School book chapter 8 · Crossing lines, parallel lines, triangles, polygons and midpoints",
        "hookSummary": "Tear the three corners off a paper triangle and lay them side by side, points touching. "
                       "They make a straight line every time. Why does that work for every triangle?",
        "beyondSchoolBook": False,
        "skillCard": {
            "skill": "Finding missing angles, and giving a reason for each step",
            "sheCan": {
                "prompt": "With no calculator: a line crosses two parallel lines and makes an angle of 65° with one of them. "
                          "Give the alternate angle and the co-interior angle. "
                          "Two angles of a triangle are 40° and 75°: find the exterior angle at the third corner. "
                          "Find the midpoint of (−2, 5) and (6, 1).",
                "answer": "The alternate angle is 65° and the co-interior angle is 115°. "
                          "The exterior angle is 40° + 75° = 115°. The midpoint is (2, 3).",
            },
            "whyItMatters": "Builders, map makers and designers find angles they cannot measure from angles they can. "
                            "Giving a reason for each step is how mathematics makes sure a fact holds every time.",
            "standsOn": [
                "Chapter 7: parallel lines and coordinates",
                "Chapter 0: if-then statements",
                "Measuring an angle in degrees, with 360° in a full turn",
            ],
            "unlocks": [
                "Chapter 9: drawing exact shapes and finding directions on a map",
                "Chapter 12: the sides and angles of right-angled triangles",
                "Every later proof about shapes, built from the facts in this chapter",
            ],
        },
        "intuitionToFormula": {
            "concreteAction": "Set the angle at A to 50° and the angle at B to 60°. "
                              "The dashed green line runs through C, parallel to the side AB.",
            "ahaInvariant": "Drag either slider. The red copy, the grey angle and the blue copy at C always fill the green line. "
                            "So the three angles of the triangle always add to 180°.",
            "formulaDisplay": "A + B + C = 180°,   exterior angle at B = A + C",
            "termMappings": [
                {"symbol": "A", "visualPart": "The red angles", "colorRole": "red",
                 "meaning": "The angle at corner A, and its copy at C"},
                {"symbol": "B", "visualPart": "The blue angles", "colorRole": "blue",
                 "meaning": "The angle at corner B, and its copy at C"},
                {"symbol": "the line through C", "visualPart": "The green dashed line", "colorRole": "green",
                 "meaning": "A line through C, parallel to AB"},
                {"symbol": "exterior angle at B", "visualPart": "The amber angle", "colorRole": "amber",
                 "meaning": "The angle between side BC and the side AB carried on past B"},
            ],
            "atlasFigureRef": "maths/ch08-angles-parallel/index.html",
        },
        "sections": [
            {
                "heading": "8.1 Where two lines cross",
                "teaches": ["vertically-opposite-angles"],
                "steps": [
                    {"kind": "question",
                     "text": "Two straight roads cross, and one corner of the crossing measures 70°. "
                             "What are the other three angles at the crossing?"},
                    {"kind": "idea",
                     "text": "Angles along a straight line add to 180°, half a full turn. "
                             "So the angle next to the 70° is 180° − 70° = 110°. Next to that is 70° again, then 110°."},
                    {"kind": "picture",
                     "text": "Draw two lines crossing like an X. Mark the 70° angle, then the angle straight across the crossing from it. "
                             "Shade both of them in one colour, and the other two in another."},
                    {"kind": "reason",
                     "text": "Why are the opposite angles equal? Each one sits beside the same 110° angle on a straight line. "
                             "So each is 180° − 110°, which is 70° both times."},
                    {"kind": "name",
                     "text": "The angles opposite each other where two lines cross are vertically opposite angles, and they are equal. "
                             "Vertically here means at the same corner point, not up and down. "
                             "Angles on a straight line add to 180°, and angles all the way round a point add to 360°."},
                    {"kind": "example",
                     "text": "Two lines cross, and one angle is 38°. The angle opposite it is 38°, and the two beside it are 180° − 38° = 142° each. "
                             "Check: 38 + 142 + 38 + 142 = 360. If another pair of opposite angles is 2x and 142°, then x = 71."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to make the angle beside it equal, instead of the one opposite. "
                             "Angles side by side share a straight line, so they add to 180°."},
                    {"kind": "turn",
                     "text": "Two lines cross. One angle is 3x and the angle opposite it is 75°. Find x.",
                     "answer": "25",
                     "answerKey": k.one(k.num("25"), accepts=["25", "x = 25", "= 25"], rejects=["75", "35", "105"])},
                    {"kind": "sayBack",
                     "text": "Vertically opposite angles are equal, and angles side by side on a straight line add to 180°."},
                ],
            },
            {
                "heading": "8.2 A line across parallel lines",
                "teaches": ["transversal", "corresponding-angles"],
                "steps": [
                    {"kind": "question",
                     "text": "A road crosses two parallel railway tracks. At the first track the road makes an angle of 60°. "
                             "What angle does it make at the second track, in the same position?"},
                    {"kind": "idea",
                     "text": "The tracks point the same way, so the road meets each one at the same slant. "
                             "Slide the first crossing along the road to the second and it fits exactly. The angle is 60° again."},
                    {"kind": "picture",
                     "text": "Draw two parallel lines across the page and a slanted line cutting both. "
                             "At each crossing, shade the angle above the parallel line and to the right of the slanted line."},
                    {"kind": "reason",
                     "text": "Why are the two shaded angles equal? Sliding the top line down the slanted line moves it onto the bottom line without turning it. "
                             "Nothing turns, so no angle changes."},
                    {"kind": "name",
                     "text": "A line that cuts across two or more lines is a transversal. "
                             "Angles in the same position at each crossing are corresponding angles. "
                             "When the lines are parallel, corresponding angles are equal, and together they trace a letter F."},
                    {"kind": "example",
                     "text": "A transversal crosses two parallel lines. At the top crossing, the angle above the line and left of the transversal is 112°. "
                             "The corresponding angle at the bottom crossing is 112° too. The angle beside it on the bottom line is 180° − 112° = 68°."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to use corresponding angles when the lines are not parallel. "
                             "If the two lines lean towards each other, the angles at the two crossings differ. "
                             "Look for the arrows that mark parallel lines first."},
                    {"kind": "turn",
                     "text": "A transversal crosses two parallel lines. One angle is 47°, and its corresponding angle is (2x + 7)°. Find x.",
                     "answer": "20",
                     "answerKey": k.one(k.num("20"), accepts=["20", "x = 20", "= 20"], rejects=["47", "27", "63"])},
                    {"kind": "sayBack",
                     "text": "A transversal meets parallel lines at the same slant, so its corresponding angles are equal."},
                ],
            },
            {
                "heading": "8.3 Z angles and C angles",
                "teaches": ["alternate-angles", "co-interior-angles"],
                "steps": [
                    {"kind": "question",
                     "text": "A transversal crosses two parallel lines. Below the top line, on the left of the transversal, the angle is 70°. "
                             "What is the angle above the bottom line, on the right?"},
                    {"kind": "idea",
                     "text": "The corresponding angle, below the bottom line on the left, is 70°. "
                             "The angle you want is vertically opposite that one, so it is 70° as well."},
                    {"kind": "picture",
                     "text": "Shade the two 70° angles. Both sit between the parallel lines, on opposite sides of the transversal, in the corners of a Z. "
                             "Then shade the angle above the bottom line on the left. With the first 70° it makes a C."},
                    {"kind": "reason",
                     "text": "Why do the two angles in the C add to 180°? The lower one sits on the bottom line beside the other 70°, so it is 110°. "
                             "And 70° + 110° = 180°."},
                    {"kind": "name",
                     "text": "Angles between the parallel lines on opposite sides of the transversal are alternate angles, and they are equal. "
                             "Angles between the lines on the same side are co-interior angles, and they add to 180°. "
                             "Look for a Z or a C."},
                    {"kind": "example",
                     "text": "An angle of 54° between two parallel lines has an alternate angle of 54°. "
                             "Two co-interior angles are x and x + 40. Then 2x + 40 = 180, so x = 70, and the angles are 70° and 110°."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to make co-interior angles equal, like alternate angles. "
                             "Equal co-interior angles would each be 90°, which happens only when the transversal crosses at a right angle."},
                    {"kind": "turn",
                     "text": "Two parallel lines are cut by a transversal. Two co-interior angles are (4x)° and (2x + 42)°. Find x.",
                     "answer": "23",
                     "answerKey": k.one(k.num("23"), accepts=["23", "x = 23", "= 23"], rejects=["21", "92", "88"])},
                    {"kind": "sayBack",
                     "text": "Alternate angles, in a Z, are equal. Co-interior angles, in a C, add to 180°."},
                ],
            },
            {
                "heading": "8.4 Why a triangle's angles make 180°",
                "figure": True,
                "teaches": ["proof"],
                "steps": [
                    {"kind": "question",
                     "text": "Tear the corners off a paper triangle and they make a straight line. But nobody can tear every triangle there is. "
                             "How can you be sure the angles add to 180° every time?"},
                    {"kind": "idea",
                     "text": "Draw a line through the top corner, parallel to the bottom side. "
                             "The three angles at the top corner fill that straight line, so they add to 180°. "
                             "Each one matches an angle of the triangle."},
                    {"kind": "picture",
                     "text": "In the figure, set the angle at A to 50° and the angle at B to 60°. "
                             "The red angle at A has a red copy at C, and the blue angle at B has a blue copy there too."},
                    {"kind": "reason",
                     "text": "Why are the copies equal? Each copy and its angle at A or B sit in a Z between the green line and side AB. "
                             "So they are alternate angles. The grey angle between the copies is the angle of the triangle at C."},
                    {"kind": "name",
                     "text": "A chain of steps like this, each with its reason, is a proof. "
                             "Each step is an if-then statement: if two lines are parallel, then alternate angles are equal. "
                             "A proof shows a fact holds for every triangle, not only the ones you drew."},
                    {"kind": "example",
                     "text": "A triangle has angles of 47° and 68°. The third angle is 180° − 47° − 68° = 65°. "
                             "The reason is that the angles in a triangle add to 180°."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to measure a few triangles and call it a proof. "
                             "A protractor reads to about 1°, and checking ten triangles still leaves every other triangle unchecked."},
                    {"kind": "turn",
                     "text": "A triangle's angles are x, 2x and 3x degrees. Find x.",
                     "answer": "30",
                     "answerKey": k.one(k.num("30"), accepts=["30", "x = 30", "30°"], rejects=["60", "90", "180"])},
                    {"kind": "sayBack",
                     "text": "A proof gives a reason for every step, so its fact holds for every triangle."},
                ],
            },
            {
                "heading": "8.5 The angle outside a triangle",
                "teaches": ["exterior-angle"],
                "steps": [
                    {"kind": "question",
                     "text": "A triangle has angles of 50°, 60° and 70°. Carry one side on past the 60° corner with a ruler. "
                             "What angle does the new line make with the other side at that corner?"},
                    {"kind": "idea",
                     "text": "The new angle and the 60° angle sit together on a straight line, so the new one is 180° − 60° = 120°. "
                             "That is the same as 50° + 70°, the angles at the other two corners."},
                    {"kind": "picture",
                     "text": "Draw the triangle and carry one side on past a corner. "
                             "Shade the angle outside the triangle, between the new line and the side next to it."},
                    {"kind": "reason",
                     "text": "Why do the other two angles add up to the outside one? The two angles at that corner make 180°, "
                             "and so do the three angles of the triangle. Take the angle inside that corner away from both."},
                    {"kind": "name",
                     "text": "The angle between one side carried on and the next side is an exterior angle. "
                             "An exterior angle of a triangle equals the sum of the angles at the other two corners."},
                    {"kind": "example",
                     "text": "A triangle has angles of 35° and 85° at two corners. The exterior angle at the third corner is 35° + 85° = 120°. "
                             "Check: the third angle is 180° − 120° = 60°, and 35 + 85 + 60 = 180."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to add in the angle beside the exterior angle as well. "
                             "The exterior angle equals the two angles away from it, not all three."},
                    {"kind": "turn",
                     "text": "A triangle has angles of 42° and 71° at two corners. What is the exterior angle at the third corner?",
                     "answer": "113°",
                     "answerKey": k.one(k.num("113"), accepts=["113", "113°", "= 113°"], rejects=["67", "180", "293"])},
                    {"kind": "sayBack",
                     "text": "An exterior angle of a triangle equals the two angles at the other corners added together."},
                ],
            },
            {
                "heading": "8.6 Angles in any shape with straight sides",
                "teaches": ["polygon", "interior-angle"],
                "steps": [
                    {"kind": "question",
                     "text": "A shape has five straight sides. From one corner, draw a line to every other corner that is not next to it. "
                             "How many triangles do you make, and what do the angles of the shape add to?"},
                    {"kind": "idea",
                     "text": "From one corner of a five-sided shape you can draw 2 lines, which cut it into 3 triangles. "
                             "Their angles fill the corners of the shape exactly. So the shape's angles add to 3 × 180° = 540°."},
                    {"kind": "picture",
                     "text": "Draw a six-sided shape and cut it up the same way from one corner. You get 4 triangles. "
                             "Each extra side adds one more triangle."},
                    {"kind": "reason",
                     "text": "Why are there always 2 fewer triangles than sides? Every side makes one triangle with the starting corner, "
                             "except the two sides that touch that corner."},
                    {"kind": "name",
                     "text": "A flat shape with straight sides is a polygon, and the angles inside it at its corners are its interior angles. "
                             "For n sides, the interior angles add to (n − 2) × 180°. "
                             "A regular polygon has all its sides equal and all its angles equal."},
                    {"kind": "example",
                     "text": "An eight-sided polygon has interior angles adding to (8 − 2) × 180° = 1080°. If it is regular, each is 1080° ÷ 8 = 135°. "
                             "Each exterior angle is then 180° − 135° = 45°. Walking once round the shape turns you a full 360°, and 8 × 45° = 360°."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to count one triangle for each side and use n × 180°. "
                             "A square would then add to 720°, but its four right angles make 360°."},
                    {"kind": "turn",
                     "text": "What do the interior angles of a seven-sided polygon add to?",
                     "answer": "900°",
                     "answerKey": k.one(k.num("900"), accepts=["900", "900°", "= 900°"], rejects=["1260", "1080", "720"])},
                    {"kind": "sayBack",
                     "text": "A polygon with n sides cuts into n − 2 triangles, so its interior angles add to (n − 2) × 180°."},
                ],
            },
            {
                "heading": "8.7 Halfway between two points",
                "teaches": ["midpoint"],
                "steps": [
                    {"kind": "question",
                     "text": "On a map grid, Kym's house is at (2, 1) and a friend's house is at (8, 5). "
                             "They walk towards each other and meet halfway. Where do they meet?"},
                    {"kind": "idea",
                     "text": "Across, halfway from 2 to 8 is 5. Up, halfway from 1 to 5 is 3. So they meet at (5, 3)."},
                    {"kind": "picture",
                     "text": "Mark both houses on squared paper and join them with a ruler. Draw the step under the line: 6 across and 4 up. "
                             "Halfway along the line is half of each, 3 across and 2 up from (2, 1)."},
                    {"kind": "reason",
                     "text": "Why average each coordinate? Halfway along the line means halfway across and halfway up. "
                             "The number halfway between two numbers is their total divided by 2."},
                    {"kind": "name",
                     "text": "A line segment is the part of a line between two points, and the point halfway along it is its midpoint. "
                             "For ends (x₁, y₁) and (x₂, y₂), the midpoint is ((x₁ + x₂) ÷ 2, (y₁ + y₂) ÷ 2)."},
                    {"kind": "example",
                     "text": "The midpoint of (−3, 4) and (5, −2) is ((−3 + 5) ÷ 2, (4 + (−2)) ÷ 2), which is (1, 1)."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to take the ends away instead of adding them: (5 − (−3)) ÷ 2 = 4. "
                             "That is how far across the midpoint is from each end, not its x-coordinate."},
                    {"kind": "turn",
                     "text": "What is the midpoint of (−6, 3) and (2, 9)?",
                     "answer": "(−2, 6)",
                     "answerKey": k.one(k.seq("-2", "6"), accepts=["(−2, 6)", "(-2, 6)", "−2, 6"],
                                        rejects=["(4, 3)", "(6, −2)", "(−4, 12)"])},
                    {"kind": "sayBack",
                     "text": "A midpoint averages the x-coordinates of the ends, then their y-coordinates."},
                ],
            },
        ],
        "callouts": [
            {"kind": "predict", "title": "Predict first",
             "body": "Predict the angle at C when the angles at A and B are both 65°. "
                     "Then set both sliders to 65° and read the grey angle."},
            {"kind": "check", "title": "Explain it",
             "body": "Two lines cross and one angle is 70°. "
                     "Explain to a friend why the angle straight across the crossing must be 70° too."},
            {"kind": "careful", "title": "Beside or opposite",
             "body": "Where two lines cross, the angles opposite each other are equal. "
                     "Angles side by side share a straight line, so they add to 180°."},
        ],
        "debate": {
            "id": "debate-ch08-angles",
            "oupUnitNumber": 8,
            "title": "Equal, or adding to 180°?",
            "contextPrompt": "A transversal crosses two parallel lines. Meera and Dev look at the two angles between the lines, "
                             "on the same side of the transversal. One of them is 65°.",
            "speakerAName": "Meera",
            "speakerAClaim": "Angles between parallel lines match, so the other one is 65° too.",
            "speakerBName": "Dev",
            "speakerBClaim": "They are co-interior angles, so they add to 180° and the other one is 115°.",
            "choices": [
                {"id": "ch08-a", "speakerLabel": "Meera is right (65°)",
                 "reasoningStatement": "Any two angles between parallel lines are equal.",
                 "isCorrect": False,
                 "socraticRebuttal": "Draw the transversal at a steep slant. Do the two angles on the same side look the same, "
                                     "or is one wide and the other narrow?"},
                {"id": "ch08-b", "speakerLabel": "Dev is right (115°)",
                 "reasoningStatement": "Co-interior angles, in a C shape, add to 180°.",
                 "isCorrect": True,
                 "socraticRebuttal": "Yes. The angle beside the 65° on the same parallel line is 115°. "
                                     "It is alternate to the other angle in the C, so that one is 115° as well."},
                {"id": "ch08-c", "speakerLabel": "Neither. Each is 90°.",
                 "reasoningStatement": "Two angles that add to 180° must each be 90°.",
                 "isCorrect": False,
                 "socraticRebuttal": "Is 65° + 115° also 180°? What does adding to 180° tell you about each angle on its own?"},
            ],
            "invariantTakeaway": "Alternate angles are equal, and co-interior angles add to 180°. Find the Z or the C before you decide.",
        },
        "keyTerms": ["Angle", "Vertically opposite angles", "Transversal", "Corresponding angles", "Alternate angles",
                     "Co-interior angles", "Proof", "Exterior angle", "Polygon", "Interior angle", "Midpoint"],
        "widgets": ["w_parallel_transversal_proof", "w_exterior_angle_tear_proof"],
        "widgetText": {
            "w_parallel_transversal_proof": {
                "title": "Copying the angles across",
                "challengePrompt": "Set the angle at A to 30° and the angle at B to 65°. "
                                   "Predict the angle at C before you read the first line of text.",
                "cutaway": "The green line through C is parallel to AB. The red and blue copies at C are alternate angles, "
                           "so the three angles at C fill a straight line.",
                "idealised": "The rule: the angles of a triangle add to 180°",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Set the angle at A to 50° and the angle at B to 60°."},
                    {"title": "2. Notice", "caption": "The red copy at C sits in a Z with the angle at A, so the two are equal."},
                    {"title": "3. Match the rule", "caption": "The red, grey and blue angles at C fill the green line: 50° + 70° + 60° = 180°."},
                    {"title": "4. Push it further", "caption": "Set both sliders to 65°. How small does the grey angle at C get?"},
                    {"title": "5. Draw it", "caption": "Draw a triangle in your journal with a line through one corner, parallel to the opposite side."},
                ],
            },
            "w_exterior_angle_tear_proof": {
                "title": "The angle outside the triangle",
                "challengePrompt": "Set the angle at A to 45° and the angle at B to 55°. "
                                   "Predict the amber angle outside B before you read it.",
                "cutaway": "The amber angle and the angle at B share a straight line, so the amber angle is 180° − 55° = 125°. "
                           "That equals 45° + 80°, the angles at A and C.",
                "idealised": "The rule: an exterior angle of a triangle = the sum of the angles at the other two corners",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Set the angle at A to 40° and the angle at B to 70°."},
                    {"title": "2. Notice", "caption": "The amber angle is 110°, and the angles at A and C are 40° and 70°."},
                    {"title": "3. Match the rule", "caption": "40° + 70° = 110°, so the exterior angle equals the two angles away from it."},
                    {"title": "4. Push it further", "caption": "Set the sides of the shape to 8. How many triangles does the text say it cuts into?"},
                    {"title": "5. Draw it", "caption": "Draw a triangle, carry one side on with a ruler, and measure the angle outside."},
                ],
            },
        },
        "atlasLessons": [
            {
                "title": "Chapter 8 · Parallel lines keep their angles",
                "question": "Why are corresponding angles equal when the lines are parallel?",
                "explanation": "Slide one parallel line along the transversal onto the other. It moves without turning, "
                               "so every angle at the first crossing lands on the matching angle at the second.",
                "limits": "The rule: corresponding and alternate angles are equal, and co-interior angles add to 180°",
            },
            {
                "title": "Chapter 8 · One proof for every triangle",
                "question": "How can one drawing show that the angles of every triangle add to 180°?",
                "explanation": "Draw a line through one corner parallel to the opposite side. "
                               "Alternate angles copy the other two corners onto that line, and a straight line is 180°.",
                "limits": "The rule: the angles of a triangle add to 180°",
            },
            {
                "title": "Chapter 8 · Cutting a polygon into triangles",
                "question": "Why do the interior angles of an n-sided polygon add to (n − 2) × 180°?",
                "explanation": "Lines from one corner cut the polygon into triangles, two fewer than it has sides. "
                               "The angles of those triangles fill its corners, 180° for each triangle.",
                "limits": "The rule: the interior angles of an n-sided polygon add to (n − 2) × 180°",
            },
        ],
        "visualMathTips": {},
        "schoolTopics": {
            "8.1": "An exterior angle of a triangle lies between one side carried on and the next side. "
                   "It equals the sum of the angles at the other two corners, so angles of 50° and 70° give an exterior angle of 120°.",
            "8.2": "Where two lines cross, vertically opposite angles are equal. When a transversal cuts parallel lines, "
                   "corresponding angles (F) and alternate angles (Z) are equal, and co-interior angles (C) add to 180°.",
            "8.3": "The midpoint of a line segment averages the coordinates of its ends. "
                   "The midpoint of (x₁, y₁) and (x₂, y₂) is ((x₁ + x₂) ÷ 2, (y₁ + y₂) ÷ 2).",
        },
        "schoolQuestions": {
            "q-oup-ch08-sb": {
                "workedExample": "Step 1: ∠ACD is an exterior angle, so it equals the angles at the other two corners, ∠BAC + ∠ABC.\n"
                                 "Step 2: 4x − 5 = (2x + 15) + (x + 20) = 3x + 35.\n"
                                 "Step 3: Take 3x from both sides and add 5: x = 40.\n"
                                 "Step 4: So ∠ACD = 4 × 40 − 5 = 155°. Check: ∠BAC = 95° and ∠ABC = 60°, and 95 + 60 = 155.",
                "fadedPrompt": "4x − 5 = 3x + 35, so x = ___ and ∠ACD = 4x − 5 = ___°.",
            },
            "q-oup-ch08-wb-focus": {
                "workedExample": "Step 1: Add the x-coordinates and halve: (−4 + 10) ÷ 2 = 6 ÷ 2 = 3.\n"
                                 "Step 2: Add the y-coordinates and halve: (7 + (−3)) ÷ 2 = 4 ÷ 2 = 2.\n"
                                 "Step 3: So M = (3, 2).\n"
                                 "Step 4: Check: from A to M is 7 across and 5 down, and from M to B is 7 across and 5 down too.",
                "fadedPrompt": "(−4 + 10) ÷ 2 = 3 and (7 + (−3)) ÷ 2 = ___, so M = (3, ___).",
            },
            "q-oup-ch08-wb-practice": {
                "workedExample": "Step 1: Co-interior angles add to 180°, so (3y + 10) + (2y − 5) = 180.\n"
                                 "Step 2: Collect like terms: 5y + 5 = 180.\n"
                                 "Step 3: Take 5 from both sides: 5y = 175, so y = 35.\n"
                                 "Step 4: Check: the angles are 115° and 65°, and 115 + 65 = 180.",
                "fadedPrompt": "(3y + 10) + (2y − 5) = 180 gives 5y + 5 = 180, so 5y = ___ and y = ___.",
            },
            "q-oup-ch08-wb-challenge": {
                "workedExample": "Step 1: Each exterior angle is 180° − 156° = 24°.\n"
                                 "Step 2: The exterior angles of a polygon add to 360°, one at each corner.\n"
                                 "Step 3: So there are 360 ÷ 24 = 15 corners, and 15 sides.\n"
                                 "Step 4: Check: (15 − 2) × 180° = 2340°, and 2340 ÷ 15 = 156.",
                "fadedPrompt": "Each exterior angle is 180° − 156° = 24°, so the number of sides is 360 ÷ 24 = ___.",
            },
        },
    }


def cards(k):
    """The concept cards this chapter teaches. The Angle card is bedrock, in bedrock.py."""
    return {
        "vertically-opposite-angles": {
            "name": "Vertically opposite angles",
            "aliases": ["vertically opposite angles", "vertically opposite angle", "vertically opposite"],
            "oneSentence": "The angles opposite each other where two straight lines cross. They are equal.",
            "picture": "Scissors opened into an X: the gap between the blades and the gap between the handles are the same angle.",
            "steps": [
                "Find where two straight lines cross.",
                "Pick an angle, and look straight across the crossing to the angle opposite it.",
                "Those two are equal. Each angle beside them makes 180° with them.",
            ],
            "workedExample": "Two lines cross, and one angle is 125°. The angle opposite is 125°, "
                             "and each of the other two is 180° − 125° = 55°.",
            "check": {
                "prompt": "Two lines cross. One angle is 2x and the angle opposite it is 84°. Find x.",
                "answer": "42",
                "answerKey": k.one(k.num("42"), accepts=["42", "x = 42", "= 42"], rejects=["84", "48", "168"]),
            },
            "mixUp": {
                "name": "angles side by side",
                "how": "The angle beside a 125° angle is not 125°. The two share a straight line, so it is 55°.",
            },
            "standsOn": ["angle"],
        },
        "transversal": {
            "name": "Transversal",
            "aliases": ["transversal", "transversals"],
            "oneSentence": "A line that crosses two or more other lines.",
            "picture": "A road crossing two railway tracks, with a crossing at each track.",
            "steps": [
                "Find the line that cuts across the others.",
                "Look at the four angles at each crossing.",
                "If the lines it crosses are parallel, the angles at one crossing match the angles at the other.",
            ],
            "workedExample": "A transversal crosses two parallel lines. At the top crossing the four angles are 65°, 115°, 65° and 115°. "
                             "The bottom crossing has the same four angles.",
            "check": {
                "prompt": "A transversal crosses two parallel lines. How many angles does it make in all, at the two crossings?",
                "answer": "8",
                "answerKey": k.one(k.num("8"), accepts=["8", "8 angles", "= 8"], rejects=["4", "2", "6"]),
            },
            "mixUp": {
                "name": "one of the parallel lines",
                "how": "The parallel lines point the same way. The transversal is the line that cuts across them at a slant.",
            },
            "standsOn": ["parallel-lines", "angle"],
        },
        "corresponding-angles": {
            "name": "Corresponding angles",
            "aliases": ["corresponding angles", "corresponding angle"],
            "oneSentence": "Angles in the same position at each crossing of a transversal. They are equal when the lines are parallel.",
            "picture": "A capital F: its two arms are the parallel lines, and the angles under each arm match.",
            "steps": [
                "Find the transversal and the parallel lines.",
                "Pick an angle at one crossing, and note which side of each line it is on.",
                "The angle on the same sides at the other crossing is its corresponding angle, and it is equal.",
            ],
            "workedExample": "At the top crossing, the angle above the line and right of the transversal is 72°. "
                             "At the bottom crossing, the angle above the line and right of the transversal is 72° too.",
            "check": {
                "prompt": "A transversal crosses two parallel lines. One angle is (3x + 10)° and its corresponding angle is 100°. Find x.",
                "answer": "30",
                "answerKey": k.one(k.num("30"), accepts=["30", "x = 30", "= 30"], rejects=["100", "90", "110"]),
            },
            "mixUp": {
                "with": "alternate-angles",
                "how": "Corresponding angles sit on the same side of the transversal, in an F. "
                       "Alternate angles sit on opposite sides, between the lines, in a Z.",
            },
            "standsOn": ["transversal", "angle"],
        },
        "alternate-angles": {
            "name": "Alternate angles",
            "aliases": ["alternate angles", "alternate angle"],
            "oneSentence": "Angles between two lines, on opposite sides of a transversal. They are equal when the lines are parallel.",
            "picture": "A capital Z: its top and bottom strokes are the parallel lines, and the two sharp corners inside it are equal.",
            "steps": [
                "Find the transversal and the two parallel lines.",
                "Look only between the parallel lines.",
                "An angle on one side of the transversal equals the angle on the other side, at the other crossing.",
            ],
            "workedExample": "A Z drawn across two parallel lines has one inside corner of 48°. "
                             "The other inside corner is 48° as well, because the two are alternate angles.",
            "check": {
                "prompt": "Two alternate angles are (5x)° and (3x + 40)°. Find x.",
                "answer": "20",
                "answerKey": k.one(k.num("20"), accepts=["20", "x = 20", "= 20"], rejects=["17.5", "5", "100"]),
            },
            "mixUp": {
                "with": "co-interior-angles",
                "how": "Alternate angles sit on opposite sides of the transversal and are equal. "
                       "Co-interior angles sit on the same side and add to 180°.",
            },
            "standsOn": ["transversal", "angle"],
        },
        "co-interior-angles": {
            "name": "Co-interior angles",
            "aliases": ["co-interior angles", "co-interior angle", "co-interior"],
            "oneSentence": "Angles between two lines, on the same side of a transversal. They add to 180° when the lines are parallel.",
            "picture": "A capital C: its top and bottom are the parallel lines, and its two inside corners add to 180°.",
            "steps": [
                "Find the transversal and the two parallel lines.",
                "Look between the lines, on one side of the transversal.",
                "The two angles there add to 180°.",
            ],
            "workedExample": "Two co-interior angles are 3x and 6x. Then 9x = 180, so x = 20, and the angles are 60° and 120°.",
            "check": {
                "prompt": "One co-interior angle is 74°. What is the other?",
                "answer": "106°",
                "answerKey": k.one(k.num("106"), accepts=["106", "106°", "= 106°"], rejects=["74", "16", "286"]),
            },
            "mixUp": {
                "with": "alternate-angles",
                "how": "Co-interior angles add to 180°, and they are equal only when both are 90°. Alternate angles are always equal.",
            },
            "standsOn": ["transversal", "angle"],
        },
        "proof": {
            "name": "Proof",
            "aliases": ["proof", "proofs"],
            "oneSentence": "A chain of steps, each with a reason, that shows a fact is true in every case.",
            "picture": "A row of dominoes: each step knocks over the next, starting from facts you already trust.",
            "steps": [
                "Write down what you know.",
                "Make one step at a time, and give each step its reason.",
                "Finish with the fact you set out to show.",
            ],
            "workedExample": "To show vertically opposite angles are equal: a + b = 180 on one straight line, "
                             "and b + c = 180 on the other. So a = c.",
            "check": {
                "prompt": "Finish this step of a proof: the angles in a triangle add to 180°, "
                          "so a triangle with angles of 90° and 35° has a third angle of ___.",
                "answer": "55°",
                "answerKey": k.one(k.num("55"), accepts=["55", "55°", "= 55°"], rejects=["125", "235", "145"]),
            },
            "mixUp": {
                "name": "checking some examples",
                "how": "Measuring ten triangles is a check, not a proof. A proof gives a reason that covers every triangle, "
                       "even the ones nobody drew.",
            },
            "standsOn": ["if-then-statement"],
        },
        "exterior-angle": {
            "name": "Exterior angle",
            "aliases": ["exterior angle", "exterior angles"],
            "oneSentence": "The angle between one side of a shape carried on past a corner and the next side.",
            "picture": "A triangle with one side drawn on past a corner, and the angle outside the triangle shaded.",
            "steps": [
                "Carry one side on past a corner with a ruler.",
                "The angle outside, between that line and the next side, is the exterior angle.",
                "It and the angle inside at that corner add to 180°.",
            ],
            "workedExample": "A triangle has angles of 30°, 70° and 80°. The exterior angle at the 80° corner is 180° − 80° = 100°, "
                             "which is 30° + 70°.",
            "check": {
                "prompt": "A triangle has angles of 58° and 64° at two corners. What is the exterior angle at the third corner?",
                "answer": "122°",
                "answerKey": k.one(k.num("122"), accepts=["122", "122°", "= 122°"], rejects=["58", "180", "238"]),
            },
            "mixUp": {
                "with": "interior-angle",
                "how": "An interior angle is inside the shape at a corner. The exterior angle is outside it, and the two add to 180°.",
            },
            "standsOn": ["angle"],
        },
        "polygon": {
            "name": "Polygon",
            "aliases": ["polygon", "polygons", "regular polygon", "regular polygons"],
            "oneSentence": "A flat shape with straight sides that join up, such as a triangle, a square or a hexagon.",
            "picture": "A five-sided shape cut by 2 lines from one corner into 3 triangles.",
            "steps": [
                "Check that every side is straight and that the sides join up.",
                "Count the sides: 5 sides make a pentagon, 6 a hexagon and 8 an octagon.",
                "If all the sides and all the angles are equal, it is a regular polygon.",
            ],
            "workedExample": "A stop sign has 8 equal straight sides and 8 equal angles, so it is a regular octagon.",
            "check": {
                "prompt": "Lines from one corner cut a 10-sided polygon into triangles. How many triangles?",
                "answer": "8",
                "answerKey": k.one(k.num("8"), accepts=["8", "8 triangles", "= 8"], rejects=["10", "9", "7"]),
            },
            "mixUp": {
                "name": "a shape with a curve",
                "how": "A semicircle is not a polygon, because part of its outline is curved.",
            },
            "standsOn": ["angle"],
        },
        "interior-angle": {
            "name": "Interior angle",
            "aliases": ["interior angle", "interior angles"],
            "oneSentence": "An angle inside a polygon, at one of its corners.",
            "picture": "A hexagon cut from one corner into 4 triangles, with its six corner angles shaded inside.",
            "steps": [
                "Count the sides, n.",
                "The interior angles add to (n − 2) × 180°.",
                "For a regular polygon, divide that total by n to get each one.",
            ],
            "workedExample": "A regular pentagon has interior angles adding to (5 − 2) × 180° = 540°. Each one is 540° ÷ 5 = 108°.",
            "check": {
                "prompt": "Each interior angle of a regular polygon is 150°. How many sides does it have?",
                "answer": "12",
                "answerKey": k.one(k.num("12"), accepts=["12", "12 sides", "= 12"], rejects=["30", "10", "6"]),
            },
            "mixUp": {
                "with": "exterior-angle",
                "how": "Each interior angle of a regular hexagon is 120°, and each exterior angle is 60°. "
                       "At any one corner, the two add to 180°.",
            },
            "standsOn": ["polygon", "angle"],
        },
        "midpoint": {
            "name": "Midpoint",
            "aliases": ["midpoint", "midpoints"],
            "oneSentence": "The point halfway along a line segment, found by averaging the coordinates of its ends.",
            "picture": "A rope tied between two posts, with a knot exactly in the middle.",
            "steps": [
                "Add the two x-coordinates and halve the total.",
                "Add the two y-coordinates and halve the total.",
                "Write the answers as a point, x first.",
            ],
            "workedExample": "The midpoint of (1, 6) and (7, 2) is ((1 + 7) ÷ 2, (6 + 2) ÷ 2), which is (4, 4).",
            "check": {
                "prompt": "What is the midpoint of (3, −1) and (9, 5)?",
                "answer": "(6, 2)",
                "answerKey": k.one(k.seq("6", "2"), accepts=["(6, 2)", "6, 2", "M = (6, 2)"],
                                   rejects=["(3, 3)", "(2, 6)", "(12, 4)"]),
            },
            "mixUp": {
                "name": "half the step",
                "how": "From (3, −1) to (9, 5) the step is 6 across and 6 up. Half the step, 3 and 3, says how far to go, "
                       "not where the midpoint is.",
            },
            "standsOn": ["coordinates"],
            "footing": "coordinates-and-gradient",
        },
    }


def sums():
    """Every sum chapter 8, its cards and its school unit text state, recomputed. test_book_maths.py checks computed == stated."""
    return [
        # Skill card
        ("65° across parallel lines", (65, 180 - 65), (65, 115)),
        ("exterior angle for 40° and 75°", 40 + 75, 180 - third_angle(40, 75)),
        ("the skill card exterior angle", 40 + 75, 115),
        ("midpoint of (−2, 5) and (6, 1)", point(midpoint((-2, 5), (6, 1))), "(2, 3)"),
        # Hook, bridge, figure and callouts
        ("the figure's triangle", (third_angle(50, 60), 50 + third_angle(50, 60) + 60), (70, 180)),
        ("both angles 65°", third_angle(65, 65), 50),
        # 8.1 Where two lines cross
        ("beside the 70°", 180 - 70, 110),
        ("opposite angles", 180 - 110, 70),
        ("beside 38°", 180 - 38, 142),
        ("round the crossing", 38 + 142 + 38 + 142, 360),
        ("2x = 142", Fraction(142, 2), 71),
        ("3x = 75", (Fraction(75, 3), Fraction(180 - 75, 3), 180 - 75), (25, 35, 105)),
        # 8.2 A line across parallel lines
        ("beside 112°", 180 - 112, 68),
        ("2x + 7 = 47", (Fraction(47 - 7, 2), Fraction(180 - 47 - 7, 2), Fraction(47 + 7, 2)), (20, 63, 27)),
        # 8.3 Z angles and C angles
        ("the C beside 70°", (180 - 70, 70 + 110), (110, 180)),
        ("x and x + 40", (Fraction(180 - 40, 2), 70 + 40), (70, 110)),
        ("4x and 2x + 42", (Fraction(180 - 42, 6), Fraction(42, 2), 4 * 23, 2 * 23 + 42, 4 * 23 + 2 * 23 + 42), (23, 21, 92, 88, 180)),
        # 8.4 Why a triangle's angles make 180°
        ("47° and 68°", third_angle(47, 68), 65),
        ("x, 2x and 3x", (Fraction(180, 1 + 2 + 3), 2 * 30, 3 * 30), (30, 60, 90)),
        # 8.5 The angle outside a triangle
        ("outside the 60° corner", (180 - 60, 50 + 70, 50 + 60 + 70), (120, 120, 180)),
        ("35° and 85°", (35 + 85, 180 - 120, 35 + 85 + 60), (120, 60, 180)),
        ("42° and 71°", (42 + 71, third_angle(42, 71), 360 - 67), (113, 67, 293)),
        # 8.6 Angles in any shape with straight sides
        ("five sides", (5 - 2 - 1, 5 - 2, 3 * 180, angle_sum(5)), (2, 3, 540, 540)),
        ("six sides", 6 - 2, 4),
        ("eight sides", (angle_sum(8), Fraction(1080, 8), 180 - 135, 8 * 45), (1080, 135, 45, 360)),
        ("a square by the slip", (4 * 180, angle_sum(4), 4 * 90), (720, 360, 360)),
        ("seven sides", (angle_sum(7), 7 * 180, 6 * 180, 4 * 180), (900, 1260, 1080, 720)),
        # 8.7 Halfway between two points
        ("the two houses", (point(midpoint((2, 1), (8, 5))), 8 - 2, 5 - 1, 2 + 3, 1 + 2), ("(5, 3)", 6, 4, 5, 3)),
        ("(−3, 4) and (5, −2)", (point(midpoint((-3, 4), (5, -2))), Fraction(5 - (-3), 2)), ("(1, 1)", 4)),
        ("(−6, 3) and (2, 9)", point(midpoint((-6, 3), (2, 9))), "(-2, 6)"),
        # Widgets and lessons
        ("A 30°, B 65°", third_angle(30, 65), 85),
        ("A 45°, B 55°", (180 - 55, 45 + third_angle(45, 55), third_angle(45, 55)), (125, 125, 80)),
        ("A 40°, B 70°", (180 - 70, third_angle(40, 70), 40 + 70), (110, 70, 110)),
        ("8 sides", 8 - 2, 6),
        # Debate
        ("beside the 65°", (180 - 65, 65 + 115), (115, 180)),
        # Cards
        ("a 130° angle on a line", 180 - 130, 50),
        ("clock hands at 12 and 3", 3 * (360 // 12), 90),
        ("crossing at 125°", 180 - 125, 55),
        ("2x = 84", (Fraction(84, 2), Fraction(180 - 84, 2), 2 * 84), (42, 48, 168)),
        ("65° and 115°", 65 + 115, 180),
        ("two crossings", 2 * 4, 8),
        ("3x + 10 = 100", (Fraction(100 - 10, 3), 100 - 10, 100 + 10), (30, 90, 110)),
        ("5x = 3x + 40", (Fraction(40, 5 - 3), 5 * 20, 3 * 20 + 40, Fraction(180 - 40, 8)), (20, 100, 100, Fraction("17.5"))),
        ("3x and 6x", (Fraction(180, 9), 3 * 20, 6 * 20), (20, 60, 120)),
        ("74° co-interior", (180 - 74, 90 - 74, 360 - 74), (106, 16, 286)),
        ("90° and 35°", (third_angle(90, 35), 90 + 35, 180 - 35), (55, 125, 145)),
        ("30°, 70° and 80°", (30 + 70 + 80, 180 - 80, 30 + 70), (180, 100, 100)),
        ("58° and 64°", (58 + 64, third_angle(58, 64), 180 + 58), (122, 58, 238)),
        ("10 sides", 10 - 2, 8),
        ("hexagon", (6 - 2, Fraction(angle_sum(6), 6), 180 - 120), (4, 120, 60)),
        ("regular pentagon", (angle_sum(5), Fraction(540, 5)), (540, 108)),
        ("150° each", (180 - 150, Fraction(360, 30), angle_sum(12) / 12), (30, 12, 150)),
        ("(1, 6) and (7, 2)", point(midpoint((1, 6), (7, 2))), "(4, 4)"),
        ("(3, −1) and (9, 5)", (point(midpoint((3, -1), (9, 5))), 9 - 3, 5 - (-1)), ("(6, 2)", 6, 6)),
        # School unit 8
        ("50° and 70° outside", 50 + 70, 120),
        ("∠ACD = 4x − 5", ((2 * 40 + 15) + (40 + 20), 4 * 40 - 5, 2 * 40 + 15, 40 + 20, 3 * 40 + 35), (155, 155, 95, 60, 155)),
        ("x = 40", 40 - 5 + 5, 40),
        ("midpoint of A(−4, 7) and B(10, −3)", (point(midpoint((-4, 7), (10, -3))), -4 + 10, 7 + (-3)), ("(3, 2)", 6, 4)),
        ("A to M and M to B", ((3 - (-4), 2 - 7), (10 - 3, -3 - 2)), ((7, -5), (7, -5))),
        ("(3y + 10) + (2y − 5) = 180", (Fraction(180 - 5, 5), 180 - 5, 3 * 35 + 10, 2 * 35 - 5), (35, 175, 115, 65)),
        ("156° each", (180 - 156, Fraction(360, 24), angle_sum(15), Fraction(2340, 15)), (24, 15, 2340, 156)),
    ]


def answers():
    """Chapter 8's turn answers and its cards' check answers, computed."""
    return {
        "ch08-s1-turn": Fraction(75, 3),
        "ch08-s2-turn": Fraction(47 - 7, 2),
        "ch08-s3-turn": Fraction(180 - 42, 4 + 2),
        "ch08-s4-turn": Fraction(180, 1 + 2 + 3),
        "ch08-s5-turn": 42 + 71,
        "ch08-s6-turn": angle_sum(7),
        "ch08-s7-turn": point(midpoint((-6, 3), (2, 9))),
        "vertically-opposite-angles-check": Fraction(84, 2),
        "transversal-check": 2 * 4,
        "corresponding-angles-check": Fraction(100 - 10, 3),
        "alternate-angles-check": Fraction(40, 5 - 3),
        "co-interior-angles-check": 180 - 74,
        "proof-check": third_angle(90, 35),
        "exterior-angle-check": 58 + 64,
        "polygon-check": 10 - 2,
        "interior-angle-check": Fraction(360, 180 - 150),
        "midpoint-check": point(midpoint((3, -1), (9, 5))),
    }
