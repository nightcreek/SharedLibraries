import EMathicaDocumentKit
import EMathicaThemeKit
import EMathicaWorkspaceKit
import SwiftUI

struct GalleryDrawerView: View {
    @Environment(\.colorScheme) private var colorScheme

    let selectedFilter: Binding<GalleryFilter>
    let selectedModuleID: Binding<String>
    let isSelectionMode: Bool
    let selectedProjectIDs: Set<UUID>
    let searchText: Binding<String>
    let isSearchPresented: Binding<Bool>
    let projects: [RecentProject]
    let moduleTitleForProjectModuleID: (String) -> String
    let moduleItems: [HomeModuleDisplayItem]
    let previewURLForProjectID: (UUID) -> URL?
    let drawerHeightFraction: ClosedRange<Double>?
    let fixedHeight: CGFloat?
    let showsSidebar: Bool
    let horizontalPadding: CGFloat
    let cardColumnCount: Int?
    let cardSpacing: CGFloat
    let cardMinWidth: CGFloat?
    let cardMaxWidth: CGFloat?
    let cardHeight: CGFloat?
    let thumbnailHeight: CGFloat?
    let panelCornerRadius: CGFloat?
    let panelPadding: CGFloat?
    let categoryRowHeight: CGFloat?
    let isCompactHeader: Bool
    let bottomPadding: CGFloat
    let onSelectModule: (String) -> Void
    let onProjectTap: (RecentProject) -> Void
    let onProjectRenameRequest: (RecentProject) -> Void
    let onRenameProject: (RecentProject, String) -> Void
    let onDeleteSelectedProjects: () -> Void
    let onMoveSelectedProjects: (String) -> Void
    let onClearSelection: () -> Void
    let onToggleSelectionMode: () -> Void

    init(
        selectedFilter: Binding<GalleryFilter>,
        selectedModuleID: Binding<String>,
        isSelectionMode: Bool,
        selectedProjectIDs: Set<UUID>,
        searchText: Binding<String>,
        isSearchPresented: Binding<Bool>,
        projects: [RecentProject],
        moduleTitleForProjectModuleID: @escaping (String) -> String,
        moduleItems: [HomeModuleDisplayItem],
        previewURLForProjectID: @escaping (UUID) -> URL?,
        drawerHeightFraction: ClosedRange<Double>? = 0.52...0.60,
        fixedHeight: CGFloat? = nil,
        showsSidebar: Bool = true,
        horizontalPadding: CGFloat = 16,
        cardColumnCount: Int? = nil,
        cardSpacing: CGFloat = 18,
        cardMinWidth: CGFloat? = nil,
        cardMaxWidth: CGFloat? = nil,
        cardHeight: CGFloat? = nil,
        thumbnailHeight: CGFloat? = nil,
        panelCornerRadius: CGFloat? = nil,
        panelPadding: CGFloat? = nil,
        categoryRowHeight: CGFloat? = nil,
        isCompactHeader: Bool = false,
        bottomPadding: CGFloat = 14,
        onSelectModule: @escaping (String) -> Void,
        onProjectTap: @escaping (RecentProject) -> Void,
        onProjectRenameRequest: @escaping (RecentProject) -> Void,
        onRenameProject: @escaping (RecentProject, String) -> Void,
        onDeleteSelectedProjects: @escaping () -> Void,
        onMoveSelectedProjects: @escaping (String) -> Void,
        onClearSelection: @escaping () -> Void,
        onToggleSelectionMode: @escaping () -> Void
    ) {
        self.selectedFilter = selectedFilter
        self.selectedModuleID = selectedModuleID
        self.isSelectionMode = isSelectionMode
        self.selectedProjectIDs = selectedProjectIDs
        self.searchText = searchText
        self.isSearchPresented = isSearchPresented
        self.projects = projects
        self.moduleTitleForProjectModuleID = moduleTitleForProjectModuleID
        self.moduleItems = moduleItems
        self.previewURLForProjectID = previewURLForProjectID
        self.drawerHeightFraction = drawerHeightFraction
        self.fixedHeight = fixedHeight
        self.showsSidebar = showsSidebar
        self.horizontalPadding = horizontalPadding
        self.cardColumnCount = cardColumnCount
        self.cardSpacing = cardSpacing
        self.cardMinWidth = cardMinWidth
        self.cardMaxWidth = cardMaxWidth
        self.cardHeight = cardHeight
        self.thumbnailHeight = thumbnailHeight
        self.panelCornerRadius = panelCornerRadius
        self.panelPadding = panelPadding
        self.categoryRowHeight = categoryRowHeight
        self.isCompactHeader = isCompactHeader
        self.bottomPadding = bottomPadding
        self.onSelectModule = onSelectModule
        self.onProjectTap = onProjectTap
        self.onProjectRenameRequest = onProjectRenameRequest
        self.onRenameProject = onRenameProject
        self.onDeleteSelectedProjects = onDeleteSelectedProjects
        self.onMoveSelectedProjects = onMoveSelectedProjects
        self.onClearSelection = onClearSelection
        self.onToggleSelectionMode = onToggleSelectionMode
    }

    @State private var renamingProject: RecentProject?
    @State private var renameTitleDraft: String = ""

    var body: some View {
        GeometryReader { proxy in
            let fullHeight = proxy.size.height
            let safeBottom = proxy.safeAreaInsets.bottom
            let targetHeight = fixedHeight ?? (fullHeight * (drawerHeightFraction?.upperBound ?? 0.60))

            VStack(spacing: 0) {
                LiquidGlassPanel(theme: drawerTheme) {
                    VStack(spacing: 12) {
                        drawerHandle

                        GalleryTopBar(
                            selectedFilter: selectedFilter,
                            isSelectionMode: isSelectionMode,
                            searchText: searchText,
                            isSearchPresented: isSearchPresented,
                            rowHeight: categoryRowHeight,
                            isCompact: isCompactHeader,
                            onToggleSelectionMode: onToggleSelectionMode
                        )

                        Divider().opacity(colorScheme == .dark ? 0.22 : 0.40)

                        HStack(alignment: .top, spacing: 18) {
                            if showsSidebar {
                                CalculatorModuleSidebarView(
                                    modules: moduleItems,
                                    selectedModuleID: selectedModuleID.wrappedValue,
                                    onSelect: onSelectModule
                                )
                                .frame(width: 240)
                            }

                            ScrollView(.vertical, showsIndicators: false) {
                                RecentProjectsGridView(
                                    projects: projects,
                                    moduleTitleForProjectModuleID: moduleTitleForProjectModuleID,
                                    isSelectionMode: isSelectionMode,
                                    selectedProjectIDs: selectedProjectIDs,
                                    previewURLForProjectID: previewURLForProjectID,
                                    preferredColumnCount: cardColumnCount,
                                    cardSpacing: cardSpacing,
                                    adaptiveMinWidth: cardMinWidth,
                                    adaptiveMaxWidth: cardMaxWidth,
                                    cardHeight: cardHeight,
                                    thumbnailHeight: thumbnailHeight,
                                    onProjectTap: onProjectTap,
                                    onProjectRenameTap: { project in
                                        onProjectRenameRequest(project)
                                        renamingProject = project
                                        renameTitleDraft = project.title
                                    }
                                )

                                if !isSelectionMode {
                                    footerText
                                        .padding(.top, 8)
                                        .padding(.bottom, 12)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                        if isSelectionMode {
                            GalleryBatchActionBar(
                                selectedProjectIDs: selectedProjectIDs,
                                modules: moduleItems,
                                onDeleteSelectedProjects: onDeleteSelectedProjects,
                                onMoveSelectedProjects: onMoveSelectedProjects,
                                onClearSelection: onClearSelection
                            )
                        }
                    }
                }
            }
            .frame(height: targetHeight)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.horizontal, horizontalPadding)
            .padding(.bottom, safeBottom + bottomPadding)
            .sheet(item: $renamingProject) { project in
                RenameProjectSheet(
                    initialTitle: project.title,
                    onCancel: {
                        renamingProject = nil
                        renameTitleDraft = ""
                    },
                    onSave: { newTitle in
                        onRenameProject(project, newTitle)
                        renamingProject = nil
                        renameTitleDraft = ""
                    }
                )
            }
        }
    }

    private var drawerTheme: LiquidGlassTheme {
        var t = LiquidGlassTheme()
        t.panelCornerRadius = panelCornerRadius ?? 34
        t.panelPadding = panelPadding ?? 16
        return t
    }

    private var drawerHandle: some View {
        Capsule(style: .continuous)
            .fill(Color.white.opacity(colorScheme == .dark ? 0.22 : 0.38))
            .frame(width: 48, height: 5)
            .padding(.top, 2)
            .padding(.bottom, 2)
    }

    private var footerText: some View {
        Text("按最近更新排序")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }
}

private struct GalleryTopBar: View {
    @Binding var selectedFilter: GalleryFilter
    let isSelectionMode: Bool
    @Binding var searchText: String
    @Binding var isSearchPresented: Bool
    let rowHeight: CGFloat?
    let isCompact: Bool
    let onToggleSelectionMode: () -> Void

    var body: some View {
        VStack(spacing: isCompact ? 8 : 10) {
            HStack(spacing: 12) {
                GalleryTabBar(selectedFilter: $selectedFilter)

                Spacer(minLength: 0)

                Button(isSelectionMode ? "完成" : "选择") {
                    onToggleSelectionMode()
                }
                .buttonStyle(.bordered)

                Button {
                    withAnimation(.snappy(duration: 0.20)) {
                        isSearchPresented.toggle()
                        if !isSearchPresented {
                            searchText = ""
                        }
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                .buttonStyle(.bordered)
            }
            .controlSize(isCompact ? .small : .regular)
            .frame(minHeight: rowHeight ?? 40)

            if isSearchPresented {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("搜索 .emathica 文件名", text: $searchText)
                        .textFieldStyle(.plain)

                    Button {
                        searchText = ""
                        isSearchPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }
}

private struct GalleryBatchActionBar: View {
    @Environment(\.colorScheme) private var colorScheme

    let selectedProjectIDs: Set<UUID>
    let modules: [HomeModuleDisplayItem]
    let onDeleteSelectedProjects: () -> Void
    let onMoveSelectedProjects: (String) -> Void
    let onClearSelection: () -> Void

    @State private var isShowingDeleteAlert: Bool = false
    @State private var isShowingMoveSheet: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Text("已选 \(selectedProjectIDs.count) 项")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            Button(role: .destructive) {
                isShowingDeleteAlert = true
            } label: {
                Label("删除", systemImage: "trash")
            }
            .buttonStyle(.bordered)

            Button {
                isShowingMoveSheet = true
            } label: {
                Label("移动", systemImage: "folder")
            }
            .buttonStyle(.bordered)

            Button {
                onClearSelection()
            } label: {
                Label("取消", systemImage: "xmark")
            }
            .buttonStyle(.bordered)
        }
        .controlSize(.regular)
        .padding(.top, 2)
        .alert("删除项目", isPresented: $isShowingDeleteAlert) {
            Button("删除", role: .destructive) {
                onDeleteSelectedProjects()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("第一版为 mock 删除（仅内存移除）。后续会对 .emathica 包进行真实删除。")
        }
        .sheet(isPresented: $isShowingMoveSheet) {
            MoveDestinationSheet(modules: modules) { moduleID in
                onMoveSelectedProjects(moduleID)
                isShowingMoveSheet = false
            }
        }
        .tint(colorScheme == .dark ? .white : .primary)
    }
}

private struct MoveDestinationSheet: View {
    @Environment(\.dismiss) private var dismiss

    let modules: [HomeModuleDisplayItem]
    let onMove: (String) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("移动到") {
                    ForEach(modules) { module in
                        Button {
                            onMove(module.id)
                        } label: {
                            HStack(spacing: 12) {
                                ModuleIconView(
                                    iconName: module.iconName,
                                    accent: module.accentToken.resolvedColor()
                                )
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(module.title)
                                        .font(.system(size: 15, weight: .semibold))
                                    Text(module.subtitle)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("移动项目")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

private struct RenameProjectSheet: View {
    @Environment(\.dismiss) private var dismiss

    let initialTitle: String
    let onCancel: () -> Void
    let onSave: (String) -> Void

    @State private var titleDraft: String
    @FocusState private var isTitleFocused: Bool

    init(
        initialTitle: String,
        onCancel: @escaping () -> Void,
        onSave: @escaping (String) -> Void
    ) {
        self.initialTitle = initialTitle
        self.onCancel = onCancel
        self.onSave = onSave
        _titleDraft = State(initialValue: initialTitle)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("输入新的项目名称")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)

                TextField("项目名称", text: $titleDraft)
                    #if canImport(UIKit)
                    .textInputAutocapitalization(.never)
                    #endif
                    .autocorrectionDisabled(true)
                    .focused($isTitleFocused)
                    .submitLabel(.done)
                    .onSubmit(save)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Spacer(minLength: 0)
            }
            .padding(16)
            .navigationTitle("重命名项目")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isTitleFocused = true
                }
            }
        }
    }

    private func save() {
        onSave(titleDraft)
        dismiss()
    }
}
