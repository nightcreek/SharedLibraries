import Foundation
import EMathicaMathCore

public enum DeletedObjectHistoryPresenter {
    public struct RowModel: Identifiable, Hashable {
        public let id: UUID
        let recordID: UUID
        let name: String
        let typeLabel: String
        let deletedAtText: String
        let contextText: String
        let summaryText: String
    }

    public static let emptyTitle = "没有可恢复的对象"
    public static let emptyMessage = "删除的对象会保存在此处，最多保留最近 200 个。"
    public static let restoreDescription = "恢复后的对象会作为独立对象加入当前文档。"

    public static func contextLabel(for context: DeletedObjectContext?) -> String {
        switch context {
        case .userDelete:
            return "手动删除"
        case .deleteAffected:
            return "删除相关对象"
        case .unknown, .none:
            return "未知来源"
        }
    }

    public static func typeLabel(for type: MathObjectType) -> String {
        switch type {
        case .function:
            return "函数"
        case .point:
            return "点"
        case .circle:
            return "圆"
        case .arc:
            return "圆弧"
        case .segment:
            return "线段"
        case .line:
            return "直线"
        case .ray, .arc:
            return "射线"
        case .parameter:
            return "参数"
        case .parameterGroup, .arc:
            return "参数组"
        }
    }

    public static func deletedAtText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    public static func summary(for object: MathObject) -> String {
        if object.type == .point, let point = object.position {
            return "坐标 \(GeometryPropertyFormatter.coordinate(point))"
        }
        if let display = object.expression.displayText.nilIfEmpty {
            return display
        }
        if let source = object.expression.sourceExpression?.nilIfEmpty {
            return source
        }
        return typeLabel(for: object.type)
    }

    public static func rowModels(from records: [DeletedObjectRecord]) -> [RowModel] {
        records
            .sorted { $0.deletedAt > $1.deletedAt }
            .map { record in
                RowModel(
                    id: record.id,
                    recordID: record.id,
                    name: record.object.name,
                    typeLabel: typeLabel(for: record.object.type),
                    deletedAtText: deletedAtText(record.deletedAt),
                    contextText: contextLabel(for: record.context),
                    summaryText: summary(for: record.object)
                )
            }
    }
}

private extension String {
    public var nilIfEmpty: String? {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
    }
}

