import Foundation

public enum MathObjectType: String, Codable, CaseIterable {
    case function
    case point
    case circle
    case segment
    case line
    case ray
    case parameter
    case parameterGroup
    case arc
}
