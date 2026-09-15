/// Fetches remote values from an external source.
///
/// Host apps implement this protocol to integrate with their remote config provider (Firebase,
/// LaunchDarkly, their own backend).
///
/// ```swift
/// struct BackendRemoteConfigFetcher: RemoteConfigFetcher {
///     func fetch() async throws -> RemoteConfig {
///         let response = try await api.remoteConfig()
///         return RemoteConfig(flags: response.flags, settings: response.settings)
///     }
/// }
/// ```
public protocol RemoteConfigFetcher: Sendable {
    /// Returns the latest remote values.
    func fetch() async throws -> RemoteConfig
}
