import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct FoxFeatureToggleMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        FeatureToggleMacro.self,
        FeatureFlagContainerMacro.self,
    ]
}
