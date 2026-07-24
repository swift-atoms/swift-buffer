// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-buffer",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26)
    ],
    products: [
        .library(name: "Buffer", targets: ["Buffer"])
    ],
    dependencies: [
        .package(path: "../../swift-primitives/swift-collection-primitives"),
        .package(path: "../../swift-primitives/swift-test-primitives")
    ],
    targets: [
        .target(
            name: "Buffer",
            dependencies: [
                .product(name: "Collection Primitives", package: "swift-collection-primitives")
            ]
        ),
        .testTarget(
            name: "Buffer Tests",
            dependencies: [
                "Buffer",
                .product(name: "Test Primitives", package: "swift-test-primitives")
            ]
        )
    ]
)

for target in package.targets where ![.system, .binary, .plugin].contains(target.type) {
    let settings: [SwiftSetting] = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableExperimentalFeature("Lifetimes")
    ]
    target.swiftSettings = (target.swiftSettings ?? []) + settings
}
