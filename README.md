# FoxDebug

A debug menu for Swift apps, and the two things most apps put in one: **feature flags** that switch
code paths, and **debug settings** that hold values — a server, a log level. Both can take values from
a backend through **remote config**.

```swift
@FeatureFlagContainer
enum AppFlags {
    @FeatureToggle(displayName: "New checkout", group: .checkout, stage: .development)
    static var newCheckout: FeatureFlag
}

@DebugSettingContainer
enum NetworkSettings {
    @DebugSetting<Stand>(displayName: "Stand", group: .network, defaultValue: .production)
    static var stand: DebugChoice<Stand>
}

if flags.isEnabled(AppFlags.newCheckout) { … }
let stand = settings.value(NetworkSettings.stand)
```

## Modules

| Product | Description |
|---------|-------------|
| `FoxDebugMenu` | The debug menu: a searchable list of sections the app registers |
| `FoxFeatureToggle` | Feature flags: definitions, provider, override store, macros |
| `FoxFeatureToggleUI` | Debug menu section for flipping flags |
| `FoxDebugSettings` | Debug settings — free text and a choice from a list: definitions, provider, store, macros |
| `FoxDebugSettingsUI` | Debug menu section for editing settings |
| `FoxRemoteConfig` | Remote values for flags and settings: fetcher, cache, bootstrap |

## Requirements

- Swift 6.0+ (Xcode 16+); the package builds in the Swift 6 language mode
- iOS 17+, macOS 14+

## Installation

```swift
.package(url: "https://github.com/tr1ckyf0x-studio/FoxDebug.git", exact: "4.0.0")
```

## Documentation

| Guide | |
|-------|---|
| [Getting started](docs/getting-started.md) | Add the package and wire it into a SwiftUI app |
| [Debug menu](docs/debug-menu.md) | Open the menu, write your own sections |
| [Feature flags](docs/feature-flags.md) | Declare flags, stages, overrides |
| [Debug settings](docs/debug-settings.md) | Text and choice settings, resolution order, threading |
| [Remote config](docs/remote-config.md) | Feed flags and settings from a backend |
| [Testing](docs/testing.md) | Unit tests and previews with isolated stores |
| [Recipes](docs/recipes.md) | Switching servers, keeping the menu out of production, feature modules |
| [Migrating from 3.x](docs/migrating-from-3.md) | What 4.0.0 changed |
| [Migrating from 2.x](docs/migrating-from-2.md) | What 3.0.0 changed |

## Demo

`Demo/` holds iOS and macOS apps wiring everything together:

```bash
mint run xcodegen --spec Demo/project.yml
open Demo/FoxDebugDemo.xcodeproj
```

## Tests

```bash
swift test
```

runs the logic and macro tests.

```bash
xcodebuild test -scheme FoxDebug-Package -destination 'platform=iOS Simulator,name=iPhone 17'
```

adds the snapshot tests. Their references live in Git LFS and are recorded on one simulator runtime;
another runtime renders system chrome differently and fails them. After changing runtime, re-record
with `TEST_RUNNER_SNAPSHOT_TESTING_RECORD=all` and review the images before committing.
