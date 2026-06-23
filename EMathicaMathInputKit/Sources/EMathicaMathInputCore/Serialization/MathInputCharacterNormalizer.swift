import Foundation

public enum MathInputCharacterNormalizer {
    public static func normalize(_ raw: String) -> String {
        if raw.isEmpty { return raw }
        var output = ""
        output.reserveCapacity(raw.count)
        for scalar in raw.unicodeScalars {
            output.append(normalizeScalar(scalar))
        }
        return output
    }

    private static func normalizeScalar(_ scalar: Unicode.Scalar) -> String {
        // Full-width digits.
        if let digit = scalarOffsetMapped(scalar, from: 0xFF10, to: 0x0030, count: 10) {
            return String(digit)
        }
        // Full-width lowercase letters.
        if let letter = scalarOffsetMapped(scalar, from: 0xFF41, to: 0x0061, count: 26) {
            return String(letter)
        }
        // Full-width uppercase letters.
        if let letter = scalarOffsetMapped(scalar, from: 0xFF21, to: 0x0041, count: 26) {
            return String(letter)
        }

        switch scalar.value {
        case 0xFF0B: return "+"   // ＋
        case 0xFF0D: return "-"   // －
        case 0x2212: return "-"   // −
        case 0x2013: return "-"   // –
        case 0x2014: return "-"   // —
        case 0xFF0A: return "*"   // ＊
        case 0xFF0F: return "/"   // ／
        case 0xFF1D: return "="   // ＝
        case 0xFF1C: return "<"   // ＜
        case 0xFF1E: return ">"   // ＞
        case 0x2264: return "<="  // ≤
        case 0x2265: return ">="  // ≥
        case 0x2260: return "!="  // ≠
        case 0xFF08: return "("   // （
        case 0xFF09: return ")"   // ）
        case 0xFF3B: return "["   // ［
        case 0xFF3D: return "]"   // ］
        case 0xFF5B: return "{"   // ｛
        case 0xFF5D: return "}"   // ｝
        case 0xFF0C: return ","   // ，
        case 0xFF1B: return ";"   // ；
        case 0xFF0E: return "."   // ．
        case 0x3000: return " "   // full-width space
        default:
            return String(scalar)
        }
    }

    private static func scalarOffsetMapped(
        _ scalar: Unicode.Scalar,
        from start: UInt32,
        to destination: UInt32,
        count: UInt32
    ) -> Unicode.Scalar? {
        guard scalar.value >= start, scalar.value < start + count else { return nil }
        let offset = scalar.value - start
        return Unicode.Scalar(destination + offset)
    }
}
