import FoxRemoteConfig
import os

/// Where a resolved setting value came from.
public enum DebugSettingSource: Sendable {
    /// Set in the debug menu.
    case local
    /// Delivered remotely; only for settings with `acceptsRemote`.
    case remote
    /// Neither of the above.
    case defaultValue
}

/// Resolves debug setting values: local value → remote value (`acceptsRemote` only) → default.
///
/// Unlike `FeatureToggleProvider` it is not bound to the main actor, and reads are synchronous from any
/// thread: settings typically configure infrastructure — a base URL, a log level — that is built off
/// the main actor. A stored or remote value that the setting cannot hold, such as the raw value of an
/// option since removed from its enum, is skipped rather than trusted.
public final class DebugSettingsProvider: Sendable {
    private let store: any DebugSettingStore
    private let remoteValues = OSAllocatedUnfairLock<[String: String]>(initialState: [:])

    public init(store: any DebugSettingStore = UserDefaultsDebugSettingStore()) {
        self.store = store
    }

    public func value(_ setting: DebugText) -> String {
        rawValue(for: setting.descriptor)
    }

    public func value<Option>(_ setting: DebugChoice<Option>) -> Option {
        Option(rawValue: rawValue(for: setting.descriptor)) ?? setting.defaultValue
    }

    public func rawValue(for descriptor: DebugSettingDescriptor) -> String {
        resolve(descriptor).rawValue
    }

    public func source(for descriptor: DebugSettingDescriptor) -> DebugSettingSource {
        resolve(descriptor).source
    }

    public func setRawValue(_ rawValue: String, for descriptor: DebugSettingDescriptor) {
        store.setRawValue(rawValue, forKey: descriptor.key)
    }

    /// Whether the store holds a value for the setting — including one it no longer accepts, which
    /// `source(for:)` does not report as `.local` but which `reset` still has something to remove.
    public func hasStoredValue(for descriptor: DebugSettingDescriptor) -> Bool {
        store.rawValue(forKey: descriptor.key) != nil
    }

    /// Removes the local value, so the setting falls back to its remote or default value.
    public func reset(_ descriptor: DebugSettingDescriptor) {
        store.removeValue(forKey: descriptor.key)
    }

    private func resolve(_ descriptor: DebugSettingDescriptor) -> (rawValue: String, source: DebugSettingSource) {
        if let local = store.rawValue(forKey: descriptor.key), descriptor.accepts(local) {
            return (local, .local)
        }
        if descriptor.acceptsRemote,
           let remote = remoteValues.withLock({ $0[descriptor.key] }),
           descriptor.accepts(remote) {
            return (remote, .remote)
        }
        return (descriptor.defaultRawValue, .defaultValue)
    }
}

// Declared in an extension: a conformance on the type itself would infer `@MainActor` for the whole
// class from the protocol, and reads must stay callable from any thread.
extension DebugSettingsProvider: AppliesRemoteConfig {
    public nonisolated func applyRemoteConfig(_ config: RemoteConfig) {
        remoteValues.withLock { $0 = config.settings }
    }
}
