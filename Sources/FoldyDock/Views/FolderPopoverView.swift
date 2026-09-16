import SwiftUI
import AppKit

public struct FolderPopoverView: View {
    @ObservedObject var viewModel: DockViewModel
    let folder: DockItem

    @State private var folderTitle: String = ""
    @State private var isEditingTitle: Bool = false

    private let columns = [
        GridItem(.adaptive(minimum: 72, maximum: 84), spacing: 14)
    ]

    public init(viewModel: DockViewModel, folder: DockItem) {
        self.viewModel = viewModel
        self.folder = folder
        _folderTitle = State(initialValue: folder.title)
    }

    private var subItems: [DockItem] {
        folder.subItems ?? []
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
                .frame(minWidth: 200, minHeight: 100)
            } else {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(subItems) { subItem in
                        folderAppItemView(subItem)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(18)
        .frame(minWidth: 260, maxWidth: 360)
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

        VStack(spacing: 4) {
            ZStack(alignment: .bottom) {
                ZStack(alignment: .topTrailing) {
                    Image(nsImage: IconProvider.shared.icon(for: item, size: 52))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)

                    if item.isPinned {
                        PinBadgeView(size: 13)
                            .offset(x: 3, y: -3)
                    }
                }
                .dockBounce(isBouncing: viewModel.isItemBouncing(item))

                // Active dot indicator
                if isRunning {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 4, height: 4)
                        .shadow(color: .white.opacity(0.8), radius: 2)
                        .offset(y: 6)
                }
            }
            .frame(height: 58)

            Text(item.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: 76)
        }
        .contentShape(Rectangle())
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
                viewModel.removeFromFolder(subItemId: item.id, folderId: folder.id)
            }
        }
    }
}
