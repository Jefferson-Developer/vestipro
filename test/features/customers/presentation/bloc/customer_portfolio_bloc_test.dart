import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';

void main() {
  group('CustomerPortfolioBloc', () {
    blocTest<CustomerPortfolioBloc, CustomerPortfolioState>(
      'loads the first portfolio page',
      build: () {
        final useCase = _FakeListCustomerPortfolioUseCase(
          <AppResult<CustomerPortfolioPageResult>>[
            AppSuccess<CustomerPortfolioPageResult>(
              CustomerPortfolioPageResult(
                customers: <Customer>[_customerA],
                hasMore: true,
                nextCursor: _customerA.id,
                isFromLocalCache: true,
              ),
            ),
          ],
        );
        return CustomerPortfolioBloc(listCustomerPortfolio: useCase);
      },
      act: (bloc) => bloc.add(
        const CustomerPortfolioStarted(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'rep-1',
        ),
      ),
      expect: () => <Object>[
        isA<CustomerPortfolioState>()
            .having(
              (state) => state.status,
              'status',
              CustomerPortfolioLoadStatus.loading,
            )
            .having((state) => state.customers, 'customers', isEmpty),
        isA<CustomerPortfolioState>()
            .having(
              (state) => state.status,
              'status',
              CustomerPortfolioLoadStatus.ready,
            )
            .having((state) => state.customers, 'customers', <Customer>[
              _customerA,
            ])
            .having((state) => state.hasMore, 'hasMore', isTrue)
            .having(
              (state) => state.isFromLocalCache,
              'isFromLocalCache',
              isTrue,
            ),
      ],
    );

    blocTest<CustomerPortfolioBloc, CustomerPortfolioState>(
      'paginates without losing already loaded customers',
      build: () {
        final useCase = _FakeListCustomerPortfolioUseCase(
          <AppResult<CustomerPortfolioPageResult>>[
            AppSuccess<CustomerPortfolioPageResult>(
              CustomerPortfolioPageResult(
                customers: <Customer>[_customerB],
                hasMore: false,
                nextCursor: _customerB.id,
              ),
            ),
          ],
        );
        return CustomerPortfolioBloc(listCustomerPortfolio: useCase);
      },
      seed: () => CustomerPortfolioState(
        status: CustomerPortfolioLoadStatus.ready,
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'rep-1',
        customers: <Customer>[_customerA],
        hasMore: true,
        nextCursor: _customerA.id,
      ),
      act: (bloc) => bloc.add(const CustomerPortfolioNextPageRequested()),
      expect: () => <Object>[
        isA<CustomerPortfolioState>().having(
          (state) => state.status,
          'status',
          CustomerPortfolioLoadStatus.loadingMore,
        ),
        isA<CustomerPortfolioState>()
            .having(
              (state) => state.status,
              'status',
              CustomerPortfolioLoadStatus.ready,
            )
            .having((state) => state.customers, 'customers', <Customer>[
              _customerA,
              _customerB,
            ])
            .having((state) => state.hasMore, 'hasMore', isFalse),
      ],
    );

    blocTest<CustomerPortfolioBloc, CustomerPortfolioState>(
      'debounces search and ignores stale text edits',
      build: () {
        final useCase = _FakeListCustomerPortfolioUseCase(
          <AppResult<CustomerPortfolioPageResult>>[
            AppSuccess<CustomerPortfolioPageResult>(
              CustomerPortfolioPageResult(
                customers: <Customer>[_customerB],
                hasMore: false,
              ),
            ),
          ],
        );
        return CustomerPortfolioBloc(listCustomerPortfolio: useCase);
      },
      seed: () => CustomerPortfolioState(
        status: CustomerPortfolioLoadStatus.ready,
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'rep-1',
        customers: <Customer>[_customerA],
      ),
      act: (bloc) => bloc
        ..add(const CustomerPortfolioSearchChanged('al'))
        ..add(const CustomerPortfolioSearchChanged('beta')),
      wait: CustomerPortfolioBloc.searchDebounce * 2,
      expect: () => <Object>[
        isA<CustomerPortfolioState>()
            .having((state) => state.searchQuery, 'searchQuery', 'al')
            .having((state) => state.customers, 'customers', <Customer>[
              _customerA,
            ]),
        isA<CustomerPortfolioState>()
            .having((state) => state.searchQuery, 'searchQuery', 'beta')
            .having((state) => state.customers, 'customers', <Customer>[
              _customerA,
            ]),
        isA<CustomerPortfolioState>()
            .having(
              (state) => state.status,
              'status',
              CustomerPortfolioLoadStatus.loading,
            )
            .having((state) => state.searchQuery, 'searchQuery', 'beta')
            .having((state) => state.customers, 'customers', isEmpty),
        isA<CustomerPortfolioState>()
            .having(
              (state) => state.status,
              'status',
              CustomerPortfolioLoadStatus.ready,
            )
            .having((state) => state.searchQuery, 'searchQuery', 'beta')
            .having((state) => state.customers, 'customers', <Customer>[
              _customerB,
            ]),
      ],
    );

    blocTest<CustomerPortfolioBloc, CustomerPortfolioState>(
      'reloads the first page when filters change',
      build: () {
        final useCase = _FakeListCustomerPortfolioUseCase(
          <AppResult<CustomerPortfolioPageResult>>[
            AppSuccess<CustomerPortfolioPageResult>(
              CustomerPortfolioPageResult(
                customers: <Customer>[_customerB],
                hasMore: false,
              ),
            ),
          ],
        );
        return CustomerPortfolioBloc(listCustomerPortfolio: useCase);
      },
      seed: () => CustomerPortfolioState(
        status: CustomerPortfolioLoadStatus.ready,
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'rep-1',
        customers: <Customer>[_customerA],
        hasMore: true,
        nextCursor: _customerA.id,
      ),
      act: (bloc) => bloc.add(
        const CustomerPortfolioFiltersChanged(
          CustomerPortfolioFilters(
            statuses: <CustomerStatus>{CustomerStatus.active},
            stateCodes: <String>{'sp'},
            potentials: <String>{'Alto'},
            lastPurchase: CustomerLastPurchaseFilter.last30Days,
          ),
        ),
      ),
      expect: () => <Object>[
        isA<CustomerPortfolioState>()
            .having(
              (state) => state.status,
              'status',
              CustomerPortfolioLoadStatus.loading,
            )
            .having((state) => state.customers, 'customers', isEmpty),
        isA<CustomerPortfolioState>()
            .having(
              (state) => state.status,
              'status',
              CustomerPortfolioLoadStatus.ready,
            )
            .having((state) => state.customers, 'customers', <Customer>[
              _customerB,
            ])
            .having((state) => state.filters.stateCodes, 'stateCodes', <String>{
              'SP',
            }),
      ],
    );

    blocTest<CustomerPortfolioBloc, CustomerPortfolioState>(
      'surfaces portfolio load failures instead of pretending the list is empty',
      build: () {
        final useCase = _FakeListCustomerPortfolioUseCase(<
          AppResult<CustomerPortfolioPageResult>
        >[
          const AppFailure<CustomerPortfolioPageResult>(
            PermissionFailure(
              'Sales representative has no active customer portfolio assignment.',
              code: 'customer_portfolio_assignment_required',
            ),
          ),
        ]);
        return CustomerPortfolioBloc(listCustomerPortfolio: useCase);
      },
      act: (bloc) => bloc.add(
        const CustomerPortfolioStarted(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'rep-1',
        ),
      ),
      expect: () => <Object>[
        isA<CustomerPortfolioState>().having(
          (state) => state.status,
          'status',
          CustomerPortfolioLoadStatus.loading,
        ),
        isA<CustomerPortfolioState>()
            .having(
              (state) => state.status,
              'status',
              CustomerPortfolioLoadStatus.failure,
            )
            .having(
              (state) => state.failure?.code,
              'failure.code',
              'customer_portfolio_assignment_required',
            ),
      ],
    );
  });
}

final _customerA = _customer(
  id: 'customer-a',
  legalName: 'Atacado Alfa',
  document: '04.252.011/0001-10',
);

final _customerB = _customer(
  id: 'customer-b',
  legalName: 'Boutique Beta',
  document: '11.222.333/0001-81',
);

Customer _customer({
  required String id,
  required String legalName,
  required String document,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Customer(
    id: id,
    organizationId: 'org-1',
    companyId: 'company-1',
    type: CustomerType.legalEntity,
    document: CnpjCpf.parse(document),
    legalName: legalName,
    status: CustomerStatus.active,
    registeredAt: now,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: CustomerSyncStatus.pending,
  );
}

final class _FakeListCustomerPortfolioUseCase
    implements ListCustomerPortfolioUseCase {
  _FakeListCustomerPortfolioUseCase(this._responses);

  final List<AppResult<CustomerPortfolioPageResult>> _responses;
  final List<_PortfolioCall> calls = <_PortfolioCall>[];

  @override
  Future<AppResult<CustomerPortfolioPageResult>> call({
    required String organizationId,
    required String companyId,
    required String userId,
    CustomerPortfolioFilters filters = CustomerPortfolioFilters.empty,
    String searchQuery = '',
    String? cursor,
    int limit = 20,
    DateTime? now,
  }) async {
    calls.add(
      _PortfolioCall(
        organizationId: organizationId,
        companyId: companyId,
        userId: userId,
        filters: filters,
        searchQuery: searchQuery,
        cursor: cursor,
        limit: limit,
      ),
    );
    final index = calls.length - 1;
    final responseIndex = index >= _responses.length
        ? _responses.length - 1
        : index;
    return _responses[responseIndex];
  }
}

final class _PortfolioCall {
  const _PortfolioCall({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.filters,
    required this.searchQuery,
    required this.cursor,
    required this.limit,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final CustomerPortfolioFilters filters;
  final String searchQuery;
  final String? cursor;
  final int limit;
}
