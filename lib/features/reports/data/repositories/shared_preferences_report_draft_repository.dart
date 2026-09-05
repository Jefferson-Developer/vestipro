import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/report_definition.dart';
import '../../domain/repositories/report_repository.dart';

@LazySingleton(as: ReportDraftRepository)
final class SharedPreferencesReportDraftRepository
    implements ReportDraftRepository {
  const SharedPreferencesReportDraftRepository();

  String _key(String userId, String organizationId, String companyId) =>
      'report_builder_draft::$userId::$organizationId::$companyId';

  @override
  Future<ReportDefinition?> load({
    required String userId,
    required String organizationId,
    required String companyId,
  }) async {
    final raw = (await SharedPreferences.getInstance()).getString(
      _key(userId, organizationId, companyId),
    );
    if (raw == null) return null;
    try {
      final definition = ReportDefinition.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
      if (definition.organizationId != organizationId ||
          definition.companyId != companyId) {
        return null;
      }
      return definition;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save({
    required String userId,
    required ReportDefinition definition,
  }) async {
    await (await SharedPreferences.getInstance()).setString(
      _key(userId, definition.organizationId, definition.companyId),
      jsonEncode(definition.toJson()),
    );
  }
}
