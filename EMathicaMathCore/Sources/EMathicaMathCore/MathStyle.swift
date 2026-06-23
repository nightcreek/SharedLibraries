import Foundation

public enum MathLineStyle: String, Hashable, Codable, Sendable {
    case solid
    case dashed
}

public struct MathStyle: Hashable, Codable {
    public var colorToken: String
    public var opacity: Double
    public var fillOpacity: Double
    public var lineWidth: Double
    public var pointSize: Double
    public var lineStyle: MathLineStyle

    public static let defaultLineWidth: Double = 2.0
    public static let defaultPointSize: Double = 6.0
    public static let defaultLineStyle: MathLineStyle = .solid

    public init(
        colorToken: String,
        opacity: Double = 1.0,
        fillOpacity: Double = 0.18,
        lineWidth: Double = MathStyle.defaultLineWidth,
        pointSize: Double = MathStyle.defaultPointSize,
        lineStyle: MathLineStyle = MathStyle.defaultLineStyle
    ) {
        self.colorToken = colorToken
        self.opacity = opacity
        self.fillOpacity = fillOpacity
        self.lineWidth = lineWidth
        self.pointSize = pointSize
        self.lineStyle = lineStyle
    }

    public enum CodingKeys: String, CodingKey {
        case colorToken
        case opacity
        case fillOpacity
        case lineWidth
        case pointSize
        case lineStyle
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.colorToken = try container.decode(String.self, forKey: .colorToken)
        self.opacity = try container.decodeIfPresent(Double.self, forKey: .opacity) ?? 1.0
        self.fillOpacity = try container.decodeIfPresent(Double.self, forKey: .fillOpacity) ?? 0.18
        self.lineWidth = try container.decodeIfPresent(Double.self, forKey: .lineWidth) ?? MathStyle.defaultLineWidth
        self.pointSize = try container.decodeIfPresent(Double.self, forKey: .pointSize) ?? MathStyle.defaultPointSize
        self.lineStyle = try container.decodeIfPresent(MathLineStyle.self, forKey: .lineStyle) ?? MathStyle.defaultLineStyle
    }

    public mutating func sanitizeInPlace() {
        lineWidth = max(0.5, min(8.0, lineWidth))
        opacity = max(0.0, min(1.0, opacity))
        fillOpacity = max(0.0, min(1.0, fillOpacity))
        pointSize = max(3.0, min(16.0, pointSize))
    }

    public func sanitized() -> MathStyle {
        var copy = self
        copy.sanitizeInPlace()
        return copy
    }
}
