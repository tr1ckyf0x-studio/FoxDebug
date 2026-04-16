/// Grouping identifier for feature flags.
///
/// Defined as a struct (not enum) so host apps can extend it
/// with their own groups without modifying the package.
///
/// Usage in host app:
/// ```swift
/// extension FeatureFlagGroup {
///     static let diskAnalyzer = FeatureFlagGroup(rawValue: "Disk Analyzer")
///     static let uninstaller = FeatureFlagGroup(rawValue: "Uninstaller")
/// }
/// ```
public struct FeatureFlagGroup: Hashable, Sendable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
