# TabStash

<p align="left">
  <img alt="iOS" src="https://img.shields.io/badge/iOS-17%2B-0A84FF">
  <img alt="SwiftUI" src="https://img.shields.io/badge/UI-SwiftUI-32ADE6">
  <img alt="SwiftData" src="https://img.shields.io/badge/Data-SwiftData-0A84FF">
  <img alt="Status" src="https://img.shields.io/badge/release_ready_in_repo-34C759">
  <img alt="Version" src="https://img.shields.io/badge/version-1.2.0-8E8E93">
</p>

> 把桌面浏览器保存的标签页带到 iPhone 继续处理。

TabStash iOS 使用 `PocketTabStash.v1` JSON 在浏览器插件与 iOS 之间显式交换数据。它不上传数据、不读取浏览器内容，只负责导入、整理和继续阅读。

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

- 收件箱、同步、设置三栏结构。
- 按集合、未读、已读、收藏过滤。
- 标题和 URL 搜索。
- 手动添加标签页。
- 打开链接、标记已读 / 未读、收藏、删除。
- PocketTabStash.v1 JSON 导入 / 导出。
- 按 ID 匹配，最新修改时间优先合并。

## 真实使用场景

用户在桌面浏览器整理 20 个标签页并导出 JSON，在 iPhone 导入。通勤时按“未读”过滤，打开几篇文章后标记已读，重要内容收藏。

## 快速开始

仓库根目录生成 Workspace：

```bash
git clone <repository-url>
cd pocket-apps
./scripts/generate.sh
open PocketApps.xcworkspace
```

在 Xcode 选择 `TabStash` scheme，然后选择模拟器或真机运行。

## 使用说明

在“收件箱”页按集合 / 未读 / 已读 / 收藏过滤，或手动添加链接。在“同步”页导入浏览器插件导出的 JSON，处理后再导出本机状态。

## 数据模型

- `StashCollectionModel`：集合 ID、名称、最后修改时间。
- `StashedTabModel`：标签页 ID、标题、URL、集合 ID、最后修改时间、已读、收藏。
- `StashSyncDocument`：schemaVersion、generatedAt、collections、tabs。

## 架构与设计

- App target：`TabStash`
- Bundle ID：`com.pocketapps.tabstash`
- UI：SwiftUI
- 存储：SwiftData / App 沙盒
- 状态与业务逻辑留在 App 内，不放进共享 Package。

详细设计见 [docs/DESIGN.md](docs/DESIGN.md)。

## 隐私与安全

- 标签页和集合保存在本机 SwiftData。
- 只读取用户显式选择的 JSON 文件。
- 不读取浏览器历史，不自动上传数据。

App 内含 `PrivacyInfo.xcprivacy`，声明不追踪用户、不采集数据。

## 测试

```bash
cd ../..
./scripts/test.sh
IOS_SIMULATOR_NAME="iPhone 17" ./scripts/test_apps.sh
./scripts/build_apps.sh
```

覆盖点：

- `TabStashSyncTests`：schema 解析、无效 URL、最新时间合并。
- `TabStashTests`：URL 解析。

## 发布状态

v1.2 工程内可发布。发布前在根目录执行：

```bash
./scripts/release_preflight.sh
```

TestFlight / App Store 仍需要 Apple Developer Team、签名证书、App Store Connect 记录、截图和隐私问卷。

## Roadmap

- 浏览器插件导出功能对齐。
- iCloud 容器作为传输层。
- 双向同步与冲突合并测试扩展。

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
