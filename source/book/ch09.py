"""
Chapter 9, written by hand to docs/CONTENT_BRIEF.md. It carries school unit 3.

Each section teaches one idea in nine steps, in this order: question, idea, picture, reason, name,
example, mistake, turn, sayBack. A section's `teaches` lists the concept cards whose names first
appear in its `name` step. `build(k)` returns the chapter and `cards(k)` its concept cards; both take the
exporter's answer-key helpers. Every section starts from something she can hold or draw: a goat on a rope,
a pair of compasses, a boat leaving a harbour, a cereal box opened flat.

`schoolTopics` and `schoolQuestions` rewrite the topic summaries, worked examples and faded prompts of
school unit 3. The answer keys and stuck sheets stay in the exporter.
"""

from math import isqrt

from book.arithmetic import Fraction


def back_bearing(bearing):
    """The bearing of the way back: half a turn from the way out."""
    return (bearing + 180) % 360


def three_figures(bearing):
    """A bearing as the text writes it, with three figures."""
    return f"{bearing:03d}°"


def euler_count(vertices, edges, faces):
    """V − E + F for a solid."""
    return vertices - edges + faces


def fourth_angle(*angles):
    """The angle that makes a quadrilateral's angles up to 360°."""
    return 360 - sum(angles)


def arcs_cross(ab, opening):
    """Arcs of one compass opening from A and from B cross only when the opening is more than half of AB."""
    return opening > Fraction(ab, 2)


def build(k):
    return {
        "number": 9,
        "title": "Constructions, bearings and nets",
        "subtitle": "School book chapter 3 · Compass drawings, four-sided shapes, directions and solids",
        "hookSummary": "With only a pencil, a ruler and a pair of compasses you can cut a line exactly in half. "
                       "No measuring is needed. Why do two arcs know where the middle is?",
        "beyondSchoolBook": False,
        "skillCard": {
            "skill": "Drawing exact shapes with compasses, giving directions as bearings, and counting the parts of a solid",
            "sheCan": {
                "prompt": "With no calculator: a ship sails on a bearing of 070°. What is the bearing back to its start? "
                          "A solid with no holes has 5 vertices and 8 edges: how many faces does it have? "
                          "Three angles of a quadrilateral are 90°, 80° and 105°: find the fourth.",
                "answer": "The bearing back is 070° + 180° = 250°. Euler's formula gives 5 − 8 + F = 2, so F = 5. "
                          "The fourth angle is 360° − 275° = 85°.",
            },
            "whyItMatters": "Sailors and pilots steer by bearings, and builders draw exact views of a house before anyone lays a brick. "
                            "A compass drawing shows where every point that obeys a rule must lie.",
            "standsOn": [
                "Chapter 8: angle facts, co-interior angles and the midpoint",
                "Chapter 7: parallel lines",
                "Measuring lengths with a ruler and angles in degrees",
            ],
            "unlocks": [
                "Chapter 10: circles, and how much a solid holds",
                "Chapter 11: moving and resizing shapes",
                "Chapter 12: the straight-line distance across a journey with a turn in it",
            ],
        },
        "intuitionToFormula": {
            "concreteAction": "Set AB to 6 cm and the compass opening to 4 cm. "
                              "The blue arcs from A and B cross above and below AB, and the red line joins the two crossings.",
            "ahaInvariant": "Move P up and down the red line. PA and PB change, but they always stay equal. "
                            "So every point on the red line is as far from A as it is from B.",
            "formulaDisplay": "PA = PB for every point P on the perpendicular bisector of AB",
            "termMappings": [
                {"symbol": "the arcs", "visualPart": "The blue arcs", "colorRole": "blue",
                 "meaning": "Points one compass opening from A, and points one compass opening from B"},
                {"symbol": "the perpendicular bisector", "visualPart": "The red line", "colorRole": "red",
                 "meaning": "The line through both crossings, at a right angle to AB"},
                {"symbol": "PA = PB", "visualPart": "The two green dashed lines", "colorRole": "green",
                 "meaning": "The distance from P to A, and the distance from P to B"},
            ],
            "atlasFigureRef": "maths/ch09-loci-constructions/index.html",
        },
        "sections": [
            {
                "heading": "9.1 Every point at one distance",
                "teaches": ["locus"],
                "steps": [
                    {"kind": "question",
                     "text": "A goat is tied to a post by a rope 3 m long. It walks round with the rope pulled tight. "
                             "What shape does it trace on the grass?"},
                    {"kind": "idea",
                     "text": "Every spot it reaches with the rope tight is exactly 3 m from the post. "
                             "Those spots make a circle, with the post at its centre."},
                    {"kind": "picture",
                     "text": "Push a pin into card and loop a 3 cm thread round the pin and a pencil. "
                             "Draw with the thread pulled tight. Every pencil mark is 3 cm from the pin."},
                    {"kind": "reason",
                     "text": "Why a circle, and nothing else? A spot closer than 3 m leaves the rope slack. "
                             "A spot further away needs a longer rope. Only the spots at exactly 3 m are left."},
                    {"kind": "name",
                     "text": "All the points that obey a rule make up a locus, and more than one locus are loci. "
                             "The locus of points 3 m from a post is a circle round the post."},
                    {"kind": "example",
                     "text": "The locus of points 2 cm from a point O is a circle round O. The point 2 cm to the left of O is on it. "
                             "A point 1 cm from O is inside the circle, so it is not on the locus."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to mark one point that obeys the rule and stop. "
                             "A locus is every point that obeys it, so it is usually a whole line or curve."},
                    {"kind": "turn",
                     "text": "A goat's rope is 4 m long and tied to a post. "
                             "How wide is the circle its rope traces, from one side to the other through the post?",
                     "answer": "8 m",
                     "answerKey": k.one(k.num("8"), accepts=["8", "8 m", "8m"], rejects=["4", "16", "2"])},
                    {"kind": "sayBack",
                     "text": "A locus is every point that obeys a rule. Points at one distance from a point make a circle."},
                ],
            },
            {
                "heading": "9.2 Equally far from two points",
                "figure": True,
                "teaches": ["perpendicular-bisector"],
                "steps": [
                    {"kind": "question",
                     "text": "Two friends live at A and B, 6 km apart. They want a café exactly as far from one home as from the other. "
                             "Where could it go?"},
                    {"kind": "idea",
                     "text": "The point halfway between A and B works, 3 km from each. "
                             "So does any point straight above or below that halfway point, on a line across AB."},
                    {"kind": "picture",
                     "text": "In the figure, set AB to 6 cm and the compass opening to 4 cm. "
                             "The blue arcs from A and B cross twice, above and below AB. The red line joins the two crossings."},
                    {"kind": "reason",
                     "text": "Why is each crossing equally far from A and B? Both arcs were drawn with the same opening, 4 cm. "
                             "Fold the paper along the red line and A lands on B, so every point on the fold is equally far from both."},
                    {"kind": "name",
                     "text": "To bisect something is to cut it into two equal parts. "
                             "The red line is the perpendicular bisector of AB: it cuts AB in half at its midpoint, at a right angle. "
                             "It is the locus of points equally far from A and B."},
                    {"kind": "example",
                     "text": "A and B are 8 cm apart. Open the compasses to 5 cm and draw an arc from each end. "
                             "The line through the two crossings meets AB 4 cm from each end, at a right angle."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to open the compasses to half of AB or less. "
                             "Then the two arcs only touch, or miss each other, and there is no line to draw."},
                    {"kind": "turn",
                     "text": "A and B are 10 cm apart. A point P is on the perpendicular bisector of AB, and PA is 13 cm. What is PB?",
                     "answer": "13 cm",
                     "answerKey": k.one(k.num("13"), accepts=["13", "13 cm", "PB = 13"], rejects=["10", "5", "26"])},
                    {"kind": "sayBack",
                     "text": "Every point on the perpendicular bisector of AB is as far from A as it is from B."},
                ],
            },
            {
                "heading": "9.3 Cutting an angle in half",
                "teaches": ["angle-bisector"],
                "steps": [
                    {"kind": "question",
                     "text": "Two straight fences meet at a corner at 70°. A gardener wants a path that stays as far from one fence as from the other. "
                             "Which way should it run?"},
                    {"kind": "idea",
                     "text": "The path should split the corner evenly, into two angles of 35°. "
                             "Then every point on it is the same distance from each fence."},
                    {"kind": "picture",
                     "text": "Draw a 70° angle. Put the compass point on the corner and draw an arc that crosses both arms. "
                             "From each crossing, draw an arc of one size so the two meet inside. Rule a line from the corner through that point."},
                    {"kind": "reason",
                     "text": "Why are the two halves equal? Join the meeting point to the two crossings, and you have two triangles. "
                             "Their three sides match pair by pair, so their angles match too, including the two halves at the corner."},
                    {"kind": "name",
                     "text": "The line that cuts an angle into two equal angles is its angle bisector. "
                             "It is the locus of points the same distance from both arms of the angle."},
                    {"kind": "example",
                     "text": "The angle bisector of a 130° angle makes two angles of 65°. "
                             "A point on it that is 4 cm from one arm is 4 cm from the other arm too."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to measure the distance to an arm along a slant. "
                             "The distance from a point to a line is the shortest one, at a right angle to the line."},
                    {"kind": "turn",
                     "text": "An angle of 148° is cut by its angle bisector. What size is each of the two new angles?",
                     "answer": "74°",
                     "answerKey": k.one(k.num("74"), accepts=["74", "74°", "= 74°"], rejects=["296", "32", "148"])},
                    {"kind": "sayBack",
                     "text": "An angle bisector cuts an angle into two equal halves, and its points are equally far from both arms."},
                ],
            },
            {
                "heading": "9.4 Triangles that must match",
                "teaches": ["congruent"],
                "steps": [
                    {"kind": "question",
                     "text": "Kym and a friend each draw a triangle with sides of 5 cm, 6 cm and 7 cm. "
                             "Must their two triangles be exactly the same?"},
                    {"kind": "idea",
                     "text": "Yes. Draw the 7 cm side first. The third corner must be 5 cm from one end and 6 cm from the other, "
                             "and only one point above the line is both."},
                    {"kind": "picture",
                     "text": "Rule a 7 cm line. Open the compasses to 5 cm and draw an arc from the left end. "
                             "Open them to 6 cm and draw an arc from the right end. Join the crossing to both ends."},
                    {"kind": "reason",
                     "text": "Why is there no other choice? Each arc is a locus, every point at one distance from an end. "
                             "Above the line the two arcs cross once. The crossing below gives the same triangle, flipped over."},
                    {"kind": "name",
                     "text": "Shapes with exactly the same shape and size are congruent. "
                             "Two triangles are congruent if all three sides match, written SSS. "
                             "Two sides and the angle between them also fix a triangle, written SAS. So do two angles and the side between them, written ASA."},
                    {"kind": "example",
                     "text": "Triangle ABC has AB = 6 cm, angle A = 40° and AC = 9 cm. Every triangle drawn from those three facts is congruent to it, by SAS. "
                             "So its third side and its other two angles match ABC's as well."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to use three matching angles. A triangle with every angle 60° can have sides of 1 cm or of 1 km. "
                             "Matching angles fix the shape, but not the size."},
                    {"kind": "turn",
                     "text": "Triangle PQR is congruent to triangle ABC, with P matching A, Q matching B and R matching C. "
                             "Angle A is 50° and angle B is 70°. What is angle R?",
                     "answer": "60°",
                     "answerKey": k.one(k.num("60"), accepts=["60", "60°", "R = 60°"], rejects=["50", "70", "120"])},
                    {"kind": "sayBack",
                     "text": "Congruent shapes match exactly. SSS, SAS or ASA is enough to show that two triangles are congruent."},
                ],
            },
            {
                "heading": "9.5 Four sides and two diagonals",
                "teaches": ["quadrilateral"],
                "steps": [
                    {"kind": "question",
                     "text": "In 9.2, each arc crossing was 4 cm from A and 4 cm from B. "
                             "Join A, the top crossing, B and the bottom crossing in order. What shape do the four lines make?"},
                    {"kind": "idea",
                     "text": "All four sides are 4 cm, so it is a diamond with equal sides. "
                             "Line AB and the red line join its opposite corners, and they cross at a right angle, halfway along each."},
                    {"kind": "picture",
                     "text": "Draw a square, a rectangle, a diamond with equal sides and a kite. "
                             "In each, join opposite corners with two straight lines. Mark where they cross at a right angle."},
                    {"kind": "reason",
                     "text": "Why do the angles of any four-sided shape add to 360°? A line between opposite corners cuts it into 2 triangles. "
                             "Each triangle's angles add to 180°, and 2 × 180° = 360°."},
                    {"kind": "name",
                     "text": "A polygon with four sides is a quadrilateral, and its angles add to 360°. "
                             "A rhombus has four equal sides, and a parallelogram has two pairs of parallel sides. "
                             "The lines joining opposite corners are the diagonals."},
                    {"kind": "example",
                     "text": "A kite has angles of 110°, 110° and 50°. Its fourth angle is 360° − 110° − 110° − 50° = 90°. "
                             "Its diagonals cross at a right angle, as a kite's always do."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to say a square is not a rhombus. "
                             "A square has four equal sides, so it is a rhombus, one that has right angles too."},
                    {"kind": "turn",
                     "text": "Three angles of a quadrilateral are 85°, 95° and 110°. What is the fourth angle?",
                     "answer": "70°",
                     "answerKey": k.one(k.num("70"), accepts=["70", "70°", "= 70°"], rejects=["290", "180", "110"])},
                    {"kind": "sayBack",
                     "text": "A quadrilateral has four sides and angles adding to 360°. Its sides and diagonals tell which kind it is."},
                ],
            },
            {
                "heading": "9.6 Directions as bearings",
                "teaches": ["bearing"],
                "steps": [
                    {"kind": "question",
                     "text": "A boat leaves a harbour heading north-east, and the captain writes the direction as 045°. "
                             "What does that number measure, and why does it have three figures?"},
                    {"kind": "idea",
                     "text": "Face north, then turn clockwise until you face the boat's way. North-east is halfway to east, so the turn is 45°. "
                             "Writing 045° keeps every direction to three figures, from 000° to 359°."},
                    {"kind": "picture",
                     "text": "Draw a north arrow at the harbour and the boat's path. Mark the turn from north to the path, clockwise. "
                             "Then draw a north arrow at the boat, and look back along the path to the harbour."},
                    {"kind": "reason",
                     "text": "Why does the way back differ by 180°? The two north arrows are parallel. "
                             "The angles between them and the path are co-interior angles, so they add to 180°."},
                    {"kind": "name",
                     "text": "A direction measured clockwise from north, in three figures, is a bearing. "
                             "The bearing of the way back is the back bearing. "
                             "Add 180° to a bearing under 180°, and take 180° from a bearing over 180°."},
                    {"kind": "example",
                     "text": "A boat sails on a bearing of 065°. Its back bearing is 065° + 180° = 245°. "
                             "A plane flies on a bearing of 290°, so its back bearing is 290° − 180° = 110°."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to turn anticlockwise from north. "
                             "West is a quarter turn anticlockwise, but its bearing is 270°, three quarter turns clockwise."},
                    {"kind": "turn",
                     "text": "A ship sails from a port on a bearing of 130°. What is the bearing of the port from the ship?",
                     "answer": "310°",
                     "answerKey": k.one(k.num("310"), accepts=["310", "310°", "= 310°"], rejects=["50", "050°", "230"])},
                    {"kind": "sayBack",
                     "text": "A bearing turns clockwise from north and has three figures. The back bearing differs from it by 180°."},
                ],
            },
            {
                "heading": "9.7 Flat drawings of a solid",
                "teaches": ["net-of-a-solid", "plan-and-elevation"],
                "steps": [
                    {"kind": "question",
                     "text": "A cereal box is opened out flat along its folds. "
                             "What shapes make up the flat card, and could you fold it back into the box?"},
                    {"kind": "idea",
                     "text": "The flat card is six rectangles joined at the folds: front, back, two sides, top and bottom. "
                             "Fold along the lines and it closes into the box again."},
                    {"kind": "picture",
                     "text": "Draw six equal squares in a cross: a row of four, with one more above and one below the second square. "
                             "Cut it out and fold along every line. It closes into a cube."},
                    {"kind": "reason",
                     "text": "Why do some patterns of six squares fail? If two squares fold onto the same side of the cube, another side stays open. "
                             "The cross works because each square lands on a different side."},
                    {"kind": "name",
                     "text": "A flat pattern that folds into a solid is a net of a solid. "
                             "A solid can also be drawn as three flat views. "
                             "The view from directly above is the plan view. "
                             "The views from the front and the side are the front elevation and the side elevation."},
                    {"kind": "example",
                     "text": "A cuboid is 5 cm long, 3 cm wide and 2 cm tall. Its plan view is a 5 cm by 3 cm rectangle. "
                             "Its front elevation is 5 cm by 2 cm, and its side elevation is 3 cm by 2 cm."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to draw the plan view on a slant, the way the solid looks from a corner. "
                             "A plan view looks straight down, so a cuboid's is a plain rectangle."},
                    {"kind": "turn",
                     "text": "A cuboid is 6 cm long, 4 cm wide and 3 cm tall. What is the area of its plan view?",
                     "answer": "24 cm²",
                     "answerKey": k.one(k.num("24"), accepts=["24", "24 cm²", "24 cm2"], rejects=["18", "12", "72"])},
                    {"kind": "sayBack",
                     "text": "A net of a solid folds up into it. The plan view and the elevations show it from above, the front and the side."},
                ],
            },
            {
                "heading": "9.8 Corners, edges and faces",
                "teaches": ["vertices-edges-faces", "eulers-formula"],
                "steps": [
                    {"kind": "question",
                     "text": "A cube has 8 corners, 12 edges and 6 flat sides. Work out 8 − 12 + 6. "
                             "Then do the same for a pyramid on a square. What do you notice?"},
                    {"kind": "idea",
                     "text": "For the cube, 8 − 12 + 6 = 2. The pyramid has 5 corners, 8 edges and 5 flat sides, "
                             "and 5 − 8 + 5 = 2 as well."},
                    {"kind": "picture",
                     "text": "Hold a box, or draw one. Touch and count each corner, then each edge, then each flat side. "
                             "Write the three counts in a table, and add a row for the pyramid."},
                    {"kind": "reason",
                     "text": "Why does the answer stay at 2? Slice one corner off a cube. You lose 1 corner and gain 3, you gain 3 edges, and you gain 1 flat side. "
                             "So corners − edges + sides changes by 2 − 3 + 1 = 0."},
                    {"kind": "name",
                     "text": "The flat surfaces of a solid are its faces, the lines where two faces meet are its edges, and the corners are its vertices. "
                             "One corner is a vertex. "
                             "For a solid with no holes, Euler's formula says V − E + F = 2."},
                    {"kind": "example",
                     "text": "A pyramid on a triangle has 4 vertices, 6 edges and 4 faces, and 4 − 6 + 4 = 2. "
                             "A solid with 12 vertices and 30 edges has 30 − 12 + 2 = 20 faces."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to count only the edges you can see in a drawing. "
                             "A cube drawn on paper shows 9 of its edges, and the other 3 hide at the back."},
                    {"kind": "turn",
                     "text": "A solid with no holes has 7 faces and 10 vertices. Use Euler's formula to find its number of edges.",
                     "answer": "15",
                     "answerKey": k.one(k.num("15"), accepts=["15", "15 edges", "E = 15"], rejects=["17", "19", "5"])},
                    {"kind": "sayBack",
                     "text": "Count the vertices, the edges and the faces. For a solid with no holes, V − E + F = 2."},
                ],
            },
        ],
        "callouts": [
            {"kind": "predict", "title": "Predict first",
             "body": "Set AB to 8 cm and the compass opening to 3 cm. "
                     "Predict whether the two arcs will cross, then look."},
            {"kind": "check", "title": "Explain it",
             "body": "A goat is tied to a post by a rope 5 m long. "
                     "Explain to a friend why the edge of the grass it can reach is a circle."},
            {"kind": "careful", "title": "Every point, not one",
             "body": "A rule such as 3 cm from a pin is obeyed by a whole circle of points, not by one. "
                     "Find every point that obeys the rule."},
        ],
        "debate": {
            "id": "debate-ch09-bearings",
            "oupUnitNumber": 3,
            "title": "Which way is back?",
            "contextPrompt": "A boat sails from a harbour on a bearing of 300°. "
                             "Asha and Rohan work out the bearing of the harbour from the boat.",
            "speakerAName": "Asha",
            "speakerAClaim": "The way back is the opposite way, so add 180°. The back bearing is 480°.",
            "speakerBName": "Rohan",
            "speakerBClaim": "A bearing stays under 360°, so take 180° away instead. The back bearing is 120°.",
            "choices": [
                {"id": "ch09-a", "speakerLabel": "Asha is right (480°)",
                 "reasoningStatement": "To face the other way, always add 180°.",
                 "isCorrect": False,
                 "socraticRebuttal": "Turning 480° clockwise from north is more than a full turn. "
                                     "Take away the full turn of 360°: which way do you face then?"},
                {"id": "ch09-b", "speakerLabel": "Rohan is right (120°)",
                 "reasoningStatement": "For a bearing over 180°, take 180° away to get the way back.",
                 "isCorrect": True,
                 "socraticRebuttal": "Yes. 300° − 180° = 120°, and adding 180° to 120° brings you round to 300° again."},
                {"id": "ch09-c", "speakerLabel": "Neither. It is 060°.",
                 "reasoningStatement": "The way back is 360° − 300°.",
                 "isCorrect": False,
                 "socraticRebuttal": "360° − 300° is the turn from north the other way round. "
                                     "Does 060° point exactly opposite to 300°, or somewhere else?"},
            ],
            "invariantTakeaway": "The back bearing is half a turn from the bearing. Add 180° or take 180° away, whichever lands from 000° to 359°.",
        },
        "keyTerms": ["Locus", "Perpendicular bisector", "Angle bisector", "Congruent", "Quadrilateral", "Bearing",
                     "Net of a solid", "Plan and elevation", "Vertices, edges and faces", "Euler's formula"],
        "widgets": ["w_euclid_compass_locus", "w_bearings_back_bearing_radar", "w_polyhedron_net_folder"],
        "widgetText": {
            "w_euclid_compass_locus": {
                "title": "Two arcs and a straight line",
                "challengePrompt": "Move the compass slider to its smallest setting. "
                                   "Predict whether the two arcs still cross, then look.",
                "cutaway": "Each crossing is one compass opening from A and the same opening from B. "
                           "So the four lines from A and B to the crossings are equal, and together they make a rhombus.",
                "idealised": "The rule: every point on the perpendicular bisector of AB is as far from A as from B",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Move the compass slider and watch the two arcs from A and B."},
                    {"title": "2. Notice", "caption": "The red line through the crossings meets AB at its midpoint, at a right angle."},
                    {"title": "3. Match the rule", "caption": "Each crossing is as far from A as from B, so it lies on the perpendicular bisector."},
                    {"title": "4. Push it further", "caption": "Open the compasses as wide as they go. Does the red line move?"},
                    {"title": "5. Draw it", "caption": "Draw a line in your journal and bisect it with compasses, keeping the arcs."},
                ],
            },
            "w_bearings_back_bearing_radar": {
                "title": "Bearings there and back",
                "challengePrompt": "Set the bearing from A to 065°. Predict the back bearing from B before you read it.",
                "cutaway": "The north arrows at A and B are parallel, so the way back points the exact opposite way. "
                           "The angles at the path are co-interior angles, 65° + 115° = 180°, and the back bearing is 245°.",
                "idealised": "The rule: back bearing = bearing + 180°, or bearing − 180° when the bearing is over 180°",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Move the bearing slider slowly from 25° up to 160°."},
                    {"title": "2. Notice", "caption": "The back bearing is always 180° more than the bearing."},
                    {"title": "3. Match the rule", "caption": "065° + 180° = 245°, read along one path in the two directions."},
                    {"title": "4. Push it further", "caption": "On paper, start from 245°. It is over 180°, so take 180° away. Where do you land?"},
                    {"title": "5. Draw it", "caption": "Write both bearings in your journal, each with three figures."},
                ],
            },
            "w_polyhedron_net_folder": {
                "title": "Folding a cube from its net",
                "challengePrompt": "Move the fold slider from flat to closed. "
                                   "Predict how many vertices the closed cube has before you count them.",
                "cutaway": "Folding joins edges and corners together, but never adds or removes a face. "
                           "The cube has 8 vertices, 12 edges and 6 faces, and 8 − 12 + 6 = 2.",
                "idealised": "The rule: Euler's formula, V − E + F = 2, for a solid with flat faces and no holes",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Set the fold slider to 0, so the net of the cube lies flat."},
                    {"title": "2. Notice", "caption": "Slide it to 1. Six squares close up into a cube with 8 vertices."},
                    {"title": "3. Match the rule", "caption": "Count 12 edges and 6 faces: 8 − 12 + 6 = 2."},
                    {"title": "4. Push it further", "caption": "On paper, count a pyramid on a square: 5 − 8 + 5. Is it 2 again?"},
                    {"title": "5. Draw it", "caption": "Draw a different cube net in your journal, then check that it folds."},
                ],
            },
        },
        "atlasLessons": [
            {
                "title": "Chapter 9 · Two arcs and a fold",
                "question": "Why does the line through two equal arc crossings cut AB in half at a right angle?",
                "explanation": "Each crossing is the same distance from A as from B. "
                               "Fold the page along the line through them and A lands on B, so the fold meets AB at its midpoint.",
                "limits": "The rule: the perpendicular bisector of AB is the locus of points equally far from A and B",
            },
            {
                "title": "Chapter 9 · Turning round on a bearing",
                "question": "Why does a back bearing differ from the bearing by 180°?",
                "explanation": "The north arrows at the start and at the finish are parallel. "
                               "The path back points the opposite way, and opposite directions are half a turn apart.",
                "limits": "The rule: back bearing = bearing ± 180°, written with three figures",
            },
            {
                "title": "Chapter 9 · Vertices minus edges plus faces",
                "question": "Why does V − E + F come to 2 for a cube and for a pyramid alike?",
                "explanation": "Slicing a corner off a solid adds 2 vertices, 3 edges and 1 face. "
                               "So V − E + F changes by 2 − 3 + 1 = 0, and it stays at 2.",
                "limits": "The rule: V − E + F = 2 for a solid with flat faces and no holes",
            },
        ],
        "visualMathTips": {},
        "schoolTopics": {
            "3.1": "A quadrilateral has four sides, and its angles add to 360°. "
                   "A rhombus and a kite have diagonals that cross at right angles, and a rectangle has diagonals of equal length.",
            "3.2": "A net of a solid folds up into it, and the plan view and elevations show it from above, the front and the side. "
                   "For a solid with no holes, Euler's formula says V − E + F = 2.",
            "3.3": "A bearing is measured clockwise from north and written with three figures, from 000° to 359°. "
                   "The back bearing differs by 180°, so 065° gives 245°.",
            "3.4": "Three sides (SSS), two sides and the angle between them (SAS), or two angles and the side between them (ASA) fix a triangle. "
                   "Triangles that match in one of these ways are congruent.",
            "3.5": "The perpendicular bisector of AB is the locus of points equally far from A and B. "
                   "An angle bisector is the locus of points equally far from the two arms of the angle.",
        },
        "schoolQuestions": {
            "q-oup-ch03-sb": {
                "workedExample": "Step 1: Draw a north arrow at M and another at B. North arrows all point the same way, so they are parallel.\n"
                                 "Step 2: The path from B back to M points the exact opposite way to the path from M to B.\n"
                                 "Step 3: 068° is under 180°, so the back bearing is 068° + 180° = 248°.\n"
                                 "Step 4: Check: 248° − 180° = 068°, the bearing out again.",
                "fadedPrompt": "068° is under 180°, so the back bearing of M from B is 068° + 180° = ___°.",
            },
            "q-oup-ch03-wb-focus": {
                "workedExample": "Step 1: Write down Euler's formula: V − E + F = 2.\n"
                                 "Step 2: Put in V = 6 and F = 8: 6 − E + 8 = 2, so 14 − E = 2.\n"
                                 "Step 3: Take E to the other side: E = 14 − 2 = 12.\n"
                                 "Step 4: Check: 6 − 12 + 8 = 2.",
                "fadedPrompt": "6 − E + 8 = 2, so 14 − E = 2 and E = ___.",
            },
            "q-oup-ch03-wb-practice": {
                "workedExample": "Step 1: The longest side is BC = 10 cm, and the corner opposite it is A.\n"
                                 "Step 2: 6² + 8² = 36 + 64 = 100, which is 10². When this happens, the angle opposite the longest side is 90°. "
                                 "Chapter 12 shows why.\n"
                                 "Step 3: So angle BAC = 90°.\n"
                                 "Step 4: The perpendicular bisector of AB is the locus of points equidistant from A and B, the same distance from each.",
                "fadedPrompt": "6² + 8² = 10², so the right angle is opposite BC, at angle ___. "
                               "The perpendicular bisector of AB is the locus of points ___ from A and B.",
            },
            "q-oup-ch03-wb-challenge": {
                "workedExample": "Step 1: The ship turns from 040° to 130°, a turn of 90°. So the two legs of the journey meet at a right angle.\n"
                                 "Step 2: The direct distance is the longest side of a triangle with a right angle between sides of 12 km and 16 km.\n"
                                 "Step 3: For such a triangle, the two shorter sides squared add to the longest side squared: 12² + 16² = 144 + 256 = 400.\n"
                                 "Step 4: √400 = 20, so the ship is 20 km from the port. Chapter 12 shows why the rule works.",
                "fadedPrompt": "The legs meet at a right angle, so the distance squared is 12² + 16² = ___, and the distance is ___ km.",
            },
        },
    }


def cards(k):
    """The concept cards this chapter teaches."""
    return {
        "locus": {
            "name": "Locus",
            "aliases": ["locus", "loci"],
            "oneSentence": "Every point that obeys a rule, such as every point 3 cm from a pin.",
            "picture": "A goat on a tight rope, sweeping a circle round its post.",
            "steps": [
                "Read the rule, such as exactly 2 cm from a point O.",
                "Mark a few points that obey it, and a few that do not.",
                "Join up all the points that obey it. That line or curve is the locus.",
            ],
            "workedExample": "The locus of points 5 cm from a point O is a circle round O. "
                             "Every point on it is 5 cm from O, and no other point is.",
            "check": {
                "prompt": "The locus of points 6 cm from a point O is a circle. How far is it across the circle, through O?",
                "answer": "12 cm",
                "answerKey": k.one(k.num("12"), accepts=["12", "12 cm", "= 12"], rejects=["6", "3", "36"]),
            },
            "mixUp": {
                "name": "one point",
                "how": "A point 3 cm from O is on the locus, but it is not the locus. The locus is the whole circle of such points.",
            },
            "standsOn": [],
        },
        "perpendicular-bisector": {
            "name": "Perpendicular bisector",
            "aliases": ["perpendicular bisector", "perpendicular bisectors"],
            "oneSentence": "The line that cuts a line segment in half at a right angle. Every point on it is equally far from both ends.",
            "picture": "A sheet folded so that A lands on B. The crease is the perpendicular bisector of AB.",
            "steps": [
                "Open the compasses to more than half of AB.",
                "Draw an arc from A and an arc from B with that one opening, crossing above and below AB.",
                "Rule a line through the two crossings.",
            ],
            "workedExample": "A and B are 6 cm apart. With the compasses open to 4 cm, the arcs cross twice. "
                             "The line through the crossings meets AB at its midpoint, 3 cm from each end.",
            "check": {
                "prompt": "P is on the perpendicular bisector of AB, and PA = 7 cm. What is PB?",
                "answer": "7 cm",
                "answerKey": k.one(k.num("7"), accepts=["7", "7 cm", "PB = 7"], rejects=["14", "3.5", "0"]),
            },
            "mixUp": {
                "name": "any line through the midpoint",
                "how": "A slanted line through the midpoint cuts AB in half too. "
                       "Only the one at a right angle keeps every point equally far from A and B.",
            },
            "standsOn": ["locus", "midpoint"],
        },
        "angle-bisector": {
            "name": "Angle bisector",
            "aliases": ["angle bisector", "angle bisectors"],
            "oneSentence": "The line that cuts an angle into two equal angles. Every point on it is equally far from the two arms.",
            "picture": "A paper corner folded so that one arm lies on the other. The crease is the angle bisector.",
            "steps": [
                "Put the compass point on the corner, and draw an arc that crosses both arms.",
                "From each crossing, draw an arc of the same size, so the two arcs meet inside the angle.",
                "Rule a line from the corner through that meeting point.",
            ],
            "workedExample": "The angle bisector of an 80° angle makes two angles of 40°. "
                             "A point on it that is 3 cm from one arm is 3 cm from the other.",
            "check": {
                "prompt": "An angle bisector makes two angles of 37°. How big was the whole angle?",
                "answer": "74°",
                "answerKey": k.one(k.num("74"), accepts=["74", "74°", "= 74°"], rejects=["18.5", "37", "143"]),
            },
            "mixUp": {
                "with": "perpendicular-bisector",
                "how": "A perpendicular bisector cuts a line segment in half. An angle bisector cuts an angle in half.",
            },
            "standsOn": ["locus", "angle"],
        },
        "congruent": {
            "name": "Congruent",
            "aliases": ["congruent", "congruent triangles", "congruent shapes", "congruence"],
            "oneSentence": "Exactly the same shape and size, so that one fits on the other, perhaps after flipping it over.",
            "picture": "Two prints from one rubber stamp: every side and every angle matches.",
            "steps": [
                "Match up the sides and the angles of the two triangles.",
                "Look for three equal sides (SSS), two sides and the angle between them (SAS), or two angles and the side between them (ASA).",
                "If one of those matches, the triangles are congruent, and every other side and angle matches too.",
            ],
            "workedExample": "Two triangles both have sides of 4 cm, 5 cm and 6 cm. They are congruent by SSS. "
                             "So the angle between the 5 cm and 6 cm sides is the same in both.",
            "check": {
                "prompt": "Triangle ABC is congruent to triangle DEF, with A matching D, B matching E and C matching F. "
                          "Angle D = 35° and angle E = 100°. What is angle C?",
                "answer": "45°",
                "answerKey": k.one(k.num("45"), accepts=["45", "45°", "C = 45°"], rejects=["35", "100", "135"]),
            },
            "mixUp": {
                "name": "same shape, different size",
                "how": "Two triangles with every angle 60°, one with 2 cm sides and one with 5 cm sides, are not congruent. "
                       "Congruent shapes match in size too.",
            },
            "standsOn": ["angle"],
        },
        "quadrilateral": {
            "name": "Quadrilateral",
            "aliases": ["quadrilateral", "quadrilaterals", "rhombus", "rhombuses", "parallelogram", "parallelograms"],
            "oneSentence": "A polygon with four straight sides. Its four angles add to 360°.",
            "picture": "A family tree: squares sit inside both the rectangles and the rhombuses, and all of them sit inside the parallelograms.",
            "steps": [
                "Count the sides. Four straight sides make a quadrilateral.",
                "Check which sides are equal and which are parallel.",
                "Join opposite corners with the two diagonals. A rhombus or a kite has them crossing at a right angle, and a rectangle has them equal.",
            ],
            "workedExample": "A parallelogram has an angle of 70°. The angle next to it is 180° − 70° = 110°, because the two are co-interior angles. "
                             "Its angles are 70°, 110°, 70° and 110°, which add to 360°.",
            "check": {
                "prompt": "Three angles of a quadrilateral are 90°, 90° and 125°. What is the fourth angle?",
                "answer": "55°",
                "answerKey": k.one(k.num("55"), accepts=["55", "55°", "= 55°"], rejects=["305", "235", "35"]),
            },
            "mixUp": {
                "name": "rhombus and square",
                "how": "Every square is a rhombus, but a rhombus with angles of 60° and 120° is not a square. A square needs right angles too.",
            },
            "standsOn": ["polygon"],
        },
        "bearing": {
            "name": "Bearing",
            "aliases": ["bearing", "bearings", "three-figure bearing", "three-figure bearings", "back bearing", "back bearings"],
            "oneSentence": "A direction given as the angle turned clockwise from north, written with three figures.",
            "picture": "A compass needle pointing north, and an arm swinging clockwise from it to the way you want to go.",
            "steps": [
                "Draw a north arrow where you start.",
                "Measure the angle clockwise from north to the direction.",
                "Write it with three figures, so 45° is written 045°.",
            ],
            "workedExample": "East is a quarter turn clockwise from north, so its bearing is 090°. South is 180°, and west is 270°.",
            "check": {
                "prompt": "A boat sails on a bearing of 240°. What is its back bearing?",
                "answer": "060°",
                "answerKey": k.one(k.num("60"), accepts=["060°", "060", "60"], rejects=["420", "120", "300"]),
            },
            "mixUp": {
                "name": "an angle from east",
                "how": "On a graph, angles are often measured anticlockwise from the east. A bearing always starts at north and turns clockwise.",
            },
            "standsOn": ["angle", "co-interior-angles"],
        },
        "net-of-a-solid": {
            "name": "Net of a solid",
            "aliases": ["net of a solid", "nets of solids", "net of a cube", "nets of a cube", "net of the cube",
                        "cube net", "cube nets"],
            "oneSentence": "A flat pattern of shapes that folds up into a solid.",
            "picture": "A cereal box opened out flat along its folds.",
            "steps": [
                "Count the flat sides of the solid, and note their shapes.",
                "Draw them joined edge to edge, so that each fold is a shared line.",
                "Fold it in your head and check that no two shapes land on the same side.",
            ],
            "workedExample": "A cube net has 6 squares. A row of 4 squares, with one more above and one below the second, folds into a cube.",
            "check": {
                "prompt": "A net of a solid has 2 triangles and 3 rectangles. How many flat sides does the solid have?",
                "answer": "5",
                "answerKey": k.one(k.num("5"), accepts=["5", "5 sides", "= 5"], rejects=["3", "2", "6"]),
            },
            "mixUp": {
                "name": "any six squares",
                "how": "Six squares in a row do not fold into a cube. The last two squares land on the first two, and two sides stay open.",
            },
            "standsOn": ["polygon"],
        },
        "plan-and-elevation": {
            "name": "Plan and elevation",
            "aliases": ["plan and elevation", "plans and elevations", "plan view", "plan views", "front elevation",
                        "front elevations", "side elevation", "side elevations", "elevation", "elevations"],
            "oneSentence": "Flat views of a solid: the plan view from directly above, and the elevations from the front and the side.",
            "picture": "A drone photo of a house from straight above, next to photos taken level with its front and its side.",
            "steps": [
                "For the plan view, look straight down and draw the outline you see.",
                "For the front elevation, look straight at the front from level with it.",
                "For the side elevation, do the same from the side.",
            ],
            "workedExample": "A tin can standing upright has a circle for its plan view. Its front and side elevations are both rectangles.",
            "check": {
                "prompt": "A cuboid is 7 cm long, 2 cm wide and 4 cm tall, with its long side at the front. "
                          "What is the area of its front elevation?",
                "answer": "28 cm²",
                "answerKey": k.one(k.num("28"), accepts=["28", "28 cm²", "28 cm2"], rejects=["14", "8", "56"]),
            },
            "mixUp": {
                "with": "net-of-a-solid",
                "how": "A net shows every side laid out flat, ready to fold. A plan view or an elevation shows only what you see from one direction.",
            },
            "standsOn": ["area"],
        },
        "vertices-edges-faces": {
            "name": "Vertices, edges and faces",
            "aliases": ["vertices", "vertices, edges and faces"],
            "oneSentence": "The corners, the fold lines and the flat surfaces of a solid. One corner is a vertex.",
            "picture": "A dice, with 8 corners, 12 edges and 6 square faces.",
            "steps": [
                "Count the flat surfaces. These are the faces.",
                "Count the lines where two faces meet. These are the edges.",
                "Count the corners. These are the vertices.",
            ],
            "workedExample": "A pyramid on a square has 5 faces: 1 square and 4 triangles. It has 8 edges and 5 vertices.",
            "check": {
                "prompt": "How many vertices does a pyramid on a pentagon have?",
                "answer": "6",
                "answerKey": k.one(k.num("6"), accepts=["6", "6 vertices", "= 6"], rejects=["5", "10", "7"]),
            },
            "mixUp": {
                "name": "edges you can see",
                "how": "A picture of a cube shows 9 edges, but a real cube has 12. Count the hidden ones at the back too.",
            },
            "standsOn": [],
        },
        "eulers-formula": {
            "name": "Euler's formula",
            "aliases": ["Euler's formula", "Euler’s formula"],
            "oneSentence": "For a solid with flat faces and no holes, the vertices take away the edges, add the faces, make 2.",
            "picture": "A cube, with 8 − 12 + 6 = 2, beside a pyramid on a square, with 5 − 8 + 5 = 2.",
            "steps": [
                "Count the vertices V, the edges E and the faces F.",
                "Work out V − E + F.",
                "If one count is missing, put the other two into V − E + F = 2 and solve.",
            ],
            "workedExample": "A solid has 8 faces and 12 edges. Then V − 12 + 8 = 2, so V = 6.",
            "check": {
                "prompt": "A solid with no holes has 6 vertices and 9 edges. How many faces does it have?",
                "answer": "5",
                "answerKey": k.one(k.num("5"), accepts=["5", "5 faces", "F = 5"], rejects=["3", "13", "17"]),
            },
            "mixUp": {
                "name": "a solid with a hole",
                "how": "A picture frame with flat sides and a hole through the middle gives V − E + F = 0. The formula is for solids with no holes.",
            },
            "standsOn": ["vertices-edges-faces"],
        },
    }


def sums():
    """Every sum chapter 9, its cards and its school unit text state, recomputed. test_book_maths.py checks computed == stated."""
    return [
        # Skill card
        ("back bearing of 070°", three_figures(back_bearing(70)), "250°"),
        ("5 vertices and 8 edges", 2 - 5 + 8, 5),
        ("90°, 80° and 105°", (90 + 80 + 105, fourth_angle(90, 80, 105)), (275, 85)),
        # Figure, bridge and callouts
        ("AB 6 cm, opening 4 cm", (arcs_cross(6, 4), Fraction(6, 2)), (True, 3)),
        ("AB 8 cm, opening 3 cm", arcs_cross(8, 3), False),
        # 9.1 Every point at one distance
        ("4 m rope", (2 * 4, 4 * 4, Fraction(4, 2)), (8, 16, 2)),
        # 9.2 Equally far from two points
        ("A and B 6 km apart", Fraction(6, 2), 3),
        ("A and B 8 cm apart, opening 5 cm", (arcs_cross(8, 5), Fraction(8, 2)), (True, 4)),
        ("A and B 10 cm apart", (Fraction(10, 2), 2 * 13), (5, 26)),
        # 9.3 Cutting an angle in half
        ("70° in half", Fraction(70, 2), 35),
        ("130° in half", Fraction(130, 2), 65),
        ("148° in half", (Fraction(148, 2), 2 * 148, 180 - 148), (74, 296, 32)),
        # 9.4 Triangles that must match
        ("angle R", (180 - 50 - 70, 50 + 70), (60, 120)),
        # 9.5 Four sides and two diagonals
        ("two triangles", 2 * 180, 360),
        ("the kite", fourth_angle(110, 110, 50), 90),
        ("85°, 95° and 110°", (fourth_angle(85, 95, 110), 85 + 95 + 110, 180 - 110), (70, 290, 70)),
        # 9.6 Directions as bearings
        ("north-east", Fraction(90, 2), 45),
        ("065° back", (three_figures(back_bearing(65)), 65 + 180), ("245°", 245)),
        ("290° back", (back_bearing(290), 290 - 180), (110, 110)),
        ("west", (360 - 90, 3 * 90), (270, 270)),
        ("130° back", (back_bearing(130), 180 - 130, 360 - 130), (310, 50, 230)),
        # 9.7 Flat drawings of a solid
        ("cuboid 5 by 3 by 2", (5 * 3, 5 * 2, 3 * 2), (15, 10, 6)),
        ("cuboid 6 by 4 by 3 plan", (6 * 4, 6 * 3, 4 * 3, 6 * 4 * 3), (24, 18, 12, 72)),
        # 9.8 Corners, edges and faces
        ("cube", euler_count(8, 12, 6), 2),
        ("pyramid on a square", euler_count(5, 8, 5), 2),
        ("slicing a corner", (-1 + 3, 2 - 3 + 1, euler_count(8 + 2, 12 + 3, 6 + 1)), (2, 0, 2)),
        ("pyramid on a triangle", euler_count(4, 6, 4), 2),
        ("12 vertices and 30 edges", (30 - 12 + 2, euler_count(12, 30, 20)), (20, 2)),
        ("a drawn cube", 12 - 9, 3),
        ("7 faces and 10 vertices", (10 + 7 - 2, euler_count(10, 15, 7), 10 + 7, 10 + 7 + 2), (15, 2, 17, 19)),
        # Debate
        ("300° back", (back_bearing(300), 300 + 180, 300 + 180 - 360, 360 - 300, back_bearing(120)), (120, 480, 120, 60, 300)),
        # Widgets and lessons
        ("065° co-interior", (180 - 65, 65 + 115, 65 + 180), (115, 180, 245)),
        ("245° back", (245 - 180, three_figures(back_bearing(245))), (65, "065°")),
        ("cube folded", euler_count(8, 12, 6), 2),
        # Cards
        ("6 cm locus", 2 * 6, 12),
        ("A and B 6 cm apart, opening 4 cm", (arcs_cross(6, 4), Fraction(6, 2)), (True, 3)),
        ("80° in half", Fraction(80, 2), 40),
        ("two angles of 37°", (2 * 37, Fraction(37, 2), 180 - 37), (74, Fraction("18.5"), 143)),
        ("angle C = angle F", (180 - 35 - 100, 35 + 100), (45, 135)),
        ("parallelogram", (180 - 70, 70 + 110 + 70 + 110), (110, 360)),
        ("90°, 90° and 125°", (fourth_angle(90, 90, 125), 90 + 90 + 125, 360 - 125), (55, 305, 235)),
        ("east, south, west", (1 * 90, 2 * 90, 3 * 90), (90, 180, 270)),
        ("240° back", (three_figures(back_bearing(240)), 240 + 180, 240 - 120, 360 - 60), ("060°", 420, 120, 300)),
        ("cube net", 4 + 1 + 1, 6),
        ("2 triangles and 3 rectangles", 2 + 3, 5),
        ("cuboid 7 by 2 by 4 front", (7 * 4, 7 * 2, 2 * 4), (28, 14, 8)),
        ("pyramid on a pentagon", 5 + 1, 6),
        ("8 faces and 12 edges", (2 + 12 - 8, euler_count(6, 12, 8)), (6, 2)),
        ("6 vertices and 9 edges", (2 - 6 + 9, euler_count(6, 9, 5), 9 - 6), (5, 2, 3)),
        ("a frame with a hole", euler_count(16, 32, 16), 0),
        # School unit 3
        ("068° back", (three_figures(back_bearing(68)), 248 - 180), ("248°", 68)),
        ("V = 6, F = 8", (6 + 8, 14 - 2, euler_count(6, 12, 8)), (14, 12, 2)),
        ("6, 8 and 10", (6 ** 2, 8 ** 2, 6 ** 2 + 8 ** 2, 10 ** 2), (36, 64, 100, 100)),
        ("040° then 130°", (130 - 40, 12 ** 2, 16 ** 2, 12 ** 2 + 16 ** 2, isqrt(400), 20 ** 2), (90, 144, 256, 400, 20, 400)),
    ]


def answers():
    """Chapter 9's turn answers and its cards' check answers, computed."""
    return {
        "ch09-s1-turn": 2 * 4,
        "ch09-s2-turn": 13,
        "ch09-s3-turn": Fraction(148, 2),
        "ch09-s4-turn": 180 - 50 - 70,
        "ch09-s5-turn": fourth_angle(85, 95, 110),
        "ch09-s6-turn": back_bearing(130),
        "ch09-s7-turn": 6 * 4,
        "ch09-s8-turn": 10 + 7 - 2,
        "locus-check": 2 * 6,
        "perpendicular-bisector-check": 7,
        "angle-bisector-check": 2 * 37,
        "congruent-check": 180 - 35 - 100,
        "quadrilateral-check": fourth_angle(90, 90, 125),
        "bearing-check": back_bearing(240),
        "net-of-a-solid-check": 2 + 3,
        "plan-and-elevation-check": 7 * 4,
        "vertices-edges-faces-check": 5 + 1,
        "eulers-formula-check": 2 - 6 + 9,
    }
