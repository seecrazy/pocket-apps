import ProjectDescription
import ProjectDescriptionHelpers

let project = appProject(
    metadata: AppMetadata(
        name: "TabStash",
        displayName: "TabStash",
        subtitle: "标签收纳",
        bundleID: "com.pocketapps.tabstash",
        version: "1.3.0"
    ),
    testDependencies: [.package(product: "PocketTestKit")]
)
