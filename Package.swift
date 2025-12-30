// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-buffer",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
    ],
    products: [
        .library(name: "Buffer", targets: ["Buffer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-standards.git", from: "0.24.1"),
    ],
    targets: [
        .target(
            name: "Buffer",
            dependencies: [
                .product(name: "Standards", package: "swift-standards"),
            ]
        ),
        .testTarget(
            name: "Buffer Tests",
            dependencies: [
                "Buffer",
                .product(name: "StandardsTestSupport", package: "swift-standards"),
            ]
        ),
    ]
)

for target in package.targets where ![.system, .binary, .plugin].contains(target.type) {
    let settings: [SwiftSetting] = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableExperimentalFeature("Lifetimes"),
    ]
    target.swiftSettings = (target.swiftSettings ?? []) + settings
}
