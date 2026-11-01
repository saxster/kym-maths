import CryptoKit
import Foundation

// MARK: - Exact Symbolic Polynomial & Dimensional Unit Verification (Ported from ../kym_tutor)

/// A deliberately finite grammar, not a Wolfram Language or natural-language evaluator.
/// Exact polynomials over the rationals, degree <= 8, one explicitly declared real variable.
/// Variable denominators are refused even if cancellation would hide their domain holes.
public enum STEMComputationError: Error, Equatable {
    case unsupportedExpression
    case arithmeticLimit
    case invalidEvidence
    case contradictedClaim
}

public struct STEMRational: Equatable, Sendable, Codable {
    public let numerator: Int64
    public let denominator: Int64

    public init(_ numerator: Int64, _ denominator: Int64 = 1) throws {
        guard denominator != 0, numerator != .min, denominator != .min else {
            throw STEMComputationError.arithmeticLimit
        }
        let divisor = Self.gcd(abs(numerator), abs(denominator))
        self.numerator = (denominator < 0 ? -numerator : numerator) / divisor
        self.denominator = abs(denominator) / divisor
    }

    public static func parse(_ text: String) throws -> Self {
        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count <= 2, parts.allSatisfy({ !$0.isEmpty }),
              parts.allSatisfy({ $0.allSatisfy { $0.isASCII && $0.isNumber } }),
              parts.joined().count <= 12, let numerator = Int64(parts.joined()) else {
            throw STEMComputationError.unsupportedExpression
        }
        var denominator: Int64 = 1
        if parts.count == 2 {
            for _ in parts[1] { denominator *= 10 }
        }
        return try Self(numerator, denominator)
    }

    public func adding(_ other: Self) throws -> Self {
        let divisor = Self.gcd(denominator, other.denominator)
        let left = try Self.multiply(numerator, other.denominator / divisor)
        let right = try Self.multiply(other.numerator, denominator / divisor)
        let (sum, overflow) = left.addingReportingOverflow(right)
        guard !overflow else { throw STEMComputationError.arithmeticLimit }
        return try Self(sum, Self.multiply(denominator, other.denominator / divisor))
    }

    public func multiplied(by other: Self) throws -> Self {
        let first = Self.gcd(abs(numerator), other.denominator)
        let second = Self.gcd(abs(other.numerator), denominator)
        return try Self(
            Self.multiply(numerator / first, other.numerator / second),
            Self.multiply(denominator / second, other.denominator / first)
        )
    }

    public func divided(by other: Self) throws -> Self {
        guard other.numerator != 0 else { throw STEMComputationError.unsupportedExpression }
        return try multiplied(by: Self(other.denominator, other.numerator))
    }

    public func negated() throws -> Self {
        try Self(-numerator, denominator)
    }

    private static func multiply(_ first: Int64, _ second: Int64) throws -> Int64 {
        let (value, overflow) = first.multipliedReportingOverflow(by: second)
        guard !overflow else { throw STEMComputationError.arithmeticLimit }
        return value
    }

    private static func gcd(_ first: Int64, _ second: Int64) -> Int64 {
        var a = first
        var b = second
        while b != 0 {
            let remainder = a % b
            a = b
            b = remainder
        }
        return max(1, a)
    }
}

public struct STEMPolynomial: Equatable, Sendable {
    // Missing coefficients are exact zeroes. Empty dictionary represents zero.
    public var coefficients: [Int: STEMRational]

    public init(coefficients: [Int: STEMRational]) {
        self.coefficients = coefficients
    }

    public static func parse(_ text: String, variable: String? = nil) throws -> Self {
        var parser = try Parser(text, variable: variable)
        return try parser.parse()
    }

    public var constant: STEMRational? {
        guard coefficients.keys.allSatisfy({ $0 == 0 }) else { return nil }
        if let value = coefficients[0] { return value }
        do { return try STEMRational(0) } catch { return nil }
    }

    private func adding(_ other: Self) throws -> Self {
        var result = coefficients
        for (power, value) in other.coefficients {
            let sum = try (result[power] ?? STEMRational(0)).adding(value)
            result[power] = sum.numerator == 0 ? nil : sum
        }
        return Self(coefficients: result)
    }

    public func multiplied(by other: Self) throws -> Self {
        var result = Self(coefficients: [:])
        for (firstPower, first) in coefficients {
            for (secondPower, second) in other.coefficients {
                let power = firstPower + secondPower
                guard power <= 8 else { throw STEMComputationError.arithmeticLimit }
                let value = try first.multiplied(by: second)
                result = try result.adding(Self(coefficients: value.numerator == 0 ? [:] : [power: value]))
            }
        }
        return result
    }

    /// Checks whether two algebraic expressions are symbolically equivalent polynomials over Q
    /// for a single variable (inferred automatically if not provided).
    public static func areEquivalent(
        _ firstExpression: String,
        _ secondExpression: String,
        variable: String? = nil
    ) -> Bool {
        let resolvedVariable = variable ?? inferSingleVariable(from: firstExpression + " " + secondExpression)
        do {
            let left = try parse(firstExpression, variable: resolvedVariable)
            let right = try parse(secondExpression, variable: resolvedVariable)
            return left == right
        } catch {
            return false
        }
    }

    private static func inferSingleVariable(from text: String) -> String? {
        let letters = Set(text.lowercased().filter { $0.isASCII && $0 >= "a" && $0 <= "z" })
        guard letters.count == 1, let single = letters.first else { return nil }
        return String(single)
    }

    private struct Parser {
        let tokens: [String]
        let variable: String?
        var index = 0
        var depth = 0

        init(_ text: String, variable: String?) throws {
            guard !text.isEmpty, text.count <= 256 else { throw STEMComputationError.unsupportedExpression }
            if let variable {
                guard variable.count == 1, let letter = variable.first,
                      letter.isASCII, letter >= "a", letter <= "z" else {
                    throw STEMComputationError.unsupportedExpression
                }
            }
            self.variable = variable
            let normalized = text
                .replacingOccurrences(of: "−", with: "-")
                .replacingOccurrences(of: "×", with: "*")
                .replacingOccurrences(of: "÷", with: "/")
                .replacingOccurrences(of: "²", with: "^2")
                .replacingOccurrences(of: "³", with: "^3")
            let chars = Array(normalized)
            var result: [String] = []
            var position = 0
            while position < chars.count {
                let char = chars[position]
                if char.isWhitespace { position += 1; continue }
                if char.isASCII && char.isNumber {
                    let start = position
                    while position < chars.count && ((chars[position].isASCII && chars[position].isNumber) || chars[position] == ".") {
                        position += 1
                    }
                    result.append(String(chars[start..<position]))
                } else {
                    guard "+-*/^()".contains(char) || String(char) == variable else {
                        throw STEMComputationError.unsupportedExpression
                    }
                    result.append(String(char))
                    position += 1
                }
            }
            guard !result.isEmpty, result.count <= 128 else { throw STEMComputationError.unsupportedExpression }
            tokens = result
        }

        mutating func parse() throws -> STEMPolynomial {
            let result = try sum()
            guard index == tokens.count else { throw STEMComputationError.unsupportedExpression }
            return result
        }

        var next: String? { index < tokens.count ? tokens[index] : nil }

        mutating func take(_ token: String) -> Bool {
            guard next == token else { return false }
            index += 1
            return true
        }

        mutating func sum() throws -> STEMPolynomial {
            var value = try product()
            while next == "+" || next == "-" {
                let subtract = take("-")
                if !subtract { _ = take("+") }
                var right = try product()
                if subtract { right = try negate(right) }
                value = try value.adding(right)
            }
            return value
        }

        mutating func product() throws -> STEMPolynomial {
            var value = try unary()
            while let token = next {
                if take("*") {
                    value = try value.multiplied(by: unary())
                } else if take("/") {
                    let divisor = try unary()
                    guard let constant = divisor.constant, constant.numerator != 0 else {
                        throw STEMComputationError.unsupportedExpression
                    }
                    let reciprocal = try STEMRational(1).divided(by: constant)
                    value = try value.multiplied(by: STEMPolynomial(coefficients: [0: reciprocal]))
                } else if token == variable || token == "(" {
                    value = try value.multiplied(by: unary())
                } else {
                    break
                }
            }
            return value
        }

        mutating func unary() throws -> STEMPolynomial {
            depth += 1
            defer { depth -= 1 }
            guard depth <= 24 else { throw STEMComputationError.arithmeticLimit }
            if take("+") { return try unary() }
            if take("-") { return try negate(unary()) }
            var value = try atom()
            if take("^") {
                guard let token = next, let power = Int(token), (0...8).contains(power) else {
                    throw STEMComputationError.unsupportedExpression
                }
                index += 1
                let base = value
                if power == 0, base.coefficients.isEmpty { throw STEMComputationError.unsupportedExpression }
                value = STEMPolynomial(coefficients: [0: try STEMRational(1)])
                for _ in 0..<power { value = try value.multiplied(by: base) }
            }
            return value
        }

        mutating func atom() throws -> STEMPolynomial {
            if take("(") {
                let value = try sum()
                guard take(")") else { throw STEMComputationError.unsupportedExpression }
                return value
            }
            guard let token = next else { throw STEMComputationError.unsupportedExpression }
            index += 1
            if token == variable { return STEMPolynomial(coefficients: [1: try STEMRational(1)]) }
            let number = try STEMRational.parse(token)
            return STEMPolynomial(coefficients: number.numerator == 0 ? [:] : [0: number])
        }

        func negate(_ value: STEMPolynomial) throws -> STEMPolynomial {
            try value.multiplied(by: STEMPolynomial(coefficients: [0: STEMRational(-1)]))
        }
    }
}

// MARK: - SI Multiplicative Dimensional Unit Checker

public struct STEMUnit: Equatable, Sendable {
    public let dimensions: [Int]
    public let scale: STEMRational

    public static func parse(_ text: String) throws -> Self {
        guard !text.isEmpty, text.count <= 64 else { throw STEMComputationError.unsupportedExpression }
        let compact = text.replacingOccurrences(of: " ", with: "")
        let pieces = compact.components(separatedBy: CharacterSet(charactersIn: "*/"))
        let operators = compact.filter { $0 == "*" || $0 == "/" }
        guard pieces.count <= 8 else { throw STEMComputationError.unsupportedExpression }
        var dimensions = [0, 0, 0, 0, 0]
        var scale = try STEMRational(1)
        for (index, piece) in pieces.enumerated() {
            let parts = piece.split(separator: "^", omittingEmptySubsequences: false)
            guard (1...2).contains(parts.count) else { throw STEMComputationError.unsupportedExpression }
            let base = try baseUnit(String(parts[0]))
            let power: Int
            if parts.count == 2 {
                guard let exponent = Int(parts[1]), (-3...3).contains(exponent) else {
                    throw STEMComputationError.unsupportedExpression
                }
                power = exponent
            } else {
                power = 1
            }
            let division = index > 0 && Array(operators)[index - 1] == "/"
            let signedPower = division ? -power : power
            for dimension in dimensions.indices {
                dimensions[dimension] += base.dimensions[dimension] * signedPower
            }
            let factor = signedPower < 0 ? try STEMRational(1).divided(by: base.scale) : base.scale
            for _ in 0..<abs(signedPower) { scale = try scale.multiplied(by: factor) }
        }
        return Self(dimensions: dimensions, scale: scale)
    }

    private static func baseUnit(_ symbol: String) throws -> Self {
        let units: [String: ([Int], Int64, Int64)] = [
            "1": ([0, 0, 0, 0, 0], 1, 1),
            "kg": ([1, 0, 0, 0, 0], 1, 1), "g": ([1, 0, 0, 0, 0], 1, 1_000),
            "m": ([0, 1, 0, 0, 0], 1, 1), "cm": ([0, 1, 0, 0, 0], 1, 100),
            "mm": ([0, 1, 0, 0, 0], 1, 1_000), "dm": ([0, 1, 0, 0, 0], 1, 10),
            "km": ([0, 1, 0, 0, 0], 1_000, 1),
            "s": ([0, 0, 1, 0, 0], 1, 1), "min": ([0, 0, 1, 0, 0], 60, 1),
            "h": ([0, 0, 1, 0, 0], 3_600, 1),
            "A": ([0, 0, 0, 1, 0], 1, 1), "mol": ([0, 0, 0, 0, 1], 1, 1),
            "N": ([1, 1, -2, 0, 0], 1, 1), "J": ([1, 2, -2, 0, 0], 1, 1),
            "W": ([1, 2, -3, 0, 0], 1, 1), "V": ([1, 2, -3, -1, 0], 1, 1),
            "L": ([0, 3, 0, 0, 0], 1, 1_000), "mL": ([0, 3, 0, 0, 0], 1, 1_000_000)
        ]
        guard let unit = units[symbol] else { throw STEMComputationError.unsupportedExpression }
        return try Self(dimensions: unit.0, scale: STEMRational(unit.1, unit.2))
    }
}

// MARK: - STEM Computational Claim & Verification Receipt

public enum STEMVerificationStatus: String, Codable, Sendable {
    case verified, contradicted, unresolved
}

public struct STEMComputationalClaim: Codable, Equatable, Sendable {
    public var excerpt: String
    public var left: String
    public var right: String
    public var variable: String?
    public var assumptions: String
    public var sourceFingerprint: String?
    public var leftUnit: String?
    public var rightUnit: String?

    public init(
        excerpt: String,
        left: String,
        right: String,
        variable: String? = nil,
        assumptions: String,
        sourceFingerprint: String? = nil,
        leftUnit: String? = nil,
        rightUnit: String? = nil
    ) {
        self.excerpt = excerpt
        self.left = left
        self.right = right
        self.variable = variable
        self.assumptions = assumptions
        self.sourceFingerprint = sourceFingerprint
        self.leftUnit = leftUnit
        self.rightUnit = rightUnit
    }
}

public struct STEMVerificationReceipt: Codable, Equatable, Sendable {
    public let claim: STEMComputationalClaim
    public let status: STEMVerificationStatus
    public let contentFingerprint: String
    public let checker: String
    public let scope: String
}

public enum STEMVerification {
    public static let checker = "kymaia-exact-polynomial-v1"
    public static let scope = "Formalized equality only; source interpretation and teaching quality are separate."

    public static func fingerprint(_ content: String) -> String {
        SHA256.hash(data: Data(content.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    public static func check(_ claim: STEMComputationalClaim, content: String) -> STEMVerificationReceipt {
        let status: STEMVerificationStatus
        let validSource = !claim.excerpt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && content.contains(claim.excerpt)
        let validAssumptions = !claim.assumptions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let currentSource = claim.sourceFingerprint == nil || claim.sourceFingerprint == fingerprint(content)
        if validSource && validAssumptions && currentSource {
            do {
                let left = try STEMPolynomial.parse(claim.left, variable: claim.variable)
                let right = try STEMPolynomial.parse(claim.right, variable: claim.variable)
                let leftUnit = try STEMUnit.parse(claim.leftUnit ?? "1")
                let rightUnit = try STEMUnit.parse(claim.rightUnit ?? "1")
                let scaledLeft = try left.multiplied(by: STEMPolynomial(coefficients: [0: leftUnit.scale]))
                let scaledRight = try right.multiplied(by: STEMPolynomial(coefficients: [0: rightUnit.scale]))
                status = leftUnit.dimensions == rightUnit.dimensions && scaledLeft == scaledRight ? .verified : .contradicted
            } catch {
                status = .unresolved
            }
        } else {
            status = .unresolved
        }
        return STEMVerificationReceipt(
            claim: claim,
            status: status,
            contentFingerprint: fingerprint(content),
            checker: checker,
            scope: scope
        )
    }
}
