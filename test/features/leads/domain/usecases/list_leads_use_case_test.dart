import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/leads/leads.dart';

void main() {
  group('ListLeadsUseCase', () {
    test(
      'rejects a blank organizationId without touching the repository',
      () async {
        final repository = _FakeLeadRepository();
        final useCase = ListLeadsUseCase(repository);

        final result = await useCase(organizationId: '   ');

        expect(result, isA<AppFailure<LeadPageResult>>());
        expect(
          (result as AppFailure<LeadPageResult>).failure.code,
          'invalid_lead_list_payload',
        );
        expect(repository.listPageCalls, isEmpty);
      },
    );

    test('rejects an out-of-range limit', () async {
      final repository = _FakeLeadRepository();
      final useCase = ListLeadsUseCase(repository);

      final result = await useCase(organizationId: 'org-1', limit: 0);

      expect(result, isA<AppFailure<LeadPageResult>>());
      expect(repository.listPageCalls, isEmpty);
    });

    test('trims organizationId/companyId/search and normalizes filters '
        'before delegating to the repository', () async {
      final repository = _FakeLeadRepository(
        response: const AppSuccess<LeadPageResult>(
          LeadPageResult(leads: <Lead>[], hasMore: false),
        ),
      );
      final useCase = ListLeadsUseCase(repository);

      await useCase(
        organizationId: ' org-1 ',
        companyId: ' company-1 ',
        searchQuery: '  Boutique  ',
        cursor: '  ',
        filters: const LeadListFilters(sourceCodes: <String>{' referral '}),
      );

      final call = repository.listPageCalls.single;
      expect(call.organizationId, 'org-1');
      expect(call.companyId, 'company-1');
      expect(call.searchQuery, 'Boutique');
      expect(call.cursor, isNull);
      expect(call.filters.sourceCodes, <String>{'referral'});
    });

    test('propagates a repository failure', () async {
      final repository = _FakeLeadRepository(
        response: const AppFailure<LeadPageResult>(
          ConnectivityFailure('offline'),
        ),
      );
      final useCase = ListLeadsUseCase(repository);

      final result = await useCase(organizationId: 'org-1');

      expect(result, isA<AppFailure<LeadPageResult>>());
    });
  });
}

final class _ListPageCall {
  const _ListPageCall({
    required this.organizationId,
    required this.companyId,
    required this.filters,
    required this.searchQuery,
    required this.limit,
    required this.cursor,
  });

  final String organizationId;
  final String? companyId;
  final LeadListFilters filters;
  final String searchQuery;
  final int limit;
  final String? cursor;
}

final class _FakeLeadRepository implements LeadRepository {
  _FakeLeadRepository({
    this.response = const AppSuccess<LeadPageResult>(
      LeadPageResult(leads: <Lead>[], hasMore: false),
    ),
  });

  final AppResult<LeadPageResult> response;
  final List<_ListPageCall> listPageCalls = <_ListPageCall>[];

  @override
  Future<AppResult<Lead>> create({required Lead lead}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Lead>> update({required Lead lead}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Lead>> getById({
    required String organizationId,
    required String id,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<LeadPageResult>> listPage({
    required String organizationId,
    String? companyId,
    required LeadListFilters filters,
    required String searchQuery,
    required int limit,
    String? cursor,
  }) async {
    listPageCalls.add(
      _ListPageCall(
        organizationId: organizationId,
        companyId: companyId,
        filters: filters,
        searchQuery: searchQuery,
        limit: limit,
        cursor: cursor,
      ),
    );
    return response;
  }
}
