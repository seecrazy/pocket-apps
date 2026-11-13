// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PocketTestKit",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(name: "PocketTestKit", targets: ["PocketTestKit"]),
    ],
    dependencies: [
        .package(path: "../PocketCore"),
    ],
    targets: [
        .target(
            name: "PocketTestKit",
            dependencies: ["PocketCore"]
        ),
        .testTarget(
            name: "PocketTestKitTests",
            dependencies: ["PocketTestKit"]
        ),
    ]
)
