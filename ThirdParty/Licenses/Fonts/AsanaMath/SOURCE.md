# Asana Math Source Record

- Font name: `Asana Math`
- Role in eMathica: `decorative`
- Actual using repository: `SharedLibraries`
- Actual using module: `EMathicaFormulaDisplayKit`
- Actual using target: `EMathicaFormulaDisplayVendor`
- Upstream release page: `https://ctan.org/pkg/asana-math`
- Fixed version: `000.962`
- Fixed release date: `2025-11-19`
- Import date: `2026-07-10`
- License: SIL Open Font License 1.1
- Local usage mode: redistributed font file bundled inside the internal vendor target

## Imported file

- Upstream font file: `Asana-Math.otf`
- Local font file:
  - `EMathicaFormulaDisplayKit/Sources/EMathicaFormulaDisplayVendor/SwiftMath/mathFonts.bundle/Asana-Math.otf`

## License text source

- The upstream CTAN package embeds the OFL 1.1 text inside its `README`.
- `LICENSE.txt` in this repository preserves that upstream license text body as a standalone file for offline inspection.

## Local companion resource

- Local generated math-table plist:
  - `EMathicaFormulaDisplayKit/Sources/EMathicaFormulaDisplayVendor/SwiftMath/mathFonts.bundle/Asana-Math.plist`
- Generation source:
  - extracted from the imported font's OpenType MATH table
  - generation script used during audit and vendoring validation:
    - `SwiftMath/mathFonts.bundle/math_table_to_plist.py`

## Modification state

- Font file: Unmodified
- Generated plist: eMathica-generated companion resource, derived from the imported font metrics
