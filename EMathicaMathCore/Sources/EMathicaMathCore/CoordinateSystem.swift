import Foundation

public struct CoordinateSystem: Hashable, Codable {
    public var name: String

    public init(name: String = "Cartesian2D") {
        self.name = name
    }
}
