import Foundation
import CoreGraphics

public struct CoordinateTransform {
    public let viewport: Viewport
    public let canvasSize: CGSize

    public func worldToScreen(_ world: WorldPoint) -> CGPoint {
        let center = canvasSize.center
        let dx = (world.x - viewport.centerWorld.x) * viewport.pointsPerUnit
        let dy = (world.y - viewport.centerWorld.y) * viewport.pointsPerUnit
        return CGPoint(x: center.x + dx, y: center.y - dy)
    }

    public func screenToWorld(_ screen: CGPoint) -> WorldPoint {
        let center = canvasSize.center
        let dx = (Double(screen.x - center.x) / viewport.pointsPerUnit)
        let dy = (Double(center.y - screen.y) / viewport.pointsPerUnit)
        return WorldPoint(x: viewport.centerWorld.x + dx, y: viewport.centerWorld.y + dy)
    }

    public func visibleWorldRect() -> WorldRect {
        let halfWidth = Double(canvasSize.width) * 0.5 / viewport.pointsPerUnit
        let halfHeight = Double(canvasSize.height) * 0.5 / viewport.pointsPerUnit
        return WorldRect(
            minX: viewport.centerWorld.x - halfWidth,
            minY: viewport.centerWorld.y - halfHeight,
            maxX: viewport.centerWorld.x + halfWidth,
            maxY: viewport.centerWorld.y + halfHeight
        )
    }
}
