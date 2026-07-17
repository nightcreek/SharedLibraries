# Architecture Decision Log

## ADR-0001 — Formula Keyboard is an independent SharedLibraries package

- Status: Accepted
- Date: 2026-07-17

### Context

The Formula Keyboard framework needs to live outside the app target so its ownership, dependency direction, and testability remain stable.

### Decision

Formula Keyboard is implemented as an independent SharedLibraries package: `EMathicaFormulaKeyboardKit`.

### Consequences

- The app consumes the framework instead of owning it.
- Keyboard primitives and future framework layers remain testable in isolation.

## ADR-0002 — Formula semantics belong to MathInput

- Status: Accepted
- Date: 2026-07-17

### Context

Formula semantics and AST truth must remain separate from keyboard abstraction.

### Decision

Formula semantics belong to MathInput rather than Formula Keyboard.

### Consequences

- Formula Keyboard does not define semantic truth.
- Keyboard actions must cross a command boundary before they affect MathInput.

## ADR-0003 — Formula rendering belongs to FormulaDisplay

- Status: Accepted
- Date: 2026-07-17

### Context

Formula rendering requires a dedicated rendering boundary that should not be reimplemented in keyboard infrastructure.

### Decision

Formula rendering belongs to FormulaDisplay rather than Formula Keyboard.

### Consequences

- Core primitives do not encode rendering behavior.
- Future keyboard rendering layers integrate with FormulaDisplay through explicit boundaries.

## ADR-0004 — Workspace acts only as host

- Status: Accepted
- Date: 2026-07-17

### Context

Workspace coordinates sessions, focus, and host behavior, but it should not become the framework itself.

### Decision

Workspace acts only as the host for Formula Keyboard integration.

### Consequences

- Workspace does not own keyboard core models.
- Host behavior remains separable from primitive definitions.

## ADR-0005 — Core owns only stable primitives

- Status: Accepted
- Date: 2026-07-17

### Context

The first Core layer needs to remain dependency-free, serializable, and stable before higher-level keyboard models exist.

### Decision

`EMathicaFormulaKeyboardCore` owns only stable primitive value types and primitive marker protocols.

### Consequences

- Core depends only on Foundation.
- Layout, rendering, actions, host behavior, and keyboard definitions are deferred to later phases.
