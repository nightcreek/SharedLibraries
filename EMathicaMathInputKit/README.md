# EMathicaMathInputKit

> 数学输入能力层，不是 UI surface。

## Current Reality

- 当前物理位置：`SharedLibraries/EMathicaMathInputKit`
- 当前 SwiftPM targets：
  - `EMathicaMathInputCore`
  - `EMathicaMathInputUI`
- `EMathicaMathInputCore` 是当前真实可用的核心能力层。
- `EMathicaMathInputUI` 目前只是占位 target，只有 `Placeholder.swift`，不能被当作已完成的真实 UI 实现。
- 当前核心层已经混合了：
  - AST / structure
  - editor state
  - input controller
  - cursor navigation
  - template definition
  - serialization
  - parser
  - renderer / preview protocol
- 当前没有真实的 SwiftUI 数学键盘 surface 落在这个 package 内。

## What MathInput Means Here

MathInput 在本项目中指“数学输入能力层”，不是“输入界面层”。

### MathInput 可以负责

- input session
- input actions
- character normalization
- paste LaTeX / source entry
- keyboard action vocabulary
- template insertion rules
- cursor movement semantics

### MathInput 不负责

- SwiftUI keyboard view
- visual key layout
- theme / color / glass style
- app-specific toolbar
- object panel UI
- canvas UI

## 包含的子目标

| Target | 说明 |
|--------|------|
| EMathicaMathInputCore | 当前真实可用核心（AST、输入状态、输入控制、光标导航、模板规则、序列化、解析、预览协议）。 |
| EMathicaMathInputUI | 占位 target，仅用于预留 UI 归属，不代表真实 SwiftUI 键盘已完成。 |

## Current Consumers

- `EMathicaWorkspaceKit`
- `eMathica`
- `OpenMathInkCollector`

## Boundary Warning

- 不应把未来所有 AST / preview / keyboard UI 继续塞进 `EMathicaMathInputCore`。
- `EMathicaMathInputUI` 目前只是 placeholder，不代表最终 UI 归属已经确定。
- `MathRenderer` / `LatexMathRenderer` 当前属于 preview / rendering boundary。
- `EditorCursorNavigator` / `TemplateDefinitionRegistry` 当前属于 keyboard logic，不等于 keyboard UI。
- 真实 UI surface 应放在 `EMathicaWorkspaceKit`、app feature，或者未来独立 presentation package 中。
- 长期边界说明见 [Documentation/Architecture/MathInputStructurePlan.md](../../Documentation/Architecture/MathInputStructurePlan.md)。

## Verification

- `swift test` in `SharedLibraries/EMathicaMathInputKit`
- 相关消费者编译：
  - `EMathicaWorkspaceKit`
  - `eMathica`
  - `OpenMathInkCollector`
