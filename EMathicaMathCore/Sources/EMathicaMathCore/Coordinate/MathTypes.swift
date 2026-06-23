import Foundation
import CoreGraphics

public struct WorldPoint: Hashable, Codable, Sendable {
    public init(x: Double = 0, y: Double = 0) { self.x = x; self.y = y }
    public var x: Double
    public var y: Double

    public static let zero = WorldPoint(x: 0, y: 0)
}

public struct WorldVector: Hashable, Codable, Sendable {
    public init(dx: Double = 0, dy: Double = 0) { self.dx = dx; self.dy = dy }
    public var dx: Double
    public var dy: Double
}

public struct WorldRect: Hashable, Codable, Sendable {
    public init(minX: Double = 0, minY: Double = 0, maxX: Double = 0, maxY: Double = 0) { self.minX = minX; self.minY = minY; self.maxX = maxX; self.maxY = maxY }
    public var minX: Double
    public var minY: Double
    public var maxX: Double
    public var maxY: Double

    public var width: Double { maxX - minX }
    public var height: Double { maxY - minY }

    public func contains(_ other: WorldRect) -> Bool {
        other.minX >= minX && other.maxX <= maxX && other.minY >= minY && other.maxY <= maxY
    }

    public func expanded(by factor: Double) -> WorldRect {
        let centerX = (minX + maxX) * 0.5
        let centerY = (minY + maxY) * 0.5
        let halfWidth = width * 0.5 * factor
        let halfHeight = height * 0.5 * factor
        return WorldRect(
            minX: centerX - halfWidth,
            minY: centerY - halfHeight,
            maxX: centerX + halfWidth,
            maxY: centerY + halfHeight
        )
    }
}

public extension WorldPoint {
    public static func + (lhs: WorldPoint, rhs: WorldVector) -> WorldPoint {
        WorldPoint(x: lhs.x + rhs.dx, y: lhs.y + rhs.dy)
    }

    public static func - (lhs: WorldPoint, rhs: WorldPoint) -> WorldVector {
        WorldVector(dx: lhs.x - rhs.x, dy: lhs.y - rhs.y)
    }
}

public extension CGSize {
    public var center: CGPoint {
        CGPoint(x: width * 0.5, y: height * 0.5)
    }
}

/// A connected sequence of 2D points forming a plot segment (e.g., one branch of a curve).
public struct PlotSegment: Hashable, Sendable {
    public var points: [WorldPoint]
    public init(points: [WorldPoint] = []) { self.points = points }
}
