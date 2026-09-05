import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/reports/data/datasources/report_remote_data_source.dart';
import 'package:vestipro/features/reports/data/repositories/report_repository_impl.dart';
import 'package:vestipro/features/reports/reports.dart';

void main() {
  const definition = ReportDefinition(
    organizationId: 'org-a',
    companyId: 'company-a',
    dimensions: <String>['seller'],
    metrics: <String>['orders'],
  );

  test(
    'maps successful aggregation response without client-side calculation',
    () async {
      final repository = ReportRepositoryImpl(
        _Remote(<String, dynamic>{
          'columns': <String>['seller', 'orders'],
          'rows': <Map<String, Object?>>[
            <String, Object?>{'seller': 'Ana', 'orders': 9},
          ],
          'generatedAt': '2026-09-04T12:00:00.000Z',
        }),
      );
      final result = await repository.execute(definition);
      expect(result, isA<AppSuccess<ReportQueryResult>>());
      expect(
        (result as AppSuccess<ReportQueryResult>).value.rows.single['orders'],
        9,
      );
    },
  );

  test('maps timeout from aggregation layer', () async {
    final repository = ReportRepositoryImpl(
      _Remote(null, error: const TimeoutException('Tempo esgotado.')),
    );
    final result = await repository.execute(definition);
    expect(result, isA<AppFailure<ReportQueryResult>>());
    expect(
      (result as AppFailure<ReportQueryResult>).failure,
      isA<ConnectivityFailure>(),
    );
  });

  test('maps server permission denial', () async {
    final repository = ReportRepositoryImpl(
      _Remote(null, error: const ForbiddenException('Sem permissão.')),
    );
    final result = await repository.execute(definition);
    expect(result, isA<AppFailure<ReportQueryResult>>());
    expect(
      (result as AppFailure<ReportQueryResult>).failure,
      isA<PermissionFailure>(),
    );
  });
}

final class _Remote implements ReportRemoteDataSource {
  const _Remote(this.response, {this.error});
  final Map<String, dynamic>? response;
  final AppException? error;
  @override
  Future<Map<String, dynamic>> execute(ReportDefinition definition) async {
    if (error != null) throw error!;
    return response!;
  }

  @override
  Future<Map<String, dynamic>> loadCatalog({
    required String organizationId,
    required String companyId,
  }) => throw UnimplementedError();
}
