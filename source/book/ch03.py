"""
Chapter 3, written by hand to docs/CONTENT_BRIEF.md. It carries school units 9 and 12.

Each section teaches one idea in nine steps, in this order: question, idea, picture, reason, name,
example, mistake, turn, sayBack. A section's `teaches` lists the concept cards whose names first
appear in its `name` step. `build(k)` returns the chapter and `cards(k)` its concept cards; both take the
exporter's answer-key helpers. Every example is worked in rupees and whole numbers before any letter appears.

`schoolTopics` and `schoolQuestions` rewrite the topic summaries, worked examples and faded prompts of
school units 9 and 12. The answer keys and stuck sheets stay in the exporter.
"""

from book.arithmetic import Fraction, compound, gcd, lcm, multiplier, nearest, percent, share


def build(k):
    return {
        "number": 3,
        "title": "Ratio, percentages and growth",
        "subtitle": "School book chapters 9 and 12 · Sharing in parts, a percentage change as one multiplication, "
                    "and money that grows on itself",
        "hookSummary": "A price goes up by 20% and then down by 20%. Why is it not back where it started?",
        "beyondSchoolBook": False,
        "skillCard": {
            "skill": "Sharing, scaling and growing amounts",
            "sheCan": {
                "prompt": "With no calculator: share ₹720 in the ratio 4 : 5. A phone costs ₹6,900 after a 15% rise. "
                          "What did it cost before? About how many years does money take to double at 3% a year?",
                "answer": "₹320 and ₹400. ₹6,000. About 24 years.",
            },
            "whyItMatters": "Prices, recipes, maps, discounts and savings all work by multiplying. "
                            "Someone who can read a percentage change is hard to fool in a shop or a bank.",
            "standsOn": [
                "Chapter 2: fractions, decimals and dividing by a decimal",
                "Multiplying and dividing by 10, 100 and 1,000",
                "Finding 10% and 50% of an amount",
            ],
            "unlocks": [
                "Chapter 5: finding an unknown amount by working backwards",
                "Chapter 11: making a shape bigger, where every length is multiplied by the same number",
                "Chapter 15: chances, which are compared as fractions and percentages",
            ],
        },
        "intuitionToFormula": {
            "concreteAction": "Set the interest rate to 8%. The amber lines show what ₹1,000 becomes after 20 years. "
                              "They give two totals: one for simple interest and one for compound interest.",
            "ahaInvariant": "Simple interest adds ₹80 every year, so 20 years add ₹1,600. "
                            "Compound interest multiplies by 1.08 every year, so each year adds more than the last. "
                            "Adding gives ₹2,600. Multiplying gives ₹4,661.",
            "formulaDisplay": "1 part = total ÷ (a + b),   A = P × mⁿ",
            "termMappings": [
                {"symbol": "a + b", "visualPart": "The red and blue boxes", "colorRole": "red",
                 "meaning": "All the parts of the ratio, counted together"},
                {"symbol": "P", "visualPart": "The ₹1,000 in the first amber line", "colorRole": "amber",
                 "meaning": "The amount at the start"},
                {"symbol": "m", "visualPart": "The interest rate slider", "colorRole": "amber",
                 "meaning": "The multiplier for one year, which is 1.08 for a rate of 8%"},
                {"symbol": "n", "visualPart": "The 20 years", "colorRole": "amber",
                 "meaning": "The number of years, so the number of times you multiply"},
                {"symbol": "A", "visualPart": "The compound total", "colorRole": "amber",
                 "meaning": "The amount at the end"},
            ],
            "atlasFigureRef": "maths/ch03-ratios-compounding/index.html",
        },
        "sections": [
            {
                "heading": "3.1 Sharing in parts",
                "figure": True,
                "teaches": ["ratio"],
                "steps": [
                    {"kind": "question",
                     "text": "Kym and Aarav sell lemonade at a fair and make ₹320. Kym worked for 3 hours and Aarav for 5. "
                             "Splitting the money in half would not be fair. How should they share it?"},
                    {"kind": "idea",
                     "text": "Pay for each hour worked. There were 3 + 5 = 8 hours in all, so cut the ₹320 into 8 equal parts. "
                             "Each part is ₹40. Kym gets 3 parts and Aarav gets 5 parts."},
                    {"kind": "picture",
                     "text": "Draw a bar of 3 equal boxes for Kym. Under it, draw a bar of 5 boxes of the same size for Aarav. "
                             "The 8 boxes together hold ₹320, so each box holds ₹40. "
                             "In the figure, set the parts for A to 3 and the parts for B to 5."},
                    {"kind": "reason",
                     "text": "Why add the 3 and the 5 first? The money is shared among all the parts, not among the two people. "
                             "Once you know what 1 part is worth, each share is a multiplication. "
                             "Kym gets 3 × ₹40 = ₹120 and Aarav gets 5 × ₹40 = ₹200. Check: ₹120 + ₹200 = ₹320."},
                    {"kind": "name",
                     "text": "A comparison like 3 to 5 is called a ratio, and it is written 3 : 5. "
                             "It does not say how much each person gets. It says how the amounts compare. "
                             "You can simplify a ratio the way you simplify a fraction: divide every part by a common factor. "
                             "So 6 : 10 is the same ratio as 3 : 5."},
                    {"kind": "example",
                     "text": "Share ₹4,500 among three cousins in the ratio 2 : 3 : 4. There are 2 + 3 + 4 = 9 parts. "
                             "One part is ₹4,500 ÷ 9 = ₹500. "
                             "The shares are 2 × ₹500 = ₹1,000, 3 × ₹500 = ₹1,500 and 4 × ₹500 = ₹2,000. "
                             "Check: the three shares add up to ₹4,500."},
                    {"kind": "mistake",
                     "text": "The tempting step is to divide by one of the numbers in the ratio, such as ₹320 ÷ 3. "
                             "But 3 is not the number of parts. There are 8. "
                             "A second trap is to read 3 : 5 as the fraction 3/5. "
                             "Kym gets 3 parts out of 8, which is 3/8 of the money."},
                    {"kind": "turn",
                     "text": "Meera and Zoya share 42 stickers in the ratio 2 : 5. How many stickers does Zoya get?",
                     "answer": "30",
                     "answerKey": k.one(k.num("30"), accepts=["30", "30 stickers", "= 30"], rejects=["12", "6", "21", "105"])},
                    {"kind": "sayBack",
                     "text": "To share in a ratio, add the parts, find what one part is worth, then multiply."},
                ],
            },
            {
                "heading": "3.2 Find one first",
                "teaches": ["unitary-method", "direct-proportion"],
                "steps": [
                    {"kind": "question",
                     "text": "A recipe for 4 people needs 300 g of paneer. Kym is cooking for 10 people. "
                             "How much paneer does she need?"},
                    {"kind": "idea",
                     "text": "Find the amount for 1 person first. 300 g ÷ 4 = 75 g each. "
                             "Then multiply by the number of people: 10 × 75 g = 750 g. "
                             "Going through one turns every question of this kind into the same two steps."},
                    {"kind": "picture",
                     "text": "Draw two number lines, one above the other. The top line counts people: 0, 1, 4 and 10. "
                             "The bottom line shows the paneer: 0 g, 75 g, 300 g and 750 g. "
                             "Each number on the bottom line is 75 times the number above it."},
                    {"kind": "reason",
                     "text": "Why is this allowed? Each person eats the same amount, so the paneer grows in step with the people. "
                             "Multiply the people by 2.5 and the paneer is multiplied by 2.5 too. "
                             "You can check: 4 × 2.5 = 10 and 300 × 2.5 = 750."},
                    {"kind": "name",
                     "text": "Finding the value of one first is called the unitary method. "
                             "Two amounts are in direct proportion when multiplying one by a number multiplies the other by the same number. "
                             "Here the paneer is directly proportional to the people. "
                             "The amount for one, 75 g, stays the same all the way along."},
                    {"kind": "example",
                     "text": "5 notebooks cost ₹180. What do 8 cost? One notebook costs ₹180 ÷ 5 = ₹36. "
                             "So 8 notebooks cost 8 × ₹36 = ₹288. "
                             "Check that the answer is sensible: 8 is less than double 5, and ₹288 is less than double ₹180."},
                    {"kind": "mistake",
                     "text": "A common slip is to divide the wrong way round and work out 5 ÷ 180. "
                             "Say what you want in words first. Rupees for each notebook means rupees ÷ notebooks. "
                             "A second trap: not everything doubles together. "
                             "A taxi charges ₹50 to start and ₹15 for each kilometre. "
                             "A 2 km trip costs ₹80 and a 4 km trip costs ₹110, not ₹160."},
                    {"kind": "turn",
                     "text": "6 pencils cost ₹45. How much do 10 pencils cost?",
                     "answer": "₹75",
                     "answerKey": k.one(k.num("75"), accepts=["75", "₹75", "75 rupees"], rejects=["7.5", "49", "450", "27"])},
                    {"kind": "sayBack",
                     "text": "Find what one is worth, then multiply by how many you need."},
                ],
            },
            {
                "heading": "3.3 When more means less",
                "teaches": ["inverse-proportion"],
                "steps": [
                    {"kind": "question",
                     "text": "4 painters can paint the school hall in 6 days. The head teacher hires 8 painters instead. "
                             "Will the job take 12 days?"},
                    {"kind": "idea",
                     "text": "No. More painters share the same work, so the job takes less time, not more. "
                             "The hall needs 4 × 6 = 24 days of one painter's work. "
                             "Shared among 8 painters, that is 24 ÷ 8 = 3 days."},
                    {"kind": "picture",
                     "text": "Think of the hall as 24 squares of wall. One painter paints one square a day. "
                             "4 painters cover 4 squares a day and finish in 6 days. "
                             "8 painters cover 8 squares a day and finish in 3 days. The 24 squares never change."},
                    {"kind": "reason",
                     "text": "Why multiply here, when the last section divided? Ask what stays the same. "
                             "For the paneer, the amount for each person stayed the same, so you divided to find it. "
                             "For the painters, the whole job stays the same, so you multiply to find it."},
                    {"kind": "name",
                     "text": "Two amounts are in inverse proportion when multiplying one by a number divides the other by the same number. "
                             "Double the painters and the time halves. "
                             "Multiply the two amounts together and the answer is always the same. Here it is 24."},
                    {"kind": "example",
                     "text": "A sack of rice feeds 12 hostel students for 10 days. How long does it feed 15 students? "
                             "The sack holds 12 × 10 = 120 days of rice for one student. "
                             "Shared among 15 students, it lasts 120 ÷ 15 = 8 days. "
                             "Check that the answer is sensible: more students, so fewer days."},
                    {"kind": "mistake",
                     "text": "The tempting step is the unitary method in its usual order: 10 ÷ 12, then × 15. "
                             "That gives 12.5 days, which says more students make the rice last longer. "
                             "Before any sum, ask one question. If this number goes up, does the other go up or down?"},
                    {"kind": "turn",
                     "text": "A tank of water lasts 20 goats for 9 days. How many days does it last 30 goats?",
                     "answer": "6 days",
                     "answerKey": k.one(k.num("6"), accepts=["6", "6 days", "= 6"], rejects=["13.5", "9", "180", "4"])},
                    {"kind": "sayBack",
                     "text": "When more of one thing means less of the other, find the total first, then share it out."},
                ],
            },
            {
                "heading": "3.4 One multiplication for a change",
                "figure": True,
                "teaches": ["percentage-multiplier"],
                "steps": [
                    {"kind": "question",
                     "text": "A pair of shoes costs ₹2,000. In June the price goes up by 20%. "
                             "In the July sale it comes down by 20%. Is it back to ₹2,000?"},
                    {"kind": "idea",
                     "text": "No. The rise is 20% of ₹2,000, which is ₹400, so the price becomes ₹2,400. "
                             "The cut is 20% of ₹2,400, which is ₹480. The sale price is ₹1,920. "
                             "The second 20% was taken from a bigger amount, so it took off more."},
                    {"kind": "picture",
                     "text": "Draw a bar of 10 boxes for ₹2,000. A 20% rise adds 2 boxes, which makes 12. "
                             "Now cut the new bar into 10 equal pieces and take 2 of them away. "
                             "Each piece is bigger than an old box, so you take away more than you added."},
                    {"kind": "reason",
                     "text": "There is a shorter way to see it. After a 20% rise you have 100% + 20% = 120% of the price. "
                             "120% is 120/100, which is 1.2. So a 20% rise is the same as multiplying by 1.2. "
                             "After a 20% cut you have 80% left, so you multiply by 0.8. "
                             "Both changes together: 1.2 × 0.8 = 0.96."},
                    {"kind": "name",
                     "text": "The one number you multiply by to make a percentage change is called the percentage multiplier. "
                             "For a rise, add the percentage to 100% and write the result as a decimal. "
                             "For a fall, take it away from 100%. "
                             "A 5% rise has the multiplier 1.05 and a 30% fall has the multiplier 0.7."},
                    {"kind": "example",
                     "text": "A phone costs ₹15,000 and its price rises by 8%. The multiplier is 1.08. "
                             "₹15,000 × 1.08 = ₹16,200. Now go back to the ₹2,000 shoes, which went up 20% and then down 20%. "
                             "The multiplier for both changes together is 0.96. "
                             "₹2,000 × 0.96 = ₹1,920, which matches. "
                             "0.96 is 96%, so the two changes make a 4% fall. In the figure, read the green line."},
                    {"kind": "mistake",
                     "text": "There are two traps. First, a 5% rise is × 1.05, not × 1.5 and not × 0.05. "
                             "Multiplying by 0.05 finds the 5% on its own. Second, percentages in a row do not add. "
                             "Two rises of 10% are not a rise of 20%. They make 1.1 × 1.1 = 1.21, which is a 21% rise."},
                    {"kind": "turn",
                     "text": "A bag costs ₹800. Its price is cut by 15%. What is the new price?",
                     "answer": "₹680",
                     "answerKey": k.one(k.num("680"), accepts=["680", "₹680", "680 rupees"], rejects=["120", "785", "920", "68"])},
                    {"kind": "sayBack",
                     "text": "A percentage change is one multiplication, and changes in a row multiply."},
                ],
            },
            {
                "heading": "3.5 Working backwards",
                "teaches": ["reverse-percentage"],
                "steps": [
                    {"kind": "question",
                     "text": "In a sale, everything is 20% off. A kurta costs ₹1,200 in the sale. What did it cost before?"},
                    {"kind": "idea",
                     "text": "It is tempting to add 20% of ₹1,200, which gives ₹1,440. "
                             "But the 20% was taken off the old price, not the sale price. "
                             "The sale price is 80% of the old price. So 80% is ₹1,200, 10% is ₹150 and 100% is ₹1,500."},
                    {"kind": "picture",
                     "text": "Draw a bar of 10 boxes for the old price. Cross out 2 boxes for the 20% off. "
                             "The 8 boxes left hold ₹1,200, so each box holds ₹150. All 10 boxes hold ₹1,500."},
                    {"kind": "reason",
                     "text": "The sale multiplied the old price by 0.8. To undo a multiplication, you divide. "
                             "₹1,200 ÷ 0.8 = ₹1,500. Adding 20% back does not undo it, because that multiplies by 1.2. "
                             "And 0.8 × 1.2 = 0.96, not 1."},
                    {"kind": "name",
                     "text": "Finding the amount before a percentage change is called a reverse percentage. "
                             "Work out the multiplier for the change, then divide the new amount by it. "
                             "Dividing by the multiplier always takes you back to the start."},
                    {"kind": "example",
                     "text": "After a 12% rise, a month's rent is ₹5,600. What was the old rent? "
                             "The multiplier for a 12% rise is 1.12, so work out ₹5,600 ÷ 1.12. "
                             "Multiply both numbers by 100 to get 560,000 ÷ 112, which is 5,000. "
                             "The old rent was ₹5,000. Check forwards: ₹5,000 × 1.12 = ₹5,600."},
                    {"kind": "mistake",
                     "text": "The trap is to take the percentage of the wrong amount. "
                             "12% of ₹5,600 is ₹672, and ₹5,600 − ₹672 = ₹4,928. Test that answer by going forwards. "
                             "₹4,928 × 1.12 = ₹5,519.36, which is not ₹5,600. "
                             "The 12% in the question was 12% of the old rent, the number you are looking for."},
                    {"kind": "turn",
                     "text": "After a 10% rise, a cinema ticket costs ₹330. What did it cost before the rise?",
                     "answer": "₹300",
                     "answerKey": k.one(k.num("300"), accepts=["300", "₹300", "300 rupees"], rejects=["297", "363", "33", "320"])},
                    {"kind": "sayBack",
                     "text": "To undo a percentage change, divide by its multiplier."},
                ],
            },
            {
                "heading": "3.6 Growth on growth",
                "figure": True,
                "teaches": ["simple-interest", "compound-growth", "rule-of-72"],
                "steps": [
                    {"kind": "question",
                     "text": "Kym's grandmother puts ₹1,000 in a bank that pays 8% interest a year. She leaves it there for 20 years. "
                             "Kym says the bank adds ₹80 a year, so it will grow to ₹2,600. Is she right?"},
                    {"kind": "idea",
                     "text": "Only if the bank pays on the first ₹1,000 each year and nothing more. Most banks do better than that. "
                             "They add the interest to the account, and the next year they pay 8% on the new, bigger amount. "
                             "Year 1 ends on ₹1,080. Year 2 adds 8% of ₹1,080, which is ₹86.40, not ₹80."},
                    {"kind": "picture",
                     "text": "Make a table with one row for each year, starting from ₹1,000. "
                             "Each row is the row above × 1.08: ₹1,080, then ₹1,166.40, then ₹1,259.71. "
                             "The steps get bigger every year, because each one is 8% of a bigger number."},
                    {"kind": "reason",
                     "text": "Each year multiplies by 1.08, so 20 years multiply by 1.08 twenty times. "
                             "A calculator gives that as about 4.66. So the ₹1,000 becomes about ₹4,661. "
                             "That is far more than ₹2,600, and the only difference is interest earning interest."},
                    {"kind": "name",
                     "text": "Interest paid only on the starting amount is simple interest. It adds the same sum every year. "
                             "Interest paid on the growing total is compound interest, and growth of this kind is compound growth. "
                             "It multiplies by the same number every year. "
                             "A quick guide is the rule of 72: divide 72 by the yearly percentage to estimate the years needed to double."},
                    {"kind": "example",
                     "text": "₹20,000 is saved at 5% compound interest for 2 years. The multiplier is 1.05 each year. "
                             "₹20,000 × 1.05 = ₹21,000, and ₹21,000 × 1.05 = ₹22,050. The interest earned is ₹2,050. "
                             "Simple interest would have paid 2 × ₹1,000 = ₹2,000. "
                             "Now use the rule of 72 on the ₹1,000 that Kym's grandmother saved at 8%. "
                             "72 ÷ 8 = 9, so her money doubles about every 9 years. "
                             "In the figure, set the interest rate to 8% and read the amber lines."},
                    {"kind": "mistake",
                     "text": "The trap is to treat compound growth as adding. 8% a year for 20 years is not 160% in total. "
                             "It is × 1.08 twenty times, which is a rise of about 366%. "
                             "The same trap works against you with a loan. A debt at 24% a year doubles in about 3 years."},
                    {"kind": "turn",
                     "text": "₹2,000 is saved at 5% compound interest a year. How much is in the account after 2 years?",
                     "answer": "₹2,205",
                     "answerKey": k.one(k.num("2205"), accepts=["2205", "₹2,205", "2,205"],
                                        rejects=["2200", "2100", "205", "2210"])},
                    {"kind": "sayBack",
                     "text": "Compound growth multiplies by the same number each year, so the growth itself grows."},
                ],
            },
        ],
        "callouts": [
            {"kind": "predict", "title": "Predict first",
             "body": "Before you touch the figure: ₹1,000 is left for 20 years at 8%. Guess the total with compound interest. "
                     "Then compare your guess with the amber lines."},
            {"kind": "check", "title": "Explain it",
             "body": "Explain to a friend why sharing ₹90 in the ratio 1 : 2 does not give anyone ₹45."},
            {"kind": "careful", "title": "Watch out for the wrong 100%",
             "body": "A percentage is always a percentage of something. "
                     "Before you calculate, ask which amount is the 100%: the old price or the new one."},
        ],
        "debate": {
            "id": "debate-ch03-percentages",
            "oupUnitNumber": 9,
            "title": "The price before the rise",
            "contextPrompt": "After a 25% rise, a month's bus pass costs ₹1,000. "
                             "Ishaan and Tara each work out what it cost before the rise.",
            "speakerAName": "Ishaan",
            "speakerAClaim": "25% of ₹1,000 is ₹250. Take it off, and the old price was ₹750.",
            "speakerBName": "Tara",
            "speakerBClaim": "The new price is 125% of the old one. ₹1,000 ÷ 1.25 = ₹800.",
            "choices": [
                {"id": "ch03-a", "speakerLabel": "Ishaan is right (₹750)",
                 "reasoningStatement": "A 25% rise is undone by a 25% cut.",
                 "isCorrect": False,
                 "socraticRebuttal": "Test it by going forwards. ₹750 × 1.25 = ₹937.50, not ₹1,000. "
                                     "The 25% in the question was 25% of the old price. Is that the same as 25% of ₹1,000?"},
                {"id": "ch03-b", "speakerLabel": "Tara is right (₹800)",
                 "reasoningStatement": "The rise multiplied the old price by 1.25, so dividing by 1.25 undoes it.",
                 "isCorrect": True,
                 "socraticRebuttal": "Yes. Check it forwards: 25% of ₹800 is ₹200, and ₹800 + ₹200 = ₹1,000."},
                {"id": "ch03-c", "speakerLabel": "Neither. It was ₹975.",
                 "reasoningStatement": "25% means 25, so take ₹25 off.",
                 "isCorrect": False,
                 "socraticRebuttal": "25% is not ₹25. It is 25 out of every 100, so its size depends on the price. "
                                     "What is 25% of ₹800?"},
            ],
            "invariantTakeaway": "To undo a percentage change, divide by its multiplier. Taking the same percentage off does not work.",
        },
        "keyTerms": [
            "Percentage", "Ratio", "Unitary method", "Direct proportion", "Inverse proportion", "Percentage multiplier",
            "Reverse percentage", "Simple interest", "Compound growth", "Rule of 72",
        ],
        "widgets": ["w_singapore_ratio_bar_model", "w_compound_multiplier_machine"],
        "widgetText": {
            "w_singapore_ratio_bar_model": {
                "title": "Sharing in a ratio",
                "challengePrompt": "Set the parts for A to 2 and the parts for B to 6. Every part is worth ₹40. "
                                   "Predict how much A and B each get. Then read the two bars.",
                "cutaway": "Every box is 1 part and holds ₹40. A has 2 boxes and B has 6, so A gets ₹80 and B gets ₹240. "
                           "Together that is 8 parts, which is ₹320.",
                "idealised": "The rule: 1 part = total ÷ number of parts",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Set the parts for A to 3 and the parts for B to 5."},
                    {"title": "2. Notice", "caption": "Every box is the same size and holds ₹40. A has 3 boxes and B has 5."},
                    {"title": "3. Match the rule", "caption": "There are 3 + 5 = 8 parts and ₹320 in all. ₹320 ÷ 8 = ₹40 for one part."},
                    {"title": "4. Push it further", "caption": "Set A to 6 and B to 2. The total is still ₹320. Who gets more now, and how much?"},
                    {"title": "5. Draw it", "caption": "Draw the two bars for 3 : 5 in your journal and write ₹40 in every box."},
                ],
            },
            "w_compound_multiplier_machine": {
                "title": "Adding or multiplying, for 20 years",
                "challengePrompt": "Set the interest rate to 10%. Predict what ₹1,000 becomes in 20 years with simple interest. "
                                   "Then guess the compound total, and read the amber lines.",
                "cutaway": "Simple interest adds the same ₹100 every year, so 20 years add ₹2,000. "
                           "Compound interest multiplies by 1.1 every year. Twenty multiplications turn ₹1,000 into ₹6,727.",
                "idealised": "The rule: multiply by the same number once for each year",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Set the interest rate to 8%. The amber lines show ₹2,600 with simple interest and ₹4,661 with compound."},
                    {"title": "2. Notice", "caption": "Compound interest gives ₹2,061 more, from the same ₹1,000 and the same rate."},
                    {"title": "3. Match the rule", "caption": "Simple interest adds 20 lots of ₹80. Compound interest multiplies by 1.08 twenty times."},
                    {"title": "4. Push it further", "caption": "Set the rate to 12%. The rule of 72 says the money doubles every 6 years. Is the compound total more than ₹8,000?"},
                    {"title": "5. Draw it", "caption": "Copy the first three years at 8% into your journal: ₹1,080, ₹1,166.40 and ₹1,259.71."},
                ],
            },
        },
        "atlasLessons": [
            {
                "title": "Chapter 3 · Sharing in a ratio",
                "question": "Why do you add the parts of a ratio before you share?",
                "explanation": "The amount is cut into equal parts, and the ratio says how many parts each person takes. "
                               "Adding tells you how many parts there are in all. Dividing by that number gives the size of one part.",
                "limits": "The rule: 1 part = total ÷ number of parts",
            },
            {
                "title": "Chapter 3 · Up 20%, then down 20%",
                "question": "Why does a 20% rise followed by a 20% fall leave you with less?",
                "explanation": "The rise multiplies by 1.2 and the fall multiplies by 0.8. Together they multiply by 0.96. "
                               "The fall is 20% of the bigger amount, so it takes off more than the rise put on.",
                "limits": "The result: 1.2 × 0.8 = 0.96, a 4% fall",
            },
            {
                "title": "Chapter 3 · The doubling rule",
                "question": "Why does money at 8% a year double in about 9 years?",
                "explanation": "Each year multiplies the money by 1.08. Nine of those multiplications come to almost exactly 2. "
                               "The rule of 72 finds the 9 without the long sum: 72 ÷ 8 = 9.",
                "limits": "The result: 1.08 multiplied nine times is about 2",
            },
        ],
        "visualMathTips": {},
        "schoolTopics": {
            "9.1": "Multiplying by a number between 0 and 1 makes a positive amount smaller. "
                   "0.4 of something is less than all of it.",
            "9.2": "Dividing by a number between 0 and 1 makes a positive amount bigger. "
                   "Scale both numbers up until you divide by a whole number: 7 ÷ 0.25 is 700 ÷ 25.",
            "9.3": "A percentage change is one multiplication. A 15% rise is × 1.15 and a 15% fall is × 0.85. "
                   "To go back to the old amount, divide by the multiplier. Changes in a row multiply.",
            "9.4": "Fractions, decimals and percentages are three ways to write one number: 1/4 = 0.25 = 25%. "
                   "Pick the form that makes the sum shortest.",
            "12.1": "A length in metres is 100 times as many centimetres. "
                    "An area has two lengths, so multiply by 100 twice: 1 m² = 10,000 cm². "
                    "A volume has three, so 1 m³ = 1,000,000 cm³.",
            "12.2": "Put both amounts in the same unit first. "
                    "Then divide every part of the ratio by a common factor until no more will go.",
            "12.3": "Add the parts, find what one part is worth, then multiply for each share. "
                    "If you are told a difference and not the total, match it to the difference in parts.",
            "12.4": "In direct proportion, both amounts are multiplied by the same number. "
                    "In inverse proportion, one is multiplied and the other is divided, so multiplying them together always gives the same answer.",
        },
        "schoolQuestions": {
            "q-oup-ch09-sb": {
                "workedExample": "Step 1: A 15% discount leaves 100% − 15% = 85% of the old price. The multiplier is 0.85.\n"
                                 "Step 2: So the old price × 0.85 = ₹2,040.\n"
                                 "Step 3: To undo × 0.85, divide by 0.85. Multiply both numbers by 100 first: 204,000 ÷ 85 = 2,400.\n"
                                 "Step 4: The old price was ₹2,400. Check forwards: ₹2,400 × 0.85 = ₹2,040.",
                "fadedPrompt": "The old price × 0.85 = ₹2,040, so the old price is ₹2,040 ÷ 0.85 = ___.",
            },
            "q-oup-ch09-wb-focus": {
                "workedExample": "Step 1: You are dividing by a number less than 1, so expect an answer bigger than 36.\n"
                                 "Step 2: Multiply both numbers by 100 to clear the decimal. 36 ÷ 0.15 becomes 3,600 ÷ 15.\n"
                                 "Step 3: 15 × 24 = 360, so 360 ÷ 15 = 24 and 3,600 ÷ 15 = 240.\n"
                                 "Step 4: Check: 240 × 0.15 = 36.",
                "fadedPrompt": "36 ÷ 0.15 is the same as 3,600 ÷ 15, which is ___.",
            },
            "q-oup-ch09-wb-practice": {
                "workedExample": "Step 1: A 20% rise has the multiplier 1.2.\n"
                                 "Step 2: A 20% fall has the multiplier 0.8.\n"
                                 "Step 3: Changes in a row multiply. 1.2 × 0.8 = 0.96.\n"
                                 "Step 4: 0.96 is 96% of the starting price, so the price has fallen by 4%. The overall change is −4%.",
                "fadedPrompt": "The two multipliers are 1.2 and 0.8. Multiply them and compare with 1. The overall change is ___.",
            },
            "q-oup-ch09-wb-challenge": {
                "workedExample": "Step 1: The multiplier for 10% growth is 1.1.\n"
                                 "Step 2: Year 1: ₹50,000 × 1.1 = ₹55,000.\n"
                                 "Step 3: Year 2: ₹55,000 × 1.1 = ₹60,500. Year 3: ₹60,500 × 1.1 = ₹66,550.\n"
                                 "Step 4: The interest is the final amount take away the start. ₹66,550 − ₹50,000 = ₹16,550.",
                "fadedPrompt": "After 3 years the ₹50,000 has grown to ₹66,550. The interest earned is ___.",
            },
            "q-oup-ch12-sb": {
                "workedExample": "Step 1: Meera has 8 parts and Kym has 3 parts, so Meera has 8 − 3 = 5 parts more.\n"
                                 "Step 2: Those 5 parts are the ₹1,350. So 1 part = ₹1,350 ÷ 5 = ₹270.\n"
                                 "Step 3: There are 3 + 5 + 8 = 16 parts in all.\n"
                                 "Step 4: The total prize is 16 × ₹270 = ₹4,320.",
                "fadedPrompt": "5 parts = ₹1,350, so 1 part = ₹270. All 16 parts together make ___.",
            },
            "q-oup-ch12-wb-focus": {
                "workedExample": "Step 1: 1 m = 100 cm.\n"
                                 "Step 2: A square 1 m by 1 m is 100 cm by 100 cm. So 1 m² = 100 × 100 = 10,000 cm².\n"
                                 "Step 3: Multiply the area by 10,000. 3.5 × 10,000 = 35,000.\n"
                                 "Step 4: 3.5 m² = 35,000 cm².",
                "fadedPrompt": "1 m² = 10,000 cm², so 3.5 m² = ___.",
            },
            "q-oup-ch12-wb-practice": {
                "workedExample": "Step 1: More pumps share the same job, so the time goes down. This is inverse proportion.\n"
                                 "Step 2: Find the whole job. 6 pumps × 10 hours = 60 hours of work for one pump.\n"
                                 "Step 3: Share the job among 15 pumps. 60 ÷ 15 = 4.\n"
                                 "Step 4: 15 pumps take 4 hours. Check: 15 × 4 = 60, the same job.",
                "fadedPrompt": "The job is 6 × 10 = 60 hours of work for one pump. With 15 pumps it takes ___.",
            },
            "q-oup-ch12-wb-challenge": {
                "workedExample": "Step 1: B is 4 in one ratio and 6 in the other. The lowest common multiple of 4 and 6 is 12.\n"
                                 "Step 2: Multiply both parts of 3 : 4 by 3, so that B becomes 12. A : B = 9 : 12.\n"
                                 "Step 3: Multiply both parts of 6 : 7 by 2, so that B becomes 12. B : C = 12 : 14.\n"
                                 "Step 4: B now matches, so join them. A : B : C = 9 : 12 : 14. No factor divides all three, so stop.",
                "fadedPrompt": "A : B = 9 : 12 and B : C = 12 : 14, so A : B : C = ___.",
            },
        },
    }


def cards(k):
    """The concept cards this chapter teaches that stand on other cards. Percentage is in bedrock.py."""
    return {
        "ratio": {
            "name": "Ratio",
            "aliases": ["ratio", "ratios"],
            "oneSentence": "A way to compare two or more amounts by saying how many parts each one has.",
            "picture": "A glass of nimbu pani uses 1 part lemon juice to 4 parts water, so the ratio is 1 : 4. "
                       "A big jug with 3 cups of juice and 12 cups of water tastes the same.",
            "steps": [
                "Write the amounts in the same unit, in the order the question names them.",
                "Divide every part by a common factor to simplify. 12 : 18 becomes 2 : 3.",
                "To share an amount in a ratio, add the parts and find what one part is worth.",
                "Multiply that by each person's number of parts.",
            ],
            "workedExample": "Share 60 sweets in the ratio 2 : 3. There are 2 + 3 = 5 parts. One part is 60 ÷ 5 = 12 sweets. "
                             "The shares are 2 × 12 = 24 and 3 × 12 = 36.",
            "check": {
                "prompt": "₹35 is shared in the ratio 2 : 5. How many rupees is the smaller share?",
                "answer": "₹10",
                "answerKey": k.one(k.num("10"), accepts=["10", "₹10", "= 10"], rejects=["25", "5", "17.5", "7"]),
            },
            "mixUp": {
                "with": "fraction",
                "how": "The ratio 2 : 3 compares one part with the other. As a fraction of the whole, the first share is 2/5, not 2/3.",
            },
            "standsOn": ["fraction", "factor"],
            "footing": "ratio-and-proportion",
        },
        "unitary-method": {
            "name": "Unitary method",
            "aliases": ["unitary method"],
            "oneSentence": "Solving a problem by first finding what one of something is worth.",
            "picture": "Six samosas cost ₹90 and you want four. First find the price of one: ₹90 ÷ 6 = ₹15. "
                       "Then four samosas cost 4 × ₹15 = ₹60.",
            "steps": [
                "Write down what you know: how many items, and how much in total.",
                "Divide to find the amount for one.",
                "Multiply by the number you need.",
                "Check that the answer is sensible. More items should cost more.",
            ],
            "workedExample": "A car uses 15 litres of petrol to travel 240 km. How far does it go on 4 litres? "
                             "On 1 litre it goes 240 ÷ 15 = 16 km. On 4 litres it goes 4 × 16 = 64 km.",
            "check": {
                "prompt": "5 mangoes cost ₹150. What do 7 mangoes cost, in rupees?",
                "answer": "₹210",
                "answerKey": k.one(k.num("210"), accepts=["210", "₹210", "= 210"], rejects=["30", "152", "1050"]),
            },
            "mixUp": {
                "name": "dividing the wrong way round",
                "how": "Say what you want in words first. Rupees for each mango means rupees ÷ mangoes: 150 ÷ 5, not 5 ÷ 150.",
            },
            "standsOn": ["ratio"],
            "footing": "multiply-or-divide",
        },
        "direct-proportion": {
            "name": "Direct proportion",
            "aliases": ["direct proportion", "directly proportional"],
            "oneSentence": "Two amounts are in direct proportion when multiplying one by a number multiplies the other by the same number.",
            "picture": "Petrol costs ₹100 a litre. 2 litres cost ₹200 and 10 litres cost ₹1,000. "
                       "Whatever happens to the litres, the same thing happens to the cost.",
            "steps": [
                "Test the link: if one amount doubles, does the other double too?",
                "Divide to find the amount for one.",
                "Multiply by the new number.",
                "Or find what one amount was multiplied by, and multiply the other amount by the same number.",
            ],
            "workedExample": "A map shows 3 cm for every 12 km of road. How long is a road that measures 5 cm on the map? "
                             "1 cm stands for 12 ÷ 3 = 4 km. So 5 cm stands for 5 × 4 = 20 km.",
            "check": {
                "prompt": "8 identical tiles weigh 20 kg. How many kilograms do 12 tiles weigh?",
                "answer": "30 kg",
                "answerKey": k.one(k.num("30"), accepts=["30", "30 kg", "= 30"], rejects=["24", "2.5", "240"]),
            },
            "mixUp": {
                "with": "inverse-proportion",
                "how": "In direct proportion both amounts go up together. "
                       "In inverse proportion one goes up as the other comes down, like workers and the days a job takes.",
            },
            "standsOn": ["ratio", "unitary-method"],
            "footing": "ratio-and-proportion",
        },
        "inverse-proportion": {
            "name": "Inverse proportion",
            "aliases": ["inverse proportion", "inversely proportional"],
            "oneSentence": "Two amounts are in inverse proportion when multiplying one by a number divides the other by the same number.",
            "picture": "A box of 24 laddoos is shared equally. With 4 friends, each gets 6. With 8 friends, each gets 3. "
                       "Twice the friends means half the laddoos each.",
            "steps": [
                "Test the link: if one amount doubles, does the other halve?",
                "Multiply the pair you know. That total never changes.",
                "Divide the total by the new number.",
            ],
            "workedExample": "5 machines print a newspaper run in 6 hours. How long do 3 machines take? "
                             "The job is 5 × 6 = 30 hours of work for one machine. 3 machines take 30 ÷ 3 = 10 hours. "
                             "Fewer machines, so more time.",
            "check": {
                "prompt": "A stack of hay lasts 12 cows for 10 days. How many days does it last 8 cows?",
                "answer": "15 days",
                "answerKey": k.one(k.num("15"), accepts=["15", "15 days", "= 15"], rejects=["6.67", "10", "120", "6"]),
            },
            "mixUp": {
                "with": "direct-proportion",
                "how": "Ask what happens when one amount goes up. If the other goes down, it is inverse proportion. "
                       "Finding the amount for one by dividing will then give nonsense.",
            },
            "standsOn": ["ratio", "direct-proportion"],
            "footing": "ratio-and-proportion",
        },
        "percentage-multiplier": {
            "name": "Percentage multiplier",
            "aliases": ["percentage multiplier", "percentage multipliers", "multiplier", "multipliers"],
            "oneSentence": "The one number you multiply by to raise or lower an amount by a percentage.",
            "picture": "A ₹500 shirt is 10% off, so you pay 90% of the price. 90% is 0.9. "
                       "The sale price is ₹500 × 0.9 = ₹450, in one multiplication.",
            "steps": [
                "Start from 100%. For a rise, add the percentage. For a fall, take it away.",
                "Divide by 100 to write the result as a decimal. 112% is 1.12 and 85% is 0.85.",
                "Multiply the amount by that decimal.",
                "For changes one after another, multiply by each multiplier in turn.",
            ],
            "workedExample": "A ₹1,200 bill has 18% tax added. 100% + 18% = 118%, so the multiplier is 1.18. "
                             "₹1,200 × 1.18 = ₹1,416.",
            "check": {
                "prompt": "What is the multiplier for a 35% fall?",
                "answer": "0.65",
                "answerKey": k.one(k.num("0.65"), accepts=["0.65", ".65", "= 0.65"], rejects=["0.35", "1.35", "35", "65"]),
            },
            "mixUp": {
                "name": "the percentage on its own",
                "how": "Multiplying by 0.18 finds the tax alone. Multiplying by 1.18 finds the bill with the tax already added.",
            },
            "standsOn": ["percentage"],
            "footing": "percentages",
        },
        "reverse-percentage": {
            "name": "Reverse percentage",
            "aliases": ["reverse percentage", "reverse percentages"],
            "oneSentence": "Working back from the amount after a percentage change to the amount before it.",
            "picture": "A shop adds 10% to every price, and a toy now costs ₹220. "
                       "The ₹220 is 110% of the old price. So 10% is ₹20, and the old price was ₹200.",
            "steps": [
                "Decide which amount is the 100%. It is the amount before the change.",
                "Find the multiplier for the change. A 10% rise is × 1.1.",
                "Divide the new amount by the multiplier.",
                "Check by going forwards from your answer.",
            ],
            "workedExample": "After a 30% cut, a kite costs ₹140. The multiplier is 0.7. ₹140 ÷ 0.7 = ₹200. "
                             "Check: 30% of ₹200 is ₹60, and ₹200 − ₹60 = ₹140.",
            "check": {
                "prompt": "After a 50% rise, a ticket costs ₹60. What did it cost before, in rupees?",
                "answer": "₹40",
                "answerKey": k.one(k.num("40"), accepts=["40", "₹40", "= 40"], rejects=["30", "90", "120"]),
            },
            "mixUp": {
                "name": "taking the same percentage off",
                "how": "Taking 10% off ₹220 gives ₹198, not ₹200. The 10% that was added was 10% of the old price.",
            },
            "standsOn": ["percentage-multiplier"],
            "footing": "percentages",
        },
        "simple-interest": {
            "name": "Simple interest",
            "aliases": ["simple interest"],
            "oneSentence": "Interest worked out on the starting amount only, so it adds the same sum every year.",
            "picture": "You lend a cousin ₹1,000 at 5% simple interest. Every year the interest is 5% of ₹1,000, which is ₹50. "
                       "After 3 years it comes to ₹150.",
            "steps": [
                "Find the interest for one year: the percentage of the starting amount.",
                "Multiply by the number of years.",
                "Add the starting amount if the question asks for the total.",
            ],
            "workedExample": "₹4,000 earns 6% simple interest for 5 years. One year's interest is 6% of ₹4,000, which is ₹240. "
                             "Five years give 5 × ₹240 = ₹1,200. The total is ₹4,000 + ₹1,200 = ₹5,200.",
            "check": {
                "prompt": "₹2,000 earns 5% simple interest a year. How many rupees of interest is that in 3 years?",
                "answer": "₹300",
                "answerKey": k.one(k.num("300"), accepts=["300", "₹300", "= 300"], rejects=["100", "2300", "315.25", "30"]),
            },
            "mixUp": {
                "with": "compound-growth",
                "how": "Simple interest pays on the starting amount only. Compound interest also pays on the interest already earned.",
            },
            "standsOn": ["percentage"],
        },
        "compound-growth": {
            "name": "Compound growth",
            "aliases": ["compound growth", "compound interest", "compounding"],
            "oneSentence": "Growth where each increase is worked out on the new, bigger total.",
            "picture": "You put ₹2,000 in a bank at 10% a year. Year 1 adds ₹200. "
                       "Year 2 adds ₹220, because the bank now pays on ₹2,200. The interest earns interest.",
            "steps": [
                "Find the multiplier for one year. For 10% growth it is 1.1.",
                "Multiply the starting amount by it once for each year.",
                "For many years, a calculator's power key does the repeated multiplying.",
                "Take away the starting amount if the question asks for the interest alone.",
            ],
            "workedExample": "₹8,000 grows at 5% compound interest for 2 years. The multiplier is 1.05. "
                             "₹8,000 × 1.05 = ₹8,400, and ₹8,400 × 1.05 = ₹8,820. The interest is ₹8,820 − ₹8,000 = ₹820.",
            "check": {
                "prompt": "₹1,000 grows by 20% a year, compounded. How many rupees is it after 2 years?",
                "answer": "₹1,440",
                "answerKey": k.one(k.num("1440"), accepts=["1440", "₹1,440", "1,440"], rejects=["1400", "1200", "440", "1040"]),
            },
            "mixUp": {
                "with": "simple-interest",
                "how": "Simple interest on ₹1,000 at 20% adds ₹200 a year, which gives ₹1,400 after 2 years. "
                       "Compound growth gives ₹1,440, because year 2 also pays on the first ₹200.",
            },
            "standsOn": ["percentage-multiplier", "power"],
        },
        "rule-of-72": {
            "name": "Rule of 72",
            "aliases": ["rule of 72"],
            "oneSentence": "A quick estimate: divide 72 by the yearly percentage growth to get the years needed to double.",
            "picture": "A bank pays 6% a year. 72 ÷ 6 = 12, so savings double in about 12 years. "
                       "At 12% a year they double in about 6 years. Double the rate, half the wait.",
            "steps": [
                "Take the percentage growth for one year.",
                "Divide 72 by it.",
                "The answer is roughly the number of years the amount takes to double.",
                "It is an estimate. It works best for rates between about 4% and 12%.",
            ],
            "workedExample": "Prices rise by 4% a year. How long until they double? 72 ÷ 4 = 18, so about 18 years. "
                             "The long sum agrees: 1.04 multiplied 18 times is about 2.03.",
            "check": {
                "prompt": "Money grows at 9% a year. About how many years does it take to double?",
                "answer": "8 years",
                "answerKey": k.one(k.num("8"), accepts=["8", "8 years", "about 8"], rejects=["9", "81", "648", "18"]),
            },
            "mixUp": {
                "name": "an exact answer",
                "how": "At 8% the rule says 9 years, and 1.08 multiplied 9 times is 1.999, which is very close. "
                       "At 36% the rule says 2 years, but the money has only grown 1.85 times by then.",
            },
            "standsOn": ["compound-growth"],
        },
    }


def sums():
    """Every sum chapter 3, its cards and its school unit text state, recomputed. test_book_maths.py checks computed == stated."""
    up20, down20 = multiplier(20), multiplier(-20)
    year = [compound(1000, 8, n) for n in range(4)]
    return [
        # Skill card
        ("₹720 in the ratio 4 : 5", share(720, 4, 5), [320, 400]),
        ("₹6,900 after a 15% rise", 6900 / multiplier(15), 6000),
        ("690,000 ÷ 115", Fraction(690000, 115), 6000),
        ("72 ÷ 3", Fraction(72, 3), 24),
        ("3% a year for 24 years is about double", round(float(compound(1, 3, 24)), 1), 2.0),
        # Bridge, widgets and Atlas lessons
        ("simple interest on ₹1,000 at 8%", (percent(8) * 1000, 20 * 80, 1000 + 20 * 80), (80, 1600, 2600)),
        ("multiplier for 8%", multiplier(8), Fraction("1.08")),
        ("₹1,000 at 8% compound for 20 years", nearest(compound(1000, 8, 20)), 4661),
        ("2 parts and 6 parts at ₹40", (2 * 40, 6 * 40, 2 + 6, (2 + 6) * 40), (80, 240, 8, 320)),
        ("3 parts and 5 parts at ₹40", (3 + 5, (3 + 5) * 40, Fraction(320, 8)), (8, 320, 40)),
        ("6 parts and 2 parts at ₹40", ((6 + 2) * 40, 6 * 40 > 2 * 40), (320, True)),
        ("simple interest on ₹1,000 at 10%", (percent(10) * 1000, 20 * 100), (100, 2000)),
        ("multiplier for 10%", multiplier(10), Fraction("1.1")),
        ("₹1,000 at 10% compound for 20 years", nearest(compound(1000, 10, 20)), 6727),
        ("compound beats simple at 8% by", 4661 - 2600, 2061),
        ("72 ÷ 12", Fraction(72, 12), 6),
        ("₹1,000 at 12% for 20 years is more than ₹8,000", nearest(compound(1000, 12, 20)) > 8000, True),
        ("first three years at 8%", [year[1], year[2], round(float(year[3]), 2)], [1080, Fraction("1166.40"), 1259.71]),
        ("1.2 × 0.8", up20 * down20, Fraction("0.96")),
        ("0.96 is a 4% fall", (1 - up20 * down20) * 100, 4),
        ("72 ÷ 8", Fraction(72, 8), 9),
        ("1.08 multiplied nine times is about 2", round(float(compound(1, 8, 9)), 2), 2.0),
        # 3.1 Sharing in parts
        ("3 + 5 hours", 3 + 5, 8),
        ("₹320 in 8 parts", Fraction(320, 8), 40),
        ("₹320 in the ratio 3 : 5", share(320, 3, 5), [120, 200]),
        ("3 × ₹40 and 5 × ₹40", (3 * 40, 5 * 40, 120 + 200), (120, 200, 320)),
        ("6 : 10 simplifies to 3 : 5", (6 // gcd(6, 10), 10 // gcd(6, 10)), (3, 5)),
        ("2 + 3 + 4 parts", 2 + 3 + 4, 9),
        ("₹4,500 ÷ 9", Fraction(4500, 9), 500),
        ("₹4,500 in the ratio 2 : 3 : 4", share(4500, 2, 3, 4), [1000, 1500, 2000]),
        ("the three shares", 1000 + 1500 + 2000, 4500),
        ("Kym's share as a fraction", Fraction(120, 320), Fraction(3, 8)),
        ("42 stickers in the ratio 2 : 5", share(42, 2, 5), [12, 30]),
        # 3.2 Find one first
        ("300 g ÷ 4", Fraction(300, 4), 75),
        ("10 × 75 g", 10 * 75, 750),
        ("the paneer line", [n * 75 for n in (0, 1, 4, 10)], [0, 75, 300, 750]),
        ("4 × 2.5 and 300 × 2.5", (4 * Fraction("2.5"), 300 * Fraction("2.5")), (10, 750)),
        ("₹180 ÷ 5", Fraction(180, 5), 36),
        ("8 × ₹36", 8 * 36, 288),
        ("8 is less than double 5, ₹288 less than double ₹180", (8 < 2 * 5, 288 < 2 * 180), (True, True)),
        ("taxi fares for 2 km and 4 km", (50 + 15 * 2, 50 + 15 * 4, 2 * (50 + 15 * 2)), (80, 110, 160)),
        ("6 pencils cost ₹45, so 10 cost", Fraction(45, 6) * 10, 75),
        # 3.3 When more means less
        ("4 painters for 6 days", 4 * 6, 24),
        ("24 ÷ 8", Fraction(24, 8), 3),
        ("8 painters finish 24 squares in", Fraction(24, 8), 3),
        ("12 students for 10 days", 12 * 10, 120),
        ("120 ÷ 15", Fraction(120, 15), 8),
        ("10 ÷ 12 × 15", Fraction(10, 12) * 15, Fraction("12.5")),
        ("20 goats for 9 days, then 30 goats", Fraction(20 * 9, 30), 6),
        # 3.4 One multiplication for a change
        ("20% of ₹2,000", percent(20) * 2000, 400),
        ("₹2,000 + ₹400", 2000 + 400, 2400),
        ("20% of ₹2,400", percent(20) * 2400, 480),
        ("₹2,400 − ₹480", 2400 - 480, 1920),
        ("10 boxes and 2 more", 10 + 2, 12),
        ("120%", (100 + 20, Fraction(120, 100)), (120, Fraction("1.2"))),
        ("80% left", multiplier(-20), Fraction("0.8")),
        ("multipliers for a 5% rise and a 30% fall", (multiplier(5), multiplier(-30)), (Fraction("1.05"), Fraction("0.7"))),
        ("₹15,000 × 1.08", 15000 * multiplier(8), 16200),
        ("₹2,000 × 0.96", 2000 * up20 * down20, 1920),
        ("1.1 × 1.1", multiplier(10) ** 2, Fraction("1.21")),
        ("1.21 is a 21% rise", (multiplier(10) ** 2 - 1) * 100, 21),
        ("₹800 cut by 15%", 800 * multiplier(-15), 680),
        # 3.5 Working backwards
        ("20% of ₹1,200 added on", 1200 + percent(20) * 1200, 1440),
        ("80%, 10% and 100% of the old price", (Fraction(1200, 8), 10 * Fraction(1200, 8)), (150, 1500)),
        ("₹1,200 ÷ 0.8", 1200 / multiplier(-20), 1500),
        ("0.8 × 1.2", multiplier(-20) * multiplier(20), Fraction("0.96")),
        ("multiplier for a 12% rise", multiplier(12), Fraction("1.12")),
        ("5,600 × 100 and 1.12 × 100", (5600 * 100, multiplier(12) * 100), (560000, 112)),
        ("560,000 ÷ 112", Fraction(560000, 112), 5000),
        ("₹5,000 × 1.12", 5000 * multiplier(12), 5600),
        ("12% of ₹5,600", percent(12) * 5600, 672),
        ("₹5,600 − ₹672", 5600 - 672, 4928),
        ("₹4,928 × 1.12", 4928 * multiplier(12), Fraction("5519.36")),
        ("₹330 after a 10% rise", 330 / multiplier(10), 300),
        # 3.6 Growth on growth
        ("₹80 a year for 20 years", 1000 + 20 * 80, 2600),
        ("year 1 at 8%", year[1], 1080),
        ("8% of ₹1,080", percent(8) * 1080, Fraction("86.40")),
        ("1.08 twenty times is about 4.66", round(float(compound(1, 8, 20)), 2), 4.66),
        ("₹20,000 at 5% for 2 years", (compound(20000, 5, 1), compound(20000, 5, 2)), (21000, 22050)),
        ("interest on ₹20,000", compound(20000, 5, 2) - 20000, 2050),
        ("simple interest on ₹20,000", (percent(5) * 20000, 2 * 1000), (1000, 2000)),
        ("8% a year for 20 years, added", 8 * 20, 160),
        ("a rise of about 366%", round(float(compound(1, 8, 20) - 1) * 100), 366),
        ("72 ÷ 24", Fraction(72, 24), 3),
        ("24% a year for 3 years is close to double", round(float(compound(1, 24, 3)), 1), 1.9),
        ("₹2,000 at 5% compound for 2 years", compound(2000, 5, 2), 2205),
        # Who is right? The price before the rise
        ("25% of ₹1,000", percent(25) * 1000, 250),
        ("₹1,000 − ₹250", 1000 - 250, 750),
        ("125%", multiplier(25), Fraction("1.25")),
        ("₹1,000 ÷ 1.25", 1000 / multiplier(25), 800),
        ("₹750 × 1.25", 750 * multiplier(25), Fraction("937.50")),
        ("25% of ₹800", (percent(25) * 800, 800 + 200), (200, 1000)),
        ("₹1,000 − ₹25", 1000 - 25, 975),
        ("the callout: ₹90 in the ratio 1 : 2", share(90, 1, 2), [30, 60]),
        # Cards: ratio, unitary-method
        ("1 : 4 and 3 : 12", Fraction(1, 4), Fraction(3, 12)),
        ("12 : 18 simplifies to 2 : 3", (12 // gcd(12, 18), 18 // gcd(12, 18)), (2, 3)),
        ("60 sweets in the ratio 2 : 3", (2 + 3, Fraction(60, 5), share(60, 2, 3)), (5, 12, [24, 36])),
        ("₹35 in the ratio 2 : 5", share(35, 2, 5), [10, 25]),
        ("first share of 2 : 3 as a fraction", Fraction(2, 2 + 3), Fraction(2, 5)),
        ("six samosas for ₹90", (Fraction(90, 6), 4 * 15), (15, 60)),
        ("240 km on 15 litres", (Fraction(240, 15), 4 * 16), (16, 64)),
        ("5 mangoes for ₹150", Fraction(150, 5) * 7, 210),
        # Cards: direct-proportion, inverse-proportion
        ("petrol at ₹100 a litre", (2 * 100, 10 * 100), (200, 1000)),
        ("3 cm for 12 km", (Fraction(12, 3), 5 * 4), (4, 20)),
        ("8 tiles weigh 20 kg, so 12 weigh", Fraction(20, 8) * 12, 30),
        ("24 laddoos", (Fraction(24, 4), Fraction(24, 8)), (6, 3)),
        ("5 machines for 6 hours", (5 * 6, Fraction(30, 3)), (30, 10)),
        ("12 cows for 10 days, then 8 cows", Fraction(12 * 10, 8), 15),
        # Cards: percentage-multiplier, reverse-percentage
        ("10% off ₹500", (multiplier(-10), 500 * multiplier(-10)), (Fraction("0.9"), 450)),
        ("112% and 85% as decimals", (Fraction(112, 100), Fraction(85, 100)), (Fraction("1.12"), Fraction("0.85"))),
        ("18% tax on ₹1,200", (100 + 18, multiplier(18), 1200 * multiplier(18)), (118, Fraction("1.18"), 1416)),
        ("multiplier for a 35% fall", multiplier(-35), Fraction("0.65")),
        ("₹220 after 10% is added", (Fraction(220, 11), 220 / multiplier(10)), (20, 200)),
        ("₹140 after a 30% cut", (multiplier(-30), 140 / multiplier(-30)), (Fraction("0.7"), 200)),
        ("30% of ₹200", (percent(30) * 200, 200 - 60), (60, 140)),
        ("₹60 after a 50% rise", 60 / multiplier(50), 40),
        ("10% off ₹220", 220 * multiplier(-10), 198),
        # Cards: simple-interest, compound-growth, rule-of-72
        ("5% of ₹1,000 for 3 years", (percent(5) * 1000, 3 * 50), (50, 150)),
        ("6% of ₹4,000 for 5 years", (percent(6) * 4000, 5 * 240, 4000 + 1200), (240, 1200, 5200)),
        ("5% of ₹2,000 for 3 years", 3 * percent(5) * 2000, 300),
        ("the compound trap for that check", compound(2000, 5, 3) - 2000, Fraction("315.25")),
        ("₹2,000 at 10%", (percent(10) * 2000, 2000 + 200, percent(10) * 2200), (200, 2200, 220)),
        ("₹8,000 at 5% for 2 years", (compound(8000, 5, 1), compound(8000, 5, 2), compound(8000, 5, 2) - 8000),
         (8400, 8820, 820)),
        ("₹1,000 at 20% for 2 years", compound(1000, 20, 2), 1440),
        ("simple interest at 20% for 2 years", 1000 + 2 * percent(20) * 1000, 1400),
        ("72 ÷ 6 and 72 ÷ 12", (Fraction(72, 6), Fraction(72, 12)), (12, 6)),
        ("72 ÷ 4", Fraction(72, 4), 18),
        ("1.04 multiplied 18 times", round(float(compound(1, 4, 18)), 2), 2.03),
        ("72 ÷ 9", Fraction(72, 9), 8),
        ("1.08 multiplied 9 times", round(float(compound(1, 8, 9)), 3), 1.999),
        ("72 ÷ 36", Fraction(72, 36), 2),
        ("1.36 multiplied twice", round(float(compound(1, 36, 2)), 2), 1.85),
        # School unit 9: topic summaries and worked examples
        ("7 ÷ 0.25", (7 / Fraction("0.25"), Fraction(700, 25)), (28, 28)),
        ("multipliers for 15% up and down", (multiplier(15), multiplier(-15)), (Fraction("1.15"), Fraction("0.85"))),
        ("1/4", (Fraction(1, 4), Fraction(1, 4) * 100), (Fraction("0.25"), 25)),
        ("the jacket", (100 - 15, 2040 * 100, Fraction(204000, 85), 2400 * multiplier(-15)), (85, 204000, 2400, 2040)),
        ("36 ÷ 0.15", (36 * 100, 15 * 24, Fraction(360, 15), 36 / Fraction("0.15"), 240 * Fraction("0.15")),
         (3600, 360, 24, 240, 36)),
        ("up 20% then down 20%", (up20, down20, up20 * down20, (up20 * down20 - 1) * 100),
         (Fraction("1.2"), Fraction("0.8"), Fraction("0.96"), -4)),
        ("₹50,000 at 10% for 3 years", [compound(50000, 10, n) for n in (1, 2, 3)], [55000, 60500, 66550]),
        ("interest on ₹50,000", compound(50000, 10, 3) - 50000, 16550),
        # School unit 12: topic summaries and worked examples
        ("1 m² in cm² and 1 m³ in cm³", (100 * 100, 100 ** 3), (10000, 1000000)),
        ("the prize", (8 - 3, Fraction(1350, 5), 3 + 5 + 8, 16 * 270), (5, 270, 16, 4320)),
        ("3.5 m² in cm²", Fraction("3.5") * 10000, 35000),
        ("the pumps", (6 * 10, Fraction(60, 15), 15 * 4), (60, 4, 60)),
        ("A : B : C", (lcm(4, 6), (3 * 3, 4 * 3), (6 * 2, 7 * 2), gcd(gcd(9, 12), 14)), (12, (9, 12), (12, 14), 1)),
    ]


def answers():
    """Chapter 3's turn answers and its cards' check answers, computed."""
    return {
        "ch03-s1-turn": share(42, 2, 5)[1],
        "ch03-s2-turn": Fraction(45, 6) * 10,
        "ch03-s3-turn": Fraction(20 * 9, 30),
        "ch03-s4-turn": 800 * multiplier(-15),
        "ch03-s5-turn": 330 / multiplier(10),
        "ch03-s6-turn": compound(2000, 5, 2),
        "ratio-check": share(35, 2, 5)[0],
        "unitary-method-check": Fraction(150, 5) * 7,
        "direct-proportion-check": Fraction(20, 8) * 12,
        "inverse-proportion-check": Fraction(12 * 10, 8),
        "percentage-multiplier-check": multiplier(-35),
        "reverse-percentage-check": 60 / multiplier(50),
        "simple-interest-check": 3 * percent(5) * 2000,
        "compound-growth-check": compound(1000, 20, 2),
        "rule-of-72-check": Fraction(72, 9),
    }
