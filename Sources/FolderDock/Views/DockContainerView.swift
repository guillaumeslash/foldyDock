import SwiftUI
import AppKit

public struct DockContainerView: View {
    @ObservedObject var viewModel: DockViewModel
    public var onSizeChange: ((CGSize) -> Void)?

    public init(viewModel: DockViewModel, onSizeChange: ((CGSize) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onSizeChange = onSizeChange
    }

    public var body: some View {
        let dockHeight = viewModel.config.iconSize + 40
        let cornerRadius = dockHeight * 0.285

        HStack(spacing: 0) {
            // Left Resize Handle
            ResizeHandleView(viewModel: viewModel, isRightEdge: false)

            HStack(spacing: 8) {
                // Pinned items (Apps & Folders)
                ForEach(viewModel.items) { item in
                    DockItemView(
                        viewModel: viewModel,
                        item: item,
                        iconSize: viewModel.config.iconSize
                    )
                }

                // Divider between pinned items and unpinned running applications
                if !viewModel.unpinnedRunningItems.isEmpty {
                    Rectangle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 1, height: viewModel.config.iconSize * 0.65)
                        .padding(.horizontal, 2)
                        .contentShape(Rectangle().inset(by: -6))
                        .onDrop(of: [.plainText, .utf8PlainText, .text], isTargeted: nil) { _ in
                            defer {
                                viewModel.clearDropState()
                            }
                            if let sourceId = viewModel.dragSourceId {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                                    viewModel.moveItemToEnd(sourceId: sourceId)
                                }
                                return true
                            }
                            return false
                        }

                    // Unpinned running applications
                    ForEach(viewModel.unpinnedRunningItems) { item in
                        DockItemView(
                            viewModel: viewModel,
                            item: item,
                            iconSize: viewModel.config.iconSize
                        )
                    }
                }
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.78), value: viewModel.items)
            .padding(.horizontal, 6)

            // Right Resize Handle
            ResizeHandleView(viewModel: viewModel, isRightEdge: true)
        }
        .padding(.vertical, 8)
        .background(
            ZStack {
                VisualEffectBackground(
                    material: .hudWindow,
                    blendingMode: .behindWindow,
                    cornerRadius: cornerRadius
                )

                // Subtle frosted color tint
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(white: 0.12).opacity(0.35))

                // Glassmorphic border
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.35),
                                Color.white.opacity(0.12)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.0
                    )
            }
        )
        .frame(height: dockHeight)
        .background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: DockSizePreferenceKey.self, value: CGSize(width: proxy.size.width, height: dockHeight))
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 6)
        .coordinateSpace(name: "dockContainer")
        .onDrop(of: [.plainText, .utf8PlainText, .text], isTargeted: nil) { _ in
            defer {
                viewModel.clearDropState()
            }
            if let sourceId = viewModel.dragSourceId {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                    viewModel.moveItemToEnd(sourceId: sourceId)
                }
                return true
            }
            return false
        }
        .onPreferenceChange(ItemFramesPreferenceKey.self) { frames in
            viewModel.itemFrames = frames
        }
        .onPreferenceChange(DockSizePreferenceKey.self) { newSize in
            onSizeChange?(newSize)
        }
    }
}

private struct DockSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let next = nextValue()
        if next != .zero {
            value = next
        }
    }
}
