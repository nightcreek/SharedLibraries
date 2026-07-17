# SwiftMath Local Modifications

Imported from:

- `https://github.com/mgriebling/SwiftMath`
- commit `1d2c90827e9c3908269d810d055fb03b7da5fd53`

## Phase 1 local modifications

- Added repository-local provenance headers to upstream files that lacked usable source/license provenance:
  - `MathBundle/MTFontMathTableV2.swift`
  - `MathBundle/MTFontV2.swift`
  - `MathBundle/MathFont.swift`
  - `MathBundle/MathImage.swift`
  - `MathRender/MTMathImage.swift`
  - `MathRender/RWLock.swift`
- Adapted bundled font registration and defaults to the three eMathica-reviewed font roles:
  - `XITSMath-Regular.otf`
  - `Euler-Math.otf`
  - `Asana-Math.otf`
- Replaced the upstream broad font bundle with a reduced bundle containing only the three approved font assets and their generated math-table plist files.
- Adapted resource loading to Swift Package resources via the vendored `mathFonts.bundle`.
- Applied minimal Swift 6 compatibility adjustments for vendor-internal shared state and sendability checks.
- Added an eMathica-owned read-only adapter around SwiftMath so that public eMathica APIs do not expose SwiftMath types directly.

## Phase 1 non-goals

No local changes in this phase implement:

- placeholder editing behavior
- selection or hit testing
- editor-surface switching
- public exposure of SwiftMath implementation types

## Phase 2A-1 local modifications

- Added internal SwiftMath cursor atom support for the host-only `\cursor{}` token.
- Extended vendored parsing so `\cursor` and `\cursor{}` resolve to a dedicated cursor atom instead of failing parse.
- Added vendor-internal cursor layout extraction so SwiftMath image rendering can return cursor geometry without drawing a cursor.
- Kept cursor rendering disabled; this phase only exports layout anchors for later blink and navigation work.
