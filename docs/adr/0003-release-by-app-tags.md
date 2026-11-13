# ADR 0003：按 App tag 独立发布

日期：2026-11-14
状态：已采纳

## 背景

每个 App 有独立 App Store Connect 记录、证书、版本号和发布节奏。

## 决策

Tag 格式为 `<AppName>@<semver>`：

```bash
git tag SoloGuard@1.0.0
git push origin SoloGuard@1.0.0
```

CI 解析 App 名与版本，只构建对应 App。

## 规则

1. tag 版本必须与 `Apps/<App>/Project.swift` 的 `appVersion` 一致。
2. release workflow 使用 App 名定位目录与 fastlane lane。
3. 共享包变更不触发自动 release；仍需对对应 App 打 tag。
4. 发布产物只上传对应 tag 的 GitHub Release。

## 理由

- 避免“一次改动触发五个 App 发布”。
- 每个 App 的 release 历史清晰。
- 证书与 profile 按 Bundle ID 隔离。
