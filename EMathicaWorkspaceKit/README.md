# EMathicaWorkspaceKit

> 工作区基础设施包。依赖所有其他 4 个包。

## 职责

提供计算器工作区的完整基础设施：工作区视图/状态/布局、工具系统、对象面板、检查器、输入集成、命令系统、工具栏。

## 核心模块

| 模块 | 说明 |
|------|------|
| Commands/ | 模块和工作区命令处理 |
| History/ | 已删除对象历史 |
| Input/ | 草稿数学、公式编辑、键盘捕获 |
| Inspector/ | 几何检查器面板 |
| Keyboard/ | 公式编辑器和数学键盘视图 |
| ObjectPanel/ | 代数对象面板、几何依赖树 |
| Protocols/ | Canonicalizers、Navigation、Naming Services |
| Shared/ | Geometry formatters、Icons、Stubs |
| StructuredInput/ | 语义降级、诊断展示 |
| Toolbar/ | 浮动工具组 |
| Tools/ | 几何工具图标、动作、分组 |

## 核心类型

- `WorkspaceView` / `WorkspaceState` / `WorkspaceLayout` — 工作区核心
- `WorkspaceConfiguration` / `WorkspaceModuleProviding` — 配置与模块提供
- `CalculatorModuleType` — 计算器模块类型

## 依赖

- EMathicaMathCore
- EMathicaDocumentKit
- EMathicaMathInputKit
- EMathicaThemeKit

## 依赖此包

- eMathica Core App Target

## 设计约束

当前 WorkspaceKit 中 Plane 服务使用了 `PlaneGeometryStubs`（空解析器）代替真实的 `PlaneGeometryResolver`，导致 11 个测试失败。这是已知的 P1 问题。
