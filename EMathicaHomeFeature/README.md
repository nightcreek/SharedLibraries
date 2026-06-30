# EMathicaHomeFeature

> 当前真实 SwiftPM package。负责 eMathica 首页主链路。

## 当前物理路径

`SharedLibraries/EMathicaHomeFeature`

## Future taxonomy path

`Packages/emathica-only/EMathicaHomeFeature`

## 这个包负责什么

`EMathicaHomeFeature` 承载 eMathica 的首页 UI、首页状态、响应式布局、视觉外壳和 AppShell action bridge。
这不是 skeleton package，而是当前已经接入 app target 的 eMathica-only package。

## Public API

- `CoreHomeView`
- `CoreHomeState`
- `HomeFeatureActions`
- `HomeWorkspaceOpenRequest`
- `CoreHomeUIState`
- `GalleryFilter`
- `HomeModuleCatalog`
- `HomeModuleDescriptor`

## Internal modules

- `Bridge`
- `Components`
- `Models`
- `State`
- `Layout`
- `Hero`
- `Background`
- `Preview`

说明：`Preview/` 只负责首页缩略图与预览展示层，不是 `ProjectPreviewRenderer` 的归属。

## App side residue

下面这些职责仍留在 app 侧：

- `AppRootView` composition
- `AppNavigationState`
- `LocalProjectStore`
- `ProjectPreviewRenderer`
- `HomeMockProjectStore`

## 依赖

- `EMathicaDocumentKit`
- `EMathicaThemeKit`
- `EMathicaWorkspaceKit`

## 测试

```bash
cd SharedLibraries/EMathicaHomeFeature
swift test
```

## 当前状态

- package 自身可独立通过 `swift test`
- app target 已接入并可以构建
- 当前仍然保留 future taxonomy 作为目标，不创建最终 `Packages/` 目录
