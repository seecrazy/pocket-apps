# At Ease（心安）

<p align="left">
  <img alt="iOS" src="https://img.shields.io/badge/iOS-17%2B-0A84FF">
  <img alt="SwiftUI" src="https://img.shields.io/badge/UI-SwiftUI-32ADE6">
  <img alt="SwiftData" src="https://img.shields.io/badge/Data-SwiftData-0A84FF">
  <img alt="Version" src="https://img.shields.io/badge/Version-0.5.0-8E8E93">
  <img alt="Status" src="https://img.shields.io/badge/Status-Subscription_Foundation-34C759">
</p>

> 每天一分钟，心安一下。

At Ease 是一款低门槛、不制造压力的极简冥想 App。当前版本完成呼吸、计时器、情绪签到、非声音练习、系统级触觉/健康/锁屏集成、5 条免费引导冥想，以及 StoreKit 2 订阅底座。真实订阅内容资产在后续阶段上架。

## 目录

- [产品定位](#产品定位)
- [设计原则](#设计原则)
- [快速开始](#快速开始)
- [当前能力](#当前能力)
- [体验架构](#体验架构)
- [数据与隐私](#数据与隐私)
- [架构与设计](#架构与设计)
- [测试](#测试)
- [Roadmap](#roadmap)
- [文档](#文档)
- [许可证](#许可证)

## 产品定位

**让“打开 App”这件事本身不构成压力。**

呼吸与计时器永远免费且可离线；引导冥想当前提供 5 条高完成率短练习，帮助用户从“打开”走到“完成”。产品不做内容堆叠，不把练习变成待办清单。

## 设计原则

| 原则 | 含义 | 当前落地 |
|---|---|---|
| 零摩擦启动 | 无登录、无注册、无搜索 | 打开即可签到、呼吸或计时 |
| 情绪优先 | 从当下情绪进入，而不是进入分类库 | 5 级情绪签到映射 3 张推荐卡片 |
| 身体在场 | 视觉、触觉、声音协同，但不依赖声音 | Core Haptics 呼吸同步、可选语音引导 |
| 不制造焦虑 | 不惩罚、不弹窗、不制造愧疚感 | 断签文案“今天重新开始也很好” |
| 内容克制 | 只保留能提升“明天再打开”的内容 | 5 条免费引导冥想，无分类页和搜索 |

## 快速开始

```bash
git clone https://github.com/pocket-apps/pocket-apps.git
cd pocket-apps
./scripts/generate.sh
open PocketApps.xcworkspace
```

在 Xcode 中选择 `AtEase` scheme，运行到 iOS 17+ 模拟器或真机。如需真机签名，请参考根 README 的 iPhone 部署说明。

## 当前能力

### 核心练习
- 一次性 3 页引导页，可跳过。
- 首页情绪签到：5 级色块 + 可读标签，可跳过。
- 基于情绪的 3 张推荐卡片。
- 引导呼吸：4-7-8、箱式呼吸、1 分钟 SOS。
- 呼吸圆环、阶段文字、可选中文语音和 Core Haptics 阶段触觉。
- 自由计时器：1–60 分钟，可叠加雨声、流水、虫鸣。

### 非声音练习
- 念头放下：输入烦恼，长按让文字随涟漪淡出。
- 触摸身体扫描：线性人体轮廓 + 分区触觉反馈。
- 环境音混音：三种本地音景可分别调节音量，预设保存在本机。

### 引导冥想（v0.4）
- 5 条免费短练习：1 分钟微休息、3 分钟会议前重置、5 分钟身体着陆、5 分钟午间放下、8 分钟睡前整理。
- 结构化播放器：步骤推进、暂停/继续、柔和阶段标签、总进度。
- 提前退出保存已完成分钟数，完成自动更新本地状态。
- 收藏、最近播放和完成标记。
- `ContentDownloadState` 与本地下载目录底座，为后续远程音频资产准备。

### 系统集成
- HealthKit 正念分钟写入。
- Live Activity 显示呼吸节奏与计时进度。
- 温和本地提醒。
- 触觉、语音与 HealthKit 均可通过设置控制。

### 订阅底座（v0.5）
- StoreKit 2 自动续期订阅产品模型。
- 月度与年度产品占位 ID，价格和 offer 由 App Store 返回。
- 订阅状态基于 `Transaction.currentEntitlements` 刷新，并在本机缓存最近已知状态。
- 恢复购买始终可用。
- 第 3 次练习后的收尾卡片只显示一行低调入口。
- 无网、加载失败或恢复失败不阻断任何免费练习。

## 体验架构

```text
App 启动
├── 引导页（仅首次，3 页可跳过）
└── 主界面
    ├── 今日
    │   ├── 情绪签到
    │   ├── 推荐卡片
    │   └── 今日分钟数
    ├── 练习
    │   ├── 呼吸
    │   ├── 计时器
    │   ├── 念头放下 / 身体扫描
    │   ├── 环境音混音
    │   └── 引导冥想
    ├── 进度
    │   ├── 本周分钟数
    │   ├── 日历热力图
    │   └── 连续天数
    └── 设置
```

## 数据与隐私

| 数据 | 存储 | 是否上传 |
|---|---|---|
| 情绪签到 | SwiftData / App 沙盒 | 否 |
| 练习记录 | SwiftData / App 沙盒 | 否 |
| 引导内容收藏与完成状态 | SwiftData / App 沙盒 | 否 |
| 音景预设与设置偏好 | UserDefaults | 否 |
| 可选正念分钟 | HealthKit，经用户授权 | 仅写入本机 Health 数据库 |

当前版本不接入账号、云端、广告、第三方统计。订阅状态缓存在本机；后续订阅仅用于解锁内容，不会迁移或上传练习历史。

## 架构与设计

- App target：`AtEase`
- Bundle ID：`com.pocketapps.atease`
- UI：SwiftUI
- 存储：SwiftData / App 沙盒
- 内容：bundled JSON manifest + schema 校验
- 服务：呼吸节奏、内容加载与校验、脚本播放器、下载底座、HealthKit、Live Activity、Core Haptics
- 设计令牌：暖灰画布、近黑呼吸页、雾蓝强调、五级情绪色
- 订阅：StoreKit 2、可注入 provider、UserDefaults 状态缓存

完整产品与 UI 设计见 [docs/DESIGN.md](docs/DESIGN.md)。

## 测试

在仓库根目录执行：

```bash
./scripts/generate.sh
./scripts/lint.sh
./scripts/test.sh
IOS_SIMULATOR_NAME="iPhone 17" ./scripts/test_apps.sh
./scripts/build_apps.sh
```

At Ease 当前覆盖点：

- 情绪推荐映射。
- 呼吸阶段推进。
- 正念分钟聚合与练习记录。
- 设计令牌与文案约束。
- Content Catalog schema 校验与加载失败边界。
- 脚本播放器推进、暂停、继续、进度、完成与提前结束。
- 下载服务状态、目录与本地文件判断。
- `GuidedContentStateModel` 用户态。
- 订阅状态缓存、刷新、购买失败保留状态、恢复成功/无购买反馈。
- 第 3 次练习后显示低调订阅入口的规则。

## Roadmap

### 已完成
- `v0.1.x`：MVP 闭环、可选声音引导。
- `v0.2`：Core Haptics、HealthKit、Live Activity。
- `v0.3`：念头放下、触摸身体扫描、环境音混音。
- `v0.4`：引导冥想内容基础设施。
- `v0.5`：StoreKit 2 订阅底座、状态缓存、恢复购买、低调订阅入口。

### 下一步
- 配置 App Store Connect 月度 / 年度订阅与 7 天试用。
- 接入真实睡眠故事或多周课程。
- `v1.0`：稳定性、无障碍、合规、截图、TestFlight 与审核。

发布原则：

1. 每个版本保持呼吸与计时器无登录、无强制订阅、可离线使用。
2. 不做内容堆叠；只增加能提升“明天再打开”的能力。
3. 订阅提示最早出现在第 3 次练习后的收尾卡片，不做弹窗施压。
4. 数据写入失败不阻断练习；进度损失必须有本地保护。

## 文档

- 设计文档：[docs/DESIGN.md](docs/DESIGN.md)
- 进度文档：[docs/PROGRESS.md](docs/PROGRESS.md)
- 仓库设计：[../../docs/DESIGN.md](../../docs/DESIGN.md)
- 隐私说明：[../../PRIVACY.md](../../PRIVACY.md)

## 许可证

仓库尚未附带开源许可证，默认保留所有权利。
