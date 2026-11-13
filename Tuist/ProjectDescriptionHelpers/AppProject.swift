import Foundation
import ProjectDescription

public struct AppMetadata {
    public let name: String
    public let displayName: String
    public let subtitle: String
    public let bundleID: String
    public let version: String
    public let buildNumber: Int

    public init(
        name: String,
        displayName: String,
        subtitle: String,
        bundleID: String,
        version: String,
        buildNumber: Int = 1
    ) {
        self.name = name
        self.displayName = displayName
        self.subtitle = subtitle
        self.bundleID = bundleID
        self.version = version
        self.buildNumber = buildNumber
    }
}

public func appProject(
    metadata: AppMetadata,
    additionalInfoPlist: [String: Plist.Value] = [:],
    testDependencies: [TargetDependency] = []
) -> Project {
    let signingSettings = localSigningSettings()

    let appTarget = Target.target(
        name: metadata.name,
        destinations: .iOS,
        product: .app,
        bundleId: metadata.bundleID,
        deploymentTargets: .iOS("17.0"),
        infoPlist: appInfoPlist(metadata: metadata, additionalInfoPlist: additionalInfoPlist),
        sources: ["Sources/**"],
        resources: ["Resources/**"],
        dependencies: [
            .package(product: "PocketCore"),
            .package(product: "PocketUI"),
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
        dependencies: [.target(name: metadata.name)] + testDependencies,
        settings: signingSettings
    )

    return Project(
        name: metadata.name,
        packages: [
            .package(path: "../../Packages/PocketCore"),
            .package(path: "../../Packages/PocketUI"),
            .package(path: "../../Packages/PocketTestKit"),
        ],
        targets: [appTarget, testTarget]
    )
}

private func appInfoPlist(
    metadata: AppMetadata,
    additionalInfoPlist: [String: Plist.Value]
) -> InfoPlist {
    var values: [String: Plist.Value] = [
        "CFBundleDisplayName": .string(metadata.displayName),
        "CFBundleShortVersionString": .string(metadata.version),
        "CFBundleVersion": .string("\(metadata.buildNumber)"),
        "UILaunchScreen": .dictionary([:]),
        "UISupportedInterfaceOrientations": .array([.string("UIInterfaceOrientationPortrait")]),
        "ITSAppUsesNonExemptEncryption": .boolean(false),
    ]
    for (key, value) in additionalInfoPlist {
        values[key] = value
    }
    return InfoPlist.extendingDefault(with: values)
}

private func localSigningSettings() -> Settings {
    let configURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Signing.xcconfig")

    guard FileManager.default.fileExists(atPath: configURL.path) else {
        return .settings(base: [
            "CODE_SIGN_STYLE": .string("Automatic"),
        ])
    }

    return .settings(
        base: [
            "CODE_SIGN_STYLE": .string("Automatic"),
        ],
        configurations: [
            .debug(name: .debug, xcconfig: .relativeToRoot("Tuist/Signing.xcconfig")),
            .release(name: .release, xcconfig: .relativeToRoot("Tuist/Signing.xcconfig")),
        ]
    )
}
