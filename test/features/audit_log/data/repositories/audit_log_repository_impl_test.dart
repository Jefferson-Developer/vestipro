import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/audit_log/audit_log.dart';
import 'package:vestipro/features/audit_log/data/datasources/audit_log_data_source.dart';
import 'package:vestipro/features/audit_log/data/dtos/audit_log_entry_dto.dart';
import 'package:vestipro/features/audit_log/data/mappers/audit_log_entry_mapper.dart';
import 'package:vestipro/features/audit_log/data/repositories/audit_log_repository_impl.dart';

class _MockAuditLogDataSource extends Mock implements AuditLogDataSource {}

void main() {
  group('AuditLogRepositoryImpl', () {
    late _MockAuditLogDataSource dataSource;
    late AuditLogRepositoryImpl repository;

    AuditLogEntryDto buildDto({
      String id = 'log-1',
      String organizationId = 'org-1',
      String action = 'role.changed',
    }) {
      return AuditLogEntryDto(
        id: id,
        organizationId: organizationId,
        actorUserId: 'user-1',
        actorName: 'Ana Souza',
        action: action,
        entityType: 'membership',
        entityId: 'user-2',
        timestamp: DateTime.utc(2026, 1, 1),
      );
    }

    AuditLogEntry buildEntry() {
      return AuditLogEntry(
        id: 'log-1',
        organizationId: 'org-1',
        actorUserId: 'user-1',
        actorName: 'Ana Souza',
        action: AuditAction.roleChanged,
        entityType: 'membership',
        entityId: 'user-2',
        timestamp: DateTime.utc(2026, 1, 1),
      );
    }

    setUpAll(() {
      registerFallbackValue(buildDto());
    });

    setUp(() {
      dataSource = _MockAuditLogDataSource();
      repository = AuditLogRepositoryImpl(
        dataSource: dataSource,
        mapper: const AuditLogEntryMapper(),
      );
    });

    group('record', () {
      test(
        'returns a success mapping the DTO recorded by the datasource',
        () async {
          when(
            () => dataSource.record(any()),
          ).thenAnswer((_) async => buildDto());

          final result = await repository.record(buildEntry());

          expect(result, isA<AppSuccess<AuditLogEntry>>());
          final entity = (result as AppSuccess<AuditLogEntry>).value;
          expect(entity.id, 'log-1');
          expect(entity.organizationId, 'org-1');
          expect(entity.action, AuditAction.roleChanged);
        },
      );

      test(
        'maps an AppException thrown by the datasource to a Failure',
        () async {
          when(
            () => dataSource.record(any()),
          ).thenThrow(const ConflictException('Entry already exists.'));

          final result = await repository.record(buildEntry());

          expect(result, isA<AppFailure<AuditLogEntry>>());
          expect(
            (result as AppFailure<AuditLogEntry>).failure,
            isA<ConflictFailure>(),
          );
        },
      );

      test('maps a generic exception thrown by the datasource to an '
          'UnexpectedFailure', () async {
        when(() => dataSource.record(any())).thenThrow(StateError('boom'));

        final result = await repository.record(buildEntry());

        expect(result, isA<AppFailure<AuditLogEntry>>());
        expect(
          (result as AppFailure<AuditLogEntry>).failure,
          isA<UnexpectedFailure>(),
        );
      });
    });

    group('listByOrganization', () {
      test('delegates to the datasource with the given organizationId and '
          'never mixes in an entry from another organization', () async {
        final entriesOrg1 = <AuditLogEntryDto>[
          buildDto(id: 'log-1', organizationId: 'org-1'),
          buildDto(id: 'log-2', organizationId: 'org-1'),
        ];

        when(
          () => dataSource.listByOrganization(
            organizationId: 'org-1',
            limit: 50,
            before: null,
            from: null,
            to: null,
            actionCode: null,
          ),
        ).thenAnswer((_) async => entriesOrg1);
        when(
          () => dataSource.listByOrganization(
            organizationId: 'org-2',
            limit: 50,
            before: null,
            from: null,
            to: null,
            actionCode: null,
          ),
        ).thenAnswer(
          (_) async => <AuditLogEntryDto>[
            buildDto(id: 'log-3', organizationId: 'org-2'),
          ],
        );

        final result = await repository.listByOrganization(
          organizationId: 'org-1',
        );

        expect(result, isA<AppSuccess<List<AuditLogEntry>>>());
        final entries = (result as AppSuccess<List<AuditLogEntry>>).value;
        expect(entries, hasLength(2));
        expect(
          entries.every((entry) => entry.organizationId == 'org-1'),
          isTrue,
        );
        verify(
          () => dataSource.listByOrganization(
            organizationId: 'org-1',
            limit: 50,
            before: null,
            from: null,
            to: null,
            actionCode: null,
          ),
        ).called(1);
      });

      test('forwards the AuditAction filter as its raw code', () async {
        when(
          () => dataSource.listByOrganization(
            organizationId: 'org-1',
            limit: 50,
            before: null,
            from: null,
            to: null,
            actionCode: 'user.deactivated',
          ),
        ).thenAnswer((_) async => <AuditLogEntryDto>[]);

        await repository.listByOrganization(
          organizationId: 'org-1',
          action: AuditAction.userDeactivated,
        );

        verify(
          () => dataSource.listByOrganization(
            organizationId: 'org-1',
            limit: 50,
            before: null,
            from: null,
            to: null,
            actionCode: 'user.deactivated',
          ),
        ).called(1);
      });

      test(
        'maps an AppException thrown by the datasource to a Failure',
        () async {
          when(
            () => dataSource.listByOrganization(
              organizationId: 'org-1',
              limit: 50,
              before: null,
              from: null,
              to: null,
              actionCode: null,
            ),
          ).thenThrow(const ForbiddenException('Not allowed.'));

          final result = await repository.listByOrganization(
            organizationId: 'org-1',
          );

          expect(result, isA<AppFailure<List<AuditLogEntry>>>());
          expect(
            (result as AppFailure<List<AuditLogEntry>>).failure,
            isA<PermissionFailure>(),
          );
        },
      );
    });
  });
}
