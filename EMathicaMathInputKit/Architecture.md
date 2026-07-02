# EMathicaMathInputKit Architecture

Status: current package boundary document  
Scope: EMathicaMathInputKit package and its direct consumers  
Last updated for: W2A consumer wiring cleanup

## 1. Purpose

`EMathicaMathInputKit` exists to provide the reusable math-input core used by package and app consumers across the workspace.

Its current job is to provide:

- structured math editing state
- math input session and action handling
- cursor movement and template insertion semantics
- source / LaTeX / compute-facing projections needed by consumers

It is not the home for full app-specific input UI.

## 2. Current Reality

The package currently exposes two targets:

- `EMathicaMathInputCore`
- `EMathicaMathInputUI`

Current reality:

- `EMathicaMathInputCore` is the real, production-used capability layer.
- `EMathicaMathInputUI` is still a placeholder target and should not be treated as a complete UI surface.
- The aggregate product `EMathicaMathInputKit` still exists, but core-only consumers should not use it by default.

After W2A consumer wiring cleanup:

- `EMathicaWorkspaceKit` depends explicitly on `EMathicaMathInputCore`
- `eMathica` app and `eMathicaTests` depend explicitly on `EMathicaMathInputCore`
- `OpenMathInkCollector` also consumes `EMathicaMathInputCore`
- `EMathicaMathInputUI` remains present in the package manifest, but is no longer pulled into the default app consumer build graph

The core target currently mixes several concerns that are still intentionally documented as one package boundary:

- AST / structure
- editor state
- input control
- cursor navigation
- template rules
- serialization / parsing
- preview-facing rendering protocols

## 3. Package Products

| Product | Target(s) | Current status | Intended consumer | Notes |
|---|---|---|---|---|
| `EMathicaMathInputCore` | `EMathicaMathInputCore` | Active | Core-only package and app consumers | Preferred product for current consumers |
| `EMathicaMathInputUI` | `EMathicaMathInputUI` | Placeholder | Future presentation-specific consumers only | Not a completed UI implementation |
| `EMathicaMathInputKit` | `EMathicaMathInputCore`, `EMathicaMathInputUI` | Transitional aggregate | Special cases that intentionally need both targets | Not recommended as the default consumer entry |

## 4. Target Boundary

### EMathicaMathInputCore

`EMathicaMathInputCore` should continue to own:

- math editor AST and structure contracts
- editor state and session facade
- keyboard action vocabulary
- template insertion and cursor navigation rules
- serialization, parsing, and conversion primitives required by consumers
- preview-facing rendering protocols and lightweight core rendering adapters

### EMathicaMathInputUI

`EMathicaMathInputUI` should not currently be described as a real keyboard or input surface.

At the moment it should be understood as:

- a placeholder target
- a possible future home for presentation-facing input UI
- not part of the default dependency surface for core-only consumers

### Aggregate Product

The aggregate product `EMathicaMathInputKit` remains valid as a package product, but it is intentionally wider than most consumers need.

That means:

- core-only consumers should prefer `EMathicaMathInputCore`
- the aggregate product should not be the default wiring choice
- future UI work can decide later whether the aggregate product remains useful, is renamed, or is narrowed

## 5. Consumer Wiring Policy

Current wiring policy:

- `EMathicaWorkspaceKit` should depend on `EMathicaMathInputCore`
- `eMathica` app and tests should depend on `EMathicaMathInputCore` unless they truly require a future presentation target
- `OpenMathInkCollector` should continue depending on `EMathicaMathInputCore`
- core-only consumers should avoid depending on the aggregate `EMathicaMathInputKit` product

This keeps placeholder UI code out of the default build graph and makes consumer intent explicit.

## 6. MathInput / Structure / Preview Boundary

### MathInput

MathInput in this package means the math-input capability layer, not the full visual input surface.

It owns:

- input session semantics
- input actions
- character normalization
- source / LaTeX entry handling
- template insertion rules
- cursor movement semantics

### Structure

AST and structured formula representation should remain free to evolve as their own boundary.

That includes concepts such as:

- `MathNode`
- `TemplateNode`
- `TemplateKind`
- `FieldID`
- editor-state-adjacent structural contracts

The long-term direction is to keep structure understandable as a reusable boundary, rather than letting it disappear inside UI code.

### Preview / Display

Formula preview should not be reduced to a throwaway lightweight UI detail if it is expected to support:

- input-area preview
- object-panel formula display
- canvas formula display
- cross-consumer rendering reuse

If preview grows into a full reusable rendering system, it should evolve as an explicit display/render boundary rather than being hidden inside placeholder UI.

### Keyboard Logic vs Presentation

Keyboard logic and visual presentation should stay separate.

Keyboard logic includes:

- action vocabulary
- template insertion rules
- arrow navigation
- ordering and movement semantics

Presentation includes:

- SwiftUI keyboard views
- visual key layout
- themes and styling
- app-specific toolbars and interaction surfaces

## 7. Future Split Direction

The following items are future planning directions, not current package reality:

- `EMathicaMathStructure`
- `EMathicaFormulaDisplay`
- a more explicit future presentation target for math input UI
- possible target or package splits between structure, input core, keyboard logic, and display

These names and splits should be treated as planning only until they are actually introduced.

## 8. Non-goals

This package should not:

- implement a full CAS inside MathInput core
- absorb app-specific UI or toolbar logic
- reintroduce legacy Collector compatibility shims into `EMathicaMathInputCore`
- pretend a placeholder UI target is already the real presentation layer
- make the aggregate product the default entry point for core-only consumers

## 9. Related Documents

- [README](README.md)
