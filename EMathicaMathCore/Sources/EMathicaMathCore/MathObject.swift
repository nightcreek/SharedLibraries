import Foundation

public enum SliderPlaybackMode: String, Hashable, Codable, Sendable {
    case increasing
    case decreasing
    case pingPong
}

public enum SliderPlaybackLoopMode: String, Hashable, Codable, Sendable {
    case clamp
    case loop
    case pingPong
}

public struct SliderSettings: Hashable, Codable, Sendable {
    public var min: Double
    public var max: Double
    public var step: Double
    public var precision: Int
    public var speed: Double
    public var playbackMode: SliderPlaybackMode
    public var playbackLoopMode: SliderPlaybackLoopMode

    public static let `default` = SliderSettings(
        min: -10,
        max: 10,
        step: 0.1,
        precision: 2,
        speed: 1.0,
        playbackMode: .increasing,
        playbackLoopMode: .loop
    )

    public init(
        min: Double,
        max: Double,
        step: Double,
        precision: Int,
        speed: Double,
        playbackMode: SliderPlaybackMode,
        playbackLoopMode: SliderPlaybackLoopMode
    ) {
        self.min = min
        self.max = max
        self.step = step
        self.precision = precision
        self.speed = speed
        self.playbackMode = playbackMode
        self.playbackLoopMode = playbackLoopMode
    }

    private enum CodingKeys: String, CodingKey {
        case min
        case max
        case step
        case precision
        case speed
        case playbackSpeed
        case playbackMode
        case playbackLoopMode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = SliderSettings.default
        self.min = try container.decodeIfPresent(Double.self, forKey: .min) ?? defaults.min
        self.max = try container.decodeIfPresent(Double.self, forKey: .max) ?? defaults.max
        self.step = try container.decodeIfPresent(Double.self, forKey: .step) ?? defaults.step
        self.precision = try container.decodeIfPresent(Int.self, forKey: .precision) ?? defaults.precision
        let decodedSpeed = try container.decodeIfPresent(Double.self, forKey: .speed)
        let decodedPlaybackSpeed = try container.decodeIfPresent(Double.self, forKey: .playbackSpeed)
        self.speed = decodedSpeed ?? decodedPlaybackSpeed ?? defaults.speed
        self.playbackMode = try container.decodeIfPresent(SliderPlaybackMode.self, forKey: .playbackMode) ?? defaults.playbackMode
        self.playbackLoopMode = try container.decodeIfPresent(SliderPlaybackLoopMode.self, forKey: .playbackLoopMode) ?? defaults.playbackLoopMode
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(min, forKey: .min)
        try container.encode(max, forKey: .max)
        try container.encode(step, forKey: .step)
        try container.encode(precision, forKey: .precision)
        try container.encode(speed, forKey: .speed)
        try container.encode(playbackMode, forKey: .playbackMode)
        try container.encode(playbackLoopMode, forKey: .playbackLoopMode)
    }
}

public enum GeometryDependencyKind: Hashable, Codable, Sendable {
    case midpointOfPoints(pointAID: UUID, pointBID: UUID)
    case parallelLine(referenceObjectID: UUID, throughPointID: UUID)
    case perpendicularLine(referenceObjectID: UUID, throughPointID: UUID)
    case intersectionOf(objectAID: UUID, objectBID: UUID, index: Int)
    case circleByCenterPoint(centerPointID: UUID, throughPointID: UUID)
    case circleByCenterRadius(centerPointID: UUID, radius: Double)
    case arcByThreePoints(pointAID: UUID, pointBID: UUID, pointCID: UUID)
}

public struct GeometryDependency: Hashable, Codable, Sendable {
    public init(kind: GeometryDependencyKind) { self.kind = kind }
    public var kind: GeometryDependencyKind
}

public enum GeometryDefinitionStatus: String, Hashable, Codable, Sendable {
    case defined
    case noSolution
    case missingSource
    case unsupported
    case invalid
}

public enum DeletedObjectContext: String, Hashable, Codable, Sendable {
    case userDelete
    case deleteAffected
    case unknown
}

public struct DeletedObjectRecord: Identifiable, Hashable, Codable {
    public var id: UUID
    public var deletedAt: Date
    public var object: MathObject
    public var context: DeletedObjectContext?

    public init(
        id: UUID = UUID(),
        deletedAt: Date = Date(),
        object: MathObject,
        context: DeletedObjectContext? = nil
    ) {
        self.id = id
        self.deletedAt = deletedAt
        self.object = object
        self.context = context
    }
}

public struct MathObject: Identifiable, Hashable, Codable {
    public let id: UUID
    public var name: String
    public var type: MathObjectType
    public var expression: MathExpression
    public var position: WorldPoint?
    public var points: [WorldPoint]?
    public var parameterValue: Double?
    public var parameterMin: Double?
    public var parameterMax: Double?
    public var sliderSettings: SliderSettings?
    public var geometryDefinition: GeometryDefinition?
    public var geometryDependency: GeometryDependency?
    public var geometryDefinitionStatus: GeometryDefinitionStatus?
    public var style: MathStyle
    public var isVisible: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        type: MathObjectType,
        expression: MathExpression,
        position: WorldPoint? = nil,
        points: [WorldPoint]? = nil,
        parameterValue: Double? = nil,
        parameterMin: Double? = nil,
        parameterMax: Double? = nil,
        sliderSettings: SliderSettings? = nil,
        geometryDefinition: GeometryDefinition? = nil,
        geometryDependency: GeometryDependency? = nil,
        geometryDefinitionStatus: GeometryDefinitionStatus? = nil,
        style: MathStyle,
        isVisible: Bool = true
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.expression = expression
        self.position = position
        self.points = points
        self.parameterValue = parameterValue
        self.parameterMin = parameterMin
        self.parameterMax = parameterMax
        self.sliderSettings = sliderSettings
        self.geometryDefinition = geometryDefinition
        self.geometryDependency = geometryDependency
        self.geometryDefinitionStatus = geometryDefinitionStatus
        self.style = style
        self.isVisible = isVisible
    }
}
