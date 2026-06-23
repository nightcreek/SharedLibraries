import Foundation

public enum GeometryKind: String, Codable, Equatable, Hashable, Sendable {
    case point
    case segment
    case line
    case ray
    case circle
    case arc
    case point3D
    case segment3D
    case line3D
    case plane3D
}

public struct GeometryAnchor: Codable, Equatable, Hashable, Sendable {
    public enum Kind: String, Codable, Hashable, Sendable {
        case object
        case fixedPoint
    }

    public var kind: Kind
    public var objectID: UUID?
    public var point: WorldPoint?

    public static func object(_ id: UUID) -> GeometryAnchor {
        GeometryAnchor(kind: .object, objectID: id, point: nil)
    }

    public static func fixedPoint(_ point: WorldPoint) -> GeometryAnchor {
        GeometryAnchor(kind: .fixedPoint, objectID: nil, point: point)
    }
}

public struct GeometryDefinition: Codable, Equatable, Hashable, Sendable {
    public var kind: GeometryKind
    public var anchors: [GeometryAnchor]
    public var point3D: WorldPoint3D?
    public var pointB3D: WorldPoint3D?
    public var vector3D: Vector3D?

    public init(
        kind: GeometryKind,
        anchors: [GeometryAnchor] = [],
        point3D: WorldPoint3D? = nil,
        pointB3D: WorldPoint3D? = nil,
        vector3D: Vector3D? = nil
    ) {
        self.kind = kind
        self.anchors = anchors
        self.point3D = point3D
        self.pointB3D = pointB3D
        self.vector3D = vector3D
    }
}
