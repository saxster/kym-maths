"""
Chapter 7, written by hand to docs/CONTENT_BRIEF.md. It carries school unit 14.

Each section teaches one idea in nine steps, in this order: question, idea, picture, reason, name,
example, mistake, turn, sayBack. A section's `teaches` lists the concept cards whose names first
appear in its `name` step. `build(k)` returns the chapter and `cards(k)` its concept cards; both take the
exporter's answer-key helpers. Every section starts from taxi fares, bike rides or a number machine before any letter.

`schoolTopics` and `schoolQuestions` rewrite the topic summaries, worked examples and faded prompts of
school unit 14. The answer keys and stuck sheets stay in the exporter.
"""

from book.arithmetic import Fraction


def line(m, c):
    """The rule y = mx + c, as a function of x."""
    return lambda x: m * x + c


def gradient(p, q):
    """The rise divided by the run from point p to point q, as a Fraction."""
    return Fraction(q[1] - p[1], q[0] - p[0])


def crosses_x_axis(m, c):
    """The x value where y = mx + c meets the x-axis, as a Fraction."""
    return Fraction(-c, m)


def build(k):
    return {
        "number": 7,
        "title": "Straight-line graphs",
        "subtitle": "School book chapter 14 · Function machines, coordinates, gradient, y = mx + c and real-life graphs",
        "hookSummary": "A taxi costs ₹50 to start and ₹20 for every kilometre. "
                       "Mark the fares for 0 to 4 km as dots on squared paper. Why do the dots fall in a straight row?",
        "beyondSchoolBook": False,
        "skillCard": {
            "skill": "Drawing and reading a straight-line graph from its equation",
            "sheCan": {
                "prompt": "With no calculator: give the gradient of y = 3x − 2 and where it crosses the y-axis. "
                          "Find the equation of the line through (1, 5) and (3, 9). Where does y = 2x + 5 cross the x-axis?",
                "answer": "Gradient 3, crossing the y-axis at (0, −2). y = 2x + 3. At (−2.5, 0).",
            },
            "whyItMatters": "A straight line is the picture of a steady rate: a fare per kilometre, a speed, a price per kilo. "
                            "Reading its steepness and its starting point answers questions without working out every value.",
            "standsOn": [
                "Chapter 6: the nth term of a sequence that goes up in equal steps",
                "Chapter 5: solving an equation and turning a formula round",
                "Negative numbers on a number line",
            ],
            "unlocks": [
                "Solving two equations at once by finding where their lines cross",
                "Speed, rates and unit prices read from a graph",
                "Curved graphs such as y = x² in later chapters",
            ],
        },
        "intuitionToFormula": {
            "concreteAction": "Set the gradient to 2, where the line crosses the y-axis to 1 and the step across to 1. "
                              "The blue line passes through (0, 1), and the step under it goes 1 across and 2 up.",
            "ahaInvariant": "Change the step across to 2 or 3. The rise grows with it, 4 up and then 6 up, "
                            "so the rise divided by the run stays 2 wherever you draw the step.",
            "formulaDisplay": "y = mx + c,   gradient m = change in y ÷ change in x",
            "termMappings": [
                {"symbol": "the rise", "visualPart": "The red side of the step", "colorRole": "red",
                 "meaning": "How far the line climbs over the dark step across"},
                {"symbol": "y = mx + c", "visualPart": "The blue line", "colorRole": "blue",
                 "meaning": "Every point whose y is m times its x, plus c"},
                {"symbol": "(0, c)", "visualPart": "The green dot", "colorRole": "green",
                 "meaning": "Where the line crosses the y-axis"},
                {"symbol": "y = 0", "visualPart": "The amber line of text", "colorRole": "amber",
                 "meaning": "Where the line crosses the x-axis"},
            ],
            "atlasFigureRef": "maths/ch07-functions-graphs/index.html",
        },
        "sections": [
            {
                "heading": "7.1 Machines that follow a rule",
                "teaches": ["function-machine", "inverse-function"],
                "steps": [
                    {"kind": "question",
                     "text": "Kym feeds 4 into a number machine and 11 comes out. Feeding in 5 gives 13, and 10 gives 23. "
                             "What does the machine do? What went in if 31 came out?"},
                    {"kind": "idea",
                     "text": "Each extra 1 going in adds 2 coming out, so the machine doubles. 4 doubled is 8, and 11 is 3 more, "
                             "so it doubles, then adds 3. To get back from 31, take 3 to get 28, then halve to get 14."},
                    {"kind": "picture",
                     "text": "Draw two boxes in a row: in, then × 2, then + 3, then out. "
                             "Under them, draw the same two boxes with the arrows pointing back: − 3, then ÷ 2."},
                    {"kind": "reason",
                     "text": "Why undo the steps in reverse order? The + 3 happened last, so it is the first thing to take off, "
                             "the way you take off your shoes before your socks."},
                    {"kind": "name",
                     "text": "A rule that turns each input into exactly one output is called a function. "
                             "A row of boxes showing its steps is a function machine, and we write the rule as f(x) = 2x + 3. "
                             "Run backwards, each step undone in reverse order, it is the inverse function, f⁻¹(x) = (x − 3) ÷ 2. "
                             "Say f⁻¹ as \"f inverse\". The small −1 is a label here, not a power."},
                    {"kind": "example",
                     "text": "Take f(x) = 5x − 4. Then f(3) = 5 × 3 − 4 = 11. "
                             "The inverse adds 4, then divides by 5, so f⁻¹(x) = (x + 4) ÷ 5, and f⁻¹(11) = 15 ÷ 5 = 3."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to undo the steps in the same order: halve first, then take 3. "
                             "For 31 that gives 15.5 − 3 = 12.5, and 2 × 12.5 + 3 = 28, not 31."},
                    {"kind": "turn",
                     "text": "f(x) = 3x − 7. What is f⁻¹(8)?",
                     "answer": "5",
                     "answerKey": k.one(k.num("5"), accepts=["5", "= 5", "f⁻¹(8) = 5"], rejects=["17", "15", "1"])},
                    {"kind": "sayBack",
                     "text": "A function machine follows its steps in order, and its inverse undoes them in reverse order."},
                ],
            },
            {
                "heading": "7.2 Points on a grid",
                "teaches": ["coordinates"],
                "steps": [
                    {"kind": "question",
                     "text": "The taxi costs ₹50 to start and ₹20 for each kilometre. Make a table of the fares for 0, 1, 2, 3 and 4 km. "
                             "Then mark each pair of numbers as a dot on squared paper. What shape do the dots make?"},
                    {"kind": "idea",
                     "text": "The fares are 50, 70, 90, 110 and 130. For each pair, go across by the kilometres and up by the fare, and put a dot. "
                             "Each dot is 1 across and 20 up from the one before, so the dots sit in a straight row."},
                    {"kind": "picture",
                     "text": "Draw a line across the page for the kilometres, 0 to 4, and a line up the side for the fare, 0 to 140 in steps of 20. "
                             "Put dots at 0 and 50, 1 and 70, 2 and 90, 3 and 110, and 4 and 130, then lay a ruler along them."},
                    {"kind": "reason",
                     "text": "Why a straight row? Each extra kilometre adds the same ₹20. "
                             "Equal steps across give equal steps up, like the arithmetic sequences of chapter 6."},
                    {"kind": "name",
                     "text": "The line across is the x-axis and the line up is the y-axis. They meet at the origin, (0, 0). "
                             "A point is named by its coordinates (x, y): how far across, then how far up. "
                             "The taxi's dots are (0, 50), (1, 70), (2, 90), (3, 110) and (4, 130)."},
                    {"kind": "example",
                     "text": "The point (3, −2) is 3 to the right of the origin and 2 down. "
                             "The point (−4, 1) is 4 to the left and 1 up. The x-coordinate always comes first."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to swap the numbers and put (2, 5) at 2 up and 5 across. "
                             "Across comes first, in the same way that x comes before y in the alphabet."},
                    {"kind": "turn",
                     "text": "Another taxi charges ₹30 to start and ₹15 for each kilometre. "
                             "What is the y-coordinate of its point for 4 km?",
                     "answer": "90",
                     "answerKey": k.one(k.num("90"), accepts=["90", "y = 90", "(4, 90)"], rejects=["60", "120", "4"])},
                    {"kind": "sayBack",
                     "text": "Coordinates (x, y) say how far across, then how far up."},
                ],
            },
            {
                "heading": "7.3 How steep?",
                "teaches": ["gradient"],
                "steps": [
                    {"kind": "question",
                     "text": "For 0, 1 and 2 km, one taxi's fares are 50, 70 and 90, and another's are 50, 80 and 110. "
                             "Draw both rows of dots. Which row is steeper, and by how much?"},
                    {"kind": "idea",
                     "text": "The first row goes up 20 for each 1 across. The second goes up 30 for each 1 across. "
                             "So the second is steeper: it climbs ₹30 for every kilometre instead of ₹20."},
                    {"kind": "picture",
                     "text": "On the first row, draw a step from (1, 70) to (3, 110): 2 across, then 40 up. "
                             "The step and the line make a right-angled triangle."},
                    {"kind": "reason",
                     "text": "Why divide the rise by the run? A wider step has a bigger rise as well. "
                             "40 up for 2 across is as steep as 20 up for 1 across, and dividing gives 20 both times."},
                    {"kind": "name",
                     "text": "Divide the rise by the run to get the gradient of the line. "
                             "Gradient = change in y ÷ change in x. A line that goes down from left to right has a negative gradient."},
                    {"kind": "example",
                     "text": "Between (−2, 1) and (4, 13), the change in y is 13 − 1 = 12 and the change in x is 4 − (−2) = 6. "
                             "The gradient is 12 ÷ 6 = 2."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to divide the run by the rise: 6 ÷ 12 = 0.5. "
                             "Another is to subtract the y values one way round and the x values the other way, which flips the sign. "
                             "Start from the same point both times."},
                    {"kind": "turn",
                     "text": "What is the gradient of the line through (1, 9) and (4, 3)?",
                     "answer": "−2",
                     "answerKey": k.one(k.num("-2"), accepts=["−2", "-2", "m = −2"], rejects=["2", "−0.5", "-0.5"])},
                    {"kind": "sayBack",
                     "text": "The gradient is the rise divided by the run, and it is negative when the line goes down."},
                ],
            },
            {
                "heading": "7.4 Reading a line's equation",
                "figure": True,
                "teaches": ["intercept", "linear-graph"],
                "steps": [
                    {"kind": "question",
                     "text": "The taxi costs ₹50 to start and ₹20 a kilometre. Write the fare y for x kilometres. "
                             "Where does its line cross the y-axis, and what is its gradient?"},
                    {"kind": "idea",
                     "text": "The fare is y = 20x + 50. At x = 0 it is 50, so the line crosses the y-axis at (0, 50). "
                             "It climbs 20 for each kilometre, so its gradient is 20. Both numbers sit in the rule."},
                    {"kind": "picture",
                     "text": "In the figure, set the gradient to 2, where the line crosses the y-axis to 1 and the step across to 1. "
                             "The green dot is at (0, 1), and the step goes 1 across and 2 up."},
                    {"kind": "reason",
                     "text": "Why is the number in front of x the gradient? Each time x goes up by 1, y goes up by that number. "
                             "The number on its own is the value of y when x is 0, which is where the line meets the y-axis."},
                    {"kind": "name",
                     "text": "Any rule y = mx + c draws a straight line, called a straight-line graph or a linear graph. "
                             "m is its gradient. The point (0, c), where it crosses the y-axis, is the y-intercept. "
                             "The point where it crosses the x-axis, where y = 0, is the x-intercept."},
                    {"kind": "example",
                     "text": "y = 2x + 5 has gradient 2 and y-intercept (0, 5). For the x-intercept, set y = 0. "
                             "Then 2x + 5 = 0, so 2x = −5 and x = −2.5. The line crosses the x-axis at (−2.5, 0)."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to read the gradient of y = 7 − 3x as 7, because it comes first. "
                             "Write it as y = −3x + 7. The gradient is −3 and the y-intercept is (0, 7)."},
                    {"kind": "turn",
                     "text": "Where does y = 4x − 12 cross the x-axis? Give the value of x.",
                     "answer": "3",
                     "answerKey": k.one(k.num("3"), accepts=["3", "x = 3", "(3, 0)"], rejects=["−12", "-12", "12", "−3"])},
                    {"kind": "sayBack",
                     "text": "In y = mx + c, m is the gradient and c is where the line crosses the y-axis."},
                ],
            },
            {
                "heading": "7.5 Lines that never meet",
                "teaches": ["parallel-lines"],
                "steps": [
                    {"kind": "question",
                     "text": "Two taxi firms both charge ₹20 a kilometre. One charges ₹50 to start and the other ₹80. "
                             "Draw both lines. Will they ever meet?"},
                    {"kind": "idea",
                     "text": "At every distance the second fare is ₹30 more: 80 against 50, 100 against 70, 120 against 90. "
                             "The gap never closes, so the lines never meet."},
                    {"kind": "picture",
                     "text": "Draw y = 20x + 50 and y = 20x + 80 on the same axes. "
                             "The second line is the first one slid 30 straight up."},
                    {"kind": "reason",
                     "text": "Why do they never meet? Both climb 20 for each 1 across, "
                             "so the gap between them stays 30 however far you go."},
                    {"kind": "name",
                     "text": "Lines that never meet are parallel lines. Two straight lines are parallel when they have the same gradient. "
                             "Lines that cross at a right angle are perpendicular, and multiplying their gradients gives −1. "
                             "For example, y = 2x and y = −½x cross at a right angle, and 2 × −½ = −1."},
                    {"kind": "example",
                     "text": "Find the line parallel to y = 3x − 1 through (2, 11). It has gradient 3, so it is y = 3x + c. "
                             "Put in x = 2 and y = 11: 11 = 6 + c, so c = 5. The line is y = 3x + 5."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to think y = 2x + 1 and y = x + 2 are parallel because they use the same numbers. "
                             "Their gradients are 2 and 1, so they cross, at (1, 3)."},
                    {"kind": "turn",
                     "text": "Which line is parallel to y = 5x + 2: y = 2x + 5, y = 5x − 3 or y = −5x + 2?",
                     "answer": "y = 5x − 3",
                     "answerKey": k.one(k.forms("y=5x-3", "y=-3+5x"), accepts=["y = 5x − 3", "y = 5x - 3", "y=5x-3"],
                                        rejects=["y = 2x + 5", "y = −5x + 2", "y = 5x + 2"])},
                    {"kind": "sayBack",
                     "text": "Parallel lines have the same gradient and cross the y-axis at different places."},
                ],
            },
            {
                "heading": "7.6 The story of a journey",
                "teaches": ["real-life-graph"],
                "steps": [
                    {"kind": "question",
                     "text": "Kym cycles 12 km to a friend's house in 1 hour, stays for 1 hour, then rides home in 2 hours. "
                             "Mark the distance from home against the time. Which part of the trip was fastest?"},
                    {"kind": "idea",
                     "text": "Going, Kym covers 12 km in 1 hour, which is 12 km an hour. Coming home, 12 km takes 2 hours, which is 6 km an hour. "
                             "During the visit, time passes but the distance stays 12 km."},
                    {"kind": "picture",
                     "text": "Put the time in hours along the x-axis, 0 to 4, and the distance from home up the y-axis, 0 to 12 km. "
                             "Join (0, 0) to (1, 12), then (1, 12) to (2, 12), then (2, 12) to (4, 0)."},
                    {"kind": "reason",
                     "text": "Why is the steepest part the fastest? Its gradient is distance ÷ time, which is the speed. "
                             "The flat part has gradient 0, so Kym is not moving."},
                    {"kind": "name",
                     "text": "A graph of a real situation, like a taxi fare or a trip, is a real-life graph. "
                             "On a distance-time graph the gradient is the speed, and a line sloping down means heading back towards the start."},
                    {"kind": "example",
                     "text": "A bus goes 30 km in the first half hour, then 30 km in the next hour. "
                             "Its speeds are 30 ÷ 0.5 = 60 km an hour, then 30 ÷ 1 = 30 km an hour. The first part of its line is twice as steep."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to read the line going down as Kym riding downhill. "
                             "It shows the distance from home shrinking, so Kym is riding home."},
                    {"kind": "turn",
                     "text": "On a distance-time graph, a runner's line goes from (0, 0) to (2, 18), with time in hours and distance in km. "
                             "What is the runner's speed in km an hour?",
                     "answer": "9",
                     "answerKey": k.one(k.num("9"), accepts=["9", "9 km an hour", "9 km/h"], rejects=["18", "36", "2"])},
                    {"kind": "sayBack",
                     "text": "On a distance-time graph the gradient is the speed, and a flat line means standing still."},
                ],
            },
        ],
        "callouts": [
            {"kind": "predict", "title": "Predict first",
             "body": "Predict where y = −2x + 3 crosses the x-axis. "
                     "Then set the gradient to −2 and where it crosses the y-axis to 3, and read the amber line."},
            {"kind": "check", "title": "Explain it",
             "body": "The machine \"multiply by 2, then add 3\" turns 4 into 11. "
                     "Explain to a friend how to run it backwards from 11 to get 4 again."},
            {"kind": "careful", "title": "Last step first",
             "body": "To run a function machine backwards, undo its last step first. "
                     "For multiply by 2, then add 3, take away 3 before you halve."},
        ],
        "debate": {
            "id": "debate-ch07-graphs",
            "oupUnitNumber": 14,
            "title": "Which number is the gradient?",
            "contextPrompt": "Arjun and Zara look at the line y = 6 − 2x and argue about its gradient.",
            "speakerAName": "Arjun",
            "speakerAClaim": "The gradient is the first number, so it is 6.",
            "speakerBName": "Zara",
            "speakerBClaim": "The gradient is the number in front of x, so it is −2.",
            "choices": [
                {"id": "ch07-a", "speakerLabel": "Arjun is right (6)",
                 "reasoningStatement": "The gradient is always the first number in the equation.",
                 "isCorrect": False,
                 "socraticRebuttal": "Work out y when x = 0 and when x = 1. How much did y change for that one step across?"},
                {"id": "ch07-b", "speakerLabel": "Zara is right (−2)",
                 "reasoningStatement": "The gradient is the number multiplying x, sign and all.",
                 "isCorrect": True,
                 "socraticRebuttal": "Yes. Written as y = −2x + 6, the line falls 2 for every 1 across, "
                                     "and it crosses the y-axis at (0, 6)."},
                {"id": "ch07-c", "speakerLabel": "Neither. It is 2.",
                 "reasoningStatement": "Steepness is a size, so it cannot be negative.",
                 "isCorrect": False,
                 "socraticRebuttal": "Is y going up or down as x goes up? What sign tells you which way the line slopes?"},
            ],
            "invariantTakeaway": "The gradient is the number multiplying x, with its sign. Rewrite the rule as y = mx + c before you read it.",
        },
        "keyTerms": ["Function machine", "Inverse function", "Coordinates", "Gradient", "Intercept", "Straight-line graph",
                     "Parallel lines", "Real-life graph"],
        "widgets": ["w_linear_graph_slope_explorer", "w_kinematics_travel_graph"],
        "widgetText": {
            "w_linear_graph_slope_explorer": {
                "title": "Rise over run stays the same",
                "challengePrompt": "Set the gradient to 3 and where the line crosses the y-axis to −2. "
                                   "Predict where it crosses the x-axis before you read the amber line.",
                "cutaway": "y = 3x − 2 crosses the y-axis at (0, −2). Setting y = 0 gives 3x = 2, so it crosses the x-axis at x = 2 ÷ 3.",
                "idealised": "The rule: y = mx + c, with gradient m = change in y ÷ change in x",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Set the gradient to 1, where the line crosses the y-axis to 0 and the step across to 1."},
                    {"title": "2. Notice", "caption": "Change the step across to 3. The rise becomes 3 too, so the gradient is still 1."},
                    {"title": "3. Match the rule", "caption": "Set the gradient to −1. The line now falls 1 for every 1 across."},
                    {"title": "4. Push it further", "caption": "Set the gradient to 0. Where does the flat line cross the x-axis?"},
                    {"title": "5. Draw it", "caption": "Draw y = 2x + 1 and y = 2x − 3 on the same axes in your journal. Do they meet?"},
                ],
            },
            "w_kinematics_travel_graph": {
                "title": "Reading a journey",
                "challengePrompt": "Kym rides 12 km in 1 hour, rests for 1 hour, then rides home in 2 hours. "
                                   "Predict which part of the line is steepest.",
                "cutaway": "The ride out climbs 12 in 1 hour, so its gradient is 12. The ride home falls 12 in 2 hours, a gradient of −6.",
                "idealised": "The rule: on a distance-time graph, speed = distance ÷ time = the gradient",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Mark the points (0, 0), (1, 12), (2, 12) and (4, 0), and join them."},
                    {"title": "2. Notice", "caption": "The flat part is the rest stop. Time passes, but the distance does not change."},
                    {"title": "3. Match the rule", "caption": "The first part rises 12 in 1 hour, which is a speed of 12 km an hour."},
                    {"title": "4. Push it further", "caption": "If the ride home took 3 hours, would its line be steeper or less steep?"},
                    {"title": "5. Draw it", "caption": "Draw the line of your own trip to school and back, and find each speed."},
                ],
            },
        },
        "atlasLessons": [
            {
                "title": "Chapter 7 · Rise over run",
                "question": "Why does the gradient of a straight line not depend on where you measure it?",
                "explanation": "Any step under a straight line makes a triangle of the same shape. "
                               "A step twice as wide rises twice as far, so the rise divided by the run never changes.",
                "limits": "The rule: gradient = change in y ÷ change in x",
            },
            {
                "title": "Chapter 7 · Reading y = mx + c",
                "question": "How can you see a line's steepness and its starting point in its equation?",
                "explanation": "Put x = 0 and y is c, so the line crosses the y-axis at (0, c). "
                               "Each step of 1 across adds m to y, so m is the gradient.",
                "limits": "The rule: y = mx + c",
            },
            {
                "title": "Chapter 7 · Speed is a gradient",
                "question": "On a distance-time graph, why does a steeper line mean a faster trip?",
                "explanation": "The gradient is the distance covered divided by the time taken, which is the speed. "
                               "A flat line covers no distance, so it means standing still.",
                "limits": "The rule: speed = distance ÷ time",
            },
        ],
        "visualMathTips": {},
        "schoolTopics": {
            "14.1": "A function machine follows a rule step by step, like f(x) = 2x + 3. "
                    "Its inverse undoes the steps in reverse order, so f⁻¹(x) = (x − 3) ÷ 2.",
            "14.2": "The line y = mx + c has gradient m, the change in y divided by the change in x, and crosses the y-axis at (0, c). "
                    "Parallel lines have the same gradient. Perpendicular gradients multiply to −1. "
                    "Two lines meet at the point that fits both equations.",
            "14.3": "A real-life graph shows a steady rate as a straight line. "
                    "On a distance-time graph the gradient is the speed, and a flat part means standing still.",
        },
        "schoolQuestions": {
            "q-oup-ch14-sb": {
                "workedExample": "Step 1: The gradient is (13 − 1) ÷ (4 − (−2)) = 12 ÷ 6 = 2.\n"
                                 "Step 2: So the line is y = 2x + c. Put in (4, 13): 13 = 8 + c, so c = 5 and y = 2x + 5.\n"
                                 "Step 3: Check with (−2, 1): 2 × (−2) + 5 = 1.\n"
                                 "Step 4: For the x-intercept, set y = 0. 2x + 5 = 0, so x = −2.5.",
                "fadedPrompt": "The line is y = 2x + 5. Setting y = 0 gives 2x = −5, so x = ___.",
            },
            "q-oup-ch14-wb-focus": {
                "workedExample": "Step 1: The machine for f(x) = 3x − 7 multiplies by 3, then takes 7.\n"
                                 "Step 2: Undo the steps in reverse order: first add 7, then divide by 3.\n"
                                 "Step 3: So f⁻¹(x) = (x + 7) ÷ 3.\n"
                                 "Step 4: Check: f(4) = 5, and f⁻¹(5) = 12 ÷ 3 = 4.",
                "fadedPrompt": "f(x) = 3x − 7 multiplies by 3, then takes 7. So f⁻¹(x) = (x + ___) ÷ 3.",
            },
            "q-oup-ch14-wb-practice": {
                "workedExample": "Step 1: y = 2x + 5 has gradient 2.\n"
                                 "Step 2: A perpendicular gradient multiplies with 2 to give −1, so it is −½.\n"
                                 "Step 3: The line passes through (0, 3), so it crosses the y-axis at 3.\n"
                                 "Step 4: The line is y = −½x + 3. Check: 2 × (−½) = −1.",
                "fadedPrompt": "2 × m = −1 gives m = −½, and the line crosses the y-axis at 3, so y = ___x + 3.",
            },
            "q-oup-ch14-wb-challenge": {
                "workedExample": "Step 1: Put y = 3x − 2 into x + 2y = 10. x + 2(3x − 2) = 10.\n"
                                 "Step 2: Expand the brackets. x + 6x − 4 = 10, so 7x = 14 and x = 2.\n"
                                 "Step 3: Then y = 3 × 2 − 2 = 4.\n"
                                 "Step 4: The lines meet at (2, 4). Check: 2 + 2 × 4 = 10.",
                "fadedPrompt": "7x = 14 gives x = 2, and y = 3 × 2 − 2 = ___, so the lines meet at (2, ___).",
            },
        },
    }


def cards(k):
    """The concept cards this chapter teaches."""
    return {
        "function-machine": {
            "name": "Function machine",
            "aliases": ["function machine", "function machines"],
            "oneSentence": "A row of steps that turns each input number into exactly one output.",
            "picture": "Two boxes joined by arrows: a number goes in, is multiplied by 2, has 3 added, and comes out.",
            "steps": [
                "Put the input into the first box.",
                "Do each box's step in order.",
                "Read the output at the end.",
            ],
            "workedExample": "For the machine × 4 then − 1, an input of 6 gives 6 × 4 = 24, then 24 − 1 = 23.",
            "check": {
                "prompt": "A machine adds 5, then multiplies by 2. What comes out when 3 goes in?",
                "answer": "16",
                "answerKey": k.one(k.num("16"), accepts=["16", "= 16", "the output is 16"], rejects=["11", "13", "10"]),
            },
            "mixUp": {
                "name": "doing the steps in any order",
                "how": "Add 5 then double turns 3 into 16. Double then add 5 turns 3 into 11. The order of the boxes matters.",
            },
            "standsOn": ["expression", "substitution"],
        },
        "inverse-function": {
            "name": "Inverse function",
            "aliases": ["inverse function", "inverse functions"],
            "oneSentence": "The rule that undoes a function, taking each output back to the input it came from.",
            "picture": "A function machine with its arrows turned round, and each box swapped for its opposite step.",
            "steps": [
                "List the steps of the function in order.",
                "Swap each step for its inverse operation.",
                "Do them in reverse order.",
            ],
            "workedExample": "f(x) = 4x + 1 multiplies by 4, then adds 1. "
                             "The inverse takes 1, then divides by 4: f⁻¹(x) = (x − 1) ÷ 4, and f⁻¹(9) = 2.",
            "check": {
                "prompt": "f(x) = 2x + 6. What is f⁻¹(20)?",
                "answer": "7",
                "answerKey": k.one(k.num("7"), accepts=["7", "= 7", "f⁻¹(20) = 7"], rejects=["46", "4", "13"]),
            },
            "mixUp": {
                "name": "undoing in the same order",
                "how": "For f(x) = 2x + 6, halving first and then taking 6 turns 20 into 4, which is wrong. Take 6 first, then halve, to get 7.",
            },
            "standsOn": ["function-machine", "inverse-operation"],
        },
        "coordinates": {
            "name": "Coordinates",
            "aliases": ["coordinates", "x-coordinate", "x-coordinates", "y-coordinate", "y-coordinates"],
            "oneSentence": "A pair of numbers (x, y) that says where a point is: how far across, then how far up.",
            "picture": "Squared paper with an x-axis across and a y-axis up, and a dot at (3, 2), 3 across and 2 up.",
            "steps": [
                "Start at the origin, (0, 0).",
                "Move across by the x-coordinate, right if it is positive and left if it is negative.",
                "Move up by the y-coordinate, or down if it is negative.",
            ],
            "workedExample": "To reach (−2, 5), go 2 to the left of the origin, then 5 up.",
            "check": {
                "prompt": "Kym starts at (1, 4), moves 3 to the right and 6 down. What are the coordinates of the new point?",
                "answer": "(4, −2)",
                "answerKey": k.one(k.seq("4", "-2"), accepts=["(4, −2)", "(4, -2)", "4, −2"],
                                   rejects=["(−2, 4)", "(4, 10)", "(−2, 10)"]),
            },
            "mixUp": {
                "name": "swapping x and y",
                "how": "(2, 5) is 2 across and 5 up. (5, 2) is 5 across and 2 up, a different point.",
            },
            "standsOn": ["negative-number"],
        },
        "gradient": {
            "name": "Gradient",
            "aliases": ["gradient", "gradients"],
            "oneSentence": "How steep a line is: the change in y divided by the change in x.",
            "picture": "A step drawn under a line, 2 across and 6 up, so the gradient is 6 ÷ 2 = 3.",
            "steps": [
                "Pick two points on the line.",
                "Find the change in y and the change in x, starting from the same point both times.",
                "Divide the change in y by the change in x.",
            ],
            "workedExample": "From (2, 3) to (6, 11), the change in y is 8 and the change in x is 4, so the gradient is 8 ÷ 4 = 2.",
            "check": {
                "prompt": "What is the gradient of the line through (0, 7) and (2, 1)?",
                "answer": "−3",
                "answerKey": k.one(k.num("-3"), accepts=["−3", "-3", "m = −3"], rejects=["3", "−⅓", "4"]),
            },
            "mixUp": {
                "name": "run over rise",
                "how": "Gradient is rise over run. A line 2 across and 6 up has gradient 3, not ⅓.",
            },
            "standsOn": ["coordinates", "negative-number"],
        },
        "intercept": {
            "name": "Intercept",
            "aliases": ["y-intercept", "y-intercepts", "x-intercept", "x-intercepts"],
            "oneSentence": "A point where a line crosses an axis: the y-intercept is where x = 0 and the x-intercept is where y = 0.",
            "picture": "The line y = 2x − 4 crossing the y-axis at (0, −4) and the x-axis at (2, 0).",
            "steps": [
                "For the y-intercept, put x = 0 into the equation.",
                "For the x-intercept, put y = 0 and solve for x.",
                "Write each one as a point.",
            ],
            "workedExample": "For y = 3x + 6, x = 0 gives y = 6, so the y-intercept is (0, 6). "
                             "y = 0 gives 3x = −6, so the x-intercept is (−2, 0).",
            "check": {
                "prompt": "Where does y = 5x − 10 cross the x-axis? Give the value of x.",
                "answer": "2",
                "answerKey": k.one(k.num("2"), accepts=["2", "x = 2", "(2, 0)"], rejects=["−10", "-10", "10", "−2"]),
            },
            "mixUp": {
                "name": "mixing up the axes",
                "how": "The y-intercept sits on the y-axis, where x = 0. The x-intercept sits on the x-axis, where y = 0.",
            },
            "standsOn": ["coordinates", "solving-equations"],
        },
        "linear-graph": {
            "name": "Straight-line graph",
            "aliases": ["straight-line graph", "straight-line graphs", "linear graph", "linear graphs"],
            "oneSentence": "The line drawn by a rule y = mx + c, where m is the gradient and c is where it crosses the y-axis.",
            "picture": "The taxi fares 50, 70, 90, 110 drawn as dots that a ruler joins into one straight line.",
            "steps": [
                "Rewrite the rule as y = mx + c if it is not already.",
                "Mark the point (0, c) on the y-axis.",
                "From there, go 1 across and m up, and mark a second point.",
                "Join the points with a ruler.",
            ],
            "workedExample": "y = 10 − 2x is y = −2x + 10. Mark (0, 10), then go 1 across and 2 down to (1, 8), and join them.",
            "check": {
                "prompt": "What is the gradient of y = 8 − 4x?",
                "answer": "−4",
                "answerKey": k.one(k.num("-4"), accepts=["−4", "-4", "m = −4"], rejects=["8", "4", "−8"]),
            },
            "mixUp": {
                "name": "the first number is the gradient",
                "how": "In y = 8 − 4x the first number, 8, is where the line crosses the y-axis. The gradient is −4, the number with x.",
            },
            "standsOn": ["gradient", "intercept", "substitution"],
        },
        "parallel-lines": {
            "name": "Parallel lines",
            "aliases": ["parallel lines", "parallel line", "parallel"],
            "oneSentence": "Lines that never meet. Straight lines are parallel when they have the same gradient.",
            "picture": "Railway tracks: two lines side by side, always the same distance apart.",
            "steps": [
                "Write each line as y = mx + c.",
                "Compare the gradients m.",
                "Equal gradients and different values of c mean parallel lines.",
            ],
            "workedExample": "y = 4x + 1 and y = 4x − 6 both have gradient 4, so they are parallel. y = 4x + 1 and y = x + 4 are not.",
            "check": {
                "prompt": "A line is parallel to y = 2x + 7 and passes through (0, −1). What is its equation?",
                "answer": "y = 2x − 1",
                "answerKey": k.one(k.forms("y=2x-1", "y=-1+2x"), accepts=["y = 2x − 1", "y = 2x - 1", "y=2x-1"],
                                   rejects=["y = 2x + 7", "y = −x + 7", "y = 7x − 1"]),
            },
            "mixUp": {
                "name": "perpendicular lines",
                "how": "Parallel lines have equal gradients. Perpendicular lines cross at a right angle, and their gradients multiply to −1.",
            },
            "standsOn": ["gradient", "linear-graph"],
        },
        "real-life-graph": {
            "name": "Real-life graph",
            "aliases": ["real-life graph", "real-life graphs", "distance-time graph", "distance-time graphs",
                        "travel graph", "travel graphs"],
            "oneSentence": "A graph of a real situation, where the gradient is a rate such as a speed or a price per kilometre.",
            "picture": "A trip drawn as distance from home against time: up for going out, flat for a stop, down for coming home.",
            "steps": [
                "Read what each axis measures, with its units.",
                "Find the gradient of each straight part.",
                "Say what that gradient means, such as km an hour or rupees per kilometre.",
            ],
            "workedExample": "A walker's line goes from (0, 0) to (3, 15), time in hours and distance in km. "
                             "The gradient is 15 ÷ 3 = 5, so the speed is 5 km an hour.",
            "check": {
                "prompt": "A car's distance-time line goes from (0, 0) to (2, 150), in hours and km. What is its speed in km an hour?",
                "answer": "75",
                "answerKey": k.one(k.num("75"), accepts=["75", "75 km an hour", "75 km/h"], rejects=["150", "300", "2"]),
            },
            "mixUp": {
                "name": "a picture of the road",
                "how": "A line going down does not mean a hill. On a distance-time graph it means getting closer to the start.",
            },
            "standsOn": ["gradient", "linear-graph"],
        },
    }


def sums():
    """Every sum chapter 7, its cards and its school unit text state, recomputed. test_book_maths.py checks computed == stated."""
    fare = line(20, 50)
    return [
        ("perpendicular gradients 2 and −½", 2 * Fraction(-1, 2), -1),
        # Skill card
        ("y = 3x − 2", (line(3, -2)(1) - line(3, -2)(0), line(3, -2)(0)), (3, -2)),
        ("the line through (1, 5) and (3, 9)", (gradient((1, 5), (3, 9)), 5 - 2 * 1, line(2, 3)(3)), (2, 3, 9)),
        ("y = 2x + 5 crosses the x-axis", crosses_x_axis(2, 5), Fraction("-2.5")),
        # Hook, bridge and figure
        ("the taxi fares", [fare(x) for x in range(5)], [50, 70, 90, 110, 130]),
        ("the figure's line y = 2x + 1", (line(2, 1)(0), line(2, 1)(1) - line(2, 1)(0)), (1, 2)),
        ("wider steps", [2 * dx for dx in (1, 2, 3)], [2, 4, 6]),
        ("the callout machine run both ways", (2 * 4 + 3, (11 - 3) / 2), (11, 4)),
        # 7.1 Machines that follow a rule
        ("the machine 2x + 3", [line(2, 3)(x) for x in (4, 5, 10, 14)], [11, 13, 23, 31]),
        ("4 doubled", (4 * 2, 11 - 8, 31 - 3, 28 // 2), (8, 3, 28, 14)),
        ("f(x) = 5x − 4", (line(5, -4)(3), Fraction(11 + 4, 5), 11 + 4), (11, 3, 15)),
        ("the slip of undoing in order", (Fraction(31, 2) - 3, 2 * Fraction("12.5") + 3), (Fraction("12.5"), 28)),
        ("f⁻¹(8) for 3x − 7", (Fraction(8 + 7, 3), 3 * 8 - 7, 8 + 7, Fraction(8 - 7, 3) * 3), (5, 17, 15, 1)),
        # 7.2 Points on a grid
        ("1 across and 20 up", [fare(x + 1) - fare(x) for x in range(4)], [20, 20, 20, 20]),
        ("the other taxi at 4 km", (line(15, 30)(4), 15 * 4, 30 * 4), (90, 60, 120)),
        # 7.3 How steep?
        ("the two rows of fares", ([fare(x) for x in range(3)], [line(30, 50)(x) for x in range(3)]), ([50, 70, 90], [50, 80, 110])),
        ("the step from (1, 70) to (3, 110)", (3 - 1, 110 - 70, gradient((1, 70), (3, 110)), fare(1), fare(3)), (2, 40, 20, 70, 110)),
        ("(−2, 1) to (4, 13)", (13 - 1, 4 - (-2), gradient((-2, 1), (4, 13)), Fraction(6, 12)), (12, 6, 2, Fraction("0.5"))),
        ("(1, 9) to (4, 3)", (gradient((1, 9), (4, 3)), gradient((1, 9), (4, 3)) * -1, Fraction(3, -6)), (-2, 2, Fraction("-0.5"))),
        # 7.4 Reading a line's equation
        ("the fare rule", (fare(0), fare(1) - fare(0)), (50, 20)),
        ("y = 2x + 5", (line(2, 5)(0), crosses_x_axis(2, 5), 0 - 5), (5, Fraction("-2.5"), -5)),
        ("y = 7 − 3x", (7 - 3 * 0, (7 - 3 * 1) - (7 - 3 * 0)), (7, -3)),
        ("y = 4x − 12", (crosses_x_axis(4, -12), line(4, -12)(3)), (3, 0)),
        # 7.5 Lines that never meet
        ("the gap of 30", [line(20, 80)(x) - fare(x) for x in range(3)], [30, 30, 30]),
        ("the two firms", ([line(20, 80)(x) for x in range(3)], [fare(x) for x in range(3)]), ([80, 100, 120], [50, 70, 90])),
        ("parallel through (2, 11)", (11 - 3 * 2, line(3, 5)(2)), (5, 11)),
        ("y = 2x + 1 and y = x + 2 meet", (line(2, 1)(1), line(1, 2)(1)), (3, 3)),
        ("perpendicular gradients", 2 * Fraction(-1, 2), -1),
        # 7.6 The story of a journey
        ("Kym's ride", (gradient((0, 0), (1, 12)), gradient((1, 12), (2, 12)), gradient((2, 12), (4, 0))), (12, 0, -6)),
        ("the bus", (Fraction(30) / Fraction("0.5"), Fraction(30, 1), Fraction(60, 30)), (60, 30, 2)),
        ("the runner", (gradient((0, 0), (2, 18)), 18 * 2), (9, 36)),
        # Callouts, widgets and lessons
        ("y = −2x + 3", crosses_x_axis(-2, 3), Fraction("1.5")),
        ("y = 3x − 2 crosses the x-axis", crosses_x_axis(3, -2), Fraction(2, 3)),
        ("a step of 3 at gradient 1", 1 * 3, 3),
        # Debate
        ("y = 6 − 2x", (6 - 2 * 0, (6 - 2 * 1) - (6 - 2 * 0)), (6, -2)),
        # Cards
        ("× 4 then − 1", (6 * 4, 6 * 4 - 1), (24, 23)),
        ("add 5 then double", ((3 + 5) * 2, 3 + 5, 3 * 2 + 5, 3 * 2 + 4), (16, 8, 11, 10)),
        ("f(x) = 4x + 1", (Fraction(9 - 1, 4), line(4, 1)(2)), (2, 9)),
        ("f⁻¹(20) for 2x + 6", (Fraction(20 - 6, 2), 2 * 20 + 6, Fraction(20, 2) - 6, Fraction(20 + 6, 2)), (7, 46, 4, 13)),
        ("(1, 4) moved", (1 + 3, 4 - 6, 4 + 6), (4, -2, 10)),
        ("a step 2 across and 6 up", Fraction(6, 2), 3),
        ("(2, 3) to (6, 11)", (11 - 3, 6 - 2, gradient((2, 3), (6, 11))), (8, 4, 2)),
        ("(0, 7) to (2, 1)", (gradient((0, 7), (2, 1)), 7 - 1 - 2), (-3, 4)),
        ("y = 2x − 4", (line(2, -4)(0), crosses_x_axis(2, -4)), (-4, 2)),
        ("y = 3x + 6", (line(3, 6)(0), crosses_x_axis(3, 6)), (6, -2)),
        ("y = 5x − 10", (crosses_x_axis(5, -10), crosses_x_axis(5, 10)), (2, -2)),
        ("y = 10 − 2x", (10 - 2 * 0, 10 - 2 * 1), (10, 8)),
        ("y = 8 − 4x", ((8 - 4 * 1) - (8 - 4 * 0), 8 - 4 * 0), (-4, 8)),
        ("y = 4x + 1 and y = x + 4", (line(4, 1)(1), line(1, 4)(1)), (5, 5)),
        ("parallel through (0, −1)", line(2, -1)(0), -1),
        ("the walker", gradient((0, 0), (3, 15)), 5),
        ("the car", (gradient((0, 0), (2, 150)), 150 * 2), (75, 300)),
        # School unit 14
        ("(−2, 1) and (4, 13) is y = 2x + 5", (gradient((-2, 1), (4, 13)), 13 - 2 * 4, line(2, 5)(-2), crosses_x_axis(2, 5)),
         (2, 5, 1, Fraction("-2.5"))),
        ("f(x) = 3x − 7 and its inverse", (line(3, -7)(4), Fraction(5 + 7, 3), 5 + 7), (5, 4, 12)),
        ("perpendicular to y = 2x + 5 through (0, 3)", (Fraction(-1, 2) * 2, line(Fraction(-1, 2), 3)(0)), (-1, 3)),
        ("y = 3x − 2 and x + 2y = 10", (2 + 2 * (3 * 2 - 2), 7 * 2 - 4, Fraction(14, 7), line(3, -2)(2), 2 + 2 * 4), (10, 10, 2, 4, 10)),
    ]


def answers():
    """Chapter 7's turn answers and its cards' check answers, computed."""
    return {
        "ch07-s1-turn": Fraction(8 + 7, 3),
        "ch07-s2-turn": line(15, 30)(4),
        "ch07-s3-turn": gradient((1, 9), (4, 3)),
        "ch07-s4-turn": crosses_x_axis(4, -12),
        "ch07-s5-turn": "y = 5x - 3",
        "ch07-s6-turn": gradient((0, 0), (2, 18)),
        "function-machine-check": (3 + 5) * 2,
        "inverse-function-check": Fraction(20 - 6, 2),
        "coordinates-check": f"({1 + 3}, {4 - 6})",
        "gradient-check": gradient((0, 7), (2, 1)),
        "intercept-check": crosses_x_axis(5, -10),
        "linear-graph-check": (8 - 4 * 1) - (8 - 4 * 0),
        "parallel-lines-check": "y = 2x - 1",
        "real-life-graph-check": gradient((0, 0), (2, 150)),
    }
