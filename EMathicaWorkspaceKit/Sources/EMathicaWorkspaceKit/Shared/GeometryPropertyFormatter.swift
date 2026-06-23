import Foundation
import EMathicaMathCore

public enum GeometryPropertyFormatter {
    public static func coordinate(_ point: WorldPoint) -> String {
        "(\(number2(point.x)), \(number2(point.y)))"
    }

    public static func vector(dx: Double, dy: Double) -> String {
        "(\(number2(dx)), \(number2(dy)))"
    }

    public static func measurement(_ value: Double) -> String {
        number2(value)
    }

    public static func length(_ value: Double) -> String {
        measurement(value)
    }

    public static func radius(_ value: Double) -> String {
        measurement(value)
    }

    public static func diameter(_ value: Double) -> String {
        measurement(value)
    }

    public static func angleRadians(_ radians: Double) -> String {
        let degrees = radians * 180 / .pi
        return "\(number1(degrees))°"
    }

    public static func slope(dx: Double, dy: Double) -> String {
        guard isFiniteValid(dx), isFiniteValid(dy) else {
            return "未定义"
        }
        if abs(dx) < 1e-9 {
            return "垂直"
        }
        let value = dy / dx
        guard isFiniteValid(value) else {
            return "未定义"
        }
        return number2(value)
    }

    public static func number2(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    public static func number1(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    public static func isFiniteValid(_ value: Double) -> Bool {
        value.isFinite && !value.isNaN
    }
}

