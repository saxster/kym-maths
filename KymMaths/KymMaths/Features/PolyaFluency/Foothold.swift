import Foundation

// MARK: - Split it, crack one piece: the foothold problems (docs/FOOTHOLD.md)

struct FootholdPiece: Equatable, Sendable {
    let claim: String
    let verdict: String
}

struct FootholdProblem: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let problem: String
    let pieces: [FootholdPiece]
    let footholdIndex: Int
    /// Steps from the foothold to the answer; the first one solves the foothold.
    let build: [String]
    let check: String

    func isFoothold(_ index: Int) -> Bool { index == footholdIndex }
}

enum FootholdCatalog {
    static let all: [FootholdProblem] = [
        FootholdProblem(
            id: "f1-bills",
            title: "Two bills",
            problem: "10 pens and 4 notebooks cost ₹280. 10 pens and 7 notebooks cost ₹400. What does a pen cost?",
            pieces: [
                FootholdPiece(
                    claim: "Find the price of a pen first",
                    verdict: "Both bills mix pens with notebooks. No fact talks about pens alone."
                ),
                FootholdPiece(
                    claim: "Compare the bills: what do the 3 extra notebooks cost?",
                    verdict: "The pens are the same in both bills, so the difference is only notebooks: ₹400 − ₹280 = ₹120."
                ),
                FootholdPiece(
                    claim: "Add the two bills together",
                    verdict: "20 pens and 11 notebooks cost ₹680. That's a bigger problem with the same two unknowns, not a piece."
                ),
            ],
            footholdIndex: 1,
            build: [
                "3 notebooks cost ₹120, so 1 notebook costs ₹40.",
                "4 notebooks cost ₹160, so 10 pens cost ₹280 − ₹160 = ₹120.",
                "A pen costs ₹12.",
            ],
            check: "Check: 10 × 12 + 7 × 40 = 120 + 280 = 400 ✓"
        ),
        FootholdProblem(
            id: "f2-ages",
            title: "Father and son",
            problem: "A father is 3 times as old as his son. In 12 years he will be twice as old. How old are they now?",
            pieces: [
                FootholdPiece(
                    claim: "Find the father's age first",
                    verdict: "Every fact ties the father to the son. Nothing talks about him alone."
                ),
                FootholdPiece(
                    claim: "Find their ages in 12 years",
                    verdict: "That's the same problem moved 12 years on. It isn't smaller."
                ),
                FootholdPiece(
                    claim: "Find the age gap. It never changes.",
                    verdict: "The gap is the same now and in 12 years. That one fact links the two moments."
                ),
            ],
            footholdIndex: 2,
            build: [
                "Now the son is 1 unit and the father 3 units, so the gap is 2 units.",
                "In 12 years the father is twice the son, so the gap equals the son's age then.",
                "The gap hasn't changed, so the son will be 2 units old.",
                "He is 1 unit now, so 1 unit is 12 years.",
                "Son 12, father 36.",
            ],
            check: "Check: in 12 years, 48 = 2 × 24 ✓"
        ),
        FootholdProblem(
            id: "f3-rectangle",
            title: "Rectangle (stretch)",
            problem: "A rectangle's perimeter is 34 cm and its diagonal is 13 cm. Find its area.",
            pieces: [
                FootholdPiece(
                    claim: "Find the length and the width first",
                    verdict: "You might guess 12 and 5. Make the diagonal 14 cm and no neat pair works, yet the area is still easy (46.5 cm²). You don't need them."
                ),
                FootholdPiece(
                    claim: "Find length + width from the perimeter",
                    verdict: "Half the perimeter is length + width = 17. One fact, one step."
                ),
                FootholdPiece(
                    claim: "Get the area straight from 34 and 13",
                    verdict: "No rule takes a perimeter and a diagonal straight to an area. That's the whole problem, not a piece of it."
                ),
            ],
            footholdIndex: 1,
            build: [
                "Length + width = 34 ÷ 2 = 17.",
                "The diagonal makes a right triangle, so length² + width² = 13² = 169 (Pythagoras).",
                "(length + width)² = length² + width² + 2 × area, so 289 = 169 + 2 × area.",
                "Area = 60 cm².",
            ],
            check: "Check: 12 × 5 = 60, 12 + 5 = 17 and 12² + 5² = 169 ✓"
        ),
    ]
}
