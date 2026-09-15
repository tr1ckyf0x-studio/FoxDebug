/// Turns a `static var` of type `DebugText` into a computed property. The property name becomes the key.
///
/// ```swift
/// @DebugSetting(displayName: "Custom URL", group: .network, placeholder: "https://…")
/// static var customURL: DebugText
/// ```
///
/// - Important: Must be applied to `static var` (not `static let`).
@attached(accessor)
public macro DebugSetting(
    displayName: String,
    group: DebugSettingGroup,
    defaultValue: String = "",
    placeholder: String = "",
    acceptsRemote: Bool = false
) = #externalMacro(module: "FoxDebugMacros", type: "DebugSettingMacro")

/// Turns a `static var` of type `DebugChoice<Option>` into a computed property. The property name
/// becomes the key.
///
/// ```swift
/// @DebugSetting(displayName: "Stand", group: .network, defaultValue: Stand.production)
/// static var stand: DebugChoice<Stand>
///
/// // Or name the option type on the attribute and write the default as an implicit member:
/// @DebugSetting<Stand>(displayName: "Stand", group: .network, defaultValue: .production)
/// static var stand: DebugChoice<Stand>
/// ```
///
/// - Important: Macro arguments are type-checked before the property they are attached to is known, so
///   `defaultValue: .production` alone has no type to resolve against — give it one of the two ways above.
@attached(accessor)
public macro DebugSetting<Option: DebugChoiceOption>(
    displayName: String,
    group: DebugSettingGroup,
    defaultValue: Option,
    acceptsRemote: Bool = false
) = #externalMacro(module: "FoxDebugMacros", type: "DebugSettingMacro")

/// Generates `static let all: [DebugSettingDescriptor]` from every `@DebugSetting` member of the type.
@attached(member, names: named(all))
public macro DebugSettingContainer() = #externalMacro(module: "FoxDebugMacros", type: "DebugSettingContainerMacro")
