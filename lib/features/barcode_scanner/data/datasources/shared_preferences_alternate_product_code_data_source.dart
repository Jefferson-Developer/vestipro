import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/entities/alternate_product_code.dart';
import 'alternate_product_code_local_data_source.dart';

/// [AlternateProductCodeLocalDataSource] backed by `SharedPreferences`, one
/// JSON object per organization keyed by the already-normalized code — same
/// "local store, per-organization key, JSON-encoded list" shape
/// `SharedPreferencesProductVariantRepository` already sets for the rest of
/// the offline product/variant cache.
@LazySingleton(as: AlternateProductCodeLocalDataSource)
final class SharedPreferencesAlternateProductCodeDataSource
    implements AlternateProductCodeLocalDataSource {
  const SharedPreferencesAlternateProductCodeDataSource();

  String _keyFor(String organizationId) =>
      'product_alternate_codes_$organizationId';

  @override
  Future<AlternateProductCode?> findByCode({
    required String organizationId,
    required String code,
  }) async {
    final byCode = await _load(organizationId);
    return byCode[code];
  }

  @override
  Future<List<AlternateProductCode>> listByOrganization(
    String organizationId,
  ) async {
    final byCode = await _load(organizationId);
    return byCode.values.toList(growable: false)
      ..sort((a, b) => a.code.compareTo(b.code));
  }

  @override
  Future<AlternateProductCode> upsert(AlternateProductCode code) async {
    final byCode = await _load(code.organizationId);
    byCode[code.code] = code;
    await _save(code.organizationId, byCode);
    return code;
  }

  Future<Map<String, AlternateProductCode>> _load(String organizationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(organizationId));
    if (raw == null) return <String, AlternateProductCode>{};
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      throw const ValidationException(
        'Invalid local alternate product code list.',
        code: 'invalid_alternate_product_code_local_list',
      );
    }
    final entries = decoded.map(_fromJson);
    return <String, AlternateProductCode>{
      for (final entry in entries) entry.code: entry,
    };
  }

  Future<void> _save(
    String organizationId,
    Map<String, AlternateProductCode> byCode,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(organizationId),
      jsonEncode(byCode.values.map(_toJson).toList(growable: false)),
    );
  }

  AlternateProductCode _fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const ValidationException(
        'Invalid local alternate product code payload.',
        code: 'invalid_alternate_product_code_local_payload',
      );
    }
    return AlternateProductCode(
      organizationId: _requiredString(value, 'organizationId'),
      code: _requiredString(value, 'code'),
      productId: _requiredString(value, 'productId'),
      variantId: _optionalString(value, 'variantId'),
      registeredAt: DateTime.parse(
        _requiredString(value, 'registeredAt'),
      ).toUtc(),
      registeredBy: _requiredString(value, 'registeredBy'),
    );
  }

  Map<String, dynamic> _toJson(AlternateProductCode code) {
    return <String, dynamic>{
      'organizationId': code.organizationId,
      'code': code.code,
      'productId': code.productId,
      if (code.variantId != null) 'variantId': code.variantId,
      'registeredAt': code.registeredAt.toUtc().toIso8601String(),
      'registeredBy': code.registeredBy,
    };
  }

  String _requiredString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is String) return value;
    throw ValidationException(
      'Invalid local alternate product code string field.',
      code: 'invalid_alternate_product_code_local_payload',
      cause: field,
    );
  }

  String? _optionalString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null || value is String) return value as String?;
    throw ValidationException(
      'Invalid local alternate product code string field.',
      code: 'invalid_alternate_product_code_local_payload',
      cause: field,
    );
  }
}
