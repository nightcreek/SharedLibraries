import EMathicaMathCore
import Foundation

public enum GeometryDependencyPresentation {
    public static func objectTypeFallbackLabel(for object: MathObject) -> String {
        guard let kind = object.geometryDefinition?.kind else {
            return object.type.rawValue
        }
        switch kind {
        case .point3D:
            return "空间点"
        case .segment3D:
            return "空间线段"
        case .line3D:
            return "空间直线"
        case .plane3D:
            return "空间平面"
        case .point, .segment, .line, .ray, .circle, .arc:
            return object.type.rawValue
        }
    }

    public static func secondaryLines(
        for object: MathObject,
        objects: [MathObject],
        simplifiedText: String?,
        metadataText: String?,
        typeFallback: String,
        geometryResolver: any GeometryPresentationResolverProtocol = DefaultGeometryPresentationResolver()
    ) -> [String] {
        let source = sourceText(for: object, objects: objects)
        let status = statusText(for: object)
        let property = geometryPropertyText(for: object, objects: objects, geometryResolver: geometryResolver)
        let normalizedSimplified = normalizedSimplifiedText(simplifiedText)
        let normalizedMetadata = normalizedMetadataText(metadataText)

        // Derived geometry rows prioritize relation + status readability.
        if object.geometryDependency != nil {
            var lines: [String] = []
            if let source {
                lines.append(source)
            }
            if let status {
                lines.append(status)
                // Keep status stable/visible; only allow optional simplified detail as a third line.
                if let normalizedSimplified {
                    lines.append("化简：\(normalizedSimplified)")
                }
                return lines
            }

            // Defined derived object: relation first, then optional detail.
            if let normalizedSimplified {
                lines.append("化简：\(normalizedSimplified)")
                return lines
            }
            if let property {
                lines.append(property)
                return lines
            }
            if let normalizedMetadata {
                lines.append(normalizedMetadata)
                return lines
            }
            if lines.isEmpty {
                lines.append(typeFallback)
            }
            return lines
        }

        // Non-derived objects keep previous behavior.
        if let normalizedSimplified {
            return ["化简：\(normalizedSimplified)"]
        }
        if let normalizedMetadata {
            return [normalizedMetadata]
        }
        if let property {
            return [property]
        }
        return [typeFallback]
    }

    public static func secondaryText(
        for object: MathObject,
        objects: [MathObject],
        simplifiedText: String?,
        metadataText: String?,
        typeFallback: String,
        geometryResolver: any GeometryPresentationResolverProtocol = DefaultGeometryPresentationResolver()
    ) -> String {
        secondaryLines(
            for: object,
            objects: objects,
            simplifiedText: simplifiedText,
            metadataText: metadataText,
            typeFallback: typeFallback,
            geometryResolver: geometryResolver
        ).joined(separator: "\n")
    }

    public static func sourceText(for object: MathObject, objects: [MathObject]) -> String? {
        guard let dependency = object.geometryDependency else { return nil }
        let objectsByID = Dictionary(uniqueKeysWithValues: objects.map { ($0.id, $0) })

        func objectName(_ id: UUID, fallback: String) -> String {
            objectsByID[id]?.name ?? fallback
        }

        switch dependency.kind {
        case .midpointOfPoints(let pointAID, let pointBID):
            return "中点：\(objectName(pointAID, fallback: "A"))，\(objectName(pointBID, fallback: "B"))"
        case .parallelLine(let referenceObjectID, let throughPointID):
            return "平行：过 \(objectName(throughPointID, fallback: "P"))，参考 \(objectName(referenceObjectID, fallback: "l"))"
        case .perpendicularLine(let referenceObjectID, let throughPointID):
            return "垂线：过 \(objectName(throughPointID, fallback: "P"))，参考 \(objectName(referenceObjectID, fallback: "l"))"
        case .intersectionOf(let objectAID, let objectBID, _):
            return "交点：\(objectName(objectAID, fallback: "A")) × \(objectName(objectBID, fallback: "B"))"
        case .circleByCenterPoint(let centerPointID, let throughPointID):
            return "圆：圆心 \(objectName(centerPointID, fallback: "A"))，过 \(objectName(throughPointID, fallback: "B"))"
        case .circleByCenterRadius(let centerPointID, let radius):
            return "圆：圆心 \(objectName(centerPointID, fallback: "A"))，半径 \(GeometryPropertyFormatter.radius(radius))"
        case .arcByThreePoints(let pointAID, let pointBID, let pointCID):
            return "圆弧：过 \(objectName(pointAID, fallback: "A")) → \(objectName(pointBID, fallback: "B")) → \(objectName(pointCID, fallback: "C"))"
        }
    }

    public static func statusText(for object: MathObject) -> String? {
        guard let status = object.geometryDefinitionStatus, status != .defined else {
            return nil
        }
        switch status {
        case .defined:
            return nil
        case .noSolution:
            return "状态：当前无交点"
        case .missingSource:
            return "状态：源对象缺失"
        case .unsupported:
            return "状态：当前关系暂不支持"
        case .invalid:
            return "状态：未定义"
        }
    }

    public static func geometryPropertyText(
        for object: MathObject,
        objects: [MathObject],
        geometryResolver: any GeometryPresentationResolverProtocol = DefaultGeometryPresentationResolver()
    ) -> String? {
        if let status = object.geometryDefinitionStatus, status != .defined {
            return nil
        }

        switch object.type {
        case .segment:
            guard let endpoints = geometryResolver.segmentEndpoints(for: object, in: objects) else {
                return nil
            }
            let dx = endpoints.1.x - endpoints.0.x
            let dy = endpoints.1.y - endpoints.0.y
            let length = (dx * dx + dy * dy).squareRoot()
            guard length.isFinite else { return nil }
            return "长度 \(GeometryPropertyFormatter.length(length))"
        case .circle:
            guard let circle = geometryResolver.circleGeometry(for: object, in: objects),
                  circle.radius.isFinite else {
                return nil
            }
            return "半径 \(GeometryPropertyFormatter.radius(circle.radius))"
        case .point, .line, .ray, .function, .parameter, .parameterGroup, .arc:
            return nil
        }
    }

    private static func normalizedSimplifiedText(_ text: String?) -> String? {
        guard let text else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func normalizedMetadataText(_ text: String?) -> String? {
        guard let text else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
