import SwiftSyntax

extension TokenSyntax {
    /// The identifier without the backticks of an escaped name: `` `default` `` gives `default`. A key
    /// derived from a property name must not carry them.
    var unescapedText: String {
        text.filter { $0 != "`" }
    }
}
