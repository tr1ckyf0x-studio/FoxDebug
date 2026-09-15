import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// Accessor macro that turns `static var name: DebugText` or `static var name: DebugChoice<Option>`
/// into a computed property constructing that type.
///
/// The attribute's arguments are forwarded to the initialiser as written, with `key` prepended. The
/// compiler, not the macro, then checks them against `DebugText` or `DebugChoice`, which is why this
/// macro never has to know which of the two it is expanding.
///
/// ```swift
/// @DebugSetting(displayName: "Stand", group: .network, defaultValue: Stand.production)
/// static var stand: DebugChoice<Stand>
/// ```
///
/// Expands to:
/// ```swift
/// static var stand: DebugChoice<Stand> {
///     get {
///         DebugChoice<Stand>(key: "stand", displayName: "Stand", group: .network, defaultValue: Stand.production)
///     }
/// }
/// ```
public struct DebugSettingMacro: AccessorMacro {

    // MARK: - Diagnostics

    private enum DiagnosticMessage: String, SwiftDiagnostics.DiagnosticMessage {
        case requiresStaticVar = "@DebugSetting requires 'static var', not 'static let'"
        case requiresTypeAnnotation = "@DebugSetting requires an explicit 'DebugText' or 'DebugChoice<Option>' type"
        case requiresSingleBinding = "@DebugSetting requires a single property per declaration"

        var severity: DiagnosticSeverity { .error }

        var message: String { rawValue }

        var diagnosticID: MessageID {
            MessageID(domain: "FoxDebugMacros", id: rawValue)
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

        if varDecl.bindingSpecifier.tokenKind == .keyword(.let) {
            context.diagnose(Diagnostic(node: Syntax(node), message: DiagnosticMessage.requiresStaticVar))
            return []
        }

        guard varDecl.bindings.count == 1, let binding = varDecl.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self)
        else {
            context.diagnose(Diagnostic(node: Syntax(node), message: DiagnosticMessage.requiresSingleBinding))
            return []
        }

        guard let type = binding.typeAnnotation?.type.trimmed else {
            context.diagnose(Diagnostic(node: Syntax(node), message: DiagnosticMessage.requiresTypeAnnotation))
            return []
        }

        let forwarded = node.arguments?.as(LabeledExprListSyntax.self)?
            .map { $0.with(\.trailingComma, nil).trimmedDescription }
            ?? []
        // `text` keeps the backticks of an escaped name such as `default`; the key must not.
        let key = pattern.identifier.text.filter { $0 != "`" }
        let arguments = (["key: \"\(key)\""] + forwarded).joined(separator: ", ")

        let accessor: AccessorDeclSyntax =
            """
            get {
                \(type)(\(raw: arguments))
            }
            """

        return [accessor]
    }
}
