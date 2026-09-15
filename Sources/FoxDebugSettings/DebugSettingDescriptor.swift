/// Type-erased definition of a debug setting: what the registry lists and the debug menu renders.
///
/// Every value is stored and resolved as a string — a choice as its option's `rawValue` — so one
/// store and one remote dictionary serve every kind.
public struct DebugSettingDescriptor: Hashable, Sendable, Identifiable {
    public enum Kind: Hashable, Sendable {
        case text(placeholder: String)
        case choice(options: [Option])
    }

    public struct Option: Hashable, Sendable {
        public let rawValue: String
        public let title: String

        public init(rawValue: String, title: String) {
            self.rawValue = rawValue
            self.title = title
        }
    }

    /// Unique identifier, derived from the property name by `@DebugSetting`.
    public let key: String
    public let displayName: String
    public let group: DebugSettingGroup
    public let kind: Kind
    public let defaultRawValue: String

    /// Whether a remote value may replace the default. Off by default: a setting that points the app
    /// somewhere, such as a server, must not be switchable from outside.
    public let acceptsRemote: Bool

    public var id: String { key }

    public init(
        key: String,
        displayName: String,
        group: DebugSettingGroup,
        kind: Kind,
        defaultRawValue: String,
        acceptsRemote: Bool
    ) {
        self.key = key
        self.displayName = displayName
        self.group = group
        self.kind = kind
        self.defaultRawValue = defaultRawValue
        self.acceptsRemote = acceptsRemote
    }

    /// Whether `rawValue` is something this setting can hold. Any string fits a text setting; a choice
    /// only takes the raw value of one of its options.
    public func accepts(_ rawValue: String) -> Bool {
        switch kind {
        case .text:
            true
        case let .choice(options):
            options.contains { $0.rawValue == rawValue }
        }
    }
}
