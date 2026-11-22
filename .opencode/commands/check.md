---
description: Format, analyze and test the project
---

Run the full check and fix anything that fails:

1. `dart format .`
2. `flutter analyze`
3. `flutter test`

Fix all analyzer warnings/errors and failing tests. Re-run the three commands
until clean. Do not weaken lints or delete tests to make things pass.

4. APPEND (never overwrite) a short check entry to `build_report.txt`:

```
==== [YYYY-MM-DD HH:MM] check ====
What was done:   <what was formatted or fixed; "nothing to fix" if clean>
Files changed:   <formatted/fixed paths, or "none">
Commands run:    dart format .; flutter analyze; flutter test
Results:         format: <clean/changed>; analyze: <clean/N issues>; test: <N/N passing>
Assumptions:     <only if something was decided>
Open issues:     <only known failures/TODOs; "none" otherwise>
Next:            <the next planned step>
```

Use the local clock for the timestamp. If `build_report.txt` is missing, create
it with a minimal `Project: luma` / `Created: YYYY-MM-DD` header first.

$ARGUMENTS

Report: what was formatted, what was fixed, and the final analyze/test result.
