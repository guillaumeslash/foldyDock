import SwiftUI
import AppKit

public struct ResizeHandleView: View {
    @ObservedObject var viewModel: DockViewModel
    public let isRightEdge: Bool

    @State private var isHovered: Bool = false

    public init(viewModel: DockViewModel, isRightEdge: Bool) {
        self.viewModel = viewModel
        self.isRightEdge = isRightEdge
    }

    public var body: some View {
        ZStack {
            // Native AppKit view handling cursor and drag tracking
            ResizeHandleRepresentable(
                isRightEdge: isRightEdge,
                onHoverChanged: { hovering in
                    isHovered = hovering
                },
                onDragChanged: { deltaX in
                    viewModel.updateIconSize(translationX: deltaX, isRightEdge: isRightEdge)
                },
                onDragEnded: {
                    viewModel.finishResizing()
                }
            )

            // Visual grip indicator
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isHovered || viewModel.isResizing ? 0.6 : 0.0),
                            Color.white.opacity(isHovered || viewModel.isResizing ? 0.3 : 0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 3.5, height: max(16, viewModel.config.iconSize * 0.38))
                .shadow(
                    color: (isHovered || viewModel.isResizing) ? Color.white.opacity(0.6) : Color.clear,
                    radius: 2
                )
                .allowsHitTesting(false)
                .animation(.easeInOut(duration: 0.18), value: isHovered)
                .animation(.easeInOut(duration: 0.18), value: viewModel.isResizing)
        }
        .frame(width: 16)
    }
}

// MARK: - Native AppKit Resize Cursor Tracking & Drag View

private struct ResizeHandleRepresentable: NSViewRepresentable {
    let isRightEdge: Bool
    let onHoverChanged: (Bool) -> Void
    let onDragChanged: (CGFloat) -> Void
    let onDragEnded: () -> Void

    func makeNSView(context: Context) -> ResizeHandleNSView {
        let view = ResizeHandleNSView()
        view.isRightEdge = isRightEdge
        view.onHoverChanged = onHoverChanged
        view.onDragChanged = onDragChanged
        view.onDragEnded = onDragEnded
        return view
    }

    func updateNSView(_ nsView: ResizeHandleNSView, context: Context) {
        nsView.isRightEdge = isRightEdge
        nsView.onHoverChanged = onHoverChanged
        nsView.onDragChanged = onDragChanged
        nsView.onDragEnded = onDragEnded
    }
}

private final class ResizeHandleNSView: NSView {
    var isRightEdge: Bool = false
    var onHoverChanged: ((Bool) -> Void)?
    var onDragChanged: ((CGFloat) -> Void)?
    var onDragEnded: (() -> Void)?

    private var startScreenX: CGFloat = 0
    private var trackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .cursorUpdate],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        self.trackingArea = area
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .resizeLeftRight)
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        NSCursor.resizeLeftRight.set()
        onHoverChanged?(true)
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        NSCursor.arrow.set()
        onHoverChanged?(false)
    }

    override func cursorUpdate(with event: NSEvent) {
        NSCursor.resizeLeftRight.set()
    }

    override func mouseDown(with event: NSEvent) {
        startScreenX = NSEvent.mouseLocation.x
        NSCursor.resizeLeftRight.set()
    }

    override func mouseDragged(with event: NSEvent) {
        let currentScreenX = NSEvent.mouseLocation.x
        let deltaX = currentScreenX - startScreenX
        NSCursor.resizeLeftRight.set()
        onDragChanged?(deltaX)
    }

    override func mouseUp(with event: NSEvent) {
        onDragEnded?()
        if bounds.contains(convert(event.locationInWindow, from: nil)) {
            NSCursor.resizeLeftRight.set()
        } else {
            NSCursor.arrow.set()
            onHoverChanged?(false)
        }
    }
}
