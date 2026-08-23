import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/audit_log/audit_log.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockAuditLogRepository extends Mock implements AuditLogRepository {}

class _MockMembershipRepository extends Mock implements MembershipRepository {}

void main() {
  group('ListAuditLogEntriesUseCase', () {
    late _MockAuditLogRepository auditLogRepository;
    late _MockMembershipRepository membershipRepository;
    late PermissionService permissionService;
    late ListAuditLogEntriesUseCase useCase;

    Membership buildMembership(String roleName) {
      return Membership(
        id: 'user-1',
        organizationId: 'org-1',
        userId: 'user-1',
        roleId: roleName,
        roleName: roleName,
        status: MembershipStatus.active,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'user-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'user-1',
      );
    }

    AuditLogEntry buildEntry() {
      return AuditLogEntry(
        id: 'log-1',
        organizationId: 'org-1',
        actorUserId: 'owner-1',
        actorName: 'Owner',
        action: AuditAction.roleChanged,
        entityType: 'membership',
        entityId: 'user-2',
        timestamp: DateTime.utc(2026, 1, 1),
      );
    }

    setUp(() {
      auditLogRepository = _MockAuditLogRepository();
      membershipRepository = _MockMembershipRepository();
      permissionService = PermissionService(membershipRepository);
      useCase = ListAuditLogEntriesUseCase(
        auditLogRepository,
        permissionService,
      );
    });

    test('OWNER (has audit.log.view) receives the entries from the '
        'repository', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'user-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(buildMembership('OWNER')),
      );
      when(
        () => auditLogRepository.listByOrganization(
          organizationId: 'org-1',
          limit: 50,
          before: null,
          from: null,
          to: null,
          action: null,
        ),
      ).thenAnswer(
        (_) async => AppSuccess<List<AuditLogEntry>>([buildEntry()]),
      );

      final result = await useCase.call(
        organizationId: 'org-1',
        requestedByUserId: 'user-1',
      );

      expect(result, isA<AppSuccess<List<AuditLogEntry>>>());
      expect((result as AppSuccess<List<AuditLogEntry>>).value, hasLength(1));
    });

    test('SALES_REP (no audit.log.view) is denied without ever reaching the '
        'repository', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'user-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(buildMembership('SALES_REP')),
      );

      final result = await useCase.call(
        organizationId: 'org-1',
        requestedByUserId: 'user-1',
      );

      expect(result, isA<AppFailure<List<AuditLogEntry>>>());
      expect(
        (result as AppFailure<List<AuditLogEntry>>).failure,
        isA<PermissionFailure>(),
      );
      verifyNever(
        () => auditLogRepository.listByOrganization(
          organizationId: any(named: 'organizationId'),
          limit: any(named: 'limit'),
          before: any(named: 'before'),
          from: any(named: 'from'),
          to: any(named: 'to'),
          action: any(named: 'action'),
        ),
      );
    });

    test('a user with no Membership at all is denied', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'stranger',
        ),
      ).thenAnswer(
        (_) async => AppFailure<Membership>(
          const NotFoundFailure('Membership not found.'),
        ),
      );

      final result = await useCase.call(
        organizationId: 'org-1',
        requestedByUserId: 'stranger',
      );

      expect(result, isA<AppFailure<List<AuditLogEntry>>>());
      expect(
        (result as AppFailure<List<AuditLogEntry>>).failure,
        isA<PermissionFailure>(),
      );
    });

    test('returns a ValidationFailure without checking permissions when '
        'required fields are blank', () async {
      final result = await useCase.call(
        organizationId: '',
        requestedByUserId: '',
      );

      expect(result, isA<AppFailure<List<AuditLogEntry>>>());
      expect(
        (result as AppFailure<List<AuditLogEntry>>).failure,
        isA<ValidationFailure>(),
      );
      verifyNever(
        () => membershipRepository.getByUser(
          organizationId: any(named: 'organizationId'),
          userId: any(named: 'userId'),
        ),
      );
    });
  });
}
