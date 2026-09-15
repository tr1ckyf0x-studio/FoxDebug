import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(FoxDebugMacros)
import FoxDebugMacros
#endif

final class DebugSettingMacroTests: XCTestCase {
    #if canImport(FoxDebugMacros)
    private let testMacros: [String: Macro.Type] = [
        "DebugSetting": DebugSettingMacro.self,
        "DebugSettingContainer": DebugSettingContainerMacro.self,
    ]

    func testTextExpansionPrependsKeyAndForwardsArguments() {
        assertMacroExpansion(
            """
            @DebugSetting(displayName: "Custom URL", group: .network, placeholder: "https://…")
            static var customURL: DebugText
            """,
            expandedSource: """
            static var customURL: DebugText {
                get {
                    DebugText(key: "customURL", displayName: "Custom URL", group: .network, placeholder: "https://…")
                }
            }
            """,
            macros: testMacros
        )
    }

    func testChoiceExpansionKeepsGenericArgument() {
        assertMacroExpansion(
            """
            @DebugSetting(displayName: "Stand", group: .network, defaultValue: Stand.production, acceptsRemote: false)
            static var stand: DebugChoice<Stand>
            """,
            expandedSource: """
            static var stand: DebugChoice<Stand> {
                get {
                    DebugChoice<Stand>(key: "stand", displayName: "Stand", group: .network, defaultValue: Stand.production, acceptsRemote: false)
                }
            }
            """,
            macros: testMacros
        )
    }

    func testMultilineArgumentsAreForwardedIntact() {
        assertMacroExpansion(
            """
            @DebugSetting(
                displayName: "Greeting \\(1)",
                group: DebugSettingGroup(rawValue: "A, B"),
                defaultValue: "a, b"
            )
            static var greeting: DebugText
            """,
            expandedSource: """
            static var greeting: DebugText {
                get {
                    DebugText(key: "greeting", displayName: "Greeting \\(1)", group: DebugSettingGroup(rawValue: "A, B"), defaultValue: "a, b")
                }
            }
            """,
            macros: testMacros
        )
    }

    func testBacktickedNameKeepsBackticksOutOfTheKey() {
        assertMacroExpansion(
            """
            @DebugSetting(displayName: "Default", group: .network)
            static var `default`: DebugText
            """,
            expandedSource: """
            static var `default`: DebugText {
                get {
                    DebugText(key: "default", displayName: "Default", group: .network)
                }
            }
            """,
            macros: testMacros
        )
    }

    func testDiagnosticOnStaticLet() {
        assertMacroExpansion(
            """
            @DebugSetting(displayName: "Stand", group: .network)
            static let stand: DebugText
            """,
            expandedSource: """
            static let stand: DebugText
            """,
            diagnostics: [
                DiagnosticSpec(message: "@DebugSetting requires 'static var', not 'static let'", line: 1, column: 1),
            ],
            macros: testMacros
        )
    }

    func testDiagnosticOnMissingType() {
        assertMacroExpansion(
            """
            @DebugSetting(displayName: "Stand", group: .network)
            static var stand = DebugText(key: "stand", displayName: "Stand", group: .network)
            """,
            expandedSource: """
            static var stand = DebugText(key: "stand", displayName: "Stand", group: .network)
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@DebugSetting requires an explicit 'DebugText' or 'DebugChoice<Option>' type",
                    line: 1,
                    column: 1
                ),
            ],
            macros: testMacros
        )
    }

    func testContainerCollectsOnlyDebugSettings() {
        assertMacroExpansion(
            """
            @DebugSettingContainer
            enum Settings {
                @DebugSetting(displayName: "A", group: .network)
                static var first: DebugText
                static var helper: Int { 0 }
                @DebugSetting(displayName: "B", group: .network, defaultValue: Stand.production)
                static var second: DebugChoice<Stand>
            }
            """,
            expandedSource: """
            enum Settings {
                static var first: DebugText {
                    get {
                        DebugText(key: "first", displayName: "A", group: .network)
                    }
                }
                static var helper: Int { 0 }
                static var second: DebugChoice<Stand> {
                    get {
                        DebugChoice<Stand>(key: "second", displayName: "B", group: .network, defaultValue: Stand.production)
                    }
                }

                static let all: [DebugSettingDescriptor] = [first.descriptor, second.descriptor]
            }
            """,
            macros: testMacros
        )
    }

    func testEmptyContainer() {
        assertMacroExpansion(
            """
            @DebugSettingContainer
            enum Settings {
            }
            """,
            expandedSource: """
            enum Settings {

                static let all: [DebugSettingDescriptor] = []
            }
            """,
            macros: testMacros
        )
    }
    #else
    func testMacrosRequireHostPlatform() throws {
        throw XCTSkip("Macros are only supported when running tests for the host platform")
    }
    #endif
}
