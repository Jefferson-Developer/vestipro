import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/conflict_resolution_service.dart';
import '../../domain/entities/conflict_record.dart';
import '../../domain/repositories/conflict_record_repository.dart';
import 'conflict_resolution_state.dart';

/// Loads a single blocked [ConflictRecord] and submits the human's explicit
/// resolution choice for it (TASK-111, EPIC-14) — the only Cubit allowed to
/// call [ConflictResolutionService.resolveManually], so `ConflictDetailPage`
/// never talks to the service/repositories directly.
///
/// Never applies a resolution automatically: [keepLocal]/[useRemote]/
/// [mergeFields] are only ever invoked from an explicit user tap, per
/// TASK-111's own restriction ("a tela nunca aplica uma resolução
/// automaticamente").
@injectable
final class ConflictResolutionCubit extends Cubit<ConflictResolutionState> {
  ConflictResolutionCubit(
    this._conflictRecordRepository,
    this._conflictResolutionService,
  ) : super(const ConflictResolutionState());

  final ConflictRecordRepository _conflictRecordRepository;
  final ConflictResolutionService _conflictResolutionService;

  /// Loads the [ConflictRecord] identified by [conflictId].
  Future<void> load({required String conflictId}) async {
    emit(
      state.copyWith(
        loadStatus: ConflictResolutionLoadStatus.loading,
        clearLoadFailure: true,
      ),
    );

    final result = await _conflictRecordRepository.getById(conflictId);

    result.fold(
      onSuccess: (record) {
        if (record == null) {
          emit(
            state.copyWith(loadStatus: ConflictResolutionLoadStatus.notFound),
          );
          return;
        }
        emit(
          state.copyWith(
            loadStatus: ConflictResolutionLoadStatus.ready,
            record: record,
          ),
        );
      },
      onFailure: (failure) => emit(
        state.copyWith(
          loadStatus: ConflictResolutionLoadStatus.failure,
          loadFailure: failure,
        ),
      ),
    );
  }

  /// "Manter minha versão": keeps [ConflictRecord.localSnapshot] in full,
  /// discarding every remote value for the fields that diverged.
  Future<void> keepLocal({required String resolvedBy}) {
    final record = state.record;
    if (record == null) return Future<void>.value();
    return _resolve(
      record: record,
      resolvedData: record.localSnapshot,
      resolvedBy: resolvedBy,
    );
  }

  /// "Usar versão do servidor": keeps [ConflictRecord.remoteSnapshot] in
  /// full, discarding every local pending value for the fields that
  /// diverged.
  Future<void> useRemote({required String resolvedBy}) {
    final record = state.record;
    if (record == null) return Future<void>.value();
    return _resolve(
      record: record,
      resolvedData: record.remoteSnapshot,
      resolvedBy: resolvedBy,
    );
  }

  /// "Mesclar campo a campo": starts from the remote snapshot and overlays
  /// exactly the fields in [fieldsFromLocal] with their local value —
  /// [fieldsFromLocal] must be a subset of
  /// [ConflictRecord.conflictingFields] (the detail page only ever offers
  /// this action for a [record] whose `policy` allows field-level merge; it
  /// is the caller's responsibility to only pass fields the user actually
  /// picked "manter local" for).
  Future<void> mergeFields({
    required Set<String> fieldsFromLocal,
    required String resolvedBy,
  }) {
    final record = state.record;
    if (record == null) return Future<void>.value();

    final resolvedData = <String, Object?>{...record.remoteSnapshot};
    for (final field in fieldsFromLocal) {
      resolvedData[field] = record.localSnapshot[field];
    }

    return _resolve(
      record: record,
      resolvedData: resolvedData,
      resolvedBy: resolvedBy,
    );
  }

  Future<void> _resolve({
    required ConflictRecord record,
    required Map<String, Object?> resolvedData,
    required String resolvedBy,
  }) async {
    emit(
      state.copyWith(
        submitStatus: ConflictResolutionSubmitStatus.submitting,
        clearSubmitFailure: true,
      ),
    );

    final result = await _conflictResolutionService.resolveManually(
      record: record,
      resolvedData: resolvedData,
      resolvedBy: resolvedBy,
    );

    result.fold(
      onSuccess: (resolved) => emit(
        state.copyWith(
          submitStatus: ConflictResolutionSubmitStatus.success,
          record: resolved,
        ),
      ),
      onFailure: (failure) => emit(
        state.copyWith(
          submitStatus: ConflictResolutionSubmitStatus.failure,
          submitFailure: failure,
        ),
      ),
    );
  }
}
