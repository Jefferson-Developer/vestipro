import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/notifications/notifications.dart';

void main() {
  group('CommunicationPreferences', () {
    test('defaults keep push/central immediate and e-mail disabled for every '
        'category (TASK-154 documented default)', () {
      final defaults = CommunicationPreferences.defaults(
        organizationId: 'org-1',
        userId: 'user-1',
      );

      for (final category in AppNotificationCategory.values) {
        expect(
          defaults.frequencyFor(category, CommunicationChannel.push),
          CommunicationFrequency.immediate,
          reason: '$category push',
        );
        expect(
          defaults.frequencyFor(category, CommunicationChannel.inApp),
          CommunicationFrequency.immediate,
          reason: '$category inApp',
        );
        expect(
          defaults.frequencyFor(category, CommunicationChannel.email),
          CommunicationFrequency.disabled,
          reason: '$category email',
        );
        expect(defaults.allows(category, CommunicationChannel.push), isTrue);
        expect(defaults.allows(category, CommunicationChannel.email), isFalse);
      }
    });

    test(
      'withChannelFrequency only changes the targeted category/channel cell',
      () {
        final defaults = CommunicationPreferences.defaults(
          organizationId: 'org-1',
          userId: 'user-1',
        );

        final updated = defaults.withChannelFrequency(
          category: AppNotificationCategory.crm,
          channel: CommunicationChannel.push,
          frequency: CommunicationFrequency.disabled,
        );

        expect(
          updated.frequencyFor(
            AppNotificationCategory.crm,
            CommunicationChannel.push,
          ),
          CommunicationFrequency.disabled,
        );
        // Untouched channel/category stay exactly as the default.
        expect(
          updated.frequencyFor(
            AppNotificationCategory.crm,
            CommunicationChannel.inApp,
          ),
          CommunicationFrequency.immediate,
        );
        expect(
          updated.frequencyFor(
            AppNotificationCategory.commercial,
            CommunicationChannel.push,
          ),
          CommunicationFrequency.immediate,
        );
      },
    );

    test('hasSystemCategoryFullyDisabled is true only once every system '
        'channel is disabled', () {
      var preferences = CommunicationPreferences.defaults(
        organizationId: 'org-1',
        userId: 'user-1',
      );
      expect(preferences.hasSystemCategoryFullyDisabled, isFalse);

      preferences = preferences.withChannelFrequency(
        category: AppNotificationCategory.system,
        channel: CommunicationChannel.push,
        frequency: CommunicationFrequency.disabled,
      );
      expect(preferences.hasSystemCategoryFullyDisabled, isFalse);

      preferences = preferences.withChannelFrequency(
        category: AppNotificationCategory.system,
        channel: CommunicationChannel.inApp,
        frequency: CommunicationFrequency.disabled,
      );
      // email was already disabled by default — push and inApp just
      // joined it, so every channel is now disabled.
      expect(preferences.hasSystemCategoryFullyDisabled, isTrue);
    });

    test('a category missing from categoryPreferences degrades to the '
        'documented default rather than throwing', () {
      const preferences = CommunicationPreferences(
        organizationId: 'org-1',
        userId: 'user-1',
        categoryPreferences:
            <AppNotificationCategory, CategoryCommunicationPreference>{},
      );

      expect(
        preferences.frequencyFor(
          AppNotificationCategory.crm,
          CommunicationChannel.push,
        ),
        CommunicationFrequency.immediate,
      );
    });
  });
}
