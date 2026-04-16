import Testing
@testable import FoxFeatureToggle

@Suite("FeatureFlagRegistry")
@MainActor
struct FeatureFlagRegistryTests {
    private static let groupA = FeatureFlagGroup(rawValue: "Group A")
    private static let groupB = FeatureFlagGroup(rawValue: "Group B")

    private static let flagA = FeatureFlag(
        key: "flagA", displayName: "Flag A",
        group: groupA, stage: .released
    )
    private static let flagB = FeatureFlag(
        key: "flagB", displayName: "Flag B",
        group: groupB, stage: .development
    )
    private static let flagC = FeatureFlag(
        key: "flagC", displayName: "Flag C",
        group: groupA, stage: .released
    )

    @Test("Register appends flags")
    func registerAppendsFlags() {
        let sut = FeatureFlagRegistry()
        sut.register([Self.flagA, Self.flagB])
        #expect(sut.flags.count == 2)
        sut.register([Self.flagC])
        #expect(sut.flags.count == 3)
    }

    @Test("Groups returns unique groups")
    func groupsReturnsUnique() {
        let sut = FeatureFlagRegistry()
        sut.register([Self.flagA, Self.flagB, Self.flagC])
        #expect(sut.groups.count == 2)
        #expect(Set(sut.groups) == Set([Self.groupA, Self.groupB]))
    }

    @Test("Empty registry returns empty groups")
    func emptyRegistryEmptyGroups() {
        let sut = FeatureFlagRegistry()
        #expect(sut.groups.isEmpty)
    }
}
