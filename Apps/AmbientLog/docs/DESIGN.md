# AmbientLog 设计文档

> 状态：已采纳
> 版本：1.2.0
> 更新时间：2026-11-14

## 1. 产品定位

AmbientLog 是本机环境音记录工具，不后台录音、不社交、不上传音频。它用分类和搜索帮用户找回“那家咖啡店的下午”或“地铁口的傍晚”。

**副标题**：环境音记录仪
**Bundle ID**：`com.pocketapps.ambientlog`

### 目标

- 用一个清晰的核心动作解决真实场景。
- 数据只保存在本机，隐私边界在首启说明中说清楚。
- UI 能表达空态、进行中、完成、失败和恢复状态。
- 单元测试覆盖核心状态机和过滤器。
- 不把业务逻辑泄漏到共享 Package。

### 非目标

- 不做云后端。
- 不做账号体系和跨设备自动同步。
- 不引入和核心体验无关的复杂权限。
- 不做广告、推荐或数据采集。

## 2. 用户与真实场景

用户在咖啡馆选择“城市”分类，录下 90 秒环境声。电话进来时录音自动停止并保留文件；回到列表可播放或重命名，未来按分类找回。

### 典型流程

1. 首启说明 → 选择分类 → 请求麦克风权限 → 录音 → 停止保存。
2. 列表搜索与分类过滤 → 播放 / 重命名 / 删除。
3. 系统中断自动停止，保留已生成文件。

## 3. 信息架构

三栏 Tab：**记录**、**收藏**、**设置**。记录页负责分类与录音；收藏页负责搜索和回放。

## 4. 数据模型

- `AmbientRecordingModel`：记录 ID、标题、分类、开始时间、时长、文件路径。
- `AmbientRecordingCategory`：全部、自然、城市、居家、夜晚。

## 5. 关键交互与状态

- 录音：`idle → permissionRequired → recording → saved`。
- 播放：`saved → playing / stopped`。
- 删除：确认后同时删除音频文件与 SwiftData 记录。

## 6. 错误与边界处理

- **麦克风权限拒绝：展示设置跳转，不伪装录音。**
- **音频文件丢失或损坏：播放失败给出明确错误。**
- **误删：删除文件和记录前必须确认。**

## 7. 隐私与数据边界

- 录音文件保存在 App 沙盒 Documents，元数据保存在本机 SwiftData。
- 仅在用户主动开始录音时访问麦克风。
- 不后台录音，不上传音频。

## 8. 测试策略

- `AmbientRecordingLibraryTests`：搜索与分类过滤。
- `AudioRecorderServiceTests`：中断描述。

## 9. 发布准备

- [x] 独立 Bundle ID 与版本号。
- [x] 独立 App Icon。
- [x] `PrivacyInfo.xcprivacy`。
- [x] App Store metadata 文案。
- [x] 单元测试通过。
- [x] 本机构建通过。
- [ ] App Store 截图。
- [ ] App Store Connect App 记录。
- [ ] 签名、证书和 provisioning profile。

## 10. Roadmap

- 波形可视化。
- 音频备注与标签。
- 后台录音边界与耗电策略。

## 参考

- [App README](../README.md)
- [进度文档](PROGRESS.md)
- [仓库设计](../../../docs/DESIGN.md)
- [隐私说明](../../../PRIVACY.md)
