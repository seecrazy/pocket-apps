# Handoff

## 会话摘要

本会话完成了 `pocket-apps` Monorepo 的设计与 v1 最小实现：

- 采用 Tuist + Workspace + 本地 SPM Packages。
- 设计文档补充了目标、非目标、用户流程、数据状态、权限边界和发布规则。
- 创建五个 App 的最小 SwiftUI 实现。
- 创建共享包、模板、CI 与 fastlane 骨架。

## 当前可验证状态

仓库已在本机用 Tuist 4.216.6 / Xcode 27.2 完成首次验证：`tuist generate`、五个 App build、共享包与 App 单元测试通过。CI 仍需要用 GitHub runner 验证一次。

```bash
cd /Users/xiaoyyu/IdeaProjects/pocket-apps
./scripts/generate.sh
./scripts/test.sh
IOS_SIMULATOR_NAME="iPhone 16" ./scripts/test_apps.sh
```

## 下一件事

1. 执行生成与构建验证。
2. 根据编译结果修正 manifest 或代码。
3. 接入 SoloGuard 本地通知。
4. 定稿 TabStash 浏览器插件与 iOS 的 iCloud schema。

## 注意

- 不要提交 `*.xcodeproj`、`*.xcworkspace`、`Derived/`。
- 不要把 App 业务逻辑移动到 `Packages/`。
- Tag 版本必须与对应 `Project.swift` 的 `appVersion` 一致。
