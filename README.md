# Pocket Apps

`pocket-apps` 是一个多 App iOS Monorepo，采用 **Tuist + 本地 Swift Package + SwiftUI/SwiftData**。仓库中的每个 App 都是独立 target，拥有独立 Bundle ID、版本号、图标、隐私清单和发布节奏。

## 产品

| App | 副标题 | v1.1 能力 | Bundle ID | 版本 |
|---|---|---|---|---|
| SoloGuard | 独居守护 | 本地生活确认计划、每日提醒、昨日异常提示、连续签到 | `com.pocketapps.sologuard` | `1.1.0` |
| FocusBox | 专注盒子 | 专注计时、完成/放弃、重启恢复、今日与最近 7 天统计 | `com.pocketapps.focusbox` | `1.1.0` |
| SlowCard | 慢递明信片 | 延迟解锁卡片、到达提醒、收藏、归档 | `com.pocketapps.slowcard` | `1.1.0` |
| AmbientLog | 环境音记录仪 | 本机录音、中断保护、播放、搜索、重命名、删除 | `com.pocketapps.ambientlog` | `1.1.0` |
| TabStash iOS | 标签收纳 | `PocketTabStash.v1` JSON 导入/导出、未读/收藏管理 | `com.pocketapps.tabstash` | `1.1.0` |

TabStash 当前使用本地 JSON 文件作为插件与 iOS 之间的数据交换层；iCloud 容器尚未启用。

## 发布状态

仓库内工程发布项已完成：

- 五个 App 可构建、可运行，单元测试通过。
- 每个 App 都有独立 1024×1024 App Icon。
- 每个 App 都包含 `PrivacyInfo.xcprivacy`。
- 权限拒绝、空数据、文件错误和录音中断都有明确 UI 反馈。
- 破坏性操作均需要确认。
- `ITSAppUsesNonExemptEncryption=false`。
- AmbientLog 声明了 `NSMicrophoneUsageDescription`。
- fastlane metadata 包含五个 App 的 App Store 文案骨架。

实际提交 App Store 还需要 Apple 开发者账号、签名证书、App Store Connect API Key、截图和隐私问卷。

## 文档

- 总体设计：[docs/DESIGN.md](docs/DESIGN.md)
- 隐私说明：[PRIVACY.md](PRIVACY.md)
- 进度与待办：[docs/ROADMAP.md](docs/ROADMAP.md)
- 会话交接：[docs/HANDOFF.md](docs/HANDOFF.md)
- 架构决策：[docs/adr](docs/adr)

## 环境要求

- macOS 15+
- Xcode 16+
- Tuist `4.216.6`
- Swift 5.9+
- Ruby 3.3+（发布流水线）
- SwiftLint / SwiftFormat

## 快速开始

```bash
git clone <repository-url>
cd pocket-apps
./scripts/generate.sh
open PocketApps.xcworkspace
```

Tuist 生成的 `*.xcodeproj`、`*.xcworkspace` 与 `Derived/` 不提交。

## 常用命令

```bash
# 生成 Xcode Workspace
./scripts/generate.sh

# SwiftFormat + SwiftLint
./scripts/lint.sh

# 三个共享包测试
./scripts/test.sh

# 五个 App 测试
IOS_SIMULATOR_NAME="iPhone 17" ./scripts/test_apps.sh

# 构建五个 App
./scripts/build_apps.sh

# 发布前完整检查
./scripts/release_preflight.sh
```

CI 中的模拟器默认是 `iPhone 16`，本地 Xcode 可按 `IOS_SIMULATOR_NAME` 覆盖。

## 工程结构

```text
pocket-apps/
├── Apps/
│   ├── SoloGuard/
│   ├── FocusBox/
│   ├── SlowCard/
│   ├── AmbientLog/
│   ├── TabStash/
│   └── _Template/
├── Packages/
│   ├── PocketCore/
│   ├── PocketUI/
│   └── PocketTestKit/
├── Tuist/
│   └── ProjectDescriptionHelpers/
├── fastlane/
├── scripts/
├── .github/workflows/
└── docs/
```

架构边界：

1. App 之间不互相依赖。
2. 共享包不包含任何 App 业务语义。
3. `PocketCore` 提供通知、权限、触感、日志、KV 存储。
4. `PocketUI` 只放可复用 SwiftUI 组件。
5. 每个领域模型、状态机、提醒规则都留在对应 App 内。

## 隐私与权限

| 数据 | 存储 | 是否上传 |
|---|---|---|
| SoloGuard 计划与签到 | SwiftData / App 沙盒 | 否 |
| FocusBox 会话与统计 | SwiftData / App 沙盒 | 否 |
| SlowCard 卡片内容 | SwiftData / App 沙盒 | 否 |
| AmbientLog 录音文件 | App 沙盒 Documents | 否 |
| TabStash 标签页 | SwiftData / App 沙盒 | 否；导出由用户显式分享 |

权限：

- SoloGuard / SlowCard：本地通知，权限拒绝时不阻塞本地功能。
- AmbientLog：麦克风，用途写入 Info.plist；录音只保存在本机。
- TabStash：通过系统文件导入访问用户选择的 JSON 文件。

每个 App 的 `PrivacyInfo.xcprivacy` 声明不追踪用户、不采集数据。

## 新增 App

1. 复制 `Apps/_Template` 到 `Apps/<NewApp>`。
2. 修改 `Project.swift` 中的 `AppMetadata`。
3. 需要额外 Info.plist 键时使用 `additionalInfoPlist`。
4. 在 `Workspace.swift` 注册目录。
5. 运行 `./scripts/generate.sh`。

不要把业务逻辑放进 `Packages/`。

## 发布

版本定义在 `Apps/<App>/Project.swift`：

```swift
AppMetadata(
    name: "SoloGuard",
    bundleID: "com.pocketapps.sologuard",
    version: "1.1.0"
)
```

Tag 必须与 manifest 版本一致：

```bash
git tag SoloGuard@1.1.0
git push origin SoloGuard@1.1.0
```

`release.yml` 会：

1. 解析 tag 中的 App 与版本。
2. 校验版本与 Project.swift 一致。
3. `tuist generate`。
4. 调用 fastlane lane 构建、签名并上传 TestFlight。

App Store 文案位于 `fastlane/metadata/<bundle-id>/`。上线前请替换支持 URL 与隐私 URL 为最终域名，并补齐截图。

发布秘密通过 GitHub Environment `app-store-release` 注入。

## 故障排查

| 问题 | 处理 |
|---|---|
| 找不到 Workspace | 先执行 `./scripts/generate.sh` |
| 模拟器名称不存在 | 设置 `IOS_SIMULATOR_NAME` |
| App Icon 报错 | 确认 `AppIcon.appiconset` 中有 1024×1024 RGB PNG |
| fastlane 失败 | 检查 Team ID、match 仓库和 App Store Connect API Key |
| TabStash 导入失败 | 确认 `schemaVersion` 为 1，URL 可解析 |
