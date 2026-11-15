# At Ease 声音架构

## 当前实现

At Ease 的音频分成三类：

1. **自然音景**：App 内 DSP 实时合成。
2. **引导语音**：优先播放 Tencent Cloud TTS 生成本地 MP3；若文件缺失，回退到 iOS 中文语音。
3. **远程订阅音频**：从 HTTPS CDN 下载后本地播放。

### 自然音景来源

此前版本的雨声、流水声、虫鸣是最简单的正弦波加白噪声原型。v1.1 已替换为基于粉噪、棕噪、包络、随机雨滴、潮汐起伏和鸟鸣层的 DSP 合成模型。

当前 6 种免费音景：

| 音景 | 合成模型 | 作用 |
|---|---|---|
| 雨声 | 粉噪 + 雨滴脉冲 | 安全感、情绪回落 |
| 流水 | 粉噪 + 水流调制 | 稳定、专注 |
| 虫鸣 | 周期鸣叫 + 夜间低噪 | 夜间放松 |
| 海浪 | 棕噪 + 11 秒潮汐包络 | 睡前呼吸节奏 |
| 森林 | 树冠粉噪 + 稀疏鸟鸣 | 白天练习、降低压迫感 |
| 风声 | 棕噪 + 14 秒阵风包络 | 低侵入环境音 |

选择本地合成而非直接分发录音素材，是为了避免第三方素材授权、Content ID 和二次分发风险。所有音景可离线使用。

### 引导语音

此前人声使用 iOS `AVSpeechSynthesizer`。当前实现改为：

1. 优先查找 Tencent Cloud TTS 预生成的 MP3。
2. 找到文件后使用 `AVAudioPlayer` 播放。
3. 找不到文件时回退到 iOS 中文语音，避免练习被网络或配置问题阻断。

Tencent TTS 音频文件命名：

```text
voice-<contentID>-<stepID>.mp3
voice-breath-inhale.mp3
voice-breath-hold.mp3
voice-breath-exhale.mp3
voice-timer-start.mp3
voice-timer-finish.mp3
```

生成脚本：

```bash
python3 scripts/generate_at_ease_tts.py \
  --content-catalog Apps/AtEase/Resources/Content/ContentCatalog.json \
  --output-dir Apps/AtEase/Resources/Voice
```

脚本会从以下变量读取凭据：

```text
TENCENT_SECRET_ID / TENCENT_SECRET_KEY
TENCENT_TTS_SECRET_ID / TENCENT_TTS_SECRET_KEY
TENCENT_CLOUD_SECRET_ID / TENCENT_CLOUD_SECRET_KEY
```

也会尝试从 `~/.zshrc` 的 `export` 行解析。凭据只用于本地脚本，不会写入仓库或 App Bundle。

## 添加新的自然音景

新增音景需要同时更新：

1. `AmbientSound`
2. `AmbientSoundLevel`
3. `AmbientBufferFactory`
4. `AmbientSoundCard`

### 音量约束

- 音量范围 0–1。
- 默认引导音量为 0.22。
- 不使用爆音、高频刺激或突然变化。
- 每个缓冲区做 80ms 循环交叉淡化。
- 测试保证所有样本有限、有能量且未削波。
