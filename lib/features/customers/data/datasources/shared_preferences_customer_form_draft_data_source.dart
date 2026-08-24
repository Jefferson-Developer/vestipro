import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../dtos/customer_form_draft_dto.dart';
import 'customer_form_draft_data_source.dart';

@LazySingleton(as: CustomerFormDraftDataSource)
final class SharedPreferencesCustomerFormDraftDataSource
    implements CustomerFormDraftDataSource {
  const SharedPreferencesCustomerFormDraftDataSource();

  String _keyFor({required String organizationId, required String userId}) {
    return 'customer_form_draft_${organizationId}_$userId';
  }

  @override
  Future<CustomerFormDraftDto?> getDraft({
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
      return CustomerFormDraftDto.fromJson(json);
    } on FormatException {
      return null;
    } on ValidationException {
      return null;
    }
  }

  @override
  Future<void> saveDraft(CustomerFormDraftDto draft) async {
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
