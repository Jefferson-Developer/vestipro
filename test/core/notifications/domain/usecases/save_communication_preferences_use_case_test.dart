import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/notifications/notifications.dart';
import 'package:vestipro/core/utils/utils.dart';

import '../../../../support/fake_communication_preferences_repository.dart';

void main() {
  group('SaveCommunicationPreferencesUseCase', () {
    late FakeCommunicationPreferencesRepository repository;
    late SaveCommunicationPreferencesUseCase useCase;

    setUp(() {
      repository = FakeCommunicationPreferencesRepository();
      useCase = SaveCommunicationPreferencesUseCase(repository);
    });

    test('persists a valid preference through the repository', () async {
      final preferences =
          CommunicationPreferences.defaults(
            organizationId: 'org-1',
            userId: 'user-1',
          ).withChannelFrequency(
            category: AppNotificationCategory.crm,
            channel: CommunicationChannel.email,
            frequency: CommunicationFrequency.dailyDigest,
          );

      final result = await useCase(preferences: preferences);

      expect(result, isA<AppSuccess<CommunicationPreferences>>());
      final saved = await repository.get(
        organizationId: 'org-1',
        userId: 'user-1',
      );
      expect(
        (saved as AppSuccess<CommunicationPreferences>).value.frequencyFor(
          AppNotificationCategory.crm,
          CommunicationChannel.email,
        ),
        CommunicationFrequency.dailyDigest,
      );
    });

    test('rejects a save that would leave the system category fully '
        'disabled, never touching the repository', () async {
      var preferences = CommunicationPreferences.defaults(
        organizationId: 'org-1',
        userId: 'user-1',
      );
      for (final channel in CommunicationChannel.values) {
        preferences = preferences.withChannelFrequency(
          category: AppNotificationCategory.system,
          channel: channel,
          frequency: CommunicationFrequency.disabled,
        );
      }

      final result = await useCase(preferences: preferences);

      expect(result, isA<AppFailure<CommunicationPreferences>>());
      expect(
        (result as AppFailure<CommunicationPreferences>).failure,
        isA<ValidationFailure>(),
      );
      final stored = await repository.get(
        organizationId: 'org-1',
        userId: 'user-1',
      );
      // Never persisted — the repository still only ever knows the
      // (unconfigured) safe default.
      expect(
        (stored as AppSuccess<CommunicationPreferences>)
            .value
            .hasSystemCategoryFullyDisabled,
        isFalse,
      );
    });
  });
}
