import SwiftUI

/// A short uppercase tag beside a row's title — `DEV` on an unreleased flag, `REMOTE` on a value that
/// arrived from outside. Shared so every section marks its rows the same way.
public struct DebugBadge: View {
    private let title: String
    private let color: Color

    public init(_ title: String, color: Color) {
        self.title = title
        self.color = color
    }

    public var body: some View {
        Text(title)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, Metrics.horizontalPadding)
            .padding(.vertical, Metrics.verticalPadding)
            .background(color.opacity(Metrics.backgroundOpacity))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
    }

    private enum Metrics {
        static let horizontalPadding: CGFloat = 6
        static let verticalPadding: CGFloat = 2
        static let backgroundOpacity = 0.2
        static let cornerRadius: CGFloat = 4
    }
}
