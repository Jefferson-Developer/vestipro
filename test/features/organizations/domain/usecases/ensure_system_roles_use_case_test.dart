import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockRoleRepository extends Mock implements RoleRepository {}

void main() {
  group('EnsureSystemRolesUseCase', () {
    late _MockRoleRepository repository;
    late EnsureSystemRolesUseCase useCase;

    Role buildRole(String code, {bool isSystemRole = true}) {
      return Role(
        id: code,
        organizationId: 'org-1',
        name: code,
        isSystemRole: isSystemRole,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'user-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'user-1',
      );
    }

    setUp(() {
      repository = _MockRoleRepository();
      useCase = EnsureSystemRolesUseCase(repository);
    });

    test('creates the 7 initial system roles, all marked isSystemRole, when '
        'none exist yet', () async {
      when(
        () => repository.listByOrganization('org-1'),
      ).thenAnswer((_) async => const AppSuccess<List<Role>>(<Role>[]));
      when(
        () => repository.create(
          id: any(named: 'id'),
          organizationId: any(named: 'organizationId'),
          name: any(named: 'name'),
          isSystemRole: any(named: 'isSystemRole'),
          createdBy: any(named: 'createdBy'),
        ),
      ).thenAnswer((invocation) async {
        final code = invocation.namedArguments[#id] as String;
        return AppSuccess<Role>(buildRole(code));
      });

      final result = await useCase.call(
        organizationId: ' org-1 ',
        createdBy: ' user-1 ',
      );

      expect(result, isA<AppSuccess<List<Role>>>());
      final roles = (result as AppSuccess<List<Role>>).value;
      expect(roles, hasLength(7));
      expect(roles.every((role) => role.isSystemRole), isTrue);
      expect(roles.map((role) => role.name).toSet(), <String>{
        'OWNER',
        'ADMIN',
        'SALES_MANAGER',
        'SALES_REP',
        'SALES_ASSISTANT',
        'FINANCE',
        'READ_ONLY',
      });
      verify(
        () => repository.create(
          id: any(named: 'id'),
          organizationId: 'org-1',
          name: any(named: 'name'),
          isSystemRole: true,
          createdBy: 'user-1',
        ),
      ).called(7);
    });

    test(
      'is idempotent: does not recreate a role that already exists',
      () async {
        when(() => repository.listByOrganization('org-1')).thenAnswer(
          (_) async => AppSuccess<List<Role>>(<Role>[buildRole('OWNER')]),
        );
        when(
          () => repository.create(
            id: any(named: 'id'),
            organizationId: any(named: 'organizationId'),
            name: any(named: 'name'),
            isSystemRole: any(named: 'isSystemRole'),
            createdBy: any(named: 'createdBy'),
          ),
        ).thenAnswer((invocation) async {
          final code = invocation.namedArguments[#id] as String;
          return AppSuccess<Role>(buildRole(code));
        });

        final result = await useCase.call(
          organizationId: 'org-1',
          createdBy: 'user-1',
        );

        expect(result, isA<AppSuccess<List<Role>>>());
        final roles = (result as AppSuccess<List<Role>>).value;
        expect(roles, hasLength(7));
        verifyNever(
          () => repository.create(
            id: 'OWNER',
            organizationId: any(named: 'organizationId'),
            name: any(named: 'name'),
            isSystemRole: any(named: 'isSystemRole'),
            createdBy: any(named: 'createdBy'),
          ),
        );
        verify(
          () => repository.create(
            id: 'ADMIN',
            organizationId: any(named: 'organizationId'),
            name: any(named: 'name'),
            isSystemRole: any(named: 'isSystemRole'),
            createdBy: any(named: 'createdBy'),
          ),
        ).called(1);
      },
    );

    test('returns a ValidationFailure without calling the repository when '
        'required fields are blank', () async {
      final result = await useCase.call(organizationId: '', createdBy: '');

      expect(result, isA<AppFailure<List<Role>>>());
      final failure = (result as AppFailure<List<Role>>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors.keys,
        containsAll(<String>['organizationId', 'createdBy']),
      );
      verifyNever(() => repository.listByOrganization(any()));
    });

    test('propagates a failure from listByOrganization without attempting '
        'to create anything', () async {
      when(() => repository.listByOrganization('org-1')).thenAnswer(
        (_) async =>
            AppFailure<List<Role>>(const ConnectivityFailure('No connection.')),
      );

      final result = await useCase.call(
        organizationId: 'org-1',
        createdBy: 'user-1',
      );

      expect(result, isA<AppFailure<List<Role>>>());
      expect(
        (result as AppFailure<List<Role>>).failure,
        isA<ConnectivityFailure>(),
      );
      verifyNever(
        () => repository.create(
          id: any(named: 'id'),
          organizationId: any(named: 'organizationId'),
          name: any(named: 'name'),
          isSystemRole: any(named: 'isSystemRole'),
          createdBy: any(named: 'createdBy'),
        ),
      );
    });
  });
}
