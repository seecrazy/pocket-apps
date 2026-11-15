# At Ease 声音架构

## 当前实现

At Ease 的音频分成三类：

1. **自然音景**：仅自由计时器使用，来自 Wikimedia Commons 的免费音频素材。
2. **引导语音**：优先播放 Tencent Cloud TTS 生成本地 MP3；若文件缺失，回退到 iOS 中文语音。
3. **冥想音乐**：仅引导冥想和呼吸练习使用，来自 Wikimedia Commons 的免费音乐素材。
3. **远程订阅音频**：从 HTTPS CDN 下载后本地播放。

### 自然音景来源

自然音仅用于自由计时器，不在引导冥想或呼吸练习中出现。当前 6 种自然音已从 Wikimedia Commons 下载并转换为 iOS 兼容的 M4A / AAC 格式：

| 音景 | 原始素材 | 作者 | 许可证 |
|---|---|---|---|
| 雨声 | [Sound of rain.ogg](https://commons.wikimedia.org/wiki/File:Sound_of_rain.ogg) | Effib | CC BY-SA 3.0 |
| 流水 | [Sound Effects - The sound of a small stream.ogg](https://commons.wikimedia.org/wiki/File:Sound_Effects_-_The_sound_of_a_small_stream.ogg) | Amada44 | CC BY-SA 4.0 |
| 虫鸣 | [Cicada sound.ogg](https://commons.wikimedia.org/wiki/File:Cicada_sound.ogg) | Schwiki | CC BY-SA 4.0 |
| 海浪 | [Oceanwavescrushing.ogg](https://commons.wikimedia.org/wiki/File:Oceanwavescrushing.ogg) | Luftrum | CC BY 3.0 |
| 森林 | [Forest ambience 2 (Gravity Sound).wav](https://commons.wikimedia.org/wiki/File:Forest_ambience_2_(Gravity_Sound).wav) | Gravity Sound | CC BY 4.0 |
| 风声 | [Wind rustling (Gravity Sound).mp3](https://commons.wikimedia.org/wiki/File:Wind_rustling_(Gravity_Sound).mp3) | Gravity Sound | CC BY 4.0 |

完整版权信息在 `Apps/AtEase/Resources/Sounds/SOUNDS-ATTRIBUTIONS.md`。

### 冥想音乐来源

引导冥想和呼吸练习使用独立的冥想音乐，不再使用自然音。当前使用 Wikimedia Commons 上的免费音乐素材：

| 音乐 | 原始素材 | 作者 | 许可证 |
|---|---|---|---|
| 平静铺底 | [Placid Ambient by MusicLFiles.ogg](https://commons.wikimedia.org/wiki/File:Placid_Ambient_by_MusicLFiles.ogg) | MusicLFiles | CC BY 4.0 |
| 温润氛围 | [Spiritual Ambient by MusicLFiles.ogg](https://commons.wikimedia.org/wiki/File:Spiritual_Ambient_by_MusicLFiles.ogg) | MusicLFiles | CC BY 4.0 |

完整版权信息在 `Apps/AtEase/Resources/Music/MUSIC-ATTRIBUTIONS.md`。

### 引导语音

此前人声使用 iOS `AVSpeechSynthesizer`。当前实现改为：

1. 优先查找 Tencent Cloud TTS 预生成的 MP3。
2. 找到文件后使用 `AVAudioPlayer` 播放。
3. 找不到文件时回退到 iOS 中文语音，避免练习被网络或配置问题阻断。

### Tencent TTS API 对齐

生成脚本已按 Tencent Cloud TTS API `v2019-08-23` 对齐：

| 场景 | Action | 说明 |
|---|---|---|
| 短文本实时合成 | `TextToVoice` | 文本上限按 140 个中文字符做安全限制 |
| 长文本合成 | `CreateTtsTask` + `DescribeTtsTaskStatus` | 创建任务后轮询 `ResultUrl` 并下载 |

关键参数：

```text
PrimaryLanguage: 1 = 中文，2 = 英文
SampleRate: 8000 / 16000 / 24000
Codec: mp3 / wav / pcm
Speed: -2 至 6
Volume: -10 至 10
ModelType: 1 = 默认模型
SessionId: TextToVoice 使用 UUID 防止重复
```

注意：

- `TextToVoice` 不存在 `Language` 参数，正确参数名是 `PrimaryLanguage`。
- `Volume` 不使用 `[0, 10]` 旧假设，正确范围是 `[-10, 10]`。
- 短文本不调用不存在的 `TextToSpeech` action。
- 长文本先调用 `CreateTtsTask`，再轮询 `DescribeTtsTaskStatus`。

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

可以先检查将生成的资源：

```bash
python3 scripts/generate_at_ease_tts.py --dry-run
```

## 音频边界

1. 自然音只允许出现在自由计时器。
2. 引导冥想与呼吸练习只使用冥想音乐。
3. 自然音卡片默认收起，展开时内部滚动，不覆盖操作按钮。
4. 新增自然音时更新 `AmbientSound`、`AmbientSoundLevel`、`AmbientSoundMixer` 与 `AmbientSoundCard`。
5. 新增冥想音乐时更新 `MeditationMusic`、`MeditationMusicMixer` 与 `MeditationMusicCard`。

### 音量约束

- 音量范围 0–1。
- 默认引导音量为 0.22。
- 不使用爆音、高频刺激或突然变化。
- 每个缓冲区做 80ms 循环交叉淡化。
- 测试保证所有样本有限、有能量且未削波。
