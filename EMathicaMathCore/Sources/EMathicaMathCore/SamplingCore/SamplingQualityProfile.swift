public enum SamplingQualityProfile: String, Codable, CaseIterable, Sendable {
    case preview
    case balanced
    case precise
    case exploratory
}
