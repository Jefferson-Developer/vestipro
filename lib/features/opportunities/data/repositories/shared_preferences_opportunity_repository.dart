import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/opportunity.dart';
import '../../domain/repositories/opportunity_repository.dart';
import '../mappers/opportunity_mapper.dart';

/// Local opportunity store used until the remote/outbox sync implementation
/// exists (TASK-058), matching the precedent set by
/// `SharedPreferencesLeadRepository` (TASK-056): the local JSON schema is
/// intentionally independent from [OpportunityDto] (Firestore-shaped,
/// `Timestamp` fields) — dates are stored as ISO-8601 strings here. Status/
/// sync-status string codes are still resolved through [OpportunityMapper]
/// so that conversion table is never duplicated.
@LazySingleton(as: OpportunityRepository)
final class SharedPreferencesOpportunityRepository
    implements OpportunityRepository {
  const SharedPreferencesOpportunityRepository(this._mapper);

  final OpportunityMapper _mapper;

  String _keyFor(String organizationId) => 'opportunities_$organizationId';

  @override
  Future<AppResult<Opportunity>> create({
    required Opportunity opportunity,
  }) async {
    try {
      final opportunities = await _load(opportunity.organizationId);
      final next = <Opportunity>[
        ...opportunities.where((existing) => existing.id != opportunity.id),
        opportunity,
      ];
      await _save(opportunity.organizationId, next);
      return AppSuccess<Opportunity>(opportunity);
    } catch (exception) {
      return AppFailure<Opportunity>(
        UnexpectedFailure(
          'Unexpected error saving opportunity locally.',
          code: 'opportunity_local_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Opportunity>> update({
    required Opportunity opportunity,
  }) async {
    try {
      final opportunities = await _load(opportunity.organizationId);
      final index = opportunities.indexWhere(
        (existing) => existing.id == opportunity.id,
      );
      if (index == -1) {
        return const AppFailure<Opportunity>(
          NotFoundFailure(
            'Opportunity not found.',
            code: 'opportunity_not_found',
          ),
        );
      }

      final next = List<Opportunity>.of(opportunities)..[index] = opportunity;
      await _save(opportunity.organizationId, next);
      return AppSuccess<Opportunity>(opportunity);
    } catch (exception) {
      return AppFailure<Opportunity>(
        UnexpectedFailure(
          'Unexpected error updating opportunity locally.',
          code: 'opportunity_local_update_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Opportunity>> getById({
    required String organizationId,
    required String id,
  }) async {
    try {
      final opportunities = await _load(organizationId);
      for (final opportunity in opportunities) {
        if (opportunity.id == id) return AppSuccess<Opportunity>(opportunity);
      }
      return const AppFailure<Opportunity>(
        NotFoundFailure(
          'Opportunity not found.',
          code: 'opportunity_not_found',
        ),
      );
    } catch (exception) {
      return AppFailure<Opportunity>(
        UnexpectedFailure(
          'Unexpected error loading opportunity locally.',
          code: 'opportunity_local_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<Opportunity>>> listByOrganization({
    required String organizationId,
    String? companyId,
    Set<String> responsibleUserIds = const <String>{},
  }) async {
    try {
      final opportunities = (await _load(organizationId))
          .where(
            (opportunity) =>
                _matchesCompany(opportunity, companyId) &&
                _matchesResponsible(opportunity, responsibleUserIds),
          )
          .toList(growable: false);
      return AppSuccess<List<Opportunity>>(opportunities);
    } catch (exception) {
      return AppFailure<List<Opportunity>>(
        UnexpectedFailure(
          'Unexpected error listing opportunities locally.',
          code: 'opportunity_local_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  bool _matchesCompany(Opportunity opportunity, String? companyId) {
    if (companyId == null || companyId.isEmpty) return true;
    if (opportunity.companyId == null) return true;
    return opportunity.companyId == companyId;
  }

  bool _matchesResponsible(
    Opportunity opportunity,
    Set<String> responsibleUserIds,
  ) {
    if (responsibleUserIds.isEmpty) return true;
    return responsibleUserIds.contains(opportunity.responsibleUserId);
  }

  Future<List<Opportunity>> _load(String organizationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(organizationId));
    if (raw == null) return const <Opportunity>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      throw const ValidationException(
        'Invalid local opportunity list.',
        code: 'invalid_opportunity_local_list',
      );
    }

    return decoded
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ValidationException(
              'Invalid local opportunity payload.',
              code: 'invalid_opportunity_local_payload',
            );
          }
          return _fromJson(item);
        })
        .toList(growable: false);
  }

  Future<void> _save(
    String organizationId,
    List<Opportunity> opportunities,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(organizationId),
      jsonEncode(opportunities.map(_toJson).toList(growable: false)),
    );
  }

  Opportunity _fromJson(Map<String, dynamic> json) {
    return Opportunity(
      id: _requiredString(json, 'id'),
      organizationId: _requiredString(json, 'organizationId'),
      companyId: _optionalString(json, 'companyId'),
      title: _requiredString(json, 'title'),
      description: _optionalString(json, 'description'),
      customerId: _optionalString(json, 'customerId'),
      leadId: _optionalString(json, 'leadId'),
      estimatedValue: _requiredDouble(json, 'estimatedValue'),
      probability: _requiredInt(json, 'probability'),
      revenueForecast: _requiredDouble(json, 'revenueForecast'),
      responsibleUserId: _requiredString(json, 'responsibleUserId'),
      stageId: _requiredString(json, 'stageId'),
      status: _mapper.statusToEntity(_requiredString(json, 'status')),
      expectedCloseDate: _requiredDate(json, 'expectedCloseDate'),
      wonReasonId: _optionalString(json, 'wonReasonId'),
      wonReason: _optionalString(json, 'wonReason'),
      wonReasonNote: _optionalString(json, 'wonReasonNote'),
      lostReasonId: _optionalString(json, 'lostReasonId'),
      lostReason: _optionalString(json, 'lostReason'),
      lostReasonNote: _optionalString(json, 'lostReasonNote'),
      closedAt: _optionalDate(json, 'closedAt'),
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

  Map<String, dynamic> _toJson(Opportunity opportunity) {
    return <String, dynamic>{
      'id': opportunity.id,
      'organizationId': opportunity.organizationId,
      if (opportunity.companyId != null) 'companyId': opportunity.companyId,
      'title': opportunity.title,
      if (opportunity.description != null)
        'description': opportunity.description,
      if (opportunity.customerId != null) 'customerId': opportunity.customerId,
      if (opportunity.leadId != null) 'leadId': opportunity.leadId,
      'estimatedValue': opportunity.estimatedValue,
      'probability': opportunity.probability,
      'revenueForecast': opportunity.revenueForecast,
      'responsibleUserId': opportunity.responsibleUserId,
      'stageId': opportunity.stageId,
      'status': _mapper.statusToDto(opportunity.status),
      'expectedCloseDate': opportunity.expectedCloseDate
          .toUtc()
          .toIso8601String(),
      if (opportunity.wonReasonId != null)
        'wonReasonId': opportunity.wonReasonId,
      if (opportunity.wonReason != null) 'wonReason': opportunity.wonReason,
      if (opportunity.wonReasonNote != null)
        'wonReasonNote': opportunity.wonReasonNote,
      if (opportunity.lostReasonId != null)
        'lostReasonId': opportunity.lostReasonId,
      if (opportunity.lostReason != null) 'lostReason': opportunity.lostReason,
      if (opportunity.lostReasonNote != null)
        'lostReasonNote': opportunity.lostReasonNote,
      if (opportunity.closedAt != null)
        'closedAt': opportunity.closedAt!.toUtc().toIso8601String(),
      'createdAt': opportunity.createdAt.toUtc().toIso8601String(),
      'createdBy': opportunity.createdBy,
      'updatedAt': opportunity.updatedAt.toUtc().toIso8601String(),
      'updatedBy': opportunity.updatedBy,
      'version': opportunity.version,
      'syncStatus': _mapper.syncStatusToDto(opportunity.syncStatus),
    };
  }

  String _requiredString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is String) return value;
    throw ValidationException(
      'Invalid local opportunity string field.',
      code: 'invalid_opportunity_local_payload',
      cause: field,
    );
  }

  String? _optionalString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null || value is String) return value as String?;
    throw ValidationException(
      'Invalid local opportunity string field.',
      code: 'invalid_opportunity_local_payload',
      cause: field,
    );
  }

  double _requiredDouble(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is num) return value.toDouble();
    throw ValidationException(
      'Invalid local opportunity numeric field.',
      code: 'invalid_opportunity_local_payload',
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
      'Invalid local opportunity integer field.',
      code: 'invalid_opportunity_local_payload',
      cause: field,
    );
  }
}
