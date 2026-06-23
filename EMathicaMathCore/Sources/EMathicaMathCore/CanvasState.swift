import Foundation
import CoreGraphics

public struct GraphCamera: Hashable, Codable, Sendable {
    public var center: SIMD2<Double>
    public var pointsPerUnit: Double

    public init(center: SIMD2<Double> = .zero, pointsPerUnit: Double = 80) {
        self.center = center
        self.pointsPerUnit = pointsPerUnit
    }

    public func mathToScreen(_ p: SIMD2<Double>, in size: CGSize) -> CGPoint {
        let cx = Double(size.width) * 0.5
        let cy = Double(size.height) * 0.5
        let x = cx + (p.x - center.x) * pointsPerUnit
        let y = cy - (p.y - center.y) * pointsPerUnit
        return CGPoint(x: x, y: y)
    }

    public func screenToMath(_ p: CGPoint, in size: CGSize) -> SIMD2<Double> {
        let cx = Double(size.width) * 0.5
        let cy = Double(size.height) * 0.5
        let mx = center.x + (Double(p.x) - cx) / pointsPerUnit
        let my = center.y + (cy - Double(p.y)) / pointsPerUnit
        return SIMD2<Double>(mx, my)
    }

    public func visibleMathRect(in size: CGSize) -> WorldRect {
        let halfW = Double(size.width) * 0.5 / pointsPerUnit
        let halfH = Double(size.height) * 0.5 / pointsPerUnit
        return WorldRect(
            minX: center.x - halfW,
            minY: center.y - halfH,
            maxX: center.x + halfW,
            maxY: center.y + halfH
        )
    }
}

public struct CanvasState: Hashable, Codable, Sendable {
    public init(origin: CGPoint = .zero, scale: Double = 60, showGrid: Bool = true, showAxis: Bool = true, minScale: Double = 0.000001, maxScale: Double = 1_000_000_000) { self.origin = origin; self.scale = scale; self.showGrid = showGrid; self.showAxis = showAxis; self.minScale = minScale; self.maxScale = maxScale }
    public var origin: CGPoint
    public var scale: Double
    public var showGrid: Bool
    public var showAxis: Bool
    public var minScale: Double
    public var maxScale: Double

    public static let `default` = CanvasState(
        origin: .zero,
        scale: 60,
        showGrid: true,
        showAxis: true,
        minScale: 0.000001,
        maxScale: 1_000_000_000
    )

    public var camera: GraphCamera {
        get {
            let safeScale = scale.isFinite && scale > 0 ? scale : 60
            let center = SIMD2<Double>(
                x: -Double(origin.x) / safeScale,
                y: Double(origin.y) / safeScale
            )
            return GraphCamera(center: center, pointsPerUnit: safeScale)
        }
        set {
            let safeScale = Self.clampScale(newValue.pointsPerUnit, min: minScale, max: maxScale)
            scale = safeScale
            origin = CGPoint(
                x: -newValue.center.x * safeScale,
                y: newValue.center.y * safeScale
            )
        }
    }

    public func visibleWorldRect(in size: CGSize) -> WorldRect {
        camera.visibleMathRect(in: size)
    }

    public static func clampScale(_ value: Double, min: Double, max: Double) -> Double {
        guard value.isFinite else { return Swift.max(min, Swift.min(max, 60)) }
        return Swift.max(min, Swift.min(max, value))
    }
}
