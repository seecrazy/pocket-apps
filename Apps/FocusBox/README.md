# FocusBox

<p align="left">
  <img alt="iOS" src="https://img.shields.io/badge/iOS-17%2B-0A84FF">
  <img alt="SwiftUI" src="https://img.shields.io/badge/UI-SwiftUI-32ADE6">
  <img alt="SwiftData" src="https://img.shields.io/badge/Data-SwiftData-0A84FF">
  <img alt="Status" src="https://img.shields.io/badge/release_ready_in_repo-34C759">
  <img alt="Version" src="https://img.shields.io/badge/version-1.2.0-8E8E93">
</p>

> 为一段真实专注记录意图、时长和趋势。

FocusBox 不强制锁机，也不读取屏幕使用记录。它用一个明确的专注意图、可靠的倒计时和本机统计，帮助用户把注意力从“焦虑地看时间”转回“现在做什么”。

## v1.2 更新

- 新增暂停 / 恢复，暂停时长会从专注计时中扣除。
- 倒计时改用真实时间计算，切屏、锁屏或 App 被回收后按实际时间恢复。
- 新增“关闭 / App 内锁定”两档配置。
- App 内锁定提供全屏专注页，不是系统级 Screen Time 锁机。

## 目录

- [亮点](#亮点)
- [真实使用场景](#真实使用场景)
- [快速开始](#快速开始)
- [使用说明](#使用说明)
- [数据模型](#数据模型)
- [架构与设计](#架构与设计)
- [隐私与安全](#隐私与安全)
- [测试](#测试)
- [发布状态](#发布状态)
- [Roadmap](#roadmap)
- [文档](#文档)
- [许可证](#许可证)

## 亮点

- 专注意图字段，写清楚这次专注做什么。
- 预设 15 / 25 / 45 / 60 分钟，也支持 5–180 分钟自定义。
- 专注、完成、放弃状态机。
- App 重启后恢复 running 会话，超时会话自动完成。
- 今日专注时长和最近 7 天趋势图。
- 最近会话列表与设置页。

## 真实使用场景

用户写下“整理项目大纲”，选择 45 分钟开始专注。中途切到系统邮件，计时继续；回到 App 后倒计时仍在推进。如果 App 被系统回收，重启后按开始时间恢复剩余时长。

## 快速开始

仓库根目录生成 Workspace：

```bash
git clone <repository-url>
cd pocket-apps
./scripts/generate.sh
open PocketApps.xcworkspace
```

在 Xcode 选择 `FocusBox` scheme，然后选择模拟器或真机运行。

## 使用说明

在“专注”页输入专注意图，选择时长或使用 Stepper 自定义，然后开始。会话完成后在“统计”页查看今日和 7 天趋势。

## 数据模型

- `FocusSessionModel`：会话 ID、开始时间、计划时长、专注意图、完成时间、状态。
- `FocusSessionStatus`：`running`、`completed`、`abandoned`。

## 架构与设计

- App target：`FocusBox`
- Bundle ID：`com.pocketapps.focusbox`
- UI：SwiftUI
- 存储：SwiftData / App 沙盒
- 状态与业务逻辑留在 App 内，不放进共享 Package。

详细设计见 [docs/DESIGN.md](docs/DESIGN.md)。

## 隐私与安全

- 专注会话和意图保存在本机 SwiftData。
- 不读取 Screen Time，不访问其他 App 使用情况。
- 不强制锁机。

App 内含 `PrivacyInfo.xcprivacy`，声明不追踪用户、不采集数据。

## 测试

```bash
cd ../..
./scripts/test.sh
IOS_SIMULATOR_NAME="iPhone 17" ./scripts/test_apps.sh
./scripts/build_apps.sh
```

覆盖点：

- `FocusSessionRecoveryTests`：恢复进行中会话和自动完成过期会话。
- `FocusStatsCalculatorTests`：今日统计与 7 天趋势只统计完成会话。

## 发布状态

v1.2 工程内可发布。发布前在根目录执行：

```bash
./scripts/release_preflight.sh
```

TestFlight / App Store 仍需要 Apple Developer Team、签名证书、App Store Connect 记录、截图和隐私问卷。

## Roadmap

- 会话标签与意图搜索。
- 专注结束通知。
- 每周专注报告。

## 文档

- 设计文档：[docs/DESIGN.md](docs/DESIGN.md)
- 进度文档：[docs/PROGRESS.md](docs/PROGRESS.md)
- 仓库总设计：[../../docs/DESIGN.md](../../docs/DESIGN.md)
- 隐私说明：[../../PRIVACY.md](../../PRIVACY.md)

## 贡献

1. 阅读本 App 的 `docs/DESIGN.md`。
2. 保持业务逻辑在 App target 内。
3. 修改前运行：
   ```bash
   ./scripts/lint.sh
   ./scripts/test.sh
   IOS_SIMULATOR_NAME="iPhone 17" ./scripts/test_apps.sh
   ```
4. 涉及产品方案变化时，先更新本 App 的设计文档。

## 许可证

仓库尚未附带开源许可证，默认保留所有权利。
