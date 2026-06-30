import EMathicaThemeKit
import EMathicaWorkspaceKit
import SwiftUI

struct NewProjectTypePickerView: View {
    @Environment(\.dismiss) private var dismiss

    let catalog: HomeModuleCatalog
    let onPick: (CalculatorModuleType) -> Void

    init(
        catalog: HomeModuleCatalog,
        onPick: @escaping (CalculatorModuleType) -> Void
    ) {
        self.catalog = catalog
        self.onPick = onPick
    }

    var body: some View {
        NavigationStack {
            List {
                Section("选择模块") {
                    ForEach(catalog.modules, id: \.id) { descriptor in
                        Button {
                            onPick(descriptor.id)
                        } label: {
                            HStack(spacing: 12) {
                                ModuleIconView(
                                    iconName: descriptor.iconName,
                                    accent: descriptor.accentToken.resolvedColor()
                                )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(descriptor.title)
                                        .font(.system(size: 15, weight: .semibold))
                                    Text(descriptor.subtitle)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("创建作品")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}
