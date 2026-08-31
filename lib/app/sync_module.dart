import 'package:injectable/injectable.dart';

import '../core/sync/domain/sync_pull_source.dart';
import '../core/sync/domain/sync_push_handler.dart';

/// Registers every [SyncPushHandler]/[SyncPullSource] implementation
/// `SyncEngine` (TASK-109) dispatches to.
///
/// This lives in `lib/app/` — the composition root — rather than inside
/// `lib/core/sync/`, same rule and same rationale as
/// `OfflinePackageLoadersModule`: `core` must never depend on `features`
/// (see `AGENTS.md`/`flutter-senior-architect`), only the app-level wiring
/// layer is allowed to know about every feature's concrete adapter at once.
///
/// Both lists are still empty: no feature enqueues through the Outbox yet
/// (`order`/`orderItem`/`crmActivity`/`customer` — TASK-108's
/// `OutboxEntityType` values — all still write online-only, directly to
/// Firestore/Functions) and no feature has registered an incremental
/// `SyncPullSource` yet either. `SyncEngine` itself is fully exercised
/// through fakes in its own tests in the meantime. To wire a real entity:
/// add its `SyncPushHandler`/`SyncPullSource` implementation to the
/// matching list below — nothing in `core/sync` needs to change.
@module
abstract class SyncModule {
  @lazySingleton
  List<SyncPushHandler> get syncPushHandlers => const <SyncPushHandler>[];

  @lazySingleton
  List<SyncPullSource> get syncPullSources => const <SyncPullSource>[];
}
