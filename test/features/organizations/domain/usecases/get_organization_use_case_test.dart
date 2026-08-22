import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

void main() {
  group('GetOrganizationUseCase', () {
    late _MockOrganizationRepository repository;
    late GetOrganizationUseCase useCase;

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
      useCase = GetOrganizationUseCase(repository);
    });

    test('returns the repository success trimming the id', () async {
      when(
        () => repository.getById('org-1'),
      ).thenAnswer((_) async => AppSuccess<Organization>(organization));

      final result = await useCase.call(' org-1 ');

      expect(result, isA<AppSuccess<Organization>>());
      verify(() => repository.getById('org-1')).called(1);
    });

    test('returns a ValidationFailure without calling the repository for a '
        'blank id', () async {
      final result = await useCase.call('   ');

      expect(result, isA<AppFailure<Organization>>());
      expect(
        (result as AppFailure<Organization>).failure,
        isA<ValidationFailure>(),
      );
      verifyNever(() => repository.getById(any()));
    });

    test('propagates a NotFoundFailure from the repository', () async {
      when(() => repository.getById('missing')).thenAnswer(
        (_) async => AppFailure<Organization>(
          const NotFoundFailure('Organization not found.'),
        ),
      );

      final result = await useCase.call('missing');

      expect(result, isA<AppFailure<Organization>>());
      expect(
        (result as AppFailure<Organization>).failure,
        isA<NotFoundFailure>(),
      );
    });
  });
}
