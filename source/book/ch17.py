"""
Chapter 17, written by hand to docs/CONTENT_BRIEF.md. No school unit teaches it, so it goes beyond the school book.

Each section teaches one idea in nine steps, in this order: question, idea, picture, reason, name,
example, mistake, turn, sayBack. A section's `teaches` lists the concept cards whose names first
appear in its `name` step. `build(k)` returns the chapter and `cards(k)` its concept cards; both take the
exporter's answer-key helpers.
"""

from book.arithmetic import Fraction


def secant_slope(f, x0, h):
    val = Fraction(f(x0 + h) - f(x0), h)
    return int(val) if val.denominator == 1 else float(val)


def build(k):
    return {
        "number": 17,
        "title": "Slopes of curves",
        "subtitle": "Beyond the school book · Zooming in until a curve looks straight, "
                    "sliding two points together, and finding where a curve levels out",
        "hookSummary": "A straight line has one gradient everywhere. "
                       "A ball thrown into the air slows down, stops at the top, and speeds up on the way down. "
                       "How do you measure the steepness of a curve at one single instant?",
        "beyondSchoolBook": True,
        "skillCard": {
            "skill": "Finding the slope of a curve at one point by shrinking the step h to zero, and locating peaks and valleys",
            "sheCan": {
                "prompt": "With no calculator: for the curve y = x³, what is the derivative dy/dx, and what is the slope of the curve at x = 2? "
                          "And for the parabola y = x² − 6x + 11, at what value of x is the curve momentarily flat?",
                "answer": "For y = x³, the power rule brings the 3 down and drops the power by 1: dy/dx = 3x². At x = 2, the slope is 3 × 2² = 12. "
                          "For y = x² − 6x + 11, the slope is dy/dx = 2x − 6, which equals 0 when x = 3.",
            },
            "whyItMatters": "Car speedometers, rockets climbing into orbit and businesses finding the best price all rely on the rate of change at one instant.",
            "standsOn": [
                "Chapter 4: expanding brackets such as (x + h)² = x² + 2xh + h²",
                "Chapter 7: the gradient of a straight line, rise divided by step across",
                "Chapter 10: the area of a square when its side grows by a thin strip",
            ],
            "unlocks": [
                "Chapter 18: areas under curves, which undo the slope step",
                "Physics: instantaneous velocity and acceleration from a position graph",
                "Optimization: finding the best dimensions of a box or container",
            ],
        },
        "intuitionToFormula": {
            "concreteAction": "In the figure, keep the red point at x = 1.25 and slide the step h from 0.45 down toward 0.05.",
            "ahaInvariant": "As the amber point slides closer to the red point, the amber line swings into the red line that touches the curve at x = 1.25. "
                            "Growing a square of side x by a thin strip h adds two strips of area x × h and a tiny corner h².",
            "formulaDisplay": "f′(x) = the limit as h → 0 of (f(x + h) − f(x)) ÷ h,   d/dx(xⁿ) = n xⁿ⁻¹",
            "termMappings": [
                {"symbol": "f(x + h) − f(x)", "visualPart": "The vertical rise between the red point and the amber point", "colorRole": "red",
                 "meaning": "How much the curve rises across the step h"},
                {"symbol": "h", "visualPart": "The horizontal step between the two points", "colorRole": "blue",
                 "meaning": "The step width that shrinks toward 0"},
                {"symbol": "2x + h → 2x", "visualPart": "Two long strips of length x plus a tiny corner h²", "colorRole": "green",
                 "meaning": "Why the derivative of x² is 2x once the corner h vanishes"},
            ],
            "atlasFigureRef": "maths/ch18-differential-calculus/index.html",
        },
        "sections": [
            {
                "heading": "17.1 Two points sliding together",
                "figure": True,
                "teaches": ["secant-line", "limit", "tangent-line"],
                "steps": [
                    {"kind": "question",
                     "text": "The gradient rule rise ÷ run needs two points, because dividing 0 ÷ 0 at one point makes no sense. "
                             "How can we find the slope of the parabola y = x² right at x = 3?"},
                    {"kind": "idea",
                     "text": "Pick a second point a small step h to the right, at x = 3 + h. "
                             "Work out rise ÷ run between them, and watch what number it settles onto as h shrinks toward 0."},
                    {"kind": "picture",
                     "text": "In the figure, watch the amber line through the two points on the curve as you slide the step h from 0.45 down to 0.05. "
                             "The amber slope gets closer and closer to the red slope at the first point."},
                    {"kind": "reason",
                     "text": "Why does the division work while h is not zero? "
                             "From x = 3 to x = 3 + h on y = x², the rise is (3 + h)² − 3² = 6h + h². "
                             "Dividing by h gives 6 + h, and as h shrinks toward 0, 6 + h settles onto 6."},
                    {"kind": "name",
                     "text": "A straight line cutting through two points on a curve is a secant line. "
                             "The value that an expression approaches as the step shrinks toward zero is the limit. "
                             "The line that touches the curve at one point with that exact limiting slope is the tangent line."},
                    {"kind": "example",
                     "text": "On y = x² between x = 3 and x = 3.1 (so h = 0.1), the secant line has slope (9.61 − 9) ÷ 0.1 = 6.1. "
                             "At h = 0.01 it is 6.01, and the limit as h approaches 0 gives a tangent line of slope 6."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to plug h = 0 in before simplifying, which gives 0 ÷ 0. "
                             "Expand and divide out h first to get 6 + h, then let h shrink to 0."},
                    {"kind": "turn",
                     "text": "On y = x², the secant line from x = 4 to x = 4 + h has slope 8 + h. "
                             "What is the slope of the tangent line at x = 4 as h shrinks to 0?",
                     "answer": "8",
                     "answerKey": k.one(k.num("8"), accepts=["8", "slope = 8"], rejects=["16", "4", "0"])},
                    {"kind": "sayBack",
                     "text": "A secant line joins two points step h apart; taking the limit as h shrinks to 0 turns it into the tangent line at one point."},
                ],
            },
            {
                "heading": "17.2 Speed at a single instant",
                "teaches": ["rate-of-change", "derivative"],
                "steps": [
                    {"kind": "question",
                     "text": "A stone dropped from a cliff falls y = 5t² metres in t seconds. "
                             "Between t = 1 and t = 3 it falls 40 metres in 2 seconds, an average of 20 m/s. "
                             "How fast is it falling at the exact instant t = 2 seconds?"},
                    {"kind": "idea",
                     "text": "20 m/s. Over a tiny step of h seconds from t = 2 to t = 2 + h, the distance fallen is 20h + 5h². "
                             "Dividing by h gives 20 + 5h, which approaches 20 m/s."},
                    {"kind": "picture",
                     "text": "Draw the curve y = 5t² rising more and more steeply, and draw the straight tangent line touching it at t = 2 with slope 20."},
                    {"kind": "reason",
                     "text": "Why does a car's speedometer match the slope of the tangent line? "
                             "A speedometer measures distance ÷ time over a tiny fraction of a second, which is the tangent slope at that moment."},
                    {"kind": "name",
                     "text": "How fast one quantity changes per unit of another at a single instant is the rate of change. "
                             "The rule or function that gives the tangent slope at any point x is the derivative, written f′(x) or dy/dx."},
                    {"kind": "example",
                     "text": "For y = 5t², the derivative is dy/dt = 10t. "
                             "At t = 1 s the stone falls at 10 m/s; at t = 2 s it falls at 20 m/s; at t = 3 s it falls at 30 m/s."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to divide total height by total time, y ÷ t, as if the graph were a straight line from (0, 0). "
                             "At t = 2 on y = 5t², y ÷ t gives 20 ÷ 2 = 10 m/s, which is only the average from t = 0 to t = 2, half the instantaneous speed of 20 m/s."},
                    {"kind": "turn",
                     "text": "A falling stone has height rule y = 5t² and derivative dy/dt = 10t. "
                             "What is its instantaneous speed in m/s at t = 4 seconds?",
                     "answer": "40",
                     "answerKey": k.one(k.num("40"), accepts=["40", "40 m/s"], rejects=["80", "20", "16"])},
                    {"kind": "sayBack",
                     "text": "The derivative dy/dx or f′(x) gives the instantaneous rate of change, the slope of the tangent line at x."},
                ],
            },
            {
                "heading": "17.3 Why a growing square has two long strips",
                "teaches": ["power-rule"],
                "steps": [
                    {"kind": "question",
                     "text": "A square tile has side x and area x². "
                             "If you widen the square by a thin strip h along its right edge and its top edge, how much new area do you add?"},
                    {"kind": "idea",
                     "text": "Two long strips, each of area x × h, plus one tiny corner square of area h². "
                             "Divide the new area 2xh + h² by the step h to get 2x + h, and let h shrink to 0: the derivative of x² is 2x."},
                    {"kind": "picture",
                     "text": "Draw a square of side x, and add a strip of width h along the right side and top. "
                             "Shade the tiny h × h square in the corner."},
                    {"kind": "reason",
                     "text": "What happens in 3D when a cube of side x and volume x³ grows by h? "
                             "It adds three square slabs of face area x² and thickness h, so the derivative of x³ is 3x²."},
                    {"kind": "name",
                     "text": "Bringing the exponent n down in front and reducing the exponent by 1 is the power rule. "
                             "The derivative of xⁿ is n xⁿ⁻¹."},
                    {"kind": "example",
                     "text": "By the power rule, the derivative of x⁴ is 4x³. "
                             "For y = 3x² + 5x − 7, the derivative is dy/dx = 3(2x) + 5(1) − 0 = 6x + 5, because a constant −7 does not change."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to bring the power down and forget to subtract 1 from the exponent, writing 3x³ for the derivative of x³. "
                             "Always drop the exponent by 1: x³ becomes 3x²."},
                    {"kind": "turn",
                     "text": "Use the power rule to find the derivative dy/dx of y = x³ at x = 2.",
                     "answer": "12",
                     "answerKey": k.one(k.num("12"), accepts=["12", "dy/dx = 12"], rejects=["8", "6", "24"])},
                    {"kind": "sayBack",
                     "text": "The power rule differentiates xⁿ to n xⁿ⁻¹, and a constant term differentiates to 0."},
                ],
            },
            {
                "heading": "17.4 Flat at the top of the flight",
                "teaches": ["stationary-point", "maximum-and-minimum"],
                "steps": [
                    {"kind": "question",
                     "text": "When you throw a cricket ball straight up, its slope is positive on the way up and negative on the way down. "
                             "What must its slope be at the exact peak of its flight?"},
                    {"kind": "idea",
                     "text": "Zero. To change from positive (rising) to negative (falling), a smooth slope must pass through 0 at the top, where the tangent line is horizontal."},
                    {"kind": "picture",
                     "text": "Draw a smooth hill and a smooth valley. "
                             "Lay a ruler flat across the top of the hill and the bottom of the valley."},
                    {"kind": "reason",
                     "text": "Why does setting dy/dx = 0 find the peak or the valley? "
                             "Everywhere else the curve is either still climbing (dy/dx > 0) or already dropping (dy/dx < 0)."},
                    {"kind": "name",
                     "text": "A point on a curve where the derivative dy/dx equals 0 is a stationary point. "
                             "A peak is a local maximum and a valley is a local minimum; together they are maximum and minimum points."},
                    {"kind": "example",
                     "text": "A ball's height is h(t) = 20t − 5t². Its derivative is dh/dt = 20 − 10t. "
                             "Setting 20 − 10t = 0 gives t = 2 seconds, and the peak height is h(2) = 20(2) − 5(4) = 20 metres."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to think dy/dx = 0 means the height y is 0. "
                             "At t = 2 s the slope is 0, while the ball is at its highest point, 20 metres in the air."},
                    {"kind": "turn",
                     "text": "For the parabola y = x² − 6x + 11, the derivative is dy/dx = 2x − 6. "
                             "At what value of x does the curve have its stationary point?",
                     "answer": "3",
                     "answerKey": k.one(k.num("3"), accepts=["3", "x = 3"], rejects=["6", "2", "11"])},
                    {"kind": "sayBack",
                     "text": "At a stationary point the tangent line is horizontal (dy/dx = 0), marking a smooth maximum and minimum."},
                ],
            },
        ],
        "callouts": [
            {"kind": "predict", "title": "Predict first",
             "body": "In the figure on y = ½x², set x₀ to 2. Before sliding the step h down toward 0, predict what slope the tangent line at x = 2 will have."},
            {"kind": "check", "title": "Explain it",
             "body": "Explain to a friend using a square of side x why the derivative of x² is 2x and not x."},
            {"kind": "careful", "title": "Slope is zero, not height",
             "body": "At the peak of a ball's flight, its derivative dh/dt is 0 because it stops rising for an instant, not because its height h is 0."},
        ],
        "debate": {
            "id": "debate-ch17-derivative",
            "oupUnitNumber": 14,
            "title": "What does zero slope at the peak mean?",
            "contextPrompt": "A cricket ball thrown straight up has height h(t) = 20t − 5t² metres. At t = 2 seconds, its derivative dh/dt is 0. Asha and Rohan debate what dh/dt = 0 tells us.",
            "speakerAName": "Asha",
            "speakerAClaim": "dh/dt = 0 means the ball is at height 0 metres on the ground.",
            "speakerBName": "Rohan",
            "speakerBClaim": "At t = 2 seconds the height is 20(2) − 5(4) = 20 metres. dh/dt = 0 means the tangent line is horizontal right at the top of the climb.",
            "choices": [
                {"id": "ch17-a", "speakerLabel": "Asha is right (height is 0 m)",
                 "reasoningStatement": "When the derivative is 0, the height is 0 too.",
                 "isCorrect": False,
                 "socraticRebuttal": "Substitute t = 2 into 20t − 5t²: 40 − 20 = 20 metres. The derivative measures slope, not height."},
                {"id": "ch17-b", "speakerLabel": "Rohan is right (flat tangent at the 20 m peak)",
                 "reasoningStatement": "The derivative is the rate of change, which passes through 0 as the ball turns from rising to falling.",
                 "isCorrect": True,
                 "socraticRebuttal": "Yes. At t = 2 seconds the ball reaches its maximum height of 20 m, where its instantaneous rate of change is 0."},
                {"id": "ch17-c", "speakerLabel": "Neither. The ball floats in the air forever after t = 2.",
                 "reasoningStatement": "Zero speed means the ball never moves again.",
                 "isCorrect": False,
                 "socraticRebuttal": "The slope is 0 only at the single instant t = 2; after t = 2, dh/dt = 20 − 10t becomes negative and the ball falls."},
            ],
            "invariantTakeaway": "At a smooth peak or valley, the derivative dy/dx is 0 because the tangent line is momentarily horizontal.",
        },
        "keyTerms": ["Secant line", "Limit", "Tangent line", "Rate of change", "Derivative",
                     "Power rule", "Stationary point", "Maximum and minimum"],
        "widgets": ["w_atlas_calculus_derivative", "w_power_rule_square_growth"],
        "widgetText": {
            "w_atlas_calculus_derivative": {
                "title": "Sliding the secant into the tangent",
                "challengePrompt": "Keep x₀ at 1.25 on y = ½x² and shrink the step h from 0.8 down to 0.05. "
                                   "Predict the value that the secant slope approaches.",
                "cutaway": "On y = ½x², the derivative is x. "
                           "As the step h shrinks toward 0, the secant slope x₀ + ½h approaches the exact tangent slope x₀.",
                "idealised": "The rule: f′(x) = the limit as h → 0 of (f(x + h) − f(x)) ÷ h",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Set x₀ to 1.5 and step h to 0.5 in the figure."},
                    {"title": "2. Notice", "caption": "The amber secant line cuts across the curve above the red tangent line."},
                    {"title": "3. Match the rule", "caption": "Slide h down to 0.05: the secant slope settles onto the tangent slope 1.5."},
                    {"title": "4. Push it further", "caption": "Move x₀ to 2.0 and check that the red tangent slope equals 2.0."},
                    {"title": "5. Draw it", "caption": "Sketch a parabola with a secant line through two points and a tangent line at one point."},
                ],
            },
            "w_power_rule_square_growth": {
                "title": "Two strips on a growing square",
                "challengePrompt": "Set the square's side x to 3 and grow it by a thin strip h. "
                                   "Count the two long strips of length 3 and see what happens to the tiny corner h².",
                "cutaway": "Growing a square of side x by h adds two strips of area x × h and a corner of area h². "
                           "Dividing by h leaves 2x + h, which becomes 2x as h shrinks to 0.",
                "idealised": "The rule: d/dx(x²) = 2x, and d/dx(xⁿ) = n xⁿ⁻¹",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Set the square side x to 2 and the step h to 0.5."},
                    {"title": "2. Notice", "caption": "The new area is two strips of 2 × 0.5 plus a corner of 0.5 × 0.5."},
                    {"title": "3. Match the rule", "caption": "Divide by h: 2(2) + 0.5 = 4.5, which approaches 2(2) = 4 as h → 0."},
                    {"title": "4. Push it further", "caption": "Set x to 3 and check that 2x + h approaches 6."},
                    {"title": "5. Draw it", "caption": "Draw a square of side x with two border strips of width h and label their areas."},
                ],
            },
        },
        "atlasLessons": [
            {
                "title": "Chapter 17 · From secant slope to tangent slope",
                "question": "How do we find the slope at one point when the gradient formula needs two points?",
                "explanation": "Take a second point at x + h and simplify the secant slope while h is not zero. "
                               "Then take the limit as h shrinks to 0.",
                "limits": "The rule: f′(x) = limit as h → 0 of (f(x + h) − f(x)) ÷ h",
            },
            {
                "title": "Chapter 17 · The geometry of the power rule",
                "question": "Why does the derivative of x² have a 2 in front, and the derivative of x³ have a 3?",
                "explanation": "A square grows along 2 edges of length x, and a cube grows along 3 square faces of area x². "
                               "The tiny corner pieces have h² or h³ and vanish when divided by h as h → 0.",
                "limits": "The rule: d/dx(xⁿ) = n xⁿ⁻¹",
            },
            {
                "title": "Chapter 17 · Finding peaks and valleys",
                "question": "Why does setting the derivative to 0 locate a smooth maximum or minimum?",
                "explanation": "A smooth curve climbs before a peak and falls after it. "
                               "At the turning point between rising and falling, the tangent line is horizontal (slope 0).",
                "limits": "The rule: stationary points occur where f′(x) = 0",
            },
        ],
        "visualMathTips": {},
    }


def cards(k):
    """The concept cards chapter 17 teaches."""
    return {
        "secant-line": {
            "name": "Secant line",
            "aliases": ["secant line", "secant lines", "secant"],
            "oneSentence": "A straight line that cuts through two points on a curve, whose gradient gives the average rate of change between them.",
            "picture": "An amber straight line cutting across a curved hill from point P to a nearby point Q.",
            "steps": [
                "Find the heights of the curve at the two points, f(x) and f(x + h).",
                "Subtract to get the rise: f(x + h) − f(x).",
                "Divide by the horizontal step h.",
            ],
            "workedExample": "On y = x² from x = 1 to x = 3, the secant line rises from 1 to 9 across a step of 2, so its slope is (9 − 1) ÷ 2 = 4.",
            "check": {
                "prompt": "On the curve y = x², what is the slope of the secant line between (1, 1) and (4, 16)?",
                "answer": "5",
                "answerKey": k.one(k.num("5"), accepts=["5", "slope = 5"], rejects=["15", "3", "4"]),
            },
            "mixUp": {
                "with": "tangent-line",
                "how": "A secant line cuts through two separate points on the curve; a tangent line touches at one point.",
            },
            "standsOn": ["gradient", "coordinates"],
        },
        "limit": {
            "name": "Limit",
            "aliases": ["the limit", "a limit", "limits"],
            "oneSentence": "The exact value that a sequence or expression gets closer and closer to as a step shrinks toward zero or grows without bound.",
            "picture": "The expression 6 + h stepping through 6.1, 6.01, 6.001 and settling onto 6 as h shrinks toward 0.",
            "steps": [
                "Simplify the expression first while the step h is not zero.",
                "Watch what happens to each term as h gets closer and closer to 0.",
                "Read the number that remains when the h terms vanish.",
            ],
            "workedExample": "As h approaches 0, the expression 4x + h approaches the limit 4x.",
            "check": {
                "prompt": "What is the limit of 10 + 3h as h shrinks to 0?",
                "answer": "10",
                "answerKey": k.one(k.num("10"), accepts=["10"], rejects=["13", "3", "0"]),
            },
            "mixUp": {
                "name": "dividing by zero before simplifying",
                "how": "Always cancel the common factor h in (6h + h²) ÷ h = 6 + h before taking the limit as h → 0.",
            },
            "standsOn": [],
        },
        "tangent-line": {
            "name": "Tangent line",
            "aliases": ["tangent line", "tangent lines"],
            "oneSentence": "The straight line that touches a curve at a single point and matches the curve's steepness right at that point.",
            "picture": "A straight ruler resting against the outside of a curve at one point P, showing the direction the curve is heading.",
            "steps": [
                "Write the slope of the secant line from x to x + h.",
                "Take the limit as the step h shrinks to 0.",
                "Draw the straight line through (x, f(x)) with that exact slope.",
            ],
            "workedExample": "On y = x² at the point (2, 4), the tangent line has slope 2(2) = 4.",
            "check": {
                "prompt": "On y = x², the slope of the tangent line at any x is 2x. What is the slope of the tangent line at x = 5?",
                "answer": "10",
                "answerKey": k.one(k.num("10"), accepts=["10", "slope = 10"], rejects=["25", "5", "2"]),
            },
            "mixUp": {
                "with": "secant-line",
                "how": "A secant line joins two points step h apart; the tangent line is the limiting line at a single point when h → 0.",
            },
            "standsOn": ["secant-line", "limit"],
        },
        "rate-of-change": {
            "name": "Rate of change",
            "aliases": ["rate of change", "rates of change", "instantaneous rate of change"],
            "oneSentence": "How fast one quantity changes per unit of another, given by the gradient of the graph.",
            "picture": "A car's speedometer reading 60 km/h at the moment the distance-time curve has gradient 60.",
            "steps": [
                "Check the units on the vertical axis and the horizontal axis.",
                "Divide vertical change by horizontal change.",
                "On a curve, use the tangent line's slope for the instantaneous rate of change.",
            ],
            "workedExample": "When water depth rises at 3 cm per minute, the rate of change of depth with respect to time is 3 cm/min.",
            "check": {
                "prompt": "A tank's volume V (in litres) changes with time t (in minutes). If the tangent slope at t = 4 is 7, what is the instantaneous rate of change, in litres per minute?",
                "answer": "7",
                "answerKey": k.one(k.num("7"), accepts=["7", "7 L/min", "7 litres per minute"], rejects=["28", "4", "1.75"]),
            },
            "mixUp": {
                "name": "dividing total height by total time on a curve",
                "how": "Total y ÷ total t gives the average rate from the start; the tangent slope gives the instantaneous rate of change right now.",
            },
            "standsOn": ["gradient", "limit"],
        },
        "derivative": {
            "name": "Derivative",
            "aliases": ["derivative", "derivatives", "dy/dx", "f′(x)"],
            "oneSentence": "The function f′(x), also written dy/dx, that gives the slope of the tangent line and instantaneous rate of change of y at any x.",
            "picture": "A machine that takes a curve y = f(x) and outputs its steepness f′(x) at every point.",
            "steps": [
                "Differentiate each term of the function using the power rule.",
                "Substitute the x-value of the point you care about.",
                "Read the result as the tangent slope at that point.",
            ],
            "workedExample": "For f(x) = x² + 3x, the derivative is f′(x) = 2x + 3. At x = 4, the slope is 2(4) + 3 = 11.",
            "check": {
                "prompt": "If f(x) = x² and its derivative is f′(x) = 2x, what is f′(6)?",
                "answer": "12",
                "answerKey": k.one(k.num("12"), accepts=["12", "f′(6) = 12"], rejects=["36", "6", "8"]),
            },
            "mixUp": {
                "name": "plugging x in before differentiating",
                "how": "f(6) = 36 is the height of the curve at x = 6; f′(6) = 12 is the slope of the curve at x = 6.",
            },
            "standsOn": ["tangent-line", "rate-of-change"],
        },
        "power-rule": {
            "name": "Power rule",
            "aliases": ["power rule", "power rules"],
            "oneSentence": "The rule for differentiating a power of x: bring the exponent n down in front and subtract 1 from the exponent, so d/dx(xⁿ) = n xⁿ⁻¹.",
            "picture": "A square x² growing along 2 sides of length x (giving 2x), and a cube x³ growing on 3 faces of area x² (giving 3x²).",
            "steps": [
                "Multiply the term by its current exponent n.",
                "Subtract 1 from the exponent to get n − 1.",
                "Replace any standalone constant number with 0.",
            ],
            "workedExample": "For y = 4x³, multiply by 3 and drop the power to 2: dy/dx = 12x².",
            "check": {
                "prompt": "By the power rule, what is the derivative of y = x⁵?",
                "answer": "5x⁴",
                "answerKey": k.one(k.expr("5x^4"), accepts=["5x⁴", "5x^4"], rejects=["5x^5", "x^4", "4x^5"]),
            },
            "mixUp": {
                "name": "forgetting to reduce the power by 1",
                "how": "Bringing 5 down is only half the step; the exponent must drop from 5 to 4, giving 5x⁴.",
            },
            "standsOn": ["derivative", "power"],
        },
        "stationary-point": {
            "name": "Stationary point",
            "aliases": ["stationary point", "stationary points", "turning point", "turning points"],
            "oneSentence": "A point on a curve where the derivative dy/dx equals 0, so the tangent line is horizontal.",
            "picture": "The flat crest of a roller-coaster hill or the flat bottom of a dip where the track is momentarily level.",
            "steps": [
                "Find the derivative dy/dx of the curve.",
                "Set dy/dx = 0 and solve the equation for x.",
                "Substitute x back into the original curve to find the height y.",
            ],
            "workedExample": "For y = x² − 8x + 19, dy/dx = 2x − 8 = 0 gives x = 4, and y = 16 − 32 + 19 = 3, so the stationary point is (4, 3).",
            "check": {
                "prompt": "A curve has derivative dy/dx = 2x − 10. At what value of x is its stationary point?",
                "answer": "5",
                "answerKey": k.one(k.num("5"), accepts=["5", "x = 5"], rejects=["10", "2", "-5"]),
            },
            "mixUp": {
                "name": "setting y = 0 instead of dy/dx = 0",
                "how": "Setting y = 0 finds where the curve crosses the x-axis; setting dy/dx = 0 finds where the curve is flat.",
            },
            "standsOn": ["derivative", "tangent-line"],
        },
        "maximum-and-minimum": {
            "name": "Maximum and minimum",
            "aliases": ["maximum and minimum", "local maximum", "local minimum", "maxima and minima"],
            "oneSentence": "A peak (local maximum) where a curve turns from rising to falling, or a valley (local minimum) where it turns from falling to rising.",
            "picture": "A hill crest with slope changing + to 0 to −, and a valley trough with slope changing − to 0 to +.",
            "steps": [
                "Solve dy/dx = 0 to find the x-coordinate of the stationary point.",
                "Check the sign of dy/dx slightly to the left and slightly to the right.",
                "Plus to minus is a local maximum; minus to plus is a local minimum.",
            ],
            "workedExample": "For y = 10x − x², dy/dx = 10 − 2x = 0 at x = 5. The maximum height is y = 10(5) − 25 = 25.",
            "check": {
                "prompt": "A thrown ball has height h = 12t − 2t², with peak at t = 3 seconds. What is its maximum height?",
                "answer": "18",
                "answerKey": k.one(k.num("18"), accepts=["18", "18 m"], rejects=["3", "36", "0"]),
            },
            "mixUp": {
                "name": "stopping at x without finding the maximum height y",
                "how": "t = 3 tells you when the peak happens; substituting t = 3 into h = 12t − 2t² gives the maximum height, 18.",
            },
            "standsOn": ["stationary-point", "rate-of-change"],
        },
    }


def sums():
    """Every sum chapter 17 and its cards state, recomputed."""
    return [
        # Skill card
        ("skill x^3 at x=2", 3 * (2 ** 2), 12),
        ("skill 2x - 6 = 0", 6 // 2, 3),
        # 17.1
        ("secant on x^2 from 3 to 3.1 and 3.01",
         (round(3.1 ** 2, 2), round((3.1 ** 2 - 9) / 0.1, 2), round((3.01 ** 2 - 9) / 0.01, 2)),
         (9.61, 6.1, 6.01)),
        ("turn 17.1", 2 * 4, 8),
        # 17.2
        ("stone y=5t^2",
         (5 * 3 ** 2 - 5 * 1 ** 2, 40 // 2, 10 * 1, 10 * 2, 10 * 3, (5 * 2 ** 2) // 2),
         (40, 20, 10, 20, 30, 10)),
        ("turn 17.2", (10 * 4, 5 * 4 ** 2), (40, 80)),
        # 17.3 and widget
        ("widget square x=2 h=0.5", 2 * 2 + 0.5, 4.5),
        ("turn 17.3", (3 * 2 ** 2, 2 ** 3), (12, 8)),
        # 17.4 and debate
        ("ball h(t) = 20t - 5t^2 at t=2", (20 // 10, 20 * 2 - 5 * 2 ** 2), (2, 20)),
        ("turn 17.4", 6 // 2, 3),
        # Cards
        ("secant-line card and check",
         (secant_slope(lambda x: x ** 2, 1, 2), secant_slope(lambda x: x ** 2, 1, 3), 4 ** 2 - 1 ** 2),
         (4, 5, 15)),
        ("tangent-line card and check", (2 * 2, 2 * 5, 5 ** 2), (4, 10, 25)),
        ("rate-of-change check", (4 * 7, 7 / 4), (28, 1.75)),
        ("derivative card and check", (2 * 4 + 3, 2 * 6, 6 ** 2), (11, 12, 36)),
        ("stationary-point card and check", (8 // 2, 4 ** 2 - 8 * 4 + 19, 10 // 2), (4, 3, 5)),
        ("maximum-and-minimum card and check", (10 * 5 - 5 ** 2, 12 * 3 - 2 * 3 ** 2), (25, 18)),
    ]


def answers():
    """Chapter 17's turn answers and its cards' check answers, computed."""
    return {
        "ch17-s1-turn": 2 * 4,
        "ch17-s2-turn": 10 * 4,
        "ch17-s3-turn": 3 * (2 ** 2),
        "ch17-s4-turn": 6 // 2,
        "secant-line-check": secant_slope(lambda x: x ** 2, 1, 3),
        "limit-check": 10 + 3 * 0,
        "tangent-line-check": 2 * 5,
        "rate-of-change-check": 7,
        "derivative-check": 2 * 6,
        "power-rule-check": "5x^4",
        "stationary-point-check": 10 // 2,
        "maximum-and-minimum-check": 12 * 3 - 2 * (3 ** 2),
    }
