import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/features/catalog_share/catalog_share.dart';

class _MockCatalogShareLookupRepository extends Mock
    implements CatalogShareLookupRepository {}

void main() {
  group('RegisterCatalogShareOpenUseCase', () {
    late _MockCatalogShareLookupRepository repository;
    late RegisterCatalogShareOpenUseCase useCase;

    setUp(() {
      repository = _MockCatalogShareLookupRepository();
      useCase = RegisterCatalogShareOpenUseCase(repository);
    });

    test('delegates to the repository with a trimmed token', () async {
      when(
        () => repository.registerOpen(token: any(named: 'token')),
      ).thenAnswer((_) async {});

      await useCase.call(token: '  token-1  ');

      verify(() => repository.registerOpen(token: 'token-1')).called(1);
    });

    test(
      'never calls the repository for a blank token, and never throws',
      () async {
        await useCase.call(token: '   ');

        verifyNever(() => repository.registerOpen(token: any(named: 'token')));
      },
    );
  });
}
