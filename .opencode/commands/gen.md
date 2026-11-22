---
description: Regenerate drift code and localizations
---

Regenerate generated code:

1. `dart run build_runner build`
2. `flutter gen-l10n`

Report any generator errors with the file and line. Never hand-edit generated
files (`*.g.dart`, `*.freezed.dart`, generated l10n).

$ARGUMENTS
