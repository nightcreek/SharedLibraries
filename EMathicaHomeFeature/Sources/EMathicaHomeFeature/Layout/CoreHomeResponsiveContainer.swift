import EMathicaDocumentKit
import EMathicaThemeKit
import SwiftUI

struct CoreHomeResponsiveContainer: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @Binding var selectedFilter: GalleryFilter
    @Binding var selectedModuleID: String
    @Binding var searchText: String
    @Binding var isSearchPresented: Bool
    let isSelectionMode: Bool
    let selectedProjectIDs: Set<UUID>
    let projects: [RecentProject]
    let moduleCatalog: HomeModuleCatalog
    let previewURLForProjectID: (UUID) -> URL?
    let moduleTitleForProjectModuleID: (String) -> String
    let moduleAccentTokenForProjectModuleID: (String) -> ColorToken
    let onPrimaryAction: () -> Void
    let onSecondaryAction: () -> Void
    let onSelectModule: (String) -> Void
    let onProjectTap: (RecentProject) -> Void
    let onProjectRenameRequest: (RecentProject) -> Void
    let onRenameProject: (RecentProject, String) -> Void
    let onDeleteSelectedProjects: () -> Void
    let onMoveSelectedProjects: (String) -> Void
    let onClearSelection: () -> Void
    let onToggleSelectionMode: () -> Void
    let onToggleProjectSelection: (UUID) -> Void

    init(
        selectedFilter: Binding<GalleryFilter>,
        selectedModuleID: Binding<String>,
        searchText: Binding<String>,
        isSearchPresented: Binding<Bool>,
        isSelectionMode: Bool,
        selectedProjectIDs: Set<UUID>,
        projects: [RecentProject],
        moduleCatalog: HomeModuleCatalog,
        previewURLForProjectID: @escaping (UUID) -> URL?,
        moduleTitleForProjectModuleID: @escaping (String) -> String,
        moduleAccentTokenForProjectModuleID: @escaping (String) -> ColorToken,
        onPrimaryAction: @escaping () -> Void,
        onSecondaryAction: @escaping () -> Void,
        onSelectModule: @escaping (String) -> Void,
        onProjectTap: @escaping (RecentProject) -> Void,
        onProjectRenameRequest: @escaping (RecentProject) -> Void,
        onRenameProject: @escaping (RecentProject, String) -> Void,
        onDeleteSelectedProjects: @escaping () -> Void,
        onMoveSelectedProjects: @escaping (String) -> Void,
        onClearSelection: @escaping () -> Void,
        onToggleSelectionMode: @escaping () -> Void,
        onToggleProjectSelection: @escaping (UUID) -> Void
    ) {
        self._selectedFilter = selectedFilter
        self._selectedModuleID = selectedModuleID
        self._searchText = searchText
        self._isSearchPresented = isSearchPresented
        self.isSelectionMode = isSelectionMode
        self.selectedProjectIDs = selectedProjectIDs
        self.projects = projects
        self.moduleCatalog = moduleCatalog
        self.previewURLForProjectID = previewURLForProjectID
        self.moduleTitleForProjectModuleID = moduleTitleForProjectModuleID
        self.moduleAccentTokenForProjectModuleID = moduleAccentTokenForProjectModuleID
        self.onPrimaryAction = onPrimaryAction
        self.onSecondaryAction = onSecondaryAction
        self.onSelectModule = onSelectModule
        self.onProjectTap = onProjectTap
        self.onProjectRenameRequest = onProjectRenameRequest
        self.onRenameProject = onRenameProject
        self.onDeleteSelectedProjects = onDeleteSelectedProjects
        self.onMoveSelectedProjects = onMoveSelectedProjects
        self.onClearSelection = onClearSelection
        self.onToggleSelectionMode = onToggleSelectionMode
        self.onToggleProjectSelection = onToggleProjectSelection
    }

    var body: some View {
        GeometryReader { proxy in
            let fluidMetrics = FluidCoreHomeMetrics.resolve(
                size: proxy.size,
                safeAreaInsets: proxy.safeAreaInsets
            )
            let metrics = CoreHomeLayoutMetrics.resolve(
                size: proxy.size,
                horizontalSizeClass: horizontalSizeClass,
                verticalSizeClass: verticalSizeClass
            )
            let moduleItems = moduleCatalog.modules.map { descriptor in
                HomeModuleDisplayItem(
                    id: descriptor.id.rawValue,
                    title: descriptor.title,
                    subtitle: descriptor.subtitle,
                    iconName: descriptor.iconName,
                    accentToken: descriptor.accentToken
                )
            }
            switch metrics.profile {
            case .padPortrait, .padLandscape:
                PadCoreHomeLayout(
                    selectedFilter: $selectedFilter,
                    selectedModuleID: $selectedModuleID,
                    searchText: $searchText,
                    isSearchPresented: $isSearchPresented,
                    isSelectionMode: isSelectionMode,
                    selectedProjectIDs: selectedProjectIDs,
                    projects: projects,
                    moduleItems: moduleItems,
                    previewURLForProjectID: previewURLForProjectID,
                    moduleTitleForProjectModuleID: moduleTitleForProjectModuleID,
                    moduleAccentTokenForProjectModuleID: moduleAccentTokenForProjectModuleID,
                    metrics: metrics,
                    fluidMetrics: fluidMetrics,
                    onPrimaryAction: onPrimaryAction,
                    onSecondaryAction: onSecondaryAction,
                    onSelectModule: onSelectModule,
                    onProjectTap: onProjectTap,
                    onProjectRenameRequest: onProjectRenameRequest,
                    onRenameProject: onRenameProject,
                    onDeleteSelectedProjects: onDeleteSelectedProjects,
                    onMoveSelectedProjects: onMoveSelectedProjects,
                    onClearSelection: onClearSelection,
                    onToggleSelectionMode: onToggleSelectionMode,
                    onToggleProjectSelection: onToggleProjectSelection
                )
            case .phonePortrait, .phoneLandscape:
                PhoneCoreHomeLayout(
                    selectedFilter: $selectedFilter,
                    searchText: $searchText,
                    isSearchPresented: $isSearchPresented,
                    isSelectionMode: isSelectionMode,
                    selectedProjectIDs: selectedProjectIDs,
                    projects: projects,
                    previewURLForProjectID: previewURLForProjectID,
                    moduleTitleForProjectModuleID: moduleTitleForProjectModuleID,
                    moduleAccentTokenForProjectModuleID: moduleAccentTokenForProjectModuleID,
                    metrics: metrics,
                    onPrimaryAction: onPrimaryAction,
                    onSecondaryAction: onSecondaryAction,
                    onProjectTap: onProjectTap,
                    onProjectRenameRequest: onProjectRenameRequest,
                    onRenameProject: onRenameProject,
                    onDeleteSelectedProjects: onDeleteSelectedProjects,
                    onMoveSelectedProjects: onMoveSelectedProjects,
                    onClearSelection: onClearSelection,
                    onToggleSelectionMode: onToggleSelectionMode,
                    onToggleProjectSelection: onToggleProjectSelection
                )
            }
        }
    }
}
