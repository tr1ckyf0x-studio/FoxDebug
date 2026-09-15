import FoxRemoteConfig
import SwiftUI

/// Where a resolved flag value came from.
public enum FeatureFlagSource: Sendable {
    /// Forced on or off in the debug menu.
    case override
    /// Delivered remotely; only for `.released` flags.
    case remote
    /// Neither of the above.
    case defaultValue
}

/// Default implementation of `ProvidesFeatureToggle`.
///
/// Resolves flag values using the priority chain:
/// Debug Override → Remote Value (.released only) → Default Value.
@MainActor
@Observable
public final class FeatureToggleProvider: ProvidesFeatureToggle {
    @ObservationIgnored private let overrideStore: any FeatureToggleOverrideStore
    private var remoteValues: [String: Bool] = [:]

    // Version counter used to invalidate observers when the external
    // override store changes (overrides live outside of this type, so
    // mutating them does not otherwise trigger @Observable updates).
    private var overrideRevision: Int = 0

    public init(overrideStore: any FeatureToggleOverrideStore = UserDefaultsFeatureToggleOverrideStore()) {
        self.overrideStore = overrideStore
    }

    public func isEnabled(_ flag: FeatureFlag) -> Bool {
        resolve(flag).isEnabled
    }

    public func source(for flag: FeatureFlag) -> FeatureFlagSource {
        resolve(flag).source
    }

    public func applyRemoteConfig(_ config: RemoteConfig) {
        remoteValues = config.flags
    }

    /// Notifies observers that external overrides have changed and cached
    /// `isEnabled(_:)` results should be re-evaluated.
    public func notifyOverridesChanged() {
        // `&+=` — wrapping addition: on overflow the value wraps around
        // (Int.max → Int.min) instead of trapping. The counter value itself
        // is meaningless; observers only care that it changed, so wrapping
        // is safe and keeps the app from crashing in the (theoretical) case
        // of an extremely long-lived session with millions of toggles.
        overrideRevision &+= 1
    }

    private func resolve(_ flag: FeatureFlag) -> (isEnabled: Bool, source: FeatureFlagSource) {
        // Register observation dependency so that `notifyOverridesChanged()`
        // invalidates views that read flag values.
        _ = overrideRevision

        switch overrideStore.override(for: flag) {
        case .forceEnabled:
            return (true, .override)
        case .forceDisabled:
            return (false, .override)
        case .defaultValue, nil:
            break
        }

        if flag.stage == .released, let remote = remoteValues[flag.key] {
            return (remote, .remote)
        }

        return (flag.defaultValue, .defaultValue)
    }
}
