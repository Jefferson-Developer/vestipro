import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/crm_activity.dart';
import '../../domain/entities/crm_activity_page_result.dart';
import '../../domain/repositories/crm_activity_repository.dart';
import '../mappers/crm_activity_mapper.dart';

@LazySingleton(as: CrmActivityRepository)
final class SharedPreferencesCrmActivityRepository
    implements CrmActivityRepository {
  const SharedPreferencesCrmActivityRepository(this._mapper);

  final CrmActivityMapper _mapper;

  String _keyFor(String organizationId) => 'crm_activities_$organizationId';

  @override
  Future<AppResult<CrmActivity>> create({required CrmActivity activity}) async {
    try {
      final activities = await _load(activity.organizationId);
      final next = <CrmActivity>[
        ...activities.where((existing) => existing.id != activity.id),
        activity,
      ];
      await _save(activity.organizationId, next);
      return AppSuccess<CrmActivity>(activity);
    } catch (exception) {
      return AppFailure<CrmActivity>(
        UnexpectedFailure(
          'Unexpected error saving CRM activity locally.',
          code: 'crm_activity_local_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<CrmActivityPageResult>> listForCustomer({
    required String organizationId,
    required String customerId,
    int limit = 20,
    String? cursor,
    bool ascending = false,
  }) {
    return _listByLink(
      organizationId: organizationId,
      limit: limit,
      cursor: cursor,
      ascending: ascending,
      matchesLink: (activity) => activity.customerId == customerId,
    );
  }

  @override
  Future<AppResult<CrmActivityPageResult>> listForLead({
    required String organizationId,
    required String leadId,
    int limit = 20,
    String? cursor,
    bool ascending = false,
  }) {
    return _listByLink(
      organizationId: organizationId,
      limit: limit,
      cursor: cursor,
      ascending: ascending,
      matchesLink: (activity) => activity.leadId == leadId,
    );
  }

  @override
  Future<AppResult<CrmActivityPageResult>> listForOpportunity({
    required String organizationId,
    required String opportunityId,
    int limit = 20,
    String? cursor,
    bool ascending = false,
  }) {
    return _listByLink(
      organizationId: organizationId,
      limit: limit,
      cursor: cursor,
      ascending: ascending,
      matchesLink: (activity) => activity.opportunityId == opportunityId,
    );
  }

  Future<AppResult<CrmActivityPageResult>> _listByLink({
    required String organizationId,
    required int limit,
    required String? cursor,
    required bool ascending,
    required bool Function(CrmActivity activity) matchesLink,
  }) async {
    try {
      final pageLimit = limit.clamp(1, 100);
      final visible =
          (await _load(
            organizationId,
          )).where(matchesLink).toList(growable: false)..sort(
            (first, second) => _compareByTimeline(first, second, ascending),
          );

      final startIndex = _startIndexAfterCursor(visible, cursor);
      final pageItems = visible
          .skip(startIndex)
          .take(pageLimit + 1)
          .toList(growable: false);
      final hasMore = pageItems.length > pageLimit;
      final activities = hasMore
          ? pageItems.take(pageLimit).toList(growable: false)
          : pageItems;

      return AppSuccess<CrmActivityPageResult>(
        CrmActivityPageResult(
          activities: activities,
          hasMore: hasMore,
          nextCursor: activities.isEmpty ? null : activities.last.id,
          isFromLocalCache: true,
        ),
      );
    } catch (exception) {
      return AppFailure<CrmActivityPageResult>(
        UnexpectedFailure(
          'Unexpected error listing CRM activities locally.',
          code: 'crm_activity_local_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  int _compareByTimeline(
    CrmActivity first,
    CrmActivity second,
    bool ascending,
  ) {
    final byDate = ascending
        ? first.occurredAt.compareTo(second.occurredAt)
        : second.occurredAt.compareTo(first.occurredAt);
    if (byDate != 0) return byDate;
    return first.id.compareTo(second.id);
  }

  int _startIndexAfterCursor(List<CrmActivity> activities, String? cursor) {
    if (cursor == null || cursor.trim().isEmpty) return 0;
    final index = activities.indexWhere((activity) => activity.id == cursor);
    return index == -1 ? 0 : index + 1;
  }

  Future<List<CrmActivity>> _load(String organizationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(organizationId));
    if (raw == null) return const <CrmActivity>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      throw const ValidationException(
        'Invalid local CRM activity list.',
        code: 'invalid_crm_activity_local_list',
      );
    }

    return decoded
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ValidationException(
              'Invalid local CRM activity payload.',
              code: 'invalid_crm_activity_local_payload',
            );
          }
          return _fromJson(item);
        })
        .toList(growable: false);
  }

  Future<void> _save(
    String organizationId,
    List<CrmActivity> activities,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(organizationId),
      jsonEncode(activities.map(_toJson).toList(growable: false)),
    );
  }

  CrmActivity _fromJson(Map<String, dynamic> json) {
    return CrmActivity(
      id: _requiredString(json, 'id'),
      organizationId: _requiredString(json, 'organizationId'),
      companyId: _optionalString(json, 'companyId'),
      type: _mapper.typeToEntity(_requiredString(json, 'type')),
      customerId: _optionalString(json, 'customerId'),
      leadId: _optionalString(json, 'leadId'),
      opportunityId: _optionalString(json, 'opportunityId'),
      userId: _requiredString(json, 'userId'),
      occurredAt: _requiredDate(json, 'occurredAt'),
      description: _requiredString(json, 'description'),
      durationMinutes: _optionalInt(json, 'durationMinutes'),
      attachmentUrls: _stringList(json, 'attachmentUrls'),
      createdAt: _requiredDate(json, 'createdAt'),
      createdBy: _requiredString(json, 'createdBy'),
      updatedAt: _requiredDate(json, 'updatedAt'),
      updatedBy: _requiredString(json, 'updatedBy'),
      version: _requiredInt(json, 'version'),
      syncStatus: _mapper.syncStatusToEntity(
        _requiredString(json, 'syncStatus'),
      ),
    );
  }

  Map<String, dynamic> _toJson(CrmActivity activity) {
    return <String, dynamic>{
      'id': activity.id,
      'organizationId': activity.organizationId,
      if (activity.companyId != null) 'companyId': activity.companyId,
      'type': _mapper.typeToDto(activity.type),
      if (activity.customerId != null) 'customerId': activity.customerId,
      if (activity.leadId != null) 'leadId': activity.leadId,
      if (activity.opportunityId != null)
        'opportunityId': activity.opportunityId,
      'userId': activity.userId,
      'occurredAt': activity.occurredAt.toUtc().toIso8601String(),
      'description': activity.description,
      if (activity.durationMinutes != null)
        'durationMinutes': activity.durationMinutes,
      'attachmentUrls': activity.attachmentUrls,
      'createdAt': activity.createdAt.toUtc().toIso8601String(),
      'createdBy': activity.createdBy,
      'updatedAt': activity.updatedAt.toUtc().toIso8601String(),
      'updatedBy': activity.updatedBy,
      'version': activity.version,
      'syncStatus': _mapper.syncStatusToDto(activity.syncStatus),
    };
  }

  String _requiredString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is String) return value;
    throw ValidationException(
      'Invalid local CRM activity string field.',
      code: 'invalid_crm_activity_local_payload',
      cause: field,
    );
  }

  String? _optionalString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null || value is String) return value as String?;
    throw ValidationException(
      'Invalid local CRM activity string field.',
      code: 'invalid_crm_activity_local_payload',
      cause: field,
    );
  }

  DateTime _requiredDate(Map<String, dynamic> json, String field) {
    return DateTime.parse(_requiredString(json, field)).toUtc();
  }

  int _requiredInt(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is int) return value;
    throw ValidationException(
      'Invalid local CRM activity integer field.',
      code: 'invalid_crm_activity_local_payload',
      cause: field,
    );
  }

  int? _optionalInt(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null || value is int) return value as int?;
    throw ValidationException(
      'Invalid local CRM activity integer field.',
      code: 'invalid_crm_activity_local_payload',
      cause: field,
    );
  }

  List<String> _stringList(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null) return const <String>[];
    if (value is List<dynamic> && value.every((item) => item is String)) {
      return value.cast<String>().toList(growable: false);
    }
    throw ValidationException(
      'Invalid local CRM activity string list field.',
      code: 'invalid_crm_activity_local_payload',
      cause: field,
    );
  }
}
