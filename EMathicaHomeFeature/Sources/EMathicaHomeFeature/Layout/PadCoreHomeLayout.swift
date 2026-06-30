import EMathicaDocumentKit
import EMathicaThemeKit
import SwiftUI

struct PadCoreHomeLayout: View {
    @Binding var selectedFilter: GalleryFilter
    @Binding var selectedModuleID: String
    @Binding var searchText: String
    @Binding var isSearchPresented: Bool
    let isSelectionMode: Bool
    let selectedProjectIDs: Set<UUID>
    let projects: [RecentProject]
    let moduleItems: [HomeModuleDisplayItem]
    let previewURLForProjectID: (UUID) -> URL?
    let moduleTitleForProjectModuleID: (String) -> String
    let moduleAccentTokenForProjectModuleID: (String) -> ColorToken
    let metrics: CoreHomeLayoutMetrics
    let fluidMetrics: FluidCoreHomeMetrics
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
        moduleItems: [HomeModuleDisplayItem],
        previewURLForProjectID: @escaping (UUID) -> URL?,
        moduleTitleForProjectModuleID: @escaping (String) -> String,
        moduleAccentTokenForProjectModuleID: @escaping (String) -> ColorToken,
        metrics: CoreHomeLayoutMetrics,
        fluidMetrics: FluidCoreHomeMetrics,
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
        self.moduleItems = moduleItems
        self.previewURLForProjectID = previewURLForProjectID
        self.moduleTitleForProjectModuleID = moduleTitleForProjectModuleID
        self.moduleAccentTokenForProjectModuleID = moduleAccentTokenForProjectModuleID
        self.metrics = metrics
        self.fluidMetrics = fluidMetrics
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

    private var padTitleFontSize: CGFloat {
        if metrics.profile == .padPortrait {
            return clamp(fluidMetrics.titleFontSize + 10, min: 64, max: 106)
        }
        return fluidMetrics.titleFontSize
    }

    var body: some View {
        ZStack {
            CoreHeroBackgroundView()

            Group {
                if fluidMetrics.shouldUseScrollView {
                    ScrollView(.vertical, showsIndicators: false) {
                        scrollContent
                    }
                } else {
                    fixedContent
                }
            }
        }
    }

    @ViewBuilder
    private var fixedContent: some View {
        VStack(spacing: fluidMetrics.sectionSpacing) {
            CoreHeroHeaderView(
                onPrimaryAction: onPrimaryAction,
                onSecondaryAction: onSecondaryAction,
                titleFontSize: padTitleFontSize,
                buttonWidth: fluidMetrics.buttonWidth,
                primaryButtonHeight: fluidMetrics.primaryButtonHeight,
                secondaryButtonHeight: fluidMetrics.secondaryButtonHeight,
                buttonFontSize: fluidMetrics.buttonFontSize,
                heroTitleBottomSpacing: fluidMetrics.heroTitleBottomSpacing,
                buttonSpacing: fluidMetrics.buttonSpacing
            )
            .frame(height: fluidMetrics.heroHeight, alignment: .center)
            .padding(.horizontal, fluidMetrics.pageHorizontalPadding)

            Spacer(minLength: fluidMetrics.minHeroPanelGap)

            GalleryDrawerView(
                selectedFilter: Binding(
                    get: { selectedFilter },
                    set: { selectedFilter = $0 }
                ),
                selectedModuleID: Binding(
                    get: { selectedModuleID },
                    set: { selectedModuleID = $0; onSelectModule($0) }
                ),
                isSelectionMode: isSelectionMode,
                selectedProjectIDs: selectedProjectIDs,
                searchText: Binding(
                    get: { searchText },
                    set: { searchText = $0 }
                ),
                isSearchPresented: Binding(
                    get: { isSearchPresented },
                    set: { isSearchPresented = $0 }
                ),
                projects: projects,
                moduleTitleForProjectModuleID: moduleTitleForProjectModuleID,
                moduleItems: moduleItems,
                previewURLForProjectID: previewURLForProjectID,
                fixedHeight: fluidMetrics.panelHeight,
                showsSidebar: false,
                horizontalPadding: fluidMetrics.panelHorizontalPadding,
                cardColumnCount: nil,
                cardSpacing: fluidMetrics.cardSpacing,
                cardMinWidth: fluidMetrics.cardMinWidth,
                cardMaxWidth: fluidMetrics.cardMaxWidth,
                cardHeight: fluidMetrics.cardHeight,
                thumbnailHeight: fluidMetrics.thumbnailHeight,
                panelCornerRadius: fluidMetrics.panelCornerRadius,
                panelPadding: fluidMetrics.panelPadding,
                categoryRowHeight: fluidMetrics.categoryRowHeight,
                isCompactHeader: fluidMetrics.isHeightConstrained,
                bottomPadding: fluidMetrics.panelBottomPadding,
                onSelectModule: onSelectModule,
                onProjectTap: { project in
                    if isSelectionMode {
                        onToggleProjectSelection(project.id)
                    } else {
                        onProjectTap(project)
                    }
                },
                onProjectRenameRequest: onProjectRenameRequest,
                onRenameProject: onRenameProject,
                onDeleteSelectedProjects: onDeleteSelectedProjects,
                onMoveSelectedProjects: onMoveSelectedProjects,
                onClearSelection: onClearSelection,
                onToggleSelectionMode: onToggleSelectionMode
            )
            .frame(height: fluidMetrics.panelHeight)
        }
        .padding(.top, fluidMetrics.topPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var scrollContent: some View {
        VStack(spacing: fluidMetrics.sectionSpacing) {
            CoreHeroHeaderView(
                onPrimaryAction: onPrimaryAction,
                onSecondaryAction: onSecondaryAction,
                titleFontSize: padTitleFontSize,
                buttonWidth: fluidMetrics.buttonWidth,
                primaryButtonHeight: fluidMetrics.primaryButtonHeight,
                secondaryButtonHeight: fluidMetrics.secondaryButtonHeight,
                buttonFontSize: fluidMetrics.buttonFontSize,
                heroTitleBottomSpacing: fluidMetrics.heroTitleBottomSpacing,
                buttonSpacing: fluidMetrics.buttonSpacing
            )
            .frame(height: fluidMetrics.heroHeight, alignment: .center)
            .padding(.horizontal, fluidMetrics.pageHorizontalPadding)

            GalleryDrawerView(
                selectedFilter: Binding(
                    get: { selectedFilter },
                    set: { selectedFilter = $0 }
                ),
                selectedModuleID: Binding(
                    get: { selectedModuleID },
                    set: { selectedModuleID = $0; onSelectModule($0) }
                ),
                isSelectionMode: isSelectionMode,
                selectedProjectIDs: selectedProjectIDs,
                searchText: Binding(
                    get: { searchText },
                    set: { searchText = $0 }
                ),
                isSearchPresented: Binding(
                    get: { isSearchPresented },
                    set: { isSearchPresented = $0 }
                ),
                projects: projects,
                moduleTitleForProjectModuleID: moduleTitleForProjectModuleID,
                moduleItems: moduleItems,
                previewURLForProjectID: previewURLForProjectID,
                fixedHeight: fluidMetrics.panelHeight,
                showsSidebar: false,
                horizontalPadding: fluidMetrics.panelHorizontalPadding,
                cardColumnCount: nil,
                cardSpacing: fluidMetrics.cardSpacing,
                cardMinWidth: fluidMetrics.cardMinWidth,
                cardMaxWidth: fluidMetrics.cardMaxWidth,
                cardHeight: fluidMetrics.cardHeight,
                thumbnailHeight: fluidMetrics.thumbnailHeight,
                panelCornerRadius: fluidMetrics.panelCornerRadius,
                panelPadding: fluidMetrics.panelPadding,
                categoryRowHeight: fluidMetrics.categoryRowHeight,
                isCompactHeader: fluidMetrics.isHeightConstrained,
                bottomPadding: fluidMetrics.panelBottomPadding,
                onSelectModule: onSelectModule,
                onProjectTap: { project in
                    if isSelectionMode {
                        onToggleProjectSelection(project.id)
                    } else {
                        onProjectTap(project)
                    }
                },
                onProjectRenameRequest: onProjectRenameRequest,
                onRenameProject: onRenameProject,
                onDeleteSelectedProjects: onDeleteSelectedProjects,
                onMoveSelectedProjects: onMoveSelectedProjects,
                onClearSelection: onClearSelection,
                onToggleSelectionMode: onToggleSelectionMode
            )
            .frame(height: fluidMetrics.panelHeight)
        }
        .padding(.top, fluidMetrics.topPadding)
    }
}
