import ProjectDescription
import ProjectDescriptionHelpers

let project = appProject(
    metadata: AppMetadata(
        name: "TemplateApp",
        displayName: "Template App",
        subtitle: "Pocket Apps Template",
        bundleID: "com.pocketapps.template",
        version: "0.1.0"
    ),
    testDependencies: [.package(product: "PocketTestKit")]
)
