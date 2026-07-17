# EMathicaFormulaKeyboardKit

`EMathicaFormulaKeyboardKit` is a standalone SharedLibraries package reserved for the future Formula Keyboard Framework.

This package exists to establish package boundaries, target ownership, and dependency direction before any production keyboard migration begins.

## Package Purpose

The Formula Keyboard Framework is intended to become shared infrastructure for keyboard abstraction and presentation.

This package is responsible for:

- housing the future Formula Keyboard package structure
- separating keyboard concerns from app-specific mounting code
- preserving a clean dependency direction inside SharedLibraries

This package is not responsible for:

- math semantics
- formula rendering
- workspace hosting

## Products

### `EMathicaFormulaKeyboardCore`

Primitive infrastructure boundary for the future keyboard framework.

### `EMathicaFormulaKeyboardBuiltin`

Reserved for built-in keyboard definitions.

### `EMathicaFormulaKeyboardRendering`

Reserved for keyboard rendering preparation and integration boundaries.

### `EMathicaFormulaKeyboardSwiftUI`

Reserved for the presentation layer.

## Ownership

- MathInput: formula semantics
- FormulaDisplay: formula rendering
- Workspace: host coordination
- FormulaKeyboard: keyboard abstraction

## Dependency Diagram

```text
                 App
                  |
           WorkspaceKit
                  |
      FormulaKeyboardSwiftUI
                  |
      FormulaKeyboardRendering
                  |
       FormulaKeyboardBuiltin
                  |
        FormulaKeyboardCore
```

## Non-goals

At the current skeleton stage, this package does not implement:

- a keyboard
- a renderer
- a host
- math models
- an AST
- FormulaDisplay
- Accessibility

Accessibility boundaries may be reserved in future phases, but they are not implemented in this package today.

## Current Status

This package is a skeleton only.

It intentionally contains no business logic, no keyboard definitions, no action pipeline, and no SwiftUI keyboard views.
