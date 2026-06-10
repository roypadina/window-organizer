// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WindowOrganizer",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "WindowOrganizerCore",
            targets: ["WindowOrganizerCore"]
        ),
        .executable(
            name: "WindowOrganizerApp",
            targets: ["WindowOrganizerApp"]
        )
    ],
    targets: [
        .target(
            name: "WindowOrganizerCore"
        ),
        .executableTarget(
            name: "WindowOrganizerApp",
            dependencies: ["WindowOrganizerCore"]
        ),
        .testTarget(
            name: "WindowOrganizerCoreTests",
            dependencies: ["WindowOrganizerCore"]
        )
    ]
)
