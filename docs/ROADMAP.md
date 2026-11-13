# Pocket Apps Roadmap

## 当前状态

日期：2026-11-14

仓库已完成 Monorepo 基础、共享包、五个 App 的 v1 最小可运行实现、CI 骨架与发布流水线骨架。本机已用 Tuist 4.216.6 / Xcode 27.2 验证 Workspace 生成、五个 App 构建和单元测试。

## 已完成

### 基础设施

- [x] 创建仓库文档结构：`README`、`DESIGN`、`ROADMAP`、`ADR`。
- [x] 创建 Tuist Workspace 与 Project manifests。
- [x] 创建 `Apps/_Template`，支持复制后新增 App。
- [x] 创建本地 SPM Packages：
  - `PocketCore`
  - `PocketUI`
  - `PocketTestKit`
- [x] 添加 SwiftLint / SwiftFormat 配置。
- [x] 添加 `scripts/generate.sh`、`scripts/lint.sh`、`scripts/test.sh`。
- [x] 添加 CI 与 release workflow 骨架。

### App v1

- [x] SoloGuard：计划创建、今日签到、连续记录展示。
- [x] FocusBox：专注会话、完成/放弃、今日与 7 天统计。
- [x] SlowCard：慢递卡片、延迟解锁、收藏。
- [x] AmbientLog：麦克风权限、录音、播放、删除。
- [x] TabStash iOS：集合/标签列表、打开 URL、已读与收藏。

## 进行中

- [x] 使用本机 Tuist / Xcode 27.2 执行一次完整 `tuist generate`、build 与 unit test。
- [ ] 根据 CI 首次运行结果修正 macOS runner 和 Tuist 安装步骤。

## 未开始

### SoloGuard

- [ ] 本地通知调度与通知动作。
- [ ] 错过签到后的本地标记策略。
- [ ] 紧急联系人数据模型的隐私评审。

### FocusBox

- [ ] Family Controls / Screen Time 隔离。
- [ ] 专注统计趋势图。
- [ ] 会话中断恢复。

### SlowCard

- [ ] SwiftData migration 策略。
- [ ] 卡片到达日提醒。
- [ ] 多张卡片的归档视图。

### AmbientLog

- [ ] 音频录制中断处理。
- [ ] 波形可视化。
- [ ] 转写与搜索。

### TabStash iOS

- [ ] iCloud 容器接入。
- [ ] 浏览器插件数据 schema 定稿。
- [ ] 只读同步到可写同步的演进。

### 发布

- [ ] 接入 Apple Developer Team ID。
- [ ] match 证书仓库与 App Store Connect API Key。
- [ ] 五个 App 的截图与文案。
- [ ] TestFlight 端到端验证。

## 下一个交付节点

1. 打通 `tuist generate` 与全部 App 构建。
2. 为 SoloGuard 接入本地通知。
3. 为 AmbientLog 补齐录音中断处理。
4. 定稿 TabStash 浏览器插件与 iOS 的同步 schema。
