import EMathicaMathCore
import Foundation

enum AlgebraObjectPanelSectionKind: String, CaseIterable, Hashable, Identifiable {
    case parameters
    case functionsAndCurves
    case geometry
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .parameters:
            return "参数"
        case .functionsAndCurves:
            return "函数与曲线"
        case .geometry:
            return "几何对象"
        case .other:
            return "其他对象"
        }
    }

    var systemImageName: String {
        switch self {
        case .parameters:
            return "slider.horizontal.3"
        case .functionsAndCurves:
            return "function"
        case .geometry:
            return "triangle"
        case .other:
            return "square.grid.2x2"
        }
    }

    static let displayOrder: [AlgebraObjectPanelSectionKind] = [
        .parameters,
        .functionsAndCurves,
        .geometry,
        .other
    ]

    static func resolve(for object: MathObject) -> AlgebraObjectPanelSectionKind {
        switch object.type {
        case .parameter:
            return .parameters
        case .function:
            return .functionsAndCurves
        case .point, .segment, .line, .ray, .circle, .arc:
            return .geometry
        case .parameterGroup:
            return .other
        }
    }
}

struct AlgebraObjectPanelSection: Identifiable, Equatable {
    let kind: AlgebraObjectPanelSectionKind
    let objects: [MathObject]

    var id: AlgebraObjectPanelSectionKind { kind }
    var title: String { kind.title }
    var systemImageName: String { kind.systemImageName }

    static func makeSections(from objects: [MathObject]) -> [AlgebraObjectPanelSection] {
        var buckets: [AlgebraObjectPanelSectionKind: [MathObject]] = [:]

        for object in objects where object.type != .parameterGroup {
            let section = AlgebraObjectPanelSectionKind.resolve(for: object)
            buckets[section, default: []].append(object)
        }

        return AlgebraObjectPanelSectionKind.displayOrder.compactMap { section in
            guard let members = buckets[section], !members.isEmpty else {
                return nil
            }
            return AlgebraObjectPanelSection(kind: section, objects: members)
        }
    }
}
