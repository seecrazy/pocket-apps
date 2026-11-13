# ADR 0005：TabStash 同步 Schema v1

日期：2026-11-14
状态：已采纳

## 背景

TabStash 的浏览器插件和 iOS 端需要交换标签页集合。直接共享 SwiftData 模型会造成跨平台耦合；iCloud 自动同步也无法立即验证字段兼容性。

## 决策

定义稳定 JSON Schema `PocketTabStash.v1`：

- `schemaVersion` 必须显式存在。
- 所有记录使用 UUID 作为稳定 ID。
- 时间字段统一 ISO 8601 UTC。
- URL 只保存字符串，导入时验证。
- 合并以 `lastModifiedAt` 最新者胜。

## 合并规则

1. 按 ID 匹配。
2. 不存在则插入。
3. 存在则比较 `lastModifiedAt`。
4. `collectionID` 缺失时放入“导入集合”。
5. 无效 URL 跳过。
6. `schemaVersion` 不支持时整体拒绝。

## 影响

- v1.1 使用本地 JSON 导入/导出验证数据格式。
- 后续 iCloud 只替换传输层，不改变 schema。
- 浏览器插件应导出该 schema；iOS 不依赖插件内部存储格式。
