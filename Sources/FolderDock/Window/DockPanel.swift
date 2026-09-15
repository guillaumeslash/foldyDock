import AppKit
import SwiftUI

public final class DockPanel: NSPanel {
    private var trackingArea: NSTrackingArea?
    private var hideTimer: Timer?
    private var inactivityTimer: Timer?
    public var autohideEnabled: Bool = true
    public var autohideDelay: TimeInterval = 0.3

    private(set) public var isHiddenState: Bool = false
    private var shownY: CGFloat = 18
    public let hotspotPanel: HotspotPanel
    public var onMiddleClickEvent: ((NSEvent) -> Void)?
    private var globalMouseMonitor: Any?

    public var targetScreen: NSScreen? {
        NSScreen.screens.first ?? NSScreen.main
    }

    public var dockHeight: CGFloat = 92.0

    public init(contentView: NSView, initialDockHeight: CGFloat = 92.0) {
        self.dockHeight = initialDockHeight
        self.hotspotPanel = HotspotPanel()

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: initialDockHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]

        let trackingContainer = DockTrackingView(dockPanel: self)
        trackingContainer.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: trackingContainer.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trackingContainer.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: trackingContainer.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: trackingContainer.bottomAnchor)
        ])

        self.contentView = trackingContainer

        hotspotPanel.onCursorHitEdge = { [weak self] in
            guard let self = self, self.isHiddenState else { return }
            self.showDock(animated: true)
        }

        reposition()
    }

    deinit {
        stopEdgeMonitoring()
    }

    override public var canBecomeKey: Bool {
        return true
    }

    override public var canBecomeMain: Bool {
        return false
    }

    public func reposition() {
        guard let screen = targetScreen else { return }
        let screenFrame = screen.frame

        let width = self.frame.width > 0 ? self.frame.width : 500
        let x = screenFrame.origin.x + (screenFrame.width - width) / 2
        self.shownY = screenFrame.origin.y + 18

        hotspotPanel.updatePosition(screen: screen)

        if isHiddenState {
            let hideTargetY = screenFrame.origin.y
            self.setFrame(NSRect(x: x, y: hideTargetY, width: width, height: dockHeight), display: true)
            self.alphaValue = 0.0
            self.orderOut(nil)
            hotspotPanel.orderFront(nil)
            startEdgeMonitoring()
        } else {
            self.setFrame(NSRect(x: x, y: shownY, width: width, height: dockHeight), display: true)
            self.alphaValue = 1.0
            self.orderFrontRegardless()
            hotspotPanel.orderOut(nil)
            stopEdgeMonitoring()
            if autohideEnabled {
                scheduleInactivityTimer()
            }
        }
    }

    public func updateDockWidth(_ width: CGFloat) {
        updateDockSize(width: width, height: self.dockHeight)
    }

    public func updateDockSize(width: CGFloat, height: CGFloat) {
        guard let screen = targetScreen else { return }
        let screenFrame = screen.frame
        if height > 0 {
            self.dockHeight = height
        }
        let x = screenFrame.origin.x + (screenFrame.width - width) / 2
        self.shownY = screenFrame.origin.y + 18

        if isHiddenState {
            let hideTargetY = screenFrame.origin.y
            self.setFrame(NSRect(x: x, y: hideTargetY, width: width, height: dockHeight), display: true, animate: false)
        } else {
            if abs(self.frame.width - width) > 0.5 || abs(self.frame.height - dockHeight) > 0.5 || abs(self.frame.origin.x - x) > 0.5 || abs(self.frame.origin.y - shownY) > 0.5 {
                self.setFrame(NSRect(x: x, y: shownY, width: width, height: dockHeight), display: true, animate: false)
            }
        }
    }

    public func mouseDidEnter() {
        hideTimer?.invalidate()
        hideTimer = nil
        inactivityTimer?.invalidate()
        inactivityTimer = nil

        if isHiddenState {
            showDock(animated: true)
        }
    }

    public var shouldPreventAutoHide: (() -> Bool)?

    public func mouseDidExit() {
        guard autohideEnabled else { return }
        if shouldPreventAutoHide?() == true {
            return
        }
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: autohideDelay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard self?.shouldPreventAutoHide?() != true else { return }
                self?.hideDock(animated: true)
            }
        }
    }

    private func scheduleInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 2.2, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, !self.isHiddenState else { return }
                if self.shouldPreventAutoHide?() != true {
                    let mouseLoc = NSEvent.mouseLocation
                    if !self.frame.contains(mouseLoc) {
                        self.hideDock(animated: true)
                    }
                }
            }
        }
    }

    public func showDock(animated: Bool = true) {
        hideTimer?.invalidate()
        hideTimer = nil
        inactivityTimer?.invalidate()
        inactivityTimer = nil
        isHiddenState = false
        stopEdgeMonitoring()
        hotspotPanel.orderOut(nil)

        guard let screen = targetScreen else { return }
        let screenFrame = screen.frame
        self.shownY = screenFrame.origin.y + 18

        let width = self.frame.width > 0 ? self.frame.width : 500
        let x = screenFrame.origin.x + (screenFrame.width - width) / 2
        let targetFrame = NSRect(
            x: x,
            y: shownY,
            width: width,
            height: dockHeight
        )

        scheduleInactivityTimer()

        if animated {
            // Position at bottom edge with opacity 0 before gliding up
            if self.alphaValue < 0.05 || !self.isVisible {
                let startFrame = NSRect(
                    x: x,
                    y: screenFrame.origin.y,
                    width: width,
                    height: dockHeight
                )
                self.setFrame(startFrame, display: false)
                self.alphaValue = 0.0
                self.orderFrontRegardless()
            }

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.24
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                self.animator().setFrame(targetFrame, display: true)
                self.animator().alphaValue = 1.0
            }
        } else {
            self.setFrame(targetFrame, display: true)
            self.alphaValue = 1.0
            self.orderFrontRegardless()
        }
    }

    public func hideDock(animated: Bool = true) {
        hideTimer?.invalidate()
        hideTimer = nil
        inactivityTimer?.invalidate()
        inactivityTimer = nil
        isHiddenState = true

        guard let screen = targetScreen else { return }
        let screenFrame = screen.frame
        let width = self.frame.width > 0 ? self.frame.width : 500
        let x = screenFrame.origin.x + (screenFrame.width - width) / 2

        // Slide towards the bottom edge of the top screen (never crossing into a screen below)
        let hideTargetY = screenFrame.origin.y
        let targetFrame = NSRect(
            x: x,
            y: hideTargetY,
            width: width,
            height: dockHeight
        )

        startEdgeMonitoring()
        hotspotPanel.updatePosition(screen: screen)
        hotspotPanel.orderFront(nil)

        if animated {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.22
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                self.animator().setFrame(targetFrame, display: true)
                self.animator().alphaValue = 0.0
            }, completionHandler: { [weak self] in
                guard let self = self, self.isHiddenState else { return }
                self.alphaValue = 0.0
                self.orderOut(nil)
            })
        } else {
            self.setFrame(targetFrame, display: true)
            self.alphaValue = 0.0
            self.orderOut(nil)
        }
    }

    // MARK: - Edge Detection for Dual-Monitor Setup

    public func startEdgeMonitoring() {
        guard globalMouseMonitor == nil else { return }
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self = self, self.isHiddenState else { return }
                let loc = NSEvent.mouseLocation
                self.checkEdgeHit(at: loc)
            }
        }
    }

    public func stopEdgeMonitoring() {
        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseMonitor = nil
        }
    }

    private func checkEdgeHit(at loc: NSPoint) {
        guard isHiddenState else { return }
        guard let screen = targetScreen else { return }
        let screenFrame = screen.frame

        let bottomEdge = screenFrame.origin.y
        // Hit if cursor is within 8pt above the bottom edge of the top screen, within its horizontal width
        let isAtBottomEdge = loc.y >= bottomEdge && loc.y <= (bottomEdge + 8.0)
            && loc.x >= screenFrame.origin.x && loc.x <= (screenFrame.origin.x + screenFrame.width)

        if isAtBottomEdge {
            showDock(animated: true)
        }
    }
}

private final class DockTrackingView: NSView {
    private weak var dockPanel: DockPanel?
    private var trackingArea: NSTrackingArea?

    init(dockPanel: DockPanel) {
        self.dockPanel = dockPanel
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        dockPanel?.mouseDidEnter()
    }

    override func mouseExited(with event: NSEvent) {
        dockPanel?.mouseDidExit()
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}
