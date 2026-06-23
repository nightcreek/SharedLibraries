import Foundation
import EMathicaMathCore

public protocol GeometryPresentationResolverProtocol {
    func pointPosition(for object: MathObject) -> WorldPoint?
    func segmentEndpoints(for object: MathObject, in objects: [MathObject]) -> (WorldPoint, WorldPoint)?
    func linePoints(for object: MathObject, in objects: [MathObject]) -> (WorldPoint, WorldPoint)?
    func rayPoints(for object: MathObject, in objects: [MathObject]) -> (WorldPoint, WorldPoint)?
    func circleGeometry(for object: MathObject, in objects: [MathObject]) -> (center: WorldPoint, radius: Double)?
}

/// Default geometry presentation resolver used by `EMathicaWorkspaceKit` when a
/// module does not provide a richer implementation.
///
/// Plane-specific resolution still lives in the Plane module; WorkspaceKit only
/// owns the protocol boundary and a no-op fallback.
public struct DefaultGeometryPresentationResolver: GeometryPresentationResolverProtocol {
    public init() {}

    public func pointPosition(for object: MathObject) -> WorldPoint? { nil }

    public func segmentEndpoints(for object: MathObject, in objects: [MathObject]) -> (WorldPoint, WorldPoint)? { nil }

    public func linePoints(for object: MathObject, in objects: [MathObject]) -> (WorldPoint, WorldPoint)? { nil }

    public func rayPoints(for object: MathObject, in objects: [MathObject]) -> (WorldPoint, WorldPoint)? { nil }

    public func circleGeometry(for object: MathObject, in objects: [MathObject]) -> (center: WorldPoint, radius: Double)? { nil }
}
