import 'package:injectable/injectable.dart';

import '../entities/insight.dart';
import 'process_insight_commercial_alert_use_case.dart';

/// Orchestrates "oportunidade quente" commercial alerts (TASK-153, EPIC-19)
/// for a batch of already-loaded [Insight]s, running client-side wherever
/// the Central de Oportunidades already loads them (`OpportunityCenterBloc`)
/// — mirrors the same client-triggered pattern
/// `GenerateCrmTaskRemindersUseCase` (TASK-152)/
/// `GenerateOrderCommercialAlertsUseCase` (TASK-153) already established.
@injectable
final class GenerateInsightCommercialAlertsUseCase {
  GenerateInsightCommercialAlertsUseCase(this._processAlert);

  final ProcessInsightCommercialAlertUseCase _processAlert;

  /// Returns how many notifications were actually dispatched (mainly for
  /// tests/telemetry — callers are not expected to react to the count).
  Future<int> call({
    required List<Insight> insights,
    required String recipientUserId,
    DateTime? now,
  }) async {
    var dispatched = 0;
    for (final insight in insights) {
      final wasDispatched = await _processAlert(
        insight: insight,
        recipientUserId: recipientUserId,
        now: now,
      );
      if (wasDispatched) dispatched += 1;
    }
    return dispatched;
  }
}
