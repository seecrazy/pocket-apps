# SlowCard

<p align="left">
  <img alt="iOS" src="https://img.shields.io/badge/iOS-17%2B-0A84FF">
  <img alt="SwiftUI" src="https://img.shields.io/badge/UI-SwiftUI-32ADE6">
  <img alt="SwiftData" src="https://img.shields.io/badge/Data-SwiftData-0A84FF">
  <img alt="Status" src="https://img.shields.io/badge/release_ready_in_repo-34C759">
  <img alt="Version" src="https://img.shields.io/badge/version-1.3.0-8E8E93">
</p>

> 给未来的自己写一封会准时到达的信。

SlowCard 不发送邮件、不分享内容、不上传卡片。它用延迟解锁把当下的想法封存起来，让用户在未来某天重新看见自己。

## v1.3 成熟产品对标更新

- 卡片列表显示“1 天后到达 / 2 小时后到达 / 已到达”等倒计时。
- 卡片状态和到达时间保持在一屏内可读。
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

- 写作提示，降低开始难度。
- 7 / 30 / 90 / 180 天延迟解锁。
- 在路上状态内容保持锁定。
- 到达日本地提醒。
- 收藏与归档过滤。
- 删除卡片时同步取消提醒。

## 真实使用场景

用户正在处理一件烦心事，写下 30 天后的期待。到达前内容不可见；到达日收到本地通知，打开后可以收藏或归档。

## 快速开始

仓库根目录生成 Workspace：

```bash
git clone <repository-url>
cd pocket-apps
./scripts/generate.sh
open PocketApps.xcworkspace
```

在 Xcode 选择 `SlowCard` scheme，然后选择模拟器或真机运行。

## 使用说明

在“明信片”页点新建，选择写作提示，写内容并选择解锁延迟。到达前内容锁定，到达后可查看、收藏或归档。

## 数据模型

- `SlowCardModel`：卡片 ID、标题、内容、创建时间、解锁时间、收藏状态。
- 派生状态：`traveling` / `received`。

## 架构与设计

- App target：`SlowCard`
- Bundle ID：`com.pocketapps.slowcard`
- UI：SwiftUI
- 存储：SwiftData / App 沙盒
- 状态与业务逻辑留在 App 内，不放进共享 Package。

详细设计见 [docs/DESIGN.md](docs/DESIGN.md)。

## 隐私与安全

- 卡片标题、内容和解锁时间保存在本机 SwiftData。
- 到达提醒为本地通知。
- 不发送邮件，不分享内容，不上传卡片。

App 内含 `PrivacyInfo.xcprivacy`，声明不追踪用户、不采集数据。

## 测试

```bash
cd ../..
./scripts/test.sh
IOS_SIMULATOR_NAME="iPhone 17" ./scripts/test_apps.sh
./scripts/build_apps.sh
```

覆盖点：

- `SlowCardLibraryTests`：全部、在路上、已收到、收藏和归档过滤。
- `SlowCardModelTests`：卡片生命周期状态。

## 发布状态

v1.2 工程内可发布。发布前在根目录执行：

```bash
./scripts/release_preflight.sh
```

TestFlight / App Store 仍需要 Apple Developer Team、签名证书、App Store Connect 记录、截图和隐私问卷。

## Roadmap

- 到达日通知动作直达卡片。
- 批量归档。
- 卡片的导出与备份策略。

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
