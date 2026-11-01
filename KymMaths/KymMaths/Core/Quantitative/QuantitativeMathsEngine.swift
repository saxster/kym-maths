import Foundation

// MARK: - 21 Wolfram-Verified Quantitative Maths Problem Templates
// Each template bridges Visual Intuition -> "Aha!" Invariant -> Symbolic Formula -> Numeric Answer

enum QuantitativeTemplateKind: String, CaseIterable, Identifiable, Codable, Sendable {
    case setInclusionExclusion          // Ch 0 · Set Theory & De Morgan
    case primeFactorHCFLCM              // Ch 1 · OUP Ch 1 Prime Factorization, HCF & LCM
    case indexLawsAndRoots              // Ch 2 · OUP Ch 1 Indices, Squares & Cubes
    case algebraicExpansionArea         // Ch 3 · OUP Ch 2 Expanding & Factorising
    case recurringDecimalToFraction     // Ch 4 · OUP Ch 6 Recurring Decimals
    case linearEquationBarModel         // Ch 5 · OUP Ch 7 Equations & Formula Rearrangement
    case compoundPercentageMultiplier   // Ch 6 · OUP Ch 9 Percentage Change & Compound Growth
    case singaporeRatioDifference       // Ch 7 · OUP Ch 12 Ratio & Constant-Difference Bar Model
    case arithmeticSequenceNthTerm      // Ch 8 · OUP Ch 11 Sequences & Gauss Pairing
    case polygonExteriorInteriorAngle   // Ch 9 · OUP Ch 3 & 8 Angle Chasing & Polygons
    case circleSectorAndPrismVolume     // Ch 10 · OUP Ch 5 Area, Circumference & Prism Volume
    case bearingsPythagorasDistance     // Ch 11 · OUP Ch 3 Bearings & Pythagoras
    case cosineRuleAndUnitCircle        // Ch 12 · Horizon Trigonometry (Unit Circle & Cosine Rule)
    case histogramFrequencyDensity      // Ch 13 · OUP Ch 4 & 10 Sampling, Histograms & Spread
    case combinatoricsPermutations      // Ch 14 · OUP Ch 15 Sample Spaces & Combinatorics
    case bayesNaturalFrequencySquare    // Ch 15 · Horizon Bayes' Theorem (1,000-Person Unit Square)
    case linearGraphGradientMidpoint    // Ch 16 · OUP Ch 8 & 14 Gradient, Intercept & Midpoint
    case instantaneousSecantDerivative  // Ch 17 · Horizon Differential Calculus (dy/dx)
    case riemannDefiniteIntegralArea    // Ch 18 · Horizon Integral Calculus (Fundamental Theorem)
    case vectorMagnitudeDotProduct      // Ch 19 · OUP Ch 16 Vectors & Dot Product
    case matrixDeterminantEigenvalue    // Ch 20 · OUP Ch 13 Transformations & 2x2 Linear Algebra

    var id: String { rawValue }

    var title: String {
        switch self {
        case .setInclusionExclusion: return "Ch 0 · Set Union & Inclusion–Exclusion"
        case .primeFactorHCFLCM: return "Ch 1 · Prime Lattice HCF × LCM Identity"
        case .indexLawsAndRoots: return "Ch 2 · Index Laws & Power Scaling"
        case .algebraicExpansionArea: return "Ch 3 · Area Model Expansion & Difference of Squares"
        case .recurringDecimalToFraction: return "Ch 4 · Recurring Decimal Shift-and-Subtract"
        case .linearEquationBarModel: return "Ch 5 · Singapore Bar-Model Linear Equation"
        case .compoundPercentageMultiplier: return "Ch 6 · Compound Multiplier Cascade"
        case .singaporeRatioDifference: return "Ch 7 · Singapore Constant-Difference Ratio"
        case .arithmeticSequenceNthTerm: return "Ch 8 · Arithmetic Sequence & Gauss Sum"
        case .polygonExteriorInteriorAngle: return "Ch 9 · Exterior Walk & Parallel Angle Chasing"
        case .circleSectorAndPrismVolume: return "Ch 10 · Circle Sector & Triangular Prism Volume"
        case .bearingsPythagorasDistance: return "Ch 11 · Bearings & Euclidean Distance"
        case .cosineRuleAndUnitCircle: return "Ch 12 · Trigonometry & Cosine Rule"
        case .histogramFrequencyDensity: return "Ch 13 · Histogram Frequency Density"
        case .combinatoricsPermutations: return "Ch 14 · Multiplication Principle & Permutations"
        case .bayesNaturalFrequencySquare: return "Ch 15 · Bayes' Theorem 1,000-Person Square"
        case .linearGraphGradientMidpoint: return "Ch 16 · Linear Gradient & Coordinate Midpoint"
        case .instantaneousSecantDerivative: return "Ch 17 · Tangent Slope Derivative dy/dx"
        case .riemannDefiniteIntegralArea: return "Ch 18 · Definite Integral Area Under Curve"
        case .vectorMagnitudeDotProduct: return "Ch 19 · Vector Resultant & Magnitude"
        case .matrixDeterminantEigenvalue: return "Ch 20 · 2×2 Matrix Determinant & Trace"
        }
    }

    var patternedWorldChapter: Int {
        switch self {
        case .setInclusionExclusion: return 0
        case .primeFactorHCFLCM: return 1
        case .indexLawsAndRoots: return 2
        case .algebraicExpansionArea: return 3
        case .recurringDecimalToFraction: return 4
        case .linearEquationBarModel: return 5
        case .compoundPercentageMultiplier: return 6
        case .singaporeRatioDifference: return 7
        case .arithmeticSequenceNthTerm: return 8
        case .polygonExteriorInteriorAngle: return 9
        case .circleSectorAndPrismVolume: return 10
        case .bearingsPythagorasDistance: return 11
        case .cosineRuleAndUnitCircle: return 12
        case .histogramFrequencyDensity: return 13
        case .combinatoricsPermutations: return 14
        case .bayesNaturalFrequencySquare: return 15
        case .linearGraphGradientMidpoint: return 16
        case .instantaneousSecantDerivative: return 17
        case .riemannDefiniteIntegralArea: return 18
        case .vectorMagnitudeDotProduct: return 19
        case .matrixDeterminantEigenvalue: return 20
        }
    }
}

struct QuantitativeMathsProblem: Identifiable, Equatable, Sendable {
    let id: String
    let template: QuantitativeTemplateKind
    let seed: Int
    let title: String
    let schoolTopicCode: String
    let patternedWorldChapter: Int
    let prompt: String
    let expectedValue: Double
    let tolerance: Double
    let unitLabel: String
    let visualIntuitionStep: String
    let ahaInvariantStep: String
    let formulaStep: String
    let stepByStepDerivation: [String]
}

struct QuantitativeAttemptEvaluation: Equatable, Sendable {
    let isCorrect: Bool
    let submittedValue: Double
    let expectedValue: Double
    let absoluteError: Double
    let feedback: String
}

enum QuantitativeMathsEngine {
    static func gcd(_ a: Int, _ b: Int) -> Int {
        var x = abs(a)
        var y = abs(b)
        while y != 0 {
            let t = x % y
            x = y
            y = t
        }
        return max(1, x)
    }

    static func generate(template: QuantitativeTemplateKind, seed: Int = 1) -> QuantitativeMathsProblem {
        let s = max(1, abs(seed))

        switch template {
        case .setInclusionExclusion:
            let total = 40 + (s % 5) * 5
            let setA = 22 + (s % 6)
            let setB = 18 + (s % 5)
            let neither = 4 + (s % 3)
            let union = total - neither
            let both = setA + setB - union
            return QuantitativeMathsProblem(
                id: "q-\(template.rawValue)-\(s)",
                template: template,
                seed: s,
                title: template.title,
                schoolTopicCode: "1.6",
                patternedWorldChapter: 0,
                prompt: "In a class of \(total) students, \(setA) study Coding (Set A), \(setB) study Robotics (Set B), and \(neither) study neither. How many students study BOTH Coding and Robotics, |A ∩ B|?",
                expectedValue: Double(both),
                tolerance: 0.01,
                unitLabel: "students",
                visualIntuitionStep: "Slide Circle A (\(setA)) over Circle B (\(setB)) inside a universal rectangle of \(total) students with \(neither) outside both circles.",
                ahaInvariantStep: "Adding |A| + |B| counts the central lens |A ∩ B| twice, while the union |A ∪ B| is \(total) − \(neither) = \(union).",
                formulaStep: "|A ∪ B| = |A| + |B| − |A ∩ B|  ⇒  |A ∩ B| = |A| + |B| − |A ∪ B|",
                stepByStepDerivation: [
                    "1. Find union |A ∪ B| = \(total) − \(neither) = \(union).",
                    "2. Sum individual sets: |A| + |B| = \(setA) + \(setB) = \(setA + setB).",
                    "3. Subtract union to isolate overlap: |A ∩ B| = \(setA + setB) − \(union) = \(both)."
                ]
            )

        case .primeFactorHCFLCM:
            let p = [6, 12, 15, 18, 24][s % 5]
            let a = p * 3
            let b = p * 5
            let hcf = gcd(a, b)
            let lcm = (a * b) / hcf
            return QuantitativeMathsProblem(
                id: "q-\(template.rawValue)-\(s)",
                template: template,
                seed: s,
                title: template.title,
                schoolTopicCode: "1.4",
                patternedWorldChapter: 1,
                prompt: "Find the Lowest Common Multiple (LCM) of \(a) and \(b) using their Highest Common Factor (HCF = \(hcf)).",
                expectedValue: Double(lcm),
                tolerance: 0.01,
                unitLabel: "",
                visualIntuitionStep: "Place the prime factors of \(a) and \(b) into a 2-circle Venn diagram. The shared lens holds the HCF (\(hcf)); the full union holds the LCM.",
                ahaInvariantStep: "Every prime power in \(a) × \(b) lands in either the union (LCM) or the intersection (HCF), so HCF × LCM = a × b.",
                formulaStep: "LCM(a, b) = (a × b) / HCF(a, b)",
                stepByStepDerivation: [
                    "1. Compute product a × b = \(a) × \(b) = \(a * b).",
                    "2. Divide by HCF(\(a), \(b)) = \(hcf).",
                    "3. LCM = \(a * b) / \(hcf) = \(lcm)."
                ]
            )

        case .indexLawsAndRoots:
            let base = 2
            let m = 4 + (s % 4)
            let n = 3 + (s % 3)
            let p = 5
            let finalExp = m + n - p
            let val = Int(pow(Double(base), Double(finalExp)))
            return QuantitativeMathsProblem(
                id: "q-\(template.rawValue)-\(s)",
                template: template,
                seed: s,
                title: template.title,
                schoolTopicCode: "1.3",
                patternedWorldChapter: 2,
                prompt: "Evaluate (\(base)^\(m) × \(base)^\(n)) ÷ \(base)^\(p) as an integer.",
                expectedValue: Double(val),
                tolerance: 0.01,
                unitLabel: "",
                visualIntuitionStep: "Line up \(m) factors of \(base) next to \(n) factors of \(base), then cancel \(p) factors from the denominator.",
                ahaInvariantStep: "Multiplying powers of the same base concatenates factor chains (add exponents); dividing cancels matching pairs (subtract exponents).",
                formulaStep: "(a^m × a^n) ÷ a^p = a^(m + n − p)",
                stepByStepDerivation: [
                    "1. Combine numerator exponents: \(m) + \(n) = \(m + n).",
                    "2. Subtract denominator exponent: \(m + n) − \(p) = \(finalExp).",
                    "3. Evaluate \(base)^\(finalExp) = \(val)."
                ]
            )

        case .algebraicExpansionArea:
            let a = 30 + (s % 4) * 10
            let b = 2 + (s % 3)
            let plus = a + b
            let minus = a - b
            let ans = a * a - b * b
            return QuantitativeMathsProblem(
                id: "q-\(template.rawValue)-\(s)",
                template: template,
                seed: s,
                title: template.title,
                schoolTopicCode: "2.2",
                patternedWorldChapter: 3,
                prompt: "Use the Difference of Two Squares identity to mentally calculate \(plus) × \(minus).",
                expectedValue: Double(ans),
                tolerance: 0.01,
                unitLabel: "",
                visualIntuitionStep: "Start with an \(a) × \(a) square, slice a strip of width \(b) from one side and attach it to the other, leaving a tiny \(b) × \(b) corner missing.",
                ahaInvariantStep: "The +ab and −ab cross-rectangles cancel completely for any (a + b)(a − b).",
                formulaStep: "(a + b)(a − b) = a² − b²",
                stepByStepDerivation: [
                    "1. Rewrite \(plus) × \(minus) as (\(a) + \(b))(\(a) − \(b)).",
                    "2. Compute a² = \(a)² = \(a * a) and b² = \(b)² = \(b * b).",
                    "3. Subtract: \(a * a) − \(b * b) = \(ans)."
                ]
            )

        case .recurringDecimalToFraction:
            let twoDigit = [18, 27, 36, 45, 54, 63, 72, 81][s % 8]
            let g = gcd(twoDigit, 99)
            let num = twoDigit / g
            let den = 99 / g
            let sumNumDen = num + den
            return QuantitativeMathsProblem(
                id: "q-\(template.rawValue)-\(s)",
                template: template,
                seed: s,
                title: template.title,
                schoolTopicCode: "6.3",
                patternedWorldChapter: 4,
                prompt: "Convert the recurring decimal 0.\(twoDigit)\(twoDigit)\(twoDigit)... into its simplest fraction p/q, and enter the sum p + q.",
                expectedValue: Double(sumNumDen),
                tolerance: 0.01,
                unitLabel: "",
                visualIntuitionStep: "Align x = 0.\(twoDigit)\(twoDigit)... directly underneath 100x = \(twoDigit).\(twoDigit)\(twoDigit)... on a decimal place-value grid.",
                ahaInvariantStep: "Multiplying by 10² shifts a 2-digit repeating block by one full period, so subtracting x shears off the infinite tail cleanly.",
                formulaStep: "100x − x = 99x = \(twoDigit)  ⇒  x = \(twoDigit)/99 = \(num)/\(den)",
                stepByStepDerivation: [
                    "1. Let x = 0.\(twoDigit) recurring; then 100x = \(twoDigit).\(twoDigit) recurring.",
                    "2. Subtract: 99x = \(twoDigit) ⇒ x = \(twoDigit)/99.",
                    "3. Divide top and bottom by HCF(\(twoDigit), 99) = \(g) to get \(num)/\(den). Sum p + q = \(num) + \(den) = \(sumNumDen)."
                ]
            )

        case .linearEquationBarModel:
            let xVal = 7 + (s % 9)
            let leftCoeff = 5
            let rightCoeff = 2
            let rightConst = 12
            let leftConst = (leftCoeff - rightCoeff) * xVal - rightConst
            return QuantitativeMathsProblem(
                id: "q-\(template.rawValue)-\(s)",
                template: template,
                seed: s,
                title: template.title,
                schoolTopicCode: "7.2",
                patternedWorldChapter: 5,
                prompt: "Solve the linear equation \(leftCoeff)x − \(leftConst) = \(rightCoeff)x + \(rightConst) for x.",
                expectedValue: Double(xVal),
                tolerance: 0.01,
                unitLabel: "",
                visualIntuitionStep: "Draw two equal-length Singapore comparison bars: \(leftCoeff) x-blocks minus \(leftConst) on top, and \(rightCoeff) x-blocks plus \(rightConst) on bottom.",
                ahaInvariantStep: "Removing \(rightCoeff) matching x-blocks from both bars leaves \(leftCoeff - rightCoeff) x-blocks equal to \(leftConst + rightConst).",
                formulaStep: "(a − c)x = d + b  ⇒  x = (d + b) / (a − c)",
                stepByStepDerivation: [
                    "1. Subtract \(rightCoeff)x from both sides: \(leftCoeff - rightCoeff)x − \(leftConst) = \(rightConst).",
                    "2. Add \(leftConst) to both sides: \(leftCoeff - rightCoeff)x = \(rightConst + leftConst).",
                    "3. Divide by \(leftCoeff - rightCoeff): x = \(rightConst + leftConst) / \(leftCoeff - rightCoeff) = \(xVal)."
                ]
            )

        case .compoundPercentageMultiplier:
            let basePrice = 2000.0 + Double((s % 5) * 500)
            let p = 20.0
            let netPrice = basePrice * (1.0 + p / 100.0) * (1.0 - p / 100.0)
            return QuantitativeMathsProblem(
                id: "q-\(template.rawValue)-\(s)",
                template: template,
                seed: s,
                title: template.title,
                schoolTopicCode: "9.3",
                patternedWorldChapter: 6,
                prompt: "An item costing ₹\(Int(basePrice)) is increased by \(Int(p))% and then discounted by \(Int(p))%. What is its final price in ₹?",
                expectedValue: netPrice,
                tolerance: 0.05,
                unitLabel: "₹",
                visualIntuitionStep: "Stretch a 10 × 10 percentage square horizontally by 1.20 and compress it vertically by 0.80: the resulting rectangle covers 0.96 of the original area.",
                ahaInvariantStep: "The second percentage acts on the enlarged amount, so (1 + r)(1 − r) = 1 − r², always leaving a net loss of r².",
                formulaStep: "V_final = V_0 × (1 + r)(1 − r) = V_0 × (1 − r²)",
                stepByStepDerivation: [
                    "1. Upward multiplier = 1 + 0.20 = 1.20; downward multiplier = 1 − 0.20 = 0.80.",
                    "2. Combined multiplier = 1.20 × 0.80 = 0.96 (a 4% net decrease).",
                    "3. Final price = ₹\(Int(basePrice)) × 0.96 = ₹\(Int(netPrice))."
                ]
            )

        case .singaporeRatioDifference:
            let unitVal = 8 + (s % 6) * 2
            let transfer = unitVal
            let initialA = 5 * unitVal
            let initialB = 3 * unitVal
            let total = initialA + initialB
            return QuantitativeMathsProblem(
                id: "q-\(template.rawValue)-\(s)",
                template: template,
                seed: s,
                title: template.title,
                schoolTopicCode: "12.3",
                patternedWorldChapter: 7,
                prompt: "Aarav and Kym share marbles in the ratio 5 : 3. After Aarav gives Kym \(transfer) marbles, they have an equal number (1 : 1). How many marbles do they have in total?",
                expectedValue: Double(total),
                tolerance: 0.01,
                unitLabel: "marbles",
                visualIntuitionStep: "Draw 5 equal bar units for Aarav and 3 equal bar units for Kym (total = 8 units). Moving 1 unit from Aarav to Kym makes both bars 4 units long.",
                ahaInvariantStep: "Internal transfers conserve the total number of units (5 + 3 = 4 + 4 = 8 units), so 1 bar unit equals \(transfer) marbles.",
                formulaStep: "1 unit = Δtransfer = \(transfer)  ⇒  Total (8 units) = 8 × \(transfer)",
                stepByStepDerivation: [
                    "1. Initial ratio = 5 : 3 (8 units total); final equal ratio = 4 : 4 (8 units total).",
                    "2. Aarav drops from 5 units to 4 units, so 1 unit = \(transfer) marbles.",
                    "3. Total marbles = 8 units × \(transfer) = \(total)."
                ]
            )

        case .arithmeticSequenceNthTerm:
            let a = 5 + (s % 4)
            let d = 3 + (s % 3)
            let n = 20
            let nth = a + (n - 1) * d
            return QuantitativeMathsProblem(
                id: "q-\(template.rawValue)-\(s)",
                template: template,
                seed: s,
                title: template.title,
                schoolTopicCode: "11.2",
                patternedWorldChapter: 8,
                prompt: "An arithmetic sequence starts \(a), \(a + d), \(a + 2 * d), \(a + 3 * d)... Find the \(n)th term T_\(n).",
                expectedValue: Double(nth),
                tolerance: 0.01,
                unitLabel: "",
                visualIntuitionStep: "Build a staircase starting at height a = \(a) where each step after the first adds a riser of height d = \(d).",
                ahaInvariantStep: "To reach the \(n)th step from the 1st step, you climb (n − 1) risers—not n risers.",
                formulaStep: "T_n = a + (n − 1)d",
                stepByStepDerivation: [
                    "1. Identify first term a = \(a) and common difference d = \(d).",
                    "2. Substitute n = \(n): T_\(n) = \(a) + (\(n) − 1) × \(d).",
                    "3. T_\(n) = \(a) + 19 × \(d) = \(nth)."
                ]
            )

        case .polygonExteriorInteriorAngle:
            let sides = [6, 8, 9, 10, 12][s % 5]
            let ext = 360 / sides
            let interior = 180 - ext
            return QuantitativeMathsProblem(
                id: "q-\(template.rawValue)-\(s)",
                template: template,
                seed: s,
                title: template.title,
                schoolTopicCode: "8.1",
                patternedWorldChapter: 9,
                prompt: "Calculate the size of one interior angle of a regular \(sides)-sided polygon (in degrees).",
                expectedValue: Double(interior),
                tolerance: 0.01,
                unitLabel: "°",
                visualIntuitionStep: "Walk around the perimeter of a regular \(sides)-gon. At each vertex you turn by the exterior angle e; after \(sides) turns you have spun one full 360° circle.",
                ahaInvariantStep: "Because the exterior turns always sum to 360°, each exterior angle is 360°/n, and each interior angle is its straight-line supplement 180° − 360°/n.",
                formulaStep: "Interior angle = 180° − (360° / n)",
                stepByStepDerivation: [
                    "1. Find one exterior angle: e = 360° / \(sides) = \(ext)°.",
                    "2. Subtract from 180° on a straight line: Interior = 180° − \(ext)° = \(interior)°."
                ]
            )

        case .circleSectorAndPrismVolume:
            let b = 6.0 + Double(s % 5) * 2.0
            let h = 5.0 + Double(s % 4)
            let length = 10.0 + Double(s % 3) * 2.0
            let area = 0.5 * b * h
            let vol = area * length
            return QuantitativeMathsProblem(
                id: "q-\(template.rawValue)-\(s)",
                template: template,
                seed: s,
                title: template.title,
                schoolTopicCode: "5.3",
                patternedWorldChapter: 10,
                prompt: "A triangular prism has a triangular cross-section of base \(Int(b)) cm and perpendicular height \(Int(h)) cm, and length \(Int(length)) cm. Calculate its volume in cm³.",
                expectedValue: vol,
                tolerance: 0.05,
                unitLabel: "cm³",
                visualIntuitionStep: "Slice the triangular prism into \(Int(length)) identical 1 cm thick triangular slabs and stack them along the prism's axis.",
                ahaInvariantStep: "Every cross-sectional slice has the same area A = ½bh, so extruding that slice through length L sweeps out volume V = A × L.",
                formulaStep: "V = A_cross × L = (½ × b × h) × L",
                stepByStepDerivation: [
                    "1. Cross-sectional triangle area A = ½ × \(Int(b)) × \(Int(h)) = \(Int(area)) cm².",
                    "2. Multiply by prism length L = \(Int(length)) cm: V = \(Int(area)) × \(Int(length)) = \(Int(vol)) cm³."
                ]
            )

        case .bearingsPythagorasDistance:
            let triples = [(6, 8, 10), (9, 12, 15), (12, 16, 20), (15, 20, 25), (8, 15, 17)]
            let (east, north, hyp) = triples[s % triples.count]
            return QuantitativeMathsProblem(
                id: "q-\(template.rawValue)-\(s)",
                template: template,
                seed: s,
                title: template.title,
                schoolTopicCode: "3.3",
                patternedWorldChapter: 11,
                prompt: "A ship sails \(east) km on a bearing of 090° (due East) and then \(north) km on a bearing of 000° (due North). How far is the ship in a straight line from its starting port?",
                expectedValue: Double(hyp),
                tolerance: 0.01,
                unitLabel: "km",
                visualIntuitionStep: "Draw the East leg (\(east) km) and North leg (\(north) km) meeting at 90°, then rearrange 4 copies of that right triangle inside a square of side (\(east) + \(north)).",
                ahaInvariantStep: "Tilting the 4 right triangles inside the outer square reveals that the central tilted square c² has the exact same area as a² + b².",
                formulaStep: "d = √(Δx² + Δy²) = √(\(east)² + \(north)²)",
                stepByStepDerivation: [
                    "1. Bearings 090° and 000° meet at a right angle (90°).",
                    "2. Compute squares: \(east)² + \(north)² = \(east * east) + \(north * north) = \(hyp * hyp).",
                    "3. Distance d = √\(hyp * hyp) = \(hyp) km."
                ]
            )

        case .cosineRuleAndUnitCircle:
            // 60 degree triangle with cos(60) = 0.5
            let a = 8.0
            let b = 5.0 + Double(s % 4)
            let cSquared = a * a + b * b - 2.0 * a * b * 0.5
            return QuantitativeMathsProblem(
                id: "q-\(template.rawValue)-\(s)",
                template: template,
                seed: s,
                title: template.title,
                schoolTopicCode: "8.2",
                patternedWorldChapter: 12,
                prompt: "In triangle ABC, side a = \(Int(a)) cm, side b = \(Int(b)) cm, and included angle C = 60° (where cos 60° = 0.5). Calculate c² using the Law of Cosines.",
                expectedValue: cSquared,
                tolerance: 0.05,
                unitLabel: "cm²",
                visualIntuitionStep: "Hinge two rods of lengths a = \(Int(a)) and b = \(Int(b)) at angle C = 60° on the unit circle, where the horizontal projection of rod b onto rod a is b cos 60°.",
                ahaInvariantStep: "When C < 90°, the third side is shorter than the Pythagorean hypotenuse by twice the projected overlap rectangle 2ab cos C.",
                formulaStep: "c² = a² + b² − 2ab cos C",
                stepByStepDerivation: [
                    "1. Compute Pythagorean sum: a² + b² = \(Int(a * a)) + \(Int(b * b)) = \(Int(a * a + b * b)).",
                    "2. Subtract cosine correction: 2 × \(Int(a)) × \(Int(b)) × cos(60°) = 2 × \(Int(a * b)) × 0.5 = \(Int(a * b)).",
                    "3. c² = \(Int(a * a + b * b)) − \(Int(a * b)) = \(Int(cSquared))."
                ]
            )

        case .histogramFrequencyDensity:
            let width = [5, 10, 20][s % 3]
            let density = Double(3 + (s % 5))
            let freq = Double(width) * density
            return QuantitativeMathsProblem(
                id: "q-\(template.rawValue)-\(s)",
                template: template,
                seed: s,
                title: template.title,
                schoolTopicCode: "10.3",
                patternedWorldChapter: 13,
                prompt: "In an unequal-width histogram, a class interval of width \(width) minutes has a bar height (Frequency Density) of \(Int(density)). How many observations (Frequency) are in this interval?",
                expectedValue: freq,
                tolerance: 0.01,
                unitLabel: "observations",
                visualIntuitionStep: "Look at the histogram rectangle of base width Δx = \(width) and height FD = \(Int(density)): each unit square of area inside the bar represents 1 observation.",
                ahaInvariantStep: "In a true histogram, it is the AREA of the bar (not its height alone) that equals the frequency.",
                formulaStep: "Frequency Density = Frequency / Class Width  ⇒  Frequency = FD × Class Width",
                stepByStepDerivation: [
                    "1. Identify class width Δx = \(width) and Frequency Density = \(Int(density)).",
                    "2. Compute bar area: Frequency = \(Int(density)) × \(width) = \(Int(freq))."
                ]
            )

        case .combinatoricsPermutations:
            let n = 5 + (s % 4)
            let ways = n * (n - 1) * (n - 2)
            return QuantitativeMathsProblem(
                id: "q-\(template.rawValue)-\(s)",
                template: template,
                seed: s,
                title: template.title,
                schoolTopicCode: "15.4",
                patternedWorldChapter: 14,
                prompt: "From \(n) finalists in a mathematics olympiad, how many different ways can Gold (1st), Silver (2nd), and Bronze (3rd) medals be awarded?",
                expectedValue: Double(ways),
                tolerance: 0.01,
                unitLabel: "ways",
                visualIntuitionStep: "Draw a 3-stage branching decision tree: \(n) branches for Gold, each splitting into \(n - 1) branches for Silver, each splitting into \(n - 2) branches for Bronze.",
                ahaInvariantStep: "Because every choice at stage 1 unlocks an identical fan of choices at stage 2, the total leaf count is the product of branching factors.",
                formulaStep: "P(n, 3) = n! / (n − 3)! = n × (n − 1) × (n − 2)",
                stepByStepDerivation: [
                    "1. Choices for Gold = \(n).",
                    "2. Remaining choices for Silver = \(n - 1); remaining for Bronze = \(n - 2).",
                    "3. Total ordered arrangements = \(n) × \(n - 1) × \(n - 2) = \(ways)."
                ]
            )

        case .bayesNaturalFrequencySquare:
            // 1000 people, 1% prevalence (10 sick, 990 healthy)
            let truePos = 9
            let falsePos = (1 + (s % 3)) * 9 // 9, 18, or 27
            let totalPos = truePos + falsePos
            let pct = (Double(truePos) / Double(totalPos)) * 100.0
            return QuantitativeMathsProblem(
                id: "q-\(template.rawValue)-\(s)",
                template: template,
                seed: s,
                title: template.title,
                schoolTopicCode: "15.3",
                patternedWorldChapter: 15,
                prompt: "In a cohort of 1,000 people, \(truePos) truly sick people test positive (True Positives) and \(falsePos) healthy people also test positive (False Positives). If a person tests positive, what is the exact posterior percentage probability P(Sick | +) that they are truly sick?",
                expectedValue: pct,
                tolerance: 0.2,
                unitLabel: "%",
                visualIntuitionStep: "Colour the 1,000-person unit square: once the test comes back positive, zoom in until ONLY the \(truePos) red True-Positive tiles and \(falsePos) amber False-Positive tiles fill the frame.",
                ahaInvariantStep: "Conditioning on '+' throws away all negative results and makes the total positive tiles (\(truePos) + \(falsePos) = \(totalPos)) the new denominator.",
                formulaStep: "P(A | B) = True Positives / (True Positives + False Positives)",
                stepByStepDerivation: [
                    "1. Total positive tests = \(truePos) + \(falsePos) = \(totalPos).",
                    "2. Posterior fraction P(Sick | +) = \(truePos) / \(totalPos).",
                    "3. Percentage = (\(truePos) / \(totalPos)) × 100% = \(String(format: "%.1f", pct))%."
                ]
            )

        case .linearGraphGradientMidpoint:
            let x1 = 2
            let y1 = 3
            let dx = 4
            let m = 2 + (s % 4)
            let x2 = x1 + dx
            let y2 = y1 + m * dx
            return QuantitativeMathsProblem(
                id: "q-\(template.rawValue)-\(s)",
                template: template,
                seed: s,
                title: template.title,
                schoolTopicCode: "14.2",
                patternedWorldChapter: 16,
                prompt: "Find the gradient m of the straight line passing through A(\(x1), \(y1)) and B(\(x2), \(y2)).",
                expectedValue: Double(m),
                tolerance: 0.01,
                unitLabel: "",
                visualIntuitionStep: "Draw a right-angled slope triangle under segment AB: step \(dx) units right (run) and climb \(y2 - y1) units up (rise).",
                ahaInvariantStep: "By similar triangles, the ratio of vertical rise Δy to horizontal run Δx is identical between any two points on a straight line.",
                formulaStep: "m = Δy / Δx = (y₂ − y₁) / (x₂ − x₁)",
                stepByStepDerivation: [
                    "1. Vertical rise Δy = \(y2) − \(y1) = \(y2 - y1).",
                    "2. Horizontal run Δx = \(x2) − \(x1) = \(dx).",
                    "3. Gradient m = \(y2 - y1) / \(dx) = \(m)."
                ]
            )

        case .instantaneousSecantDerivative:
            let a = 1 + (s % 3)
            let x0 = 2 + (s % 4)
            let deriv = 2 * a * x0
            return QuantitativeMathsProblem(
                id: "q-\(template.rawValue)-\(s)",
                template: template,
                seed: s,
                title: template.title,
                schoolTopicCode: "14.3",
                patternedWorldChapter: 17,
                prompt: "Find the instantaneous rate of change (tangent slope dy/dx) of the parabola y = \(a)x² at x = \(x0).",
                expectedValue: Double(deriv),
                tolerance: 0.01,
                unitLabel: "",
                visualIntuitionStep: "Slide the second point of a secant chord along y = \(a)x² toward x = \(x0) until Δx → 0 and the chord locks onto the tangent line.",
                ahaInvariantStep: "Expanding \(a)(x + h)² − \(a)x² leaves \(2 * a)xh + \(a)h²; dividing by h gives \(2 * a)x + \(a)h, and as h → 0 the h-term vanishes.",
                formulaStep: "d/dx (ax²) = 2ax",
                stepByStepDerivation: [
                    "1. Differentiate y = \(a)x² using the power rule: dy/dx = 2 × \(a)x = \(2 * a)x.",
                    "2. Evaluate at x = \(x0): dy/dx = \(2 * a) × \(x0) = \(deriv)."
                ]
            )

        case .riemannDefiniteIntegralArea:
            let upper = 2 + (s % 3) // 2, 3, or 4
            let area = Double(upper * upper * upper) // integral of 3x^2 from 0 to upper is upper^3
            return QuantitativeMathsProblem(
                id: "q-\(template.rawValue)-\(s)",
                template: template,
                seed: s,
                title: template.title,
                schoolTopicCode: "14.3",
                patternedWorldChapter: 18,
                prompt: "Evaluate the exact area under the curve f(x) = 3x² from x = 0 to x = \(upper), i.e. ∫₀^\(upper) 3x² dx.",
                expectedValue: area,
                tolerance: 0.01,
                unitLabel: "sq units",
                visualIntuitionStep: "Increase the number of Riemann rectangles under f(x) = 3x² on [0, \(upper)] from N = 4 to N = 60 until the stepped tops merge with the smooth curve.",
                ahaInvariantStep: "Because the rate of growth of the area function A(x) is the curve height 3x², the area function must be the antiderivative F(x) = x³.",
                formulaStep: "∫₀^b 3x² dx = [x³]₀^b = b³ − 0³",
                stepByStepDerivation: [
                    "1. Find the antiderivative of 3x²: F(x) = x³ (since d/dx(x³) = 3x²).",
                    "2. Apply the Fundamental Theorem of Calculus: F(\(upper)) − F(0) = \(upper)³ − 0 = \(Int(area))."
                ]
            )

        case .vectorMagnitudeDotProduct:
            let pairs = [(3, 4, 5), (5, 12, 13), (8, 15, 17), (6, 8, 10)]
            let (vx, vy, mag) = pairs[s % pairs.count]
            return QuantitativeMathsProblem(
                id: "q-\(template.rawValue)-\(s)",
                template: template,
                seed: s,
                title: template.title,
                schoolTopicCode: "16.1",
                patternedWorldChapter: 19,
                prompt: "Calculate the magnitude |v| of the column vector v = (\(vx), \(vy)).",
                expectedValue: Double(mag),
                tolerance: 0.01,
                unitLabel: "units",
                visualIntuitionStep: "Draw the arrow v stepping \(vx) units right and \(vy) units up on a coordinate grid, forming a right-angled triangle with the arrow as hypotenuse.",
                ahaInvariantStep: "Translating a vector anywhere on the plane leaves its horizontal step vx, vertical step vy, and hypotenuse length √(vx² + vy²) invariant.",
                formulaStep: "|v| = √(vx² + vy²)",
                stepByStepDerivation: [
                    "1. Square the components: \(vx)² + \(vy)² = \(vx * vx) + \(vy * vy) = \(mag * mag).",
                    "2. Take the square root: |v| = √\(mag * mag) = \(mag)."
                ]
            )

        case .matrixDeterminantEigenvalue:
            let a = 3 + (s % 3)
            let d = 2 + (s % 4)
            let b = 1
            let c = 2
            let det = a * d - b * c
            return QuantitativeMathsProblem(
                id: "q-\(template.rawValue)-\(s)",
                template: template,
                seed: s,
                title: template.title,
                schoolTopicCode: "13.5",
                patternedWorldChapter: 20,
                prompt: "A 2×2 linear transformation matrix is A = [[\(a), \(b)], [\(c), \(d)]]. By what area scale factor det(A) does this matrix scale any shape in the plane?",
                expectedValue: Double(det),
                tolerance: 0.01,
                unitLabel: "× area",
                visualIntuitionStep: "Drag the red basis vector Aî to (\(a), \(c)) and the blue basis vector Aĵ to (\(b), \(d)) in the 3D Matrix Sandbox and watch the amber unit square stretch into a parallelogram.",
                ahaInvariantStep: "Enclosing the sheared parallelogram inside an (\(a)+\(b)) × (\(c)+\(d)) bounding box and subtracting the corner triangles leaves exact area ad − bc.",
                formulaStep: "det([[a, b], [c, d]]) = ad − bc",
                stepByStepDerivation: [
                    "1. Multiply main diagonal entries: a × d = \(a) × \(d) = \(a * d).",
                    "2. Subtract off-diagonal product: b × c = \(b) × \(c) = \(b * c).",
                    "3. Determinant det(A) = \(a * d) − \(b * c) = \(det)."
                ]
            )
        }
    }

    static func evaluate(problem: QuantitativeMathsProblem, numericInput: String) -> QuantitativeAttemptEvaluation? {
        let cleaned = numericInput
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: "₹", with: "")
            .replacingOccurrences(of: "%", with: "")
            .replacingOccurrences(of: "°", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let value = Double(cleaned) else { return nil }
        let err = abs(value - problem.expectedValue)
        let ok = err <= problem.tolerance

        let feedback: String
        if ok {
            feedback = "Exact match! Expected \(formatNumber(problem.expectedValue)) \(problem.unitLabel). Notice how the visual invariant guarantees the formula."
        } else {
            feedback = "Submitted \(formatNumber(value)), expected \(formatNumber(problem.expectedValue)) \(problem.unitLabel). Check the Intuition → Formula steps below."
        }

        return QuantitativeAttemptEvaluation(
            isCorrect: ok,
            submittedValue: value,
            expectedValue: problem.expectedValue,
            absoluteError: err,
            feedback: feedback
        )
    }

    private static func formatNumber(_ x: Double) -> String {
        if abs(x.rounded() - x) < 0.001 {
            return String(Int(x.rounded()))
        }
        return String(format: "%.2f", x)
    }
}
