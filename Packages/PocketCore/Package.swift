// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PocketCore",
    defaultLocalization: "zh-Hans",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(name: "PocketCore", targets: ["PocketCore"]),
    ],
    targets: [
        .target(name: "PocketCore"),
        .testTarget(
            name: "PocketCoreTests",
            dependencies: ["PocketCore"]
        ),
    ]
)
