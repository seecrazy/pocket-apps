# Handoff

## 会话摘要

本会话完成了 `pocket-apps` Monorepo 的设计、v1 最小实现与 v1.1 发布准备：

- 采用 Tuist + Workspace + 本地 SPM Packages。
- 设计文档补充了目标、非目标、用户流程、数据状态、权限边界和发布规则。
- 创建五个 App 的最小 SwiftUI 实现。
- 创建共享包、模板、CI 与 fastlane 骨架。
- 统一本地通知抽象。
- SoloGuard、SlowCard 接入本地提醒。
- FocusBox 支持恢复与趋势统计。
- AmbientLog 支持中断保护、搜索、重命名。
- TabStash 定义并实现 JSON schema v1。
- 五个 App 升至 `1.1.0`，补齐隐私清单和发布级 UI 边界。
- README 重写为开源仓库结构，并补充 iPhone 14 真机部署说明。
- Tuist 支持通过本地 `Tuist/Signing.xcconfig` 注入 `DEVELOPMENT_TEAM`。
- 五个 App 增加首启说明、设置页和更贴近真实场景的流程。
- PocketUI 新增 OnboardingPage 与 SettingSection。
- 新增 SF Symbol 存在性测试，修复无效图标与空图标问题。
- 五个 App 均有独立 README、`docs/DESIGN.md` 与 `docs/PROGRESS.md`。

## 当前可验证状态

仓库已在本机用 Tuist 4.216.6 / Xcode 27.2 执行 `scripts/release_preflight.sh`，并全部通过：release metadata 检查、Workspace 生成、SwiftFormat/SwiftLint、共享包测试、五个 App 测试和五个 App 构建。

```bash
cd /Users/xiaoyyu/IdeaProjects/pocket-apps
./scripts/generate.sh
./scripts/lint.sh
./scripts/release_preflight.sh
```

## 下一件事

1. 执行生成与构建验证。
2. 根据编译结果修正 manifest 或代码。
3. 用 Apple 开发者账号接入签名与 TestFlight。
4. 将浏览器插件导出格式对齐 `PocketTabStash.v1`。

## 注意

- 不要提交 `*.xcodeproj`、`*.xcworkspace`、`Derived/`。
- 不要把 App 业务逻辑移动到 `Packages/`。
- Tag 版本必须与对应 `Project.swift` 的 `appVersion` 一致。
