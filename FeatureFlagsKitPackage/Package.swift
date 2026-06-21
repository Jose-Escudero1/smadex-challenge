// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FeatureFlagsKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "FeatureFlagsKit",
            targets: ["FeatureFlagsKit"]
        )
    ],
    targets: [
        .target(
            name: "FeatureFlagsKit"
        ),
        .testTarget(
            name: "FeatureFlagsKitTests",
            dependencies: ["FeatureFlagsKit"]
        )
    ]
)
