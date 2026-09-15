import SwiftSyntax

/// Builds the `static let all` a container macro adds, from every member carrying a given attribute —
/// including members inside `#if` blocks, which a walk over the direct members alone silently drops.
///
/// Without `#if` the collection is a plain array literal. With it, `#if` cannot appear inside a literal,
/// so the collection is built by a closure that repeats the same `#if` structure around its appends.
enum ContainerCollection {
    private indirect enum Item {
        case element(String)
        case conditional([(keyword: String, condition: String?, items: [Item])])
    }

    static func declaration(
        elementType: String,
        members: MemberBlockItemListSyntax,
        attribute: String,
        element: (String) -> String
    ) -> DeclSyntax {
        let items = collect(members, attribute: attribute, element: element)

        guard items.contains(where: { if case .conditional = $0 { true } else { false } }) else {
            let elements = items.compactMap { if case let .element(value) = $0 { value } else { nil } }
            return "static let all: [\(raw: elementType)] = [\(raw: elements.joined(separator: ", "))]"
        }

        let body = render(items).joined(separator: "\n")
        return """
            static let all: [\(raw: elementType)] = {
            var all: [\(raw: elementType)] = []
            \(raw: body)
            return all
            }()
            """
    }

    private static func collect(
        _ members: MemberBlockItemListSyntax,
        attribute: String,
        element: (String) -> String
    ) -> [Item] {
        members.compactMap { member -> Item? in
            if let ifConfig = member.decl.as(IfConfigDeclSyntax.self) {
                let clauses = ifConfig.clauses.map { clause in
                    let nested: [Item]
                    if case let .decls(decls) = clause.elements {
                        nested = collect(decls, attribute: attribute, element: element)
                    } else {
                        nested = []
                    }
                    return (keyword: clause.poundKeyword.text, condition: clause.condition?.trimmedDescription, items: nested)
                }
                return clauses.allSatisfy(\.items.isEmpty) ? nil : .conditional(clauses)
            }

            guard let variable = member.decl.as(VariableDeclSyntax.self),
                  variable.hasAttribute(named: attribute),
                  let name = variable.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
            else {
                return nil
            }
            return .element(element(name))
        }
    }

    private static func render(_ items: [Item]) -> [String] {
        items.flatMap { item -> [String] in
            switch item {
            case let .element(value):
                return ["all.append(\(value))"]
            case let .conditional(clauses):
                let lines = clauses.flatMap { clause in
                    [[clause.keyword, clause.condition].compactMap { $0 }.joined(separator: " ")] + render(clause.items)
                }
                return lines + ["#endif"]
            }
        }
    }
}
