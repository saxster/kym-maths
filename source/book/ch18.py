"""
Chapter 18, written by hand to docs/CONTENT_BRIEF.md. No school unit teaches it, so it goes beyond the school book.

Each section teaches one idea in nine steps, in this order: question, idea, picture, reason, name,
example, mistake, turn, sayBack. A section's `teaches` lists the concept cards whose names first
appear in its `name` step. `build(k)` returns the chapter and `cards(k)` its concept cards; both take the
exporter's answer-key helpers.
"""

from book.arithmetic import Fraction


def midpoint_riemann_linear(k_slope, upper_x, n):
    dx = Fraction(upper_x, n)
    total = sum(k_slope * (i + Fraction(1, 2)) * dx * dx for i in range(n))
    return int(total) if total.denominator == 1 else float(total)


def build(k):
    return {
        "number": 18,
        "title": "Areas under curves",
        "subtitle": "Beyond the school book · Slicing a curved region into thin rectangles, "
                    "running the power rule backwards, and why area undoes slope",
        "hookSummary": "A train's speed graph is a curve, not a flat line. "
                       "How do you find the exact distance it travelled when the shape under the graph is not a rectangle or a triangle?",
        "beyondSchoolBook": True,
        "skillCard": {
            "skill": "Approximating the area under a curve with thin rectangles, reversing the power rule to find an antiderivative, and evaluating definite integrals",
            "sheCan": {
                "prompt": "With no calculator: what is the antiderivative of 2x that is 0 at x = 0? "
                          "What is the exact area under y = 2x from x = 0 to x = 3? "
                          "Check your answer with the area of a right-angled triangle of base 3 and height 6.",
                "answer": "The antiderivative of 2x is x², because the derivative of x² is 2x. "
                          "From x = 0 to x = 3, the area is 3² − 0² = 9, which matches the triangle ½ × 3 × 6 = 9.",
            },
            "whyItMatters": "Whenever a rate of change varies from moment to moment, the total accumulated change is the area under the rate curve.",
            "standsOn": [
                "Chapter 7: distance as the area under a speed–time graph",
                "Chapter 10: the areas of rectangles and triangles",
                "Chapter 17: the derivative and the power rule",
            ],
            "unlocks": [
                "Physics: work done by a changing force and distance from a changing velocity",
                "Probability: finding probabilities as areas under a smooth bell curve",
                "Geometry: volumes of curved solids sliced into thin discs",
            ],
        },
        "intuitionToFormula": {
            "concreteAction": "In the figure, set the right-hand edge x to 2.4, the slope k to 1.0, and slide the number of strips from 4 up to 20.",
            "ahaInvariant": "Above the midpoint of each strip, the tiny triangle sticking out on the right matches the tiny triangle missing on the left. "
                            "Every thin strip of area f(x) × Δx equals a tiny step up on the antiderivative curve F(x).",
            "formulaDisplay": "∫ₐᵇ f(x) dx = F(b) − F(a)   where F′(x) = f(x)",
            "termMappings": [
                {"symbol": "f(xᵢ) Δx", "visualPart": "One blue vertical strip of width Δx", "colorRole": "blue",
                 "meaning": "The area of a single thin rectangle under the curve"},
                {"symbol": "∫₀ˣ f(t) dt", "visualPart": "All the strips added together from 0 to x", "colorRole": "green",
                 "meaning": "The total accumulated area under the rate curve"},
                {"symbol": "F(b) − F(a)", "visualPart": "The height reached on the antiderivative curve", "colorRole": "red",
                 "meaning": "Total change in F, which equals the area under F′"},
            ],
            "atlasFigureRef": "maths/ch19-integral-calculus/index.html",
        },
        "sections": [
            {
                "heading": "18.1 Slicing a curved shape into thin strips",
                "figure": True,
                "teaches": ["riemann-sum", "midpoint-rule"],
                "steps": [
                    {"kind": "question",
                     "text": "You know how to find the area of a rectangle: width × height. "
                             "How can rectangles measure the area under a curve whose height keeps changing?"},
                    {"kind": "idea",
                     "text": "Slice the base into thin strips of equal width Δx. "
                             "Stand a rectangle on each strip using the height at its middle, and add their areas up."},
                    {"kind": "picture",
                     "text": "In the figure, set the upper edge x to 2.4 and slide the number of strips from 4 up to 20. "
                             "Watch the stepped tops hug the green line more and more closely."},
                    {"kind": "reason",
                     "text": "Why measure the height at the midpoint of each strip rather than at its left or right edge? "
                             "A rising curve is lower on the left and higher on the right, so the missed triangle balances the extra one."},
                    {"kind": "name",
                     "text": "Adding the areas of thin vertical rectangles Σ f(xᵢ) Δx to approximate the area under a curve is a Riemann sum. "
                             "Choosing the curve's height at the middle of each strip's base is the midpoint rule."},
                    {"kind": "example",
                     "text": "To estimate the area under y = x² from x = 0 to x = 2 using 2 strips of width 1, "
                             "the midpoints are x = 0.5 and x = 1.5. "
                             "The midpoint rule gives 1 × (0.5)² + 1 × (1.5)² = 0.25 + 2.25 = 2.5."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to add the heights f(xᵢ) and forget to multiply by the strip width Δx. "
                             "Each strip is a rectangle, so its area is height × width."},
                    {"kind": "turn",
                     "text": "Estimate the area under y = 2x from x = 0 to x = 4 using 2 strips of width 2, "
                             "with midpoints at x = 1 (height 2) and x = 3 (height 6).",
                     "answer": "16",
                     "answerKey": k.one(k.num("16"), accepts=["16", "area = 16"], rejects=["8", "12", "32"])},
                    {"kind": "sayBack",
                     "text": "A Riemann sum adds rectangle areas height × width; the midpoint rule takes each height at the middle of its strip."},
                ],
            },
            {
                "heading": "18.2 Letting the strips become infinitely thin",
                "teaches": ["definite-integral", "signed-area"],
                "steps": [
                    {"kind": "question",
                     "text": "A train travels forward at 10 m/s for 3 seconds, then reverses at −5 m/s for 2 seconds. "
                             "How far from its start does it finish?"},
                    {"kind": "idea",
                     "text": "It moves +30 m forward and −10 m backward, finishing 30 − 10 = 20 m ahead of its start. "
                             "Area above the time axis adds on; area below the time axis subtracts."},
                    {"kind": "picture",
                     "text": "Draw a rectangle of height +10 and width 3 above the axis (area +30), "
                             "and a rectangle of depth −5 and width 2 below the axis (area −10)."},
                    {"kind": "reason",
                     "text": "Why let the number of strips grow without bound on a curved graph? "
                             "As the strip width dx shrinks to 0, the jagged steps disappear and the limit of the Riemann sum equals the exact area."},
                    {"kind": "name",
                     "text": "The limit of the Riemann sum from x = a to x = b as strip width shrinks to 0 is the definite integral, ∫ₐᵇ f(x) dx. "
                             "The elongated S sign ∫ stands for 'sum'. "
                             "Because regions above the x-axis count as positive and regions below count as negative, the definite integral measures signed area."},
                    {"kind": "example",
                     "text": "Under y = 2x from x = 0 to x = 3, the region is a triangle of base 3 and height 6. "
                             "So the definite integral ∫₀³ 2x dx = ½ × 3 × 6 = 9."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to add the area below the axis instead of subtracting it when finding net change. "
                             "For signed area, anything below the horizontal axis carries a minus sign."},
                    {"kind": "turn",
                     "text": "A curve forms a region of area 14 above the x-axis and a region of area 5 below the x-axis. "
                             "What is the net signed area (the definite integral across both regions)?",
                     "answer": "9",
                     "answerKey": k.one(k.num("9"), accepts=["9", "+9"], rejects=["19", "-9", "70"])},
                    {"kind": "sayBack",
                     "text": "The definite integral ∫ₐᵇ f(x) dx is the exact limit of the Riemann sum and measures signed area: above the axis minus below."},
                ],
            },
            {
                "heading": "18.3 Why slope and area undo each other",
                "teaches": ["antiderivative", "fundamental-theorem-of-calculus"],
                "steps": [
                    {"kind": "question",
                     "text": "Suppose you know a train's speed at every instant is v(t) = 2t, "
                             "and you notice that the position rule F(t) = t² has derivative F′(t) = 2t. "
                             "How can F(t) = t² give you the area under v(t) = 2t from t = 1 to t = 4 in one subtraction?"},
                    {"kind": "idea",
                     "text": "Each thin strip of area under the speed curve, v(t) × dt, is a tiny step of distance dF. "
                             "Adding all the tiny steps from t = 1 to t = 4 gives the total change in position: F(4) − F(1) = 4² − 1² = 15."},
                    {"kind": "picture",
                     "text": "Stack thin vertical steps dF one on top of another from F(a) up to F(b). "
                             "The middle steps cancel in pairs, leaving only F(b) − F(a)."},
                    {"kind": "reason",
                     "text": "How do you reverse the power rule to find F(x) from xⁿ? "
                             "Differentiating multiplied by the power and subtracted 1; reversing it adds 1 to the power and divides by the new power: xⁿ⁺¹ ÷ (n + 1)."},
                    {"kind": "name",
                     "text": "A function F(x) whose derivative F′(x) equals f(x) is an antiderivative of f(x). "
                             "The rule that the definite integral of f(x) from a to b equals F(b) − F(a) is the fundamental theorem of calculus."},
                    {"kind": "example",
                     "text": "To find ∫₀² 3x² dx, notice that x³ has derivative 3x², so F(x) = x³ is an antiderivative. "
                             "By the fundamental theorem of calculus, the exact area is F(2) − F(0) = 2³ − 0³ = 8."},
                    {"kind": "mistake",
                     "text": "The tempting slip when finding an antiderivative of xⁿ is to subtract 1 from the power as if differentiating. "
                             "Always add 1 to the exponent and divide by the new exponent, then check by differentiating your answer."},
                    {"kind": "turn",
                     "text": "Since F(x) = x³ is an antiderivative of 3x², use F(3) − F(1) to find the exact area ∫₁³ 3x² dx.",
                     "answer": "26",
                     "answerKey": k.one(k.num("26"), accepts=["26", "area = 26"], rejects=["27", "24", "6"])},
                    {"kind": "sayBack",
                     "text": "An antiderivative F(x) reverses the derivative, and the fundamental theorem of calculus says ∫ₐᵇ f(x) dx = F(b) − F(a)."},
                ],
            },
        ],
        "callouts": [
            {"kind": "predict", "title": "Predict first",
             "body": "In the figure, set the upper edge x to 2.0 and the slope k to 1.0. "
                     "Predict the exact area of the triangle from 0 to 2 before looking at the readout."},
            {"kind": "check", "title": "Explain it",
             "body": "Explain to a friend why adding up thousands of tiny height steps dF from x = a to x = b leaves F(b) − F(a)."},
            {"kind": "careful", "title": "Check by differentiating",
             "body": "After you write an antiderivative F(x), differentiate it in your head to check that F′(x) gives back the function inside the integral."},
        ],
        "debate": {
            "id": "debate-ch18-integral",
            "oupUnitNumber": 14,
            "title": "What does the area under a speed graph measure?",
            "contextPrompt": "A metro train's speed v(t) in m/s is plotted against time t in seconds. Asha and Rohan debate what the area under the v(t) curve represents.",
            "speakerAName": "Asha",
            "speakerAClaim": "The area under the speed graph gives the train's acceleration.",
            "speakerBName": "Rohan",
            "speakerBClaim": "Each thin strip has height in m/s multiplied by width in seconds, which gives metres. Adding the strips gives the total distance travelled.",
            "choices": [
                {"id": "ch18-a", "speakerLabel": "Asha is right (acceleration)",
                 "reasoningStatement": "Any calculation on a speed graph gives acceleration.",
                 "isCorrect": False,
                 "socraticRebuttal": "Acceleration is the slope dv/dt, which divides m/s by seconds to get m/s². Area multiplies the two axes."},
                {"id": "ch18-b", "speakerLabel": "Rohan is right (distance travelled in metres)",
                 "reasoningStatement": "Multiplying height (m/s) by width (s) gives metres for each thin strip, so the total area is total distance.",
                 "isCorrect": True,
                 "socraticRebuttal": "Yes. Slope divides the vertical unit by the horizontal unit; area multiplies them: (m/s) × s = m."},
                {"id": "ch18-c", "speakerLabel": "Neither. It gives the average speed.",
                 "reasoningStatement": "The area under a curve is its average value.",
                 "isCorrect": False,
                 "socraticRebuttal": "To get average speed, you would still have to divide that total distance (the area) by the total time."},
            ],
            "invariantTakeaway": "The derivative divides units (slope = y ÷ x); the definite integral multiplies units (area = ∫ y dx).",
        },
        "keyTerms": ["Riemann sum", "Midpoint rule", "Definite integral", "Signed area",
                     "Antiderivative", "Fundamental theorem of calculus"],
        "widgets": ["w_atlas_calculus_integral", "w_ftc_area_slope_duality"],
        "widgetText": {
            "w_atlas_calculus_integral": {
                "title": "Midpoint strips under a curve",
                "challengePrompt": "Set the upper edge x to 2.0 and the slope k to 1.0, then slide the number of strips N from 4 to 20. "
                                   "Watch the sum of the strips compared with the exact area ½kx².",
                "cutaway": "Each strip has width Δx = x ÷ N and height measured at its midpoint. "
                           "On a straight line the left and right triangles on top of each strip balance, and on a curve the error vanishes as N grows.",
                "idealised": "The rule: ∫₀ˣ kt dt = ½kx²",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Set upper edge x to 2.0, strips N to 4, and slope k to 1.0."},
                    {"title": "2. Notice", "caption": "Each of the 4 blue strips has width 2.0 ÷ 4 = 0.5."},
                    {"title": "3. Match the rule", "caption": "The 4 strips add to ½ × 1.0 × 2.0² = 2.0."},
                    {"title": "4. Push it further", "caption": "Slide x to 3.0 and check that the area grows to ½ × 1.0 × 3.0² = 4.5."},
                    {"title": "5. Draw it", "caption": "Draw the triangle under y = t from 0 to 2 and split it into 2 midpoint strips."},
                ],
            },
            "w_ftc_area_slope_duality": {
                "title": "How area and slope undo each other",
                "challengePrompt": "Compare the area under the line y = t from 0 to x with the height of the parabola F(x) = ½x². "
                                   "Predict the rate at which the area grows when you nudge x right by dx.",
                "cutaway": "Nudging the right edge x by a thin step dx adds one vertical ribbon of width dx and height f(x). "
                           "So the rate of change of the area with respect to x is the curve's height f(x) itself.",
                "idealised": "The rule: d/dx (∫₀ˣ f(t) dt) = f(x), and ∫ₐᵇ f(x) dx = F(b) − F(a)",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Set x to 2.0 and slope k to 1.0."},
                    {"title": "2. Notice", "caption": "The height of the line at x = 2 is 2, and the area from 0 to 2 is ½(2)² = 2."},
                    {"title": "3. Match the rule", "caption": "Differentiate ½x²: the power rule gives ½(2x) = x, the height of the line."},
                    {"title": "4. Push it further", "caption": "Set k to 1.5 and x to 2.0: the area is ½(1.5)(4) = 3.0 and the height is 3.0."},
                    {"title": "5. Draw it", "caption": "Sketch a curve f(x), shade the area to x, and draw one thin new strip of area f(x) dx at the right edge."},
                ],
            },
        },
        "atlasLessons": [
            {
                "title": "Chapter 18 · Adding thin rectangles",
                "question": "Why does the midpoint rule give a closer estimate than using the left or right edge of each strip?",
                "explanation": "At the midpoint of a strip, a rising curve lies below the top on the left and above it on the right. "
                               "The two small triangular errors cancel.",
                "limits": "The rule: Riemann sum = Σ f(xᵢ) Δx",
            },
            {
                "title": "Chapter 18 · Reversing the power rule",
                "question": "How do we find an antiderivative of xⁿ?",
                "explanation": "Since differentiating multiplies by the exponent and subtracts 1, reversing it adds 1 to the exponent and divides by the new exponent: xⁿ⁺¹ ÷ (n + 1).",
                "limits": "The rule: an antiderivative of xⁿ is xⁿ⁺¹ ÷ (n + 1)",
            },
            {
                "title": "Chapter 18 · The fundamental theorem of calculus",
                "question": "Why does the area under f(x) from a to b equal F(b) − F(a)?",
                "explanation": "Each thin strip of area f(x) dx equals a small rise dF on the antiderivative curve F(x). "
                               "Adding all the small rises from x = a to x = b gives the total height change F(b) − F(a).",
                "limits": "The rule: ∫ₐᵇ f(x) dx = F(b) − F(a) where F′(x) = f(x)",
            },
        ],
        "visualMathTips": {
            "tip-calculus-ftc": {
                "title": "Why slope and area undo each other",
                "visualIntuition": "Compare the shaded triangle of area under f′(t) = t from 0 to x with the height of the parabola f(x) = ½x².",
                "ahaMoment": "Each thin strip of area f′(t) × dt is a tiny step df on the original curve. "
                             "All the strips add up to f(x) − f(0).",
                "formula": "∫₀ˣ f′(t) dt = f(x) − f(0)",
            },
        },
    }


def cards(k):
    """The concept cards chapter 18 teaches."""
    return {
        "riemann-sum": {
            "name": "Riemann sum",
            "aliases": ["Riemann sum", "Riemann sums"],
            "oneSentence": "An approximation to the area under a curve made by slicing the region into vertical rectangles and adding their areas: Σ f(xᵢ) Δx.",
            "picture": "A row of thin blue rectangles standing side by side under a curve.",
            "steps": [
                "Split the interval from a to b into N strips of equal width Δx = (b − a) ÷ N.",
                "Multiply each strip's height f(xᵢ) by its width Δx.",
                "Add the N rectangle areas together.",
            ],
            "workedExample": "Two strips of width 3 and heights 4 and 7 have a Riemann sum of (4 × 3) + (7 × 3) = 12 + 21 = 33.",
            "check": {
                "prompt": "Three strips each have width Δx = 2 and heights 3, 5 and 7. What is their Riemann sum?",
                "answer": "30",
                "answerKey": k.one(k.num("30"), accepts=["30", "area = 30"], rejects=["15", "17", "210"]),
            },
            "mixUp": {
                "name": "adding the heights without multiplying by the width",
                "how": "3 + 5 + 7 = 15 is only the sum of the heights; multiply by the strip width 2 to get the area, 30.",
            },
            "standsOn": ["area", "sigma"],
        },
        "midpoint-rule": {
            "name": "Midpoint rule",
            "aliases": ["midpoint rule", "midpoint rules"],
            "oneSentence": "A Riemann sum where each rectangle's height is measured at the midpoint of its base.",
            "picture": "A rectangle whose top crosses the curve at the middle of the strip, so the left overhang and right gap balance.",
            "steps": [
                "Find the midpoint of each strip along the horizontal axis.",
                "Evaluate the curve's height f(x) at each midpoint.",
                "Multiply each midpoint height by the strip width Δx and add them up.",
            ],
            "workedExample": "On [0, 4] split into 2 strips [0, 2] and [2, 4], the midpoints are x = 1 and x = 3.",
            "check": {
                "prompt": "The interval from x = 2 to x = 6 is used as one strip. At what x-value does the midpoint rule measure the height?",
                "answer": "4",
                "answerKey": k.one(k.num("4"), accepts=["4", "x = 4"], rejects=["2", "6", "8"]),
            },
            "mixUp": {
                "name": "using the left or right endpoint",
                "how": "The midpoint of 2 and 6 is (2 + 6) ÷ 2 = 4, halfway between the two edges.",
            },
            "standsOn": ["riemann-sum", "midpoint"],
        },
        "definite-integral": {
            "name": "Definite integral",
            "symbol": "∫",
            "aliases": ["definite integral", "definite integrals", "integral", "integrals", "∫"],
            "oneSentence": "The exact signed area between f(x) and the x-axis from x = a to x = b, written ∫ₐᵇ f(x) dx.",
            "picture": "The shaded region under a curve between two vertical walls at x = a and x = b.",
            "steps": [
                "Read the lower limit a at the bottom of ∫ and the upper limit b at the top.",
                "Find an antiderivative F(x) of the function inside the integral.",
                "Compute F(b) − F(a).",
            ],
            "workedExample": "∫₀⁴ 2x dx is the area under y = 2x from 0 to 4: using F(x) = x², it equals 4² − 0² = 16.",
            "check": {
                "prompt": "What is the definite integral ∫₀⁵ 2x dx, the area under y = 2x from x = 0 to x = 5?",
                "answer": "25",
                "answerKey": k.one(k.num("25"), accepts=["25"], rejects=["10", "5", "50"]),
            },
            "mixUp": {
                "with": "derivative",
                "how": "The derivative dy/dx finds the slope of the curve; the definite integral ∫ f(x) dx finds the accumulated area under the curve.",
            },
            "standsOn": ["riemann-sum", "limit"],
        },
        "signed-area": {
            "name": "Signed area",
            "aliases": ["signed area", "signed areas"],
            "oneSentence": "Area where regions above the horizontal axis count as positive and regions below the horizontal axis count as negative.",
            "picture": "A wave with a +10 crest above the axis and a −4 trough below the axis, giving a net signed area of +6.",
            "steps": [
                "Find the area of the parts of the curve that sit above the x-axis (+).",
                "Find the area of the parts that sit below the x-axis (−).",
                "Subtract the area below from the area above.",
            ],
            "workedExample": "A graph has area 12 above the axis and area 5 below the axis, so its signed area is 12 − 5 = 7.",
            "check": {
                "prompt": "A velocity graph has area 20 m above the time axis and area 8 m below the time axis. What is the net signed area (displacement), in m?",
                "answer": "12",
                "answerKey": k.one(k.num("12"), accepts=["12", "12 m", "+12"], rejects=["28", "-12", "8"]),
            },
            "mixUp": {
                "name": "total geometric area regardless of sign",
                "how": "Total distance walked is 20 + 8 = 28 m, but net displacement (signed area) subtracts the backward part: 20 − 8 = 12 m.",
            },
            "standsOn": ["definite-integral", "negative-number"],
        },
        "antiderivative": {
            "name": "Antiderivative",
            "aliases": ["antiderivative", "antiderivatives"],
            "oneSentence": "A function F(x) whose derivative F′(x) gives back f(x), found for a power xⁿ by adding 1 to the exponent and dividing by the new exponent.",
            "picture": "Running the derivative machine in reverse: 3x² goes in, and x³ comes out.",
            "steps": [
                "Add 1 to the exponent n to get n + 1.",
                "Divide the term by the new exponent n + 1.",
                "Differentiate your result to verify it gives back the starting function.",
            ],
            "workedExample": "An antiderivative of 3x² is x³, because the derivative of x³ is 3x².",
            "check": {
                "prompt": "Find the antiderivative F(x) of 4x³ that has no constant term.",
                "answer": "x⁴",
                "answerKey": k.one(k.expr("x^4"), accepts=["x⁴", "x^4"], rejects=["12x^2", "4x^4", "x^3"]),
            },
            "mixUp": {
                "with": "derivative",
                "how": "Differentiating 4x³ drops the power to give 12x²; finding an antiderivative raises the power to give x⁴.",
            },
            "standsOn": ["derivative", "power-rule", "inverse-operation"],
        },
        "fundamental-theorem-of-calculus": {
            "name": "Fundamental theorem of calculus",
            "aliases": ["fundamental theorem of calculus"],
            "oneSentence": "The bridge between derivatives and integrals: if F′(x) = f(x), then the definite integral ∫ₐᵇ f(x) dx equals F(b) − F(a).",
            "picture": "A staircase of tiny rises dF = f(x) dx adding up to the total height difference F(b) − F(a).",
            "steps": [
                "Find an antiderivative F(x) such that F′(x) = f(x).",
                "Evaluate F(b) at the upper limit and F(a) at the lower limit.",
                "Subtract F(b) − F(a).",
            ],
            "workedExample": "Since F(x) = x² has derivative 2x, ∫₁⁴ 2x dx = F(4) − F(1) = 16 − 1 = 15.",
            "check": {
                "prompt": "Given that F(x) = x² is an antiderivative of 2x, use F(5) − F(2) to evaluate ∫₂⁵ 2x dx.",
                "answer": "21",
                "answerKey": k.one(k.num("21"), accepts=["21"], rejects=["25", "29", "6"]),
            },
            "mixUp": {
                "name": "subtracting in the wrong order F(a) − F(b)",
                "how": "Always start with the upper limit: Top minus Bottom, F(b) − F(a) = 25 − 4 = 21.",
            },
            "standsOn": ["definite-integral", "antiderivative"],
        },
    }


def sums():
    """Every sum chapter 18 and its cards state, recomputed."""
    return [
        # Skill card
        ("skill integral 2x from 0 to 3", (3 ** 2 - 0 ** 2, Fraction(1, 2) * 3 * 6), (9, 9)),
        # 18.1
        ("18.1 example y=x^2 on [0,2] with 2 strips", 1 * (0.5 ** 2) + 1 * (1.5 ** 2), 2.5),
        ("turn 18.1 y=2x on [0,4] with 2 strips", (2 * 2 + 2 * 6, 2 + 6), (16, 8)),
        # 18.2
        ("18.2 train +30 - 10", (10 * 3, -5 * 2, 30 - 10), (30, -10, 20)),
        ("turn 18.2 signed area 14 - 5", (14 - 5, 14 + 5), (9, 19)),
        # 18.3
        ("18.3 F(4) - F(1) and F(2) - F(0)", (4 ** 2 - 1 ** 2, 2 ** 3 - 0 ** 3), (15, 8)),
        ("turn 18.3 F(3) - F(1) on x^3", (3 ** 3 - 1 ** 3, 3 ** 3), (26, 27)),
        # Widgets
        ("widget integral",
         (2.0 / 4, midpoint_riemann_linear(1, 2, 4), 0.5 * 1.0 * 3.0 ** 2, 0.5 * 1.5 * 2.0 ** 2),
         (0.5, 2, 4.5, 3.0)),
        # Cards
        ("riemann-sum card and check", (4 * 3 + 7 * 3, (3 + 5 + 7) * 2, 3 + 5 + 7), (33, 30, 15)),
        ("midpoint-rule check", (2 + 6) // 2, 4),
        ("definite-integral card and check", (4 ** 2 - 0 ** 2, 5 ** 2 - 0 ** 2), (16, 25)),
        ("signed-area card and check", (12 - 5, 20 - 8, 20 + 8), (7, 12, 28)),
        ("ftc card and check", (4 ** 2 - 1 ** 2, 5 ** 2 - 2 ** 2, 5 ** 2 + 2 ** 2), (15, 21, 29)),
    ]


def answers():
    """Chapter 18's turn answers and its cards' check answers, computed."""
    return {
        "ch18-s1-turn": 2 * 2 + 2 * 6,
        "ch18-s2-turn": 14 - 5,
        "ch18-s3-turn": 3 ** 3 - 1 ** 3,
        "riemann-sum-check": (3 + 5 + 7) * 2,
        "midpoint-rule-check": (2 + 6) // 2,
        "definite-integral-check": 5 ** 2 - 0 ** 2,
        "signed-area-check": 20 - 8,
        "antiderivative-check": "x^4",
        "fundamental-theorem-of-calculus-check": 5 ** 2 - 2 ** 2,
    }
