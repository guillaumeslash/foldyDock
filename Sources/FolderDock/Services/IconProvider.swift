import AppKit

@MainActor
public final class IconProvider {
    public static let shared = IconProvider()

    private let cache = NSCache<NSString, NSImage>()

    public init() {
        cache.countLimit = 200
    }

    /// Retrieves or generates an icon for a DockItem
    public func icon(for item: DockItem, size: CGFloat = 64) -> NSImage {
        let cacheKey = "\(item.id.uuidString)-\(Int(size))" as NSString
        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }

        let generatedImage: NSImage
        switch item.type {
        case .app:
            generatedImage = appIcon(for: item, size: size)
        case .folder:
            generatedImage = folderIcon(for: item, size: size)
        }

        cache.setObject(generatedImage, forKey: cacheKey)
        return generatedImage
    }

    /// Invalidate cache for a specific item (e.g. after modifying folder contents)
    public func invalidateCache(for itemId: UUID) {
        // Simple cache clear or prefix-based removal
        cache.removeAllObjects()
    }

    private func appIcon(for item: DockItem, size: CGFloat) -> NSImage {
        var image: NSImage?

        if let path = item.appPath, FileManager.default.fileExists(atPath: path) {
            image = NSWorkspace.shared.icon(forFile: path)
        } else if let bid = item.bundleIdentifier,
                  let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bid) {
            image = NSWorkspace.shared.icon(forFile: url.path)
        }

        let finalImage = image ?? NSWorkspace.shared.icon(for: .applicationBundle)
        finalImage.size = NSSize(width: size, height: size)
        return finalImage
    }

    /// Creates an iOS-style 2x2 miniature icon grid for a folder
    private func folderIcon(for item: DockItem, size: CGFloat) -> NSImage {
        let targetSize = NSSize(width: size, height: size)
        let newImage = NSImage(size: targetSize)

        newImage.lockFocus()

        // Background container: translucent frosted squircle/rounded rect
        let bgRect = NSRect(origin: .zero, size: targetSize)
        let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: size * 0.22, yRadius: size * 0.22)
        NSColor(white: 0.15, alpha: 0.65).setFill()
        bgPath.fill()

        // Border outline
        NSColor(white: 1.0, alpha: 0.25).setStroke()
        bgPath.lineWidth = 1.0
        bgPath.stroke()

        // Draw all mini-app icons in dynamic grid
        let subItems = item.subItems ?? []
        let totalCount = subItems.count

        if totalCount > 0 {
            let cols = max(2, Int(ceil(sqrt(Double(totalCount)))))
            let rows = max(2, Int(ceil(Double(totalCount) / Double(cols))))
            let padding = size * 0.10
            let availableW = size - (padding * 2)
            let gap = max(1.0, size * (cols == 2 ? 0.08 : 0.04))
            let miniSize = (availableW - CGFloat(cols - 1) * gap) / CGFloat(cols)
            let totalGridH = CGFloat(rows) * miniSize + CGFloat(rows - 1) * gap
            let startY = (size - totalGridH) / 2

            for index in 0..<totalCount {
                let row = index / cols
                let col = index % cols
                let x = padding + CGFloat(col) * (miniSize + gap)
                // Cocoa y=0 is at bottom
                let y = startY + CGFloat(rows - 1 - row) * (miniSize + gap)
                let subItem = subItems[index]
                let miniIcon = appIcon(for: subItem, size: miniSize)
                let destRect = NSRect(x: x, y: y, width: miniSize, height: miniSize)
                miniIcon.draw(in: destRect, from: .zero, operation: .sourceOver, fraction: 1.0)
            }
        } else {
            // Empty folder fallback icon
            let folderSymbol = NSImage(systemSymbolName: "folder.fill", accessibilityDescription: nil)
            let symbolSize = size * 0.5
            let destRect = NSRect(
                x: (size - symbolSize) / 2,
                y: (size - symbolSize) / 2,
                width: symbolSize,
                height: symbolSize
            )
            folderSymbol?.draw(in: destRect, from: .zero, operation: .sourceOver, fraction: 0.8)
        }

        newImage.unlockFocus()
        return newImage
    }
}
