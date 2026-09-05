import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/privacy/privacy.dart';

void main() {
  test('conceder e revogar registram finalidade, data e hora em UTC', () async {
    final repository = _FakeConsentRepository();
    final grantedAt = DateTime.parse('2026-09-05T09:30:00-03:00');
    final revokedAt = grantedAt.add(const Duration(hours: 2));

    await GrantConsent(repository)(
      organizationId: 'org-a',
      userId: 'user-a',
      purpose: ConsentPurpose.location,
      grantedAt: grantedAt,
    );
    await RevokeConsent(repository)(
      organizationId: 'org-a',
      userId: 'user-a',
      purpose: ConsentPurpose.location,
      revokedAt: revokedAt,
    );

    expect(repository.records, hasLength(2));
    expect(repository.records.first.purpose, ConsentPurpose.location);
    expect(repository.records.first.granted, isTrue);
    expect(repository.records.first.recordedAt, grantedAt.toUtc());
    expect(repository.records.last.granted, isFalse);
    expect(repository.records.last.recordedAt, revokedAt.toUtc());
  });

  test('funcionalidade dependente inicia desativada sem opt-in', () async {
    final repository = _FakeConsentRepository();
    final access = WatchConsentAccess(repository)(
      organizationId: 'org-a',
      userId: 'user-a',
      purpose: ConsentPurpose.location,
    );

    expect(
      access,
      emits(
        isA<AppSuccess<bool>>().having(
          (result) => result.value,
          'acesso',
          isFalse,
        ),
      ),
    );
    repository.emit();
  });

  test('revogação desativa funcionalidade imediatamente', () async {
    final repository = _FakeConsentRepository();
    final values = <bool>[];
    final subscription =
        WatchConsentAccess(repository)(
          organizationId: 'org-a',
          userId: 'user-a',
          purpose: ConsentPurpose.location,
        ).listen((result) {
          if (result case AppSuccess<bool>(:final value)) values.add(value);
        });

    await GrantConsent(repository)(
      organizationId: 'org-a',
      userId: 'user-a',
      purpose: ConsentPurpose.location,
      grantedAt: DateTime.utc(2026, 9, 5, 12),
    );
    await RevokeConsent(repository)(
      organizationId: 'org-a',
      userId: 'user-a',
      purpose: ConsentPurpose.location,
      revokedAt: DateTime.utc(2026, 9, 5, 13),
    );
    await Future<void>.delayed(Duration.zero);

    expect(values, <bool>[true, false]);
    await subscription.cancel();
  });

  test('listagem isola registros por organização e usuário', () async {
    final repository = _FakeConsentRepository();
    repository.records.addAll(<ConsentRecord>[
      _record('org-a', 'user-a'),
      _record('org-b', 'user-a'),
      _record('org-a', 'user-b'),
    ]);

    final result = await ListUserConsents(repository)(
      organizationId: 'org-a',
      userId: 'user-a',
    );
    final records = (result as AppSuccess<List<ConsentRecord>>).value;

    expect(records, hasLength(1));
    expect(records.single.organizationId, 'org-a');
    expect(records.single.userId, 'user-a');
  });
}

ConsentRecord _record(String organizationId, String userId) => ConsentRecord(
  organizationId: organizationId,
  userId: userId,
  purpose: ConsentPurpose.location,
  granted: true,
  recordedAt: DateTime.utc(2026),
);

final class _FakeConsentRepository implements ConsentRepository {
  final records = <ConsentRecord>[];
  final _changes = StreamController<void>.broadcast();

  void emit() => _changes.add(null);

  @override
  Future<AppResult<void>> appendConsentRecord(ConsentRecord record) async {
    records.add(record);
    emit();
    return const AppSuccess<void>(null);
  }

  @override
  Future<AppResult<List<ConsentRecord>>> listUserConsents({
    required String organizationId,
    required String userId,
  }) async => AppSuccess<List<ConsentRecord>>(
    records
        .where(
          (record) =>
              record.organizationId == organizationId &&
              record.userId == userId,
        )
        .toList(),
  );

  @override
  Stream<AppResult<List<ConsentRecord>>> watchUserConsents({
    required String organizationId,
    required String userId,
  }) => _changes.stream.map(
    (_) => AppSuccess<List<ConsentRecord>>(
      records
          .where(
            (record) =>
                record.organizationId == organizationId &&
                record.userId == userId,
          )
          .toList(),
    ),
  );
}
