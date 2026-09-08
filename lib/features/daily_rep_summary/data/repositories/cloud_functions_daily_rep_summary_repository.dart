import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/functions/functions.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/daily_rep_summary.dart';
import '../../domain/entities/daily_rep_summary_reference.dart';
import '../../domain/repositories/daily_rep_summary_repository.dart';

/// Calls the `getDailyRepSummary` Cloud Function (TASK-188, EPIC-28) — the
/// only place this feature ever reaches the network. No Firestore datasource
/// exists for this feature: the server-side cache/history
/// (`organizations/{organizationId}/dailyRepSummaries/{sellerId}_{dateKey}`)
/// is never readable directly by any client (`firestore.rules` denies it
/// outright), so every read goes through this one callable.
@LazySingleton(as: DailyRepSummaryRepository)
final class CloudFunctionsDailyRepSummaryRepository
    implements DailyRepSummaryRepository {
  const CloudFunctionsDailyRepSummaryRepository(this._functions);

  final CloudFunctionsService _functions;

  static const _statusByName = <String, DailyRepSummaryResultStatus>{
    'ready': DailyRepSummaryResultStatus.ready,
    'empty': DailyRepSummaryResultStatus.empty,
    'error': DailyRepSummaryResultStatus.error,
    'not_generated_yet': DailyRepSummaryResultStatus.notGeneratedYet,
  };

  @override
  Future<AppResult<DailyRepSummary>> load({
    required String organizationId,
    required String sellerId,
    String? dateKey,
  }) => _guard(() async {
    final json = await _functions.call<Map<String, dynamic>>(
      'getDailyRepSummary',
      requireAuth: true,
      data: <String, dynamic>{
        'organizationId': organizationId,
        'sellerId': sellerId,
        'dateKey': ?dateKey,
      },
    );
    final rawReferences =
        json['references'] as List<dynamic>? ?? const <dynamic>[];
    final generatedAtRaw = json['generatedAt'] as String?;
    return DailyRepSummary(
      status:
          _statusByName[json['status'] as String? ?? ''] ??
          DailyRepSummaryResultStatus.notGeneratedYet,
      dateKey: json['dateKey'] as String,
      summaryText: json['summaryText'] as String?,
      references: rawReferences
          .map((raw) {
            final reference = Map<String, dynamic>.from(raw as Map);
            return DailyRepSummaryReference(
              code: reference['code'] as String,
              label: reference['label'] as String,
              value: reference['value'] as String,
              unit: reference['unit'] as String?,
            );
          })
          .toList(growable: false),
      generatedAt: generatedAtRaw == null
          ? null
          : DateTime.parse(generatedAtRaw),
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
          'Falha inesperada ao consultar o resumo diário.',
          cause: error,
        ),
      );
    }
  }
}
