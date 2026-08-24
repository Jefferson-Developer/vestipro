import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';

void main() {
  group('AnalyticsEvents', () {
    test('exposes exactly the initial taxonomy, with no duplicates', () {
      expect(
        AnalyticsEvents.values,
        unorderedEquals(<String>[
          'login_completed',
          'sign_up_completed',
          'organization_created',
          'customer_created',
          'lead_created',
          'lead_qualified',
          'lead_disqualified',
          'product_viewed',
          'catalog_filtered',
          'order_created',
          'order_submitted',
          'order_sync_failed',
          'crm_activity_created',
          'insight_opened',
          'insight_action_clicked',
          'report_exported',
          'offline_pack_downloaded',
          'product_added_to_order',
          'password_reset_requested',
          'invite_sent',
          'invite_accepted',
          'user_role_updated',
          'user_deactivated',
          'user_reactivated',
          'team_created',
          'team_updated',
          'team_deleted',
          'portfolio_assignment_saved',
        ]),
      );

      expect(
        AnalyticsEvents.values.toSet().length,
        AnalyticsEvents.values.length,
      );
    });
  });
}
