import SwiftUI

public struct BouncingModifier: ViewModifier {
    public let isBouncing: Bool
    public var bounceHeight: CGFloat

    @State private var yOffset: CGFloat = 0.0
    @State private var scaleX: CGFloat = 1.0
    @State private var scaleY: CGFloat = 1.0
    @State private var isRunningSequence: Bool = false

    public init(isBouncing: Bool, bounceHeight: CGFloat = 14.0) {
        self.isBouncing = isBouncing
        self.bounceHeight = bounceHeight
    }

    public func body(content: Content) -> some View {
        content
            .offset(y: yOffset)
            .scaleEffect(x: scaleX, y: scaleY, anchor: .bottom)
            .onChange(of: isBouncing) { _, bouncing in
                if bouncing {
                    startBounceSequence()
                } else {
                    stopBounce()
                }
            }
            .onAppear {
                if isBouncing {
                    startBounceSequence()
                }
            }
            .onDisappear {
                stopBounce()
            }
    }

    private func startBounceSequence() {
        guard !isRunningSequence else { return }
        isRunningSequence = true

        let h = bounceHeight

        // Phase 1: High Leap
        withAnimation(.easeOut(duration: 0.16)) {
            yOffset = -h
            scaleX = 0.96
            scaleY = 1.04
        }

        // Phase 1 Land
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            guard self.isRunningSequence else { return }
            withAnimation(.easeIn(duration: 0.14)) {
                self.yOffset = 0
                self.scaleX = 1.04
                self.scaleY = 0.96
            }
        }

        // Phase 2: Medium Rebound
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            guard self.isRunningSequence else { return }
            withAnimation(.easeOut(duration: 0.15)) {
                self.yOffset = -h * 0.65
                self.scaleX = 0.98
                self.scaleY = 1.02
            }
        }

        // Phase 2 Land
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.48) {
            guard self.isRunningSequence else { return }
            withAnimation(.easeIn(duration: 0.14)) {
                self.yOffset = 0
                self.scaleX = 1.02
                self.scaleY = 0.98
            }
        }

        // Phase 3: Small Hop
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.64) {
            guard self.isRunningSequence else { return }
            withAnimation(.easeOut(duration: 0.13)) {
                self.yOffset = -h * 0.32
                self.scaleX = 1.0
                self.scaleY = 1.0
            }
        }

        // Phase 3 Land & Settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.78) {
            guard self.isRunningSequence else { return }
            withAnimation(.easeIn(duration: 0.12)) {
                self.yOffset = 0
                self.scaleX = 1.0
                self.scaleY = 1.0
            }
            self.isRunningSequence = false
        }
    }

    private func stopBounce() {
        isRunningSequence = false
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
            yOffset = 0
            scaleX = 1.0
            scaleY = 1.0
        }
    }
}

public extension View {
    func dockBounce(isBouncing: Bool, height: CGFloat = 14.0) -> some View {
        self.modifier(BouncingModifier(isBouncing: isBouncing, bounceHeight: height))
    }
}
