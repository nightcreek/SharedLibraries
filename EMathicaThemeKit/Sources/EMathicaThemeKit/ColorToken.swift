import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public enum ColorToken: String, Codable, CaseIterable {
    case blue
    case red
    case orange
    case indigo
    case purple
    case cyan
    case pink
    case green
    case white
    case yellowOrange

    public func resolvedColor() -> Color {
        switch self {
        case .blue:
            return .blue
        case .red:
            return .red
        case .orange:
            return .orange
        case .indigo:
            return .indigo
        case .purple:
            return .purple
        case .cyan:
            return .cyan
        case .pink:
            return .pink
        case .green:
            return .green
        case .white:
            return .white
        case .yellowOrange:
            return Color(red: 1.0, green: 0.72, blue: 0.25)
        }
    }

    public static func resolvedColor(from styleColor: String, fallback: ColorToken = .blue) -> Color {
        if let color = Color(hexStyleToken: styleColor) {
            return color
        }
        return (ColorToken(rawValue: styleColor) ?? fallback).resolvedColor()
    }

    public static func customHex(from styleColor: String) -> String? {
        guard styleColor.hasPrefix("hex:") else { return nil }
        let hex = String(styleColor.dropFirst(4)).trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard hex.count == 6 else { return nil }
        return "#\(hex)"
    }
}

public extension Color {
    init?(hexStyleToken: String) {
        let rawHex: String
        if hexStyleToken.hasPrefix("hex:") {
            rawHex = String(hexStyleToken.dropFirst(4))
        } else if hexStyleToken.hasPrefix("#") {
            rawHex = String(hexStyleToken.dropFirst())
        } else {
            return nil
        }

        let normalizedHex = rawHex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard normalizedHex.count == 6, let value = UInt64(normalizedHex, radix: 16) else { return nil }
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self = Color(red: red, green: green, blue: blue)
    }

    public func rgbHexString() -> String? {
#if canImport(UIKit)
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        return Self.hexString(red: red, green: green, blue: blue)
#elseif canImport(AppKit)
        let nsColor = NSColor(self)
        guard let color = nsColor.usingColorSpace(.sRGB) else { return nil }
        return Self.hexString(red: color.redComponent, green: color.greenComponent, blue: color.blueComponent)
#else
        return nil
#endif
    }

    private static func hexString(red: CGFloat, green: CGFloat, blue: CGFloat) -> String {
        let r = max(0, min(255, Int((red * 255).rounded())))
        let g = max(0, min(255, Int((green * 255).rounded())))
        let b = max(0, min(255, Int((blue * 255).rounded())))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
