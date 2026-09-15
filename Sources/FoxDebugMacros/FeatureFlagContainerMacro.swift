import SwiftSyntax
import SwiftSyntaxMacros

/// Member macro that generates a `static let all: [FeatureFlag]` property
/// containing all members annotated with `@FeatureToggle`.
///
/// Usage:
/// ```swift
/// @FeatureFlagContainer
/// enum DiskAnalyzerFlags {
///     @FeatureToggle(group: .core, stage: .development)
///     static var concurrentScan = "Concurrent Scan"
/// }
/// ```
///
/// Adds:
/// ```swift
/// static let all: [FeatureFlag] = [concurrentScan]
/// ```
public struct FeatureFlagContainerMacro: MemberMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let memberNames = declaration.memberBlock.members.compactMap { member -> String? in
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else {
                return nil
            }

            // Check if the variable has a @FeatureToggle attribute
            let hasFeatureToggle = varDecl.attributes.contains { attr in
                guard case let .attribute(attributeSyntax) = attr,
                      let identifier = attributeSyntax.attributeName.as(IdentifierTypeSyntax.self)
                else {
                    return false
                }
                return identifier.name.text == "FeatureToggle"
            }

            guard hasFeatureToggle else { return nil }

            // Extract the property name
            guard let binding = varDecl.bindings.first,
                  let pattern = binding.pattern.as(IdentifierPatternSyntax.self)
            else {
                return nil
            }

            return pattern.identifier.text
        }

        let arrayElements = memberNames.joined(separator: ", ")
        let allProperty: DeclSyntax = "static let all: [FeatureFlag] = [\(raw: arrayElements)]"

        return [allProperty]
    }
}
