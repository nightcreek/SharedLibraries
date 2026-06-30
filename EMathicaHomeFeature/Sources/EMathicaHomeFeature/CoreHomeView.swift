import Foundation
import EMathicaDocumentKit
import EMathicaThemeKit
import EMathicaWorkspaceKit
import SwiftUI

public struct CoreHomeView: View {
    @Binding var selectedFilter: GalleryFilter
    @Binding var selectedModuleID: String
    @Binding var searchText: String
    @Binding var isSearchPresented: Bool
    @Binding var lastErrorMessage: String?

    let isSelectionMode: Bool
    let selectedProjectIDs: Set<UUID>
    let projects: [RecentProject]
    let moduleCatalog: HomeModuleCatalog
    let previewURLForProjectID: (UUID) -> URL?
    let moduleTitleForProjectModuleID: (String) -> String
    let moduleAccentTokenForProjectModuleID: (String) -> ColorToken
    let actions: HomeFeatureActions
    let onSelectModule: (String) -> Void
    let onProjectRenameRequest: (RecentProject) -> Void
    let onRenameProject: (RecentProject, String) -> Void
    let onDeleteSelectedProjects: () -> Void
    let onMoveSelectedProjects: (String) -> Void
    let onClearSelection: () -> Void
    let onToggleSelectionMode: () -> Void
    let onToggleProjectSelection: (UUID) -> Void
    let openProjectRequest: (RecentProject) throws -> HomeWorkspaceOpenRequest
    let createProjectRequest: (CalculatorModuleType) throws -> HomeWorkspaceOpenRequest
    let reloadProjects: () -> Void

    @State private var isShowingNewProjectPicker: Bool = false

    public init(
        selectedFilter: Binding<GalleryFilter>,
        selectedModuleID: Binding<String>,
        searchText: Binding<String>,
        isSearchPresented: Binding<Bool>,
        lastErrorMessage: Binding<String?>,
        isSelectionMode: Bool,
        selectedProjectIDs: Set<UUID>,
        projects: [RecentProject],
        moduleCatalog: HomeModuleCatalog,
        previewURLForProjectID: @escaping (UUID) -> URL?,
        moduleTitleForProjectModuleID: @escaping (String) -> String,
        moduleAccentTokenForProjectModuleID: @escaping (String) -> ColorToken,
        actions: HomeFeatureActions = HomeFeatureActions(openWorkspace: { _ in }),
        onSelectModule: @escaping (String) -> Void,
        onProjectRenameRequest: @escaping (RecentProject) -> Void = { _ in },
        onRenameProject: @escaping (RecentProject, String) -> Void,
        onDeleteSelectedProjects: @escaping () -> Void,
        onMoveSelectedProjects: @escaping (String) -> Void,
        onClearSelection: @escaping () -> Void,
        onToggleSelectionMode: @escaping () -> Void,
        onToggleProjectSelection: @escaping (UUID) -> Void,
        openProjectRequest: @escaping (RecentProject) throws -> HomeWorkspaceOpenRequest,
        createProjectRequest: @escaping (CalculatorModuleType) throws -> HomeWorkspaceOpenRequest,
        reloadProjects: @escaping () -> Void
    ) {
        self._selectedFilter = selectedFilter
        self._selectedModuleID = selectedModuleID
        self._searchText = searchText
        self._isSearchPresented = isSearchPresented
        self._lastErrorMessage = lastErrorMessage
        self.isSelectionMode = isSelectionMode
        self.selectedProjectIDs = selectedProjectIDs
        self.projects = projects
        self.moduleCatalog = moduleCatalog
        self.previewURLForProjectID = previewURLForProjectID
        self.moduleTitleForProjectModuleID = moduleTitleForProjectModuleID
        self.moduleAccentTokenForProjectModuleID = moduleAccentTokenForProjectModuleID
        self.actions = actions
        self.onSelectModule = onSelectModule
        self.onProjectRenameRequest = onProjectRenameRequest
        self.onRenameProject = onRenameProject
        self.onDeleteSelectedProjects = onDeleteSelectedProjects
        self.onMoveSelectedProjects = onMoveSelectedProjects
        self.onClearSelection = onClearSelection
        self.onToggleSelectionMode = onToggleSelectionMode
        self.onToggleProjectSelection = onToggleProjectSelection
        self.openProjectRequest = openProjectRequest
        self.createProjectRequest = createProjectRequest
        self.reloadProjects = reloadProjects
    }

    public var body: some View {
        CoreHomeResponsiveContainer(
            selectedFilter: $selectedFilter,
            selectedModuleID: $selectedModuleID,
            searchText: $searchText,
            isSearchPresented: $isSearchPresented,
            isSelectionMode: isSelectionMode,
            selectedProjectIDs: selectedProjectIDs,
            projects: projects,
            moduleCatalog: moduleCatalog,
            previewURLForProjectID: previewURLForProjectID,
            moduleTitleForProjectModuleID: moduleTitleForProjectModuleID,
            moduleAccentTokenForProjectModuleID: moduleAccentTokenForProjectModuleID,
            onPrimaryAction: { isShowingNewProjectPicker = true },
            onSecondaryAction: {},
            onSelectModule: onSelectModule,
            onProjectTap: { project in
                do {
                    let request = try openProjectRequest(project)
                    actions.openWorkspace(request)
                } catch {
                    lastErrorMessage = "打开项目失败：\(error.localizedDescription)"
                }
            },
            onProjectRenameRequest: onProjectRenameRequest,
            onRenameProject: onRenameProject,
            onDeleteSelectedProjects: onDeleteSelectedProjects,
            onMoveSelectedProjects: onMoveSelectedProjects,
            onClearSelection: onClearSelection,
            onToggleSelectionMode: onToggleSelectionMode,
            onToggleProjectSelection: onToggleProjectSelection
        )
        .sheet(isPresented: $isShowingNewProjectPicker) {
            NewProjectTypePickerView(catalog: moduleCatalog) { module in
                do {
                    let request = try createProjectRequest(module)
                    actions.openWorkspace(request)
                } catch {
                    lastErrorMessage = "新建项目失败：\(error.localizedDescription)"
                }
                isShowingNewProjectPicker = false
            }
        }
        .task {
            reloadProjects()
        }
    }
}

#Preview {
    let previewCatalog = HomeModuleCatalog(modules: [
        HomeModuleDescriptor(id: .plane, title: "平面计算器", subtitle: "函数与几何", iconName: "plane_calculator"),
        HomeModuleDescriptor(id: .space, title: "立体计算器", subtitle: "图形与几何", iconName: "space_calculator"),
        HomeModuleDescriptor(id: .modeling, title: "建模", subtitle: "几何建模与可视化", iconName: "modeling"),
        HomeModuleDescriptor(id: .music, title: "音乐", subtitle: "乐器创作与演奏", iconName: "music"),
        HomeModuleDescriptor(id: .data, title: "数据分析", subtitle: "数据处理与可视化", iconName: "data_analysis"),
        HomeModuleDescriptor(id: .notes, title: "笔记与公式", subtitle: "公式笔记与整理", iconName: "notes_formula")
    ])
    CoreHomeView(
        selectedFilter: .constant(.recent),
        selectedModuleID: .constant("plane"),
        searchText: .constant(""),
        isSearchPresented: .constant(false),
        lastErrorMessage: .constant(nil),
        isSelectionMode: false,
        selectedProjectIDs: [],
        projects: [],
        moduleCatalog: previewCatalog,
        previewURLForProjectID: { _ in nil },
        moduleTitleForProjectModuleID: { _ in "" },
        moduleAccentTokenForProjectModuleID: { _ in .blue },
        actions: HomeFeatureActions(openWorkspace: { _ in }),
        onSelectModule: { _ in },
        onRenameProject: { _, _ in },
        onDeleteSelectedProjects: {},
        onMoveSelectedProjects: { _ in },
        onClearSelection: {},
        onToggleSelectionMode: {},
        onToggleProjectSelection: { _ in },
        openProjectRequest: { _ in throw CocoaError(.featureUnsupported) },
        createProjectRequest: { _ in throw CocoaError(.featureUnsupported) },
        reloadProjects: {}
    )
}
