# TabStash 设计文档

> 状态：已采纳
> 版本：1.3.0
> 更新时间：2026-11-14

## 1. 产品定位

TabStash iOS 使用 `PocketTabStash.v1` JSON 在浏览器插件与 iOS 之间显式交换数据。它不上传数据、不读取浏览器内容，只负责导入、整理和继续阅读。

**副标题**：标签收纳
**Bundle ID**：`com.pocketapps.tabstash`

### 目标

- 用一个清晰的核心动作解决真实场景。
- 数据只保存在本机，隐私边界在首启说明中说清楚。
- UI 能表达空态、进行中、完成、失败和恢复状态。
- 单元测试覆盖核心状态机和过滤器。
- 不把业务逻辑泄漏到共享 Package。

### 非目标

- 不做云后端。
- 不做账号体系和跨设备自动同步。
- 不引入和核心体验无关的复杂权限。
- 不做广告、推荐或数据采集。

## 2. 用户与真实场景

用户在桌面浏览器整理 20 个标签页并导出 JSON，在 iPhone 导入。通勤时按“未读”过滤，打开几篇文章后标记已读，重要内容收藏。

### 典型流程

1. 桌面插件导出 JSON → iOS 导入 → 按 ID 合并 → 未读列表处理。
2. 手动添加链接时自动归属集合，必要时创建默认集合。
3. 导出 JSON 后通过系统分享面板保存或回传。

## 3. 信息架构

三栏 Tab：**收件箱**、**同步**、**设置**。收件箱负责过滤与处理；同步页负责 JSON 导入导出和数据汇总。

## 4. 数据模型

- `StashCollectionModel`：集合 ID、名称、最后修改时间。
- `StashedTabModel`：标签页 ID、标题、URL、集合 ID、最后修改时间、已读、收藏。
- `StashSyncDocument`：schemaVersion、generatedAt、collections、tabs。

## 5. 关键交互与状态

- 阅读状态：`unread → read`，可反向切换。
- 收藏：独立布尔状态。
- 合并：按 `id` 匹配；已存在记录以 `lastModifiedAt` 最新者胜。
- 校验：URL 必须有 host；schemaVersion 不是 1 时拒绝导入。

## 6. 错误与边界处理

- **schemaVersion 不支持：整体拒绝导入，不做部分合并。**
- **孤儿 collectionID：归入“导入集合”。**
- **无效 URL：跳过并统计。**
- **时间冲突：`lastModifiedAt` 最新者胜。**

## 7. 隐私与数据边界

- 标签页和集合保存在本机 SwiftData。
- 只读取用户显式选择的 JSON 文件。
- 不读取浏览器历史，不自动上传数据。

## 8. 测试策略

- `TabStashSyncTests`：schema 解析、无效 URL、最新时间合并。
- `TabStashTests`：URL 解析。

## 9. 发布准备

- [x] 独立 Bundle ID 与版本号。
- [x] 独立 App Icon。
- [x] `PrivacyInfo.xcprivacy`。
- [x] App Store metadata 文案。
- [x] 单元测试通过。
- [x] 本机构建通过。
- [ ] App Store 截图。
- [ ] App Store Connect App 记录。
- [ ] 签名、证书和 provisioning profile。

## 10. Roadmap

- 浏览器插件导出功能对齐。
- iCloud 容器作为传输层。
- 双向同步与冲突合并测试扩展。

## 参考

- [App README](../README.md)
- [进度文档](PROGRESS.md)
- [仓库设计](../../../docs/DESIGN.md)
- [隐私说明](../../../PRIVACY.md)
