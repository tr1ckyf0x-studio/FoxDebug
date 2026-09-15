import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct FoxDebugMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        FeatureToggleMacro.self,
        FeatureFlagContainerMacro.self,
    ]
}
