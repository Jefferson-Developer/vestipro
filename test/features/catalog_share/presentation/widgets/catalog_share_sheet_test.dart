import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog_share/catalog_share.dart';

class _MockCatalogShareRepository extends Mock
    implements CatalogShareRepository {}

void main() {
  late _MockCatalogShareRepository repository;

  const items = [CatalogShareItem(productId: 'product-1', name: 'Camisa')];

  final issuedShare = IssuedCatalogShare(
    share: CatalogShare(
      id: 'share-1',
      organizationId: 'org-1',
      scope: CatalogShareScope.product,
      items: items,
      isRevoked: false,
      openCount: 0,
      expiresAt: DateTime.utc(2026, 2, 1),
      createdBy: 'rep-1',
      createdByName: 'Rep Um',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
    token: 'raw-token',
  );

  setUpAll(() {
    registerFallbackValue(CatalogShareScope.product);
    registerFallbackValue(const <CatalogShareItem>[]);
  });

  setUp(() {
    repository = _MockCatalogShareRepository();
  });

  Future<void> pumpTriggerScaffold(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: AppButton(
                label: 'open',
                onPressed: () => CatalogShareSheet.show(
                  context: context,
                  createBloc: () => CatalogShareSheetBloc(
                    createCatalogShareLink: CreateCatalogShareLinkUseCase(
                      repository,
                    ),
                    getCatalogShare: GetCatalogShareUseCase(repository),
                    analyticsService: FakeAnalyticsService(),
                  ),
                  organizationId: 'org-1',
                  scope: CatalogShareScope.product,
                  items: items,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the generated link and a copy button on success', (
    tester,
  ) async {
    when(
      () => repository.create(
        organizationId: any(named: 'organizationId'),
        scope: any(named: 'scope'),
        items: any(named: 'items'),
        collectionId: any(named: 'collectionId'),
        collectionName: any(named: 'collectionName'),
        expiresInDays: any(named: 'expiresInDays'),
      ),
    ).thenAnswer((_) async => AppSuccess<IssuedCatalogShare>(issuedShare));

    await pumpTriggerScaffold(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.textContaining(issuedShare.token), findsOneWidget);
    expect(find.text('Copiar link'), findsOneWidget);
    expect(
      find.text('Ainda não visualizado pelo destinatário.'),
      findsOneWidget,
    );
  });

  testWidgets('shows an error state with retry on failure', (tester) async {
    when(
      () => repository.create(
        organizationId: any(named: 'organizationId'),
        scope: any(named: 'scope'),
        items: any(named: 'items'),
        collectionId: any(named: 'collectionId'),
        collectionName: any(named: 'collectionName'),
        expiresInDays: any(named: 'expiresInDays'),
      ),
    ).thenAnswer(
      (_) async =>
          AppFailure<IssuedCatalogShare>(const UnexpectedFailure('boom')),
    );

    await pumpTriggerScaffold(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível gerar o link'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });
}
