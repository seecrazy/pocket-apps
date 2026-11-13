# Pocket Apps 设计文档

> 状态：已采纳
> 更新时间：2026-11-14

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

`pocket-apps` 是“口袋应用集”，聚焦独立、即开即用的小工具与体验型产品。首批五个 App 保持独立的 Bundle ID、App Store Connect 记录、版本号与发布节奏。

| # | App | 副标题 | 方向 | Bundle ID | v1 边界 |
|---|---|---|---|---|---|
| 1 | SoloGuard | 独居守护 | 独居安全与生活确认 | `com.pocketapps.sologuard` | 本机计划、签到状态、提醒；不做真实 SOS 与紧急联系人外发 |
| 2 | FocusBox | 专注盒子 | 注意力恢复与屏幕戒断 | `com.pocketapps.focusbox` | 本机会话与专注统计；v1 不做社交打卡 |
| 3 | SlowCard | 慢递明信片 | 慢交互与情绪价值 | `com.pocketapps.slowcard` | 本地慢递卡片；v1 不做真实邮政寄送 |
| 4 | AmbientLog | 环境音记录仪 | iOS 独占能力工具 | `com.pocketapps.ambientlog` | 本机录音、环境记录；不做自动上传 |
| 5 | TabStash iOS | 标签收纳 | 浏览器插件伴侣 | `com.pocketapps.tabstash` | 读取 iCloud 同步的标签页集合并组织继续阅读；v1 不做浏览器执行注入 |

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

1. 用户在浏览器插件端把标签页集合保存到 iCloud 同步容器。
2. iOS App 读取同步集合，展示未读与已读分组。
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
| TabStash | iCloud / Documents | iCloud 未登录时展示本地占位集合与恢复指引 |

### 错误边界

- 网络不可用不影响 v1 核心功能；TabStash 同步由 iCloud 负责。
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
| TabStash 标签页 | iCloud 同步容器 | 用户显式通过插件保存 |

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
- [x] PocketCore / PocketUI / PocketTestKit 单元测试通过。

### 功能

- [x] SoloGuard 可创建计划、显示今日状态并完成签到。
- [x] FocusBox 可开始、完成或放弃专注会话并统计今日时长。
- [x] SlowCard 可创建延迟解锁卡片并按日期解锁。
- [x] AmbientLog 可请求权限、录制、播放与删除。
- [x] TabStash iOS 可展示本地样例集合、打开 URL、切换已读与收藏。

### 发布准备

- [x] `.github/workflows/ci.yml` 支持 lint、生成、受影响构建。
- [x] `.github/workflows/release.yml` 支持 App tag 隔离发布。
- [x] fastlane 提供 five App 的 beta / release lane 骨架。
- [ ] App Store Connect 真实账号、证书与 Team ID 接入后执行端到端 TestFlight 发布。

## 10. 风险与后续优化

| 风险 | 缓解 |
|---|---|
| Tuist 版本升级改变 manifest API | 锁定 `.tuist-version`，CI 使用相同版本 |
| iCloud 同步字段演进导致插件与 iOS 不兼容 | TabStash 后续引入 schema version 字段与只读降级 |
| SwiftData 迁移破坏用户数据 | 每个模型修改前新增 migration note 与备份策略 |
| 独居安全场景误发给紧急联系人 | v1 明确不做真实外发，后续功能必须通过单独隐私评审 |
| 录音耗电与后台中断 | 后续接入 AVAudioSession interruption 处理和后台任务边界 |
