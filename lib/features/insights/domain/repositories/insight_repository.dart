import '../../../../core/utils/utils.dart';
import '../entities/insight.dart';
import '../entities/insight_page.dart';
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
}
