import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockCompanyRepository extends Mock implements CompanyRepository {}

void main() {
  group('CreateCompanyUseCase', () {
    late _MockCompanyRepository repository;
    late CreateCompanyUseCase useCase;

    final company = Company(
      id: 'company-1',
      organizationId: 'org-1',
      name: 'Marca A',
      legalName: 'Marca A Confecções Ltda',
      status: CompanyStatus.active,
      version: 1,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'user-1',
      updatedAt: DateTime.utc(2026, 1, 1),
      updatedBy: 'user-1',
    );

    setUp(() {
      repository = _MockCompanyRepository();
      useCase = CreateCompanyUseCase(repository);
    });

    test(
      'delegates to the repository with trimmed fields on a valid payload',
      () async {
        when(
          () => repository.create(
            id: any(named: 'id'),
            organizationId: any(named: 'organizationId'),
            name: any(named: 'name'),
            legalName: any(named: 'legalName'),
            taxId: any(named: 'taxId'),
            createdBy: any(named: 'createdBy'),
          ),
        ).thenAnswer((_) async => AppSuccess<Company>(company));

        final result = await useCase.call(
          id: ' company-1 ',
          organizationId: ' org-1 ',
          name: ' Marca A ',
          legalName: ' Marca A Confecções Ltda ',
          taxId: '  ',
          createdBy: ' user-1 ',
        );

        expect(result, isA<AppSuccess<Company>>());
        verify(
          () => repository.create(
            id: 'company-1',
            organizationId: 'org-1',
            name: 'Marca A',
            legalName: 'Marca A Confecções Ltda',
            taxId: null,
            createdBy: 'user-1',
          ),
        ).called(1);
      },
    );

    test('returns a ValidationFailure without calling the repository when '
        'required fields are blank', () async {
      final result = await useCase.call(
        id: '',
        organizationId: '  ',
        name: '',
        createdBy: '',
      );

      expect(result, isA<AppFailure<Company>>());
      final failure = (result as AppFailure<Company>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors.keys,
        containsAll(<String>['id', 'organizationId', 'name', 'createdBy']),
      );
      verifyNever(
        () => repository.create(
          id: any(named: 'id'),
          organizationId: any(named: 'organizationId'),
          name: any(named: 'name'),
          legalName: any(named: 'legalName'),
          taxId: any(named: 'taxId'),
          createdBy: any(named: 'createdBy'),
        ),
      );
    });

    test('propagates a network failure from the repository', () async {
      when(
        () => repository.create(
          id: any(named: 'id'),
          organizationId: any(named: 'organizationId'),
          name: any(named: 'name'),
          legalName: any(named: 'legalName'),
          taxId: any(named: 'taxId'),
          createdBy: any(named: 'createdBy'),
        ),
      ).thenAnswer(
        (_) async =>
            AppFailure<Company>(const ConnectivityFailure('No connection.')),
      );

      final result = await useCase.call(
        id: 'company-1',
        organizationId: 'org-1',
        name: 'Marca A',
        createdBy: 'user-1',
      );

      expect(result, isA<AppFailure<Company>>());
      expect(
        (result as AppFailure<Company>).failure,
        isA<ConnectivityFailure>(),
      );
    });
  });
}
