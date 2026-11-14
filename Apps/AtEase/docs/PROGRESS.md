# At Ease 进度文档

> 当前版本：0.1.0  
> 状态：MVP 可运行

## 已完成

### 产品基础

- [x] 产品定位、信息架构、设计令牌、交互规则文档化。
- [x] Tuist `AtEase` App target。
- [x] Workspace 注册。
- [x] App Icon 占位与 PrivacyInfo。
- [x] 启动屏颜色与首页画布对齐。

### 功能

- [x] 3 页引导，可跳过。
- [x] 5 级情绪签到。
- [x] 情绪映射推荐卡片。
- [x] 引导呼吸：4-7-8、Box、SOS。
- [x] 呼吸圆环动画与阶段文字。
- [x] 触觉辅助开关。
- [x] 1–60 分钟计时器。
- [x] SwiftData 情绪与练习记录。
- [x] 本周分钟数、35 天热力图、连续天数。
- [x] 设置页：触觉、默认时长、订阅状态占位。

### 技术

- [x] `BreathingPattern`、`BreathingPhase`、`BreathingEngine`。
- [x] `RecommendationEngine`。
- [x] `MindfulMinutesService`。
- [x] `AtEaseDesignTokens`。
- [x] 单元测试覆盖核心服务。

## 进行中

- [ ] Core Haptics 与呼吸阶段精确同步。
- [ ] 呼吸页背景 60 秒饱和度波动。

## 未开始

- [ ] HealthKit 正念分钟写入。
- [ ] Live Activity。
- [ ] 引导冥想播放器。
- [ ] 念头放下交互。
- [ ] 触摸身体扫描。
- [ ] 环境音混音。
- [ ] 订阅与付费墙。

## 近期优先级

1. 打通 Core Haptics 与呼吸节奏。
2. 实现 HealthKit 正念分钟写入。
3. 完成“念头放下”交互原型。
4. 定义内容分发与订阅分层 API。

## 验证命令

```bash
./scripts/generate.sh
./scripts/lint.sh
./scripts/test.sh
IOS_SIMULATOR_NAME="iPhone 17" ./scripts/test_apps.sh
./scripts/build_apps.sh
```
