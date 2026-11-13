import ProjectDescription
import ProjectDescriptionHelpers

let project = appProject(
    metadata: AppMetadata(
        name: "AmbientLog",
        displayName: "AmbientLog",
        subtitle: "环境音记录仪",
        bundleID: "com.pocketapps.ambientlog",
        version: "1.0.0"
    ),
    testDependencies: [.package(product: "PocketTestKit")]
)
