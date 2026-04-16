import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(FoxFeatureToggleMacros)
import FoxFeatureToggleMacros
#endif

final class FeatureToggleMacroTests: XCTestCase {
    #if canImport(FoxFeatureToggleMacros)
    private let testMacros: [String: Macro.Type] = [
        "FeatureToggle": FeatureToggleMacro.self,
    ]

    func testBasicExpansion() throws {
        assertMacroExpansion(
            """
            @FeatureToggle(displayName: "Concurrent Scan", group: .core, stage: .development)
            static var concurrentScan: FeatureFlag
            """,
            expandedSource: """
            static var concurrentScan: FeatureFlag {
                get {
                    FeatureFlag(
                        key: "concurrentScan",
                        displayName: "Concurrent Scan",
                        group: .core,
                        stage: .development,
                        defaultValue: false
                    )
                }
            }
            """,
            macros: testMacros
        )
    }

    func testExpansionWithDefaultValueTrue() throws {
        assertMacroExpansion(
            """
            @FeatureToggle(displayName: "Dark Theme", group: .ui, stage: .released, defaultValue: true)
            static var darkTheme: FeatureFlag
            """,
            expandedSource: """
            static var darkTheme: FeatureFlag {
                get {
                    FeatureFlag(
                        key: "darkTheme",
                        displayName: "Dark Theme",
                        group: .ui,
                        stage: .released,
                        defaultValue: true
                    )
                }
            }
            """,
            macros: testMacros
        )
    }

    func testDiagnosticOnStaticLet() throws {
        assertMacroExpansion(
            """
            @FeatureToggle(displayName: "Test", group: .core, stage: .development)
            static let concurrentScan: FeatureFlag
            """,
            expandedSource: """
            static let concurrentScan: FeatureFlag
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@FeatureToggle requires 'static var', not 'static let'",
                    line: 1,
                    column: 1
                ),
            ],
            macros: testMacros
        )
    }

    func testDiagnosticOnMissingDisplayName() throws {
        assertMacroExpansion(
            """
            @FeatureToggle(group: .core, stage: .development)
            static var concurrentScan: FeatureFlag
            """,
            expandedSource: """
            static var concurrentScan: FeatureFlag
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@FeatureToggle requires a 'displayName' argument",
                    line: 1,
                    column: 1
                ),
            ],
            macros: testMacros
        )
    }
    #else
    func testMacrosRequireHostPlatform() throws {
        throw XCTSkip("Macros are only supported when running tests for the host platform")
    }
    #endif
}
