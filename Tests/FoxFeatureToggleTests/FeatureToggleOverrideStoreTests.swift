import Foundation
import Testing
@testable import FoxFeatureToggle

@Suite("FeatureToggleOverrideStore")
struct FeatureToggleOverrideStoreTests {
    private let testFlag = FeatureFlag(
        key: "testFlag",
        displayName: "Test Flag",
        group: FeatureFlagGroup(rawValue: "Test"),
        stage: .development
    )

    private func makeSUT() -> UserDefaultsFeatureToggleOverrideStore {
        let defaults = UserDefaults(suiteName: "FoxFeatureToggleTests.\(UUID().uuidString)")!
        return UserDefaultsFeatureToggleOverrideStore(defaults: defaults)
    }

    @Test("Returns nil when no override is stored")
    func overrideReturnsNilByDefault() {
        let sut = makeSUT()
        #expect(sut.override(for: testFlag) == nil)
    }

    @Test("Set and get override round-trips correctly")
    func setAndGetOverride() {
        let sut = makeSUT()
        sut.setOverride(.forceEnabled, for: testFlag)
        #expect(sut.override(for: testFlag) == .forceEnabled)
    }

    @Test("Remove override clears stored value")
    func removeOverride() {
        let sut = makeSUT()
        sut.setOverride(.forceDisabled, for: testFlag)
        sut.removeOverride(for: testFlag)
        #expect(sut.override(for: testFlag) == nil)
    }

    @Test("Uses namespaced key prefix")
    func namespacedKeyPrefix() {
        let defaults = UserDefaults(suiteName: "FoxFeatureToggleTests.\(UUID().uuidString)")!
        let sut = UserDefaultsFeatureToggleOverrideStore(defaults: defaults)
        sut.setOverride(.forceEnabled, for: testFlag)
        let storedValue = defaults.string(forKey: "FoxFeatureToggle.override.testFlag")
        #expect(storedValue == FeatureFlagOverride.forceEnabled.rawValue)
    }
}
