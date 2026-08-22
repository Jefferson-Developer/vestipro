import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockBranchRepository extends Mock implements BranchRepository {}

void main() {
  group('ListBranchesByCompanyUseCase', () {
    late _MockBranchRepository repository;
    late ListBranchesByCompanyUseCase useCase;

    Branch buildBranch(String id) {
      return Branch(
        id: id,
        organizationId: 'org-1',
        companyId: 'company-1',
        name: 'Loja $id',
        type: BranchType.store,
        status: BranchStatus.active,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'user-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'user-1',
      );
    }

    setUp(() {
      repository = _MockBranchRepository();
      useCase = ListBranchesByCompanyUseCase(repository);
    });

    test('delegates to the repository with the trimmed organizationId/'
        'companyId and returns every branch of that company', () async {
      final branchA = buildBranch('branch-a');
      final branchB = buildBranch('branch-b');

      when(
        () => repository.listByCompany(
          organizationId: 'org-1',
          companyId: 'company-1',
        ),
      ).thenAnswer((_) async => AppSuccess<List<Branch>>([branchA, branchB]));

      final result = await useCase.call(
        organizationId: ' org-1 ',
        companyId: ' company-1 ',
      );

      expect(result, isA<AppSuccess<List<Branch>>>());
      expect(
        (result as AppSuccess<List<Branch>>).value,
        containsAll(<Branch>[branchA, branchB]),
      );
      verify(
        () => repository.listByCompany(
          organizationId: 'org-1',
          companyId: 'company-1',
        ),
      ).called(1);
    });

    test('returns a ValidationFailure without calling the repository for '
        'blank organizationId/companyId', () async {
      final result = await useCase.call(organizationId: '', companyId: '  ');

      expect(result, isA<AppFailure<List<Branch>>>());
      final failure = (result as AppFailure<List<Branch>>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors.keys,
        containsAll(<String>['organizationId', 'companyId']),
      );
      verifyNever(
        () => repository.listByCompany(
          organizationId: any(named: 'organizationId'),
          companyId: any(named: 'companyId'),
        ),
      );
    });
  });
}
