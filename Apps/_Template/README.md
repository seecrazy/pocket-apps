# Pocket Apps Template

这是一个新增 App 的模板目录。复制本目录后，需要同步修改：

1. `Project.swift` 中的 `AppMetadata`。
2. `Workspace.swift` 注册新目录。
3. 本 README 和 `docs/` 内的设计 / 进度文档。
4. 资源目录中的 App Icon 与 `PrivacyInfo.xcprivacy`。

## 快速开始

```bash
cp -R Apps/_Template Apps/NewApp
# 修改 Project.swift 和 Workspace.swift
./scripts/generate.sh
open PocketApps.xcworkspace
```

## 文档

- [docs/DESIGN.md](docs/DESIGN.md)
- [docs/PROGRESS.md](docs/PROGRESS.md)
