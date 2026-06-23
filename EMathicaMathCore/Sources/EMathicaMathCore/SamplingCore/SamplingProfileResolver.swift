public struct SamplingProfileResolver {
    public init() {}

    public func curveOptions2D(
        for profile: SamplingQualityProfile
    ) -> CurveSamplingOptions2D {
        CurveSamplingOptions2D.defaults(for: profile)
    }
}
