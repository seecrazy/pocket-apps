# Pocket Apps Privacy

Pocket Apps 的产品以本机数据优先。v1.1 不接入统计 SDK、广告 SDK、第三方后端，也不进行用户追踪。

## 数据存储

| App | 存储的数据 | 存储位置 | 是否上传 |
|---|---|---|---|
| SoloGuard | 生活确认计划、签到记录 | App 沙盒 SwiftData | 否 |
| FocusBox | 专注会话、专注统计 | App 沙盒 SwiftData | 否 |
| SlowCard | 明信片标题、内容、解锁时间 | App 沙盒 SwiftData | 否 |
| AmbientLog | 录音元数据和音频文件 | App 沙盒 Documents | 否 |
| TabStash | 导入的标签页集合和阅读状态 | App 沙盒 SwiftData | 否 |

## 系统能力

- **本地通知**：SoloGuard 与 SlowCard 使用通知，授权失败时不阻塞本地功能。
- **麦克风**：AmbientLog 仅在用户主动点击开始录音时访问麦克风。
- **文件导入**：TabStash 仅读取用户通过系统文件选择器选择的 JSON 文件。

## 隐私清单

每个 App 都包含 `PrivacyInfo.xcprivacy`，声明：

- 不追踪用户。
- 不采集数据。
- 不包含追踪域名。

## 删除数据

用户可以在 App 内删除对应记录；App 沙盒数据也会随卸载 App 删除。
