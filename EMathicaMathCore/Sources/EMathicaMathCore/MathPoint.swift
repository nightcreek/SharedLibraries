import Foundation

public struct MathPoint: Hashable, Codable {
    public init(x: Double = 0, y: Double = 0) { self.x = x; self.y = y }
    public var x: Double
    public var y: Double

}
