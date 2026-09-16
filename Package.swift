// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FoldyDock",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "FoldyDock",
            targets: ["FoldyDock"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "FoldyDock",
            dependencies: [],
            path: "Sources/FoldyDock"
        ),
        .testTarget(
            name: "FoldyDockTests",
            dependencies: ["FoldyDock"],
            path: "Tests/FoldyDockTests"
        )
    ]
)
