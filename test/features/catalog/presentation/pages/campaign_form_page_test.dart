import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network_image_mock/network_image_mock.dart';
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
  group('CampaignFormPage', () {
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

    Widget buildPage({CatalogCampaign? initialCampaign}) {
      return CampaignFormPage(
        organizationId: 'org-1',
        userId: 'current-user',
        permissionService: permissionService,
        createBloc: () => CampaignFormBloc(
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
        initialCampaign: initialCampaign,
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

      expect(find.text('Nova campanha'), findsNothing);
    });

    testWidgets('renders an empty form for a new campaign', (tester) async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'current-user',
        ),
      ).thenAnswer((_) async => AppSuccess<Membership>(ownerMembership()));

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Nova campanha'), findsOneWidget);
      expect(find.text('Criar campanha'), findsOneWidget);
    });

    testWidgets('renders a prefilled form when editing an existing campaign', (
      tester,
    ) async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'current-user',
        ),
      ).thenAnswer((_) async => AppSuccess<Membership>(ownerMembership()));
      final campaign = buildTestCampaign(
        id: 'campaign-1',
      ).copyWith(title: 'Verão em Movimento');

      await mockNetworkImagesFor(() async {
        await pumpApp(tester, buildPage(initialCampaign: campaign));
        await tester.pumpAndSettle();

        expect(find.text('Editar campanha'), findsOneWidget);
        expect(find.text('Verão em Movimento'), findsOneWidget);
        expect(find.text('Salvar alterações'), findsOneWidget);
      });
    });

    testWidgets('shows a field error when submitting a blank title', (
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

      await tester.ensureVisible(find.text('Criar campanha'));
      await tester.tap(find.text('Criar campanha'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Informe o título da campanha.'), findsOneWidget);
      expect(campaignRepository.campaigns, isEmpty);
    });

    testWidgets('creates a campaign and pops with the saved value', (
      tester,
    ) async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'current-user',
        ),
      ).thenAnswer((_) async => AppSuccess<Membership>(ownerMembership()));

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await CampaignFormPage.push(
                      context: context,
                      organizationId: 'org-1',
                      userId: 'current-user',
                      permissionService: permissionService,
                      createBloc: () => CampaignFormBloc(
                        storage: _StubStorageDataSource(),
                        createCampaign: CreateCampaignUseCase(
                          campaignRepository,
                        ),
                        updateCampaign: UpdateCampaignUseCase(
                          campaignRepository,
                        ),
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
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'Verão em Movimento',
      );
      await tester.ensureVisible(find.text('Criar campanha'));
      await tester.tap(find.text('Criar campanha'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Nova campanha'), findsNothing);
      expect(
        campaignRepository.campaigns.values.single.title,
        'Verão em Movimento',
      );
    });
  });
}
