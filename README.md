# Pocket Apps

`pocket-apps` 是一个承载多个独立发布 iOS App 的 Monorepo。当前首批包含 SoloGuard、FocusBox、SlowCard、AmbientLog 与 TabStash iOS。

## 产品状态

仓库已完成 v1 最小实现：

- SoloGuard：本地生活确认计划与每日签到。
- FocusBox：专注计时、完成/放弃与今日统计。
- SlowCard：延迟解锁的写给自己的明信片。
- AmbientLog：本机麦克风录音、播放与删除。
- TabStash iOS：标签集合与继续阅读列表。

以上功能当前以本机 SwiftData 数据为主；TabStash 的 iCloud 同步尚未接入，v1 中展示本地样例数据。

## 文档入口

- 设计方案：[docs/DESIGN.md](docs/DESIGN.md)
- 进展与待办：[docs/ROADMAP.md](docs/ROADMAP.md)
- 会话交接：[docs/HANDOFF.md](docs/HANDOFF.md)
- ADR：[docs/adr](docs/adr)

## 环境要求

- macOS 15+
- Xcode 16+
- Tuist 4.216.6（仓库通过 `.tuist-version` 记录当前版本）
- Ruby + Bundler（发布流水线使用）
- SwiftLint / SwiftFormat（本地 lint）

## 快速开始

```bash
git clone <repository-url>
cd pocket-apps
./scripts/generate.sh
open PocketApps.xcworkspace
```

生成 Workspace 后，Xcode 左侧可以选择任意 App target 运行。所有 iOS App 的最低部署版本为 iOS 17。

## 常用命令

```bash
# 生成 Xcode 工程
./scripts/generate.sh

# 检查格式与 SwiftLint
./scripts/lint.sh

# 运行本地 Package 单元测试
./scripts/test.sh

# 运行各 App 单元测试
./scripts/test_apps.sh

# 构建五个 App
./scripts/build_apps.sh
```

## 新增 App

1. 复制 `Apps/_Template` 到 `Apps/<NewApp>`。
2. 修改 `Project.swift` 里的 `AppMetadata`，包括 name、displayName、bundleID 和 version。
3. 在 `Workspace.swift` 注册新目录。
4. 执行 `./scripts/generate.sh`。

不要提交 `*.xcodeproj` 或 `*.xcworkspace`。

## 发布

版本定义在 `Apps/<App>/Project.swift` 的 `AppMetadata.version`。发布时 tag 必须与该字段一致：

```bash
git tag SoloGuard@1.0.0
git push origin SoloGuard@1.0.0
```

`.github/workflows/release.yml` 会校验 tag、生成工程并调用对应 fastlane lane。TestFlight 上传需要先配置 App Store Connect API Key、Apple Developer Team ID、证书和 provisioning profile。

## 边界

- 共享包只放基础能力，不放 App 业务逻辑。
- App 之间不互相依赖。
- SoloGuard v1 不实现真实紧急联系人外发。
- AmbientLog 录音只保存在 App 沙盒，不上传云端。
- TabStash v1 只展示同步/样例标签页，不反向编辑浏览器插件。
