import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog_share/catalog_share.dart';

class _MockCatalogShareLookupRepository extends Mock
    implements CatalogShareLookupRepository {}

void main() {
  late _MockCatalogShareLookupRepository repository;
  late FakeAnalyticsService analyticsService;

  const validPreview = CatalogSharePreview(
    outcome: CatalogShareOutcome.valid,
    organizationName: 'Grupo Fashion XPTO',
    scope: CatalogShareScope.product,
    items: [CatalogShareItem(productId: 'product-1', name: 'Camisa')],
  );

  CatalogSharePublicBloc buildBloc() {
    return CatalogSharePublicBloc(
      previewCatalogShare: PreviewCatalogShareUseCase(repository),
      registerCatalogShareOpen: RegisterCatalogShareOpenUseCase(repository),
      analyticsService: analyticsService,
    );
  }

  setUp(() {
    repository = _MockCatalogShareLookupRepository();
    analyticsService = FakeAnalyticsService();
    when(
      () => repository.registerOpen(token: any(named: 'token')),
    ).thenAnswer((_) async {});
  });

  group('CatalogSharePublicBloc — started', () {
    blocTest<CatalogSharePublicBloc, CatalogSharePublicState>(
      'reports a valid preview, logs catalog_share_opened and records the '
      'open',
      setUp: () {
        when(
          () => repository.preview(token: any(named: 'token')),
        ).thenAnswer((_) async => const AppSuccess(validPreview));
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const CatalogSharePublicStarted(token: 'token-1')),
      expect: () => [
        isA<CatalogSharePublicState>().having(
          (s) => s.status,
          'status',
          CatalogSharePublicStatus.loading,
        ),
        isA<CatalogSharePublicState>()
            .having((s) => s.status, 'status', CatalogSharePublicStatus.valid)
            .having((s) => s.preview, 'preview', validPreview),
      ],
      verify: (_) {
        expect(analyticsService.loggedEvents, hasLength(1));
        expect(
          analyticsService.loggedEvents.single.name,
          AnalyticsEvents.catalogShareOpened,
        );
        verify(() => repository.registerOpen(token: 'token-1')).called(1);
      },
    );

    blocTest<CatalogSharePublicBloc, CatalogSharePublicState>(
      'reports an unavailable outcome (expired) without logging analytics '
      'or registering an open',
      setUp: () {
        when(() => repository.preview(token: any(named: 'token'))).thenAnswer(
          (_) async => const AppSuccess(
            CatalogSharePreview(outcome: CatalogShareOutcome.expired),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const CatalogSharePublicStarted(token: 'token-1')),
      expect: () => [
        isA<CatalogSharePublicState>().having(
          (s) => s.status,
          'status',
          CatalogSharePublicStatus.loading,
        ),
        isA<CatalogSharePublicState>()
            .having(
              (s) => s.status,
              'status',
              CatalogSharePublicStatus.unavailable,
            )
            .having(
              (s) => s.unavailableReason,
              'unavailableReason',
              CatalogShareOutcome.expired,
            ),
      ],
      verify: (_) {
        expect(analyticsService.loggedEvents, isEmpty);
        verifyNever(() => repository.registerOpen(token: any(named: 'token')));
      },
    );

    blocTest<CatalogSharePublicBloc, CatalogSharePublicState>(
      'reports a technical failure as error, distinct from an unavailable '
      'outcome',
      setUp: () {
        when(() => repository.preview(token: any(named: 'token'))).thenAnswer(
          (_) async => const AppFailure(ConnectivityFailure('Offline.')),
        );
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const CatalogSharePublicStarted(token: 'token-1')),
      expect: () => [
        isA<CatalogSharePublicState>().having(
          (s) => s.status,
          'status',
          CatalogSharePublicStatus.loading,
        ),
        isA<CatalogSharePublicState>().having(
          (s) => s.status,
          'status',
          CatalogSharePublicStatus.error,
        ),
      ],
      verify: (_) {
        expect(analyticsService.loggedEvents, isEmpty);
      },
    );
  });
}
