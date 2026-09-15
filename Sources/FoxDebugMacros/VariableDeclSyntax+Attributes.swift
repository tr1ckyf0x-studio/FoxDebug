import SwiftSyntax

extension VariableDeclSyntax {
    /// Whether the declaration carries `@name`, written bare or qualified by its module
    /// (`@FoxDebugSettings.DebugSetting`) — a container macro must collect both spellings.
    func hasAttribute(named name: String) -> Bool {
        attributes.contains { element in
            guard case let .attribute(attribute) = element else {
                return false
            }
            if let identifier = attribute.attributeName.as(IdentifierTypeSyntax.self) {
                return identifier.name.text == name
            }
            if let member = attribute.attributeName.as(MemberTypeSyntax.self) {
                return member.name.text == name
            }
            return false
        }
    }
}
