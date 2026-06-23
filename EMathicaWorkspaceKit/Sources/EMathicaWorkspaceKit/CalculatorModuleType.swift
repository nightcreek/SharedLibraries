import Foundation

public enum CalculatorModuleType: String, CaseIterable, Identifiable, Codable {
    case plane
    case space
    case modeling
    case music
    case data
    case notes

    public var id: String { rawValue }
}
