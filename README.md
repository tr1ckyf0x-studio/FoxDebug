# FoxDebug

Reusable debug menu and feature toggle system for Swift apps.

## Modules

| Module | Description |
|--------|-------------|
| FoxDebugMenu | Universal debug menu with plugin-based section registration |
| FoxFeatureToggle | Feature toggle runtime: flag definitions, provider, override store, macros |
| FoxFeatureToggleUI | Pre-built debug section for feature toggle management |
| FoxFeatureToggleMacros | Swift macros (@FeatureToggle, @FeatureFlagContainer) |

## Requirements

- Swift 5.10+
- macOS 14+
- iOS 17+

## Installation

Add FoxDebug as a Swift Package Manager dependency in your `Package.swift`:

```swift
.package(url: "https://github.com/tr1ckyf0x-studio/FoxDebug.git", from: "1.0.0")
```

Then add the required modules to your target:

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "FoxDebugMenu", package: "FoxDebug"),
        .product(name: "FoxFeatureToggle", package: "FoxDebug"),
        .product(name: "FoxFeatureToggleUI", package: "FoxDebug"),
    ]
)
```

## Quick Start

```swift
import FoxDebugMenu
import FoxFeatureToggle
import FoxFeatureToggleUI

// 1. Define flag groups
extension FeatureFlagGroup {
    static let app = FeatureFlagGroup(rawValue: "App")
}

// 2. Create a flag container with macros
@FeatureFlagContainer
enum AppFlags {
    @FeatureToggle(group: .app, stage: .development)
    static var myFeature = "My Feature"
}

// 3. Set up provider, registries, and debug menu at app init
let overrideStore = FeatureToggleOverrideStore()
let provider = FeatureToggleProvider(
    flags: AppFlags.allFlags,
    overrideStore: overrideStore
)

let debugMenuRegistry = DebugMenuRegistry()
let featureToggleRegistry = FeatureToggleRegistry(
    provider: provider,
    overrideStore: overrideStore
)
debugMenuRegistry.register(
    FeatureToggleDebugSection(registry: featureToggleRegistry)
)

// 4. Check flag state
if provider.isEnabled(AppFlags.myFeature) {
    // feature is active
}
```

## Adding Feature Flags

Use `@FeatureFlagContainer` on an enum and `@FeatureToggle` on each flag. Note: flags must be declared as `static var`, not `static let`.

```swift
import FoxFeatureToggle

extension FeatureFlagGroup {
    static let myModule = FeatureFlagGroup(rawValue: "My Module")
}

@FeatureFlagContainer
enum MyModuleFlags {
    @FeatureToggle(group: .myModule, stage: .development)
    static var newFeature = "New Feature"

    @FeatureToggle(group: .myModule, stage: .released, defaultValue: true)
    static var existingFeature = "Existing Feature"
}
```

## Registering Custom Debug Sections

Conform to `DebugSection` to add your own sections to the debug menu:

```swift
import FoxDebugMenu
import SwiftUI

struct NetworkDebugSection: DebugSection {
    let id = "network"
    let title = "Network"
    let icon = Image(systemName: "wifi")

    var body: some View {
        Text("Network debug content")
    }
}

// Registration:
debugMenuRegistry.register(NetworkDebugSection())
```

## Module Integration (Dependency Inversion)

Consumer modules should not depend on FoxDebug directly. Instead, define a local protocol in the module and create an adapter in the host app:

```swift
// In your module (no FoxDebug dependency):
protocol MyModuleFeatureFlags: Sendable {
    var isNewFeatureEnabled: Bool { get }
}

// In host app:
struct MyModuleFlagsAdapter: MyModuleFeatureFlags {
    let provider: ProvidesFeatureToggle
    var isNewFeatureEnabled: Bool { provider.isEnabled(MyModuleFlags.newFeature) }
}
```

## Value Resolution Priority

```
Debug Override (when set) → Remote Value (.released only) → Default Value
```

## Feature Flag Stages

- `.development` — remote values ignored; only debug menu override or default value applies
- `.released` — remote values are applied when provided
