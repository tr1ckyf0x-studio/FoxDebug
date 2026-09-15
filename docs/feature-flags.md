# Feature flags

A feature flag is a `Bool` the app checks before taking a code path. It has a default, can be forced
on or off from the debug menu, and — once the feature is released — can be switched remotely.

## Declaring flags

```swift
import FoxFeatureToggle

extension FeatureFlagGroup {
    static let checkout = FeatureFlagGroup(rawValue: "Checkout")
}

@FeatureFlagContainer
enum CheckoutFlags {
    @FeatureToggle(displayName: "Apple Pay", group: .checkout, stage: .released, defaultValue: true)
    static var applePay: FeatureFlag

    @FeatureToggle(displayName: "One-tap checkout", group: .checkout, stage: .development)
    static var oneTap: FeatureFlag

    #if DEBUG
    @FeatureToggle(displayName: "Fake card processor", group: .checkout, stage: .development)
    static var fakeProcessor: FeatureFlag
    #endif
}
```

- **`static var`, not `static let`.** The macro turns the property into a computed one, which a `let`
  cannot be.
- **The key is the property name.** It is what overrides and remote values are stored under, so
  renaming a property forgets its override. Backticks are not part of the key: `` `default` `` is
  stored as `default`.
- **`defaultValue`** is `false` unless given.
- **`#if` blocks** are fine: `all` includes a member under the same condition.
- **Groups** are a struct, not an enum, so every module can add its own with an extension. The menu
  shows one section per group, sorted by name.

## Stages

| Stage | Remote value | Use it for |
|-------|--------------|------------|
| `.development` | ignored | work in progress — nobody can turn it on from outside by mistake |
| `.released` | applied | shipped features you may need to switch off remotely (a kill switch) |

Moving a flag from `.development` to `.released` is a code change, which is the point: the decision to
let a backend control a feature goes through review.

## Registering and reading

```swift
let overrideStore = UserDefaultsFeatureToggleOverrideStore()
let flags = FeatureToggleProvider(overrideStore: overrideStore)

let registry = FeatureFlagRegistry()
registry.register(CheckoutFlags.all)
registry.register(ProfileFlags.all)

debugMenuRegistry.register(
    FeatureToggleDebugSection(provider: flags, registry: registry, overrideStore: overrideStore)
)
```

Pass **the same override store** to the provider and to the section: the section writes overrides into
it, and the provider reads them from it.

```swift
if flags.isEnabled(CheckoutFlags.oneTap) { … }
```

`FeatureToggleProvider` is `@MainActor` and `@Observable`: read it on the main actor, and a SwiftUI
view that reads a flag re-renders when the flag is flipped in the menu.

## How a value is resolved

1. **Override** — forced **On** or **Off** in the menu. **Default** in the menu means no override.
2. **Remote value** — only for a `.released` flag, only if the backend sent one.
3. **`defaultValue`.**

`flags.source(for:)` tells which of the three produced the current value: `.override`, `.remote` or
`.defaultValue`. The menu shows a `REMOTE` badge from it.

## In the menu

Each flag shows its name, a `DEV` badge for `.development`, a `REMOTE` badge when a backend decides its
value, a dot for its current state, and a **Default / On / Off** picker. A search field filters by name,
and **Overridden** narrows the list to flags someone has forced.

## Changing overrides from code

Writing to the store directly bypasses observation, so tell the provider afterwards:

```swift
overrideStore.setOverride(.forceEnabled, for: CheckoutFlags.oneTap)
flags.notifyOverridesChanged()
```

The menu does this itself; you only need it for your own tooling, such as a launch argument that
enables a flag for UI tests.
