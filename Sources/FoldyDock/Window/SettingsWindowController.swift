import AppKit
import SwiftUI

@MainActor
public final class SettingsWindowController: NSObject, NSWindowDelegate {
    public static let shared = SettingsWindowController()

    private var window: NSWindow?

    public func show(viewModel: DockViewModel) {
        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = FoldyDockSettingsView(viewModel: viewModel, onClose: { [weak self] in
            self?.window?.close()
        })

        let hostingController = NSHostingController(rootView: settingsView)
        let win = NSWindow(contentViewController: hostingController)
        win.title = "Paramètres FoldyDock"
        win.styleMask = [.titled, .closable, .miniaturizable]
        win.titlebarAppearsTransparent = false
        win.isMovableByWindowBackground = true
        win.hasShadow = true
        win.level = .floating
        win.isReleasedWhenClosed = false
        win.delegate = self
        win.center()

        self.window = win
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func windowWillClose(_ notification: Notification) {
        window = nil
    }
}
