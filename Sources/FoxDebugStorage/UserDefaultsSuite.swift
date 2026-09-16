import Foundation

/// A `UserDefaults` suite held by name, so the stores built on it can be `Sendable`.
///
/// `UserDefaults` is not `Sendable`: it is thread-safe, but open for subclassing, and a subclass need
/// not be. Holding the name and opening the suite per access is Apple's guidance for crossing isolation,
/// and cheap — every instance for one suite shares the same backing store.
package struct UserDefaultsSuite: Sendable {
    package let name: String?

    package init(name: String?) {
        self.name = name
    }

    /// The suite, or `UserDefaults.standard` when `name` is `nil` or names no valid suite.
    package var defaults: UserDefaults {
        name.flatMap(UserDefaults.init(suiteName:)) ?? .standard
    }
}
