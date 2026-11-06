// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DoodleStudio",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "DoodleStudio",
            targets: ["DoodleStudio"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "DoodleStudio",
            dependencies: [],
            path: "DoodleStudio",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "DoodleStudioTests",
            dependencies: ["DoodleStudio"],
            path: "DoodleStudioTests"
        )
    ]
)
