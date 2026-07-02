# EMathicaMathInputKit Architecture

Status: current package boundary document  
Scope: EMathicaMathInputKit package and its direct consumers  
Last updated for: M4B public protocol design alignment

## 1. Scope

`EMathicaMathInputKit` defines the reusable math-input core for package and app consumers across the eMathica workspace.

The current package still exposes:

- `EMathicaMathInputCore`
- `EMathicaMathInputUI`
- aggregate product `EMathicaMathInputKit`

Current reality:

- `EMathicaMathInputCore` is the real, production-used capability layer.
- `EMathicaMathInputUI` is still a placeholder target and is not a complete input UI surface.
- Core-only consumers should depend on `EMathicaMathInputCore`, not on the aggregate product by default.

This document records the first-version public protocol boundary for MathInput. It does not claim that every named protocol concept already exists as a concrete Swift API.

## 2. Public Input / Output Protocol

The first-version MathInput boundary is built around a structured editing model.

MathInput:

- edits internal eMathica AST
- does not directly edit LaTeX strings
- does not render formulas visually
- does not own CAS
- does not own graph sampling
- does not own object-panel display
- does not own FormulaRender layout

LaTeX remains important, but only for:

- import
- export
- copy
- compatibility
- debugging
- fallback

The intended protocol chain is:

- `input(...)` / `latexin(...)`
- internal eMathica AST
- `formula()`
- `latexout()`
- `displayout()`

Protocol meaning:

- `formula()` returns structured `MathFormula`
- `latexout()` returns clean LaTeX
- `displayout()` returns `FormulaDisplayMarkup` for FormulaRender and other lightweight display consumers

Important boundary:

- `displayout()` is not the internal editing state
- MathInput still edits internal AST
- `displayout()` is only a display projection of AST plus cursor / placeholder state

## 3. Textual input() Protocol

The first-version public input surface has two entry kinds:

- `input(token)`
- `latexin(latex)`

### input(token)

`input(...)` is the action-sequence protocol for incremental editing.

It is the intended entry for:

- software keyboard input
- hardware keyboard input
- ML handwriting recognition output
- OCR tokenized recognition output
- future structured math-input sources

All of these should normalize into MathInput tokens before entering the internal AST editing pipeline.

### latexin(latex)

`latexin(...)` is the full-expression import protocol.

It is intended for:

- pasted LaTeX
- imported LaTeX
- compatibility flows
- fallback ingestion of externally produced formulas

`latexin(...)` is not LaTeX string editing. It should parse supported LaTeX into `MathFormula` / internal eMathica AST, after which editing continues on AST.

### Token Text Form

The first-version textual token form is:

- `input(type:value)`

Supported token kinds:

- `char`
- `number`
- `op`
- `function`
- `template`
- `control`

Examples:

- `input(char:x)`
- `input(number:2)`
- `input(op:+)`
- `input(function:sin)`
- `input(template:fraction)`
- `input(control:nextSlot)`

First-version control values:

- `moveLeft`
- `moveRight`
- `moveUp`
- `moveDown`
- `nextSlot`
- `previousSlot`
- `deleteBackward`
- `deleteForward`
- `submit`
- `cancel`
- `undo`
- `redo`

Protocol notes:

- `input(...)` is the incremental action protocol
- `latexin(...)` is the full-expression import protocol
- `latexin(...)` should not be folded into `input(...)`
- ML / OCR / handwriting systems can emit `input(...)` sequences
- if a model recognizes a complete formula directly, it may call `latexin(...)`
- the preferred editing-oriented path is still `input(...)`, because it maps more naturally onto cursor movement and undo / redo

Example protocol sequence for `x^2+1`:

- `input(char:x)`
- `input(template:superscript)`
- `input(number:2)`
- `input(control:moveRight)`
- `input(op:+)`
- `input(number:1)`

Example protocol sequence for a fraction `x/2`:

- `input(template:fraction)`
- `input(char:x)`
- `input(control:nextSlot)`
- `input(number:2)`

Example protocol sequence for `sin(x)`:

- `input(function:sin)`
- `input(char:x)`
- `input(control:nextSlot)`

## 4. MathFormula Minimal AST

The first-version shared structured output is `MathFormula`.

`MathFormula` is the intended formula boundary shared across:

- MathInput
- FormulaRender
- object panel display
- canvas display
- notebook-like formula storage

It should not be named `MathInputFormula`, and FormulaRender should not depend on `MathInputSession`.

### Minimal Node Set

| Node kind | Meaning |
|---|---|
| `sequence` | A sequence of formula elements. The root node is usually a sequence. |
| `symbol` | A variable or symbolic token such as `x`, `y`, `a`, `theta`. |
| `number` | A numeric token such as `1`, `2`, or `3.14`. |
| `operatorSymbol` | An operator or relation token such as `+`, `-`, `=`, or `<=`. |
| `function` | A function call such as `sin(x)`, `cos(x)`, `ln(x)`, or `log(x)`. |
| `template` | A structured template such as fraction, square root, superscript, subscript, parentheses, or absolute value. |
| `rawLatex` | A fallback node for LaTeX that cannot yet be structurally parsed or edited deeply. |

### Function Nodes

The first version treats functions as independent nodes rather than encoding them as `symbol("sin")` plus parentheses.

This keeps:

- semantic intent clearer
- export behavior clearer
- future computation alignment cleaner

### rawLatex Fallback

`rawLatex` is a compatibility strategy, not the primary editing path.

It may be used for:

- unsupported imported LaTeX
- partial compatibility preservation
- fallback display or save flows

It does not guarantee deep structured editing.

### First-Version Template Kinds

The initial core template set is:

- `fraction`
- `sqrt`
- `superscript`
- `subscript`
- `parentheses`
- `absoluteValue`

### Deferred Template Kinds

The following are intentionally deferred from the first core AST set:

- `piecewise`
- `parametric2D`
- `matrix`
- `integral`
- `sum`
- `limit`
- `cases`
- aligned equations

These are deferred because they are either:

- closer to Plane / Workspace semantics
- more complex in editing behavior
- more complex in rendering behavior
- better introduced after the basic formula input / display / import / export loop is stable

## 5. Template Field Order

The first version uses fixed field order rather than a more complex public field-role protocol.

Field order is part of the protocol.

| Template kind | Fields |
|---|---|
| `fraction` | `[numerator, denominator]` |
| `sqrt` | `[radicand]` |
| `superscript` | `[base, exponent]` |
| `subscript` | `[base, subscript]` |
| `parentheses` | `[content]` |
| `absoluteValue` | `[content]` |

Implications:

- field order is part of the first-version contract
- `latexout()` can interpret structure from template kind plus ordered fields
- `displayout()` can interpret structure from template kind plus ordered fields
- FormulaRender can consume the same order without depending on MathInput session state

This is intentionally simpler than exposing a richer public field-role system at the first stage.

If more explicit metadata becomes necessary later, it should extend rather than break this order-based contract.

Example structure for `x^2`:

- `template: superscript`
- `fields:`
- `base -> symbol x`
- `exponent -> number 2`

Example structure for `\frac{x}{2}`:

- `template: fraction`
- `fields:`
- `numerator -> symbol x`
- `denominator -> number 2`

## 6. FormulaDisplayMarkup / displayout()

`displayout()` returns `FormulaDisplayMarkup`.

`FormulaDisplayMarkup` is the first-version lightweight display protocol between MathInput and FormulaRender.

Its role is:

- lightweight display projection
- real-time formula display
- cursor-aware display
- placeholder-aware display

It is not:

- normal LaTeX
- the internal editing state
- a substitute for the AST

MathInput still edits internal AST. `FormulaDisplayMarkup` is only the projected display form.

### First-Version Display Subset

The intended first display subset includes:

- symbol
- number
- operator
- function
- `\\frac{}{}`
- `\\sqrt{}`
- `^{}`
- `_{}`
- `(...)`
- `|...|`
- `\\cursor{}`
- `\\placeholder{}`
- `□`

Protocol notes:

- `\\cursor{}` marks the current cursor position
- `\\placeholder{}` marks an empty slot
- `□` is a short form for `\\placeholder{}`
- the formal protocol prefers `\\placeholder{}`

Example:

- `\\frac{x}{\\cursor{}\\placeholder{}}`

Short form:

- `\\frac{x}{\\cursor{}□}`

These are display-equivalent forms.

### Example Projection

For this edit sequence:

- `input(template:fraction)`
- `input(char:x)`
- `input(control:nextSlot)`

The intended outputs are:

`formula()`:

- `template fraction`
- `fields:`
- `numerator -> sequence [symbol x]`
- `denominator -> empty sequence`

`latexout()`:

- `\\frac{x}{}`

`displayout()`:

- `\\frac{x}{\\cursor{}\\placeholder{}}`

or, as a short form:

- `\\frac{x}{\\cursor{}□}`

### Display Boundary

`displayout()` should be understood as:

- AST projection for display
- cursor / placeholder aware
- intended for FormulaRender consumption

`latexout()` should remain:

- clean export LaTeX
- cursor-free
- placeholder-free unless an explicit fallback policy says otherwise

## 7. LaTeX Boundary

LaTeX is intentionally bounded.

LaTeX is used for:

- `latexin()`
- `latexout()`
- copy
- export
- compatibility
- debugging
- fallback

LaTeX is not used as the primary protocol for:

- internal editing structure
- true cursor state
- undo / redo state
- the long-term sole display contract for FormulaRender

### First-Version latexin() Support

The intended first supported import range includes:

- `x`
- `123`
- `x+1`
- `x^2`
- `x_1`
- `\\frac{x}{2}`
- `\\sqrt{x}`
- `\\sin(x)`
- `\\cos(x)`
- `\\tan(x)`
- `\\ln(x)`
- `\\log(x)`
- `(x+1)`
- `|x|`

More complex LaTeX may fall back into `rawLatex`.

When `rawLatex` is used:

- structural editability is not guaranteed
- compatibility is preserved as a fallback
- it should not be treated as the preferred long-term editing path

## 8. Undo / Redo Boundary

First-version undo / redo should operate on AST snapshots, not on inverse-operation math and not on LaTeX strings.

Each meaningful edit step should preserve enough session state to restore:

- current `MathFormula` / internal AST
- current cursor or internal edit position
- current selection state if selection is present

Undo behavior:

- restore the previous snapshot

Redo behavior:

- restore a snapshot from the redo stack

This means:

- undo / redo does not operate on raw LaTeX text
- undo / redo does not operate on `displayout()` strings
- undo / redo operates on AST-based editing state
- `latexout()` and `displayout()` are recomputed projections after restoration

## 9. FormulaRender Decoupling

FormulaRender should not depend on:

- `MathInputSession`
- `InputController`
- `WorkspaceState`
- edit-history state
- keyboard state

The first-version FormulaRender boundary should consume:

- `FormulaDisplayMarkup`

In a later stage, FormulaRender may also consume:

- `MathFormula`

But FormulaRender should not become reverse-bound to MathInput session internals.

Intended relationship:

MathInput:

- edits internal AST
- exports `displayout()`
- exports `latexout()`
- exports `formula()`

FormulaRender:

- parses `FormulaDisplayMarkup`
- produces layout, render plan, and cursor geometry
- leaves final drawing to platform UI layers

Object panel / canvas / notebook style consumers:

- may store `MathFormula`
- may use `displayout()` for lightweight display
- do not need to depend on `MathInputSession`

This keeps rendering reusable and keeps editing state private to MathInput.

## 10. First Version Decisions

The first-version design decisions in this document are:

- MathInput edits internal AST, not LaTeX strings
- `input(...)` and `latexin(...)` are distinct protocol surfaces
- `formula()`, `latexout()`, and `displayout()` are distinct output surfaces
- `displayout()` is a display projection, not editor state
- `MathFormula` is the long-lived structured formula boundary
- `FormulaDisplayMarkup` is the lightweight display boundary
- field order is part of the first-version template contract
- LaTeX remains important, but bounded
- undo / redo belongs to AST editing state
- FormulaRender should stay decoupled from MathInput session internals

These decisions define boundary intent for future implementation work, but they do not imply that every protocol name in this document already exists as a finalized runtime API.

## Related Documents

- [README](README.md)
