import '../../../errors/errors.dart';
import '../../domain/entities/conflict_record.dart';

enum ConflictResolutionLoadStatus { initial, loading, ready, notFound, failure }

enum ConflictResolutionSubmitStatus { idle, submitting, success, failure }

/// Drives `ConflictDetailPage` (TASK-111): loads one [ConflictRecord] by id
/// and tracks the submission of the human's explicit resolution choice
/// ("Manter minha versão" / "Usar versão do servidor" / "Mesclar campo a
/// campo").
final class ConflictResolutionState {
  const ConflictResolutionState({
    this.loadStatus = ConflictResolutionLoadStatus.initial,
    this.submitStatus = ConflictResolutionSubmitStatus.idle,
    this.record,
    this.loadFailure,
    this.submitFailure,
  });

  final ConflictResolutionLoadStatus loadStatus;
  final ConflictResolutionSubmitStatus submitStatus;

  /// The loaded conflict — kept even after a successful resolution
  /// ([submitStatus] == [ConflictResolutionSubmitStatus.success]) so the
  /// confirmation view can still render what was resolved.
  final ConflictRecord? record;

  final Failure? loadFailure;
  final Failure? submitFailure;

  bool get isInitialLoading =>
      loadStatus == ConflictResolutionLoadStatus.initial ||
      loadStatus == ConflictResolutionLoadStatus.loading;

  bool get isSubmitting =>
      submitStatus == ConflictResolutionSubmitStatus.submitting;

  bool get isResolved => submitStatus == ConflictResolutionSubmitStatus.success;

  ConflictResolutionState copyWith({
    ConflictResolutionLoadStatus? loadStatus,
    ConflictResolutionSubmitStatus? submitStatus,
    ConflictRecord? record,
    Failure? loadFailure,
    bool clearLoadFailure = false,
    Failure? submitFailure,
    bool clearSubmitFailure = false,
  }) {
    return ConflictResolutionState(
      loadStatus: loadStatus ?? this.loadStatus,
      submitStatus: submitStatus ?? this.submitStatus,
      record: record ?? this.record,
      loadFailure: clearLoadFailure ? null : loadFailure ?? this.loadFailure,
      submitFailure: clearSubmitFailure
          ? null
          : submitFailure ?? this.submitFailure,
    );
  }
}
