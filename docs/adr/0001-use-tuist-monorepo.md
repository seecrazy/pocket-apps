# ADR 0001：使用 Tuist 管理 iOS 多 App Monorepo

日期：2026-11-14
状态：已采纳

## 背景

仓库计划承载多个独立发布、独立 Bundle ID 的 iOS App，并共享基础能力。如果为每个 App 手工维护 `.xcodeproj`，容易出现：

- 共享包路径和 target 配置合并冲突；
- 本地能打开但 CI 无法复现的工程状态；
- 新增 App 时复制不可读的 pbxproj；
- 无法按变更路径准确构建受影响 App。

## 决策

采用 Tuist：

- 根目录用 `Workspace.swift` 汇总全部 App 与 Package；
- 每个 App 用自己的 `Project.swift` 声明 target；
- 共享 App 配置放入 `Tuist/ProjectDescriptionHelpers`；
- `.xcodeproj`、`.xcworkspace` 与 `Derived/` 不提交；
- CI 统一执行 `tuist generate`。

## 理由

1. 工程配置代码化，PR 可审查。
2. 多 App 与本地 SPM 包关系显式。
3. 可在 CI 中复现工程。
4. 新增 App 的成本从维护 pbxproj 变为声明式配置。

## 影响

- 开发者必须先执行 `./scripts/generate.sh` 再打开 Xcode。
- Tuist 版本通过 `.tuist-version` 固定。
- 工程生成失败是 CI 的硬失败。

## 其他方案

| 方案 | 未采用原因 |
|---|---|
| 单 App 多 target | 发布与业务边界混在一起，不利于长期扩展 |
| 每个 App 独立仓库 | 共享包需要跨仓协调，发布和 CI 成本高 |
| 手写 `.xcodeproj` | pbxproj 合并冲突大，配置不可读 |
| XcodeGen | 能生成工程，但 Tuist 对 Workspace、Project helper 与 Monorepo 场景更聚合 |
