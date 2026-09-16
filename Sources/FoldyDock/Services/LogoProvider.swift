import AppKit

public final class LogoProvider {
    public static let shared = LogoProvider()

    private var cachedBaseImage: NSImage?
    private var cachedMenuBarImage: NSImage?
    private var cachedLogoImages: [CGFloat: NSImage] = [:]

    public init() {}

    /// Returns the main FoldyDock logo resized to the requested dimension with high interpolation
    public func logoImage(size: CGFloat? = nil) -> NSImage {
        let base = baseLogo()

        guard let size = size else {
            return base
        }

        if let cached = cachedLogoImages[size] {
            return cached
        }

        let targetSize = NSSize(width: size, height: size)
        let img = NSImage(size: targetSize, flipped: false) { rect in
            NSGraphicsContext.current?.imageInterpolation = .high
            base.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
            return true
        }
        cachedLogoImages[size] = img
        return img
    }

    /// Generates an optimized, pixel-crisp 18x18 icon for the macOS menu bar
    public func menuBarImage() -> NSImage {
        if let cached = cachedMenuBarImage {
            return cached
        }

        let ptSize: CGFloat = 18.0
        let base = baseLogo()

        let img = NSImage(size: NSSize(width: ptSize, height: ptSize), flipped: false) { rect in
            NSGraphicsContext.current?.imageInterpolation = .high
            base.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
            return true
        }
        img.isTemplate = false
        cachedMenuBarImage = img
        return img
    }

    private func baseLogo() -> NSImage {
        if let cached = cachedBaseImage {
            return cached
        }

        let loaded = loadLogoFromDisk()
        cachedBaseImage = loaded
        return loaded
    }

    private func loadLogoFromDisk() -> NSImage {
        // 1. App Bundle Resources via Bundle.main URL
        if let url = Bundle.main.url(forResource: "logoFoldyDock", withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            return img
        }

        // 2. Main bundle resourceURL
        if let resUrl = Bundle.main.resourceURL?.appendingPathComponent("logoFoldyDock.png"),
           FileManager.default.fileExists(atPath: resUrl.path),
           let img = NSImage(contentsOf: resUrl) {
            return img
        }

        // 3. Relative to main bundle Contents/Resources
        let bundlePath = Bundle.main.bundlePath
        let inResources = (bundlePath as NSString).appendingPathComponent("Contents/Resources/logoFoldyDock.png")
        if FileManager.default.fileExists(atPath: inResources),
           let img = NSImage(contentsOfFile: inResources) {
            return img
        }

        // 4. Source Tree / Relative to this source file (#filePath)
        let sourceFileUrl = URL(fileURLWithPath: #filePath)
        let rootFromSource = sourceFileUrl
            .deletingLastPathComponent() // Services
            .deletingLastPathComponent() // FoldyDock
            .deletingLastPathComponent() // Sources
            .deletingLastPathComponent() // Project root
            .appendingPathComponent("logoFoldyDock.png")
        if FileManager.default.fileExists(atPath: rootFromSource.path),
           let img = NSImage(contentsOf: rootFromSource) {
            return img
        }

        // 5. Current Working Directory
        let currentDir = FileManager.default.currentDirectoryPath
        let inCurrentDir = (currentDir as NSString).appendingPathComponent("logoFoldyDock.png")
        if FileManager.default.fileExists(atPath: inCurrentDir),
           let img = NSImage(contentsOfFile: inCurrentDir) {
            return img
        }

        // 6. Absolute Development Path
        let devPath = "/Users/gmperso/Documents/DEV/foldyDock/logoFoldyDock.png"
        if FileManager.default.fileExists(atPath: devPath),
           let img = NSImage(contentsOfFile: devPath) {
            return img
        }

        // Fallback: SF Symbol
        return NSImage(systemSymbolName: "dock.rectangle", accessibilityDescription: "FoldyDock") ?? NSImage()
    }
}
