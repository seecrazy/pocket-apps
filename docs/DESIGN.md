# Pocket Apps 设计文档

> 状态：已采纳
> 更新时间：2026-11-14（v1.3 / At Ease v0.1 发布准备）

## 1. 目标与非目标

### 目标

- 建立一个可持续扩展的 iOS Monorepo `pocket-apps`，承载多个可独立发布的轻量 App。
- 共享基础设施，但不共享业务语义；每个 App 的领域模型、状态机和 UI 逻辑保持独立。
- 使用声明式工程描述消除 `.xcodeproj` 合并冲突，使工程可在 CI 中稳定复现。
- 让新 App 的接入流程标准化：复制模板、修改标识、注册 Workspace、生成工程。
- 让任意 App 可通过 `<App>@<version>` tag 独立进入发布流水线。

### 非目标

- 不在 v1 引入云端后端；核心产品均以本机数据优先。
- 不做 Android、Web 或桌面客户端；Monorepo 的首个跨端形态只覆盖 TabStash 浏览器插件对应的 iOS 伴侣端。
- 不把各 App 的业务代码抽到共享包；共享包只提供可复用的无业务能力。
- 不在 v1 实现 App 之间的 Universal Link、App Group 或 Watch App 互通。

## 2. 产品定位

`pocket-apps` 是“口袋应用集”，聚焦独立、即开即用的小工具与体验型产品。当前首批产品保持独立的 Bundle ID、App Store Connect 记录、版本号与发布节奏。

| # | App | 副标题 | 方向 | Bundle ID | v1 边界 |
|---|---|---|---|---|---|
| 1 | SoloGuard | 独居守护 | 独居安全与生活确认 | `com.pocketapps.sologuard` | 本机计划、签到状态、提醒；不做真实 SOS 与紧急联系人外发 |
| 2 | FocusBox | 专注盒子 | 注意力恢复与屏幕戒断 | `com.pocketapps.focusbox` | 本机会话与专注统计；v1 不做社交打卡 |
| 3 | SlowCard | 慢递明信片 | 慢交互与情绪价值 | `com.pocketapps.slowcard` | 本地慢递卡片；v1 不做真实邮政寄送 |
| 4 | AmbientLog | 环境音记录仪 | iOS 独占能力工具 | `com.pocketapps.ambientlog` | 本机录音、环境记录；不做自动上传 |
| 5 | TabStash iOS | 标签收纳 | 浏览器插件伴侣 | `com.pocketapps.tabstash` | 通过 `PocketTabStash.v1` JSON 导入/导出标签页集合；不做浏览器执行注入 |
| 6 | At Ease（心安） | 冥想 · 呼吸 · 助眠 | 低门槛冥想 | `com.pocketapps.atease` | v0.1 只做呼吸、计时器、情绪签到与本机进度；不做订阅、云内容和 HealthKit |

## 3. 架构总览

### 3.1 工程形态

- `Workspace.swift` 是唯一显式入口，声明全部 App 与本地 Package。
- 每个 App 目录包含自己的 `Project.swift`、SwiftUI 入口、业务代码、资源与测试。
- `Packages/` 使用 SPM 本地包：`PocketCore`、`PocketUI`、`PocketTestKit`。
- `.xcodeproj`、`.xcworkspace` 与 `Derived/` 均不提交，由 Tuist 生成。
- 共享配置由 `Tuist/ProjectDescriptionHelpers/AppProject.swift` 注入，避免每个 App 重复维护 target 描述。

### 3.2 技术栈

| 类别 | 选择 | 说明 |
|---|---|---|
| 语言 | Swift 5 | 保持与当前 Tuist/Xcode 工具链兼容，后续可按 App 独立迁移 Swift 6 strict concurrency |
| UI | SwiftUI + 必要 UIKit 桥接 | 所有 App 以 SwiftUI 为主；Family Controls、AVAudioSession 等必要时桥接 |
| 数据 | iOS 17+ SwiftData；`UserDefaults` 只存轻量偏好 | `PocketCore.Storage` 提供容器与轻量 Key-Value 门面 |
| 依赖 | SPM 本地包 + 第三方 SPM | v1 尽量零第三方运行时依赖 |
| 测试 | XCTest + Swift Testing | 单元测试优先覆盖状态机与存储 |
| 生成 | Tuist | 生成 Workspace/Project，CI 可复现 |
| CI/CD | GitHub Actions + fastlane | lint、受影响 App 构建测试、tag 发布 |

### 3.3 模块边界

```text
App Target
  ├─ App entry (@main)
  ├─ App-scoped state machine / view model
  ├─ App-scoped SwiftData model
  └─ UI composition
        ↓ depends on
PocketUI
  ├─ PrimaryButton
  ├─ SettingRow
  ├─ EmptyStateView
  ├─ CardContainer
  └─ StatusBarChip
        ↓ depends on
PocketCore
  ├─ Haptics
  ├─ Logging
  ├─ Permissions
  └─ KeyValueStore
```

`PocketTestKit` 仅被测试 target 引用，提供确定性时钟、内存 KV store 和权限 mock。

## 4. 用户流程

### SoloGuard

1. 首次启动展示隐私边界说明：数据仅保存在本机，v1 不自动外发信息。
2. 用户创建“生活确认计划”，选择频率、提醒时间和连续失败后的本地标记。
3. 每次提醒到达后用户打开 App 或点击通知动作完成签到。
4. 列表按日期展示签到连续性与异常日。
5. 设置可编辑计划或关闭提醒。

### FocusBox

1. 用户选择 25 / 45 / 60 分钟或自定义专注时长。
2. 开始会话后展示倒计时与“完成 / 放弃”入口。
3. 会话完成后记录专注时长、完成状态和当日聚合。
4. 首页显示最近 7 天的本地专注统计。
5. v1 不强制锁机；用户可以从系统返回其他 App，但会话计时继续。

### SlowCard

1. 用户撰写一张给自己的明信片，选择解锁延迟（例如 7 / 30 / 90 天）。
2. 卡片进入“在路上”状态，写作内容在到达前保持不可查看。
3. 到达日解锁后进入“已收到”状态，用户可标记收藏。
4. 首页优先显示最近一封将要到达的卡片。
5. v1 不提供发送或分享功能。

### AmbientLog

1. 用户查看麦克风权限说明后创建一条环境记录。
2. 开始录音后显示计时器、波形占位与停止按钮。
3. 停止后生成音频文件与记录条目。
4. 列表支持播放、重命名与删除。
5. v1 不上传云端，音频保存在 App 沙盒内。

### TabStash iOS

1. 用户在浏览器插件端导出 `PocketTabStash.v1` JSON。
2. iOS App 导入 JSON，展示未读与已读分组。
3. 用户打开 URL 系统浏览器后手动标记已读。
4. 列表支持按集合与收藏过滤。
5. v1 iOS 侧不做插件协议反向写入；同步冲突以最近修改时间优先。

## 5. 数据与状态模型

### 5.1 SoloGuard

```swift
struct CheckInPlan {
    var id: UUID
    var title: String
    var interval: PlanInterval
    var reminderHour: Int
    var reminderMinute: Int
    var isEnabled: Bool
}

struct DailyCheckIn {
    var id: UUID
    var day: Date
    var completedAt: Date?
    var note: String?
}

enum PlanInterval { case daily, weekly }
```

状态：

```text
计划启用 → 今日待确认 → 已确认 / 已错过 → 连续计数更新
```

### 5.2 FocusBox

```swift
struct FocusSession {
    var id: UUID
    var startedAt: Date
    var plannedMinutes: Int
    var completedAt: Date?
    var status: FocusSessionStatus
}

enum FocusSessionStatus { case running, completed, abandoned }
```

状态：

```text
idle → running → completed
              ↘ abandoned
```

### 5.3 SlowCard

```swift
struct SlowCard {
    var id: UUID
    var title: String
    var body: String
    var createdAt: Date
    var unlockAt: Date
    var isFavorite: Bool
}
```

派生状态：

```text
createdAt < now < unlockAt → 在路上
unlockAt <= now           → 已收到
isFavorite                → 收藏（不影响生命周期）
```

### 5.4 AmbientLog

```swift
struct AmbientRecording {
    var id: UUID
    var title: String
    var startedAt: Date
    var duration: TimeInterval
    var fileURL: URL
}
```

状态：

```text
idle → permissionRequired → recording → saved → playing
                                          ↘ deleted
```

### 5.5 TabStash iOS

```swift
struct StashedTab {
    var id: UUID
    var title: String
    var url: URL
    var collectionID: UUID
    var lastModifiedAt: Date
    var isRead: Bool
    var isFavorite: Bool
}

struct StashCollection {
    var id: UUID
    var name: String
    var lastModifiedAt: Date
}
```

状态：

```text
同步可见 → 未读 → 已读
未读/已读 → 收藏
```

## 6. 关键交互与错误处理

### 通用交互

- 所有破坏性操作使用确认弹层。
- 列表空态使用 `EmptyStateView`，明确说明下一步动作。
- 影响用户感知的关键成功操作触发轻触感反馈。
- 设置页统一使用 `SettingRow`。

### 权限

| App | 权限 | 拒绝后的行为 |
|---|---|---|
| SoloGuard | Notifications | 保留本地手动签到，展示重新开启入口 |
| FocusBox | Notifications | 专注会话仍可运行，仅缺少结束提醒 |
| AmbientLog | Microphone | 阻断录音，展示设置跳转与隐私说明 |
| TabStash | Documents / File Import | 文件无效时提示原因；不注入插件 |

### 错误边界

- 网络不可用不影响 v1 核心功能；TabStash 使用本地 JSON 导入/导出。
- SwiftData 保存失败先重试一次，再显示可关闭的本地错误提示。
- 音频录制失败立即停止计时，保留已生成文件（若存在）并提示失败原因。
- URL 无法打开时保留卡片未读状态。
- 测试与时钟相关逻辑一律通过注入的 `DateProvider` 实现，避免真实休眠。

## 7. 发布与配置

### 版本与 Tag

- 版本源为 `Apps/<App>/Project.swift` 中的 `appVersion`。
- Tag 格式：`<AppName>@<semver>`，例如 `SoloGuard@1.0.0`。
- 发布前必须确认 tag 版本与 manifest 版本一致；CI 会执行该检查。

### Bundle 与签名

- Bundle ID 前缀：`com.pocketapps`。
- 每个 App 独立 provisioning profile 与 App Store Connect 记录。
- fastlane lane 命名：`<lowercase_app_name>_beta` 和 `<lowercase_app_name>_release`。

### 隐私声明

| 数据 | 使用方式 | 是否上传 |
|---|---|---|
| 签到记录 | 本机 SwiftData | 否 |
| 专注记录 | 本机 SwiftData | 否 |
| 明信片内容 | 本机 SwiftData | 否 |
| 录音文件 | App 沙盒 | 否 |
| TabStash 标签页 | 本机 SwiftData；用户导入 JSON | 否；导出走系统分享面板 |

## 8. 边界决策

1. **共享包不包含业务逻辑**：`PocketCore` 不知道“签到”“明信片”“专注”等概念。
2. **每个 App 独立生成工程**：App 之间不能互相依赖。
3. **SwiftData 是基线**：`PocketCore.Storage` 只封装容器创建和轻量 KV，避免过早抽象 ORM。
4. **通知权限不阻塞核心流程**：SoloGuard 与 FocusBox 在权限拒绝时仍保留本地功能。
5. **TabStash v1 是消费者**：iOS 侧先读取同步数据，不实现插件编辑协议。

## 9. 验收清单

### Monorepo 基础

- [x] 根目录包含 `README.md`、`docs/DESIGN.md`、`docs/ROADMAP.md`、`docs/adr`。
- [x] `Workspace.swift` 注册五个 App 与三个本地 Package。
- [x] `Apps/_Template` 可作为新增 App 模板。
- [x] `tuist generate` 可生成工程。
- [x] 所有 App target 可构建，五个 App 的单元测试通过。
- [x] 每个 App 有隐私清单、独立图标、删除确认与空态。
- [x] PocketCore / PocketUI / PocketTestKit 单元测试通过。

### 功能

- [x] SoloGuard 可创建计划、显示今日状态并完成签到。
- [x] FocusBox 可开始、完成或放弃专注会话并统计今日时长。
- [x] SlowCard 可创建延迟解锁卡片并按日期解锁。
- [x] AmbientLog 可请求权限、录制、播放与删除。
- [x] TabStash iOS 可导入 JSON、打开 URL、切换已读与收藏。

### 发布准备

- [x] `.github/workflows/ci.yml` 支持 lint、生成、受影响构建。
- [x] `.github/workflows/release.yml` 支持 App tag 隔离发布。
- [x] fastlane 提供 five App 的 beta / release lane 骨架。
- [ ] App Store Connect 真实账号、证书与 Team ID 接入后执行端到端 TestFlight 发布。

## 10. 风险与后续优化

| 风险 | 缓解 |
|---|---|
| Tuist 版本升级改变 manifest API | 锁定 `.tuist-version`，CI 使用相同版本 |
| TabStash schema 演进导致插件与 iOS 不兼容 | 引入 schema version 字段；不支持的版本整体拒绝 |
| SwiftData 迁移破坏用户数据 | 每个模型修改前新增 migration note 与备份策略 |
| 独居安全场景误发给紧急联系人 | v1 明确不做真实外发，后续功能必须通过单独隐私评审 |
| 录音耗电与后台中断 | 后续接入 AVAudioSession interruption 处理和后台任务边界 |

## 11. v1.1 增强：可靠性、提醒与数据互通

> 状态：已采纳
> 日期：2026-11-14

### 11.1 目标

- 在不引入云端后端的前提下，让五个 App 的核心数据更可靠。
- 将提醒统一抽象到 `PocketCore.NotificationScheduling`，避免 App 各自散落通知实现。
- 补齐录音中断、专注会话恢复、慢递到达提醒、TabStash 同步 schema 四类高价值边界。
- 保持每个 App 独立发布；新增能力不要求五个 App 同步升级。

### 11.2 非目标

- 不引入 FocusBox 的 Screen Time / Family Controls 隔离。
- 不实现 SoloGuard 紧急联系人外发。
- 不把 AmbientLog 录音上传云端。
- 不在 TabStash 中写入浏览器插件私有协议；iOS 只定义标准化导入/导出数据。

### 11.3 模块增强

#### PocketCore

新增 `NotificationScheduling` 抽象：

```swift
protocol NotificationScheduling {
    func requestAuthorization() async -> Bool
    func scheduleDailyReminder(id: String, hour: Int, minute: Int, title: String, body: String) async throws
    func scheduleAt(id: String, date: Date, title: String, body: String) async throws
    func cancel(ids: [String]) async
}
```

系统实现使用 `UNUserNotificationCenter`；测试与 UI preview 可使用内存实现。通知 ID 约定为：

| App | 通知 ID |
|---|---|
| SoloGuard | `sologuard.plan.<uuid>` |
| SlowCard | `slowcard.card.<uuid>` |
| 其他 App | v1.1 不主动发送通知 |

#### PocketUI

新增可复用组件：

- `TrendBarChart`：展示最近 N 天的整数趋势，FocusBox 使用。
- `SearchField`：统一搜索输入，AmbientLog 与 TabStash 使用。
- `ArchiveRow`：统一归档卡片与已收到的慢递卡片。

### 11.4 App 级设计

#### SoloGuard

##### 用户流程

1. 用户创建或更新计划时，App 请求通知授权。
2. 授权成功后按计划 hour/minute 调度每日本地通知。
3. 用户关闭计划时取消对应通知。
4. 每日签到完成后，当天通知标记已读即可，无需重新调度。
5. 进入 App 时检查昨天是否缺失签到；缺失记录展示为“已错过”，连续计数从今天重新开始。

##### 数据状态

```text
计划启用 → 通知已调度 → 今日待确认 → 已确认
计划禁用 → 通知已取消
昨天缺失 → yesterday missed badge → 连续计数重置
```

##### 错误处理

- 通知授权拒绝时仍允许本地手动签到，并在计划卡片提示“提醒未开启”。
- 调度失败记录 OSLog，不阻塞保存计划。
- 不做错过后的自动外发。

#### FocusBox

##### 会话恢复

1. App 启动时查询 `running` 会话。
2. 使用 `startedAt + plannedMinutes` 计算剩余时间。
3. 剩余时间大于 0 时恢复倒计时。
4. 剩余时间小于等于 0 时自动标记 `completed`，不弹窗等待用户确认。

##### 统计

新增最近 7 天趋势条形图，只统计 `completed` 会话：

```swift
struct DailyFocusSummary { var day: Date; var minutes: Int }
```

#### SlowCard

##### 到达提醒

1. 保存卡片时调度 `unlockAt` 本地通知。
2. 删除卡片时取消通知。
3. 授权失败不阻塞卡片创建。

##### 归档

新增 `归档` 过滤：

```text
已收到 + isFavorite == false → 归档
```

这不是新生命周期状态，只是视图分组，避免与 `traveling / received` 生命周期混淆。

#### AmbientLog

##### 录音中断

1. 监听 `AVAudioSession.interruptionNotification`。
2. `.began` 时立即停止录音，保留文件与已录时长。
3. `.ended` 不自动恢复录音；用户手动确认后继续。
4. 中断原因展示给用户，如电话、系统资源冲突、未知中断。

##### 列表管理

新增搜索与重命名：

- 搜索匹配 `title`。
- 重命名使用确认保存，不自动提交。
- 删除仍然同时删除 SwiftData 记录与沙盒文件。

#### TabStash iOS

##### 同步 Schema v1

定义 JSON 文档 `PocketTabStash.v1`：

```json
{
  "schemaVersion": 1,
  "generatedAt": "2026-11-14T00:00:00Z",
  "collections": [
    { "id": "UUID", "name": "String", "lastModifiedAt": "Date" }
  ],
  "tabs": [
    {
      "id": "UUID",
      "title": "String",
      "url": "String",
      "collectionID": "UUID",
      "lastModifiedAt": "Date",
      "isRead": false,
      "isFavorite": false
    }
  ]
}
```

导入合并规则：

1. 以 `id` 匹配集合与标签。
2. 不存在的记录插入。
3. 已存在的记录按 `lastModifiedAt` 最新者胜。
4. `collectionID` 不存在时放入“导入集合”。
5. 无效 URL 的标签跳过。
6. `schemaVersion != 1` 时拒绝导入并提示版本不支持。

iOS v1.1 通过本地 JSON 文件导入/导出验证 schema；iCloud 容器留到下一次交付。

### 11.5 验收清单

#### 基础

- [x] `NotificationScheduling` 可注入、可测试。
- [x] `TrendBarChart`、`SearchField`、`ArchiveRow` 可复用。
- [x] 所有 App 构建通过。
- [x] 新增单元测试通过。

#### SoloGuard

- [x] 创建计划时可调度每日提醒。
- [x] 关闭计划可取消提醒。
- [x] 昨天缺失签到时显示“已错过”。

#### FocusBox

- [x] App 重启后可恢复未完成倒计时。
- [x] 最近 7 天统计展示。

#### SlowCard

- [x] 保存卡片可调度到达提醒。
- [x] 删除卡片可取消提醒。
- [x] 已收到且未收藏的卡片可归档查看。

#### AmbientLog

- [x] 录音中断自动停止。
- [x] 中断原因可见。
- [x] 录音列表支持搜索与重命名。

#### TabStash

- [x] 定义并实现 schema v1。
- [x] 导入支持插入与最新修改时间合并。
- [x] 无效 URL、孤儿 collectionID 与版本错误可安全处理。

## 12. 发布准备清单

> 状态：v1.1 已在本仓库准备就绪；实际 TestFlight 仍依赖 Apple 开发者账号与签名资源。

### 工程发布项

- [x] 五个 App 版本均为 `1.1.0`。
- [x] Bundle ID 与 fastlane lane 一一对应。
- [x] App Icon 提供独立 1024×1024 PNG。
- [x] 每个 App 包含 `PrivacyInfo.xcprivacy`。
- [x] `ITSAppUsesNonExemptEncryption=false`。
- [x] AmbientLog 包含麦克风用途描述。
- [x] 破坏性操作均有确认弹层。
- [x] 核心空态、错误态与权限拒绝态可用。
- [x] 单元测试覆盖状态机、过滤器、通知调度 fake 和 TabStash schema 合并。
- [x] fastlane metadata 包含五个 App 的名称、副标题、描述、关键词、推广文案和版本说明。

### App Store 依赖项

- [ ] Apple Developer Program Team ID。
- [ ] 五个 App Store Connect App 记录。
- [ ] match 证书仓库和五个 provisioning profile。
- [ ] App Store Connect API Key。
- [ ] App Store 隐私问卷（见隐私声明表）。
- [ ] 截图；将 metadata 中的支持/隐私 URL 替换为最终域名。

### 签名与发布

本机真机部署使用自动签名。开发者可通过 `Tuist/Signing.xcconfig` 注入 `DEVELOPMENT_TEAM`，该文件不入库；也可以在 Xcode `Signing & Capabilities` 中选择 Team。iPhone 14 需要升级到 iOS 17+ 并开启 Developer Mode。

```bash
./scripts/generate.sh
./scripts/lint.sh
./scripts/test.sh
IOS_SIMULATOR_NAME="iPhone 16" ./scripts/test_apps.sh
./scripts/build_apps.sh
git tag SoloGuard@1.1.0
git push origin SoloGuard@1.1.0
```

CI 会校验 tag 与 `Apps/<App>/Project.swift` 的版本一致。

## 13. v1.2 方向：贴近真实使用

> 状态：本轮已实现
> 日期：2026-11-14

### 13.1 目标

- 让五个 App 从“功能演示”进一步贴近真实使用：首次使用、日常流程、回看、设置和隐私边界都清晰。
- 不引入云后端，不扩大权限范围。
- 保持每个 App 独立可发布。

### 13.2 通用模式

#### 首启说明

每个 App 都有一次性首启页，说明真实边界：

- SoloGuard：不做紧急联系人外发。
- FocusBox：不读取屏幕使用记录，不强制锁机。
- SlowCard：卡片不上传，只在解锁时间后可见。
- AmbientLog：不上传音频，不后台录音。
- TabStash：只通过显式导入导出交换数据。

使用 `@AppStorage` 记录 `hasCompletedOnboarding`。

#### 设置页

每个 App 都有设置页，解释数据边界与使用建议：数据只保存在本机、权限拒绝时的降级路径、关键能力不做什么。

#### UI 复用

`PocketUI` 新增 `OnboardingPage`、`SettingSection`，并让 `SettingRow` 支持图标颜色。

### 13.3 App 级增强

#### SoloGuard

- 三栏结构：今日、历史、设置。
- 签到历史。
- 完成签到触感反馈。

真实场景：用户早晚分别确认“今天正常”，历史页帮助回看节奏。

#### FocusBox

- 专注意图字段。
- 自定义 5–180 分钟时长。
- 默认时长设置。
- 统计页独立展示 7 天趋势和最近会话。

真实场景：写下“整理项目大纲”，开始专注；短暂离开 App 后回来，倒计时继续。

#### SlowCard

- 写作提示。
- 明确的锁卡与解锁状态。
- 收藏触感反馈。

真实场景：写下一件当前正在面对的小事，7 天或 90 天后回看。

#### AmbientLog

- 录音分类：自然、城市、居家、夜晚。
- 分类 + 搜索过滤。
- 首选分类持久化。
- 设置页说明不后台录音。

真实场景：先选“城市”，再录下地铁口的声景，之后按分类找回。

#### TabStash iOS

- 收件箱、同步、设置三栏结构。
- 搜索标题/URL。
- 手动添加标签页。
- 数据汇总与显式导入导出页。

真实场景：桌面插件导出 JSON，iOS 导入后按未读/已读/收藏处理。

### 13.4 验收清单

- [x] 五个 App 有首启说明。
- [x] 五个 App 有设置页。
- [x] 所有 App 可构建、测试通过。
- [x] SF Symbol 存在性有自动化测试。
- [x] `PrimaryButton` 不再创建空图标。

## 14. v1.2 第二轮：从可用到好用

> 状态：本轮设计已采纳
> 日期：2026-11-14

### 14.1 目标

第二轮聚焦每个 App 目前最明显的“单页工具感”，让核心场景拥有更完整的日常闭环：

- SoloGuard：计划不只是创建后只能删除，还要能编辑；历史不只是流水，还要能回看趋势。
- FocusBox：专注会话要能暂停/恢复，且 App 重启后状态仍可信。
- SlowCard：解锁时间要支持任意未来日期；解锁内容要能复制或分享。
- AmbientLog：录音要能导出/分享，音频元数据要可见。
- TabStash：集合要可创建；未读要能批量打开或标记已读。

### 14.2 非目标

- 不引入云后端或账号体系。
- 不接入 Screen Time / Family Controls。
- 不把 App 之间打通。
- 不做复杂导出格式，只保留当前 schema 或系统能力可处理的内容。

### 14.3 功能设计

#### SoloGuard

- 增加计划编辑入口，支持修改标题、提醒时间。
- 编辑保存后，若计划启用，重新调度对应本地通知；若禁用则取消通知。
- 历史页增加最近 14 天趋势图，统计每日完成计划数。

#### FocusBox

- 会话状态扩展为 `running / paused / completed / abandoned`。
- 暂停时记录 `pausedAt`；恢复时把暂停时长累计到 `pausedSeconds`。
- 恢复剩余时间 = 计划时长 - (当前时间 - 开始时间 - 累计暂停时长)。
- App 被回收后，如果状态是 paused，则以暂停时点冻结剩余时间。

#### SlowCard

- 新建卡片支持预设延迟和任意未来日期。
- 已解锁卡片支持复制内容，并提供系统分享入口。
- 拒绝解锁前编辑内容，保持“慢递”的时间承诺。

#### AmbientLog

- 录音卡片显示文件大小和最近修改时间。
- 支持通过系统分享面板导出音频文件。
- 文件缺失时明确提示，而不是表现为可播放但无响应。

#### TabStash

- 支持创建新集合。
- 当前过滤结果中的未读项支持“全部打开”和“全部标记已读”。
- 操作前明确作用范围，避免影响所有集合。

### 14.4 验收清单

- [x] SoloGuard 可编辑计划并重新调度通知。
- [x] SoloGuard 历史页有 14 天完成趋势。
- [x] FocusBox 可暂停、恢复，重启后 paused 状态不误判为超时完成。
- [x] SlowCard 支持任意未来解锁日期。
- [x] SlowCard 解锁内容可复制/分享。
- [x] AmbientLog 显示音频文件元数据并可分享。
- [x] TabStash 可创建集合并批量处理未读。
- [x] 新增状态机与过滤逻辑有单元测试。

## 15. v1.3 产品修正：真实能力与真实场景

> 状态：本轮设计已采纳
> 日期：2026-11-14

### 15.1 结论

三个产品定位需要修正：

1. **FocusBox**：不能把“App 内锁定”说成系统级强制锁机。v1.3 提供“关闭 / App 内遮罩”两档；真正的系统级屏蔽后续走 Screen Time / Family Controls 能力，需要单独 entitlement。
2. **AmbientLog**：环境音记录必须支持后台持续录音，并把声音量化成 dBFS、波形和统计，否则只是“录完能播”的玩具。
3. **SoloGuard**：仅“打卡”不足以承载个人安全守卫。v1.3 补充守护联系人、紧急状态卡片、快速呼叫和显式分享；自动外发仍是禁区。

### 15.2 FocusBox 设计

#### 专注模式

| 模式 | 行为 | 限制 |
|---|---|---|
| 关闭 | 普通倒计时，用户可自由离开 | 无 |
| App 内遮罩 | 在 App 内覆盖导航，防止误点；用户仍可切屏 / 锁屏 | 只控制 App 内行为 |
| Screen Time 盾牌 | 专注期间由系统屏蔽所选 App / 域名 | 需要 Family Controls entitlement 与用户授权 |

#### 系统能力边界

iOS 第三方 App **不能**阻止用户按 Home 键、上滑、锁屏或切换到其他 App。真正的“锁机”只能通过：

1. **Family Controls + Managed Settings**：用户选择要屏蔽的 App / 域名，专注期间由系统加盾牌。
2. **Guided Access**：用户手动开启的无障碍模式；App 不能静默开启。
3. **Single App Mode**：企业 / MDM 场景；不适合普通消费者 App。

因此，原“App 内锁定”应改名为“App 内遮罩”，不能宣传成锁机。

#### 倒计时修正

所有剩余时间必须用墙钟时间计算：

```text
remaining = plannedSeconds - (now - startedAt - pausedSeconds)
```

App 进入后台后 Timer 可能暂停；回到前台时按上述公式重算。锁屏、切屏、系统回收后的恢复不应倒退或卡住。

### 15.3 AmbientLog 设计

#### 后台录音

- Info.plist 增加 `UIBackgroundModes: audio`。
- 录音会话使用 `AVAudioSession.playAndRecord` 并保持 active。
- 用户开始录音后，锁屏或切到后台可继续录音。
- 系统中断仍然停止录音并保留文件。

#### 声音量化

`AVAudioRecorder` 启用 metering：

- 采样 `averagePower(forChannel:)`，单位 dBFS，范围约 -160...0。
- 实时显示当前 dBFS、峰值 dBFS、平均 dBFS。
- 将采样结果归一化并保存到录音记录，用于历史波形展示。
- 录音中的波形、录音后的波形都必须可见。
- 在录音页提供“dBFS 是什么”的说明，明确它不是环境噪声 dB SPL。
- 普通用户看到的读数应同时给出可读描述，例如“接近静音 / 安静 / 一般说话 / 较大声音”。

### 15.4 SoloGuard 设计

#### 产品边界

SoloGuard 是“本机守护工具”，不是无人值守 SOS。它能准备紧急信息、检测异常状态、降低求助摩擦，但真实外发必须由用户显式确认。

#### 守护能力

1. **守护联系人**：本机保存姓名、电话、关系、备注；不读取系统通讯录。
2. **安全状态卡**：展示最近签到、连续状态、计划标题、生成时间。
3. **快速行动**：
   - 拨打守护联系人。
   - 打开发送短信入口并预填安全状态。
   - 呼叫公共紧急号码。
4. **显式分享**：分享动作总是进入系统确认流程；App 不自动给联系人发送消息。
5. **异常提示**：错过计划时显示“需要查看”，但不自动定性为危险。

#### 禁止事项

- 不后台读取位置。
- 不自动发送短信。
- 不把“未打卡”直接解释为事故。
- 不把联系人数据上传云端。

## 16. v1.3 成熟产品对标优化

> 状态：本轮设计已采纳
> 日期：2026-11-14

### 16.1 对标原则

不复制大而全功能，而是抽取成熟 App 在同类场景中的核心体验：

| App | 对标产品 | 关键借鉴 | 本轮落地 |
|---|---|---|---|
| SoloGuard | Apple Reminders / Streaks | 清晰的今日任务、连续记录、联系人快速操作 | 计划编辑、14 天趋势、守护联系人主联系人管理 |
| FocusBox | Forest / Session / Apple Timer | 明确目标、圆形进度、会话状态可恢复 | 专注进度环、连续专注天数、暂停恢复 |
| SlowCard | FutureMe / Postcrossing | 到达倒计时、归档、收藏 | 卡片倒计时、已收到与在路上状态强化 |
| AmbientLog | Apple Voice Memos / Sound Meter | 录音计时、波形、音量说明、文件管理 | 录音秒数、波形、dBFS 解释卡、文件导出 |
| TabStash | Pocket / Instapaper | 阅读列表、过滤、批量处理、集合 | 创建集合、批量标记已读、搜索过滤 |

### 16.2 交互准则

1. 首屏只回答“现在该做什么”。
2. 关键状态用卡片、进度环、倒计时和趋势图表达。
3. 批量操作必须显示作用范围并支持确认。
4. 所有列表必须有空态、过滤态和错误态。
5. 成功操作提供触感反馈。
6. 破坏性操作必须确认。

### 16.3 验收

- [x] SoloGuard 守护联系人可编辑、设为主要、删除确认。
- [x] FocusBox 有连续专注天数和圆形专注进度。
- [x] SlowCard 有到达倒计时。
- [x] AmbientLog 有录音秒数实时展示。
- [x] TabStash 可创建集合并批量处理未读。
