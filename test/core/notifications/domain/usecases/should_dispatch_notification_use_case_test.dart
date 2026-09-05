import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/notifications/notifications.dart';
import 'package:vestipro/core/utils/utils.dart';

import '../../../../support/fake_communication_preferences_repository.dart';

void main() {
  group('ShouldDispatchNotificationUseCase', () {
    test('allows dispatch when the category/channel is not disabled', () async {
      final repository = FakeCommunicationPreferencesRepository();
      final useCase = ShouldDispatchNotificationUseCase(repository);

      final allowed = await useCase(
        organizationId: 'org-1',
        userId: 'user-1',
        category: AppNotificationCategory.crm,
      );

      expect(allowed, isTrue);
    });

    test(
      'blocks dispatch once the recipient disabled the category/channel',
      () async {
        final repository = FakeCommunicationPreferencesRepository();
        repository.seed(
          CommunicationPreferences.defaults(
            organizationId: 'org-1',
            userId: 'user-1',
          ).withChannelFrequency(
            category: AppNotificationCategory.commercial,
            channel: CommunicationChannel.inApp,
            frequency: CommunicationFrequency.disabled,
          ),
        );
        final useCase = ShouldDispatchNotificationUseCase(repository);

        final allowed = await useCase(
          organizationId: 'org-1',
          userId: 'user-1',
          category: AppNotificationCategory.commercial,
        );

        expect(allowed, isFalse);
      },
    );

    test('fails open (allows dispatch) when the preferences read itself fails, '
        'so a transient error never silently mutes a notification', () async {
      final useCase = ShouldDispatchNotificationUseCase(
        _FailingCommunicationPreferencesRepository(),
      );

      final allowed = await useCase(
        organizationId: 'org-1',
        userId: 'user-1',
        category: AppNotificationCategory.system,
      );

      expect(allowed, isTrue);
    });
  });
}

final class _FailingCommunicationPreferencesRepository
    implements CommunicationPreferencesRepository {
  @override
  Future<AppResult<CommunicationPreferences>> get({
    required String organizationId,
    required String userId,
  }) async {
    return AppFailure<CommunicationPreferences>(
      const UnexpectedFailure('boom', code: 'test_failure'),
    );
  }

  @override
  Stream<CommunicationPreferences> watch({
    required String organizationId,
    required String userId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<CommunicationPreferences>> save({
    required CommunicationPreferences preferences,
  }) async {
    throw UnimplementedError();
  }
}
