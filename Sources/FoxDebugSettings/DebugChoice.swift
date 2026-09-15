/// A debug setting that picks one case of `Option`, shown in the debug menu as a picker.
///
/// Declared with `@DebugSetting` inside a `@DebugSettingContainer`, or constructed directly.
public struct DebugChoice<Option: DebugChoiceOption>: Hashable, Sendable {
    public let descriptor: DebugSettingDescriptor
    public let defaultValue: Option

    public init(
        key: String,
        displayName: String,
        group: DebugSettingGroup,
        defaultValue: Option,
        acceptsRemote: Bool = false
    ) {
        self.defaultValue = defaultValue
        descriptor = DebugSettingDescriptor(
            key: key,
            displayName: displayName,
            group: group,
            kind: .choice(options: Option.allCases.map { DebugSettingDescriptor.Option(rawValue: $0.rawValue, title: $0.title) }),
            defaultRawValue: defaultValue.rawValue,
            acceptsRemote: acceptsRemote
        )
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.descriptor == rhs.descriptor
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(descriptor)
    }
}
