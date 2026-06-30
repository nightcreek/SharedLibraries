# EMathicaMathInputKit

> 数学键盘输入系统。

## 职责

提供结构化的数学公式输入体验，包含输入引擎、语法树解析、序列化和键盘 UI。

## 包含的子目标

| Target | 说明 |
|--------|------|
| EMathicaMathInputCore | 输入引擎核心（AST、引擎、序列化、状态）。无 UI 依赖。 |
| EMathicaMathInputUI | 输入 UI 层（编辑器视图、键盘视图、主题）。依赖 SwiftUI。 |

## 核心模块

- **AST/** — 抽象语法树
- **Engine/** — 输入引擎（解析、补全、导航）
- **Serialization/** — 序列化（LaTeX ↔ AST）
- **State/** — 输入状态管理
- **EditorView/** — 编辑器视图层
- **Keyboard/** — 数学键盘 UI
- **Theme/** — 输入主题

## 依赖

无内部依赖。

## 依赖此包

- EMathicaWorkspaceKit
- OpenMathInk Collector
