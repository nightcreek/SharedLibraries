import EMathicaFormulaDisplayCore
import OSLog
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct FormulaSwiftMathSnapshotView: View {
    private static let logger = Logger(
        subsystem: "EMathicaFormulaDisplayKit",
        category: "FormulaSwiftMathSnapshotView"
    )

    let snapshot: FormulaSwiftMathSnapshot?
    let error: FormulaSwiftMathRenderError?
    let style: FormulaDisplayStyle
    let showsCursor: Bool
    let showsPlaceholderBounds: Bool
    let onTapInsertionID: ((FormulaInsertionID) -> Void)?

    @State private var blinkController = FormulaCursorBlinkController()

    init(
        snapshot: FormulaSwiftMathSnapshot?,
        error: FormulaSwiftMathRenderError?,
        style: FormulaDisplayStyle,
        showsCursor: Bool,
        showsPlaceholderBounds: Bool,
        onTapInsertionID: ((FormulaInsertionID) -> Void)? = nil
    ) {
        self.snapshot = snapshot
        self.error = error
        self.style = style
        self.showsCursor = showsCursor
        self.showsPlaceholderBounds = showsPlaceholderBounds
        self.onTapInsertionID = onTapInsertionID
    }

    var body: some View {
        Group {
            if let snapshot, let image = makeImage(from: snapshot.pngData) {
                let canvasLayout = Self.editorCanvasLayout(
                    for: snapshot,
                    showsCursor: showsCursor
                )
                let canvas = ZStack(alignment: .topLeading) {
                    image
                        .resizable()
                        .interpolation(.high)
                        .frame(
                            width: Self.imageSize(for: snapshot).width,
                            height: Self.imageSize(for: snapshot).height,
                            alignment: .topLeading
                        )
                        .offset(x: canvasLayout.contentOrigin.x, y: canvasLayout.contentOrigin.y)

                    if showsPlaceholderBounds {
                        ForEach(snapshot.placeholderAnchors) { anchor in
                            let index = snapshot.placeholderAnchors.firstIndex(where: { $0.id == anchor.id }) ?? 0
                            FormulaPlaceholderOverlay(
                                rect: canvasLayout.placeholderRects[index],
                                strokeColor: style.placeholderStrokeColor,
                                fillColor: style.placeholderFillColor
                            )
                        }
                        Canvas { context, _ in
                            for anchor in snapshot.insertionAnchors {
                                let rect = anchor.rect.offsetBy(
                                    dx: canvasLayout.contentOrigin.x,
                                    dy: canvasLayout.contentOrigin.y
                                )
                                let path = Path(
                                    roundedRect: CGRect(
                                        x: rect.minX,
                                        y: rect.minY,
                                        width: rect.size.width,
                                        height: rect.size.height
                                    ),
                                    cornerRadius: 1,
                                    style: .continuous
                                )
                                context.stroke(
                                    path,
                                    with: .color(Color.cyan.opacity(0.28)),
                                    style: StrokeStyle(lineWidth: 1, dash: [2, 2])
                                )
                            }
                        }
                    }

                    if showsCursor, let cursorRect = canvasLayout.cursorVisualRect {
                        TimelineView(.periodic(from: blinkController.referenceDate, by: blinkController.sampleInterval)) { context in
                            FormulaCursorOverlay(
                                rect: cursorRect,
                                color: style.cursorColor,
                                opacity: blinkController.opacity(at: context.date)
                            )
                        }
                    }
                }
                Group {
                    if onTapInsertionID != nil {
                        canvas
                            .contentShape(Rectangle())
                            .highPriorityGesture(
                                tapGesture(for: snapshot, canvasLayout: canvasLayout)
                            )
                    } else {
                        canvas
                    }
                }
                .frame(
                    width: canvasLayout.canvasSize.width,
                    height: canvasLayout.canvasSize.height,
                    alignment: .topLeading
                )
            } else {
                EmptyView()
            }
        }
        .onAppear {
            logHiddenRenderErrorIfNeeded()
        }
    }

    static func cursorState(from snapshot: FormulaSwiftMathSnapshot) -> FormulaCursorState? {
        guard let anchor = snapshot.cursorAnchor else { return nil }
        return FormulaCursorState(insertionPoint: anchor)
    }

    static func imageSize(for snapshot: FormulaSwiftMathSnapshot) -> CGSize {
        CGSize(
            width: CGFloat(max(snapshot.size.width, 1)),
            height: CGFloat(max(snapshot.size.height, 1))
        )
    }

    static func editorCanvasLayout(
        for snapshot: FormulaSwiftMathSnapshot,
        showsCursor: Bool
    ) -> FormulaEditorCanvasLayout {
        let imageSize = Self.imageSize(for: snapshot)
        let formulaFrame = CGRect(origin: .zero, size: imageSize)
        let cursorAnchor = showsCursor ? snapshot.cursorAnchor : nil
        let cursorVisualRect = cursorAnchor.map {
            FormulaCursorOverlay.cursorVisualRect(
                for: FormulaCursorState(insertionPoint: $0)
            )
        }
        let placeholderAnchors = snapshot.placeholderAnchors
        let placeholderRects = placeholderAnchors.map(Self.editorCanvasRect(for:))

        let bounds = Self.editorCanvasBounds(
            formulaFrame: formulaFrame,
            cursorVisualRect: cursorVisualRect,
            placeholderRects: placeholderRects
        )
        let contentOrigin = CGPoint(
            x: max(0, -bounds.minX),
            y: max(0, -bounds.minY)
        )
        let canvasSize = CGSize(
            width: max(1, bounds.maxX + contentOrigin.x),
            height: max(1, bounds.maxY + contentOrigin.y)
        )
        let formulaFrameInCanvas = formulaFrame.offsetBy(
            dx: contentOrigin.x,
            dy: contentOrigin.y
        )
        let cursorRectInCanvas = cursorVisualRect?.offsetBy(
            dx: contentOrigin.x,
            dy: contentOrigin.y
        )
        let placeholderRectsInCanvas = placeholderRects.map {
            $0.offsetBy(dx: contentOrigin.x, dy: contentOrigin.y)
        }

        return FormulaEditorCanvasLayout(
            snapshotSize: imageSize,
            contentInsets: EdgeInsets(
                top: contentOrigin.y,
                leading: contentOrigin.x,
                bottom: max(0, canvasSize.height - formulaFrameInCanvas.maxY),
                trailing: max(0, canvasSize.width - formulaFrameInCanvas.maxX)
            ),
            contentOrigin: contentOrigin,
            canvasSize: canvasSize,
            formulaFrame: formulaFrameInCanvas,
            cursorAnchor: cursorAnchor,
            cursorVisualRect: cursorRectInCanvas,
            placeholderAnchors: placeholderAnchors,
            placeholderRects: placeholderRectsInCanvas
        )
    }

    private func makeImage(from data: Data) -> Image? {
        #if canImport(UIKit)
        guard let image = UIImage(data: data) else { return nil }
        return Image(uiImage: image)
        #elseif canImport(AppKit)
        guard let image = NSImage(data: data) else { return nil }
        return Image(nsImage: image)
        #else
        return nil
        #endif
    }

    private func logHiddenRenderErrorIfNeeded() {
        guard let error else { return }
        Self.logger.error(
            "Hidden SwiftMath UI error. domain=\(error.domain, privacy: .public) code=\(error.code, privacy: .public) message=\(error.message, privacy: .public)"
        )
    }

    private func tapGesture(
        for snapshot: FormulaSwiftMathSnapshot,
        canvasLayout: FormulaEditorCanvasLayout
    ) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onEnded { value in
                guard let onTapInsertionID else { return }
                guard let insertionID = FormulaInsertionHitResolver.resolve(
                    at: value.location,
                    layout: canvasLayout,
                    insertionAnchors: snapshot.insertionAnchors,
                    placeholderAnchors: snapshot.placeholderAnchors
                ) else {
                    return
                }
                onTapInsertionID(insertionID)
            }
    }

    private static func editorCanvasRect(for anchor: FormulaPlaceholderAnchor) -> CGRect {
        FormulaPlaceholderOverlay.overlayRect(for: anchor)
    }

    private static func editorCanvasBounds(
        formulaFrame: CGRect,
        cursorVisualRect: CGRect?,
        placeholderRects: [CGRect]
    ) -> CGRect {
        var bounds = formulaFrame
        if let cursorVisualRect {
            bounds = bounds.union(cursorVisualRect)
        }
        for placeholderRect in placeholderRects {
            bounds = bounds.union(placeholderRect)
        }
        return bounds
    }
}

struct FormulaEditorCanvasLayout {
    let snapshotSize: CGSize
    let contentInsets: EdgeInsets
    let contentOrigin: CGPoint
    let canvasSize: CGSize
    let formulaFrame: CGRect
    let cursorAnchor: FormulaCursorAnchor?
    let cursorVisualRect: CGRect?
    let placeholderAnchors: [FormulaPlaceholderAnchor]
    let placeholderRects: [CGRect]

    var contentOffset: CGSize {
        CGSize(width: contentOrigin.x, height: contentOrigin.y)
    }
}
