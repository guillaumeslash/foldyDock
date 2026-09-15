import AppKit

public final class HotspotPanel: NSPanel {
    public var onCursorHitEdge: (() -> Void)?
    private var trackingArea: NSTrackingArea?

    public init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]

        let view = HotspotView()
        view.onMouseEnter = { [weak self] in
            self?.onCursorHitEdge?()
        }
        self.contentView = view
    }

    public func updatePosition(screen: NSScreen) {
        let screenFrame = screen.frame
        let height: CGFloat = 5.0
        let frame = NSRect(
            x: screenFrame.origin.x,
            y: screenFrame.origin.y,
            width: screenFrame.width,
            height: height
        )
        self.setFrame(frame, display: true)
    }
}

private final class HotspotView: NSView {
    var onMouseEnter: (() -> Void)?
    private var trackingArea: NSTrackingArea?

    override func draw(_ dirtyRect: NSRect) {
        // Subtle almost-zero alpha fill guarantees hit-testing works without visible pixels
        NSColor(white: 0.0, alpha: 0.001).setFill()
        dirtyRect.fill()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        self.trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        onMouseEnter?()
    }
}

