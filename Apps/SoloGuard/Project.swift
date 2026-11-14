import ProjectDescription
import ProjectDescriptionHelpers

let project = appProject(
    metadata: AppMetadata(
        name: "SoloGuard",
        displayName: "SoloGuard",
        subtitle: "独居守护",
        bundleID: "com.pocketapps.sologuard",
        version: "1.2.0"
    ),
    testDependencies: [.package(product: "PocketTestKit")]
)
