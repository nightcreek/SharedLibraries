import Foundation

public enum WorkspaceToolIcon: Hashable {
    case system(String)
    case asset(String)
    case text(String)
    case geometry(GeometryToolGlyph)
}

public enum GeometryToolGlyph: String, Hashable {
    case point
    case segment
    case midpoint
    case line
    case ray
    case parallel
    case perpendicular
    case circle
    case arc
    case intersection
}
