import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/opportunity_outcome_reason.dart';
import '../../domain/repositories/opportunity_outcome_reason_repository.dart';
import '../../domain/value_objects/opportunity_outcome_type.dart';
import '../mappers/opportunity_outcome_reason_mapper.dart';

@LazySingleton(as: OpportunityOutcomeReasonRepository)
final class SharedPreferencesOpportunityOutcomeReasonRepository
    implements OpportunityOutcomeReasonRepository {
  const SharedPreferencesOpportunityOutcomeReasonRepository(this._mapper);

  final OpportunityOutcomeReasonMapper _mapper;

  String _keyFor(String organizationId) =>
      'opportunity_outcome_reasons_$organizationId';

  @override
  Future<AppResult<OpportunityOutcomeReason>> create({
    required OpportunityOutcomeReason reason,
  }) async {
    try {
      final reasons = await _load(reason.organizationId);
      final next = <OpportunityOutcomeReason>[
        ...reasons.where((existing) => existing.id != reason.id),
        reason,
      ];
      await _save(reason.organizationId, next);
      return AppSuccess<OpportunityOutcomeReason>(reason);
    } catch (exception) {
      return AppFailure<OpportunityOutcomeReason>(
        UnexpectedFailure(
          'Unexpected error creating opportunity outcome reason locally.',
          code: 'opportunity_outcome_reason_local_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<OpportunityOutcomeReason>> update({
    required OpportunityOutcomeReason reason,
  }) async {
    try {
      final reasons = await _load(reason.organizationId);
      final index = reasons.indexWhere((existing) => existing.id == reason.id);
      if (index == -1) {
        return const AppFailure<OpportunityOutcomeReason>(
          NotFoundFailure(
            'Opportunity outcome reason not found.',
            code: 'opportunity_outcome_reason_not_found',
          ),
        );
      }

      final next = List<OpportunityOutcomeReason>.of(reasons)..[index] = reason;
      await _save(reason.organizationId, next);
      return AppSuccess<OpportunityOutcomeReason>(reason);
    } catch (exception) {
      return AppFailure<OpportunityOutcomeReason>(
        UnexpectedFailure(
          'Unexpected error updating opportunity outcome reason locally.',
          code: 'opportunity_outcome_reason_local_update_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<OpportunityOutcomeReason>> getById({
    required String organizationId,
    required String id,
  }) async {
    try {
      final reasons = await _load(organizationId);
      for (final reason in reasons) {
        if (reason.id == id) {
          return AppSuccess<OpportunityOutcomeReason>(reason);
        }
      }
      return const AppFailure<OpportunityOutcomeReason>(
        NotFoundFailure(
          'Opportunity outcome reason not found.',
          code: 'opportunity_outcome_reason_not_found',
        ),
      );
    } catch (exception) {
      return AppFailure<OpportunityOutcomeReason>(
        UnexpectedFailure(
          'Unexpected error loading opportunity outcome reason locally.',
          code: 'opportunity_outcome_reason_local_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<OpportunityOutcomeReason>>> listByOrganization({
    required String organizationId,
    OpportunityOutcomeType? type,
    bool includeInactive = false,
  }) async {
    try {
      final reasons =
          (await _load(organizationId))
              .where(
                (reason) =>
                    (type == null || reason.type == type) &&
                    (includeInactive || reason.isActive),
              )
              .toList(growable: false)
            ..sort((a, b) {
              final typeComparison = a.type.index.compareTo(b.type.index);
              if (typeComparison != 0) return typeComparison;
              return a.description.compareTo(b.description);
            });
      return AppSuccess<List<OpportunityOutcomeReason>>(reasons);
    } catch (exception) {
      return AppFailure<List<OpportunityOutcomeReason>>(
        UnexpectedFailure(
          'Unexpected error listing opportunity outcome reasons locally.',
          code: 'opportunity_outcome_reason_local_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  Future<List<OpportunityOutcomeReason>> _load(String organizationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(organizationId));
    if (raw == null) return const <OpportunityOutcomeReason>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      throw const ValidationException(
        'Invalid local opportunity outcome reason list.',
        code: 'invalid_opportunity_outcome_reason_local_list',
      );
    }

    return decoded
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ValidationException(
              'Invalid local opportunity outcome reason payload.',
              code: 'invalid_opportunity_outcome_reason_local_payload',
            );
          }
          return _fromJson(item);
        })
        .toList(growable: false);
  }

  Future<void> _save(
    String organizationId,
    List<OpportunityOutcomeReason> reasons,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(organizationId),
      jsonEncode(reasons.map(_toJson).toList(growable: false)),
    );
  }

  OpportunityOutcomeReason _fromJson(Map<String, dynamic> json) {
    return OpportunityOutcomeReason(
      id: _requiredString(json, 'id'),
      organizationId: _requiredString(json, 'organizationId'),
      type: _mapper.typeToEntity(_requiredString(json, 'type')),
      description: _requiredString(json, 'description'),
      isActive: _requiredBool(json, 'isActive'),
      createdAt: _requiredDate(json, 'createdAt'),
      createdBy: _requiredString(json, 'createdBy'),
      updatedAt: _requiredDate(json, 'updatedAt'),
      updatedBy: _requiredString(json, 'updatedBy'),
      version: _requiredInt(json, 'version'),
    );
  }

  Map<String, dynamic> _toJson(OpportunityOutcomeReason reason) {
    return <String, dynamic>{
      'id': reason.id,
      'organizationId': reason.organizationId,
      'type': _mapper.typeToDto(reason.type),
      'description': reason.description,
      'isActive': reason.isActive,
      'createdAt': reason.createdAt.toUtc().toIso8601String(),
      'createdBy': reason.createdBy,
      'updatedAt': reason.updatedAt.toUtc().toIso8601String(),
      'updatedBy': reason.updatedBy,
      'version': reason.version,
    };
  }

  String _requiredString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is String) return value;
    throw ValidationException(
      'Invalid local opportunity outcome reason string field.',
      code: 'invalid_opportunity_outcome_reason_local_payload',
      cause: field,
    );
  }

  bool _requiredBool(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is bool) return value;
    throw ValidationException(
      'Invalid local opportunity outcome reason boolean field.',
      code: 'invalid_opportunity_outcome_reason_local_payload',
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
      'Invalid local opportunity outcome reason integer field.',
      code: 'invalid_opportunity_outcome_reason_local_payload',
      cause: field,
    );
  }
}
