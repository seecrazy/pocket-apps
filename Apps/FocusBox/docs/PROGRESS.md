# FocusBox 进度文档

> 更新时间：2026-11-14
> 当前版本：1.3.0
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

- 专注意图字段，写清楚这次专注做什么。
- 预设 15 / 25 / 45 / 60 分钟，也支持 5–180 分钟自定义。
- 专注、完成、放弃状态机。
- App 重启后恢复 running 会话，超时会话自动完成。
- 今日专注时长和最近 7 天趋势图。
- 最近会话列表与设置页。

### 测试

- `FocusSessionRecoveryTests`：恢复进行中会话和自动完成过期会话。
- `FocusStatsCalculatorTests`：今日统计与 7 天趋势只统计完成会话。

### v1.2 已完成

- [x] 会话暂停 / 恢复状态机。
- [x] 墙钟剩余时间计算。
- [x] App 被回收后的 running / paused 恢复。
- [x] 可配置 App 内遮罩。
- [x] 澄清 iOS 能力边界：App 内遮罩不能阻止系统切屏。
- [ ] Family Controls / Managed Settings 系统级 Screen Time 盾牌。
- [x] 暂停与恢复的单元测试。

**边界**：系统级 Screen Time 锁机需要 Family Controls entitlement，当前未接入。

### v1.3 成熟产品对标

- [x] 专注进度环。
- [x] 连续专注天数。
- [x] 会话暂停 / 恢复状态机。

## 当前状态

v1.2 工程内可发布

## 已知边界

- **系统后台限制：用开始时间和计划时长恢复，而不是只依赖 Timer。**
- **用户误触放弃：放弃状态需可区分，不影响完成统计。**
- **跨天统计：统一使用本地 Calendar 判断同一天。**

## 下一步

- 会话标签与意图搜索。
- 专注结束通知。
- 每周专注报告。

### 近期优先级

1. 会话标签与意图搜索。
2. 专注结束通知。
3. 每周专注报告。

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
- 保持业务逻辑在 `FocusBox` App target 内，不要移动到 `Packages/`。
- App Store 发布前的账号、签名、证书和截图仍在仓库外。
