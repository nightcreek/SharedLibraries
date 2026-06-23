import Foundation
import EMathicaMathCore

public enum SpaceGeometryPropertyFormatter {
    public static func coordinate(_ point: WorldPoint3D) -> String {
        "(\(number2(point.x)), \(number2(point.y)), \(number2(point.z)))"
    }

    public static func vector(_ vector: Vector3D) -> String {
        "<\(number2(vector.x)), \(number2(vector.y)), \(number2(vector.z))>"
    }

    public static func measurement(_ value: Double) -> String {
        number2(value)
    }

    public static func planeEquation(point: WorldPoint3D, normal: Vector3D) -> String {
        guard isFiniteValid(normal.x), isFiniteValid(normal.y), isFiniteValid(normal.z) else {
            return "未定义"
        }
        let length = normal.length
        guard isFiniteValid(length), length > 1e-8 else {
            return "未定义"
        }
        let d = normal.dot(Vector3D(x: point.x, y: point.y, z: point.z))
        guard isFiniteValid(d) else {
            return "未定义"
        }
        return "\(number2(normal.x))x + \(number2(normal.y))y + \(number2(normal.z))z = \(number2(d))"
    }

    public static func number2(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    public static func isFiniteValid(_ value: Double) -> Bool {
        value.isFinite && !value.isNaN
    }
}
