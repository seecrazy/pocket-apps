# SlowCard 进度文档

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

- 写作提示，降低开始难度。
- 7 / 30 / 90 / 180 天延迟解锁。
- 在路上状态内容保持锁定。
- 到达日本地提醒。
- 收藏与归档过滤。
- 删除卡片时同步取消提醒。

### 测试

- `SlowCardLibraryTests`：全部、在路上、已收到、收藏和归档过滤。
- `SlowCardModelTests`：卡片生命周期状态。

## 当前状态

v1.2 工程内可发布

## 已知边界

- **通知权限拒绝：卡片仍在解锁时间后可见。**
- **内容误删：删除前必须确认。**
- **数据迁移：未来新增字段需评估 SwiftData migration。**

## 下一步

- 到达日通知动作直达卡片。
- 批量归档。
- 卡片的导出与备份策略。

### 近期优先级

1. 到达日通知动作直达卡片。
2. 批量归档。
3. 卡片的导出与备份策略。

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
- 保持业务逻辑在 `SlowCard` App target 内，不要移动到 `Packages/`。
- App Store 发布前的账号、签名、证书和截图仍在仓库外。
