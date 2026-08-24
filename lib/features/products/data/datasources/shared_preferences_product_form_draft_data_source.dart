import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../dtos/product_form_draft_dto.dart';
import 'product_form_draft_data_source.dart';

@LazySingleton(as: ProductFormDraftDataSource)
final class SharedPreferencesProductFormDraftDataSource
    implements ProductFormDraftDataSource {
  const SharedPreferencesProductFormDraftDataSource();

  String _keyFor({required String organizationId, required String userId}) {
    return 'product_form_draft_${organizationId}_$userId';
  }

  @override
  Future<ProductFormDraftDto?> getDraft({
    required String organizationId,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(
      _keyFor(organizationId: organizationId, userId: userId),
    );
    if (raw == null) return null;

    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      return ProductFormDraftDto.fromJson(json);
    } on FormatException {
      return null;
    } on ValidationException {
      return null;
    }
  }

  @override
  Future<void> saveDraft(ProductFormDraftDto draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(organizationId: draft.organizationId, userId: draft.userId),
      jsonEncode(draft.toJson()),
    );
  }

  @override
  Future<void> clearDraft({
    required String organizationId,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(organizationId: organizationId, userId: userId));
  }
}
