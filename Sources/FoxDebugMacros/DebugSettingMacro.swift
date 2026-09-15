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
        case requiresStatic = "@DebugSetting requires a 'static var' inside a @DebugSettingContainer type"
        case requiresTypeAnnotation = "@DebugSetting requires an explicit 'DebugText' or 'DebugChoice<Option>' type"
        case requiresSingleBinding = "@DebugSetting requires a single property per declaration"
        case choiceRequiresDefault = "@DebugSetting on a 'DebugChoice' requires 'defaultValue'"
        case placeholderOnChoice = "'placeholder' applies only to 'DebugText'; a 'DebugChoice' shows a picker"

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

        guard varDecl.modifiers.contains(where: { [.keyword(.static), .keyword(.class)].contains($0.name.tokenKind) }) else {
            context.diagnose(Diagnostic(node: Syntax(node), message: DiagnosticMessage.requiresStatic))
            return []
        }

        // Checked on the syntax so a wrong or optional type is reported here, at the attribute, rather than
        // as an unrelated initialiser error inside the expansion.
        guard let type = binding.typeAnnotation?.type.trimmed,
              let kind = SettingKind(type)
        else {
            context.diagnose(Diagnostic(node: Syntax(node), message: DiagnosticMessage.requiresTypeAnnotation))
            return []
        }

        let arguments = node.arguments?.as(LabeledExprListSyntax.self).map(Array.init) ?? []
        if kind == .choice {
            if let placeholder = arguments.first(where: { $0.label?.text == "placeholder" }) {
                context.diagnose(Diagnostic(node: Syntax(placeholder), message: DiagnosticMessage.placeholderOnChoice))
                return []
            }
            guard arguments.contains(where: { $0.label?.text == "defaultValue" }) else {
                context.diagnose(Diagnostic(node: Syntax(node), message: DiagnosticMessage.choiceRequiresDefault))
                return []
            }
        }

        let forwarded = arguments.map { $0.with(\.trailingComma, nil).trimmedDescription }
        let key = pattern.identifier.unescapedText
        let initialiserArguments = (["key: \"\(key)\""] + forwarded).joined(separator: ", ")

        let accessor: AccessorDeclSyntax =
            """
            get {
                \(type)(\(raw: initialiserArguments))
            }
            """

        return [accessor]
    }

    private enum SettingKind {
        case text
        case choice

        /// Recognises `DebugText` and `DebugChoice<…>`, bare or module-qualified.
        init?(_ type: TypeSyntax) {
            let name: String
            let hasGenericArgument: Bool
            if let identifier = type.as(IdentifierTypeSyntax.self) {
                name = identifier.name.text
                hasGenericArgument = identifier.genericArgumentClause != nil
            } else if let member = type.as(MemberTypeSyntax.self) {
                name = member.name.text
                hasGenericArgument = member.genericArgumentClause != nil
            } else {
                return nil
            }

            switch (name, hasGenericArgument) {
            case ("DebugText", false): self = .text
            case ("DebugChoice", true): self = .choice
            default: return nil
            }
        }
    }
}
