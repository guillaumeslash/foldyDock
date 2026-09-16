import Foundation

public struct DockConfig: Codable, Equatable, Sendable {
    public var autohideEnabled: Bool
    public var autohideDelay: Double // In seconds (default: 0.3)
    public var iconSize: Double // In points (default: 52)
    public var items: [DockItem]

    public init(
        autohideEnabled: Bool = true,
        autohideDelay: Double = 0.3,
        iconSize: Double = 52.0,
        items: [DockItem] = []
    ) {
        self.autohideEnabled = autohideEnabled
        self.autohideDelay = autohideDelay
        self.iconSize = iconSize
        self.items = items
    }

    /// Default dock configuration with standard macOS applications and an example folder.
    public static var defaultConfig: DockConfig {
        let finder = DockItem(
            type: .app,
            title: "Finder",
            bundleIdentifier: "com.apple.finder",
            appPath: "/System/Library/CoreServices/Finder.app",
            isPinned: true
        )

        let safari = DockItem(
            type: .app,
            title: "Safari",
            bundleIdentifier: "com.apple.Safari",
            appPath: "/Applications/Safari.app",
            isPinned: true
        )

        let messages = DockItem(
            type: .app,
            title: "Messages",
            bundleIdentifier: "com.apple.MobileSMS",
            appPath: "/System/Applications/Messages.app",
            isPinned: true
        )

        let mail = DockItem(
            type: .app,
            title: "Mail",
            bundleIdentifier: "com.apple.mail",
            appPath: "/System/Applications/Mail.app",
            isPinned: true
        )

        let commFolder = DockItem(
            type: .folder,
            title: "Communication",
            isPinned: true,
            subItems: [messages, mail]
        )

        let terminal = DockItem(
            type: .app,
            title: "Terminal",
            bundleIdentifier: "com.apple.Terminal",
            appPath: "/System/Applications/Utilities/Terminal.app",
            isPinned: true
        )

        let settings = DockItem(
            type: .app,
            title: "Réglages",
            bundleIdentifier: "com.apple.systempreferences",
            appPath: "/System/Applications/System Settings.app",
            isPinned: true
        )

        return DockConfig(
            autohideEnabled: true,
            autohideDelay: 0.3,
            iconSize: 52.0,
            items: [finder, safari, commFolder, terminal, settings]
        )
    }
}
