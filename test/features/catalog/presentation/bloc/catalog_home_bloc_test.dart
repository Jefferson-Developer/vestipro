import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog/catalog.dart';
import 'package:vestipro/features/products/products.dart';

import '../../catalog_test_fakes.dart';

void main() {
  group('CatalogHomeBloc', () {
    blocTest<CatalogHomeBloc, CatalogHomeState>(
      'loads every enabled section successfully, sorted by order',
      build: () => buildTestCatalogHomeBloc(
        collectionsResult: AppSuccess<List<Collection>>(<Collection>[
          buildTestCollection(id: 'col-1'),
        ]),
        productsResult: AppSuccess<List<Product>>(<Product>[
          buildTestCatalogHomeProduct(id: 'prod-1'),
        ]),
        campaignsResult: AppSuccess<List<CatalogCampaign>>(<CatalogCampaign>[
          buildTestCampaign(id: 'camp-1'),
        ]),
        analyticsService: FakeAnalyticsService(),
      ),
      act: (bloc) => bloc.add(
        const CatalogHomeStarted(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'user-1',
        ),
      ),
      expect: () => <Object>[
        isA<CatalogHomeState>().having(
          (state) => state.status,
          'status',
          CatalogHomeLoadStatus.loading,
        ),
        isA<CatalogHomeState>()
            .having(
              (state) => state.status,
              'status',
              CatalogHomeLoadStatus.ready,
            )
            .having(
              (state) => state.sections.map((s) => s.type).toList(),
              'section types in order',
              <CatalogHomeSectionType>[
                CatalogHomeSectionType.featuredCollections,
                CatalogHomeSectionType.newArrivals,
                CatalogHomeSectionType.campaigns,
              ],
            )
            .having((state) => state.isStale, 'isStale', isFalse)
            .having(
              (state) => state.sectionFailures,
              'sectionFailures',
              isEmpty,
            ),
        isA<CatalogHomeState>().having(
          (state) => state.hasLoggedViewed,
          'hasLoggedViewed',
          isTrue,
        ),
      ],
    );

    blocTest<CatalogHomeBloc, CatalogHomeState>(
      'keeps the sections that loaded when one section fails (partial success)',
      build: () => buildTestCatalogHomeBloc(
        collectionsResult: AppSuccess<List<Collection>>(<Collection>[
          buildTestCollection(id: 'col-1'),
        ]),
        productsResult: AppSuccess<List<Product>>(<Product>[
          buildTestCatalogHomeProduct(id: 'prod-1'),
        ]),
        campaignsResult: const AppFailure<List<CatalogCampaign>>(
          ServerFailure('campaigns down', code: 'campaigns_down'),
        ),
        analyticsService: FakeAnalyticsService(),
      ),
      act: (bloc) => bloc.add(
        const CatalogHomeStarted(organizationId: 'org-1', userId: 'user-1'),
      ),
      expect: () => <Object>[
        isA<CatalogHomeState>(),
        isA<CatalogHomeState>()
            .having(
              (state) => state.status,
              'status',
              CatalogHomeLoadStatus.ready,
            )
            .having(
              (state) => state.sections.map((s) => s.type).toList(),
              'section types',
              <CatalogHomeSectionType>[
                CatalogHomeSectionType.featuredCollections,
                CatalogHomeSectionType.newArrivals,
              ],
            )
            .having(
              (state) => state.sectionFailures.containsKey(
                CatalogHomeSectionType.campaigns,
              ),
              'has campaigns failure',
              isTrue,
            ),
        isA<CatalogHomeState>().having(
          (state) => state.hasLoggedViewed,
          'hasLoggedViewed',
          isTrue,
        ),
      ],
    );

    blocTest<CatalogHomeBloc, CatalogHomeState>(
      'shows a valid (non-error) empty ready state when every section is genuinely empty',
      build: () => buildTestCatalogHomeBloc(
        collectionsResult: const AppSuccess<List<Collection>>(<Collection>[]),
        productsResult: const AppSuccess<List<Product>>(<Product>[]),
        campaignsResult: const AppSuccess<List<CatalogCampaign>>(
          <CatalogCampaign>[],
        ),
        analyticsService: FakeAnalyticsService(),
      ),
      act: (bloc) => bloc.add(
        const CatalogHomeStarted(organizationId: 'org-1', userId: 'user-1'),
      ),
      expect: () => <Object>[
        isA<CatalogHomeState>(),
        isA<CatalogHomeState>()
            .having(
              (state) => state.status,
              'status',
              CatalogHomeLoadStatus.ready,
            )
            .having((state) => state.sections, 'sections', isEmpty)
            .having((state) => state.failure, 'failure', isNull),
        isA<CatalogHomeState>().having(
          (state) => state.hasLoggedViewed,
          'hasLoggedViewed',
          isTrue,
        ),
      ],
    );

    blocTest<CatalogHomeBloc, CatalogHomeState>(
      'reports a full failure when there is no cache and every section fails',
      build: () => buildTestCatalogHomeBloc(
        collectionsResult: const AppFailure<List<Collection>>(
          ServerFailure('down', code: 'down'),
        ),
        productsResult: const AppFailure<List<Product>>(
          ServerFailure('down', code: 'down'),
        ),
        campaignsResult: const AppFailure<List<CatalogCampaign>>(
          ServerFailure('down', code: 'down'),
        ),
        analyticsService: FakeAnalyticsService(),
      ),
      act: (bloc) => bloc.add(
        const CatalogHomeStarted(organizationId: 'org-1', userId: 'user-1'),
      ),
      expect: () => <Object>[
        isA<CatalogHomeState>(),
        isA<CatalogHomeState>()
            .having(
              (state) => state.status,
              'status',
              CatalogHomeLoadStatus.failure,
            )
            .having((state) => state.sections, 'sections', isEmpty)
            .having((state) => state.failure, 'failure', isNotNull),
      ],
    );

    blocTest<CatalogHomeBloc, CatalogHomeState>(
      'paints the cached snapshot instantly, then keeps it flagged as stale when the fresh load fails offline',
      build: () => buildTestCatalogHomeBloc(
        collectionsResult: const AppFailure<List<Collection>>(
          ConnectivityFailure('offline', code: 'offline'),
        ),
        productsResult: const AppFailure<List<Product>>(
          ConnectivityFailure('offline', code: 'offline'),
        ),
        campaignsResult: const AppFailure<List<CatalogCampaign>>(
          ConnectivityFailure('offline', code: 'offline'),
        ),
        cachedSnapshot: CatalogHomeSnapshot(
          sections: <CatalogHomeSection>[
            const CatalogHomeSection(
              type: CatalogHomeSectionType.featuredCollections,
              title: 'Coleções em destaque',
              order: 0,
              priority: 0,
              items: <CatalogHomeItem>[
                CatalogHomeItem(id: 'cached-col-1', title: 'Coleção cacheada'),
              ],
            ),
          ],
          savedAt: DateTime.utc(2026, 8, 1),
        ),
        analyticsService: FakeAnalyticsService(),
      ),
      act: (bloc) => bloc.add(
        const CatalogHomeStarted(organizationId: 'org-1', userId: 'user-1'),
      ),
      expect: () => <Object>[
        isA<CatalogHomeState>().having(
          (state) => state.status,
          'status',
          CatalogHomeLoadStatus.loading,
        ),
        isA<CatalogHomeState>()
            .having(
              (state) => state.status,
              'status',
              CatalogHomeLoadStatus.ready,
            )
            .having((state) => state.isStale, 'isStale', isTrue)
            .having(
              (state) => state.sections,
              'sections has cached item',
              <CatalogHomeSection>[
                const CatalogHomeSection(
                  type: CatalogHomeSectionType.featuredCollections,
                  title: 'Coleções em destaque',
                  order: 0,
                  priority: 0,
                  items: <CatalogHomeItem>[
                    CatalogHomeItem(
                      id: 'cached-col-1',
                      title: 'Coleção cacheada',
                    ),
                  ],
                ),
              ],
            ),
        // hasLoggedViewed flips to true right after the cached paint logs
        // catalog_home_viewed once.
        isA<CatalogHomeState>().having(
          (state) => state.hasLoggedViewed,
          'hasLoggedViewed',
          isTrue,
        ),
        isA<CatalogHomeState>()
            .having(
              (state) => state.status,
              'status stays ready after failed revalidation',
              CatalogHomeLoadStatus.ready,
            )
            .having((state) => state.isStale, 'still stale', isTrue)
            .having(
              (state) => state.sections,
              'keeps cached sections',
              <CatalogHomeSection>[
                const CatalogHomeSection(
                  type: CatalogHomeSectionType.featuredCollections,
                  title: 'Coleções em destaque',
                  order: 0,
                  priority: 0,
                  items: <CatalogHomeItem>[
                    CatalogHomeItem(
                      id: 'cached-col-1',
                      title: 'Coleção cacheada',
                    ),
                  ],
                ),
              ],
            ),
      ],
    );

    blocTest<CatalogHomeBloc, CatalogHomeState>(
      'logs catalog_home_viewed exactly once for a successful load',
      build: () => buildTestCatalogHomeBloc(
        collectionsResult: AppSuccess<List<Collection>>(<Collection>[
          buildTestCollection(id: 'col-1'),
        ]),
        productsResult: const AppSuccess<List<Product>>(<Product>[]),
        campaignsResult: const AppSuccess<List<CatalogCampaign>>(
          <CatalogCampaign>[],
        ),
        analyticsService: FakeAnalyticsService(),
      ),
      act: (bloc) => bloc.add(
        const CatalogHomeStarted(organizationId: 'org-1', userId: 'user-1'),
      ),
      verify: (bloc) {
        final analyticsService = bloc.analyticsService as FakeAnalyticsService;
        final logged = analyticsService.loggedEvents
            .where((event) => event.name == AnalyticsEvents.catalogHomeViewed)
            .toList();
        expect(logged, hasLength(1));
        expect(logged.single.parameters?['organization_id'], 'org-1');
        expect(logged.single.parameters?['sections_count'], 1);
      },
    );

    blocTest<CatalogHomeBloc, CatalogHomeState>(
      'logs catalog_section_opened with the tapped section type',
      build: () => buildTestCatalogHomeBloc(
        collectionsResult: const AppSuccess<List<Collection>>(<Collection>[]),
        productsResult: const AppSuccess<List<Product>>(<Product>[]),
        campaignsResult: const AppSuccess<List<CatalogCampaign>>(
          <CatalogCampaign>[],
        ),
        analyticsService: FakeAnalyticsService(),
      ),
      seed: () => const CatalogHomeState(organizationId: 'org-1'),
      act: (bloc) => bloc.add(
        const CatalogHomeSectionOpened(CatalogHomeSectionType.newArrivals),
      ),
      verify: (bloc) {
        final analyticsService = bloc.analyticsService as FakeAnalyticsService;
        final logged = analyticsService.loggedEvents
            .where(
              (event) => event.name == AnalyticsEvents.catalogSectionOpened,
            )
            .toList();
        expect(logged, hasLength(1));
        expect(logged.single.parameters?['section_type'], 'newArrivals');
      },
    );
  });
}
