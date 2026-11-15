# At Ease App Store 发布门槛

> 版本：1.0.0  
> 本文档区分“仓库内已完成”与“发布前必须由开发者账号完成”的步骤。

## 仓库内已完成

- Workspace 与 `AtEase` / `AtEaseWidgets` / `AtEaseTests` 可生成、可构建。
- 免费呼吸、计时器、非声音练习、引导冥想和订阅分层完整可用。
- 呼吸与计时器无登录、无强制订阅、可离线。
- 5 条免费引导冥想与 3 条订阅深度内容原型已内置。
- 远程音频支持 HTTPS schema、沙盒下载、离线复用、缓存管理。
- 可选自动预下载默认关闭。
- 后台音频模式与会话激活已声明。
- 隐私清单不追踪、不采集，并声明 UserDefaults 与 File timestamp。
- App Icon、PrivacyInfo、fastlane metadata 与 release preflight 已完成。
- 主要图标操作和内容操作已补齐 VoiceOver 标签。

## 发布前外部步骤

### 1. Apple Developer / App Store Connect

- 确认 Apple Developer Program 有效。
- 在 App Store Connect 创建 `com.pocketapps.atease`。
- 创建月度订阅：

```text
com.pocketapps.atease.subscription.monthly
```

- 创建年度订阅：

```text
com.pocketapps.atease.subscription.annual
```

- 如提供 7 天试用，配置 introductory offer。
- 确认订阅审核材料、价格层级和本地化文案。
- 在 match / fastlane 可访问的证书仓库中提供 App Store 签名资源。

### 2. 内容资产与授权

当前 3 条订阅条目是结构化文本引导。上架正式订阅前需要：

- 录制正式导师音频或授权音频。
- 上传音频到 HTTPS CDN。
- 将 `ContentCatalog.json` 中对应条目更新为 `audioKind: remote`。
- 填入真实 `remoteAudio.url` 与受支持扩展名。
- 建立授权台账：来源、授权类型、到期日、是否允许 App 内分发、Content ID 状态。

### 3. 截图与审核材料

建议覆盖以下场景：

1. 今日页：情绪签到与今日分钟。
2. 呼吸页：圆环与阶段文字。
3. 计时器页：自定义时长。
4. 引导冥想列表：免费内容与订阅内容。
5. 引导冥想播放页：阶段与进度。
6. 离线音频页：缓存大小与管理操作。

截图原则：

- 不使用夸张促销文案。
- 不出现警告色或倒计时。
- 突出低门槛、可静音、可离线。
- 文案与 App Store description 一致。

### 4. 隐私问卷

- 不收集数据。
- 不追踪用户。
- 不包含追踪域名。
- 不使用广告或第三方统计 SDK。
- UserDefaults：App 功能偏好，理由 `CA92.1`。
- File timestamp：本地音频缓存管理，理由 `C617.1`。
- HealthKit：仅在用户授权后写入正念分钟。

### 5. TestFlight 冒烟清单

- 冷启动到今日页。
- 情绪签到并开始 1 分钟呼吸。
- 计时器启动、暂停、继续、结束。
- 引导冥想播放、暂停、提前结束。
- 锁屏播放冥想音频。
- 切后台后音频继续。
- 离线状态打开已下载内容。
- 删除单条缓存与清理全部。
- StoreKit 购买、试用、恢复购买。
- VoiceOver 遍历呼吸、冥想列表、播放器和设置页。
- 通知授权拒绝后不阻断核心功能。
- HealthKit 授权拒绝后不阻断本地记录。

## 发布命令

仓库内检查：

```bash
./scripts/release_preflight.sh
```

TestFlight：

```bash
bundle exec fastlane atease_beta
```

提交 App Store 审核：

```bash
bundle exec fastlane atease_release
```

Tag：

```bash
git tag AtEase@1.0.0
git push origin AtEase@1.0.0
```
