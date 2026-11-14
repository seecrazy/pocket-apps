# AmbientLog

<p align="left">
  <img alt="iOS" src="https://img.shields.io/badge/iOS-17%2B-0A84FF">
  <img alt="SwiftUI" src="https://img.shields.io/badge/UI-SwiftUI-32ADE6">
  <img alt="SwiftData" src="https://img.shields.io/badge/Data-SwiftData-0A84FF">
  <img alt="Status" src="https://img.shields.io/badge/release_ready_in_repo-34C759">
  <img alt="Version" src="https://img.shields.io/badge/version-1.1.0-8E8E93">
</p>

> 把某个地点和时刻的声音留在手机里。

AmbientLog 是本机环境音记录工具，不后台录音、不社交、不上传音频。它用分类和搜索帮用户找回“那家咖啡店的下午”或“地铁口的傍晚”。

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

- 自然 / 城市 / 居家 / 夜晚分类。
- 录音前选择或记住分类偏好。
- 录音中断自动停止并保留文件。
- 中断原因可见。
- 搜索、播放、重命名、删除。
- 设置页说明数据边界。

## 真实使用场景

用户在咖啡馆选择“城市”分类，录下 90 秒环境声。电话进来时录音自动停止并保留文件；回到列表可播放或重命名，未来按分类找回。

## 快速开始

仓库根目录生成 Workspace：

```bash
git clone <repository-url>
cd pocket-apps
./scripts/generate.sh
open PocketApps.xcworkspace
```

在 Xcode 选择 `AmbientLog` scheme，然后选择模拟器或真机运行。

## 使用说明

在“记录”页选择分类，点击开始录音；停止后记录保存到本机。列表页可搜索、按分类过滤、播放、重命名或删除。

## 数据模型

- `AmbientRecordingModel`：记录 ID、标题、分类、开始时间、时长、文件路径。
- `AmbientRecordingCategory`：全部、自然、城市、居家、夜晚。

## 架构与设计

- App target：`AmbientLog`
- Bundle ID：`com.pocketapps.ambientlog`
- UI：SwiftUI
- 存储：SwiftData / App 沙盒
- 状态与业务逻辑留在 App 内，不放进共享 Package。

详细设计见 [docs/DESIGN.md](docs/DESIGN.md)。

## 隐私与安全

- 录音文件保存在 App 沙盒 Documents，元数据保存在本机 SwiftData。
- 仅在用户主动开始录音时访问麦克风。
- 不后台录音，不上传音频。

App 内含 `PrivacyInfo.xcprivacy`，声明不追踪用户、不采集数据。

## 测试

```bash
cd ../..
./scripts/test.sh
IOS_SIMULATOR_NAME="iPhone 17" ./scripts/test_apps.sh
./scripts/build_apps.sh
```

覆盖点：

- `AmbientRecordingLibraryTests`：搜索与分类过滤。
- `AudioRecorderServiceTests`：中断描述。

## 发布状态

v1.1 工程内可发布。发布前在根目录执行：

```bash
./scripts/release_preflight.sh
```

TestFlight / App Store 仍需要 Apple Developer Team、签名证书、App Store Connect 记录、截图和隐私问卷。

## Roadmap

- 波形可视化。
- 音频备注与标签。
- 后台录音边界与耗电策略。

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
