// swift-tools-version: 5.10

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "FoxDebug",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(name: "FoxDebugMenu", targets: ["FoxDebugMenu"]),
        .library(name: "FoxFeatureToggle", targets: ["FoxFeatureToggle"]),
        .library(name: "FoxFeatureToggleUI", targets: ["FoxFeatureToggleUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "509.0.0" ..< "601.0.0-prerelease"),
    ],
    targets: [
        // MARK: - FoxDebugMenu
        .target(name: "FoxDebugMenu"),

        // MARK: - FoxFeatureToggle
        .target(
            name: "FoxFeatureToggle",
            dependencies: ["FoxFeatureToggleMacros"]
        ),

        // MARK: - FoxFeatureToggleUI
        .target(
            name: "FoxFeatureToggleUI",
            dependencies: ["FoxFeatureToggle", "FoxDebugMenu"]
        ),

        // MARK: - FoxFeatureToggleMacros
        .macro(
            name: "FoxFeatureToggleMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),

        // MARK: - Tests
        .testTarget(
            name: "FoxFeatureToggleTests",
            dependencies: ["FoxFeatureToggle"]
        ),
        .testTarget(
            name: "FoxFeatureToggleMacrosTests",
            dependencies: [
                "FoxFeatureToggleMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
