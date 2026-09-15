import SwiftUI
import AppKit

public struct DockItemView: View {
    @ObservedObject var viewModel: DockViewModel
    public let item: DockItem
    public let iconSize: CGFloat

    @State private var isHovered: Bool = false

    private var dropPlacement: DropPlacement? {
        if viewModel.activeDropTargetId == item.id {
            return viewModel.activeDropPlacement
        }
        return nil
    }

    public init(viewModel: DockViewModel, item: DockItem, iconSize: CGFloat = 52.0) {
        self.viewModel = viewModel
        self.item = item
        self.iconSize = iconSize
    }

    private var isRunning: Bool {
        viewModel.isItemRunning(item)
    }

    private var itemWidth: CGFloat {
        iconSize + 12
    }

    private var folderFontSize: CGFloat {
        max(9.0, min(12.5, iconSize * 0.19))
    }

    private var folderSize: CGFloat {
        iconSize * 0.835
    }

    public var body: some View {
        VStack(spacing: 2) {
            // 1. Top Slot: Folder title above the folder (for folders) or empty spacer (for apps)
            ZStack {
                if item.type == .folder {
                    Text(item.title)
                        .font(.system(size: folderFontSize, weight: .medium, design: .rounded))
                        .foregroundColor(isHovered ? .white : Color.white.opacity(0.92))
                        .shadow(color: Color.black.opacity(0.8), radius: 1.5, x: 0, y: 1)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: itemWidth + 6)
                }
            }
            .frame(height: 14)

            // 2. Middle Slot: Main Icon (App or Folder)
            ZStack(alignment: .center) {
                // Insertion bar indicator on the left
                if dropPlacement == .before {
                    HStack {
                        InsertionBar()
                            .offset(x: -6)
                        Spacer()
                    }
                }

                // Insertion bar indicator on the right
                if dropPlacement == .after {
                    HStack {
                        Spacer()
                        InsertionBar()
                            .offset(x: 6)
                    }
                }

                // Glowing highlight halo when targeted for folder addition or merge
                if dropPlacement == .merge {
                    let haloSize = (item.type == .folder ? folderSize : iconSize * 0.84) + 8
                    RoundedRectangle(cornerRadius: haloSize * 0.25, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color(red: 0.25, green: 0.65, blue: 1.0),
                                    Color.cyan,
                                    Color.white.opacity(0.9)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3.0
                        )
                        .frame(width: haloSize, height: haloSize)
                        .shadow(color: Color.blue.opacity(0.95), radius: 12)
                        .shadow(color: Color.cyan.opacity(0.8), radius: 6)
                        .shadow(color: Color.white.opacity(0.85), radius: 3)
                        .transition(.scale.combined(with: .opacity))
                }

                // Main Icon (App or Folder)
                ZStack(alignment: .topTrailing) {
                    if item.type == .folder {
                        FolderIconGrid(
                            item: item,
                            size: folderSize,
                            isHighlighted: dropPlacement == .merge,
                            bouncingSubItemIds: viewModel.bouncingItemIds,
                            runningSubItemIds: viewModel.runningSubItemIds(for: item)
                        )
                    } else {
                        Image(nsImage: IconProvider.shared.icon(for: item, size: iconSize))
                            .resizable()
                            .scaledToFit()
                            .frame(width: iconSize, height: iconSize)
                            .clipShape(RoundedRectangle(cornerRadius: iconSize * 0.22, style: .continuous))
                            .overlay(
                                Group {
                                    if dropPlacement == .merge {
                                        RoundedRectangle(cornerRadius: iconSize * 0.22, style: .continuous)
                                            .stroke(Color.white.opacity(0.95), lineWidth: 2.0)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: iconSize * 0.22, style: .continuous)
                                                    .fill(Color.blue.opacity(0.3))
                                            )
                                    }
                                }
                            )
                            .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 1.5)
                    }

                    if item.isPinned {
                        PinBadgeView(size: 13)
                            .offset(x: 3, y: -3)
                    }
                }
                .dockBounce(isBouncing: viewModel.isItemBouncing(item))
            }
            .frame(width: iconSize, height: iconSize)
            .scaleEffect(dropPlacement == .merge ? 1.15 : (isHovered ? 1.12 : 1.0))
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isHovered)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: dropPlacement)

            // 3. Bottom Slot: Running indicator dot for BOTH apps and folders
            ZStack {
                if isRunning {
                    Circle()
                        .fill(Color.white.opacity(0.95))
                        .frame(width: 4, height: 4)
                        .shadow(color: Color.white.opacity(0.8), radius: 2)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(height: 6)
        }
        .frame(width: itemWidth, height: iconSize + 24, alignment: .center)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                viewModel.hoveredItemId = item.id
            } else if viewModel.hoveredItemId == item.id {
                viewModel.hoveredItemId = nil
            }
        }
        .help(item.title)
        .onTapGesture {
            viewModel.launch(item: item)
        }
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: ItemFramesPreferenceKey.self,
                    value: [item.id: geo.frame(in: .named("dockContainer"))]
                )
            }
        )
        .contextMenu {
            contextMenuItems
        }
        // Drag source
        .onDrag {
            print("[DOCK_EVENT] onDrag started for: \(item.title) (id: \(item.id))")
            viewModel.dragSourceId = item.id
            return NSItemProvider(object: item.id.uuidString as NSString)
        }
        // Drop destination
        .onDrop(of: [.plainText, .utf8PlainText, .text], delegate: DockItemDropDelegate(
            targetItem: item,
            viewModel: viewModel,
            itemWidth: itemWidth
        ))
        .popover(
            isPresented: Binding(
                get: { viewModel.activeFolder?.id == item.id },
                set: { if !$0 { viewModel.closeFolderPopover() } }
            ),
            attachmentAnchor: .point(.top),
            arrowEdge: .bottom
        ) {
            if item.type == .folder {
                FolderPopoverView(viewModel: viewModel, folder: item)
            }
        }
    }

    @ViewBuilder
    private var contextMenuItems: some View {
        if item.type == .folder {
            Button("Ouvrir le dossier") {
                viewModel.toggleFolderPopover(item)
            }

            Button("Renommer le dossier...") {
                showRenameDialog()
            }

            Button("Dissocier le dossier") {
                viewModel.dissolveFolder(folderId: item.id)
            }

            Divider()

            Button("Supprimer du dock") {
                viewModel.removeItem(itemId: item.id)
            }
        } else {
            Button("Ouvrir") {
                viewModel.launch(item: item)
            }

            if isRunning {
                Button("Quitter l'application") {
                    viewModel.terminate(item: item)
                }
            }

            Divider()

            Button(item.isPinned ? "Détacher du dock" : "Conserver dans le dock") {
                viewModel.togglePin(itemId: item.id)
            }

            if item.isPinned {
                Button("Supprimer du dock") {
                    viewModel.removeItem(itemId: item.id)
                }
            }
        }
    }

    private func showRenameDialog() {
        let alert = NSAlert()
        alert.messageText = "Renommer le dossier"
        alert.informativeText = "Entrez le nouveau nom pour ce dossier :"
        alert.addButton(withTitle: "Enregistrer")
        alert.addButton(withTitle: "Annuler")
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 220, height: 24))
        input.stringValue = item.title
        alert.accessoryView = input
        if alert.runModal() == .alertFirstButtonReturn {
            viewModel.renameFolder(folderId: item.id, newTitle: input.stringValue)
        }
    }
}

// MARK: - Insertion Bar Visual Indicator

private struct InsertionBar: View {
    var body: some View {
        Capsule()
            .fill(Color.white)
            .frame(width: 3.5, height: 48)
            .shadow(color: Color.blue.opacity(0.85), radius: 5)
            .shadow(color: Color.white.opacity(0.7), radius: 2)
            .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Drop Delegate for Reordering & Folder Merge

private struct DockItemDropDelegate: DropDelegate {
    let targetItem: DockItem
    let viewModel: DockViewModel
    let itemWidth: CGFloat

    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: [.plainText, .utf8PlainText, .text])
    }

    func dropEntered(info: DropInfo) {
        updatePlacement(info: info)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        updatePlacement(info: info)
        return DropProposal(operation: .move)
    }

    func dropExited(info: DropInfo) {
        if viewModel.activeDropTargetId == targetItem.id {
            viewModel.clearDropTarget()
        }
    }

    private func updatePlacement(info: DropInfo) {
        guard let sourceId = viewModel.dragSourceId, sourceId != targetItem.id else {
            return
        }

        let edgeThreshold = targetItem.type == .folder ? itemWidth * 0.16 : itemWidth * 0.28
        let x = info.location.x

        let placement: DropPlacement
        if x < edgeThreshold {
            placement = .before
        } else if x > (itemWidth - edgeThreshold) {
            placement = .after
        } else {
            placement = .merge
        }

        viewModel.setDropTarget(itemId: targetItem.id, placement: placement)
    }

    func performDrop(info: DropInfo) -> Bool {
        let edgeThreshold = targetItem.type == .folder ? itemWidth * 0.16 : itemWidth * 0.28
        let x = info.location.x

        let placement: DropPlacement
        if let active = viewModel.activeDropPlacement, viewModel.activeDropTargetId == targetItem.id {
            placement = active
        } else if x < edgeThreshold {
            placement = .before
        } else if x > (itemWidth - edgeThreshold) {
            placement = .after
        } else {
            placement = .merge
        }

        defer {
            viewModel.clearDropState()
        }

        // 1. Direct sourceId from ViewModel
        if let sourceId = viewModel.dragSourceId, sourceId != targetItem.id {
            applyDrop(sourceId: sourceId, placement: placement)
            return true
        }

        // 2. Fallback via NSItemProvider
        let providers = info.itemProviders(for: [.plainText, .utf8PlainText, .text])
        if let provider = providers.first {
            _ = provider.loadObject(ofClass: NSString.self) { string, _ in
                if let uuidString = string as? String, let sourceId = UUID(uuidString: uuidString) {
                    DispatchQueue.main.async {
                        self.applyDrop(sourceId: sourceId, placement: placement)
                    }
                }
            }
            return true
        }

        return false
    }

    private func applyDrop(sourceId: UUID, placement: DropPlacement) {
        guard sourceId != targetItem.id else { return }
        print("[DOCK_EVENT] applyDrop called! sourceId: \(sourceId), target: \(targetItem.title), placement: \(placement)")

        switch placement {
        case .merge:
            viewModel.mergeIntoFolder(sourceId: sourceId, targetId: targetItem.id)
        case .before, .after:
            viewModel.moveItem(sourceId: sourceId, targetId: targetItem.id, placement: placement)
        }
    }
}
