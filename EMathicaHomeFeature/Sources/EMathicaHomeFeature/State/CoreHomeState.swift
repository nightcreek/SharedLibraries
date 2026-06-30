import EMathicaWorkspaceKit
import EMathicaThemeKit
import EMathicaDocumentKit
import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
public final class CoreHomeState {
    public var ui: CoreHomeUIState

    public let moduleCatalog: HomeModuleCatalog
    private let projectStore: any ProjectStore
    public var projects: [RecentProject]
    public var lastErrorMessage: String?

    public init(
        projectStore: any ProjectStore,
        moduleCatalog: HomeModuleCatalog,
        ui: CoreHomeUIState? = nil
    ) {
        self.moduleCatalog = moduleCatalog
        self.projectStore = projectStore
        self.projects = []
        self.ui = ui ?? .default
        self.lastErrorMessage = nil

        if self.ui.selectedModuleID.isEmpty || !self.moduleCatalog.modules.contains(where: { $0.id.rawValue == self.ui.selectedModuleID }) {
            self.ui.selectedModuleID = Self.defaultSelectedModuleID(in: moduleCatalog)
        }
    }

    private static func defaultSelectedModuleID(in moduleCatalog: HomeModuleCatalog) -> String {
        if let planeModule = moduleCatalog.modules.first(where: { $0.id == .plane }) {
            return planeModule.id.rawValue
        }
        return moduleCatalog.modules.first?.id.rawValue ?? ""
    }

    private func descriptor(for moduleID: String) -> HomeModuleDescriptor? {
        moduleCatalog.modules.first(where: { $0.id.rawValue == moduleID })
    }

    public func moduleTitle(for moduleID: String) -> String {
        descriptor(for: moduleID)?.title ?? ""
    }

    func moduleIconName(for moduleID: String) -> String {
        descriptor(for: moduleID)?.iconName ?? "plane_calculator"
    }

    public func moduleAccentToken(for moduleID: String) -> ColorToken {
        descriptor(for: moduleID)?.accentToken ?? .blue
    }

    public func filteredProjects() -> [RecentProject] {
        var result = projects

        if let moduleID = ui.selectedFilter.moduleID {
            result = result.filter { $0.moduleID == moduleID }
        }

        let trimmed = ui.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(trimmed) }
        }

        return Array(result.prefix(10))
    }

    public func setFilter(_ filter: GalleryFilter) {
        withAnimation(.snappy(duration: 0.22)) {
            ui.selectedFilter = filter
            if let moduleID = filter.moduleID {
                ui.selectedModuleID = moduleID
            }
        }
    }

    public func selectModule(moduleID: String) {
        withAnimation(.snappy(duration: 0.22)) {
            ui.selectedModuleID = moduleID
            ui.selectedFilter = GalleryFilter.allCases.first(where: { $0.moduleID == moduleID }) ?? .recent
        }
    }

    public func toggleSelectionMode() {
        withAnimation(.snappy(duration: 0.20)) {
            ui.isSelectionMode.toggle()
            if !ui.isSelectionMode {
                ui.selectedProjectIDs.removeAll()
            }
        }
    }

    public func toggleProjectSelection(id: UUID) {
        if ui.selectedProjectIDs.contains(id) {
            ui.selectedProjectIDs.remove(id)
        } else {
            ui.selectedProjectIDs.insert(id)
        }
    }

    public func clearSelection() {
        ui.selectedProjectIDs.removeAll()
    }

    public func deleteSelectedProjects() {
        let ids = ui.selectedProjectIDs
        do {
            for id in ids {
                try projectStore.deleteProject(id: id)
            }
            reloadProjects()
        } catch {
            lastErrorMessage = "删除项目失败：\(error.localizedDescription)"
        }
        clearSelection()
    }

    public func moveSelectedProjects(to moduleID: String) {
        let ids = ui.selectedProjectIDs
        do {
            for id in ids {
                var document = try projectStore.loadProject(id: id)
                var metadata = document.metadata
                metadata.moduleID = moduleID
                metadata.calculatorType = moduleID
                metadata.updatedAt = Date()
                document.metadata = metadata
                document.moduleID = moduleID
                try projectStore.saveProject(document)
            }
            reloadProjects()
        } catch {
            lastErrorMessage = "移动项目失败：\(error.localizedDescription)"
        }
        clearSelection()
    }

    public func reloadProjects() {
        do {
            projects = try projectStore.listProjects()
            lastErrorMessage = nil
        } catch {
            projects = []
            lastErrorMessage = "读取项目列表失败：\(error.localizedDescription)"
        }
    }

    public func createProject(module: CalculatorModuleType, title: String = "新项目") throws -> EMathicaDocument {
        let now = Date()
        let projectID = UUID()
        let metadata = ProjectMetadata(
            id: projectID,
            title: title,
            moduleID: module.rawValue,
            createdAt: now,
            updatedAt: now,
            calculatorType: module.rawValue
        )
        let document: EMathicaDocument
        switch module {
        case .plane:
            document = EMathicaDocument(id: projectID, metadata: metadata, moduleID: module.rawValue, objects: [])
        default:
            document = EMathicaDocument(id: projectID, metadata: metadata, moduleID: module.rawValue, objects: [])
        }
        _ = try projectStore.createProject(metadata: metadata, document: document)
        reloadProjects()
        return document
    }

    public func openProject(_ project: RecentProject) throws -> (module: CalculatorModuleType, document: EMathicaDocument) {
        let module = CalculatorModuleType(rawValue: project.moduleID) ?? .plane
        var document = try projectStore.loadProject(id: project.id)
        var metadata = document.metadata
        metadata.updatedAt = Date()
        document.metadata = metadata
        do {
            try projectStore.saveProject(document)
            reloadProjects()
        } catch {
            lastErrorMessage = "更新最近使用失败：\(error.localizedDescription)"
        }
        return (module, document)
    }

    func saveProject(_ document: EMathicaDocument) {
        do {
            try projectStore.saveProject(document)
            reloadProjects()
        } catch {
            lastErrorMessage = "保存项目失败：\(error.localizedDescription)"
        }
    }

    public func renameProject(id: UUID, title: String) {
        do {
            _ = try projectStore.renameProject(id: id, title: title)
            reloadProjects()
        } catch {
            lastErrorMessage = "重命名失败：\(error.localizedDescription)"
        }
    }

    public func previewURL(for projectID: UUID) -> URL? {
        projectStore.previewURL(for: projectID)
    }
}
