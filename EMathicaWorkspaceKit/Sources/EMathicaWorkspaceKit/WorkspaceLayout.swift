import SwiftUI

public struct WorkspaceLayoutMetrics: Hashable {
    public var objectPanelWidth: CGFloat
    public var objectPanelLeading: CGFloat
    public var objectPanelTop: CGFloat
    public var objectPanelMaxHeight: CGFloat
    public var isCompactKeyboardLayout: Bool

    public var toolbarTop: CGFloat
    public var toolbarHorizontalPadding: CGFloat
    public var toolbarMaxWidth: CGFloat

    public var inspectorTop: CGFloat
    public var inspectorTrailing: CGFloat
    public var inspectorPanelTop: CGFloat
    public var inspectorPanelWidth: CGFloat
    public var inspectorPanelMaxHeight: CGFloat

    public var inputBarHorizontalPadding: CGFloat
    public var inputBarBottom: CGFloat
    public var inputBarMaxWidth: CGFloat

    /// Conservative compact-height breakpoint used to keep the fixed-height keyboard
    /// from crowding the canvas/object panel stack on short Stage Manager / phone windows.
    public static let compactKeyboardAvailableHeightThreshold: CGFloat = 700

    public static func make(size: CGSize, safeInsets: EdgeInsets) -> WorkspaceLayoutMetrics {
        let isWide = size.width >= 900
        let objectPanelMaxHeightRatio: CGFloat = isWide ? 0.66 : 0.58
        let availableHeight = max(0, size.height - safeInsets.top - safeInsets.bottom)
        let isCompactKeyboardLayout = availableHeight < compactKeyboardAvailableHeightThreshold

        #if os(macOS)
        let objectPanelWidth: CGFloat = isWide ? 320 : 280
        #else
        let objectPanelWidth: CGFloat = isWide ? 280 : 260
        #endif
        let objectPanelLeading: CGFloat = isWide ? 20 : 16
        let toolbarTop: CGFloat = max(16, safeInsets.top + 18)
        let toolbarMaxWidth: CGFloat = min(isWide ? 430 : 360, size.width - 128)
        let inspectorPanelTop = max(toolbarTop + 58, safeInsets.top + 78)
        let inspectorPanelWidth = min(isWide ? 340 : 310, max(260, size.width - 44))

        return WorkspaceLayoutMetrics(
            objectPanelWidth: objectPanelWidth,
            objectPanelLeading: objectPanelLeading,
            objectPanelTop: max(toolbarTop + 58, safeInsets.top + 78),
            objectPanelMaxHeight: max(220, size.height * objectPanelMaxHeightRatio),
            isCompactKeyboardLayout: isCompactKeyboardLayout,
            toolbarTop: toolbarTop,
            toolbarHorizontalPadding: isWide ? 16 : 12,
            toolbarMaxWidth: toolbarMaxWidth,
            inspectorTop: toolbarTop,
            inspectorTrailing: isWide ? 22 : 16,
            inspectorPanelTop: inspectorPanelTop,
            inspectorPanelWidth: inspectorPanelWidth,
            inspectorPanelMaxHeight: max(260, size.height - inspectorPanelTop - max(90, safeInsets.bottom + 82)),
            inputBarHorizontalPadding: isWide ? 44 : 34,
            inputBarBottom: max(2, safeInsets.bottom + 0),
            inputBarMaxWidth: 720
        )
    }
}
