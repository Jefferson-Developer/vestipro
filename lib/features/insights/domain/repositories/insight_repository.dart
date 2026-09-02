import '../../../../core/utils/utils.dart';
import '../entities/insight.dart';
import '../entities/insight_page.dart';
import '../entities/insight_visibility_filter.dart';
import '../value_objects/insight_status.dart';
import '../value_objects/insight_type.dart';

abstract interface class InsightRepository {
  Future<AppResult<void>> saveAll({
    required String organizationId,
    required List<Insight> insights,
  });

  Future<AppResult<InsightPage>> listPageByRecipient({
    required String organizationId,
    required String recipientUserId,
    int limit = 25,
    DateTime? before,
    InsightType? type,
    InsightStatus? status,
  });

  /// Lists a page of `Insight`s across every `recipientUserId` [visibility]
  /// allows (TASK-132's Central de Oportunidades) — `dismissed`/`resolved`
  /// insights are always excluded, since a discarded insight must not
  /// reappear in the same generation cycle.
  Future<AppResult<InsightPage>> listPageByVisibility({
    required String organizationId,
    required InsightVisibilityFilter visibility,
    int limit = 25,
    DateTime? before,
    InsightType? type,
  });

  /// Updates a single `Insight`'s [status] (viewed/inProgress/dismissed/
  /// resolved), e.g. from the Central de Oportunidades' discard/resolve/undo
  /// actions (TASK-132).
  Future<AppResult<void>> updateStatus({
    required String organizationId,
    required String insightId,
    required InsightStatus status,
  });
}
