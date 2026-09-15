# Getting started

FoxDebug gives an app a debug menu and two things to put in it: **feature flags**, which switch code
paths on and off, and **debug settings**, which hold values the app reads — a server address, a log
level. Both can also take values from a backend through **remote config**.

## 1. Add the package

In `Package.swift`:

```swift
.package(url: "https://github.com/tr1ckyf0x-studio/FoxDebug.git", exact: "3.0.0")
```

Or in an XcodeGen `project.yml`:

```yaml
packages:
  FoxDebug:
    url: https://github.com/tr1ckyf0x-studio/FoxDebug.git
    exactVersion: 3.0.0
```

Pick the products you use:

| Product | Add it when |
|---------|-------------|
| `FoxDebugMenu` | always — the menu itself |
| `FoxFeatureToggle` | you declare or read feature flags |
| `FoxFeatureToggleUI` | the menu should let people flip flags |
| `FoxDebugSettings` | you declare or read debug settings |
| `FoxDebugSettingsUI` | the menu should let people edit settings |
| `FoxRemoteConfig` | flags or settings take values from a backend |

The UI products are the only ones that depend on `FoxDebugMenu`. Code that just reads a flag or a
setting needs `FoxFeatureToggle` or `FoxDebugSettings` and nothing else.

## 2. Declare what the app has

```swift
import FoxDebugSettings
import FoxFeatureToggle

extension FeatureFlagGroup {
    static let onboarding = FeatureFlagGroup(rawValue: "Onboarding")
}

@FeatureFlagContainer
enum AppFlags {
    @FeatureToggle(displayName: "New welcome screen", group: .onboarding, stage: .development)
    static var newWelcome: FeatureFlag
}

extension DebugSettingGroup {
    static let network = DebugSettingGroup(rawValue: "Network")
}

enum LogLevel: String, DebugChoiceOption {
    case debug, info, error
}

@DebugSettingContainer
enum AppSettings {
    @DebugSetting<LogLevel>(displayName: "Log level", group: .network, defaultValue: .error)
    static var logLevel: DebugChoice<LogLevel>
}
```

The macros turn each `static var` into a definition whose key is the property name, and give the
container a `static let all` listing every definition in it.

## 3. Wire it up once, at launch

Keep every object for the life of the process — a second provider would be a second, disconnected
view of the same values. Here a plain `@Observable` model owns them; a DI container works just as
well.

```swift
import FoxDebugMenu
import FoxDebugSettings
import FoxDebugSettingsUI
import FoxFeatureToggle
import FoxFeatureToggleUI
import SwiftUI

@MainActor
@Observable
final class AppDebugTools {
    let menu = DebugMenuRegistry()
    let flags: FeatureToggleProvider
    let settings = DebugSettingsProvider()

    private let overrideStore = UserDefaultsFeatureToggleOverrideStore()

    init() {
        flags = FeatureToggleProvider(overrideStore: overrideStore)

        let flagRegistry = FeatureFlagRegistry()
        flagRegistry.register(AppFlags.all)

        let settingRegistry = DebugSettingRegistry()
        settingRegistry.register(AppSettings.all)

        menu.register(FeatureToggleDebugSection(provider: flags, registry: flagRegistry, overrideStore: overrideStore))
        menu.register(DebugSettingsSection(provider: settings, registry: settingRegistry))
    }
}
```

A flag or setting that is never registered still resolves correctly — it just does not appear in the
menu, so there is no way to change it from there.

## 4. Present the menu

```swift
@main
struct MyApp: App {
    @State private var debugTools = AppDebugTools()
    @State private var isDebugMenuPresented = false

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(debugTools)
                .sheet(isPresented: $isDebugMenuPresented) {
                    DebugMenuView(registry: debugTools.menu)
                }
                .onShakeGesture { isDebugMenuPresented = true }   // see Debug menu → Opening the menu
        }
    }
}
```

## 5. Read values

```swift
if debugTools.flags.isEnabled(AppFlags.newWelcome) {
    NewWelcomeView()
}

let level: LogLevel = debugTools.settings.value(AppSettings.logLevel)
```

`FeatureToggleProvider` is `@Observable`, so a SwiftUI view reading a flag updates when the flag is
flipped in the menu. `DebugSettingsProvider` is not observable — see
[Debug settings](debug-settings.md#when-a-change-takes-effect).

## Next

- Keep the menu out of the App Store build: [Recipes](recipes.md#keeping-the-menu-out-of-production).
- Take values from a backend: [Remote config](remote-config.md).
