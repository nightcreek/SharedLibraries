import EMathicaFormulaDisplayCore
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Color {
    func resolvedFormulaRGBA() -> FormulaRGBAColor {
        #if canImport(UIKit)
        let color = UIColor(self)
        var red = CGFloat.zero
        var green = CGFloat.zero
        var blue = CGFloat.zero
        var alpha = CGFloat.zero
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return .init(red: red, green: green, blue: blue, alpha: alpha)
        #elseif canImport(AppKit)
        let color = NSColor(self).usingColorSpace(.deviceRGB) ?? .black
        return .init(
            red: color.redComponent,
            green: color.greenComponent,
            blue: color.blueComponent,
            alpha: color.alphaComponent
        )
        #else
        return .init(red: 0, green: 0, blue: 0, alpha: 1)
        #endif
    }
}
