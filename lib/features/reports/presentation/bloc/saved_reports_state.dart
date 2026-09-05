import '../../../../core/errors/errors.dart';
import '../../domain/entities/saved_report.dart';

enum SavedReportsStatus { initial, loading, ready, failure }

final class SavedReportsState {
  const SavedReportsState({
    this.status = SavedReportsStatus.initial,
    this.organizationId = '',
    this.companyId = '',
    this.userId = '',
    this.owned = const <SavedReport>[],
    this.shared = const <SavedReport>[],
    this.isMutating = false,
    this.failure,
    this.successMessage,
    this.reportToOpen,
  });

  final SavedReportsStatus status;
  final String organizationId;
  final String companyId;
  final String userId;
  final List<SavedReport> owned;
  final List<SavedReport> shared;

  /// `true` while a create/rename/share/favorite/duplicate/delete call is in
  /// flight — the UI disables the triggering action to avoid a double-submit,
  /// never the whole list (a slow mutation on one row must not block reading
  /// the others).
  final bool isMutating;
  final Failure? failure;
  final String? successMessage;

  /// One-shot signal for `SavedReportOpenRequested` (TASK-145): once set, a
  /// `BlocListener` navigates to the report builder (TASK-144) and
  /// immediately dispatches `SavedReportOpenedMessageCleared` so the same
  /// navigation never fires twice from a rebuild.
  final SavedReport? reportToOpen;

  bool get isEmpty =>
      status == SavedReportsStatus.ready && owned.isEmpty && shared.isEmpty;

  SavedReportsState copyWith({
    SavedReportsStatus? status,
    String? organizationId,
    String? companyId,
    String? userId,
    List<SavedReport>? owned,
    List<SavedReport>? shared,
    bool? isMutating,
    Failure? failure,
    bool clearFailure = false,
    String? successMessage,
    bool clearSuccessMessage = false,
    SavedReport? reportToOpen,
    bool clearReportToOpen = false,
  }) => SavedReportsState(
    status: status ?? this.status,
    organizationId: organizationId ?? this.organizationId,
    companyId: companyId ?? this.companyId,
    userId: userId ?? this.userId,
    owned: owned ?? this.owned,
    shared: shared ?? this.shared,
    isMutating: isMutating ?? this.isMutating,
    failure: clearFailure ? null : failure ?? this.failure,
    successMessage: clearSuccessMessage
        ? null
        : successMessage ?? this.successMessage,
    reportToOpen: clearReportToOpen ? null : reportToOpen ?? this.reportToOpen,
  );
}
