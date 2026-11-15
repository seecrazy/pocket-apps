# At Ease 进度文档

> 当前版本：1.2.0
> 状态：练习音乐边界修正完成；等待开发者账号、App Store Connect 订阅与签名
> 最后更新：2026-11-15

## 当前摘要

At Ease 已完成 v0.1–v1.1 的仓库内发布路径：无登录呼吸/计时、情绪签到、本地进度、可选语音、Core Haptics、HealthKit、Live Activity、非声音练习、多层环境音、练习页冥想音乐、5 条免费结构化引导冥想、StoreKit 2 订阅底座、3 条订阅深度内容原型的锁定 / 解锁分发、远程音频下载与离线播放底座、音频缓存管理、可选顺序预下载、后台音频、无障碍标签、隐私审计、App Store 发布门槛与 Tencent TTS 音频优先级。正式订阅音频、CDN、订阅产品配置和 TestFlight 发布仍需外部账号资源。

## 已完成

### v0.1.x — MVP 闭环

- [x] 3 页引导页，可跳过。
- [x] 5 级情绪签到，包含可读标签与“平静 → 焦躁”说明。
- [x] 情绪映射推荐卡片。
- [x] 引导呼吸：4-7-8、Box、SOS。
- [x] 1–60 分钟计时器。
- [x] 呼吸圆环、阶段文字、SwiftData 本地进度。
- [x] 本周分钟数、35 天热力图、连续天数。
- [x] 设置页：触觉、默认时长、订阅状态占位。
- [x] 可选中文语音引导与一键静音。
- [x] 呼吸阶段语音、计时开始/结束语音。

### v0.2 — 身体在场与系统能力

- [x] Core Haptics 与吸气 / 屏息 / 呼气阶段同步。
- [x] HealthKit 正念分钟写入。
- [x] Live Activity 显示呼吸节奏与计时进度。
- [x] 温和本地提醒。
- [x] 权限失败不阻断本地记录。
- [ ] 真机触觉精度与 HealthKit 授权场景回归。

### v0.3 — 非声音练习

- [x] 念头放下：输入、长按淡出、结束记录。
- [x] 触摸身体扫描：分区高亮与轻触觉。
- [x] 环境音混音：雨声、流水、虫鸣。
- [x] 音量调节与预设保存。
- [x] 静音设备下完整可用。
- [ ] 环境音素材在更多设备上的听感回归。

### v0.4 — 内容基础设施

- [x] `AtEaseContentManifest` schema 与 bundled `ContentCatalog.json`。
- [x] `MeditationContentValidator` 校验非法内容。
- [x] `MeditationContentCatalogLoader` 加载失败保护。
- [x] 5 条免费基础引导冥想：
  - [x] 一分钟微休息。
  - [x] 三分钟会议前重置。
  - [x] 五分钟身体着陆。
  - [x] 五分钟午间放下。
  - [x] 八分钟睡前整理。
- [x] `MeditationScriptPlayer`：步骤推进、暂停/继续、进度、完成与提前退出保存。
- [x] `GuidedContentStateModel`：收藏、最近播放、完成状态、下载状态。
- [x] 练习页引导冥想入口与免费内容列表。
- [x] `MeditationPlayerView`：阶段文本、总进度、操作按钮。
- [x] 结束时写入 `PracticeSessionModel`。
- [x] `ContentDownloadState`、协议和本地下载目录底座。
- [x] 内容、播放器与下载服务单元测试。

## 当前待办

### v0.5 — 订阅闭环

- [x] 定义订阅分层与 entitlement 规则。
- [x] 接入 StoreKit 2 产品、购买、恢复与 currentEntitlements 刷新。
- [x] `UserDefaultsSubscriptionCache` 订阅状态缓存。
- [x] 可注入 `SubscriptionStoreProviding`，错误不改变本地练习数据。
- [x] 设置页显示免费 / 订阅状态，并提供订阅页与恢复购买。
- [x] `SubscriptionEntryRule` 控制第 3 次练习后的低调入口。
- [x] `MeditationPlayerView` 收尾卡片显示一行订阅链接，不弹窗施压。
- [x] 订阅页展示 StoreKit 返回价格与 introductory offer。
- [x] 订阅失败 / 无网 / 恢复无购买反馈清晰，不影响免费练习。
- [ ] App Store Connect 配置月度、年度订阅和 7 天试用。
- [ ] 接入真实睡眠故事或多周课程内容资产。

### v0.6 — 订阅内容分发

- [x] `MeditationContentAccessService` 作为唯一访问判定入口。
- [x] 免费内容始终可播放。
- [x] 订阅内容未授权时返回 `subscriptionRequired`。
- [x] 内容列表显示免费条目在前、订阅条目在后。
- [x] 收藏过滤保留锁定订阅条目。
- [x] 锁定卡片显示 `lock` 与“订阅解锁”，无红色促销样式。
- [x] 订阅内容点击进入订阅页。
- [x] `AtEaseRootView` 持有唯一订阅状态并注入 environment。
- [x] 订阅状态刷新后练习页内容自动解锁。
- [x] 订阅过期后自动回到锁定状态。
- [x] 播放器二次校验授权；未授权时不启动、不写练习记录。
- [x] `ContentCatalog.json` 新增 3 条订阅内容：
  - [x] 压力释放 · 第 1 天。
  - [x] 深度身体扫描。
  - [x] 睡前故事 · 夜里的灯塔。
- [x] 访问判定、分层列表和内置内容分层测试。

### v0.7 — 远程音频与离线播放

- [x] `AtEaseContentManifest` schema 升级到 v2。
- [x] 新增 `MeditationRemoteAudio`：HTTPS URL 与安全扩展名。
- [x] 校验 remote 内容必须带 `remoteAudio`。
- [x] 校验本地内容不能携带 `remoteAudio`。
- [x] 校验扩展名限定 `m4a`、`mp3`、`wav`、`aac`。
- [x] 新增 `MeditationAudioPreparationService`。
- [x] scripted / bundled 直接进入播放，不触发下载。
- [x] remote 内容先检查本地缓存。
- [x] 本地不存在时下载到 `Documents/Downloads/<contentID>/audio.<ext>`。
- [x] 下载成功后写入 `downloaded` 状态。
- [x] 下次播放复用本地文件，不重复下载。
- [x] 下载失败显示“音频暂时无法准备”，不启动结构化播放，也不写练习记录。
- [x] 播放中与暂停 / 继续同步控制本地音频。
- [x] 播放结束或离开页面停止音频。
- [x] 新增 `AVAudioPlayerAdapter` 与可替换的 `MeditationAudioPlaying` 协议。
- [x] remoteAudio schema、下载失败、本地复用与 scripted 免下载测试。

### v0.8 — 音频下载管理

- [x] `AudioDownloadSummary` 描述远程音频标题、路径、大小与订阅要求。
- [x] `AudioDownloadItemState` 支持 idle、downloading、downloaded、failed。
- [x] 新增 `MeditationAudioDownloadManager`。
- [x] 管理页只加载 `audioKind == remote` 的内容。
- [x] 重新加载时检查本地文件、大小和修改时间。
- [x] 支持单条下载。
- [x] 下载中禁止重复触发。
- [x] 下载成功后自动刷新大小与状态。
- [x] 下载失败显示中性提示并支持重试。
- [x] `ContentDownloadService` 新增本地缓存列表。
- [x] 新增文件大小读取。
- [x] 新增删除单个 `Downloads/<contentID>/` 目录。
- [x] 新增删除全部远程音频缓存。
- [x] 设置页新增“离线音频”入口。
- [x] 管理页显示已缓存条数与总大小。
- [x] 每条内容显示下载 / 下载中 / 已下载 / 重试状态。
- [x] 已下载内容显示大小和“删除”。
- [x] 支持“清理全部”。
- [x] 空状态说明当前还没有远程音频内容。
- [x] 未订阅的订阅内容显示“订阅解锁”，不提供下载。
- [x] 缓存列表、大小、下载、删除、清理全部测试。

### v0.9 — 可选预下载与状态联动

- [x] `AtEaseRootView` 持有唯一 `MeditationAudioDownloadManager`。
- [x] 通过 environment 注入练习页、设置页和离线音频页。
- [x] 离线音频页改为使用共享缓存状态。
- [x] `MeditationAudioDownloadManager` 新增内容级状态查询。
- [x] 新增 `isDownloaded(for:)`，练习列表显示“已离线”。
- [x] 新增下载中状态显示。
- [x] 播放器关闭后自动刷新共享缓存状态。
- [x] 新增 `atease.autoPredownloadEnabled` 设置，默认关闭。
- [x] 设置页新增“自动预下载”开关。
- [x] 开启开关立即预下载当前可访问内容。
- [x] Root 启动后根据开关预下载。
- [x] 订阅状态变化后根据开关重新预下载。
- [x] 预下载只处理 `audioKind == remote` 内容。
- [x] 预下载跳过已下载内容。
- [x] 预下载未订阅时跳过订阅内容。
- [x] 预下载按 manifest 原序逐条处理，不并发请求。
- [x] 单条失败保留 failed 状态，后续条目继续。
- [x] 新增预下载完成数、总数和当前条目。
- [x] 设置页显示“正在预下载 X / Y”。
- [x] 预下载运行中支持取消。
- [x] 取消后不再开始新条目。
- [x] scripted / bundled 不显示缓存状态。
- [x] 预下载权限过滤、失败继续、取消与已下载跳过测试。

### v1.0 — 发布就绪

- [x] App target 增加 `UIBackgroundModes: audio`。
- [x] `AVAudioPlayerAdapter` 播放前激活 `.playback` 音频会话。
- [x] 远程音频支持锁屏与切后台继续播放。
- [x] 停止播放时释放音频会话。
- [x] 隐私清单新增 `NSPrivacyAccessedAPICategoryFileTimestamp`。
- [x] 隐私清单保留 `CA92.1` 与 `C617.1` reason。
- [x] 身体扫描关闭按钮补齐“关闭”标签。
- [x] 计时器关闭按钮补齐“关闭计时器”标签。
- [x] 念头放下关闭按钮补齐“关闭”标签。
- [x] 音频缓存清理全部补齐语义标签。
- [x] 收藏按钮包含内容标题与收藏状态。
- [x] 订阅内容卡片包含内容标题与订阅解锁语义。
- [x] 订阅产品选择按钮包含产品名称。
- [x] 音频下载 / 删除按钮包含内容标题。
- [x] 新增 release audit 测试验证隐私清单。
- [x] release audit 测试验证后台音频模式。
- [x] release audit 测试验证订阅产品 ID。
- [x] release audit 测试验证内置目录没有占位远程 URL。
- [x] release audit 测试验证版本号 `1.0.0`。
- [x] 新增 `docs/APP_STORE.md` 发布门槛。
- [x] 根隐私文档补充 At Ease 与后台音频、HealthKit。

### v1.1 — 自然音景与 Tencent TTS

- [x] 环境音从 3 种扩展到 6 种：雨声、流水、虫鸣、海浪、森林、风声。
- [x] 移除逐样本随机噪声原型。
- [x] 使用 Wikimedia Commons 免费音频素材。
- [x] 使用 ffmpeg 转换为 iOS 兼容的 M4A / AAC。
- [x] 记录完整来源、作者、许可证与授权要求。
- [x] `AmbientSoundLevel` 兼容旧版 3 音景预设。
- [x] 引导冥想使用独立冥想音乐。
- [x] 呼吸练习使用独立冥想音乐。
- [x] 播放结束或离开页面停止背景音景。
- [x] 新增 `AtEaseVoiceLocator`，按 Tencent TTS 音频命名查找本地语音。
- [x] `AtEaseAudioGuide` 优先播放 Tencent TTS 生成的 MP3。
- [x] 缺失 Tencent 音频时回退到 iOS 中文语音。
- [x] 引导冥想步骤语音按 `contentID + stepID` 查找。
- [x] 呼吸吸气 / 屏息 / 呼气语音按固定资源名查找。
- [x] 计时开始 / 结束语音按固定资源名查找。
- [x] 新增 `scripts/generate_at_ease_tts.py`。
- [x] 脚本使用 Tencent Cloud TC3-HMAC-SHA256 签名。
- [x] 短文本调用 Tencent TTS `TextToVoice`。
- [x] 长文本调用 `CreateTtsTask` 并轮询 `DescribeTtsTaskStatus`。
- [x] 使用 `PrimaryLanguage` 而不是不存在的 `Language` 参数。
- [x] 音量参数按 `[-10, 10]` 对齐。
- [x] 语速参数按 `[-2, 6]` 对齐。
- [x] 脚本从环境或 `~/.zshrc` 读取凭据，不写入仓库。
- [x] 脚本从 `ContentCatalog.json` 生成全部步骤语音。
- [x] 新增环境音能量、边界、新音景与旧预设兼容测试。
- [x] 新增语音资源命名与缺失回退测试。
- [x] Tencent TTS 脚本生成实际 MP3。
- [ ] 真机听感回归：雨声、海浪、森林和风声长时间播放。

### v1.2 — 音频边界修正

- [x] 引导冥想播放页移除自然音列表。
- [x] 呼吸页移除自然音列表。
- [x] 新增 `MeditationMusicMixer` 与 `MeditationMusicCard`。
- [x] 引导冥想和呼吸练习默认使用冥想音乐。
- [x] 冥想音乐提供“平静铺底”和“温润氛围”两轨。
- [x] 练习页音乐控件保持单行，不覆盖播放 / 结束按钮。
- [x] 自然音仅保留在自由计时器。
- [x] 自然音卡片默认收起。
- [x] 展开后使用受限高度，不覆盖计时器操作按钮。
- [x] `AmbientSoundMixer` 改为播放 Wikimedia Commons 音频素材。
- [x] 6 种自然音完成 M4A / AAC 转换。
- [x] 2 条冥想音乐完成 M4A / AAC 转换。
- [x] 新增自然音与冥想音乐资源存在性测试。
- [x] 新增 Tencent TTS 语音资源存在性测试。
- [x] 新增自然音与冥想音乐 `ATTRIBUTIONS.md`。

### 发布前

- [ ] 真机验证 Core Haptics、HealthKit、Live Activity。
- [ ] 真实导师/环境音频资产接入与授权台账。
- [ ] App Store 截图、隐私问卷与审核材料。
- [ ] TestFlight 冒烟验证。

## 版本演进路线

| 版本 | 主题 | 状态 |
|---|---|---|
| `0.1.x` | MVP 闭环 | ✅ 已完成 |
| `0.2` | 身体在场与系统能力 | ✅ 代码完成，真机回归待做 |
| `0.3` | 非声音练习 | ✅ 代码完成，听感回归待做 |
| `0.4` | 内容基础设施 | ✅ 已完成 |
| `0.5` | 订阅底座 | ✅ 代码完成，商店产品待配置 |
| `0.6` | 订阅内容分发 | ✅ 代码完成，正式内容资产待上架 |
| `0.7` | 远程音频与离线播放 | ✅ 代码完成，CDN 与正式资产待上架 |
| `0.8` | 音频下载管理 | ✅ 已完成 |
| `0.9` | 可选预下载与状态联动 | ✅ 已完成 |
| `1.0` | 发布就绪 | ✅ 仓库内完成；签名/订阅/资产待外部配置 |
| `1.0` | 公开发布 | ⏳ |
| `1.1` | 自然音景与 Tencent TTS | ✅ 已完成 |
| `1.2` | 音频边界修正 | ✅ 已完成 |

## 验证状态

最近一次 At Ease 单元测试：

```text
Executed 66 tests, with 0 failures
** TEST SUCCEEDED **
```

提交前仍需执行：

```bash
./scripts/generate.sh
./scripts/lint.sh
./scripts/test.sh
IOS_SIMULATOR_NAME="iPhone 17" ./scripts/test_apps.sh
./scripts/build_apps.sh
```
