"""
Chapter 14, written by hand to docs/CONTENT_BRIEF.md. It maps to OUP Unit 10 (Presenting data and interpreting results).

Each section teaches one idea in nine steps, in this order: question, idea, picture, reason, name,
example, mistake, turn, sayBack. A section's `teaches` lists the concept cards whose names first
appear in its `name` step. `build(k)` returns the chapter and `cards(k)` its concept cards; both take the
exporter's answer-key helpers.
"""

import math

from book.arithmetic import Fraction


def mean_value(values):
    total = Fraction(sum(values), len(values))
    return int(total) if total.denominator == 1 else float(total)


def median_value(values):
    ordered = sorted(values)
    n = len(ordered)
    mid = n // 2
    if n % 2 == 1:
        return ordered[mid]
    avg = Fraction(ordered[mid - 1] + ordered[mid], 2)
    return int(avg) if avg.denominator == 1 else float(avg)


def quartiles_and_iqr(values):
    ordered = sorted(values)
    mid = len(ordered) // 2
    lower = median_value(ordered[:mid])
    upper = median_value(ordered[mid + (len(ordered) % 2):])
    return lower, upper, upper - lower


def frequency_density(frequency, width):
    fd = Fraction(frequency, width)
    return int(fd) if fd.denominator == 1 else float(fd)


def pop_variance(values):
    mu = Fraction(sum(values), len(values))
    var = sum((x - mu) ** 2 for x in values) / len(values)
    return int(var) if var.denominator == 1 else float(var)


def build(k):
    return {
        "number": 14,
        "title": "Spread: histograms and standard deviation",
        "subtitle": "School book chapter 10 · Smoothing a bumpy line over time, ordering leaves, "
                    "drawing bars whose area is the count, and measuring spread",
        "hookSummary": "Two bus routes both take 20 minutes on average. "
                       "One arrives in 19, 20 or 21 minutes; the other takes 5 minutes or 35. "
                       "The average alone hides the wait.",
        "beyondSchoolBook": False,
        "skillCard": {
            "skill": "Reading and drawing time-series graphs, stem-and-leaf diagrams and unequal-width histograms, and comparing two sets of data by their middle and their spread",
            "sheCan": {
                "prompt": "With no calculator: in a survey of parcel masses, the group 40 ≤ m < 60 kg holds 30 parcels and the group 60 ≤ m < 70 kg holds 25 parcels. "
                          "What height should each bar have on a histogram? "
                          "And for the seven numbers 12, 15, 17, 20, 24, 29, 31, what are the middle value and the spread of the middle half?",
                "answer": "For 40 to 60 kg the width is 20, so the bar height is 30 ÷ 20 = 1.5. "
                          "For 60 to 70 kg the width is 10, so the bar height is 25 ÷ 10 = 2.5. "
                          "For the seven numbers, the middle value is 20, and the middle half runs from 15 to 29, a spread of 29 − 15 = 14.",
            },
            "whyItMatters": "Averages without spread can mislead a hospital, a weather office or a shopper. "
                            "Knowing how wide the bars are and how far values sit from the middle lets you read the whole shape of the data.",
            "standsOn": [
                "Chapter 3: dividing by a width to find a rate per unit",
                "Chapter 10: the area of a rectangle, height times width",
                "Chapter 13: the mean of a group of numbers",
            ],
            "unlocks": [
                "Chapter 15: the bell-shaped curve of totals when many random steps add up",
                "Chapter 16: reading two-way area diagrams where rectangle area is the count",
                "Chapter 18: adding the areas of thin rectangles under a curve",
            ],
        },
        "intuitionToFormula": {
            "concreteAction": "In the figure, keep the count in the third group at 30 and widen its span from 10 minutes to 25 minutes.",
            "ahaInvariant": "As the third bar gets wider, its height drops so that width × height stays equal to 30. "
                            "In a histogram, the area of the bar is the count.",
            "formulaDisplay": "Frequency density = count ÷ width,   IQR = Q₃ − Q₁,   σ = √( Σ(x − mean)² ÷ n )",
            "termMappings": [
                {"symbol": "count ÷ width", "visualPart": "The height of the red bar on the right", "colorRole": "red",
                 "meaning": "How many items fall in each 1 unit of width"},
                {"symbol": "height × width", "visualPart": "The filled area of each bar", "colorRole": "blue",
                 "meaning": "The exact count of items in that group"},
                {"symbol": "IQR & σ", "visualPart": "The spread of values around the middle", "colorRole": "amber",
                 "meaning": "How tightly or loosely the data clusters"},
            ],
            "atlasFigureRef": "maths/ch11-data-histograms/index.html",
        },
        "sections": [
            {
                "heading": "14.1 Smoothing out the bumps across time",
                "teaches": ["time-series", "moving-average"],
                "steps": [
                    {"kind": "question",
                     "text": "An ice-cream stall writes down its sales every day for a month. "
                             "Weekends spike high and Mondays dip low. How can the owner see whether the month as a whole is climbing?"},
                    {"kind": "idea",
                     "text": "Plot the days in order along the bottom, then take the mean of each run of 7 days. "
                             "Every 7-day window holds one Saturday and one Monday, so the weekly bumps flatten out."},
                    {"kind": "picture",
                     "text": "Picture a jagged mountain path of daily dots, and a smooth ribbon running through the middle of every three consecutive dots."},
                    {"kind": "reason",
                     "text": "Why slide the window one step at a time? Each step drops the oldest day and adds the newest day. "
                             "One hot Saturday cannot pull the whole ribbon up on its own."},
                    {"kind": "name",
                     "text": "A graph with time along the horizontal axis and readings plotted in order is a time series. "
                             "The mean of a sliding window of fixed length, such as 3 days or 4 quarters, is a moving average."},
                    {"kind": "example",
                     "text": "Daily sales over four days are 10, 14, 18 and 22. "
                             "The first 3-day moving average is (10 + 14 + 18) ÷ 3 = 14, and the next is (14 + 18 + 22) ÷ 3 = 18."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to plot a moving average above the last day of its window. "
                             "Plot it above the middle of its window so the trend line is not shifted sideways."},
                    {"kind": "turn",
                     "text": "Rainfall over three months is 12 mm, 18 mm and 24 mm. What is their 3-month moving average, in mm?",
                     "answer": "18",
                     "answerKey": k.one(k.num("18"), accepts=["18", "18 mm", "18mm"], rejects=["54", "15", "21"])},
                    {"kind": "sayBack",
                     "text": "A time series plots readings in time order, and a moving average smooths regular ups and downs to show the underlying trend."},
                ],
            },
            {
                "heading": "14.2 Keeping every digit while showing the shape",
                "teaches": ["stem-and-leaf-diagram", "median", "quartile", "interquartile-range"],
                "steps": [
                    {"kind": "question",
                     "text": "Seven cyclists finish a hill climb in 12, 15, 17, 20, 24, 29 and 31 minutes. "
                             "If one cyclist had a puncture and took 95 minutes instead of 31, the mean jumps up. What measure of the middle stays at 20?"},
                    {"kind": "idea",
                     "text": "The middle number when they are lined up in order, 20. "
                             "And to measure the spread without being fooled by the 95-minute puncture, take the gap across the middle half of the riders: 29 − 15 = 14."},
                    {"kind": "picture",
                     "text": "Write the tens digit on the left of a line and the ordered units digits on the right: "
                             "1 | 2 5 7, 2 | 0 4 9, 3 | 1. Add the key: 1 | 2 means 12 minutes."},
                    {"kind": "reason",
                     "text": "Why cut off the bottom quarter and the top quarter? Extreme outliers live at the two ends. "
                             "The middle half shows how spread out typical riders are."},
                    {"kind": "name",
                     "text": "Splitting each number into a tens stem and an ordered units leaf makes a stem-and-leaf diagram. "
                             "In an ordered list, the middle value is the median. "
                             "The middles of the two halves are the quartiles Q₁ and Q₃, and Q₃ − Q₁ is the interquartile range."},
                    {"kind": "example",
                     "text": "For 12, 15, 17, 20, 24, 29, 31, the 4th value is the median, 20. "
                             "The lower three values 12, 15, 17 have middle Q₁ = 15; the upper three 24, 29, 31 have middle Q₃ = 29; "
                             "so the interquartile range is 29 − 15 = 14."},
                    {"kind": "mistake",
                     "text": "The tempting slip in a stem-and-leaf diagram is to leave the leaves unsorted or forget the key. "
                             "Without ascending leaves you cannot count to the median, and without a key 2 | 4 could mean 24 or 2.4."},
                    {"kind": "turn",
                     "text": "Find the interquartile range of the seven ordered numbers 10, 13, 16, 19, 22, 25, 28.",
                     "answer": "12",
                     "answerKey": k.one(k.num("12"), accepts=["12", "IQR = 12"], rejects=["18", "19", "9"])},
                    {"kind": "sayBack",
                     "text": "A stem-and-leaf diagram keeps every exact value in order; the median marks the middle and the interquartile range Q₃ − Q₁ measures the middle half."},
                ],
            },
            {
                "heading": "14.3 Why area, not height, is the count",
                "figure": True,
                "teaches": ["class-width", "frequency-density", "histogram"],
                "steps": [
                    {"kind": "question",
                     "text": "Waiting times at a clinic are grouped into 0 to 10 minutes (18 patients), 10 to 20 minutes (24 patients), "
                             "and one wide group from 20 to 45 minutes (30 patients). "
                             "If you draw a bar of height 30 for the wide group, why does the chart lie?"},
                    {"kind": "idea",
                     "text": "Because the group from 20 to 45 minutes is 25 minutes wide, two and a half times as wide as the 10-minute groups. "
                             "Making it 30 units tall as well makes its rectangle look huge, even though only 1.2 patients arrived per minute."},
                    {"kind": "picture",
                     "text": "In the figure, look at the three bars when the third group's width is 25 minutes and its count is 30. "
                             "Its height is 30 ÷ 25 = 1.2, so the area of the red rectangle is 25 × 1.2 = 30."},
                    {"kind": "reason",
                     "text": "Why divide the count by the width? The eye judges a bar by the ink it covers, which is its area. "
                             "Setting height = count ÷ width guarantees that area = width × height = count."},
                    {"kind": "name",
                     "text": "The span of a group from its lower edge to its upper edge is the class width. "
                             "The count divided by the class width is the frequency density. "
                             "A chart of continuous groups with no gaps where bar height is frequency density and bar area is the count is a histogram."},
                    {"kind": "example",
                     "text": "For 40 ≤ m < 60 kg with 30 parcels, the class width is 60 − 40 = 20 kg and the frequency density is 30 ÷ 20 = 1.5. "
                             "For 60 ≤ m < 70 kg with 25 parcels, the class width is 10 kg and the frequency density is 25 ÷ 10 = 2.5."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to plot the raw count on the vertical axis when the groups have unequal widths. "
                             "Always divide count by class width first, and multiply frequency density by class width to read a count back."},
                    {"kind": "turn",
                     "text": "A group 10 ≤ t < 25 seconds has class width 15 seconds and frequency density 3.2. "
                             "How many items are in this group?",
                     "answer": "48",
                     "answerKey": k.one(k.num("48"), accepts=["48", "48 items", "48 observations"], rejects=["18.2", "4.8", "15"])},
                    {"kind": "sayBack",
                     "text": "In a histogram, frequency density is count ÷ class width, so the area of every bar equals the count in that group."},
                ],
            },
            {
                "heading": "14.4 Distance from the balance point",
                "teaches": ["sigma", "variance", "standard-deviation"],
                "steps": [
                    {"kind": "question",
                     "text": "Five friends score 4, 6, 8, 10 and 12 on a quiz. Their mean is 8. "
                             "If you find each score's gap from 8 (−4, −2, 0, +2, +4) and add those gaps up, you get 0. "
                             "How do we stop the negative gaps cancelling the positive ones?"},
                    {"kind": "idea",
                     "text": "Square each gap before adding, take the mean of those squares, then take the square root to return to the starting units. "
                             "This calculation goes beyond the school book, which only asks you to compare spreads."},
                    {"kind": "picture",
                     "text": "Picture a plank balanced on a pivot at 8, with blocks at 4, 6, 8, 10 and 12. "
                             "Each block's distance from the pivot is squared: 16, 4, 0, 4 and 16."},
                    {"kind": "reason",
                     "text": "Why take the square root at the end? Squaring turns marks into squared marks, or metres into square metres. "
                             "Taking the square root brings the spread back into marks or metres so you can compare it with the mean."},
                    {"kind": "name",
                     "text": "The Greek capital letter Σ, called sigma, means 'add up all the terms of this kind'. "
                             "The mean of the squared gaps from the mean, Σ(x − mean)² ÷ n, is the variance. "
                             "Its square root is the standard deviation, written σ."},
                    {"kind": "example",
                     "text": "For 4, 6, 8, 10, 12, the mean is 8 and the squared gaps are 16, 4, 0, 4, 16. "
                             "Their sum Σ(x − 8)² is 40, the variance is 40 ÷ 5 = 8, and the standard deviation is σ = √8 ≈ 2.83."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to stop at the variance, 8, and forget the square root. "
                             "A spread of 8 marks would be wider than the gap from 8 to the highest score, 12. Take the square root to get √8 ≈ 2.83."},
                    {"kind": "turn",
                     "text": "Four numbers 2, 4, 6 and 8 have a mean of 5. "
                             "Their gaps from 5 are −3, −1, 1 and 3, so the squared gaps are 9, 1, 1 and 9. "
                             "What is their variance, Σ(x − 5)² ÷ 4?",
                     "answer": "5",
                     "answerKey": k.one(k.num("5"), accepts=["5", "variance = 5"], rejects=["20", "0", "2.24"])},
                    {"kind": "sayBack",
                     "text": "Variance averages the squared distances from the mean using Σ, and standard deviation σ takes the square root to measure typical spread."},
                ],
            },
        ],
        "callouts": [
            {"kind": "predict", "title": "Predict first",
             "body": "In the figure, keep the third group's count at 30 and double its width from 15 to 30. "
                     "Predict what happens to its bar height before you move the slider."},
            {"kind": "check", "title": "Explain it",
             "body": "Explain to a friend why a taller bar on a histogram does not always hold more items than a shorter, wider bar."},
            {"kind": "careful", "title": "Always pair middle with spread",
             "body": "When comparing two groups of data, give one measure of the middle (mean or median) and one measure of spread (interquartile range or standard deviation)."},
        ],
        "debate": {
            "id": "debate-ch14-histograms",
            "oupUnitNumber": 10,
            "title": "Does the tallest bar hold the most people?",
            "contextPrompt": "On a journey-time histogram, group A (width 10 minutes) has frequency density 4, and group B (width 30 minutes) has frequency density 2.",
            "speakerAName": "Asha",
            "speakerAClaim": "Group A's bar is twice as tall as group B's (4 against 2), so twice as many people are in group A.",
            "speakerBName": "Rohan",
            "speakerBClaim": "In a histogram, the area is the count. Group A holds 10 × 4 = 40 people, while group B holds 30 × 2 = 60 people.",
            "choices": [
                {"id": "ch14-a", "speakerLabel": "Asha is right (group A has more)",
                 "reasoningStatement": "The tallest bar always shows the biggest count.",
                 "isCorrect": False,
                 "socraticRebuttal": "Height matches the count only when every bar has the same width. Here group B is three times as wide as group A."},
                {"id": "ch14-b", "speakerLabel": "Rohan is right (group B has 60, group A has 40)",
                 "reasoningStatement": "Count equals frequency density × class width, which is the area of the bar.",
                 "isCorrect": True,
                 "socraticRebuttal": "Yes. Group A is more crowded per minute, but group B spans 30 minutes and holds 30 × 2 = 60 people in total."},
                {"id": "ch14-c", "speakerLabel": "Neither. They hold the same number of people.",
                 "reasoningStatement": "A wider bar and a taller bar cancel each other out.",
                 "isCorrect": False,
                 "socraticRebuttal": "Multiply width by height for each bar: 10 × 4 = 40, while 30 × 2 = 60."},
            ],
            "invariantTakeaway": "In a histogram, the area of a bar (class width × frequency density) equals the count in that group.",
        },
        "keyTerms": ["Time series", "Moving average", "Stem-and-leaf diagram", "Median", "Quartile", "Interquartile range",
                     "Class width", "Frequency density", "Histogram", "Sigma", "Variance", "Standard deviation"],
        "widgets": ["w_histogram_frequency_density", "w_mean_fulcrum_std_dev"],
        "widgetText": {
            "w_histogram_frequency_density": {
                "title": "Histogram bars where area is the count",
                "challengePrompt": "Change the width of the third group from 10 minutes to 30 minutes while keeping its count at 30. "
                                   "Predict the bar height at width 10 and at width 30.",
                "cutaway": "The count in the third group stays 30. "
                           "When the class width grows from 10 to 30, the frequency density drops from 3 to 1 so the rectangle's area stays 30.",
                "idealised": "The rule: frequency density = count ÷ class width, and bar area = count",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Set the third group's width to 15 minutes and its count to 30."},
                    {"title": "2. Notice", "caption": "The red bar's height is 30 ÷ 15 = 2."},
                    {"title": "3. Match the rule", "caption": "Slide the width to 30 minutes: the height drops to 30 ÷ 30 = 1."},
                    {"title": "4. Push it further", "caption": "Keep width at 25 and slide the count to 50. Check that height becomes 2."},
                    {"title": "5. Draw it", "caption": "Sketch two bars of widths 10 and 20 that both hold a count of 20."},
                ],
            },
            "w_mean_fulcrum_std_dev": {
                "title": "Balancing at the mean and measuring spread",
                "challengePrompt": "Look at five points balanced at 8. "
                                   "Predict what happens to the standard deviation if every point moves 2 units further from 8.",
                "cutaway": "The mean is the balance point where positive and negative gaps cancel to 0. "
                           "Squaring the gaps, averaging them and taking the square root gives the standard deviation σ.",
                "idealised": "The rule: σ = √( Σ(x − mean)² ÷ n )",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Start with the five numbers 4, 6, 8, 10 and 12 around the mean 8."},
                    {"title": "2. Notice", "caption": "Their gaps from 8 are −4, −2, 0, 2 and 4, which add to 0."},
                    {"title": "3. Match the rule", "caption": "Their squares 16, 4, 0, 4 and 16 add to 40, giving variance 40 ÷ 5 = 8."},
                    {"title": "4. Push it further", "caption": "Take the square root: √8 is about 2.83, the typical distance from 8."},
                    {"title": "5. Draw it", "caption": "Draw a number line from 2 to 14, mark the pivot at 8, and label σ ≈ 2.83 on each side."},
                ],
            },
        },
        "atlasLessons": [
            {
                "title": "Chapter 14 · Why unequal widths need frequency density",
                "question": "Why can't we plot the raw count as the bar height when class widths differ?",
                "explanation": "A class that is twice as wide collects items across twice the span. "
                               "Dividing count by class width gives the rate per unit width, so the rectangle's area equals the count.",
                "limits": "The rule: frequency density = count ÷ class width",
            },
            {
                "title": "Chapter 14 · Median and interquartile range",
                "question": "Why do we use the median and interquartile range when a list has an extreme outlier?",
                "explanation": "One huge value pulls the mean and standard deviation toward it, "
                               "but the median and the middle half between Q₁ and Q₃ barely move.",
                "limits": "The rule: IQR = Q₃ − Q₁ covers the middle 50% of the ordered list",
            },
            {
                "title": "Chapter 14 · Squaring the gaps for standard deviation",
                "question": "Why do we square each distance from the mean before averaging?",
                "explanation": "Gaps below the mean are negative and gaps above are positive, so they add to zero. "
                               "Squaring makes every term positive, and the square root at the end restores the original unit.",
                "limits": "The rule: variance = Σ(x − mean)² ÷ n, and standard deviation σ = √variance",
            },
        ],
        "visualMathTips": {},
        "schoolTopics": {
            "10.1": "A time series graph plots measurements in time order with time on the horizontal axis. "
                    "A moving average averages fixed-length windows to smooth regular seasonal swings and show the trend.",
            "10.2": "A stem-and-leaf diagram splits each number into a leading stem and a trailing leaf written in order, with a key. "
                    "Back-to-back diagrams compare two groups on the same stems.",
            "10.3": "A histogram shows continuous grouped data with no gaps between bars. "
                    "When class widths differ, bar height is frequency density = count ÷ class width, so bar area equals the count.",
            "10.4": "To compare two distributions fairly, compare one measure of middle (mean or median) and one measure of spread (interquartile range or standard deviation).",
        },
        "schoolQuestions": {
            "q-oup-ch10-sb": {
                "workedExample": "Step 1: The first class 40 ≤ m < 60 kg has class width 60 − 40 = 20 kg, so its frequency density is 30 ÷ 20 = 1.5.\n"
                                 "Step 2: The second class 60 ≤ m < 70 kg has class width 70 − 60 = 10 kg, so its frequency density is 25 ÷ 10 = 2.5.\n"
                                 "Step 3: The second class has fewer items in total, but they are packed more tightly per kilogram.",
                "fadedPrompt": "First class: 30 ÷ 20 = ___. Second class: 25 ÷ 10 = ___.",
            },
            "q-oup-ch10-wb-focus": {
                "workedExample": "Step 1: There are 7 ordered values: 12, 15, 17, 20, 24, 29, 31. The middle (4th) value is the median, 20.\n"
                                 "Step 2: The lower half 12, 15, 17 has middle Q₁ = 15, and the upper half 24, 29, 31 has middle Q₃ = 29.\n"
                                 "Step 3: The interquartile range is Q₃ − Q₁ = 29 − 15 = 14.",
                "fadedPrompt": "The middle value is the median = ___, and Q₃ − Q₁ = 29 − 15 = ___.",
            },
            "q-oup-ch10-wb-practice": {
                "workedExample": "Step 1: Find the mean of 4, 6, 8, 10, 12: (4 + 6 + 8 + 10 + 12) ÷ 5 = 40 ÷ 5 = 8.\n"
                                 "Step 2: Square the gaps from 8: (−4)² + (−2)² + 0² + 2² + 4² = 16 + 4 + 0 + 4 + 16 = 40.\n"
                                 "Step 3: Divide by 5 to get variance 8, then take the square root: σ = √8 ≈ 2.83.",
                "fadedPrompt": "Mean = 8, variance = 40 ÷ 5 = 8, so standard deviation σ = √8 ≈ ___.",
            },
            "q-oup-ch10-wb-challenge": {
                "workedExample": "Step 1: The class 10 ≤ t < 25 s has class width 25 − 10 = 15 seconds.\n"
                                 "Step 2: Count = frequency density × class width = 3.2 × 15 = 48 observations.",
                "fadedPrompt": "Class width = 25 − 10 = 15 s, so the count is 15 × 3.2 = ___.",
            },
        },
    }


def cards(k):
    """The concept cards chapter 14 teaches."""
    return {
        "time-series": {
            "name": "Time series",
            "aliases": ["time series", "time-series", "time-series graph", "time-series graphs"],
            "oneSentence": "A line graph that plots measurements in time order, with time along the horizontal axis.",
            "picture": "Monthly rainfall plotted from January on the left to December on the right, joined by straight segments.",
            "steps": [
                "Put time in even steps along the horizontal axis.",
                "Plot each measurement above its time.",
                "Join consecutive points to see seasonal peaks and the overall trend.",
            ],
            "workedExample": "Plotting a shop's sales for Quarter 1, Quarter 2, Quarter 3 and Quarter 4 in order makes a time series.",
            "check": {
                "prompt": "On a time-series graph of hourly temperature, which axis carries the hours of the day: 'horizontal' or 'vertical'?",
                "answer": "horizontal",
                "answerKey": k.one(k.words(["horizontal", "bottom", "x-axis"], forbid=["vertical", "y-axis"]),
                                   accepts=["horizontal", "the horizontal axis", "bottom"], rejects=["vertical", "y-axis"]),
            },
            "mixUp": {
                "name": "sorting points by size instead of time",
                "how": "Never rearrange the points from smallest to biggest; keep them in strict time order from left to right.",
            },
            "standsOn": ["coordinates"],
        },
        "moving-average": {
            "name": "Moving average",
            "aliases": ["moving average", "moving averages"],
            "oneSentence": "A series of means taken over a sliding window of fixed length, used to smooth out regular bumps in a time series.",
            "picture": "A 3-day window sliding one day at a time along a week of sales, leaving a smooth trail of averages.",
            "steps": [
                "Add the first k consecutive readings and divide by k.",
                "Slide the window one step right: drop the oldest reading and include the next one.",
                "Plot each mean above the middle of its window.",
            ],
            "workedExample": "For daily temperatures 20, 23, 26, 29, the 3-day moving averages are (20 + 23 + 26) ÷ 3 = 23 and (23 + 26 + 29) ÷ 3 = 26.",
            "check": {
                "prompt": "Find the 3-day moving average of the readings 8, 11 and 17.",
                "answer": "12",
                "answerKey": k.one(k.num("12"), accepts=["12"], rejects=["36", "11", "9"]),
            },
            "mixUp": {
                "with": "mean",
                "how": "A single mean averages the whole list at once; a moving average slides a fixed window along a time series.",
            },
            "standsOn": ["mean", "time-series"],
        },
        "stem-and-leaf-diagram": {
            "name": "Stem-and-leaf diagram",
            "aliases": ["stem-and-leaf diagram", "stem-and-leaf diagrams", "stem-and-leaf", "stem and leaf"],
            "oneSentence": "A table that splits each number into a leading stem and an ordered trailing leaf, showing the shape while keeping exact values.",
            "picture": "A vertical line with tens digits 1, 2, 3 on the left and ordered units digits branching out like leaves on the right.",
            "steps": [
                "Put the leading digits (stems) in a vertical column from smallest to largest.",
                "Write each number's last digit (leaf) next to its stem, in ascending order.",
                "Write a key such as '2 | 5 means 25' so the place value is clear.",
            ],
            "workedExample": "With key 3 | 1 = 31, the row '3 | 1 4 8' stands for the three numbers 31, 34 and 38.",
            "check": {
                "prompt": "In a stem-and-leaf diagram with key 4 | 2 = 42, what number does stem 5 and leaf 7 stand for?",
                "answer": "57",
                "answerKey": k.one(k.num("57"), accepts=["57"], rejects=["5.7", "75", "12"]),
            },
            "mixUp": {
                "name": "leaving out the key or the order",
                "how": "Always sort the leaves from smallest to largest and write a key, or 5 | 7 could mean 57, 5.7 or 570.",
            },
            "standsOn": [],
        },
        "median": {
            "name": "Median",
            "aliases": ["median", "medians"],
            "oneSentence": "The middle number when all the values are lined up in order from smallest to largest.",
            "picture": "Seven stepping stones in order across a stream, with you standing on the 4th stone in the middle.",
            "steps": [
                "Sort the numbers from smallest to largest.",
                "If there are n numbers, find position (n + 1) ÷ 2.",
                "If two numbers share the middle, take the halfway value between them.",
            ],
            "workedExample": "Ordered: 3, 7, 8, 12, 19. There are 5 numbers, so the 3rd number, 8, is the median.",
            "check": {
                "prompt": "Find the median of the five numbers 14, 5, 9, 21, 11.",
                "answer": "11",
                "answerKey": k.one(k.num("11"), accepts=["11"], rejects=["9", "12", "14"]),
            },
            "mixUp": {
                "name": "picking the middle number before sorting",
                "how": "In 14, 5, 9, 21, 11 the middle position is 9 only because the list is muddled. Sort to 5, 9, 11, 14, 21 first to get 11.",
            },
            "standsOn": [],
        },
        "quartile": {
            "name": "Quartile",
            "aliases": ["quartile", "quartiles", "lower quartile", "upper quartile", "Q₁", "Q₃"],
            "oneSentence": "The three cut-points that split an ordered list into four equal quarters: Q₁ at a quarter, Q₂ at the median, and Q₃ at three quarters.",
            "picture": "A ribbon folded in half to mark the median, then each half folded in half again to mark Q₁ and Q₃.",
            "steps": [
                "Sort the list and find the median to split it into a lower half and an upper half.",
                "Find the median of the lower half to get the lower quartile Q₁.",
                "Find the median of the upper half to get the upper quartile Q₃.",
            ],
            "workedExample": "For 2, 4, 6, 8, 10, 12, 14, the median is 8. The lower half 2, 4, 6 has middle Q₁ = 4, and the upper half 10, 12, 14 has middle Q₃ = 12.",
            "check": {
                "prompt": "For the seven ordered numbers 3, 5, 7, 10, 13, 18, 20, what is the upper quartile Q₃?",
                "answer": "18",
                "answerKey": k.one(k.num("18"), accepts=["18", "Q₃ = 18"], rejects=["5", "10", "13"]),
            },
            "mixUp": {
                "with": "median",
                "how": "The median splits the whole list in half; Q₁ and Q₃ split the lower and upper halves in half.",
            },
            "standsOn": ["median"],
        },
        "interquartile-range": {
            "name": "Interquartile range",
            "aliases": ["interquartile range", "interquartile ranges", "IQR"],
            "oneSentence": "The spread of the middle half of the data, found by subtracting the lower quartile from the upper quartile: Q₃ − Q₁.",
            "picture": "A box spanning from Q₁ to Q₃ that holds the middle 50% of values and ignores extreme tails at both ends.",
            "steps": [
                "Find the lower quartile Q₁ and the upper quartile Q₃.",
                "Subtract Q₁ from Q₃: IQR = Q₃ − Q₁.",
                "Use it to compare how spread out the middle half of two groups is.",
            ],
            "workedExample": "When Q₁ = 15 and Q₃ = 29, the interquartile range is 29 − 15 = 14.",
            "check": {
                "prompt": "In a dataset, the lower quartile Q₁ is 12 and the upper quartile Q₃ is 31. What is the interquartile range?",
                "answer": "19",
                "answerKey": k.one(k.num("19"), accepts=["19", "IQR = 19"], rejects=["43", "12", "31"]),
            },
            "mixUp": {
                "name": "subtracting the smallest value from the largest",
                "how": "Largest minus smallest uses the two extreme ends, which one outlier can stretch. Q₃ − Q₁ uses only the middle half.",
            },
            "standsOn": ["quartile"],
            "footing": "spread-and-density",
        },
        "class-width": {
            "name": "Class width",
            "aliases": ["class width", "class widths"],
            "oneSentence": "The span of a continuous group, found by subtracting its lower boundary from its upper boundary.",
            "picture": "A bar stretching from 40 kg to 60 kg on the horizontal axis, spanning a width of 20 kg.",
            "steps": [
                "Read the upper boundary and lower boundary of the group.",
                "Subtract lower boundary from upper boundary.",
                "Use that width when working out frequency density.",
            ],
            "workedExample": "For the group 10 ≤ t < 25 seconds, the class width is 25 − 10 = 15 seconds.",
            "check": {
                "prompt": "What is the class width of the interval 30 ≤ x < 55?",
                "answer": "25",
                "answerKey": k.one(k.num("25"), accepts=["25"], rejects=["85", "30", "55"]),
            },
            "mixUp": {
                "name": "adding the boundaries instead of subtracting",
                "how": "Adding and halving gives the midpoint of the group; subtracting upper minus lower gives the class width.",
            },
            "standsOn": [],
        },
        "frequency-density": {
            "name": "Frequency density",
            "aliases": ["frequency density", "frequency densities"],
            "oneSentence": "How many items fall in each unit of width: count divided by class width.",
            "picture": "30 people spread across a 15-minute window: 30 ÷ 15 = 2 people per minute.",
            "steps": [
                "Find the class width of the group.",
                "Divide the group's count (frequency) by the class width.",
                "Plot that number as the height of the histogram bar.",
            ],
            "workedExample": "A group of width 20 kg holds 30 parcels, so its frequency density is 30 ÷ 20 = 1.5 parcels per kg.",
            "check": {
                "prompt": "A group has class width 10 and count 35. What is its frequency density?",
                "answer": "3.5",
                "answerKey": k.one(k.num("3.5"), accepts=["3.5", "7/2"], rejects=["350", "25", "45"]),
            },
            "mixUp": {
                "name": "multiplying count by width",
                "how": "Divide count by class width to get frequency density; multiply frequency density by class width to get the count back.",
            },
            "standsOn": ["class-width", "ratio"],
            "footing": "spread-and-density",
        },
        "histogram": {
            "name": "Histogram",
            "aliases": ["histogram", "histograms"],
            "oneSentence": "A chart for continuous grouped data with no gaps between bars, where bar height is frequency density and bar area is the count.",
            "picture": "Three touching rectangles of different widths whose areas match the counts in each group.",
            "steps": [
                "Mark the continuous scale along the horizontal axis with no gaps.",
                "Work out frequency density = count ÷ class width for each group.",
                "Draw each rectangle with its class width and its frequency density as height.",
            ],
            "workedExample": "A bar from 10 to 25 (width 15) with height 3.2 has area 15 × 3.2 = 48, so it represents 48 items.",
            "check": {
                "prompt": "A histogram bar has class width 8 and frequency density 5. How many items does the bar represent?",
                "answer": "40",
                "answerKey": k.one(k.num("40"), accepts=["40", "40 items"], rejects=["0.625", "13", "1.6"]),
            },
            "mixUp": {
                "name": "a bar chart for separate categories",
                "how": "A bar chart for categories has gaps and uses height for the count; a histogram has no gaps and uses area for the count.",
            },
            "standsOn": ["frequency-density", "area"],
            "footing": "spread-and-density",
        },
        "sigma": {
            "name": "Sigma",
            "symbol": "Σ",
            "aliases": ["Σ", "sigma"],
            "oneSentence": "The Greek capital letter Σ, used as short notation for 'add up all the values of this kind'.",
            "picture": "A checkout till receipt that adds every item in the basket into one total at the bottom.",
            "steps": [
                "Look at the expression written after Σ.",
                "Work out that expression for each item in the list.",
                "Add all those results together.",
            ],
            "workedExample": "If the values of x are 2, 3 and 5, then Σx = 2 + 3 + 5 = 10, and Σx² = 4 + 9 + 25 = 38.",
            "check": {
                "prompt": "For the three values x = 1, 2 and 4, what is Σx²?",
                "answer": "21",
                "answerKey": k.one(k.num("21"), accepts=["21"], rejects=["7", "49", "14"]),
            },
            "mixUp": {
                "name": "squaring the total instead of adding the squares",
                "how": "Σx² adds the squares 1² + 2² + 4² = 21. Squaring the total (1 + 2 + 4)² = 49 is written (Σx)².",
            },
            "standsOn": [],
        },
        "variance": {
            "name": "Variance",
            "aliases": ["variance", "variances"],
            "oneSentence": "The mean of the squared distances from the mean: Σ(x − mean)² ÷ n.",
            "picture": "Squares built on the distance from each data point to the balance point, then shared equally.",
            "steps": [
                "Subtract the mean from each value to find its gap.",
                "Square every gap so none are negative.",
                "Add the squared gaps and divide by how many values there are.",
            ],
            "workedExample": "For 1, 5, 6 with mean 4, the gaps are −3, 1, 2, their squares are 9, 1, 4, and the variance is (9 + 1 + 4) ÷ 3 = 14/3.",
            "check": {
                "prompt": "Three numbers 2, 5 and 8 have mean 5. Their gaps from 5 are −3, 0 and 3. What is their variance?",
                "answer": "6",
                "answerKey": k.one(k.num("6"), accepts=["6"], rejects=["18", "0", "3"]),
            },
            "mixUp": {
                "with": "standard-deviation",
                "how": "Variance is still in squared units; take its square root to get the standard deviation.",
            },
            "standsOn": ["mean", "sigma", "power"],
        },
        "standard-deviation": {
            "name": "Standard deviation",
            "symbol": "σ",
            "aliases": ["standard deviation", "standard deviations"],
            "oneSentence": "The square root of the variance, written σ: how far values typically sit from the mean, in the data's own units.",
            "picture": "Two arms of length σ reaching left and right from the balance point μ.",
            "steps": [
                "Work out the variance Σ(x − mean)² ÷ n.",
                "Take the square root of the variance.",
                "Read σ in the same units as the original measurements.",
            ],
            "workedExample": "When the variance of five heights is 9 cm², the standard deviation is σ = √9 = 3 cm.",
            "check": {
                "prompt": "A set of test scores has a variance of 16. What is its standard deviation σ?",
                "answer": "4",
                "answerKey": k.one(k.num("4"), accepts=["4", "σ = 4"], rejects=["16", "8", "256"]),
            },
            "mixUp": {
                "with": "variance",
                "how": "Forgetting the square root leaves you with the variance (16) instead of the standard deviation (4).",
            },
            "standsOn": ["variance", "square-root"],
        },
    }


def sums():
    """Every sum chapter 14 and its cards state, recomputed."""
    seven = [12, 15, 17, 20, 24, 29, 31]
    five = [4, 6, 8, 10, 12]
    return [
        # Hook
        ("hook bus averages", (mean_value([19, 20, 21]), mean_value([5, 35])), (20, 20)),
        # Skill card and school unit 10
        ("skill histogram heights", (frequency_density(30, 60 - 40), frequency_density(25, 70 - 60)), (1.5, 2.5)),
        ("skill seven numbers median & IQR", (median_value(seven), quartiles_and_iqr(seven)), (20, (15, 29, 14))),
        # 14.1
        ("moving averages 10, 14, 18, 22", (mean_value([10, 14, 18]), mean_value([14, 18, 22])), (14, 18)),
        ("turn 14.1", (12 + 18 + 24, mean_value([12, 18, 24])), (54, 18)),
        # 14.2
        ("turn 14.2", quartiles_and_iqr([10, 13, 16, 19, 22, 25, 28]), (13, 25, 12)),
        # 14.3
        ("figure wide bin 25, count 30", (45 - 20, frequency_density(30, 25), 25 * 1.2), (25, 1.2, 30.0)),
        ("turn 14.3", (25 - 10, round(15 * 3.2)), (15, 48)),
        # 14.4
        ("five numbers 4, 6, 8, 10, 12",
         (mean_value(five), [x - 8 for x in five], [abs(x - 8) ** 2 for x in five],
          sum((x - 8) ** 2 for x in five), pop_variance(five), round(math.sqrt(8), 2)),
         (8, [-4, -2, 0, 2, 4], [16, 4, 0, 4, 16], 40, 8, 2.83)),
        ("turn 14.4", (mean_value([2, 4, 6, 8]), sum((x - 5) ** 2 for x in [2, 4, 6, 8]), pop_variance([2, 4, 6, 8])),
         (5, 20, 5)),
        # Debate and widgets
        ("debate areas", (10 * 4, 30 * 2), (40, 60)),
        ("widget histogram", (30 // 10, 30 // 15, 30 // 30, 50 // 25), (3, 2, 1, 2)),
        # Cards
        ("moving-average card and check",
         (mean_value([20, 23, 26]), mean_value([23, 26, 29]), 8 + 11 + 17, mean_value([8, 11, 17])),
         (23, 26, 36, 12)),
        ("median card and check", (median_value([3, 7, 8, 12, 19]), median_value([14, 5, 9, 21, 11])), (8, 11)),
        ("quartile card and check",
         (quartiles_and_iqr([2, 4, 6, 8, 10, 12, 14]), quartiles_and_iqr([3, 5, 7, 10, 13, 18, 20])),
         ((4, 12, 8), (5, 18, 13))),
        ("interquartile-range card and check", (29 - 15, 31 - 12, 31 + 12), (14, 19, 43)),
        ("class-width card and check", (25 - 10, 55 - 30, 55 + 30), (15, 25, 85)),
        ("frequency-density card and check", (frequency_density(30, 20), frequency_density(35, 10)), (1.5, 3.5)),
        ("histogram card and check", (round(15 * 3.2), 8 * 5, 5 / 8, 8 / 5), (48, 40, 0.625, 1.6)),
        ("sigma card and check",
         (2 + 3 + 5, 2 ** 2 + 3 ** 2 + 5 ** 2, 1 ** 2 + 2 ** 2 + 4 ** 2, (1 + 2 + 4) ** 2),
         (10, 38, 21, 49)),
        ("variance card and check",
         (mean_value([1, 5, 6]), sum((x - 4) ** 2 for x in [1, 5, 6]), pop_variance([2, 5, 8])),
         (4, 14, 6)),
        ("standard-deviation card and check", (math.isqrt(9), math.isqrt(16), 16 ** 2), (3, 4, 256)),
    ]


def answers():
    """Chapter 14's turn answers and its cards' check answers, computed."""
    return {
        "ch14-s1-turn": mean_value([12, 18, 24]),
        "ch14-s2-turn": quartiles_and_iqr([10, 13, 16, 19, 22, 25, 28])[2],
        "ch14-s3-turn": round((25 - 10) * 3.2),
        "ch14-s4-turn": pop_variance([2, 4, 6, 8]),
        "time-series-check": "horizontal",
        "moving-average-check": mean_value([8, 11, 17]),
        "stem-and-leaf-diagram-check": 5 * 10 + 7,
        "median-check": median_value([14, 5, 9, 21, 11]),
        "quartile-check": quartiles_and_iqr([3, 5, 7, 10, 13, 18, 20])[1],
        "interquartile-range-check": 31 - 12,
        "class-width-check": 55 - 30,
        "frequency-density-check": frequency_density(35, 10),
        "histogram-check": 8 * 5,
        "sigma-check": 1 ** 2 + 2 ** 2 + 4 ** 2,
        "variance-check": pop_variance([2, 5, 8]),
        "standard-deviation-check": math.isqrt(16),
    }
