import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_list_filters.dart';
import '../../domain/entities/lead_page_result.dart';
import '../../domain/repositories/lead_repository.dart';
import '../mappers/lead_mapper.dart';

/// Local lead store used until the remote/outbox sync implementation exists
/// (TASK-056), matching the precedent set by `SharedPreferencesCustomerRepository`
/// (TASK-048): mutations are kept durable with `syncStatus.pending` and
/// `listPage` performs the same filtering/pagination client-side that the
/// customer portfolio does.
///
/// The local JSON schema is intentionally independent from [LeadDto]
/// (Firestore-shaped, `Timestamp` fields): dates are stored as ISO-8601
/// strings here, the same divergence `SharedPreferencesCustomerRepository`
/// keeps from `CustomerDto`. Status/source/sync-status string codes are
/// still resolved through [LeadMapper] so that conversion table is never
/// duplicated.
@LazySingleton(as: LeadRepository)
final class SharedPreferencesLeadRepository implements LeadRepository {
  const SharedPreferencesLeadRepository(this._mapper);

  final LeadMapper _mapper;

  String _keyFor(String organizationId) => 'leads_$organizationId';

  @override
  Future<AppResult<Lead>> create({required Lead lead}) async {
    try {
      final leads = await _load(lead.organizationId);
      final next = <Lead>[
        ...leads.where((existing) => existing.id != lead.id),
        lead,
      ];
      await _save(lead.organizationId, next);
      return AppSuccess<Lead>(lead);
    } catch (exception) {
      return AppFailure<Lead>(
        UnexpectedFailure(
          'Unexpected error saving lead locally.',
          code: 'lead_local_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Lead>> update({required Lead lead}) async {
    try {
      final leads = await _load(lead.organizationId);
      final index = leads.indexWhere((existing) => existing.id == lead.id);
      if (index == -1) {
        return const AppFailure<Lead>(
          NotFoundFailure('Lead not found.', code: 'lead_not_found'),
        );
      }

      final next = List<Lead>.of(leads)..[index] = lead;
      await _save(lead.organizationId, next);
      return AppSuccess<Lead>(lead);
    } catch (exception) {
      return AppFailure<Lead>(
        UnexpectedFailure(
          'Unexpected error updating lead locally.',
          code: 'lead_local_update_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Lead>> getById({
    required String organizationId,
    required String id,
  }) async {
    try {
      final leads = await _load(organizationId);
      for (final lead in leads) {
        if (lead.id == id) return AppSuccess<Lead>(lead);
      }
      return const AppFailure<Lead>(
        NotFoundFailure('Lead not found.', code: 'lead_not_found'),
      );
    } catch (exception) {
      return AppFailure<Lead>(
        UnexpectedFailure(
          'Unexpected error loading lead locally.',
          code: 'lead_local_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<LeadPageResult>> listPage({
    required String organizationId,
    String? companyId,
    required LeadListFilters filters,
    required String searchQuery,
    required int limit,
    String? cursor,
  }) async {
    try {
      final normalizedSearch = _normalizeSearch(searchQuery);
      final normalizedFilters = filters.normalized();
      final visible =
          (await _load(organizationId))
              .where(
                (lead) =>
                    _matchesCompany(lead, companyId) &&
                    _matchesSearch(lead, normalizedSearch) &&
                    _matchesFilters(lead, normalizedFilters),
              )
              .toList(growable: false)
            ..sort(_compareLeads);

      final startIndex = _startIndexAfterCursor(visible, cursor);
      final pageItems = visible
          .skip(startIndex)
          .take(limit + 1)
          .toList(growable: false);
      final hasMore = pageItems.length > limit;
      final leadsPage = hasMore
          ? pageItems.take(limit).toList(growable: false)
          : pageItems;

      return AppSuccess<LeadPageResult>(
        LeadPageResult(
          leads: leadsPage,
          hasMore: hasMore,
          nextCursor: leadsPage.isEmpty ? null : leadsPage.last.id,
          isFromLocalCache: true,
        ),
      );
    } catch (exception) {
      return AppFailure<LeadPageResult>(
        UnexpectedFailure(
          'Unexpected error listing leads locally.',
          code: 'lead_local_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  bool _matchesCompany(Lead lead, String? companyId) {
    if (companyId == null || companyId.isEmpty) return true;
    if (lead.companyId == null) return true;
    return lead.companyId == companyId;
  }

  bool _matchesSearch(Lead lead, String search) {
    if (search.isEmpty) return true;
    final haystack = _normalizeSearch(
      <String>[lead.name, lead.document ?? ''].join(' '),
    );
    return haystack.contains(search);
  }

  bool _matchesFilters(Lead lead, LeadListFilters filters) {
    if (filters.statuses.isNotEmpty &&
        !filters.statuses.contains(lead.status)) {
      return false;
    }
    if (filters.sourceCodes.isNotEmpty &&
        !filters.sourceCodes.contains(lead.source.code)) {
      return false;
    }
    if (filters.responsibleUserIds.isNotEmpty &&
        !filters.responsibleUserIds.contains(lead.responsibleUserId)) {
      return false;
    }
    return true;
  }

  int _compareLeads(Lead first, Lead second) {
    final byDate = second.createdAt.compareTo(first.createdAt);
    if (byDate != 0) return byDate;
    return first.id.compareTo(second.id);
  }

  int _startIndexAfterCursor(List<Lead> leads, String? cursor) {
    if (cursor == null || cursor.trim().isEmpty) return 0;
    final index = leads.indexWhere((lead) => lead.id == cursor);
    return index == -1 ? 0 : index + 1;
  }

  String _normalizeSearch(String value) {
    final lower = value.trim().toLowerCase();
    const accents = <String, String>{
      'á': 'a',
      'à': 'a',
      'ã': 'a',
      'â': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'õ': 'o',
      'ô': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };
    return lower.split('').map((char) => accents[char] ?? char).join();
  }

  Future<List<Lead>> _load(String organizationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(organizationId));
    if (raw == null) return const <Lead>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      throw const ValidationException(
        'Invalid local lead list.',
        code: 'invalid_lead_local_list',
      );
    }

    return decoded
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ValidationException(
              'Invalid local lead payload.',
              code: 'invalid_lead_local_payload',
            );
          }
          return _fromJson(item);
        })
        .toList(growable: false);
  }

  Future<void> _save(String organizationId, List<Lead> leads) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(organizationId),
      jsonEncode(leads.map(_toJson).toList(growable: false)),
    );
  }

  Lead _fromJson(Map<String, dynamic> json) {
    return Lead(
      id: _requiredString(json, 'id'),
      organizationId: _requiredString(json, 'organizationId'),
      companyId: _optionalString(json, 'companyId'),
      name: _requiredString(json, 'name'),
      document: _optionalString(json, 'document'),
      source: _mapper.sourceToEntity(
        _requiredString(json, 'sourceCode'),
        label: _requiredString(json, 'sourceLabel'),
      ),
      responsibleUserId: _requiredString(json, 'responsibleUserId'),
      status: _mapper.statusToEntity(_requiredString(json, 'status')),
      score: _requiredInt(json, 'score'),
      disqualificationReason: _optionalString(json, 'disqualificationReason'),
      convertedCustomerId: _optionalString(json, 'convertedCustomerId'),
      convertedOpportunityId: _optionalString(json, 'convertedOpportunityId'),
      createdAt: _requiredDate(json, 'createdAt'),
      contactedAt: _optionalDate(json, 'contactedAt'),
      qualifiedAt: _optionalDate(json, 'qualifiedAt'),
      convertedAt: _optionalDate(json, 'convertedAt'),
      createdBy: _requiredString(json, 'createdBy'),
      updatedAt: _requiredDate(json, 'updatedAt'),
      updatedBy: _requiredString(json, 'updatedBy'),
      version: _requiredInt(json, 'version'),
      syncStatus: _mapper.syncStatusToEntity(
        _requiredString(json, 'syncStatus'),
      ),
    );
  }

  Map<String, dynamic> _toJson(Lead lead) {
    return <String, dynamic>{
      'id': lead.id,
      'organizationId': lead.organizationId,
      if (lead.companyId != null) 'companyId': lead.companyId,
      'name': lead.name,
      if (lead.document != null) 'document': lead.document,
      'sourceCode': lead.source.code,
      'sourceLabel': lead.source.label,
      'responsibleUserId': lead.responsibleUserId,
      'status': _mapper.statusToDto(lead.status),
      'score': lead.score,
      if (lead.disqualificationReason != null)
        'disqualificationReason': lead.disqualificationReason,
      if (lead.convertedCustomerId != null)
        'convertedCustomerId': lead.convertedCustomerId,
      if (lead.convertedOpportunityId != null)
        'convertedOpportunityId': lead.convertedOpportunityId,
      'createdAt': lead.createdAt.toUtc().toIso8601String(),
      if (lead.contactedAt != null)
        'contactedAt': lead.contactedAt!.toUtc().toIso8601String(),
      if (lead.qualifiedAt != null)
        'qualifiedAt': lead.qualifiedAt!.toUtc().toIso8601String(),
      if (lead.convertedAt != null)
        'convertedAt': lead.convertedAt!.toUtc().toIso8601String(),
      'createdBy': lead.createdBy,
      'updatedAt': lead.updatedAt.toUtc().toIso8601String(),
      'updatedBy': lead.updatedBy,
      'version': lead.version,
      'syncStatus': _mapper.syncStatusToDto(lead.syncStatus),
    };
  }

  String _requiredString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is String) return value;
    throw ValidationException(
      'Invalid local lead string field.',
      code: 'invalid_lead_local_payload',
      cause: field,
    );
  }

  String? _optionalString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null || value is String) return value as String?;
    throw ValidationException(
      'Invalid local lead string field.',
      code: 'invalid_lead_local_payload',
      cause: field,
    );
  }

  DateTime _requiredDate(Map<String, dynamic> json, String field) {
    return DateTime.parse(_requiredString(json, field)).toUtc();
  }

  DateTime? _optionalDate(Map<String, dynamic> json, String field) {
    final value = _optionalString(json, field);
    return value == null ? null : DateTime.parse(value).toUtc();
  }

  int _requiredInt(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is int) return value;
    throw ValidationException(
      'Invalid local lead integer field.',
      code: 'invalid_lead_local_payload',
      cause: field,
    );
  }
}
