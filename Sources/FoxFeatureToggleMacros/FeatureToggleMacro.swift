import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// Accessor macro that transforms a `static var name: FeatureFlag` declaration
/// into a computed property returning a `FeatureFlag`.
///
/// Usage:
/// ```swift
/// @FeatureToggle(displayName: "Concurrent Scan", group: .core, stage: .development)
/// static var concurrentScan: FeatureFlag
/// ```
///
/// Expands to:
/// ```swift
/// static var concurrentScan: FeatureFlag {
///     get {
///         FeatureFlag(
///             key: "concurrentScan",
///             displayName: "Concurrent Scan",
///             group: .core,
///             stage: .development,
///             defaultValue: false
///         )
///     }
/// }
/// ```
public struct FeatureToggleMacro: AccessorMacro {

    // MARK: - Diagnostics

    private enum DiagnosticMessage: String, SwiftDiagnostics.DiagnosticMessage {
        case requiresStaticVar = "@FeatureToggle requires 'static var', not 'static let'"
        case missingDisplayName = "@FeatureToggle requires a 'displayName' argument"

        var severity: DiagnosticSeverity { .error }

        var message: String { rawValue }

        var diagnosticID: MessageID {
            MessageID(domain: "FoxFeatureToggleMacros", id: rawValue)
        }
    }

    // MARK: - AccessorMacro

    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self) else {
            return []
        }

        // Must be `var`, not `let`
        if varDecl.bindingSpecifier.tokenKind == .keyword(.let) {
            context.diagnose(
                Diagnostic(
                    node: Syntax(node),
                    message: DiagnosticMessage.requiresStaticVar
                )
            )
            return []
        }

        guard let binding = varDecl.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self)
        else {
            return []
        }

        let propertyName = pattern.identifier.text

        // Extract macro arguments
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return []
        }

        var displayNameExpr: String?
        var groupExpr: String?
        var stageExpr: String?
        var defaultValueExpr: String = "false"

        for argument in arguments {
            let label = argument.label?.text
            let value = argument.expression.description.trimmingCharacters(in: .whitespaces)
            switch label {
            case "displayName":
                // Strip surrounding quotes from the string literal
                if let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self),
                   let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                    displayNameExpr = segment.content.text
                }
            case "group":
                groupExpr = value
            case "stage":
                stageExpr = value
            case "defaultValue":
                defaultValueExpr = value
            default:
                break
            }
        }

        guard let displayName = displayNameExpr else {
            context.diagnose(
                Diagnostic(
                    node: Syntax(node),
                    message: DiagnosticMessage.missingDisplayName
                )
            )
            return []
        }

        guard let group = groupExpr, let stage = stageExpr else {
            return []
        }

        let accessor: AccessorDeclSyntax =
            """
            get {
                FeatureFlag(
                    key: \(literal: propertyName),
                    displayName: \(literal: displayName),
                    group: \(raw: group),
                    stage: \(raw: stage),
                    defaultValue: \(raw: defaultValueExpr)
                )
            }
            """

        return [accessor]
    }
}
