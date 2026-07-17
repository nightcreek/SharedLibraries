# Euler Math Source Record

- Font name: `Euler Math`
- Role in eMathica: `handwrittenResult`
- Actual using repository: `SharedLibraries`
- Actual using module: `EMathicaFormulaDisplayKit`
- Actual using target: `EMathicaFormulaDisplayVendor`
- Upstream release page: `https://ctan.org/pkg/euler-math`
- Fixed version: `0.75`
- Fixed release date: `2026-02-18`
- Import date: `2026-07-10`
- License for the font file: SIL Open Font License 1.1
- Local usage mode: redistributed font file bundled inside the internal vendor target

## Imported file

- Upstream font file: `Euler-Math.otf`
- Local font file:
  - `EMathicaFormulaDisplayKit/Sources/EMathicaFormulaDisplayVendor/SwiftMath/mathFonts.bundle/Euler-Math.otf`

## License text source

- The CTAN package used for the font audit did not include a standalone OFL body file.
- `LICENSE.txt` in this repository is the authoritative SIL Open Font License 1.1 text stored locally to satisfy eMathica offline-notice requirements.
- This repository does not vendor Euler Math LaTeX support files, so LPPL records for `.sty` support code are intentionally out of scope for Phase 1.

## Local companion resource

- Local generated math-table plist:
  - `EMathicaFormulaDisplayKit/Sources/EMathicaFormulaDisplayVendor/SwiftMath/mathFonts.bundle/Euler-Math.plist`
- Generation source:
  - extracted from the imported font's OpenType MATH table
  - generation script used during audit and vendoring validation:
    - `SwiftMath/mathFonts.bundle/math_table_to_plist.py`

## Modification state

- Font file: Unmodified
- Generated plist: eMathica-generated companion resource, derived from the imported font metrics
