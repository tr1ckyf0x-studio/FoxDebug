# Migrating from 3.x

4.0.0 moves the package to Swift 6. Everything it declares `Sendable` is now proven so by the compiler,
with no `@unchecked` left — which changed how the `UserDefaults`-backed stores are created.

## Requirements

- **Swift 6.0+ (Xcode 16+).** The manifest uses `swift-tools-version: 6.0` and every target builds in
  the Swift 6 language mode. The platforms are unchanged: iOS 17+, macOS 14+.
- **swift-syntax 600.0.0 ..< 605.0.0**, up from `509.0.0 ..< 601.0.0-prerelease`, so the package resolves
  alongside other macro packages built for current toolchains.

## Stores take a suite name

`UserDefaults` is not `Sendable`, so a store can no longer hold one. It holds the suite's name and opens
the suite per access instead.

| 3.x | 4.0.0 |
|-----|-------|
| `UserDefaultsFeatureToggleOverrideStore(defaults: UserDefaults)` | `UserDefaultsFeatureToggleOverrideStore(suiteName: String?)` |
| `UserDefaultsDebugSettingStore(defaults: UserDefaults)` | `UserDefaultsDebugSettingStore(suiteName: String?)` |
| `UserDefaultsRemoteConfigCache(defaults: UserDefaults)` | `UserDefaultsRemoteConfigCache(suiteName: String?)` |

- The default is still the standard suite: `UserDefaultsDebugSettingStore()` needs no change.
- A store built from `UserDefaults(suiteName: "x")!` becomes `UserDefaultsDebugSettingStore(suiteName: "x")`.
- A name that `UserDefaults(suiteName:)` rejects — the app's own bundle identifier, for instance —
  falls back to the standard suite, as passing `.standard` did.
- The stores are now structs rather than classes. Nothing in them held identity, so code that only
  passes them around is unaffected.

Keys and stored values are unchanged, so overrides, settings and the remote cache survive the update.

## Debug menu sections

`DebugMenuRegistry.register(_:)` was already main-actor isolated; the type erasure behind it now is too.
A section registered from the main actor — the only place the registry could be reached — is
unaffected.
