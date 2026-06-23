import Foundation
import EMathicaMathCore

public struct GeometryInspectorPropertyRow: Equatable {
    public var label: String
    public var value: String
}

public enum GeometryInspectorPropertyPresenter {
    public static func rows(
        for object: MathObject,
        objects: [MathObject],
        geometryResolver: any GeometryPresentationResolverProtocol = DefaultGeometryPresentationResolver()
    ) -> [GeometryInspectorPropertyRow] {
        switch object.type {
        case .point:
            return pointRows(for: object, objects: objects, geometryResolver: geometryResolver)
        case .segment:
            return segmentRows(for: object, objects: objects, geometryResolver: geometryResolver)
        case .line:
            return lineRows(for: object, objects: objects, geometryResolver: geometryResolver)
        case .ray, .arc:
            return rayRows(for: object, objects: objects, geometryResolver: geometryResolver)
        case .circle:
            return circleRows(for: object, objects: objects, geometryResolver: geometryResolver)
        case .function, .parameter, .parameterGroup, .arc:
            return []
        }
    }

    private static func pointRows(
        for object: MathObject,
        objects: [MathObject],
        geometryResolver: any GeometryPresentationResolverProtocol
    ) -> [GeometryInspectorPropertyRow] {
        var rows: [GeometryInspectorPropertyRow] = []
        if let kind = dependencyKindText(for: object) {
            rows.append(.init(label: "构造关系", value: kind))
        }
        let nonDefined = nonDefinedStatusRow(for: object)
        if let source = GeometryDependencyPresentation.sourceText(for: object, objects: objects) {
            rows.append(.init(label: "来源对象", value: source))
        }
        if case .intersectionOf(_, _, let index)? = object.geometryDependency?.kind {
            rows.append(.init(label: "交点序号", value: "\(index + 1)"))
        }
        if let nonDefined {
            rows.append(nonDefined)
            return rows
        }
        guard let position = geometryResolver.pointPosition(for: object) else {
            return rows
        }
        rows.append(.init(label: "坐标", value: GeometryPropertyFormatter.coordinate(position)))
        return rows
    }

    private static func segmentRows(
        for object: MathObject,
        objects: [MathObject],
        geometryResolver: any GeometryPresentationResolverProtocol
    ) -> [GeometryInspectorPropertyRow] {
        var rows: [GeometryInspectorPropertyRow] = []
        if let kind = dependencyKindText(for: object) {
            rows.append(.init(label: "构造关系", value: kind))
        }
        if let source = GeometryDependencyPresentation.sourceText(for: object, objects: objects) {
            rows.append(.init(label: "来源对象", value: source))
        }
        if let nonDefined = nonDefinedStatusRow(for: object) {
            rows.append(nonDefined)
            return rows
        }
        guard let endpoints = geometryResolver.segmentEndpoints(for: object, in: objects) else {
            return rows
        }
        let pointA = endpointLabel(for: object, anchorIndex: 0, fallback: endpoints.0, objects: objects, geometryResolver: geometryResolver)
        let pointB = endpointLabel(for: object, anchorIndex: 1, fallback: endpoints.1, objects: objects, geometryResolver: geometryResolver)
        rows.append(.init(label: "端点 A", value: pointA))
        rows.append(.init(label: "端点 B", value: pointB))

        let dx = endpoints.1.x - endpoints.0.x
        let dy = endpoints.1.y - endpoints.0.y
        let length = (dx * dx + dy * dy).squareRoot()
        if length.isFinite {
            rows.append(.init(label: "长度", value: GeometryPropertyFormatter.length(length)))
        }
        if dx.isFinite, dy.isFinite, !(dx == 0 && dy == 0) {
            rows.append(.init(label: "方向角", value: GeometryPropertyFormatter.angleRadians(atan2(dy, dx))))
        }
        return rows
    }

    private static func lineRows(
        for object: MathObject,
        objects: [MathObject],
        geometryResolver: any GeometryPresentationResolverProtocol
    ) -> [GeometryInspectorPropertyRow] {
        var rows: [GeometryInspectorPropertyRow] = []
        if let kind = dependencyKindText(for: object) {
            rows.append(.init(label: "构造关系", value: kind))
        }
        if let source = GeometryDependencyPresentation.sourceText(for: object, objects: objects) {
            rows.append(.init(label: "来源对象", value: source))
        }
        if let nonDefined = nonDefinedStatusRow(for: object) {
            rows.append(nonDefined)
            return rows
        }
        guard let points = geometryResolver.linePoints(for: object, in: objects) else {
            return rows
        }
        rows.append(.init(label: "过点", value: endpointLabel(for: object, anchorIndex: 0, fallback: points.0, objects: objects, geometryResolver: geometryResolver)))
        appendVectorRows(start: points.0, end: points.1, to: &rows)
        return rows
    }

    private static func rayRows(
        for object: MathObject,
        objects: [MathObject],
        geometryResolver: any GeometryPresentationResolverProtocol
    ) -> [GeometryInspectorPropertyRow] {
        var rows: [GeometryInspectorPropertyRow] = []
        if let kind = dependencyKindText(for: object) {
            rows.append(.init(label: "构造关系", value: kind))
        }
        if let source = GeometryDependencyPresentation.sourceText(for: object, objects: objects) {
            rows.append(.init(label: "来源对象", value: source))
        }
        if let nonDefined = nonDefinedStatusRow(for: object) {
            rows.append(nonDefined)
            return rows
        }
        guard let points = geometryResolver.rayPoints(for: object, in: objects) else {
            return rows
        }
        rows.append(.init(label: "起点", value: endpointLabel(for: object, anchorIndex: 0, fallback: points.0, objects: objects, geometryResolver: geometryResolver)))
        appendVectorRows(start: points.0, end: points.1, includeSlope: false, to: &rows)
        return rows
    }

    private static func circleRows(
        for object: MathObject,
        objects: [MathObject],
        geometryResolver: any GeometryPresentationResolverProtocol
    ) -> [GeometryInspectorPropertyRow] {
        var rows: [GeometryInspectorPropertyRow] = []
        if let kind = dependencyKindText(for: object) {
            rows.append(.init(label: "构造关系", value: kind))
        }
        if let source = GeometryDependencyPresentation.sourceText(for: object, objects: objects) {
            rows.append(.init(label: "来源对象", value: source))
        }
        if let nonDefined = nonDefinedStatusRow(for: object) {
            rows.append(nonDefined)
            return rows
        }
        guard let circle = geometryResolver.circleGeometry(for: object, in: objects) else {
            return rows
        }

        let center = centerLabel(for: object, fallback: circle.center, objects: objects, geometryResolver: geometryResolver)
        rows.append(.init(label: "圆心", value: center))
        rows.append(.init(label: "半径", value: GeometryPropertyFormatter.radius(circle.radius)))
        rows.append(.init(label: "直径", value: GeometryPropertyFormatter.diameter(circle.radius * 2)))
        return rows
    }

    private static func appendVectorRows(
        start: WorldPoint,
        end: WorldPoint,
        includeSlope: Bool = true,
        to rows: inout [GeometryInspectorPropertyRow]
    ) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        guard dx.isFinite, dy.isFinite, !(dx == 0 && dy == 0) else { return }
        rows.append(.init(label: "方向向量", value: GeometryPropertyFormatter.vector(dx: dx, dy: dy)))
        if includeSlope {
            rows.append(.init(label: "斜率", value: GeometryPropertyFormatter.slope(dx: dx, dy: dy)))
        }
        rows.append(.init(label: "方向角", value: GeometryPropertyFormatter.angleRadians(atan2(dy, dx))))
    }

    private static func endpointLabel(
        for object: MathObject,
        anchorIndex: Int,
        fallback: WorldPoint,
        objects: [MathObject],
        geometryResolver: any GeometryPresentationResolverProtocol
    ) -> String {
        guard let definition = object.geometryDefinition,
              definition.anchors.indices.contains(anchorIndex) else {
            return pointText(fallback)
        }
        let anchor = definition.anchors[anchorIndex]
        guard anchor.kind == .object,
              let id = anchor.objectID,
              let referenced = objects.first(where: { $0.id == id }) else {
            return pointText(fallback)
        }
        if let position = geometryResolver.pointPosition(for: referenced) {
            return "\(referenced.name) \(pointText(position))"
        }
        return referenced.name
    }

    private static func centerLabel(
        for object: MathObject,
        fallback: WorldPoint,
        objects: [MathObject],
        geometryResolver: any GeometryPresentationResolverProtocol
    ) -> String {
        guard let definition = object.geometryDefinition,
              definition.anchors.indices.contains(0) else {
            return pointText(fallback)
        }
        let anchor = definition.anchors[0]
        guard anchor.kind == .object,
              let id = anchor.objectID,
              let centerObject = objects.first(where: { $0.id == id }) else {
            return pointText(fallback)
        }
        if let position = geometryResolver.pointPosition(for: centerObject) {
            return "\(centerObject.name) \(pointText(position))"
        }
        return centerObject.name
    }

    private static func nonDefinedStatusRow(for object: MathObject) -> GeometryInspectorPropertyRow? {
        guard let status = GeometryDependencyPresentation.statusText(for: object) else {
            return nil
        }
        let displayStatus = status.replacingOccurrences(of: "状态：", with: "")
        return GeometryInspectorPropertyRow(label: "定义状态", value: displayStatus)
    }

    private static func dependencyKindText(for object: MathObject) -> String? {
        guard let kind = object.geometryDependency?.kind else {
            return nil
        }
        switch kind {
        case .midpointOfPoints:
            return "中点"
        case .parallelLine:
            return "平行线"
        case .perpendicularLine:
            return "垂线"
        case .intersectionOf:
            return "交点"
        case .circleByCenterPoint:
            return "动态圆"
        case .circleByCenterRadius:
            return "固定半径圆"
        case .arcByThreePoints:
            return "三点圆弧"
        }
    }

    private static func pointText(_ point: WorldPoint) -> String {
        GeometryPropertyFormatter.coordinate(point)
    }
}
