// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FolderDock",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "FolderDock",
            targets: ["FolderDock"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "FolderDock",
            dependencies: [],
            path: "Sources/FolderDock"
        ),
        .testTarget(
            name: "FolderDockTests",
            dependencies: ["FolderDock"],
            path: "Tests/FolderDockTests"
        )
    ]
)
