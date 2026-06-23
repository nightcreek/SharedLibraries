import Foundation

public struct Viewport: Hashable, Codable {
    public var centerWorld: WorldPoint
    public var pointsPerUnit: Double

    public init(centerWorld: WorldPoint = .zero, pointsPerUnit: Double = 80) {
        self.centerWorld = centerWorld
        self.pointsPerUnit = pointsPerUnit
    }
}
