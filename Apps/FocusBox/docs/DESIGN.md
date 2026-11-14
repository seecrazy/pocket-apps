# FocusBox 设计文档

> 状态：已采纳  
> 版本：1.1.0  
> 更新时间：2026-11-14

## 1. 产品定位

FocusBox 不强制锁机，也不读取屏幕使用记录。它用一个明确的专注意图、可靠的倒计时和本机统计，帮助用户把注意力从“焦虑地看时间”转回“现在做什么”。

**副标题**：专注盒子  
**Bundle ID**：`com.pocketapps.focusbox`

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

用户写下“整理项目大纲”，选择 45 分钟开始专注。中途切到系统邮件，计时继续；回到 App 后倒计时仍在推进。如果 App 被系统回收，重启后按开始时间恢复剩余时长。

### 典型流程

1. 首启说明 → 输入意图 → 选择时长 → 开始专注 → 完成 / 放弃。
2. 离开 App 后计时继续；重启 App 后按开始时间恢复。
3. 完成会话写入 SwiftData，统计页按本地日历聚合。

## 3. 信息架构

三栏 Tab：**专注**、**统计**、**设置**。专注页承担开始、进行中和恢复状态；统计页独立展示趋势。

## 4. 数据模型

- `FocusSessionModel`：会话 ID、开始时间、计划时长、专注意图、完成时间、状态。
- `FocusSessionStatus`：`running`、`completed`、`abandoned`。

## 5. 关键交互与状态

- 会话：`idle → running → completed` 或 `idle → running → abandoned`。
- 恢复：App 启动时查询 `running`，按 `startedAt + plannedMinutes` 计算剩余时间。
- 超时：剩余时间小于等于 0 时自动标记 `completed`。

## 6. 错误与边界处理

- **系统后台限制：用开始时间和计划时长恢复，而不是只依赖 Timer。**
- **用户误触放弃：放弃状态需可区分，不影响完成统计。**
- **跨天统计：统一使用本地 Calendar 判断同一天。**

## 7. 隐私与数据边界

- 专注会话和意图保存在本机 SwiftData。
- 不读取 Screen Time，不访问其他 App 使用情况。
- 不强制锁机。

## 8. 测试策略

- `FocusSessionRecoveryTests`：恢复进行中会话和自动完成过期会话。
- `FocusStatsCalculatorTests`：今日统计与 7 天趋势只统计完成会话。

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

- 会话标签与意图搜索。
- 专注结束通知。
- 每周专注报告。

## 参考

- [App README](../README.md)
- [进度文档](PROGRESS.md)
- [仓库设计](../../../docs/DESIGN.md)
- [隐私说明](../../../PRIVACY.md)
