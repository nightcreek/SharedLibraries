# EMathicaMathCore

> 数学引擎核心包。无外部依赖。

## 职责

提供所有基础数学类型和计算能力，是整个 eMathica 生态系统的数学基础。

## 包含的子模块

| 子模块 | 说明 |
|--------|------|
| AlgebraCore | 代数表达式系统 |
| CASCore | 计算机代数系统 |
| Coordinate | 坐标系与坐标变换 |
| EvaluationCore | 表达式求值引擎 |
| GraphCore | 图形采样与渲染数据 |
| SamplingCore | 曲线采样算法 |
| SemanticCore | 语义分析 |
| SpaceMathCore | 3D/空间数学 |
| Viewport | 视口管理 |

## 核心类型

- `GeometryDefinition` — 几何对象定义
- `MathExpression` — 数学表达式表示
- `MathObject` / `MathObjectType` — 数学对象模型
- `MathPoint` — 点类型
- `CoordinateSystem` — 坐标系
- `DependencyGraph` — 对象依赖图（DAG）
- `CanvasState` — 画布状态
- `MathStyle` — 数学样式

## 依赖

无内部依赖。

## 依赖此包

- EMathicaDocumentKit
- EMathicaWorkspaceKit
- eMathica Core App Target
