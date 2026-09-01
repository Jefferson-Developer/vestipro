import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/target.dart';
import '../../domain/repositories/target_repository.dart';
import '../../domain/value_objects/target_dimension_type.dart';
import '../../domain/value_objects/target_metric_type.dart';
import '../mappers/target_mapper.dart';

/// Local Target store used until the remote/Outbox sync implementation
/// exists, matching the precedent set by
/// `SharedPreferencesOpportunityRepository` (TASK-058) and
/// `SharedPreferencesPromotionalCampaignRepository`: an interim local store,
/// not yet wired to Firestore/the Outbox — `SyncPushHandler`'s own docs note
/// that wiring is still pending even for `order`/`orderItem`/`crmActivity`/
/// `customer`, so a Target-specific Firestore+Outbox repository is
/// deliberately out of TASK-115's scope, expected to arrive together with
/// whichever future task first wires any entity through that pipeline.
///
/// The local JSON schema is intentionally independent from `TargetDto`
/// (Firestore-shaped, `Timestamp` fields): dates are stored as ISO-8601
/// strings here. Enum string codes are still resolved through [TargetMapper]
/// so that conversion table is never duplicated.
@LazySingleton(as: TargetRepository)
final class SharedPreferencesTargetRepository implements TargetRepository {
  const SharedPreferencesTargetRepository(this._mapper);

  final TargetMapper _mapper;

  String _keyFor(String organizationId) => 'targets_$organizationId';

  @override
  Future<AppResult<Target>> create({required Target target}) async {
    try {
      final targets = await _load(target.organizationId);
      final next = <Target>[
        ...targets.where((existing) => existing.id != target.id),
        target,
      ];
      await _save(target.organizationId, next);
      return AppSuccess<Target>(target);
    } catch (exception) {
      return AppFailure<Target>(
        UnexpectedFailure(
          'Unexpected error saving target locally.',
          code: 'target_local_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Target>> update({required Target target}) async {
    try {
      final targets = await _load(target.organizationId);
      final index = targets.indexWhere((existing) => existing.id == target.id);
      if (index == -1) {
        return const AppFailure<Target>(
          NotFoundFailure('Target not found.', code: 'target_not_found'),
        );
      }

      final next = List<Target>.of(targets)..[index] = target;
      await _save(target.organizationId, next);
      return AppSuccess<Target>(target);
    } catch (exception) {
      return AppFailure<Target>(
        UnexpectedFailure(
          'Unexpected error updating target locally.',
          code: 'target_local_update_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Target>> getById({
    required String organizationId,
    required String id,
  }) async {
    try {
      final targets = await _load(organizationId);
      for (final target in targets) {
        if (target.id == id) return AppSuccess<Target>(target);
      }
      return const AppFailure<Target>(
        NotFoundFailure('Target not found.', code: 'target_not_found'),
      );
    } catch (exception) {
      return AppFailure<Target>(
        UnexpectedFailure(
          'Unexpected error loading target locally.',
          code: 'target_local_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<Target>>> listByDimension({
    required String organizationId,
    String? companyId,
    required TargetDimensionType dimensionType,
    required String dimensionId,
    TargetMetricType? metricType,
  }) async {
    try {
      final targets = (await _load(organizationId))
          .where(
            (target) =>
                target.deletedAt == null &&
                target.dimensionType == dimensionType &&
                target.dimensionId == dimensionId &&
                (companyId == null ||
                    companyId.isEmpty ||
                    target.companyId == companyId) &&
                (metricType == null || target.metricType == metricType),
          )
          .toList(growable: false);
      return AppSuccess<List<Target>>(targets);
    } catch (exception) {
      return AppFailure<List<Target>>(
        UnexpectedFailure(
          'Unexpected error listing targets locally.',
          code: 'target_local_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  Future<List<Target>> _load(String organizationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(organizationId));
    if (raw == null) return const <Target>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      throw const ValidationException(
        'Invalid local target list.',
        code: 'invalid_target_local_list',
      );
    }

    return decoded
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ValidationException(
              'Invalid local target payload.',
              code: 'invalid_target_local_payload',
            );
          }
          return _fromJson(item);
        })
        .toList(growable: false);
  }

  Future<void> _save(String organizationId, List<Target> targets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(organizationId),
      jsonEncode(targets.map(_toJson).toList(growable: false)),
    );
  }

  Target _fromJson(Map<String, dynamic> json) {
    return Target(
      id: _requiredString(json, 'id'),
      organizationId: _requiredString(json, 'organizationId'),
      companyId: _requiredString(json, 'companyId'),
      dimensionType: _mapper.dimensionTypeToEntity(
        _requiredString(json, 'dimensionType'),
      ),
      dimensionId: _requiredString(json, 'dimensionId'),
      periodGranularity: _mapper.periodGranularityToEntity(
        _requiredString(json, 'periodGranularity'),
      ),
      startDate: _requiredDate(json, 'startDate'),
      endDate: _requiredDate(json, 'endDate'),
      metricType: _mapper.metricTypeToEntity(
        _requiredString(json, 'metricType'),
      ),
      targetValue: _requiredDouble(json, 'targetValue'),
      currency: _requiredString(json, 'currency'),
      status: _mapper.statusToEntity(_requiredString(json, 'status')),
      createdAt: _requiredDate(json, 'createdAt'),
      createdBy: _requiredString(json, 'createdBy'),
      updatedAt: _requiredDate(json, 'updatedAt'),
      updatedBy: _requiredString(json, 'updatedBy'),
      deletedAt: _optionalDate(json, 'deletedAt'),
      version: _requiredInt(json, 'version'),
      syncStatus: _mapper.syncStatusToEntity(
        _requiredString(json, 'syncStatus'),
      ),
    );
  }

  Map<String, dynamic> _toJson(Target target) {
    return <String, dynamic>{
      'id': target.id,
      'organizationId': target.organizationId,
      'companyId': target.companyId,
      'dimensionType': _mapper.dimensionTypeToDto(target.dimensionType),
      'dimensionId': target.dimensionId,
      'periodGranularity': _mapper.periodGranularityToDto(
        target.periodGranularity,
      ),
      'startDate': target.startDate.toUtc().toIso8601String(),
      'endDate': target.endDate.toUtc().toIso8601String(),
      'metricType': _mapper.metricTypeToDto(target.metricType),
      'targetValue': target.targetValue,
      'currency': target.currency,
      'status': _mapper.statusToDto(target.status),
      'createdAt': target.createdAt.toUtc().toIso8601String(),
      'createdBy': target.createdBy,
      'updatedAt': target.updatedAt.toUtc().toIso8601String(),
      'updatedBy': target.updatedBy,
      if (target.deletedAt != null)
        'deletedAt': target.deletedAt!.toUtc().toIso8601String(),
      'version': target.version,
      'syncStatus': _mapper.syncStatusToDto(target.syncStatus),
    };
  }

  String _requiredString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is String) return value;
    throw ValidationException(
      'Invalid local target string field.',
      code: 'invalid_target_local_payload',
      cause: field,
    );
  }

  double _requiredDouble(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is num) return value.toDouble();
    throw ValidationException(
      'Invalid local target numeric field.',
      code: 'invalid_target_local_payload',
      cause: field,
    );
  }

  DateTime _requiredDate(Map<String, dynamic> json, String field) {
    return DateTime.parse(_requiredString(json, field)).toUtc();
  }

  DateTime? _optionalDate(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null) return null;
    if (value is String) return DateTime.parse(value).toUtc();
    throw ValidationException(
      'Invalid local target date field.',
      code: 'invalid_target_local_payload',
      cause: field,
    );
  }

  int _requiredInt(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is int) return value;
    throw ValidationException(
      'Invalid local target integer field.',
      code: 'invalid_target_local_payload',
      cause: field,
    );
  }
}
