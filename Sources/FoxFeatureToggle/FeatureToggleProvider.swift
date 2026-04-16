import SwiftUI

/// Default implementation of `ProvidesFeatureToggle`.
///
/// Resolves flag values using the priority chain:
/// Debug Override → Remote Value (.released only) → Default Value.
@MainActor
public final class FeatureToggleProvider: ProvidesFeatureToggle, ObservableObject {
    private let overrideStore: any FeatureToggleOverrideStore
    @Published private var remoteValues: [String: Bool] = [:]

    public init(overrideStore: any FeatureToggleOverrideStore = UserDefaultsFeatureToggleOverrideStore()) {
        self.overrideStore = overrideStore
    }

    public func isEnabled(_ flag: FeatureFlag) -> Bool {
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
}
