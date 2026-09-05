import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/notifications/data/datasources/communication_preferences_data_source.dart';
import 'package:vestipro/core/notifications/data/dtos/communication_preferences_dto.dart';
import 'package:vestipro/core/notifications/data/mappers/communication_preferences_mapper.dart';
import 'package:vestipro/core/notifications/notifications.dart';
import 'package:vestipro/core/utils/utils.dart';

void main() {
  group('CommunicationPreferencesRepositoryImpl', () {
    late _FakeCommunicationPreferencesDataSource dataSource;
    late CommunicationPreferencesRepositoryImpl repository;

    setUp(() {
      dataSource = _FakeCommunicationPreferencesDataSource();
      repository = CommunicationPreferencesRepositoryImpl(
        dataSource: dataSource,
        mapper: const CommunicationPreferencesMapper(),
      );
    });

    test('get() degrades to the documented default when the user never saved '
        'anything yet', () async {
      final result = await repository.get(
        organizationId: 'org-1',
        userId: 'user-1',
      );

      expect(result, isA<AppSuccess<CommunicationPreferences>>());
      final preferences =
          (result as AppSuccess<CommunicationPreferences>).value;
      expect(
        preferences.allows(
          AppNotificationCategory.crm,
          CommunicationChannel.push,
        ),
        isTrue,
      );
      expect(
        preferences.allows(
          AppNotificationCategory.crm,
          CommunicationChannel.email,
        ),
        isFalse,
      );
    });

    test('save() round-trips every category/channel through the mapper '
        'unchanged', () async {
      final preferences =
          CommunicationPreferences.defaults(
            organizationId: 'org-1',
            userId: 'user-1',
          ).withChannelFrequency(
            category: AppNotificationCategory.system,
            channel: CommunicationChannel.email,
            frequency: CommunicationFrequency.dailyDigest,
          );

      final saveResult = await repository.save(preferences: preferences);
      expect(saveResult, isA<AppSuccess<CommunicationPreferences>>());

      final readResult = await repository.get(
        organizationId: 'org-1',
        userId: 'user-1',
      );
      final read = (readResult as AppSuccess<CommunicationPreferences>).value;
      expect(
        read.frequencyFor(
          AppNotificationCategory.system,
          CommunicationChannel.email,
        ),
        CommunicationFrequency.dailyDigest,
      );
    });

    test(
      'watch() reflects the same change on two independent subscriptions, '
      'simulating two devices signed in as the same user (TASK-154)',
      () async {
        final deviceA = repository.watch(
          organizationId: 'org-1',
          userId: 'user-1',
        );
        final deviceB = repository.watch(
          organizationId: 'org-1',
          userId: 'user-1',
        );

        final deviceAValues = <CommunicationPreferences>[];
        final deviceBValues = <CommunicationPreferences>[];
        final subscriptionA = deviceA.listen(deviceAValues.add);
        final subscriptionB = deviceB.listen(deviceBValues.add);

        // One of the two "devices" saves a change...
        await repository.save(
          preferences:
              CommunicationPreferences.defaults(
                organizationId: 'org-1',
                userId: 'user-1',
              ).withChannelFrequency(
                category: AppNotificationCategory.commercial,
                channel: CommunicationChannel.push,
                frequency: CommunicationFrequency.disabled,
              ),
        );
        await Future<void>.delayed(Duration.zero);

        // ...and the other one observes it too, without polling/reloading.
        expect(
          deviceBValues.last.frequencyFor(
            AppNotificationCategory.commercial,
            CommunicationChannel.push,
          ),
          CommunicationFrequency.disabled,
        );
        expect(
          deviceAValues.last.frequencyFor(
            AppNotificationCategory.commercial,
            CommunicationChannel.push,
          ),
          CommunicationFrequency.disabled,
        );

        await subscriptionA.cancel();
        await subscriptionB.cancel();
      },
    );

    test(
      'never leaks one user/organization\'s preference into another\'s read',
      () async {
        await repository.save(
          preferences:
              CommunicationPreferences.defaults(
                organizationId: 'org-1',
                userId: 'user-1',
              ).withChannelFrequency(
                category: AppNotificationCategory.crm,
                channel: CommunicationChannel.push,
                frequency: CommunicationFrequency.disabled,
              ),
        );

        final otherUserResult = await repository.get(
          organizationId: 'org-1',
          userId: 'user-2',
        );
        final otherOrgResult = await repository.get(
          organizationId: 'org-2',
          userId: 'user-1',
        );

        for (final result in <AppResult<CommunicationPreferences>>[
          otherUserResult,
          otherOrgResult,
        ]) {
          final preferences =
              (result as AppSuccess<CommunicationPreferences>).value;
          expect(
            preferences.allows(
              AppNotificationCategory.crm,
              CommunicationChannel.push,
            ),
            isTrue,
            reason: 'must never see user-1/org-1\'s disabled preference',
          );
        }
      },
    );
  });
}

/// In-memory [CommunicationPreferencesDataSource] fake, keyed by
/// `(organizationId, userId)` — the same isolation key the real Firestore
/// path (`organizations/{organizationId}/communicationPreferences/{userId}`)
/// enforces structurally. [watch] is backed by a broadcast
/// [StreamController] per key so multiple independent subscriptions (two
/// simulated devices) all observe the same [upsert].
final class _FakeCommunicationPreferencesDataSource
    implements CommunicationPreferencesDataSource {
  final Map<String, CommunicationPreferencesDto> _stored =
      <String, CommunicationPreferencesDto>{};
  final Map<String, StreamController<CommunicationPreferencesDto?>>
  _controllers = <String, StreamController<CommunicationPreferencesDto?>>{};

  String _key(String organizationId, String userId) =>
      '$organizationId::$userId';

  StreamController<CommunicationPreferencesDto?> _controllerFor(String key) {
    return _controllers.putIfAbsent(
      key,
      () => StreamController<CommunicationPreferencesDto?>.broadcast(),
    );
  }

  @override
  Future<CommunicationPreferencesDto?> getById({
    required String organizationId,
    required String userId,
  }) async {
    return _stored[_key(organizationId, userId)];
  }

  @override
  Stream<CommunicationPreferencesDto?> watch({
    required String organizationId,
    required String userId,
  }) {
    final key = _key(organizationId, userId);
    return _controllerFor(key).stream;
  }

  @override
  Future<void> upsert(CommunicationPreferencesDto dto) async {
    final key = _key(dto.organizationId, dto.userId);
    _stored[key] = dto;
    _controllerFor(key).add(dto);
  }
}
