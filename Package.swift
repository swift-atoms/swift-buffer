// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-buffer-primitives",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [

        .library(name: "Buffer Primitive", targets: ["Buffer Primitive"]),

        .library(name: "Buffer Protocol Primitives", targets: ["Buffer Protocol Primitives"]),

        .library(name: "Buffer Primitives", targets: ["Buffer Primitives"]),

        .library(
            name: "Buffer Primitives Test Support",
            targets: ["Buffer Primitives Test Support"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-primitives/swift-index-primitives.git",
            branch: "main"
        ),

        .package(
            url: "https://github.com/swift-primitives/swift-storage-primitives.git",
            branch: "main"
        ),

        .package(
            url: "https://github.com/swift-primitives/swift-memory-primitives.git",
            branch: "main"
        ),
    ],
    targets: [

        .target(
            name: "Buffer Primitive",
            dependencies: []
        ),

        .target(
            name: "Buffer Protocol Primitives",
            dependencies: [
                "Buffer Primitive",
                .product(name: "Index Primitives", package: "swift-index-primitives"),

                .product(name: "Store Protocol Primitives", package: "swift-storage-primitives"),
            ]
        ),

        .target(
            name: "Buffer Primitives",
            dependencies: [
                "Buffer Primitive",
                "Buffer Protocol Primitives",
            ]
        ),

        .target(
            name: "Buffer Primitives Test Support",
            dependencies: [
                "Buffer Primitives",
                .product(name: "Store Protocol Primitives", package: "swift-storage-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(
                    name: "Memory Primitives Test Support",
                    package: "swift-memory-primitives"
                ),
            ],
            path: "Tests/Support"
        ),

        .testTarget(
            name: "Buffer Primitives Tests",
            dependencies: [
                .target(name: "Buffer Primitives"),
                .target(name: "Buffer Primitives Test Support"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Store Protocol Primitives", package: "swift-storage-primitives"),
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
