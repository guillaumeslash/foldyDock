import SwiftUI
import AppKit

public struct FolderPopoverView: View {
    @ObservedObject var viewModel: DockViewModel
    let folder: DockItem

    @State private var folderTitle: String = ""
    @State private var isEditingTitle: Bool = false

    private let appIconSize: CGFloat = 64.0
    private let columns = [
        GridItem(.adaptive(minimum: 88, maximum: 104), spacing: 16)
    ]

    public init(viewModel: DockViewModel, folder: DockItem) {
        self.viewModel = viewModel
        self.folder = folder
        _folderTitle = State(initialValue: folder.title)
    }

    private var currentFolder: DockItem {
        viewModel.items.first(where: { $0.id == folder.id }) ?? folder
    }

    private var subItems: [DockItem] {
        currentFolder.subItems ?? []
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Header: Folder Title + Close Button
            HStack {
                if isEditingTitle {
                    TextField("Nom du dossier", text: $folderTitle, onCommit: {
                        isEditingTitle = false
                        viewModel.renameFolder(folderId: folder.id, newTitle: folderTitle)
                    })
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(6)
                } else {
                    Text(folder.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .onTapGesture(count: 2) {
                            isEditingTitle = true
                        }
                }

                Spacer()

                // Edit title button
                Button(action: {
                    if isEditingTitle {
                        viewModel.renameFolder(folderId: folder.id, newTitle: folderTitle)
                    }
                    isEditingTitle.toggle()
                }) {
                    Image(systemName: isEditingTitle ? "checkmark.circle.fill" : "pencil.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .buttonStyle(.plain)

                // Close button
                Button(action: {
                    viewModel.closeFolderPopover()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 6)

            Divider()
                .background(Color.white.opacity(0.15))

            // Grid of applications
            if subItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.4))
                    Text("Dossier vide")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(minWidth: 240, minHeight: 110)
            } else {
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(subItems) { subItem in
                        folderAppItemView(subItem)
                    }
                }
                .padding(.top, 4)
                .animation(.spring(response: 0.32, dampingFraction: 0.78), value: subItems.map(\.id))
            }
        }
        .padding(18)
        .frame(minWidth: 320, maxWidth: 480)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(white: 0.14).opacity(0.35))
        )
        .coordinateSpace(name: "folderPopover")
        .onPreferenceChange(FolderItemFramesPreferenceKey.self) { frames in
            viewModel.folderItemFrames = frames
        }
        .onDisappear {
            viewModel.folderItemFrames = [:]
        }
    }

    @ViewBuilder
    private func folderAppItemView(_ item: DockItem) -> some View {
        let isRunning = viewModel.isItemRunning(item)
        let windowCount = viewModel.windowCount(for: item)
        let isTargeted = viewModel.activeDropTargetId == item.id
        let placement = viewModel.activeDropPlacement

        VStack(spacing: 2) {
            Text(item.title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(Color.white.opacity(0.92))
                .shadow(color: Color.black.opacity(0.8), radius: 1.5, x: 0, y: 1)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: 88)

            ZStack(alignment: .top) {
                // Drop insertion indicator on the left
                if isTargeted && placement == .before {
                    HStack {
                        Capsule()
                            .fill(Color.white)
                            .frame(width: 3.5, height: appIconSize * 0.85)
                            .shadow(color: Color.blue.opacity(0.9), radius: 5)
                            .shadow(color: Color.white.opacity(0.7), radius: 2)
                            .offset(x: -5)
                        Spacer()
                    }
                }

                // Drop insertion indicator on the right
                if isTargeted && placement == .after {
                    HStack {
                        Spacer()
                        Capsule()
                            .fill(Color.white)
                            .frame(width: 3.5, height: appIconSize * 0.85)
                            .shadow(color: Color.blue.opacity(0.9), radius: 5)
                            .shadow(color: Color.white.opacity(0.7), radius: 2)
                            .offset(x: 5)
                    }
                }

                // App icon
                Image(nsImage: IconProvider.shared.icon(for: item, size: appIconSize))
                    .resizable()
                    .scaledToFit()
                    .frame(width: appIconSize, height: appIconSize)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2.5)
                    .dockBounce(isBouncing: viewModel.isItemBouncing(item))

                // Active multi-window indicator
                if isRunning {
                    MultiWindowIndicatorView(windowCount: windowCount, dotSize: 4.5, spacing: 3.5)
                        .offset(y: appIconSize + 4)
                }
            }
            .frame(width: 88, height: appIconSize + 14)
        }
        .frame(width: 88)
        .contentShape(Rectangle())
        .scaleEffect(isTargeted ? 1.05 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isTargeted)
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: FolderItemFramesPreferenceKey.self,
                    value: [item.id: geo.frame(in: .named("folderPopover"))]
                )
            }
        )
        .onTapGesture {
            viewModel.launch(item: item)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                viewModel.closeFolderPopover()
            }
        }
        .onDrag {
            viewModel.dragSourceId = item.id
            return NSItemProvider(object: item.id.uuidString as NSString)
        }
        .onDrop(of: [.plainText, .utf8PlainText, .text], delegate: FolderItemDropDelegate(
            targetItem: item,
            folderId: currentFolder.id,
            viewModel: viewModel,
            itemWidth: 88
        ))
        .contextMenu {
            Button("Ouvrir") {
                viewModel.launch(item: item)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                    viewModel.closeFolderPopover()
                }
            }

            if isRunning {
                Button("Quitter l'application") {
                    viewModel.terminate(item: item)
                }
            }

            Divider()

            Button("Sortir du dossier") {
                viewModel.removeFromFolder(subItemId: item.id, folderId: currentFolder.id)
            }
        }
    }
}

// MARK: - Drop Delegate for Reordering inside a Folder

private struct FolderItemDropDelegate: DropDelegate {
    let targetItem: DockItem
    let folderId: UUID
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
        let x = info.location.x
        let placement: DropPlacement = x < (itemWidth / 2) ? .before : .after
        viewModel.setDropTarget(itemId: targetItem.id, placement: placement)
    }

    func performDrop(info: DropInfo) -> Bool {
        let x = info.location.x
        let placement: DropPlacement = x < (itemWidth / 2) ? .before : .after

        defer {
            viewModel.clearDropState()
        }

        if let sourceId = viewModel.dragSourceId, sourceId != targetItem.id {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                viewModel.moveSubItem(
                    folderId: folderId,
                    sourceId: sourceId,
                    targetId: targetItem.id,
                    placement: placement
                )
            }
            return true
        }

        let providers = info.itemProviders(for: [.plainText, .utf8PlainText, .text])
        if let provider = providers.first {
            _ = provider.loadObject(ofClass: NSString.self) { string, _ in
                if let uuidString = string as? String, let sourceId = UUID(uuidString: uuidString) {
                    DispatchQueue.main.async {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                            self.viewModel.moveSubItem(
                                folderId: self.folderId,
                                sourceId: sourceId,
                                targetId: self.targetItem.id,
                                placement: placement
                            )
                        }
                    }
                }
            }
            return true
        }

        return false
    }
}
