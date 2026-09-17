import XCTest
import AppKit
@testable import FoldyDock

final class DockPanelTests: XCTestCase {
    @MainActor
    func testDockPanelInitialDimensionsAndReposition() {
        let dummyView = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 92))
        let panel = DockPanel(contentView: dummyView, initialDockHeight: 92.0)

        XCTAssertEqual(panel.dockHeight, 92.0)
        XCTAssertEqual(panel.frame.height, 92.0)

        panel.reposition()
        XCTAssertEqual(panel.frame.origin.y, panel.currentScreen.frame.origin.y + 18.0)
        XCTAssertEqual(panel.frame.height, 92.0)

        panel.updateDockSize(width: 400, height: 120.0)
        XCTAssertEqual(panel.dockHeight, 120.0)
        XCTAssertEqual(panel.frame.height, 120.0)
    }

    @MainActor
    func testIsMouseInDockZone() {
        let dummyView = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 92))
        let panel = DockPanel(contentView: dummyView, initialDockHeight: 92.0)
        panel.reposition()

        let dockFrame = panel.frame
        let screenOriginY = panel.currentScreen.frame.origin.y

        // Point inside the dock
        let insideDock = NSPoint(x: dockFrame.midX, y: dockFrame.midY)
        XCTAssertTrue(panel.isMouseInDockZone(at: insideDock))

        // Point directly underneath the dock in the bottom 18pt gap
        let inBottomGap = NSPoint(x: dockFrame.midX, y: screenOriginY + 5.0)
        XCTAssertTrue(panel.isMouseInDockZone(at: inBottomGap))

        // Point far above the dock (e.g. desktop/application)
        let aboveDock = NSPoint(x: dockFrame.midX, y: dockFrame.maxY + 50.0)
        XCTAssertFalse(panel.isMouseInDockZone(at: aboveDock))

        // Point far to the left of the dock
        let farLeft = NSPoint(x: dockFrame.minX - 100.0, y: screenOriginY + 5.0)
        XCTAssertFalse(panel.isMouseInDockZone(at: farLeft))

        // Point far to the right of the dock
        let farRight = NSPoint(x: dockFrame.maxX + 100.0, y: screenOriginY + 5.0)
        XCTAssertFalse(panel.isMouseInDockZone(at: farRight))
    }
}
