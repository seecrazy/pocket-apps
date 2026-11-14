# TabStash 进度文档

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

- 收件箱、同步、设置三栏结构。
- 按集合、未读、已读、收藏过滤。
- 标题和 URL 搜索。
- 手动添加标签页。
- 打开链接、标记已读 / 未读、收藏、删除。
- PocketTabStash.v1 JSON 导入 / 导出。
- 按 ID 匹配，最新修改时间优先合并。

### 测试

- `TabStashSyncTests`：schema 解析、无效 URL、最新时间合并。
- `TabStashTests`：URL 解析。

## 当前状态

v1.1 工程内可发布

## 已知边界

- **schemaVersion 不支持：整体拒绝导入，不做部分合并。**
- **孤儿 collectionID：归入“导入集合”。**
- **无效 URL：跳过并统计。**
- **时间冲突：`lastModifiedAt` 最新者胜。**

## 下一步

- 浏览器插件导出功能对齐。
- iCloud 容器作为传输层。
- 双向同步与冲突合并测试扩展。

### 近期优先级

1. 浏览器插件导出功能对齐。
2. iCloud 容器作为传输层。
3. 双向同步与冲突合并测试扩展。

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
- 保持业务逻辑在 `TabStash` App target 内，不要移动到 `Packages/`。
- App Store 发布前的账号、签名、证书和截图仍在仓库外。
