# ADR 0004：本地通知统一由 PocketCore 抽象

日期：2026-11-14
状态：已采纳

## 背景

SoloGuard 的每日提醒与 SlowCard 的到达提醒都需要 `UNUserNotificationCenter`。如果两个 App 各自实现，容易出现授权策略、通知 ID、失败处理不一致。

## 决策

在 `PocketCore` 中定义 `NotificationScheduling`：

- App 只传入业务化的通知 ID、标题、正文和时间。
- 系统实现包装 `UNUserNotificationCenter`。
- 测试使用内存 fake。
- 权限拒绝不阻塞核心功能。

## 规则

1. 通知 ID 必须带 App 前缀，避免未来 App Group/共享通知中心时冲突。
2. 通知失败只记录日志，不作为业务保存失败。
3. App 负责在生命周期变化时取消自己的通知。

## 理由

本地通知属于通用能力，不属于某个 App 的业务。抽象后可以在 CI 中测试 App 的调度决策，而不依赖真实系统权限。
