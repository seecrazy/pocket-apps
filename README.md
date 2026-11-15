# Pocket Apps

<p align="left">
  <img alt="Platform" src="https://img.shields.io/badge/iOS-17%2B-0A84FF">
  <img alt="UI" src="https://img.shields.io/badge/UI-SwiftUI-32ADE6">
  <img alt="Data" src="https://img.shields.io/badge/Data-SwiftData-0A84FF">
  <img alt="Project" src="https://img.shields.io/badge/Project-Tuist-7C4DFF">
  <img alt="Status" src="https://img.shields.io/badge/Release-ready_in_repo-34C759">
</p>

`pocket-apps` 是一组小而美的 iOS 工具与体验类 App。仓库采用 **Tuist Workspace + 本地 Swift Package + SwiftUI/SwiftData**，每个 App 都是独立 target，拥有独立 Bundle ID、版本号、图标、隐私清单和发布节奏。

**当前状态**：工程内发布准备完成；六个 App 已通过本机 release preflight。At Ease 已进入 v1.0 发布门槛。实际 TestFlight / App Store 发布仍需 Apple 开发者账号、订阅产品与签名资源。

## 目录

- [产品](#产品)
- [发布状态](#发布状态)
- [环境要求](#环境要求)
- [快速开始](#快速开始)
- [常用命令](#常用命令)
- [部署到真机 iPhone 14](#部署到真机-iphone-14)
- [工程结构](#工程结构)
- [架构边界](#架构边界)
- [隐私与权限](#隐私与权限)
- [新增 App](#新增-app)
- [测试](#测试)
- [发布](#发布)
- [贡献](#贡献)
- [安全](#安全)
- [故障排查](#故障排查)
- [许可证](#许可证)

## 产品

| App | 副标题 | 能力 | Bundle ID | 版本 |
|---|---|---|---|---|
| SoloGuard | 独居守护 | 守护联系人编辑、主联系人管理、安全状态卡、签到趋势 | `com.pocketapps.sologuard` | `1.3.0` |
| FocusBox | 专注盒子 | 专注意图、暂停恢复、进度环、连续专注天数 | `com.pocketapps.focusbox` | `1.3.0` |
| SlowCard | 慢递明信片 | 延迟解锁卡片、到达倒计时、收藏、归档、写作提示 | `com.pocketapps.slowcard` | `1.3.0` |
| AmbientLog | 环境音记录仪 | 后台录音、实时计时、dBFS 波形、文件导出 | `com.pocketapps.ambientlog` | `1.3.0` |
| TabStash iOS | 标签收纳 | JSON 导入/导出、集合管理、批量已读、搜索 | `com.pocketapps.tabstash` | `1.3.0` |
| At Ease（心安） | 冥想 · 呼吸 · 助眠 | 呼吸、计时器、情绪签到、本地进度、触觉、Live Activity、冥想音乐、自由计时器自然音、引导冥想、订阅分层、离线音频、缓存管理、可选预下载、后台音频 | `com.pocketapps.atease` | `1.2.0` |

每个 App 都有独立的 README、设计文档和进度文档：

| App | README | 设计 | 进度 |
|---|---|---|---|
| SoloGuard | [README](Apps/SoloGuard/README.md) | [DESIGN](Apps/SoloGuard/docs/DESIGN.md) | [PROGRESS](Apps/SoloGuard/docs/PROGRESS.md) |
| FocusBox | [README](Apps/FocusBox/README.md) | [DESIGN](Apps/FocusBox/docs/DESIGN.md) | [PROGRESS](Apps/FocusBox/docs/PROGRESS.md) |
| SlowCard | [README](Apps/SlowCard/README.md) | [DESIGN](Apps/SlowCard/docs/DESIGN.md) | [PROGRESS](Apps/SlowCard/docs/PROGRESS.md) |
| AmbientLog | [README](Apps/AmbientLog/README.md) | [DESIGN](Apps/AmbientLog/docs/DESIGN.md) | [PROGRESS](Apps/AmbientLog/docs/PROGRESS.md) |
| TabStash iOS | [README](Apps/TabStash/README.md) | [DESIGN](Apps/TabStash/docs/DESIGN.md) | [PROGRESS](Apps/TabStash/docs/PROGRESS.md) |
| At Ease（心安） | [README](Apps/AtEase/README.md) | [DESIGN](Apps/AtEase/docs/DESIGN.md) | [PROGRESS](Apps/AtEase/docs/PROGRESS.md) |

TabStash 当前使用本地 JSON 文件作为插件与 iOS 之间的数据交换层；iCloud 容器尚未启用。

## 发布状态

仓库内工程发布项已完成：

- 六个 App 可构建、可运行，单元测试通过。
- 每个 App 都有独立 1024×1024 App Icon。
- 每个 App 都包含 `PrivacyInfo.xcprivacy`。
- 权限拒绝、空数据、文件错误和录音中断都有明确 UI 反馈。
- 破坏性操作均需要确认。
- `ITSAppUsesNonExemptEncryption=false`。
- AmbientLog 声明了 `NSMicrophoneUsageDescription`。
- fastlane metadata 包含六个 App 的 App Store 文案骨架。
- 六个 App 有一次性首启说明和设置页。
- At Ease 提供 [App Store 发布门槛](Apps/AtEase/docs/APP_STORE.md)。

实际提交 App Store 还需要 Apple 开发者账号、签名证书、App Store Connect API Key、截图和隐私问卷。

## 环境要求

| 工具 | 版本 |
|---|---|
| macOS | 15+ |
| Xcode | 16+ |
| Tuist | `4.216.6` |
| Swift | 5.9+ |
| Ruby | 3.3+（发布流水线） |
| SwiftLint / SwiftFormat | 最新稳定版 |

设备要求见 [部署到真机 iPhone 14](#部署到真机-iphone-14)。

## 快速开始

```bash
git clone <repository-url>
cd pocket-apps
./scripts/generate.sh
open PocketApps.xcworkspace
```

Tuist 生成的 `*.xcodeproj`、`*.xcworkspace` 与 `Derived/` 不提交。

如果你只想快速看某个 App，可以打开 Workspace 后选择对应 scheme，例如：

```text
FocusBox > iPhone 17 Pro
```

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

## 部署到真机 iPhone 14

仓库支持 Xcode 部署到真机。需要注意两件事：**签名账号** 和 **iPhone 14 的系统版本**。

### 兼容性

| 项目 | 要求 |
|---|---|
| 最低系统版本 | iOS 17.0 |
| iPhone 14 | 需要升级到 iOS 17 或更高版本 |
| Developer Mode | 需要在 iPhone 上开启 |
| 签名 | 需要 Apple Developer Team 或 Personal Team |

Developer Mode 入口：`设置 > 隐私与安全性 > 开发者模式`。

### 使用 Xcode 部署

1. 用数据线连接 iPhone 14。
2. 生成并打开 Workspace：

   ```bash
   ./scripts/generate.sh
   open PocketApps.xcworkspace
   ```

3. 在 Xcode 顶部选择任一 App scheme，例如 `SoloGuard`。
4. 在设备选择器中选择你的 iPhone 14。
5. 选择 target，进入 `Signing & Capabilities`。
6. 选择 Apple Developer Team；没有付费账号时可以使用 Personal Team 试装。
7. 勾选 `Automatically manage signing`。
8. 选择 `Product > Run`。

如果希望生成工程时自动写入 Team ID，先创建本地签名配置：

```bash
cp Tuist/Signing.xcconfig.example Tuist/Signing.xcconfig
```

编辑 `Tuist/Signing.xcconfig`，把 `YOUR_TEAM_ID` 替换成真实 Team ID：

```text
DEVELOPMENT_TEAM = YOUR_TEAM_ID
```

然后重新生成工程：

```bash
./scripts/generate.sh
open PocketApps.xcworkspace
```

`YOUR_TEAM_ID` 可以在 [Apple Developer Account Membership](https://developer.apple.com/account) 页面查看。`Tuist/Signing.xcconfig` 已加入 `.gitignore`，不要提交真实 Team ID。

### 免费开发者账号限制

Personal Team 可以用于本机安装，但有系统限制：

- App 会周期性过期，需要重新安装。
- 首次安装后需要在 iPhone 上信任开发者证书。
- 不能使用部分高级 entitlement。
- 不能直接上传 TestFlight。

### 真机部署失败排查

| 提示 / 现象 | 处理 |
|---|---|
| 设备不显示 | 检查数据线、解锁手机、允许“信任此电脑”，然后重启 Xcode |
| iOS version is lower than deployment target | 将 iPhone 14 升级到 iOS 17+ |
| No profiles for ... were found | 选择 Team，并勾选 Automatically manage signing |
| Developer Mode disabled | 在 iPhone 上开启开发者模式后重启设备 |
| Untrusted Developer | 在 iPhone `设置 > 通用 > VPN与设备管理` 中信任开发者证书 |

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

## 架构边界

1. App 之间不互相依赖。
2. 共享包不包含任何 App 业务语义。
3. `PocketCore` 提供通知、权限、触感、日志、KV 存储。
4. `PocketUI` 只放可复用 SwiftUI 组件。
5. 每个领域模型、状态机、提醒规则都留在对应 App 内。

设计文档与架构决策见：

- [docs/DESIGN.md](docs/DESIGN.md)
- [docs/adr](docs/adr)

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

每个 App 的 `PrivacyInfo.xcprivacy` 声明不追踪用户、不采集数据。完整说明见 [PRIVACY.md](PRIVACY.md)。

## 新增 App

1. 复制 `Apps/_Template` 到 `Apps/<NewApp>`。
2. 修改 `Project.swift` 中的 `AppMetadata`。
3. 需要额外 Info.plist 键时使用 `additionalInfoPlist`。
4. 在 `Workspace.swift` 注册目录。
5. 运行 `./scripts/generate.sh`。

不要把业务逻辑放进 `Packages/`。

## 测试

```bash
./scripts/test.sh
IOS_SIMULATOR_NAME="iPhone 17" ./scripts/test_apps.sh
./scripts/build_apps.sh
./scripts/release_preflight.sh
```

测试覆盖：

- SoloGuard 签到、昨日异常与连续状态。
- FocusBox 会话恢复与 7 天统计。
- SlowCard 生命周期、收藏与归档过滤。
- AmbientLog 搜索过滤、中断描述。
- TabStash JSON schema、无效 URL 与最新时间合并。
- PocketCore / PocketTestKit 通知调度 fake。
- PocketUI 可复用组件。

## 发布

版本定义在 `Apps/<App>/Project.swift`：

```swift
AppMetadata(
    name: "SoloGuard",
    bundleID: "com.pocketapps.sologuard",
    version: "1.3.0"
)
```

Tag 必须与 manifest 版本一致：

```bash
git tag SoloGuard@1.3.0
git push origin SoloGuard@1.3.0
```

`release.yml` 会：

1. 解析 tag 中的 App 与版本。
2. 校验版本与 Project.swift 一致。
3. `tuist generate`。
4. 调用 fastlane lane 构建、签名并上传 TestFlight。

App Store 文案位于 `fastlane/metadata/<bundle-id>/`。上线前请替换支持 URL 与隐私 URL 为最终域名，并补齐截图。

发布秘密通过 GitHub Environment `app-store-release` 注入。

## 贡献

1. 创建功能分支。
2. 执行 `./scripts/generate.sh` 后再打开 Xcode。
3. 修改前检查 `docs/DESIGN.md`；涉及方案变化时，先更新设计文档或 ADR。
4. 保持 App 间隔离，不要把业务逻辑放入共享包。
5. 提交前运行：

   ```bash
   ./scripts/lint.sh
   ./scripts/test.sh
   IOS_SIMULATOR_NAME="iPhone 17" ./scripts/test_apps.sh
   ```

6. 使用简洁的 conventional commit，例如 `feat: add focus session tags`。

## 安全

如果发现安全问题，请不要直接创建公开 issue。先通过仓库维护者提供的私密渠道联系。

## 故障排查

| 问题 | 处理 |
|---|---|
| 找不到 Workspace | 先执行 `./scripts/generate.sh` |
| 模拟器名称不存在 | 设置 `IOS_SIMULATOR_NAME` |
| App Icon 报错 | 确认 `AppIcon.appiconset` 中有 1024×1024 RGB PNG |
| fastlane 失败 | 检查 Team ID、match 仓库和 App Store Connect API Key |
| 真机签名失败 | 在 Xcode 选择 Development Team，或创建 `Tuist/Signing.xcconfig` 后重新生成工程 |
| TabStash 导入失败 | 确认 `schemaVersion` 为 1，URL 可解析 |

## 许可证

当前仓库未附带开源许可证，默认保留所有权利。公开发布前应先选择并添加 `LICENSE`。
