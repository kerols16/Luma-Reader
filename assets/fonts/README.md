# Bundled fonts

All fonts here are OFL-licensed and are bundled so the app works fully offline.
License texts live in `licenses/`.

| Role | Family | File | Source |
| --- | --- | --- | --- |
| Arabic reading | Amiri | `Amiri-Regular.ttf` | [Google Fonts / Amiri](https://github.com/google/fonts/tree/main/ofl/amiri) |
| English reading | Literata | `Literata-Variable.ttf` | [Google Fonts / Literata](https://github.com/google/fonts/tree/main/ofl/literata) |
| Arabic UI | IBM Plex Sans Arabic | `IBMPlexSansArabic-Regular.ttf`, `IBMPlexSansArabic-Medium.ttf` | [Google Fonts / IBM Plex Sans Arabic](https://github.com/google/fonts/tree/main/ofl/ibmplexsansarabic) |
| English UI | Inter | `Inter-Variable.ttf` | [Google Fonts / Inter](https://github.com/google/fonts/tree/main/ofl/inter) |

## Candidates considered

- Arabic reading: Amiri (bundled), Noto Naskh Arabic
- Arabic UI: IBM Plex Sans Arabic (bundled), Cairo
- English reading: Literata (bundled), Source Serif 4
- English UI: Inter (bundled)

To swap a family, drop the OFL files in this folder, update the `fonts:` section
in `pubspec.yaml`, update the family names in `lib/core/theme/app_fonts.dart`,
and add the license to `licenses/`.

Rules: no italics for Arabic, no letter-spacing for Arabic, and no font styling
outside `lib/core/theme/`.
