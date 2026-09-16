import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct TrashItemView: View {
    @ObservedObject var viewModel: DockViewModel
    public let iconSize: CGFloat
    public let dockHeight: CGFloat

    @State private var isHovered: Bool = false
    @State private var isDropTargeted: Bool = false

    public init(viewModel: DockViewModel, iconSize: CGFloat, dockHeight: CGFloat) {
        self.viewModel = viewModel
        self.iconSize = iconSize
        self.dockHeight = dockHeight
    }

    private static let emptyTrashPath = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/TrashIcon.icns"
    private static let fullTrashPath = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FullTrashIcon.icns"
    private static let dockEmptyTrashPath = "/System/Library/CoreServices/Dock.app/Contents/Resources/trashempty@2x.png"
    private static let dockFullTrashPath = "/System/Library/CoreServices/Dock.app/Contents/Resources/trashfull@2x.png"

    private var trashIcon: NSImage {
        let isFull = !viewModel.isTrashEmpty

        // 1. Official macOS UTType icon for trash-empty / trash-full
        let typeIdentifier = isFull ? "com.apple.trash-full" : "com.apple.trash-empty"
        if let utType = UTType(typeIdentifier) {
            let icon = NSWorkspace.shared.icon(for: utType)
            icon.size = NSSize(width: iconSize * 2, height: iconSize * 2)
            return icon
        }

        // 2. Fallback to CoreTypes.bundle .icns
        let preferredPath = isFull ? Self.fullTrashPath : Self.emptyTrashPath
        if let icon = NSImage(contentsOfFile: preferredPath) {
            icon.size = NSSize(width: iconSize * 2, height: iconSize * 2)
            return icon
        }

        // 3. Fallback to Dock.app bundled images
        let fallbackDockPath = isFull ? Self.dockFullTrashPath : Self.dockEmptyTrashPath
        if let dockIcon = NSImage(contentsOfFile: fallbackDockPath) {
            dockIcon.size = NSSize(width: iconSize * 2, height: iconSize * 2)
            return dockIcon
        }

        // 4. Fallback to SF Symbol
        if let sfSymbol = NSImage(systemSymbolName: isFull ? "trash.fill" : "trash", accessibilityDescription: "Corbeille") {
            return sfSymbol
        }

        return NSImage()
    }

    public var body: some View {
        ZStack(alignment: .center) {
            // 1. Main trash icon
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                ZStack {
                    if isDropTargeted {
                        Circle()
                            .fill(Color.red.opacity(0.35))
                            .frame(width: iconSize * 1.15, height: iconSize * 1.15)
                            .blur(radius: 4)
                    }

                    Image(nsImage: trashIcon)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: iconSize, height: iconSize)
                        .shadow(color: Color.black.opacity(isHovered ? 0.35 : 0.2), radius: isHovered ? 5 : 2.5, x: 0, y: isHovered ? 3 : 1.5)
                }
                .frame(width: iconSize, height: iconSize)
            }
            .frame(width: iconSize, height: iconSize)
            .scaleEffect(isDropTargeted ? 1.25 : (isHovered ? 1.12 : 1.0))
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isHovered)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isDropTargeted)
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovered = hovering
                if hovering {
                    viewModel.updateTrashStatus()
                }
            }
            .onTapGesture {
                viewModel.openTrash()
            }
            .contextMenu {
                Button("Ouvrir la corbeille") {
                    viewModel.openTrash()
                }

                Button("Vider la corbeille") {
                    viewModel.emptyTrash()
                }

                Divider()

                Button("Masquer la corbeille") {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        viewModel.toggleTrash()
                    }
                }
            }

            // 2. Tooltip above trash on hover
            if isHovered && !isDropTargeted {
                VStack {
                    Text("Corbeille")
                        .font(.system(size: max(10, min(12, iconSize * 0.22)), weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            VisualEffectBackground(
                                material: .hudWindow,
                                blendingMode: .withinWindow,
                                cornerRadius: 6
                            )
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color(white: 0.15).opacity(0.85))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                        )
                        .shadow(color: Color.black.opacity(0.35), radius: 4, x: 0, y: 2)
                        .offset(y: -(dockHeight * 0.5 + 20))
                    Spacer(minLength: 0)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .animation(.easeInOut(duration: 0.15), value: isHovered)
            }
        }
        .frame(width: iconSize, height: dockHeight)
        .onDrop(of: [.plainText, .utf8PlainText, .text], isTargeted: $isDropTargeted) { _ in
            defer {
                viewModel.clearDropState()
            }
            if let sourceId = viewModel.dragSourceId {
                viewModel.dropOnTrash(sourceId: sourceId)
                return true
            }
            return false
        }
    }
}
