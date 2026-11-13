import ProjectDescription
import ProjectDescriptionHelpers

let project = appProject(
    metadata: AppMetadata(
        name: "SlowCard",
        displayName: "SlowCard",
        subtitle: "慢递明信片",
        bundleID: "com.pocketapps.slowcard",
        version: "1.1.0"
    ),
    testDependencies: [.package(product: "PocketTestKit")]
)
