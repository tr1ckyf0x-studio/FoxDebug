import Observation

/// Collects the debug settings the debug menu lists.
///
/// Settings are registered at app startup from `@DebugSettingContainer` enums. A setting that was never
/// registered still resolves through `DebugSettingsProvider`; it just cannot be changed from the menu.
@MainActor
@Observable
public final class DebugSettingRegistry {
    public private(set) var settings: [DebugSettingDescriptor] = []

    public init() {}

    /// Registers settings, typically a `@DebugSettingContainer`'s `all`. Registering the same setting twice
    /// lists it once. Two different settings under one key — `baseURL` declared in two containers — would
    /// share a stored value, so that asserts.
    public func register(_ settings: [DebugSettingDescriptor]) {
        for setting in settings {
            guard let existing = self.settings.first(where: { $0.key == setting.key }) else {
                self.settings.append(setting)
                continue
            }
            assert(existing == setting, "Debug setting key '\(setting.key)' is declared twice with different definitions")
        }
    }

    public var groups: [DebugSettingGroup] {
        var seen = Set<DebugSettingGroup>()
        return settings.map(\.group).filter { seen.insert($0).inserted }
    }
}
