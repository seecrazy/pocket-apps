// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PocketUI",
    defaultLocalization: "zh-Hans",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(name: "PocketUI", targets: ["PocketUI"]),
    ],
    dependencies: [
        .package(path: "../PocketCore"),
    ],
    targets: [
        .target(
            name: "PocketUI",
            dependencies: ["PocketCore"]
        ),
        .testTarget(
            name: "PocketUITests",
            dependencies: ["PocketUI"]
        ),
    ]
)
