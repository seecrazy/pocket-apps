import ProjectDescription
import ProjectDescriptionHelpers

let project = appProject(
    metadata: AppMetadata(
        name: "AmbientLog",
        displayName: "AmbientLog",
        subtitle: "环境音记录仪",
        bundleID: "com.pocketapps.ambientlog",
        version: "1.3.0"
    ),
    additionalInfoPlist: [
        "NSMicrophoneUsageDescription": .string("用于录制你主动选择保存的环境音。录音只保存在 App 沙盒内。"),
        "UIBackgroundModes": .array([.string("audio")]),
    ],
    testDependencies: [.package(product: "PocketTestKit")]
)
