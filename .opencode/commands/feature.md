---
description: Scaffold a new feature folder
---

Create a new feature named `$ARGUMENTS` under `lib/features/$ARGUMENTS/`,
following AGENTS.md:

- `<name>_page.dart` — the screen widget.
- `<name>_cubit.dart` and `<name>_state.dart` — Cubit + sealed state.
- `data/<name>_repository.dart` — repository stub returning domain entities
  (no drift rows, no Flutter imports in domain models).
- `<name>_route.dart` (or route entry) wired into `lib/core/router/`.
- `test/features/$ARGUMENTS/<name>_cubit_test.dart` — test stub.
- ARB keys in **both** `lib/core/l10n/app_en.arb` and `app_ar.arb` (ICU plurals
  with all six Arabic forms where counts are involved).
- Run `/gen`, then `flutter analyze` and `flutter test`.

Use snake_case file names, no hardcoded strings, no inline colors, directional
widgets only. Report the files created and the test/analyze result.
