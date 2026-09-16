# Testing

Everything FoxDebug persists goes through a store protocol, so a test can hand it a fresh store and
never touch what the app, the simulator or another test left in `UserDefaults.standard`.

## Debug settings

`InMemoryDebugSettingStore` exists for this. Seed it with raw values keyed by setting key:

```swift
import FoxDebugSettings
import FoxRemoteConfig
import Testing

@Test("The client logs verbosely when the debug menu asks it to")
func verboseLogging() {
    let settings = DebugSettingsProvider(store: InMemoryDebugSettingStore(values: ["logLevel": "verbose"]))

    let client = APIClient(settings: settings)

    #expect(client.logger.level == .verbose)
}
```

Remote values are applied the same way the bootstrap applies them:

```swift
settings.applyRemoteConfig(RemoteConfig(settings: ["requestTimeout": "5"]))
```

`InMemoryDebugSettingStore` is thread-safe, so it also works for code under test that reads settings
off the main actor.

## Feature flags

There is no in-memory override store in the package; give the UserDefaults one a throwaway suite:

```swift
import FoxFeatureToggle
import Foundation
import Testing

@MainActor
@Test("One-tap checkout shows when its flag is on")
func oneTap() {
    let store = UserDefaultsFeatureToggleOverrideStore(suiteName: "tests.\(UUID().uuidString)")
    store.setOverride(.forceEnabled, for: CheckoutFlags.oneTap)
    let flags = FeatureToggleProvider(overrideStore: store)

    #expect(CheckoutModel(flags: flags).showsOneTap)
}
```

A unique suite per test keeps tests independent even when Swift Testing runs them in parallel.

For a remote value, `flags.applyRemoteConfig(RemoteConfig(flags: ["applePay": false]))` — remembering that
it only affects `.released` flags.

## Code that should not know about FoxDebug

When the type under test takes a `FeatureToggleProvider` or a `DebugSettingsProvider`, the test has to
build one. If that is more than the test is about, depend on a protocol of your own instead and pass a
stub — see [Recipes → Feature modules](recipes.md#feature-modules-without-a-foxdebug-dependency).

## Previews

The same stores make previews deterministic:

```swift
#Preview("Verbose logging") {
    NetworkInspector(
        settings: DebugSettingsProvider(store: InMemoryDebugSettingStore(values: ["logLevel": "verbose"]))
    )
}
```

## UI tests

A UI test cannot reach into the app's objects, but it can pass launch arguments. Seed the stores from
them before anything reads a value:

```swift
// In the app, at launch, before building anything that reads settings or flags.
if let stand = UserDefaults.standard.string(forKey: "uiTestStand") {       // -uiTestStand development
    settingsStore.setRawValue(stand, forKey: NetworkSettings.stand.descriptor.key)
}
```

Arguments passed as `-key value` land in `UserDefaults`' argument domain, so no parsing is needed.
Guard this with the same compilation condition as the debug menu.
