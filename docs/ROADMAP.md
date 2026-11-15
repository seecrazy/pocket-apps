# Pocket Apps Roadmap

## 当前状态

日期：2026-11-14

六个 App 已进入发布准备阶段：前五个 App 处于 v1.3 工程内可发布状态，At Ease 处于 v0.1 MVP 状态。仓库内工程、功能、隐私清单、可测试性和发布流水线骨架已经齐备；实际 App Store / TestFlight 交付依赖 Apple 开发者账号、证书与签名资源。

## 已完成

### 基础设施

- [x] Tuist Workspace、本地 SPM Package、模板 App。
- [x] SwiftLint / SwiftFormat / scripts。
- [x] CI：lint、生成、共享包测试、App 测试、全部 App 构建。
- [x] Release workflow：按 `<App>@<version>` tag 独立发布。
- [x] fastlane lane：六个 App 的 beta / release。
- [x] fastlane metadata 文案骨架。
- [x] 六个 App 独立 README / 设计文档 / 进度文档。

### SoloGuard

- [x] 本地生活确认计划。
- [x] 每日提醒调度与取消。
- [x] 昨日缺失签到提示。
- [x] 计划删除时取消提醒并清理记录。
- [x] 签到历史、设置页和首启说明。

### FocusBox

- [x] 专注会话与状态机。
- [x] 完成 / 放弃记录。
- [x] 重启后恢复 running 会话或自动完成超时会话。
- [x] 今日统计和最近 7 天趋势图。
- [x] 专注意图、自定义时长、设置页和首启说明。

### SlowCard

- [x] 慢递卡片与延迟解锁。
- [x] 到达提醒调度与删除取消。
- [x] 收藏与归档过滤。
- [x] 删除确认。
- [x] 写作提示、锁卡状态、设置页和首启说明。

### AmbientLog

- [x] 麦克风权限、录音、播放、重命名、删除。
- [x] 录音中断自动停止并保留文件。
- [x] 中断原因提示。
- [x] 搜索过滤与播放错误提示。
- [x] 录音分类、分类搜索、设置页和首启说明。

### TabStash iOS

- [x] `PocketTabStash.v1` JSON schema。
- [x] JSON 导入与导出。
- [x] 最新修改时间合并策略。
- [x] 孤儿 collection、无效 URL、版本错误处理。
- [x] 未读 / 已读 / 收藏管理与删除。
- [x] 搜索、手动添加标签页、同步页、设置页和首启说明。

### 发布准备

- [x] 五个 App 版本升至 `1.1.0`。
- [x] 独立 App Icon。
- [x] `PrivacyInfo.xcprivacy`。
- [x] AmbientLog 麦克风用途描述。
- [x] 破坏性操作确认。
- [x] 空态、错误态和权限拒绝态。
- [x] 状态机、过滤器、通知调度、schema 合并测试。
- [x] SF Symbol 存在性测试。
- [x] 本机 `release_preflight.sh` 全量通过。
- [x] 支持通过 `Tuist/Signing.xcconfig` 配置本机真机签名。

## 待完成

### App Store 依赖

- [ ] Apple Developer Team ID。
- [ ] 六个 App Store Connect App 记录。
- [ ] match 证书仓库。
- [ ] 六个 provisioning profile。
- [ ] App Store Connect API Key。
- [ ] App Store 隐私问卷。
- [ ] 六套截图。
- [ ] 将 metadata 中支持/隐私 URL 替换为最终域名。
- [ ] TestFlight 端到端发布验证。

### 后续产品增强

#### SoloGuard

- [ ] 计划编辑与频率模型（每日 / 每周）。
- [ ] 通知动作直接完成签到。
- [ ] 错过签到趋势统计。

#### FocusBox

- [ ] Family Controls / Screen Time 隔离。
- [ ] 会话标签与专注意图搜索。

#### SlowCard

- [ ] SwiftData migration 策略。
- [ ] 到达日通知动作直达卡片。
- [ ] 多张卡片的批量归档。

#### AmbientLog

- [x] 波形可视化。
- [ ] 转写与全文搜索。
- [ ] 后台录音边界与耗电策略。

#### TabStash iOS

- [ ] 浏览器插件导出功能对齐。
- [ ] iCloud 容器作为传输层。
- [ ] 双向同步与冲突合并测试扩展。

## 下一个交付节点

1. 用真实 Apple 账号完成签名与 TestFlight 上传。
2. 将浏览器插件导出格式对齐 `PocketTabStash.v1`。
3. 为 SoloGuard 增加通知动作签到。
4. 为 AmbientLog 增加录音中断测试的协议级 mock。

## 第二轮迭代

### SoloGuard

- [x] 计划编辑与通知重调度。
- [x] 最近 14 天签到趋势。
- [x] 守护联系人、安全状态卡、快速呼叫与显式分享。

### FocusBox

- [x] 专注会话暂停 / 恢复。
- [x] paused 状态在 App 重启后保持可信。
- [x] 可配置 App 内遮罩。
- [ ] Family Controls 系统级 Screen Time 盾牌。

### SlowCard

- [x] 任意未来解锁日期。
- [x] 解锁内容复制 / 分享。

### AmbientLog

- [x] 音频文件元数据展示。
- [x] 系统分享导出。
- [x] 后台音频模式。
- [x] dBFS 音量统计与波形。
- [x] dBFS 解释卡片。

### At Ease

- [x] v0.2：Core Haptics、HealthKit、Live Activity。
- [x] v0.3：念头放下、触摸身体扫描、环境音混音。
- [x] v0.4：引导冥想内容 schema、5 条免费内容、播放器、收藏与下载底座。
- [x] v0.5：StoreKit 2 订阅底座、状态缓存、恢复购买、第 3 次练习后的低调入口。
- [x] v0.6：订阅内容接入、访问判定、锁定/解锁联动、播放器二次校验。
- [x] v0.7：remoteAudio schema、首次播放下载、本地缓存复用与播放底座。
- [x] v0.8：离线音频管理页、缓存大小、单条删除、清理全部与订阅锁定规则。
- [x] v0.9：App 级缓存状态、可选顺序预下载、取消与练习列表离线状态。
- [x] v1.0：后台音频、隐私审计、无障碍标签、release audit 与 App Store 发布门槛。
- [x] v1.1：6 种自然音景素材化、Tencent TTS 本地音频优先。
- [x] v1.2：练习页改用冥想音乐；自然音仅保留在自由计时器，并默认收起。
- [ ] Core Haptics 真机精度验证。
- [ ] HealthKit 授权状态与失败 UI。
- [ ] 正式订阅内容音频资产、OS 级后台预下载、CDN 分发与 App Store Connect 订阅上架。

### TabStash

- [x] 创建集合。
- [x] 当前结果内批量处理未读。

## 第三轮产品修正

### FocusBox

- [x] 倒计时改用墙钟计算，切屏 / 锁屏 / 回前台不卡住。
- [x] 支持“关闭 / App 内遮罩”配置。
- [ ] 预留 Screen Time 系统锁机方案。

### AmbientLog

- [x] 增加 `UIBackgroundModes: audio`。
- [x] 支持锁屏 / 切后台继续录音。
- [x] 记录 dBFS 并实时显示音量统计。
- [x] 保存并展示波形。

### SoloGuard

- [x] 新增守护联系人。
- [x] 生成安全状态卡。
- [x] 支持快速呼叫与显式分享。

## 第四轮：成熟产品对标优化

### SoloGuard
- [x] 守护联系人编辑 / 主联系人管理。
### FocusBox
- [x] 专注进度环。
- [x] 连续专注天数。
### SlowCard
- [x] 卡片到达倒计时。
### AmbientLog
- [x] 录音秒数实时展示。
### TabStash
- [x] 创建集合。
- [x] 批量标记已读。
