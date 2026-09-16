import Foundation

public struct DockConfig: Codable, Equatable, Sendable {
    public var autohideEnabled: Bool
    public var autohideDelay: Double // In seconds (default: 0.3)
    public var iconSize: Double // In points (default: 52)
    public var items: [DockItem]
    public var showTrash: Bool // In dock (default: true)

    enum CodingKeys: String, CodingKey {
        case autohideEnabled
        case autohideDelay
        case iconSize
        case items
        case showTrash
    }

    public init(
        autohideEnabled: Bool = true,
        autohideDelay: Double = 0.3,
        iconSize: Double = 52.0,
        items: [DockItem] = [],
        showTrash: Bool = true
    ) {
        self.autohideEnabled = autohideEnabled
        self.autohideDelay = autohideDelay
        self.iconSize = iconSize
        self.items = items
        self.showTrash = showTrash
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.autohideEnabled = try container.decodeIfPresent(Bool.self, forKey: .autohideEnabled) ?? true
        self.autohideDelay = try container.decodeIfPresent(Double.self, forKey: .autohideDelay) ?? 0.3
        self.iconSize = try container.decodeIfPresent(Double.self, forKey: .iconSize) ?? 52.0
        self.items = try container.decodeIfPresent([DockItem].self, forKey: .items) ?? []
        self.showTrash = try container.decodeIfPresent(Bool.self, forKey: .showTrash) ?? true
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
