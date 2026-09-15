import SwiftSyntax
import SwiftSyntaxMacros

/// Member macro that generates a `static let all: [FeatureFlag]` property
/// containing all members annotated with `@FeatureToggle`, `#if`-guarded members included.
///
/// Usage:
/// ```swift
/// @FeatureFlagContainer
/// enum DiskAnalyzerFlags {
///     @FeatureToggle(displayName: "Concurrent Scan", group: .core, stage: .development)
///     static var concurrentScan: FeatureFlag
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
        [
            ContainerCollection.declaration(
                elementType: "FeatureFlag",
                members: declaration.memberBlock.members,
                attribute: "FeatureToggle",
                element: { $0 }
            ),
        ]
    }
}
