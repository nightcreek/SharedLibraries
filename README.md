# eMathica SharedLibraries

> eMathica 生态系统的共享 Swift Package 根目录。

`SharedLibraries/` 是当前真实物理 package root。
`Packages/shared/`、`Packages/emathica-only/`、`Packages/openmathink-only/` 只是未来 taxonomy 目标，不是当前事实。

当前这里包含 6 个 SwiftPM 包，其中 `EMathicaHomeFeature` 已经不是 skeleton，而是已承载 Home UI 的 eMathica-only package。

## 当前包含的包

| Package | 当前职责 | 分类 | 主要依赖 | 当前状态 |
|---------|---------|------|---------|---------|
| `EMathicaMathCore` | 数学引擎、CAS、求值、采样、坐标变换 | shared | 无 | Active |
| `EMathicaDocumentKit` | 文档模型、项目元数据、`RecentProject`、`ProjectStore` 协议 | shared | `EMathicaMathCore` | Active |
| `EMathicaThemeKit` | 颜色令牌、玻璃态组件、主题系统 | shared | 无 | Active |
| `EMathicaMathInputKit` | 数学键盘输入系统 | shared | 无 | Active |
| `EMathicaWorkspaceKit` | 工作区状态、命令、对象面板、输入与布局基础设施 | shared | `EMathicaMathCore`, `EMathicaDocumentKit`, `EMathicaThemeKit`, `EMathicaMathInputKit` | Active |
| `EMathicaHomeFeature` | 首页 UI、状态、布局、视觉外壳与 action bridge | eMathica-only | `EMathicaDocumentKit`, `EMathicaThemeKit`, `EMathicaWorkspaceKit` | Active |

## 当前位置

- eMathica Core 依赖 SharedLibraries。
- OpenMathInk Collector 也依赖 SharedLibraries。
- 当前共享包仍由单个物理目录承载，尚未迁移到最终 taxonomy。

## 读法

每个包目录都包含自己的 `README.md`、`Package.swift` 和 `Tests/`。
如果要了解某个包的细节，请进入对应包目录阅读本地 README。

## 下一步

- 保持当前 6 包的状态稳定
- 继续收敛 `EMathicaHomeFeature` 的公开 API
- 后续再讨论 `Packages/shared/`、`Packages/emathica-only/`、`Packages/openmathink-only/` 的最终目录化
