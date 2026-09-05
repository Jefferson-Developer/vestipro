import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/notifications/notifications.dart';
import 'package:vestipro/core/utils/utils.dart';

import '../../../../support/fake_communication_preferences_repository.dart';

class _FakeDeviceTimezoneProvider implements DeviceTimezoneProvider {
  _FakeDeviceTimezoneProvider(this._offsetMinutes);

  int _offsetMinutes;

  set offsetMinutes(int value) => _offsetMinutes = value;

  @override
  int currentOffsetMinutes() => _offsetMinutes;
}

void main() {
  group('SyncDeviceTimezoneUseCase', () {
    late FakeCommunicationPreferencesRepository preferencesRepository;
    late _FakeDeviceTimezoneProvider timezoneProvider;
    late SyncDeviceTimezoneUseCase useCase;

    setUp(() {
      preferencesRepository = FakeCommunicationPreferencesRepository();
      timezoneProvider = _FakeDeviceTimezoneProvider(-180);
      useCase = SyncDeviceTimezoneUseCase(
        preferencesRepository,
        timezoneProvider,
      );
    });

    test('persists the device\'s current offset the first time it syncs '
        '(no offset on file yet)', () async {
      await useCase(organizationId: 'org-1', userId: 'user-1');

      final result = await preferencesRepository.get(
        organizationId: 'org-1',
        userId: 'user-1',
      );
      final preferences =
          (result as AppSuccess<CommunicationPreferences>).value;
      expect(preferences.quietHours.timezoneOffsetMinutes, -180);
      expect(preferences.quietHours.timezoneUpdatedAt, isNotNull);
    });

    test('does not write anything when the offset on file already matches the '
        'device\'s current one', () async {
      preferencesRepository.seed(
        CommunicationPreferences.defaults(
          organizationId: 'org-1',
          userId: 'user-1',
        ).withQuietHours(const QuietHours(timezoneOffsetMinutes: -180)),
      );

      await useCase(organizationId: 'org-1', userId: 'user-1');

      final result = await preferencesRepository.get(
        organizationId: 'org-1',
        userId: 'user-1',
      );
      final preferences =
          (result as AppSuccess<CommunicationPreferences>).value;
      // Still null updatedAt on the document itself (never re-saved) —
      // the repository fake's `save` always fills it in, so an unchanged
      // `timezoneUpdatedAt` proves no write happened.
      expect(preferences.quietHours.timezoneUpdatedAt, isNull);
    });

    test('updates the persisted offset once the device reports a different '
        'one (e.g. the user travelled to a new timezone)', () async {
      preferencesRepository.seed(
        CommunicationPreferences.defaults(
          organizationId: 'org-1',
          userId: 'user-1',
        ).withQuietHours(const QuietHours(timezoneOffsetMinutes: -180)),
      );
      timezoneProvider.offsetMinutes = 60;

      await useCase(organizationId: 'org-1', userId: 'user-1');

      final result = await preferencesRepository.get(
        organizationId: 'org-1',
        userId: 'user-1',
      );
      final preferences =
          (result as AppSuccess<CommunicationPreferences>).value;
      expect(preferences.quietHours.timezoneOffsetMinutes, 60);
    });
  });
}
