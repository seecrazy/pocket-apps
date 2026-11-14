import ProjectDescription
import ProjectDescriptionHelpers

let project = appProject(
    metadata: AppMetadata(
        name: "FocusBox",
        displayName: "FocusBox",
        subtitle: "专注盒子",
        bundleID: "com.pocketapps.focusbox",
        version: "1.3.0"
    ),
    testDependencies: [.package(product: "PocketTestKit")]
)
