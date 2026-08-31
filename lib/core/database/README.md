Database abstractions, base datasources, and persistence adapters live here.

The local (offline) database technology is Drift/SQLite. That decision — Drift vs. Isar, with
objective criteria and trade-offs — is fixed and justified in
[`docs/adr/0003-banco-local-drift.md`](../../../docs/adr/0003-banco-local-drift.md), the source of
truth for any future change. `AppDatabase` (`app_database.dart`) is the single local database class;
new tables extend its same migration chain, they never create a second local database.
