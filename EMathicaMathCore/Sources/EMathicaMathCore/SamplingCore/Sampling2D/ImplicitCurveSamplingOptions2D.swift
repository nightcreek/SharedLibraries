public struct ImplicitCurveSamplingOptions2D: Equatable, Sendable {
    public var qualityProfile: SamplingQualityProfile
    public var xResolution: Int
    public var yResolution: Int
    public var maxAbsCoordinate: Double
    public var enableSegmentStitching: Bool
    public var stitchingTolerance: Double

    public init(
        qualityProfile: SamplingQualityProfile,
        xResolution: Int,
        yResolution: Int,
        maxAbsCoordinate: Double = 1.0e12,
        enableSegmentStitching: Bool = true,
        stitchingTolerance: Double = 1.0e-6
    ) {
        self.qualityProfile = qualityProfile
        self.xResolution = xResolution
        self.yResolution = yResolution
        self.maxAbsCoordinate = maxAbsCoordinate
        self.enableSegmentStitching = enableSegmentStitching
        self.stitchingTolerance = stitchingTolerance
    }

    public static func defaults(
        for profile: SamplingQualityProfile
    ) -> ImplicitCurveSamplingOptions2D {
        switch profile {
        case .preview:
            return .init(
                qualityProfile: .preview,
                xResolution: 64,
                yResolution: 64,
                enableSegmentStitching: true,
                stitchingTolerance: 1.0e-6
            )
        case .balanced:
            return .init(
                qualityProfile: .balanced,
                xResolution: 128,
                yResolution: 128,
                enableSegmentStitching: true,
                stitchingTolerance: 1.0e-6
            )
        case .precise:
            return .init(
                qualityProfile: .precise,
                xResolution: 256,
                yResolution: 256,
                enableSegmentStitching: true,
                stitchingTolerance: 1.0e-7
            )
        case .exploratory:
            return .init(
                qualityProfile: .exploratory,
                xResolution: 384,
                yResolution: 384,
                enableSegmentStitching: true,
                stitchingTolerance: 1.0e-7
            )
        }
    }
}
