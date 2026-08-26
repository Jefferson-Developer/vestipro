import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog_share/catalog_share.dart';

class _MockCatalogShareRepository extends Mock
    implements CatalogShareRepository {}

void main() {
  late _MockCatalogShareRepository repository;
  late FakeAnalyticsService analyticsService;

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

  CatalogShareSheetBloc buildBloc() {
    return CatalogShareSheetBloc(
      createCatalogShareLink: CreateCatalogShareLinkUseCase(repository),
      getCatalogShare: GetCatalogShareUseCase(repository),
      analyticsService: analyticsService,
    );
  }

  setUpAll(() {
    registerFallbackValue(CatalogShareScope.product);
    registerFallbackValue(const <CatalogShareItem>[]);
  });

  setUp(() {
    repository = _MockCatalogShareRepository();
    analyticsService = FakeAnalyticsService();
  });

  group('CatalogShareSheetBloc — started', () {
    blocTest<CatalogShareSheetBloc, CatalogShareSheetState>(
      'creates the share, exposes the token/link and logs catalog_share_created',
      setUp: () {
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
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const CatalogShareSheetStarted(
          organizationId: 'org-1',
          scope: CatalogShareScope.product,
          items: items,
        ),
      ),
      expect: () => [
        isA<CatalogShareSheetState>().having(
          (s) => s.status,
          'status',
          CatalogShareSheetStatus.submitting,
        ),
        isA<CatalogShareSheetState>()
            .having((s) => s.status, 'status', CatalogShareSheetStatus.success)
            .having((s) => s.issuedShare?.token, 'token', 'raw-token'),
      ],
      verify: (_) {
        expect(analyticsService.loggedEvents, hasLength(1));
        expect(
          analyticsService.loggedEvents.single.name,
          AnalyticsEvents.catalogShareCreated,
        );
      },
    );

    blocTest<CatalogShareSheetBloc, CatalogShareSheetState>(
      'reports a failure without logging analytics',
      setUp: () {
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
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const CatalogShareSheetStarted(
          organizationId: 'org-1',
          scope: CatalogShareScope.product,
          items: items,
        ),
      ),
      expect: () => [
        isA<CatalogShareSheetState>().having(
          (s) => s.status,
          'status',
          CatalogShareSheetStatus.submitting,
        ),
        isA<CatalogShareSheetState>().having(
          (s) => s.status,
          'status',
          CatalogShareSheetStatus.failure,
        ),
      ],
      verify: (_) {
        expect(analyticsService.loggedEvents, isEmpty);
      },
    );
  });

  group('CatalogShareSheetBloc — retried', () {
    blocTest<CatalogShareSheetBloc, CatalogShareSheetState>(
      'resends the exact same payload the started event was given',
      setUp: () {
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
      },
      build: buildBloc,
      seed: () => const CatalogShareSheetState(
        status: CatalogShareSheetStatus.failure,
        organizationId: 'org-1',
        scope: CatalogShareScope.product,
        items: items,
      ),
      act: (bloc) => bloc.add(const CatalogShareSheetRetried()),
      expect: () => [
        isA<CatalogShareSheetState>().having(
          (s) => s.status,
          'status',
          CatalogShareSheetStatus.submitting,
        ),
        isA<CatalogShareSheetState>().having(
          (s) => s.status,
          'status',
          CatalogShareSheetStatus.success,
        ),
      ],
      verify: (_) {
        verify(
          () => repository.create(
            organizationId: 'org-1',
            scope: CatalogShareScope.product,
            items: items,
            collectionId: null,
            collectionName: null,
            expiresInDays: null,
          ),
        ).called(1);
      },
    );
  });

  group('CatalogShareSheetBloc — refreshRequested', () {
    blocTest<CatalogShareSheetBloc, CatalogShareSheetState>(
      're-reads the share and exposes updated openCount',
      setUp: () {
        when(
          () => repository.getById(
            organizationId: any(named: 'organizationId'),
            shareId: any(named: 'shareId'),
          ),
        ).thenAnswer(
          (_) async => AppSuccess<CatalogShare>(
            issuedShare.share.copyWith(openCount: 4),
          ),
        );
      },
      build: buildBloc,
      seed: () => CatalogShareSheetState(
        status: CatalogShareSheetStatus.success,
        organizationId: 'org-1',
        scope: CatalogShareScope.product,
        items: items,
        issuedShare: issuedShare,
      ),
      act: (bloc) => bloc.add(const CatalogShareSheetRefreshRequested()),
      expect: () => [
        isA<CatalogShareSheetState>().having(
          (s) => s.isRefreshing,
          'isRefreshing',
          true,
        ),
        isA<CatalogShareSheetState>()
            .having((s) => s.isRefreshing, 'isRefreshing', false)
            .having(
              (s) => s.refreshedShare?.openCount,
              'refreshedShare.openCount',
              4,
            ),
      ],
    );
  });
}
