# EMathicaDocumentKit

> 当前真实 SwiftPM package。负责 eMathica 的文档模型与持久化协议层。

## 职责

- 定义 `EMathicaDocument`
- 定义 `ProjectMetadata`
- 定义 `RecentProject`
- 定义 `ProjectStore` / `ProjectStoreError`
- 定义文档命令与补丁类型
- 定义包编解码与文件布局

## 不负责

- 不负责 `LocalProjectStore` 这种 concrete implementation
- 不负责 `ProjectPreviewRenderer`
- 不负责 Home UI 的布局与展示

## 依赖

- `EMathicaMathCore`

## 被谁使用

- `eMathica` app target
- `EMathicaHomeFeature`
- `EMathicaWorkspaceKit`

## 当前状态

- 当前是 active 的 shared package
- 是 HomeFeature 与 App 共享的数据边界之一
