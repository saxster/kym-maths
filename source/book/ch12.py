"""
Chapter 12, written by hand to docs/CONTENT_BRIEF.md. No school unit teaches it, so it goes beyond the school book.

Each section teaches one idea in nine steps, in this order: question, idea, picture, reason, name,
example, mistake, turn, sayBack. A section's `teaches` lists the concept cards whose names first
appear in its `name` step. `build(k)` returns the chapter and `cards(k)` its concept cards; both take the
exporter's answer-key helpers. Every section starts from something she can hold or measure: a set square,
a ladder, a ramp, a Ferris wheel, a piece of string, a field with no square corner.

"Tangent" belongs to trigonometry here (risk R2). The tangent line of chapter 17 is its own card.
"""

import math

from book.arithmetic import Fraction


def hypotenuse(a, b):
    """The longest side of a right-angled triangle with shorter sides a and b: a whole number when it is one."""
    square = a * a + b * b
    return math.isqrt(square) if math.isqrt(square) ** 2 == square else math.sqrt(square)


def cosine_rule(a, b, cos_c):
    """The third side squared, from two sides and the cosine of the angle between them."""
    square = a * a + b * b - 2 * a * b * Fraction(cos_c)
    return int(square) if square.denominator == 1 else square


def sin(degrees):
    return round(math.sin(math.radians(degrees)), 9)


def cos(degrees):
    return round(math.cos(math.radians(degrees)), 9)


HALF = Fraction(1, 2)


def build(k):
    return {
        "number": 12,
        "title": "Pythagoras and trigonometry",
        "subtitle": "Beyond the school book · The longest side of a right-angled triangle, "
                    "and the ratios that tie its sides to its angles",
        "hookSummary": "A ladder 5 m long leans on a wall, with its foot 3 m out. "
                       "How high up the wall does it reach, without climbing it?",
        "beyondSchoolBook": True,
        "skillCard": {
            "skill": "Finding a missing side of a right-angled triangle, and linking its sides to its angles with sine, cosine and tangent",
            "sheCan": {
                "prompt": "With no calculator: a right-angled triangle has shorter sides of 5 cm and 12 cm. What is the length of its longest side? "
                          "A ramp 10 m long makes 30° with the ground, and sin 30° = 0.5. How high does it rise?",
                "answer": "5² + 12² = 25 + 144 = 169, and 13² = 169, so the longest side is 13 cm. The ramp rises 10 × 0.5 = 5 m.",
            },
            "whyItMatters": "Builders, pilots and phone maps all find distances they cannot measure with a tape. "
                            "They use a right-angled triangle and one of these rules.",
            "standsOn": [
                "Chapter 1: square numbers and square roots",
                "Chapter 8: angles and the right angle",
                "Chapter 10: the radius of a circle",
                "Chapter 11: similar shapes, which keep their ratios",
            ],
            "unlocks": [
                "Chapter 17: slopes of curves, measured like the steepness of a ramp",
                "Chapter 19: vectors, whose lengths come from Pythagoras' theorem",
                "Chapter 20: matrices that turn a shape, built from sine and cosine",
            ],
        },
        "intuitionToFormula": {
            "concreteAction": "Set the angle θ to 30° and the radius to 2. Then move the radius slider up to 4, one step at a time.",
            "ahaInvariant": "The triangle grows, but its height ÷ radius stays 0.5 at 30°. "
                            "The ratio belongs to the angle, not to the size of the triangle.",
            "formulaDisplay": "sin θ = height ÷ radius,   cos θ = across ÷ radius,   sin²θ + cos²θ = 1",
            "termMappings": [
                {"symbol": "sin θ", "visualPart": "The red side, straight up from the ground to P", "colorRole": "red",
                 "meaning": "The height for every 1 unit of slope"},
                {"symbol": "cos θ", "visualPart": "The blue side along the ground", "colorRole": "blue",
                 "meaning": "The distance across for every 1 unit of slope"},
                {"symbol": "radius", "visualPart": "The green slope from O to P", "colorRole": "green",
                 "meaning": "The longest side, which the other two are divided by"},
            ],
            "atlasFigureRef": "maths/unit-circle/index.html#1",
        },
        "sections": [
            {
                "heading": "12.1 The longest side",
                "teaches": ["right-angled-triangle", "hypotenuse"],
                "steps": [
                    {"kind": "question",
                     "text": "Pick up a set square. One of its corners is square, like the corner of a page. "
                             "Which of its three edges is the longest?"},
                    {"kind": "idea",
                     "text": "The edge across from the square corner. "
                             "The square corner is the biggest angle in the triangle, and the biggest angle faces the longest side."},
                    {"kind": "picture",
                     "text": "Draw a triangle with a square corner, with sides of 3 cm and 4 cm along it. "
                             "Join their ends and measure the third side. It is 5 cm."},
                    {"kind": "reason",
                     "text": "Why must it be the longest? The other two angles add up to 90°, so each is smaller than the square corner. "
                             "A smaller angle faces a shorter side."},
                    {"kind": "name",
                     "text": "A triangle with one 90° corner is a right-angled triangle. "
                             "The side across from the right angle is the hypotenuse, and it is always the longest side."},
                    {"kind": "example",
                     "text": "A triangle has sides of 6 cm, 8 cm and 10 cm, with the right angle between the 6 cm and 8 cm sides. "
                             "The 10 cm side faces it, so 10 cm is the hypotenuse."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to call the side at the bottom of the drawing the hypotenuse. "
                             "Find the right angle first. The hypotenuse is the side that does not touch it."},
                    {"kind": "turn",
                     "text": "A right-angled triangle has angles of 90° and 35°. What is its third angle, in degrees?",
                     "answer": "55°",
                     "answerKey": k.one(k.num("55"), accepts=["55", "55°", "55 degrees"], rejects=["125", "145", "35"])},
                    {"kind": "sayBack",
                     "text": "In a right-angled triangle, the side across from the right angle is the hypotenuse, the longest side."},
                ],
            },
            {
                "heading": "12.2 Squares on the sides",
                "teaches": ["pythagoras-theorem"],
                "steps": [
                    {"kind": "question",
                     "text": "A ladder 5 m long leans on a wall, with its foot 3 m out from the wall. "
                             "How high up the wall does it reach?"},
                    {"kind": "idea",
                     "text": "4 m. Draw a square on each side of the triangle. "
                             "The two small squares together cover exactly as much as the big one."},
                    {"kind": "picture",
                     "text": "On squared paper, draw the 3, 4, 5 triangle and a square on each side. "
                             "Count the small squares: 9 and 16 on the short sides, 25 on the longest."},
                    {"kind": "reason",
                     "text": "Why does it always work? Four copies of the triangle fit round a tilted square inside a big square. "
                             "Move them and the space left over becomes the two smaller squares."},
                    {"kind": "name",
                     "text": "This is Pythagoras' theorem. In a right-angled triangle with shorter sides a and b and hypotenuse c, "
                             "a² + b² = c²."},
                    {"kind": "example",
                     "text": "The shorter sides are 5 cm and 12 cm. Then c² = 25 + 144 = 169, and the square root of 169 is 13. "
                             "So the hypotenuse is 13 cm."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to add the sides themselves. "
                             "3 + 4 = 7, but the hypotenuse of the 3, 4, 5 triangle is 5. Square the sides first."},
                    {"kind": "turn",
                     "text": "A right-angled triangle has shorter sides of 6 cm and 8 cm. How long is its hypotenuse?",
                     "answer": "10 cm",
                     "answerKey": k.one(k.num("10"), accepts=["10", "10 cm", "10cm"], rejects=["14", "100", "48"])},
                    {"kind": "sayBack",
                     "text": "The two shorter sides squared and added make the hypotenuse squared: a² + b² = c²."},
                ],
            },
            {
                "heading": "12.3 How steep is a ramp",
                "teaches": ["theta", "tangent"],
                "steps": [
                    {"kind": "question",
                     "text": "One ramp rises 1 m for every 4 m along the ground. Another rises 2 m for every 8 m. Which is steeper?"},
                    {"kind": "idea",
                     "text": "Neither. Both rise a quarter of a metre for every metre along, so they make the same angle with the ground."},
                    {"kind": "picture",
                     "text": "Draw a ramp 4 cm along and 1 cm up, and another 8 cm along and 2 cm up. "
                             "Measure the angle at the bottom of each with a protractor."},
                    {"kind": "reason",
                     "text": "Why the same angle? The big ramp is an enlargement of the small one with scale factor 2. "
                             "Its rise and its run double together, so rise ÷ run stays the same."},
                    {"kind": "name",
                     "text": "The angle we are working with is often called θ, said theta. "
                             "The rise ÷ the run is the tangent of θ, written tan θ. Each angle has its own tangent."},
                    {"kind": "example",
                     "text": "A ramp rises 2 m over 5 m along the ground. tan θ = 2 ÷ 5 = 0.4. "
                             "Any ramp that rises 0.4 m per metre along makes the same angle θ."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to divide the run by the rise. "
                             "The rise goes on top, so a gentle ramp has a small tangent."},
                    {"kind": "turn",
                     "text": "A ramp rises 3 m over 4 m along the ground. What is tan θ?",
                     "answer": "0.75",
                     "answerKey": k.one(k.num("0.75"), accepts=["0.75", "3/4", "tan θ = 0.75"], rejects=["1.33", "7", "12"])},
                    {"kind": "sayBack",
                     "text": "tan θ is the rise ÷ the run. It depends on the angle θ, not on how big the ramp is."},
                ],
            },
            {
                "heading": "12.4 Height for every metre of slope",
                "figure": True,
                "teaches": ["sine", "cosine"],
                "steps": [
                    {"kind": "question",
                     "text": "A ladder leans at 30° to the ground. How high does it reach for every metre of its length?"},
                    {"kind": "idea",
                     "text": "Half a metre. At 30°, a ladder reaches up half of its own length, however long the ladder is."},
                    {"kind": "picture",
                     "text": "In the figure, set θ to 30° and the radius to 2. The red height is 1. "
                             "Move the radius up to 4: the height grows to 2, and height ÷ radius stays 0.5."},
                    {"kind": "reason",
                     "text": "Why does the ratio stay? Each bigger triangle is an enlargement of the first. "
                             "Every side is multiplied by the same scale factor, so their ratios do not change."},
                    {"kind": "name",
                     "text": "The height ÷ the slope is the sine of θ, written sin θ. "
                             "The distance across ÷ the slope is the cosine of θ, written cos θ. So sin 30° = 0.5."},
                    {"kind": "example",
                     "text": "A ladder 6 m long makes 30° with the ground. Its top is 6 × sin 30° = 6 × 0.5 = 3 m up the wall."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to divide by the side along the ground. "
                             "Sine and cosine divide by the slope, the hypotenuse. Only tangent divides by the run."},
                    {"kind": "turn",
                     "text": "A ramp 8 m long makes 30° with the ground, and sin 30° = 0.5. How high does it rise?",
                     "answer": "4 m",
                     "answerKey": k.one(k.num("4"), accepts=["4", "4 m", "4m"], rejects=["16", "8", "0.5"])},
                    {"kind": "sayBack",
                     "text": "sin θ is height ÷ hypotenuse and cos θ is across ÷ hypotenuse. Both belong to the angle, whatever the size."},
                ],
            },
            {
                "heading": "12.5 One circle for every angle",
                "teaches": ["unit-circle", "pythagorean-identity"],
                "steps": [
                    {"kind": "question",
                     "text": "You sit on a Ferris wheel whose spokes are 1 unit long. "
                             "As it turns, how high above the hub and how far to the side are you?"},
                    {"kind": "idea",
                     "text": "Your spoke is the hypotenuse, 1 unit long. So your height is sin θ and your distance across is cos θ."},
                    {"kind": "picture",
                     "text": "Draw a circle of radius 10 cm centred on (0, 0). Mark the point at 30° round from the right. "
                             "Measure its height, 5 cm, and its distance across, about 8.7 cm."},
                    {"kind": "reason",
                     "text": "Why do the squares add up to 1? The height, the distance across and the spoke make a right-angled triangle. "
                             "Pythagoras' theorem says height² + across² = 1²."},
                    {"kind": "name",
                     "text": "A circle of radius 1 centred on (0, 0) is the unit circle. The point at angle θ is (cos θ, sin θ). "
                             "The rule sin²θ + cos²θ = 1 is the Pythagorean identity."},
                    {"kind": "example",
                     "text": "At 30°, sin θ = 0.5, so sin²θ = 0.25. Then cos²θ = 1 − 0.25 = 0.75, and cos 30° is about 0.866."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to think sin θ + cos θ = 1. At 30° that would make cos 30° = 0.5. "
                             "It is the squares that add to 1."},
                    {"kind": "turn",
                     "text": "For an angle less than 90°, sin θ = 0.6. Use sin²θ + cos²θ = 1 to find cos θ.",
                     "answer": "0.8",
                     "answerKey": k.one(k.num("0.8"), accepts=["0.8", "cos θ = 0.8", "4/5"], rejects=["0.4", "0.64", "0.36"])},
                    {"kind": "sayBack",
                     "text": "On the unit circle the point at angle θ is (cos θ, sin θ), and sin²θ + cos²θ = 1 at every angle."},
                ],
            },
            {
                "heading": "12.6 Measuring a turn by its arc",
                "teaches": ["radian"],
                "steps": [
                    {"kind": "question",
                     "text": "Cut a piece of string as long as a circle's radius, and lay it round the edge of the circle. "
                             "What angle does it make at the centre?"},
                    {"kind": "idea",
                     "text": "A little less than 60°, about 57°. "
                             "The angle depends only on how many radii fit along the arc, not on the size of the circle."},
                    {"kind": "picture",
                     "text": "Draw a circle of radius 5 cm and bend a 5 cm strip of paper along its edge. "
                             "Join both ends of the strip to the centre and measure the angle."},
                    {"kind": "reason",
                     "text": "Why about 57°? The whole circumference is 2π radii long, about 6.28 of them. "
                             "So one radius of arc is 360° ÷ 6.28, about 57.3°."},
                    {"kind": "name",
                     "text": "An angle whose arc is one radius long is 1 radian. "
                             "A full turn is 2π radians and a half turn is π radians."},
                    {"kind": "example",
                     "text": "A half turn is 180°, which is π radians, about 3.14. "
                             "So 90°, half of that, is π ÷ 2 radians, about 1.57."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to read 1 radian as 1°. "
                             "A radian is far bigger: about 57 degrees fit inside it."},
                    {"kind": "turn",
                     "text": "A full turn is 2π radians, about 6.28. How many radians is a quarter turn, to 2 decimal places?",
                     "answer": "1.57",
                     "answerKey": k.one(k.num("1.57"), accepts=["1.57", "1.57 radians", "about 1.57"], rejects=["90", "3.14", "6.28"])},
                    {"kind": "sayBack",
                     "text": "One radian is the angle whose arc is one radius long. A full turn is 2π radians."},
                ],
            },
            {
                "heading": "12.7 Triangles with no right angle",
                "teaches": ["sine-rule"],
                "steps": [
                    {"kind": "question",
                     "text": "A field is a triangle with no square corner. "
                             "Can you still find a side you cannot reach from a side and two angles you can measure?"},
                    {"kind": "idea",
                     "text": "Yes. Drop a line from one corner straight down to the opposite side. "
                             "That splits the field into two right-angled triangles that share their height."},
                    {"kind": "picture",
                     "text": "Draw any triangle ABC and drop a line from C straight down to AB. "
                             "Label the side across from A as a, and the side across from B as b."},
                    {"kind": "reason",
                     "text": "Why do the two sides match up? The shared height is b × sin A in one triangle and a × sin B in the other. "
                             "So b × sin A = a × sin B."},
                    {"kind": "name",
                     "text": "Divide both sides and you get the sine rule: a ÷ sin A = b ÷ sin B = c ÷ sin C. "
                             "Each side ÷ the sine of the angle across from it gives the same number."},
                    {"kind": "example",
                     "text": "In a triangle, a = 6 cm, sin A = 0.5 and sin B = 0.8. "
                             "Then b = 6 × 0.8 ÷ 0.5 = 9.6 cm."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to pair a side with an angle at one of its own ends. "
                             "Each side goes with the angle across from it."},
                    {"kind": "turn",
                     "text": "In a triangle, a = 8 cm, sin A = 0.4 and sin B = 0.6. Use the sine rule to find b.",
                     "answer": "12 cm",
                     "answerKey": k.one(k.num("12"), accepts=["12", "12 cm", "b = 12"], rejects=["5.33", "4.8", "3.2"])},
                    {"kind": "sayBack",
                     "text": "In any triangle, each side ÷ the sine of the angle across from it gives the same number."},
                ],
            },
            {
                "heading": "12.8 Pythagoras with a correction",
                "teaches": ["cosine-rule"],
                "steps": [
                    {"kind": "question",
                     "text": "Two sides of a triangle are 5 cm and 8 cm, with 60° between them. How long is the third side?"},
                    {"kind": "idea",
                     "text": "7 cm. With a right angle it would be about 9.4 cm, from Pythagoras' theorem. "
                             "A smaller angle pulls the ends closer, so you take something away."},
                    {"kind": "picture",
                     "text": "Hinge two sticks of 5 cm and 8 cm together. Open them to 90°, then close them to 60°. "
                             "Watch the gap between their free ends shrink."},
                    {"kind": "reason",
                     "text": "Why take away 2ab cos C? Cosine measures how much one side leans along the other. "
                             "At 90° the lean is zero and the rule turns back into Pythagoras' theorem."},
                    {"kind": "name",
                     "text": "The cosine rule says c² = a² + b² − 2ab cos C, where C is the angle between sides a and b."},
                    {"kind": "example",
                     "text": "Sides of 3 cm and 5 cm meet at 60°, and cos 60° = 0.5. "
                             "Then c² = 9 + 25 − 2 × 3 × 5 × 0.5 = 19, so c is about 4.36 cm."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to use an angle that is not between the two known sides. "
                             "The angle C must sit where sides a and b meet."},
                    {"kind": "turn",
                     "text": "Sides of 5 cm and 8 cm meet at 60°, and cos 60° = 0.5. Use the cosine rule to find the third side.",
                     "answer": "7 cm",
                     "answerKey": k.one(k.num("7"), accepts=["7", "7 cm", "c = 7"], rejects=["49", "9.43", "13"])},
                    {"kind": "sayBack",
                     "text": "The cosine rule c² = a² + b² − 2ab cos C is Pythagoras' theorem with a correction for the angle."},
                ],
            },
        ],
        "callouts": [
            {"kind": "predict", "title": "Predict first",
             "body": "Set θ to 45°. Predict whether the red height or the blue side along the ground will be longer, then look."},
            {"kind": "check", "title": "Explain it",
             "body": "Explain to a friend why sin 30° is 0.5 in every right-angled triangle with a 30° angle, "
                     "from a set square to a mountain."},
            {"kind": "careful", "title": "Name the angle first",
             "body": "The side across from an angle and the side beside it swap when you move to the other angle. "
                     "Name the angle you are working with, then name its sides."},
        ],
        "debate": {
            "id": "debate-ch12-pythagoras-trig",
            "oupUnitNumber": 8,
            "title": "Double the angle, double the sine?",
            "contextPrompt": "sin 30° = 0.5. Asha and Rohan argue about sin 60°.",
            "speakerAName": "Asha",
            "speakerAClaim": "60° is twice 30°, so sin 60° is twice 0.5. That makes it 1.",
            "speakerBName": "Rohan",
            "speakerBClaim": "sin 60° can't be 1. That would make the height as long as the slope, and only 90° does that.",
            "choices": [
                {"id": "ch12-a", "speakerLabel": "Asha is right (sin 60° = 1)",
                 "reasoningStatement": "The angle doubles, so the height for every metre of slope doubles too.",
                 "isCorrect": False,
                 "socraticRebuttal": "If sin 60° were 1, the height would equal the slope. "
                                     "What would sin 90° be, and could any height be longer than the slope?"},
                {"id": "ch12-b", "speakerLabel": "Rohan is right (sin 60° is less than 1)",
                 "reasoningStatement": "The height can never be longer than the slope, and only a 90° angle makes them equal.",
                 "isCorrect": True,
                 "socraticRebuttal": "Yes. sin 60° is about 0.866. "
                                     "Doubling an angle does not double its sine: the height grows more and more slowly near 90°."},
                {"id": "ch12-c", "speakerLabel": "Neither. It depends how big the triangle is.",
                 "reasoningStatement": "A bigger triangle has a bigger height.",
                 "isCorrect": False,
                 "socraticRebuttal": "A bigger triangle has a longer slope too. "
                                     "What happens to height ÷ slope when both grow by the same scale factor?"},
            ],
            "invariantTakeaway": "A sine belongs to its angle, but it does not grow in step with it: sin 60° is about 0.866, not twice sin 30°.",
        },
        "keyTerms": ["Right-angled triangle", "Hypotenuse", "Pythagoras' theorem", "Theta", "Tangent", "Sine", "Cosine",
                     "Unit circle", "Pythagorean identity", "Radian", "Sine rule", "Cosine rule"],
        "widgets": ["w_atlas_unit_circle", "w_pythagoras_garfield_proof", "w_cosine_rule_generaliser"],
        "widgetText": {
            "w_atlas_unit_circle": {
                "title": "A point that goes round",
                "challengePrompt": "Turn the point round the circle. "
                                   "Before you start, predict the angle where its height is greatest.",
                "cutaway": "The point sits on a circle of radius 1. Its height above the centre is sin θ, "
                           "and its distance across is cos θ.",
                "idealised": "The rule: the point at angle θ on the unit circle is (cos θ, sin θ)",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Turn the point slowly from 0° round to 90°."},
                    {"title": "2. Notice", "caption": "The height grows from 0 to 1, and the distance across shrinks from 1 to 0."},
                    {"title": "3. Match the rule", "caption": "Height is sin θ and distance across is cos θ, because the radius is 1."},
                    {"title": "4. Push it further", "caption": "Turn past 90°. Predict which of the two becomes negative first."},
                    {"title": "5. Draw it", "caption": "Draw a circle of radius 10 cm and mark the points at 30°, 45° and 60°."},
                ],
            },
            "w_pythagoras_garfield_proof": {
                "title": "Three squares on one triangle",
                "challengePrompt": "Look at the triangle under the point on the circle. "
                                   "Predict what the squares on its two shorter sides add up to.",
                "cutaway": "The triangle under the point has a hypotenuse of 1, the radius. "
                           "Its shorter sides are sin θ and cos θ, so their squares add to 1² = 1.",
                "idealised": "The rule: a² + b² = c², so sin²θ + cos²θ = 1",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Move the point and watch the three squares change size."},
                    {"title": "2. Notice", "caption": "The two small squares trade area, but the big square on the radius stays the same."},
                    {"title": "3. Match the rule", "caption": "The square on the radius is 1 × 1 = 1, so the two small squares add to 1."},
                    {"title": "4. Push it further", "caption": "Find the angle where the two small squares are equal. Predict it first."},
                    {"title": "5. Draw it", "caption": "Draw the 3, 4, 5 triangle with a square on each side, and count the small squares."},
                ],
            },
            "w_cosine_rule_generaliser": {
                "title": "Opening a hinge",
                "challengePrompt": "Open the angle between two sides from 60° to 90° and then to 120°. "
                                   "Predict whether the third side grows or shrinks.",
                "cutaway": "Two sides are hinged at angle C. Below 90° the far side is shorter than Pythagoras' theorem gives, "
                           "and above 90° it is longer.",
                "idealised": "The rule: c² = a² + b² − 2ab cos C",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Open the hinge slowly and watch the third side."},
                    {"title": "2. Notice", "caption": "At 90° the third side is what Pythagoras' theorem gives."},
                    {"title": "3. Match the rule", "caption": "cos 90° = 0, so the part taken away is 0 at a right angle."},
                    {"title": "4. Push it further", "caption": "Past 90°, cos C is negative. Predict what that does to c²."},
                    {"title": "5. Draw it", "caption": "Draw sides of 5 cm and 8 cm at 60°, and measure the third side. It is 7 cm."},
                ],
            },
        },
        "atlasLessons": [
            {
                "title": "Chapter 12 · The squares on a right-angled triangle",
                "question": "Why do the squares on the two shorter sides add up to the square on the hypotenuse?",
                "explanation": "Four copies of the triangle fit round a tilted square inside a bigger square. "
                               "Moved around, they leave two smaller squares uncovered instead, with the same area.",
                "limits": "The rule: a² + b² = c² works only when the angle between a and b is 90°",
            },
            {
                "title": "Chapter 12 · Ratios that belong to an angle",
                "question": "Why is sin 30° the same in a set square and in a mountain?",
                "explanation": "Any two right-angled triangles with a 30° angle are similar shapes. "
                               "One is an enlargement of the other, so height ÷ hypotenuse is the same in both.",
                "limits": "The rule: sin θ, cos θ and tan θ depend only on the angle θ",
            },
            {
                "title": "Chapter 12 · The point on the circle",
                "question": "Why is the point at angle θ on the unit circle at (cos θ, sin θ)?",
                "explanation": "Its radius is 1 and is the hypotenuse of the triangle under it. "
                               "Height ÷ 1 is sin θ and across ÷ 1 is cos θ.",
                "limits": "The rule: sin²θ + cos²θ = 1 at every angle",
            },
        ],
        "visualMathTips": {
            "tip-pythag-trig": {
                "title": "Why sin²θ + cos²θ = 1 for every angle",
                "visualIntuition": "On a circle of radius 1, the point at angle θ sits sin θ up and cos θ across from the centre.",
                "ahaMoment": "Those two lengths are the shorter sides of a right-angled triangle whose hypotenuse is 1.",
                "formula": "sin²θ + cos²θ = 1² = 1",
            },
        },
    }


def cards(k):
    """The concept cards this chapter teaches."""
    return {
        "right-angled-triangle": {
            "name": "Right-angled triangle",
            "aliases": ["right-angled triangle", "right-angled triangles", "right triangle", "right triangles"],
            "oneSentence": "A triangle with one corner of exactly 90°, a square corner like the corner of a page.",
            "picture": "A set square, with one square corner and two pointed ones.",
            "steps": [
                "Look for the corner marked with a small square.",
                "The other two angles add up to 90°.",
                "The side across from the square corner is the longest.",
            ],
            "workedExample": "A triangle has angles of 90°, 60° and 30°. It has a square corner, so it is a right-angled triangle.",
            "check": {
                "prompt": "A right-angled triangle has one angle of 25°, besides the right angle. What is its third angle, in degrees?",
                "answer": "65°",
                "answerKey": k.one(k.num("65"), accepts=["65", "65°", "65 degrees"], rejects=["155", "115", "25"]),
            },
            "mixUp": {
                "name": "any triangle with a big angle",
                "how": "Only an angle of exactly 90° counts. A triangle with a 100° angle is not a right-angled triangle.",
            },
            "standsOn": [],
        },
        "hypotenuse": {
            "name": "Hypotenuse",
            "aliases": ["hypotenuse", "hypotenuses"],
            "oneSentence": "The side of a right-angled triangle across from the right angle. It is always the longest side.",
            "picture": "A ladder leaning on a wall: the ladder itself, from the ground to the wall.",
            "steps": [
                "Find the right angle.",
                "Look across the triangle from it.",
                "The side you see is the hypotenuse. It does not touch the right angle.",
            ],
            "workedExample": "A triangle has sides of 5, 12 and 13 cm with a right angle between the 5 cm and 12 cm sides. "
                             "The hypotenuse is the 13 cm side.",
            "check": {
                "prompt": "A right-angled triangle has sides of 7 cm, 24 cm and 25 cm. How long is its hypotenuse, in cm?",
                "answer": "25 cm",
                "answerKey": k.one(k.num("25"), accepts=["25", "25 cm", "25cm"], rejects=["7", "24", "31"]),
            },
            "mixUp": {
                "name": "the bottom side",
                "how": "The hypotenuse is found from the right angle, not from how the triangle is drawn. It can point any way.",
            },
            "standsOn": ["right-angled-triangle"],
        },
        "pythagoras-theorem": {
            "name": "Pythagoras' theorem",
            "aliases": ["Pythagoras' theorem", "Pythagoras's theorem", "Pythagoras theorem", "Pythagoras"],
            "oneSentence": "In a right-angled triangle, the squares on the two shorter sides add up to the square on the hypotenuse: a² + b² = c².",
            "picture": "A 3, 4, 5 triangle on squared paper, with 9 and 16 small squares on its short sides and 25 on its longest.",
            "steps": [
                "Square the two shorter sides.",
                "Add the two squares.",
                "Take the square root to get the hypotenuse.",
            ],
            "workedExample": "Shorter sides of 8 cm and 15 cm give 64 + 225 = 289. The square root of 289 is 17, so the hypotenuse is 17 cm.",
            "check": {
                "prompt": "A right-angled triangle has shorter sides of 9 cm and 12 cm. How long is its hypotenuse, in cm?",
                "answer": "15 cm",
                "answerKey": k.one(k.num("15"), accepts=["15", "15 cm", "15cm"], rejects=["21", "225", "108"]),
            },
            "mixUp": {
                "name": "adding the sides",
                "how": "The squares add up, not the sides. 3 + 4 is 7, but the hypotenuse is 5.",
            },
            "standsOn": ["hypotenuse", "square-root", "area"],
        },
        "theta": {
            "name": "Theta",
            "aliases": ["θ", "theta"],
            "oneSentence": "A Greek letter, said theta, used as the name of an angle we are working with.",
            "picture": "A ramp with a small arc at its foot, labelled θ.",
            "steps": [
                "Find the angle marked θ.",
                "Measure it, or work it out from the other angles.",
                "Use θ in a rule wherever that angle appears.",
            ],
            "workedExample": "In a right-angled triangle, θ and 40° are the two smaller angles. They add to 90°, so θ = 50°.",
            "check": {
                "prompt": "In a right-angled triangle, θ and 70° are the two smaller angles. What is θ, in degrees?",
                "answer": "20°",
                "answerKey": k.one(k.num("20"), accepts=["20", "20°", "θ = 20"], rejects=["110", "70", "290"]),
            },
            "mixUp": {
                "name": "a length",
                "how": "θ names an angle, measured in degrees or radians. Letters like a, b and c name sides.",
            },
            "standsOn": [],
        },
        "tangent": {
            "name": "Tangent",
            "aliases": ["tangent", "tan θ", "tan"],
            "oneSentence": "In a right-angled triangle, the side across from angle θ ÷ the side beside it. For a ramp it is rise ÷ run.",
            "picture": "A ramp 4 m along and 1 m up: tan θ = 1 ÷ 4 = 0.25.",
            "steps": [
                "Find the side across from θ, the rise.",
                "Find the side beside θ that is not the hypotenuse, the run.",
                "Divide the rise by the run.",
            ],
            "workedExample": "A ramp rises 1.5 m over 6 m along the ground. tan θ = 1.5 ÷ 6 = 0.25.",
            "check": {
                "prompt": "A ramp rises 5 m over 5 m along the ground. What is tan θ?",
                "answer": "1",
                "answerKey": k.one(k.num("1"), accepts=["1", "tan θ = 1", "1.0"], rejects=["5", "10", "0.5"]),
            },
            "mixUp": {
                "with": "sine",
                "how": "Tangent divides the rise by the run. Sine divides the rise by the hypotenuse, the slope.",
            },
            "standsOn": ["right-angled-triangle", "ratio"],
        },
        "sine": {
            "name": "Sine",
            "aliases": ["sine", "sines", "sin θ", "sin"],
            "oneSentence": "In a right-angled triangle, the side across from angle θ ÷ the hypotenuse.",
            "picture": "A ladder leaning at 30°: its top is half of its length up the wall, so sin 30° = 0.5.",
            "steps": [
                "Find the side across from θ, the height.",
                "Find the hypotenuse, the slope.",
                "Divide the height by the hypotenuse.",
            ],
            "workedExample": "A slope 10 m long rises 6 m. sin θ = 6 ÷ 10 = 0.6.",
            "check": {
                "prompt": "A right-angled triangle has a hypotenuse of 20 cm and an angle θ of 30°, and sin 30° = 0.5. "
                          "How long is the side across from θ, in cm?",
                "answer": "10 cm",
                "answerKey": k.one(k.num("10"), accepts=["10", "10 cm", "10cm"], rejects=["40", "20", "17.3"]),
            },
            "mixUp": {
                "with": "cosine",
                "how": "Sine uses the side across from θ. Cosine uses the side beside θ.",
            },
            "standsOn": ["hypotenuse", "ratio", "similar-shapes"],
        },
        "cosine": {
            "name": "Cosine",
            "aliases": ["cosine", "cosines", "cos θ", "cos"],
            "oneSentence": "In a right-angled triangle, the side beside angle θ ÷ the hypotenuse.",
            "picture": "A ladder leaning at 60°: its foot is half of its length out from the wall, so cos 60° = 0.5.",
            "steps": [
                "Find the side beside θ that is not the hypotenuse.",
                "Find the hypotenuse.",
                "Divide the side beside θ by the hypotenuse.",
            ],
            "workedExample": "A slope 10 m long covers 8 m along the ground. cos θ = 8 ÷ 10 = 0.8.",
            "check": {
                "prompt": "A ladder 12 m long makes 60° with the ground, and cos 60° = 0.5. How far is its foot from the wall, in m?",
                "answer": "6 m",
                "answerKey": k.one(k.num("6"), accepts=["6", "6 m", "6m"], rejects=["24", "12", "10.4"]),
            },
            "mixUp": {
                "with": "sine",
                "how": "Cosine uses the side beside θ. Sine uses the side across from θ.",
            },
            "standsOn": ["hypotenuse", "ratio"],
        },
        "unit-circle": {
            "name": "Unit circle",
            "aliases": ["unit circle", "unit circles"],
            "oneSentence": "A circle of radius 1 centred on (0, 0). The point at angle θ on it is (cos θ, sin θ).",
            "picture": "A Ferris wheel with spokes 1 unit long, its hub at (0, 0).",
            "steps": [
                "Start at (1, 0), on the right.",
                "Turn anticlockwise through angle θ.",
                "Read off the point: its x-coordinate is cos θ and its y-coordinate is sin θ.",
            ],
            "workedExample": "At 90° the point is straight above the centre, at (0, 1). So cos 90° = 0 and sin 90° = 1.",
            "check": {
                "prompt": "Where on the unit circle is the point at 0°?",
                "answer": "(1, 0)",
                "answerKey": k.one(k.seq("1", "0"), accepts=["(1, 0)", "1, 0", "(1,0)"], rejects=["(0, 1)", "(0, 0)", "(−1, 0)"]),
            },
            "mixUp": {
                "name": "a circle of another size",
                "how": "Only a circle of radius 1 gives sin θ and cos θ directly. On a bigger circle, divide by the radius first.",
            },
            "standsOn": ["radius-and-diameter", "coordinates", "sine", "cosine"],
        },
        "pythagorean-identity": {
            "name": "Pythagorean identity",
            "aliases": ["Pythagorean identity", "Pythagorean identities"],
            "oneSentence": "The rule sin²θ + cos²θ = 1, true for every angle θ.",
            "picture": "The triangle under a point on the unit circle, with sides sin θ and cos θ and a hypotenuse of 1.",
            "steps": [
                "Square the sine you know.",
                "Take it away from 1 to get the cosine squared.",
                "Take the square root.",
            ],
            "workedExample": "If cos θ = 0.6, then sin²θ = 1 − 0.36 = 0.64, so sin θ = 0.8 for an angle less than 90°.",
            "check": {
                "prompt": "For an angle less than 90°, cos θ = 0.8. What is sin θ?",
                "answer": "0.6",
                "answerKey": k.one(k.num("0.6"), accepts=["0.6", "sin θ = 0.6", "3/5"], rejects=["0.2", "0.36", "0.64"]),
            },
            "mixUp": {
                "name": "sin θ + cos θ = 1",
                "how": "The squares add to 1, not the sine and cosine themselves. At 45° each is about 0.707.",
            },
            "standsOn": ["pythagoras-theorem", "unit-circle"],
        },
        "radian": {
            "name": "Radian",
            "aliases": ["radian", "radians"],
            "oneSentence": "The angle whose arc is one radius long, about 57.3°. A full turn is 2π radians.",
            "picture": "A piece of string as long as the radius, bent round the edge of the circle.",
            "steps": [
                "To change degrees to radians, divide by 180.",
                "Then multiply by π.",
                "Check: 180° is π radians, about 3.14.",
            ],
            "workedExample": "60° is 60 ÷ 180 × π = π ÷ 3 radians, about 1.05.",
            "check": {
                "prompt": "A half turn is π radians. How many radians is that, to 2 decimal places?",
                "answer": "3.14",
                "answerKey": k.one(k.num("3.14"), accepts=["3.14", "3.14 radians", "about 3.14"], rejects=["180", "6.28", "1.57"]),
            },
            "mixUp": {
                "name": "a degree",
                "how": "A radian is about 57 times as big as a degree.",
            },
            "standsOn": ["radius-and-diameter", "angle"],
        },
        "sine-rule": {
            "name": "Sine rule",
            "aliases": ["sine rule", "sine rules"],
            "oneSentence": "In any triangle, each side ÷ the sine of the angle across from it gives the same number: a ÷ sin A = b ÷ sin B.",
            "picture": "A triangle split by a line dropped from its top corner into two right-angled triangles with one shared height.",
            "steps": [
                "Pair each side with the angle across from it.",
                "Write a ÷ sin A = b ÷ sin B with the values you know.",
                "Solve for the one you are missing.",
            ],
            "workedExample": "a = 6 cm, sin A = 0.3 and sin B = 0.5. Then b = 6 × 0.5 ÷ 0.3 = 10 cm.",
            "check": {
                "prompt": "In a triangle, a = 10 cm, sin A = 0.5 and sin B = 0.3. How long is b, in cm?",
                "answer": "6 cm",
                "answerKey": k.one(k.num("6"), accepts=["6", "6 cm", "b = 6"], rejects=["16.7", "1.5", "3"]),
            },
            "mixUp": {
                "with": "cosine-rule",
                "how": "The sine rule needs a side and the angle across from it. The cosine rule needs two sides and the angle between them.",
            },
            "standsOn": ["sine", "ratio"],
        },
        "cosine-rule": {
            "name": "Cosine rule",
            "aliases": ["cosine rule", "cosine rules"],
            "oneSentence": "In any triangle, c² = a² + b² − 2ab cos C, where C is the angle between sides a and b.",
            "picture": "Two sticks hinged together, the gap between their free ends shrinking as the hinge closes.",
            "steps": [
                "Find the two known sides and the angle between them.",
                "Work out a² + b² − 2ab cos C.",
                "Take the square root to get c.",
            ],
            "workedExample": "a = 4 cm, b = 6 cm and C = 60°, with cos 60° = 0.5. Then c² = 16 + 36 − 24 = 28, so c is about 5.29 cm.",
            "check": {
                "prompt": "Sides of 3 cm and 4 cm meet at 90°, and cos 90° = 0. How long is the third side, in cm?",
                "answer": "5 cm",
                "answerKey": k.one(k.num("5"), accepts=["5", "5 cm", "c = 5"], rejects=["7", "25", "1"]),
            },
            "mixUp": {
                "with": "pythagoras-theorem",
                "how": "Pythagoras' theorem is the cosine rule at 90°, where cos C = 0. At any other angle the correction matters.",
            },
            "standsOn": ["pythagoras-theorem", "cosine"],
        },
    }


def sums():
    """Every sum chapter 12 and its cards state, recomputed. test_book_maths.py checks computed == stated."""
    third = lambda *angles: 180 - sum(angles)
    return [
        # The values the text quotes
        ("sin 30°, cos 60°", (sin(30), cos(60)), (0.5, 0.5)),
        ("cos 30°, sin 60°, sin 45°", (round(cos(30), 3), round(sin(60), 3), round(sin(45), 3)), (0.866, 0.866, 0.707)),
        ("0° and 90°", (cos(0), sin(0), cos(90), sin(90)), (1, 0, 0, 1)),
        ("π, 2π, π ÷ 2, π ÷ 3", (round(math.pi, 2), round(2 * math.pi, 2), round(math.pi / 2, 2), round(math.pi / 3, 2)),
         (3.14, 6.28, 1.57, 1.05)),
        ("one radian", (round(math.degrees(1), 1), round(360 / (2 * math.pi), 1), round(math.degrees(1))), (57.3, 57.3, 57)),
        # Skill card, hook, figure
        ("skill 5, 12", (25 + 144, hypotenuse(5, 12)), (169, 13)),
        ("skill ramp", 10 * HALF, 5),
        ("hook ladder 5, 3", math.isqrt(5 ** 2 - 3 ** 2), 4),
        ("figure radius 2 and 4 at 30°", (2 * HALF, 4 * HALF), (1, 2)),
        # 12.1 The longest side
        ("3, 4 gives 5", hypotenuse(3, 4), 5),
        ("other two add to 90", third(90), 90),
        ("6, 8, 10", hypotenuse(6, 8), 10),
        ("turn 12.1", (third(90, 35), 90 + 35, 180 - 35), (55, 125, 145)),
        # 12.2 Squares on the sides
        ("squares 9, 16, 25", (3 ** 2, 4 ** 2, 5 ** 2, 9 + 16), (9, 16, 25, 25)),
        ("5, 12, 13", (25 + 144, math.isqrt(169)), (169, 13)),
        ("3 + 4", 3 + 4, 7),
        ("turn 12.2", (hypotenuse(6, 8), 6 + 8, 6 ** 2 + 8 ** 2, 6 * 8), (10, 14, 100, 48)),
        # 12.3 How steep is a ramp
        ("ramps 1 over 4 and 2 over 8", (Fraction(1, 4), Fraction(2, 8)), (Fraction(1, 4), Fraction(1, 4))),
        ("2 over 5", float(Fraction(2, 5)), 0.4),
        ("turn 12.3", (float(Fraction(3, 4)), round(4 / 3, 2), 3 + 4, 3 * 4), (0.75, 1.33, 7, 12)),
        # 12.4 Height for every metre of slope
        ("ladder 6 m", 6 * HALF, 3),
        ("turn 12.4", (8 * HALF, 8 * 2), (4, 16)),
        # 12.5 One circle for every angle
        ("Ferris point at 30°, radius 10", (10 * HALF, round(10 * cos(30), 1)), (5, 8.7)),
        ("30°: squares", (HALF ** 2, 1 - HALF ** 2), (Fraction(1, 4), Fraction(3, 4))),
        ("turn 12.5", (math.sqrt(1 - Fraction(3, 5) ** 2), 1 - Fraction(3, 5), Fraction(4, 5) ** 2, Fraction(3, 5) ** 2),
         (0.8, Fraction(2, 5), Fraction(16, 25), Fraction(9, 25))),
        # 12.6 Measuring a turn by its arc
        ("turn 12.6", round(2 * math.pi / 4, 2), 1.57),
        # 12.7 Triangles with no right angle
        ("example b", 6 * Fraction(8, 10) / HALF, Fraction(96, 10)),
        ("turn 12.7", (8 * Fraction(6, 10) / Fraction(4, 10), round(8 * 0.4 / 0.6, 2), 8 * 0.6, 8 * 0.4),
         (12, 5.33, 4.8, 3.2)),
        # 12.8 Pythagoras with a correction
        ("5, 8 at 90°", round(math.sqrt(25 + 64), 1), 9.4),
        ("3, 5 at 60°", (cosine_rule(3, 5, HALF), round(math.sqrt(19), 2)), (19, 4.36)),
        ("turn 12.8", (cosine_rule(5, 8, HALF), math.isqrt(49), round(math.sqrt(89), 2), 5 + 8), (49, 7, 9.43, 13)),
        # Debate
        ("sin 60° is not twice sin 30°", (2 * sin(30), round(sin(60), 3)), (1, 0.866)),
        # Cards
        ("right-angled card", third(90, 60), 30),
        ("right-angled check", (third(90, 25), 180 - 25, 90 + 25), (65, 155, 115)),
        ("hypotenuse card", hypotenuse(5, 12), 13),
        ("hypotenuse check", (hypotenuse(7, 24), 7 + 24), (25, 31)),
        ("pythagoras card", (64 + 225, math.isqrt(289), hypotenuse(8, 15)), (289, 17, 17)),
        ("pythagoras check", (hypotenuse(9, 12), 9 + 12, 9 * 12, 15 ** 2), (15, 21, 108, 225)),
        ("theta card", third(90, 40), 50),
        ("theta check", (third(90, 70), 180 - 70, 360 - 70), (20, 110, 290)),
        ("tangent card", (float(Fraction(1, 4)), Fraction(3, 2) / 6), (0.25, Fraction(1, 4))),
        ("tangent check", Fraction(5, 5), 1),
        ("sine card", float(Fraction(6, 10)), 0.6),
        ("sine check", (20 * HALF, round(20 * cos(30), 1)), (10, 17.3)),
        ("cosine card", float(Fraction(8, 10)), 0.8),
        ("cosine check", (12 * HALF, round(12 * sin(60), 1)), (6, 10.4)),
        ("identity card", (1 - Fraction(36, 100), math.sqrt(0.64)), (Fraction(64, 100), 0.8)),
        ("identity check", math.sqrt(1 - Fraction(64, 100)), 0.6),
        ("identity mix-up at 45°", round(sin(45) + cos(45), 3), 1.414),
        ("radian card", (Fraction(60, 180), round(math.pi / 3, 2)), (Fraction(1, 3), 1.05)),
        ("sine rule card", 6 * HALF / Fraction(3, 10), 10),
        ("sine rule check", (10 * Fraction(3, 10) / HALF, round(10 * 0.5 / 0.3, 1)), (6, 16.7)),
        ("cosine rule card", (cosine_rule(4, 6, HALF), round(math.sqrt(28), 2)), (28, 5.29)),
        ("cosine rule check", (cosine_rule(3, 4, 0), hypotenuse(3, 4)), (25, 5)),
    ]


def answers():
    """Chapter 12's turn answers and its cards' check answers, computed."""
    decimal = lambda value: str(float(value))
    return {
        "ch12-s1-turn": 180 - 90 - 35,
        "ch12-s2-turn": hypotenuse(6, 8),
        "ch12-s3-turn": decimal(Fraction(3, 4)),
        "ch12-s4-turn": 8 * HALF,
        "ch12-s5-turn": decimal(math.sqrt(1 - Fraction(36, 100))),
        "ch12-s6-turn": round(2 * math.pi / 4, 2),
        "ch12-s7-turn": 8 * Fraction(6, 10) / Fraction(4, 10),
        "ch12-s8-turn": math.isqrt(cosine_rule(5, 8, HALF)),
        "right-angled-triangle-check": 180 - 90 - 25,
        "hypotenuse-check": hypotenuse(7, 24),
        "pythagoras-theorem-check": hypotenuse(9, 12),
        "theta-check": 180 - 90 - 70,
        "tangent-check": Fraction(5, 5),
        "sine-check": 20 * HALF,
        "cosine-check": 12 * HALF,
        "unit-circle-check": f"({cos(0):g}, {sin(0):g})",
        "pythagorean-identity-check": decimal(math.sqrt(1 - Fraction(64, 100))),
        "radian-check": round(math.pi, 2),
        "sine-rule-check": 10 * Fraction(3, 10) / HALF,
        "cosine-rule-check": math.isqrt(cosine_rule(3, 4, 0)),
    }
