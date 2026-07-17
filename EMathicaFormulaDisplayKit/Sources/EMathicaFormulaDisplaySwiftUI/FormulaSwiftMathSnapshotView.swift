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

    @State private var blinkController = FormulaCursorBlinkController()

    var body: some View {
        Group {
            if let snapshot, let image = makeImage(from: snapshot.pngData) {
                ZStack(alignment: .topLeading) {
                    image
                        .resizable()
                        .interpolation(.high)
                        .frame(
                            width: Self.frameSize(for: snapshot).width,
                            height: Self.frameSize(for: snapshot).height,
                            alignment: .topLeading
                        )

                    if showsPlaceholderBounds {
                        ForEach(Array(snapshot.placeholderAnchors.enumerated()), id: \.element.id) { _, anchor in
                            FormulaPlaceholderOverlay(
                                anchor: anchor,
                                strokeColor: style.placeholderStrokeColor,
                                fillColor: style.placeholderFillColor
                            )
                        }
                    }

                    if showsCursor, let cursorState = Self.cursorState(from: snapshot) {
                        TimelineView(.periodic(from: blinkController.referenceDate, by: blinkController.sampleInterval)) { context in
                            FormulaCursorOverlay(
                                state: cursorState,
                                color: style.cursorColor,
                                opacity: blinkController.opacity(at: context.date)
                            )
                        }
                    }
                }
                .frame(
                    width: Self.frameSize(for: snapshot).width,
                    height: Self.frameSize(for: snapshot).height,
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

    static func frameSize(for snapshot: FormulaSwiftMathSnapshot) -> CGSize {
        CGSize(
            width: CGFloat(max(snapshot.size.width, 1)),
            height: CGFloat(max(snapshot.size.height, 1))
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
}
