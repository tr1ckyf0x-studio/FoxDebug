import Foundation
import Testing
@testable import FoxFeatureToggle

@Suite("RemoteFlagsCache")
struct RemoteFlagsCacheTests {

    private func makeSUT() -> UserDefaultsRemoteFlagsCache {
        let defaults = UserDefaults(suiteName: "FoxFeatureToggleTests.\(UUID().uuidString)")!
        return UserDefaultsRemoteFlagsCache(defaults: defaults)
    }

    @Test("Returns empty dictionary when cache is empty")
    func emptyCache() {
        let sut = makeSUT()
        #expect(sut.load().isEmpty)
    }

    @Test("Save and load round-trip")
    func saveAndLoad() {
        let sut = makeSUT()
        sut.save(["flagA": true, "flagB": false])
        let loaded = sut.load()
        #expect(loaded["flagA"] == true)
        #expect(loaded["flagB"] == false)
        #expect(loaded.count == 2)
    }

    @Test("Save performs full replace — old keys are removed")
    func saveReplacesOldKeys() {
        let sut = makeSUT()
        sut.save(["flagA": true, "flagB": false])
        sut.save(["flagC": true])
        let loaded = sut.load()
        #expect(loaded["flagA"] == nil)
        #expect(loaded["flagB"] == nil)
        #expect(loaded["flagC"] == true)
        #expect(loaded.count == 1)
    }

    @Test("Clear empties the cache")
    func clear() {
        let sut = makeSUT()
        sut.save(["flagA": true])
        sut.clear()
        #expect(sut.load().isEmpty)
    }
}
