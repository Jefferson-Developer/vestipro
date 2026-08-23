import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/audit_log/audit_log.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockAuditLogRepository extends Mock implements AuditLogRepository {}

void main() {
  group('AssignRoleToUserUseCase', () {
    late _MockMembershipRepository repository;
    late _MockAuditLogRepository auditLogRepository;
    late AssignRoleToUserUseCase useCase;

    Membership buildMembership({
      String roleId = 'SALES_REP',
      String roleName = 'SALES_REP',
      List<String> teamIds = const <String>[],
      MembershipStatus status = MembershipStatus.active,
    }) {
      return Membership(
        id: 'user-1',
        organizationId: 'org-1',
        userId: 'user-1',
        roleId: roleId,
        roleName: roleName,
        teamIds: teamIds,
        status: status,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'user-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'user-1',
      );
    }

    setUpAll(() {
      registerFallbackValue(MembershipStatus.active);
      registerFallbackValue(
        AuditLogEntry(
          id: 'fallback',
          organizationId: 'org-1',
          actorUserId: 'user-owner',
          actorName: 'Owner',
          action: AuditAction.roleChanged,
          entityType: 'membership',
          entityId: 'user-1',
          timestamp: DateTime.utc(2026, 1, 1),
        ),
      );
    });

    setUp(() {
      repository = _MockMembershipRepository();
      auditLogRepository = _MockAuditLogRepository();
      useCase = AssignRoleToUserUseCase(repository, auditLogRepository);

      when(() => auditLogRepository.record(any())).thenAnswer(
        (invocation) async => AppSuccess<AuditLogEntry>(
          invocation.positionalArguments.first as AuditLogEntry,
        ),
      );
    });

    test('creates a new Membership when the user has none yet, and records '
        'a role.changed audit log entry with no previousValue', () async {
      when(
        () => repository.getByUser(organizationId: 'org-1', userId: 'user-1'),
      ).thenAnswer(
        (_) async => AppFailure<Membership>(
          const NotFoundFailure(
            'Membership not found.',
            code: 'membership_not_found',
          ),
        ),
      );
      when(
        () => repository.create(
          organizationId: 'org-1',
          userId: 'user-1',
          roleId: 'SALES_REP',
          roleName: 'SALES_REP',
          createdBy: 'user-owner',
        ),
      ).thenAnswer((_) async => AppSuccess<Membership>(buildMembership()));

      final result = await useCase.call(
        organizationId: ' org-1 ',
        userId: ' user-1 ',
        roleId: ' SALES_REP ',
        roleName: ' SALES_REP ',
        updatedBy: ' user-owner ',
        actorName: ' Owner Name ',
      );

      expect(result, isA<AppSuccess<Membership>>());
      verify(
        () => repository.create(
          organizationId: 'org-1',
          userId: 'user-1',
          roleId: 'SALES_REP',
          roleName: 'SALES_REP',
          createdBy: 'user-owner',
        ),
      ).called(1);
      verifyNever(
        () => repository.update(
          organizationId: any(named: 'organizationId'),
          userId: any(named: 'userId'),
          roleId: any(named: 'roleId'),
          roleName: any(named: 'roleName'),
          teamIds: any(named: 'teamIds'),
          status: any(named: 'status'),
          updatedBy: any(named: 'updatedBy'),
        ),
      );

      final capturedEntry =
          verify(() => auditLogRepository.record(captureAny())).captured.single
              as AuditLogEntry;
      expect(capturedEntry.organizationId, 'org-1');
      expect(capturedEntry.actorUserId, 'user-owner');
      expect(capturedEntry.actorName, 'Owner Name');
      expect(capturedEntry.action, AuditAction.roleChanged);
      expect(capturedEntry.entityType, 'membership');
      expect(capturedEntry.entityId, 'user-1');
      expect(capturedEntry.previousValue, isNull);
      expect(capturedEntry.newValue, <String, Object?>{
        'roleId': 'SALES_REP',
        'roleName': 'SALES_REP',
      });
      expect(capturedEntry.id, isNotEmpty);
    });

    test('updates the roleId/roleName of an existing Membership, preserving '
        'teamIds and status, and records the previous role in the audit log '
        'entry', () async {
      final existing = buildMembership(
        roleId: 'SALES_REP',
        roleName: 'SALES_REP',
        teamIds: const <String>['team-1'],
        status: MembershipStatus.active,
      );
      when(
        () => repository.getByUser(organizationId: 'org-1', userId: 'user-1'),
      ).thenAnswer((_) async => AppSuccess<Membership>(existing));
      when(
        () => repository.update(
          organizationId: 'org-1',
          userId: 'user-1',
          roleId: 'SALES_MANAGER',
          roleName: 'SALES_MANAGER',
          teamIds: const <String>['team-1'],
          status: MembershipStatus.active,
          updatedBy: 'user-owner',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(
          buildMembership(
            roleId: 'SALES_MANAGER',
            roleName: 'SALES_MANAGER',
            teamIds: const <String>['team-1'],
          ),
        ),
      );

      final result = await useCase.call(
        organizationId: 'org-1',
        userId: 'user-1',
        roleId: 'SALES_MANAGER',
        roleName: 'SALES_MANAGER',
        updatedBy: 'user-owner',
        actorName: 'Owner Name',
      );

      expect(result, isA<AppSuccess<Membership>>());
      verify(
        () => repository.update(
          organizationId: 'org-1',
          userId: 'user-1',
          roleId: 'SALES_MANAGER',
          roleName: 'SALES_MANAGER',
          teamIds: const <String>['team-1'],
          status: MembershipStatus.active,
          updatedBy: 'user-owner',
        ),
      ).called(1);
      verifyNever(
        () => repository.create(
          organizationId: any(named: 'organizationId'),
          userId: any(named: 'userId'),
          roleId: any(named: 'roleId'),
          roleName: any(named: 'roleName'),
          createdBy: any(named: 'createdBy'),
        ),
      );

      final capturedEntry =
          verify(() => auditLogRepository.record(captureAny())).captured.single
              as AuditLogEntry;
      expect(capturedEntry.previousValue, <String, Object?>{
        'roleId': 'SALES_REP',
        'roleName': 'SALES_REP',
      });
      expect(capturedEntry.newValue, <String, Object?>{
        'roleId': 'SALES_MANAGER',
        'roleName': 'SALES_MANAGER',
      });
    });

    test('returns a ValidationFailure without calling the repository when '
        'required fields are blank', () async {
      final result = await useCase.call(
        organizationId: '',
        userId: '',
        roleId: '',
        roleName: '',
        updatedBy: '',
        actorName: '',
      );

      expect(result, isA<AppFailure<Membership>>());
      final failure = (result as AppFailure<Membership>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors.keys,
        containsAll(<String>[
          'organizationId',
          'userId',
          'roleId',
          'roleName',
          'updatedBy',
          'actorName',
        ]),
      );
      verifyNever(
        () => repository.getByUser(
          organizationId: any(named: 'organizationId'),
          userId: any(named: 'userId'),
        ),
      );
      verifyNever(() => auditLogRepository.record(any()));
    });

    test('propagates a NotFoundFailure raised when the organization itself '
        'does not exist (create also fails), without recording an audit '
        'log entry', () async {
      when(
        () => repository.getByUser(
          organizationId: 'missing-org',
          userId: 'user-1',
        ),
      ).thenAnswer(
        (_) async => AppFailure<Membership>(
          const NotFoundFailure(
            'Membership not found.',
            code: 'membership_not_found',
          ),
        ),
      );
      when(
        () => repository.create(
          organizationId: 'missing-org',
          userId: 'user-1',
          roleId: 'SALES_REP',
          roleName: 'SALES_REP',
          createdBy: 'user-owner',
        ),
      ).thenAnswer(
        (_) async => AppFailure<Membership>(
          const NotFoundFailure(
            'Organization not found.',
            code: 'organization_not_found',
          ),
        ),
      );

      final result = await useCase.call(
        organizationId: 'missing-org',
        userId: 'user-1',
        roleId: 'SALES_REP',
        roleName: 'SALES_REP',
        updatedBy: 'user-owner',
        actorName: 'Owner Name',
      );

      expect(result, isA<AppFailure<Membership>>());
      expect(
        (result as AppFailure<Membership>).failure,
        isA<NotFoundFailure>(),
      );
      verifyNever(() => auditLogRepository.record(any()));
    });

    test('propagates a non-NotFound failure from getByUser without attempting '
        'to create, update nor recording an audit log entry', () async {
      when(
        () => repository.getByUser(organizationId: 'org-1', userId: 'user-1'),
      ).thenAnswer(
        (_) async =>
            AppFailure<Membership>(const ConnectivityFailure('No connection.')),
      );

      final result = await useCase.call(
        organizationId: 'org-1',
        userId: 'user-1',
        roleId: 'SALES_REP',
        roleName: 'SALES_REP',
        updatedBy: 'user-owner',
        actorName: 'Owner Name',
      );

      expect(result, isA<AppFailure<Membership>>());
      expect(
        (result as AppFailure<Membership>).failure,
        isA<ConnectivityFailure>(),
      );
      verifyNever(
        () => repository.create(
          organizationId: any(named: 'organizationId'),
          userId: any(named: 'userId'),
          roleId: any(named: 'roleId'),
          roleName: any(named: 'roleName'),
          createdBy: any(named: 'createdBy'),
        ),
      );
      verifyNever(
        () => repository.update(
          organizationId: any(named: 'organizationId'),
          userId: any(named: 'userId'),
          roleId: any(named: 'roleId'),
          roleName: any(named: 'roleName'),
          teamIds: any(named: 'teamIds'),
          status: any(named: 'status'),
          updatedBy: any(named: 'updatedBy'),
        ),
      );
      verifyNever(() => auditLogRepository.record(any()));
    });

    test('propagates a Failure from the audit log repository instead of '
        'silently discarding it, even though the Membership mutation itself '
        'already succeeded', () async {
      when(
        () => repository.getByUser(organizationId: 'org-1', userId: 'user-1'),
      ).thenAnswer(
        (_) async => AppFailure<Membership>(
          const NotFoundFailure(
            'Membership not found.',
            code: 'membership_not_found',
          ),
        ),
      );
      when(
        () => repository.create(
          organizationId: 'org-1',
          userId: 'user-1',
          roleId: 'SALES_REP',
          roleName: 'SALES_REP',
          createdBy: 'user-owner',
        ),
      ).thenAnswer((_) async => AppSuccess<Membership>(buildMembership()));
      when(() => auditLogRepository.record(any())).thenAnswer(
        (_) async => AppFailure<AuditLogEntry>(
          const ConnectivityFailure('No connection.'),
        ),
      );

      final result = await useCase.call(
        organizationId: 'org-1',
        userId: 'user-1',
        roleId: 'SALES_REP',
        roleName: 'SALES_REP',
        updatedBy: 'user-owner',
        actorName: 'Owner Name',
      );

      expect(result, isA<AppFailure<Membership>>());
      expect(
        (result as AppFailure<Membership>).failure,
        isA<ConnectivityFailure>(),
      );
    });
  });
}
