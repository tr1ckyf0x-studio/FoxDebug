/// A free-text debug setting, shown in the debug menu as a text field.
///
/// Declared with `@DebugSetting` inside a `@DebugSettingContainer`, or constructed directly.
public struct DebugText: Hashable, Sendable {
    public let descriptor: DebugSettingDescriptor

    public var defaultValue: String { descriptor.defaultRawValue }

    public init(
        key: String,
        displayName: String,
        group: DebugSettingGroup,
        defaultValue: String = "",
        placeholder: String = "",
        acceptsRemote: Bool = false
    ) {
        descriptor = DebugSettingDescriptor(
            key: key,
            displayName: displayName,
            group: group,
            kind: .text(placeholder: placeholder),
            defaultRawValue: defaultValue,
            acceptsRemote: acceptsRemote
        )
    }
}
