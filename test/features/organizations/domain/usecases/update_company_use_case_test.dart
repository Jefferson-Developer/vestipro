import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockCompanyRepository extends Mock implements CompanyRepository {}

void main() {
  group('UpdateCompanyUseCase', () {
    late _MockCompanyRepository repository;
    late UpdateCompanyUseCase useCase;

    final updatedCompany = Company(
      id: 'company-1',
      organizationId: 'org-1',
      name: 'Marca A Renomeada',
      status: CompanyStatus.active,
      version: 2,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'user-1',
      updatedAt: DateTime.utc(2026, 1, 2),
      updatedBy: 'user-2',
    );

    setUp(() {
      repository = _MockCompanyRepository();
      useCase = UpdateCompanyUseCase(repository);
    });

    setUpAll(() {
      registerFallbackValue(CompanyStatus.active);
    });

    test('delegates to the repository and never asks it to change the '
        'organizationId — the use case has no parameter for it', () async {
      when(
        () => repository.update(
          organizationId: any(named: 'organizationId'),
          id: any(named: 'id'),
          name: any(named: 'name'),
          legalName: any(named: 'legalName'),
          taxId: any(named: 'taxId'),
          status: any(named: 'status'),
          updatedBy: any(named: 'updatedBy'),
        ),
      ).thenAnswer((_) async => AppSuccess<Company>(updatedCompany));

      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'company-1',
        name: 'Marca A Renomeada',
        status: CompanyStatus.active,
        updatedBy: 'user-2',
      );

      expect(result, isA<AppSuccess<Company>>());
      expect(
        (result as AppSuccess<Company>).value.organizationId,
        'org-1',
        reason:
            'The use case has no parameter to change organizationId; the '
            'value returned must stay the one the fake repository set.',
      );
      verify(
        () => repository.update(
          organizationId: 'org-1',
          id: 'company-1',
          name: 'Marca A Renomeada',
          legalName: null,
          taxId: null,
          status: CompanyStatus.active,
          updatedBy: 'user-2',
        ),
      ).called(1);
    });

    test('returns a ValidationFailure without calling the repository for '
        'blank required fields', () async {
      final result = await useCase.call(
        organizationId: '',
        id: '',
        name: '',
        status: CompanyStatus.active,
        updatedBy: '',
      );

      expect(result, isA<AppFailure<Company>>());
      final failure = (result as AppFailure<Company>).failure;
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
          legalName: any(named: 'legalName'),
          taxId: any(named: 'taxId'),
          status: any(named: 'status'),
          updatedBy: any(named: 'updatedBy'),
        ),
      );
    });
  });
}
