import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(FoxFeatureToggleMacros)
import FoxFeatureToggleMacros
#endif

final class FeatureFlagContainerMacroTests: XCTestCase {
    #if canImport(FoxFeatureToggleMacros)
    private let testMacros: [String: Macro.Type] = [
        "FeatureFlagContainer": FeatureFlagContainerMacro.self,
        "FeatureToggle": FeatureToggleMacro.self,
    ]

    func testGeneratesAllProperty() throws {
        assertMacroExpansion(
            """
            @FeatureFlagContainer
            enum DiskAnalyzerFlags {
                @FeatureToggle(displayName: "Concurrent Scan", group: .core, stage: .development)
                static var concurrentScan: FeatureFlag

                @FeatureToggle(displayName: "Sunburst View", group: .core, stage: .released)
                static var sunburstView: FeatureFlag
            }
            """,
            expandedSource: """
            enum DiskAnalyzerFlags {
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
                static var sunburstView: FeatureFlag {
                    get {
                        FeatureFlag(
                            key: "sunburstView",
                            displayName: "Sunburst View",
                            group: .core,
                            stage: .released,
                            defaultValue: false
                        )
                    }
                }

                static let all: [FeatureFlag] = [concurrentScan, sunburstView]
            }
            """,
            macros: testMacros
        )
    }

    func testEmptyContainerGeneratesEmptyAll() throws {
        assertMacroExpansion(
            """
            @FeatureFlagContainer
            enum EmptyFlags {
            }
            """,
            expandedSource: """
            enum EmptyFlags {

                static let all: [FeatureFlag] = []
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
