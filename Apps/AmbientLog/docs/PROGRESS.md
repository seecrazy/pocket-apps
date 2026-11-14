# AmbientLog 进度文档

> 更新时间：2026-11-14
> 当前版本：1.2.0
> 当前状态：v1.2 工程内可发布

## 已完成

### 产品基础

- [x] SwiftUI App 入口与独立 target。
- [x] iOS 17 / SwiftData 基础栈。
- [x] 一次性首启说明。
- [x] 设置页。
- [x] 空态、错误态和权限拒绝态。
- [x] 破坏性操作确认。
- [x] 关键操作触感反馈。
- [x] `PrivacyInfo.xcprivacy`。
- [x] App Icon。
- [x] App Store metadata。

### 功能

- 自然 / 城市 / 居家 / 夜晚分类。
- 录音前选择或记住分类偏好。
- 录音中断自动停止并保留文件。
- 中断原因可见。
- 搜索、播放、重命名、删除。
- 设置页说明数据边界。

### 测试

- `AmbientRecordingLibraryTests`：搜索与分类过滤。
- `AudioRecorderServiceTests`：中断描述。

### v1.2 已完成

- [x] `UIBackgroundModes: audio`。
- [x] AVAudioRecorder metering 与 dBFS 采样。
- [x] 波形可视化。
- [x] 音量峰值 / 均值统计。
- [x] 录音文件分享导出与文件元数据展示。
- [x] 音量归一化与降采样单元测试。

**边界**：系统仍可能因电话、蓝牙断开或资源冲突中断录音；中断会保留已生成文件。

## 当前状态

v1.2 工程内可发布

## 已知边界

- **麦克风权限拒绝：展示设置跳转，不伪装录音。**
- **音频文件丢失或损坏：播放失败给出明确错误。**
- **误删：删除文件和记录前必须确认。**

## 下一步

- 波形可视化。
- 音频备注与标签。
- 后台录音边界与耗电策略。

### 近期优先级

1. 波形可视化。
2. 音频备注与标签。
3. 后台录音边界与耗电策略。

## 验证命令

```bash
# 仓库根目录
./scripts/generate.sh
./scripts/lint.sh
./scripts/test.sh
IOS_SIMULATOR_NAME="iPhone 17" ./scripts/test_apps.sh
./scripts/build_apps.sh
./scripts/release_preflight.sh
```

## 交接说明

- 新会话先读本 README 和 `docs/DESIGN.md`。
- 修改产品方案前，先更新设计文档。
- 保持业务逻辑在 `AmbientLog` App target 内，不要移动到 `Packages/`。
- App Store 发布前的账号、签名、证书和截图仍在仓库外。
