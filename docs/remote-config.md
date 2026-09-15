# Remote config

Remote config lets a backend decide values without a new build: switch off a released feature that
misbehaves, or tune a setting. One `RemoteConfigBootstrap` feeds both feature flags and debug settings.

## What a backend can change

| | Takes a remote value when |
|---|---|
| Feature flag | its stage is `.released` |
| Debug setting | it is declared with `acceptsRemote: true` |

A value set in the debug menu always wins over a remote one, so a tester can still override a flag the
backend controls.

## The payload

`RemoteConfig` is `Codable`, and a response can decode straight into it:

```json
{
  "flags": { "applePay": false },
  "settings": { "requestTimeout": "45", "logLevel": "info" }
}
```

- Keys are flag and setting keys — the property names.
- Either dictionary may be missing. Unknown top-level keys are ignored.
- Setting values are always strings. A choice takes its option's `rawValue`; one that matches no option
  is ignored.
- A flag and a setting may share a key: they live in separate dictionaries.

## Wiring

Implement a fetcher over your own API:

```swift
import FoxRemoteConfig

struct BackendRemoteConfigFetcher: RemoteConfigFetcher {
    let client: APIClient

    func fetch() async throws -> RemoteConfig {
        try await client.get("/remote-config", as: RemoteConfig.self)
    }
}
```

Then run the bootstrap **once**, at launch, before anything reads a flag or a setting:

```swift
@MainActor
func startRemoteConfig(flags: FeatureToggleProvider, settings: DebugSettingsProvider, client: APIClient) {
    RemoteConfigBootstrap(
        fetcher: BackendRemoteConfigFetcher(client: client),
        cache: UserDefaultsRemoteConfigCache(),
        consumers: [flags, settings]
    )
    .run(onFetchFailure: { error in
        Logger.remoteConfig.error("Fetch failed: \(error)")
    })
}
```

## The deferred pattern

`run()` does two things:

1. **Before it returns**, it applies the config cached by the previous launch to every consumer.
   Anything read afterwards already sees it.
2. **In the background**, it fetches a fresh config and caches it — for the **next** launch.

A fetched value therefore never changes a flag under the user in the middle of a session: a screen
does not rearrange itself because a request finished. The costs are that the very first launch runs on
defaults, and that a remote change reaches a user one launch later.

Consequences worth knowing:

- **Call `run()` once per process.** Calling it again — from `onAppear`, a scene phase change — would
  apply what the first fetch just cached, mid-session, which is exactly what the pattern prevents.
- **A failed fetch** calls `onFetchFailure` and leaves the cache as it was; the next launch uses the
  last good config and retries.
- **Cancelling** the task `run()` returns leaves the cache untouched and reports nothing.
- **To wait for the fetch** — in a test, or a debug action that refreshes the cache — await the task:
  `await bootstrap.run().value`.

## Consumers of your own

Anything conforming to `AppliesRemoteConfig` can be a consumer. The requirement is `@MainActor` and
receives the whole config:

```swift
@MainActor
final class ExperimentAssignments: AppliesRemoteConfig {
    private(set) var variant = "control"

    func applyRemoteConfig(_ config: RemoteConfig) {
        variant = config.settings["checkoutExperiment"] ?? "control"
    }
}
```

## Your own cache

`UserDefaultsRemoteConfigCache` stores the config as JSON under `FoxRemoteConfig.cache`. For another
store, conform to `RemoteConfigCache`: `load()` must return `.empty` rather than fail when there is
nothing readable, and `save(_:)` replaces the whole config rather than merging.
