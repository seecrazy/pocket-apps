# SoloGuard 进度文档

> 更新时间：2026-11-14  
> 当前版本：1.1.0  
> 当前状态：v1.1 工程内可发布

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

- 一次性隐私说明，明确数据只保存在本机。
- 多个生活确认计划，可设置每日提醒时间。
- 今日状态、连续记录与昨日缺失提示。
- 签到历史，支持按计划回看节奏。
- 计划删除时同步取消提醒并清理记录。
- 完成签到提供轻触感反馈。

### 测试

- `SoloGuardLibraryTests`：今日完成状态与昨日缺失判断。
- `StreakCalculatorTests`：连续签到计数。

## 当前状态

v1.1 工程内可发布

## 已知边界

- **提醒权限被拒绝：保留手动签到，仍可查看历史。**
- **时区或日期边界：以本地日历的 `startOfDay` 计算连续记录。**
- **用户误删：破坏性操作必须有确认。**

## 下一步

- 支持每日 / 每周混合频率。
- 通知动作直接完成签到。
- 连续记录趋势图。

### 近期优先级

1. 支持每日 / 每周混合频率。
2. 通知动作直接完成签到。
3. 连续记录趋势图。

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
- 保持业务逻辑在 `SoloGuard` App target 内，不要移动到 `Packages/`。
- App Store 发布前的账号、签名、证书和截图仍在仓库外。
