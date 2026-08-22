import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

void main() {
  group('CreateOrganizationUseCase', () {
    late _MockOrganizationRepository repository;
    late CreateOrganizationUseCase useCase;

    final organization = Organization(
      id: 'org-1',
      name: 'Grupo Fashion XPTO',
      slug: 'grupo-fashion-xpto',
      settings: const OrganizationSettings(
        currency: 'BRL',
        country: 'BR',
        defaultLanguage: 'pt-BR',
      ),
      status: OrganizationStatus.active,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'user-1',
      updatedAt: DateTime.utc(2026, 1, 1),
      updatedBy: 'user-1',
    );

    setUp(() {
      repository = _MockOrganizationRepository();
      useCase = CreateOrganizationUseCase(repository);
    });

    setUpAll(() {
      registerFallbackValue(
        const OrganizationSettings(
          currency: 'BRL',
          country: 'BR',
          defaultLanguage: 'pt-BR',
        ),
      );
    });

    test(
      'delegates to the repository with trimmed fields on a valid payload',
      () async {
        when(
          () => repository.create(
            id: any(named: 'id'),
            name: any(named: 'name'),
            slug: any(named: 'slug'),
            settings: any(named: 'settings'),
            createdBy: any(named: 'createdBy'),
          ),
        ).thenAnswer((_) async => AppSuccess<Organization>(organization));

        final result = await useCase.call(
          id: ' org-1 ',
          name: ' Grupo Fashion XPTO ',
          slug: ' grupo-fashion-xpto ',
          currency: 'BRL',
          country: 'BR',
          defaultLanguage: 'pt-BR',
          createdBy: ' user-1 ',
        );

        expect(result, isA<AppSuccess<Organization>>());
        verify(
          () => repository.create(
            id: 'org-1',
            name: 'Grupo Fashion XPTO',
            slug: 'grupo-fashion-xpto',
            settings: const OrganizationSettings(
              currency: 'BRL',
              country: 'BR',
              defaultLanguage: 'pt-BR',
            ),
            createdBy: 'user-1',
          ),
        ).called(1);
      },
    );

    test('returns a ValidationFailure without calling the repository when '
        'required fields are blank', () async {
      final result = await useCase.call(
        id: '',
        name: '  ',
        slug: '',
        currency: 'BRL',
        country: 'BR',
        defaultLanguage: 'pt-BR',
        createdBy: '',
      );

      expect(result, isA<AppFailure<Organization>>());
      final failure = (result as AppFailure<Organization>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors.keys,
        containsAll(<String>['id', 'name', 'slug', 'createdBy']),
      );
      verifyNever(
        () => repository.create(
          id: any(named: 'id'),
          name: any(named: 'name'),
          slug: any(named: 'slug'),
          settings: any(named: 'settings'),
          createdBy: any(named: 'createdBy'),
        ),
      );
    });

    test('returns a ValidationFailure without calling the repository when '
        'settings are invalid', () async {
      final result = await useCase.call(
        id: 'org-1',
        name: 'Grupo Fashion XPTO',
        slug: 'grupo-fashion-xpto',
        currency: '',
        country: 'BR',
        defaultLanguage: 'pt-BR',
        createdBy: 'user-1',
      );

      expect(result, isA<AppFailure<Organization>>());
      expect(
        (result as AppFailure<Organization>).failure,
        isA<ValidationFailure>(),
      );
      verifyNever(
        () => repository.create(
          id: any(named: 'id'),
          name: any(named: 'name'),
          slug: any(named: 'slug'),
          settings: any(named: 'settings'),
          createdBy: any(named: 'createdBy'),
        ),
      );
    });

    test('propagates a network failure from the repository', () async {
      when(
        () => repository.create(
          id: any(named: 'id'),
          name: any(named: 'name'),
          slug: any(named: 'slug'),
          settings: any(named: 'settings'),
          createdBy: any(named: 'createdBy'),
        ),
      ).thenAnswer(
        (_) async => AppFailure<Organization>(
          const ConnectivityFailure('No connection.'),
        ),
      );

      final result = await useCase.call(
        id: 'org-1',
        name: 'Grupo Fashion XPTO',
        slug: 'grupo-fashion-xpto',
        currency: 'BRL',
        country: 'BR',
        defaultLanguage: 'pt-BR',
        createdBy: 'user-1',
      );

      expect(result, isA<AppFailure<Organization>>());
      expect(
        (result as AppFailure<Organization>).failure,
        isA<ConnectivityFailure>(),
      );
    });
  });
}
