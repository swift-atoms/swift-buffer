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

        .library(name: "Buffer Protocol", targets: ["Buffer Protocol"]),

        .library(name: "Buffer", targets: ["Buffer"]),

        .library(
            name: "Buffer Test Support",
            targets: ["Buffer Test Support"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-atoms/swift-cardinal.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-index.git",
            branch: "main"
        ),

        .package(
            url: "https://github.com/swift-atoms/swift-ordinal.git",
            branch: "main"
        ),

        .package(
            url: "https://github.com/swift-atoms/swift-store.git",
            branch: "main"
        ),

        .package(
            url: "https://github.com/swift-atoms/swift-memory.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-tagged.git",
            branch: "main"
        ),
    ],
    targets: [

        .target(
            name: "Buffer",
            dependencies: []
        ),

        .target(
            name: "Buffer Protocol",
            dependencies: [
                .target(name: "Buffer"),
                .product(name: "Cardinal Carrier", package: "swift-cardinal"),
                .product(name: "Index", package: "swift-index"),
                .product(name: "Ordinal Protocol", package: "swift-ordinal"),

                .product(name: "Store", package: "swift-store"),
                .product(name: "Store Protocol", package: "swift-store"),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),

        .target(
            name: "Buffer Test Support",
            dependencies: [
                .target(name: "Buffer"),
                .target(name: "Buffer Protocol"),
                .product(name: "Cardinal Tagged", package: "swift-cardinal"),
                .product(name: "Store", package: "swift-store"),
                .product(name: "Store Protocol", package: "swift-store"),
                .product(name: "Index", package: "swift-index"),
                .product(
                    name: "Tagged Standard Library Integration",
                    package: "swift-tagged"
                ),
                .product(
                    name: "Memory",
                    package: "swift-memory"
                ),
            ],
            path: "Tests/Support"
        ),

        .testTarget(
            name: "Buffer Tests",
            dependencies: [
                .target(name: "Buffer"),
                .target(name: "Buffer Protocol"),
                .target(name: "Buffer Test Support"),
                .product(name: "Cardinal Tagged", package: "swift-cardinal"),
                .product(name: "Index", package: "swift-index"),
                .product(name: "Ordinal", package: "swift-ordinal"),
                .product(name: "Ordinal Protocol", package: "swift-ordinal"),
                .product(name: "Store", package: "swift-store"),
                .product(name: "Store Protocol", package: "swift-store"),
                .product(name: "Tagged", package: "swift-tagged"),
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
