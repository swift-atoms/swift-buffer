// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-buffer",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(
            name: "Buffer",
            targets: ["Buffer"]
        ),
        .library(
            name: "Buffer Standard Library Integration",
            targets: ["Buffer Standard Library Integration"]
        ),
        .library(
            name: "Buffer Apple Foundation Integration",
            targets: ["Buffer Apple Foundation Integration"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Buffer",
            dependencies: []
        ),
        .target(
            name: "Buffer Standard Library Integration",
            dependencies: ["Buffer"]
        ),
        .target(
            name: "Buffer Apple Foundation Integration",
            dependencies: [
                "Buffer",
                "Buffer Standard Library Integration",
            ]
        ),
        .testTarget(
            name: "Buffer Tests",
            dependencies: ["Buffer"],
            path: "Tests/Buffer Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = [
        .enableExperimentalFeature("BuiltinModule"),
        .enableExperimentalFeature("RawLayout"),
    ]

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
