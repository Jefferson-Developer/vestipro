import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/functions/functions.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/approach_suggestion.dart';
import '../../domain/entities/approach_suggestion_reference.dart';
import '../../domain/repositories/approach_suggestion_repository.dart';

/// Calls the `suggestApproach` Cloud Function (TASK-187, EPIC-28) — the only
/// place this feature ever reaches the network. No Firestore datasource
/// exists for this feature: the server-side cache
/// (`organizations/{organizationId}/approachSuggestions/{customerId}`) is
/// never readable directly by any client (`firestore.rules` denies it
/// outright), so every call — cached or freshly generated — goes through
/// this one callable. Mirrors
/// `CloudFunctionsWalletSummaryRepository` (TASK-186) exactly.
@LazySingleton(as: ApproachSuggestionRepository)
final class CloudFunctionsApproachSuggestionRepository
    implements ApproachSuggestionRepository {
  const CloudFunctionsApproachSuggestionRepository(this._functions);

  final CloudFunctionsService _functions;

  @override
  Future<AppResult<ApproachSuggestion>> generate({
    required String organizationId,
    required String companyId,
    required String customerId,
  }) => _guard(() async {
    final json = await _functions.call<Map<String, dynamic>>(
      'suggestApproach',
      requireAuth: true,
      data: <String, dynamic>{
        'organizationId': organizationId,
        'companyId': companyId,
        'customerId': customerId,
      },
    );
    final rawReferences =
        json['references'] as List<dynamic>? ?? const <dynamic>[];
    return ApproachSuggestion(
      suggestedText: json['suggestedText'] as String,
      references: rawReferences
          .map((raw) {
            final reference = Map<String, dynamic>.from(raw as Map);
            return ApproachSuggestionReference(
              code: reference['code'] as String,
              label: reference['label'] as String,
              value: reference['value'] as String,
              unit: reference['unit'] as String?,
            );
          })
          .toList(growable: false),
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
          'Falha inesperada ao gerar a sugestão de abordagem.',
          cause: error,
        ),
      );
    }
  }
}
