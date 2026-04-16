import Foundation
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
    func remoteValueAppliedForReleased() async {
        let (sut, _) = makeSUT()
        await sut.loadRemoteFlags(["released": true])
        #expect(sut.isEnabled(Self.releasedFlag) == true)
    }

    @Test("Remote value IGNORED when stage is .development")
    func remoteValueIgnoredForDevelopment() async {
        let (sut, _) = makeSUT()
        await sut.loadRemoteFlags(["development": true])
        #expect(sut.isEnabled(Self.developmentFlag) == false)
    }

    @Test("Debug override takes priority over remote")
    func overrideTakesPriorityOverRemote() async {
        let (sut, store) = makeSUT()
        await sut.loadRemoteFlags(["released": true])
        store.setOverride(.forceDisabled, for: Self.releasedFlag)
        #expect(sut.isEnabled(Self.releasedFlag) == false)
    }
}
