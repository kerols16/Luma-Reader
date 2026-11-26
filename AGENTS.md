# AGENTS.md — Luma

## Product

Luma is an offline-first Flutter app (Android + iOS) for daily reading.
The user imports a PDF (book, syllabus, novel), picks a time window (e.g. 30 days)
and minutes per day (default 60). Luma splits the book into daily reading units,
shows today's unit in a comfortable reader, tracks progress, and sends one gentle
daily local reminder. UI languages: Arabic (RTL) and English. UI language is
independent of book language. Look and feel is the top priority. v0 has no AI.

## Stack and architecture

- State: `flutter_bloc` — prefer Cubit. Use Bloc only when explicit events help.
- Routing: `go_router`.
- Local DB: `drift` (SQLite) + `path_provider`, generated typed code.
  Do not write SQL by hand unless drift cannot express the query.
- Localization: official Flutter `gen_l10n` (ARB + ICU plurals), locales `en`, `ar`.
- Notifications: `flutter_local_notifications` + `timezone` + `flutter_timezone` (local only).
- File picking: `file_picker`.
- Fonts: bundled in `assets/` (must work offline), OFL-licensed only.
- Architecture: UI -> Cubit -> repository -> drift. Repositories return domain
  entities, never drift rows. `lib/domain/` is pure Dart (no Flutter imports)
  and fully unit-tested.
- `lib/services/llm/` stays an empty interface — no implementation in v0.
- Do not add dependencies beyond the agreed stack without asking.

## Layout

```
lib/
  core/     theme/, l10n/, router/, utils/
  data/     db/, pdf/, files/
  domain/   entities/, planning/, segmentation/, notifications/
  features/ library/, create_plan/, plan_review/, today/, progress/, settings/
  services/ notifications/, llm/
```

## RTL rules

- Never use `left`/`right` (or `EdgeInsets.only(left:)`). Use `EdgeInsetsDirectional`,
  `AlignmentDirectional`, `start`/`end`, and directional icons.
- Each text paragraph gets its own `TextDirection` derived from its content,
  because books mix Arabic and English regardless of UI locale.
- Test Arabic layouts with an RTL `Directionality`, not just translated strings.

## Strings and localization

- No hardcoded user-facing strings. Everything goes through ARB files
  (`lib/core/l10n/app_en.arb`, `app_ar.arb`).
- Plurals use ICU. Arabic has six forms: zero / one / two / few / many / other.
- Keep UI language separate from book content language.

## Theming

- Fonts and colors come only from the theme. No inline colors, no ad-hoc
  `TextStyle` colors, no magic font sizes outside design tokens.
- Three reader themes (light, sepia, dark) are defined in one place.

## Quality bar

- Every domain function has unit tests. Cover edge cases, not just the happy path.
- Before claiming a task is done, run `flutter analyze` and `flutter test` and fix failures.
- Run `/check` before finishing a task.
- Small commits with clear messages. Never touch files outside the task's scope.

## Build report

Keep a local, uncommitted `build_report.txt` at the project root (ignored by git).
After EVERY step or task, and after every `/check` run that changes code, APPEND
(never overwrite) an entry in this format:

```
==== [YYYY-MM-DD HH:MM] <step or task name> ====
What was done:   (2-5 plain lines)
Files changed:   (paths, new / modified / deleted)
Commands run:    (the important ones only)
Results:         (dart format / flutter analyze / flutter test: pass counts)
Assumptions:     (anything you decided without asking me)
Open issues:     (known gaps, TODOs, things to revisit)
Next:            (what the next step is)
```

## Project commands

OpenCode V2 discovers project commands in `.opencode/commands/` (the legacy
singular `.opencode/command/` is also read, but use `commands/`).
