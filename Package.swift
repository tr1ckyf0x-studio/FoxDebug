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
        .library(name: "FoxDebugSettings", targets: ["FoxDebugSettings"]),
        .library(name: "FoxDebugSettingsUI", targets: ["FoxDebugSettingsUI"]),
        .library(name: "FoxRemoteConfig", targets: ["FoxRemoteConfig"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "509.0.0" ..< "601.0.0-prerelease"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.17.0"),
    ],
    targets: [
        // MARK: - FoxDebugMenu
        .target(name: "FoxDebugMenu"),

        // MARK: - FoxFeatureToggle
        .target(
            name: "FoxFeatureToggle",
            dependencies: ["FoxDebugMacros", "FoxRemoteConfig"]
        ),

        // MARK: - FoxDebugSettings
        .target(
            name: "FoxDebugSettings",
            dependencies: ["FoxDebugMacros", "FoxRemoteConfig"]
        ),

        // MARK: - FoxRemoteConfig
        .target(name: "FoxRemoteConfig"),

        // MARK: - FoxFeatureToggleUI
        .target(
            name: "FoxFeatureToggleUI",
            dependencies: ["FoxFeatureToggle", "FoxDebugMenu"]
        ),

        // MARK: - FoxDebugSettingsUI
        .target(
            name: "FoxDebugSettingsUI",
            dependencies: ["FoxDebugSettings", "FoxDebugMenu"]
        ),

        // MARK: - FoxDebugMacros
        .macro(
            name: "FoxDebugMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),

        // MARK: - Tests
        .testTarget(
            name: "FoxFeatureToggleTests",
            dependencies: ["FoxFeatureToggle", "FoxRemoteConfig"]
        ),
        .testTarget(
            name: "FoxDebugSettingsTests",
            dependencies: ["FoxDebugSettings", "FoxRemoteConfig"]
        ),
        .testTarget(
            name: "FoxRemoteConfigTests",
            dependencies: ["FoxRemoteConfig"]
        ),
        .testTarget(
            name: "FoxDebugUITests",
            dependencies: [
                "FoxDebugMenu",
                "FoxFeatureToggle",
                "FoxFeatureToggleUI",
                "FoxDebugSettings",
                "FoxDebugSettingsUI",
                "FoxRemoteConfig",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            exclude: ["__Snapshots__"]
        ),
        .testTarget(
            name: "FoxDebugMacrosTests",
            dependencies: [
                "FoxDebugMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
