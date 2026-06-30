import Foundation

public enum GalleryFilter: String, CaseIterable, Codable, Sendable {
    case recent = "最近使用"
    case plane = "平面"
    case space = "立体"
    case modeling = "建模"
    case music = "音乐"
    case data = "数据"
    case notes = "笔记"

    var moduleID: String? {
        switch self {
        case .recent:
            return nil
        case .plane:
            return "plane"
        case .space:
            return "space"
        case .modeling:
            return "modeling"
        case .music:
            return "music"
        case .data:
            return "data"
        case .notes:
            return "notes"
        }
    }
}
