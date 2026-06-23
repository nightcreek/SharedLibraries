import Foundation

enum QuickStartExpressionTemplate: String, CaseIterable, Identifiable {
    case explicitFunction
    case parametricCurve
    case polarCurve
    case point

    var id: String { rawValue }

    var title: String {
        switch self {
        case .explicitFunction:
            return "显函数"
        case .parametricCurve:
            return "参数曲线"
        case .polarCurve:
            return "极坐标"
        case .point:
            return "点"
        }
    }

    var previewText: String {
        switch self {
        case .explicitFunction:
            return "y = sin(x)"
        case .parametricCurve:
            return "x = cos(t), y = sin(t)"
        case .polarCurve:
            return "r = 1 + cos(theta)"
        case .point:
            return "A = (1, 2)"
        }
    }

    var helperText: String {
        switch self {
        case .explicitFunction:
            return "传统函数入口"
        case .parametricCurve:
            return "二维参数表达"
        case .polarCurve:
            return "极角驱动曲线"
        case .point:
            return "坐标对象入口"
        }
    }

    var systemImageName: String {
        switch self {
        case .explicitFunction:
            return "function"
        case .parametricCurve:
            return "scribble.variable"
        case .polarCurve:
            return "circle.dotted"
        case .point:
            return "smallcircle.filled.circle"
        }
    }
}
