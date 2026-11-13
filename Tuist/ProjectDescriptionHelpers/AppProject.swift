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
    let appTarget = Target.target(
        name: metadata.name,
        destinations: .iOS,
        product: .app,
        bundleId: metadata.bundleID,
        deploymentTargets: .iOS("17.0"),
        infoPlist: {
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
        }(),
        sources: ["Sources/**"],
        resources: ["Resources/**"],
        dependencies: [
            .package(product: "PocketCore"),
            .package(product: "PocketUI"),
        ]
    )

    let testTarget = Target.target(
        name: "\(metadata.name)Tests",
        destinations: .iOS,
        product: .unitTests,
        bundleId: "\(metadata.bundleID).tests",
        deploymentTargets: .iOS("17.0"),
        infoPlist: .default,
        sources: ["Tests/**"],
        dependencies: [.target(name: metadata.name)] + testDependencies
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
