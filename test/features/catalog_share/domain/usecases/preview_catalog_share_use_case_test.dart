import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog_share/catalog_share.dart';

class _MockCatalogShareLookupRepository extends Mock
    implements CatalogShareLookupRepository {}

void main() {
  group('PreviewCatalogShareUseCase', () {
    late _MockCatalogShareLookupRepository repository;
    late PreviewCatalogShareUseCase useCase;

    const preview = CatalogSharePreview(outcome: CatalogShareOutcome.valid);

    setUp(() {
      repository = _MockCatalogShareLookupRepository();
      useCase = PreviewCatalogShareUseCase(repository);
    });

    test('delegates to the repository with a trimmed token', () async {
      when(
        () => repository.preview(token: any(named: 'token')),
      ).thenAnswer((_) async => const AppSuccess<CatalogSharePreview>(preview));

      final result = await useCase.call(token: '  token-1  ');

      expect(result, isA<AppSuccess<CatalogSharePreview>>());
      verify(() => repository.preview(token: 'token-1')).called(1);
    });

    test('returns a ValidationFailure without calling the repository when '
        'token is blank', () async {
      final result = await useCase.call(token: '   ');

      expect(result, isA<AppFailure<CatalogSharePreview>>());
      verifyNever(() => repository.preview(token: any(named: 'token')));
    });
  });
}
