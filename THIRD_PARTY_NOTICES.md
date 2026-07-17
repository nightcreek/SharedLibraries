# Third-Party Notices

This repository vendors and redistributes a small set of reviewed third-party source code and font assets for `EMathicaFormulaDisplayKit`.

This file is the repository-level entry point required by eMathica third-party governance. It does not replace the component-level records under `ThirdParty/`.

## Active third-party components

| Component | Type | Upstream | Fixed version | License | Used by | Local records |
| --- | --- | --- | --- | --- | --- | --- |
| SwiftMath | Source code | `https://github.com/mgriebling/SwiftMath` | commit `1d2c90827e9c3908269d810d055fb03b7da5fd53` | MIT | `EMathicaFormulaDisplayKit/EMathicaFormulaDisplayVendor` | `ThirdParty/Licenses/SwiftMath/` |
| XITS Math | Font | `https://github.com/aliftype/xits` and CTAN `fonts/xits` | `1.302`, tag `v1.302`, commit `81258e3318693741a50bd921d87c73d497103d37` | SIL Open Font License 1.1 | `EMathicaFormulaDisplayVendor`, role `standard` | `ThirdParty/Licenses/Fonts/XITSMath/` |
| Euler Math | Font | CTAN `pkg/euler-math` | `0.75`, release date `2026-02-18` | SIL Open Font License 1.1 for the font file | `EMathicaFormulaDisplayVendor`, role `handwrittenResult` | `ThirdParty/Licenses/Fonts/EulerMath/` |
| Asana Math | Font | CTAN `pkg/asana-math` | `000.962`, release date `2025-11-19` | SIL Open Font License 1.1 | `EMathicaFormulaDisplayVendor`, role `decorative` | `ThirdParty/Licenses/Fonts/AsanaMath/` |

## Scope in this repository

- Actual usage repository: `SharedLibraries`
- Actual usage module: `EMathicaFormulaDisplayKit`
- Internal vendor target: `EMathicaFormulaDisplayVendor`
- Public eMathica packages must not expose SwiftMath implementation types in their public API surface.

## Record layout

- SwiftMath source record:
  - `ThirdParty/Licenses/SwiftMath/LICENSE.txt`
  - `ThirdParty/Licenses/SwiftMath/SOURCE.md`
  - `ThirdParty/Licenses/SwiftMath/FILES.md`
  - `ThirdParty/Licenses/SwiftMath/MODIFICATIONS.md`
- Font records:
  - `ThirdParty/Licenses/Fonts/XITSMath/`
  - `ThirdParty/Licenses/Fonts/EulerMath/`
  - `ThirdParty/Licenses/Fonts/AsanaMath/`

## Governance notes

- License texts are stored locally for offline inspection.
- Version anchors use a fixed commit or a fixed release date and package checksum, never a floating branch name.
- Files derived from SwiftMath keep upstream headers when present and add repository-local provenance headers only where upstream files lacked usable provenance headers.
- The font files are tracked separately from SwiftMath because their licenses and Reserved Font Name constraints are independent from SwiftMath's MIT source-code license.
