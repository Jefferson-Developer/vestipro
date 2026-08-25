import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/commercial_size_grid_draft.dart';
import '../../domain/repositories/commercial_size_grid_draft_repository.dart';

@LazySingleton(as: CommercialSizeGridDraftRepository)
final class SharedPreferencesCommercialSizeGridDraftRepository
    implements CommercialSizeGridDraftRepository {
  const SharedPreferencesCommercialSizeGridDraftRepository();

  String _keyFor(String organizationId, String productId) =>
      'commercial_size_grid_draft_${organizationId}_$productId';

  @override
  Future<AppResult<CommercialSizeGridDraft?>> getDraft({
    required String organizationId,
    required String productId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyFor(organizationId, productId));
      if (raw == null) return const AppSuccess<CommercialSizeGridDraft?>(null);
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const ValidationException(
          'Invalid local commercial size grid draft payload.',
          code: 'invalid_commercial_size_grid_draft_payload',
        );
      }
      return AppSuccess<CommercialSizeGridDraft>(_fromJson(decoded));
    } catch (exception) {
      return AppFailure<CommercialSizeGridDraft?>(
        UnexpectedFailure(
          'Unexpected error loading commercial size grid draft locally.',
          code: 'commercial_size_grid_draft_local_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<CommercialSizeGridDraft>> saveDraft({
    required CommercialSizeGridDraft draft,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keyFor(draft.organizationId, draft.productId),
        jsonEncode(_toJson(draft)),
      );
      return AppSuccess<CommercialSizeGridDraft>(draft);
    } catch (exception) {
      return AppFailure<CommercialSizeGridDraft>(
        UnexpectedFailure(
          'Unexpected error saving commercial size grid draft locally.',
          code: 'commercial_size_grid_draft_local_save_unexpected',
          cause: exception,
        ),
      );
    }
  }

  CommercialSizeGridDraft _fromJson(Map<String, dynamic> json) {
    final organizationId = json['organizationId'];
    final productId = json['productId'];
    final quantities = json['quantitiesByVariantId'];
    final updatedAt = json['updatedAt'];
    if (organizationId is! String ||
        productId is! String ||
        quantities is! Map ||
        updatedAt is! String) {
      throw const ValidationException(
        'Invalid local commercial size grid draft payload.',
        code: 'invalid_commercial_size_grid_draft_payload',
      );
    }
    return CommercialSizeGridDraft(
      organizationId: organizationId,
      productId: productId,
      quantitiesByVariantId: Map<String, int>.unmodifiable(
        quantities.map((key, value) {
          if (key is! String || value is! int) {
            throw const ValidationException(
              'Invalid local commercial size grid draft quantities.',
              code: 'invalid_commercial_size_grid_draft_payload',
            );
          }
          return MapEntry<String, int>(key, value);
        }),
      ),
      updatedAt: DateTime.parse(updatedAt).toUtc(),
    );
  }

  Map<String, dynamic> _toJson(CommercialSizeGridDraft draft) {
    return <String, dynamic>{
      'organizationId': draft.organizationId,
      'productId': draft.productId,
      'quantitiesByVariantId': draft.quantitiesByVariantId,
      'updatedAt': draft.updatedAt.toUtc().toIso8601String(),
    };
  }
}
