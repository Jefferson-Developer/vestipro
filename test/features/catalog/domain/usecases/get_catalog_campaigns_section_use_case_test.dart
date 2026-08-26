import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog/catalog.dart';

void main() {
  group('GetCatalogCampaignsSectionUseCase', () {
    const config = CatalogHomeSectionConfig(
      type: CatalogHomeSectionType.campaigns,
      title: 'Campanhas em destaque',
      order: 2,
      priority: 2,
    );
    final now = DateTime.utc(2026, 6, 15);

    test('keeps only campaigns visible at "now", ordered by order', () async {
      final visibleLater = _campaign(id: 'camp-2', order: 1);
      final visibleFirst = _campaign(id: 'camp-1', order: 0);
      final inactive = _campaign(id: 'camp-3', order: 2, active: false);
      final useCase = GetCatalogCampaignsSectionUseCase(
        _FakeRepository(
          AppSuccess<List<CatalogCampaign>>(<CatalogCampaign>[
            visibleLater,
            visibleFirst,
            inactive,
          ]),
        ),
      );

      final result = await useCase(
        organizationId: 'org-1',
        config: config,
        now: now,
      );

      final section = (result as AppSuccess<CatalogHomeSection>).value;
      expect(section.items.map((item) => item.id).toList(), <String>[
        'camp-1',
        'camp-2',
      ]);
    });

    test('propagates a repository failure', () async {
      final useCase = GetCatalogCampaignsSectionUseCase(
        _FakeRepository(
          const AppFailure<List<CatalogCampaign>>(
            ServerFailure('down', code: 'down'),
          ),
        ),
      );

      final result = await useCase(
        organizationId: 'org-1',
        config: config,
        now: now,
      );

      expect(result, isA<AppFailure<CatalogHomeSection>>());
    });
  });
}

CatalogCampaign _campaign({
  required String id,
  required int order,
  bool active = true,
}) {
  final createdAt = DateTime.utc(2026, 1, 1);
  return CatalogCampaign(
    id: id,
    organizationId: 'org-1',
    title: 'Campanha $id',
    order: order,
    active: active,
    createdAt: createdAt,
    createdBy: 'user-1',
    updatedAt: createdAt,
    updatedBy: 'user-1',
  );
}

class _FakeRepository implements CatalogCampaignRepository {
  _FakeRepository(this._result);

  final AppResult<List<CatalogCampaign>> _result;

  @override
  Future<AppResult<List<CatalogCampaign>>> listByOrganization(
    String organizationId,
  ) async => _result;

  @override
  Future<AppResult<CatalogCampaign>> getById({
    required String organizationId,
    required String id,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<CatalogCampaign>> create({
    required CatalogCampaign campaign,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<CatalogCampaign>> update({
    required CatalogCampaign campaign,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<CatalogCampaign>> delete({
    required String organizationId,
    required String id,
    required String updatedBy,
  }) => throw UnimplementedError();
}
