import EMathicaMathInputCore
import EMathicaMathInputUI
import EMathicaThemeKit
import EMathicaDocumentKit
import EMathicaMathCore
import EMathicaFormulaDisplayCore
import EMathicaFormulaDisplaySwiftUI
import SwiftUI

public struct WorkspaceView: View {
    @Environment(\.workspaceNavigationDelegate) private var navigationDelegate

    public let module: CalculatorModuleType
    public let configuration: WorkspaceConfiguration

    @State private var state: WorkspaceState
    @State private var objectPanelDragStartWidth: CGFloat?
    @State private var isShowingRenameSheet: Bool = false
    @State private var isShowingDeletedHistorySheet: Bool = false
    @State private var renameTitleDraft: String = ""
    @AppStorage("Workspace.objectPanelWidth") private var storedObjectPanelWidth: Double = 0

    public init(module: CalculatorModuleType, document: EMathicaDocument, configuration: WorkspaceConfiguration) {
        self.module = module
        self.configuration = configuration
        self._state = State(
            initialValue: WorkspaceState(
                module: module,
                document: document,
                toolGroups: configuration.toolGroups,
                moduleProvider: configuration.moduleProvider,
                readOnlyFormulaDisplayConfiguration: configuration.readOnlyFormulaDisplay
            )
        )
    }

    public var body: some View {
        GeometryReader { proxy in
            let safeInsets = proxy.safeAreaInsets
            let metrics = WorkspaceLayoutMetrics.make(size: proxy.size, safeInsets: safeInsets)
            let objectPanelWidth = resolvedObjectPanelWidth(size: proxy.size, metrics: metrics)
            let objectPanelHeight = resolvedObjectPanelHeight(size: proxy.size, metrics: metrics)

            ZStack(alignment: .top) {
                canvasLayer
                    .zIndex(WorkspaceInteractionLayer.canvas)

                if configuration.showsObjectPanel && state.isObjectPanelPresented {
                    if state.isObjectPanelFullscreen {
                        objectPanelFullscreenLayer(
                            size: proxy.size,
                            metrics: metrics
                        )
                        .zIndex(WorkspaceInteractionLayer.objects + 2)
                    } else {
                        AlgebraObjectPanelView(
                            state: state,
                            onRequestDeleteObjects: { ids in
                                requestDeleteObjects(ids)
                            },
                            onToggleFullscreen: {
                                state.isObjectPanelFullscreen = true
                            },
                            isFullscreen: false
                        )
                            .frame(width: objectPanelWidth)
                            .frame(height: objectPanelHeight, alignment: .top)
                            .padding(.leading, metrics.objectPanelLeading)
                            .padding(.top, metrics.objectPanelTop)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .animation(.snappy(duration: 0.20), value: objectPanelWidth)
                            .animation(.snappy(duration: 0.20), value: objectPanelHeight)
                            .zIndex(WorkspaceInteractionLayer.objects)

                        ObjectPanelResizeHandle()
                            .frame(width: WorkspaceControlHitbox.resizeHandleHitWidth, height: objectPanelHeight)
                            .position(
                                x: metrics.objectPanelLeading + objectPanelWidth,
                                y: metrics.objectPanelTop + objectPanelHeight * 0.5
                            )
                            .highPriorityGesture(objectPanelResizeGesture(size: proxy.size, metrics: metrics))
                            .zIndex(WorkspaceInteractionLayer.objects + 1)
                    }
                }

                FloatingToolGroupsView(
                    toolGroups: configuration.toolGroups,
                    selectedToolID: state.activeToolID,
                    onToolAction: handleToolAction
                )
                .frame(maxWidth: metrics.toolbarMaxWidth)
.padding(Edge.Set.horizontal, metrics.toolbarHorizontalPadding)
                .contentShape(Rectangle())
                .position(
                    x: proxy.size.width * 0.5,
                    y: metrics.toolbarTop + WorkspaceControlHitbox.toolbarHalfHeight
                )
                .zIndex(WorkspaceInteractionLayer.toolbar)

                HStack(spacing: 8) {
                    if configuration.showsObjectPanel {
                        objectPanelToggleButton
                    }

                    #if DEBUG
                    DocumentMenuButton(
                        title: state.document.metadata.title,
                        onGoHome: { navigationDelegate?.workspaceDidRequestClose(document: state.document) },
                        onRename: {
                            renameTitleDraft = state.document.metadata.title
                            isShowingRenameSheet = true
                        },
                        onShowDeletedHistory: {
                            isShowingDeletedHistorySheet = true
                        },
                        onUndo: { state.dispatch(.undo) },
                        onRedo: { state.dispatch(.redo) },
                        onRevertToOpenState: { state.dispatch(.revertToOpenState) },
                        canUndo: state.canUndo,
                        canRedo: state.canRedo,
                        canRevert: state.canRevertToOpenState,
                        readOnlyFormulaDebugOverride: state.readOnlyFormulaDisplayRuntimeOverride,
                        effectiveReadOnlyFormulaBackend: state.effectiveReadOnlyFormulaDisplayConfiguration.backend,
                        readOnlyFormulaDiagnostics: state.readOnlyFormulaDiagnostics,
                        onUseProjectDefaultReadOnlyFormulaBackend: {
                            state.clearReadOnlyFormulaBackendOverride()
                        },
                        onUseLegacyReadOnlyFormulaBackend: {
                            state.setReadOnlyFormulaBackendOverride(.legacy)
                        },
                        onUseSwiftMathReadOnlyFormulaBackend: {
                            state.setReadOnlyFormulaBackendOverride(.swiftMath)
                        }
                    )
                    #else
                    DocumentMenuButton(
                        title: state.document.metadata.title,
                        onGoHome: { navigationDelegate?.workspaceDidRequestClose(document: state.document) },
                        onRename: {
                            renameTitleDraft = state.document.metadata.title
                            isShowingRenameSheet = true
                        },
                        onShowDeletedHistory: {
                            isShowingDeletedHistorySheet = true
                        },
                        onUndo: { state.dispatch(.undo) },
                        onRedo: { state.dispatch(.redo) },
                        onRevertToOpenState: { state.dispatch(.revertToOpenState) },
                        canUndo: state.canUndo,
                        canRedo: state.canRedo,
                        canRevert: state.canRevertToOpenState
                    )
                    #endif
                }
                .padding(.leading, metrics.objectPanelLeading)
                .padding(.top, metrics.inspectorTop)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .zIndex(WorkspaceInteractionLayer.controls)

                HStack(spacing: 8) {
                    LiquidGlassIconButton(systemName: "arrow.uturn.backward", accessibilityLabel: "撤销") {
                        state.dispatch(.undo)
                    }
                    .frame(
                        width: WorkspaceControlHitbox.circleButtonHalfSize * 2,
                        height: WorkspaceControlHitbox.circleButtonHalfSize * 2
                    )
                    .contentShape(Circle())
                    .allowsHitTesting(true)
                    .disabled(!state.canUndo || !state.allowsWorkspaceUndoShortcuts)
                    .keyboardShortcut("z", modifiers: [.command])

                    LiquidGlassIconButton(systemName: "arrow.uturn.forward", accessibilityLabel: "重做") {
                        state.dispatch(.redo)
                    }
                    .frame(
                        width: WorkspaceControlHitbox.circleButtonHalfSize * 2,
                        height: WorkspaceControlHitbox.circleButtonHalfSize * 2
                    )
                    .contentShape(Circle())
                    .allowsHitTesting(true)
                    .disabled(!state.canRedo || !state.allowsWorkspaceUndoShortcuts)
                    .keyboardShortcut("z", modifiers: [.command, .shift])
                    .keyboardShortcut("y", modifiers: [.command])
                }
                .position(
                    x: proxy.size.width - metrics.inspectorTrailing - 96,
                    y: metrics.inspectorTop + WorkspaceControlHitbox.circleButtonHalfSize
                )
                .zIndex(WorkspaceInteractionLayer.controls)

                if configuration.showsInspectorButton {
                    LiquidGlassIconButton(systemName: "slider.horizontal.3", accessibilityLabel: "设置和检查器") {
                        state.dispatch(.setInspectorVisible(!state.isInspectorPresented))
                    }
                    .frame(
                        width: WorkspaceControlHitbox.circleButtonHalfSize * 2,
                        height: WorkspaceControlHitbox.circleButtonHalfSize * 2
                    )
                    .contentShape(Circle())
                    .allowsHitTesting(true)
                    .position(
                        x: proxy.size.width - metrics.inspectorTrailing - WorkspaceControlHitbox.circleButtonHalfSize,
                        y: metrics.inspectorTop + WorkspaceControlHitbox.circleButtonHalfSize
                    )
                    .zIndex(WorkspaceInteractionLayer.controls)
                }

                if configuration.showsInspectorButton && state.isInspectorPresented {
                    ObjectInspectorPanel(state: state) {
                        state.dispatch(.setInspectorVisible(false))
                    }
                    .frame(width: metrics.inspectorPanelWidth)
                    .frame(maxHeight: metrics.inspectorPanelMaxHeight)
                    .position(
                        x: proxy.size.width - metrics.inspectorTrailing - metrics.inspectorPanelWidth * 0.5,
                        y: metrics.inspectorPanelTop + metrics.inspectorPanelMaxHeight * 0.5
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .zIndex(WorkspaceInteractionLayer.controls + 1)
                }

                if configuration.showsInputBar {
                    WorkspaceInlineInputDock(state: state)
                        .frame(maxWidth: metrics.inputBarMaxWidth)
.padding(Edge.Set.horizontal, metrics.inputBarHorizontalPadding)
                        .padding(.bottom, metrics.inputBarBottom)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .zIndex(WorkspaceInteractionLayer.controls)
                }
            }
            .ignoresSafeArea(edges: [.top, .bottom])
            .sheet(isPresented: $isShowingRenameSheet) {
                RenameWorkspaceTitleSheet(
                    initialTitle: renameTitleDraft,
                    onCancel: {
                        isShowingRenameSheet = false
                    },
                    onSave: { newTitle in
                        state.renameCurrentProject(title: newTitle) { id, title in
                            guard let delegate = navigationDelegate else {
                                throw WorkspaceNavigationError.delegateUnavailable
                            }
                            return try delegate.workspaceDidRenameProject(id: id, title: title)
                        }
                        isShowingRenameSheet = false
                    }
                )
            }
            .sheet(isPresented: $isShowingDeletedHistorySheet) {
                DeletedObjectHistorySheet(state: state)
            }
            .confirmationDialog(
                "删除关联对象？",
                isPresented: Binding(
                    get: { state.pendingDependencyDeletion != nil },
                    set: { isPresented in
                        if !isPresented {
                            state.cancelPendingDependencyDeletion()
                        }
                    }
                ),
                titleVisibility: .visible,
                presenting: state.pendingDependencyDeletion
            ) { context in
                Button("仅删除所选对象", role: .destructive) {
                    state.confirmPendingDependencyDeletion(strategy: .unlink)
                }
                Button("删除所选及相关对象", role: .destructive) {
                    state.confirmPendingDependencyDeletion(strategy: .deleteAffected)
                }
                Button("取消", role: .cancel) {
                    state.cancelPendingDependencyDeletion()
                }
            } message: { context in
                if context.selectedIDs.count == 1 {
                    Text("该对象被 \(context.affectedIDs.count) 个动态对象引用。请选择如何处理相关对象。")
                } else {
                    Text("所选对象被 \(context.affectedIDs.count) 个动态对象引用。请选择如何处理相关对象。")
                }
            }
            .onChange(of: state.isKeyboardPresented) { _, visible in
                print("[CanvasFrame] keyboardVisible=\(visible) canvasSize=\(proxy.size)")
            }
            .onChange(of: state.isObjectPanelPresented) { _, isVisible in
                if !isVisible {
                    state.isObjectPanelFullscreen = false
                }
            }
            .onAppear {
                state.updateCanvasPixelSize(proxy.size)
                state.updateCompactHeightLayout(metrics.isCompactKeyboardLayout)
            }
            .onChange(of: proxy.size) { _, newSize in
                state.updateCanvasPixelSize(newSize)
                state.updateCompactHeightLayout(metrics.isCompactKeyboardLayout)
            }
            .onChange(of: metrics.isCompactKeyboardLayout) { _, isCompact in
                state.updateCompactHeightLayout(isCompact)
            }
        }
    }

    @ViewBuilder
    private func objectPanelFullscreenLayer(
        size: CGSize,
        metrics: WorkspaceLayoutMetrics
    ) -> some View {
        Color.black.opacity(colorSchemeAwareFullscreenBackdropOpacity)
            .ignoresSafeArea()
            .allowsHitTesting(false)

        AlgebraObjectPanelView(
            state: state,
            onRequestDeleteObjects: { ids in
                requestDeleteObjects(ids)
            },
            onToggleFullscreen: {
                state.isObjectPanelFullscreen = false
            },
            isFullscreen: true
        )
        .frame(
            width: min(max(420, size.width - fullscreenPanelHorizontalInset * 2), fullscreenPanelMaxWidth(for: size)),
            height: min(max(320, size.height - fullscreenPanelVerticalInset * 2), fullscreenPanelMaxHeight(for: size)),
            alignment: .top
        )
        .padding(.top, max(metrics.toolbarTop + 44, fullscreenPanelVerticalInset))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .transition(.opacity.combined(with: .scale(scale: 0.985)))
    }

    private var colorSchemeAwareFullscreenBackdropOpacity: Double {
        0.18
    }

    private var fullscreenPanelHorizontalInset: CGFloat {
        24
    }

    private var fullscreenPanelVerticalInset: CGFloat {
        24
    }

    private func fullscreenPanelMaxWidth(for size: CGSize) -> CGFloat {
        min(1100, size.width - 32)
    }

    private func fullscreenPanelMaxHeight(for size: CGSize) -> CGFloat {
        max(360, size.height - 120)
    }

    private var canvasLayer: some View {
        configuration.moduleProvider.makeCanvasView(
            context: WorkspaceCanvasContext(
                canvasState: state.document.canvasState,
                spaceCameraState: state.document.spaceCameraState,
                spaceWorkPlane: state.activeSpaceWorkPlane,
                objects: state.document.objects,
                selectedObjectID: state.selectedObjectID,
                selectedObjectIDs: state.selectedObjectIDs,
                activeToolID: state.activeToolID,
                draftMathObject: state.draftMathObject,
                dispatch: state.dispatch
            )
        )
        .ignoresSafeArea()
    }

    private func handleToolAction(_ action: WorkspaceToolAction) {
        switch action {
        case .setActiveTool(let id):
            if id == "plane.slider" {
                state.createNextParameter()
                return
            }
            if id == "plane.function" {
                withAnimation(.snappy(duration: 0.20)) {
                    state.dispatch(.setActiveTool(id: id))
                }
                state.dispatch(.openInput(mode: .expression))
                return
            }
            withAnimation(.snappy(duration: 0.20)) {
                state.dispatch(.setActiveTool(id: id))
            }

        case .openInput(let mode):
            state.dispatch(.openInput(mode: mode))

        case .showInspector:
            state.dispatch(.setInspectorVisible(true))

        case .command(let command):
            state.dispatch(command)

        case .moduleSpecific(let id):
            // Tool actions only carry the module-specific identifier here; callers that
            // need payload data should dispatch the command directly.
            state.dispatch(.moduleSpecific(id: id, payload: ""))
        }
    }

    private func resolvedObjectPanelWidth(size: CGSize, metrics: WorkspaceLayoutMetrics) -> CGFloat {
        let bounds = objectPanelWidthBounds(size: size)
        let preferred = storedObjectPanelWidth > 0 ? CGFloat(storedObjectPanelWidth) : metrics.objectPanelWidth
        return min(bounds.max, max(bounds.min, preferred))
    }

    private func objectPanelWidthBounds(size: CGSize) -> (min: CGFloat, max: CGFloat) {
        #if os(macOS)
        let minWidth: CGFloat = 260
        let maxWidth = min(520, size.width * 0.35)
        #else
        let minWidth: CGFloat = 230
        let maxWidth = min(420, size.width * 0.40)
        #endif
        return (minWidth, max(minWidth, maxWidth))
    }

    private func resolvedObjectPanelHeight(size: CGSize, metrics: WorkspaceLayoutMetrics) -> CGFloat {
        let objects = state.document.objects.filter { $0.type != .parameterGroup }
        let contentHeight = AlgebraObjectPanelLayoutMetrics.contentHeight(for: objects)
        return min(
            max(AlgebraObjectPanelLayoutMetrics.minimumPanelHeight, contentHeight),
            metrics.objectPanelMaxHeight
        )
    }

    private func objectPanelResizeGesture(size: CGSize, metrics: WorkspaceLayoutMetrics) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .onChanged { value in
                if objectPanelDragStartWidth == nil {
                    objectPanelDragStartWidth = resolvedObjectPanelWidth(size: size, metrics: metrics)
                }
                let start = objectPanelDragStartWidth ?? metrics.objectPanelWidth
                let bounds = objectPanelWidthBounds(size: size)
                let next = min(bounds.max, max(bounds.min, start + value.translation.width))
                storedObjectPanelWidth = Double(next)
            }
            .onEnded { _ in
                objectPanelDragStartWidth = nil
            }
    }

    private func requestDeleteObjects(_ ids: Set<UUID>) {
        state.requestDeleteObjectsWithConfirmation(ids)
    }

    private var objectPanelToggleButton: some View {
        LiquidGlassIconButton(
            systemName: "sidebar.left",
            accessibilityLabel: state.isObjectPanelPresented ? "隐藏对象区" : "显示对象区"
        ) {
            withAnimation(.snappy(duration: 0.20)) {
                state.dispatch(.toggleObjectPanel)
            }
        }
        .overlay(alignment: .topTrailing) {
            if state.isObjectPanelPresented {
                Circle()
                    .fill(Color.blue.opacity(0.88))
                    .frame(width: 8, height: 8)
                    .offset(x: -4, y: 4)
            }
        }
    }
}

private enum WorkspaceInteractionLayer {
    public static let canvas: Double = 0
    public static let objects: Double = 10
    public static let controls: Double = 100
    public static let keyboard: Double = 110
    public static let toolbar: Double = 120
}

private enum WorkspaceControlHitbox {
    public static let circleButtonHalfSize: CGFloat = 22
    public static let toolbarHalfHeight: CGFloat = 24
    public static let resizeHandleHitWidth: CGFloat = 18
}

public enum WorkspaceObjectPanelHandleVisualMetrics {
    public static let idleOpacity: Double = 0
    public static let activeOpacity: Double = 1
}

private struct ObjectPanelResizeHandle: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovering = false
    @GestureState private var isDragging = false

    public var body: some View {
        Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
            .overlay(alignment: .center) {
                Capsule()
                    .fill(handleColor)
                    .frame(width: isHovering || isDragging ? 3 : 1.5)
                    .opacity(
                        isHovering || isDragging
                            ? WorkspaceObjectPanelHandleVisualMetrics.activeOpacity
                            : WorkspaceObjectPanelHandleVisualMetrics.idleOpacity
                    )
.padding(Edge.Set.vertical, 16)
                    .animation(.snappy(duration: 0.16), value: isHovering)
                    .animation(.snappy(duration: 0.16), value: isDragging)
            }
            #if os(macOS)
            .onHover { isHovering = $0 }
            #endif
            .gesture(DragGesture(minimumDistance: 1).updating($isDragging) { _, state, _ in
                state = true
            })
    }

    private var handleColor: Color {
        if isHovering || isDragging {
            return .blue.opacity(colorScheme == .dark ? 0.62 : 0.48)
        }
        return Color.primary.opacity(colorScheme == .dark ? 0.16 : 0.12)
    }
}

private struct DocumentMenuButton: View {
    public var title: String
    public var onGoHome: () -> Void
    public var onRename: () -> Void
    public var onShowDeletedHistory: () -> Void
    public var onUndo: () -> Void
    public var onRedo: () -> Void
    public var onRevertToOpenState: () -> Void
    public var canUndo: Bool
    public var canRedo: Bool
    public var canRevert: Bool
    #if DEBUG
    public var readOnlyFormulaDebugOverride: FormulaDisplayRuntimeState?
    public var effectiveReadOnlyFormulaBackend: FormulaRenderingBackend
    public var readOnlyFormulaDiagnostics: FormulaDisplayDiagnostics
    public var onUseProjectDefaultReadOnlyFormulaBackend: () -> Void
    public var onUseLegacyReadOnlyFormulaBackend: () -> Void
    public var onUseSwiftMathReadOnlyFormulaBackend: () -> Void
    #endif
    @State private var isShowingRevertConfirmation = false

    public var body: some View {
        Menu {
            Section {
                Text(title.isEmpty ? "未命名图表" : title)
                Text("已保存")
            }

            Button(action: onUndo) {
                Label("撤销", systemImage: "arrow.uturn.backward")
            }
            .disabled(!canUndo)

            Button(action: onRedo) {
                Label("重做", systemImage: "arrow.uturn.forward")
            }
            .disabled(!canRedo)

            #if DEBUG
            Divider()

            Section("Developer") {
                Text("只读公式后端：\(backendDebugLabel(effectiveReadOnlyFormulaBackend))")
                if let readOnlyFormulaDebugOverride {
                    Text("当前来源：Override (\(backendDebugLabel(readOnlyFormulaDebugOverride.backend)))")
                } else {
                    Text("当前来源：Project Default")
                }
                Text("Fallbacks: \(readOnlyFormulaDiagnostics.fallbackCount)")
                Text("Last Fallback: \(fallbackReasonDebugLabel(readOnlyFormulaDiagnostics.lastFallbackReason))")

                Menu("Read-only Formula Backend") {
                    Button(action: onUseProjectDefaultReadOnlyFormulaBackend) {
                        menuSelectionLabel(
                            title: "Project Default",
                            selected: readOnlyFormulaDebugOverride == nil
                        )
                    }
                    Button(action: onUseLegacyReadOnlyFormulaBackend) {
                        menuSelectionLabel(
                            title: "Legacy",
                            selected: effectiveReadOnlyFormulaBackend == .legacy && readOnlyFormulaDebugOverride != nil
                        )
                    }
                    Button(action: onUseSwiftMathReadOnlyFormulaBackend) {
                        menuSelectionLabel(
                            title: "SwiftMath",
                            selected: effectiveReadOnlyFormulaBackend == .swiftMath
                        )
                    }
                }
            }
            #endif

            Button(role: .destructive) {
                isShowingRevertConfirmation = true
            } label: {
                Label("恢复到打开时状态", systemImage: "arrow.counterclockwise")
            }
            .disabled(!canRevert)

            Divider()

            Button(action: onGoHome) {
                Label("返回首页", systemImage: "house")
            }
            Button(action: onRename) {
                Label("重命名", systemImage: "pencil")
            }
            Button(action: onShowDeletedHistory) {
                Label("恢复已删除对象", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
            }
            Button {
            } label: {
                Label("保存副本", systemImage: "doc.on.doc")
            }
            Button {
            } label: {
                Label("导出", systemImage: "square.and.arrow.down")
            }
            Button {
            } label: {
                Label("分享", systemImage: "square.and.arrow.up")
            }
            Button {
            } label: {
                Label("文件信息", systemImage: "info.circle")
            }
        } label: {
            Image(systemName: "folder")
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .labelStyle(.iconOnly)
        .accessibilityLabel("工作区文档菜单")
        .accessibilityIdentifier("workspace-document-menu")
        .confirmationDialog(
            "恢复到打开时状态？",
            isPresented: $isShowingRevertConfirmation,
            titleVisibility: .visible
        ) {
            Button("恢复", role: .destructive, action: onRevertToOpenState)
            Button("取消", role: .cancel) {}
        } message: {
            Text("这会放弃本次打开后的修改。你可以再撤销此操作。")
        }
        .background {
            if #available(iOS 26.0, macOS 16.0, *) {
                Color.clear
                    .glassEffect(.regular.interactive(), in: .circle)
            } else {
                Circle()
                    .fill(.ultraThinMaterial)
            }
        }
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }

    #if DEBUG
    private func backendDebugLabel(_ backend: FormulaRenderingBackend) -> String {
        switch backend {
        case .legacy:
            return "Legacy"
        case .swiftMath:
            return "SwiftMath"
        }
    }

    private func fallbackReasonDebugLabel(_ reason: FormulaDisplayFallbackReason?) -> String {
        guard let reason else { return "none" }
        return reason.rawValue
    }

    @ViewBuilder
    private func menuSelectionLabel(title: String, selected: Bool) -> some View {
        if selected {
            Label(title, systemImage: "checkmark")
        } else {
            Text(title)
        }
    }
    #endif
}

private struct RenameWorkspaceTitleSheet: View {
    @Environment(\.dismiss) private var dismiss

    public let initialTitle: String
    public let onCancel: () -> Void
    public let onSave: (String) -> Void

    @State private var titleDraft: String
    @FocusState private var isTitleFocused: Bool

    public init(
        initialTitle: String,
        onCancel: @escaping () -> Void,
        onSave: @escaping (String) -> Void
    ) {
        self.initialTitle = initialTitle
        self.onCancel = onCancel
        self.onSave = onSave
        _titleDraft = State(initialValue: initialTitle)
    }

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("输入新的项目名称")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)

                TextField("项目名称", text: $titleDraft)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .autocorrectionDisabled(true)
                    .focused($isTitleFocused)
                    .submitLabel(SubmitLabel.done)
                    .onSubmit(save)
.padding(Edge.Set.horizontal, 12)
.padding(Edge.Set.vertical, 10)
                    .background(Material.thinMaterial)
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

private struct WorkspaceInlineInputDock: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var state: WorkspaceState

    public var body: some View {
        VStack(spacing: WorkspaceInlineInputVisualMetrics.previewKeyboardSpacing) {
            editorBar

            if WorkspaceInlineInputVisualMetrics.showsParameterSuggestionsInDock,
               state.isInputPresented && !state.inputDraftAnalysis.suggestions.isEmpty {
                parameterSuggestionView
            }

            if state.isInputPresented && state.isKeyboardPresented {
                keyboardPanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(WorkspaceInteractionLayer.keyboard)
            }
        }
        .contentShape(Rectangle())
        .allowsHitTesting(true)
        .animation(.snappy(duration: 0.20), value: state.isInputPresented)
        .animation(.snappy(duration: 0.20), value: state.isKeyboardPresented)
    }

    private var editorBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Spacer(minLength: 0)

                FormulaBarIconButton(systemName: "keyboard") {
                    print("[KeyboardIcon] tapped")
                    state.dispatch(.toggleKeyboard)
                }
                FormulaBarIconButton(systemName: "xmark") {
                    state.cancelInputDraft()
                }
                FormulaBarIconButton(title: "↵") {
                    state.dispatch(.submitInput)
                }
                .overlay(alignment: .topTrailing) {
                    if shouldShowInputStatusBadge {
                        Image(systemName: inputStatusBadgeSymbol)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(inputStatusBadgeColor)
                            .padding(4)
                            .background(.ultraThinMaterial, in: Circle())
                            .offset(x: 4, y: -4)
                            .accessibilityHidden(true)
                    }
                }
            }

            if state.canShowQuickStartExpressionTemplates {
                quickStartTemplateStrip
            }

            if state.isInputPresented {
                FormulaEditingDisplayView(
                    inputState: state.formulaInputState,
                    isFocused: state.focus == .formulaEditor,
                    configuration: state.effectiveReadOnlyFormulaDisplayConfiguration,
                    onTapCursor: { cursor in
                        state.focusEditor(at: cursor)
                        if !state.isInputPresented {
                            state.dispatch(.openInput(mode: .expression))
                        }
                    },
                    onKeyboardAction: { action in
                        state.handleKeyboardAction(action)
                    }
                )
                .allowsHitTesting(
                    state.isInputPresented || WorkspaceInlineInputVisualMetrics.formulaContentHitTestingWhenClosed
                )
                .frame(minHeight: FormulaEditingDisplayView.minimumLayoutHeight, alignment: .topLeading)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                FormulaDisplayPreviewView(
                    inputState: state.formulaInputState,
                    configuration: state.effectiveReadOnlyFormulaDisplayConfiguration,
                    surface: .editorPreview
                )
                    .allowsHitTesting(false)
                    .frame(minHeight: FormulaEditingDisplayView.minimumLayoutHeight, alignment: .topLeading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if WorkspaceInlineInputVisualMetrics.showsCommitErrorBanner,
               state.isInputPresented, let commitErrorMessage = state.commitErrorMessage {
                commitErrorBanner(message: commitErrorMessage)
            }

            if WorkspaceInlineInputVisualMetrics.showsPiecewiseAppendRowControl,
               state.canAppendPiecewiseRow {
                HStack {
                    Button {
                        state.appendPiecewiseRow()
                    } label: {
                        Label("添加一行", systemImage: "plus.circle")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                }
            }
        }
.padding(Edge.Set.vertical, 6)
.padding(Edge.Set.horizontal, 12)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onTapGesture {
            guard !state.isInputPresented else { return }
            print("[FormulaEditorBar] tapped")
            state.startFormulaEditing(openKeyboard: true)
        }
        .transaction { tx in
            tx.animation = nil
        }
        .background {
            GlassPanel(cornerRadius: 18, theme: inputBarTheme, contentPadding: 0) {
                Color.clear
            }
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.06 : 0.10),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 10)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .allowsHitTesting(false)
            }
            .allowsHitTesting(false)
        }
    }

    private var quickStartTemplateStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("快速开始")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(QuickStartExpressionTemplate.allCases) { template in
                        Button {
                            state.startQuickStartExpressionTemplate(template)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: template.systemImageName)
                                        .font(.system(size: 11, weight: .semibold))
                                    Text(template.title)
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(inputChromeTint)

                                Text(template.previewText)
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(.secondary.opacity(0.92))
                                    .lineLimit(1)

                                Text(template.helperText)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.secondary.opacity(0.82))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 9)
                            .frame(width: 168, alignment: .leading)
                            .background {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.white.opacity(colorScheme == .dark ? 0.04 : 0.24))
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.06), lineWidth: 0.8)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 1)
            }
        }
    }

    @ViewBuilder
    private func commitErrorBanner(message: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.red.opacity(0.92))
                .padding(.top, 1)

            Text(message)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.red.opacity(colorScheme == .dark ? 0.95 : 0.88))
                .lineLimit(2)
                .truncationMode(.tail)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.red.opacity(colorScheme == .dark ? 0.10 : 0.08))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.red.opacity(colorScheme == .dark ? 0.16 : 0.12), lineWidth: 0.8)
        }
    }

    private var keyboardPanel: some View {
        VStack(spacing: 10) {
            MathInputKeyboardView { action in
                state.handleKeyboardAction(action)
            }
        }
        .padding(10)
        .frame(minHeight: WorkspaceInlineInputVisualMetrics.keyboardPanelMinHeight)
        .background(Color.clear)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var parameterSuggestionView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("未定义参数")
                .font(.system(size: 13, weight: .bold))

            FlowLayout(spacing: 8) {
                ForEach(state.inputDraftAnalysis.suggestions) { suggestion in
                    Button {
                        state.createParameter(named: suggestion.symbol)
                    } label: {
                        Label("滑动条 \(suggestion.symbol)", systemImage: "plus")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .buttonStyle(.plain)
.padding(Edge.Set.vertical, 7)
.padding(Edge.Set.horizontal, 10)
                    .background(.thinMaterial, in: Capsule())
                }
            }

            if !state.inputDraftAnalysis.restrictions.isEmpty {
                Text(state.inputDraftAnalysis.restrictions.joined(separator: "，"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            GlassPanel(cornerRadius: 18, theme: .sidePanel, contentPadding: 0) {
                Color.clear
            }
        }
    }
}

private struct FormulaBarIconButton: View {
    public static let hitSize: CGFloat = WorkspaceInlineInputVisualMetrics.iconButtonHitSize

    public var systemName: String? = nil
    public var title: String? = nil
    public var action: () -> Void

    public var body: some View {
        Button(action: action) {
            ZStack {
                if let systemName {
                    Image(systemName: systemName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary.opacity(0.84))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let title {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.primary.opacity(0.84))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(width: Self.hitSize, height: Self.hitSize)
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(FormulaBarIconButtonStyle())
        .transaction { tx in
            tx.animation = nil
        }
    }
}

private struct FormulaBarIconButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                Circle()
                    .fill(Color.white.opacity(configuration.isPressed ? 0.12 : 0.0))
                    .allowsHitTesting(false)
            }
            .transaction { tx in
                tx.animation = nil
            }
    }
}

private extension WorkspaceInlineInputDock {
    public var inputBarTheme: WorkspaceTheme {
        var theme = WorkspaceTheme.sidePanel
        theme.lightPanelOpacity = WorkspaceInlineInputVisualMetrics.previewPanelLightOpacity
        theme.darkPanelOpacity = WorkspaceInlineInputVisualMetrics.previewPanelDarkOpacity
        theme.lightStrokeOpacity = WorkspaceInlineInputVisualMetrics.previewPanelLightStrokeOpacity
        theme.darkStrokeOpacity = WorkspaceInlineInputVisualMetrics.previewPanelDarkStrokeOpacity
        theme.lightShadowOpacity = 0.04
        theme.darkShadowOpacity = 0.06
        return theme
    }

    public var editorBarBackgroundFill: Color {
        colorScheme == .dark ? Color.black.opacity(0.10) : Color.white.opacity(0.16)
    }

    public var editorBarStrokeOpacity: Double {
        state.isKeyboardPresented ? 0.10 : 0.14
    }

    public var draftDiagnosticPresentation: FormulaDiagnosticPresentation? {
        var diagnostics = state.draftMathObject?.diagnostics ?? []
        if let parseError = state.draftMathObject?.parseError,
           !parseError.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            diagnostics.append(
                FormulaPlotDiagnostic(
                    stage: .parse,
                    severity: .error,
                    code: "parse_error",
                    message: parseError,
                    source: .draft
                )
            )
        }
        return FormulaDiagnosticPresenter.topPresentation(from: diagnostics, includeInfo: false)
    }

    public func diagnosticIconName(for severity: FormulaPlotDiagnosticSeverity) -> String {
        switch severity {
        case .error:
            return "xmark.octagon.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        }
    }

    public func diagnosticColor(for severity: FormulaPlotDiagnosticSeverity) -> Color {
        switch severity {
        case .error:
            return .red.opacity(0.9)
        case .warning:
            return .orange.opacity(0.9)
        case .info:
            return .secondary
        }
    }

    var inputChromeTint: Color {
        colorScheme == .dark ? Color.white.opacity(0.95) : Color.black.opacity(0.88)
    }

    var shouldShowInputStatusBadge: Bool {
        state.commitErrorMessage != nil || draftDiagnosticPresentation != nil
    }

    var inputStatusBadgeSymbol: String {
        if state.commitErrorMessage != nil {
            return "exclamationmark.triangle.fill"
        }
        return diagnosticIconName(for: draftDiagnosticPresentation?.severity ?? .info)
    }

    var inputStatusBadgeColor: Color {
        if state.commitErrorMessage != nil {
            return Color.red.opacity(0.92)
        }
        return diagnosticColor(for: draftDiagnosticPresentation?.severity ?? .info)
    }
}

public enum WorkspaceInlineInputVisualMetrics {
    public static let iconButtonHitSize: CGFloat = 36
    public static let previewKeyboardSpacing: CGFloat = 16
    public static let keyboardPanelMinHeight: CGFloat = 216
    public static let previewPanelDarkOpacity: Double = 0.08
    public static let previewPanelLightOpacity: Double = 0.10
    public static let previewPanelDarkStrokeOpacity: Double = 0.04
    public static let previewPanelLightStrokeOpacity: Double = 0.05
    public static let usesStrongKeyboardMaterialBackplate = false
    public static let keyboardPanelUsesVisualClip = false
    public static let formulaContentHitTestingWhenClosed = false
    public static let showsParameterSuggestionsInDock = false
    public static let showsCommitErrorBanner = false
    public static let showsPiecewiseAppendRowControl = false
}

private struct FlowLayout<Content: View>: View {
    public var spacing: CGFloat
    @ViewBuilder var content: Content

    public var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: spacing) {
                content
            }
            VStack(alignment: .leading, spacing: spacing) {
                content
            }
        }
    }
}
