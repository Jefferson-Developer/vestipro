import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog/catalog.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('GetFeaturedCollectionsSectionUseCase', () {
    const config = CatalogHomeSectionConfig(
      type: CatalogHomeSectionType.featuredCollections,
      title: 'Coleções em destaque',
      order: 0,
      priority: 0,
      itemLimit: 1,
    );

    test(
      'keeps only active collections, most recent first, capped at itemLimit',
      () async {
        final older = _collection(
          id: 'col-old',
          startDate: DateTime.utc(2025, 1, 1),
        );
        final newer = _collection(
          id: 'col-new',
          startDate: DateTime.utc(2026, 1, 1),
        );
        final closed = _collection(
          id: 'col-closed',
          startDate: DateTime.utc(2026, 6, 1),
          status: CollectionStatus.closed,
        );
        final useCase = GetFeaturedCollectionsSectionUseCase(
          _FakeRepository(
            AppSuccess<List<Collection>>(<Collection>[older, newer, closed]),
          ),
        );

        final result = await useCase(organizationId: 'org-1', config: config);

        final section = (result as AppSuccess<CatalogHomeSection>).value;
        expect(section.items.map((item) => item.id).toList(), <String>[
          'col-new',
        ]);
      },
    );

    test('propagates a repository failure', () async {
      final useCase = GetFeaturedCollectionsSectionUseCase(
        _FakeRepository(
          const AppFailure<List<Collection>>(
            ServerFailure('down', code: 'down'),
          ),
        ),
      );

      final result = await useCase(organizationId: 'org-1', config: config);

      expect(result, isA<AppFailure<CatalogHomeSection>>());
    });

    test(
      'returns an empty section when there are no active collections',
      () async {
        final useCase = GetFeaturedCollectionsSectionUseCase(
          _FakeRepository(const AppSuccess<List<Collection>>(<Collection>[])),
        );

        final result = await useCase(organizationId: 'org-1', config: config);

        final section = (result as AppSuccess<CatalogHomeSection>).value;
        expect(section.isEmpty, isTrue);
      },
    );
  });
}

Collection _collection({
  required String id,
  DateTime? startDate,
  CollectionStatus status = CollectionStatus.active,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Collection(
    id: id,
    organizationId: 'org-1',
    name: 'Coleção $id',
    startDate: startDate,
    status: status,
    version: 1,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
  );
}

class _FakeRepository implements CollectionRepository {
  _FakeRepository(this._result);

  final AppResult<List<Collection>> _result;

  @override
  Future<AppResult<Collection>> create({required Collection collection}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<Collection>> update({required Collection collection}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<List<Collection>>> listByOrganization(
    String organizationId,
  ) async => _result;

  @override
  Future<AppResult<Collection>> getById({
    required String organizationId,
    required String id,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<Collection>> close({
    required String organizationId,
    required String id,
    required String updatedBy,
  }) => throw UnimplementedError();
}
