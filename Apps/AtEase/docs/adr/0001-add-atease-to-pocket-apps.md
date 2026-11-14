# ADR 0001：将 At Ease 加入 Pocket Apps Monorepo

日期：2026-11-14  
状态：已采纳

## 背景

At Ease 是一个低门槛冥想 App，核心体验是呼吸、计时、情绪签到和进度观察。它与现有 App 一样具备独立 Bundle ID、独立发布节奏和本机数据边界，同时需要共享 SwiftUI 设计组件与工程基础。

## 决策

将 At Ease 加入 `Apps/AtEase`，使用现有 `PocketCore`、`PocketUI`、`PocketTestKit` 本地包，并通过 `appProject` 生成 target。

## 理由

1. 复用工程、测试、签名、发布流水线。
2. 保持冥想业务逻辑在独立 App target 内。
3. 不引入 App 间依赖。
4. 便于按 `AtEase@<version>` 独立发布。

## 边界

- 共享包不包含冥想业务逻辑。
- 不引入账号体系。
- v0.1 不接云端内容。
