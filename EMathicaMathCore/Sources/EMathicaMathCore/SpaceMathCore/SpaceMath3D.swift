import Foundation

public struct WorldPoint3D: Codable, Hashable, Sendable {
    public var x: Double
    public var y: Double
    public var z: Double
    public init(x: Double = 0, y: Double = 0, z: Double = 0) { self.x = x; self.y = y; self.z = z }

    public static let zero = WorldPoint3D(x: 0, y: 0, z: 0)

    public func distance(to other: WorldPoint3D) -> Double {
        (self - other).length
    }
}

public struct Vector3D: Codable, Hashable, Sendable {
    public var x: Double
    public var y: Double
    public var z: Double
    public init(x: Double = 0, y: Double = 0, z: Double = 0) { self.x = x; self.y = y; self.z = z }

    public static let zero = Vector3D(x: 0, y: 0, z: 0)
    public static let worldUp = Vector3D(x: 0, y: 1, z: 0)
    public static let worldForward = Vector3D(x: 0, y: 0, z: -1)

    public var lengthSquared: Double {
        x * x + y * y + z * z
    }

    public var length: Double {
        sqrt(lengthSquared)
    }

    public func dot(_ rhs: Vector3D) -> Double {
        x * rhs.x + y * rhs.y + z * rhs.z
    }

    public func cross(_ rhs: Vector3D) -> Vector3D {
        Vector3D(
            x: y * rhs.z - z * rhs.y,
            y: z * rhs.x - x * rhs.z,
            z: x * rhs.y - y * rhs.x
        )
    }

    public func normalized(epsilon: Double = 1e-9) -> Vector3D {
        let len = length
        guard len > epsilon, len.isFinite else { return .zero }
        return self / len
    }
}

public enum SpaceProjectionType: String, Codable, Hashable, Sendable {
    case orthographic
    case perspective
}

public struct SpaceViewportSize: Codable, Hashable, Sendable {
    public init(width: Double = 0, height: Double = 0) { self.width = width; self.height = height }
    public var width: Double
    public var height: Double

    public static let zero = SpaceViewportSize(width: 0, height: 0)
}

public struct ProjectedPoint2D: Hashable, Sendable {
    public var x: Double
    public var y: Double
    public var depth: Double
    public var isVisible: Bool
}

public struct SpaceCameraState: Codable, Hashable, Sendable {
    public var target: WorldPoint3D
    public var distance: Double
    public var yaw: Double
    public var pitch: Double
    public var projection: SpaceProjectionType
    public var fovDegrees: Double

    public static let minDistance: Double = 0.1
    public static let maxDistance: Double = 10_000
    // Keep away from poles to avoid unstable feel near extreme orbit angles.
    public static let minPitch: Double = -(85.0 * .pi / 180.0)
    public static let maxPitch: Double = 85.0 * .pi / 180.0

    public static let `default` = SpaceCameraState(
        target: .zero,
        distance: 10,
        yaw: -.pi / 4,
        pitch: .pi / 8,
        projection: .perspective,
        fovDegrees: 60
    )

    public var clampedDistance: Double {
        guard distance.isFinite else { return 10 }
        return min(Self.maxDistance, max(Self.minDistance, distance))
    }

    public var clampedPitch: Double {
        guard pitch.isFinite else { return 0 }
        return min(Self.maxPitch, max(Self.minPitch, pitch))
    }

    public var clampedFovDegrees: Double {
        guard fovDegrees.isFinite else { return 60 }
        return min(170, max(10, fovDegrees))
    }

    public var position: WorldPoint3D {
        let d = clampedDistance
        let p = clampedPitch
        let cosPitch = cos(p)
        return WorldPoint3D(
            x: target.x + d * cosPitch * cos(yaw),
            y: target.y + d * sin(p),
            z: target.z + d * cosPitch * sin(yaw)
        )
    }

    public var forward: Vector3D {
        (target - position).normalized()
    }

    public var right: Vector3D {
        let f = forward
        let baseUp = abs(f.dot(.worldUp)) > 0.999 ? Vector3D(x: 0, y: 0, z: 1) : .worldUp
        return f.cross(baseUp).normalized()
    }

    public var up: Vector3D {
        right.cross(forward).normalized()
    }

    public func orbit(deltaYaw: Double, deltaPitch: Double) -> SpaceCameraState {
        var next = self
        next.yaw += deltaYaw
        next.pitch = min(Self.maxPitch, max(Self.minPitch, pitch + deltaPitch))
        return next
    }

    public func zoom(delta: Double) -> SpaceCameraState {
        var next = self
        next.distance = min(Self.maxDistance, max(Self.minDistance, distance + delta))
        return next
    }

    public func pan(deltaX: Double, deltaY: Double) -> SpaceCameraState {
        var next = self
        let shift = right * deltaX + up * deltaY
        next.target = target + shift
        return next
    }

    public func project(
        _ point: WorldPoint3D,
        viewportSize: SpaceViewportSize,
        orthographicPointsPerUnit: Double = 60
    ) -> ProjectedPoint2D {
        let rel = point - position
        let cx = rel.dot(right)
        let cy = rel.dot(up)
        let cz = rel.dot(forward)
        let centerX = viewportSize.width * 0.5
        let centerY = viewportSize.height * 0.5

        switch projection {
        case .orthographic:
            let s = orthographicPointsPerUnit.isFinite && orthographicPointsPerUnit > 0 ? orthographicPointsPerUnit : 60
            return ProjectedPoint2D(
                x: centerX + cx * s,
                y: centerY - cy * s,
                depth: cz,
                isVisible: true
            )
        case .perspective:
            let nearEpsilon = 1e-6
            guard cz > nearEpsilon else {
                return ProjectedPoint2D(x: 0, y: 0, depth: cz, isVisible: false)
            }
            let fovRadians = clampedFovDegrees * .pi / 180
            let focal = (viewportSize.height * 0.5) / tan(fovRadians * 0.5)
            return ProjectedPoint2D(
                x: centerX + (cx / cz) * focal,
                y: centerY - (cy / cz) * focal,
                depth: cz,
                isVisible: true
            )
        }
    }
}

public extension Vector3D {
    public static func + (lhs: Vector3D, rhs: Vector3D) -> Vector3D {
        Vector3D(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }

    public static func - (lhs: Vector3D, rhs: Vector3D) -> Vector3D {
        Vector3D(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }

    static prefix func - (v: Vector3D) -> Vector3D {
        Vector3D(x: -v.x, y: -v.y, z: -v.z)
    }

    public static func * (lhs: Vector3D, rhs: Double) -> Vector3D {
        Vector3D(x: lhs.x * rhs, y: lhs.y * rhs, z: lhs.z * rhs)
    }

    public static func * (lhs: Double, rhs: Vector3D) -> Vector3D {
        rhs * lhs
    }

    public static func / (lhs: Vector3D, rhs: Double) -> Vector3D {
        guard rhs != 0 else { return .zero }
        return Vector3D(x: lhs.x / rhs, y: lhs.y / rhs, z: lhs.z / rhs)
    }
}

public extension WorldPoint3D {
    public static func + (lhs: WorldPoint3D, rhs: Vector3D) -> WorldPoint3D {
        WorldPoint3D(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }

    public static func - (lhs: WorldPoint3D, rhs: WorldPoint3D) -> Vector3D {
        Vector3D(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }
}

// MARK: - SpaceWorkPlane

/// The active coordinate plane for 3D workspace construction and viewing.
public enum SpaceWorkPlane: String, CaseIterable, Hashable, Codable, Sendable {
    case xy
    case yz
    case zx

    public var label: String {
        switch self {
        case .xy: return "XY"
        case .yz: return "YZ"
        case .zx: return "ZX"
        }
    }
}
