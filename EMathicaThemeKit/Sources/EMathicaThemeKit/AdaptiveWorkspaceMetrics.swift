import SwiftUI

public struct AdaptiveWorkspaceMetrics {
    public var isWide: Bool
    public var safeInsets: EdgeInsets
    public var size: CGSize

    public static func make(size: CGSize, safeInsets: EdgeInsets) -> AdaptiveWorkspaceMetrics {
        AdaptiveWorkspaceMetrics(
            isWide: size.width >= 900,
            safeInsets: safeInsets,
            size: size
        )
    }
}
