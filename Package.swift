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
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.10.0")
    ],
    targets: [
        .target(
            name: "WindowOrganizerCore"
        ),
        .executableTarget(
            name: "WindowOrganizerApp",
            dependencies: ["WindowOrganizerCore", .product(name: "Sparkle", package: "Sparkle")],
            // Sparkle.framework is embedded in Contents/Frameworks (Scripts/package_app.sh).
            linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])]
        ),
        .testTarget(
            name: "WindowOrganizerCoreTests",
            dependencies: ["WindowOrganizerCore"]
        ),
        .testTarget(
            name: "WindowOrganizerScreenshotTests",
            dependencies: ["WindowOrganizerApp", "WindowOrganizerCore"]
        )
    ]
)
