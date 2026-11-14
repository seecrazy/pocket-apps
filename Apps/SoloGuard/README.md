# SoloGuard

<p align="left">
  <img alt="iOS" src="https://img.shields.io/badge/iOS-17%2B-0A84FF">
  <img alt="SwiftUI" src="https://img.shields.io/badge/UI-SwiftUI-32ADE6">
  <img alt="SwiftData" src="https://img.shields.io/badge/Data-SwiftData-0A84FF">
  <img alt="Status" src="https://img.shields.io/badge/release_ready_in_repo-34C759">
  <img alt="Version" src="https://img.shields.io/badge/version-1.1.0-8E8E93">
</p>

> 为独居生活建立轻量的日常确认习惯。

SoloGuard 不做紧急联系人外发，也不上传生活状态。它把“今天正常吗”变成一个低压力、可回看的本地仪式，帮助独居用户观察自己的日常节奏。

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

- 一次性隐私说明，明确数据只保存在本机。
- 多个生活确认计划，可设置每日提醒时间。
- 今日状态、连续记录与昨日缺失提示。
- 签到历史，支持按计划回看节奏。
- 计划删除时同步取消提醒并清理记录。
- 完成签到提供轻触感反馈。

## 真实使用场景

用户早上或晚上打开 App，点一下“完成签到”。连续 5 天后，App 用连续计数给用户一个稳定的心理锚点；如果昨天没有签到，会给出明确的“昨日已错过”提示。

## 快速开始

仓库根目录生成 Workspace：

```bash
git clone <repository-url>
cd pocket-apps
./scripts/generate.sh
open PocketApps.xcworkspace
```

在 Xcode 选择 `SoloGuard` scheme，然后选择模拟器或真机运行。

## 使用说明

在“今日”页创建计划，选择提醒时间；每天提醒后点击“完成签到”。连续计数和历史记录在对应页查看。可以在计划卡片上关闭提醒，但仍可手动签到。

## 数据模型

- `CheckInPlanModel`：计划 ID、标题、提醒时间、启用状态、创建时间。
- `CheckInRecordModel`：签到记录 ID、计划 ID、日期、完成时间、备注。

## 架构与设计

- App target：`SoloGuard`
- Bundle ID：`com.pocketapps.sologuard`
- UI：SwiftUI
- 存储：SwiftData / App 沙盒
- 状态与业务逻辑留在 App 内，不放进共享 Package。

详细设计见 [docs/DESIGN.md](docs/DESIGN.md)。

## 隐私与安全

- 计划与签到记录保存在本机 SwiftData。
- 本地通知仅用于提醒用户确认。
- 不上传生活状态，不联系紧急联系人。

App 内含 `PrivacyInfo.xcprivacy`，声明不追踪用户、不采集数据。

## 测试

```bash
cd ../..
./scripts/test.sh
IOS_SIMULATOR_NAME="iPhone 17" ./scripts/test_apps.sh
./scripts/build_apps.sh
```

覆盖点：

- `SoloGuardLibraryTests`：今日完成状态与昨日缺失判断。
- `StreakCalculatorTests`：连续签到计数。

## 发布状态

v1.1 工程内可发布。发布前在根目录执行：

```bash
./scripts/release_preflight.sh
```

TestFlight / App Store 仍需要 Apple Developer Team、签名证书、App Store Connect 记录、截图和隐私问卷。

## Roadmap

- 支持每日 / 每周混合频率。
- 通知动作直接完成签到。
- 连续记录趋势图。

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
