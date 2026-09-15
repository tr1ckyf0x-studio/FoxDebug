import SwiftSyntax
import SwiftSyntaxMacros

/// Member macro that generates `static let all: [DebugSettingDescriptor]` from every `@DebugSetting`
/// member of the type.
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
        let descriptors = declaration.memberBlock.members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .filter { $0.hasAttribute(named: "DebugSetting") }
            .compactMap { $0.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text }
            .map { "\($0).descriptor" }

        return ["static let all: [DebugSettingDescriptor] = [\(raw: descriptors.joined(separator: ", "))]"]
    }
}

extension VariableDeclSyntax {
    func hasAttribute(named name: String) -> Bool {
        attributes.contains { element in
            guard case let .attribute(attribute) = element,
                  let identifier = attribute.attributeName.as(IdentifierTypeSyntax.self)
            else {
                return false
            }
            return identifier.name.text == name
        }
    }
}
