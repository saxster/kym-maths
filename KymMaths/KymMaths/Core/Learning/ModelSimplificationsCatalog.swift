import Foundation

// MARK: - PhET-Style "Model Simplifications": What Each Chapter Figure Leaves Out

/// Honest, plain-English notes explaining what a chapter's interactive model leaves out
/// and where Kym meets the full idea later. Every sentence stays short and avoids jargon.
enum ModelSimplificationsCatalog {
    static func note(forChapter chapterNumber: Int) -> String {
        notes[chapterNumber] ?? "This picture fixes a few numbers at clean whole steps so the pattern is easy to see. Real problems can use messy fractions or more than two pieces."
    }

    private static let notes: [Int: String] = [
        0: "These Venn circles show two finite groups in one room. Later you will meet sets of three groups and sets with endlessly many numbers.",
        1: "The number line snaps to clean steps so turns are clear. Between every two ticks sit fractions and numbers like √2 that never settle on a fraction.",
        2: "Here the repeating decimal repeats in clean two-digit blocks. Longer repeating blocks use the same subtraction trick with 1,000 or 10,000.",
        3: "Both ratios and bank rates stay steady across every year shown here. In real shops and banks, prices and interest rates change from year to year.",
        4: "This grid splits expressions with tidy whole numbers so every box is clear. Messy quadratics need completing the square or the quadratic formula later.",
        5: "The balance pans hold one unknown x with flat weights. Two unknowns at once need two balance statements solved together as simultaneous equations.",
        6: "Each staircase steps by a steady rule from term to term. Real growth often mixes several rules or bends up and down.",
        7: "This graph draws straight lines with clean grid steps. Curves whose steepness changes from point to point wait for Chapter 17.",
        8: "These lines stay flat on one sheet of paper. On a curved ball like Earth, a triangle's three angles actually add up to more than 180°.",
        9: "The workshop assumes sharp pencil points and rigid lines. Real paper compasses slip a millimetre, so always check lengths with a ruler too.",
        10: "Cutting a circle into 24 wedges still leaves tiny scallops along the edge. Only infinitely thin slices make the rectangle exact.",
        11: "Here shapes enlarge and turn cleanly around fixed grid points. Later you can combine turns, flips and stretches with 2×2 matrices.",
        12: "The triangles here wrap cleanly round a right angle. Triangles without a right angle use the sine and cosine rules later in the chapter.",
        13: "Every draw in this sampler picks fairly and independently. Real polls can be skewed if some people are missed or refuse to answer.",
        14: "The data points sit cleanly on whole ticks with no missing entries. Real datasets contain odd spikes, gaps and ties that shift averages differently.",
        15: "Each peg on the Galton board splits 50–50 without spin or bounce noise. Real random events often depend on what happened the step before.",
        16: "The 1,000-person square splits into exact round counts for clarity. Real medical tests update probabilities step by step across several clues.",
        17: "These curves are smooth almost everywhere, with at most one sharp corner or jump. Functions that wiggle endlessly need sharper limit tools later.",
        18: "Midpoint bars trade leftover bits above and below a smooth curve. Wild jumps and infinite tails wait for university integration.",
        19: "These arrows lie on one flat plane with two numbers each. Three-dimensional space adds a third number straight up out of the page.",
        20: "This sandbox keeps off-diagonal entries matching so stretch directions stay real. Pure rotations twist vectors off every line and need complex numbers."
    ]
}
