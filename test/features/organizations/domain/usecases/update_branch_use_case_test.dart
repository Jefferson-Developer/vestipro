import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockBranchRepository extends Mock implements BranchRepository {}

void main() {
  group('UpdateBranchUseCase', () {
    late _MockBranchRepository repository;
    late UpdateBranchUseCase useCase;

    final updatedBranch = Branch(
      id: 'branch-1',
      organizationId: 'org-1',
      companyId: 'company-1',
      name: 'Loja Blumenau Centro',
      type: BranchType.store,
      status: BranchStatus.active,
      version: 2,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'user-1',
      updatedAt: DateTime.utc(2026, 1, 2),
      updatedBy: 'user-2',
    );

    setUp(() {
      repository = _MockBranchRepository();
      useCase = UpdateBranchUseCase(repository);
    });

    setUpAll(() {
      registerFallbackValue(BranchType.store);
      registerFallbackValue(BranchStatus.active);
    });

    test(
      'delegates to the repository and never asks it to change '
      'organizationId/companyId — the use case has no parameter for either',
      () async {
        when(
          () => repository.update(
            organizationId: any(named: 'organizationId'),
            id: any(named: 'id'),
            name: any(named: 'name'),
            type: any(named: 'type'),
            address: any(named: 'address'),
            status: any(named: 'status'),
            updatedBy: any(named: 'updatedBy'),
          ),
        ).thenAnswer((_) async => AppSuccess<Branch>(updatedBranch));

        final result = await useCase.call(
          organizationId: 'org-1',
          id: 'branch-1',
          name: 'Loja Blumenau Centro',
          type: BranchType.store,
          status: BranchStatus.active,
          updatedBy: 'user-2',
        );

        expect(result, isA<AppSuccess<Branch>>());
        final value = (result as AppSuccess<Branch>).value;
        expect(
          value.organizationId,
          'org-1',
          reason:
              'The use case has no parameter to change organizationId; the '
              'value returned must stay the one the fake repository set.',
        );
        expect(
          value.companyId,
          'company-1',
          reason:
              'The use case has no parameter to change companyId; the '
              'value returned must stay the one the fake repository set.',
        );
        verify(
          () => repository.update(
            organizationId: 'org-1',
            id: 'branch-1',
            name: 'Loja Blumenau Centro',
            type: BranchType.store,
            address: null,
            status: BranchStatus.active,
            updatedBy: 'user-2',
          ),
        ).called(1);
      },
    );

    test('returns a ValidationFailure without calling the repository for '
        'blank required fields', () async {
      final result = await useCase.call(
        organizationId: '',
        id: '',
        name: '',
        type: BranchType.store,
        status: BranchStatus.active,
        updatedBy: '',
      );

      expect(result, isA<AppFailure<Branch>>());
      final failure = (result as AppFailure<Branch>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors.keys,
        containsAll(<String>['organizationId', 'id', 'name', 'updatedBy']),
      );
      verifyNever(
        () => repository.update(
          organizationId: any(named: 'organizationId'),
          id: any(named: 'id'),
          name: any(named: 'name'),
          type: any(named: 'type'),
          address: any(named: 'address'),
          status: any(named: 'status'),
          updatedBy: any(named: 'updatedBy'),
        ),
      );
    });
  });
}
