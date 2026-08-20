# Static Quality

Static quality gates are mandatory for every VestiPro task that touches Dart or Flutter code.

## Required Commands

Run the local gate before closing a task:

```powershell
.\scripts\check.ps1
```

The script fails fast and runs:

```bash
dart format --set-exit-if-changed .
flutter analyze
```

It also scans Dart source and tests for `TODO` or `FIXME` comments without context. Any marker must
include a task, issue, or reference on the same line, such as `TASK-008`, `VESTI-123`, `#123`, or a
URL.

## Analyzer Policy

`analysis_options.yaml` uses `package:flutter_lints/flutter.yaml` and promotes critical diagnostics to
errors. In particular:

- `avoid_print` is an error. Production code must not use `print`; until `AppLogger` exists, avoid
  ad hoc logging.
- `avoid_dynamic_calls` is an error. Explicit `dynamic` types are allowed only at framework
  boundaries or with a documented reason, and calls on dynamic values are blocked.
- Unused code, null-safety misuse, missing arguments, unresolved identifiers, and broken imports are
  blocking analyzer failures.
- Generated files (`*.freezed.dart`, `*.g.dart`, `*.config.dart`) are excluded from custom analysis
  because their suppressions and formatting are owned by generators.

Do not suppress a lint globally without an architecture note. A local `// ignore:` must include a
short reason near the suppression unless the file is generated.

## Review Limits

The limits below are review alerts, not automatic build failures:

| Item | Recommended limit |
| --- | ---: |
| Dart file | 300 lines |
| Main widget class | 150 lines |
| Method/function | 30 lines |
| Parameters per method/function | 5 |
| Nested conditional levels | 3 |

When code exceeds these limits, prefer extracting a cohesive widget, use case, value object, mapper,
or private helper that matches the existing feature-first Clean Architecture.
