import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/storage/storage.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog/catalog.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/products/products.dart';

import '../../../../core/design_system/components/test_pump_app.dart';
import '../../catalog_test_fakes.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _StubStorageDataSource extends Fake implements StorageDataSource {}

class _ThrowingProductSearchRepository implements ProductSearchRepository {
  @override
  Future<AppResult<ProductSearchResult>> searchProducts({
    required String organizationId,
    required String query,
    ProductSearchSource source = ProductSearchSource.remote,
    int limit = 20,
  }) => throw UnimplementedError();
}

class _ThrowingVariantAvailabilityRepository
    implements VariantAvailabilityRepository {
  @override
  Future<AppResult<List<VariantAvailability>>> listByVariantIds({
    required String organizationId,
    required Iterable<String> variantIds,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<List<VariantAvailability>>> listByProductIds({
    required String organizationId,
    required Iterable<String> productIds,
  }) => throw UnimplementedError();
}

void main() {
  group('CampaignsPage', () {
    late _MockMembershipRepository membershipRepository;
    late InMemoryCatalogCampaignRepository campaignRepository;
    late InMemoryCatalogProductRepository productRepository;
    late PermissionService permissionService;

    Membership ownerMembership() {
      return Membership(
        id: 'current-user',
        organizationId: 'org-1',
        userId: 'current-user',
        roleId: 'OWNER',
        roleName: 'OWNER',
        status: MembershipStatus.active,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'owner-1',
        name: 'Ana Souza',
        email: 'ana@vestipro.com.br',
      );
    }

    Membership salesRepMembership() {
      return Membership(
        id: 'current-user',
        organizationId: 'org-1',
        userId: 'current-user',
        roleId: 'SALES_REP',
        roleName: 'SALES_REP',
        status: MembershipStatus.active,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'owner-1',
        name: 'João Vendedor',
        email: 'joao@vestipro.com.br',
      );
    }

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      campaignRepository = InMemoryCatalogCampaignRepository();
      productRepository = InMemoryCatalogProductRepository();
      permissionService = PermissionService(membershipRepository);
    });

    Widget buildPage() {
      return CampaignsPage(
        organizationId: 'org-1',
        userId: 'current-user',
        permissionService: permissionService,
        createBloc: () => CampaignListBloc(
          listCampaigns: ListCampaignsUseCase(campaignRepository),
          deleteCampaign: DeleteCampaignUseCase(campaignRepository),
          now: () => DateTime.utc(2026, 6, 15),
        ),
        createFormBloc: () => CampaignFormBloc(
          storage: _StubStorageDataSource(),
          createCampaign: CreateCampaignUseCase(campaignRepository),
          updateCampaign: UpdateCampaignUseCase(campaignRepository),
          listRelatedProducts: ListCampaignRelatedProductsUseCase(
            productRepository,
          ),
        ),
        createProductSearchBloc: () => ProductSearchBloc(
          searchProducts: SearchProductsUseCase(
            _ThrowingProductSearchRepository(),
          ),
          getVariantAvailability: GetVariantAvailabilityUseCase(
            _ThrowingVariantAvailabilityRepository(),
          ),
        ),
      );
    }

    testWidgets('denies access to a profile without catalog.manage', (
      tester,
    ) async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'current-user',
        ),
      ).thenAnswer((_) async => AppSuccess<Membership>(salesRepMembership()));

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Campanhas e lookbooks'), findsNothing);
    });

    testWidgets('shows an empty state guiding the first campaign creation', (
      tester,
    ) async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'current-user',
        ),
      ).thenAnswer((_) async => AppSuccess<Membership>(ownerMembership()));

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma campanha cadastrada'), findsOneWidget);
      expect(find.text('Criar primeira campanha'), findsOneWidget);
    });

    testWidgets('renders existing campaigns with their status', (tester) async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'current-user',
        ),
      ).thenAnswer((_) async => AppSuccess<Membership>(ownerMembership()));
      campaignRepository.seed(
        buildTestCampaign(id: 'campaign-1').copyWith(title: 'Verão 2026'),
      );

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Verão 2026'), findsOneWidget);
      expect(find.text('Ativa'), findsOneWidget);
    });

    testWidgets('shows an error state when loading campaigns fails', (
      tester,
    ) async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'current-user',
        ),
      ).thenAnswer((_) async => AppSuccess<Membership>(ownerMembership()));
      campaignRepository.shouldFail = true;

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(
        find.text('Não foi possível carregar as campanhas'),
        findsOneWidget,
      );
    });
  });
}
