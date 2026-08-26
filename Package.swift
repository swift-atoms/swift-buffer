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

        .library(name: "Buffer Primitive", targets: ["Buffer Primitive"]),

        .library(name: "Buffer Protocol", targets: ["Buffer Protocol"]),

        .library(name: "Buffer", targets: ["Buffer"]),

        .library(
            name: "Buffer Test Support",
            targets: ["Buffer Test Support"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-molecules/swift-index.git",
            branch: "main"
        ),

        .package(
            url: "https://github.com/swift-molecules/swift-storage.git",
            branch: "main"
        ),

        .package(
            url: "https://github.com/swift-molecules/swift-memory.git",
            branch: "main"
        ),
    ],
    targets: [

        .target(
            name: "Buffer Primitive",
            dependencies: []
        ),

        .target(
            name: "Buffer Protocol",
            dependencies: [
                "Buffer Primitive",
                .product(name: "Index", package: "swift-index"),

                .product(name: "Store Protocol", package: "swift-storage"),
            ]
        ),

        .target(
            name: "Buffer",
            dependencies: [
                "Buffer Primitive",
                "Buffer Protocol",
            ]
        ),

        .target(
            name: "Buffer Test Support",
            dependencies: [
                "Buffer",
                .product(name: "Store Protocol", package: "swift-storage"),
                .product(name: "Index", package: "swift-index"),
                .product(
                    name: "Memory Test Support",
                    package: "swift-memory"
                ),
            ],
            path: "Tests/Support"
        ),

        .testTarget(
            name: "Buffer Tests",
            dependencies: [
                .target(name: "Buffer"),
                .target(name: "Buffer Test Support"),
                .product(name: "Index", package: "swift-index"),
                .product(name: "Store Protocol", package: "swift-storage"),
            ]
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
