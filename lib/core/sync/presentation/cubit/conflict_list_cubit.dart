import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/conflict_policy.dart';
import '../../domain/entities/conflict_record.dart';
import '../../domain/repositories/conflict_record_repository.dart';
import 'conflict_list_state.dart';

/// Loads and prioritizes the open conflicts a vendedor/gestor must resolve
/// (TASK-111, EPIC-14) — the list `ConflictDetailPage`'s "Resolver" action
/// links into for each item.
@injectable
final class ConflictListCubit extends Cubit<ConflictListState> {
  ConflictListCubit(this._conflictRecordRepository)
    : super(const ConflictListState());

  final ConflictRecordRepository _conflictRecordRepository;

  /// Loads every open conflict for [organizationId], prioritized with
  /// financial/critical conflicts (`ConflictPolicy.manualResolution` —
  /// orders and order items, the only entities that policy is ever assigned
  /// to, see `ConflictPolicyCatalog`) first — `tasks.md`, seção 5.5 /
  /// TASK-111's own scope: "priorizando os mais antigos e os de maior
  /// impacto (pedidos primeiro)".
  Future<void> load({required String organizationId}) async {
    emit(
      state.copyWith(
        loadStatus: ConflictListLoadStatus.loading,
        organizationId: organizationId,
        clearFailure: true,
      ),
    );

    final result = await _conflictRecordRepository.listOpen(
      organizationId: organizationId,
    );

    result.fold(
      onSuccess: (conflicts) => emit(
        state.copyWith(
          loadStatus: ConflictListLoadStatus.ready,
          conflicts: _prioritized(conflicts),
        ),
      ),
      onFailure: (failure) => emit(
        state.copyWith(
          loadStatus: ConflictListLoadStatus.failure,
          failure: failure,
        ),
      ),
    );
  }

  /// Removes [conflictId] from the currently loaded list — called by the
  /// detail screen right after a successful resolution, so the list
  /// reflects it immediately instead of waiting for a full [load] reload.
  void removeResolved(String conflictId) {
    if (state.loadStatus != ConflictListLoadStatus.ready) return;
    emit(
      state.copyWith(
        conflicts: state.conflicts
            .where((conflict) => conflict.id != conflictId)
            .toList(growable: false),
      ),
    );
  }

  /// Splits [conflicts] into "critical" (manual-resolution policy) and
  /// "the rest", each group keeping the repository's own oldest-detected-
  /// first order intact — never resorted through an unstable sort, so
  /// within each group the original ordering is guaranteed preserved.
  List<ConflictRecord> _prioritized(List<ConflictRecord> conflicts) {
    final critical = <ConflictRecord>[];
    final rest = <ConflictRecord>[];
    for (final conflict in conflicts) {
      if (conflict.policy == ConflictPolicy.manualResolution) {
        critical.add(conflict);
      } else {
        rest.add(conflict);
      }
    }
    return <ConflictRecord>[...critical, ...rest];
  }
}
