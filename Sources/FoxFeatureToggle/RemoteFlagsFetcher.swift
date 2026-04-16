/// Fetches remote feature flag values from an external source.
///
/// Host apps implement this protocol to integrate with their remote config
/// provider (Firebase, LaunchDarkly, custom backend, etc).
///
/// Example:
/// ```swift
/// struct FirebaseRemoteFlagsFetcher: RemoteFlagsFetcher {
///     func fetch() async throws -> [String: Bool] {
///         // Fetch from Firebase Remote Config
///     }
/// }
/// ```
public protocol RemoteFlagsFetcher: Sendable {
    /// Returns the latest remote flag values.
    ///
    /// Values are keyed by `FeatureFlag.key`.
    func fetch() async throws -> [String: Bool]
}
