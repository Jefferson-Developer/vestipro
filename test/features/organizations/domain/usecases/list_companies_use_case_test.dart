import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockCompanyRepository extends Mock implements CompanyRepository {}

void main() {
  group('ListCompaniesUseCase', () {
    late _MockCompanyRepository repository;
    late ListCompaniesUseCase useCase;

    final companyA = Company(
      id: 'company-a',
      organizationId: 'org-1',
      name: 'Marca A',
      status: CompanyStatus.active,
      version: 1,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'user-1',
      updatedAt: DateTime.utc(2026, 1, 1),
      updatedBy: 'user-1',
    );

    final companyB = Company(
      id: 'company-b',
      organizationId: 'org-1',
      name: 'Marca B',
      status: CompanyStatus.active,
      version: 1,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'user-1',
      updatedAt: DateTime.utc(2026, 1, 1),
      updatedBy: 'user-1',
    );

    setUp(() {
      repository = _MockCompanyRepository();
      useCase = ListCompaniesUseCase(repository);
    });

    test('delegates to the repository with the trimmed organizationId and '
        'returns every company of that organization', () async {
      when(() => repository.listByOrganization('org-1')).thenAnswer(
        (_) async => AppSuccess<List<Company>>([companyA, companyB]),
      );

      final result = await useCase.call(' org-1 ');

      expect(result, isA<AppSuccess<List<Company>>>());
      expect(
        (result as AppSuccess<List<Company>>).value,
        containsAll(<Company>[companyA, companyB]),
      );
      verify(() => repository.listByOrganization('org-1')).called(1);
    });

    test('returns a ValidationFailure without calling the repository for a '
        'blank organizationId', () async {
      final result = await useCase.call('   ');

      expect(result, isA<AppFailure<List<Company>>>());
      expect(
        (result as AppFailure<List<Company>>).failure,
        isA<ValidationFailure>(),
      );
      verifyNever(() => repository.listByOrganization(any()));
    });
  });
}
