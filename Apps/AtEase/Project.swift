import ProjectDescription
import ProjectDescriptionHelpers

let project = appProject(
    metadata: AppMetadata(
        name: "AtEase",
        displayName: "At Ease",
        subtitle: "冥想 · 呼吸 · 助眠",
        bundleID: "com.pocketapps.atease",
        version: "0.1.0",
        buildNumber: 1
    ),
    additionalInfoPlist: [
        "UILaunchScreen": .dictionary([
            "UIColorName": .string("LaunchBackground"),
        ]),
    ],
    testDependencies: [.package(product: "PocketTestKit")]
)
