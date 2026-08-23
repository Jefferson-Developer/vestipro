import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/audit_log/audit_log.dart';

class _MockAuditLogRepository extends Mock implements AuditLogRepository {}

void main() {
  group('RecordAuditLogUseCase', () {
    late _MockAuditLogRepository repository;
    late RecordAuditLogUseCase useCase;

    setUpAll(() {
      registerFallbackValue(
        AuditLogEntry(
          id: 'fallback',
          organizationId: 'org-1',
          actorUserId: 'user-1',
          actorName: 'Ana',
          action: AuditAction.roleChanged,
          entityType: 'membership',
          entityId: 'user-2',
          timestamp: DateTime.utc(2026, 1, 1),
        ),
      );
    });

    setUp(() {
      repository = _MockAuditLogRepository();
      useCase = RecordAuditLogUseCase(repository);
    });

    test('records a well-formed entry with the given data, trimmed', () async {
      when(() => repository.record(any())).thenAnswer(
        (invocation) async => AppSuccess<AuditLogEntry>(
          invocation.positionalArguments.first as AuditLogEntry,
        ),
      );

      final result = await useCase.call(
        organizationId: ' org-1 ',
        actorUserId: ' user-1 ',
        actorName: ' Ana Souza ',
        action: AuditAction.userDeactivated,
        entityType: ' membership ',
        entityId: ' user-2 ',
        previousValue: <String, Object?>{'status': 'active'},
        newValue: <String, Object?>{'status': 'inactive'},
      );

      expect(result, isA<AppSuccess<AuditLogEntry>>());
      final entry = (result as AppSuccess<AuditLogEntry>).value;
      expect(entry.organizationId, 'org-1');
      expect(entry.actorUserId, 'user-1');
      expect(entry.actorName, 'Ana Souza');
      expect(entry.action, AuditAction.userDeactivated);
      expect(entry.entityType, 'membership');
      expect(entry.entityId, 'user-2');
      expect(entry.previousValue, <String, Object?>{'status': 'active'});
      expect(entry.newValue, <String, Object?>{'status': 'inactive'});
      expect(entry.id, isNotEmpty);
    });

    test(
      'strips sensitive keys before handing the entry to the repository',
      () async {
        when(() => repository.record(any())).thenAnswer(
          (invocation) async => AppSuccess<AuditLogEntry>(
            invocation.positionalArguments.first as AuditLogEntry,
          ),
        );

        await useCase.call(
          organizationId: 'org-1',
          actorUserId: 'user-1',
          actorName: 'Ana Souza',
          action: AuditAction.userDeactivated,
          entityType: 'membership',
          entityId: 'user-2',
          previousValue: <String, Object?>{
            'roleId': 'SALES_REP',
            'password': 'super-secret',
          },
        );

        final captured =
            verify(() => repository.record(captureAny())).captured.single
                as AuditLogEntry;
        expect(captured.previousValue, <String, Object?>{
          'roleId': 'SALES_REP',
        });
      },
    );

    test('returns a ValidationFailure without calling the repository when '
        'required fields are blank', () async {
      final result = await useCase.call(
        organizationId: '',
        actorUserId: '',
        actorName: '',
        action: AuditAction.roleChanged,
        entityType: '',
        entityId: '',
      );

      expect(result, isA<AppFailure<AuditLogEntry>>());
      final failure = (result as AppFailure<AuditLogEntry>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors.keys,
        containsAll(<String>[
          'organizationId',
          'actorUserId',
          'actorName',
          'entityType',
          'entityId',
        ]),
      );
      verifyNever(() => repository.record(any()));
    });

    test('propagates a Failure raised by the repository', () async {
      when(() => repository.record(any())).thenAnswer(
        (_) async => AppFailure<AuditLogEntry>(
          const ConnectivityFailure('No connection.'),
        ),
      );

      final result = await useCase.call(
        organizationId: 'org-1',
        actorUserId: 'user-1',
        actorName: 'Ana Souza',
        action: AuditAction.roleChanged,
        entityType: 'membership',
        entityId: 'user-2',
      );

      expect(result, isA<AppFailure<AuditLogEntry>>());
      expect(
        (result as AppFailure<AuditLogEntry>).failure,
        isA<ConnectivityFailure>(),
      );
    });
  });
}
