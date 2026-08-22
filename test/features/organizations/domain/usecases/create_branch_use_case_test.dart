import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockBranchRepository extends Mock implements BranchRepository {}

void main() {
  group('CreateBranchUseCase', () {
    late _MockBranchRepository repository;
    late CreateBranchUseCase useCase;

    const address = BranchAddress(
      street: 'Rua XV de Novembro',
      number: '100',
      neighborhood: 'Centro',
      city: 'Blumenau',
      state: 'SC',
      postalCode: '89010-000',
      country: 'BR',
    );

    final branch = Branch(
      id: 'branch-1',
      organizationId: 'org-1',
      companyId: 'company-1',
      name: 'Loja Blumenau',
      type: BranchType.store,
      address: address,
      status: BranchStatus.active,
      version: 1,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'user-1',
      updatedAt: DateTime.utc(2026, 1, 1),
      updatedBy: 'user-1',
    );

    setUp(() {
      repository = _MockBranchRepository();
      useCase = CreateBranchUseCase(repository);
    });

    setUpAll(() {
      registerFallbackValue(address);
      registerFallbackValue(BranchType.store);
    });

    test(
      'delegates to the repository with trimmed fields on a valid payload',
      () async {
        when(
          () => repository.create(
            id: any(named: 'id'),
            organizationId: any(named: 'organizationId'),
            companyId: any(named: 'companyId'),
            name: any(named: 'name'),
            type: any(named: 'type'),
            address: any(named: 'address'),
            createdBy: any(named: 'createdBy'),
          ),
        ).thenAnswer((_) async => AppSuccess<Branch>(branch));

        final result = await useCase.call(
          id: ' branch-1 ',
          organizationId: ' org-1 ',
          companyId: ' company-1 ',
          name: ' Loja Blumenau ',
          type: BranchType.store,
          address: address,
          createdBy: ' user-1 ',
        );

        expect(result, isA<AppSuccess<Branch>>());
        verify(
          () => repository.create(
            id: 'branch-1',
            organizationId: 'org-1',
            companyId: 'company-1',
            name: 'Loja Blumenau',
            type: BranchType.store,
            address: address,
            createdBy: 'user-1',
          ),
        ).called(1);
      },
    );

    test('returns a ValidationFailure without calling the repository when '
        'required fields are blank', () async {
      final result = await useCase.call(
        id: '',
        organizationId: '',
        companyId: '  ',
        name: '',
        type: BranchType.showroom,
        createdBy: '',
      );

      expect(result, isA<AppFailure<Branch>>());
      final failure = (result as AppFailure<Branch>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors.keys,
        containsAll(<String>[
          'id',
          'organizationId',
          'companyId',
          'name',
          'createdBy',
        ]),
      );
      verifyNever(
        () => repository.create(
          id: any(named: 'id'),
          organizationId: any(named: 'organizationId'),
          companyId: any(named: 'companyId'),
          name: any(named: 'name'),
          type: any(named: 'type'),
          address: any(named: 'address'),
          createdBy: any(named: 'createdBy'),
        ),
      );
    });

    test('propagates a network failure from the repository', () async {
      when(
        () => repository.create(
          id: any(named: 'id'),
          organizationId: any(named: 'organizationId'),
          companyId: any(named: 'companyId'),
          name: any(named: 'name'),
          type: any(named: 'type'),
          address: any(named: 'address'),
          createdBy: any(named: 'createdBy'),
        ),
      ).thenAnswer(
        (_) async =>
            AppFailure<Branch>(const ConnectivityFailure('No connection.')),
      );

      final result = await useCase.call(
        id: 'branch-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        name: 'Loja Blumenau',
        type: BranchType.store,
        createdBy: 'user-1',
      );

      expect(result, isA<AppFailure<Branch>>());
      expect(
        (result as AppFailure<Branch>).failure,
        isA<ConnectivityFailure>(),
      );
    });
  });
}
