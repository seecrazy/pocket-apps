import ProjectDescription
import ProjectDescriptionHelpers

let metadata = AppMetadata(
    name: "AtEase",
    displayName: "At Ease",
    subtitle: "冥想 · 呼吸 · 助眠",
    bundleID: "com.pocketapps.atease",
    version: "0.7.0",
    buildNumber: 1
)

let signingSettings: Settings = .settings(
    base: [
        "CODE_SIGN_STYLE": .string("Automatic"),
    ]
)

let appInfoPlist: InfoPlist = .extendingDefault(
    with: [
        "CFBundleDisplayName": .string(metadata.displayName),
        "CFBundleShortVersionString": .string(metadata.version),
        "CFBundleVersion": .string("\(metadata.buildNumber)"),
        "UILaunchScreen": .dictionary([
            "UIColorName": .string("LaunchBackground"),
        ]),
        "UISupportedInterfaceOrientations": .array([.string("UIInterfaceOrientationPortrait")]),
        "ITSAppUsesNonExemptEncryption": .boolean(false),
        "NSSupportsLiveActivities": .boolean(true),
        "NSSupportsLiveActivitiesFrequentUpdates": .boolean(false),
        "NSHealthShareUsageDescription": .string("At Ease 不会读取你的健康数据。当前功能只需要在授权后写入正念分钟。"),
        "NSHealthUpdateUsageDescription": .string("在你完成呼吸或计时练习后，写入对应的正念分钟。"),
    ]
)

let widgetInfoPlist: InfoPlist = .extendingDefault(
    with: [
        "CFBundleDisplayName": .string("At Ease Widgets"),
        "CFBundleShortVersionString": .string(metadata.version),
        "CFBundleVersion": .string("\(metadata.buildNumber)"),
        "NSExtension": .dictionary([
            "NSExtensionPointIdentifier": .string("com.apple.widgetkit-extension"),
        ]),
    ]
)

let widgetTarget = Target.target(
    name: "AtEaseWidgets",
    destinations: .iOS,
    product: .appExtension,
    bundleId: "\(metadata.bundleID).widgets",
    deploymentTargets: .iOS("17.0"),
    infoPlist: widgetInfoPlist,
    sources: [
        "Widgets/**",
        "Sources/Shared/LiveActivity/**",
    ],
    settings: signingSettings
)

let appTarget = Target.target(
    name: metadata.name,
    destinations: .iOS,
    product: .app,
    bundleId: metadata.bundleID,
    deploymentTargets: .iOS("17.0"),
    infoPlist: appInfoPlist,
    sources: ["Sources/**"],
    resources: ["Resources/**"],
    entitlements: .dictionary([
        "com.apple.developer.healthkit": .boolean(true),
    ]),
    dependencies: [
        .package(product: "PocketCore"),
        .package(product: "PocketUI"),
        .target(name: "AtEaseWidgets"),
    ],
    settings: signingSettings
)

let testTarget = Target.target(
    name: "\(metadata.name)Tests",
    destinations: .iOS,
    product: .unitTests,
    bundleId: "\(metadata.bundleID).tests",
    deploymentTargets: .iOS("17.0"),
    infoPlist: .default,
    sources: ["Tests/**"],
    dependencies: [.target(name: metadata.name), .package(product: "PocketTestKit")],
    settings: signingSettings
)

let project = Project(
    name: metadata.name,
    packages: [
        .package(path: "../../Packages/PocketCore"),
        .package(path: "../../Packages/PocketUI"),
        .package(path: "../../Packages/PocketTestKit"),
    ],
    targets: [appTarget, widgetTarget, testTarget]
)
