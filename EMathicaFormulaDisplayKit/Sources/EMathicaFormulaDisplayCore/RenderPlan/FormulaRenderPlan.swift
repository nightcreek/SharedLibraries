import Foundation

public enum FormulaHitRegionKind: Equatable, Sendable {
    case node
    case cursor
    case placeholder
    case text
    case structure
}

public struct FormulaHitRegion: Equatable, Sendable {
    public var id: FormulaLayoutID
    public var frame: FormulaRect
    public var kind: FormulaHitRegionKind

    public init(id: FormulaLayoutID, frame: FormulaRect, kind: FormulaHitRegionKind) {
        self.id = id
        self.frame = frame
        self.kind = kind
    }
}

public struct FormulaRenderPlan: Equatable, Sendable {
    public var size: FormulaSize
    public var baseline: Double
    public var elements: [FormulaRenderElement]
    public var bounds: FormulaRect
    public var cursorRects: [FormulaRect]
    public var placeholderRects: [FormulaRect]
    public var hitRegions: [FormulaHitRegion]
    public var debugFrames: [FormulaRect]
    public var rootNode: FormulaDisplayNode
    public var rootLayoutBox: FormulaLayoutBox?

    public init(
        size: FormulaSize,
        baseline: Double,
        elements: [FormulaRenderElement],
        bounds: FormulaRect,
        cursorRects: [FormulaRect],
        placeholderRects: [FormulaRect],
        hitRegions: [FormulaHitRegion],
        debugFrames: [FormulaRect] = [],
        rootNode: FormulaDisplayNode,
        rootLayoutBox: FormulaLayoutBox? = nil
    ) {
        self.size = size
        self.baseline = baseline
        self.elements = elements
        self.bounds = bounds
        self.cursorRects = cursorRects
        self.placeholderRects = placeholderRects
        self.hitRegions = hitRegions
        self.debugFrames = debugFrames
        self.rootNode = rootNode
        self.rootLayoutBox = rootLayoutBox
    }
}
