# At Ease 进度文档

> 当前版本：0.6.0
> 状态：订阅内容分发完成，等待正式音频资产与 App Store Connect 产品
> 最后更新：2026-11-15

## 当前摘要

At Ease 已完成 v0.1–v0.6 的核心路径：无登录呼吸/计时、情绪签到、本地进度、可选语音、Core Haptics、HealthKit、Live Activity、非声音练习、环境音混音、5 条免费结构化引导冥想、StoreKit 2 订阅底座，以及 3 条订阅深度内容原型的锁定 / 解锁分发。正式订阅音频、App Store Connect 产品配置和 TestFlight 发布仍在后续阶段。

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
| `1.0` | 公开发布 | ⏳ |

## 验证状态

最近一次 At Ease 单元测试：

```text
Executed 32 tests, with 0 failures
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
