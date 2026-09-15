import Foundation

public final class DockPersistenceService: Sendable {
    public static let shared = DockPersistenceService()

    private var fileManager: FileManager { .default }
    private let directoryURL: URL
    private let configURL: URL

    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.directoryURL = appSupport.appendingPathComponent("FolderDock", isDirectory: true)
        self.configURL = directoryURL.appendingPathComponent("config.json")
    }

    /// Custom initializer for testing with a dedicated directory.
    public init(customDirectoryURL: URL) {
        self.directoryURL = customDirectoryURL
        self.configURL = customDirectoryURL.appendingPathComponent("config.json")
    }

    /// Loads configuration from disk or returns default configuration if not present or corrupt.
    public func loadConfig() -> DockConfig {
        guard fileManager.fileExists(atPath: configURL.path) else {
            let defaultConfig = DockConfig.defaultConfig
            saveConfig(defaultConfig)
            return defaultConfig
        }

        do {
            let data = try Data(contentsOf: configURL)
            let config = try JSONDecoder().decode(DockConfig.self, from: data)
            return config
        } catch {
            print("[DockPersistenceService] Error reading config: \(error). Falling back to default.")
            let fallback = DockConfig.defaultConfig
            saveConfig(fallback)
            return fallback
        }
    }

    /// Saves configuration to JSON file in Application Support atomically.
    public func saveConfig(_ config: DockConfig) {
        do {
            if !fileManager.fileExists(atPath: directoryURL.path) {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            }

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(config)
            try data.write(to: configURL, options: .atomic)
        } catch {
            print("[DockPersistenceService] Failed to save config: \(error)")
        }
    }
}
