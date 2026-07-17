# XITS Math Source Record

- Font name: `XITS Math`
- Role in eMathica: `standard`
- Actual using repository: `SharedLibraries`
- Actual using module: `EMathicaFormulaDisplayKit`
- Actual using target: `EMathicaFormulaDisplayVendor`
- Upstream repository: `https://github.com/aliftype/xits`
- Cross-check source: `https://ctan.org/texarchive/fonts/xits`
- Fixed version: `1.302`
- Fixed tag: `v1.302`
- Fixed commit: `81258e3318693741a50bd921d87c73d497103d37`
- Import date: `2026-07-10`
- License: SIL Open Font License 1.1
- Local usage mode: redistributed font file bundled inside the internal vendor target

## Imported file

- Upstream font file: `XITSMath-Regular.otf`
- Local font file:
  - `EMathicaFormulaDisplayKit/Sources/EMathicaFormulaDisplayVendor/SwiftMath/mathFonts.bundle/XITSMath-Regular.otf`

## Local companion resource

- Local generated math-table plist:
  - `EMathicaFormulaDisplayKit/Sources/EMathicaFormulaDisplayVendor/SwiftMath/mathFonts.bundle/XITSMath-Regular.plist`
- Generation source:
  - extracted from the imported font's OpenType MATH table
  - generation script used during audit and vendoring validation:
    - `SwiftMath/mathFonts.bundle/math_table_to_plist.py`

## Modification state

- Font file: Unmodified
- Generated plist: eMathica-generated companion resource, derived from the imported font metrics
