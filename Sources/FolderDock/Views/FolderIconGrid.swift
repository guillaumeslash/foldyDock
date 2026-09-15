import SwiftUI
import AppKit

public struct FolderIconGrid: View {
    public let item: DockItem
    public let size: CGFloat
    public var isHighlighted: Bool
    public var bouncingSubItemIds: Set<UUID>
    public var runningSubItemIds: Set<UUID>

    public init(
        item: DockItem,
        size: CGFloat = 52.0,
        isHighlighted: Bool = false,
        bouncingSubItemIds: Set<UUID> = [],
        runningSubItemIds: Set<UUID> = []
    ) {
        self.item = item
        self.size = size
        self.isHighlighted = isHighlighted
        self.bouncingSubItemIds = bouncingSubItemIds
        self.runningSubItemIds = runningSubItemIds
    }

    private var subItems: [DockItem] {
        item.subItems ?? []
    }

    public var body: some View {
        ZStack {
            // iOS-style squircle background with highlight state
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(
                    isHighlighted
                        ? LinearGradient(
                            colors: [
                                Color(red: 0.18, green: 0.52, blue: 1.0).opacity(0.85),
                                Color(red: 0.08, green: 0.36, blue: 0.92).opacity(0.78)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [
                                Color(white: 0.22).opacity(0.72),
                                Color(white: 0.14).opacity(0.65)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                )
                .overlay(
                    Group {
                        if isHighlighted {
                            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                                .fill(
                                    RadialGradient(
                                        colors: [Color.white.opacity(0.38), Color.clear],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: size * 0.55
                                    )
                                )
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                        .stroke(
                            isHighlighted
                                ? LinearGradient(
                                    colors: [Color.white, Color.cyan.opacity(0.95), Color.white.opacity(0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.white.opacity(0.28), Color.white.opacity(0.14)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                            lineWidth: isHighlighted ? 2.5 : 1.0
                        )
                )
                .shadow(
                    color: isHighlighted ? Color.blue.opacity(0.95) : Color.black.opacity(0.2),
                    radius: isHighlighted ? 12 : 3,
                    x: 0,
                    y: isHighlighted ? 0 : 1.5
                )
                .shadow(
                    color: isHighlighted ? Color.cyan.opacity(0.8) : Color.clear,
                    radius: isHighlighted ? 6 : 0,
                    x: 0,
                    y: 0
                )
                .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isHighlighted)

            // Content: dynamic scalable mini icons
            if subItems.isEmpty {
                Image(systemName: "folder.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.45, height: size * 0.45)
                    .foregroundStyle(.white.opacity(0.8))
            } else {
                let layout = DynamicGridLayout(itemCount: subItems.count, containerSize: size)
                VStack(spacing: layout.verticalSpacing) {
                    ForEach(0..<layout.rows, id: \.self) { row in
                        HStack(spacing: layout.horizontalSpacing) {
                            ForEach(0..<layout.cols, id: \.self) { col in
                                let index = row * layout.cols + col
                                miniIconView(at: index, layout: layout)
                            }
                        }
                    }
                }
                .padding(layout.outerPadding)
            }
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private func miniIconView(at index: Int, layout: DynamicGridLayout) -> some View {
        if index < subItems.count {
            let sub = subItems[index]
            let isBouncing = bouncingSubItemIds.contains(sub.id)
            let isRunning = runningSubItemIds.contains(sub.id)

            VStack(spacing: layout.dotSpacing) {
                Image(nsImage: IconProvider.shared.icon(for: sub, size: layout.iconSize))
                    .resizable()
                    .scaledToFit()
                    .frame(width: layout.iconSize, height: layout.iconSize)
                    .clipShape(RoundedRectangle(cornerRadius: layout.cornerRadius, style: .continuous))
                    .dockBounce(isBouncing: isBouncing, height: layout.bounceHeight)

                // Petite pastille sous l'app ouverte
                Circle()
                    .fill(isRunning ? Color.white.opacity(0.95) : Color.clear)
                    .frame(width: layout.dotSize, height: layout.dotSize)
                    .shadow(color: isRunning ? Color.white.opacity(0.85) : Color.clear, radius: max(0.5, layout.dotSize * 0.4))
                    .shadow(color: isRunning ? Color.black.opacity(0.4) : Color.clear, radius: 0.5, y: 0.5)
            }
        } else {
            Color.clear
                .frame(
                    width: layout.iconSize,
                    height: layout.iconSize + layout.dotSpacing + layout.dotSize
                )
        }
    }
}

// MARK: - Dynamic Grid Layout Calculation

private struct DynamicGridLayout {
    let cols: Int
    let rows: Int
    let iconSize: CGFloat
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat
    let dotSize: CGFloat
    let dotSpacing: CGFloat
    let bounceHeight: CGFloat
    let cornerRadius: CGFloat
    let outerPadding: CGFloat

    init(itemCount: Int, containerSize: CGFloat) {
        let c = max(2, Int(ceil(sqrt(Double(itemCount)))))
        let r = max(2, Int(ceil(Double(itemCount) / Double(c))))
        self.cols = c
        self.rows = r

        let scale = containerSize / 52.0

        switch c {
        case 2:
            self.iconSize = 17.5 * scale
            self.horizontalSpacing = 3.0 * scale
            self.verticalSpacing = 1.5 * scale
            self.dotSize = 2.6 * scale
            self.dotSpacing = 1.2 * scale
            self.bounceHeight = 3.5 * scale
            self.cornerRadius = 17.5 * 0.22 * scale
            self.outerPadding = 3.5 * scale
        case 3:
            self.iconSize = 11.5 * scale
            self.horizontalSpacing = 2.0 * scale
            self.verticalSpacing = 1.4 * scale
            self.dotSize = 2.0 * scale
            self.dotSpacing = 0.8 * scale
            self.bounceHeight = 2.4 * scale
            self.cornerRadius = 11.5 * 0.22 * scale
            self.outerPadding = 3.5 * scale
        case 4:
            self.iconSize = 8.2 * scale
            self.horizontalSpacing = 1.5 * scale
            self.verticalSpacing = 1.1 * scale
            self.dotSize = 1.6 * scale
            self.dotSpacing = 0.6 * scale
            self.bounceHeight = 1.8 * scale
            self.cornerRadius = 8.2 * 0.22 * scale
            self.outerPadding = 3.0 * scale
        case 5:
            self.iconSize = 6.4 * scale
            self.horizontalSpacing = 1.2 * scale
            self.verticalSpacing = 0.9 * scale
            self.dotSize = 1.3 * scale
            self.dotSpacing = 0.5 * scale
            self.bounceHeight = 1.4 * scale
            self.cornerRadius = 6.4 * 0.22 * scale
            self.outerPadding = 2.5 * scale
        default:
            let hSpacing = max(0.8, 1.2 - CGFloat(c - 5) * 0.08) * scale
            let totalHSpacing = CGFloat(c - 1) * hSpacing
            let availW = containerSize - 12.0 * scale
            let w = max(3.0 * scale, (availW - totalHSpacing) / CGFloat(c))
            self.iconSize = w
            self.horizontalSpacing = hSpacing
            self.verticalSpacing = max(0.6 * scale, hSpacing * 0.8)
            self.dotSize = max(0.9 * scale, w * 0.18)
            self.dotSpacing = max(0.3 * scale, w * 0.08)
            self.bounceHeight = max(1.0 * scale, w * 0.2)
            self.cornerRadius = max(0.6 * scale, w * 0.22)
            self.outerPadding = 2.0 * scale
        }
    }
}
