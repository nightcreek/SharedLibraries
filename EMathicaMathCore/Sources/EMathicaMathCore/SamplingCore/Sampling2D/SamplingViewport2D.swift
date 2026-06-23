public struct SamplingViewport2D: Equatable, Sendable {
    public var xRange: SamplingRange
    public var yRange: SamplingRange
    public var pixelWidth: Double
    public var pixelHeight: Double

    public init(
        xRange: SamplingRange,
        yRange: SamplingRange,
        pixelWidth: Double,
        pixelHeight: Double
    ) {
        self.xRange = xRange
        self.yRange = yRange
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
    }

    public func project(_ point: SamplePoint2D) -> SamplePoint2D {
        let xDenominator = xRange.upper - xRange.lower
        let yDenominator = yRange.upper - yRange.lower
        guard pixelWidth > 0,
              pixelHeight > 0,
              xDenominator > 0,
              yDenominator > 0 else {
            return .init(x: point.x, y: point.y)
        }

        let nx = (point.x - xRange.lower) / xDenominator
        let ny = (point.y - yRange.lower) / yDenominator

        // y-axis is projected top-down: world yRange.upper -> 0, yRange.lower -> pixelHeight.
        return .init(
            x: nx * pixelWidth,
            y: (1.0 - ny) * pixelHeight
        )
    }
}
