import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/outbox_summary.dart';
import '../../domain/repositories/outbox_repository.dart';

/// Reactive Outbox watcher (TASK-108, EPIC-14) — the Central de
/// Sincronização (TASK-112) uses this to show pending/syncing/failed/
/// conflict counts in real time instead of polling the local database.
///
/// One instance watches exactly one `organizationId` scope at a time —
/// calling [watch] again (e.g. after switching organization) replaces the
/// previous subscription instead of stacking a second one.
@injectable
final class OutboxWatcherCubit extends Cubit<OutboxSummary> {
  OutboxWatcherCubit(this._outboxRepository) : super(const OutboxSummary());

  final OutboxRepository _outboxRepository;

  StreamSubscription<OutboxSummary>? _subscription;

  /// Starts (or restarts) observing the Outbox summary for
  /// [organizationId].
  void watch({required String organizationId}) {
    unawaited(_subscription?.cancel());
    _subscription = _outboxRepository
        .watchSummary(organizationId: organizationId)
        .listen((summary) {
          if (isClosed) return;
          emit(summary);
        });
  }

  @override
  Future<void> close() {
    unawaited(_subscription?.cancel());
    return super.close();
  }
}
