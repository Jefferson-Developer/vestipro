import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/functions/functions.dart';
import '../../../../core/utils/utils.dart';
import '../../../reports/domain/entities/report_definition.dart';
import '../../domain/entities/report_explanation.dart';
import '../../domain/entities/report_explanation_reference.dart';
import '../../domain/repositories/report_explanation_repository.dart';

/// Calls the `explainReport` Cloud Function (TASK-189, EPIC-28) — the only
/// place this feature ever reaches the network. No Firestore datasource
/// exists for this feature: the server-side cache
/// (`organizations/{organizationId}/reportExplanations/{cacheKey}`) is never
/// readable directly by any client (`firestore.rules` denies it outright),
/// so every call — cached or freshly generated — goes through this one
/// callable.
@LazySingleton(as: ReportExplanationRepository)
final class CloudFunctionsReportExplanationRepository
    implements ReportExplanationRepository {
  const CloudFunctionsReportExplanationRepository(this._functions);

  final CloudFunctionsService _functions;

  @override
  Future<AppResult<ReportExplanation>> explain({
    required ReportDefinition definition,
    String? savedReportId,
  }) => _guard(() async {
    final json = await _functions.call<Map<String, dynamic>>(
      'explainReport',
      requireAuth: true,
      data: <String, dynamic>{
        'organizationId': definition.organizationId,
        'companyId': definition.companyId,
        if (savedReportId != null) 'savedReportId': savedReportId,
        'dimensions': definition.dimensions,
        'metrics': definition.metrics,
        'filters': definition.filters
            .map((filter) => filter.toJson())
            .toList(growable: false),
        'groupBy': definition.groupBy,
        if (definition.sortBy != null) 'sortBy': definition.sortBy!.toJson(),
        'comparisonPeriod': definition.comparisonPeriod.name,
      },
    );
    final rawReferences =
        json['references'] as List<dynamic>? ?? const <dynamic>[];
    return ReportExplanation(
      explanationText: json['explanationText'] as String,
      references: rawReferences
          .map((raw) {
            final reference = Map<String, dynamic>.from(raw as Map);
            return ReportExplanationReference(
              code: reference['code'] as String,
              label: reference['label'] as String,
              value: reference['value'] as String,
              unit: reference['unit'] as String?,
            );
          })
          .toList(growable: false),
      periodKey: json['periodKey'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      fromCache: json['fromCache'] as bool? ?? false,
    );
  });

  Future<AppResult<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return AppSuccess<T>(await action());
    } on AppException catch (error) {
      return AppFailure<T>(mapAppExceptionToFailure(error));
    } catch (error) {
      return AppFailure<T>(
        UnexpectedFailure(
          'Falha inesperada ao explicar o relatório.',
          cause: error,
        ),
      );
    }
  }
}
