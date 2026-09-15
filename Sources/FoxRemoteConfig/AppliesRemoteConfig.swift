/// A mechanism that takes remote values: `FeatureToggleProvider` and `DebugSettingsProvider` both
/// conform, so one `RemoteConfigBootstrap` feeds them together.
@MainActor
public protocol AppliesRemoteConfig: Sendable {
    /// Replaces the remote values in effect with those in `config`.
    func applyRemoteConfig(_ config: RemoteConfig)
}
