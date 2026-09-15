import SwiftUI

public struct PinBadgeView: View {
    public let size: CGFloat

    public init(size: CGFloat = 14.0) {
        self.size = size
    }

    public var body: some View {
        ZStack {
            // Dark liquid-glass circle background
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.22).opacity(0.92),
                            Color(white: 0.10).opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.55),
                                    Color.white.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                )
                .shadow(color: Color.black.opacity(0.4), radius: 2, x: 0, y: 1)

            // Pin icon
            Image(systemName: "pin.fill")
                .font(.system(size: size * 0.52, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color(white: 0.88)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .frame(width: size, height: size)
    }
}
