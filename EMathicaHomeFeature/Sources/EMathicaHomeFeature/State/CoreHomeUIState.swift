import Foundation

public struct CoreHomeUIState: Hashable, Codable, Sendable {
    public var selectedFilter: GalleryFilter
    public var selectedModuleID: String
    public var isSelectionMode: Bool
    public var selectedProjectIDs: Set<UUID>
    public var searchText: String
    public var isSearchPresented: Bool

    public init(
        selectedFilter: GalleryFilter,
        selectedModuleID: String,
        isSelectionMode: Bool,
        selectedProjectIDs: Set<UUID>,
        searchText: String,
        isSearchPresented: Bool
    ) {
        self.selectedFilter = selectedFilter
        self.selectedModuleID = selectedModuleID
        self.isSelectionMode = isSelectionMode
        self.selectedProjectIDs = selectedProjectIDs
        self.searchText = searchText
        self.isSearchPresented = isSearchPresented
    }

    static let `default` = CoreHomeUIState(
        selectedFilter: .recent,
        selectedModuleID: "plane",
        isSelectionMode: false,
        selectedProjectIDs: [],
        searchText: "",
        isSearchPresented: false
    )
}
