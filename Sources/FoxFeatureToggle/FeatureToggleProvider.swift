import SwiftUI

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
        // Register observation dependency so that `notifyOverridesChanged()`
        // invalidates views that read flag values.
        _ = overrideRevision

        // Priority 1: Debug override
        if let override = overrideStore.override(for: flag) {
            switch override {
            case .forceEnabled:
                return true
            case .forceDisabled:
                return false
            case .defaultValue:
                break
            }
        }

        // Priority 2: Remote value (only for .released stage)
        if flag.stage == .released, let remote = remoteValues[flag.key] {
            return remote
        }

        // Priority 3: Default value
        return flag.defaultValue
    }

    public func loadRemoteFlags(_ flags: [String: Bool]) async {
        remoteValues = flags
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
}
