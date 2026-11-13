# ADR 0002：共享能力使用本地 SPM Package

日期：2026-11-14
状态：已采纳

## 背景

五个 App 需要复用触感、日志、权限、轻量存储和 SwiftUI 组件，但业务语义必须留在 App 内。

## 决策

使用 `Packages/` 下的本地 SPM Package：

- `PocketCore`：无 UI 基础能力。
- `PocketUI`：SwiftUI 组件。
- `PocketTestKit`：仅测试 target 使用。

App 通过 `.package(path:)` 引用本地包。

## 边界

1. `PocketCore` 不 import SwiftUI。
2. `PocketUI` 不实现任何 App 业务模型。
3. App 之间不互相依赖。
4. 新增共享能力前必须回答“至少两个 App 会使用”。

## 理由

- SPM 与 Xcode/Tuist 生态一致。
- 本地包可单独测试。
- 避免引入 CocoaPods 与额外依赖锁机制。
- Package API 变化通过编译失败暴露，而不是运行时隐性耦合。
