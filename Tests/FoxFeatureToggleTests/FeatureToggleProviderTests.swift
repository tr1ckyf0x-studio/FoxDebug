import Foundation
import FoxRemoteConfig
import Observation
import Testing
@testable import FoxFeatureToggle

@Suite("FeatureToggleProvider")
@MainActor
struct FeatureToggleProviderTests {
    private static let group = FeatureFlagGroup(rawValue: "Test")

    private static let releasedFlag = FeatureFlag(
        key: "released", displayName: "Released",
        group: group, stage: .released, defaultValue: false
    )
    private static let developmentFlag = FeatureFlag(
        key: "development", displayName: "Development",
        group: group, stage: .development, defaultValue: false
    )
    private static let defaultTrueFlag = FeatureFlag(
        key: "defaultTrue", displayName: "Default True",
        group: group, stage: .released, defaultValue: true
    )

    private func makeSUT() -> (FeatureToggleProvider, UserDefaultsFeatureToggleOverrideStore) {
        let defaults = UserDefaults(suiteName: "FoxFeatureToggleTests.\(UUID().uuidString)")!
        let store = UserDefaultsFeatureToggleOverrideStore(defaults: defaults)
        let provider = FeatureToggleProvider(overrideStore: store)
        return (provider, store)
    }

    @Test("Returns defaultValue when no override and no remote")
    func returnsDefaultValue() {
        let (sut, _) = makeSUT()
        #expect(sut.isEnabled(Self.releasedFlag) == false)
        #expect(sut.isEnabled(Self.defaultTrueFlag) == true)
    }

    @Test("Override forceEnabled returns true")
    func overrideForceEnabled() {
        let (sut, store) = makeSUT()
        store.setOverride(.forceEnabled, for: Self.releasedFlag)
        #expect(sut.isEnabled(Self.releasedFlag) == true)
    }

    @Test("Override forceDisabled returns false")
    func overrideForceDisabled() {
        let (sut, store) = makeSUT()
        store.setOverride(.forceDisabled, for: Self.defaultTrueFlag)
        #expect(sut.isEnabled(Self.defaultTrueFlag) == false)
    }

    @Test("Override defaultValue falls through to remote/default")
    func overrideDefaultValueFallsThrough() {
        let (sut, store) = makeSUT()
        store.setOverride(.defaultValue, for: Self.releasedFlag)
        #expect(sut.isEnabled(Self.releasedFlag) == false)
    }

    @Test("Remote value applied when stage is .released")
    func remoteValueAppliedForReleased() {
        let (sut, _) = makeSUT()
        sut.applyRemoteConfig(RemoteConfig(flags: ["released": true]))
        #expect(sut.isEnabled(Self.releasedFlag) == true)
        #expect(sut.source(for: Self.releasedFlag) == .remote)
    }

    @Test("Remote false turns off a flag whose default is true")
    func remoteFalseOverridesDefaultTrue() {
        let (sut, _) = makeSUT()
        sut.applyRemoteConfig(RemoteConfig(flags: ["defaultTrue": false]))
        #expect(sut.isEnabled(Self.defaultTrueFlag) == false)
    }

    @Test("Remote value IGNORED when stage is .development")
    func remoteValueIgnoredForDevelopment() {
        let (sut, _) = makeSUT()
        sut.applyRemoteConfig(RemoteConfig(flags: ["development": true]))
        #expect(sut.isEnabled(Self.developmentFlag) == false)
        #expect(sut.source(for: Self.developmentFlag) == .defaultValue)
    }

    @Test("Debug override takes priority over remote")
    func overrideTakesPriorityOverRemote() {
        let (sut, store) = makeSUT()
        sut.applyRemoteConfig(RemoteConfig(flags: ["released": true]))
        store.setOverride(.forceDisabled, for: Self.releasedFlag)
        #expect(sut.isEnabled(Self.releasedFlag) == false)
        #expect(sut.source(for: Self.releasedFlag) == .override)
    }

    @Test("Override .defaultValue falls through to the remote value")
    func defaultOverrideFallsThroughToRemote() {
        let (sut, store) = makeSUT()
        sut.applyRemoteConfig(RemoteConfig(flags: ["released": true]))
        store.setOverride(.defaultValue, for: Self.releasedFlag)
        #expect(sut.isEnabled(Self.releasedFlag) == true)
        #expect(sut.source(for: Self.releasedFlag) == .remote)
    }

    @Test("Applying a config replaces earlier remote values instead of merging")
    func applyReplaces() {
        let (sut, _) = makeSUT()
        sut.applyRemoteConfig(RemoteConfig(flags: ["released": true]))
        sut.applyRemoteConfig(RemoteConfig(flags: ["defaultTrue": false]))
        #expect(sut.isEnabled(Self.releasedFlag) == false)
        #expect(sut.isEnabled(Self.defaultTrueFlag) == false)
    }

    @Test("Remote settings do not leak into flags with the same key")
    func settingsDoNotLeak() {
        let (sut, _) = makeSUT()
        sut.applyRemoteConfig(RemoteConfig(settings: ["released": "true"]))
        #expect(sut.isEnabled(Self.releasedFlag) == false)
    }

    @Test("Source is .override when forced and .defaultValue when nothing applies")
    func sources() {
        let (sut, store) = makeSUT()
        #expect(sut.source(for: Self.releasedFlag) == .defaultValue)
        store.setOverride(.forceEnabled, for: Self.releasedFlag)
        #expect(sut.source(for: Self.releasedFlag) == .override)
    }

    @Test("Applying remote values notifies observers")
    func applyNotifiesObservers() {
        let (sut, _) = makeSUT()
        let changed = ObservationFlag()
        withObservationTracking {
            _ = sut.isEnabled(Self.releasedFlag)
        } onChange: {
            changed.set()
        }
        sut.applyRemoteConfig(RemoteConfig(flags: ["released": true]))
        #expect(changed.isSet)
    }

    @Test("Bootstrap feeds the provider its cached flags before run returns")
    func bootstrapIntegration() {
        let (sut, _) = makeSUT()
        let defaults = UserDefaults(suiteName: "FoxFeatureToggleTests.\(UUID().uuidString)")!
        let cache = UserDefaultsRemoteConfigCache(defaults: defaults)
        cache.save(RemoteConfig(flags: ["released": true]))

        RemoteConfigBootstrap(fetcher: NeverFetcher(), cache: cache, consumers: [sut]).run()

        #expect(sut.isEnabled(Self.releasedFlag) == true)
    }
}

private final class ObservationFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var value = false

    var isSet: Bool { lock.withLock { value } }

    func set() {
        lock.withLock { value = true }
    }
}

private struct NeverFetcher: RemoteConfigFetcher {
    func fetch() async throws -> RemoteConfig {
        throw CancellationError()
    }
}
