# SwiftMath Source Record

## Component identity

- Project: `SwiftMath`
- Upstream repository: `https://github.com/mgriebling/SwiftMath`
- Imported commit: `1d2c90827e9c3908269d810d055fb03b7da5fd53`
- Import date: `2026-07-10`
- License: MIT
- Local usage:
  - repository: `SharedLibraries`
  - module: `EMathicaFormulaDisplayKit`
  - target: `EMathicaFormulaDisplayVendor`
  - use mode: vendored source code, locally adapted for package resource loading and Swift 6 build compatibility

## Upstream file roots used

- `Sources/SwiftMath/MathBundle/`
- `Sources/SwiftMath/MathRender/`
- `Sources/SwiftMath/MathRender/Tokenization/`

## Excluded upstream content

The following upstream content was intentionally not vendored into this repository for Phase 1:

- demo and example surfaces
- upstream package wrapper and product naming
- upstream test target in full
- upstream bundled fonts other than the three eMathica-reviewed font roles

## Local integration boundary

- Vendor files live under:
  - `EMathicaFormulaDisplayKit/Sources/EMathicaFormulaDisplayVendor/SwiftMath/`
- eMathica-owned adapter files live under:
  - `EMathicaFormulaDisplayKit/Sources/EMathicaFormulaDisplayVendor/`
  - `EMathicaFormulaDisplayKit/Sources/EMathicaFormulaDisplayCore/`
  - `EMathicaFormulaDisplayKit/Sources/EMathicaFormulaDisplaySwiftUI/`

## Derivation notes

- SwiftMath itself preserves derivation statements from `iosMath` in many file headers.
- eMathica keeps those upstream derivation statements intact where they already exist.
- Files that lacked sufficient provenance headers received repository-local provenance headers pointing back to the fixed SwiftMath commit and to this repository's local notice files.
