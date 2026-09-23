# FoldyDock Domain

FoldyDock is an expandable, floating macOS dock with folders, window tracking, and real-time frosted glass blur.

## Language

**DockItem**:
An identifiable visual element positioned in the dock or inside a folder (application, folder, separator).
_Avoid_: Node, widget, component

**Folder**:
A composite dock item grouping multiple applications. A folder has a maximum depth of 1 and cannot contain another folder.
_Avoid_: Directory, group, category

**DockHierarchy**:
The ordered collection and structural tree of dock items, enforcing grouping, reordering, and dissolution invariants.
_Avoid_: ItemList, layout tree, container

**Pinned Application**:
An application persistently positioned in the dock root or inside a folder.
_Avoid_: Favorite, anchored app, bookmark

**Unpinned Application**:
A running application temporarily displayed in the dock while active, which disappears when terminated unless pinned.
_Avoid_: Ephemeral app, background app

**Drop Placement**:
The intended spatial resolution of a drag-and-drop interaction relative to a target item (`before`, `after`, or `merge`).
_Avoid_: Drop position, insert mode
