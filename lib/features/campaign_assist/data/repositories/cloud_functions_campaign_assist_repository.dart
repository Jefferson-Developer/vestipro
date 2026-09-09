import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/functions/functions.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/campaign_creation_draft.dart';
import '../../domain/repositories/campaign_assist_repository.dart';

/// Calls the `assistCampaignCreation` Cloud Function (TASK-192, EPIC-28) —
/// the only place this feature ever reaches the network. No Firestore
/// datasource exists for this feature: the server-side cache
/// (`organizations/{organizationId}/campaignAssistDrafts/{cacheKey}`) is
/// never readable directly by any client (`firestore.rules` denies it
/// outright), so every call — cached or freshly generated — goes through
/// this one callable. Mirrors `CloudFunctionsApproachSuggestionRepository`
/// (TASK-187) exactly.
@LazySingleton(as: CampaignAssistRepository)
final class CloudFunctionsCampaignAssistRepository
    implements CampaignAssistRepository {
  const CloudFunctionsCampaignAssistRepository(this._functions);

  final CloudFunctionsService _functions;

  @override
  Future<AppResult<CampaignCreationDraft>> generate({
    required String organizationId,
    required List<String> productIds,
    required String audienceDescription,
    required String tone,
    DateTime? startAt,
    DateTime? endAt,
  }) => _guard(() async {
    final json = await _functions.call<Map<String, dynamic>>(
      'assistCampaignCreation',
      requireAuth: true,
      data: <String, dynamic>{
        'organizationId': organizationId,
        'productIds': productIds,
        'audienceDescription': audienceDescription,
        'tone': tone,
        if (startAt != null) 'startAt': startAt.toUtc().toIso8601String(),
        if (endAt != null) 'endAt': endAt.toUtc().toIso8601String(),
      },
    );
    final rawCitedProductIds =
        json['citedProductIds'] as List<dynamic>? ?? const <dynamic>[];
    return CampaignCreationDraft(
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      description: json['description'] as String,
      citedProductIds: rawCitedProductIds.cast<String>().toList(
        growable: false,
      ),
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
          'Falha inesperada ao gerar a sugestão de campanha.',
          cause: error,
        ),
      );
    }
  }
}
