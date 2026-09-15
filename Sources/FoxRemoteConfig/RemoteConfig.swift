/// Remote values for every mechanism that accepts them, as delivered by a `RemoteConfigFetcher`.
///
/// Flags and settings are kept in separate dictionaries rather than one keyed by name: a flag and a
/// setting may share a key, and each consumer reads only the values of its own type.
public struct RemoteConfig: Codable, Equatable, Sendable {
    /// Feature flag values, keyed by `FeatureFlag.key`.
    public var flags: [String: Bool]

    /// Debug setting values, keyed by `DebugSettingDescriptor.key`. A choice is its option's `rawValue`.
    public var settings: [String: String]

    public init(flags: [String: Bool] = [:], settings: [String: String] = [:]) {
        self.flags = flags
        self.settings = settings
    }

    public static let empty = RemoteConfig()

    // A missing dictionary decodes as empty: a cache written by an older version, or a backend that only
    // sends flags, must still load rather than fail the whole config.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        flags = try container.decodeIfPresent([String: Bool].self, forKey: .flags) ?? [:]
        settings = try container.decodeIfPresent([String: String].self, forKey: .settings) ?? [:]
    }
}
