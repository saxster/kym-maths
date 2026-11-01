import Foundation
import SwiftUI

// MARK: - Logical Coordinate Space

/// Fixed logical coordinate space (`1000 x 640`) used by both the AI Mentor's
/// `render_interactive_canvas` tool and Kym's interactive chalkboard gestures.
/// Keeping a device-independent logical coordinate space ensures LLM-generated
/// bar models, number lines, geometric constructions, and freehand annotations
/// align deterministically across iPad 11", iPad 13", Split View, and macOS.
public enum TutorCanvasSpace {
    public static let width: Double = 1000
    public static let height: Double = 640
    public static let size = CGSize(width: width, height: height)
    public static let aspectRatio: CGFloat = CGFloat(width / height)

    public static func toView(_ point: CGPoint, in viewSize: CGSize) -> CGPoint {
        guard viewSize.width > 0, viewSize.height > 0 else { return .zero }
        return CGPoint(
            x: point.x / width * viewSize.width,
            y: point.y / height * viewSize.height
        )
    }

    public static func toLogical(_ point: CGPoint, in viewSize: CGSize) -> CGPoint {
        guard viewSize.width > 0, viewSize.height > 0 else { return .zero }
        return CGPoint(
            x: clamp(Double(point.x / viewSize.width) * width, min: 0, max: width),
            y: clamp(Double(point.y / viewSize.height) * height, min: 0, max: height)
        )
    }

    public static func toLogicalDelta(_ delta: CGSize, in viewSize: CGSize) -> CGSize {
        guard viewSize.width > 0, viewSize.height > 0 else { return .zero }
        return CGSize(
            width: Double(delta.width / viewSize.width) * width,
            height: Double(delta.height / viewSize.height) * height
        )
    }

    public static func clamp(_ value: Double, min lower: Double, max upper: Double) -> Double {
        Swift.min(Swift.max(value, lower), upper)
    }
}

// MARK: - Semantic Color Role

public enum TutorCanvasColorRole: String, Codable, Sendable, CaseIterable, Equatable {
    case accent
    case secondary
    case success
    case warning
    case error
    case ink
    case muted

    public var swiftUIColor: Color {
        switch self {
        case .accent: return .kymaiaPrimary
        case .secondary: return .kymaiaSecondary
        case .success: return .kymaiaSuccess
        case .warning: return .kymaiaWarning
        case .error: return .kymaiaError
        case .ink: return .kymaiaInk
        case .muted: return .kymaiaMutedInk
        }
    }
}

// MARK: - Freehand Ink Conversion

public enum TutorCanvasInkConversion {
    public static func strokePoints(in points: [CGPoint], viewSize: CGSize) -> [CGPoint] {
        guard points.count >= 2,
              viewSize.width > 0,
              viewSize.height > 0 else {
            return []
        }
        return points.map { TutorCanvasSpace.toLogical($0, in: viewSize) }
    }
}

// MARK: - TutorCanvasShape

public struct TutorCanvasShape: Identifiable, Codable, Sendable, Equatable {
    public enum Kind: String, Codable, Sendable, Equatable {
        case rect
        case ellipse
        case line
        case arrow
        case text
        case numberLine = "number_line"
        case fractionBar = "fraction_bar"
        case sticker
    }

    public struct NumberLinePayload: Codable, Sendable, Equatable {
        public var min: Double
        public var max: Double
        public var marks: [Double]
        public var label: String?

        public init(min: Double, max: Double, marks: [Double] = [], label: String? = nil) {
            self.min = min
            self.max = max
            self.marks = marks
            self.label = label
        }
    }

    public struct FractionBarPayload: Codable, Sendable, Equatable {
        public var totalParts: Int
        public var filledParts: Int
        public var label: String?

        public init(totalParts: Int, filledParts: Int, label: String? = nil) {
            self.totalParts = totalParts
            self.filledParts = filledParts
            self.label = label
        }
    }

    public var id: String
    public var kind: Kind
    public var x: Double
    public var y: Double
    public var width: Double?
    public var height: Double?
    public var x2: Double?
    public var y2: Double?
    public var text: String?
    public var color: TutorCanvasColorRole
    public var filled: Bool
    public var numberLine: NumberLinePayload?
    public var fractionBar: FractionBarPayload?

    public init(
        id: String = UUID().uuidString,
        kind: Kind,
        x: Double,
        y: Double,
        width: Double? = nil,
        height: Double? = nil,
        x2: Double? = nil,
        y2: Double? = nil,
        text: String? = nil,
        color: TutorCanvasColorRole = .accent,
        filled: Bool = false,
        numberLine: NumberLinePayload? = nil,
        fractionBar: FractionBarPayload? = nil
    ) {
        self.id = id
        self.kind = kind
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.x2 = x2
        self.y2 = y2
        self.text = text
        self.color = color
        self.filled = filled
        self.numberLine = numberLine
        self.fractionBar = fractionBar
    }

    /// Logical bounding rectangle (`1000 x 640` space) used for hit-testing and drag selection.
    public var boundsRect: CGRect {
        switch kind {
        case .rect, .ellipse, .fractionBar:
            let w = Swift.max(width ?? 140, 24)
            let h = Swift.max(height ?? 72, 24)
            return CGRect(x: x, y: y, width: w, height: h)
        case .numberLine:
            let w = Swift.max(width ?? 560, 120)
            let h = Swift.max(height ?? 70, 44)
            return CGRect(x: x, y: y - h / 2, width: w, height: h)
        case .line, .arrow:
            let endX = x2 ?? (x + 120)
            let endY = y2 ?? y
            let minX = Swift.min(x, endX)
            let minY = Swift.min(y, endY)
            let maxX = Swift.max(x, endX)
            let maxY = Swift.max(y, endY)
            return CGRect(
                x: minX - 16,
                y: minY - 16,
                width: Swift.max(maxX - minX + 32, 32),
                height: Swift.max(maxY - minY + 32, 32)
            )
        case .text, .sticker:
            let w = Swift.max(width ?? Double(Swift.max((text ?? "").count * 12, 80)), 64)
            let h = Swift.max(height ?? 44, 36)
            return CGRect(x: x, y: y, width: w, height: h)
        }
    }

    /// Translates the shape in logical coordinates and clamps to the canvas.
    public func movedBy(dx: Double, dy: Double) -> TutorCanvasShape {
        var copy = self
        copy.x += dx
        copy.y += dy
        if let endX = copy.x2 { copy.x2 = endX + dx }
        if let endY = copy.y2 { copy.y2 = endY + dy }
        return copy.sanitized()
    }

    /// Clamps coordinates and repairs malformed AI-generated payloads so the view never overflows.
    public func sanitized() -> TutorCanvasShape {
        var s = self
        if s.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            s.id = UUID().uuidString
        }
        s.x = TutorCanvasSpace.clamp(s.x, min: 0, max: TutorCanvasSpace.width - 24)
        s.y = TutorCanvasSpace.clamp(s.y, min: 0, max: TutorCanvasSpace.height - 24)

        if let w = s.width {
            s.width = TutorCanvasSpace.clamp(w, min: 20, max: TutorCanvasSpace.width - s.x)
        }
        if let h = s.height {
            s.height = TutorCanvasSpace.clamp(h, min: 20, max: TutorCanvasSpace.height - s.y)
        }
        if let x2 = s.x2 {
            s.x2 = TutorCanvasSpace.clamp(x2, min: 0, max: TutorCanvasSpace.width)
        }
        if let y2 = s.y2 {
            s.y2 = TutorCanvasSpace.clamp(y2, min: 0, max: TutorCanvasSpace.height)
        }
        if var nl = s.numberLine {
            if nl.max <= nl.min {
                nl.max = nl.min + 10
            }
            nl.marks = nl.marks.filter { $0 >= nl.min && $0 <= nl.max }
            s.numberLine = nl
        }
        if var fb = s.fractionBar {
            fb.totalParts = Swift.min(Swift.max(fb.totalParts, 1), 12)
            fb.filledParts = Swift.min(Swift.max(fb.filledParts, 0), fb.totalParts)
            s.fractionBar = fb
        }
        return s
    }
}

// MARK: - TutorCanvas & Edit History

public struct TutorCanvas: Codable, Sendable, Equatable {
    public var title: String
    public var caption: String?
    public var showGrid: Bool
    public var shapes: [TutorCanvasShape]

    public init(
        title: String,
        caption: String? = nil,
        showGrid: Bool = true,
        shapes: [TutorCanvasShape] = []
    ) {
        self.title = title
        self.caption = caption
        self.showGrid = showGrid
        self.shapes = shapes.map { $0.sanitized() }
    }

    public func sanitized() -> TutorCanvas {
        TutorCanvas(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Interactive Chalkboard" : title,
            caption: caption,
            showGrid: showGrid,
            shapes: shapes.map { $0.sanitized() }
        )
    }
}

public struct TutorCanvasEditState: Sendable, Equatable {
    public var shapes: [TutorCanvasShape]
    public var strokes: [[CGPoint]]

    public init(shapes: [TutorCanvasShape] = [], strokes: [[CGPoint]] = []) {
        self.shapes = shapes
        self.strokes = strokes
    }
}

public struct TutorCanvasEditHistory: Sendable, Equatable {
    public static let maxUndoDepth = 30

    public private(set) var current: TutorCanvasEditState
    private var undoStack: [TutorCanvasEditState] = []
    private var redoStack: [TutorCanvasEditState] = []

    public init(initial: TutorCanvasEditState = TutorCanvasEditState()) {
        self.current = initial
    }

    public var canUndo: Bool { !undoStack.isEmpty }
    public var canRedo: Bool { !redoStack.isEmpty }

    public mutating func record(_ nextState: TutorCanvasEditState) {
        guard nextState != current else { return }
        undoStack.append(current)
        if undoStack.count > Self.maxUndoDepth {
            undoStack.removeFirst(undoStack.count - Self.maxUndoDepth)
        }
        current = nextState
        redoStack.removeAll()
    }

    public mutating func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(current)
        current = previous
    }

    public mutating func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(current)
        current = next
    }

    public mutating func reset(to state: TutorCanvasEditState) {
        current = state
        undoStack.removeAll()
        redoStack.removeAll()
    }
}

// MARK: - TutorCanvasAction & Incremental Applier

public enum TutorCanvasAction: String, Codable, Sendable, Equatable {
    case replace
    case add
    case update
    case remove
    case clear

    public static func parse(_ raw: String?) -> TutorCanvasAction {
        guard let cleaned = raw?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              let parsed = TutorCanvasAction(rawValue: cleaned) else {
            return .replace
        }
        return parsed
    }
}

public enum TutorCanvasActionApplier {
    public static func apply(
        action: TutorCanvasAction,
        incoming: TutorCanvas,
        removeIDs: [String] = [],
        to existing: TutorCanvas?
    ) -> TutorCanvas {
        let sanitizedIncoming = incoming.sanitized()
        guard var target = existing else {
            return action == .clear
                ? TutorCanvas(title: sanitizedIncoming.title, caption: nil, showGrid: sanitizedIncoming.showGrid, shapes: [])
                : sanitizedIncoming
        }

        if !sanitizedIncoming.title.isEmpty {
            target.title = sanitizedIncoming.title
        }
        if let caption = sanitizedIncoming.caption {
            target.caption = caption
        }
        target.showGrid = sanitizedIncoming.showGrid

        switch action {
        case .replace:
            return sanitizedIncoming
        case .clear:
            target.shapes.removeAll()
            return target
        case .add:
            for shape in sanitizedIncoming.shapes {
                if let idx = target.shapes.firstIndex(where: { $0.id == shape.id }) {
                    target.shapes[idx] = shape
                } else {
                    target.shapes.append(shape)
                }
            }
            return target
        case .update:
            for shape in sanitizedIncoming.shapes {
                if let idx = target.shapes.firstIndex(where: { $0.id == shape.id }) {
                    target.shapes[idx] = shape
                } else {
                    target.shapes.append(shape)
                }
            }
            return target
        case .remove:
            let idsToDelete = Set(removeIDs + sanitizedIncoming.shapes.map(\.id))
            target.shapes.removeAll { idsToDelete.contains($0.id) }
            return target
        }
    }
}
