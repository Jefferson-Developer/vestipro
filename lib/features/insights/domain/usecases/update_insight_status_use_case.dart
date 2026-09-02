import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../repositories/insight_repository.dart';
import '../value_objects/insight_status.dart';

/// Applies a single `Insight.status` transition from the Central de
/// Oportunidades (TASK-132): discard (`dismissed`), mark as resolved
/// (`resolved`), or the immediate undo of either — reapplying whatever
/// status the insight had right before the action, which `OpportunityCenterBloc`
/// tracks locally so the undo snackbar never needs a round-trip read.
@injectable
final class UpdateInsightStatusUseCase {
  const UpdateInsightStatusUseCase(this._insightRepository);

  final InsightRepository _insightRepository;

  Future<AppResult<void>> call({
    required String organizationId,
    required String insightId,
    required InsightStatus status,
  }) {
    final normalizedOrganizationId = organizationId.trim();
    final normalizedInsightId = insightId.trim();
    final fieldErrors = <String, String>{};

    if (normalizedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (normalizedInsightId.isEmpty) {
      fieldErrors['insightId'] = 'InsightId is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return Future<AppResult<void>>.value(
        AppFailure<void>(
          ValidationFailure(
            'Invalid insight status payload.',
            fieldErrors: fieldErrors,
            code: 'invalid_insight_status_payload',
          ),
        ),
      );
    }

    return _insightRepository.updateStatus(
      organizationId: normalizedOrganizationId,
      insightId: normalizedInsightId,
      status: status,
    );
  }
}
