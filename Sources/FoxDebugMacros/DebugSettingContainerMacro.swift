import SwiftSyntax
import SwiftSyntaxMacros

/// Member macro that generates `static let all: [DebugSettingDescriptor]` from every `@DebugSetting`
/// member of the type, `#if`-guarded members included.
///
/// ```swift
/// @DebugSettingContainer
/// enum AppSettings {
///     @DebugSetting(displayName: "Custom URL", group: .network)
///     static var customURL: DebugText
/// }
/// // Generated: static let all: [DebugSettingDescriptor] = [customURL.descriptor]
/// ```
public struct DebugSettingContainerMacro: MemberMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        [
            ContainerCollection.declaration(
                elementType: "DebugSettingDescriptor",
                members: declaration.memberBlock.members,
                attribute: "DebugSetting",
                element: { "\($0).descriptor" }
            ),
        ]
    }
}
