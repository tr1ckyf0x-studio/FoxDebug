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
/// ```
///
/// - Important: Spell the default out with its type (`Stand.production`, not `.production`): macro
///   arguments are type-checked before the declaration they are attached to is known.
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
