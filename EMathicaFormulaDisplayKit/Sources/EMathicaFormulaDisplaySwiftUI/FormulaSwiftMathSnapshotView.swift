import EMathicaFormulaDisplayCore
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct FormulaSwiftMathSnapshotView: View {
    let snapshot: FormulaSwiftMathSnapshot?
    let error: FormulaSwiftMathRenderError?
    let style: FormulaDisplayStyle

    var body: some View {
        Group {
            if let snapshot, let image = makeImage(from: snapshot.pngData) {
                image
                    .resizable()
                    .interpolation(.high)
                    .frame(
                        width: max(snapshot.size.width, 1),
                        height: max(snapshot.size.height, 1),
                        alignment: .topLeading
                    )
            } else if let error {
                Text(error.message)
                    .font(style.baseFont)
                    .foregroundStyle(style.errorTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                EmptyView()
            }
        }
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
}
