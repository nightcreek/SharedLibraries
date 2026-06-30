import Foundation

enum ProjectThumbnailKind: String, Codable, CaseIterable, Sendable {
    case parabolaGraph
    case circleGeometry
    case parametricCurve
    case surface3D
    case spiralStairModel
    case synthWaveform
    case sequencerBlocks
    case heatmap
    case lineChart
    case formulaNotes
}
