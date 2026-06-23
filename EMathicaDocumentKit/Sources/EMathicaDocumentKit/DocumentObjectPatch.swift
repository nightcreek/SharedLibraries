import Foundation
import EMathicaMathCore

public struct DocumentObjectPatch: Hashable, Codable {
    public var name: String?
    public var isVisible: Bool?
    public var expressionDisplayText: String?
    public var expression: MathExpression?
    public var position: WorldPoint?
    public var points: [WorldPoint]?
    public var parameterValue: Double?
    public var parameterMin: Double?
    public var parameterMax: Double?
    public var sliderSettings: SliderSettings?
    public var geometryDefinition: GeometryDefinition?
    public var geometryDependency: GeometryDependency?
    public var clearGeometryDependency: Bool?
    public var geometryDefinitionStatus: GeometryDefinitionStatus?
    public var clearGeometryDefinitionStatus: Bool?
    public var styleColorToken: String?
    public var styleOpacity: Double?
    public var styleFillOpacity: Double?
    public var styleLineWidth: Double?
    public var stylePointSize: Double?
    public var styleLineStyle: MathLineStyle?

    public init(
        name: String? = nil,
        isVisible: Bool? = nil,
        expressionDisplayText: String? = nil,
        expression: MathExpression? = nil,
        position: WorldPoint? = nil,
        points: [WorldPoint]? = nil,
        parameterValue: Double? = nil,
        parameterMin: Double? = nil,
        parameterMax: Double? = nil,
        sliderSettings: SliderSettings? = nil,
        geometryDefinition: GeometryDefinition? = nil,
        geometryDependency: GeometryDependency? = nil,
        clearGeometryDependency: Bool? = nil,
        geometryDefinitionStatus: GeometryDefinitionStatus? = nil,
        clearGeometryDefinitionStatus: Bool? = nil,
        styleColorToken: String? = nil,
        styleOpacity: Double? = nil,
        styleFillOpacity: Double? = nil,
        styleLineWidth: Double? = nil,
        stylePointSize: Double? = nil,
        styleLineStyle: MathLineStyle? = nil
    ) {
        self.name = name
        self.isVisible = isVisible
        self.expressionDisplayText = expressionDisplayText
        self.expression = expression
        self.position = position
        self.points = points
        self.parameterValue = parameterValue
        self.parameterMin = parameterMin
        self.parameterMax = parameterMax
        self.sliderSettings = sliderSettings
        self.geometryDefinition = geometryDefinition
        self.geometryDependency = geometryDependency
        self.clearGeometryDependency = clearGeometryDependency
        self.geometryDefinitionStatus = geometryDefinitionStatus
        self.clearGeometryDefinitionStatus = clearGeometryDefinitionStatus
        self.styleColorToken = styleColorToken
        self.styleOpacity = styleOpacity
        self.styleFillOpacity = styleFillOpacity
        self.styleLineWidth = styleLineWidth
        self.stylePointSize = stylePointSize
        self.styleLineStyle = styleLineStyle
    }
}
