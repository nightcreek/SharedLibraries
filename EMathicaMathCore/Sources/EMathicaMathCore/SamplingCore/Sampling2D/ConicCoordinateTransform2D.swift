import Foundation

public struct ConicCoordinateTransform2D: Equatable, Sendable {
    public var centerX: Double
    public var centerY: Double
    public var rotationAngle: Double

    public init(centerX: Double, centerY: Double, rotationAngle: Double) {
        self.centerX = centerX
        self.centerY = centerY
        self.rotationAngle = rotationAngle
    }

    public func transformLocalToWorld(_ point: SamplePoint2D) -> SamplePoint2D {
        let cosTheta = Foundation.cos(rotationAngle)
        let sinTheta = Foundation.sin(rotationAngle)
        let xWorld = centerX + cosTheta * point.x - sinTheta * point.y
        let yWorld = centerY + sinTheta * point.x + cosTheta * point.y
        return SamplePoint2D(x: xWorld, y: yWorld)
    }
}
