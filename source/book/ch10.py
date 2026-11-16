"""
Chapter 10, written by hand to docs/CONTENT_BRIEF.md. It carries school unit 5.

Each section teaches one idea in nine steps, in this order: question, idea, picture, reason, name,
example, mistake, turn, sayBack. A section's `teaches` lists the concept cards whose names first
appear in its `name` step. `build(k)` returns the chapter and `cards(k)` its concept cards; both take the
exporter's answer-key helpers. Every section starts from something she can hold or cut: a bicycle wheel,
a tin and a piece of string, a pizza, a box of chocolates, a stack of coins.

`schoolTopics` and `schoolQuestions` rewrite the topic summaries, worked examples and faded prompts of
school unit 5. The answer keys and stuck sheets stay in the exporter.
"""

from math import pi

from book.arithmetic import Fraction

PI = Fraction("3.14")


def circumference(radius):
    """The distance round a circle, with π taken as 3.14."""
    return 2 * PI * radius


def circle_area(radius):
    """The area of a circle, with π taken as 3.14."""
    return PI * radius * radius


def trapezium_area(a, b, height):
    """Half the sum of the parallel sides, times the height between them."""
    return Fraction(a + b, 2) * height


def share(angle):
    """The part of the whole circle that a slice with this angle at the centre takes."""
    return Fraction(angle, 360)


def round_to(value, places):
    """A value rounded to a number of decimal places, as a Fraction, so it compares exactly."""
    return Fraction(str(round(float(value), places)))


def build(k):
    return {
        "number": 10,
        "title": "Circles, prisms and volume",
        "subtitle": "School book chapter 5 · The distance round a circle, the space inside shapes, and how much a solid holds",
        "hookSummary": "A circle has no straight sides to measure along. "
                       "So how can a pizza's area be worked out with a ruler?",
        "beyondSchoolBook": False,
        "skillCard": {
            "skill": "Working out the distance round a circle, the area of curved and slanted shapes, and the space inside a solid",
            "sheCan": {
                "prompt": "With no calculator: a circle has a radius of 10 cm. Using π ≈ 3.14, find the distance round it and its area. "
                          "A prism has a cross-section of 12 cm² and a length of 5 cm. What is its volume?",
                "answer": "The circumference is 2 × 3.14 × 10 = 62.8 cm. The area is 3.14 × 10 × 10 = 314 cm². "
                          "The volume is 12 × 5 = 60 cm³.",
            },
            "whyItMatters": "Wheels, pipes, tins and water tanks are round or long and straight. "
                            "Working out how far a wheel rolls, or how much a tank holds, needs these rules.",
            "standsOn": [
                "Chapter 9: loci, nets and the faces of a solid",
                "Chapter 8: polygons and their angles",
                "The area of a rectangle, counted in unit squares",
            ],
            "unlocks": [
                "Chapter 11: moving and resizing shapes, and what resizing does to an area",
                "Chapter 12: the sides of a right-angled triangle",
                "Chapter 18: areas under curves, found by adding thin slices",
            ],
        },
        "intuitionToFormula": {
            "concreteAction": "Set the radius to 4 cm and the slices to 12. "
                              "The circle's slices sit top to tail in a strip, points up and points down.",
            "ahaInvariant": "Move the slices slider up. The strip straightens into a rectangle πr long and r tall. "
                            "So the circle's area is πr × r = πr².",
            "formulaDisplay": "A = πr × r = πr²",
            "termMappings": [
                {"symbol": "πr", "visualPart": "The blue curved edges along the bottom of the strip", "colorRole": "blue",
                 "meaning": "Half of the distance round the circle"},
                {"symbol": "r", "visualPart": "The red height of the strip", "colorRole": "red",
                 "meaning": "The radius, from the centre of the circle to its edge"},
                {"symbol": "the green slice", "visualPart": "The green part of the circle", "colorRole": "green",
                 "meaning": "A slice with the angle set by the third slider, and its share of the area"},
            ],
            "atlasFigureRef": "maths/ch10-circles-mensuration/index.html",
        },
        "sections": [
            {
                "heading": "10.1 Across a circle",
                "teaches": ["radius-and-diameter"],
                "steps": [
                    {"kind": "question",
                     "text": "A bicycle wheel has spokes running from the hub to the rim, each 30 cm long. "
                             "How far is it across the wheel, through the hub?"},
                    {"kind": "idea",
                     "text": "Each spoke reaches from the middle to the edge. "
                             "Two spokes in one straight line reach right across, so the wheel is 60 cm across."},
                    {"kind": "picture",
                     "text": "Draw a circle with the compasses open to 4 cm. "
                             "Rule a line from the centre to the edge, then a line right across through the centre."},
                    {"kind": "reason",
                     "text": "Why is the line across twice the line out? The circle is the locus of points 4 cm from the centre. "
                             "The line across is one 4 cm line out on each side."},
                    {"kind": "name",
                     "text": "The distance from the centre of a circle to its edge is the radius, and more than one are radii. "
                             "The distance across through the centre is the diameter, twice the radius."},
                    {"kind": "example",
                     "text": "A coin has a diameter of 24 mm. Its radius is 24 ÷ 2 = 12 mm. "
                             "A round table with a radius of 75 cm has a diameter of 150 cm."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to measure across the circle without passing through the centre. "
                             "Any line across that misses the centre is shorter than the diameter."},
                    {"kind": "turn",
                     "text": "A round pond has a diameter of 9 m. What is its radius?",
                     "answer": "4.5 m",
                     "answerKey": k.one(k.num("4.5"), accepts=["4.5", "4.5 m", "4.5m"], rejects=["18", "9", "3"])},
                    {"kind": "sayBack",
                     "text": "The radius runs from the centre to the edge. The diameter runs right across through the centre, and is twice the radius."},
                ],
            },
            {
                "heading": "10.2 The distance round",
                "teaches": ["pi", "circumference"],
                "steps": [
                    {"kind": "question",
                     "text": "Wrap a string once round a tin, then lay it beside the tin's diameter. "
                             "How many diameters long is the string?"},
                    {"kind": "idea",
                     "text": "A little more than 3, every time. "
                             "A coin, a tin and a plate all give the same answer, whether the circle is big or small."},
                    {"kind": "picture",
                     "text": "Measure round three round things with string, and measure across each one. "
                             "Divide the distance round by the distance across. Each answer comes out near 3.14."},
                    {"kind": "reason",
                     "text": "Why is it the same for every circle? All circles are the same shape, only bigger or smaller. "
                             "Double the diameter and the distance round doubles too, so the one divided by the other stays the same."},
                    {"kind": "name",
                     "text": "The distance round a circle is its circumference. "
                             "It is always π times the diameter, where π, said pi, is about 3.14. "
                             "So C = πd, or C = 2πr."},
                    {"kind": "example",
                     "text": "A plate has a diameter of 20 cm. Its circumference is π × 20, which is about 3.14 × 20 = 62.8 cm."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to multiply the radius by π and stop. "
                             "That gives half the circumference, because πd = π × 2r."},
                    {"kind": "turn",
                     "text": "A wheel has a radius of 5 cm. Using π ≈ 3.14, what is its circumference?",
                     "answer": "31.4 cm",
                     "answerKey": k.one(k.num("31.4"), accepts=["31.4", "31.4 cm", "C = 31.4"], rejects=["15.7", "78.5", "10"])},
                    {"kind": "sayBack",
                     "text": "Every circle's circumference is π times its diameter, and π is about 3.14."},
                ],
            },
            {
                "heading": "10.3 Slanted shapes",
                "teaches": ["trapezium"],
                "steps": [
                    {"kind": "question",
                     "text": "A parallelogram leans over, with a base of 6 cm and a height of 4 cm. "
                             "Does it cover the same space as a 6 cm by 4 cm rectangle?"},
                    {"kind": "idea",
                     "text": "Yes. Cut a triangle off one slanted end and slide it to the other end. "
                             "The parallelogram becomes a 6 cm by 4 cm rectangle, with area 24 cm²."},
                    {"kind": "picture",
                     "text": "Draw a parallelogram on squared paper and cut it out. "
                             "Cut straight down from one top corner, and move the triangle across. It fits into a rectangle."},
                    {"kind": "reason",
                     "text": "Why the straight-up height and not the slanted side? Cutting and sliding keeps the area the same. "
                             "The rectangle it makes is as tall as the straight-up height."},
                    {"kind": "name",
                     "text": "A parallelogram's area is base × height, with the height at a right angle to the base. "
                             "A quadrilateral with one pair of parallel sides is a trapezium. "
                             "Two copies make a parallelogram, so a trapezium's area is ½(a + b) × h."},
                    {"kind": "example",
                     "text": "A trapezium has parallel sides of 5 cm and 9 cm, with 4 cm between them. "
                             "Its area is ½ × (5 + 9) × 4 = 7 × 4 = 28 cm²."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to use the slanted side as the height. "
                             "A parallelogram with base 9 cm, slanted side 5 cm and height 4 cm has area 36 cm², not 45 cm²."},
                    {"kind": "turn",
                     "text": "A trapezium has parallel sides of 3 cm and 7 cm, and the height between them is 4 cm. What is its area?",
                     "answer": "20 cm²",
                     "answerKey": k.one(k.num("20"), accepts=["20", "20 cm²", "20 cm2"], rejects=["40", "84", "10"])},
                    {"kind": "sayBack",
                     "text": "A parallelogram's area is base × height. A trapezium's is half the two parallel sides added, × height. Use the straight-up height."},
                ],
            },
            {
                "heading": "10.4 The space inside a circle",
                "figure": True,
                "teaches": ["area-of-a-circle"],
                "steps": [
                    {"kind": "question",
                     "text": "A pizza has a radius of 10 cm. How much space does it cover? "
                             "A circle has no straight sides to multiply together."},
                    {"kind": "idea",
                     "text": "Cut it into thin slices and lay them top to tail, points up and points down. "
                             "They make a shape that is nearly a rectangle."},
                    {"kind": "picture",
                     "text": "In the figure, set the radius to 4 cm and the slices to 12. The slices sit top to tail in a strip. "
                             "Move the slices slider up and watch the strip straighten."},
                    {"kind": "reason",
                     "text": "Why is the strip πr long and r tall? Half the slices have their curved edges along the bottom, so the bottom is half the circumference, πr. "
                             "Each slice is one radius tall."},
                    {"kind": "name",
                     "text": "So the area of a circle is πr × r, written πr². "
                             "With π ≈ 3.14, the pizza of radius 10 cm covers about 314 cm²."},
                    {"kind": "example",
                     "text": "A round rug has a radius of 2 m. Its area is π × 2², which is about 3.14 × 4 = 12.56 m²."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to work out π × r × 2 in place of π × r × r. "
                             "For a radius of 10 cm that gives 62.8, which is a length round the edge, not an area."},
                    {"kind": "turn",
                     "text": "A circle has a radius of 3 cm. Using π ≈ 3.14, what is its area?",
                     "answer": "28.26 cm²",
                     "answerKey": k.one(k.num("28.26"), accepts=["28.26", "28.26 cm²", "28.26 cm2"],
                                        rejects=["18.84", "9.42", "113.04"])},
                    {"kind": "sayBack",
                     "text": "Lay a circle's slices top to tail and they make a strip πr long and r tall. So its area is πr²."},
                ],
            },
            {
                "heading": "10.5 Slices of a circle",
                "teaches": ["sector"],
                "steps": [
                    {"kind": "question",
                     "text": "A pizza of radius 10 cm is cut into 4 equal slices. "
                             "How much pizza is in one slice, and how long is its crust?"},
                    {"kind": "idea",
                     "text": "Each slice is a quarter of the pizza. "
                             "So its area is a quarter of the whole area, and its crust is a quarter of the circumference."},
                    {"kind": "picture",
                     "text": "Draw a circle and two radii with 90° between them, and shade the slice between them. "
                             "The 90° is a quarter of the 360° round the centre."},
                    {"kind": "reason",
                     "text": "Why use the angle? The slices round the centre share 360° between them. "
                             "A slice with an angle of 90° takes 90/360 of the circle, of its area and of its edge."},
                    {"kind": "name",
                     "text": "A slice of a circle between two radii is a sector. "
                             "With an angle θ at the centre, its curved edge has an arc length of θ/360 × 2πr, and its area is θ/360 × πr²."},
                    {"kind": "example",
                     "text": "A sector has a radius of 10 cm and an angle of 90°. "
                             "Its area is ¼ × 314 = 78.5 cm², and its arc length is ¼ × 62.8 = 15.7 cm."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to give the arc length as the distance round the whole sector. "
                             "The distance round also takes in the two straight radii."},
                    {"kind": "turn",
                     "text": "A sector has a radius of 6 cm and an angle of 60°. Using π ≈ 3.14, what is its arc length?",
                     "answer": "6.28 cm",
                     "answerKey": k.one(k.num("6.28"), accepts=["6.28", "6.28 cm", "= 6.28"], rejects=["18.84", "18.28", "37.68"])},
                    {"kind": "sayBack",
                     "text": "A sector with angle θ is θ/360 of its circle. Its area and its arc length are that share of the whole."},
                ],
            },
            {
                "heading": "10.6 How much a solid holds",
                "teaches": ["volume", "prism", "cross-section"],
                "steps": [
                    {"kind": "question",
                     "text": "A box of chocolates is shaped like a long tent, with the same triangle at every point along it. "
                             "How can you work out the space inside?"},
                    {"kind": "idea",
                     "text": "Cut it into slices 1 cm thick. Each slice is the same triangle, so each holds the same amount. "
                             "Add up the slices."},
                    {"kind": "picture",
                     "text": "Build a cuboid from 1 cm cubes, 4 cubes long, 3 across and 2 high. "
                             "One layer across the end holds 3 × 2 = 6 cubes. Count the layers."},
                    {"kind": "reason",
                     "text": "Why multiply? There are 4 layers along the length, each with 6 cubes, so 6 × 4 = 24 cubes. "
                             "The area of the end counts the cubes in one layer."},
                    {"kind": "name",
                     "text": "The space a solid fills is its volume, counted in cubes such as cm³. "
                             "A solid with the same shape all along its length is a prism. "
                             "A slice straight across it is its cross-section, and its volume is the area of the cross-section × its length."},
                    {"kind": "example",
                     "text": "The tent box has a triangle at each end with base 6 cm and height 4 cm, of area ½ × 6 × 4 = 12 cm². "
                             "It is 20 cm long, so it holds 12 × 20 = 240 cm³."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to multiply every length you can see: 6 × 4 × 20 = 480 cm³. "
                             "That is the box that would fit round the tent, twice as big."},
                    {"kind": "turn",
                     "text": "A prism has a cross-section of area 15 cm² and is 8 cm long. What is its volume?",
                     "answer": "120 cm³",
                     "answerKey": k.one(k.num("120"), accepts=["120", "120 cm³", "120 cm3"], rejects=["23", "60", "240"])},
                    {"kind": "sayBack",
                     "text": "A prism has the same cross-section all along. Its volume is the area of the cross-section × its length."},
                ],
            },
            {
                "heading": "10.7 Wrapping a solid",
                "teaches": ["surface-area"],
                "steps": [
                    {"kind": "question",
                     "text": "How much paper does it take to cover a box 5 cm long, 3 cm wide and 2 cm tall, with no overlaps?"},
                    {"kind": "idea",
                     "text": "Open the box out flat into its net. The paper must cover every one of its six rectangles."},
                    {"kind": "picture",
                     "text": "Draw the net of the box and label its rectangles. "
                             "The top and bottom are 5 by 3, the front and back are 5 by 2, and the two ends are 3 by 2."},
                    {"kind": "reason",
                     "text": "Why count each size twice? A cuboid's faces come in opposite pairs of the same size. "
                             "So the paper needed is 2 × (15 + 10 + 6) = 62 cm²."},
                    {"kind": "name",
                     "text": "The total area of all the faces of a solid is its surface area. "
                             "It is counted in squares such as cm², because it is a flat area folded round."},
                    {"kind": "example",
                     "text": "A cube has edges of 3 cm. Each of its 6 faces is 3 × 3 = 9 cm², so its surface area is 6 × 9 = 54 cm²."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to mix up surface area and volume. "
                             "The 5 by 3 by 2 box has a surface area of 62 cm² but a volume of 30 cm³."},
                    {"kind": "turn",
                     "text": "A cube has edges of 4 cm. What is its surface area?",
                     "answer": "96 cm²",
                     "answerKey": k.one(k.num("96"), accepts=["96", "96 cm²", "96 cm2"], rejects=["64", "16", "48"])},
                    {"kind": "sayBack",
                     "text": "Surface area adds up the area of every face. Its net lays every face out flat to count."},
                ],
            },
            {
                "heading": "10.8 Leaning stacks",
                "teaches": ["cavalieris-principle"],
                "steps": [
                    {"kind": "question",
                     "text": "Stack 20 coins in a straight pile, then push the pile so it leans. "
                             "Does the leaning pile hold more metal, less, or the same?"},
                    {"kind": "idea",
                     "text": "The same. It is the same 20 coins, slid sideways. "
                             "Each coin keeps its shape and its thickness."},
                    {"kind": "picture",
                     "text": "Draw a straight stack of coins as a tall rectangle. "
                             "Beside it, draw the same stack leaning, as a slanted parallelogram of the same height."},
                    {"kind": "reason",
                     "text": "Why does leaning not change the volume? Cut both stacks at any height, and each cut is one coin's circle. "
                             "Equal slices at every height add up to equal volumes."},
                    {"kind": "name",
                     "text": "Cavalieri's principle says that two solids of the same height have the same volume "
                             "if their cross-sections at every height have equal areas."},
                    {"kind": "example",
                     "text": "A tin shaped like a cylinder has a radius of 4 cm and a height of 10 cm. "
                             "Every slice is a circle of about 3.14 × 16 = 50.24 cm², so it holds about 502.4 cm³."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to measure a leaning solid's height along its slant. "
                             "The height is straight up, at a right angle to the bottom."},
                    {"kind": "turn",
                     "text": "A straight stack of 12 coins has a volume of 30 cm³. "
                             "It is pushed over so that it leans. What is its volume now?",
                     "answer": "30 cm³",
                     "answerKey": k.one(k.num("30"), accepts=["30", "30 cm³", "30 cm3"], rejects=["0", "60", "2.5"])},
                    {"kind": "sayBack",
                     "text": "Equal slices at every height give equal volumes. Leaning a stack does not change how much it holds."},
                ],
            },
        ],
        "callouts": [
            {"kind": "predict", "title": "Predict first",
             "body": "Set the slices slider to 4, then to 24. "
                     "Predict which strip looks more like a rectangle, then look."},
            {"kind": "check", "title": "Explain it",
             "body": "A round rug and a square rug both measure 2 m across. "
                     "Explain to a friend which one covers more floor, and why."},
            {"kind": "careful", "title": "Height straight up",
             "body": "In every area and volume rule in this chapter, the height is measured at a right angle to the bottom. "
                     "Never measure it along a slant."},
        ],
        "debate": {
            "id": "debate-ch10-circles",
            "oupUnitNumber": 5,
            "title": "Twice as wide, how much more pizza?",
            "contextPrompt": "A small pizza has a radius of 10 cm, and a large one has a radius of 20 cm. "
                             "Asha and Rohan argue about how much more pizza the large one has.",
            "speakerAName": "Asha",
            "speakerAClaim": "The radius is twice as long, so the large pizza has twice as much.",
            "speakerBName": "Rohan",
            "speakerBClaim": "The area is πr², and the radius is squared. So the large pizza has four times as much.",
            "choices": [
                {"id": "ch10-a", "speakerLabel": "Asha is right (twice as much)",
                 "reasoningStatement": "Double the size, double the pizza.",
                 "isCorrect": False,
                 "socraticRebuttal": "Work out both areas with π ≈ 3.14: 3.14 × 10 × 10 and 3.14 × 20 × 20. "
                                     "Is the second one double the first?"},
                {"id": "ch10-b", "speakerLabel": "Rohan is right (four times as much)",
                 "reasoningStatement": "The radius is used twice in πr², so doubling it doubles the area twice.",
                 "isCorrect": True,
                 "socraticRebuttal": "Yes. 314 cm² becomes 1256 cm², which is 4 × 314. "
                                     "The large pizza is twice as long and twice as tall in every direction."},
                {"id": "ch10-c", "speakerLabel": "Neither. It is π times as much.",
                 "reasoningStatement": "The rule has a π in it, so π decides how much more.",
                 "isCorrect": False,
                 "socraticRebuttal": "Both pizzas use the same π. Divide one area by the other: what is left once the π cancels?"},
            ],
            "invariantTakeaway": "Double the radius and the area of a circle is four times as big, because the radius is multiplied by itself.",
        },
        "keyTerms": ["Radius and diameter", "Pi", "Circumference", "Trapezium", "Area of a circle", "Sector",
                     "Volume", "Prism", "Cross-section", "Surface area", "Cavalieri's principle"],
        "widgets": ["w_circle_sector_rearranger", "w_trapezium_prism_slicer"],
        "widgetText": {
            "w_circle_sector_rearranger": {
                "title": "A circle laid out as a strip",
                "challengePrompt": "Set the unfold slider to 0, so you see the whole circle. "
                                   "Predict the length and height of the strip before you slide it to 1.",
                "cutaway": "Half the slices have their curved edges along the bottom, half the circumference, πr. "
                           "Each slice is one radius tall, so the strip covers πr × r = πr².",
                "idealised": "The rule: the area of a circle is πr²",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Move the unfold slider slowly from 0 to 1."},
                    {"title": "2. Notice", "caption": "The slices sit top to tail, and the strip looks like a rectangle."},
                    {"title": "3. Match the rule", "caption": "The strip is πr long and r tall, so its area is πr²."},
                    {"title": "4. Push it further", "caption": "Make the radius bigger. Does the strip get longer, taller, or both?"},
                    {"title": "5. Draw it", "caption": "Draw a circle cut into 8 slices in your journal, and lay them top to tail."},
                ],
            },
            "w_trapezium_prism_slicer": {
                "title": "Two trapeziums make a parallelogram",
                "challengePrompt": "Set the top side a to 3 and the bottom side b to 6. "
                                   "Predict how long the parallelogram made of two copies will be.",
                "cutaway": "Turn a copy of the trapezium over and put it beside the first. "
                           "Together they make a parallelogram a + b long, so one trapezium is half of (a + b) × h.",
                "idealised": "The rule: the area of a trapezium is ½(a + b) × h",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Move the top side slider and the bottom side slider."},
                    {"title": "2. Notice", "caption": "The two copies always fit together into a parallelogram."},
                    {"title": "3. Match the rule", "caption": "With a = 3 and b = 6, the parallelogram is 9 long, so one trapezium is half of 9 × h."},
                    {"title": "4. Push it further", "caption": "Make a equal to b. What shape is the trapezium now?"},
                    {"title": "5. Draw it", "caption": "Draw a trapezium in your journal, and a second copy turned over beside it."},
                ],
            },
        },
        "atlasLessons": [
            {
                "title": "Chapter 10 · A circle laid out flat",
                "question": "Why is the area of a circle πr²?",
                "explanation": "Cut the circle into thin slices and lay them top to tail. "
                               "The strip is half the circumference long, πr, and one radius tall, so it covers πr × r.",
                "limits": "The rule: the area of a circle is πr², and its circumference is 2πr",
            },
            {
                "title": "Chapter 10 · Two trapeziums side by side",
                "question": "Why is a trapezium's area half of (a + b) × h?",
                "explanation": "Two copies of the trapezium, one turned over, make a parallelogram a + b long and h tall. "
                               "One trapezium is half of that parallelogram.",
                "limits": "The rule: the area of a trapezium is ½(a + b) × h, with h at a right angle to the parallel sides",
            },
            {
                "title": "Chapter 10 · Slices that add up",
                "question": "Why is a prism's volume the area of its cross-section times its length?",
                "explanation": "Each 1 cm slice along the prism holds as many cubes as the cross-section has squares. "
                               "Count the slices and multiply.",
                "limits": "The rule: volume of a prism = area of the cross-section × length",
            },
        ],
        "visualMathTips": {
            "tip-circle-area": {
                "title": "Why a circle's area is πr²",
                "visualIntuition": "Cut a circle into 24 thin slices and lay them top to tail, points up and points down.",
                "ahaMoment": "The strip is half the circumference long, πr, and one radius tall, r.",
                "formula": "A = πr × r = πr²",
            },
        },
        "schoolTopics": {
            "5.1": "The circumference of a circle is π times its diameter, C = πd = 2πr, with π about 3.14. "
                   "A sector with angle θ has θ/360 of the circle's area and of its circumference.",
            "5.2": "A parallelogram's area is base × height. A trapezium's area is ½(a + b) × h. "
                   "In both, the height is measured at a right angle to the base.",
            "5.3": "The volume of a prism is the area of its cross-section × its length. "
                   "A triangular prism with a 12 cm² triangle at each end and a length of 20 cm holds 240 cm³.",
            "5.4": "The surface area of a solid adds up the areas of all its faces. "
                   "Draw its net, find the area of each face, and add them.",
            "5.5": "Some lengths, weights and amounts are still given in older units. "
                   "5 miles is about 8 km, 1 inch is about 2.5 cm, 1 kg is about 2.2 pounds, and 1 litre is about 1.76 pints.",
        },
        "schoolQuestions": {
            "q-oup-ch05-sb": {
                "workedExample": "Step 1: The cross-section is a trapezium, so its area is ½ × (40 + 60) × 30 = 50 × 30 = 1500 cm².\n"
                                 "Step 2: Put the length in the same unit: 2.5 m = 250 cm.\n"
                                 "Step 3: The volume is the area of the cross-section × the length: 1500 × 250 = 375,000 cm³.\n"
                                 "Step 4: 1 litre is 1000 cm³, so the trough holds 375,000 ÷ 1000 = 375 litres.",
                "fadedPrompt": "The cross-section is ½ × (40 + 60) × 30 = 1500 cm². "
                               "The volume is 1500 × 250 = 375,000 cm³, which is ___ litres.",
            },
            "q-oup-ch05-wb-focus": {
                "workedExample": "Step 1: The circumference is 2πr = 2 × 22/7 × 7.\n"
                                 "Step 2: The 7s cancel, leaving 2 × 22 = 44 cm.\n"
                                 "Step 3: The area is πr² = 22/7 × 7 × 7.\n"
                                 "Step 4: One 7 cancels, leaving 22 × 7 = 154 cm².",
                "fadedPrompt": "C = 2 × 22/7 × 7 = ___ cm, and A = 22/7 × 7 × 7 = ___ cm².",
            },
            "q-oup-ch05-wb-practice": {
                "workedExample": "Step 1: The perimeter goes round all four sides: 14 + 10 + 14 + 10 = 48 cm.\n"
                                 "Step 2: The area uses the height at a right angle to the base, 8 cm, not the slanted side.\n"
                                 "Step 3: Area = base × height = 14 × 8 = 112 cm².\n"
                                 "Step 4: Check: using the slanted side would give 140 cm², too big, because the shape leans.",
                "fadedPrompt": "Perimeter = 14 + 10 + 14 + 10 = ___ cm. Area = 14 × ___ = ___ cm².",
            },
            "q-oup-ch05-wb-challenge": {
                "workedExample": "Step 1: Each slice is a sector with angle 360° ÷ 6 = 60°, so it is 1/6 of the pizza.\n"
                                 "Step 2: The arc length is 1/6 × 2 × π × 10, which is about 10.47 cm.\n"
                                 "Step 3: The distance round the slice also takes in its two straight radii: 10 + 10 = 20 cm.\n"
                                 "Step 4: The perimeter is about 20 + 10.47 = 30.47, which is 30.5 cm to 1 decimal place.",
                "fadedPrompt": "Arc length = 1/6 × 2 × π × 10 ≈ ___ cm. Perimeter = 10 + 10 + arc length ≈ ___ cm.",
            },
        },
    }


def cards(k):
    """The concept cards this chapter teaches."""
    return {
        "radius-and-diameter": {
            "name": "Radius and diameter",
            "aliases": ["radius", "radii", "diameter", "diameters", "radius and diameter"],
            "oneSentence": "The radius runs from the centre of a circle to its edge. The diameter runs right across through the centre, twice as long.",
            "picture": "A bicycle wheel: one spoke is a radius, and two spokes in a line make a diameter.",
            "steps": [
                "Find the centre of the circle.",
                "A straight line from the centre to the edge is a radius.",
                "A straight line from edge to edge through the centre is a diameter, two radii long.",
            ],
            "workedExample": "A clock face has a diameter of 30 cm. Its radius is 30 ÷ 2 = 15 cm.",
            "check": {
                "prompt": "A circle has a radius of 8 cm. What is its diameter?",
                "answer": "16 cm",
                "answerKey": k.one(k.num("16"), accepts=["16", "16 cm", "d = 16"], rejects=["4", "8", "64"]),
            },
            "mixUp": {
                "name": "any line across",
                "how": "A line from edge to edge that misses the centre is shorter than the diameter. The diameter passes through the centre.",
            },
            "standsOn": ["locus"],
        },
        "pi": {
            "name": "Pi",
            "aliases": ["π"],
            "oneSentence": "The number of diameters that fit round any circle, about 3.14. It is written π and said pi.",
            "picture": "A string wrapped once round a tin, laid beside the tin's diameter: a little over 3 diameters long.",
            "steps": [
                "Measure the distance round a circle.",
                "Measure the distance across it, through the centre.",
                "Divide the first by the second. The answer is always about 3.14, which is π.",
            ],
            "workedExample": "A hoop is 100 cm across and about 314 cm round. 314 ÷ 100 = 3.14, which is π to 2 decimal places.",
            "check": {
                "prompt": "A circle has a diameter of 10 cm. Using π ≈ 3.14, how far is it round the circle?",
                "answer": "31.4 cm",
                "answerKey": k.one(k.num("31.4"), accepts=["31.4", "31.4 cm", "= 31.4"], rejects=["62.8", "13.14", "78.5"]),
            },
            "mixUp": {
                "name": "exactly 3.14",
                "how": "3.14 is π to 2 decimal places. π goes on for ever without repeating: 3.14159…",
            },
            "standsOn": ["radius-and-diameter"],
        },
        "circumference": {
            "name": "Circumference",
            "aliases": ["circumference", "circumferences"],
            "oneSentence": "The distance round a circle: π times the diameter, or 2πr.",
            "picture": "A wheel rolled along the ground for one full turn. The track it leaves is one circumference long.",
            "steps": [
                "Find the diameter. If you know the radius, double it.",
                "Multiply the diameter by π.",
                "Give the answer as a length, such as cm.",
            ],
            "workedExample": "A wheel has a diameter of 50 cm. One full turn rolls it π × 50, about 3.14 × 50 = 157 cm.",
            "check": {
                "prompt": "A circle has a radius of 2 cm. Using π ≈ 3.14, what is its circumference?",
                "answer": "12.56 cm",
                "answerKey": k.one(k.num("12.56"), accepts=["12.56", "12.56 cm", "C = 12.56"], rejects=["6.28", "25.12", "4"]),
            },
            "mixUp": {
                "with": "area-of-a-circle",
                "how": "The circumference, 2πr, is a length round the edge. The area, πr², is the space inside, in squares.",
            },
            "standsOn": ["pi", "radius-and-diameter"],
            "footing": "area-and-perimeter",
        },
        "trapezium": {
            "name": "Trapezium",
            "aliases": ["trapezium", "trapeziums", "trapezia"],
            "oneSentence": "A quadrilateral with one pair of parallel sides. Its area is half the two parallel sides added, times the height.",
            "picture": "Two copies of a trapezium, one turned over, sitting together as a parallelogram.",
            "steps": [
                "Add the two parallel sides, a + b.",
                "Multiply by the height h, the distance between them at a right angle.",
                "Halve the answer.",
            ],
            "workedExample": "A trapezium has parallel sides of 4 cm and 10 cm, 6 cm apart. Its area is ½ × 14 × 6 = 42 cm².",
            "check": {
                "prompt": "A trapezium has parallel sides of 2 cm and 8 cm, and a height of 5 cm. What is its area?",
                "answer": "25 cm²",
                "answerKey": k.one(k.num("25"), accepts=["25", "25 cm²", "25 cm2"], rejects=["50", "80", "15"]),
            },
            "mixUp": {
                "name": "the slanted side",
                "how": "The height of a trapezium is at a right angle to the parallel sides. A slanted side is longer than the height.",
            },
            "standsOn": ["quadrilateral", "area"],
        },
        "area-of-a-circle": {
            "name": "Area of a circle",
            "aliases": ["area of a circle", "areas of circles", "area of the circle"],
            "oneSentence": "The space inside a circle: π times the radius times the radius, written πr².",
            "picture": "A circle cut into thin slices and laid top to tail as a strip, πr long and r tall.",
            "steps": [
                "Find the radius. If you know the diameter, halve it.",
                "Multiply the radius by itself.",
                "Multiply by π, and give the answer in squares such as cm².",
            ],
            "workedExample": "A round table top has a radius of 50 cm. Its area is about 3.14 × 50 × 50 = 7850 cm².",
            "check": {
                "prompt": "A circle has a diameter of 20 cm. Using π ≈ 3.14, what is its area?",
                "answer": "314 cm²",
                "answerKey": k.one(k.num("314"), accepts=["314", "314 cm²", "314 cm2"], rejects=["1256", "62.8", "31.4"]),
            },
            "mixUp": {
                "name": "using the diameter",
                "how": "πr² squares the radius. Squaring the diameter gives 4 times the area.",
            },
            "standsOn": ["pi", "area"],
        },
        "sector": {
            "name": "Sector",
            "aliases": ["sector", "sectors", "arc length", "arc lengths"],
            "oneSentence": "A slice of a circle between two radii. With angle θ it has θ/360 of the circle's area and of its circumference.",
            "picture": "One slice of a pizza cut into equal slices from the centre.",
            "steps": [
                "Find the angle θ at the centre.",
                "Write the share of the circle, θ/360.",
                "Multiply the circle's area, or its circumference, by that share.",
            ],
            "workedExample": "A sector has radius 10 cm and angle 36°, so it is 36/360 = 1/10 of the circle. "
                             "Its area is about 314 ÷ 10 = 31.4 cm².",
            "check": {
                "prompt": "A sector has a radius of 10 cm and an angle of 180°. Using π ≈ 3.14, what is its area?",
                "answer": "157 cm²",
                "answerKey": k.one(k.num("157"), accepts=["157", "157 cm²", "157 cm2"], rejects=["314", "31.4", "78.5"]),
            },
            "mixUp": {
                "name": "the arc length and the perimeter",
                "how": "The arc length is the curved edge only. The perimeter of a sector adds the two straight radii.",
            },
            "standsOn": ["area-of-a-circle", "circumference", "angle"],
        },
        "volume": {
            "name": "Volume",
            "aliases": ["volume", "volumes"],
            "oneSentence": "The space a solid fills, counted in cubes such as cm³.",
            "picture": "A box filled with 1 cm cubes, 4 long, 3 across and 2 high: 24 cubes.",
            "steps": [
                "Pick a unit cube, such as 1 cm by 1 cm by 1 cm.",
                "Count the cubes in one layer.",
                "Multiply by the number of layers, and give the answer in cubes such as cm³.",
            ],
            "workedExample": "A cuboid is 5 cm long, 3 cm wide and 2 cm tall. One layer holds 5 × 3 = 15 cubes, and 2 layers hold 30 cm³.",
            "check": {
                "prompt": "A cuboid is 6 cm long, 5 cm wide and 4 cm tall. What is its volume?",
                "answer": "120 cm³",
                "answerKey": k.one(k.num("120"), accepts=["120", "120 cm³", "120 cm3"], rejects=["15", "148", "30"]),
            },
            "mixUp": {
                "with": "surface-area",
                "how": "Volume counts the cubes inside, in cm³. Surface area counts the squares on the outside, in cm².",
            },
            "standsOn": ["area"],
            "footing": "units-and-scale",
        },
        "prism": {
            "name": "Prism",
            "aliases": ["prism", "prisms"],
            "oneSentence": "A solid with the same shape all along its length, such as a cuboid or a tent shape.",
            "picture": "A loaf of bread: every slice across it is the same shape.",
            "steps": [
                "Look along the solid from one end.",
                "Check that every slice straight across is the same shape and size.",
                "If it is, the solid is a prism, named after the shape of its slices.",
            ],
            "workedExample": "A tent shape with a triangle at each end is a triangular prism. A cuboid is a prism with a rectangle all along.",
            "check": {
                "prompt": "A prism has a cross-section of area 9 cm² and a length of 7 cm. What is its volume?",
                "answer": "63 cm³",
                "answerKey": k.one(k.num("63"), accepts=["63", "63 cm³", "63 cm3"], rejects=["16", "32", "126"]),
            },
            "mixUp": {
                "name": "a pyramid",
                "how": "A pyramid narrows to a point, so its slices get smaller. A prism's slices stay the same all along.",
            },
            "standsOn": ["net-of-a-solid", "polygon"],
        },
        "cross-section": {
            "name": "Cross-section",
            "aliases": ["cross-section", "cross-sections", "cross section", "cross sections"],
            "oneSentence": "The flat shape you see when a solid is cut straight across.",
            "picture": "A cucumber cut straight across shows a circle.",
            "steps": [
                "Picture a cut straight across the solid.",
                "Draw the flat shape the cut shows.",
                "Find its area, in squares such as cm².",
            ],
            "workedExample": "A tent-shaped prism has a triangle cross-section with base 6 cm and height 4 cm. Its area is ½ × 6 × 4 = 12 cm².",
            "check": {
                "prompt": "A prism's cross-section is a rectangle 3 cm by 5 cm. What is its area?",
                "answer": "15 cm²",
                "answerKey": k.one(k.num("15"), accepts=["15", "15 cm²", "15 cm2"], rejects=["8", "16", "30"]),
            },
            "mixUp": {
                "name": "a slice along the length",
                "how": "A cut along a tent shape shows a rectangle. The cross-section is the cut straight across, the triangle.",
            },
            "standsOn": ["area"],
        },
        "surface-area": {
            "name": "Surface area",
            "aliases": ["surface area", "surface areas"],
            "oneSentence": "The total area of all the faces of a solid, counted in squares such as cm².",
            "picture": "Wrapping paper laid flat that covers a box exactly, with no overlaps.",
            "steps": [
                "Draw the net of the solid.",
                "Find the area of each face.",
                "Add them all up, and give the answer in squares such as cm².",
            ],
            "workedExample": "A cuboid 4 cm by 2 cm by 1 cm has faces of 8, 4 and 2 cm², two of each. Its surface area is 2 × 14 = 28 cm².",
            "check": {
                "prompt": "A cube has edges of 5 cm. What is its surface area?",
                "answer": "150 cm²",
                "answerKey": k.one(k.num("150"), accepts=["150", "150 cm²", "150 cm2"], rejects=["125", "25", "60"]),
            },
            "mixUp": {
                "with": "volume",
                "how": "Surface area counts squares on the outside, in cm². Volume counts cubes inside, in cm³.",
            },
            "standsOn": ["area", "net-of-a-solid"],
        },
        "cavalieris-principle": {
            "name": "Cavalieri's principle",
            "aliases": ["Cavalieri's principle", "Cavalieri’s principle"],
            "oneSentence": "Two solids of the same height have the same volume if their slices at every height have equal areas.",
            "picture": "A straight stack of coins beside the same stack pushed over so it leans.",
            "steps": [
                "Check that the two solids have the same height, measured straight up.",
                "Cut both at the same height, and compare the areas of the two slices.",
                "If the areas match at every height, the volumes match too.",
            ],
            "workedExample": "A straight tin and a leaning tin are both 10 cm tall, with circles of 50 cm² at every height. "
                             "Both hold 50 × 10 = 500 cm³.",
            "check": {
                "prompt": "A leaning stack of coins is 6 cm tall, and every coin has an area of 5 cm². What is its volume?",
                "answer": "30 cm³",
                "answerKey": k.one(k.num("30"), accepts=["30", "30 cm³", "30 cm3"], rejects=["11", "60", "15"]),
            },
            "mixUp": {
                "name": "the slanted length",
                "how": "A leaning solid is measured straight up for its height. Its slanted side is longer than its height.",
            },
            "standsOn": ["volume", "cross-section"],
        },
    }


def sums():
    """Every sum chapter 10, its cards and its school unit text state, recomputed. test_book_maths.py checks computed == stated."""
    return [
        # Skill card
        ("radius 10 cm", (circumference(10), circle_area(10)), (Fraction("62.8"), 314)),
        ("prism 12 by 5", 12 * 5, 60),
        # Figure and callouts
        ("radius 4 strip", (PI * 4, circle_area(4)), (Fraction("12.56"), Fraction("50.24"))),
        ("rugs 2 m across", (circle_area(1), 2 * 2), (Fraction("3.14"), 4)),
        # 10.1 Across a circle
        ("30 cm spokes", 2 * 30, 60),
        ("coin 24 mm", (Fraction(24, 2), 2 * 75), (12, 150)),
        ("pond 9 m", (Fraction(9, 2), 2 * 9, Fraction(9, 3)), (Fraction("4.5"), 18, 3)),
        # 10.2 The distance round
        ("plate 20 cm", PI * 20, Fraction("62.8")),
        ("πd = π × 2r", (PI * 10, circumference(5)), (Fraction("31.4"), Fraction("31.4"))),
        ("wheel radius 5", (circumference(5), PI * 5, circle_area(5), 2 * 5), (Fraction("31.4"), Fraction("15.7"), Fraction("78.5"), 10)),
        # 10.3 Slanted shapes
        ("parallelogram 6 by 4", 6 * 4, 24),
        ("trapezium 5, 9, 4", (Fraction(5 + 9, 2), trapezium_area(5, 9, 4)), (7, 28)),
        ("parallelogram 9, 5, 4", (9 * 4, 9 * 5), (36, 45)),
        ("trapezium 3, 7, 4", (trapezium_area(3, 7, 4), (3 + 7) * 4, (3 + 7) * 4 * 2 + 4, Fraction(3 + 7, 1)),
         (20, 40, 84, 10)),
        # 10.4 The space inside a circle
        ("pizza radius 10", circle_area(10), 314),
        ("rug radius 2", (2 ** 2, circle_area(2)), (4, Fraction("12.56"))),
        ("π × r × 2 for 10", PI * 10 * 2, Fraction("62.8")),
        ("radius 3", (circle_area(3), circumference(3), PI * 3, circle_area(6)),
         (Fraction("28.26"), Fraction("18.84"), Fraction("9.42"), Fraction("113.04"))),
        # 10.5 Slices of a circle
        ("4 equal slices", (Fraction(360, 4), share(90)), (90, Fraction(1, 4))),
        ("sector 10 cm, 90°", (share(90) * circle_area(10), share(90) * circumference(10)), (Fraction("78.5"), Fraction("15.7"))),
        ("sector 6 cm, 60°", (share(60) * circumference(6), share(60) * circle_area(6), share(60) * circumference(6) + 12,
                              circle_area(6) / 3),
         (Fraction("6.28"), Fraction("18.84"), Fraction("18.28"), Fraction("37.68"))),
        # 10.6 How much a solid holds
        ("cubes 4 by 3 by 2", (3 * 2, 6 * 4), (6, 24)),
        ("tent box", (Fraction(1, 2) * 6 * 4, 12 * 20, 6 * 4 * 20), (12, 240, 480)),
        ("prism 15 by 8", (15 * 8, 15 + 8, Fraction(15 * 8, 2), 15 * 8 * 2), (120, 23, 60, 240)),
        # 10.7 Wrapping a solid
        ("box 5 by 3 by 2", (5 * 3, 5 * 2, 3 * 2, 2 * (15 + 10 + 6), 5 * 3 * 2), (15, 10, 6, 62, 30)),
        ("cube 3 cm", (3 * 3, 6 * 9), (9, 54)),
        ("cube 4 cm", (6 * 4 * 4, 4 ** 3, 4 * 4, 3 * 4 * 4), (96, 64, 16, 48)),
        # 10.8 Leaning stacks
        ("tin radius 4, height 10", (PI * 16, PI * 16 * 10), (Fraction("50.24"), Fraction("502.4"))),
        ("12 coins", (30, 2 * 30, Fraction(30, 12)), (30, 60, Fraction("2.5"))),
        # Debate
        ("pizzas 10 and 20", (circle_area(10), circle_area(20), circle_area(20) / circle_area(10)), (314, 1256, 4)),
        # Widgets and lessons
        ("a = 3, b = 6", 3 + 6, 9),
        # Cards
        ("clock 30 cm", Fraction(30, 2), 15),
        ("radius 8", (2 * 8, Fraction(8, 2), 8 * 8), (16, 4, 64)),
        ("hoop 100 cm", (PI * 100, Fraction(314, 100)), (314, PI)),
        ("diameter 10", (PI * 10, PI * 20, PI + 10, circle_area(5)), (Fraction("31.4"), Fraction("62.8"), Fraction("13.14"), Fraction("78.5"))),
        ("wheel 50 cm", PI * 50, 157),
        ("radius 2 round", (circumference(2), PI * 2, circumference(4)), (Fraction("12.56"), Fraction("6.28"), Fraction("25.12"))),
        ("trapezium 4, 10, 6", (4 + 10, trapezium_area(4, 10, 6)), (14, 42)),
        ("trapezium 2, 8, 5", (trapezium_area(2, 8, 5), (2 + 8) * 5, 2 * 8 * 5, 2 + 8 + 5), (25, 50, 80, 15)),
        ("table radius 50", circle_area(50), 7850),
        ("diameter 20 area", (circle_area(10), PI * 20 * 20, PI * 20, PI * 10), (314, 1256, Fraction("62.8"), Fraction("31.4"))),
        ("diameter squared", circle_area(20) / circle_area(10), 4),
        ("sector 36°", (share(36), circle_area(10) * share(36)), (Fraction(1, 10), Fraction("31.4"))),
        ("sector 180°", (share(180) * circle_area(10), circle_area(10), share(180) * circumference(10), share(90) * circle_area(10)),
         (157, 314, Fraction("31.4"), Fraction("78.5"))),
        ("cuboid 5 by 3 by 2", (5 * 3, 15 * 2), (15, 30)),
        ("cuboid 6 by 5 by 4", (6 * 5 * 4, 6 + 5 + 4, 2 * (30 + 24 + 20), 6 * 5), (120, 15, 148, 30)),
        ("prism 9 by 7", (9 * 7, 9 + 7, Fraction(9 * 7, 2) + Fraction(1, 2), 9 * 7 * 2), (63, 16, 32, 126)),
        ("tent cross-section", Fraction(1, 2) * 6 * 4, 12),
        ("rectangle 3 by 5", (3 * 5, 3 + 5, 2 * (3 + 5), 2 * 3 * 5), (15, 8, 16, 30)),
        ("cuboid 4 by 2 by 1", (4 * 2, 4 * 1, 2 * 1, 2 * (8 + 4 + 2)), (8, 4, 2, 28)),
        ("cube 5 cm", (6 * 25, 5 ** 3, 5 * 5, 12 * 5), (150, 125, 25, 60)),
        ("tins 50 by 10", 50 * 10, 500),
        ("stack 6 by 5", (6 * 5, 6 + 5, 2 * 30, Fraction(30, 2)), (30, 11, 60, 15)),
        # School unit 5
        ("trough", (trapezium_area(40, 60, 30), Fraction("2.5") * 100, 1500 * 250, Fraction(375000, 1000)), (1500, 250, 375000, 375)),
        ("radius 7 with 22/7", (2 * Fraction(22, 7) * 7, Fraction(22, 7) * 7 * 7), (44, 154)),
        ("parallelogram 14, 10, 8", (14 + 10 + 14 + 10, 14 * 8, 14 * 10), (48, 112, 140)),
        ("pizza in 6", (Fraction(360, 6), round_to(2 * pi * 10 / 6, 2), round_to(20 + 2 * pi * 10 / 6, 2),
                        round_to(20 + 2 * pi * 10 / 6, 1)),
         (60, Fraction("10.47"), Fraction("30.47"), Fraction("30.5"))),
        ("old units", (round_to(8 / 1.609344, 0), round_to(2.54, 1), round_to(1 / 0.45359237, 1), round_to(1 / 0.56826125, 2)),
         (5, Fraction("2.5"), Fraction("2.2"), Fraction("1.76"))),
    ]


def answers():
    """Chapter 10's turn answers and its cards' check answers, computed."""
    return {
        "ch10-s1-turn": Fraction(9, 2),
        "ch10-s2-turn": circumference(5),
        "ch10-s3-turn": trapezium_area(3, 7, 4),
        "ch10-s4-turn": circle_area(3),
        "ch10-s5-turn": share(60) * circumference(6),
        "ch10-s6-turn": 15 * 8,
        "ch10-s7-turn": 6 * 4 * 4,
        "ch10-s8-turn": 30,
        "radius-and-diameter-check": 2 * 8,
        "pi-check": PI * 10,
        "circumference-check": circumference(2),
        "trapezium-check": trapezium_area(2, 8, 5),
        "area-of-a-circle-check": circle_area(10),
        "sector-check": share(180) * circle_area(10),
        "volume-check": 6 * 5 * 4,
        "prism-check": 9 * 7,
        "cross-section-check": 3 * 5,
        "surface-area-check": 6 * 5 * 5,
        "cavalieris-principle-check": 6 * 5,
    }
