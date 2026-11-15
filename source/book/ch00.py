"""
Chapter 0, written by hand to docs/CONTENT_BRIEF.md.

It goes beyond the Stage 8 school book (plan decision D4), so it leans only on bedrock cards
(risk R4). Each section teaches one idea in the nine steps, in order. A section's `teaches` lists
the cards whose names first appear in its `name` step. `cards(k)` holds the cards this chapter
teaches; `sums()` and `answers()` let test_book_maths recompute every number the text states.
"""


def build(k):
    return {
        "number": 0,
        "title": "Sets and logic",
        "subtitle": "Beyond the school book · How to sort things into groups, count overlaps without counting twice, "
                    "and test an if-then claim",
        "hookSummary": "How do you count a crowd without counting anyone twice?",
        "beyondSchoolBook": True,
        "skillCard": {
            "skill": "Sorting, counting overlaps and testing claims",
            "sheCan": {
                "prompt": "With no calculator: in a class of 30, 17 play cricket, 12 play football and 5 play both. "
                          "How many play neither? Then find a number that breaks the claim "
                          "\"if a number is odd, it is a multiple of 3\".",
                "answer": "17 + 12 − 5 = 24 play a sport, so 6 play neither. "
                          "5 breaks the claim, because it is odd and not a multiple of 3. So do 1, 7, 11 and 13.",
            },
            "whyItMatters": "Working out chances means counting outcomes in groups that overlap, so it needs this way of counting. "
                            "A proof in geometry is a chain of if-then steps. "
                            "One counterexample stops you from trusting a false rule.",
            "standsOn": ["Multiples and times tables", "Adding and taking away up to 100",
                         "Powers of 2, like 2³ = 8"],
            "unlocks": [
                "Chapter 8: angles and proof, built from if-then steps",
                "Chapter 15: counting outcomes, often drawn as Venn diagrams",
                "Chapter 16: Bayes, which counts people in overlapping groups",
            ],
        },
        "intuitionToFormula": {
            "concreteAction": "Move the three sliders: how many play cricket, how many play football, and how many play both. "
                              "Watch the four parts of the class change. They always add up to 30.",
            "ahaInvariant": "The students who play both are inside the cricket count and inside the football count. "
                            "Add the two counts and they are counted twice. Take the overlap away once and everyone counts once.",
            "formulaDisplay": "n(A ∪ B) = n(A) + n(B) − n(A ∩ B),   (A ∪ B)′ = A′ ∩ B′",
            "termMappings": [
                {"symbol": "n(A) + n(B)", "visualPart": "The red circle and the blue circle", "colorRole": "red",
                 "meaning": "Adds the middle twice, once with each circle"},
                {"symbol": "− n(A ∩ B)", "visualPart": "The amber middle", "colorRole": "amber",
                 "meaning": "Takes the middle away once, so it counts once"},
                {"symbol": "(A ∪ B)′", "visualPart": "The green box outside both circles", "colorRole": "green",
                 "meaning": "Everyone who is in neither group"},
            ],
            "atlasFigureRef": "maths/ch00-sets-logic/index.html",
        },
        "sections": [
            {
                "heading": "0.1 What makes a set",
                "teaches": ["set", "member", "universal-set"],
                "steps": [
                    {"kind": "question",
                     "text": "Your class has 30 students. The teacher asks everyone in the cricket team to stand up. "
                             "How does each student know whether to stand?"},
                    {"kind": "idea",
                     "text": "Each student checks one rule: am I in the cricket team? The answer is yes or no, never maybe. "
                             "A rule like that sorts the whole class into in and out. "
                             "The days of the week that start with T work the same way. Tuesday and Thursday are in, and nothing else is."},
                    {"kind": "picture",
                     "text": "On paper, write the group inside curly brackets: {Tuesday, Thursday}. "
                             "Order does not matter, so {Thursday, Tuesday} is the same group. Writing a day twice adds nothing. "
                             "Now draw a box around everything you could have chosen from, all seven days."},
                    {"kind": "reason",
                     "text": "Why must the rule be so strict? Try the rule \"tall students\". Is a student of 150 cm tall? "
                             "People will disagree, so nobody can count the group. "
                             "A clear yes-or-no rule is what makes counting possible."},
                    {"kind": "name",
                     "text": "A collection with a clear rule for what is in it is called a set. "
                             "Each thing in it is a member, also called an element. "
                             "The sign ∈ means \"is a member of\", so Tuesday ∈ {Tuesday, Thursday}. "
                             "The box of everything you could choose from is the universal set, written ξ."},
                    {"kind": "example",
                     "text": "Let ξ be the whole numbers from 1 to 10. Find the even numbers in ξ. "
                             "Test each number against the rule: is it even? 2, 4, 6, 8 and 10 pass. "
                             "So the set is {2, 4, 6, 8, 10}, and it has 5 members."},
                    {"kind": "mistake",
                     "text": "It is tempting to count a repeated thing twice. The letters of the word MUMBAI make the set {M, U, B, A, I}. "
                             "That is 5 members, not 6. M appears twice in the word, but once in the set."},
                    {"kind": "turn",
                     "text": "ξ is the whole numbers from 1 to 20. How many members does the set of multiples of 3 in ξ have?",
                     "answer": "6",
                     "answerKey": k.one(k.num("6"), accepts=["6", "= 6"], rejects=["7", "3", "20"])},
                    {"kind": "sayBack",
                     "text": "A set is a collection with a yes-or-no rule, and each thing in it counts once."},
                ],
            },
            {
                "heading": "0.2 Where two sets meet",
                "teaches": ["venn-diagram", "intersection", "union"],
                "figure": True,
                "steps": [
                    {"kind": "question",
                     "text": "In a class of 30, some students play cricket and some play football. A few play both. "
                             "You draw one circle for each sport. Where do the students who play both go?"},
                    {"kind": "idea",
                     "text": "Each name goes in one place on the page. Cricket only goes in one circle, and football only in the other. "
                             "A student who plays both has to be inside both circles at once. "
                             "So the circles must overlap, and those students go in the shared middle."},
                    {"kind": "picture",
                     "text": "In the figure, move the sliders to 18 in A, 15 in B and 7 in both. Circle A is cricket and circle B is football. "
                             "The middle holds the 7 who play both. The green box around everything holds all 30 students."},
                    {"kind": "reason",
                     "text": "Why overlap the circles rather than draw them apart? "
                             "A student who plays both needs a spot that is inside both circles. "
                             "Two circles drawn apart have no such spot. Overlapping them makes one."},
                    {"kind": "name",
                     "text": "A drawing of sets as circles inside a box is a Venn diagram. "
                             "The middle part, in A and in B, is the intersection, written A ∩ B. "
                             "Everything in A or B or both is the union, written A ∪ B. "
                             "To tell them apart, ∪ looks like the letter U, for union. ∩ is the same shape upside down."},
                    {"kind": "example",
                     "text": "Let A = {1, 2, 3, 4} and B = {3, 4, 5}. "
                             "A ∩ B holds what is in both lists, so A ∩ B = {3, 4}. "
                             "A ∪ B holds everything in either list, once each, so A ∪ B = {1, 2, 3, 4, 5}. "
                             "Check: 3 and 4 appear once in the union, not twice."},
                    {"kind": "mistake",
                     "text": "It is tempting to read \"A or B\" as one of them but not both. In sets, \"or\" always includes the middle. "
                             "A student who plays cricket and football is in A ∪ B. Leave the middle out and your count comes up short."},
                    {"kind": "turn",
                     "text": "A = {2, 4, 6, 8} and B = {4, 8, 12}. How many members does A ∪ B have?",
                     "answer": "5",
                     "answerKey": k.one(k.num("5"), accepts=["5", "= 5"], rejects=["7", "2", "3"])},
                    {"kind": "sayBack",
                     "text": "The intersection is what two sets share, and the union is everything in either one, counted once."},
                ],
            },
            {
                "heading": "0.3 Counting without counting twice",
                "teaches": ["complement"],
                "figure": True,
                "steps": [
                    {"kind": "question",
                     "text": "A survey of 30 students finds that 18 play cricket and 15 play football. "
                             "But 18 + 15 = 33, which is more than the whole class. Did the survey go wrong?"},
                    {"kind": "idea",
                     "text": "Nothing went wrong. The 7 students who play both were counted with the cricket players, and again with the football players. "
                             "Count them once and 18 + 15 − 7 = 26 play at least one sport. "
                             "That leaves 30 − 26 = 4 who play neither."},
                    {"kind": "picture",
                     "text": "In the figure, keep 18 in A, 15 in B and 7 in both. Read the three parts inside the circles: "
                             "11 play cricket only, 7 play both and 8 play football only. "
                             "11 + 7 + 8 = 26. The 4 in the green box outside the circles make the total 30."},
                    {"kind": "reason",
                     "text": "Why take the overlap away exactly once? Adding the two circles' counts adds the middle twice, once with each circle. "
                             "Every other part is added once. Taking the middle away once leaves every student counted exactly once."},
                    {"kind": "name",
                     "text": "Write n(A) for the number of members of A. The rule is n(A ∪ B) = n(A) + n(B) − n(A ∩ B). "
                             "Everything in the universal set that is not in A is the complement of A, written A′. "
                             "The 4 students outside both circles make up (A ∪ B)′."},
                    {"kind": "example",
                     "text": "In a group of 40 people, 25 like tea, 22 like coffee and 10 like both. How many like neither? "
                             "First the union: 25 + 22 − 10 = 37 like at least one. "
                             "Then the complement: 40 − 37 = 3 like neither."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to forget the people outside the circles. In the tea survey, 37 is not the whole group. "
                             "The 3 who like neither still belong to the 40. "
                             "Before you finish, check that the four parts add up to the total: 15 + 10 + 12 + 3 = 40."},
                    {"kind": "turn",
                     "text": "In a class of 32, 20 take art, 15 take music and 6 take both. How many take neither?",
                     "answer": "3",
                     "answerKey": k.one(k.num("3"), accepts=["3", "= 3"], rejects=["29", "-3", "9"])},
                    {"kind": "sayBack",
                     "text": "Add the two circles, take away the overlap once, and whatever is left of the total sits outside both."},
                ],
            },
            {
                "heading": "0.4 Sets inside sets",
                "teaches": ["subset", "power-set"],
                "steps": [
                    {"kind": "question",
                     "text": "A dosa stall offers three fillings: potato, cheese and onion. "
                             "You may choose any mix of them, or none at all. How many different dosas can you order?"},
                    {"kind": "idea",
                     "text": "List them by size. There is 1 plain dosa with nothing. There are 3 with one filling. "
                             "There are 3 with two fillings: potato and cheese, potato and onion, cheese and onion. "
                             "There is 1 with all three. That is 1 + 3 + 3 + 1 = 8 dosas."},
                    {"kind": "picture",
                     "text": "On paper, go through the fillings one at a time. Potato is in or out: 2 choices. "
                             "Cheese is in or out, which doubles it to 4. Onion is in or out, which doubles it to 8."},
                    {"kind": "reason",
                     "text": "Why does each new filling double the count? Every order you had before now comes in two versions. "
                             "One leaves the new filling out and one puts it in. No order is lost and none is counted twice. "
                             "So 3 fillings give 2 × 2 × 2 = 8 orders."},
                    {"kind": "name",
                     "text": "Each order is a subset of {potato, cheese, onion}: a set whose members all come from the bigger set. "
                             "We write {potato, cheese} ⊆ {potato, cheese, onion}. "
                             "The plain dosa is the empty set, { }, which is a subset of every set. "
                             "The set of all the subsets is the power set. A set with 3 members has 2³ = 8 subsets."},
                    {"kind": "example",
                     "text": "List the subsets of {red, blue}. Each colour is in or out. Both out gives { }. "
                             "One in gives {red} and {blue}. Both in gives {red, blue}. "
                             "That is 4 subsets, and 2² = 4, so the power set has 4 members."},
                    {"kind": "mistake",
                     "text": "Two subsets are easy to forget: the empty set and the whole set itself. "
                             "A list for {red, blue} that stops at {red} and {blue} has only 2 of the 4. "
                             "Check your count against 2 × 2 = 4."},
                    {"kind": "turn",
                     "text": "A set has 4 members. How many subsets does it have?",
                     "answer": "16",
                     "answerKey": k.one(k.num("16"), accepts=["16", "= 16"], rejects=["8", "4", "15"])},
                    {"kind": "sayBack",
                     "text": "A subset is any choice of members from a set, and each new member doubles the number of choices."},
                ],
            },
            {
                "heading": "0.5 If this, then that",
                "teaches": ["if-then-statement", "counterexample"],
                "steps": [
                    {"kind": "question",
                     "text": "Riya says: if a number ends in 0, it is in the 5 times table. "
                             "Dev says: if a number is odd, it is in the 3 times table. Who is right?"},
                    {"kind": "idea",
                     "text": "Test Dev's claim. 3 is odd, and it is in the 3 times table. 9 works too. "
                             "Then try 5. It is odd, but it is not in the 3 times table. That one number sinks the claim. "
                             "Riya's claim survives every number you try: 10, 20, 70, 1,000."},
                    {"kind": "picture",
                     "text": "On paper, draw a circle for the numbers that end in 0. Draw the 5 times table as a bigger circle around it. "
                             "The small circle sits completely inside the big one. "
                             "Riya's claim says exactly that: no number ending in 0 is outside the big circle."},
                    {"kind": "reason",
                     "text": "Why can a hundred numbers that fit never prove Riya right? A claim about every number is a promise with no exceptions. "
                             "Numbers that fit cannot rule out a later one that does not. One exception breaks the promise at once. "
                             "To prove Riya right you need a reason. A number ending in 0 is 10 × something, and 10 = 2 × 5."},
                    {"kind": "name",
                     "text": "A claim of the form \"if this, then that\" is an if-then statement, written p ⇒ q. "
                             "The arrow is read \"implies\". "
                             "In Dev's claim, p is \"the number is odd\" and q is \"it is in the 3 times table\". "
                             "A case where p is true and q is false is a counterexample. 5 is a counterexample to Dev's claim."},
                    {"kind": "example",
                     "text": "Is this true: if a number is a multiple of 4, then it is even? "
                             "A counterexample would be a multiple of 4 that is odd. "
                             "But 4 × anything = 2 × (2 × anything), and 2 × anything is even. "
                             "No counterexample can exist, so the statement is true."},
                    {"kind": "mistake",
                     "text": "It is tempting to flip the arrow. If it is raining, then the road is wet. "
                             "That does not mean every wet road had rain. A burst pipe wets the road too. "
                             "Turning p ⇒ q round gives a new claim, and it can be false while p ⇒ q is true."},
                    {"kind": "turn",
                     "text": "Find a counterexample to this claim: if a number is a multiple of 3, then it is odd. "
                             "Give the smallest one above 0.",
                     "answer": "6",
                     "answerKey": k.one(k.num("6"), accepts=["6", "= 6"], rejects=["3", "9", "2"])},
                    {"kind": "sayBack",
                     "text": "An if-then statement is a promise, and one counterexample is enough to break it."},
                ],
            },
            {
                "heading": "0.6 The same promise, read backwards",
                "teaches": ["contrapositive"],
                "steps": [
                    {"kind": "question",
                     "text": "A sign at a swimming pool in Mumbai says: if you swim here, you have a pass. "
                             "A guard at the gate meets someone with no pass. What can the guard be sure of?"},
                    {"kind": "idea",
                     "text": "That person is not swimming here. If they were swimming, they would have a pass. "
                             "So no pass means no swimming. The guard knows this without looking at the pool."},
                    {"kind": "picture",
                     "text": "On paper, draw the swimmers as a small circle inside a bigger circle of pass holders. "
                             "Put a dot outside the pass circle for the person at the gate. "
                             "The dot is outside the swimmers' circle too, because that circle sits inside the pass circle."},
                    {"kind": "reason",
                     "text": "Why do the two sentences say the same thing? They describe the same picture: swimmers inside pass holders. "
                             "\"If swimming, then pass\" reads it from the inside out. "
                             "\"If no pass, then not swimming\" reads it from the outside in. One cannot be true without the other."},
                    {"kind": "name",
                     "text": "From p ⇒ q you can make \"if not q, then not p\". This is called the contrapositive. "
                             "It is true whenever p ⇒ q is true, and false whenever p ⇒ q is false."},
                    {"kind": "example",
                     "text": "Write the contrapositive of: if a number is a multiple of 10, then it ends in 0. "
                             "Swap the two parts and put \"not\" in front of each. "
                             "If a number does not end in 0, then it is not a multiple of 10. "
                             "Test it on 25: it does not end in 0, and 25 is not in the 10 times table."},
                    {"kind": "mistake",
                     "text": "The tempting slip is to add the two \"not\"s and forget to swap. "
                             "\"If you do not swim here, you have no pass\" is a different claim. It is false, because many pass holders stay dry. "
                             "Both parts must swap, and both must get a \"not\"."},
                    {"kind": "turn",
                     "text": "A rule says: if it rains, the match is cancelled. Today the match was not cancelled. "
                             "Did it rain? Answer yes or no.",
                     "answer": "No",
                     "answerKey": k.one(k.words(["no", "not", "didn't", "isn't"], forbid=["yes", "idea", "maybe", "know", "sure"]),
                                        accepts=["no", "No", "it did not rain"], rejects=["yes", "it rained", "maybe"])},
                    {"kind": "sayBack",
                     "text": "Swap the two parts and say not to both, and you get the same promise read from the outside in."},
                ],
            },
            {
                "heading": "0.7 Not this and not that",
                "teaches": ["truth-table", "de-morgan"],
                "figure": True,
                "steps": [
                    {"kind": "question",
                     "text": "The 4 students outside both circles play neither sport. "
                             "You could say they are not in \"cricket or football\". "
                             "You could also say they are not in cricket and not in football. Do the two descriptions always pick the same students?"},
                    {"kind": "idea",
                     "text": "To be outside the union, a student must miss cricket and also miss football. "
                             "Missing only one sport is not enough. "
                             "So \"not cricket-or-football\" and \"not cricket and not football\" pick out the same 4 students."},
                    {"kind": "picture",
                     "text": "In the figure, look at the green box outside both circles. "
                             "On paper, shade everything outside A, then everything outside B. "
                             "The part you shaded twice is exactly the part outside both circles."},
                    {"kind": "reason",
                     "text": "Why must this work for every pair of sets, not only this class? "
                             "Each member is in A or not, and in B or not. That makes only four kinds of member. "
                             "Check the two descriptions on all four kinds and they agree every time. Four kinds cover every case."},
                    {"kind": "name",
                     "text": "A table that checks a claim on every mix of true and false is a truth table. "
                             "The rule you found is one of De Morgan's laws: (A ∪ B)′ = A′ ∩ B′. "
                             "The other law says (A ∩ B)′ = A′ ∪ B′. In both, the dash moves inside and ∪ and ∩ swap."},
                    {"kind": "example",
                     "text": "Check the second law with ξ = {1, 2, 3, 4}, A = {1, 2} and B = {2, 3}. "
                             "A ∩ B = {2}, so (A ∩ B)′ = {1, 3, 4}. "
                             "A′ = {3, 4} and B′ = {1, 4}, so A′ ∪ B′ = {1, 3, 4}. The two sides match."},
                    {"kind": "mistake",
                     "text": "It is tempting to move the dash inside and keep the sign, as if (A ∪ B)′ were A′ ∪ B′. "
                             "Test it on the class of 30 with 7 in both. A′ ∪ B′ holds everyone who misses at least one sport. "
                             "That is 30 − 7 = 23 students, not the 4 who play neither."},
                    {"kind": "turn",
                     "text": "ξ = {1, 2, 3, 4, 5, 6}, A = {1, 2, 3} and B = {3, 4}. How many members does A′ ∩ B′ have?",
                     "answer": "2",
                     "answerKey": k.one(k.num("2"), accepts=["2", "= 2"], rejects=["5", "4", "3"])},
                    {"kind": "sayBack",
                     "text": "Outside A or B means outside both, so a dash over a bracket turns ∪ into ∩."},
                ],
            },
        ],
        "callouts": [
            {"kind": "predict", "title": "Predict first",
             "body": "18 students play cricket and 15 play football, in a class of 30. Could it be that nobody plays both? "
                     "Write your answer and one reason before you check it with the figure."},
            {"kind": "check", "title": "Explain it",
             "body": "A friend adds 18 cricket players and 15 football players and says 33 students play a sport. "
                     "Explain in your own words what went wrong."},
            {"kind": "careful", "title": "Watch out for the middle",
             "body": "When you count everyone who plays cricket or football, the students who play both belong to the count. "
                     "Count them once, not twice and not zero times."},
        ],
        "keyTerms": [
            "Set", "Member", "Universal set", "Venn diagram", "Intersection", "Union", "Complement", "Subset",
            "Power set", "If-then statement", "Counterexample", "Contrapositive", "Truth table", "De Morgan's laws",
        ],
        "widgets": ["w_venn_inclusion_exclusion", "w_truth_table_logic_gates", "w_quantifier_counterexample"],
        "widgetText": {
            "w_venn_inclusion_exclusion": {
                "title": "Two circles in a class of 30",
                "challengePrompt": "Put 18 in A, 15 in B and 7 in both. "
                                   "Predict how many students are outside both circles, then read the figure.",
                "cutaway": "11 play cricket only, 7 play both and 8 play football only. That is 26, so 4 are outside both circles.",
                "idealised": "The rule: n(A ∪ B) = n(A) + n(B) − n(A ∩ B)",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Put 18 in A, 15 in B and 7 in both."},
                    {"title": "2. Notice", "caption": "The four parts are 11, 7, 8 and 4. Together they make 30."},
                    {"title": "3. Match the colours", "caption": "Red is A, blue is B, the amber number is the middle, and green is outside both."},
                    {"title": "4. Push it further", "caption": "Put 22 in A and 20 in B. Why can the middle not go below 12?"},
                    {"title": "5. Draw it", "caption": "Draw the two circles in your journal and write the count in each of the four parts."},
                ],
            },
            "w_truth_table_logic_gates": {
                "title": "Checking every case",
                "challengePrompt": "On paper, make a table with four rows: in A and in B, in A only, in B only, in neither. "
                                   "Use it to check that outside A ∪ B means outside A and outside B.",
                "cutaway": "Only the last row is outside A ∪ B. It is also the only row outside A and outside B. "
                           "So (A ∪ B)′ = A′ ∩ B′.",
                "idealised": "The rule: (A ∪ B)′ = A′ ∩ B′",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Write the four rows: in both, in A only, in B only, in neither."},
                    {"title": "2. Notice", "caption": "Tick the rows that are inside A ∪ B. Three are, and one is not."},
                    {"title": "3. Match the rule", "caption": "The row outside A ∪ B is the row that is outside A and outside B."},
                    {"title": "4. Push it further", "caption": "Now tick the rows outside A ∩ B. Which description picks the same three rows?"},
                    {"title": "5. Draw it", "caption": "Copy the table into your journal and mark the rows for each side of the law."},
                ],
            },
            "w_quantifier_counterexample": {
                "title": "Hunting for a counterexample",
                "challengePrompt": "Test the claim \"if a number is odd, it is a multiple of 3\" on the numbers 1 to 15. "
                                   "Find every number that breaks it.",
                "cutaway": "1, 5, 7, 11 and 13 are odd and not multiples of 3. Any one of them breaks the claim.",
                "idealised": "One counterexample is enough to show a claim is false.",
                "watchSteps": [
                    {"title": "1. Try it", "caption": "Write the odd numbers from 1 to 15."},
                    {"title": "2. Notice", "caption": "Cross out each one that is a multiple of 3. Five numbers are left."},
                    {"title": "3. Match the rule", "caption": "Each number left is odd and not a multiple of 3, so each one is a counterexample."},
                    {"title": "4. Push it further", "caption": "Now test \"if a number is a multiple of 6, it is even\". Can you break it?"},
                    {"title": "5. Draw it", "caption": "In your journal, draw the odd numbers and the multiples of 3 as two circles. Put 5 where it belongs."},
                ],
            },
        },
        "atlasLessons": [
            {
                "title": "Chapter 0 · Two circles in a class of 30",
                "question": "Why do 18 cricket players and 15 football players make only 26 students who play a sport?",
                "explanation": "The 7 who play both are inside both counts. Take them away once: 18 + 15 − 7 = 26.",
                "limits": "The rule: n(A ∪ B) = n(A) + n(B) − n(A ∩ B)",
            },
            {
                "title": "Chapter 0 · Outside both circles",
                "question": "How many of the 30 students play neither sport?",
                "explanation": "26 play at least one sport, so 30 − 26 = 4 are outside both circles. "
                               "They make up the complement of A ∪ B.",
                "limits": "The count: n((A ∪ B)′) = 30 − 26 = 4",
            },
            {
                "title": "Chapter 0 · Not this and not that",
                "question": "Why is outside A ∪ B the same as outside A and outside B?",
                "explanation": "To be outside the union, a student must miss both sports. Missing one is not enough. "
                               "So (A ∪ B)′ = A′ ∩ B′.",
                "limits": "De Morgan's law: (A ∪ B)′ = A′ ∩ B′",
            },
        ],
        "visualMathTips": {},
        "debate": {
            "id": "debate-ch00-sets",
            "oupUnitNumber": 1,
            "title": "Who plays both?",
            "contextPrompt": "A class in Mumbai has 40 students. 24 play cricket, 20 play football and 4 play neither. "
                             "Aarav and Zoya disagree about how many play both.",
            "speakerAName": "Aarav",
            "speakerAClaim": "24 + 20 = 44. The class has 40, so 44 − 40 = 4 must play both.",
            "speakerBName": "Zoya",
            "speakerBClaim": "The 4 who play neither are outside both circles. So 40 − 4 = 36 play a sport, "
                             "and 44 − 36 = 8 play both.",
            "choices": [
                {"id": "ch00-a", "speakerLabel": "Aarav is right (4 students)",
                 "reasoningStatement": "Take the class size away from the two counts added together, and you get the overlap.",
                 "isCorrect": False,
                 "socraticRebuttal": "Try it with 4 in both. Then 20 play only cricket and 16 play only football. "
                                     "20 + 4 + 16 = 40, which leaves nobody outside the circles. But 4 students play neither."},
                {"id": "ch00-b", "speakerLabel": "Zoya is right (8 students)",
                 "reasoningStatement": "First take away the 4 who play neither. The overlap is how far 44 goes past the 36 who are left.",
                 "isCorrect": True,
                 "socraticRebuttal": "Yes. 16 play only cricket, 8 play both and 12 play only football. 16 + 8 + 12 + 4 = 40."},
                {"id": "ch00-c", "speakerLabel": "Neither. It is 24 − 20 = 4.",
                 "reasoningStatement": "The overlap is the difference between the two counts.",
                 "isCorrect": False,
                 "socraticRebuttal": "24 − 20 compares the sizes of the two circles. It says nothing about how much they overlap."},
            ],
            "invariantTakeaway": "First find how many are inside the circles. The overlap is how far the two counts add up past that.",
        },
    }


def cards(k):
    return {
        "set": {
            "name": "Set",
            "aliases": ["sets", "a set", "the set of", "empty set"],
            "oneSentence": "A collection of things with a clear rule for what is in it.",
            "picture": "The days of the week that start with S make a set: {Saturday, Sunday}. "
                       "Ask of any day whether it starts with S, and the answer is yes or no.",
            "steps": [
                "Write the members inside curly brackets, with commas between them.",
                "Write each member once. {1, 1, 2} is the same set as {1, 2}.",
                "Order does not matter. {1, 2} and {2, 1} are the same set.",
                "A set with nothing in it is the empty set, written { }.",
            ],
            "workedExample": "Write the vowels in the word CRICKET as a set. Check each letter: C no, R no, I yes, C no, K no, E yes, T no. "
                             "The set is {I, E}, with 2 members.",
            "check": {
                "prompt": "How many members does the set of letters in the word APPLE have?",
                "answer": "4",
                "answerKey": k.one(k.num("4"), accepts=["4", "= 4"], rejects=["5", "3", "2"]),
            },
            "mixUp": {
                "name": "a list",
                "how": "A list can repeat things, and its order matters. A set holds each thing once, in any order.",
            },
            "standsOn": [],
        },
        "member": {
            "name": "Member",
            "symbol": "∈",
            "aliases": ["member", "members", "element", "elements", "∈"],
            "oneSentence": "One of the things inside a set.",
            "picture": "Asha sings in the school choir, so she is a member of the set of choir singers. "
                       "You do not sing in the choir, so you are not a member.",
            "steps": [
                "Read the rule of the set.",
                "Test the thing against the rule.",
                "If it passes, write ∈, as in 4 ∈ {2, 4, 6}. If it fails, write ∉, as in 5 ∉ {2, 4, 6}.",
            ],
            "workedExample": "Is 15 a member of the multiples of 5? 15 = 3 × 5, so yes. "
                             "Is 22? 22 ÷ 5 leaves 2 over, so no.",
            "check": {
                "prompt": "A = {2, 3, 5, 7}. How many of the numbers 1, 2, 3 and 4 are members of A?",
                "answer": "2",
                "answerKey": k.one(k.num("2"), accepts=["2", "= 2"], rejects=["4", "3", "1"]),
            },
            "mixUp": {
                "with": "subset",
                "how": "A member is one thing: 2 ∈ {1, 2, 3}. A subset is a set: {2} ⊆ {1, 2, 3}. The curly brackets tell you which.",
            },
            "standsOn": ["set"],
        },
        "universal-set": {
            "name": "Universal set",
            "symbol": "ξ",
            "aliases": ["universal set", "universal sets", "ξ"],
            "oneSentence": "Everything you are choosing from in one problem, drawn as the box around a Venn diagram.",
            "picture": "When you sort the 30 students in your class into teams, the universal set is all 30 students. "
                       "A student from another school is not in it.",
            "steps": [
                "Decide what the problem is about: students, numbers or letters.",
                "Write that whole collection as ξ.",
                "Every other set in the problem must fit inside ξ.",
                "Anything in ξ but outside every circle still counts.",
            ],
            "workedExample": "ξ is the whole numbers from 1 to 10, and A is the even numbers in ξ. Then A = {2, 4, 6, 8, 10}. "
                             "12 is even, but it is not in ξ, so it is not in A.",
            "check": {
                "prompt": "ξ is the whole numbers from 1 to 12. A is the multiples of 4 in ξ. How many members does A have?",
                "answer": "3",
                "answerKey": k.one(k.num("3"), accepts=["3", "= 3"], rejects=["4", "12", "2"]),
            },
            "mixUp": {
                "with": "union",
                "how": "The union is everything inside the circles. The universal set is the whole box, "
                       "including what lies outside every circle.",
            },
            "standsOn": ["set"],
        },
        "venn-diagram": {
            "name": "Venn diagram",
            "aliases": ["venn diagram", "venn diagrams"],
            "oneSentence": "A picture of sets as circles inside a box, where an overlap shows what the sets share.",
            "picture": "Draw a box for your class of 30. Draw one circle for cricket and one for football. "
                       "Students who play both go where the circles overlap.",
            "steps": [
                "Draw a box for the universal set.",
                "Draw one circle for each set, overlapping.",
                "Fill in the middle first: the things in both.",
                "Then fill in the rest of each circle, and last of all the outside.",
            ],
            "workedExample": "In a class of 30, 12 play chess, 10 play carrom and 4 play both. Put 4 in the middle. "
                             "Chess only is 12 − 4 = 8. Carrom only is 10 − 4 = 6. Outside is 30 − 8 − 4 − 6 = 12.",
            "check": {
                "prompt": "In a Venn diagram, 9 things are in A, 6 are in B and 2 are in both. How many are in A only?",
                "answer": "7",
                "answerKey": k.one(k.num("7"), accepts=["7", "= 7"], rejects=["9", "11", "4"]),
            },
            "mixUp": {
                "name": "two separate circles",
                "how": "Draw the circles apart only when nothing is in both. If even one thing is shared, they must overlap.",
            },
            "standsOn": ["set"],
        },
        "intersection": {
            "name": "Intersection",
            "symbol": "∩",
            "aliases": ["intersection", "intersections", "∩"],
            "oneSentence": "The things that are in both sets at once.",
            "picture": "The friends who like mango are {Asha, Bilal, Chetan}. The friends who like guava are {Bilal, Divya}. "
                       "Only Bilal likes both, so the intersection is {Bilal}.",
            "steps": [
                "Go through the members of the first set.",
                "Keep each one that is also in the second set.",
                "Write what you kept. If you kept nothing, the intersection is the empty set.",
            ],
            "workedExample": "A = {1, 3, 5, 7, 9} and B = {3, 6, 9}. 3 is in both, and so is 9. Nothing else is. "
                             "So A ∩ B = {3, 9}.",
            "check": {
                "prompt": "A = {2, 4, 6, 8, 10} and B = {5, 10, 15}. How many members does A ∩ B have?",
                "answer": "1",
                "answerKey": k.one(k.num("1"), accepts=["1", "= 1"], rejects=["0", "7", "8"]),
            },
            "mixUp": {
                "with": "union",
                "how": "∩ means in both, so it is never bigger than either set. ∪ means in either, so it is never smaller.",
            },
            "standsOn": ["set"],
        },
        "union": {
            "name": "Union",
            "symbol": "∪",
            "aliases": ["union", "unions", "∪"],
            "oneSentence": "Everything that is in one set or the other or both, with each thing written once.",
            "picture": "The mango fans are {Asha, Bilal, Chetan} and the guava fans are {Bilal, Divya}. "
                       "Everyone who likes either fruit is {Asha, Bilal, Chetan, Divya}. Bilal is written once.",
            "steps": [
                "Write every member of the first set.",
                "Add each member of the second set that is not already there.",
                "To count it without listing, use n(A ∪ B) = n(A) + n(B) − n(A ∩ B).",
            ],
            "workedExample": "A = {1, 2, 3} and B = {2, 3, 4, 5}. Start with 1, 2 and 3. Add 4 and 5, because 2 and 3 are already there. "
                             "A ∪ B = {1, 2, 3, 4, 5}, with 5 members. Check with the rule: 3 + 4 − 2 = 5.",
            "check": {
                "prompt": "A has 8 members, B has 5, and 3 are in both. How many members does A ∪ B have?",
                "answer": "10",
                "answerKey": k.one(k.num("10"), accepts=["10", "= 10"], rejects=["13", "3", "16"]),
            },
            "mixUp": {
                "with": "intersection",
                "how": "∪ looks like the letter U, for union: everything in either set. "
                       "∩ is the same shape upside down: only what is in both.",
            },
            "standsOn": ["set"],
        },
        "complement": {
            "name": "Complement",
            "symbol": "A′",
            "aliases": ["complement", "complements", "A′", "B′"],
            "oneSentence": "Everything in the universal set that is not in a given set.",
            "picture": "In a class of 30, 18 play cricket. The other 12 do not. Those 12 are the complement of the cricket players.",
            "steps": [
                "Find the universal set, ξ.",
                "Take away every member of A.",
                "What is left is A′. Its count is n(ξ) − n(A).",
            ],
            "workedExample": "ξ = {1, 2, 3, 4, 5, 6} and A = {2, 4, 6}. Take away 2, 4 and 6. "
                             "A′ = {1, 3, 5}. Check: 6 − 3 = 3 members.",
            "check": {
                "prompt": "ξ has 25 members and A has 9. How many members does A′ have?",
                "answer": "16",
                "answerKey": k.one(k.num("16"), accepts=["16", "= 16"], rejects=["34", "9", "25"]),
            },
            "mixUp": {
                "name": "the opposite",
                "how": "The complement depends on ξ. If ξ is 1 to 10, the complement of the even numbers is {1, 3, 5, 7, 9}. "
                       "Change ξ and A′ changes too.",
            },
            "standsOn": ["universal-set"],
        },
        "subset": {
            "name": "Subset",
            "symbol": "⊆",
            "aliases": ["subset", "subsets", "⊆"],
            "oneSentence": "A set whose members are all inside another set.",
            "picture": "Every girl in your cricket team is in the cricket team. "
                       "So the girls in the team make a subset of the team.",
            "steps": [
                "Take each member of the smaller set.",
                "Check that it is also in the bigger set.",
                "If every one passes, it is a subset. One failure and it is not.",
                "The empty set and the whole set always count as subsets.",
            ],
            "workedExample": "Is {2, 4} a subset of {1, 2, 3, 4}? 2 is in it and 4 is in it, so yes: {2, 4} ⊆ {1, 2, 3, 4}. "
                             "Is {2, 5}? 5 is not in it, so no.",
            "check": {
                "prompt": "How many of these are subsets of {1, 2, 3, 4}: {1, 4}, {2, 5}, { } and {3}?",
                "answer": "3",
                "answerKey": k.one(k.num("3"), accepts=["3", "= 3"], rejects=["2", "4", "1"]),
            },
            "mixUp": {
                "with": "member",
                "how": "A member is one thing: 3 ∈ {1, 2, 3}. A subset is a set: {3} ⊆ {1, 2, 3}.",
            },
            "standsOn": ["set", "member"],
        },
        "power-set": {
            "name": "Power set",
            "aliases": ["power set", "power sets"],
            "oneSentence": "The set of every subset of a set, including the empty set and the whole set.",
            "picture": "A chaat stall can add sev, curd and chutney. Each possible plate, from no topping to all three, is one subset. "
                       "All 8 plates together make the power set.",
            "steps": [
                "Take the members one at a time.",
                "Each member is either in a subset or out of it: 2 choices.",
                "Multiply the choices. 3 members give 2 × 2 × 2 = 8 subsets.",
                "A set with n members has 2ⁿ subsets.",
            ],
            "workedExample": "How many subsets does {red, green, blue, yellow} have? Each colour is in or out. "
                             "That is 2 × 2 × 2 × 2 = 16, which is 2⁴.",
            "check": {
                "prompt": "A set has 5 members. How many members does its power set have?",
                "answer": "32",
                "answerKey": k.one(k.num("32"), accepts=["32", "= 32"], rejects=["10", "25", "31"]),
            },
            "mixUp": {
                "with": "subset",
                "how": "A subset is one choice, like {sev}. The power set is the set of all the choices together.",
            },
            "standsOn": ["subset"],
        },
        "if-then-statement": {
            "name": "If-then statement",
            "symbol": "⇒",
            "aliases": ["if-then statement", "if-then statements", "implies", "⇒"],
            "oneSentence": "A claim that whenever one thing is true, a second thing is true as well.",
            "picture": "If it is Sunday, then the school is closed. Every Sunday tests the promise. "
                       "One Sunday with the school open would make the claim false.",
            "steps": [
                "Split the claim into its if part, p, and its then part, q.",
                "Look for a case where p is true.",
                "Check whether q is true there too.",
                "One case with p true and q false shows the claim is false.",
            ],
            "workedExample": "Test: if a number is a multiple of 6, then it is even. 6, 12 and 18 are even. "
                             "And 6 = 2 × 3, so every multiple of 6 is 2 × something. The claim is true.",
            "check": {
                "prompt": "Claim: if a number is a multiple of 4, then it is a multiple of 8. "
                          "What is the smallest whole number above 0 that breaks it?",
                "answer": "4",
                "answerKey": k.one(k.num("4"), accepts=["4", "= 4"], rejects=["8", "16", "2"]),
            },
            "mixUp": {
                "name": "the claim turned round",
                "how": "Swapping the parts makes a new claim. If it is Sunday, the school is closed. "
                       "But a closed school does not mean it is Sunday. It could be a holiday.",
            },
            "standsOn": [],
        },
        "counterexample": {
            "name": "Counterexample",
            "aliases": ["counterexample", "counterexamples", "counter-example", "counter-examples"],
            "oneSentence": "One case that shows an if-then claim is false: the if part holds and the then part does not.",
            "picture": "Someone says every bird can fly. A penguin is a bird that cannot fly. "
                       "One penguin is enough to show the claim is false.",
            "steps": [
                "Write the claim as: if p, then q.",
                "Look for something that makes p true.",
                "Among those, look for one that makes q false.",
                "If you find one, the claim is false. Show it and stop.",
            ],
            "workedExample": "Claim: if two numbers are odd, their sum is odd. Try 3 and 5. Both are odd, and 3 + 5 = 8, which is even. "
                             "So 3 and 5 are a counterexample, and the claim is false.",
            "check": {
                "prompt": "Claim: every number in the 4 times table is also in the 6 times table. "
                          "What is the smallest counterexample above 0?",
                "answer": "4",
                "answerKey": k.one(k.num("4"), accepts=["4", "= 4"], rejects=["12", "6", "24"]),
            },
            "mixUp": {
                "name": "an example that fits",
                "how": "Examples that fit a claim never prove it. Only a reason does. "
                       "A counterexample works the other way: one is enough to disprove it.",
            },
            "standsOn": ["if-then-statement"],
        },
        "contrapositive": {
            "name": "Contrapositive",
            "aliases": ["contrapositive", "contrapositives"],
            "oneSentence": "The if-then statement you get by swapping the two parts and putting not in front of each.",
            "picture": "If it is Sunday, then the school is closed. Its contrapositive is: if the school is open, it is not Sunday. "
                       "Both say the same thing.",
            "steps": [
                "Write the statement as: if p, then q.",
                "Swap the parts: if q, then p.",
                "Put not in front of each part: if not q, then not p.",
                "This is true exactly when the first statement is true.",
            ],
            "workedExample": "Find the contrapositive of: if a shape is a square, then it has four sides. "
                             "Swap and add not: if a shape does not have four sides, then it is not a square. "
                             "A triangle has three sides, and it is not a square.",
            "check": {
                "prompt": "Statement: if a number is a multiple of 10, then it ends in 0. A number ends in 7. "
                          "Is it a multiple of 10? Answer yes or no.",
                "answer": "No",
                "answerKey": k.one(k.words(["no", "not", "didn't", "isn't"], forbid=["yes", "idea", "maybe", "know", "sure"]),
                                   accepts=["no", "No", "it is not"], rejects=["yes", "it is", "maybe"]),
            },
            "mixUp": {
                "name": "swapping without the nots",
                "how": "Swapping alone gives if q, then p, which can be false when the statement is true. "
                       "The contrapositive swaps and adds not to both parts, and it always agrees.",
            },
            "standsOn": ["if-then-statement"],
        },
        "truth-table": {
            "name": "Truth table",
            "aliases": ["truth table", "truth tables"],
            "oneSentence": "A table with one row for every way the parts of a claim can be true or false.",
            "picture": "To check a claim about A and B, ask two questions of each member: in A? in B? "
                       "There are only four mixes of answers: yes yes, yes no, no yes, no no. Four rows cover everyone.",
            "steps": [
                "List the parts: in A? in B?",
                "Write one row for each mix of yes and no. Two parts give 4 rows.",
                "Work out the claim on each row.",
                "Two claims mean the same thing if they agree on every row.",
            ],
            "workedExample": "Check that \"not in A or B\" matches \"not in A and not in B\". "
                             "Row yes, yes: both say no. Row yes, no: both say no. Row no, yes: both say no. "
                             "Row no, no: both say yes. They agree on all four rows.",
            "check": {
                "prompt": "A claim has three parts, and each can be true or false. How many rows does its truth table need?",
                "answer": "8",
                "answerKey": k.one(k.num("8"), accepts=["8", "= 8"], rejects=["6", "3", "9"]),
            },
            "mixUp": {
                "with": "venn-diagram",
                "how": "A Venn diagram shows the four kinds of member as four regions. A truth table lists the same four kinds as rows.",
            },
            "standsOn": ["intersection", "union"],
        },
        "de-morgan": {
            "name": "De Morgan's laws",
            "aliases": ["de morgan's laws", "de morgan's law", "de morgan’s laws", "de morgan’s law", "de morgan"],
            "oneSentence": "Two rules for the complement of a union or an intersection: the dash moves inside, and ∪ and ∩ swap.",
            "picture": "The students who play neither cricket nor football are the ones who miss cricket and also miss football. "
                       "Not in cricket-or-football is the same as not in cricket and not in football.",
            "steps": [
                "(A ∪ B)′ = A′ ∩ B′. Outside either circle means outside both.",
                "(A ∩ B)′ = A′ ∪ B′. Outside the middle means outside at least one circle.",
                "When the dash moves inside the brackets, swap ∪ and ∩.",
            ],
            "workedExample": "ξ = {1, 2, 3, 4, 5}, A = {1, 2} and B = {2, 3}. A ∪ B = {1, 2, 3}, so (A ∪ B)′ = {4, 5}. "
                             "A′ = {3, 4, 5} and B′ = {1, 4, 5}, so A′ ∩ B′ = {4, 5}. The two sides match.",
            "check": {
                "prompt": "ξ has 30 members and 7 of them are in A ∩ B. How many members does A′ ∪ B′ have?",
                "answer": "23",
                "answerKey": k.one(k.num("23"), accepts=["23", "= 23"], rejects=["7", "37", "4"]),
            },
            "mixUp": {
                "name": "moving the dash without swapping",
                "how": "(A ∪ B)′ is not A′ ∪ B′. In a class of 30 with 7 in both, A′ ∪ B′ has 23 students, "
                       "while only 4 might play neither.",
            },
            "standsOn": ["complement", "union", "intersection"],
        },
    }


def _subsets(items):
    out = [set()]
    for item in items:
        out += [subset | {item} for subset in out]
    return out


def sums():
    """(label, computed, stated) for every number chapter 0 and its cards state."""
    xi = set(range(1, 11))
    a1, b1 = {1, 2, 3, 4}, {3, 4, 5}
    xi7, a7, b7 = {1, 2, 3, 4}, {1, 2}, {2, 3}
    xi_turn7, a_turn7, b_turn7 = {1, 2, 3, 4, 5, 6}, {1, 2, 3}, {3, 4}
    xi_dm, a_dm, b_dm = {1, 2, 3, 4, 5}, {1, 2}, {2, 3}
    return [
        ("0.1 even numbers in 1 to 10", sorted(n for n in xi if n % 2 == 0), [2, 4, 6, 8, 10]),
        ("0.1 letters of MUMBAI", len(set("MUMBAI")), 5),
        ("0.1 letters of MUMBAI, counted with repeats", len("MUMBAI"), 6),
        ("0.2 A ∩ B", sorted(a1 & b1), [3, 4]),
        ("0.2 A ∪ B", sorted(a1 | b1), [1, 2, 3, 4, 5]),
        ("0.3 33 counted", 18 + 15, 33),
        ("0.3 at least one sport", 18 + 15 - 7, 26),
        ("0.3 neither", 30 - 26, 4),
        ("0.3 cricket only", 18 - 7, 11),
        ("0.3 football only", 15 - 7, 8),
        ("0.3 parts inside", 11 + 7 + 8, 26),
        ("0.3 tea union", 25 + 22 - 10, 37),
        ("0.3 tea neither", 40 - 37, 3),
        ("0.3 tea parts", (25 - 10) + 10 + (22 - 10) + 3, 40),
        ("0.4 dosas by size", 1 + 3 + 3 + 1, 8),
        ("0.4 dosas by doubling", len(_subsets(["potato", "cheese", "onion"])), 8),
        ("0.4 2³", 2 ** 3, 8),
        ("0.4 subsets of {red, blue}", len(_subsets(["red", "blue"])), 4),
        ("0.5 3 and 9 are odd multiples of 3", all(n % 2 and n % 3 == 0 for n in (3, 9)), True),
        ("0.5 5 is odd and not a multiple of 3", bool(5 % 2 and 5 % 3), True),
        ("0.5 Riya's numbers are multiples of 5", all(n % 5 == 0 for n in (10, 20, 70, 1000)), True),
        ("0.5 10 = 2 × 5", 2 * 5, 10),
        ("0.5 every multiple of 4 is even", all((4 * n) % 2 == 0 for n in range(1, 1000)), True),
        ("0.6 25 is not a multiple of 10", 25 % 10 != 0, True),
        ("0.7 A ∩ B", sorted(a7 & b7), [2]),
        ("0.7 (A ∩ B)′", sorted(xi7 - (a7 & b7)), [1, 3, 4]),
        ("0.7 A′", sorted(xi7 - a7), [3, 4]),
        ("0.7 B′", sorted(xi7 - b7), [1, 4]),
        ("0.7 A′ ∪ B′", sorted((xi7 - a7) | (xi7 - b7)), [1, 3, 4]),
        ("0.7 class A′ ∪ B′", 30 - 7, 23),
        ("0.7 turn by De Morgan", len(xi_turn7 - (a_turn7 | b_turn7)), 2),
        ("skill card at least one sport", 17 + 12 - 5, 24),
        ("skill card neither", 30 - 24, 6),
        ("skill card counterexamples", [n for n in range(1, 15) if n % 2 and n % 3], [1, 5, 7, 11, 13]),
        ("callout: at least 3 must play both", 18 + 15 - 30, 3),
        ("widget: cricket only, football only, both, outside", [18 - 7, 15 - 7, 7, 30 - 26], [11, 8, 7, 4]),
        ("widget: smallest middle for 22 and 20", 22 + 20 - 30, 12),
        ("widget: odd numbers left after crossing out multiples of 3",
         len([n for n in range(1, 16, 2) if n % 3]), 5),
        ("debate: inside the circles", 40 - 4, 36),
        ("debate: both", 24 + 20 - 36, 8),
        ("debate: Aarav's split leaves nobody outside", (24 - 4) + 4 + (20 - 4), 40),
        ("debate: Zoya's parts", (24 - 8) + 8 + (20 - 8) + 4, 40),
        ("card set: vowels of CRICKET", sorted(set("CRICKET") & set("AEIOU")), ["E", "I"]),
        ("card member: 15 = 3 × 5", 3 * 5, 15),
        ("card member: 22 ÷ 5 remainder", 22 % 5, 2),
        ("card universal set: evens in 1 to 10", sorted(n for n in xi if n % 2 == 0), [2, 4, 6, 8, 10]),
        ("card venn: chess only", 12 - 4, 8),
        ("card venn: carrom only", 10 - 4, 6),
        ("card venn: outside", 30 - 8 - 4 - 6, 12),
        ("card intersection", sorted({1, 3, 5, 7, 9} & {3, 6, 9}), [3, 9]),
        ("card intersection picture", sorted({"Asha", "Bilal", "Chetan"} & {"Bilal", "Divya"}), ["Bilal"]),
        ("card union", sorted({1, 2, 3} | {2, 3, 4, 5}), [1, 2, 3, 4, 5]),
        ("card union rule", 3 + 4 - 2, 5),
        ("card union picture", len({"Asha", "Bilal", "Chetan"} | {"Bilal", "Divya"}), 4),
        ("card complement picture", 30 - 18, 12),
        ("card complement", sorted({1, 2, 3, 4, 5, 6} - {2, 4, 6}), [1, 3, 5]),
        ("card complement mix-up", sorted(set(range(1, 11)) - {2, 4, 6, 8, 10}), [1, 3, 5, 7, 9]),
        ("card subset {2, 4}", {2, 4} <= {1, 2, 3, 4}, True),
        ("card subset {2, 5}", {2, 5} <= {1, 2, 3, 4}, False),
        ("card power set: 3 members", 2 * 2 * 2, 8),
        ("card power set: 4 colours", len(_subsets(["red", "green", "blue", "yellow"])), 16),
        ("card if-then: 6 = 2 × 3", 2 * 3, 6),
        ("card counterexample: 3 + 5", 3 + 5, 8),
        ("card de morgan: (A ∪ B)′", sorted(xi_dm - (a_dm | b_dm)), [4, 5]),
        ("card de morgan: A′", sorted(xi_dm - a_dm), [3, 4, 5]),
        ("card de morgan: B′", sorted(xi_dm - b_dm), [1, 4, 5]),
        ("card de morgan: A′ ∩ B′", sorted((xi_dm - a_dm) & (xi_dm - b_dm)), [4, 5]),
    ]


def answers():
    """The right answer to every 'Your turn' and card check, computed."""
    multiples_of_10 = range(10, 1000, 10)
    return {
        "ch00-s1-turn": len([n for n in range(1, 21) if n % 3 == 0]),
        "ch00-s2-turn": len({2, 4, 6, 8} | {4, 8, 12}),
        "ch00-s3-turn": 32 - (20 + 15 - 6),
        "ch00-s4-turn": len(_subsets([1, 2, 3, 4])),
        "ch00-s5-turn": next(n for n in range(1, 100) if n % 3 == 0 and n % 2 == 0),
        # If it had rained, the match would have been cancelled. It was not, so it did not rain.
        "ch00-s6-turn": "no",
        "ch00-s7-turn": len(({1, 2, 3, 4, 5, 6} - {1, 2, 3}) & ({1, 2, 3, 4, 5, 6} - {3, 4})),
        "set-check": len(set("APPLE")),
        "member-check": len({1, 2, 3, 4} & {2, 3, 5, 7}),
        "universal-set-check": len([n for n in range(1, 13) if n % 4 == 0]),
        "venn-diagram-check": 9 - 2,
        "intersection-check": len({2, 4, 6, 8, 10} & {5, 10, 15}),
        "union-check": 8 + 5 - 3,
        "complement-check": 25 - 9,
        "subset-check": sum(s <= {1, 2, 3, 4} for s in [{1, 4}, {2, 5}, set(), {3}]),
        "power-set-check": len(_subsets(range(5))),
        "if-then-statement-check": next(n for n in range(1, 100) if n % 4 == 0 and n % 8 != 0),
        "counterexample-check": next(n for n in range(1, 100) if n % 4 == 0 and n % 6 != 0),
        # A number ending in 7 does not end in 0, so by the contrapositive it is not a multiple of 10.
        "contrapositive-check": "no" if all(m % 10 == 0 for m in multiples_of_10) else "yes",
        "truth-table-check": 2 ** 3,
        "de-morgan-check": 30 - 7,
    }
