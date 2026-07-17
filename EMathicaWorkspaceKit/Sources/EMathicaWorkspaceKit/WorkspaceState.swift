import EMathicaMathInputCore
import EMathicaDocumentKit
import Foundation
import Observation
import CoreGraphics
import EMathicaMathCore

@MainActor
@Observable
final class WorkspaceState {
    public var module: CalculatorModuleType
    private let moduleProvider: WorkspaceModuleProviding
    public var document: EMathicaDocument

    /// Exposed for views that need to format semantic metadata.
    public var semanticIntentAdapter: (any SemanticIntentAdapterProtocol)? {
        moduleProvider.semanticIntentAdapter
    }

    public var geometryPresentationResolver: any GeometryPresentationResolverProtocol {
        moduleProvider.geometryPresentationResolver ?? DefaultGeometryPresentationResolver()
    }

    public var activeToolID: String

    public var selectedObjectIDs: Set<UUID>

    public var isInputPresented: Bool
    public var inputMode: WorkspaceInputMode
    public var inputText: String
    public var formulaInputState: FormulaInputState

    public var isInspectorPresented: Bool
    public var isKeyboardPresented: Bool
    public var isCompactHeightLayout: Bool
    public var isObjectPanelPresented: Bool
    public var isObjectPanelFullscreen: Bool
    public var focus: WorkspaceFocus
    public var inputDraftAnalysis: ParameterSuggestionAnalysis
    public var draftMathObject: DraftMathObject?
    public var formulaEditSession: FormulaEditSession?
    public var editorUIState: EditorUIState
    public var canvasPixelSize: CGSize
    public var isCanvasInteracting: Bool
    public var activeSpaceWorkPlane: SpaceWorkPlane
    public var isQuickStartExpressionTemplatesEnabled: Bool

    public var lastErrorMessage: String?
    public var lastToastMessage: String?
    public var commitErrorMessage: String?

    private let inputController = InputController()
    private var draftPreviewTask: Task<Void, Never>?
    private var draftSourceExpressionOverride: String?
    private var preferFreshInputSessionOnNextOpen: Bool
    private var playingSliderDirections: [UUID: Double]
    private var sliderPlaybackTask: Task<Void, Never>?
    private var sessionHistory: WorkspaceSessionHistory
    private var isApplyingHistorySnapshot: Bool
    private var pendingCanvasUndoBefore: EMathicaDocument?
    private var pendingObjectDragUndoBefore: EMathicaDocument?
    private var draggingObjectIDForUndo: UUID?
    private var pendingDeletionHistoryContext: DeletedObjectContext?
    public var pendingDependencyDeletion: DependencyDeletionDialogContext?
    private var mathKeyboardCompactVisibilityState: MathKeyboardCompactVisibilityState

    public init(module: CalculatorModuleType, document: EMathicaDocument, toolGroups: [WorkspaceToolGroup], moduleProvider: WorkspaceModuleProviding) {
        self.module = module
        self.moduleProvider = moduleProvider
        self.document = document

        self.activeToolID = toolGroups.first?.tools.first?.id ?? ""

        if let firstSelectable = document.objects.first(where: { $0.type != .parameterGroup }) {
            self.selectedObjectIDs = [firstSelectable.id]
        } else {
            self.selectedObjectIDs = []
        }

        self.isInputPresented = false
        self.inputMode = .expression
        self.inputText = ""
        self.formulaInputState = FormulaInputState()

        self.isInspectorPresented = false
        self.isKeyboardPresented = false
        self.isCompactHeightLayout = false
        self.isObjectPanelPresented = !moduleProvider.startsWithObjectPanelCollapsed
        self.isObjectPanelFullscreen = false
        self.focus = .none
        self.inputDraftAnalysis = .empty
        self.draftMathObject = nil
        self.formulaEditSession = nil
        self.editorUIState = .default
        self.canvasPixelSize = .zero
        self.isCanvasInteracting = false
        self.activeSpaceWorkPlane = .xy
        self.isQuickStartExpressionTemplatesEnabled = false

        self.lastErrorMessage = nil
        self.lastToastMessage = nil
        self.commitErrorMessage = nil
        self.draftSourceExpressionOverride = nil
        self.preferFreshInputSessionOnNextOpen = false
        self.playingSliderDirections = [:]
        self.sliderPlaybackTask = nil
        self.sessionHistory = WorkspaceSessionHistory(openBaseline: document, maxDepth: 100)
        self.isApplyingHistorySnapshot = false
        self.pendingCanvasUndoBefore = nil
        self.pendingObjectDragUndoBefore = nil
        self.draggingObjectIDForUndo = nil
        self.pendingDeletionHistoryContext = nil
        self.pendingDependencyDeletion = nil
        self.mathKeyboardCompactVisibilityState = .automatic
    }

    public var selectedObjectID: UUID? {
        selectedObjectIDs.first
    }

    public var canAppendPiecewiseRow: Bool {
        currentPiecewiseTemplateContext() != nil
    }

    public var canUndo: Bool {
        sessionHistory.canUndo
    }

    public var canRedo: Bool {
        sessionHistory.canRedo
    }

    public var canRevertToOpenState: Bool {
        document != sessionHistory.openBaseline
    }

    public var allowsWorkspaceUndoShortcuts: Bool {
        formulaEditSession == nil
    }

    public var undoDepth: Int {
        sessionHistory.undoStack.count
    }

    public var redoDepth: Int {
        sessionHistory.redoStack.count
    }

    public func dispatch(_ command: WorkspaceCommand) {
        switch command {
        case .updateInputText(let text):
            clearCommitError()
            let incoming = text
            let current = formulaInputState.source
            draftSourceExpressionOverride = incoming
            if formulaEditSession == nil,
               !incoming.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                // Explicit prefill (e.g. object panel "编辑表达式") should not be overridden
                // by the post-commit fresh-session guard.
                preferFreshInputSessionOnNextOpen = false
            }
            if incoming == current {
                inputText = incoming
            } else if let singleInsertion = singleCharacterInsertion(from: current, to: incoming, at: formulaInputState.cursorIndex) {
                handleKeyboardAction(.insertCharacter(singleInsertion))
            } else if let singleDeletion = singleCharacterDeletion(from: current, to: incoming, at: formulaInputState.cursorIndex) {
                for _ in 0..<singleDeletion {
                    handleKeyboardAction(.deleteBackward)
                }
            } else {
                // Keep AST as source-of-truth during an active structured edit session.
                // Non-incremental text replacement can desync cursor paths and "swallow" input.
                if formulaEditSession == nil {
                    formulaInputState.editorState.root = MathNode.sequence(incoming.map { MathNode.character(String($0)) })
                    formulaInputState.editorState.cursor = EditorCursor(path: [], offset: incoming.count)
                } else {
                    let rebuiltRoot = SimpleMathParser().parseSource(incoming)
                        ?? MathNode.sequence(incoming.map { MathNode.character(String($0)) })
                    formulaInputState.editorState.root = rebuiltRoot
                    let rootCount = MathEditorTree.sequence(at: [], in: rebuiltRoot)?.count ?? 0
                    formulaInputState.editorState.cursor = EditorCursor(path: [], offset: rootCount)
                }
            }
            formulaInputState.syncDerivedStrings(context: currentLoweringContext())
            inputDraftAnalysis = ParameterSuggestionAnalyzer.analyze(
                formulaInputState.source,
                existingObjects: document.objects
            )
            if formulaEditSession != nil {
                formulaEditSession?.editorState = formulaInputState.editorState
                formulaEditSession?.isDirty = true
            }
            updateDraftPreviewNow()
            return

        case .openInput(let mode):
            inputMode = mode
            startFormulaEditing(openKeyboard: true)
            return

        case .dismissInput:
            cancelFormulaEditing()
            return

        case .toggleKeyboard:
            toggleMathKeyboardFromFormulaBar()
            return

        case .setKeyboardVisible(let isVisible):
            isKeyboardPresented = isVisible
            editorUIState.isMathKeyboardVisible = isVisible
            if isCompactHeightLayout {
                mathKeyboardCompactVisibilityState = .userToggled
            } else {
                mathKeyboardCompactVisibilityState = .automatic
            }
            editorUIState.focus = .formulaEditor
            focus = .formulaEditor
            return

        case .setInspectorVisible(let isVisible):
            isInspectorPresented = isVisible
            return

        case .toggleObjectPanel:
            isObjectPanelPresented.toggle()
            return

        case .setObjectPanelVisible(let isVisible):
            isObjectPanelPresented = isVisible
            return

        case .setCanvasInteracting(let isInteracting):
            guard isCanvasInteracting != isInteracting else { return }
            if isInteracting {
                pendingCanvasUndoBefore = document
            } else {
                finishCanvasUndoTransactionIfNeeded()
            }
            isCanvasInteracting = isInteracting
            // Interacting/settled transitions should trigger re-sampling quality changes for semantic preview.
            if formulaEditSession != nil || isInputPresented || !formulaInputState.source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                scheduleDraftPreviewUpdate()
            }
            return

        case .setSpaceCameraState(let cameraState):
            performRecordedDocumentMutation(
                title: undoTitle(for: command),
                shouldRecord: shouldRecordUndo(for: command)
            ) {
                document.apply(.updateSpaceCameraState(cameraState))
            }
            return

        case .setSpaceWorkPlane(let workPlane):
            activeSpaceWorkPlane = workPlane
            return

        case .setObjectDragging(let id, let isDragging):
            handleObjectDraggingState(id: id, isDragging: isDragging)
            return

        case .undo:
            performUndo()
            return

        case .redo:
            performRedo()
            return

        case .revertToOpenState:
            revertToOpenBaseline()
            return

        case .deleteSelectedObjects:
            requestDeleteObjectsWithConfirmation(selectedObjectIDs)
            return

        case .restoreDeletedObject(let recordID):
            restoreDeletedObject(recordID: recordID)
            return

        case .submitInput:
            commitFormulaEditing()
            return

        default:
            break
        }

        let handler = moduleProvider.commandHandler
        let context = ModuleCommandContext(document: document, selectedObjectIDs: selectedObjectIDs, inputText: inputText)
        let output = handler.handle(command, context: context)
        let isSubmittingInput: Bool
        if case .submitInput = command {
            isSubmittingInput = true
        } else {
            isSubmittingInput = false
        }
        let didCreateInputObject = isSubmittingInput && !output.documentCommands.isEmpty

        if !output.documentCommands.isEmpty {
            let recordUndo = shouldRecordUndo(for: command)
            performRecordedDocumentMutation(
                title: undoTitle(for: command),
                shouldRecord: recordUndo
            ) {
                let deletedRecords = deletedObjectRecords(
                    from: output.documentCommands,
                    in: document,
                    context: deletionHistoryContext(for: command)
                )
                let changedPointIDs = changedGeometrySourceIDs(
                    from: output.documentCommands,
                    in: document
                )
                let removedSourceIDs = removedObjectIDs(
                    from: output.documentCommands,
                    in: document
                )
                document.apply(output.documentCommands)
                if !deletedRecords.isEmpty {
                    document.apply(.appendDeletedObjectRecords(deletedRecords))
                }
                if !removedSourceIDs.isEmpty {
                    applyGeometryDependencyCleanup(removedSourceIDs: removedSourceIDs)
                }
                if !changedPointIDs.isEmpty {
                    applyGeometryDependencyRecompute(changedSourceIDs: changedPointIDs)
                }
                if didCreateInputObject {
                    attachStructuredInputMetadataToSelectedObject()
                }
            }
        }

        apply(output.effects)

        if didCreateInputObject {
            clearInputDraft()
        }
    }

    private func changedGeometrySourceIDs(
        from commands: [DocumentCommand],
        in document: EMathicaDocument
    ) -> Set<UUID> {
        var ids: Set<UUID> = []
        for command in commands {
            switch command {
            case .updateObject(let id, let patch):
                guard let object = document.objects.first(where: { $0.id == id }) else { continue }
                if patch.position != nil, object.type == .point {
                    ids.insert(id)
                }
                if patch.points != nil, isLineLike(object.type) || object.type == .circle {
                    ids.insert(id)
                }
            case .deleteObject(let id):
                if let object = document.objects.first(where: { $0.id == id }),
                   (object.type == .point || isLineLike(object.type) || object.type == .circle) {
                    ids.insert(id)
                }
            case .deleteObjects(let deletedIDs):
                let deletedSet = Set(deletedIDs)
                for object in document.objects where deletedSet.contains(object.id) {
                    guard object.type == .point || isLineLike(object.type) || object.type == .circle else { continue }
                    ids.insert(object.id)
                }
            case .addObject,
                 .renameObject,
                 .setObjectVisibility,
                 .reorderObject,
                 .updateCanvasState,
                 .updateSpaceCameraState,
                 .updateMetadata,
                 .appendDeletedObjectRecords,
                 .removeDeletedObjectRecord:
                continue
            }
        }
        return ids
    }

    private func isLineLike(_ type: MathObjectType) -> Bool {
        switch type {
        case .segment, .line, .ray, .arc:
            return true
        case .circle, .function, .point, .parameter, .parameterGroup, .arc:
            return false
        }
    }

    private func applyGeometryDependencyRecompute(changedSourceIDs: Set<UUID>) {
        guard let service = moduleProvider.geometryDependencyService else { return }
        let patches = service.dependencyPatches(
            objects: document.objects,
            changedSourceIDs: changedSourceIDs
        )
        guard !patches.isEmpty else { return }
        let commands = patches.map { id, patch in
            DocumentCommand.updateObject(id: id, patch: patch)
        }
        document.apply(commands)
    }

    private func removedObjectIDs(
        from commands: [DocumentCommand],
        in document: EMathicaDocument
    ) -> Set<UUID> {
        var ids: Set<UUID> = []
        for command in commands {
            switch command {
            case .deleteObject(let id):
                if document.objects.contains(where: { $0.id == id }) {
                    ids.insert(id)
                }
            case .deleteObjects(let deletedIDs):
                let set = Set(deletedIDs)
                for object in document.objects where set.contains(object.id) {
                    ids.insert(object.id)
                }
            case .addObject,
                 .updateObject,
                 .renameObject,
                 .setObjectVisibility,
                 .reorderObject,
                 .updateCanvasState,
                 .updateSpaceCameraState,
                 .updateMetadata,
                 .appendDeletedObjectRecords,
                 .removeDeletedObjectRecord:
                continue
            }
        }
        return ids
    }

    private func deletedObjectRecords(
        from commands: [DocumentCommand],
        in document: EMathicaDocument,
        context: DeletedObjectContext?
    ) -> [DeletedObjectRecord] {
        let objectsByID = Dictionary(uniqueKeysWithValues: document.objects.map { ($0.id, $0) })
        var records: [DeletedObjectRecord] = []
        for command in commands {
            switch command {
            case .deleteObject(let id):
                guard let object = objectsByID[id] else { continue }
                records.append(
                    DeletedObjectRecord(
                        object: object,
                        context: context
                    )
                )
            case .deleteObjects(let ids):
                for id in ids {
                    guard let object = objectsByID[id] else { continue }
                    records.append(
                        DeletedObjectRecord(
                            object: object,
                            context: context
                        )
                    )
                }
            case .addObject,
                 .updateObject,
                 .renameObject,
                 .setObjectVisibility,
                 .reorderObject,
                 .updateCanvasState,
                 .updateSpaceCameraState,
                 .updateMetadata,
                 .appendDeletedObjectRecords,
                 .removeDeletedObjectRecord:
                continue
            }
        }
        return records
    }

    private func deletionHistoryContext(for command: WorkspaceCommand) -> DeletedObjectContext? {
        switch command {
        case .deleteObject, .deleteObjects:
            if let pending = pendingDeletionHistoryContext {
                return pending
            }
            return .userDelete
        default:
            return nil
        }
    }

    private func applyGeometryDependencyCleanup(removedSourceIDs: Set<UUID>) {
        guard let service = moduleProvider.geometryDependencyService else { return }
        let patches = service.dependencyCleanupPatchesForRemovedSources(
            objects: document.objects,
            removedSourceIDs: removedSourceIDs
        )
        guard !patches.isEmpty else { return }
        let commands = patches.map { id, patch in
            DocumentCommand.updateObject(id: id, patch: patch)
        }
        document.apply(commands)
    }

    public func insertEmptyExpression() {
        dispatch(.openInput(mode: .expression))
    }

    public func directlyAffectedDerivedObjectIDs(for candidateSourceIDs: Set<UUID>) -> Set<UUID> {
        moduleProvider.geometryDependencyService?.directlyAffectedDerivedObjectIDs(
            objects: document.objects,
            candidateSourceIDs: candidateSourceIDs
        ) ?? []
    }

    public func downstreamAffectedDerivedObjectIDs(for candidateSourceIDs: Set<UUID>) -> Set<UUID> {
        moduleProvider.geometryDependencyService?.downstreamAffectedDerivedObjectIDs(
            objects: document.objects,
            candidateSourceIDs: candidateSourceIDs
        ) ?? []
    }

    public func requestDeleteObjectsWithConfirmation(_ ids: Set<UUID>) {
        guard !ids.isEmpty else { return }
        let affected = directlyAffectedDerivedObjectIDs(for: ids)
        guard !affected.isEmpty else {
            performDeleteObjects(ids)
            return
        }
        pendingDependencyDeletion = DependencyDeletionDialogContext(
            selectedIDs: ids,
            affectedIDs: affected
        )
    }

    public func cancelPendingDependencyDeletion() {
        pendingDependencyDeletion = nil
    }

    public func confirmPendingDependencyDeletion(strategy: DependencyDeletionStrategy) {
        guard let context = pendingDependencyDeletion else { return }
        let deleteIDs: Set<UUID>
        let historyContext: DeletedObjectContext
        switch strategy {
        case .unlink:
            deleteIDs = context.selectedIDs
            historyContext = .userDelete
        case .deleteAffected:
            let directlyAffected = directlyAffectedDerivedObjectIDs(for: context.selectedIDs)
            deleteIDs = context.selectedIDs.union(directlyAffected)
            historyContext = .deleteAffected
        }
        pendingDependencyDeletion = nil
        pendingDeletionHistoryContext = historyContext
        performDeleteObjects(deleteIDs)
    }

    private func performDeleteObjects(_ ids: Set<UUID>) {
        guard !ids.isEmpty else { return }
        defer { pendingDeletionHistoryContext = nil }
        if ids.count == 1, let id = ids.first {
            dispatch(.deleteObject(id: id))
        } else {
            dispatch(.deleteObjects(ids: Array(ids)))
        }
    }

    private func shouldRecordUndo(for command: WorkspaceCommand) -> Bool {
        switch command {
        case .setActiveTool,
             .selectObject,
             .clearSelection,
             .updateInputText,
             .dismissInput,
             .openInput,
             .toggleKeyboard,
             .setKeyboardVisible,
             .setInspectorVisible,
             .toggleObjectPanel,
             .setObjectPanelVisible,
             .setObjectDragging,
             .setCanvasInteracting,
             .undo,
             .redo,
             .revertToOpenState:
            return false
        case .setCanvasViewport:
            return !isCanvasInteracting
        case .setSpaceCameraState:
            return !isCanvasInteracting
        case .setSpaceWorkPlane:
            return false
        case .createPoint,
             .createFunction,
             .createSegment,
             .createLine,
             .createRay,
             .deleteObject,
             .deleteObjects,
             .deleteSelectedObjects,
             .duplicateSelectedObjects,
             .renameObject,
             .toggleObjectVisibility,
             .updateObjectStyle,
             .updateObjectPosition,
             .convertObjectToStatic,
             .restoreDeletedObject,
             .submitInput,
             .moduleSpecific:
            if case .updateObjectPosition = command {
                return draggingObjectIDForUndo == nil
            }
            return true
        }
    }

    private func undoTitle(for command: WorkspaceCommand) -> String {
        switch command {
        case .createPoint, .createFunction, .createSegment, .createLine, .createRay, .moduleSpecific:
            return "创建对象"
        case .deleteObject, .deleteObjects, .deleteSelectedObjects:
            return "删除对象"
        case .duplicateSelectedObjects:
            return "复制对象"
        case .renameObject:
            return "重命名对象"
        case .toggleObjectVisibility:
            return "切换对象可见性"
        case .updateObjectStyle:
            return "修改对象样式"
        case .updateObjectPosition:
            return "移动对象"
        case .convertObjectToStatic:
            return "转为独立对象"
        case .restoreDeletedObject:
            return "恢复删除对象"
        case .setCanvasViewport:
            return "调整画布视图"
        case .setSpaceCameraState:
            return "调整空间视角"
        case .setSpaceWorkPlane:
            return "切换工作平面"
        case .submitInput:
            return "提交表达式"
        case .setActiveTool,
             .selectObject,
             .clearSelection,
             .updateInputText,
             .dismissInput,
             .openInput,
             .toggleKeyboard,
             .setKeyboardVisible,
             .setInspectorVisible,
             .toggleObjectPanel,
             .setObjectPanelVisible,
             .setObjectDragging,
             .setCanvasInteracting,
             .undo,
             .redo,
             .revertToOpenState:
            return "编辑"
        }
    }

    private func performRecordedDocumentMutation(
        title: String,
        shouldRecord: Bool,
        _ mutation: () -> Void
    ) {
        let before = document
        mutation()
        let after = document
        guard shouldRecord, !isApplyingHistorySnapshot, before != after else { return }
        sessionHistory.push(
            WorkspaceUndoStep(
                before: before,
                after: after,
                title: title,
                timestamp: Date()
            )
        )
    }

    private func performUndo() {
        guard !isApplyingHistorySnapshot,
              let step = sessionHistory.undoStack.popLast() else { return }
        isApplyingHistorySnapshot = true
        document = step.before
        isApplyingHistorySnapshot = false
        sessionHistory.redoStack.append(step)
    }

    private func performRedo() {
        guard !isApplyingHistorySnapshot,
              let step = sessionHistory.redoStack.popLast() else { return }
        isApplyingHistorySnapshot = true
        document = step.after
        isApplyingHistorySnapshot = false
        sessionHistory.undoStack.append(step)
    }

    private func revertToOpenBaseline() {
        guard !isApplyingHistorySnapshot else { return }
        let before = document
        let after = sessionHistory.openBaseline
        guard before != after else { return }
        isApplyingHistorySnapshot = true
        document = after
        isApplyingHistorySnapshot = false
        sessionHistory.push(
            WorkspaceUndoStep(
                before: before,
                after: after,
                title: "恢复到打开时状态",
                timestamp: Date()
            )
        )
    }

    private func finishCanvasUndoTransactionIfNeeded() {
        guard let before = pendingCanvasUndoBefore else { return }
        pendingCanvasUndoBefore = nil
        let after = document
        guard !isApplyingHistorySnapshot, before != after else { return }
        sessionHistory.push(
            WorkspaceUndoStep(
                before: before,
                after: after,
                title: "调整画布视图",
                timestamp: Date()
            )
        )
    }

    private func handleObjectDraggingState(id: UUID?, isDragging: Bool) {
        if isDragging {
            guard let id else { return }
            if draggingObjectIDForUndo == id { return }
            draggingObjectIDForUndo = id
            pendingObjectDragUndoBefore = document
            return
        }
        finishObjectDragUndoTransactionIfNeeded()
    }

    private func finishObjectDragUndoTransactionIfNeeded() {
        defer {
            pendingObjectDragUndoBefore = nil
            draggingObjectIDForUndo = nil
        }
        guard let before = pendingObjectDragUndoBefore else { return }
        let after = document
        guard !isApplyingHistorySnapshot, before != after else { return }
        sessionHistory.push(
            WorkspaceUndoStep(
                before: before,
                after: after,
                title: "移动对象",
                timestamp: Date()
            )
        )
    }

    private func restoreDeletedObject(recordID: UUID) {
        guard let history = document.deletedObjectHistory,
              let record = history.first(where: { $0.id == recordID }) else {
            return
        }
        let targetID: UUID = document.objects.contains(where: { $0.id == record.object.id }) ? UUID() : record.object.id
        let source = record.object
        let restored = MathObject(
            id: targetID,
            name: source.name,
            type: source.type,
            expression: source.expression,
            position: source.position,
            points: source.points,
            parameterValue: source.parameterValue,
            parameterMin: source.parameterMin,
            parameterMax: source.parameterMax,
            sliderSettings: source.sliderSettings,
            geometryDefinition: source.geometryDefinition,
            geometryDependency: nil,
            geometryDefinitionStatus: nil,
            style: source.style,
            isVisible: source.isVisible
        )
        performRecordedDocumentMutation(title: "恢复删除对象", shouldRecord: true) {
            document.apply(.addObject(restored))
            document.apply(.removeDeletedObjectRecord(recordID: recordID))
        }
        if document.objects.contains(where: { $0.id == targetID }) {
            selectedObjectIDs = [targetID]
        }
    }

    public func handleKeyboardAction(_ action: KeyboardAction) {
        clearCommitError()
        if formulaEditSession == nil {
            startFormulaEditing(openKeyboard: false)
        }
        if case .submit = action {
            commitFormulaEditing()
            return
        }
        if case .enter = action {
            commitFormulaEditing()
            return
        }
        if case .cancel = action {
            cancelFormulaEditing()
            return
        }
        guard var session = formulaEditSession else { return }
        draftSourceExpressionOverride = inputText
        ensureValidCursor(in: &session.editorState)
        print("[StructuredInput] action=\(action)")
        print("[StructuredInput] before.cursor.path=\(session.editorState.cursor.path) offset=\(session.editorState.cursor.offset)")
        print("[StructuredInput] before.ast=\n\(session.editorState.root.debugTree)")
        inputController.handle(action, state: &session.editorState)
        ensureValidCursor(in: &session.editorState)
        print("[StructuredInput] after.cursor.path=\(session.editorState.cursor.path) offset=\(session.editorState.cursor.offset)")
        print("[StructuredInput] after.ast=\n\(session.editorState.root.debugTree)")
        session.isDirty = true
        formulaEditSession = session
        formulaInputState.editorState = session.editorState
        formulaInputState.syncDerivedStrings(context: currentLoweringContext())
        syncInputTextFromFormulaState()
        formulaEditSession?.editorState = formulaInputState.editorState
        formulaEditSession?.isDirty = true
        isInputPresented = true
        formulaInputState.isEditing = true
        editorUIState.focus = .formulaEditor
        focus = .formulaEditor
        updateDraftPreviewNow()
    }

    public func updateFormulaSelection(_ range: Range<Int>) {
        formulaInputState.selectedRange = range
        formulaInputState.cursorIndex = range.upperBound
        let projection = CursorProjectionResult(
            source: formulaInputState.source,
            cursorIndex: formulaInputState.cursorIndex,
            cursorStops: formulaInputState.sourceCursorStops
        )
        formulaInputState.editorState.cursor = SourceRangeToCursorMapper.map(range: range, in: projection)
    }

    public func focusEditor(at cursor: EditorCursor) {
        if formulaEditSession == nil {
            startFormulaEditing(openKeyboard: false)
        }
        formulaInputState.editorState.cursor = cursor
        formulaInputState.editorState.selection = nil
        ensureValidCursor(in: &formulaInputState.editorState)
        formulaEditSession?.editorState.cursor = formulaInputState.editorState.cursor
        formulaEditSession?.editorState.selection = nil
        formulaInputState.syncDerivedStrings(context: currentLoweringContext())
        syncInputTextFromFormulaState()
        editorUIState.focus = .formulaEditor
        focus = .formulaEditor
    }

    public func beginEditingObjectExpression(_ objectID: UUID, openKeyboard: Bool = true) {
        guard let object = document.objects.first(where: { $0.id == objectID }),
              moduleProvider.canEditExpression(for: object) else {
            return
        }
        selectedObjectIDs = [objectID]
        loadExpressionForEditing(object, openKeyboard: openKeyboard)
    }

    public func appendPiecewiseRow() {
        if formulaEditSession == nil {
            startFormulaEditing(openKeyboard: false)
        }
        guard var session = formulaEditSession,
              let context = currentPiecewiseTemplateContext(in: session.editorState) else {
            return
        }

        let newRowIndex = context.rows
        var updated = context.template
        updated.kind = .piecewise(rows: context.rows + 1)
        updated.fields.append(
            TemplateField(id: FieldID.rowExpression(newRowIndex), node: MathNode.sequence([MathNode.placeholder]))
        )
        updated.fields.append(
            TemplateField(id: FieldID.rowCondition(newRowIndex), node: MathNode.sequence([MathNode.placeholder]))
        )

        MathEditorTree.setNode(.template(updated), at: context.templatePath, in: &session.editorState.root)
        session.editorState.cursor = EditorCursor(
            path: context.templatePath + [.templateField(FieldID.rowExpression(newRowIndex))],
            offset: 0
        )
        session.isDirty = true

        formulaEditSession = session
        formulaInputState.editorState = session.editorState
        formulaInputState.syncDerivedStrings(context: currentLoweringContext())
        syncInputTextFromFormulaState()
        formulaInputState.isEditing = true
        isInputPresented = true
        focus = .formulaEditor
        editorUIState.focus = .formulaEditor
        scheduleDraftPreviewUpdate()
    }

    public func clearInputDraft() {
        formulaInputState = FormulaInputState(
            editorState: EditorState(),
            source: "",
            displayLatex: "",
            computeExpression: "",
            cursorIndex: 0,
            currentPlaceholderIndex: nil,
            selectedRange: 0..<0,
            sourceCursorStops: [],
            isEditing: false
        )
        inputText = ""
        inputDraftAnalysis = .empty
        lastErrorMessage = nil
        commitErrorMessage = nil
        focus = .none
        editorUIState.focus = .none
        clearDraftPreview()
        mathKeyboardCompactVisibilityState = .automatic
    }

    public func cancelInputDraft() {
        clearInputDraft()
        dispatch(.dismissInput)
    }

    public func createNextParameter() {
        let namingService = moduleProvider.objectNamingService ?? DefaultWorkspaceObjectNamingService()
        let name = namingService.nextParameterName(existingObjects: document.objects)
        createParameter(named: name)
    }

    public func createParameter(named name: String, initialValue: Double? = nil) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !document.objects.contains(where: { $0.type == .parameter && $0.name == trimmed }) else { return }

        let value = initialValue ?? defaultParameterValue(for: trimmed)
        let settings = SliderSettings.default
        let object = MathObject(
            name: trimmed,
            type: .parameter,
            expression: MathExpression(displayText: "\(trimmed) = \(formatParameterValue(value, precision: settings.precision))"),
            parameterValue: value,
            parameterMin: settings.min,
            parameterMax: settings.max,
            sliderSettings: settings,
            style: MathStyle(colorToken: "indigo")
        )
        performRecordedDocumentMutation(title: "创建参数", shouldRecord: true) {
            document.apply(.addObject(object))
        }
        selectedObjectIDs = [object.id]
    }

    public func updateParameter(id: UUID, value: Double, recordUndo: Bool = true) {
        guard let object = document.objects.first(where: { $0.id == id && $0.type == .parameter }) else { return }
        let quantized = quantizedParameterValue(value, object: object)
        let precision = object.sliderSettings?.precision ?? 2
        let display = "\(object.name) = \(formatParameterValue(quantized, precision: precision))"
        var expression = object.expression
        expression.displayText = display
        performRecordedDocumentMutation(title: "调整参数", shouldRecord: recordUndo) {
            document.apply(.updateObject(id: id, patch: DocumentObjectPatch(expression: expression, parameterValue: quantized)))
        }
        if formulaEditSession != nil || !formulaInputState.source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            scheduleDraftPreviewUpdate()
        }
    }

    public func isSliderPlaying(id: UUID) -> Bool {
        playingSliderDirections[id] != nil
    }

    public func toggleSliderPlayback(id: UUID) {
        guard let object = document.objects.first(where: { $0.id == id && $0.type == .parameter }) else { return }
        if isSliderPlaying(id: id) {
            playingSliderDirections[id] = nil
            stopSliderPlaybackLoopIfIdle()
            return
        }
        let mode = object.sliderSettings?.playbackMode ?? .increasing
        let direction: Double
        switch mode {
        case .increasing, .pingPong:
            direction = 1
        case .decreasing:
            direction = -1
        }
        playingSliderDirections[id] = direction
        startSliderPlaybackLoopIfNeeded()
    }

    public func updateSliderSettings(id: UUID, settings: SliderSettings) {
        updateSliderSettings(id: id, settings: settings, value: nil)
    }

    public func updateSliderSettings(id: UUID, settings: SliderSettings, value: Double?) {
        guard let object = document.objects.first(where: { $0.id == id && $0.type == .parameter }) else { return }
        let normalized = normalizedSliderSettings(settings)

        let current = value ?? object.parameterValue ?? 0
        let clampedValue = min(max(current, normalized.min), normalized.max)
        let quantized = quantizedParameterValue(clampedValue, settings: normalized)
        let display = "\(object.name) = \(formatParameterValue(quantized, precision: normalized.precision))"
        var expression = object.expression
        expression.displayText = display

        performRecordedDocumentMutation(title: "更新参数设置", shouldRecord: true) {
            document.apply(
                .updateObject(
                    id: id,
                    patch: DocumentObjectPatch(
                        expression: expression,
                        parameterValue: quantized,
                        parameterMin: normalized.min,
                        parameterMax: normalized.max,
                        sliderSettings: normalized
                    )
                )
            )
        }
        if formulaEditSession != nil || !formulaInputState.source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            scheduleDraftPreviewUpdate()
        }
    }

    public func updateObjectStyle(id: UUID, style: MathStyle) {
        let sanitized = style.sanitized()
        dispatch(
            .updateObjectStyle(
                id: id,
                colorToken: sanitized.colorToken,
                opacity: sanitized.opacity,
                fillOpacity: sanitized.fillOpacity,
                lineWidth: sanitized.lineWidth,
                pointSize: sanitized.pointSize,
                lineStyle: sanitized.lineStyle
            )
        )
    }

    public func updateObjectStyle(id: UUID, transform: (MathStyle) -> MathStyle) {
        guard let object = document.objects.first(where: { $0.id == id }) else { return }
        updateObjectStyle(id: id, style: transform(object.style))
    }

    public func updateCanvas(showGrid: Bool? = nil, showAxis: Bool? = nil) {
        var canvas = document.canvasState
        if let showGrid {
            canvas.showGrid = showGrid
        }
        if let showAxis {
            canvas.showAxis = showAxis
        }
        dispatch(.setCanvasViewport(canvas))
    }

    private func apply(_ effects: [WorkspaceEffect]) {
        for effect in effects {
            switch effect {
            case .selectObject(let id):
                selectedObjectIDs = [id]
                if moduleProvider.autoRevealsInspectorOnSelection {
                    isInspectorPresented = true
                }
                if formulaEditSession == nil {
                    loadSelectedObjectIntoFormulaBarIfNeeded()
                }

            case .selectObjects(let ids):
                selectedObjectIDs = ids
                if moduleProvider.autoRevealsInspectorOnSelection, !ids.isEmpty {
                    isInspectorPresented = true
                }
                if formulaEditSession == nil {
                    loadSelectedObjectIntoFormulaBarIfNeeded()
                }

            case .clearSelection:
                selectedObjectIDs.removeAll()
                if moduleProvider.autoHidesInspectorOnSelectionClear {
                    isInspectorPresented = false
                }
                if formulaEditSession == nil {
                    formulaInputState = FormulaInputState()
                    syncInputTextFromFormulaState()
                }

            case .setActiveTool(let id):
                activeToolID = id

            case .openInput(let mode):
                inputMode = mode
                startFormulaEditing(openKeyboard: false)

            case .closeInput:
                cancelFormulaEditing()

            case .focusInput:
                startFormulaEditing(openKeyboard: false)

            case .showKeyboard(let isVisible):
                isKeyboardPresented = isVisible
                editorUIState.isMathKeyboardVisible = isVisible

            case .showInspector(let isVisible):
                isInspectorPresented = isVisible

            case .showError(let message):
                lastErrorMessage = message

            case .showToast(let message):
                lastToastMessage = message
            }
        }
    }

    private func defaultParameterValue(for name: String) -> Double {
        switch name {
        case "n":
            return 2
        default:
            return 1
        }
    }

    private func syncInputTextFromFormulaState() {
        inputText = formulaInputState.source
        inputDraftAnalysis = ParameterSuggestionAnalyzer.analyze(
            inputText,
            existingObjects: document.objects
        )
    }

    private func editableExpression(for object: MathObject) -> String {
        if let source = object.expression.sourceExpression, !source.isEmpty {
            return source
        }
        if let raw = object.expression.rawInput, !raw.isEmpty {
            return raw
        }
        if let originalLatex = object.expression.originalLatex, !originalLatex.isEmpty {
            return originalLatex
        }
        return object.expression.displayText
    }

    private func loadSelectedObjectIntoFormulaBarIfNeeded() {
        guard let selected = selectedObjectID,
              let object = document.objects.first(where: { $0.id == selected }) else {
            return
        }
        guard moduleProvider.canEditExpression(for: object) else { return }
        formulaInputState = inputState(from: object, isEditing: false)
        syncInputTextFromFormulaState()
    }

    private func clearDraftPreview() {
        draftPreviewTask?.cancel()
        draftPreviewTask = nil
        draftMathObject = nil
        draftSourceExpressionOverride = nil
    }

    private func scheduleDraftPreviewUpdate() {
        let source = formulaInputState.source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isInputPresented || formulaEditSession != nil || !source.isEmpty else { return }
        draftPreviewTask?.cancel()
        draftPreviewTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 110_000_000)
            guard !Task.isCancelled else { return }
            self?.updateDraftPreviewNow()
        }
    }

    private func updateDraftPreviewNow() {
        let source = formulaInputState.source.trimmingCharacters(in: .whitespacesAndNewlines)
        if source.isEmpty {
            draftMathObject = nil
            return
        }
        #if DEBUG
        let modeDescription: String = {
            guard let session = formulaEditSession else { return "none" }
            switch session.mode {
            case .createNew:
                return "create"
            case .editExisting(let objectID):
                return "edit(\(objectID.uuidString.prefix(8)))"
            }
        }()
        print("[PlanePreview][WorkspaceState] mode=\(modeDescription) isInputPresented=\(isInputPresented) source=\"\(formulaInputState.source)\" compute=\"\(formulaInputState.computeExpression)\"")
        #endif
        draftMathObject = moduleProvider.makeDraftMathObject(
            formulaInputState: formulaInputState,
            document: document,
            previous: draftMathObject,
            canvasPixelSize: canvasPixelSize,
            canvasInteracting: isCanvasInteracting
        )
        if let override = draftSourceExpressionOverride, !override.isEmpty {
            draftMathObject?.sourceExpression = override
        }
        #if DEBUG
        if let draftMathObject {
            print("[PlanePreview][WorkspaceState] draft!=nil samples=\(draftMathObject.previewSamples.count) lastValid=\(draftMathObject.lastValidPreviewSamples.count) parseError=\(draftMathObject.parseError ?? "nil")")
        } else {
            print("[PlanePreview][WorkspaceState] draft=nil")
        }
        #endif
    }

    public func updateCanvasPixelSize(_ size: CGSize) {
        guard size.width.isFinite, size.height.isFinite else { return }
        guard size.width > 0, size.height > 0 else { return }
        canvasPixelSize = size
    }

    private func singleCharacterInsertion(from old: String, to new: String, at cursor: Int) -> String? {
        guard new.count == old.count + 1 else { return nil }
        let safeCursor = max(0, min(cursor, old.count))
        let oldPrefix = String(old.prefix(safeCursor))
        let oldSuffix = String(old.dropFirst(safeCursor))
        guard new.hasPrefix(oldPrefix), new.hasSuffix(oldSuffix) else { return nil }
        let insertedStart = new.index(new.startIndex, offsetBy: safeCursor)
        let insertedEnd = new.index(after: insertedStart)
        return String(new[insertedStart..<insertedEnd])
    }

    private func singleCharacterDeletion(from old: String, to new: String, at cursor: Int) -> Int? {
        guard old.count == new.count + 1 else { return nil }
        guard cursor > 0 else { return nil }
        let deleteIndex = cursor - 1
        let oldPrefix = String(old.prefix(deleteIndex))
        let oldSuffix = String(old.dropFirst(deleteIndex + 1))
        guard new == oldPrefix + oldSuffix else { return nil }
        return 1
    }

    private func applySemanticIntentMetadata(to expression: inout MathExpression) {
        guard let adapter = moduleProvider.semanticIntentAdapter else { return }
        let intent = formulaInputState.semanticState.graphClassification?.intent
        expression.semanticGraphKind = adapter.semanticGraphKind(from: intent)
        expression.semanticParameterSymbol = adapter.parameterSymbol(from: intent)
        expression.semanticParameterRange = adapter.parameterRange(from: intent)
    }

    private func attachStructuredInputMetadataToSelectedObject() {
        guard let objectID = selectedObjectID,
              let object = document.objects.first(where: { $0.id == objectID }) else { return }

        var expression = object.expression
        expression.rawInput = formulaInputState.source
        expression.sourceExpression = formulaInputState.source
        expression.computeExpression = formulaInputState.computeExpression
        applySemanticIntentMetadata(to: &expression)
        if let data = try? JSONEncoder().encode(formulaInputState.editorState),
           let json = String(data: data, encoding: .utf8) {
            expression.editorASTData = json
        }
        if !formulaInputState.displayLatex.isEmpty {
            expression.originalLatex = formulaInputState.displayLatex
        }
        document.apply(.updateObject(id: objectID, patch: DocumentObjectPatch(expression: expression)))
    }

    private func submitEditingObject(objectID: UUID) {
        let text = formulaInputState.source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            commitErrorMessage = "请输入内容"
            return
        }
        let canonicalInput = moduleProvider.inputCanonicalizer.canonicalize(
            source: text,
            semanticState: formulaInputState.semanticState
        )
        let parsed = moduleProvider.buildExpression(
            from: canonicalInput,
            fallbackToExplicitY: shouldFallbackToExplicitYForCommit()
        )
        let updatedExpression: MathExpression
        switch parsed {
        case .success(let expression):
            updatedExpression = expression
        case .failure(let error):
            commitErrorMessage = error.message
            return
        }
        guard let object = document.objects.first(where: { $0.id == objectID }) else { return }
        let namingService = moduleProvider.objectNamingService ?? DefaultWorkspaceObjectNamingService()
        var updated = updatedExpression
        updated.rawInput = formulaInputState.source
        updated.sourceExpression = formulaInputState.source
        updated.computeExpression = formulaInputState.computeExpression
        applySemanticIntentMetadata(to: &updated)
        if let data = try? JSONEncoder().encode(formulaInputState.editorState),
           let json = String(data: data, encoding: .utf8) {
            updated.editorASTData = json
        }
        if !formulaInputState.displayLatex.isEmpty {
            updated.originalLatex = formulaInputState.displayLatex
        }
        var patch = DocumentObjectPatch(expression: updated)
        if object.type == .function,
           let resolvedName = namingService.resolvedExplicitFunctionName(
            from: updatedExpression.algebraAnalysis?.relation,
            existingObjects: document.objects,
            excluding: objectID
           ) {
            patch.name = resolvedName
        }
        performRecordedDocumentMutation(title: "编辑表达式", shouldRecord: true) {
            document.apply(.updateObject(id: objectID, patch: patch))
        }
        selectedObjectIDs = [objectID]
        clearInputDraft()
        formulaEditSession = nil
        isInputPresented = false
        isKeyboardPresented = false
        editorUIState.isMathKeyboardVisible = false
        formulaInputState.isEditing = false
        focus = .none
        editorUIState.focus = .none
    }

    private func normalizedEditorRoot(_ root: MathNode) -> MathNode {
        if case .sequence = root {
            return root
        }
        return MathNode.sequence([root])
    }

    private func editorState(forSource source: String) -> EditorState {
        let parsedRoot = normalizedEditorRoot(
            SimpleMathParser().parseSource(source) ?? MathNode.sequence(source.map { MathNode.character(String($0)) })
        )
        let sequenceCount: Int
        if case MathNode.sequence(let nodes) = parsedRoot {
            sequenceCount = nodes.count
        } else {
            sequenceCount = 1
        }
        var editor = EditorState(root: parsedRoot, cursor: .init(path: [], offset: sequenceCount))
        ensureValidCursor(in: &editor)
        return editor
    }

    private func inputState(from object: MathObject, isEditing: Bool) -> FormulaInputState {
        if let data = object.expression.editorASTData?.data(using: .utf8),
           var state = try? JSONDecoder().decode(EditorState.self, from: data) {
            state.root = normalizedEditorRoot(state.root)
            ensureValidCursor(in: &state)
            return FormulaInputState(editorState: state, isEditing: isEditing)
        }
        let source = editableExpression(for: object)
        return FormulaInputState(editorState: editorState(forSource: source), isEditing: isEditing)
    }

    private func loadExpressionForEditing(_ object: MathObject, openKeyboard: Bool) {
        var state = inputState(from: object, isEditing: true).editorState
        state.root = normalizedEditorRoot(state.root)
        ensureValidCursor(in: &state)
        makeSession(
            mode: .editExisting(objectID: object.id),
            state: state,
            original: state,
            rawSourceExpression: editableExpression(for: object)
        )
        formulaInputState.isEditing = true
        formulaEditSession?.editorState = formulaInputState.editorState
        formulaEditSession?.isDirty = false
        if openKeyboard {
            isKeyboardPresented = true
            editorUIState.isMathKeyboardVisible = true
        }
        scheduleDraftPreviewUpdate()
    }

    private func makeSession(
        mode: FormulaEditMode,
        state: EditorState,
        original: EditorState?,
        rawSourceExpression: String? = nil
    ) {
        clearDraftPreview()
        clearCommitError()
        draftSourceExpressionOverride = rawSourceExpression
        formulaEditSession = FormulaEditSession(
            mode: mode,
            editorState: state,
            originalEditorState: original,
            isDirty: false
        )
        formulaInputState.editorState = state
        formulaInputState.isEditing = true
        formulaInputState.syncDerivedStrings(context: currentLoweringContext())
        syncInputTextFromFormulaState()
        isInputPresented = true
        focus = .formulaEditor
        editorUIState.focus = .formulaEditor
        updateDraftPreviewNow()
    }

    public func startFormulaEditing(openKeyboard: Bool = true) {
        if let session = formulaEditSession {
            isInputPresented = true
            focus = .formulaEditor
            editorUIState.focus = .formulaEditor
            if shouldShowMathKeyboardByDefault(openKeyboard: openKeyboard) {
                isKeyboardPresented = true
                editorUIState.isMathKeyboardVisible = true
            }
            formulaInputState.editorState = session.editorState
            formulaInputState.syncDerivedStrings(context: currentLoweringContext())
            syncInputTextFromFormulaState()
            scheduleDraftPreviewUpdate()
            return
        }

        if preferFreshInputSessionOnNextOpen {
            preferFreshInputSessionOnNextOpen = false
            makeSession(mode: .createNew, state: EditorState(), original: nil)
        } else {
            if let selected = selectedObjectID,
               let object = document.objects.first(where: { $0.id == selected }),
               moduleProvider.canEditExpression(for: object) {
                loadExpressionForEditing(object, openKeyboard: false)
            } else {
                makeSession(mode: .createNew, state: EditorState(), original: nil)
            }
        }

        if shouldShowMathKeyboardByDefault(openKeyboard: openKeyboard) {
            isKeyboardPresented = true
            editorUIState.isMathKeyboardVisible = true
        }
        scheduleDraftPreviewUpdate()
    }

    public func toggleMathKeyboardFromFormulaBar() {
        if formulaEditSession == nil {
            startFormulaEditing(openKeyboard: true)
            return
        }
        isKeyboardPresented.toggle()
        editorUIState.isMathKeyboardVisible = isKeyboardPresented
        if isCompactHeightLayout {
            mathKeyboardCompactVisibilityState = .userToggled
        }
        focus = .formulaEditor
        editorUIState.focus = .formulaEditor
    }

    public func cancelFormulaEditing() {
        formulaEditSession = nil
        isInputPresented = false
        isKeyboardPresented = false
        editorUIState.isMathKeyboardVisible = false
        formulaInputState.isEditing = false
        focus = .none
        editorUIState.focus = .none
        clearCommitError()
        clearDraftPreview()
        mathKeyboardCompactVisibilityState = .automatic
        if let selected = selectedObjectID,
           let object = document.objects.first(where: { $0.id == selected }),
           moduleProvider.canEditExpression(for: object) {
            formulaInputState = inputState(from: object, isEditing: false)
            syncInputTextFromFormulaState()
        } else {
            clearInputDraft()
        }
    }

    public func updateCompactHeightLayout(_ isCompact: Bool) {
        guard isCompactHeightLayout != isCompact else { return }
        isCompactHeightLayout = isCompact

        if isCompact {
            guard isKeyboardPresented else {
                if mathKeyboardCompactVisibilityState != .userToggled {
                    mathKeyboardCompactVisibilityState = .automatic
                }
                return
            }

            if mathKeyboardCompactVisibilityState != .userToggled {
                isKeyboardPresented = false
                editorUIState.isMathKeyboardVisible = false
                mathKeyboardCompactVisibilityState = .autoCollapsed
            }
            return
        }

        if mathKeyboardCompactVisibilityState == .autoCollapsed,
           isInputPresented || formulaEditSession != nil {
            isKeyboardPresented = true
            editorUIState.isMathKeyboardVisible = true
        }
        mathKeyboardCompactVisibilityState = .automatic
    }

    public var inputSessionStatusLabel: String? {
        guard isInputPresented || formulaEditSession != nil else { return nil }

        guard let session = formulaEditSession else {
            return "新建函数"
        }

        switch session.mode {
        case .createNew:
            return "新建函数"
        case .editExisting(let objectID):
            if let object = document.objects.first(where: { $0.id == objectID }) {
                let trimmedName = object.name.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedName.isEmpty {
                    return "编辑 \(trimmedName)"
                }
            }
            return "编辑中"
        }
    }

    public var inputSessionModeBadgeText: String? {
        guard isInputPresented || formulaEditSession != nil else { return nil }

        switch formulaEditSession?.mode {
        case .createNew, .none:
            return "新建"
        case .editExisting:
            return "编辑"
        }
    }

    public var inputSessionPrimaryTitle: String {
        switch formulaEditSession?.mode {
        case .createNew, .none:
            return "输入函数或表达式"
        case .editExisting(let objectID):
            if let object = document.objects.first(where: { $0.id == objectID }) {
                let trimmedName = object.name.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedName.isEmpty {
                    return "编辑 \(trimmedName)"
                }
            }
            return "编辑表达式"
        }
    }

    public var inputSessionSecondaryTitle: String {
        let isEditingExisting: Bool
        if case .editExisting = formulaEditSession?.mode {
            isEditingExisting = true
        } else {
            isEditingExisting = false
        }

        if !isInputPresented && formulaEditSession == nil {
            return "轻点这里输入函数、参数曲线或极坐标表达式"
        }

        if isEditingExisting {
            return "修改当前对象的数学定义，提交后会直接更新画布"
        }

        return "支持函数、参数曲线、极坐标等二维表达式入口"
    }

    public var canShowQuickStartExpressionTemplates: Bool {
        guard isQuickStartExpressionTemplatesEnabled else { return false }
        guard module == .plane else { return false }
        if case .editExisting = formulaEditSession?.mode {
            return false
        }
        return true
    }

    public func startQuickStartExpressionTemplate(
        _ template: QuickStartExpressionTemplate,
        openKeyboard: Bool = true
    ) {
        preferFreshInputSessionOnNextOpen = false
        let editorState = editorState(forSource: template.previewText)
        makeSession(
            mode: .createNew,
            state: editorState,
            original: nil,
            rawSourceExpression: template.previewText
        )
        formulaEditSession?.isDirty = !template.previewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        inputDraftAnalysis = ParameterSuggestionAnalyzer.analyze(
            formulaInputState.source,
            existingObjects: document.objects
        )
        if shouldShowMathKeyboardByDefault(openKeyboard: openKeyboard) {
            isKeyboardPresented = true
            editorUIState.isMathKeyboardVisible = true
        }
        scheduleDraftPreviewUpdate()
    }

    public func commitFormulaEditing() {
        guard let session = formulaEditSession else { return }
        let trimmed = formulaInputState.source.trimmingCharacters(in: .whitespacesAndNewlines)

        switch session.mode {
        case .createNew:
            guard !trimmed.isEmpty else {
                cancelFormulaEditing()
                return
            }
            let canonicalInput = moduleProvider.inputCanonicalizer.canonicalize(
                source: trimmed,
                semanticState: formulaInputState.semanticState
            )
            let parsed = moduleProvider.buildExpression(
                from: canonicalInput,
                fallbackToExplicitY: shouldFallbackToExplicitYForCommit()
            )
            let builtExpression: MathExpression
            switch parsed {
            case .success(let result):
                builtExpression = result
            case .failure(let error):
                commitErrorMessage = error.message
                return
            }
            let namingService = moduleProvider.objectNamingService ?? DefaultWorkspaceObjectNamingService()
            let name = namingService.resolvedExplicitFunctionName(
                from: builtExpression.algebraAnalysis?.relation,
                existingObjects: document.objects
            ) ?? namingService.nextFunctionName(existingObjects: document.objects)
            var expression = builtExpression
            expression.rawInput = formulaInputState.source
            expression.sourceExpression = formulaInputState.source
            expression.computeExpression = formulaInputState.computeExpression
            applySemanticIntentMetadata(to: &expression)
            if let data = try? JSONEncoder().encode(formulaInputState.editorState),
               let json = String(data: data, encoding: .utf8) {
                expression.editorASTData = json
            }
            if !formulaInputState.displayLatex.isEmpty {
                expression.originalLatex = formulaInputState.displayLatex
            }
            let object = committedObject(
                expression: expression,
                fallbackName: name,
                namingService: namingService
            )
            performRecordedDocumentMutation(title: "提交表达式", shouldRecord: true) {
                document.apply(.addObject(object))
            }
            selectedObjectIDs = [object.id]

        case .editExisting(let objectID):
            submitEditingObject(objectID: objectID)
            if commitErrorMessage != nil { return }
        }

        formulaEditSession = nil
        // A successful submit ends the current edit session. Keep selection, but
        // the next input focus should start a fresh formula rather than silently
        // re-enter editing mode for the just-committed object.
        preferFreshInputSessionOnNextOpen = true
        clearInputDraft()
        isInputPresented = false
        isKeyboardPresented = false
        editorUIState.isMathKeyboardVisible = false
        formulaInputState.isEditing = false
        focus = .none
        editorUIState.focus = .none
    }

    private func clearCommitError() {
        commitErrorMessage = nil
    }

    private func committedObject(
        expression: MathExpression,
        fallbackName: String,
        namingService: any WorkspaceObjectNamingServiceProtocol
    ) -> MathObject {
        if let pointObject = committedPointObjectIfPossible(
            expression: expression,
            fallbackName: fallbackName,
            namingService: namingService
        ) {
            return pointObject
        }

        return MathObject(
            name: fallbackName,
            type: .function,
            expression: expression,
            style: MathStyle(colorToken: "blue")
        )
    }

    private func committedPointObjectIfPossible(
        expression: MathExpression,
        fallbackName: String,
        namingService: any WorkspaceObjectNamingServiceProtocol
    ) -> MathObject? {
        guard case .point(let xExpr, let yExpr)? = formulaInputState.semanticState.graphClassification?.intent else {
            return nil
        }

        let evaluator = ExprEvaluator()
        guard case .value(let x) = evaluator.evaluate(xExpr),
              case .value(let y) = evaluator.evaluate(yExpr),
              x.isFinite,
              y.isFinite else {
            return nil
        }

        let name = committedPointName(fallbackName: fallbackName, namingService: namingService)
        let point = WorldPoint(x: x, y: y)
        return MathObject(
            name: name,
            type: .point,
            expression: expression,
            position: point,
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "blue")
        )
    }

    private func committedPointName(
        fallbackName: String,
        namingService: any WorkspaceObjectNamingServiceProtocol
    ) -> String {
        let trimmed = formulaInputState.source.trimmingCharacters(in: .whitespacesAndNewlines)
        if let equalsIndex = trimmed.firstIndex(of: "=") {
            let candidate = trimmed[..<equalsIndex].trimmingCharacters(in: .whitespacesAndNewlines)
            if !candidate.isEmpty {
                return candidate
            }
        }
        if !fallbackName.isEmpty {
            return fallbackName
        }
        return namingService.nextPointName(existingObjects: document.objects)
    }

    private func shouldShowMathKeyboardByDefault(openKeyboard: Bool) -> Bool {
        guard openKeyboard else { return false }
        return !isCompactHeightLayout
    }

    public func renameCurrentProject(
        title: String,
        performRename: (UUID, String) throws -> RecentProject
    ) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            lastErrorMessage = "项目名称不能为空"
            return
        }
        do {
            _ = try performRename(document.metadata.id, trimmed)
            document.metadata.title = trimmed
            document.metadata.updatedAt = Date()
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = "重命名失败：\(error.localizedDescription)"
        }
    }

    private func formatParameterValue(_ value: Double, precision: Int = 2) -> String {
        let digits = max(0, min(precision, 8))
        let factor = pow(10.0, Double(digits))
        let rounded = (value * factor).rounded() / factor
        if digits == 0 || rounded == Double(Int(rounded)) {
            return String(Int(rounded))
        }
        return String(format: "%.\(digits)f", rounded)
    }

    private func quantizedParameterValue(_ raw: Double, object: MathObject) -> Double {
        if let settings = object.sliderSettings {
            return quantizedParameterValue(raw, settings: settings)
        }
        if let minValue = object.parameterMin, let maxValue = object.parameterMax {
            return min(max(raw, minValue), maxValue)
        }
        return raw
    }

    private func quantizedParameterValue(_ raw: Double, settings: SliderSettings) -> Double {
        let clamped = min(max(raw, settings.min), settings.max)
        guard settings.step > 0 else { return clamped }
        let offset = (clamped - settings.min) / settings.step
        let snapped = settings.min + offset.rounded() * settings.step
        return min(max(snapped, settings.min), settings.max)
    }

    private func startSliderPlaybackLoopIfNeeded() {
        guard sliderPlaybackTask == nil else { return }
        sliderPlaybackTask = Task { [weak self] in
            guard let self else { return }
            let frameDurationNs: UInt64 = 33_000_000
            while !Task.isCancelled {
                if self.playingSliderDirections.isEmpty {
                    break
                }
                try? await Task.sleep(nanoseconds: frameDurationNs)
                if Task.isCancelled { break }
                self.advancePlayingSliders(frameDuration: 1.0 / 30.0)
            }
            await MainActor.run { [weak self] in
                self?.sliderPlaybackTask = nil
            }
        }
    }

    private func stopSliderPlaybackLoopIfIdle() {
        guard playingSliderDirections.isEmpty else { return }
        sliderPlaybackTask?.cancel()
        sliderPlaybackTask = nil
    }

    private func advancePlayingSliders(frameDuration: Double) {
        guard !playingSliderDirections.isEmpty else { return }
        var staleIDs: [UUID] = []
        for (id, direction) in playingSliderDirections {
            guard let object = document.objects.first(where: { $0.id == id && $0.type == .parameter }) else {
                staleIDs.append(id)
                continue
            }
            let settings = object.sliderSettings ?? .default
            let current = object.parameterValue ?? settings.min
            let delta = settings.step * settings.speed * frameDuration * 30.0
            let baseDirection: Double = settings.playbackMode == .decreasing ? -1 : 1
            let usesDynamicDirection = settings.playbackMode == .pingPong || settings.playbackLoopMode == .pingPong
            let movingDirection = usesDynamicDirection ? direction : baseDirection
            var next = current + movingDirection * delta
            var nextDirection = direction
            var shouldStop = false

            switch settings.playbackMode {
            case .increasing:
                handlePlaybackBoundary(
                    next: &next,
                    nextDirection: &nextDirection,
                    shouldStop: &shouldStop,
                    settings: settings,
                    movingDirection: movingDirection
                )
            case .decreasing:
                handlePlaybackBoundary(
                    next: &next,
                    nextDirection: &nextDirection,
                    shouldStop: &shouldStop,
                    settings: settings,
                    movingDirection: movingDirection
                )
            case .pingPong:
                if next >= settings.max {
                    next = settings.max
                    nextDirection = -1
                } else if next <= settings.min {
                    next = settings.min
                    nextDirection = 1
                }
            }

            updateParameter(id: id, value: next, recordUndo: false)
            if shouldStop {
                staleIDs.append(id)
            } else if nextDirection != direction {
                playingSliderDirections[id] = nextDirection
            }
        }

        for id in staleIDs {
            playingSliderDirections[id] = nil
        }
        stopSliderPlaybackLoopIfIdle()
    }

    private func normalizedSliderSettings(_ settings: SliderSettings) -> SliderSettings {
        let clampedMin = min(settings.min, settings.max)
        let clampedMax = max(settings.min, settings.max)
        let safeStep = settings.step > 0 ? settings.step : SliderSettings.default.step
        let safePrecision = max(0, min(settings.precision, 6))
        let safeSpeed = max(0.01, settings.speed)
        return SliderSettings(
            min: clampedMin,
            max: clampedMax,
            step: safeStep,
            precision: safePrecision,
            speed: safeSpeed,
            playbackMode: settings.playbackMode,
            playbackLoopMode: settings.playbackLoopMode
        )
    }

    private func handlePlaybackBoundary(
        next: inout Double,
        nextDirection: inout Double,
        shouldStop: inout Bool,
        settings: SliderSettings,
        movingDirection: Double
    ) {
        guard next < settings.min || next > settings.max else { return }
        switch settings.playbackLoopMode {
        case .clamp:
            next = min(max(next, settings.min), settings.max)
            shouldStop = true
        case .loop:
            next = movingDirection >= 0 ? settings.min : settings.max
        case .pingPong:
            next = min(max(next, settings.min), settings.max)
            nextDirection = movingDirection >= 0 ? -1 : 1
        }
    }

    private func shouldFallbackToExplicitYForCommit() -> Bool {
        guard let intent = formulaInputState.semanticState.graphClassification?.intent else {
            return true
        }
        if case .unknown = intent {
            return true
        }
        return false
    }

    private func currentLoweringContext() -> LoweringContext {
        let symbols = Dictionary(
            uniqueKeysWithValues: document.objects.compactMap { object -> (String, Symbol)? in
                guard object.type == .parameter else { return nil }
                return (object.name, Symbol(name: object.name, role: .parameter))
            }
        )
        return LoweringContext(
            mode: .expression,
            symbolTable: SymbolTable(symbols: symbols)
        )
    }

    private func ensureValidCursor(in state: inout EditorState) {
        if let sequence = MathEditorTree.sequence(at: state.cursor.path, in: state.root) {
            state.cursor.offset = max(0, min(sequence.count, state.cursor.offset))
            return
        }
        let rootCount = MathEditorTree.sequence(at: [], in: state.root)?.count ?? 0
        state.cursor = EditorCursor(path: [], offset: rootCount)
    }

    private func currentPiecewiseTemplateContext(in state: EditorState? = nil) -> (template: TemplateNode, templatePath: [EditorPathComponent], rows: Int)? {
        let state = state ?? formulaInputState.editorState
        guard let templateContext = MathEditorTree.currentTemplateContext(for: state.cursor, in: state.root) else {
            return nil
        }
        guard case .piecewise(let rows) = templateContext.template.kind else {
            return nil
        }
        return (template: templateContext.template, templatePath: templateContext.templatePath, rows: rows)
    }
}

private enum MathKeyboardCompactVisibilityState {
    case automatic
    case autoCollapsed
    case userToggled
}

public enum DependencyDeletionStrategy: Hashable {
    case unlink
    case deleteAffected
}

public struct DependencyDeletionDialogContext: Hashable {
    public let selectedIDs: Set<UUID>
    public let affectedIDs: Set<UUID>
}

private struct ExprInfixSerializer {
    public func serialize(_ expr: Expr) -> String {
        render(expr, parentPrecedence: .lowest)
    }

    private enum Precedence: Int {
        case lowest = 0
        case additive = 1
        case multiplicative = 2
        case power = 3
        case unary = 4
        case primary = 5
    }

    private func render(_ expr: Expr, parentPrecedence: Precedence) -> String {
        switch expr {
        case .integer(let value):
            return "\(value)"
        case .rational(let n, let d):
            return "(\(n))/(\(d))"
        case .decimal(let value):
            return value
        case .real(let value):
            return "\(value)"
        case .symbol(let symbol):
            return symbol.name
        case .constant(let constant):
            switch constant {
            case .pi:
                return "pi"
            case .e:
                return "e"
            case .imaginaryUnit:
                return "i"
            case .infinity:
                return "infinity"
            }
        case .negate(let value):
            let rendered = "-\(render(value, parentPrecedence: .unary))"
            return wrapIfNeeded(rendered, current: .unary, parent: parentPrecedence)
        case .add(let terms):
            let rendered = terms.map { render($0, parentPrecedence: .additive) }.joined(separator: "+")
            return wrapIfNeeded(rendered, current: .additive, parent: parentPrecedence)
        case .multiply(let factors):
            let rendered = factors.map { render($0, parentPrecedence: .multiplicative) }.joined(separator: "*")
            return wrapIfNeeded(rendered, current: .multiplicative, parent: parentPrecedence)
        case .divide(let numerator, let denominator):
            let rendered = "\(render(numerator, parentPrecedence: .multiplicative))/\(render(denominator, parentPrecedence: .multiplicative))"
            return wrapIfNeeded(rendered, current: .multiplicative, parent: parentPrecedence)
        case .power(let base, let exponent):
            let rendered = "\(render(base, parentPrecedence: .power))^\(render(exponent, parentPrecedence: .unary))"
            return wrapIfNeeded(rendered, current: .power, parent: parentPrecedence)
        case .function(let fn, let args):
            let name = functionName(fn)
            let renderedArgs = args.map { render($0, parentPrecedence: .lowest) }.joined(separator: ",")
            return "\(name)(\(renderedArgs))"
        case .equation(let left, let right):
            return "\(render(left, parentPrecedence: .lowest))=\(render(right, parentPrecedence: .lowest))"
        case .relation(let left, let relation, let right):
            return "\(render(left, parentPrecedence: .lowest))\(relation.rawValue)\(render(right, parentPrecedence: .lowest))"
        case .chainedRelation(let expressions, let relations):
            guard !expressions.isEmpty else { return "" }
            var parts: [String] = [render(expressions[0], parentPrecedence: .lowest)]
            for index in 0..<relations.count where index + 1 < expressions.count {
                parts.append(relations[index].rawValue)
                parts.append(render(expressions[index + 1], parentPrecedence: .lowest))
            }
            return parts.joined()
        case .tuple(let values):
            return "{\(values.map { render($0, parentPrecedence: .lowest) }.joined(separator: ","))}"
        case .piecewise, .vector, .matrix, .assignment, .functionDefinition, .unknown:
            return ExprDebugPrinter().print(expr)
        }
    }

    private func wrapIfNeeded(_ text: String, current: Precedence, parent: Precedence) -> String {
        current.rawValue < parent.rawValue ? "(\(text))" : text
    }

    private func functionName(_ fn: MathFunction) -> String {
        switch fn {
        case .sin: return "sin"
        case .cos: return "cos"
        case .tan: return "tan"
        case .asin: return "asin"
        case .acos: return "acos"
        case .atan: return "atan"
        case .sinh: return "sinh"
        case .cosh: return "cosh"
        case .tanh: return "tanh"
        case .exp: return "exp"
        case .ln: return "ln"
        case .lg: return "lg"
        case .log: return "log"
        case .logBase: return "logBase"
        case .sqrt: return "sqrt"
        case .abs: return "abs"
        case .floor: return "floor"
        case .ceil: return "ceil"
        case .min: return "min"
        case .max: return "max"
        case .custom(let name): return name
        }
    }
}
