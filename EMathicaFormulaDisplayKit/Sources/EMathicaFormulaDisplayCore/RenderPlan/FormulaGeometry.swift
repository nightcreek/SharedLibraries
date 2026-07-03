import Foundation

public struct FormulaPoint: Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public static let zero = FormulaPoint(x: 0, y: 0)
}

public struct FormulaSize: Equatable, Sendable {
    public var width: Double
    public var height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }

    public static let zero = FormulaSize(width: 0, height: 0)
}

public struct FormulaRect: Equatable, Sendable {
    public var origin: FormulaPoint
    public var size: FormulaSize

    public init(origin: FormulaPoint, size: FormulaSize) {
        self.origin = origin
        self.size = size
    }

    public var minX: Double { origin.x }
    public var minY: Double { origin.y }
    public var maxX: Double { origin.x + size.width }
    public var maxY: Double { origin.y + size.height }

    public func offsetBy(dx: Double, dy: Double) -> FormulaRect {
        FormulaRect(
            origin: .init(x: origin.x + dx, y: origin.y + dy),
            size: size
        )
    }

    public static let zero = FormulaRect(origin: .zero, size: .zero)
}
