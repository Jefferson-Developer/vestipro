import '../../../../core/errors/errors.dart';

String? normalizeTargetOptional(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

/// Builds the failure returned when `CreateTargetUseCase` finds another
/// active Target whose period overlaps the one being created, for the same
/// dimension/metric.
Failure targetPeriodOverlapFailure() {
  return const ValidationFailure(
    'Another active target already covers part of this period for this '
    'dimension and metric.',
    fieldErrors: <String, String>{
      'startDate': 'Overlapping active target exists for this period.',
    },
    code: 'target_period_overlap',
  );
}
