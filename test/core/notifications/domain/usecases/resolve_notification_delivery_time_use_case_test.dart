import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/notifications/notifications.dart';

import '../../../../support/fake_communication_preferences_repository.dart';

void main() {
  group('ResolveNotificationDeliveryTimeUseCase', () {
    late FakeCommunicationPreferencesRepository preferencesRepository;
    late ResolveNotificationDeliveryTimeUseCase useCase;

    setUp(() {
      preferencesRepository = FakeCommunicationPreferencesRepository();
      useCase = ResolveNotificationDeliveryTimeUseCase(preferencesRepository);
    });

    test('a critical notification always resolves to null (deliver now), '
        'even during the recipient\'s own active quiet hours', () async {
      preferencesRepository.seed(
        CommunicationPreferences.defaults(
          organizationId: 'org-1',
          userId: 'user-1',
        ).withQuietHours(
          const QuietHours(enabled: true, timezoneOffsetMinutes: 0),
        ),
      );

      final deliverAt = await useCase(
        organizationId: 'org-1',
        userId: 'user-1',
        priority: AppNotificationPriority.critical,
        now: DateTime.utc(2026, 1, 16, 23),
      );

      expect(deliverAt, isNull);
    });

    test('an informative notification resolves to null when the recipient '
        'never enabled quiet hours (the default)', () async {
      final deliverAt = await useCase(
        organizationId: 'org-1',
        userId: 'user-1',
        priority: AppNotificationPriority.informative,
        now: DateTime.utc(2026, 1, 16, 23),
      );

      expect(deliverAt, isNull);
    });

    test('an informative notification resolves to null when now falls '
        'outside the configured window', () async {
      preferencesRepository.seed(
        CommunicationPreferences.defaults(
          organizationId: 'org-1',
          userId: 'user-1',
        ).withQuietHours(
          const QuietHours(enabled: true, timezoneOffsetMinutes: 0),
        ),
      );

      final deliverAt = await useCase(
        organizationId: 'org-1',
        userId: 'user-1',
        priority: AppNotificationPriority.informative,
        now: DateTime.utc(2026, 1, 16, 12),
      );

      expect(deliverAt, isNull);
    });

    test('an informative notification resolves to the quiet-hours end '
        'instant when now falls inside the configured window', () async {
      preferencesRepository.seed(
        CommunicationPreferences.defaults(
          organizationId: 'org-1',
          userId: 'user-1',
        ).withQuietHours(
          const QuietHours(enabled: true, timezoneOffsetMinutes: 0),
        ),
      );

      final deliverAt = await useCase(
        organizationId: 'org-1',
        userId: 'user-1',
        priority: AppNotificationPriority.informative,
        now: DateTime.utc(2026, 1, 16, 23),
      );

      expect(deliverAt, DateTime.utc(2026, 1, 17, 7));
    });
  });
}
