import Foundation
import EMathicaMathCore

public enum SpaceGeometryInspectorPropertyPresenter {
    public static func rows(for object: MathObject) -> [GeometryInspectorPropertyRow] {
        guard let definition = object.geometryDefinition else { return [] }

        switch definition.kind {
        case .point3D:
            guard let point = definition.point3D else { return [] }
            return [
                .init(label: "对象类型", value: "空间点"),
                .init(label: "坐标", value: SpaceGeometryPropertyFormatter.coordinate(point))
            ]
        case .segment3D:
            guard let a = definition.point3D, let b = definition.pointB3D else { return [] }
            let length = a.distance(to: b)
            return [
                .init(label: "对象类型", value: "空间线段"),
                .init(label: "端点 A", value: SpaceGeometryPropertyFormatter.coordinate(a)),
                .init(label: "端点 B", value: SpaceGeometryPropertyFormatter.coordinate(b)),
                .init(label: "长度", value: SpaceGeometryPropertyFormatter.measurement(length))
            ]
        case .line3D:
            guard let point = definition.point3D, let direction = definition.vector3D else { return [] }
            return [
                .init(label: "对象类型", value: "空间直线"),
                .init(label: "过点", value: SpaceGeometryPropertyFormatter.coordinate(point)),
                .init(label: "方向向量", value: SpaceGeometryPropertyFormatter.vector(direction)),
                .init(label: "方向向量长度", value: SpaceGeometryPropertyFormatter.measurement(direction.length))
            ]
        case .plane3D:
            guard let point = definition.point3D, let normal = definition.vector3D else { return [] }
            return [
                .init(label: "对象类型", value: "空间平面"),
                .init(label: "过点", value: SpaceGeometryPropertyFormatter.coordinate(point)),
                .init(label: "法向量", value: SpaceGeometryPropertyFormatter.vector(normal)),
                .init(label: "平面方程", value: SpaceGeometryPropertyFormatter.planeEquation(point: point, normal: normal))
            ]
        case .point, .segment, .line, .ray, .circle, .arc:
            return []
        }
    }
}
