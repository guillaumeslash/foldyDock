import SwiftUI
import AppKit

public struct VisualEffectBackground: NSViewRepresentable {
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode
    public var cornerRadius: CGFloat

    public init(
        material: NSVisualEffectView.Material = .hudWindow,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        cornerRadius: CGFloat = 24.0
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.cornerRadius = cornerRadius
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = cornerRadius
        view.layer?.masksToBounds = true
        view.maskImage = Self.makeMaskImage(cornerRadius: cornerRadius)
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.layer?.cornerRadius = cornerRadius
        nsView.layer?.masksToBounds = true
        nsView.maskImage = Self.makeMaskImage(cornerRadius: cornerRadius)
    }

    private static var cachedMasks: [CGFloat: NSImage] = [:]

    private static func makeMaskImage(cornerRadius: CGFloat) -> NSImage {
        let roundedRadius = round(cornerRadius * 2) / 2
        if let cached = cachedMasks[roundedRadius] {
            return cached
        }
        let edge = max(4.0, roundedRadius * 2 + 4)
        let image = NSImage(size: NSSize(width: edge, height: edge), flipped: false) { rect in
            let path = NSBezierPath(roundedRect: rect, xRadius: roundedRadius, yRadius: roundedRadius)
            NSColor.black.setFill()
            path.fill()
            return true
        }
        image.capInsets = NSEdgeInsets(top: roundedRadius, left: roundedRadius, bottom: roundedRadius, right: roundedRadius)
        image.resizingMode = .stretch
        cachedMasks[roundedRadius] = image
        return image
    }
}
