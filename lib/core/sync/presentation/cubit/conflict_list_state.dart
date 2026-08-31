import '../../../errors/errors.dart';
import '../../domain/entities/conflict_record.dart';

enum ConflictListLoadStatus { initial, loading, ready, failure }

/// Drives [ConflictListCubit] (TASK-111): the list of open
/// (`status == ConflictRecordStatus.conflict`) records for one
/// `organizationId`, already prioritized (financial/critical conflicts
/// first — see `ConflictListCubit._prioritized`).
final class ConflictListState {
  const ConflictListState({
    this.loadStatus = ConflictListLoadStatus.initial,
    this.organizationId = '',
    this.conflicts = const <ConflictRecord>[],
    this.failure,
  });

  final ConflictListLoadStatus loadStatus;
  final String organizationId;
  final List<ConflictRecord> conflicts;
  final Failure? failure;

  bool get isInitialLoading =>
      loadStatus == ConflictListLoadStatus.initial ||
      loadStatus == ConflictListLoadStatus.loading;

  bool get isEmpty =>
      loadStatus == ConflictListLoadStatus.ready && conflicts.isEmpty;

  ConflictListState copyWith({
    ConflictListLoadStatus? loadStatus,
    String? organizationId,
    List<ConflictRecord>? conflicts,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return ConflictListState(
      loadStatus: loadStatus ?? this.loadStatus,
      organizationId: organizationId ?? this.organizationId,
      conflicts: conflicts ?? this.conflicts,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}
