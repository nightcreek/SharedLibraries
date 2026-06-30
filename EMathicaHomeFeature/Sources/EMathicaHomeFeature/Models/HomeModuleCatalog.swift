import EMathicaThemeKit
import EMathicaWorkspaceKit
import Foundation

public struct HomeModuleCatalog {
    var modules: [HomeModuleDescriptor]

    public init(modules: [HomeModuleDescriptor]) {
        self.modules = modules
    }
}

public struct HomeModuleDescriptor: Hashable {
    var id: CalculatorModuleType
    var title: String
    var subtitle: String
    var iconName: String
    var accentToken: ColorToken

    public init(
        id: CalculatorModuleType,
        title: String,
        subtitle: String,
        iconName: String,
        accentToken: ColorToken? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.accentToken = accentToken ?? Self.defaultAccentToken(for: id)
    }

    private static func defaultAccentToken(for id: CalculatorModuleType) -> ColorToken {
        switch id {
        case .plane:
            return .blue
        case .space:
            return .indigo
        case .modeling:
            return .purple
        case .music:
            return .cyan
        case .data:
            return .green
        case .notes:
            return .pink
        }
    }
}
