public struct CurveSamplingOptions2D: Equatable, Sendable {
    public var qualityProfile: SamplingQualityProfile
    public var algorithm: CurveSamplingAlgorithm2D

    public var initialSampleCount: Int
    public var maxSampleCount: Int
    public var maxRefinementDepth: Int

    public var discontinuityThreshold: Double
    public var maxAbsCoordinate: Double
    public var refinementErrorThreshold: Double
    public var screenErrorTolerance: Double?

    public init(
        qualityProfile: SamplingQualityProfile,
        algorithm: CurveSamplingAlgorithm2D,
        initialSampleCount: Int,
        maxSampleCount: Int,
        maxRefinementDepth: Int,
        discontinuityThreshold: Double,
        maxAbsCoordinate: Double,
        refinementErrorThreshold: Double,
        screenErrorTolerance: Double?
    ) {
        self.qualityProfile = qualityProfile
        self.algorithm = algorithm
        self.initialSampleCount = initialSampleCount
        self.maxSampleCount = maxSampleCount
        self.maxRefinementDepth = maxRefinementDepth
        self.discontinuityThreshold = discontinuityThreshold
        self.maxAbsCoordinate = maxAbsCoordinate
        self.refinementErrorThreshold = refinementErrorThreshold
        self.screenErrorTolerance = screenErrorTolerance
    }

    public static func defaults(
        for profile: SamplingQualityProfile
    ) -> CurveSamplingOptions2D {
        switch profile {
        case .preview:
            return .init(
                qualityProfile: .preview,
                algorithm: .uniform,
                initialSampleCount: 256,
                maxSampleCount: 256,
                maxRefinementDepth: 0,
                discontinuityThreshold: 1000,
                maxAbsCoordinate: 1.0e12,
                refinementErrorThreshold: .infinity,
                screenErrorTolerance: nil
            )
        case .balanced:
            return .init(
                qualityProfile: .balanced,
                algorithm: .uniformWithBasicRefinement,
                initialSampleCount: 512,
                maxSampleCount: 1024,
                maxRefinementDepth: 2,
                discontinuityThreshold: 1000,
                maxAbsCoordinate: 1.0e12,
                refinementErrorThreshold: 0.1,
                screenErrorTolerance: 2.0
            )
        case .precise:
            return .init(
                qualityProfile: .precise,
                algorithm: .adaptiveScreenSpace,
                initialSampleCount: 768,
                maxSampleCount: 4096,
                maxRefinementDepth: 6,
                discontinuityThreshold: 500,
                maxAbsCoordinate: 1.0e12,
                refinementErrorThreshold: 0.03,
                screenErrorTolerance: 0.75
            )
        case .exploratory:
            return .init(
                qualityProfile: .exploratory,
                algorithm: .hybridExploratory,
                initialSampleCount: 1024,
                maxSampleCount: 8192,
                maxRefinementDepth: 8,
                discontinuityThreshold: 300,
                maxAbsCoordinate: 1.0e12,
                refinementErrorThreshold: 0.01,
                screenErrorTolerance: 0.5
            )
        }
    }
}
